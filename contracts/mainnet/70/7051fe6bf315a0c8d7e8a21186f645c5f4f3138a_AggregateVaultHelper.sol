pragma solidity 0.8.17;

import { AggregateVaultStorage } from "../storage/AggregateVaultStorage.sol";
import { BaseHandler } from "../BaseHandler.sol";
import { IGMIWithERC20 as GMI } from "../interfaces/IGMI.sol";
import { IFeeEscrow } from "../interfaces/IFeeEscrow.sol";
import { Pricing } from "../libraries/Pricing.sol";
import { LibAggregateVaultUtils } from "../libraries/LibAggregateVaultUtils.sol";
import { TOKEN_USDC_NATIVE, TOKEN_WETH, YEAR } from "../constants.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { OracleWrapper } from "../peripheral/OracleWrapper.sol";
import { IPositionManager } from "../interfaces/IPositionManager.sol";
import { IVaultFees } from "../interfaces/IVaultFees.sol";
import { PriceCast } from "../libraries/PriceCast.sol";
import { SafeCast } from "../libraries/SafeCast.sol";
import { NettedPositionTracker } from "../libraries/NettedPositionTracker.sol";
import { Delegatecall } from "../libraries/Delegatecall.sol";
import { Solarray } from "../libraries/Solarray.sol";
import { GmxStorage } from "../libraries/GmxStorage.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ISwapManager } from "../interfaces/ISwapManager.sol";
import { LibCycle } from "../libraries/LibCycle.sol";
import { GlobalACL, Auth } from "../Auth.sol";
import { FeeReserve } from "./FeeReserve.sol";
import { Vester } from "./Vester.sol";

using SafeCast for uint256;
using SafeCast for int256;
using PriceCast for uint256;
using Delegatecall for address;
using Solarray for uint256[2];
using SafeTransferLib for ERC20;

/// @title AggregateVaultViews
/// @author Umami Devs
/// @notice A contract providing view functions for AggregateVaultStorage data.
contract AggregateVaultViews is AggregateVaultStorage {
    /// @notice Returns the array of AssetVaultEntry structs.
    function getAssetVaultEntries() public view returns (AssetVaultStorage[2] memory _assetVaultEntry) {
        _assetVaultEntry = _getStorage().vaults;
    }

    /// @notice Returns the index of a token in the asset vault array.
    /// @param _token The address of the token.
    function tokenToAssetVaultIndex(address _token) public view returns (uint256 _idx) {
        _idx = _getTokenToAssetVaultIndex()[_token];
    }

    /// @notice Returns the index of a vault in the asset vault array.
    /// @param _vault The address of the vault.
    function vaultToAssetVaultIndex(address _vault) public view returns (uint256 _idx) {
        _idx = _getVaultToAssetVaultIndex()[_vault];
    }

    /// @notice Returns the current vault state.
    function getVaultState() public view returns (VaultState memory _vaultState) {
        _vaultState = _getVaultState();
    }

    /// @notice Returns the current rebalance state.
    function getRebalanceState() public view returns (RebalanceState memory _rebalanceState) {
        _rebalanceState = _getRebalanceState();
    }

    /// @notice Returns the current GMI attribution for each asset vault.
    function getVaultGmiAttribution() public view returns (uint256[2] memory _gmiAttribution) {
        _gmiAttribution = _getStorage().vaultGmiAttribution;
    }

    /// @notice Returns the last netted price for a given epoch.
    /// @param _epoch The epoch for which to retrieve the netted price.
    function getLastNettedPrice(uint256 _epoch) public view returns (int256[2] memory _nettedPrices) {
        _nettedPrices = _getNettedPrices(_epoch);
    }

    /// @notice Returns the array of position managers.
    function getPositionManagers() public view returns (IPositionManager[] memory _positionManagers) {
        _positionManagers = _getPositionManagers();
    }

    /// @notice Returns the array of netted positions.
    function getNettedPositions() public view returns (int256[2][2] memory _nettedPositions) {
        _nettedPositions = _getStorage().nettedPositions;
    }

    /// @notice Returns the array of active external positions.
    function getActiveExternalPosition() public view returns (int256 _activeExternalPosition) {
        _activeExternalPosition = _getStorage().externalPosition;
    }
}

/// @title AggregateVaultHelper
/// @author Umami Devs
/// @notice A contract that constains extended logic of the AggregateVault. Common storage layout is used with delegate calls.
contract AggregateVaultHelper is AggregateVaultStorage, AggregateVaultViews, BaseHandler, GlobalACL {
    constructor(Auth _auth) GlobalACL(_auth) { }

    /**
     * @notice Gets the current asset vault price per share (PPS)
     * @param _vault The address of the asset vault
     * @param isDeposit if the pricing is for a deposit or withdrawal
     * @param useLlo should use the LLO price
     * @return - The price per share of the asset vault
     */
    function getVaultPPS(address _vault, bool isDeposit, bool useLlo) external onlyDelegateCall returns (uint256) {
        VaultState memory vaultState = _getVaultState();
        uint256 index = vaultToAssetVaultIndex(_vault);
        if (vaultState.rebalanceOpen) return vaultState.rebalancePPS[index];

        AssetVaultStorage storage vault = _getStorage().vaults[index];
        uint256 vaultSupply = ERC20(vault.vault).totalSupply();
        uint256 decimals = _vaultDecimals(index);
        uint256 oneToken = 10 ** decimals;

        if (vaultSupply == 0) return oneToken;

        uint256 nativeTokenBalance = ERC20(vault.token).balanceOf(address(this));
        uint256 gmiUsd = useLlo ? _vaultGmiBalanceUsd(index) : _vaultGmiBalanceUsdChainlink(index); // 18 decimal

        uint256 vaultTokenPrice = useLlo ? _vaultTokenPrice(index) : _vaultTokenPriceChainlink(index);
        uint256 gmiToVaultToken = gmiUsd * 1e12 / vaultTokenPrice;

        uint256 positionMargin =
            _getAssetVaultHedgesInNativeToken(index, vaultTokenPrice.toInternalPrice(decimals), decimals);

        uint256 totalBalance = nativeTokenBalance + gmiToVaultToken + positionMargin;
        totalBalance -= _getPendingFees(vault, _getVaultState().lastRebalanceTime, totalBalance, vaultSupply);
        return isDeposit
            ? (totalBalance * oneToken + vaultSupply - 1) / vaultSupply
            : totalBalance * oneToken / vaultSupply;
    }

    /**
     * @notice Gets the current asset vault Total Value Locked (TVL)
     * @dev TVL of the vaults may not equal PPS * totalSupply due to precision loss
     * @param _vault The address of the asset vault
     * @param useLlo should use the LLO price
     * @return vaultTvl The total value locked in the asset vault
     */
    function getVaultTVL(address _vault, bool useLlo) external onlyDelegateCall returns (uint256 vaultTvl) {
        uint256 index = vaultToAssetVaultIndex(_vault);
        uint256 decimals = _vaultDecimals(index);

        if (_getStorage().vaultState.rebalanceOpen) {
            uint256 totalSupply = ERC20(_vault).totalSupply();
            return _getStorage().vaultState.rebalancePPS[index] * totalSupply / 10 ** decimals;
        }

        AssetVaultStorage storage vault = _getStorage().vaults[index];
        uint256 gmiUsd = useLlo ? _vaultGmiBalanceUsd(index) : _vaultGmiBalanceUsdChainlink(index); // 18 decimals

        uint256 vaultTokenPrice = useLlo ? _vaultTokenPrice(index) : _vaultTokenPriceChainlink(index);

        uint256 positionMargin =
            _getAssetVaultHedgesInNativeToken(index, vaultTokenPrice.toInternalPrice(decimals), decimals);

        uint256 gmiToVaultToken = gmiUsd * 1e12 / vaultTokenPrice;
        uint256 nativeTokenBalance = ERC20(vault.token).balanceOf(address(this));
        vaultTvl = nativeTokenBalance + gmiToVaultToken + positionMargin;
        vaultTvl -=
            _getPendingFees(vault, _getVaultState().lastRebalanceTime, vaultTvl, ERC20(vault.vault).totalSupply());
    }

    /**
     * @notice Gets the current asset vault price per share (PPS). This function can be used to
     * get the PPS according to an off chain price set.
     * @param _vault The address of the asset vault
     * @param isDeposit if the pricing is for a deposit or withdrawal
     * @param prices The prices of the markets in GMI. This array is ordered in the same sequence
     * as the GMI index assets. To get the ordering of prices call GMI.indexAssets()
     * @param max Should the max or min price be used.
     * @return - The price per share of the asset vault
     */
    function getVaultPPSWithPrices(address _vault, bool isDeposit, GmxStorage.MarketPrices[] memory prices, bool max)
        external
        onlyDelegateCall
        returns (uint256)
    {
        uint256 index = vaultToAssetVaultIndex(_vault);
        AssetVaultStorage storage vault = _getStorage().vaults[index];
        uint256 vaultSupply = ERC20(vault.vault).totalSupply();
        uint256 decimals = _vaultDecimals(index);
        uint256 oneToken = 10 ** decimals;
        if (vaultSupply == 0) return oneToken;
        uint256 gmiUsd;
        uint256 vaultTokenPrice;
        {
            uint256 ethPrice = max ? prices[0].longTokenPrice.max : prices[0].longTokenPrice.min;
            uint256 usdcPrice = max ? prices[0].shortTokenPrice.max : prices[0].shortTokenPrice.min;
            uint256 gmiPPS = GMI(_getStorage().gmi).pps(prices);
            uint256 gmiBalance = LibAggregateVaultUtils.getVaultGmiWithPrices(
                index,
                _getVaultState().epoch,
                gmiPPS,
                Solarray.int256s(usdcPrice.toInternalPrice(6).toInt256(), ethPrice.toInternalPrice(18).toInt256())
            );
            gmiUsd = gmiPPS * gmiBalance / 1e18;
            vaultTokenPrice = vault.token == TOKEN_USDC_NATIVE ? usdcPrice : ethPrice;
        }
        uint256 gmiToVaultToken = gmiUsd * 1e12 / vaultTokenPrice;
        uint256 positionMargin =
            _getAssetVaultHedgesInNativeToken(index, vaultTokenPrice.toInternalPrice(decimals), decimals);
        uint256 totalBalance = ERC20(vault.token).balanceOf(address(this)) + gmiToVaultToken + positionMargin;
        totalBalance -= _getPendingFees(vault, _getVaultState().lastRebalanceTime, totalBalance, vaultSupply);
        return isDeposit
            ? (totalBalance * oneToken + vaultSupply - 1) / vaultSupply
            : totalBalance * oneToken / vaultSupply;
    }

    /**
     * @notice Gets the current asset vault Total Value Locked (TVL). This function can be used to
     * get the TVL according to an off chain price set.
     * @dev TVL of the vaults may not equal PPS * totalSupply due to precision loss.
     * @param _vault The address of the asset vault
     * @param prices The prices of the markets in GMI. This array is ordered in the same sequence
     * as the GMI index assets. To get the ordering of prices call GMI.indexAssets()
     * @param max Should the max or min price be used.
     * @return tvlWithPrices The total value locked in the asset vault
     */
    function getVaultTVLWithPrices(address _vault, GmxStorage.MarketPrices[] memory prices, bool max)
        external
        onlyDelegateCall
        returns (uint256 tvlWithPrices)
    {
        uint256 index = vaultToAssetVaultIndex(_vault);
        uint256 decimals = _vaultDecimals(index);
        AssetVaultStorage storage vault = _getStorage().vaults[index];
        uint256 ethPrice = max ? prices[0].longTokenPrice.max : prices[0].longTokenPrice.min;
        uint256 usdcPrice = max ? prices[0].shortTokenPrice.max : prices[0].shortTokenPrice.min;
        uint256 gmiPPS = GMI(_getStorage().gmi).pps(prices);
        uint256 gmiBalance = LibAggregateVaultUtils.getVaultGmiWithPrices(
            index,
            _getVaultState().epoch,
            gmiPPS,
            Solarray.int256s(usdcPrice.toInternalPrice(6).toInt256(), ethPrice.toInternalPrice(18).toInt256())
        );
        uint256 gmiUsd = gmiPPS * gmiBalance / 1e18;
        uint256 vaultTokenPrice = vault.token == TOKEN_USDC_NATIVE ? usdcPrice : ethPrice;
        uint256 positionMargin =
            _getAssetVaultHedgesInNativeToken(index, vaultTokenPrice.toInternalPrice(decimals), decimals);

        uint256 gmiToVaultToken = gmiUsd * 1e12 / vaultTokenPrice;
        uint256 nativeTokenBalance = ERC20(vault.token).balanceOf(address(this));
        tvlWithPrices = nativeTokenBalance + gmiToVaultToken + positionMargin;
        tvlWithPrices -=
            _getPendingFees(vault, _getVaultState().lastRebalanceTime, tvlWithPrices, ERC20(vault.vault).totalSupply());
    }

    /**
     * @notice Gets the current GMI for all vaults
     * @return gmiAmounts An array containing the GMI for each vault
     */
    function getVaultGmi(uint256 currentEpoch, bool useLlo) public view returns (uint256[2] memory gmiAmounts) {
        return _getVaultsGmi(currentEpoch, useLlo);
    }

    /**
     * @notice Gets the current GMI in $ with 1e18 decimals for all vaults
     * @return - An array containing the GMI dollars for each vault
     */
    function getVaultsGmiValue(uint256 currentEpoch, bool useLlo)
        external
        view
        onlyDelegateCall
        returns (uint256[2] memory)
    {
        return _getVaultsGmiInUsd(currentEpoch, useLlo);
    }

    /**
     * @notice Gets the current GMI in $ with 1e18 decimals for all vaults using an off chain price
     * @param prices The prices of the markets in GMI. This array is ordered in the same sequence
     * as the GMI index assets. To get the ordering of prices call GMI.indexAssets()
     * @param max Should the max or min price be used.
     * @return gmiUsdAmounts An array containing the GMI dollars for each vault
     */
    function getVaultsGmiValueWithPrices(GmxStorage.MarketPrices[] memory prices, bool max)
        external
        view
        onlyDelegateCall
        returns (uint256[2] memory gmiUsdAmounts)
    {
        uint256 currentEpoch = _getVaultState().epoch;
        uint256 ethPrice = max ? prices[0].longTokenPrice.max : prices[0].longTokenPrice.min;
        uint256 usdcPrice = max ? prices[0].shortTokenPrice.max : prices[0].shortTokenPrice.min;
        uint256 gmiPPS = GMI(_getStorage().gmi).pps(prices);
        gmiUsdAmounts = [
            LibAggregateVaultUtils.getVaultGmiWithPrices(
                0,
                currentEpoch,
                gmiPPS,
                Solarray.int256s(usdcPrice.toInternalPrice(6).toInt256(), ethPrice.toInternalPrice(18).toInt256())
            ),
            LibAggregateVaultUtils.getVaultGmiWithPrices(
                1,
                currentEpoch,
                gmiPPS,
                Solarray.int256s(usdcPrice.toInternalPrice(6).toInt256(), ethPrice.toInternalPrice(18).toInt256())
            )
        ];
        gmiUsdAmounts[0] = gmiUsdAmounts[0] * gmiPPS / 1e18;
        gmiUsdAmounts[1] = gmiUsdAmounts[1] * gmiPPS / 1e18;
    }

    // CYCLE
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Cycles the vaults, this settles internal position pnl,
     * and rebalances GMI held by each vault to the target amounts set in `openRebalancePeriod(...)`
     * @param shouldRebalanceGmi Whether the GMI amounts should be rebalanced this cycle. Flag set in keeper
     */
    function cycle(bool shouldRebalanceGmi)
        external
        onlyDelegateCall
        returns (LibCycle.GMIMintRequest[2] memory, LibCycle.GMIBurnRequest[2] memory)
    {
        AVStorage storage stg = _getStorage();
        require(stg.vaultState.rebalanceOpen, "!rebalanceOpen");
        stg.isAboveWatermark[0] = stg.vaultState.rebalancePPS[0] > stg.vaults[0].feeWatermarkPPS ? true : false;
        stg.isAboveWatermark[1] = stg.vaultState.rebalancePPS[1] > stg.vaults[1].feeWatermarkPPS ? true : false;
        return LibCycle.cycle(shouldRebalanceGmi);
    }

    /**
     * @notice Fulfills the requests made in `cycle(...)`. This is called after the GMX keeper has executed requests
     */
    function fulfilRequests() external onlyDelegateCall {
        require(getVaultState().rebalanceOpen, "!rebalanceOpen");
        LibCycle.fulfilRequests();
    }

    /// @notice for setting the Gmi Attribution via config to recover
    function setVaultGmiAttribution(uint256[2] memory _gmiAttribution) external onlyDelegateCall onlyConfigurator {
        _getStorage().vaultGmiAttribution = _gmiAttribution;
    }

    /// @notice for setting the last netted prices via config to recover
    function setLastNettedPrices(uint256 epoch, int256[2] memory _nettedPrices)
        external
        onlyDelegateCall
        onlyConfigurator
    {
        _getStorage().lastNettedPrices[epoch] = _nettedPrices;
    }

    /// @notice for setting the epoch via config to recover
    function setEpoch(uint256 epoch) external onlyDelegateCall onlyConfigurator {
        _getStorage().vaultState.epoch = epoch;
    }

    /// @notice to clear stale requests
    function clearMintBurnRequests(uint256 start, uint256 end) external onlyDelegateCall onlyConfigurator {
        for (uint256 i = start; i <= end; i++) {
            LibCycle.clearMintBurnRequestForEpoch(i);
        }
    }

    /// @notice set slippage tolerance for swaps
    function setSwapSlippageTolerance(uint256 _slippage) external onlyDelegateCall onlyConfigurator {
        _getStorage().swapSlippage = _slippage;
    }

    function pullKeeperFees() external onlyDelegateCall {
        FeeReserve(getVaultState().depositFeeEscrow).pullKeeperFees();
    }

    // INTERNAL GETTERS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Get the total pending rebalance fees for the vault
     * @param vault the underlying vault token address.
     * @param lastRebalanceTime time the vaults last rebalanced.
     * @param currentBalance current balance of the vault.
     * @param vaultSupply total supply of the vault token.
     * @return totalVaultFee the total pending vault fees.
     */
    function _getPendingFees(
        AssetVaultStorage memory vault,
        uint256 lastRebalanceTime,
        uint256 currentBalance,
        uint256 vaultSupply
    ) internal returns (uint256 totalVaultFee) {
        VaultFees memory vaultFees = _getVaultFees();
        uint256 percentYear = lastRebalanceTime == 0 ? 0 : 1e18 * (block.timestamp - lastRebalanceTime) / YEAR;
        (bytes memory ret) = _getStorage().feeHelper.delegateCall(
            abi.encodeCall(
                IVaultFees._getVaultRebalanceFees,
                (
                    currentBalance,
                    _getStorage().isAboveWatermark[vault.token == TOKEN_USDC_NATIVE ? 0 : 1],
                    vaultFees.performanceFee * percentYear / 1e18,
                    vaultFees.managementFee * percentYear / 1e18
                )
            )
        );
        (,, totalVaultFee) = abi.decode(ret, (uint256, uint256, uint256));
    }

    /**
     * @notice Get the total value locked (TVL) for a specific AssetVaultEntry.
     * @param _assetVault The AssetVaultEntry to get the TVL for.
     * @param _useLlo Should use chainlink llo.
     * @return _totalTvl The total TVL for the AssetVaultEntry.
     * @return _bufferTvl The TVL held in the buffer for the AssetVaultEntry.
     * @return _gmiTvl The TVL held in the glp for the AssetVaultEntry.
     * @return _hedgesTvl The TVL held in hedges for the AssetVaultEntry.
     */
    function _getAssetVaultTvl(AssetVaultStorage storage _assetVault, bool _useLlo)
        internal
        returns (uint256 _totalTvl, uint256 _bufferTvl, uint256 _gmiTvl, uint256 _hedgesTvl)
    {
        uint256 index = vaultToAssetVaultIndex(_assetVault.vault);
        _bufferTvl = ERC20(_assetVault.token).balanceOf(address(this));
        uint256 vaultTokenPrice = _useLlo ? _vaultTokenPrice(index) : _vaultTokenPriceChainlink(index);
        uint256 decimals = _vaultDecimals(index);
        _gmiTvl = _useLlo ? _vaultGmiBalanceUsd(index) : _vaultGmiBalanceUsdChainlink(index); // 18 decimals
        _gmiTvl = _gmiTvl * 1e12 / vaultTokenPrice;

        _hedgesTvl = _getAssetVaultHedgesInNativeToken(index, vaultTokenPrice.toInternalPrice(decimals), decimals);
        _totalTvl = _bufferTvl + _gmiTvl + _hedgesTvl;
    }

    /**
     * @notice Get the hedges value in native token for a specific vault index.
     * @param _vaultIdx The index of the vault to get the hedges value for.
     * @return _hedgesToken The hedges value in native token for the specified vault index.
     */
    function _getAssetVaultHedgesInNativeToken(uint256 _vaultIdx, uint256 tokenPrice, uint256 tokenDecimals)
        internal
        returns (uint256 _hedgesToken)
    {
        uint256 hedgesUsd = _getAssetVaultHedgeInUsd(_vaultIdx);
        _hedgesToken = (hedgesUsd * (10 ** tokenDecimals)) / tokenPrice;
    }

    /**
     * @notice Get the hedges value in USD for a specific vault index.
     * @param _vaultIdx The index of the vault to get the hedges value for.
     * @return _hedgesUsd The hedges value in USD for the specified vault index.
     */
    function _getAssetVaultHedgeInUsd(uint256 _vaultIdx) internal returns (uint256 _hedgesUsd) {
        AVStorage storage stg = _getStorage();
        uint256 positionMargin;

        /// @dev here we assume all margin belongs to one vault
        if (stg.externalPosition > 0 && _vaultIdx == 0) {
            (positionMargin,) = _getTotalMargin(TOKEN_WETH);
            return positionMargin * 1e18 / 1e30;
        } else if (stg.externalPosition < 0 && _vaultIdx == 1) {
            (positionMargin,) = _getTotalMargin(TOKEN_WETH);
            return positionMargin * 1e18 / 1e30;
        } else {
            return 0;
        }
    }

    /**
     * @notice Get the total margin value for a specific token.
     * @param _token The address of the token to get the total margin value for.
     * @return _totalMargin The total margin value for the specified token.
     */
    function _getTotalMargin(address _token) internal returns (uint256 _totalMargin, bool _isLong) {
        IPositionManager[] storage positionManagers = _getPositionManagers();
        uint256 length = positionManagers.length;

        bool unset = true;
        _isLong = false;

        for (uint256 i = 0; i < length; ++i) {
            bytes memory ret =
                address(positionManagers[i]).delegateCall(abi.encodeWithSignature("positionMargin(address)", _token));
            (uint256 margin, bool isLong_) = abi.decode(ret, (uint256, bool));
            if (margin > 0) {
                if (unset) {
                    _isLong = isLong_;
                    unset = false;
                } else {
                    require(_isLong == isLong_, "AggregateVaultHelper: mixed long/short");
                }
            }
            _totalMargin += margin;
        }
    }

    /**
     * @notice Get the total notional value for a specific token.
     * @param _token The address of the token to get the total notional value for.
     * @return _totalNotional The total notional value for the specified token.
     */
    function getTotalNotional(address _token) public returns (uint256 _totalNotional, bool _isLong) {
        IPositionManager[] storage positionManagers = _getPositionManagers();
        uint256 length = positionManagers.length;

        bool unset = true;
        _isLong = false;

        for (uint256 i = 0; i < length; ++i) {
            bytes memory ret =
                address(positionManagers[i]).delegateCall(abi.encodeWithSignature("positionNotional(address)", _token));
            (uint256 notional, bool isLong_) = abi.decode(ret, (uint256, bool));
            if (notional > 0) {
                if (unset) {
                    _isLong = isLong_;
                    unset = false;
                } else {
                    require(_isLong == isLong_, "AggregateVaultHelper: mixed long/short");
                }
            }

            _totalNotional += notional;
        }
    }

    /// @dev calls the library logic to get the gmi in dollars held by vaults, uses the LLO
    function _vaultGmiBalanceUsd(uint256 _idx) internal view returns (uint256) {
        uint256 pps = Pricing.getIndexPps(_getStorage().oracleWrapper, GMI(_getStorage().gmi));
        uint256 gmiBalance = LibAggregateVaultUtils.getVaultGmi(_idx, _getVaultState().epoch, true);
        return pps * gmiBalance / 1e18;
    }

    /// @dev calls the library logic to get the gmi in dollars held by vaults, uses the onchain prices
    function _vaultGmiBalanceUsdChainlink(uint256 _idx) internal view returns (uint256) {
        uint256 pps = Pricing.getIndexPpsChainlink(_getStorage().oracleWrapper, GMI(_getStorage().gmi));
        uint256 gmiBalance = LibAggregateVaultUtils.getVaultGmi(_idx, _getVaultState().epoch, false);
        return pps * gmiBalance / 1e18;
    }

    /**
     * @notice Calculates the GMI amount owned by a vault in USD at a given epoch.
     * @param currentEpoch The epoch number.
     * @param useLlo Should use chainlink llo.
     * @return gmiUsdAmounts The amount of GMI in usd owned by the vault.
     */
    function _getVaultsGmiInUsd(uint256 currentEpoch, bool useLlo)
        internal
        view
        returns (uint256[2] memory gmiUsdAmounts)
    {
        gmiUsdAmounts = [
            LibAggregateVaultUtils.getVaultGmi(0, currentEpoch, useLlo),
            LibAggregateVaultUtils.getVaultGmi(1, currentEpoch, useLlo)
        ];
        uint256 pps = useLlo
            ? Pricing.getIndexPps(_getStorage().oracleWrapper, GMI(_getStorage().gmi))
            : Pricing.getIndexPpsChainlink(_getStorage().oracleWrapper, GMI(_getStorage().gmi));
        gmiUsdAmounts[0] = gmiUsdAmounts[0] * pps / 1e18;
        gmiUsdAmounts[1] = gmiUsdAmounts[1] * pps / 1e18;
    }

    /**
     * @notice Calculates the GMI amount owned by a vault at a given epoch.
     * @param currentEpoch The epoch number.
     * @param useLlo Should use chainlink llo.
     * @return gmiAmounts The amount of GLP owned by the vault.
     */
    function _getVaultsGmi(uint256 currentEpoch, bool useLlo) internal view returns (uint256[2] memory gmiAmounts) {
        return LibAggregateVaultUtils.getVaultsGmi(currentEpoch, useLlo);
    }

    /// @notice gets the vault token price from the vault index
    function _vaultTokenPrice(uint256 _idx) internal view returns (uint256) {
        address token = _getStorage().vaults[_idx].token;
        address oracle = _getStorage().oracleWrapper;

        if (token == TOKEN_USDC_NATIVE) {
            return OracleWrapper(oracle).getChainlinkPrice(token);
        } else {
            return OracleWrapper(oracle).getLloPriceWithinL1Blocks(token);
        }
    }

    /// @notice gets the vault token price from the vault index, using the onchain price
    function _vaultTokenPriceChainlink(uint256 _idx) internal view returns (uint256) {
        address token = _getStorage().vaults[_idx].token;
        address oracle = _getStorage().oracleWrapper;
        return OracleWrapper(oracle).getChainlinkPrice(token);
    }

    /// @notice gets the vault token decimals
    function _vaultDecimals(uint256 _idx) internal view returns (uint256) {
        address token = _getStorage().vaults[_idx].token;
        return token == TOKEN_USDC_NATIVE ? 6 : 18;
    }

    /// @dev for callbacks
    function callbackSigs() external pure returns (bytes4[] memory) {
        bytes4[] memory sigs = new bytes4[](0);
        return sigs;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Delegatecall } from "../libraries/Delegatecall.sol";
import { IHookExecutor, HookType } from "../interfaces/IHookExecutor.sol";
import { IPositionManager } from "../interfaces/IPositionManager.sol";
import { IArbSys } from "../interfaces/IArbSys.sol";
import { ARBSYS } from "../constants.sol";

bytes32 constant STORAGE_SLOT = keccak256("AggregateVault.storage");

/// @title LibAggregateVaultStorage
/// @author Umami Devs
/// @notice Library for some storage logic
library LibAggregateVaultStorage {
    function getStorage() internal pure returns (AggregateVaultStorage.AVStorage storage _storage) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            _storage.slot := slot
        }
    }

    function getTokenToAssetVaultIndex()
        internal
        view
        returns (mapping(address => uint256) storage _tokenToAssetVaultIndex)
    {
        _tokenToAssetVaultIndex = getStorage().tokenToAssetVaultIndex;
    }

    /**
     * @dev Retrieves the vault state from storage.
     * @return _vaultState The current vault state.
     */
    function getVaultState() internal view returns (AggregateVaultStorage.VaultState storage _vaultState) {
        _vaultState = getStorage().vaultState;
    }

    /**
     * @dev Retrieves the current rebalance state from storage.
     * @return _rebalanceState The current rebalance state.
     */
    function getRebalanceState() internal view returns (AggregateVaultStorage.RebalanceState storage _rebalanceState) {
        _rebalanceState = getStorage().rebalanceState;
    }

    function getEmitter() internal view returns (address _emitter) {
        _emitter = getStorage().emitter;
    }
}

/// @title AggregateVaultStorage
/// @author Umami Devs
/// @notice Storage inheritance for AggregateVault
abstract contract AggregateVaultStorage {
    error InvalidAsset();

    enum CallType {
        Call,
        DelegateCall
    }

    struct AssetVaultStorage {
        // size 8
        address vault; // 0
        address token; // 1
        address timelockYieldBoost; // 2
        uint256 feeWatermarkPPS; // 3
        uint256 feeWatermarkDate; // 4
        int256 epochDelta; // 5
        uint256 lastCheckpointTvl; // 6
        uint256 timelockBoostPercent; // 7
    }

    struct SetPricesParams {
        address[] realtimeFeedTokens;
        bytes[] realtimeFeedData;
    }

    struct RebalanceState {
        // size 6
        uint256[2] indexAllocation; // 0
        uint256[2] indexComposition; // 2
        int256 externalPosition; // 4
        uint256 epoch; // 5
    }

    struct VaultState {
        // size 12
        uint256 epoch; // 0
        bool rebalanceOpen; // 1
        uint256 lastRebalanceTime; // 2
        address feeRecipient; // 3
        address depositFeeEscrow; // 4
        address withdrawalFeeEscrow; // 5
        uint256[2] indexAllocation; // 6
        uint256[2] vaultCaps; // 8
        uint256[2] rebalancePPS; // 10
    }

    struct VaultFees {
        // size 4
        uint256 performanceFee; // 0
        uint256 managementFee; // 1
        uint256 withdrawalFee; // 2
        uint256 depositFee; // 3
    }

    /// @dev open close request
    struct OCRequest {
        address sender;
        address account;
        address vault;
        address callback;
        bool isDeposit;
        uint256 amount;
        uint256 minOut;
        uint256 requestBlock;
    }

    struct AVStorage {
        /// @dev vault state
        VaultState vaultState; // 0-11
        /// @notice The array of asset vault entries.
        AssetVaultStorage[2] vaults; // 12-19, 19-26
        /// @dev vault fee storage
        VaultFees vaultFees; // 27-30
        /// @notice The mapping of token addresses to asset vault indices.
        mapping(address => uint256) tokenToAssetVaultIndex; // 31
        /// @notice The mapping of vault indices to asset vault indices.
        mapping(address => uint256) vaultToAssetVaultIndex; // 32
        /// @notice The current rebalance state.
        RebalanceState rebalanceState; // 33-39
        /// @dev |.....||depositHook|withdrawHook|openHook|closeHook|
        bytes32 hooksConfig; // 40
        address hookHandler; // 41
        /// @dev event emitter
        address emitter;
        uint256 requestNonce;
        /// @notice The array of position manager contracts.
        IPositionManager[] positionManagers; // 44
        /// @dev active external position size
        int256 externalPosition; // 45
        /// @dev the vault netted positions
        int256[2][2] nettedPositions; // 46-49
        /// @dev open/close request storage: nonce => request
        mapping(uint256 => OCRequest) pendingRequests; // 50
        /// @dev execution keeper address for gas rebates
        address rebalanceKeeper; // 51
        /// @dev fee logic
        address feeHelper; // 52
        /// @dev execution amount for regular request
        uint256 executionGasAmount; // 53
        /// @dev execution amount for callback request
        uint256 executionGasAmountCallback; // 54
        /// @notice Maps epoch IDs to the last netted prices.
        mapping(uint256 => int256[2]) lastNettedPrices; // 55
        /// @notice The zero sum PnL threshold value.
        uint256 zeroSumPnlThreshold;
        /// @dev block tolerance for acceptable LLO price
        uint8 L1BlockTolerance;
        /// @notice Flag to indicate whether netting should be checked.
        bool shouldCheckNetting; // 57
        /// @notice The netted threshold value.
        uint256 nettedThreshold;
        /// @notice oracle contract.
        address oracleWrapper;
        uint256[2] vaultGmiAttribution; // USDC, ETH
        /// @notice GMI index
        address payable gmi;
        /// @notice Active helper contract
        address aggregateVaultHelper;
        /// @notice active GMX V2 handler contract
        address gmxV2Handler;
        /// @notice Active request handler
        address requestHandler;
        /// @notice If the GMX fee logic should be used on deposit/withdrawal
        bool shouldUseGmxFee;
        /// @notice UNIV3 swap manager
        address uniswapV3SwapManager;
        /// @notice Slippage param for uniswap
        uint256 swapSlippage;
        /// @notice if the last pps was above watermark
        bool[2] isAboveWatermark;
    }

    /**
     * @dev Retrieves the storage struct of the contract.
     * @return _storage The storage struct containing all contract state variables.
     */
    function _getStorage() internal pure returns (AVStorage storage _storage) {
        _storage = LibAggregateVaultStorage.getStorage();
    }

    /**
     * @dev Retrieves the vault state from storage.
     * @return _vaultState The current vault state.
     */
    function _getVaultState() internal view returns (VaultState storage _vaultState) {
        _vaultState = _getStorage().vaultState;
    }

    function _getEmitter() internal view returns (address _emitter) {
        _emitter = _getStorage().emitter;
    }

    function _getRequestHandler() internal view returns (address _rhandler) {
        _rhandler = _getStorage().requestHandler;
    }

    function _getOracleWrapper() internal view returns (address) {
        return _getStorage().oracleWrapper;
    }

    function _getGmxV2Handler() internal view returns (address) {
        return _getStorage().gmxV2Handler;
    }

    function _getShouldUseGmxFee() internal view returns (bool) {
        return _getStorage().shouldUseGmxFee;
    }

    function _getL1BlockTolerance() internal view returns (uint8) {
        return _getStorage().L1BlockTolerance;
    }

    /**
     * @dev Retrieves the vault entries array from storage.
     * @return vaults The array of asset vault entries.
     */
    function _getAssetVaultEntries() internal view returns (AssetVaultStorage[2] storage) {
        return _getStorage().vaults;
    }

    /**
     * @dev Sets the rebalance keeper in storage.
     */
    function _setL1BlockTolerance(uint8 newTolerance) internal {
        _getStorage().L1BlockTolerance = newTolerance;
    }

    /**
     * @dev Sets the rebalance keeper in storage.
     */
    function _setRebalanceKeeper(address newKeeper) internal {
        _getStorage().rebalanceKeeper = newKeeper;
    }

    /**
     * @dev Retrieves the current rebalance state from storage.
     * @return _rebalanceState The current rebalance state.
     */
    function _getRebalanceState() internal view returns (RebalanceState storage _rebalanceState) {
        _rebalanceState = _getStorage().rebalanceState;
    }

    /**
     * @dev Retrieves the netted threshold from storage.
     * @return _nettedThreshold The current netted threshold value.
     */
    function _getNettedThreshold() internal view returns (uint256 _nettedThreshold) {
        _nettedThreshold = _getStorage().nettedThreshold;
    }

    /**
     * @dev Retrieves the array of position managers from storage.
     * @return _positionManagers The array of position managers.
     */
    function _getPositionManagers() internal view returns (IPositionManager[] storage _positionManagers) {
        _positionManagers = _getStorage().positionManagers;
    }

    /**
     * @dev Retrieves the vault to asset vault index mapping from storage.
     * @return _vaultToAssetVaultIndex The mapping of vault addresses to asset vault indexes.
     */
    function _getVaultToAssetVaultIndex()
        internal
        view
        returns (mapping(address => uint256) storage _vaultToAssetVaultIndex)
    {
        _vaultToAssetVaultIndex = _getStorage().vaultToAssetVaultIndex;
    }

    /**
     * @dev Retrieves the token to asset vault index mapping from storage.
     * @return _tokenToAssetVaultIndex The mapping of token addresses to asset vault indexes.
     */
    function _getTokenToAssetVaultIndex()
        internal
        view
        returns (mapping(address => uint256) storage _tokenToAssetVaultIndex)
    {
        _tokenToAssetVaultIndex = _getStorage().tokenToAssetVaultIndex;
    }

    /**
     * @dev Retrieves the netted positions matrix from storage.
     * @return _nettedPositions The matrix of netted positions.
     */
    function _getNettedPositions() internal view returns (int256[2][2] storage _nettedPositions) {
        _nettedPositions = _getStorage().nettedPositions;
    }

    /**
     * @dev Retrieves the netted prices at epoch.
     * @return _nettedPrices The array of netted prices.
     */
    function _getNettedPrices(uint256 epoch) internal view returns (int256[2] storage _nettedPrices) {
        _nettedPrices = _getStorage().lastNettedPrices[epoch];
    }

    /**
     * @dev Retrieves the zero sum PnL threshold from storage.
     * @return _zeroSumPnlThreshold The current zero sum PnL threshold value.
     */
    function _getZeroSumPnlThreshold() internal view returns (uint256 _zeroSumPnlThreshold) {
        _zeroSumPnlThreshold = _getStorage().zeroSumPnlThreshold;
    }

    /**
     * @dev Retrieves the external position from storage.
     * @return _extenralPosition The positions.
     */
    function _getExternalPosition() internal view returns (int256 _extenralPosition) {
        _extenralPosition = _getStorage().externalPosition;
    }

    /**
     * @dev Retrieves the fee helper from storage.
     * @return _feeHelper The current fee helper.
     */
    function _getFeeHelper() internal view returns (address _feeHelper) {
        _feeHelper = _getStorage().feeHelper;
    }

    /**
     * @dev Retrieves the vault fees struct from storage.
     * @return _vaultFees The current vault fees.
     */
    function _getVaultFees() internal view returns (VaultFees storage _vaultFees) {
        _vaultFees = _getStorage().vaultFees;
    }

    /**
     * @dev Retrieves the asset vault entry for the given asset address.
     * @param asset The asset address for which to retrieve the vault entry.
     * @return vault The asset vault entry for the given asset address.
     */
    function _getVaultFromAsset(address asset) internal view returns (AssetVaultStorage storage vault) {
        AssetVaultStorage[2] storage vaults = _getAssetVaultEntries();
        if (vaults[0].token == asset) {
            return vaults[0];
        } else if (vaults[1].token == asset) {
            return vaults[1];
        } else {
            revert InvalidAsset();
        }
    }

    /**
     * @dev Sets the netted positions matrix in storage.
     * @param _nettedPositions The updated netted positions matrix.
     */
    function _setPositions(int256[2][2] memory _nettedPositions, int256 _externalPosition) internal {
        int256[2][2] storage nettedPositions = _getNettedPositions();
        _getStorage().externalPosition = _externalPosition;
        nettedPositions[0][0] = _nettedPositions[0][0];
        nettedPositions[0][1] = _nettedPositions[0][1];
        nettedPositions[1][0] = _nettedPositions[1][0];
        nettedPositions[1][1] = _nettedPositions[1][1];
    }

    /**
     * @dev Sets the vault GMI attribution array in storage.
     * @param vaultGmiAttribution The updated vault GMI attribution array.
     */
    function _setVaultGmiAttribution(uint256[2] memory vaultGmiAttribution) internal {
        uint256[2] storage gmiAttribution = _getStorage().vaultGmiAttribution;
        gmiAttribution[0] = vaultGmiAttribution[0];
        gmiAttribution[1] = vaultGmiAttribution[1];
    }

    /**
     * @notice Get the AssetVaultEntry at the given index.
     * @param _idx The index of the AssetVaultEntry.
     * @return _assetVault The AssetVaultEntry at the given index.
     */
    function _getAssetVaultEntry(uint256 _idx) internal view returns (AssetVaultStorage storage _assetVault) {
        _assetVault = _getAssetVaultEntries()[_idx];
    }

    // HOOKS
    // ------------------------------------------------------------------------

    function _isHookEnabledMask(HookType _type) internal pure returns (uint256) {
        uint256 hookNum = uint256(_type);
        return 1 << ((hookNum * 2) + 1);
    }

    function _hookCallTypeMask(HookType _type) internal pure returns (uint256) {
        uint256 hookNum = uint256(_type);
        return 1 << (hookNum * 2);
    }

    function _getHook(HookType _type) internal view returns (bool _isEnabled, bool _isDelegateHook) {
        bytes32 config = _getStorage().hooksConfig;
        uint256 isEnabledMask = _isHookEnabledMask(_type);
        uint256 callTypeMask = _hookCallTypeMask(_type);
        _isEnabled = (uint256(config) & isEnabledMask) != 0;
        _isDelegateHook = (uint256(config) & callTypeMask) != 0;
    }

    function _enableHook(HookType _type, CallType _callType) internal {
        bytes32 config = _getStorage().hooksConfig;
        uint256 isEnabledMask = _isHookEnabledMask(_type);
        uint256 callTypeMask = _hookCallTypeMask(_type);
        // cleared
        config = bytes32(uint256(config) & ~(isEnabledMask | callTypeMask));
        // set
        config = bytes32(uint256(config) | isEnabledMask | (_callType == CallType.DelegateCall ? callTypeMask : 0));
        _getStorage().hooksConfig = config;
    }

    function _disableHook(HookType _type) internal {
        bytes32 config = _getStorage().hooksConfig;
        uint256 isEnabledMask = _isHookEnabledMask(_type);
        uint256 callTypeMask = _hookCallTypeMask(_type);
        config = bytes32(uint256(config) & ~(isEnabledMask | callTypeMask));
        _getStorage().hooksConfig = config;
    }

    function _executeHook(HookType _hookType, bytes memory _cd) internal returns (bytes memory) {
        (bool isEnabled, bool isDelegateHook) = _getHook(_hookType);
        if (isEnabled) {
            address hookHandler = _getStorage().hookHandler;
            bytes memory hcd = abi.encodeCall(IHookExecutor.executeHook, (_hookType, _cd));

            if (isDelegateHook) {
                return Delegatecall.delegateCall(hookHandler, hcd);
            } else {
                (bool success, bytes memory ret) = hookHandler.call(hcd);
                if (!success) {
                    assembly {
                        let length := mload(ret)
                        let start := add(ret, 0x20)
                        revert(start, length)
                    }
                }
                return ret;
            }
        }
        return hex"";
    }

    function _getBlockNumber() internal view returns (uint256 _blockNumber) {
        _blockNumber = IArbSys(ARBSYS).arbBlockNumber();
    }

    // REQUESTS
    // ------------------------------------------------------------------------

    function _saveRequest(
        address sender,
        address account,
        address vault,
        address callback,
        bool isDeposit,
        uint256 amount,
        uint256 minOut
    ) internal returns (uint256 requestNonce) {
        AVStorage storage stg = _getStorage();
        stg.pendingRequests[++stg.requestNonce] = OCRequest({
            sender: sender,
            account: account,
            vault: vault,
            callback: callback,
            isDeposit: isDeposit,
            amount: amount,
            minOut: minOut,
            requestBlock: _getBlockNumber()
        });
        return stg.requestNonce;
    }

    function _getRequest(uint256 key) internal view returns (OCRequest memory order) {
        AVStorage storage stg = _getStorage();
        order = stg.pendingRequests[key];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IHandlerContract } from "./interfaces/IHandlerContract.sol";
import { ISwapManager } from "./interfaces/ISwapManager.sol";
import { PositionManagerRouter } from "./position-managers/PositionManagerRouter.sol";

/**
 * @title BaseHandler
 * @author Umami DAO
 * @notice Abstract base contract for implementing handler contracts with a delegate call restriction.
 * @dev Any contract inheriting from this contract must implement the IHandlerContract interface.
 */
abstract contract BaseHandler is IHandlerContract {
    address immutable SELF;

    error OnlyDelegateCall();

    constructor() {
        SELF = address(this);
    }

    /**
     * @notice Executes a token swap using the provided SwapManager instance.
     * @param _swapManager The SwapManager instance to use for the swap.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountIn The input amount to swap.
     * @param _minOut The minimum output amount required for the swap.
     * @param _data Additional data for the swap.
     * @return _amountOut The output amount received from the swap.
     */
    function _executeSwap(
        ISwapManager _swapManager,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minOut,
        bytes memory _data
    ) internal returns (uint256 _amountOut) {
        _amountOut = PositionManagerRouter(payable(address(this))).executeSwap(
            _swapManager, _tokenIn, _tokenOut, _amountIn, _minOut, _data
        );
    }

    /**
     * @notice Modifier to restrict functions to be called only via delegate call.
     * @dev Reverts if the function is called directly (not via delegate call).
     */
    modifier onlyDelegateCall() {
        if (address(this) == SELF) {
            revert OnlyDelegateCall();
        }
        _;
    }
}

import { GmxStorage } from "../libraries/GmxStorage.sol";

interface IGMI {
    function INDEX_SIZE() external view returns (uint256);
    function indexAssets() external view returns (address[] memory);
    function tvl(GmxStorage.MarketPrices[] memory prices) external view returns (uint256);
    function pps(GmxStorage.MarketPrices[] memory prices) external view returns (uint256);
    function previewMint(uint256 shares, address asset, GmxStorage.MarketPrices[] memory prices)
        external
        view
        returns (uint256[] memory);
    function redeem(uint256 shares, address receiver, address owner, GmxStorage.MarketPrices[] memory prices)
        external
        returns (uint256[] memory assets);
    function deposit(uint256[] memory assets, GmxStorage.MarketPrices[] memory prices, address receiver)
        external
        returns (uint256 shares);
    function sharesToMarketTokens(uint256 shares, GmxStorage.MarketPrices[] memory prices)
        external
        view
        returns (uint256[] memory);
    function getWeights() external view returns (uint256[] memory);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

interface IGMIWithERC20 is IGMI, IERC20 { }

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IFeeEscrow {
    function pullFeesAndVest(uint256[2] memory _feeAmounts, address keeper, uint256 keeperBps) external;

    function setVaultReturnBips(uint256 _newBips) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { OracleWrapper } from "../peripheral/OracleWrapper.sol";
import { IGMIWithERC20 as GMI } from "../interfaces/IGMI.sol";
import { GmxStorage } from "./GmxStorage.sol";
import { PriceCast } from "./PriceCast.sol";
import { MarketUtils, DataStore, Market } from "@gmx/market/MarketUtils.sol";
import { TOKEN_WETH, TOKEN_USDC_NATIVE, GMX_V2_DATA_STORE } from "../constants.sol";

/// @title GMPricing
/// @author Umami Devs
library GMPricing {
    function getMarketPrice(address _oracle, address _gm, bool _useLlo)
        internal
        view
        returns (GmxStorage.MarketPrices memory)
    {
        uint256 ethPrice = getTokenPrice(_oracle, TOKEN_WETH, _useLlo);
        uint256 usdcPrice = OracleWrapper(_oracle).getChainlinkPrice(TOKEN_USDC_NATIVE);

        return getMarketPrice(_oracle, _gm, ethPrice, usdcPrice, _useLlo);
    }

    function getMarketPrice(address _oracle, address _gm, uint256 _ethPrice, uint256 _usdcPrice, bool _useLlo)
        internal
        view
        returns (GmxStorage.MarketPrices memory marketPrice)
    {
        address indexToken = MarketUtils.getEnabledMarket(DataStore(GMX_V2_DATA_STORE), _gm).indexToken;
        marketPrice.longTokenPrice = GmxStorage.Price({ min: _ethPrice, max: _ethPrice });
        marketPrice.shortTokenPrice = GmxStorage.Price({ min: _usdcPrice, max: _usdcPrice });
        uint256 indexTokenPrice = getTokenPrice(_oracle, indexToken, _useLlo);
        marketPrice.indexTokenPrice = GmxStorage.Price({ min: indexTokenPrice, max: indexTokenPrice });
    }

    function getTokenPrice(address _oracle, address _token, bool _withLlo) internal view returns (uint256) {
        return _withLlo
            ? OracleWrapper(_oracle).getLloPriceWithinL1Blocks(_token)
            : OracleWrapper(_oracle).getChainlinkPrice(_token);
    }
}

/// @title Pricing
/// @author Umami Devs
library Pricing {
    function getMarketPrices(address _oracle, GMI _gmi, bool _useLlo)
        internal
        view
        returns (GmxStorage.MarketPrices[] memory marketPrices)
    {
        uint256 indexSize = _gmi.INDEX_SIZE();
        marketPrices = new GmxStorage.MarketPrices[](indexSize);
        address[] memory marketTokens = _gmi.indexAssets();
        uint256 ethPrice = getTokenPrice(_oracle, TOKEN_WETH, _useLlo);
        uint256 usdcPrice = OracleWrapper(_oracle).getChainlinkPrice(TOKEN_USDC_NATIVE);
        for (uint256 i = 0; i < indexSize; i++) {
            marketPrices[i] = getMarketPrice(_oracle, marketTokens[i], ethPrice, usdcPrice, _useLlo);
        }
        return marketPrices;
    }

    function getIndexTvl(address _oracle, GMI _gmi) internal view returns (uint256) {
        return _gmi.tvl(getMarketPrices(_oracle, _gmi, true));
    }

    function getIndexTvlChainlink(address _oracle, GMI _gmi) internal view returns (uint256) {
        return _gmi.tvl(getMarketPrices(_oracle, _gmi, false));
    }

    function getIndexPps(address _oracle, GMI _gmi) internal view returns (uint256) {
        return _gmi.pps(getMarketPrices(_oracle, _gmi, true));
    }

    function getIndexPpsChainlink(address _oracle, GMI _gmi) internal view returns (uint256) {
        return _gmi.pps(getMarketPrices(_oracle, _gmi, false));
    }

    function getMarketPrice(address _oracle, address _gm, bool _useLlo)
        internal
        view
        returns (GmxStorage.MarketPrices memory)
    {
        return GMPricing.getMarketPrice(_oracle, _gm, _useLlo);
    }

    function getMarketPrice(address _oracle, address _gm, uint256 _ethPrice, uint256 _usdcPrice, bool _useLlo)
        internal
        view
        returns (GmxStorage.MarketPrices memory marketPrice)
    {
        return GMPricing.getMarketPrice(_oracle, _gm, _ethPrice, _usdcPrice, _useLlo);
    }

    function getTokenPrice(address _oracle, address _token, bool _withLlo) internal view returns (uint256) {
        return GMPricing.getTokenPrice(_oracle, _token, _withLlo);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { AggregateVaultStorage, LibAggregateVaultStorage } from "../storage/AggregateVaultStorage.sol";
import { NettedPositionTracker } from "./NettedPositionTracker.sol";
import { IGMIWithERC20 as GMI } from "../interfaces/IGMI.sol";
import { OracleWrapper } from "../peripheral/OracleWrapper.sol";
import { TOKEN_USDC_NATIVE, TOKEN_WETH, DEPLOYMENT_MULTISIG } from "../constants.sol";
import { Pricing } from "./Pricing.sol";
import { SafeCast } from "./SafeCast.sol";
import { PriceCast } from "./PriceCast.sol";
import { IFeeEscrow } from "../interfaces/IFeeEscrow.sol";
import { FeeReserve } from "../peripheral/FeeReserve.sol";

using SafeCast for uint256;
using SafeCast for int256;
using PriceCast for uint256;

/// @title LibAggregateVaultUtils
/// @author Umami Devs
/// @notice A logic library that contains functionality for the AggregateVault
library LibAggregateVaultUtils {
    /**
     * @notice Calculates the GMI amount owned by a vault at a given epoch.
     * @param _vaultIdx The index of the vault.
     * @param _currentEpoch The epoch number.
     * @return _gmiAmount The amount of GMI owned by the vault.
     */
    function getVaultGmi(uint256 _vaultIdx, uint256 _currentEpoch, bool useLlo)
        internal
        view
        returns (uint256 _gmiAmount)
    {
        AggregateVaultStorage.AVStorage storage stg = _getStorage();
        int256[2] memory currentAssetPrices = getVaultTokenPrices(useLlo);
        uint256 indexPrice = useLlo
            ? Pricing.getIndexPps(stg.oracleWrapper, GMI(stg.gmi))
            : Pricing.getIndexPpsChainlink(stg.oracleWrapper, GMI(stg.gmi));
        return getVaultGmiWithPrices(_vaultIdx, _currentEpoch, indexPrice, currentAssetPrices);
    }

    /**
     * @notice Calculates the GMI amount owned by a vault at a given epoch using the currentAssetPrices
     * and indexPrice of the GMI index. This is used when passing an offchain price to calculate the current
     * value.
     * @param _vaultIdx The index of the vault.
     * @param _currentEpoch The epoch number.
     * @param indexPrice The price of one share of the GMI index.
     * @param currentAssetPrices The current prices of [USDC, ETH] both in 18 decimal format.
     * @return _gmiAmount The amount of GMI owned by the vault.
     */
    function getVaultGmiWithPrices(
        uint256 _vaultIdx,
        uint256 _currentEpoch,
        uint256 indexPrice,
        int256[2] memory currentAssetPrices
    ) internal view returns (uint256 _gmiAmount) {
        AggregateVaultStorage.AVStorage storage stg = _getStorage();
        uint256[2] memory vaultsGmi = [vaultGmiBalanceToken(0), vaultGmiBalanceToken(1)];
        if (_currentEpoch == 0) {
            return vaultsGmi[_vaultIdx];
        } else {
            (,, int256[2] memory gmiPnl,) = NettedPositionTracker.settleNettingPositionPnl(
                stg.nettedPositions,
                currentAssetPrices,
                stg.lastNettedPrices[_currentEpoch],
                vaultsGmi,
                indexPrice,
                stg.zeroSumPnlThreshold
            );
            int256 gmiDelta = gmiPnl[_vaultIdx];
            if (gmiPnl[_vaultIdx] < 0 && vaultsGmi[_vaultIdx] < (-gmiDelta).toUint256()) {
                return 0;
            } else {
                return uint256(vaultsGmi[_vaultIdx].toInt256() + gmiDelta);
            }
        }
    }

    function pullFeeAmountsFromEscrow(uint256[2] memory _feeAmounts) external {
        AggregateVaultStorage.AVStorage storage stg = _getStorage();
        AggregateVaultStorage.VaultState storage vaultState = stg.vaultState;
        FeeReserve feeReserve = FeeReserve(vaultState.depositFeeEscrow);
        // withdrawFeeEscrow is same address post FeeReserve refactor
        feeReserve.pullAsset(TOKEN_USDC_NATIVE, _feeAmounts[0], false);
        feeReserve.pullAsset(TOKEN_WETH, _feeAmounts[1], false);
    }

    /**
     * @notice Calculates the proportion of GMI attributed to a vault. 100% = 1e18, 10% = 0.1e18.
     * @param _idx The index of the vault.
     * @return _proportion The proportion of GMI attributed to the vault.
     */
    function getVaultGmiProportion(uint256 _idx) internal view returns (uint256 _proportion) {
        uint256[2] memory gmiAttribution = _getStorage().vaultGmiAttribution;
        uint256 totalAttribution = gmiAttribution[0] + gmiAttribution[1];
        if (totalAttribution == 0) return 0;
        uint256 vaultAttribution = gmiAttribution[_idx];
        return vaultAttribution * 1e18 / totalAttribution;
    }

    /**
     * @notice Calculates the value of GMI held by a vault in the vault native token
     * @param _idx The index of the vault.
     * @return - The value of gmi held by the vault.
     */
    function vaultGmiBalanceToken(uint256 _idx) internal view returns (uint256) {
        uint256 gmiBalance = GMI(_getStorage().gmi).balanceOf(address(this));
        return gmiBalance * getVaultGmiProportion(_idx) / 1e18;
    }

    /**
     * @notice Gets the vault token prices, either on-chain or using the low latency oracle price in storage
     * @param useLlo should use the LLO
     * @return tokenPrices prices of the vault tokens
     */
    function getVaultTokenPrices(bool useLlo) internal view returns (int256[2] memory tokenPrices) {
        address oracle = _getStorage().oracleWrapper;
        uint256 usdcPrice = OracleWrapper(oracle).getChainlinkPrice(TOKEN_USDC_NATIVE);
        uint256 wethPrice = useLlo
            ? OracleWrapper(oracle).getLloPriceWithinL1Blocks(TOKEN_WETH)
            : OracleWrapper(oracle).getChainlinkPrice(TOKEN_WETH);
        return [usdcPrice.toInternalPrice(6).toInt256(), wethPrice.toInternalPrice(18).toInt256()];
    }

    /// @dev the total GMI held by vaults may not be equal to the total supply of GMI
    function getVaultsGmi(uint256 epoch, bool useLlo) internal view returns (uint256[2] memory) {
        return [getVaultGmi(0, epoch, useLlo), getVaultGmi(1, epoch, useLlo)];
    }

    /// @dev get the storage struct
    function _getStorage() internal pure returns (AggregateVaultStorage.AVStorage storage stg) {
        stg = LibAggregateVaultStorage.getStorage();
    }
}

pragma solidity 0.8.17;

address constant GMX_POSITION_ROUTER = 0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868;
address constant GMX_VAULT = 0x489ee077994B6658eAfA855C308275EAd8097C4A;
address constant GMX_ROUTER = 0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064;
address constant GMX_GLP_REWARD_ROUTER = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;

address constant TOKEN_FRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;

address constant DATA_STORE = 0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8;
address constant READER = 0x38d91ED96283d62182Fc6d990C24097A918a4d9b;
address constant TOKEN_USDC_BRIDGED = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
address constant TOKEN_WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
address constant TOKEN_USDC_NATIVE = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
address constant TOKEN_XRP = 0xc14e065b0067dE91534e032868f5Ac6ecf2c6868;
address constant TOKEN_LINK = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
address constant TOKEN_ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;

uint256 constant DECIMALS_WETH = 18;
uint256 constant DECIMALS_USDC_NATIVE = 6;
uint256 constant DECIMALS_XRP = 6;
uint256 constant DECIMALS_LTC = 8;
uint256 constant DECIMALS_DOGE = 8;

uint256 constant YEAR = 31557600;

bool constant CONFIG_GMI_UPGRADABLE = true;
bool constant CONFIG_AGGREGATE_VAULT_UPGRADABLE = true;
address constant CONFIG_PROXY_ADMIN = 0x4e5645bee4eD80C6FEe04DCC15D14A3AC956748A; // umami-devs msig
address constant CONFIG_UI_FEE_RECEIVER = CONFIG_PROXY_ADMIN;
uint256 constant CONFIG_DEPOSIT_CALLBACK_GASLIMIT = 500_000;
uint256 constant CONFIG_WITHDRAWAL_CALLBACK_GASLIMIT = 500_000;
uint256 constant CONFIG_GMI_DEPOSIT_TOLERANCE = 0.1e18;
uint256 constant CONFIG_GMI_MINT_CAP_TOLERANCE = 0.9e18;
uint256 constant CONFIG_SWAP_SLIPPAGE_TOLERANCE = 500; // bps
uint16 constant CONFIG_MAX_COPY_UNTRUSTED_CALL = 500; // number of bytes max copy for untrusted calls
uint256 constant CONFIG_USDC_FEE_PER_EPOCH = 5e6;
uint256 constant CONFIG_WETH_FEE_PER_EPOCH = 0.0025e18;

address constant GMX_V2_EXCHANGE_ROUTER = 0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8;
address constant GMX_V2_MARKET_UTILS = 0x7ffF7ef2fc8Db5159B0046ad49d018A5aB40dB11;
address constant GMX_V2_DATA_STORE = 0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8;
address constant GMX_V2_XRP_INDEX_TOKEN = 0xc14e065b0067dE91534e032868f5Ac6ecf2c6868;
address constant GMX_V2_LTC_INDEX_TOKEN = 0xB46A094Bc4B0adBD801E14b9DB95e05E28962764;
address constant GMX_V2_DOGE_INDEX_TOKEN = 0xC4da4c24fd591125c3F47b340b6f4f76111883d8;
address constant GMX_V2_ORACLE = 0xa11B501c2dd83Acd29F6727570f2502FAaa617F2;

address constant CHAINLINK_ETH_PRICE_FEED = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
address constant CHAINLINK_XRP_PRICE_FEED = 0xB4AD57B52aB9141de9926a3e0C8dc6264c2ef205;
address constant CHAINLINK_USDC_PRICE_FEED = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
address constant CHAINLINK_DOGE_PRICE_FEED = 0x9A7FB1b3950837a8D9b40517626E11D4127C098C;

// GMX MARKET TOKENS
/// @dev key for max pnl factor
bytes32 constant MAX_PNL_FACTOR_FOR_DEPOSITS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_DEPOSITS"));
/// @dev key for max pnl factor for withdrawals
bytes32 constant MAX_PNL_FACTOR_FOR_WITHDRAWALS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS"));
address constant MARKET_ETH = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336;
address constant MARKET_XRP = 0x0CCB4fAa6f1F1B30911619f1184082aB4E25813c;
address constant MARKET_DOGE = 0x6853EA96FF216fAb11D2d930CE3C508556A4bdc4;
address constant MARKET_LTC = 0xD9535bB5f58A1a75032416F2dFe7880C30575a41;

// uniswap
address constant UNISWAP_SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
address constant UNISWAP_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

address constant TESTNET_CHAINLINK_LLO_VERIFIER_PROXY = 0xea9B98Be000FBEA7f6e88D08ebe70EbaAD10224c;
address constant TESTNET_CHAINLINK_LLO_REWARD_MANAGER = 0x86F3659e02Bd3eDE216356BED9361DD70Be53897;
address constant TESTNET_CHAINLINK_LLO_FEE_MANAGER = 0x75DBc8Db499e69b6990cd5576850a8D71cD5E670;
bytes32 constant TESTNET_CHAINLINK_LLO_ETH_FEEDID = 0x00023496426b520583ae20a66d80484e0fc18544866a5b0bfee15ec771963274;
address constant TESTNET_TOKEN_WETH = 0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3;
address constant TESTNET_TOKEN_LINK = 0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28;

address constant ARBSYS = address(0x64);
address constant SUPRA_FEED = 0x8a358F391d93f7558D5F5E61BDf533e2cc3Cf7a3;
//address constant SUPRA_FEED = 0x6562fB484C57d1Cba9E89A59C9Ad3F1b6fc79a65;
address constant DEPLOYMENT_MULTISIG = 0xb137d135Dc8482B633265c21191F50a4bA26145d;
address constant DEV_MULTISIG = 0x4e5645bee4eD80C6FEe04DCC15D14A3AC956748A;
address constant REBALANCE_KEEPER = 0x0577562211F36b46fB5642a35BD92361C1770Dde;

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { GlobalACL, Auth, REQUEST_HANDLER, AGGREGATE_VAULT_ROLE, KEEPER_ROLE } from "../Auth.sol";
import { IAggregatorV3Interface } from "../interfaces/IAggregatorV3Interface.sol";
import { IVerifierProxy } from "../interfaces/IVerifierProxy.sol";
import { IArbSys } from "../interfaces/IArbSys.sol";
import { ARBSYS, GMX_V2_LTC_INDEX_TOKEN, TOKEN_USDC_NATIVE } from "../constants.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ISupraSValueFeed } from "../interfaces/ISupraSValueFeed.sol";
import { StorageViewer } from "./StorageViewer.sol";

using SafeTransferLib for ERC20;

library LLOReportDecoder {
    struct SignedReportData {
        bytes32[3] context;
        bytes blob;
        bytes32[] rawRs;
        bytes32[] rawSs;
        bytes32 rawVs;
    }

    struct ReportData {
        bytes32 feedId;
        uint32 validFromTimestamp;
        uint32 observationsTimestamp;
        uint192 nativeFee;
        uint192 linkFee;
        uint32 expiresAt;
        int192 benchmarkPrice;
    }

    function decodeSignedReport(bytes memory _signedReportData)
        internal
        pure
        returns (SignedReportData memory _reportData)
    {
        (_reportData.context, _reportData.blob, _reportData.rawRs, _reportData.rawSs, _reportData.rawVs) =
            abi.decode(_signedReportData, (bytes32[3], bytes, bytes32[], bytes32[], bytes32));
    }

    function decodeReportBlob(bytes memory _reportBlob) internal pure returns (ReportData memory _reportData) {
        (
            _reportData.feedId,
            _reportData.validFromTimestamp,
            _reportData.observationsTimestamp,
            _reportData.nativeFee,
            _reportData.linkFee,
            _reportData.expiresAt,
            _reportData.benchmarkPrice
        ) = abi.decode(_reportBlob, (bytes32, uint32, uint32, uint192, uint192, uint32, int192));
    }
}

/// @title OracleWrapper
/// @author Umami Devs
/// @notice Contains core oracle logic
contract OracleWrapper is GlobalACL {
    error ZeroAddress();
    error InvalidPrice();
    error FailedDeviationCheck(uint256);
    error InvalidToken();
    error PriceOutsideTolerance();

    event UpdateTokenDetails(address indexed _token, TokenDetails _tokenDetails);

    struct TokenDetails {
        uint96 decimals;
        address chainlinkPriceFeed;
        bytes32 lloFeedId;
    }

    struct LLOConfiguration {
        IVerifierProxy verifierProxy;
        address feeManager;
        address rewardManager;
    }

    struct PriceDetails {
        uint32 validFrom;
        uint32 validTill;
        uint192 price;
        uint128 lastUpdatedBlockNumber;
        uint128 lastUpdatedBlockNumberL2;
        uint128 lastUpdatedBlockTimestamp;
        bytes32 feedId;
    }

    mapping(address => TokenDetails) tokenDetails;
    LLOConfiguration public lloConfiguration;
    address public immutable LINK;
    mapping(address => PriceDetails) lloPriceDetails;
    StorageViewer public storageViewer;
    uint256 public lloDeviationFactor;

    constructor(
        Auth _auth,
        StorageViewer viewer,
        address _verifierProxy,
        address _feeManager,
        address _rewardManager,
        address _link
    ) GlobalACL(_auth) {
        lloConfiguration = LLOConfiguration({
            verifierProxy: IVerifierProxy(_verifierProxy),
            feeManager: _feeManager,
            rewardManager: _rewardManager
        });
        LINK = _link;
        require(address(viewer) != address(0));
        storageViewer = viewer;
    }

    function updateViewer(StorageViewer viewer) external onlyConfigurator {
        require(address(viewer) != address(0));
        storageViewer = viewer;
    }

    function updateDeviationFactor(uint256 _newDeviationFactor) external onlyConfigurator {
        require(_newDeviationFactor < 1e18);
        lloDeviationFactor = _newDeviationFactor;
    }

    function updateTokenDetails(address _token, address _chainlinkPriceFeed, uint256 _decimals, bytes32 _lloFeedId)
        external
        onlyConfigurator
    {
        TokenDetails storage deets = tokenDetails[_token];
        deets.chainlinkPriceFeed = _chainlinkPriceFeed;
        // read decimals from chain if token contract is not empty and decimals arg passed is 0
        uint96 decimals = _decimals > 0 ? uint96(_decimals) : _token.code.length > 0 ? ERC20(_token).decimals() : 0;
        deets.decimals = decimals;
        deets.lloFeedId = _lloFeedId;
        emit UpdateTokenDetails(_token, deets);
    }

    function updateLLOConfiguration(address _verifierProxy, address _feeManager, address _rewardManager)
        external
        onlyConfigurator
    {
        lloConfiguration = LLOConfiguration({
            verifierProxy: IVerifierProxy(_verifierProxy),
            feeManager: _feeManager,
            rewardManager: _rewardManager
        });
    }

    function getChainlinkPrice(address _token) public view returns (uint256 _price) {
        TokenDetails storage deets = tokenDetails[_token];
        uint256 tokenDecimals = deets.decimals;
        uint256 priceDecimal;

        if (_token == GMX_V2_LTC_INDEX_TOKEN) {
            return _getLtcPrice();
        } else {
            address priceFeed = deets.chainlinkPriceFeed;
            if (priceFeed == address(0)) revert ZeroAddress();

            (, int256 price,,,) = IAggregatorV3Interface(priceFeed).latestRoundData();
            if (price < 0) revert InvalidPrice();
            _price = uint256(price);
            priceDecimal = IAggregatorV3Interface(priceFeed).decimals();
        }

        uint256 targetDecimals = 30;
        if (priceDecimal + tokenDecimals < targetDecimals) {
            _price = _price * (10 ** (targetDecimals - priceDecimal - tokenDecimals));
        } else {
            _price = _price / (10 ** (priceDecimal + tokenDecimals - targetDecimals));
        }
    }

    function getChainlinkPriceInternal(address _token) public view returns (uint256) {
        uint256 externalPrice = getChainlinkPrice(_token);
        TokenDetails storage deets = tokenDetails[_token];
        uint256 tokenDecimals = deets.decimals;
        uint256 oneToken = 10 ** tokenDecimals;
        return externalPrice * oneToken / 1e12;
    }

    function setAndGetLloPrice(address _token, bytes calldata _report)
        public
        validateSetPriceAuth
        returns (uint256 _price)
    {
        _price = _setAndGetPriceInternal(_token, _report);
    }

    function getLloPriceWithinL1Blocks(address _token) public view returns (uint256 _price) {
        if (_token == TOKEN_USDC_NATIVE) return getChainlinkPrice(_token);
        PriceDetails storage priceDeets = lloPriceDetails[_token];
        if (priceDeets.feedId == bytes32(0)) revert InvalidToken();
        uint256 minBlockNumber = block.number - storageViewer.getBlockTolerance();
        if (priceDeets.lastUpdatedBlockNumber < minBlockNumber) revert PriceOutsideTolerance();
        _price = priceDeets.price;
    }

    function getLloPriceWithinL2Blocks(address _token) public view returns (uint256 _price) {
        if (_token == TOKEN_USDC_NATIVE) return getChainlinkPrice(_token);
        PriceDetails storage priceDeets = lloPriceDetails[_token];
        if (priceDeets.feedId == bytes32(0)) revert InvalidToken();
        uint256 minBlockNumber = _getBlockNumber() - storageViewer.getBlockTolerance();
        if (priceDeets.lastUpdatedBlockNumberL2 < minBlockNumber) revert PriceOutsideTolerance();
        _price = priceDeets.price;
    }

    function getLloPriceWithinSeconds(address _token, uint256 _seconds) public view returns (uint256 _price) {
        if (_token == TOKEN_USDC_NATIVE) return getChainlinkPrice(_token);
        PriceDetails storage priceDeets = lloPriceDetails[_token];
        if (priceDeets.feedId == bytes32(0)) revert InvalidToken();
        uint256 minTimestamp = block.timestamp - _seconds;
        if (priceDeets.lastUpdatedBlockTimestamp < minTimestamp) revert PriceOutsideTolerance();
        _price = priceDeets.price;
    }

    /// @dev mostly a test util, this.call so it catches the mock
    function _getLloPrice18Decimals(address _token) public view returns (uint256 _price) {
        uint256 lloPrice = this.getLloPriceWithinL1Blocks(_token);
        TokenDetails storage deets = tokenDetails[_token];
        uint256 tokenDecimals = deets.decimals;
        uint256 oneToken = uint256(10) ** tokenDecimals;
        _price = lloPrice * oneToken / 1e12;
    }

    function _approveTokens(bytes memory _report) internal {
        LLOReportDecoder.SignedReportData memory signedReportData = LLOReportDecoder.decodeSignedReport(_report);
        LLOReportDecoder.ReportData memory reportData = LLOReportDecoder.decodeReportBlob(signedReportData.blob);
        ERC20(LINK).safeApprove(lloConfiguration.rewardManager, reportData.linkFee);
    }

    function _getBlockNumber() internal view returns (uint256 _blockNumber) {
        _blockNumber = IArbSys(ARBSYS).arbBlockNumber();
    }

    function _getLtcPrice() internal view returns (uint256 _price) {
        /// @dev return last LLO price
        _price = lloPriceDetails[GMX_V2_LTC_INDEX_TOKEN].price;
    }

    function _setAndGetPriceInternal(address _token, bytes memory _report) internal returns (uint256 _price) {
        _price = abi.decode(_report, (uint256));
        _checkPriceDeviation(_token, _price);
        lloPriceDetails[_token] = PriceDetails({
            validFrom: uint32(block.timestamp),
            validTill: uint32(block.timestamp + 5 minutes),
            price: uint192(_price),
            lastUpdatedBlockNumberL2: uint128(_getBlockNumber()),
            lastUpdatedBlockNumber: uint128(block.number),
            lastUpdatedBlockTimestamp: uint128(block.timestamp),
            feedId: bytes32(type(uint256).max)
        });
    }

    function _setAndGetPriceLlo(address _token, bytes memory _report) internal returns (uint256 _price) {
        bytes32 lloFeedId = tokenDetails[_token].lloFeedId;
        if (lloFeedId == bytes32(0)) revert InvalidToken();

        _approveTokens(_report);
        bytes memory verifiedData = lloConfiguration.verifierProxy.verify(_report);
        LLOReportDecoder.ReportData memory reportData = LLOReportDecoder.decodeReportBlob(verifiedData);
        if (reportData.benchmarkPrice < 0) revert InvalidPrice();
        if (reportData.feedId != lloFeedId) revert InvalidToken();
        _price = uint256(uint192(reportData.benchmarkPrice));
        lloPriceDetails[_token] = PriceDetails({
            validFrom: reportData.validFromTimestamp,
            validTill: reportData.expiresAt,
            price: uint192(_price),
            lastUpdatedBlockNumberL2: uint128(_getBlockNumber()),
            lastUpdatedBlockNumber: uint128(block.number),
            lastUpdatedBlockTimestamp: uint128(block.timestamp),
            feedId: lloFeedId
        });
    }

    function _checkPriceDeviation(address _token, uint256 _newPrice) internal {
        if (_token == GMX_V2_LTC_INDEX_TOKEN) {
            return; // skip for LTC due to lack of on-chain oracle
        }
        uint256 externalPrice = getChainlinkPrice(_token);
        uint256 deviation = _newPrice * 1e18 / externalPrice;
        if (deviation < 1e18 - lloDeviationFactor || deviation > 1e18 + lloDeviationFactor) {
            revert FailedDeviationCheck(deviation);
        }
    }

    /// @dev validate the set price call
    modifier validateSetPriceAuth() {
        require(
            AUTH.hasRole(AGGREGATE_VAULT_ROLE, msg.sender) || AUTH.hasRole(REQUEST_HANDLER, msg.sender)
                || AUTH.hasRole(KEEPER_ROLE, msg.sender),
            "OracleWrapper: !authorized"
        );
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { IHandlerContract } from "./IHandlerContract.sol";

interface IPositionManager is IHandlerContract {
    function positionNotional(address _indexToken) external view returns (uint256, bool);

    function positionMargin(address _indexToken) external view returns (uint256, bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IVaultFees {
    function getVaultRebalanceFees(address vault, uint256 lastRebalance)
        external
        returns (uint256, uint256, uint256, uint256);

    function getWithdrawalFee(address vault, uint256 size, bool useLlo) external view returns (uint256, uint256);

    function getDepositFee(address vault, uint256 size, bool useLlo) external view returns (uint256);

    function _getVaultRebalanceFees(
        uint256 currentBalance,
        bool isAboveWatermark,
        uint256 performanceFeePercent,
        uint256 managementFeePercent
    ) external returns (uint256 _performanceFeeInAsset, uint256 _managementFeeInAsset, uint256 _totalVaultFee);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title Price Cast
/// @author Umami Devs
/// @notice Contains methods for casting price to gmx decimals
library PriceCast {
    /// @notice Cast an internal 1e18 price to price per unit
    /// @param internalPrice The 1e18 price to be casted
    /// @param decimals The token decimals
    /// @return externalPrice Price per unit
    function toExternalPricing(uint256 internalPrice, uint256 decimals) internal pure returns (uint256 externalPrice) {
        externalPrice = (internalPrice * 1e12) / 10 ** decimals;
    }

    /// @notice Cast price per unit to 1e18 standard
    /// @param externalPrice The price per unit
    /// @param decimals The token decimals
    /// @return internalPrice 1e18 decmal price
    function toInternalPrice(uint256 externalPrice, uint256 decimals) internal pure returns (uint256 internalPrice) {
        internalPrice = (externalPrice * 1e18) / 10 ** (30 - decimals);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Safe casting methods
/// @author Umami Devs
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2 ** 255, "toInt256: Cast overflow");
        z = int256(y);
    }

    /// @notice Cast a int256 to a uint256, revert on overflow or negative
    /// @param y The int256 to be casted
    /// @return z The casted integer, now type uint256
    function toUint256(int256 y) internal pure returns (uint256 z) {
        require(y >= 0, "toUint256: Cast underflow");
        z = uint256(y);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Solarray } from "../libraries/Solarray.sol";

/// @title NettedPositionTracker
/// @author Umami Devs
/// @notice Math for tracking netted positions in the vault
library NettedPositionTracker {
    /**
     * @notice Derive the pnl for each vault in dollars (1e18)
     * @param internalPositions matrix of internal positions taken out by each vault
     * @param assetPriceChange percent price change for each asset in 1e18 eg. 5% = 0.05 * 1e18 / 1e18
     * @return pnl pnl for each vault in dollars
     */
    function getNettedPnl(int256[2][2] memory internalPositions, int256[2] memory assetPriceChange)
        internal
        pure
        returns (int256[2] memory pnl)
    {
        int256[2] memory iPnl;
        int256[2] memory nettingCollumnSum = Solarray.sumColumns(internalPositions);

        nettingCollumnSum[0] -= internalPositions[0][0];
        nettingCollumnSum[1] -= internalPositions[1][1];

        iPnl[0] += nettingCollumnSum[0] * assetPriceChange[0] / 1e18;
        iPnl[1] += nettingCollumnSum[1] * assetPriceChange[1] / 1e18;

        pnl[0] = nettingCollumnSum[1] != 0
            ? iPnl[0] + (-iPnl[1] * (internalPositions[0][1] * 1e18 / nettingCollumnSum[1])) / 1e18
            : iPnl[0];
        pnl[1] = nettingCollumnSum[0] != 0
            ? iPnl[1] + (-iPnl[0] * (internalPositions[1][0] * 1e18 / nettingCollumnSum[0])) / 1e18
            : iPnl[1];
    }

    /**
     * @notice Returns the settle result from the internal positions
     * @param internalPositions matrix of internal netted positions the vaults hold
     * @param currentAssetPrices current asset prices in 1e18
     * @param nettedAssetPrices asset prices at last settlement
     * @param vaultIndexAmount index amount owned by each vault
     * @param indexPrice price of index in 1e18
     * @param pnlSumThreshold threshold for the sum of pnl to be under
     * @return settledVaultIndexAmount amount of index held by each vault after internal pnl is settled
     * @return nettedPnl pnl for each vault in $
     * @return indexPnl pnl for each vault in index
     */
    function settleNettingPositionPnl(
        int256[2][2] memory internalPositions,
        int256[2] memory currentAssetPrices,
        int256[2] memory nettedAssetPrices,
        uint256[2] memory vaultIndexAmount,
        uint256 indexPrice,
        uint256 pnlSumThreshold
    )
        internal
        pure
        returns (
            uint256[2] memory settledVaultIndexAmount,
            int256[2] memory nettedPnl,
            int256[2] memory indexPnl,
            int256[2] memory percentPriceChange
        )
    {
        _validatePrices(currentAssetPrices, nettedAssetPrices);
        require(indexPrice > 0, "NettedPositionTracker: indexPrice must be greater than 0");

        // calculate the change in price
        percentPriceChange = calculatePriceChange(currentAssetPrices, nettedAssetPrices);

        // get the dollar value pnl
        nettedPnl = getNettedPnl(internalPositions, percentPriceChange);

        // require 0 sum
        checkZeroSum(nettedPnl, pnlSumThreshold);

        indexPnl = pnlToIndex(int256(indexPrice), nettedPnl);

        // find the index value pnl using index price
        int256[2] memory indexPnlDifference = Solarray.arrayDifference(vaultIndexAmount, indexPnl);
        checkNegativeDifference(indexPnlDifference);

        settledVaultIndexAmount = Solarray.intToUintArray(indexPnlDifference);
    }

    /**
     * @notice Calculates the % price change for each asset in 1e18
     * @param currentPrices current asset prices
     * @param nettedPrices last netted prices
     * @return percentPriceChange % price change in 1e18 eg. 1% = 0.01 * 1e18 / 1e18
     */
    function calculatePriceChange(int256[2] memory currentPrices, int256[2] memory nettedPrices)
        internal
        pure
        returns (int256[2] memory percentPriceChange)
    {
        percentPriceChange[0] = ((currentPrices[0] - nettedPrices[0]) * 1e18 / nettedPrices[0]);
        percentPriceChange[1] = ((currentPrices[1] - nettedPrices[1]) * 1e18 / nettedPrices[1]);
    }

    /**
     * @notice Calculated the pnl denominated in the index basket
     * @param indexPrice share price of the index
     * @param pnl in $ 1e18
     * @return indexAmount index pnl for each vault
     */
    function pnlToIndex(int256 indexPrice, int256[2] memory pnl) internal pure returns (int256[2] memory indexAmount) {
        indexAmount[0] = (pnl[0] * 1e18 / indexPrice);
        indexAmount[1] = (pnl[1] * 1e18 / indexPrice);
    }

    /**
     * @notice Check for zero sum of pnl to ensure balanced pnl from internal positions
     * @param nettingPositionPnl array of pnl for each vault
     * @param zeroSumThreshold threshold for the zero sum, used for rounding errors
     */
    function checkZeroSum(int256[2] memory nettingPositionPnl, uint256 zeroSumThreshold) internal pure {
        uint256 absoluteSum = Solarray.arraySumAbsolute(nettingPositionPnl);
        int256 pnlDifference = Solarray.arraySum(nettingPositionPnl);
        uint256 pnlAbsoluteDifference = pnlDifference > 0 ? uint256(pnlDifference) : uint256(-pnlDifference);
        uint256 buffer = (absoluteSum * zeroSumThreshold) / 1e18;
        if (absoluteSum == 0) return; // no internal position change
        require(pnlAbsoluteDifference < buffer, "NettedPositionTracker: greater than threshold");
    }

    /**
     * @notice Check for vault index remaining to be above the capacity of the vault
     * @param differenceArray new allocation to index for each vault
     */
    function checkNegativeDifference(int256[2] memory differenceArray) internal pure {
        require(differenceArray[0] >= 0 && differenceArray[1] >= 0, "NettedPositionTracker: differenceArray[i] < 0");
    }

    /**
     * @notice Check for valid prices
     * @param _a prices array
     * @param _b prices array
     */
    function _validatePrices(int256[2] memory _a, int256[2] memory _b) internal pure {
        require(_a[0] > 0 && _a[1] > 0, "NettedPositionTracker: _a[i] must be greater than 0");
        require(_b[0] > 0 && _b[1] > 0, "NettedPositionTracker: _b[i] must be greater than 0");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title Delegatecall
/// @author Umami Devs
library Delegatecall {
    error EmptyContract(address);

    function delegateCall(address _target, bytes memory _calldata) internal returns (bytes memory _ret) {
        if (_target.code.length == 0) revert EmptyContract(_target);

        bool success;
        (success, _ret) = _target.delegatecall(_calldata);
        if (!success) {
            /// @solidity memory-safe-assembly
            assembly {
                let length := mload(_ret)
                let start := add(_ret, 0x20)
                revert(start, length)
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { SafeCast } from "./SafeCast.sol";

/// @title Solarray
/// @author Umami Devs
/// @notice Array functions
library Solarray {
    using SafeCast for int256;

    function uint256s(uint256 a, uint256 b) internal pure returns (uint256[2] memory arr) {
        arr[0] = a;
        arr[1] = b;
    }

    function int256s(int256 a, int256 b) internal pure returns (int256[2] memory arr) {
        arr[0] = a;
        arr[1] = b;
    }

    function addresss(address a, address b) internal pure returns (address[2] memory arr) {
        arr[0] = a;
        arr[1] = b;
    }

    function variableAddresss(address a, address b, address c, address d) internal pure returns (address[] memory) {
        address[] memory arr = new address[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function addresss(address a, address b, address c, address d) internal pure returns (address[4] memory arr) {
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
    }

    function uint256s(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (uint256[4] memory arr) {
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
    }

    function variableUint256s(uint256 a, uint256 b, uint256 c, uint256 d)
        internal
        pure
        returns (uint256[] memory arr)
    {
        arr = new uint256[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function int256s(int256 a, int256 b, int256 c, int256 d) internal pure returns (int256[4] memory arr) {
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
    }

    function variableInt256s(int256 a, int256 b, int256 c, int256 d) internal pure returns (int256[] memory arr) {
        arr = new int256[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function intToUintArray(int256[2] memory array) internal pure returns (uint256[2] memory uintArray) {
        require(array[0] >= 0 && array[1] >= 0, "Solarray: intToUintArray: negative value");
        uintArray = [uint256(array[0]), uint256(array[1])];
    }

    function arraySum(int256[2] memory array) internal pure returns (int256 sum) {
        for (uint256 i = 0; i < 2; i++) {
            sum += array[i];
        }
    }

    function arraySum(uint256[2] memory array) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < 2; i++) {
            sum += array[i];
        }
    }

    function arraySum(uint256[] memory array) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < array.length; i++) {
            sum += array[i];
        }
    }

    function arraySumWithSafeCast(int256[] memory array) internal pure returns (uint256 sum) {
        int256 intSum;
        for (uint256 i = 0; i < array.length; i++) {
            intSum += array[i];
        }
        sum = SafeCast.toUint256(intSum);
    }

    function arraySumAbsolute(int256[2] memory array) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < 2; i++) {
            sum += array[i] > 0 ? uint256(array[i]) : uint256(-array[i]);
        }
    }

    function arrayDifference(uint256[2] memory base, int256[2] memory difference)
        internal
        pure
        returns (int256[2] memory result)
    {
        for (uint256 i = 0; i < 2; i++) {
            result[i] = SafeCast.toInt256(base[i]) + difference[i];
        }
    }

    function arrayDifference(uint256[4] memory base, uint256[4] memory difference)
        internal
        pure
        returns (int256[4] memory result)
    {
        for (uint256 i = 0; i < 4; i++) {
            result[i] = SafeCast.toInt256(base[i]) - SafeCast.toInt256(difference[i]);
        }
    }

    function arrayDifference(uint256[] memory base, int256[] memory difference)
        internal
        pure
        returns (int256[] memory)
    {
        require(base.length == difference.length);
        int256[] memory result = new int256[](base.length);
        for (uint256 i = 0; i < base.length; i++) {
            result[i] = SafeCast.toInt256(base[i]) + difference[i];
        }
        return result;
    }

    function arrayDifference(uint256[] memory base, uint256[] memory difference)
        internal
        pure
        returns (int256[] memory)
    {
        require(base.length == difference.length);
        int256[] memory result = new int256[](base.length);
        for (uint256 i = 0; i < base.length; i++) {
            result[i] = SafeCast.toInt256(base[i]) - SafeCast.toInt256(difference[i]);
        }
        return result;
    }

    function arrayAddProportion(
        uint256[] memory base,
        uint256 amount,
        int256[] memory proportions,
        uint256 divisor,
        bool positive
    ) internal pure returns (uint256[] memory) {
        require(base.length == proportions.length);
        uint256 proportion;
        bool direction;
        uint256[] memory result = new uint256[](base.length);
        for (uint256 i = 0; i < 4; i++) {
            direction = proportions[i] > 0;
            proportion = direction ? SafeCast.toUint256(proportions[i]) : SafeCast.toUint256(-proportions[i]);
            result[i] = direction == positive ? base[i] + (amount * proportion / divisor) : base[i];
        }
        return result;
    }

    function arrayRemoveDirection(int256[] memory base, bool positive) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](base.length);
        bool direction;
        for (uint256 i = 0; i < base.length; i++) {
            direction = base[i] > 0;
            result[i] =
                direction == positive ? 0 : direction ? SafeCast.toUint256(base[i]) : SafeCast.toUint256(-base[i]);
        }
        return result;
    }

    /**
     * @notice Calculates the sum of array elements in one direction ~ +/-
     * @param _array to perform the operation
     * @param positive direction of sum
     * @return sum total sum in direction
     */
    function directionalSum(int256[] memory _array, bool positive) public pure returns (int256 sum) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] > 0 && positive) {
                sum += _array[i];
            } else if (_array[i] < 0 && !positive) {
                sum += _array[i];
            }
        }
    }

    function sumColumns(int256[2][2] memory array) internal pure returns (int256[2] memory retArray) {
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < 2; j++) {
                retArray[i] += array[j][i];
            }
        }
    }

    function int2FixedToDynamic(int256[2] memory arr) public view returns (int256[] memory retArr) {
        bytes memory ret = fixedToDynamicArray(abi.encode(arr), 2);
        /// @solidity memory-safe-assembly
        assembly {
            retArr := ret // point to the array
        }
    }

    function uint2FixedToDynamic(uint256[2] memory arr) internal view returns (uint256[] memory retArr) {
        bytes memory ret = fixedToDynamicArray(abi.encode(arr), 2);
        /// @solidity memory-safe-assembly
        assembly {
            retArr := ret // point to the array
        }
    }

    function uint4FixedToDynamic(uint256[4] memory arr) internal view returns (uint256[] memory retArr) {
        bytes memory ret = fixedToDynamicArray(abi.encode(arr), 4);
        /// @solidity memory-safe-assembly
        assembly {
            retArr := ret // point to the array
        }
    }

    function int4FixedToDynamic(int256[4] memory arr) internal view returns (int256[] memory retArr) {
        bytes memory ret = fixedToDynamicArray(abi.encode(arr), 4);
        /// @solidity memory-safe-assembly
        assembly {
            retArr := ret // point to the array
        }
    }

    function fixedToDynamicArray(bytes memory arr, uint256 fixedSize) public view returns (bytes memory retArray) {
        (bool success, bytes memory data) = address(0x04).staticcall(arr);
        require(success, "identity precompile failed");
        /// @solidity memory-safe-assembly
        assembly {
            retArray := data // point to the copied data
            mstore(retArray, fixedSize) // store array length
        }
    }

    /**
     * @dev Gets the value of the element at the specified index in the given array. If the index is out of bounds, returns 0.
     *
     * @param arr the array to get the value from
     * @param index the index of the element in the array
     * @return the value of the element at the specified index in the array
     */
    function get(bytes32[] memory arr, uint256 index) internal pure returns (bytes32) {
        if (index < arr.length) {
            return arr[index];
        }

        return bytes32(0);
    }

    /**
     * @dev Determines whether all of the elements in the given array are equal to the specified value.
     *
     * @param arr the array to check the elements of
     * @param value the value to compare the elements of the array to
     * @return true if all of the elements in the array are equal to the specified value, false otherwise
     */
    function areEqualTo(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] != value) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Determines whether all of the elements in the given array are greater than the specified value.
     *
     * @param arr the array to check the elements of
     * @param value the value to compare the elements of the array to
     * @return true if all of the elements in the array are greater than the specified value, false otherwise
     */
    function areGreaterThan(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] <= value) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Determines whether all of the elements in the given array are greater than or equal to the specified value.
     *
     * @param arr the array to check the elements of
     * @param value the value to compare the elements of the array to
     * @return true if all of the elements in the array are greater than or equal to the specified value, false otherwise
     */
    function areGreaterThanOrEqualTo(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] < value) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Determines whether all of the elements in the given array are less than the specified value.
     *
     * @param arr the array to check the elements of
     * @param value the value to compare the elements of the array to
     * @return true if all of the elements in the array are less than the specified value, false otherwise
     */
    function areLessThan(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] >= value) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Determines whether all of the elements in the given array are less than or equal to the specified value.
     *
     * @param arr the array to check the elements of
     * @param value the value to compare the elements of the array to
     * @return true if all of the elements in the array are less than or equal to the specified value, false otherwise
     */
    function areLessThanOrEqualTo(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] > value) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Gets the median value of the elements in the given array. For arrays with an odd number of elements, returns the element at the middle index. For arrays with an even number of elements, returns the average of the two middle elements.
     *
     * @param arr the array to get the median value from
     * @return the median value of the elements in the given array
     */
    function getMedian(uint256[] memory arr) internal pure returns (uint256) {
        if (arr.length % 2 == 1) {
            return arr[arr.length / 2];
        }

        return (arr[arr.length / 2] + arr[arr.length / 2 - 1]) / 2;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { PriceCast } from "./PriceCast.sol";

/// @title GmxStorage
/// @dev Struct wrapper for Gmx Storage
/// @author Umami Devs
library GmxStorage {
    // pricing struct for a gmx market
    struct MarketPrices {
        Price indexTokenPrice;
        Price longTokenPrice;
        Price shortTokenPrice;
    }

    // @param min the min price
    // @param max the max price
    struct Price {
        uint256 min;
        uint256 max;
    }

    // cast from 1e18
    function castToPrice(uint256 min, uint256 max, uint256 decimals) internal pure returns (Price memory) {
        return Price(PriceCast.toExternalPricing(min, decimals), PriceCast.toExternalPricing(max, decimals));
    }

    // market token prices as [index, long, short]
    function castToMarketPrices(uint256[3] memory min, uint256[3] memory max, uint256[3] memory decimals)
        internal
        pure
        returns (MarketPrices memory)
    {
        return MarketPrices(
            castToPrice(min[0], max[0], decimals[0]),
            castToPrice(min[1], max[1], decimals[1]),
            castToPrice(min[2], max[2], decimals[2])
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

pragma solidity 0.8.17;

import { IHandlerContract } from "./IHandlerContract.sol";

interface ISwapManager is IHandlerContract {
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _minOut, bytes calldata _data)
        external
        returns (uint256 _amountOut);
}

pragma solidity 0.8.17;

import { OracleWrapper } from "../peripheral/OracleWrapper.sol";
import { IGMIWithERC20 as GMI } from "../interfaces/IGMI.sol";
import { IGmxV2Handler, GmxV2HandlerStorage } from "../interfaces/IGmxV2Handler.sol";
import { AggregateVaultStorage, LibAggregateVaultStorage } from "../storage/AggregateVaultStorage.sol";
import { GmxStorage } from "./GmxStorage.sol";
import { Pricing } from "./Pricing.sol";
import { Delegatecall } from "./Delegatecall.sol";
import { TOKEN_WETH, TOKEN_USDC_NATIVE } from "../constants.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ISwapManager } from "../interfaces/ISwapManager.sol";
import { PositionManagerRouter } from "../position-managers/PositionManagerRouter.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { UniswapV3SwapManager } from "../handlers/UniswapV3SwapManager.sol";
import { NettedPositionTracker } from "./NettedPositionTracker.sol";
import { SafeCast } from "./SafeCast.sol";
import { Emitter } from "../peripheral/Emitter.sol";
import { LibAggregateVaultUtils } from "./LibAggregateVaultUtils.sol";

using SafeCast for uint256;
using SafeCast for int256;

using SafeTransferLib for ERC20;

/// @title LibCycle
/// @author Umami Devs
/// @notice A library that contains cycle related logic for rebalancing the vault.
library LibCycle {
    /// @dev only one request can be sent for each LP
    error OnlyOneRequestPerAssetPerEpoch();
    /// @dev the request for the current epoch has already been fulfilled
    error RequestAlreadyFulfilled(bytes32);
    /// @dev Request has not been executed bu the GMX keeper
    error RequestNotExecuted();
    /// @dev Request did not succeed due to an error when fulfilling
    error RequestNotSucceded();

    bytes32 constant CYCLE_STORAGE_SLOT = keccak256("AggregateVaultHelper.cycleStorage");

    struct GMIMintRequest {
        bytes32[] depositKeys;
        uint256[] assetAmounts;
        uint256[] gmAmountsRequired;
        uint256[] gmAmountsMinted;
        address[] markets;
        address asset;
        uint256 targetGMIAmount;
        uint256 gmiMinted;
        bool fulfilled;
    }

    struct GMIBurnRequest {
        bytes32[] withdrawalKeys;
        uint256[] gmAmounts;
        address[] markets;
        address asset;
        uint256 gmiAmount;
        uint256[] usdcReceived;
        uint256[] ethReceived;
        bool fulfilled;
    }

    struct StorageCycle {
        mapping(bytes32 => GMIMintRequest) mintRequests;
        mapping(bytes32 => GMIBurnRequest) burnRequests;
    }

    function _getCycleStorage() internal pure returns (StorageCycle storage _storage) {
        bytes32 slot = CYCLE_STORAGE_SLOT;

        assembly {
            _storage.slot := slot
        }
    }

    /// @dev returns the burn request key for an asset and epoch to be used as reference
    function _getMintBurnRequestKey(address _asset, uint256 _epoch) internal pure returns (bytes32) {
        return keccak256(abi.encode(_asset, _epoch));
    }

    /// @dev sets a key in storage for a mint request to be used as reference when validating it
    function _setMintRequest(address _asset, uint256 _epoch, GMIMintRequest memory _mintRequest) internal {
        bytes32 key = _getMintBurnRequestKey(_asset, _epoch);
        if (_getCycleStorage().mintRequests[key].asset != address(0)) revert OnlyOneRequestPerAssetPerEpoch();
        _getCycleStorage().mintRequests[key] = _mintRequest;
        _emitter().emitMintRequest(_asset, _epoch, _mintRequest);
    }

    /// @dev sets a key in storage for a burn request to be used as reference when validating it
    function _setBurnRequest(address _asset, uint256 _epoch, GMIBurnRequest memory _burnRequest) internal {
        bytes32 key = _getMintBurnRequestKey(_asset, _epoch);
        if (_getCycleStorage().burnRequests[key].asset != address(0)) revert OnlyOneRequestPerAssetPerEpoch();
        _getCycleStorage().burnRequests[key] = _burnRequest;
        _emitter().emitBurnRequest(_asset, _epoch, _burnRequest);
    }

    /// @dev used to clear all requests for an epoch when resetting the storage via controller
    function clearMintBurnRequestForEpoch(uint256 _epoch) external {
        bytes32 usdcKey = _getMintBurnRequestKey(TOKEN_USDC_NATIVE, _epoch);
        bytes32 ethKey = _getMintBurnRequestKey(TOKEN_WETH, _epoch);

        GMIMintRequest memory gmiMintRequest;
        GMIBurnRequest memory gmiBurnRequest;

        _getCycleStorage().mintRequests[usdcKey] = gmiMintRequest;
        _getCycleStorage().burnRequests[usdcKey] = gmiBurnRequest;

        _getCycleStorage().mintRequests[ethKey] = gmiMintRequest;
        _getCycleStorage().burnRequests[ethKey] = gmiBurnRequest;
    }

    /**
     * @notice cycle settles internal PnL and can request a GM token rebalance in GMI
     * @param shouldRebalanceGmi if the GMI should be rebalanced this round
     * @return mintRequests any mint requests that were submitted this cycle
     * @return burnRequests any burn requests that were submitted this cycle
     */
    function cycle(bool shouldRebalanceGmi)
        external
        returns (GMIMintRequest[2] memory mintRequests, GMIBurnRequest[2] memory burnRequests)
    {
        // settle internal netted pnl only after first round
        AggregateVaultStorage.VaultState storage vaultState = LibAggregateVaultStorage.getVaultState();
        int256[2] memory prices = LibAggregateVaultUtils.getVaultTokenPrices(true);
        uint256 gmiPrice = Pricing.getIndexPps(_getOracleWrapper(), _gmi());
        if (vaultState.epoch > 0) {
            _settleInternalPnl(prices, gmiPrice);
        }
        // update next netting prices
        _updateNettingCheckpointPrice(prices, vaultState.epoch + 1);

        // rebalance glp
        return shouldRebalanceGmi ? rebalanceGmiFromRebalanceState(gmiPrice) : (mintRequests, burnRequests);
    }

    /**
     * @dev This contains logic for rebalancing the GMI held by the vaults and minting/burning the underlying of GMI
     * @param _gmiPrice current GMI price to rebalance from
     * @return _mintRequests any mint requests that were submitted
     * @return _burnRequests any burn requests that were submitted
     */
    function rebalanceGmiFromRebalanceState(uint256 _gmiPrice)
        internal
        returns (GMIMintRequest[2] memory _mintRequests, GMIBurnRequest[2] memory _burnRequests)
    {
        AggregateVaultStorage.RebalanceState storage rebalanceState = LibAggregateVaultStorage.getRebalanceState();
        uint256[2] memory targetUsd = rebalanceState.indexAllocation;
        uint256[2] memory targetShares = [targetUsd[0] * 1e18 / _gmiPrice, targetUsd[1] * 1e18 / _gmiPrice];
        uint256[2] memory currentShares = LibAggregateVaultUtils.getVaultsGmi(0, true);
        _emitter().emitRebalanceGmiFromState(targetUsd, targetShares, currentShares);
        return rebalanceGmi(currentShares, targetShares, _gmiPrice);
    }

    /**
     * @notice rebalances the GMI using USD as a numeraire
     * @param _gmiPrice current GMI price to rebalance from
     * @return _mintRequests any mint requests that were submitted
     * @return _burnRequests any burn requests that were submitted
     */
    function rebalanceGmiUsd(uint256[2] memory _current, uint256[2] memory _target, uint256 _gmiPrice)
        internal
        returns (GMIMintRequest[2] memory _mintRequests, GMIBurnRequest[2] memory _burnRequests)
    {
        uint256[2] memory targetShares = [_target[0] * 1e18 / _gmiPrice, _target[1] * 1e18 / _gmiPrice];
        uint256[2] memory currentShares = [_current[0] * 1e18 / _gmiPrice, _current[1] * 1e18 / _gmiPrice];
        return rebalanceGmi(currentShares, targetShares, _gmiPrice);
    }

    /**
     * @dev This contains logic for rebalancing the GMI held by the vaults and minting/burning the underlying of GMI
     * @param _current current GMI in USD held by vaults
     * @param _target target GMI in USD held by vaults
     * @param _gmiPrice current GMI price to rebalance from
     * @return _mintRequests any mint requests that were submitted
     * @return _burnRequests any burn requests that were submitted
     */
    function rebalanceGmi(uint256[2] memory _current, uint256[2] memory _target, uint256 _gmiPrice)
        internal
        returns (GMIMintRequest[2] memory _mintRequests, GMIBurnRequest[2] memory _burnRequests)
    {
        bool isUsdcBurn = _target[0] < _current[0];
        bool isEthBurn = _target[1] < _current[1];
        bool isOppositeDirection = isUsdcBurn != isEthBurn;

        // internally swap gmi for native asset for internally
        // settlable swap amount of gmi tokens
        if (isOppositeDirection) {
            uint256 deltaUsdc = isUsdcBurn ? _current[0] - _target[0] : _target[0] - _current[0];
            uint256 deltaEth = isEthBurn ? _current[1] - _target[1] : _target[1] - _current[1];
            // min of the two
            uint256 internalNet = deltaUsdc > deltaEth ? deltaEth : deltaUsdc;
            uint256 internalNetUsd = internalNet * _gmiPrice / 1e18;
            int256[2] memory prices = LibAggregateVaultUtils.getVaultTokenPrices(true);

            // swap vault assets for internal net
            if (isUsdcBurn) {
                uint256 ethAmount = internalNetUsd * 1e18 / uint256(prices[1]);
                _swap(true, ethAmount);
            } else {
                uint256 usdcAmount = internalNetUsd * 1e6 / uint256(prices[0]);
                _swap(false, usdcAmount);
            }

            uint256 totalGmi = _gmi().balanceOf(address(this));

            // act as if internal netted was the current state
            if (isUsdcBurn) {
                _current[0] = _current[0] - internalNet;
                _commitGmiDeltaProportions(0, -int256(internalNet), totalGmi);
                totalGmi = totalGmi - internalNet;

                _current[1] = _current[1] + internalNet;
                _commitGmiDeltaProportions(1, int256(internalNet), totalGmi);
            } else {
                _current[0] = _current[0] + internalNet;
                _commitGmiDeltaProportions(0, int256(internalNet), totalGmi);
                totalGmi = totalGmi + internalNet;

                _current[1] = _current[1] - internalNet;
                _commitGmiDeltaProportions(1, -int256(internalNet), totalGmi);
            }
        }

        // PERF: refactor to aggregate the mint/burn requests for both vaults to reduce
        // execution fees
        for (uint256 i = 0; i < 2; i++) {
            AggregateVaultStorage.AssetVaultStorage storage assetVault = _getStorage().vaults[i];
            address asset = assetVault.token;

            if (_target[i] > _current[i]) {
                _mintRequests[i] = _increaseGMI(asset, _target[i] - _current[i]);
            }
            // covers the do nothing on delta 0 case
            else if (_target[i] < _current[i]) {
                uint256 gmiDelta = _current[i] - _target[i];
                _burnRequests[i] = _decreaseGMI(asset, gmiDelta);
                // need to commit here because burning gmi is atomic, while minting is not
                // minting is committed in fulfilMint
                GMI gmi = GMI(_getStorage().gmi);
                uint256 prevTotal = gmi.balanceOf(address(this)) + gmiDelta;
                _commitGmiDeltaProportions(i, -int256(gmiDelta), prevTotal);
            }
        }
    }

    /**
     * @notice request an increase in GM tokens held using a quote from GMI
     * @param _asset the underlying of the vault to use for minting
     * @param _delta the delta of GMI
     * @return _mintRequest the returned GMI mint request
     */
    function _increaseGMI(address _asset, uint256 _delta) internal returns (GMIMintRequest memory _mintRequest) {
        GMI gmi = GMI(_getStorage().gmi);
        address oracle = _getStorage().oracleWrapper;
        GmxStorage.MarketPrices[] memory marketPrices = Pricing.getMarketPrices(oracle, gmi, true);
        uint256[] memory gmSharesRequired = gmi.previewMint(_delta, _asset, marketPrices);

        address[] memory markets = gmi.indexAssets();
        bytes32[] memory depositKeys = new bytes32[](markets.length);
        uint256[] memory assetAmounts = new uint256[](markets.length);
        uint256 epoch = LibAggregateVaultStorage.getVaultState().epoch;
        require(markets.length == 4, "markets.length != 4");
        for (uint256 i = 0; i < markets.length; i++) {
            if (gmSharesRequired[i] > 0) {
                uint256 assetAmountRequired = _previewGmMint(markets[i], gmSharesRequired[i], _asset);
                if (assetAmountRequired == 0) {
                    gmSharesRequired[i] = 0;
                    continue;
                }
                assetAmounts[i] = assetAmountRequired;
                depositKeys[i] = _mintGmWithAsset(markets[i], _asset, assetAmountRequired);
            }
        }
        _mintRequest = GMIMintRequest({
            depositKeys: depositKeys,
            assetAmounts: assetAmounts,
            gmAmountsRequired: gmSharesRequired,
            gmAmountsMinted: new uint256[](markets.length),
            markets: markets,
            asset: _asset,
            targetGMIAmount: _delta,
            fulfilled: false,
            gmiMinted: 0
        });
        _setMintRequest(_asset, epoch, _mintRequest);
    }

    /**
     * @notice request an decrease in GM tokens held using a quote from GMI
     * @param _asset the underlying of the vault to use for burning
     * @param _delta the delta of GMI
     * @return _burnRequest the returned GMI burn request
     */
    function _decreaseGMI(address _asset, uint256 _delta) internal returns (GMIBurnRequest memory _burnRequest) {
        GMI gmi = GMI(_getStorage().gmi);
        address oracle = _getStorage().oracleWrapper;
        GmxStorage.MarketPrices[] memory marketPrices = Pricing.getMarketPrices(oracle, gmi, true);
        uint256[] memory gmSharesReceived = gmi.redeem(_delta, address(this), address(this), marketPrices);
        address[] memory markets = gmi.indexAssets();
        bytes32[] memory withdrawalKeys = new bytes32[](markets.length);
        for (uint256 i = 0; i < markets.length; i++) {
            if (gmSharesReceived[i] > 0) {
                withdrawalKeys[i] = _burnGMForAsset(markets[i], gmSharesReceived[i]);
            }
        }
        uint256 epoch = LibAggregateVaultStorage.getVaultState().epoch;
        _burnRequest = GMIBurnRequest({
            withdrawalKeys: withdrawalKeys,
            gmAmounts: gmSharesReceived,
            asset: _asset,
            markets: markets,
            gmiAmount: _delta,
            usdcReceived: new uint256[](4),
            ethReceived: new uint256[](4),
            fulfilled: false
        });
        _setBurnRequest(_asset, epoch, _burnRequest);
    }

    /// @dev requests a burn GM
    function _burnGMForAsset(address _market, uint256 _amt) internal returns (bytes32 _withdrawKey) {
        bytes memory cd = abi.encodeCall(IGmxV2Handler.burnGmTokens, (_market, _amt, address(this)));
        bytes memory ret = Delegatecall.delegateCall(address(_gmxV2Handler()), cd);
        _withdrawKey = abi.decode(ret, (bytes32));
    }

    /// @dev requests a mint GM
    function _mintGmWithAsset(address _market, address _asset, uint256 _amt) internal returns (bytes32 _depositKey) {
        (uint256 amountEth, uint256 amountUsdc) = _asset == TOKEN_WETH ? (_amt, uint256(0)) : (uint256(0), _amt);
        bytes memory cd = abi.encodeCall(IGmxV2Handler.mintGmTokens, (_market, amountEth, amountUsdc, address(this)));
        bytes memory ret = Delegatecall.delegateCall(address(_gmxV2Handler()), cd);
        _depositKey = abi.decode(ret, (bytes32));
    }

    /// @dev previews a mint GM
    function _previewGmMint(address _gm, uint256 _gmAmount, address _asset) internal returns (uint256 _assetAmount) {
        address oracle = _getStorage().oracleWrapper;
        uint256 gmPrice = _gmTokenPrice(oracle, _gm, true); // 30 decimals
        uint256 tokenPrice = Pricing.getTokenPrice(oracle, _asset, true); // 1 wei token's price, oneToken's price is 30 decimals
        _assetAmount = (_gmAmount * gmPrice / 1e18) / tokenPrice;
    }

    /// @dev get the token price of a GM token, has a flag whether to use the LLO or onchain price
    function _gmTokenPrice(address _oracleWrapper, address _gm, bool _withLlo) internal returns (uint256) {
        GmxStorage.MarketPrices memory marketPrice = Pricing.getMarketPrice(_oracleWrapper, _gm, _withLlo);
        IGmxV2Handler gmxV2Handler = _gmxV2Handler();
        bytes memory gmMidPriceCalldata = abi.encodeCall(IGmxV2Handler.getGmMidPrice, (_gm, marketPrice));
        bytes memory ret = Delegatecall.delegateCall(address(gmxV2Handler), gmMidPriceCalldata);
        return abi.decode(ret, (uint256));
    }

    /// @dev gets the gmxV2Handler from storage
    function _gmxV2Handler() internal view returns (IGmxV2Handler) {
        return IGmxV2Handler(_getStorage().gmxV2Handler);
    }

    /**
     * @notice Called after all requests have been executed by the GMX keeper. This mints GMI if requred and
     * clears the pending requests from storage as fulfilled
     */
    function fulfilRequests() external {
        uint256 epoch = LibAggregateVaultStorage.getVaultState().epoch;
        address[2] memory assets = [_getStorage().vaults[0].token, _getStorage().vaults[1].token];
        int256[2] memory aggregateFees;
        for (uint256 i = 0; i < assets.length; i++) {
            // NOTE: only 1 GMI mint/burn request per asset per epoch
            bytes32 mintBurnKey = _getMintBurnRequestKey(assets[i], epoch);
            GMIMintRequest memory mintRequest = _getCycleStorage().mintRequests[mintBurnKey];
            if (mintRequest.asset != address(0)) {
                int256[2] memory mintFees = _fulfilMintRequest(mintBurnKey, mintRequest);
                aggregateFees[0] += mintFees[0];
                aggregateFees[1] += mintFees[1];
            }
            GMIBurnRequest memory burnRequest = _getCycleStorage().burnRequests[mintBurnKey];
            if (burnRequest.asset != address(0)) {
                int256[2] memory burnFees = _fulfilBurnRequest(mintBurnKey, burnRequest);
                aggregateFees[0] += burnFees[0];
                aggregateFees[1] += burnFees[1];
            }
        }
        uint256[2] memory toPull =
            [aggregateFees[0] > 0 ? uint256(aggregateFees[0]) : 0, aggregateFees[1] > 0 ? uint256(aggregateFees[1]) : 0];
        LibAggregateVaultUtils.pullFeeAmountsFromEscrow(toPull);
    }

    /**
     * @notice fulfils a mint request, will mint GMI with the tokens recieved
     * @param _key the key of the request
     * @param _mintRequest the mint request in storage
     */
    function _fulfilMintRequest(bytes32 _key, GMIMintRequest memory _mintRequest)
        internal
        returns (int256[2] memory feeAmounts)
    {
        if (_mintRequest.fulfilled) revert RequestAlreadyFulfilled(_key);
        bool isUsdc = _mintRequest.asset == TOKEN_USDC_NATIVE;

        GMI gmi = GMI(_getStorage().gmi);
        uint256 indexSize = gmi.INDEX_SIZE();
        uint256[] memory gmReceived = new uint256[](indexSize);
        for (uint256 i = 0; i < indexSize; i++) {
            if (_mintRequest.gmAmountsRequired[i] > 0 && _mintRequest.assetAmounts[i] > 0) {
                GmxV2HandlerStorage.DepositRequestDetails memory depositRequestDetails =
                    _getDepositRequestDetails(_mintRequest.depositKeys[i]);
                if (!depositRequestDetails.executed) revert RequestNotExecuted();
                if (!depositRequestDetails.success) revert RequestNotSucceded();
                gmReceived[i] = depositRequestDetails.amountMinted;
                feeAmounts[isUsdc ? 0 : 1] += depositRequestDetails.feesPaid
                    / (isUsdc ? int256(depositRequestDetails.usdcPrice) : int256(depositRequestDetails.ethPrice));
                ERC20(_mintRequest.markets[i]).safeApprove(address(gmi), gmReceived[i]);
            }
        }

        GmxStorage.MarketPrices[] memory marketPrices = Pricing.getMarketPrices(_getStorage().oracleWrapper, gmi, true);
        uint256 gmiMinted = gmi.deposit(gmReceived, marketPrices, address(this));
        uint256 prevTotal = gmi.balanceOf(address(this)) - gmiMinted;
        uint256 vaultIdx = LibAggregateVaultStorage.getTokenToAssetVaultIndex()[_mintRequest.asset];
        _commitGmiDeltaProportions(vaultIdx, int256(gmiMinted), prevTotal);

        GMIMintRequest storage s_mintRequest = _getCycleStorage().mintRequests[_key];
        s_mintRequest.gmiMinted = gmiMinted;
        s_mintRequest.fulfilled = true;
        s_mintRequest.gmAmountsMinted = gmReceived;

        _emitter().emitFulfilGmiMintRequest(
            s_mintRequest.targetGMIAmount, gmiMinted, s_mintRequest.gmAmountsRequired, gmReceived
        );
    }

    /**
     * @notice fulfils a burn request, will swap the opposite token to vault token since gmx
     * returns some of both underlying tokens of the market when burning
     * @param _key the key of the request
     * @param _burnRequest the burn request in storage
     */
    function _fulfilBurnRequest(bytes32 _key, GMIBurnRequest memory _burnRequest)
        internal
        returns (int256[2] memory feeAmounts)
    {
        if (_burnRequest.fulfilled) revert RequestAlreadyFulfilled(_key);
        bool isUsdc = _burnRequest.asset == TOKEN_USDC_NATIVE;

        uint256[4] memory usdcReceived;
        uint256[4] memory ethReceived;
        uint256 amountOutTotal;
        for (uint256 i = 0; i < 4; i++) {
            if (_burnRequest.gmAmounts[i] > 0) {
                GmxV2HandlerStorage.WithdrawRequestDetails memory withdrawRequestDetails =
                    _getWithdrawalRequestDetails(_burnRequest.withdrawalKeys[i]);
                if (!withdrawRequestDetails.executed) revert RequestNotExecuted();
                if (!withdrawRequestDetails.success) revert RequestNotSucceded();

                usdcReceived[i] = withdrawRequestDetails.usdcAmountReceived;
                ethReceived[i] = withdrawRequestDetails.wethAmountReceived;

                // swap non-native token for native token
                if (isUsdc) {
                    amountOutTotal = _swap(true, ethReceived[i]) + usdcReceived[i];
                } else {
                    amountOutTotal = _swap(false, usdcReceived[i]) + ethReceived[i];
                }
                feeAmounts[isUsdc ? 0 : 1] += (withdrawRequestDetails.feesPaid)
                    / (isUsdc ? int256(withdrawRequestDetails.usdcPrice) : int256(withdrawRequestDetails.ethPrice));
            }
        }

        GMIBurnRequest storage s_burnRequest = _getCycleStorage().burnRequests[_key];
        s_burnRequest.usdcReceived = usdcReceived;
        s_burnRequest.ethReceived = ethReceived;
        s_burnRequest.fulfilled = true;

        _emitter().emitFulfilGmiBurnRequest(s_burnRequest.gmiAmount, usdcReceived, ethReceived);
    }

    /// @dev gets the details of a request in storage
    function _getDepositRequestDetails(bytes32 _key)
        internal
        returns (GmxV2HandlerStorage.DepositRequestDetails memory)
    {
        address handler = address(_getStorage().gmxV2Handler);
        bytes memory cd = abi.encodeCall(IGmxV2Handler.getDepositRequestDetails, (_key));
        bytes memory ret = Delegatecall.delegateCall(handler, cd);
        return abi.decode(ret, (GmxV2HandlerStorage.DepositRequestDetails));
    }

    /// @dev gets the details of a request in storage
    function _getWithdrawalRequestDetails(bytes32 _key)
        internal
        returns (GmxV2HandlerStorage.WithdrawRequestDetails memory)
    {
        address handler = address(_getStorage().gmxV2Handler);
        bytes memory cd = abi.encodeCall(IGmxV2Handler.getWithdrawRequestDetails, (_key));
        bytes memory ret = Delegatecall.delegateCall(handler, cd);
        return abi.decode(ret, (GmxV2HandlerStorage.WithdrawRequestDetails));
    }

    /// @dev executes a swap using the uniswap manager in storage
    function _swap(bool _ethForUsdc, uint256 _amount) internal returns (uint256 _amountOut) {
        (address tokenIn, address tokenOut) =
            _ethForUsdc ? (TOKEN_WETH, TOKEN_USDC_NATIVE) : (TOKEN_USDC_NATIVE, TOKEN_WETH);
        OracleWrapper ow = OracleWrapper(_getOracleWrapper());
        uint256 ethPrice = ow.getChainlinkPrice(TOKEN_WETH);
        uint256 usdcPrice = ow.getChainlinkPrice(TOKEN_USDC_NATIVE);
        uint256 minOut = _ethForUsdc ? _amount * ethPrice / usdcPrice : _amount * usdcPrice / ethPrice;
        _amountOut = PositionManagerRouter(payable(address(this))).executeSwap(
            ISwapManager(_getStorage().uniswapV3SwapManager),
            tokenIn,
            tokenOut,
            _amount,
            minOut * (1e18 - _getStorage().swapSlippage) / 1e18,
            hex""
        );
    }

    /// @dev commits the changes in GMI held to storage
    function _commitGmiDeltaProportions(uint256 _vaultIdx, int256 _amt, uint256 _prevTotal) internal {
        uint256[2] memory currentAttribution = _getStorage().vaultGmiAttribution;
        uint256 totalAttribution = currentAttribution[0] + currentAttribution[1];
        uint256[2] memory currentProportions;
        if (totalAttribution == 0) {
            currentProportions = [uint256(0), uint256(0)];
        } else {
            currentProportions =
                [currentAttribution[0] * 1e18 / totalAttribution, currentAttribution[1] * 1e18 / totalAttribution];
        }
        uint256[2] memory prevAmounts =
            [_prevTotal * currentProportions[0] / 1e18, _prevTotal * currentProportions[1] / 1e18];

        if (_amt > 0) {
            prevAmounts[_vaultIdx] += uint256(_amt);
            uint256 newTotal = _prevTotal + uint256(_amt);
            currentProportions[0] = prevAmounts[0] * 1e18 / newTotal;
            currentProportions[1] = prevAmounts[1] * 1e18 / newTotal;
        } else {
            prevAmounts[_vaultIdx] -= uint256(-_amt);
            uint256 newTotal = _prevTotal - uint256(-_amt);
            currentProportions[0] = prevAmounts[0] * 1e18 / newTotal;
            currentProportions[1] = prevAmounts[1] * 1e18 / newTotal;
        }
        _getStorage().vaultGmiAttribution = currentProportions;
    }

    function _getStorage() internal pure returns (AggregateVaultStorage.AVStorage storage _storage) {
        _storage = LibAggregateVaultStorage.getStorage();
    }

    function _getOracleWrapper() internal view returns (address _oracleWrapper) {
        _oracleWrapper = _getStorage().oracleWrapper;
    }

    function _gmi() internal view returns (GMI gmIndex) {
        gmIndex = GMI(_getStorage().gmi);
    }

    function _emitter() internal view returns (Emitter emitter) {
        emitter = Emitter(_getStorage().emitter);
    }

    /**
     * @notice Settles the internal PnL for the given asset prices and GMI price
     * @param currentAssetPrices An array of the current asset prices
     * @param gmiPrice The current GMI price
     */
    function _settleInternalPnl(int256[2] memory currentAssetPrices, uint256 gmiPrice) internal {
        uint256[2] memory settledVaultIndexAmount;
        int256[2] memory nettedPnl;
        int256[2] memory indexPnl;
        int256[2] memory percentPriceChange;
        // get the previous allocated glp amount
        uint256[2] memory vaultsGmi = LibAggregateVaultUtils.getVaultsGmi(0, true);
        AggregateVaultStorage.AVStorage storage avs = _getStorage();
        (settledVaultIndexAmount, nettedPnl, indexPnl, percentPriceChange) = NettedPositionTracker
            .settleNettingPositionPnl(
            avs.nettedPositions,
            currentAssetPrices,
            _getNettedPrices(LibAggregateVaultStorage.getVaultState().epoch),
            vaultsGmi,
            gmiPrice,
            avs.zeroSumPnlThreshold
        );
        // while this is set here to gmi amount, the read and usage is always x / total
        // as proportions, its because the GMI amount in storage and real amounts
        // are not going to match because of mint/burn slippage differences, etc.
        avs.vaultGmiAttribution = settledVaultIndexAmount;
        Emitter(avs.emitter).emitSettleNettedPositionPnl(
            vaultsGmi, settledVaultIndexAmount, indexPnl, nettedPnl, percentPriceChange
        );
    }

    function _getNettedPrices(uint256 _epoch) internal view returns (int256[2] memory _nettedPrices) {
        _nettedPrices = _getStorage().lastNettedPrices[_epoch];
    }

    /// @dev updates the checkpoint prices in storage for calculating the next internal positions
    function _updateNettingCheckpointPrice(int256[2] memory _prices, uint256 epochId) internal {
        int256[2] memory prices = _getStorage().lastNettedPrices[epochId];
        require(prices[0] == 0, "AggregateVault: lastNettedPrices already inited for given epoch");
        AggregateVaultStorage.AVStorage storage avs = _getStorage();
        avs.lastNettedPrices[epochId] = _prices;
        Emitter(avs.emitter).emitUpdateNettingCheckpointPrice(_getStorage().lastNettedPrices[epochId - 1], _prices);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

bytes32 constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR");
bytes32 constant AGGREGATE_VAULT_ROLE = keccak256("AGGREGATE_VAULT");
bytes32 constant REQUEST_HANDLER = keccak256("REQUEST_HANDLER");
bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
bytes32 constant EXECUTION_KEEPER = keccak256("EXECUTION_KEEPER");
bytes32 constant SWAP_KEEPER = keccak256("SWAP_KEEPER");

/// @title Auth
/// @author Umami Devs
/// @notice Simple centralized ACL
contract Auth {
    /// @dev user not authorized with given role
    error NotAuthorized(bytes32 _role, address _user);

    event RoleUpdated(bytes32 indexed role, address indexed user, bool authorized);

    bytes32 public constant AUTH_MANAGER_ROLE = keccak256("AUTH_MANAGER");
    mapping(bytes32 => mapping(address => bool)) public hasRole;

    constructor() {
        _updateRole(msg.sender, AUTH_MANAGER_ROLE, true);
    }

    function updateRole(address _user, bytes32 _role, bool _authorized) external {
        onlyRole(AUTH_MANAGER_ROLE, msg.sender);
        _updateRole(_user, _role, _authorized);
    }

    function onlyRole(bytes32 _role, address _user) public view {
        if (!hasRole[_role][_user]) {
            revert NotAuthorized(_role, _user);
        }
    }

    function _updateRole(address _user, bytes32 _role, bool _authorized) internal {
        hasRole[_role][_user] = _authorized;
        emit RoleUpdated(_role, _user, _authorized);
    }
}

/// @title GlobalACL
/// @author Umami Devs
abstract contract GlobalACL {
    Auth public immutable AUTH;

    constructor(Auth _auth) {
        require(address(_auth) != address(0), "GlobalACL: zero address");
        AUTH = _auth;
    }

    modifier onlyConfigurator() {
        AUTH.onlyRole(CONFIGURATOR_ROLE, msg.sender);
        _;
    }

    modifier onlyAggregateVault() {
        AUTH.onlyRole(AGGREGATE_VAULT_ROLE, msg.sender);
        _;
    }

    modifier onlyRequestHandler() {
        AUTH.onlyRole(REQUEST_HANDLER, msg.sender);
        _;
    }

    modifier onlyExecutionKeeper() {
        AUTH.onlyRole(EXECUTION_KEEPER, msg.sender);
        _;
    }

    modifier onlyRole(bytes32 _role) {
        AUTH.onlyRole(_role, msg.sender);
        _;
    }
}

import { Auth, GlobalACL } from "../Auth.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { StorageViewer } from "./StorageViewer.sol";
import { TOKEN_USDC_NATIVE, TOKEN_WETH } from "src/constants.sol";

using SafeTransferLib for ERC20;

contract FeeReserve is GlobalACL {
    error FeeReserve__BalanceNotEnough();
    error FeeReserve__AlreadyClaimed();

    StorageViewer public immutable storageViewer;
    uint256 public usdcFeePerEpoch;
    uint256 public wethFeePerEpoch;
    address public keeper;
    mapping(uint256 => bool) claimed;

    constructor(Auth _auth, StorageViewer _storageViewer, uint256 _usdcFee, uint256 _wethFee, address _keeper)
        GlobalACL(_auth)
    {
        storageViewer = _storageViewer;
        usdcFeePerEpoch = _usdcFee;
        wethFeePerEpoch = _wethFee;
        keeper = _keeper;
    }

    function setFeesPerEpoch(uint256 _usdcFee, uint256 _wethFee) external onlyConfigurator {
        usdcFeePerEpoch = _usdcFee;
        wethFeePerEpoch = _wethFee;
    }

    function setKeeper(address _keeper) external onlyConfigurator {
        keeper = _keeper;
    }

    function pullAsset(address _asset, uint256 _amt, bool _revert) external onlyAggregateVault returns (uint256) {
        return _transfer(_asset, msg.sender, _amt, _revert);
    }

    function pullKeeperFees() external onlyAggregateVault {
        uint256 currentEpoch = storageViewer.getEpoch();
        if (claimed[currentEpoch]) {
            revert FeeReserve__AlreadyClaimed();
        }
        claimed[currentEpoch] = true;
        _transfer(TOKEN_USDC_NATIVE, keeper, usdcFeePerEpoch, false);
        _transfer(TOKEN_WETH, keeper, wethFeePerEpoch, false);
    }

    function _transfer(address _asset, address _to, uint256 _amt, bool _revert) internal returns (uint256) {
        uint256 balance = ERC20(_asset).balanceOf(address(this));
        if (_amt > balance && _revert) revert FeeReserve__BalanceNotEnough();
        uint256 amtToSend = _amt > balance ? balance : _amt;
        if (amtToSend > 0) {
            ERC20(_asset).safeTransfer(_to, amtToSend);
        }
        return amtToSend;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { GlobalACL } from "../Auth.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { AggregateVault } from "src/vaults/AggregateVault.sol";

uint256 constant PRECISION = 1e18;

/// @title Vester
/// @author Umami Devs
/// @notice Vester contract to vest deposit and withdraw fee surplus into the aggregate vault
contract Vester is GlobalACL {
    using SafeTransferLib for ERC20;

    event SetVestDuration(uint256 previousVestDuration, uint256 newVestDuration);
    event Claimed(address indexed token, uint256 amount);
    event AddVest(address indexed token, uint256 amount);

    error VestingPerSecondTooLow();

    address public immutable aggregateVault;

    struct VestingInfo {
        uint256 vestingPerSecond;
        uint256 lastClaim;
    }

    mapping(address => VestingInfo) public vestingInfo;
    uint256 public vestDuration;

    constructor(AggregateVault _aggregateVault, uint256 _vestDuration) GlobalACL(_aggregateVault.AUTH()) {
        aggregateVault = address(_aggregateVault);
        _setVestDuration(_vestDuration);
    }

    /**
     * @notice Set the vest duration
     * @param _vestDuration The new vest duration
     */
    function setVestDuration(uint256 _vestDuration) external onlyConfigurator {
        _setVestDuration(_vestDuration);
    }

    /**
     * @notice Claim vested tokens into aggregate vault
     * @param _asset The asset to claim
     */
    function claim(address _asset) public returns (uint256) {
        uint256 _vested = vested(_asset);
        if (_vested == 0) return 0;

        vestingInfo[_asset].lastClaim = block.timestamp;
        emit Claimed(_asset, _vested);

        ERC20(_asset).safeTransfer(aggregateVault, _vested);
        return _vested;
    }

    /**
     * @notice Add new vesting tokens
     * @param _asset The asset to vest
     * @param _amount The amount to vest
     */
    function addVest(address _asset, uint256 _amount) external {
        claim(_asset);

        emit AddVest(_asset, _amount);
        ERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentBalance = ERC20(_asset).balanceOf(address(this));

        uint256 vestingPerSecond = currentBalance * PRECISION / vestDuration;
        if (vestingPerSecond == 0) revert VestingPerSecondTooLow();

        vestingInfo[_asset] = VestingInfo({ vestingPerSecond: vestingPerSecond, lastClaim: block.timestamp });
    }

    /**
     * Get vested amount of an asset
     * @param _asset The asset to get vested amount of
     * @return The vested amount
     */
    function vested(address _asset) public view returns (uint256) {
        uint256 duration = block.timestamp - vestingInfo[_asset].lastClaim;
        uint256 totalVested = duration * vestingInfo[_asset].vestingPerSecond / PRECISION;
        uint256 totalBalance = ERC20(_asset).balanceOf(address(this));
        return totalVested > totalBalance ? totalBalance : totalVested;
    }

    function _setVestDuration(uint256 _newVestDuration) internal {
        uint256 previousVestDuration = vestDuration;
        vestDuration = _newVestDuration;
        emit SetVestDuration(previousVestDuration, _newVestDuration);
    }
}

pragma solidity 0.8.17;

enum HookType {
    DEPOSIT_HOOK,
    WITHDRAW_HOOK,
    OPEN_REBALANCE_HOOK,
    CLOSE_REBALANCE_HOOK
}

interface IHookExecutor {
    function executeHook(HookType _type, bytes calldata _data) external returns (bytes memory);
}

pragma solidity 0.8.17;

interface IArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.17;

interface IHandlerContract {
    function callbackSigs() external pure returns (bytes4[] memory);
}

pragma solidity 0.8.17;

import { Auth, GlobalACL } from "../Auth.sol";
import { Multicall } from "../libraries/Multicall.sol";
import { IPositionManager } from "../interfaces/IPositionManager.sol";
import { IHandlerContract } from "../interfaces/IHandlerContract.sol";
import { ISwapManager } from "../interfaces/ISwapManager.sol";
import { Delegatecall } from "../libraries/Delegatecall.sol";

contract WhitelistedTokenRegistry is GlobalACL {
    event UpdatedWhitelistedToken(address indexed _token, bool _isWhitelisted);
    event UpdatedIsWhitelistingEnabled(bool _isEnabled);

    /// @notice whitelisted tokens to/from which swaps allowed
    mapping(address => bool) public whitelistedTokens;
    /// @notice whitelisting in effect
    bool public isWhitelistingEnabled = true;

    constructor(Auth _auth) GlobalACL(_auth) { }

    function updateWhitelistedToken(address _token, bool _isWhitelisted) external onlyConfigurator {
        whitelistedTokens[_token] = _isWhitelisted;
        emit UpdatedWhitelistedToken(_token, _isWhitelisted);
    }

    function updateIsWhitelistingEnabled(bool _isWhitelistingEnabled) external onlyConfigurator {
        isWhitelistingEnabled = _isWhitelistingEnabled;
        emit UpdatedIsWhitelistingEnabled(_isWhitelistingEnabled);
    }

    function isWhitelistedToken(address _token) external view returns (bool) {
        if (isWhitelistingEnabled) {
            return whitelistedTokens[_token];
        }
        return true;
    }
}

library PositionManagerRouterLib {
    error NotWhitelistedToken();
    error UnknownHandlerContract();

    function executeSwap(
        ISwapManager _swapManager,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minOut,
        bytes calldata _data,
        WhitelistedTokenRegistry whitelistedTokenRegistry,
        mapping(ISwapManager => bool) storage swapHandlers,
        mapping(IHandlerContract => bool) storage handlerContracts
    ) external returns (uint256 _amountOut) {
        if (
            !whitelistedTokenRegistry.isWhitelistedToken(_tokenIn)
                || !whitelistedTokenRegistry.isWhitelistedToken(_tokenOut)
        ) revert NotWhitelistedToken();

        bool isSwapHandler = swapHandlers[_swapManager];
        bool isHandler = handlerContracts[_swapManager];
        if (!isSwapHandler || !isHandler) {
            revert UnknownHandlerContract();
        }

        bytes memory ret = _delegatecall(
            address(_swapManager), abi.encodeCall(ISwapManager.swap, (_tokenIn, _tokenOut, _amountIn, _minOut, _data))
        );
        (_amountOut) = abi.decode(ret, (uint256));
    }

    function _delegatecall(address _target, bytes memory _data) internal returns (bytes memory ret) {
        bool success;
        (success, ret) = _target.delegatecall(_data);
        if (!success) {
            /// @solidity memory-safe-assembly
            assembly {
                let length := mload(ret)
                let start := add(ret, 0x20)
                revert(start, length)
            }
        }
        return ret;
    }
}

/**
 * @title PositionManagerRouter
 * @author Umami DAO
 * @dev This abstract contract is a base implementation for a position manager router.
 *      It handles execution, callbacks, and swap operations on handler contracts.
 */
abstract contract PositionManagerRouter {
    using Delegatecall for address;

    error UnknownCallback();
    error CallbackHandlerNotSet();
    error UnknownHandlerContract();
    error OnlySelf();
    error NotWhitelistedToken();

    /// @dev Emitted when a callback handler is updated.
    event CallbackHandlerUpdated(bytes4 indexed _sig, address indexed _handler, bool _enabled);

    /// @dev Emitted when a handler contract is updated.
    event HandlerContractUpdated(address indexed _contract, bool _enabled);

    /// @dev Emitted when a default handler contract is updated.
    event DefaultHandlerContractUpdated(bytes4 indexed _sig, address indexed _handler);

    /// @dev Emitted when a swap handler is updated.
    event SwapHandlerUpdated(address indexed _handled, bool _enabled);
    event WhitelistedTokenUpdated(address indexed _token, bool _isWhitelisted);

    /// @notice mapping of handler contracts and callbacks they can handle
    mapping(IHandlerContract => mapping(bytes4 => bool)) public handlerContractCallbacks;

    /// @notice mapping of allowed handler contracts
    mapping(IHandlerContract => bool) public handlerContracts;

    /// @notice current handler contract, set when `executeWithCallbackHandler` called.
    ///         Useful when multiple handlers can handle same callback. So you specify
    ///         which handler to call.
    address public currentCallbackHandler;

    /// @notice mapping of default handlers for a given method. This is used if currentCallbackHandler
    ///         is not set.
    mapping(bytes4 => IHandlerContract) public defaultHandlers;

    /// @notice whitelisted swap handlers
    mapping(ISwapManager => bool) public swapHandlers;
    /// @notice Whitelisted token registry
    WhitelistedTokenRegistry immutable whitelistedTokenRegistry;

    constructor(WhitelistedTokenRegistry _registry) {
        whitelistedTokenRegistry = _registry;
    }

    /**
     * @notice Updates the handler contract and its associated callbacks.
     * @param _handler The handler contract to be updated.
     * @param _enabled Whether the handler should be enabled or disabled.
     */
    function updateHandlerContract(IHandlerContract _handler, bool _enabled) public {
        _onlyConfigurator();
        handlerContracts[_handler] = _enabled;
        emit HandlerContractUpdated(address(_handler), _enabled);
        _updateHandlerContractCallbacks(_handler, _enabled);
    }

    /**
     * @notice Updates the default handler contract for a given method signature.
     * @param _sig The method signature of the default handler.
     * @param _handler The handler contract to be set as the default for the given method.
     */
    function updateDefaultHandlerContract(bytes4 _sig, IHandlerContract _handler) external {
        _onlyConfigurator();
        defaultHandlers[_sig] = _handler;
        emit DefaultHandlerContractUpdated(_sig, address(_handler));
    }

    /**
     * @notice Updates a swap handler and its associated handler contract.
     * @param _manager The swap manager to be updated.
     * @param _enabled Whether the swap handler should be enabled or disabled.
     */
    function updateSwapHandler(ISwapManager _manager, bool _enabled) external {
        _onlyConfigurator();
        updateHandlerContract(_manager, _enabled);
        swapHandlers[_manager] = _enabled;
        emit SwapHandlerUpdated(address(_manager), _enabled);
    }

    /**
     * @notice Executes a call to a handler contract.
     * @param _handler The handler contract to be called.
     * @param data The data to be sent to the handler contract.
     * @return ret The returned data from the handler contract.
     */
    function execute(address _handler, bytes calldata data) public payable returns (bytes memory ret) {
        bool isSwapHandler = swapHandlers[ISwapManager(_handler)];
        if (isSwapHandler) {
            if (msg.sender != address(this)) {
                revert OnlySelf();
            }
        } else {
            _validateExecuteCallAuth();
        }
        bool isHandler = handlerContracts[IHandlerContract(_handler)];
        if (!isHandler) revert UnknownHandlerContract();
        ret = _handler.delegateCall(data);
    }

    /**
     * @notice Executes a call to a handler contract with the specified `currentCallbackHandler`.
     * @dev `execute` with `currentCallbackHandler` set. Useful when multiple handlers can handle a callback.abi
     *       E.g.: Flash loan callbacks, swap callbacks, etc.
     * @param _handler The handler contract to be called.
     * @param data The data to be sent to the handler contract.
     * @param _callbackHandler The callback handler to be used for this execution.
     * @return ret The returned data from the handler contract.
     */
    function executeWithCallbackHandler(address _handler, bytes calldata data, address _callbackHandler)
        external
        payable
        withHandler(_callbackHandler)
        returns (bytes memory ret)
    {
        ret = execute(_handler, data);
    }

    /**
     * @notice Executes a swap against a swap manager.
     * @dev execute swap against a swap manager
     * @param _swapManager The swap manager to execute the swap against.
     * @param _tokenIn The token being provided for the swap.
     * @param _tokenOut The token being requested from the swap.
     * @param _amountIn The amount of `_tokenIn` being provided for the swap.
     * @param _minOut The minimum amount of `_tokenOut` to be received from the swap.
     * @param _data Additional data to be passed to the swap manager.
     * @return _amountOut The amount of `_tokenOut` received from the swap.
     */
    function executeSwap(
        ISwapManager _swapManager,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minOut,
        bytes calldata _data
    ) external returns (uint256 _amountOut) {
        if (msg.sender != address(this)) {
            _onlySwapIssuer();
        }
        _amountOut = PositionManagerRouterLib.executeSwap(
            _swapManager,
            _tokenIn,
            _tokenOut,
            _amountIn,
            _minOut,
            _data,
            whitelistedTokenRegistry,
            swapHandlers,
            handlerContracts
        );
    }

    /**
     * @dev Fallback function which handles callbacks from external contracts.
     *      It forwards the call to the appropriate handler, either the
     *      `currentCallbackHandler` or the default handler for the method signature.
     *      This is necessary to have callback handlers defined in position managers and swap handlers.
     */
    fallback() external payable {
        bytes memory _ret = _handleCallback();

        // bubble up the returned data from the handler
        /// @solidity memory-safe-assembly
        assembly {
            let length := mload(_ret)
            return(add(_ret, 0x20), length)
        }
    }

    /// @dev To be implemented by inheriting contracts to restrict certain functions to a configurator role.
    function _onlyConfigurator() internal virtual;

    /// @dev To be implemented by inheriting contracts to restrict certain functions to a swap issuer role.
    function _onlySwapIssuer() internal virtual;

    /// @dev To be implemented by inheriting contracts to validate the caller's authorization for execute calls.
    function _validateExecuteCallAuth() internal virtual;

    /**
     * @dev Updates the handler contract callbacks based on the provided `_handler` and `_enabled` status.
     * @param _handler The handler contract to update the callbacks for.
     * @param _enabled Whether the handler contract's callbacks should be enabled or disabled.
     */
    function _updateHandlerContractCallbacks(IHandlerContract _handler, bool _enabled) internal {
        bytes4[] memory handlerSigs = _handler.callbackSigs();
        unchecked {
            for (uint256 i = 0; i < handlerSigs.length; ++i) {
                bytes4 sig = handlerSigs[i];
                handlerContractCallbacks[_handler][sig] = _enabled;
                emit CallbackHandlerUpdated(sig, address(_handler), _enabled);
            }
        }
    }

    /**
     * @dev Handles a callback, i.e. an unknown method that this contract is
     *      not capable of handling.
     *      First tries to check and call `currentCallbackHandler` if it is
     *      set. If it is not set, check and call `defaultHandlers[msg.sig]`.
     *      Also validates that the handler contract is capable of handling
     *      this specific callback.
     * @return ret The returned data from the handler.
     */
    function _handleCallback() internal returns (bytes memory ret) {
        IHandlerContract handler = IHandlerContract(currentCallbackHandler);

        // no transient callback handler set
        if (address(handler) == address(0)) {
            // check if default handler exist for given sig
            handler = defaultHandlers[msg.sig];
            if (handler == IHandlerContract(address(0))) {
                revert CallbackHandlerNotSet();
            }
        }

        if (!handlerContracts[handler]) revert UnknownHandlerContract();

        if (!handlerContractCallbacks[handler][msg.sig]) {
            revert UnknownCallback();
        }

        ret = address(handler).delegateCall(msg.data);
    }

    /**
     * @dev Modifier to ensure the specified `_handler` is a valid handler contract.
     * @param _handler The address of the handler contract to validate.
     */
    modifier withHandler(address _handler) {
        if (!handlerContracts[IHandlerContract(_handler)]) {
            revert UnknownHandlerContract();
        }

        currentCallbackHandler = _handler;
        _;
        currentCallbackHandler = address(0);
    }

    /// @dev Modifier to ensure the caller of the function is the contract itself.
    modifier onlySelf() {
        if (msg.sender != address(this)) revert OnlySelf();
        _;
    }

    /// @dev External payable function to receive funds.
    receive() external payable { }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../data/DataStore.sol";
import "../event/EventEmitter.sol";
import "../bank/StrictBank.sol";

import "./Market.sol";
import "./MarketPoolValueInfo.sol";
import "./MarketToken.sol";
import "./MarketEventUtils.sol";
import "./MarketStoreUtils.sol";

import "../position/Position.sol";
import "../order/Order.sol";

import "../oracle/Oracle.sol";
import "../price/Price.sol";

import "../utils/Calc.sol";
import "../utils/Precision.sol";

// @title MarketUtils
// @dev Library for market functions
library MarketUtils {
    using SignedMath for int256;
    using SafeCast for int256;
    using SafeCast for uint256;

    using Market for Market.Props;
    using Position for Position.Props;
    using Order for Order.Props;
    using Price for Price.Props;

    enum FundingRateChangeType {
        NoChange,
        Increase,
        Decrease
    }

    // @dev struct to store the prices of tokens of a market
    // @param indexTokenPrice price of the market's index token
    // @param longTokenPrice price of the market's long token
    // @param shortTokenPrice price of the market's short token
    struct MarketPrices {
        Price.Props indexTokenPrice;
        Price.Props longTokenPrice;
        Price.Props shortTokenPrice;
    }

    struct CollateralType {
        uint256 longToken;
        uint256 shortToken;
    }

    struct PositionType {
        CollateralType long;
        CollateralType short;
    }

    // @dev struct for the result of the getNextFundingAmountPerSize call
    // note that abs(nextSavedFundingFactorPerSecond) may not equal the fundingFactorPerSecond
    // see getNextFundingFactorPerSecond for more info
    struct GetNextFundingAmountPerSizeResult {
        bool longsPayShorts;
        uint256 fundingFactorPerSecond;
        int256 nextSavedFundingFactorPerSecond;

        PositionType fundingFeeAmountPerSizeDelta;
        PositionType claimableFundingAmountPerSizeDelta;
    }

    struct GetNextFundingAmountPerSizeCache {
        PositionType openInterest;

        uint256 longOpenInterest;
        uint256 shortOpenInterest;

        uint256 durationInSeconds;

        uint256 sizeOfLargerSide;
        uint256 fundingUsd;

        uint256 fundingUsdForLongCollateral;
        uint256 fundingUsdForShortCollateral;
    }

    struct GetNextFundingFactorPerSecondCache {
        uint256 diffUsd;
        uint256 totalOpenInterest;

        uint256 fundingFactor;
        uint256 fundingExponentFactor;

        uint256 diffUsdAfterExponent;
        uint256 diffUsdToOpenInterestFactor;

        int256 savedFundingFactorPerSecond;
        uint256 savedFundingFactorPerSecondMagnitude;

        int256 nextSavedFundingFactorPerSecond;
        int256 nextSavedFundingFactorPerSecondWithMinBound;
    }

    struct FundingConfigCache {
        uint256 thresholdForStableFunding;
        uint256 thresholdForDecreaseFunding;

        uint256 fundingIncreaseFactorPerSecond;
        uint256 fundingDecreaseFactorPerSecond;

        uint256 minFundingFactorPerSecond;
        uint256 maxFundingFactorPerSecond;
    }

    struct GetExpectedMinTokenBalanceCache {
        uint256 poolAmount;
        uint256 swapImpactPoolAmount;
        uint256 claimableCollateralAmount;
        uint256 claimableFeeAmount;
        uint256 claimableUiFeeAmount;
        uint256 affiliateRewardAmount;
    }

    // @dev get the market token's price
    // @param dataStore DataStore
    // @param market the market to check
    // @param longTokenPrice the price of the long token
    // @param shortTokenPrice the price of the short token
    // @param indexTokenPrice the price of the index token
    // @param maximize whether to maximize or minimize the market token price
    // @return returns (the market token's price, MarketPoolValueInfo.Props)
    function getMarketTokenPrice(
        DataStore dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        Price.Props memory longTokenPrice,
        Price.Props memory shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) external view returns (int256, MarketPoolValueInfo.Props memory) {
        uint256 supply = getMarketTokenSupply(MarketToken(payable(market.marketToken)));

        MarketPoolValueInfo.Props memory poolValueInfo = getPoolValueInfo(
            dataStore,
            market,
            indexTokenPrice,
            longTokenPrice,
            shortTokenPrice,
            pnlFactorType,
            maximize
        );

        // if the supply is zero then treat the market token price as 1 USD
        if (supply == 0) {
            return (Precision.FLOAT_PRECISION.toInt256(), poolValueInfo);
        }

        if (poolValueInfo.poolValue == 0) { return (0, poolValueInfo); }

        int256 marketTokenPrice = Precision.mulDiv(Precision.WEI_PRECISION, poolValueInfo.poolValue, supply);
        return (marketTokenPrice, poolValueInfo);
    }

    // @dev get the total supply of the marketToken
    // @param marketToken the marketToken
    // @return the total supply of the marketToken
    function getMarketTokenSupply(MarketToken marketToken) internal view returns (uint256) {
        return marketToken.totalSupply();
    }

    // @dev get the opposite token of the market
    // if the inputToken is the longToken return the shortToken and vice versa
    // @param inputToken the input token
    // @param market the market values
    // @return the opposite token
    function getOppositeToken(address inputToken, Market.Props memory market) internal pure returns (address) {
        if (inputToken == market.longToken) {
            return market.shortToken;
        }

        if (inputToken == market.shortToken) {
            return market.longToken;
        }

        revert Errors.UnableToGetOppositeToken(inputToken, market.marketToken);
    }

    function validateSwapMarket(DataStore dataStore, address marketAddress) internal view {
        Market.Props memory market = MarketStoreUtils.get(dataStore, marketAddress);
        validateSwapMarket(dataStore, market);
    }

    function validateSwapMarket(DataStore dataStore, Market.Props memory market) internal view {
        validateEnabledMarket(dataStore, market);

        if (market.longToken == market.shortToken) {
            revert Errors.InvalidSwapMarket(market.marketToken);
        }
    }

    // @dev get the token price from the stored MarketPrices
    // @param token the token to get the price for
    // @param the market values
    // @param the market token prices
    // @return the token price from the stored MarketPrices
    function getCachedTokenPrice(address token, Market.Props memory market, MarketPrices memory prices) internal pure returns (Price.Props memory) {
        if (token == market.longToken) {
            return prices.longTokenPrice;
        }
        if (token == market.shortToken) {
            return prices.shortTokenPrice;
        }
        if (token == market.indexToken) {
            return prices.indexTokenPrice;
        }

        revert Errors.UnableToGetCachedTokenPrice(token, market.marketToken);
    }

    // @dev return the primary prices for the market tokens
    // @param oracle Oracle
    // @param market the market values
    function getMarketPrices(Oracle oracle, Market.Props memory market) internal view returns (MarketPrices memory) {
        return MarketPrices(
            oracle.getPrimaryPrice(market.indexToken),
            oracle.getPrimaryPrice(market.longToken),
            oracle.getPrimaryPrice(market.shortToken)
        );
    }

    // @dev get the usd value of either the long or short tokens in the pool
    // without accounting for the pnl of open positions
    // @param dataStore DataStore
    // @param market the market values
    // @param prices the prices of the market tokens
    // @param whether to return the value for the long or short token
    // @return the usd value of either the long or short tokens in the pool
    function getPoolUsdWithoutPnl(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong,
        bool maximize
    ) internal view returns (uint256) {
        address token = isLong ? market.longToken : market.shortToken;
        // note that if it is a single token market, the poolAmount returned will be
        // the amount of tokens in the pool divided by 2
        uint256 poolAmount = getPoolAmount(dataStore, market, token);
        uint256 tokenPrice;

        if (maximize) {
            tokenPrice = isLong ? prices.longTokenPrice.max : prices.shortTokenPrice.max;
        } else {
            tokenPrice = isLong ? prices.longTokenPrice.min : prices.shortTokenPrice.min;
        }

        return poolAmount * tokenPrice;
    }

    // @dev get the USD value of a pool
    // the value of a pool is the worth of the liquidity provider tokens in the pool - pending trader pnl
    // we use the token index prices to calculate this and ignore price impact since if all positions were closed the
    // net price impact should be zero
    // @param dataStore DataStore
    // @param market the market values
    // @param longTokenPrice price of the long token
    // @param shortTokenPrice price of the short token
    // @param indexTokenPrice price of the index token
    // @param maximize whether to maximize or minimize the pool value
    // @return the value information of a pool
    function getPoolValueInfo(
        DataStore dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        Price.Props memory longTokenPrice,
        Price.Props memory shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) public view returns (MarketPoolValueInfo.Props memory) {
        MarketPoolValueInfo.Props memory result;

        result.longTokenAmount = getPoolAmount(dataStore, market, market.longToken);
        result.shortTokenAmount = getPoolAmount(dataStore, market, market.shortToken);

        result.longTokenUsd = result.longTokenAmount * longTokenPrice.pickPrice(maximize);
        result.shortTokenUsd = result.shortTokenAmount * shortTokenPrice.pickPrice(maximize);

        result.poolValue = (result.longTokenUsd + result.shortTokenUsd).toInt256();

        MarketPrices memory prices = MarketPrices(
            indexTokenPrice,
            longTokenPrice,
            shortTokenPrice
        );

        result.totalBorrowingFees = getTotalPendingBorrowingFees(
            dataStore,
            market,
            prices,
            true
        );

        result.totalBorrowingFees += getTotalPendingBorrowingFees(
            dataStore,
            market,
            prices,
            false
        );

        result.borrowingFeePoolFactor = Precision.FLOAT_PRECISION - dataStore.getUint(Keys.BORROWING_FEE_RECEIVER_FACTOR);
        result.poolValue += Precision.applyFactor(result.totalBorrowingFees, result.borrowingFeePoolFactor).toInt256();

        // !maximize should be used for net pnl as a larger pnl leads to a smaller pool value
        // and a smaller pnl leads to a larger pool value
        //
        // while positions will always be closed at the less favourable price
        // using the inverse of maximize for the getPnl calls would help prevent
        // gaming of market token values by increasing the spread
        //
        // liquidations could be triggerred by manipulating a large spread but
        // that should be more difficult to execute

        result.longPnl = getPnl(
            dataStore,
            market,
            indexTokenPrice,
            true, // isLong
            !maximize // maximize
        );

        result.longPnl = getCappedPnl(
            dataStore,
            market.marketToken,
            true,
            result.longPnl,
            result.longTokenUsd,
            pnlFactorType
        );

        result.shortPnl = getPnl(
            dataStore,
            market,
            indexTokenPrice,
            false, // isLong
            !maximize // maximize
        );

        result.shortPnl = getCappedPnl(
            dataStore,
            market.marketToken,
            false,
            result.shortPnl,
            result.shortTokenUsd,
            pnlFactorType
        );

        result.netPnl = result.longPnl + result.shortPnl;
        result.poolValue = result.poolValue - result.netPnl;

        result.impactPoolAmount = getNextPositionImpactPoolAmount(dataStore, market.marketToken);
        // use !maximize for pickPrice since the impactPoolUsd is deducted from the poolValue
        uint256 impactPoolUsd = result.impactPoolAmount * indexTokenPrice.pickPrice(!maximize);

        result.poolValue -= impactPoolUsd.toInt256();

        return result;
    }

    // @dev get the net pending pnl for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param indexTokenPrice the price of the index token
    // @param maximize whether to maximize or minimize the net pnl
    // @return the net pending pnl for a market
    function getNetPnl(
        DataStore dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool maximize
    ) internal view returns (int256) {
        int256 longPnl = getPnl(dataStore, market, indexTokenPrice, true, maximize);
        int256 shortPnl = getPnl(dataStore, market, indexTokenPrice, false, maximize);

        return longPnl + shortPnl;
    }

    // @dev get the capped pending pnl for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to check for the long or short side
    // @param pnl the uncapped pnl of the market
    // @param poolUsd the USD value of the pool
    // @param pnlFactorType the pnl factor type to use
    function getCappedPnl(
        DataStore dataStore,
        address market,
        bool isLong,
        int256 pnl,
        uint256 poolUsd,
        bytes32 pnlFactorType
    ) internal view returns (int256) {
        if (pnl < 0) { return pnl; }

        uint256 maxPnlFactor = getMaxPnlFactor(dataStore, pnlFactorType, market, isLong);
        int256 maxPnl = Precision.applyFactor(poolUsd, maxPnlFactor).toInt256();

        return pnl > maxPnl ? maxPnl : pnl;
    }

    // @dev get the pending pnl for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param indexTokenPrice the price of the index token
    // @param isLong whether to check for the long or short side
    // @param maximize whether to maximize or minimize the pnl
    function getPnl(
        DataStore dataStore,
        Market.Props memory market,
        uint256 indexTokenPrice,
        bool isLong,
        bool maximize
    ) internal view returns (int256) {
        Price.Props memory _indexTokenPrice = Price.Props(indexTokenPrice, indexTokenPrice);

        return getPnl(
            dataStore,
            market,
            _indexTokenPrice,
            isLong,
            maximize
        );
    }

    // @dev get the pending pnl for a market for either longs or shorts
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param indexTokenPrice the price of the index token
    // @param isLong whether to get the pnl for longs or shorts
    // @param maximize whether to maximize or minimize the net pnl
    // @return the pending pnl for a market for either longs or shorts
    function getPnl(
        DataStore dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) internal view returns (int256) {
        int256 openInterest = getOpenInterest(dataStore, market, isLong).toInt256();
        uint256 openInterestInTokens = getOpenInterestInTokens(dataStore, market, isLong);
        if (openInterest == 0 || openInterestInTokens == 0) {
            return 0;
        }

        uint256 price = indexTokenPrice.pickPriceForPnl(isLong, maximize);

        // openInterest is the cost of all positions, openInterestValue is the current worth of all positions
        int256 openInterestValue = (openInterestInTokens * price).toInt256();
        int256 pnl = isLong ? openInterestValue - openInterest : openInterest - openInterestValue;

        return pnl;
    }

    // @dev get the amount of tokens in the pool
    // @param dataStore DataStore
    // @param market the market to check
    // @param token the token to check
    // @return the amount of tokens in the pool
    function getPoolAmount(DataStore dataStore, Market.Props memory market, address token) internal view returns (uint256) {
        /* Market.Props memory market = MarketStoreUtils.get(dataStore, marketAddress); */
        // if the longToken and shortToken are the same, return half of the token amount, so that
        // calculations of pool value, etc would be correct
        uint256 divisor = getPoolDivisor(market.longToken, market.shortToken);
        return dataStore.getUint(Keys.poolAmountKey(market.marketToken, token)) / divisor;
    }

    // @dev get the max amount of tokens allowed to be in the pool
    // @param dataStore DataStore
    // @param market the market to check
    // @param token the token to check
    // @return the max amount of tokens that are allowed in the pool
    function getMaxPoolAmount(DataStore dataStore, address market, address token) internal view returns (uint256) {
        return dataStore.getUint(Keys.maxPoolAmountKey(market, token));
    }

    // @dev get the max amount of tokens allowed to be deposited in the pool
    // @param dataStore DataStore
    // @param market the market to check
    // @param token the token to check
    // @return the max amount of tokens that can be deposited in the pool
    function getMaxPoolAmountForDeposit(DataStore dataStore, address market, address token) internal view returns (uint256) {
        return dataStore.getUint(Keys.maxPoolAmountForDepositKey(market, token));
    }

    // @dev get the max open interest allowed for the market
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether this is for the long or short side
    // @return the max open interest allowed for the market
    function getMaxOpenInterest(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.maxOpenInterestKey(market, isLong));
    }

    // @dev increment the claimable collateral amount
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to increment the claimable collateral for
    // @param token the claimable token
    // @param account the account to increment the claimable collateral for
    // @param delta the amount to increment
    function incrementClaimableCollateralAmount(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        address account,
        uint256 delta
    ) internal {
        uint256 divisor = dataStore.getUint(Keys.CLAIMABLE_COLLATERAL_TIME_DIVISOR);
        uint256 timeKey = Chain.currentTimestamp() / divisor;

        uint256 nextValue = dataStore.incrementUint(
            Keys.claimableCollateralAmountKey(market, token, timeKey, account),
            delta
        );

        uint256 nextPoolValue = dataStore.incrementUint(
            Keys.claimableCollateralAmountKey(market, token),
            delta
        );

        MarketEventUtils.emitClaimableCollateralUpdated(
            eventEmitter,
            market,
            token,
            timeKey,
            account,
            delta,
            nextValue,
            nextPoolValue
        );
    }

    // @dev increment the claimable funding amount
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the trading market
    // @param token the claimable token
    // @param account the account to increment for
    // @param delta the amount to increment
    function incrementClaimableFundingAmount(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        address account,
        uint256 delta
    ) internal {
        uint256 nextValue = dataStore.incrementUint(
            Keys.claimableFundingAmountKey(market, token, account),
            delta
        );

        uint256 nextPoolValue = dataStore.incrementUint(
            Keys.claimableFundingAmountKey(market, token),
            delta
        );

        MarketEventUtils.emitClaimableFundingUpdated(
            eventEmitter,
            market,
            token,
            account,
            delta,
            nextValue,
            nextPoolValue
        );
    }

    // @dev claim funding fees
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to claim for
    // @param token the token to claim
    // @param account the account to claim for
    // @param receiver the receiver to send the amount to
    function claimFundingFees(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        address account,
        address receiver
    ) internal returns (uint256) {
        bytes32 key = Keys.claimableFundingAmountKey(market, token, account);

        uint256 claimableAmount = dataStore.getUint(key);
        dataStore.setUint(key, 0);

        uint256 nextPoolValue = dataStore.decrementUint(
            Keys.claimableFundingAmountKey(market, token),
            claimableAmount
        );

        MarketToken(payable(market)).transferOut(
            token,
            receiver,
            claimableAmount
        );

        validateMarketTokenBalance(dataStore, market);

        MarketEventUtils.emitFundingFeesClaimed(
            eventEmitter,
            market,
            token,
            account,
            receiver,
            claimableAmount,
            nextPoolValue
        );

        return claimableAmount;
    }

    // @dev claim collateral
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to claim for
    // @param token the token to claim
    // @param timeKey the time key
    // @param account the account to claim for
    // @param receiver the receiver to send the amount to
    function claimCollateral(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        uint256 timeKey,
        address account,
        address receiver
    ) internal returns (uint256) {
        uint256 claimableAmount = dataStore.getUint(Keys.claimableCollateralAmountKey(market, token, timeKey, account));

        uint256 claimableFactor;

        {
            uint256 claimableFactorForTime = dataStore.getUint(Keys.claimableCollateralFactorKey(market, token, timeKey));
            uint256 claimableFactorForAccount = dataStore.getUint(Keys.claimableCollateralFactorKey(market, token, timeKey, account));
            claimableFactor = claimableFactorForTime > claimableFactorForAccount ? claimableFactorForTime : claimableFactorForAccount;
        }

        uint256 claimedAmount = dataStore.getUint(Keys.claimedCollateralAmountKey(market, token, timeKey, account));

        uint256 adjustedClaimableAmount = Precision.applyFactor(claimableAmount, claimableFactor);
        if (adjustedClaimableAmount <= claimedAmount) {
            revert Errors.CollateralAlreadyClaimed(adjustedClaimableAmount, claimedAmount);
        }

        uint256 amountToBeClaimed = adjustedClaimableAmount - claimedAmount;

        dataStore.setUint(
            Keys.claimedCollateralAmountKey(market, token, timeKey, account),
            adjustedClaimableAmount
        );

        uint256 nextPoolValue = dataStore.decrementUint(
            Keys.claimableCollateralAmountKey(market, token),
            amountToBeClaimed
        );

        MarketToken(payable(market)).transferOut(
            token,
            receiver,
            amountToBeClaimed
        );

        validateMarketTokenBalance(dataStore, market);

        MarketEventUtils.emitCollateralClaimed(
            eventEmitter,
            market,
            token,
            timeKey,
            account,
            receiver,
            amountToBeClaimed,
            nextPoolValue
        );

        return amountToBeClaimed;
    }

    // @dev apply a delta to the pool amount
    // validatePoolAmount is not called in this function since applyDeltaToPoolAmount
    // is called when receiving fees
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to apply to
    // @param token the token to apply to
    // @param delta the delta amount
    function applyDeltaToPoolAmount(
        DataStore dataStore,
        EventEmitter eventEmitter,
        Market.Props memory market,
        address token,
        int256 delta
    ) internal returns (uint256) {
        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.poolAmountKey(market.marketToken, token),
            delta,
            "Invalid state, negative poolAmount"
        );

        applyDeltaToVirtualInventoryForSwaps(
            dataStore,
            eventEmitter,
            market,
            token,
            delta
        );

        MarketEventUtils.emitPoolAmountUpdated(eventEmitter, market.marketToken, token, delta, nextValue);

        return nextValue;
    }

    function getAdjustedSwapImpactFactor(DataStore dataStore, address market, bool isPositive) internal view returns (uint256) {
        (uint256 positiveImpactFactor, uint256 negativeImpactFactor) = getAdjustedSwapImpactFactors(dataStore, market);

        return isPositive ? positiveImpactFactor : negativeImpactFactor;
    }

    function getAdjustedSwapImpactFactors(DataStore dataStore, address market) internal view returns (uint256, uint256) {
        uint256 positiveImpactFactor = dataStore.getUint(Keys.swapImpactFactorKey(market, true));
        uint256 negativeImpactFactor = dataStore.getUint(Keys.swapImpactFactorKey(market, false));

        // if the positive impact factor is more than the negative impact factor, positions could be opened
        // and closed immediately for a profit if the difference is sufficient to cover the position fees
        if (positiveImpactFactor > negativeImpactFactor) {
            positiveImpactFactor = negativeImpactFactor;
        }

        return (positiveImpactFactor, negativeImpactFactor);
    }

    function getAdjustedPositionImpactFactor(DataStore dataStore, address market, bool isPositive) internal view returns (uint256) {
        (uint256 positiveImpactFactor, uint256 negativeImpactFactor) = getAdjustedPositionImpactFactors(dataStore, market);

        return isPositive ? positiveImpactFactor : negativeImpactFactor;
    }

    function getAdjustedPositionImpactFactors(DataStore dataStore, address market) internal view returns (uint256, uint256) {
        uint256 positiveImpactFactor = dataStore.getUint(Keys.positionImpactFactorKey(market, true));
        uint256 negativeImpactFactor = dataStore.getUint(Keys.positionImpactFactorKey(market, false));

        // if the positive impact factor is more than the negative impact factor, positions could be opened
        // and closed immediately for a profit if the difference is sufficient to cover the position fees
        if (positiveImpactFactor > negativeImpactFactor) {
            positiveImpactFactor = negativeImpactFactor;
        }

        return (positiveImpactFactor, negativeImpactFactor);
    }

    // @dev cap the input priceImpactUsd by the available amount in the position
    // impact pool and the max positive position impact factor
    // @param dataStore DataStore
    // @param market the trading market
    // @param tokenPrice the price of the token
    // @param priceImpactUsd the calculated USD price impact
    // @return the capped priceImpactUsd
    function getCappedPositionImpactUsd(
        DataStore dataStore,
        address market,
        Price.Props memory indexTokenPrice,
        int256 priceImpactUsd,
        uint256 sizeDeltaUsd
    ) internal view returns (int256) {
        if (priceImpactUsd < 0) {
            return priceImpactUsd;
        }

        uint256 impactPoolAmount = getPositionImpactPoolAmount(dataStore, market);
        int256 maxPriceImpactUsdBasedOnImpactPool = (impactPoolAmount * indexTokenPrice.min).toInt256();

        if (priceImpactUsd > maxPriceImpactUsdBasedOnImpactPool) {
            priceImpactUsd = maxPriceImpactUsdBasedOnImpactPool;
        }

        uint256 maxPriceImpactFactor = getMaxPositionImpactFactor(dataStore, market, true);
        int256 maxPriceImpactUsdBasedOnMaxPriceImpactFactor = Precision.applyFactor(sizeDeltaUsd, maxPriceImpactFactor).toInt256();

        if (priceImpactUsd > maxPriceImpactUsdBasedOnMaxPriceImpactFactor) {
            priceImpactUsd = maxPriceImpactUsdBasedOnMaxPriceImpactFactor;
        }

        return priceImpactUsd;
    }

    // @dev get the position impact pool amount
    // @param dataStore DataStore
    // @param market the market to check
    // @return the position impact pool amount
    function getPositionImpactPoolAmount(DataStore dataStore, address market) internal view returns (uint256) {
        return dataStore.getUint(Keys.positionImpactPoolAmountKey(market));
    }

    // @dev get the swap impact pool amount
    // @param dataStore DataStore
    // @param market the market to check
    // @param token the token to check
    // @return the swap impact pool amount
    function getSwapImpactPoolAmount(DataStore dataStore, address market, address token) internal view returns (uint256) {
        return dataStore.getUint(Keys.swapImpactPoolAmountKey(market, token));
    }

    // @dev apply a delta to the swap impact pool
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to apply to
    // @param token the token to apply to
    // @param delta the delta amount
    function applyDeltaToSwapImpactPool(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        int256 delta
    ) internal returns (uint256) {
        uint256 nextValue = dataStore.applyBoundedDeltaToUint(
            Keys.swapImpactPoolAmountKey(market, token),
            delta
        );

        MarketEventUtils.emitSwapImpactPoolAmountUpdated(eventEmitter, market, token, delta, nextValue);

        return nextValue;
    }

    // @dev apply a delta to the position impact pool
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to apply to
    // @param delta the delta amount
    function applyDeltaToPositionImpactPool(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        int256 delta
    ) internal returns (uint256) {
        uint256 nextValue = dataStore.applyBoundedDeltaToUint(
            Keys.positionImpactPoolAmountKey(market),
            delta
        );

        MarketEventUtils.emitPositionImpactPoolAmountUpdated(eventEmitter, market, delta, nextValue);

        return nextValue;
    }

    // @dev apply a delta to the open interest
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to apply to
    // @param collateralToken the collateralToken to apply to
    // @param isLong whether to apply to the long or short side
    // @param delta the delta amount
    function applyDeltaToOpenInterest(
        DataStore dataStore,
        EventEmitter eventEmitter,
        Market.Props memory market,
        address collateralToken,
        bool isLong,
        int256 delta
    ) internal returns (uint256) {
        if (market.indexToken == address(0)) {
            revert Errors.OpenInterestCannotBeUpdatedForSwapOnlyMarket(market.marketToken);
        }

        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.openInterestKey(market.marketToken, collateralToken, isLong),
            delta,
            "Invalid state: negative open interest"
        );

        // if the open interest for longs is increased then tokens were virtually bought from the pool
        // so the virtual inventory should be decreased
        // if the open interest for longs is decreased then tokens were virtually sold to the pool
        // so the virtual inventory should be increased
        // if the open interest for shorts is increased then tokens were virtually sold to the pool
        // so the virtual inventory should be increased
        // if the open interest for shorts is decreased then tokens were virtually bought from the pool
        // so the virtual inventory should be decreased
        applyDeltaToVirtualInventoryForPositions(
            dataStore,
            eventEmitter,
            market.indexToken,
            isLong ? -delta : delta
        );

        if (delta > 0) {
            validateOpenInterest(
                dataStore,
                market,
                isLong
            );
        }

        MarketEventUtils.emitOpenInterestUpdated(eventEmitter, market.marketToken, collateralToken, isLong, delta, nextValue);

        return nextValue;
    }

    // @dev apply a delta to the open interest in tokens
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to apply to
    // @param collateralToken the collateralToken to apply to
    // @param isLong whether to apply to the long or short side
    // @param delta the delta amount
    function applyDeltaToOpenInterestInTokens(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        int256 delta
    ) internal returns (uint256) {
        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.openInterestInTokensKey(market, collateralToken, isLong),
            delta,
            "Invalid state: negative open interest in tokens"
        );

        MarketEventUtils.emitOpenInterestInTokensUpdated(eventEmitter, market, collateralToken, isLong, delta, nextValue);

        return nextValue;
    }

    // @dev apply a delta to the collateral sum
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to apply to
    // @param collateralToken the collateralToken to apply to
    // @param isLong whether to apply to the long or short side
    // @param delta the delta amount
    function applyDeltaToCollateralSum(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        int256 delta
    ) internal returns (uint256) {
        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.collateralSumKey(market, collateralToken, isLong),
            delta,
            "Invalid state: negative collateralSum"
        );

        MarketEventUtils.emitCollateralSumUpdated(eventEmitter, market, collateralToken, isLong, delta, nextValue);

        return nextValue;
    }

    // @dev update the funding state
    // @param dataStore DataStore
    // @param market the market to update
    // @param prices the prices of the market tokens
    function updateFundingState(
        DataStore dataStore,
        EventEmitter eventEmitter,
        Market.Props memory market,
        MarketPrices memory prices
    ) external {
        GetNextFundingAmountPerSizeResult memory result = getNextFundingAmountPerSize(dataStore, market, prices);

        applyDeltaToFundingFeeAmountPerSize(
            dataStore,
            eventEmitter,
            market.marketToken,
            market.longToken,
            true,
            result.fundingFeeAmountPerSizeDelta.long.longToken
        );

        applyDeltaToFundingFeeAmountPerSize(
            dataStore,
            eventEmitter,
            market.marketToken,
            market.longToken,
            false,
            result.fundingFeeAmountPerSizeDelta.short.longToken
        );

        applyDeltaToFundingFeeAmountPerSize(
            dataStore,
            eventEmitter,
            market.marketToken,
            market.shortToken,
            true,
            result.fundingFeeAmountPerSizeDelta.long.shortToken
        );

        applyDeltaToFundingFeeAmountPerSize(
            dataStore,
            eventEmitter,
            market.marketToken,
            market.shortToken,
            false,
            result.fundingFeeAmountPerSizeDelta.short.shortToken
        );

        applyDeltaToClaimableFundingAmountPerSize(
            dataStore,
            eventEmitter,
            market.marketToken,
            market.longToken,
            true,
            result.claimableFundingAmountPerSizeDelta.long.longToken
        );

        applyDeltaToClaimableFundingAmountPerSize(
            dataStore,
            eventEmitter,
            market.marketToken,
            market.longToken,
            false,
            result.claimableFundingAmountPerSizeDelta.short.longToken
        );

        applyDeltaToClaimableFundingAmountPerSize(
            dataStore,
            eventEmitter,
            market.marketToken,
            market.shortToken,
            true,
            result.claimableFundingAmountPerSizeDelta.long.shortToken
        );

        applyDeltaToClaimableFundingAmountPerSize(
            dataStore,
            eventEmitter,
            market.marketToken,
            market.shortToken,
            false,
            result.claimableFundingAmountPerSizeDelta.short.shortToken
        );

        setSavedFundingFactorPerSecond(dataStore, market.marketToken, result.nextSavedFundingFactorPerSecond);

        dataStore.setUint(Keys.fundingUpdatedAtKey(market.marketToken), Chain.currentTimestamp());
    }

    // @dev get the next funding amount per size values
    // @param dataStore DataStore
    // @param prices the prices of the market tokens
    // @param market the market to update
    // @param longToken the market's long token
    // @param shortToken the market's short token
    function getNextFundingAmountPerSize(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices
    ) internal view returns (GetNextFundingAmountPerSizeResult memory) {
        GetNextFundingAmountPerSizeResult memory result;
        GetNextFundingAmountPerSizeCache memory cache;

        uint256 divisor = getPoolDivisor(market.longToken, market.shortToken);

        // get the open interest values by long / short and by collateral used
        cache.openInterest.long.longToken = getOpenInterest(dataStore, market.marketToken, market.longToken, true, divisor);
        cache.openInterest.long.shortToken = getOpenInterest(dataStore, market.marketToken, market.shortToken, true, divisor);
        cache.openInterest.short.longToken = getOpenInterest(dataStore, market.marketToken, market.longToken, false, divisor);
        cache.openInterest.short.shortToken = getOpenInterest(dataStore, market.marketToken, market.shortToken, false, divisor);

        // sum the open interest values to get the total long and short open interest values
        cache.longOpenInterest = cache.openInterest.long.longToken + cache.openInterest.long.shortToken;
        cache.shortOpenInterest = cache.openInterest.short.longToken + cache.openInterest.short.shortToken;

        // if either long or short open interest is zero, then funding should not be updated
        // as there would not be any user to pay the funding to
        if (cache.longOpenInterest == 0 || cache.shortOpenInterest == 0) {
            return result;
        }

        // if the blockchain is not progressing / a market is disabled, funding fees
        // will continue to accumulate
        // this should be a rare occurrence so funding fees are not adjusted for this case
        cache.durationInSeconds = getSecondsSinceFundingUpdated(dataStore, market.marketToken);

        cache.sizeOfLargerSide = cache.longOpenInterest > cache.shortOpenInterest ? cache.longOpenInterest : cache.shortOpenInterest;

        (result.fundingFactorPerSecond, result.longsPayShorts, result.nextSavedFundingFactorPerSecond) = getNextFundingFactorPerSecond(
            dataStore,
            market.marketToken,
            cache.longOpenInterest,
            cache.shortOpenInterest,
            cache.durationInSeconds
        );

        // for single token markets, if there is $200,000 long open interest
        // and $100,000 short open interest and if the fundingUsd is $8:
        // fundingUsdForLongCollateral: $4
        // fundingUsdForShortCollateral: $4
        // fundingFeeAmountPerSizeDelta.long.longToken: 4 / 100,000
        // fundingFeeAmountPerSizeDelta.long.shortToken: 4 / 100,000
        // claimableFundingAmountPerSizeDelta.short.longToken: 4 / 100,000
        // claimableFundingAmountPerSizeDelta.short.shortToken: 4 / 100,000
        //
        // the divisor for fundingFeeAmountPerSizeDelta is 100,000 because the
        // cache.openInterest.long.longOpenInterest and cache.openInterest.long.shortOpenInterest is divided by 2
        //
        // when the fundingFeeAmountPerSize value is incremented, it would be incremented twice:
        // 4 / 100,000 + 4 / 100,000 = 8 / 100,000
        //
        // since the actual long open interest is $200,000, this would result in a total of 8 / 100,000 * 200,000 = $16 being charged
        //
        // when the claimableFundingAmountPerSize value is incremented, it would similarly be incremented twice:
        // 4 / 100,000 + 4 / 100,000 = 8 / 100,000
        //
        // when calculating the amount to be claimed, the longTokenClaimableFundingAmountPerSize and shortTokenClaimableFundingAmountPerSize
        // are compared against the market's claimableFundingAmountPerSize for the longToken and claimableFundingAmountPerSize for the shortToken
        //
        // since both these values will be duplicated, the amount claimable would be:
        // (8 / 100,000 + 8 / 100,000) * 100,000 = $16
        //
        // due to these, the fundingUsd should be divided by the divisor

        cache.fundingUsd = Precision.applyFactor(cache.sizeOfLargerSide, cache.durationInSeconds * result.fundingFactorPerSecond);
        cache.fundingUsd = cache.fundingUsd / divisor;

        // split the fundingUsd value by long and short collateral
        // e.g. if the fundingUsd value is $500, and there is $1000 of long open interest using long collateral and $4000 of long open interest
        // with short collateral, then $100 of funding fees should be paid from long positions using long collateral, $400 of funding fees
        // should be paid from long positions using short collateral
        // short positions should receive $100 of funding fees in long collateral and $400 of funding fees in short collateral
        if (result.longsPayShorts) {
            cache.fundingUsdForLongCollateral = Precision.mulDiv(cache.fundingUsd, cache.openInterest.long.longToken, cache.longOpenInterest);
            cache.fundingUsdForShortCollateral = Precision.mulDiv(cache.fundingUsd, cache.openInterest.long.shortToken, cache.longOpenInterest);
        } else {
            cache.fundingUsdForLongCollateral = Precision.mulDiv(cache.fundingUsd, cache.openInterest.short.longToken, cache.shortOpenInterest);
            cache.fundingUsdForShortCollateral = Precision.mulDiv(cache.fundingUsd, cache.openInterest.short.shortToken, cache.shortOpenInterest);
        }

        // calculate the change in funding amount per size values
        // for example, if the fundingUsdForLongCollateral is $100, the longToken price is $2000, the longOpenInterest is $10,000, shortOpenInterest is $5000
        // if longs pay shorts then the fundingFeeAmountPerSize.long.longToken should be increased by 0.05 tokens per $10,000 or 0.000005 tokens per $1
        // the claimableFundingAmountPerSize.short.longToken should be increased by 0.05 tokens per $5000 or 0.00001 tokens per $1
        if (result.longsPayShorts) {
            // use the same longTokenPrice.max and shortTokenPrice.max to calculate the amount to be paid and received
            // positions only pay funding in the position's collateral token
            // so the fundingUsdForLongCollateral is divided by the total long open interest for long positions using the longToken as collateral
            // and the fundingUsdForShortCollateral is divided by the total long open interest for long positions using the shortToken as collateral
            result.fundingFeeAmountPerSizeDelta.long.longToken = getFundingAmountPerSizeDelta(
                cache.fundingUsdForLongCollateral,
                cache.openInterest.long.longToken,
                prices.longTokenPrice.max,
                true // roundUpMagnitude
            );

            result.fundingFeeAmountPerSizeDelta.long.shortToken = getFundingAmountPerSizeDelta(
                cache.fundingUsdForShortCollateral,
                cache.openInterest.long.shortToken,
                prices.shortTokenPrice.max,
                true // roundUpMagnitude
            );

            // positions receive funding in both the longToken and shortToken
            // so the fundingUsdForLongCollateral and fundingUsdForShortCollateral is divided by the total short open interest
            result.claimableFundingAmountPerSizeDelta.short.longToken = getFundingAmountPerSizeDelta(
                cache.fundingUsdForLongCollateral,
                cache.shortOpenInterest,
                prices.longTokenPrice.max,
                false // roundUpMagnitude
            );

            result.claimableFundingAmountPerSizeDelta.short.shortToken = getFundingAmountPerSizeDelta(
                cache.fundingUsdForShortCollateral,
                cache.shortOpenInterest,
                prices.shortTokenPrice.max,
                false // roundUpMagnitude
            );
        } else {
            // use the same longTokenPrice.max and shortTokenPrice.max to calculate the amount to be paid and received
            // positions only pay funding in the position's collateral token
            // so the fundingUsdForLongCollateral is divided by the total short open interest for short positions using the longToken as collateral
            // and the fundingUsdForShortCollateral is divided by the total short open interest for short positions using the shortToken as collateral
            result.fundingFeeAmountPerSizeDelta.short.longToken = getFundingAmountPerSizeDelta(
                cache.fundingUsdForLongCollateral,
                cache.openInterest.short.longToken,
                prices.longTokenPrice.max,
                true // roundUpMagnitude
            );

            result.fundingFeeAmountPerSizeDelta.short.shortToken = getFundingAmountPerSizeDelta(
                cache.fundingUsdForShortCollateral,
                cache.openInterest.short.shortToken,
                prices.shortTokenPrice.max,
                true // roundUpMagnitude
            );

            // positions receive funding in both the longToken and shortToken
            // so the fundingUsdForLongCollateral and fundingUsdForShortCollateral is divided by the total long open interest
            result.claimableFundingAmountPerSizeDelta.long.longToken = getFundingAmountPerSizeDelta(
                cache.fundingUsdForLongCollateral,
                cache.longOpenInterest,
                prices.longTokenPrice.max,
                false // roundUpMagnitude
            );

            result.claimableFundingAmountPerSizeDelta.long.shortToken = getFundingAmountPerSizeDelta(
                cache.fundingUsdForShortCollateral,
                cache.longOpenInterest,
                prices.shortTokenPrice.max,
                false // roundUpMagnitude
            );
        }

        return result;
    }

    // @dev get the next funding factor per second
    // in case the minFundingFactorPerSecond is not zero, and the long / short skew has flipped
    // if orders are being created frequently it is possible that the minFundingFactorPerSecond prevents
    // the nextSavedFundingFactorPerSecond from being decreased fast enough for the sign to eventually flip
    // if it is bound by minFundingFactorPerSecond
    // for that reason, only the nextFundingFactorPerSecond is bound by minFundingFactorPerSecond
    // and the nextSavedFundingFactorPerSecond is not bound by minFundingFactorPerSecond
    // @return nextFundingFactorPerSecond, longsPayShorts, nextSavedFundingFactorPerSecond
    function getNextFundingFactorPerSecond(
        DataStore dataStore,
        address market,
        uint256 longOpenInterest,
        uint256 shortOpenInterest,
        uint256 durationInSeconds
    ) internal view returns (uint256, bool, int256) {
        GetNextFundingFactorPerSecondCache memory cache;

        cache.diffUsd = Calc.diff(longOpenInterest, shortOpenInterest);
        cache.totalOpenInterest = longOpenInterest + shortOpenInterest;

        if (cache.diffUsd == 0) { return (0, true, 0); }

        if (cache.totalOpenInterest == 0) {
            revert Errors.UnableToGetFundingFactorEmptyOpenInterest();
        }

        cache.fundingExponentFactor = getFundingExponentFactor(dataStore, market);

        cache.diffUsdAfterExponent = Precision.applyExponentFactor(cache.diffUsd, cache.fundingExponentFactor);
        cache.diffUsdToOpenInterestFactor = Precision.toFactor(cache.diffUsdAfterExponent, cache.totalOpenInterest);

        FundingConfigCache memory configCache;
        configCache.fundingIncreaseFactorPerSecond = dataStore.getUint(Keys.fundingIncreaseFactorPerSecondKey(market));

        if (configCache.fundingIncreaseFactorPerSecond == 0) {
            cache.fundingFactor = getFundingFactor(dataStore, market);

            // if there is no fundingIncreaseFactorPerSecond then return the static fundingFactor based on open interest difference
            return (
                Precision.applyFactor(cache.diffUsdToOpenInterestFactor, cache.fundingFactor),
                longOpenInterest > shortOpenInterest,
                0
            );
        }

        // if the savedFundingFactorPerSecond is positive then longs pay shorts
        // if the savedFundingFactorPerSecond is negative then shorts pay longs
        cache.savedFundingFactorPerSecond = getSavedFundingFactorPerSecond(dataStore, market);
        cache.savedFundingFactorPerSecondMagnitude = cache.savedFundingFactorPerSecond.abs();

        configCache.thresholdForStableFunding = dataStore.getUint(Keys.thresholdForStableFundingKey(market));
        configCache.thresholdForDecreaseFunding = dataStore.getUint(Keys.thresholdForDecreaseFundingKey(market));

        // set the default of nextSavedFundingFactorPerSecond as the savedFundingFactorPerSecond
        cache.nextSavedFundingFactorPerSecond = cache.savedFundingFactorPerSecond;

        // the default will be NoChange
        FundingRateChangeType fundingRateChangeType;

        bool isSkewTheSameDirectionAsFunding = (cache.savedFundingFactorPerSecond > 0 && longOpenInterest > shortOpenInterest) || (cache.savedFundingFactorPerSecond < 0 && shortOpenInterest > longOpenInterest);

        if (isSkewTheSameDirectionAsFunding) {
            if (cache.diffUsdToOpenInterestFactor > configCache.thresholdForStableFunding) {
                fundingRateChangeType = FundingRateChangeType.Increase;
            } else if (cache.diffUsdToOpenInterestFactor < configCache.thresholdForDecreaseFunding) {
                fundingRateChangeType = FundingRateChangeType.Decrease;
            }
        } else {
            // if the skew has changed, then the funding should increase in the opposite direction
            fundingRateChangeType = FundingRateChangeType.Increase;
        }

        if (fundingRateChangeType == FundingRateChangeType.Increase) {
            // increase funding rate
            int256 increaseValue = Precision.applyFactor(cache.diffUsdToOpenInterestFactor, configCache.fundingIncreaseFactorPerSecond).toInt256() * durationInSeconds.toInt256();

            // if there are more longs than shorts, then the savedFundingFactorPerSecond should increase
            // otherwise the savedFundingFactorPerSecond should increase in the opposite direction / decrease
            if (longOpenInterest < shortOpenInterest) {
                increaseValue = -increaseValue;
            }

            cache.nextSavedFundingFactorPerSecond = cache.savedFundingFactorPerSecond + increaseValue;
        }

        if (fundingRateChangeType == FundingRateChangeType.Decrease && cache.savedFundingFactorPerSecondMagnitude != 0) {
            configCache.fundingDecreaseFactorPerSecond = dataStore.getUint(Keys.fundingDecreaseFactorPerSecondKey(market));
            uint256 decreaseValue = configCache.fundingDecreaseFactorPerSecond * durationInSeconds;

            if (cache.savedFundingFactorPerSecondMagnitude <= decreaseValue) {
                // set the funding factor to 1 or -1 depending on the original savedFundingFactorPerSecond
                cache.nextSavedFundingFactorPerSecond = cache.savedFundingFactorPerSecond / cache.savedFundingFactorPerSecondMagnitude.toInt256();
            } else {
                // reduce the original savedFundingFactorPerSecond while keeping the original sign of the savedFundingFactorPerSecond
                int256 sign = cache.savedFundingFactorPerSecond / cache.savedFundingFactorPerSecondMagnitude.toInt256();
                cache.nextSavedFundingFactorPerSecond = (cache.savedFundingFactorPerSecondMagnitude - decreaseValue).toInt256() * sign;
            }
        }

        configCache.minFundingFactorPerSecond = dataStore.getUint(Keys.minFundingFactorPerSecondKey(market));
        configCache.maxFundingFactorPerSecond = dataStore.getUint(Keys.maxFundingFactorPerSecondKey(market));

        cache.nextSavedFundingFactorPerSecond = Calc.boundMagnitude(
            cache.nextSavedFundingFactorPerSecond,
            0,
            configCache.maxFundingFactorPerSecond
        );

        cache.nextSavedFundingFactorPerSecondWithMinBound = Calc.boundMagnitude(
            cache.nextSavedFundingFactorPerSecond,
            configCache.minFundingFactorPerSecond,
            configCache.maxFundingFactorPerSecond
        );

        return (
            cache.nextSavedFundingFactorPerSecondWithMinBound.abs(),
            cache.nextSavedFundingFactorPerSecondWithMinBound > 0,
            cache.nextSavedFundingFactorPerSecond
        );
    }

    // store funding values as token amount per (Precision.FLOAT_PRECISION_SQRT / Precision.FLOAT_PRECISION) of USD size
    function getFundingAmountPerSizeDelta(
        uint256 fundingUsd,
        uint256 openInterest,
        uint256 tokenPrice,
        bool roundUpMagnitude
    ) internal pure returns (uint256) {
        if (fundingUsd == 0 || openInterest == 0) { return 0; }

        uint256 fundingUsdPerSize = Precision.mulDiv(
            fundingUsd,
            Precision.FLOAT_PRECISION * Precision.FLOAT_PRECISION_SQRT,
            openInterest,
            roundUpMagnitude
        );

        if (roundUpMagnitude) {
            return Calc.roundUpDivision(fundingUsdPerSize, tokenPrice);
        } else {
            return fundingUsdPerSize / tokenPrice;
        }
    }

    // @dev update the cumulative borrowing factor for a market
    // @param dataStore DataStore
    // @param market the market to update
    // @param longToken the market's long token
    // @param shortToken the market's short token
    // @param prices the prices of the market tokens
    // @param isLong whether to update the long or short side
    function updateCumulativeBorrowingFactor(
        DataStore dataStore,
        EventEmitter eventEmitter,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong
    ) external {
        (/* uint256 nextCumulativeBorrowingFactor */, uint256 delta) = getNextCumulativeBorrowingFactor(
            dataStore,
            market,
            prices,
            isLong
        );

        incrementCumulativeBorrowingFactor(
            dataStore,
            eventEmitter,
            market.marketToken,
            isLong,
            delta
        );

        dataStore.setUint(Keys.cumulativeBorrowingFactorUpdatedAtKey(market.marketToken, isLong), Chain.currentTimestamp());
    }

    // @dev get the ratio of pnl to pool value
    // @param dataStore DataStore
    // @param oracle Oracle
    // @param market the trading market
    // @param isLong whether to get the value for the long or short side
    // @param maximize whether to maximize the factor
    // @return (pnl of positions) / (long or short pool value)
    function getPnlToPoolFactor(
        DataStore dataStore,
        Oracle oracle,
        address market,
        bool isLong,
        bool maximize
    ) internal view returns (int256) {
        Market.Props memory _market = getEnabledMarket(dataStore, market);
        MarketPrices memory prices = MarketPrices(
            oracle.getPrimaryPrice(_market.indexToken),
            oracle.getPrimaryPrice(_market.longToken),
            oracle.getPrimaryPrice(_market.shortToken)
        );

        return getPnlToPoolFactor(dataStore, _market, prices, isLong, maximize);
    }

    // @dev get the ratio of pnl to pool value
    // @param dataStore DataStore
    // @param market the market values
    // @param prices the prices of the market tokens
    // @param isLong whether to get the value for the long or short side
    // @param maximize whether to maximize the factor
    // @return (pnl of positions) / (long or short pool value)
    function getPnlToPoolFactor(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong,
        bool maximize
    ) internal view returns (int256) {
        uint256 poolUsd = getPoolUsdWithoutPnl(dataStore, market, prices, isLong, !maximize);

        if (poolUsd == 0) {
            return 0;
        }

        int256 pnl = getPnl(
            dataStore,
            market,
            prices.indexTokenPrice,
            isLong,
            maximize
        );

        return Precision.toFactor(pnl, poolUsd);
    }

    function validateOpenInterest(
        DataStore dataStore,
        Market.Props memory market,
        bool isLong
    ) internal view {
        uint256 openInterest = getOpenInterest(dataStore, market, isLong);
        uint256 maxOpenInterest = getMaxOpenInterest(dataStore, market.marketToken, isLong);

        if (openInterest > maxOpenInterest) {
            revert Errors.MaxOpenInterestExceeded(openInterest, maxOpenInterest);
        }
    }

    // @dev validate that the pool amount is within the max allowed amount
    // @param dataStore DataStore
    // @param market the market to check
    // @param token the token to check
    function validatePoolAmount(
        DataStore dataStore,
        Market.Props memory market,
        address token
    ) internal view {
        uint256 poolAmount = getPoolAmount(dataStore, market, token);
        uint256 maxPoolAmount = getMaxPoolAmount(dataStore, market.marketToken, token);

        if (poolAmount > maxPoolAmount) {
            revert Errors.MaxPoolAmountExceeded(poolAmount, maxPoolAmount);
        }
    }

    // @dev validate that the pool amount is within the max allowed deposit amount
    // @param dataStore DataStore
    // @param market the market to check
    // @param token the token to check
    function validatePoolAmountForDeposit(
        DataStore dataStore,
        Market.Props memory market,
        address token
    ) internal view {
        uint256 poolAmount = getPoolAmount(dataStore, market, token);
        uint256 maxPoolAmount = getMaxPoolAmountForDeposit(dataStore, market.marketToken, token);

        if (poolAmount > maxPoolAmount) {
            revert Errors.MaxPoolAmountForDepositExceeded(poolAmount, maxPoolAmount);
        }
    }

    // @dev validate that the amount of tokens required to be reserved
    // is below the configured threshold
    // @param dataStore DataStore
    // @param market the market values
    // @param prices the prices of the market tokens
    // @param isLong whether to check the long or short side
    function validateReserve(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong
    ) internal view {
        // poolUsd is used instead of pool amount as the indexToken may not match the longToken
        // additionally, the shortToken may not be a stablecoin
        uint256 poolUsd = getPoolUsdWithoutPnl(dataStore, market, prices, isLong, false);
        uint256 reserveFactor = getReserveFactor(dataStore, market.marketToken, isLong);
        uint256 maxReservedUsd = Precision.applyFactor(poolUsd, reserveFactor);

        uint256 reservedUsd = getReservedUsd(
            dataStore,
            market,
            prices,
            isLong
        );

        if (reservedUsd > maxReservedUsd) {
            revert Errors.InsufficientReserve(reservedUsd, maxReservedUsd);
        }
    }

    // @dev validate that the amount of tokens required to be reserved for open interest
    // is below the configured threshold
    // @param dataStore DataStore
    // @param market the market values
    // @param prices the prices of the market tokens
    // @param isLong whether to check the long or short side
    function validateOpenInterestReserve(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong
    ) internal view {
        // poolUsd is used instead of pool amount as the indexToken may not match the longToken
        // additionally, the shortToken may not be a stablecoin
        uint256 poolUsd = getPoolUsdWithoutPnl(dataStore, market, prices, isLong, false);
        uint256 reserveFactor = getOpenInterestReserveFactor(dataStore, market.marketToken, isLong);
        uint256 maxReservedUsd = Precision.applyFactor(poolUsd, reserveFactor);

        uint256 reservedUsd = getReservedUsd(
            dataStore,
            market,
            prices,
            isLong
        );

        if (reservedUsd > maxReservedUsd) {
            revert Errors.InsufficientReserveForOpenInterest(reservedUsd, maxReservedUsd);
        }
    }

    // @dev update the swap impact pool amount, if it is a positive impact amount
    // cap the impact amount to the amount available in the swap impact pool
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to apply to
    // @param token the token to apply to
    // @param tokenPrice the price of the token
    // @param priceImpactUsd the USD price impact
    function applySwapImpactWithCap(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address token,
        Price.Props memory tokenPrice,
        int256 priceImpactUsd
    ) internal returns (int256) {
        int256 impactAmount = getSwapImpactAmountWithCap(
            dataStore,
            market,
            token,
            tokenPrice,
            priceImpactUsd
        );

        // if there is a positive impact, the impact pool amount should be reduced
        // if there is a negative impact, the impact pool amount should be increased
        applyDeltaToSwapImpactPool(
            dataStore,
            eventEmitter,
            market,
            token,
            -impactAmount
        );

        return impactAmount;
    }

    function getSwapImpactAmountWithCap(
        DataStore dataStore,
        address market,
        address token,
        Price.Props memory tokenPrice,
        int256 priceImpactUsd
    ) internal view returns (int256) {
        int256 impactAmount;

        if (priceImpactUsd > 0) {
            // positive impact: minimize impactAmount, use tokenPrice.max
            // round positive impactAmount down, this will be deducted from the swap impact pool for the user
            impactAmount = priceImpactUsd / tokenPrice.max.toInt256();

            int256 maxImpactAmount = getSwapImpactPoolAmount(dataStore, market, token).toInt256();
            if (impactAmount > maxImpactAmount) {
                impactAmount = maxImpactAmount;
            }
        } else {
            // negative impact: maximize impactAmount, use tokenPrice.min
            // round negative impactAmount up, this will be deducted from the user
            impactAmount = Calc.roundUpMagnitudeDivision(priceImpactUsd, tokenPrice.min);
        }

        return impactAmount;
    }

    // @dev get the funding amount to be deducted or distributed
    //
    // @param latestFundingAmountPerSize the latest funding amount per size
    // @param positionFundingAmountPerSize the funding amount per size for the position
    // @param positionSizeInUsd the position size in USD
    // @param roundUpMagnitude whether the round up the result
    //
    // @return fundingAmount
    function getFundingAmount(
        uint256 latestFundingAmountPerSize,
        uint256 positionFundingAmountPerSize,
        uint256 positionSizeInUsd,
        bool roundUpMagnitude
    ) internal pure returns (uint256) {
        uint256 fundingDiffFactor = (latestFundingAmountPerSize - positionFundingAmountPerSize);

        // a user could avoid paying funding fees by continually updating the position
        // before the funding fee becomes large enough to be chargeable
        // to avoid this, funding fee amounts should be rounded up
        //
        // this could lead to large additional charges if the token has a low number of decimals
        // or if the token's value is very high, so care should be taken to inform users of this
        //
        // if the calculation is for the claimable amount, the amount should be rounded down instead

        // divide the result by Precision.FLOAT_PRECISION * Precision.FLOAT_PRECISION_SQRT as the fundingAmountPerSize values
        // are stored based on FLOAT_PRECISION_SQRT values
        return Precision.mulDiv(
            positionSizeInUsd,
            fundingDiffFactor,
            Precision.FLOAT_PRECISION * Precision.FLOAT_PRECISION_SQRT,
            roundUpMagnitude
        );
    }

    // @dev get the borrowing fees for a position, assumes that cumulativeBorrowingFactor
    // has already been updated to the latest value
    // @param dataStore DataStore
    // @param position Position.Props
    // @return the borrowing fees for a position
    function getBorrowingFees(DataStore dataStore, Position.Props memory position) internal view returns (uint256) {
        uint256 cumulativeBorrowingFactor = getCumulativeBorrowingFactor(dataStore, position.market(), position.isLong());
        if (position.borrowingFactor() > cumulativeBorrowingFactor) {
            revert Errors.UnexpectedBorrowingFactor(position.borrowingFactor(), cumulativeBorrowingFactor);
        }
        uint256 diffFactor = cumulativeBorrowingFactor - position.borrowingFactor();
        return Precision.applyFactor(position.sizeInUsd(), diffFactor);
    }

    // @dev get the borrowing fees for a position by calculating the latest cumulativeBorrowingFactor
    // @param dataStore DataStore
    // @param position Position.Props
    // @param market the position's market
    // @param prices the prices of the market tokens
    // @return the borrowing fees for a position
    function getNextBorrowingFees(DataStore dataStore, Position.Props memory position, Market.Props memory market, MarketPrices memory prices) internal view returns (uint256) {
        (uint256 nextCumulativeBorrowingFactor, /* uint256 delta */) = getNextCumulativeBorrowingFactor(
            dataStore,
            market,
            prices,
            position.isLong()
        );

        if (position.borrowingFactor() > nextCumulativeBorrowingFactor) {
            revert Errors.UnexpectedBorrowingFactor(position.borrowingFactor(), nextCumulativeBorrowingFactor);
        }
        uint256 diffFactor = nextCumulativeBorrowingFactor - position.borrowingFactor();
        return Precision.applyFactor(position.sizeInUsd(), diffFactor);
    }

    // @dev get the total reserved USD required for positions
    // @param market the market to check
    // @param prices the prices of the market tokens
    // @param isLong whether to get the value for the long or short side
    function getReservedUsd(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong
    ) internal view returns (uint256) {
        uint256 reservedUsd;
        if (isLong) {
            // for longs calculate the reserved USD based on the open interest and current indexTokenPrice
            // this works well for e.g. an ETH / USD market with long collateral token as WETH
            // the available amount to be reserved would scale with the price of ETH
            // this also works for e.g. a SOL / USD market with long collateral token as WETH
            // if the price of SOL increases more than the price of ETH, additional amounts would be
            // automatically reserved
            uint256 openInterestInTokens = getOpenInterestInTokens(dataStore, market, isLong);
            reservedUsd = openInterestInTokens * prices.indexTokenPrice.max;
        } else {
            // for shorts use the open interest as the reserved USD value
            // this works well for e.g. an ETH / USD market with short collateral token as USDC
            // the available amount to be reserved would not change with the price of ETH
            reservedUsd = getOpenInterest(dataStore, market, isLong);
        }

        return reservedUsd;
    }

    // @dev get the virtual inventory for swaps
    // @param dataStore DataStore
    // @param market the market to check
    // @return returns (has virtual inventory, virtual long token inventory, virtual short token inventory)
    function getVirtualInventoryForSwaps(DataStore dataStore, address market) internal view returns (bool, uint256, uint256) {
        bytes32 virtualMarketId = dataStore.getBytes32(Keys.virtualMarketIdKey(market));
        if (virtualMarketId == bytes32(0)) {
            return (false, 0, 0);
        }

        return (
            true,
            dataStore.getUint(Keys.virtualInventoryForSwapsKey(virtualMarketId, true)),
            dataStore.getUint(Keys.virtualInventoryForSwapsKey(virtualMarketId, false))
        );
    }

    function getIsLongToken(Market.Props memory market, address token) internal pure returns (bool) {
        if (token != market.longToken && token != market.shortToken) {
            revert Errors.UnexpectedTokenForVirtualInventory(token, market.marketToken);
        }

        return token == market.longToken;
    }

    // @dev get the virtual inventory for positions
    // @param dataStore DataStore
    // @param token the token to check
    function getVirtualInventoryForPositions(DataStore dataStore, address token) internal view returns (bool, int256) {
        bytes32 virtualTokenId = dataStore.getBytes32(Keys.virtualTokenIdKey(token));
        if (virtualTokenId == bytes32(0)) {
            return (false, 0);
        }

        return (true, dataStore.getInt(Keys.virtualInventoryForPositionsKey(virtualTokenId)));
    }

    // @dev update the virtual inventory for swaps
    // @param dataStore DataStore
    // @param marketAddress the market to update
    // @param token the token to update
    // @param delta the update amount
    function applyDeltaToVirtualInventoryForSwaps(
        DataStore dataStore,
        EventEmitter eventEmitter,
        Market.Props memory market,
        address token,
        int256 delta
    ) internal returns (bool, uint256) {
        bytes32 virtualMarketId = dataStore.getBytes32(Keys.virtualMarketIdKey(market.marketToken));
        if (virtualMarketId == bytes32(0)) {
            return (false, 0);
        }

        bool isLongToken = getIsLongToken(market, token);

        uint256 nextValue = dataStore.applyBoundedDeltaToUint(
            Keys.virtualInventoryForSwapsKey(virtualMarketId, isLongToken),
            delta
        );

        MarketEventUtils.emitVirtualSwapInventoryUpdated(eventEmitter, market.marketToken, isLongToken, virtualMarketId, delta, nextValue);

        return (true, nextValue);
    }

    // @dev update the virtual inventory for positions
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param token the token to update
    // @param delta the update amount
    function applyDeltaToVirtualInventoryForPositions(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address token,
        int256 delta
    ) internal returns (bool, int256) {
        bytes32 virtualTokenId = dataStore.getBytes32(Keys.virtualTokenIdKey(token));
        if (virtualTokenId == bytes32(0)) {
            return (false, 0);
        }

        int256 nextValue = dataStore.applyDeltaToInt(
            Keys.virtualInventoryForPositionsKey(virtualTokenId),
            delta
        );

        MarketEventUtils.emitVirtualPositionInventoryUpdated(eventEmitter, token, virtualTokenId, delta, nextValue);

        return (true, nextValue);
    }

    // @dev get the open interest of a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    function getOpenInterest(
        DataStore dataStore,
        Market.Props memory market
    ) internal view returns (uint256) {
        uint256 longOpenInterest = getOpenInterest(dataStore, market, true);
        uint256 shortOpenInterest = getOpenInterest(dataStore, market, false);

        return longOpenInterest + shortOpenInterest;
    }

    // @dev get either the long or short open interest for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param isLong whether to get the long or short open interest
    // @return the long or short open interest for a market
    function getOpenInterest(
        DataStore dataStore,
        Market.Props memory market,
        bool isLong
    ) internal view returns (uint256) {
        uint256 divisor = getPoolDivisor(market.longToken, market.shortToken);
        uint256 openInterestUsingLongTokenAsCollateral = getOpenInterest(dataStore, market.marketToken, market.longToken, isLong, divisor);
        uint256 openInterestUsingShortTokenAsCollateral = getOpenInterest(dataStore, market.marketToken, market.shortToken, isLong, divisor);

        return openInterestUsingLongTokenAsCollateral + openInterestUsingShortTokenAsCollateral;
    }

    // @dev the long and short open interest for a market based on the collateral token used
    // @param dataStore DataStore
    // @param market the market to check
    // @param collateralToken the collateral token to check
    // @param isLong whether to check the long or short side
    function getOpenInterest(
        DataStore dataStore,
        address market,
        address collateralToken,
        bool isLong,
        uint256 divisor
    ) internal view returns (uint256) {
        return dataStore.getUint(Keys.openInterestKey(market, collateralToken, isLong)) / divisor;
    }

    // this is used to divide the values of getPoolAmount and getOpenInterest
    // if the longToken and shortToken are the same, then these values have to be divided by two
    // to avoid double counting
    function getPoolDivisor(address longToken, address shortToken) internal pure returns (uint256) {
        return longToken == shortToken ? 2 : 1;
    }

    // @dev the long and short open interest in tokens for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param isLong whether to check the long or short side
    function getOpenInterestInTokens(
        DataStore dataStore,
        Market.Props memory market,
        bool isLong
    ) internal view returns (uint256) {
        uint256 divisor = getPoolDivisor(market.longToken, market.shortToken);
        uint256 openInterestUsingLongTokenAsCollateral = getOpenInterestInTokens(dataStore, market.marketToken, market.longToken, isLong, divisor);
        uint256 openInterestUsingShortTokenAsCollateral = getOpenInterestInTokens(dataStore, market.marketToken, market.shortToken, isLong, divisor);

        return openInterestUsingLongTokenAsCollateral + openInterestUsingShortTokenAsCollateral;
    }

    // @dev the long and short open interest in tokens for a market based on the collateral token used
    // @param dataStore DataStore
    // @param market the market to check
    // @param collateralToken the collateral token to check
    // @param isLong whether to check the long or short side
    function getOpenInterestInTokens(
        DataStore dataStore,
        address market,
        address collateralToken,
        bool isLong,
        uint256 divisor
    ) internal view returns (uint256) {
        return dataStore.getUint(Keys.openInterestInTokensKey(market, collateralToken, isLong)) / divisor;
    }

    // @dev get the sum of open interest and pnl for a market
    // getOpenInterestInTokens * tokenPrice would not reflect pending positive pnl
    // for short positions, so getOpenInterestWithPnl should be used if that info is needed
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param indexTokenPrice the price of the index token
    // @param isLong whether to check the long or short side
    // @param maximize whether to maximize or minimize the value
    // @return the sum of open interest and pnl for a market
    function getOpenInterestWithPnl(
        DataStore dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) internal view returns (int256) {
        uint256 openInterest = getOpenInterest(dataStore, market, isLong);
        int256 pnl = getPnl(dataStore, market, indexTokenPrice, isLong, maximize);
        return Calc.sumReturnInt256(openInterest, pnl);
    }

    // @dev get the max position impact factor for decreasing position
    // @param dataStore DataStore
    // @param market the market to check
    // @param isPositive whether the price impact is positive or negative
    function getMaxPositionImpactFactor(DataStore dataStore, address market, bool isPositive) internal view returns (uint256) {
        (uint256 maxPositiveImpactFactor, uint256 maxNegativeImpactFactor) = getMaxPositionImpactFactors(dataStore, market);

        return isPositive ? maxPositiveImpactFactor : maxNegativeImpactFactor;
    }

    function getMaxPositionImpactFactors(DataStore dataStore, address market) internal view returns (uint256, uint256) {
        uint256 maxPositiveImpactFactor = dataStore.getUint(Keys.maxPositionImpactFactorKey(market, true));
        uint256 maxNegativeImpactFactor = dataStore.getUint(Keys.maxPositionImpactFactorKey(market, false));

        if (maxPositiveImpactFactor > maxNegativeImpactFactor) {
            maxPositiveImpactFactor = maxNegativeImpactFactor;
        }

        return (maxPositiveImpactFactor, maxNegativeImpactFactor);
    }

    // @dev get the max position impact factor for liquidations
    // @param dataStore DataStore
    // @param market the market to check
    function getMaxPositionImpactFactorForLiquidations(DataStore dataStore, address market) internal view returns (uint256) {
        return dataStore.getUint(Keys.maxPositionImpactFactorForLiquidationsKey(market));
    }

    // @dev get the min collateral factor
    // @param dataStore DataStore
    // @param market the market to check
    function getMinCollateralFactor(DataStore dataStore, address market) internal view returns (uint256) {
        return dataStore.getUint(Keys.minCollateralFactorKey(market));
    }

    // @dev get the min collateral factor for open interest multiplier
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether it is for the long or short side
    function getMinCollateralFactorForOpenInterestMultiplier(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.minCollateralFactorForOpenInterestMultiplierKey(market, isLong));
    }

    // @dev get the min collateral factor for open interest
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param openInterestDelta the change in open interest
    // @param isLong whether it is for the long or short side
    function getMinCollateralFactorForOpenInterest(
        DataStore dataStore,
        Market.Props memory market,
        int256 openInterestDelta,
        bool isLong
    ) internal view returns (uint256) {
        uint256 openInterest = getOpenInterest(dataStore, market, isLong);
        openInterest = Calc.sumReturnUint256(openInterest, openInterestDelta);
        uint256 multiplierFactor = getMinCollateralFactorForOpenInterestMultiplier(dataStore, market.marketToken, isLong);
        return Precision.applyFactor(openInterest, multiplierFactor);
    }

    // @dev get the total amount of position collateral for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to get the value for longs or shorts
    // @return the total amount of position collateral for a market
    function getCollateralSum(DataStore dataStore, address market, address collateralToken, bool isLong, uint256 divisor) internal view returns (uint256) {
        return dataStore.getUint(Keys.collateralSumKey(market, collateralToken, isLong)) / divisor;
    }

    // @dev get the reserve factor for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to get the value for longs or shorts
    // @return the reserve factor for a market
    function getReserveFactor(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.reserveFactorKey(market, isLong));
    }

    // @dev get the open interest reserve factor for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to get the value for longs or shorts
    // @return the open interest reserve factor for a market
    function getOpenInterestReserveFactor(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.openInterestReserveFactorKey(market, isLong));
    }

    // @dev get the max pnl factor for a market
    // @param dataStore DataStore
    // @param pnlFactorType the type of the pnl factor
    // @param market the market to check
    // @param isLong whether to get the value for longs or shorts
    // @return the max pnl factor for a market
    function getMaxPnlFactor(DataStore dataStore, bytes32 pnlFactorType, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.maxPnlFactorKey(pnlFactorType, market, isLong));
    }

    // @dev get the min pnl factor after ADL
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to check the long or short side
    function getMinPnlFactorAfterAdl(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.minPnlFactorAfterAdlKey(market, isLong));
    }

    // @dev get the funding factor for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @return the funding factor for a market
    function getFundingFactor(DataStore dataStore, address market) internal view returns (uint256) {
        return dataStore.getUint(Keys.fundingFactorKey(market));
    }

    // @dev get the saved funding factor for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @return the saved funding factor for a market
    function getSavedFundingFactorPerSecond(DataStore dataStore, address market) internal view returns (int256) {
        return dataStore.getInt(Keys.savedFundingFactorPerSecondKey(market));
    }

    // @dev set the saved funding factor
    // @param dataStore DataStore
    // @param market the market to set the funding factor for
    function setSavedFundingFactorPerSecond(DataStore dataStore, address market, int256 value) internal returns (int256) {
        return dataStore.setInt(Keys.savedFundingFactorPerSecondKey(market), value);
    }

    // @dev get the funding exponent factor for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @return the funding exponent factor for a market
    function getFundingExponentFactor(DataStore dataStore, address market) internal view returns (uint256) {
        return dataStore.getUint(Keys.fundingExponentFactorKey(market));
    }

    // @dev get the funding fee amount per size for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short size
    // @return the funding fee amount per size for a market based on collateralToken
    function getFundingFeeAmountPerSize(DataStore dataStore, address market, address collateralToken, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.fundingFeeAmountPerSizeKey(market, collateralToken, isLong));
    }

    // @dev get the claimable funding amount per size for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short size
    // @return the claimable funding amount per size for a market based on collateralToken
    function getClaimableFundingAmountPerSize(DataStore dataStore, address market, address collateralToken, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.claimableFundingAmountPerSizeKey(market, collateralToken, isLong));
    }

    // @dev apply delta to the funding fee amount per size for a market
    // @param dataStore DataStore
    // @param market the market to set
    // @param collateralToken the collateralToken to set
    // @param isLong whether to set it for the long or short side
    // @param delta the delta to increment by
    function applyDeltaToFundingFeeAmountPerSize(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        uint256 delta
    ) internal {
        if (delta == 0) { return; }

        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.fundingFeeAmountPerSizeKey(market, collateralToken, isLong),
            delta
        );

        MarketEventUtils.emitFundingFeeAmountPerSizeUpdated(
            eventEmitter,
            market,
            collateralToken,
            isLong,
            delta,
            nextValue
        );
    }

    // @dev apply delta to the claimable funding amount per size for a market
    // @param dataStore DataStore
    // @param market the market to set
    // @param collateralToken the collateralToken to set
    // @param isLong whether to set it for the long or short side
    // @param delta the delta to increment by
    function applyDeltaToClaimableFundingAmountPerSize(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        uint256 delta
    ) internal {
        if (delta == 0) { return; }

        uint256 nextValue = dataStore.applyDeltaToUint(
            Keys.claimableFundingAmountPerSizeKey(market, collateralToken, isLong),
            delta
        );

        MarketEventUtils.emitClaimableFundingAmountPerSizeUpdated(
            eventEmitter,
            market,
            collateralToken,
            isLong,
            delta,
            nextValue
        );
    }

    // @dev get the number of seconds since funding was updated for a market
    // @param market the market to check
    // @return the number of seconds since funding was updated for a market
    function getSecondsSinceFundingUpdated(DataStore dataStore, address market) internal view returns (uint256) {
        uint256 updatedAt = dataStore.getUint(Keys.fundingUpdatedAtKey(market));
        if (updatedAt == 0) { return 0; }
        return Chain.currentTimestamp() - updatedAt;
    }

    // @dev get the borrowing factor for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to check the long or short side
    // @return the borrowing factor for a market
    function getBorrowingFactor(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.borrowingFactorKey(market, isLong));
    }

    // @dev get the borrowing exponent factor for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to check the long or short side
    // @return the borrowing exponent factor for a market
    function getBorrowingExponentFactor(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.borrowingExponentFactorKey(market, isLong));
    }

    // @dev get the cumulative borrowing factor for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to check the long or short side
    // @return the cumulative borrowing factor for a market
    function getCumulativeBorrowingFactor(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.cumulativeBorrowingFactorKey(market, isLong));
    }

    // @dev increase the cumulative borrowing factor
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param market the market to increment the borrowing factor for
    // @param isLong whether to increment the long or short side
    // @param delta the increase amount
    function incrementCumulativeBorrowingFactor(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market,
        bool isLong,
        uint256 delta
    ) internal {
        uint256 nextCumulativeBorrowingFactor = dataStore.incrementUint(
            Keys.cumulativeBorrowingFactorKey(market, isLong),
            delta
        );

        MarketEventUtils.emitBorrowingFactorUpdated(
            eventEmitter,
            market,
            isLong,
            delta,
            nextCumulativeBorrowingFactor
        );
    }

    // @dev get the timestamp of when the cumulative borrowing factor was last updated
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to check the long or short side
    // @return the timestamp of when the cumulative borrowing factor was last updated
    function getCumulativeBorrowingFactorUpdatedAt(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.cumulativeBorrowingFactorUpdatedAtKey(market, isLong));
    }

    // @dev get the number of seconds since the cumulative borrowing factor was last updated
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to check the long or short side
    // @return the number of seconds since the cumulative borrowing factor was last updated
    function getSecondsSinceCumulativeBorrowingFactorUpdated(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        uint256 updatedAt = getCumulativeBorrowingFactorUpdatedAt(dataStore, market, isLong);
        if (updatedAt == 0) { return 0; }
        return Chain.currentTimestamp() - updatedAt;
    }

    // @dev update the total borrowing amount after a position changes size
    // this is the sum of all position.borrowingFactor * position.sizeInUsd
    // @param dataStore DataStore
    // @param market the market to update
    // @param isLong whether to update the long or short side
    // @param prevPositionSizeInUsd the previous position size in USD
    // @param prevPositionBorrowingFactor the previous position borrowing factor
    // @param nextPositionSizeInUsd the next position size in USD
    // @param nextPositionBorrowingFactor the next position borrowing factor
    function updateTotalBorrowing(
        DataStore dataStore,
        address market,
        bool isLong,
        uint256 prevPositionSizeInUsd,
        uint256 prevPositionBorrowingFactor,
        uint256 nextPositionSizeInUsd,
        uint256 nextPositionBorrowingFactor
    ) external {
        uint256 totalBorrowing = getNextTotalBorrowing(
            dataStore,
            market,
            isLong,
            prevPositionSizeInUsd,
            prevPositionBorrowingFactor,
            nextPositionSizeInUsd,
            nextPositionBorrowingFactor
        );

        setTotalBorrowing(dataStore, market, isLong, totalBorrowing);
    }

    // @dev get the next total borrowing amount after a position changes size
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to check the long or short side
    // @param prevPositionSizeInUsd the previous position size in USD
    // @param prevPositionBorrowingFactor the previous position borrowing factor
    // @param nextPositionSizeInUsd the next position size in USD
    // @param nextPositionBorrowingFactor the next position borrowing factor
    function getNextTotalBorrowing(
        DataStore dataStore,
        address market,
        bool isLong,
        uint256 prevPositionSizeInUsd,
        uint256 prevPositionBorrowingFactor,
        uint256 nextPositionSizeInUsd,
        uint256 nextPositionBorrowingFactor
    ) internal view returns (uint256) {
        uint256 totalBorrowing = getTotalBorrowing(dataStore, market, isLong);
        totalBorrowing -= Precision.applyFactor(prevPositionSizeInUsd, prevPositionBorrowingFactor);
        totalBorrowing += Precision.applyFactor(nextPositionSizeInUsd, nextPositionBorrowingFactor);

        return totalBorrowing;
    }

    // @dev get the next cumulative borrowing factor
    // @param dataStore DataStore
    // @param prices the prices of the market tokens
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param isLong whether to check the long or short side
    function getNextCumulativeBorrowingFactor(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong
    ) internal view returns (uint256, uint256) {
        uint256 durationInSeconds = getSecondsSinceCumulativeBorrowingFactorUpdated(dataStore, market.marketToken, isLong);
        uint256 borrowingFactorPerSecond = getBorrowingFactorPerSecond(
            dataStore,
            market,
            prices,
            isLong
        );

        uint256 cumulativeBorrowingFactor = getCumulativeBorrowingFactor(dataStore, market.marketToken, isLong);

        uint256 delta = durationInSeconds * borrowingFactorPerSecond;
        uint256 nextCumulativeBorrowingFactor = cumulativeBorrowingFactor + delta;
        return (nextCumulativeBorrowingFactor, delta);
    }

    // @dev get the borrowing factor per second
    // @param dataStore DataStore
    // @param market the market to get the borrowing factor per second for
    // @param prices the prices of the market tokens
    // @param isLong whether to get the factor for the long or short side
    function getBorrowingFactorPerSecond(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong
    ) internal view returns (uint256) {
        uint256 reservedUsd = getReservedUsd(
            dataStore,
            market,
            prices,
            isLong
        );

        if (reservedUsd == 0) { return 0; }

        // check if the borrowing fee for the smaller side should be skipped
        // if skipBorrowingFeeForSmallerSide is true, and the longOpenInterest is exactly the same as the shortOpenInterest
        // then the borrowing fee would be charged for both sides, this should be very rare
        bool skipBorrowingFeeForSmallerSide = dataStore.getBool(Keys.SKIP_BORROWING_FEE_FOR_SMALLER_SIDE);
        if (skipBorrowingFeeForSmallerSide) {
            uint256 longOpenInterest = getOpenInterest(dataStore, market, true);
            uint256 shortOpenInterest = getOpenInterest(dataStore, market, false);

            // if getting the borrowing factor for longs and if the longOpenInterest
            // is smaller than the shortOpenInterest, then return zero
            if (isLong && longOpenInterest < shortOpenInterest) {
                return 0;
            }

            // if getting the borrowing factor for shorts and if the shortOpenInterest
            // is smaller than the longOpenInterest, then return zero
            if (!isLong && shortOpenInterest < longOpenInterest) {
                return 0;
            }
        }

        uint256 poolUsd = getPoolUsdWithoutPnl(dataStore, market, prices, isLong, false);

        if (poolUsd == 0) {
            revert Errors.UnableToGetBorrowingFactorEmptyPoolUsd();
        }

        uint256 borrowingExponentFactor = getBorrowingExponentFactor(dataStore, market.marketToken, isLong);
        uint256 reservedUsdAfterExponent = Precision.applyExponentFactor(reservedUsd, borrowingExponentFactor);

        uint256 reservedUsdToPoolFactor = Precision.toFactor(reservedUsdAfterExponent, poolUsd);
        uint256 borrowingFactor = getBorrowingFactor(dataStore, market.marketToken, isLong);

        return Precision.applyFactor(reservedUsdToPoolFactor, borrowingFactor);
    }

    function distributePositionImpactPool(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address market
    ) external {
        (uint256 distributionAmount, uint256 nextPositionImpactPoolAmount) = getPendingPositionImpactPoolDistributionAmount(dataStore, market);

        applyDeltaToPositionImpactPool(
            dataStore,
            eventEmitter,
            market,
            -distributionAmount.toInt256()
        );

        MarketEventUtils.emitPositionImpactPoolDistributed(
            eventEmitter,
            market,
            distributionAmount,
            nextPositionImpactPoolAmount
        );

        dataStore.setUint(Keys.positionImpactPoolDistributedAtKey(market), Chain.currentTimestamp());
    }

    function getNextPositionImpactPoolAmount(
        DataStore dataStore,
        address market
    ) internal view returns (uint256) {
        (/* uint256 distributionAmount */, uint256 nextPositionImpactPoolAmount) = getPendingPositionImpactPoolDistributionAmount(dataStore, market);

        return nextPositionImpactPoolAmount;
    }

    // @return (distributionAmount, nextPositionImpactPoolAmount)
    function getPendingPositionImpactPoolDistributionAmount(
        DataStore dataStore,
        address market
    ) internal view returns (uint256, uint256) {
        uint256 positionImpactPoolAmount = getPositionImpactPoolAmount(dataStore, market);
        if (positionImpactPoolAmount == 0) { return (0, positionImpactPoolAmount); }

        uint256 distributionRate = dataStore.getUint(Keys.positionImpactPoolDistributionRateKey(market));
        if (distributionRate == 0) { return (0, positionImpactPoolAmount); }

        uint256 minPositionImpactPoolAmount = dataStore.getUint(Keys.minPositionImpactPoolAmountKey(market));
        if (positionImpactPoolAmount <= minPositionImpactPoolAmount) { return (0, positionImpactPoolAmount); }

        uint256 maxDistributionAmount = positionImpactPoolAmount - minPositionImpactPoolAmount;

        uint256 durationInSeconds = getSecondsSincePositionImpactPoolDistributed(dataStore, market);
        uint256 distributionAmount = Precision.applyFactor(durationInSeconds, distributionRate);

        if (distributionAmount > maxDistributionAmount) {
            distributionAmount = maxDistributionAmount;
        }

        return (distributionAmount, positionImpactPoolAmount - distributionAmount);
    }

    function getSecondsSincePositionImpactPoolDistributed(
        DataStore dataStore,
        address market
    ) internal view returns (uint256) {
        uint256 distributedAt = dataStore.getUint(Keys.positionImpactPoolDistributedAtKey(market));
        if (distributedAt == 0) { return 0; }
        return Chain.currentTimestamp() - distributedAt;
    }

    // @dev get the total pending borrowing fees
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param isLong whether to check the long or short side
    function getTotalPendingBorrowingFees(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong
    ) internal view returns (uint256) {
        uint256 openInterest = getOpenInterest(
            dataStore,
            market,
            isLong
        );

        (uint256 nextCumulativeBorrowingFactor, /* uint256 delta */) = getNextCumulativeBorrowingFactor(
            dataStore,
            market,
            prices,
            isLong
        );

        uint256 totalBorrowing = getTotalBorrowing(dataStore, market.marketToken, isLong);

        return Precision.applyFactor(openInterest, nextCumulativeBorrowingFactor) - totalBorrowing;
    }

    // @dev get the total borrowing value
    // the total borrowing value is the sum of position.borrowingFactor * position.size / (10 ^ 30)
    // for all positions of the market
    // if borrowing APR is 1000% for 100 years, the cumulativeBorrowingFactor could be as high as 100 * 1000 * (10 ** 30)
    // since position.size is a USD value with 30 decimals, under this scenario, there may be overflow issues
    // if open interest exceeds (2 ** 256) / (10 ** 30) / (100 * 1000 * (10 ** 30)) => 1,157,920,900,000 USD
    // @param dataStore DataStore
    // @param market the market to check
    // @param isLong whether to check the long or short side
    // @return the total borrowing value
    function getTotalBorrowing(DataStore dataStore, address market, bool isLong) internal view returns (uint256) {
        return dataStore.getUint(Keys.totalBorrowingKey(market, isLong));
    }

    // @dev set the total borrowing value
    // @param dataStore DataStore
    // @param market the market to set
    // @param isLong whether to set the long or short side
    // @param value the value to set to
    function setTotalBorrowing(DataStore dataStore, address market, bool isLong, uint256 value) internal returns (uint256) {
        return dataStore.setUint(Keys.totalBorrowingKey(market, isLong), value);
    }

    // @dev convert a USD value to number of market tokens
    // @param usdValue the input USD value
    // @param poolValue the value of the pool
    // @param supply the supply of market tokens
    // @return the number of market tokens
    function usdToMarketTokenAmount(
        uint256 usdValue,
        uint256 poolValue,
        uint256 supply
    ) internal pure returns (uint256) {
        // if the supply and poolValue is zero, use 1 USD as the token price
        if (supply == 0 && poolValue == 0) {
            return Precision.floatToWei(usdValue);
        }

        // if the supply is zero and the poolValue is more than zero,
        // then include the poolValue for the amount of tokens minted so that
        // the market token price after mint would be 1 USD
        if (supply == 0 && poolValue > 0) {
            return Precision.floatToWei(poolValue + usdValue);
        }

        // round market tokens down
        return Precision.mulDiv(supply, usdValue, poolValue);
    }

    // @dev convert a number of market tokens to its USD value
    // @param marketTokenAmount the input number of market tokens
    // @param poolValue the value of the pool
    // @param supply the supply of market tokens
    // @return the USD value of the market tokens
    function marketTokenAmountToUsd(
        uint256 marketTokenAmount,
        uint256 poolValue,
        uint256 supply
    ) internal pure returns (uint256) {
        if (supply == 0) { revert Errors.EmptyMarketTokenSupply(); }

        return Precision.mulDiv(poolValue, marketTokenAmount, supply);
    }

    // @dev validate that the specified market exists and is enabled
    // @param dataStore DataStore
    // @param marketAddress the address of the market
    function validateEnabledMarket(DataStore dataStore, address marketAddress) internal view {
        Market.Props memory market = MarketStoreUtils.get(dataStore, marketAddress);
        validateEnabledMarket(dataStore, market);
    }

    // @dev validate that the specified market exists and is enabled
    // @param dataStore DataStore
    // @param market the market to check
    function validateEnabledMarket(DataStore dataStore, Market.Props memory market) internal view {
        if (market.marketToken == address(0)) {
            revert Errors.EmptyMarket();
        }

        bool isMarketDisabled = dataStore.getBool(Keys.isMarketDisabledKey(market.marketToken));
        if (isMarketDisabled) {
            revert Errors.DisabledMarket(market.marketToken);
        }
    }

    // @dev validate that the positions can be opened in the given market
    // @param market the market to check
    function validatePositionMarket(DataStore dataStore, Market.Props memory market) internal view {
        validateEnabledMarket(dataStore, market);

        if (isSwapOnlyMarket(market)) {
            revert Errors.InvalidPositionMarket(market.marketToken);
        }
    }

    function validatePositionMarket(DataStore dataStore, address marketAddress) internal view {
        Market.Props memory market = MarketStoreUtils.get(dataStore, marketAddress);
        validatePositionMarket(dataStore, market);
    }

    // @dev check if a market only supports swaps and not positions
    // @param market the market to check
    function isSwapOnlyMarket(Market.Props memory market) internal pure returns (bool) {
        return market.indexToken == address(0);
    }

    // @dev check if the given token is a collateral token of the market
    // @param market the market to check
    // @param token the token to check
    function isMarketCollateralToken(Market.Props memory market, address token) internal pure returns (bool) {
        return token == market.longToken || token == market.shortToken;
    }

    // @dev validate if the given token is a collateral token of the market
    // @param market the market to check
    // @param token the token to check
    function validateMarketCollateralToken(Market.Props memory market, address token) internal pure {
        if (!isMarketCollateralToken(market, token)) {
            revert Errors.InvalidCollateralTokenForMarket(market.marketToken, token);
        }
    }

    // @dev get the enabled market, revert if the market does not exist or is not enabled
    // @param dataStore DataStore
    // @param marketAddress the address of the market
    function getEnabledMarket(DataStore dataStore, address marketAddress) internal view returns (Market.Props memory) {
        Market.Props memory market = MarketStoreUtils.get(dataStore, marketAddress);
        validateEnabledMarket(dataStore, market);
        return market;
    }

    function getSwapPathMarket(DataStore dataStore, address marketAddress) internal view returns (Market.Props memory) {
        Market.Props memory market = MarketStoreUtils.get(dataStore, marketAddress);
        validateSwapMarket(dataStore, market);
        return market;
    }

    // @dev get a list of market values based on an input array of market addresses
    // @param swapPath list of market addresses
    function getSwapPathMarkets(DataStore dataStore, address[] memory swapPath) internal view returns (Market.Props[] memory) {
        Market.Props[] memory markets = new Market.Props[](swapPath.length);

        for (uint256 i; i < swapPath.length; i++) {
            address marketAddress = swapPath[i];
            markets[i] = getSwapPathMarket(dataStore, marketAddress);
        }

        return markets;
    }

    function validateSwapPath(DataStore dataStore, address[] memory swapPath) internal view {
        uint256 maxSwapPathLength = dataStore.getUint(Keys.MAX_SWAP_PATH_LENGTH);
        if (swapPath.length > maxSwapPathLength) {
            revert Errors.MaxSwapPathLengthExceeded(swapPath.length, maxSwapPathLength);
        }

        for (uint256 i; i < swapPath.length; i++) {
            address marketAddress = swapPath[i];
            validateSwapMarket(dataStore, marketAddress);
        }
    }

    // @dev validate that the pending pnl is below the allowed amount
    // @param dataStore DataStore
    // @param market the market to check
    // @param prices the prices of the market tokens
    // @param pnlFactorType the pnl factor type to check
    function validateMaxPnl(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bytes32 pnlFactorTypeForLongs,
        bytes32 pnlFactorTypeForShorts
    ) internal view {
        (bool isPnlFactorExceededForLongs, int256 pnlToPoolFactorForLongs, uint256 maxPnlFactorForLongs) = isPnlFactorExceeded(
            dataStore,
            market,
            prices,
            true,
            pnlFactorTypeForLongs
        );

        if (isPnlFactorExceededForLongs) {
            revert Errors.PnlFactorExceededForLongs(pnlToPoolFactorForLongs, maxPnlFactorForLongs);
        }

        (bool isPnlFactorExceededForShorts, int256 pnlToPoolFactorForShorts, uint256 maxPnlFactorForShorts) = isPnlFactorExceeded(
            dataStore,
            market,
            prices,
            false,
            pnlFactorTypeForShorts
        );

        if (isPnlFactorExceededForShorts) {
            revert Errors.PnlFactorExceededForShorts(pnlToPoolFactorForShorts, maxPnlFactorForShorts);
        }
    }

    // @dev check if the pending pnl exceeds the allowed amount
    // @param dataStore DataStore
    // @param oracle Oracle
    // @param market the market to check
    // @param isLong whether to check the long or short side
    // @param pnlFactorType the pnl factor type to check
    function isPnlFactorExceeded(
        DataStore dataStore,
        Oracle oracle,
        address market,
        bool isLong,
        bytes32 pnlFactorType
    ) internal view returns (bool, int256, uint256) {
        Market.Props memory _market = getEnabledMarket(dataStore, market);
        MarketPrices memory prices = getMarketPrices(oracle, _market);

        return isPnlFactorExceeded(
            dataStore,
            _market,
            prices,
            isLong,
            pnlFactorType
        );
    }

    // @dev check if the pending pnl exceeds the allowed amount
    // @param dataStore DataStore
    // @param _market the market to check
    // @param prices the prices of the market tokens
    // @param isLong whether to check the long or short side
    // @param pnlFactorType the pnl factor type to check
    function isPnlFactorExceeded(
        DataStore dataStore,
        Market.Props memory market,
        MarketPrices memory prices,
        bool isLong,
        bytes32 pnlFactorType
    ) internal view returns (bool, int256, uint256) {
        int256 pnlToPoolFactor = getPnlToPoolFactor(dataStore, market, prices, isLong, true);
        uint256 maxPnlFactor = getMaxPnlFactor(dataStore, pnlFactorType, market.marketToken, isLong);

        bool isExceeded = pnlToPoolFactor > 0 && pnlToPoolFactor.toUint256() > maxPnlFactor;

        return (isExceeded, pnlToPoolFactor, maxPnlFactor);
    }

    function getUiFeeFactor(DataStore dataStore, address account) internal view returns (uint256) {
        uint256 maxUiFeeFactor = dataStore.getUint(Keys.MAX_UI_FEE_FACTOR);
        uint256 uiFeeFactor = dataStore.getUint(Keys.uiFeeFactorKey(account));

        return uiFeeFactor < maxUiFeeFactor ? uiFeeFactor : maxUiFeeFactor;
    }

    function setUiFeeFactor(
        DataStore dataStore,
        EventEmitter eventEmitter,
        address account,
        uint256 uiFeeFactor
    ) internal {
        uint256 maxUiFeeFactor = dataStore.getUint(Keys.MAX_UI_FEE_FACTOR);

        if (uiFeeFactor > maxUiFeeFactor) {
            revert Errors.InvalidUiFeeFactor(uiFeeFactor, maxUiFeeFactor);
        }

        dataStore.setUint(
            Keys.uiFeeFactorKey(account),
            uiFeeFactor
        );

        MarketEventUtils.emitUiFeeFactorUpdated(eventEmitter, account, uiFeeFactor);
    }

    function validateMarketTokenBalance(
        DataStore dataStore,
        Market.Props[] memory markets
    ) public view {
        for (uint256 i; i < markets.length; i++) {
            validateMarketTokenBalance(dataStore, markets[i]);
        }
    }

    function validateMarketTokenBalance(
        DataStore dataStore,
        address _market
    ) public view {
        Market.Props memory market = getEnabledMarket(dataStore, _market);
        validateMarketTokenBalance(dataStore, market);
    }

    function validateMarketTokenBalance(
        DataStore dataStore,
        Market.Props memory market
    ) public view {
        validateMarketTokenBalance(dataStore, market, market.longToken);

        if (market.longToken == market.shortToken) {
            return;
        }

        validateMarketTokenBalance(dataStore, market, market.shortToken);
    }

    function validateMarketTokenBalance(
        DataStore dataStore,
        Market.Props memory market,
        address token
    ) internal view {
        if (market.marketToken == address(0) || token == address(0)) {
            revert Errors.EmptyAddressInMarketTokenBalanceValidation(market.marketToken, token);
        }

        uint256 balance = IERC20(token).balanceOf(market.marketToken);
        uint256 expectedMinBalance = getExpectedMinTokenBalance(dataStore, market, token);

        if (balance < expectedMinBalance) {
            revert Errors.InvalidMarketTokenBalance(market.marketToken, token, balance, expectedMinBalance);
        }

        // funding fees can be claimed even if the collateral for positions that should pay funding fees
        // hasn't been reduced yet
        // due to that, funding fees and collateral is excluded from the expectedMinBalance calculation
        // and validated separately

        // use 1 for the getCollateralSum divisor since getCollateralSum does not sum over both the
        // longToken and shortToken
        uint256 collateralAmount = getCollateralSum(dataStore, market.marketToken, token, true, 1);
        collateralAmount += getCollateralSum(dataStore, market.marketToken, token, false, 1);

        if (balance < collateralAmount) {
            revert Errors.InvalidMarketTokenBalanceForCollateralAmount(market.marketToken, token, balance, collateralAmount);
        }

        uint256 claimableFundingFeeAmount = dataStore.getUint(Keys.claimableFundingAmountKey(market.marketToken, token));

        // in case of late liquidations, it may be possible for the claimableFundingFeeAmount to exceed the market token balance
        // but this should be very rare
        if (balance < claimableFundingFeeAmount) {
            revert Errors.InvalidMarketTokenBalanceForClaimableFunding(market.marketToken, token, balance, claimableFundingFeeAmount);
        }
    }

    function getExpectedMinTokenBalance(
        DataStore dataStore,
        Market.Props memory market,
        address token
    ) internal view returns (uint256) {
        GetExpectedMinTokenBalanceCache memory cache;

        // get the pool amount directly as MarketUtils.getPoolAmount will divide the amount by 2
        // for markets with the same long and short token
        cache.poolAmount = dataStore.getUint(Keys.poolAmountKey(market.marketToken, token));
        cache.swapImpactPoolAmount = getSwapImpactPoolAmount(dataStore, market.marketToken, token);
        cache.claimableCollateralAmount = dataStore.getUint(Keys.claimableCollateralAmountKey(market.marketToken, token));
        cache.claimableFeeAmount = dataStore.getUint(Keys.claimableFeeAmountKey(market.marketToken, token));
        cache.claimableUiFeeAmount = dataStore.getUint(Keys.claimableUiFeeAmountKey(market.marketToken, token));
        cache.affiliateRewardAmount = dataStore.getUint(Keys.affiliateRewardKey(market.marketToken, token));

        // funding fees are excluded from this summation as claimable funding fees
        // are incremented without a corresponding decrease of the collateral of
        // other positions, the collateral of other positions is decreased when
        // those positions are updated
        return
            cache.poolAmount
            + cache.swapImpactPoolAmount
            + cache.claimableCollateralAmount
            + cache.claimableFeeAmount
            + cache.claimableUiFeeAmount
            + cache.affiliateRewardAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IAggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IVerifierProxy {
    function verify(bytes calldata) external returns (bytes memory);

    function s_feeManager() external view returns (address);
}

pragma solidity 0.8.17;

// depending on the requirement, you may build one or more data structures given below.

interface ISupraSValueFeed {
    // Data structure to hold the pair data
    struct priceFeed {
        uint256 round;
        uint256 decimals;
        uint256 time;
        uint256 price;
    }

    // Data structure to hold the derived/connverted data pairs.  This depends on your requirements.
    struct derivedData {
        int256 roundDifference;
        uint256 derivedPrice;
        uint256 decimals;
    }

    // Below functions enable you to retrieve different flavours of S-Value
    // Term "pair ID" and "Pair index" both refer to the same, pair index mentioned in our data pairs list.

    // Function to retrieve the data for a single data pair
    function getSvalue(uint256 _pairIndex) external view returns (priceFeed memory);

    //Function to fetch the data for a multiple data pairs
    function getSvalues(uint256[] memory _pairIndexes) external view returns (priceFeed[] memory);

    // Function to convert and derive new data pairs using two pair IDs and a mathematical operator multiplication(*) or division(/).
    //** Curreently only available in testnets
    function getDerivedSvalue(uint256 pair_id_1, uint256 pair_id_2, uint256 operation)
        external
        view
        returns (derivedData memory);

    // Function to check  the latest Timestamp on which a data pair is updated. This will help you check the staleness of a data pair before performing an action.
    function getTimestamp(uint256 _tradingPair) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { AggregateVaultStorage, IPositionManager } from "../storage/AggregateVaultStorage.sol";
import { Emitter } from "../peripheral/Emitter.sol";
import { OracleWrapper } from "../peripheral/OracleWrapper.sol";

/// @title StorageViewer
/// @author Umami Devs
contract StorageViewer is AggregateVaultStorage {
    function getRequest(uint256 key) external view returns (OCRequest memory order) {
        return _getRequest(key);
    }

    function getEmitter() external view returns (Emitter) {
        return Emitter(_getStorage().emitter);
    }

    function rebalanceOpen() external view returns (bool) {
        return _getVaultState().rebalanceOpen;
    }

    function getOracleWrapper() external view returns (OracleWrapper) {
        return OracleWrapper(_getStorage().oracleWrapper);
    }

    function getVaultState() external view returns (VaultState memory) {
        return _getStorage().vaultState;
    }

    function getAssetVaults() external view returns (AssetVaultStorage[2] memory _vaults) {
        _vaults = _getStorage().vaults;
    }

    function getTokenToAssetVaultIndex(address _token) external view returns (uint256 _index) {
        _index = _getStorage().tokenToAssetVaultIndex[_token];
    }

    function getVaultToAssetVaultIndex(address _vault) external view returns (uint256 _index) {
        _index = _getStorage().vaultToAssetVaultIndex[_vault];
    }

    function getRebalanceState() external view returns (RebalanceState memory _rebalanceState) {
        _rebalanceState = _getStorage().rebalanceState;
    }

    function getVaultFees() external view returns (VaultFees memory _vaultFees) {
        _vaultFees = _getStorage().vaultFees;
    }

    function getEpoch() external view returns (uint256 _epoch) {
        _epoch = _getStorage().vaultState.epoch;
    }

    function getBlockTolerance() external view returns (uint8 _blockTolerance) {
        _blockTolerance = _getStorage().L1BlockTolerance;
    }

    function getPositionManagers() external view returns (IPositionManager[] memory) {
        return _getStorage().positionManagers;
    }

    function getHookHandler() external view returns (address) {
        return _getStorage().hookHandler;
    }

    function getRebalanceKeeper() external view returns (address) {
        return _getStorage().rebalanceKeeper;
    }

    function getNettedThreshold() external view returns (uint256) {
        return _getStorage().nettedThreshold;
    }

    function getFeeHelper() external view returns (address) {
        return _getStorage().feeHelper;
    }

    function getGmi() external view returns (address) {
        return _getStorage().gmi;
    }

    function getAggregateVaultHelper() external view returns (address) {
        return _getStorage().aggregateVaultHelper;
    }

    function getGmxV2Handler() external view returns (address) {
        return _getStorage().gmxV2Handler;
    }

    function getRequestHandler() external view returns (address) {
        return _getStorage().requestHandler;
    }

    function getUniswapV3SwapManager() external view returns (address) {
        return _getStorage().uniswapV3SwapManager;
    }

    function getSwapSlippage() external view returns (uint256) {
        return _getStorage().swapSlippage;
    }

    function getRequestNonce() external view returns (uint256) {
        return _getStorage().requestNonce;
    }

    function getExecutionGasAmount() external view returns (uint256) {
        return _getStorage().executionGasAmount;
    }

    function getExecutionGasAmountCallback() external view returns (uint256) {
        return _getStorage().executionGasAmountCallback;
    }

    function getZeroSumPnlThreshold() external view returns (uint256) {
        return _getStorage().zeroSumPnlThreshold;
    }

    function getL1BlockTolerance() external view returns (uint256) {
        return _getStorage().L1BlockTolerance;
    }

    function getShouldCheckNetting() external view returns (bool) {
        return _getStorage().shouldCheckNetting;
    }

    function getShouldUseGmxFee() external view returns (bool) {
        return _getStorage().shouldUseGmxFee;
    }

    function getEpochStorageKey() external view returns (bytes32 _key) {
        VaultState storage vaultState = _getStorage().vaultState;
        assembly {
            _key := vaultState.slot
        }
    }

    function readStorageSlots(bytes32[] calldata _slots) external view returns (bytes32[] memory _values) {
        _values = new bytes32[](_slots.length);
        for (uint256 i; i < _slots.length; i++) {
            uint256 value;
            bytes32 slot = _slots[i];
            assembly {
                value := sload(slot)
            }
            _values[i] = bytes32(value);
        }
    }

    function gasRequirement(bool _callback) external view returns (uint256) {
        return _callback ? _getStorage().executionGasAmountCallback : _getStorage().executionGasAmount;
    }

    function getExternalPosition() external view returns (int256) {
        return _getStorage().externalPosition;
    }

    function getLastNettedPrice(uint256 _epoch) external view returns (int256[2] memory _prices) {
        _prices = _getStorage().lastNettedPrices[_epoch];
    }

    function getVaultGmiAttribution() external view returns (uint256[2] memory _vaultGmiAttribution) {
        _vaultGmiAttribution = _getStorage().vaultGmiAttribution;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { GmxStorage } from "../libraries/GmxStorage.sol";
import { Price } from "gmx-synthetics/price/Price.sol";
import { Market } from "gmx-synthetics/market/MarketUtils.sol";

import { GmxStorage } from "../libraries/GmxStorage.sol";

/// @title GmxV2HandlerStorage
/// @author Umami Devs
contract GmxV2HandlerStorage {
    struct DepositRequestDetails {
        address market;
        uint256 wethAmountDeposited;
        uint256 usdcAmountDeposited;
        uint256 amountMinted;
        bool executed;
        bool success;
        uint256 ethPrice;
        uint256 usdcPrice;
        int256 feesPaid;
    }

    struct WithdrawRequestDetails {
        address market;
        uint256 gmAmountDeposited;
        uint256 usdcAmountReceived;
        uint256 wethAmountReceived;
        bool executed;
        bool success;
        uint256 ethPrice;
        uint256 usdcPrice;
        int256 feesPaid;
    }

    struct RequestDetails {
        address market;
        address withAsset;
        uint256 amount; // in case of deposit it is the
        bool isDeposit;
    }

    struct GmxV2Storage {
        mapping(bytes32 => DepositRequestDetails) depositRequests;
        mapping(bytes32 => WithdrawRequestDetails) withdrawRequests;
    }

    bytes32 GMX_V2_STORAGE_SLOT = keccak256("gmx.v2.storage");

    function _getGmxV2Storage() internal view returns (GmxV2Storage storage _storage) {
        bytes32 position = GMX_V2_STORAGE_SLOT;
        assembly {
            _storage.slot := position
        }
    }
}

interface IGmxV2Handler {
    function burnGmTokens(address _market, uint256 _amount, address _receiver)
        external
        returns (bytes32 _withdrawKey);
    function mintGmTokens(address _market, uint256 _amountWeth, uint256 _amountUsdc, address _receiver)
        external
        payable
        returns (bytes32 _depositKey);
    function getMarket(address _market) external view returns (Market.Props memory _marketProps);
    function getGmMidPrice(address market, GmxStorage.MarketPrices memory tokenPrices)
        external
        view
        returns (uint256 price);
    function getDepositRequestDetails(bytes32 _key)
        external
        view
        returns (GmxV2HandlerStorage.DepositRequestDetails memory);
    function getWithdrawRequestDetails(bytes32 _key)
        external
        view
        returns (GmxV2HandlerStorage.WithdrawRequestDetails memory);
    function getMaxDepositAmount(address _market, address _token) external view returns (uint256 maxDepositAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { BaseSwapManager } from "./BaseSwapManager.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ISwapRouter } from "../interfaces/uniswap/ISwapRouter.sol";
import { IUniswapV3Pool } from "../interfaces/uniswap/IUniswapV3Pool.sol";
import { IUniswapV3Factory } from "../interfaces/uniswap/IUniswapV3Factory.sol";
import { UNISWAP_SWAP_ROUTER, UNISWAP_FACTORY } from "../constants.sol";

/**
 * @title UniswapV3SwapManager
 * @author Umami DAO
 * @notice Uniswap V3 implementation of the BaseSwapManager for swapping tokens.
 * @dev This contract uses the Uniswap V3 router for performing token swaps.
 */
contract UniswapV3SwapManager is BaseSwapManager {
    using SafeTransferLib for ERC20;

    // STORAGE
    // ------------------------------------------------------------------------------------------

    struct Config {
        uint24[] feeTiers;
        address intermediaryAsset;
    }

    /// @notice UniV3 router for calling swaps
    /// https://github.com/Uniswap/v3-periphery/blob/main/contracts/SwapRouter.sol
    ISwapRouter public constant uniV3Router = ISwapRouter(UNISWAP_SWAP_ROUTER);

    /// @notice UniV3 factory for discovering pools
    /// https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Factory.sol
    IUniswapV3Factory public constant uniV3factory = IUniswapV3Factory(UNISWAP_FACTORY);

    bytes32 public constant CONFIG_SLOT = keccak256("swapManagers.UniswapV3.config");

    constructor(address _intermediaryAsset) {
        require(_intermediaryAsset != address(0), "!_intermediaryAsset");
        Config storage config = _configStorage();
        config.intermediaryAsset = _intermediaryAsset;
    }

    // EXTERNAL
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Swaps tokens using the Uniswap V3 router.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountIn The amount of input tokens to swap.
     * @param _minOut The minimum amount of output tokens to receive.
     * @param - Encoded swap data (not used in this implementation).
     * @return _amountOut The actual amount of output tokens received.
     */
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _minOut, bytes calldata)
        external
        onlyDelegateCall
        swapChecks(_tokenIn, _tokenOut, _amountIn, _minOut)
        returns (uint256 _amountOut)
    {
        bytes memory path = _getSwapPath(_tokenIn, _tokenOut);
        _amountOut = _swapTokenExactInput(_tokenIn, _amountIn, _minOut, path);
    }

    /**
     * @notice Swaps tokens using the Uniswap V3 router.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountOut The amount of output tokens to swap into.
     * @param _maxIn The maximum amount of input tokens that can be used.
     * @return _amountIn The actual amount of output tokens received.
     */
    function exactOutputSwap(address _tokenIn, address _tokenOut, uint256 _amountOut, uint256 _maxIn)
        external
        onlyDelegateCall
        swapChecksExactOutput(_tokenIn, _tokenOut, _amountOut, _maxIn)
        returns (uint256 _amountIn)
    {
        bytes memory path = _getSwapPath(_tokenOut, _tokenIn);
        _amountIn = _swapTokenExactOutput(_tokenIn, _amountOut, _maxIn, path);
    }

    /**
     * @notice Adds a new fee tier.
     * @param _feeTier A fee tier to add.
     */
    function addFeeTier(uint24 _feeTier) external onlyDelegateCall {
        require(_feeTier > 0 && _feeTier < 100_000, "UniswapV3SwapManager: !_feeTier");
        Config storage config = _configStorage();
        config.feeTiers.push(_feeTier);
    }

    /**
     * @notice Removes an existing fee tier.
     * @param _feeTierToRemove A fee tier to remove.
     * @param _idx index of the tier.
     */
    function removeFeeTierAt(uint24 _feeTierToRemove, uint256 _idx) external onlyDelegateCall {
        Config storage config = _configStorage();
        require(config.feeTiers[_idx] == _feeTierToRemove, "UniswapV3SwapManager: invalid idx");
        config.feeTiers[_idx] = config.feeTiers[config.feeTiers.length - 1];
        config.feeTiers.pop();
    }

    /**
     * @notice Sets the intermediary asset used for swapping.
     * @param _newAsset The address of the new intermediary asset.
     */
    function setIntermediaryAsset(address _newAsset) external onlyDelegateCall {
        require(_newAsset != address(0), "UniswapV3SwapManager: !_newAsset");
        Config storage config = _configStorage();
        config.intermediaryAsset = _newAsset;
    }

    // INTERNAL
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Internal function to perform a token swap with exact input.
     * @param _tokenIn The address of the input token.
     * @param _amountIn The amount of input tokens to swap.
     * @param _minOut The minimum amount of output tokens to receive.
     * @param _path The encoded path for the swap.
     * @return _out The actual amount of output tokens received.
     */
    function _swapTokenExactInput(address _tokenIn, uint256 _amountIn, uint256 _minOut, bytes memory _path)
        internal
        returns (uint256 _out)
    {
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: _path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: _minOut
        });
        ERC20(_tokenIn).safeApprove(address(uniV3Router), _amountIn);
        return uniV3Router.exactInput(params);
    }

    /**
     * @notice Internal function to perform a token swap with exact input.
     * @param _tokenIn The address of the input token.
     * @param _amountOut The amount of output tokens to swap into.
     * @param _maxIn The maximum amount of input tokens to use.
     * @param _path The encoded path for the swap.
     * @return _in The actual amount of input tokens used.
     */
    function _swapTokenExactOutput(address _tokenIn, uint256 _amountOut, uint256 _maxIn, bytes memory _path)
        internal
        returns (uint256 _in)
    {
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: _path,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: _amountOut,
            amountInMaximum: _maxIn
        });
        ERC20(_tokenIn).safeApprove(address(uniV3Router), _maxIn);
        return uniV3Router.exactOutput(params);
    }

    /**
     * @notice Internal function to generate the swap path.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @return path The encoded swap path.
     */
    function _getSwapPath(address _tokenIn, address _tokenOut) internal view returns (bytes memory path) {
        Config storage config = _configStorage();
        uint24 tokenInFee = _getSwapFee(_tokenIn);
        uint24 tokenOutFee = _getSwapFee(_tokenOut);
        require(_tokenIn != _tokenOut, "UniswapV3SwapManager: !unique tokens");
        if (_tokenIn == config.intermediaryAsset || _tokenOut == config.intermediaryAsset) {
            require(tokenInFee > 0 || tokenOutFee > 0, "UniswapV3SwapManager: !_tokenOut");
            uint24 fee = tokenInFee > 0 ? tokenInFee : tokenOutFee;
            path = abi.encodePacked(_tokenIn, fee, _tokenOut);
        } else {
            require(tokenInFee > 0, "UniswapV3SwapManager: !_tokenIn");
            require(tokenOutFee > 0, "UniswapV3SwapManager: !_tokenOut");
            path = abi.encodePacked(_tokenIn, tokenInFee, config.intermediaryAsset, tokenOutFee, _tokenOut);
        }
    }

    /**
     * @notice finds the pool with the highest balance of _balanceToken
     * @param _targetToken The address of the token recorded in config.
     * @return swapFee The fee for the pool with the highest balance of _balanceToken.
     */
    function _getSwapFee(address _targetToken) internal view returns (uint24 swapFee) {
        Config storage config = _configStorage();
        address bestSwapPool;
        address iterSwapPool;
        /// @dev the feeTiers will be of length 4-5 and set with manual config
        for (uint256 i = 0; i < config.feeTiers.length; i++) {
            iterSwapPool = uniV3factory.getPool(_targetToken, config.intermediaryAsset, config.feeTiers[i]);

            // set initial value
            if (bestSwapPool == address(0) && iterSwapPool != address(0)) {
                swapFee = config.feeTiers[i];
                bestSwapPool = iterSwapPool;
            }
            if (
                iterSwapPool != address(0)
                    && IUniswapV3Pool(bestSwapPool).liquidity() < IUniswapV3Pool(iterSwapPool).liquidity()
            ) {
                swapFee = config.feeTiers[i];
                bestSwapPool = iterSwapPool;
            }
        }
    }

    /**
     * @notice Internal function to access the config storage.
     * @return config The config storage instance.
     */
    function _configStorage() internal pure returns (Config storage config) {
        bytes32 slot = CONFIG_SLOT;
        assembly {
            config.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Auth, GlobalACL, SWAP_KEEPER, KEEPER_ROLE } from "../Auth.sol";
import { LibCycle } from "../libraries/LibCycle.sol";
import { AggregateVaultStorage } from "../storage/AggregateVaultStorage.sol";

/// @title Emitter
/// @author Umami Devs
/// @notice Emitter handles events from the vaults for easy indexing
contract Emitter is GlobalACL {
    event CollectVaultFees(
        uint256 totalVaultFee,
        uint256 performanceFeeInAsset,
        uint256 managementFeeInAsset,
        uint256 timelockYieldMintAmount,
        address indexed assetVault
    );

    event RebalanceGmiFromState(uint256[2] targetUsd, uint256[2] targetShares, uint256[2] currentShares);

    event MintRequest(address asset, uint256 epoch, LibCycle.GMIMintRequest _mintRequest);

    event BurnRequest(address asset, uint256 epoch, LibCycle.GMIBurnRequest _mintRequest);

    event FulfilGmiMintRequest(
        uint256 targetGMIAmount, uint256 gmiMinted, uint256[] gmAmountsRequired, uint256[] gmAmountsMinted
    );

    event FulfilGmiBurnRequest(uint256 gmiAmount, uint256[4] usdcReceived, uint256[4] ethReceived);

    event OpenRebalance(uint256 timestamp, uint256[2] nextVaultIndexAlloc, uint256[2] nextIndexComp, int256 position);

    event CloseRebalance(uint256 timestamp);

    event DepositRequest(uint256 indexed key, address indexed account, address indexed vault);

    event WithdrawalRequest(uint256 indexed key, address indexed account, address indexed vault);

    event RequestExecuted(uint256 indexed key, address indexed account, address indexed vault, address callback);

    event ExecutionError(uint256 indexed key, address account, address vault, bool isDeposit, bytes error);

    event CallbackExecutionError(uint256 indexed key, bytes error);

    event CallbackExecutionSuccess(uint256 indexed key, AggregateVaultStorage.OCRequest request);

    event UpdateNettingCheckpointPrice(int256[2] oldPrices, int256[2] newPrices);

    event SettleNettedPositionPnl(
        uint256[2] previousGlpAmount,
        uint256[2] settledGlpAmount,
        int256[2] glpPnl,
        int256[2] dollarPnl,
        int256[2] percentPriceChange
    );

    event SetCallback(bool status);

    constructor(Auth auth) GlobalACL(auth) { }

    function emitCollectVaultFees(
        uint256 totalVaultFee,
        uint256 performanceFeeInAsset,
        uint256 managementFeeInAsset,
        uint256 timelockYieldMintAmount,
        address assetVault
    ) external onlyAggregateVault {
        emit CollectVaultFees(
            totalVaultFee, performanceFeeInAsset, managementFeeInAsset, timelockYieldMintAmount, assetVault
        );
    }

    function emitOpenRebalance(
        uint256 timestamp,
        uint256[2] memory nextVaultIndexAlloc,
        uint256[2] memory nextIndexComp,
        int256 position
    ) external onlyAggregateVault {
        emit OpenRebalance(timestamp, nextVaultIndexAlloc, nextIndexComp, position);
    }

    function emitCloseRebalance(uint256 timestamp) external onlyAggregateVault {
        emit CloseRebalance(timestamp);
    }

    function emitDepositRequest(uint256 key, address account, address vault) external onlyAggregateVault {
        emit DepositRequest(key, account, vault);
    }

    function emitWithdrawalRequest(uint256 key, address account, address vault) external onlyAggregateVault {
        emit WithdrawalRequest(key, account, vault);
    }

    function emitRequestExecuted(uint256 key, address account, address vault, address callback)
        external
        onlyRequestHandler
    {
        emit RequestExecuted(key, account, vault, callback);
    }

    function emitExecutionError(uint256 key, address account, address vault, bool isDeposit, bytes memory err)
        external
        onlyRequestHandler
    {
        emit ExecutionError(key, account, vault, isDeposit, err);
    }

    function emitSetCallbackEnabled(bool status) external onlyRequestHandler {
        emit SetCallback(status);
    }

    function emitRequestCallbackError(uint256 key, bytes memory err) external onlyRequestHandler {
        emit CallbackExecutionError(key, err);
    }

    function emitRequestCallbackSuccess(uint256 key, AggregateVaultStorage.OCRequest memory request)
        external
        onlyRequestHandler
    {
        emit CallbackExecutionSuccess(key, request);
    }

    function emitSettleNettedPositionPnl(
        uint256[2] memory previousIndexAmount,
        uint256[2] memory settledIndexAmount,
        int256[2] memory indexPnl,
        int256[2] memory dollarPnl,
        int256[2] memory percentPriceChange
    ) external onlyAggregateVault {
        emit SettleNettedPositionPnl(previousIndexAmount, settledIndexAmount, indexPnl, dollarPnl, percentPriceChange);
    }

    function emitRebalanceGmiFromState(
        uint256[2] memory targetUsd,
        uint256[2] memory targetShares,
        uint256[2] memory currentShares
    ) external onlyAggregateVault {
        emit RebalanceGmiFromState(targetUsd, targetShares, currentShares);
    }

    function emitMintRequest(address _asset, uint256 _epoch, LibCycle.GMIMintRequest memory _mintRequest)
        external
        onlyAggregateVault
    {
        emit MintRequest(_asset, _epoch, _mintRequest);
    }

    function emitBurnRequest(address _asset, uint256 _epoch, LibCycle.GMIBurnRequest memory _burnRequest)
        external
        onlyAggregateVault
    {
        emit BurnRequest(_asset, _epoch, _burnRequest);
    }

    function emitFulfilGmiMintRequest(
        uint256 targetGMIAmount,
        uint256 gmiMinted,
        uint256[] memory gmAmountsRequired,
        uint256[] memory gmAmountsMinted
    ) external onlyAggregateVault {
        emit FulfilGmiMintRequest(targetGMIAmount, gmiMinted, gmAmountsRequired, gmAmountsMinted);
    }

    function emitFulfilGmiBurnRequest(uint256 gmiAmount, uint256[4] memory usdcReceived, uint256[4] memory ethReceived)
        external
        onlyAggregateVault
    {
        emit FulfilGmiBurnRequest(gmiAmount, usdcReceived, ethReceived);
    }

    function emitUpdateNettingCheckpointPrice(int256[2] memory oldPrices, int256[2] memory newPrices)
        external
        onlyAggregateVault
    {
        emit UpdateNettingCheckpointPrice(oldPrices, newPrices);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { TransferUtils } from "../libraries/TransferUtils.sol";
import { Auth, GlobalACL, SWAP_KEEPER, KEEPER_ROLE, REQUEST_HANDLER } from "../Auth.sol";
import { AssetVault } from "./AssetVault.sol";
import { AggregateVaultStorage } from "../storage/AggregateVaultStorage.sol";
import { PositionManagerRouter, WhitelistedTokenRegistry } from "../position-managers/PositionManagerRouter.sol";
import { Multicall } from "../libraries/Multicall.sol";
import { NettingMath } from "../libraries/NettingMath.sol";
import { HookType } from "../interfaces/IHookExecutor.sol";
import { Emitter } from "../peripheral/Emitter.sol";
import { Delegatecall } from "../libraries/Delegatecall.sol";
import { OracleWrapper } from "../peripheral/OracleWrapper.sol";
import { AggregateVaultHelper } from "../peripheral/AggregateVaultHelper.sol";
import { IAssetVault } from "../interfaces/IAssetVault.sol";
import { IVaultFees } from "../interfaces/IVaultFees.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { IPositionManager } from "../interfaces/IPositionManager.sol";
import { Solarray } from "../libraries/Solarray.sol";

enum Peripheral {
    HookHandler,
    EventEmitter,
    OracleWrapper,
    GMI,
    AggregateVaultHelper,
    GmxV2Handler,
    FeeHelper,
    RequestHandler,
    UniswapV3SwapManager
}

enum ConfigItem {
    VaultFees,
    ShouldCheckNetting,
    ShouldUseGmxFee,
    L1BlockTolerance,
    ExecutionGasAmounts,
    RebalanceKeeper,
    FeeRecipient,
    VaultCaps,
    Thresholds
}

using Delegatecall for address;
using SafeTransferLib for ERC20;

/// @title AggregateVault
/// @author Umami Devs
/// @notice Contains common logic for all asset vaults and core keeper interactions
contract AggregateVault is Multicall, AggregateVaultStorage, PositionManagerRouter, GlobalACL {
    // ERRORS
    // ------------------------------------------------------------------------------------------

    /// @dev address should not be zero
    error ZeroAddress();
    /// @dev gas is not above the min required for the keeper execution
    error MinGasRequirement();
    /// @dev amount should be greater than 0
    error AmountEqualsZero();
    /// @dev vault rebalance is open
    error RebalanceOpen();
    /// @dev vault rebealance is closed
    error RebalanceNotOpen();
    /// @dev netting check has failed for the parameters passed
    error FailedNettingCheck();
    /// @dev config validation failed on set
    error FailedConfigValidation();
    /// @dev delevate view did not revert
    error DelegateViewRevert();
    /// @dev oracle price length is not equal to config requirement
    error OraclePriceSizeInvalid();
    /// @dev caller is not the asset vault
    error NotAssetVault();
    /// @dev not RequestHandler or AssetVault
    error notRequestHandlerOrAssetVault();
    /// @dev already paused
    error AggregateVault__AlreadyPaused();
    /// @dev invalid config item
    error AggregateVault__InvalidConfigItem();

    constructor(Auth _auth, WhitelistedTokenRegistry _whitelistedTokenRegistry)
        PositionManagerRouter(_whitelistedTokenRegistry)
        GlobalACL(_auth)
    { }

    // DEPOSIT & WITHDRAW
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Handles a deposit of a specified amount of an ERC20 asset into the AggregateVault from an account, with a deposit fee deducted.
     * @param assets The amount of the asset to be deposited.
     * @param account The address of the account from which the deposit will be made.
     */
    function handleDeposit(uint256 assets, uint256 minOutAfterFees, address account, address sender, address callback)
        external
        payable
        onlyAssetVault
    {
        if (assets == 0) revert AmountEqualsZero();
        if (account == address(0)) revert ZeroAddress();
        AVStorage storage stg = _getStorage();
        uint256 gas = _gasRequirement(callback != address(0));
        if (msg.value < gas * tx.gasprice) revert MinGasRequirement();

        // store request data
        uint256 key = _saveRequest(sender, account, msg.sender, callback, true, assets, minOutAfterFees);

        // send execution gas cost
        TransferUtils.transferNativeAsset(stg.rebalanceKeeper, msg.value);

        _executeHook(HookType.DEPOSIT_HOOK, msg.data[4:]);

        // emit request event
        Emitter(stg.emitter).emitDepositRequest(key, account, msg.sender);
    }

    /**
     * @notice Handles a withdrawal of a specified amount of an ERC20 asset from the AggregateVault to an account, with a withdrawal fee deducted.
     * @param shares The amount of the shares to be withdrawn.
     * @param account The address of the account to which the withdrawal will be made.
     */
    function handleWithdraw(uint256 shares, uint256 minOutAfterFees, address account, address sender, address callback)
        external
        payable
        onlyAssetVault
    {
        if (shares == 0) revert AmountEqualsZero();
        if (account == address(0)) revert ZeroAddress();
        AVStorage storage stg = _getStorage();
        uint256 gas = _gasRequirement(callback != address(0));
        if (msg.value < gas * tx.gasprice) revert MinGasRequirement();

        // store request data
        uint256 key = _saveRequest(sender, account, msg.sender, callback, false, shares, minOutAfterFees);

        // send execution gas cost
        TransferUtils.transferNativeAsset(stg.rebalanceKeeper, msg.value);

        _executeHook(HookType.WITHDRAW_HOOK, msg.data[4:]);

        // emit request event
        Emitter(stg.emitter).emitWithdrawalRequest(key, account, msg.sender);
    }

    /**
     * @notice clear a request from storage when a request is cancelled or fulfilled by handler
     */
    function clearRequest(uint256 key) external onlyRequestHandlerOrAssetVault returns (OCRequest memory order) {
        AVStorage storage stg = _getStorage();
        order = stg.pendingRequests[key];
        delete stg.pendingRequests[key];
    }

    /**
     * @notice releases funds for withdrawal to the user, can only be called by the request handler
     * @param underlyingToken the underlying vault token for the request
     * @param account the account the request was made for
     * @param assets the amounf of assets
     * @param baseWithdrawalFee size of the base withdrawal fee calculated in request handler
     * @param managmentPerformanceFee the size of the managment and performance fee prorata for the withdrawal
     */
    function releaseWithdrawal(
        address underlyingToken,
        address account,
        uint256 assets,
        uint256 baseWithdrawalFee,
        uint256 managmentPerformanceFee
    ) external onlyRequestHandler {
        TransferUtils.transferAsset(underlyingToken, account, assets);
        VaultState storage vaultState = _getVaultState();
        if (baseWithdrawalFee > 0) {
            TransferUtils.transferAsset(underlyingToken, vaultState.withdrawalFeeEscrow, baseWithdrawalFee);
        }
        if (managmentPerformanceFee > 0) {
            TransferUtils.transferAsset(underlyingToken, vaultState.feeRecipient, managmentPerformanceFee);
        }
    }

    /**
     * @notice Increments the epoch deposit/withdraw delta.
     */
    function incrementEpochDelta(address asset, int256 amount) external onlyRequestHandler {
        AssetVaultStorage storage vaultStg = _getVaultFromAsset(asset);
        vaultStg.epochDelta += amount;
    }

    // REBALANCE
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Executes a multicall in the context of the aggregate vault.
     * @param data the calls to be executed.
     * @return results the return values of each call.
     */
    function multicall(bytes[] calldata data)
        external
        payable
        onlyRole(KEEPER_ROLE)
        returns (bytes[] memory results, uint256[] memory gasEstimates)
    {
        (results, gasEstimates) = _multicall(data);
    }

    /**
     * @notice Opens the rebalance period and validates next rebalance state.
     * @param nextVaultIndexAlloc next vault GMI allocations in $
     * @param nextIndexComposition the composition of the GMI index
     * @param externalPosition the external position the vaults are taking on in $
     * @param priceData token price data.
     * @param _hook hook
     */
    function openRebalancePeriod(
        uint256[2] memory nextVaultIndexAlloc,
        uint256[2] memory nextIndexComposition,
        int256 externalPosition,
        SetPricesParams memory priceData,
        bytes memory _hook
    ) external onlyRole(KEEPER_ROLE) setOraclePricing(priceData) {
        // before rebalance hook
        _executeHook(HookType.OPEN_REBALANCE_HOOK, _hook);
        VaultState storage vaultState = _getVaultState();
        if (vaultState.rebalanceOpen) revert RebalanceOpen();

        // check netting constraint
        checkNettingConstraint(
            Solarray.arraySum(nextVaultIndexAlloc), nextVaultIndexAlloc, nextIndexComposition, externalPosition
        );

        // pause vault deposits
        pauseDeposits();

        // set rebalance storage
        RebalanceState storage rebalanceState = _getRebalanceState();
        rebalanceState.indexAllocation = nextVaultIndexAlloc;
        rebalanceState.indexComposition = nextIndexComposition;
        rebalanceState.externalPosition = externalPosition;
        rebalanceState.epoch = vaultState.epoch;

        // cache the rebalance PPS
        AssetVaultStorage[2] storage assetVaults = _getAssetVaultEntries();
        for (uint256 i = 0; i < 2; i++) {
            vaultState.rebalancePPS[i] = getVaultPPS(assetVaults[i].vault, false, true);
        }
        vaultState.rebalanceOpen = true;

        Emitter(_getEmitter()).emitOpenRebalance(
            block.timestamp, nextVaultIndexAlloc, nextIndexComposition, externalPosition
        );
    }

    /**
     * @notice Closes a rebalance period and validates current state is valid.
     */
    function closeRebalancePeriod(SetPricesParams memory priceData, bytes memory _hook)
        external
        onlyRole(KEEPER_ROLE)
        setOraclePricing(priceData)
    {
        VaultState storage vaultState = _getVaultState();
        if (!vaultState.rebalanceOpen) revert RebalanceNotOpen();
        RebalanceState storage rebalanceState = _getRebalanceState();

        address aggregateVaultHelper = _getStorage().aggregateVaultHelper;
        bytes memory gmiValue = aggregateVaultHelper.delegateCall(
            abi.encodeCall(AggregateVaultHelper.getVaultsGmiValue, (vaultState.epoch, true))
        );
        uint256[2] memory vaultIndexAllocation = abi.decode(gmiValue, (uint256[2]));

        // check netting constraint
        checkNettingConstraint(
            Solarray.arraySum(vaultIndexAllocation),
            rebalanceState.indexAllocation,
            rebalanceState.indexComposition,
            rebalanceState.externalPosition
        );

        // calculate the new netted positions
        (int256[2][2] memory nettedMatrix,) = NettingMath.calculateNettedPositions(
            rebalanceState.externalPosition, rebalanceState.indexComposition, vaultIndexAllocation
        );

        AssetVaultStorage[2] storage assetVaults = _getAssetVaultEntries();

        // collect fees
        if (vaultState.epoch > 0) _collectVaultRebalanceFees(assetVaults);

        // reset epoch delta
        _resetEpochDeltas();

        vaultState.rebalanceOpen = false;
        vaultState.indexAllocation = rebalanceState.indexAllocation;

        // set netted positions
        _setPositions(nettedMatrix, rebalanceState.externalPosition);

        // finalise tvl checkpoint
        _setCheckpointTvls(assetVaults);

        // note set last to not trigger internal pnl
        vaultState.epoch += 1;
        vaultState.lastRebalanceTime = block.timestamp;

        // after rebalance hook
        _executeHook(HookType.CLOSE_REBALANCE_HOOK, _hook);

        // unpause vaults
        unpauseDeposits();

        Emitter(_getEmitter()).emitCloseRebalance(block.timestamp);
    }

    /**
     * @notice Checks if the netting constraint is satisfied for the given input values.
     * @dev Reverts if the netting constraint is not satisfied.
     * @param vaultCumulativeHoldings The total dollars deposited in backing.
     * @param indexComposition composition of the backing index.
     * @param vaultHoldings amount held by each vault.
     * @param externalPosition the external position to hedge.
     */
    function checkNettingConstraint(
        uint256 vaultCumulativeHoldings,
        uint256[2] memory vaultHoldings,
        uint256[2] memory indexComposition,
        int256 externalPosition
    ) internal view {
        if (_getStorage().shouldCheckNetting) {
            if (
                !NettingMath.isNetted(
                    vaultCumulativeHoldings, indexComposition, vaultHoldings, externalPosition, _getNettedThreshold()
                )
            ) {
                revert FailedNettingCheck();
            }
        }
    }

    // VIEWS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice vault rebalance in progress
     */
    function rebalanceOpen() external view returns (bool) {
        return _getVaultState().rebalanceOpen;
    }

    /**
     * @notice preview a vault request
     * @param key The request key to query for
     * @return - The OCRequest corresponding to the key if set
     */
    function getRequest(uint256 key) external view returns (OCRequest memory) {
        return _getStorage().pendingRequests[key];
    }

    /**
     * @notice Gets the current asset vault price per share (PPS)
     * @param _assetVault The address of the asset vault whose PPS is being queried
     * @param useLlo should use the low latency oracle price
     * @return _tvl The current asset vault PPS
     */
    function getVaultPPS(address _assetVault, bool isDeposit, bool useLlo) public returns (uint256) {
        address aggregateVaultHelper = _getStorage().aggregateVaultHelper;
        bytes memory ret = aggregateVaultHelper.delegateCall(
            abi.encodeCall(AggregateVaultHelper.getVaultPPS, (_assetVault, isDeposit, useLlo))
        );
        return abi.decode(ret, (uint256));
    }

    /**
     * @notice Gets the current asset vault total value locked (TVL)
     * @param _assetVault The address of the asset vault whose TVL is being queried
     * @param useLlo should use the low latency oracle price
     * @return _tvl The current asset vault TVL
     */
    function getVaultTVL(address _assetVault, bool useLlo) public returns (uint256 _tvl) {
        address aggregateVaultHelper = _getStorage().aggregateVaultHelper;
        bytes memory ret =
            aggregateVaultHelper.delegateCall(abi.encodeCall(AggregateVaultHelper.getVaultTVL, (_assetVault, useLlo)));
        return abi.decode(ret, (uint256));
    }

    /**
     * @notice preview deposit fee
     * @param size The size of the deposit for which the fee is being calculated
     * @return totalDepositFee The calculated deposit fee
     */
    function previewDepositFee(address token, uint256 size, bool useLlo) external returns (uint256 totalDepositFee) {
        address feeHelper = _getFeeHelper();
        (bytes memory ret) = feeHelper.delegateCall(abi.encodeCall(IVaultFees.getDepositFee, (token, size, useLlo)));
        (totalDepositFee) = abi.decode(ret, (uint256));
    }

    /**
     * @notice preview withdrawal fee
     * @param token The address of the token for which the withdrawal fee is being calculated
     * @param size The size of the withdrawal for which the fee is being calculated
     * @return totalWithdrawalFee The calculated withdrawal fee
     */
    function previewWithdrawalFee(address token, uint256 size, bool useLlo)
        external
        returns (uint256 totalWithdrawalFee)
    {
        address feeHelper = _getFeeHelper();
        (bytes memory ret) = feeHelper.delegateCall(abi.encodeCall(IVaultFees.getWithdrawalFee, (token, size, useLlo)));
        uint256 baseFee;
        (totalWithdrawalFee, baseFee) = abi.decode(ret, (uint256, uint256));
        totalWithdrawalFee += baseFee;
    }

    /**
     * @notice Preview the asset vault cap
     * @param _asset The address of the asset whose vault cap is being queried
     * @return The current asset vault cap
     */
    function previewVaultCap(address _asset) external view returns (uint256) {
        uint256 vidx = _getTokenToAssetVaultIndex()[_asset];
        VaultState memory state = _getVaultState();
        return state.vaultCaps[vidx];
    }

    /**
     * @notice Preview the timelock address for an asset vault
     * @param _asset The address of the asset whose vault timelock is being queried
     * @return timelock address of the timelock contract
     */
    function getVaultTimelockAddress(address _asset) external view returns (address timelock) {
        AssetVaultStorage storage vaultStg = _getVaultFromAsset(_asset);
        return vaultStg.timelockYieldBoost;
    }

    /**
     * @dev reads storage slots in the contract returned as bytes32[] result
     */
    function readStorageSlots(bytes32[] calldata _slots) external view returns (bytes32[] memory _values) {
        _values = new bytes32[](_slots.length);
        for (uint256 i; i < _slots.length; i++) {
            uint256 value;
            bytes32 slot = _slots[i];
            assembly {
                value := sload(slot)
            }
            _values[i] = bytes32(value);
        }
    }

    /**
     * @notice Update asset vault receipt contracts
     * @param assetVaults An array of new asset vault entries
     */
    function setAssetVaults(AssetVaultStorage[2] calldata assetVaults) external onlyConfigurator {
        AssetVaultStorage[2] storage vaults = _getAssetVaultEntries();
        mapping(address => uint256) storage tokenToAssetVaultIndex = _getTokenToAssetVaultIndex();
        mapping(address => uint256) storage vaultToAssetVaultIndex = _getVaultToAssetVaultIndex();

        for (uint256 i = 0; i < 2; i++) {
            vaults[i] = assetVaults[i];
            tokenToAssetVaultIndex[assetVaults[i].token] = i;
            vaultToAssetVaultIndex[assetVaults[i].vault] = i;
        }
    }

    // CONFIG
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Set the peripheral contract addresses
     * @param peripheral The enum value of the peripheral type
     * @param addr The address of the peripheral contract
     */
    function setPeripheral(Peripheral peripheral, address addr) external onlyConfigurator {
        AVStorage storage stg = _getStorage();
        if (peripheral == Peripheral.HookHandler) {
            stg.hookHandler = addr;
        } else if (peripheral == Peripheral.EventEmitter) {
            stg.emitter = addr;
        } else if (peripheral == Peripheral.OracleWrapper) {
            stg.oracleWrapper = addr;
        } else if (peripheral == Peripheral.GMI) {
            stg.gmi = payable(addr);
        } else if (peripheral == Peripheral.AggregateVaultHelper) {
            stg.aggregateVaultHelper = addr;
        } else if (peripheral == Peripheral.GmxV2Handler) {
            stg.gmxV2Handler = addr;
        } else if (peripheral == Peripheral.FeeHelper) {
            stg.feeHelper = addr;
        } else if (peripheral == Peripheral.RequestHandler) {
            stg.requestHandler = addr;
        } else if (peripheral == Peripheral.UniswapV3SwapManager) {
            stg.uniswapV3SwapManager = addr;
        } else {
            revert("AggregateVault: invalid peripheral");
        }
    }

    function setConfig(ConfigItem _item, bytes calldata _data) external onlyConfigurator {
        AVStorage storage stg = _getStorage();
        if (_item == ConfigItem.VaultFees) {
            (uint256 performanceFee, uint256 managementFee, uint256 withdrawalFee, uint256 depositFee) =
                abi.decode(_data, (uint256, uint256, uint256, uint256));
            _getStorage().vaultFees = VaultFees({
                performanceFee: performanceFee,
                managementFee: managementFee,
                withdrawalFee: withdrawalFee,
                depositFee: depositFee
            });
        } else if (_item == ConfigItem.ShouldCheckNetting) {
            bool val = abi.decode(_data, (bool));
            stg.shouldCheckNetting = val;
        } else if (_item == ConfigItem.ShouldUseGmxFee) {
            bool val = abi.decode(_data, (bool));
            stg.shouldUseGmxFee = val;
        } else if (_item == ConfigItem.L1BlockTolerance) {
            uint8 newBlockTolerance = abi.decode(_data, (uint8));
            _setL1BlockTolerance(newBlockTolerance);
        } else if (_item == ConfigItem.ExecutionGasAmounts) {
            (uint256 executionGasAmount, uint256 executionGasAmountCallback) = abi.decode(_data, (uint256, uint256));
            stg.executionGasAmount = executionGasAmount;
            stg.executionGasAmountCallback = executionGasAmountCallback;
        } else if (_item == ConfigItem.RebalanceKeeper) {
            address newKeeper = abi.decode(_data, (address));
            _setRebalanceKeeper(newKeeper);
        } else if (_item == ConfigItem.FeeRecipient) {
            (address recipient, address depositFeeEscrow, address withdrawalFeeEscrow) =
                abi.decode(_data, (address, address, address));
            VaultState storage state = _getVaultState();
            state.feeRecipient = recipient;
            state.depositFeeEscrow = depositFeeEscrow;
            state.withdrawalFeeEscrow = withdrawalFeeEscrow;
        } else if (_item == ConfigItem.VaultCaps) {
            (uint256[2] memory caps) = abi.decode(_data, (uint256[2]));
            VaultState storage state = _getVaultState();
            state.vaultCaps = caps;
        } else if (_item == ConfigItem.Thresholds) {
            (uint256 newNettedThreshold, uint256 zeroSumPnlThreshold, uint256 swapSlippage) =
                abi.decode(_data, (uint256, uint256, uint256));

            if (
                zeroSumPnlThreshold == 0 || zeroSumPnlThreshold >= 1e18 || newNettedThreshold == 0
                    || newNettedThreshold >= 10_000
            ) revert FailedConfigValidation();

            stg.zeroSumPnlThreshold = zeroSumPnlThreshold;
            stg.nettedThreshold = newNettedThreshold;
            stg.swapSlippage = swapSlippage;
        } else {
            revert AggregateVault__InvalidConfigItem();
        }
    }

    /**
     * @notice Add a new position manager to the list of position managers
     * @param _manager The address of the new position manager
     */
    function addPositionManager(IPositionManager _manager) external onlyConfigurator {
        IPositionManager[] storage positionManagers = _getPositionManagers();
        positionManagers.push(_manager);
    }

    // DELEGATE VIEWS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Executes a delegate view to the specified target with the provided data and decodes the response as bytes.
     */
    function delegateview(address _target, bytes calldata _data) external returns (bool _success, bytes memory _ret) {
        (bool success, bytes memory ret) = address(this).call(abi.encodeCall(this.delegateviewRevert, (_target, _data)));
        if (success) revert DelegateViewRevert();
        (_success, _ret) = abi.decode(ret, (bool, bytes));
    }

    /**
     * @notice Executes a delegate call to the specified target with the provided data and reverts on error.
     */
    function delegateviewRevert(address _target, bytes memory _data) external {
        (bool success, bytes memory ret) = _target.delegatecall(_data);
        bytes memory encoded = abi.encode(success, ret);
        /// @solidity memory-safe-assembly
        assembly {
            revert(add(encoded, 0x20), mload(encoded))
        }
    }

    // INTERNAL
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Collects vault rebalance fees, mints timelock shares and distributes them.
     */
    function _collectVaultRebalanceFees(AssetVaultStorage[2] memory assetVaults) internal {
        uint256 performanceFeeInAsset;
        uint256 managementFeeInAsset;
        uint256 timelockYieldMintAmount;
        uint256 totalVaultFee;
        address feeHelper = _getFeeHelper();
        VaultState storage vaultState = _getVaultState();
        for (uint256 i = 0; i < 2; i++) {
            (bytes memory ret) = feeHelper.delegateCall(
                abi.encodeCall(IVaultFees.getVaultRebalanceFees, (assetVaults[i].token, vaultState.lastRebalanceTime))
            );
            (performanceFeeInAsset, managementFeeInAsset, timelockYieldMintAmount, totalVaultFee) =
                abi.decode(ret, (uint256, uint256, uint256, uint256));

            if (totalVaultFee > 0) {
                TransferUtils.transferAsset(assetVaults[i].token, vaultState.feeRecipient, totalVaultFee);
            }
            if (timelockYieldMintAmount > 0 && assetVaults[i].timelockYieldBoost != address(0)) {
                AssetVault(assetVaults[i].vault).mintTo(timelockYieldMintAmount, assetVaults[i].timelockYieldBoost);
            }

            Emitter(_getEmitter()).emitCollectVaultFees(
                totalVaultFee,
                performanceFeeInAsset,
                managementFeeInAsset,
                timelockYieldMintAmount,
                assetVaults[i].vault
            );
        }
    }

    /**
     * @notice Resets the epoch deposit/withdraw delta for all asset vaults.
     */
    function _resetEpochDeltas() internal {
        AssetVaultStorage[2] storage assetVaults = _getAssetVaultEntries();
        assetVaults[0].epochDelta = int256(0);
        assetVaults[1].epochDelta = int256(0);
    }

    /**
     * @notice Sets the checkpoint TVL for all asset vaults.
     */
    function _setCheckpointTvls(AssetVaultStorage[2] storage assetVaults) internal {
        assetVaults[0].lastCheckpointTvl = getVaultTVL(assetVaults[0].vault, true);
        assetVaults[1].lastCheckpointTvl = getVaultTVL(assetVaults[1].vault, true);
    }

    // UTILS
    // ------------------------------------------------------------------------------------------

    function depositEth() external payable onlyRole(KEEPER_ROLE) { }

    function withdrawEth(uint256 amount) external payable onlyRole(KEEPER_ROLE) {
        TransferUtils.transferNativeAsset(msg.sender, amount);
    }

    /**
     * @notice Pause deposits and withdrawals for the asset vaults
     */
    function pauseDeposits() public onlyRole(KEEPER_ROLE) {
        AssetVaultStorage[2] storage assetVaults = _getAssetVaultEntries();
        for (uint256 i = 0; i < 2; i++) {
            bool isPaused = IAssetVault(assetVaults[i].vault).depositPaused()
                || IAssetVault(assetVaults[i].vault).withdrawalPaused();
            if (isPaused) revert AggregateVault__AlreadyPaused();
            IAssetVault(assetVaults[i].vault).pauseDepositWithdraw();
        }
    }

    /**
     * @notice Unpause deposits and withdrawals for the asset vaults
     */
    function unpauseDeposits() public onlyRole(KEEPER_ROLE) {
        AssetVaultStorage[2] storage assetVaults = _getAssetVaultEntries();
        for (uint256 i = 0; i < 2; i++) {
            IAssetVault(assetVaults[i].vault).unpauseDepositWithdraw();
        }
    }

    /**
     * @notice Sets the oracle ricing
     */
    modifier setOraclePricing(SetPricesParams memory prices) {
        if (prices.realtimeFeedTokens.length != prices.realtimeFeedData.length) revert OraclePriceSizeInvalid();
        for (uint256 i = 0; i < prices.realtimeFeedTokens.length; i++) {
            OracleWrapper(_getOracleWrapper()).setAndGetLloPrice(
                prices.realtimeFeedTokens[i], prices.realtimeFeedData[i]
            );
        }
        _;
    }

    /**
     * @notice Ensures the caller is an asset vault.
     */
    modifier onlyAssetVault() {
        if (!_isAssetVault()) revert NotAssetVault();
        _;
    }

    /**
     * @notice Ensures the caller is the RequestHandler or the AssetVault.
     */
    modifier onlyRequestHandlerOrAssetVault() {
        if (!(_isAssetVault() || AUTH.hasRole(REQUEST_HANDLER, msg.sender))) revert notRequestHandlerOrAssetVault();
        _;
    }

    /**
     * @notice check if the sender is an assetVault
     */
    function _isAssetVault() internal view returns (bool) {
        AssetVaultStorage[2] storage assetVaults = _getAssetVaultEntries();
        for (uint256 i = 0; i < 2; ++i) {
            if (msg.sender == assetVaults[i].vault) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev returns the gas requirement for call execution.
     */
    function _gasRequirement(bool _callback) internal view returns (uint256) {
        return _callback ? _getStorage().executionGasAmountCallback : _getStorage().executionGasAmount;
    }

    /// @dev To be implemented by inheriting contracts to restrict certain functions to a configurator role.
    function _onlyConfigurator() internal override onlyConfigurator { }

    /// @dev To be implemented by inheriting contracts to validate the caller's authorization for execute calls.
    function _validateExecuteCallAuth() internal override onlyRole(KEEPER_ROLE) { }

    /**
     * @notice Ensures the caller is permissioned to swap.
     */
    function _onlySwapIssuer() internal override onlyRole(SWAP_KEEPER) { }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall {
    function _multicall(bytes[] calldata data)
        internal
        returns (bytes[] memory results, uint256[] memory gasEstimates)
    {
        results = new bytes[](data.length);
        gasEstimates = new uint256[](data.length);

        unchecked {
            for (uint256 i = 0; i < data.length; ++i) {
                uint256 startGas = gasleft();
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);

                if (!success) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        let resultLength := mload(result)
                        revert(add(result, 0x20), resultLength)
                    }
                }

                results[i] = result;
                uint256 endGas = gasleft();
                gasEstimates[i] = startGas - endGas;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
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
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
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
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
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
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
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
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
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
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
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
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
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
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
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
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
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
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
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
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
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
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
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
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
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
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
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
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
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
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
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
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
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
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
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
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
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
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
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
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
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
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
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
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
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
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
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
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
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
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/Calc.sol";
import "../utils/Printer.sol";

// @title DataStore
// @dev DataStore for all general state values
contract DataStore is RoleModule {
    using SafeCast for int256;

    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableValues for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.UintSet;

    // store for uint values
    mapping(bytes32 => uint256) public uintValues;
    // store for int values
    mapping(bytes32 => int256) public intValues;
    // store for address values
    mapping(bytes32 => address) public addressValues;
    // store for bool values
    mapping(bytes32 => bool) public boolValues;
    // store for string values
    mapping(bytes32 => string) public stringValues;
    // store for bytes32 values
    mapping(bytes32 => bytes32) public bytes32Values;

    // store for uint[] values
    mapping(bytes32 => uint256[]) public uintArrayValues;
    // store for int[] values
    mapping(bytes32 => int256[]) public intArrayValues;
    // store for address[] values
    mapping(bytes32 => address[]) public addressArrayValues;
    // store for bool[] values
    mapping(bytes32 => bool[]) public boolArrayValues;
    // store for string[] values
    mapping(bytes32 => string[]) public stringArrayValues;
    // store for bytes32[] values
    mapping(bytes32 => bytes32[]) public bytes32ArrayValues;

    // store for bytes32 sets
    mapping(bytes32 => EnumerableSet.Bytes32Set) internal bytes32Sets;
    // store for address sets
    mapping(bytes32 => EnumerableSet.AddressSet) internal addressSets;
    // store for uint256 sets
    mapping(bytes32 => EnumerableSet.UintSet) internal uintSets;

    constructor(RoleStore _roleStore) RoleModule(_roleStore) {}

    // @dev get the uint value for the given key
    // @param key the key of the value
    // @return the uint value for the key
    function getUint(bytes32 key) external view returns (uint256) {
        return uintValues[key];
    }

    // @dev set the uint value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the uint value for the key
    function setUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uintValues[key] = value;
        return value;
    }

    // @dev delete the uint value for the given key
    // @param key the key of the value
    function removeUint(bytes32 key) external onlyController {
        delete uintValues[key];
    }

    // @dev add the input int value to the existing uint value
    // @param key the key of the value
    // @param value the input int value
    // @return the new uint value
    function applyDeltaToUint(bytes32 key, int256 value, string memory errorMessage) external onlyController returns (uint256) {
        uint256 currValue = uintValues[key];
        if (value < 0 && (-value).toUint256() > currValue) {
            revert(errorMessage);
        }
        uint256 nextUint = Calc.sumReturnUint256(currValue, value);
        uintValues[key] = nextUint;
        return nextUint;
    }

    // @dev add the input uint value to the existing uint value
    // @param key the key of the value
    // @param value the input int value
    // @return the new uint value
    function applyDeltaToUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uint256 currValue = uintValues[key];
        uint256 nextUint = currValue + value;
        uintValues[key] = nextUint;
        return nextUint;
    }

    // @dev add the input int value to the existing uint value, prevent the uint
    // value from becoming negative
    // @param key the key of the value
    // @param value the input int value
    // @return the new uint value
    function applyBoundedDeltaToUint(bytes32 key, int256 value) external onlyController returns (uint256) {
        uint256 uintValue = uintValues[key];
        if (value < 0 && (-value).toUint256() > uintValue) {
            uintValues[key] = 0;
            return 0;
        }

        uint256 nextUint = Calc.sumReturnUint256(uintValue, value);
        uintValues[key] = nextUint;
        return nextUint;
    }

    // @dev add the input uint value to the existing uint value
    // @param key the key of the value
    // @param value the input uint value
    // @return the new uint value
    function incrementUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uint256 nextUint = uintValues[key] + value;
        uintValues[key] = nextUint;
        return nextUint;
    }

    // @dev subtract the input uint value from the existing uint value
    // @param key the key of the value
    // @param value the input uint value
    // @return the new uint value
    function decrementUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uint256 nextUint = uintValues[key] - value;
        uintValues[key] = nextUint;
        return nextUint;
    }

    // @dev get the int value for the given key
    // @param key the key of the value
    // @return the int value for the key
    function getInt(bytes32 key) external view returns (int256) {
        return intValues[key];
    }

    // @dev set the int value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the int value for the key
    function setInt(bytes32 key, int256 value) external onlyController returns (int256) {
        intValues[key] = value;
        return value;
    }

    function removeInt(bytes32 key) external onlyController {
        delete intValues[key];
    }

    // @dev add the input int value to the existing int value
    // @param key the key of the value
    // @param value the input int value
    // @return the new int value
    function applyDeltaToInt(bytes32 key, int256 value) external onlyController returns (int256) {
        int256 nextInt = intValues[key] + value;
        intValues[key] = nextInt;
        return nextInt;
    }

    // @dev add the input int value to the existing int value
    // @param key the key of the value
    // @param value the input int value
    // @return the new int value
    function incrementInt(bytes32 key, int256 value) external onlyController returns (int256) {
        int256 nextInt = intValues[key] + value;
        intValues[key] = nextInt;
        return nextInt;
    }

    // @dev subtract the input int value from the existing int value
    // @param key the key of the value
    // @param value the input int value
    // @return the new int value
    function decrementInt(bytes32 key, int256 value) external onlyController returns (int256) {
        int256 nextInt = intValues[key] - value;
        intValues[key] = nextInt;
        return nextInt;
    }

    // @dev get the address value for the given key
    // @param key the key of the value
    // @return the address value for the key
    function getAddress(bytes32 key) external view returns (address) {
        return addressValues[key];
    }

    // @dev set the address value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the address value for the key
    function setAddress(bytes32 key, address value) external onlyController returns (address) {
        addressValues[key] = value;
        return value;
    }

    // @dev delete the address value for the given key
    // @param key the key of the value
    function removeAddress(bytes32 key) external onlyController {
        delete addressValues[key];
    }

    // @dev get the bool value for the given key
    // @param key the key of the value
    // @return the bool value for the key
    function getBool(bytes32 key) external view returns (bool) {
        return boolValues[key];
    }

    // @dev set the bool value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the bool value for the key
    function setBool(bytes32 key, bool value) external onlyController returns (bool) {
        boolValues[key] = value;
        return value;
    }

    // @dev delete the bool value for the given key
    // @param key the key of the value
    function removeBool(bytes32 key) external onlyController {
        delete boolValues[key];
    }

    // @dev get the string value for the given key
    // @param key the key of the value
    // @return the string value for the key
    function getString(bytes32 key) external view returns (string memory) {
        return stringValues[key];
    }

    // @dev set the string value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the string value for the key
    function setString(bytes32 key, string memory value) external onlyController returns (string memory) {
        stringValues[key] = value;
        return value;
    }

    // @dev delete the string value for the given key
    // @param key the key of the value
    function removeString(bytes32 key) external onlyController {
        delete stringValues[key];
    }

    // @dev get the bytes32 value for the given key
    // @param key the key of the value
    // @return the bytes32 value for the key
    function getBytes32(bytes32 key) external view returns (bytes32) {
        return bytes32Values[key];
    }

    // @dev set the bytes32 value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the bytes32 value for the key
    function setBytes32(bytes32 key, bytes32 value) external onlyController returns (bytes32) {
        bytes32Values[key] = value;
        return value;
    }

    // @dev delete the bytes32 value for the given key
    // @param key the key of the value
    function removeBytes32(bytes32 key) external onlyController {
        delete bytes32Values[key];
    }

    // @dev get the uint array for the given key
    // @param key the key of the uint array
    // @return the uint array for the key
    function getUintArray(bytes32 key) external view returns (uint256[] memory) {
        return uintArrayValues[key];
    }

    // @dev set the uint array for the given key
    // @param key the key of the uint array
    // @param value the value of the uint array
    function setUintArray(bytes32 key, uint256[] memory value) external onlyController {
        uintArrayValues[key] = value;
    }

    // @dev delete the uint array for the given key
    // @param key the key of the uint array
    // @param value the value of the uint array
    function removeUintArray(bytes32 key) external onlyController {
        delete uintArrayValues[key];
    }

    // @dev get the int array for the given key
    // @param key the key of the int array
    // @return the int array for the key
    function getIntArray(bytes32 key) external view returns (int256[] memory) {
        return intArrayValues[key];
    }

    // @dev set the int array for the given key
    // @param key the key of the int array
    // @param value the value of the int array
    function setIntArray(bytes32 key, int256[] memory value) external onlyController {
        intArrayValues[key] = value;
    }

    // @dev delete the int array for the given key
    // @param key the key of the int array
    // @param value the value of the int array
    function removeIntArray(bytes32 key) external onlyController {
        delete intArrayValues[key];
    }

    // @dev get the address array for the given key
    // @param key the key of the address array
    // @return the address array for the key
    function getAddressArray(bytes32 key) external view returns (address[] memory) {
        return addressArrayValues[key];
    }

    // @dev set the address array for the given key
    // @param key the key of the address array
    // @param value the value of the address array
    function setAddressArray(bytes32 key, address[] memory value) external onlyController {
        addressArrayValues[key] = value;
    }

    // @dev delete the address array for the given key
    // @param key the key of the address array
    // @param value the value of the address array
    function removeAddressArray(bytes32 key) external onlyController {
        delete addressArrayValues[key];
    }

    // @dev get the bool array for the given key
    // @param key the key of the bool array
    // @return the bool array for the key
    function getBoolArray(bytes32 key) external view returns (bool[] memory) {
        return boolArrayValues[key];
    }

    // @dev set the bool array for the given key
    // @param key the key of the bool array
    // @param value the value of the bool array
    function setBoolArray(bytes32 key, bool[] memory value) external onlyController {
        boolArrayValues[key] = value;
    }

    // @dev delete the bool array for the given key
    // @param key the key of the bool array
    // @param value the value of the bool array
    function removeBoolArray(bytes32 key) external onlyController {
        delete boolArrayValues[key];
    }

    // @dev get the string array for the given key
    // @param key the key of the string array
    // @return the string array for the key
    function getStringArray(bytes32 key) external view returns (string[] memory) {
        return stringArrayValues[key];
    }

    // @dev set the string array for the given key
    // @param key the key of the string array
    // @param value the value of the string array
    function setStringArray(bytes32 key, string[] memory value) external onlyController {
        stringArrayValues[key] = value;
    }

    // @dev delete the string array for the given key
    // @param key the key of the string array
    // @param value the value of the string array
    function removeStringArray(bytes32 key) external onlyController {
        delete stringArrayValues[key];
    }

    // @dev get the bytes32 array for the given key
    // @param key the key of the bytes32 array
    // @return the bytes32 array for the key
    function getBytes32Array(bytes32 key) external view returns (bytes32[] memory) {
        return bytes32ArrayValues[key];
    }

    // @dev set the bytes32 array for the given key
    // @param key the key of the bytes32 array
    // @param value the value of the bytes32 array
    function setBytes32Array(bytes32 key, bytes32[] memory value) external onlyController {
        bytes32ArrayValues[key] = value;
    }

    // @dev delete the bytes32 array for the given key
    // @param key the key of the bytes32 array
    // @param value the value of the bytes32 array
    function removeBytes32Array(bytes32 key) external onlyController {
        delete bytes32ArrayValues[key];
    }

    // @dev check whether the given value exists in the set
    // @param setKey the key of the set
    // @param value the value to check
    function containsBytes32(bytes32 setKey, bytes32 value) external view returns (bool) {
        return bytes32Sets[setKey].contains(value);
    }

    // @dev get the length of the set
    // @param setKey the key of the set
    function getBytes32Count(bytes32 setKey) external view returns (uint256) {
        return bytes32Sets[setKey].length();
    }

    // @dev get the values of the set in the given range
    // @param setKey the key of the set
    // @param the start of the range, values at the start index will be returned
    // in the result
    // @param the end of the range, values at the end index will not be returned
    // in the result
    function getBytes32ValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (bytes32[] memory) {
        return bytes32Sets[setKey].valuesAt(start, end);
    }

    // @dev add the given value to the set
    // @param setKey the key of the set
    // @param value the value to add
    function addBytes32(bytes32 setKey, bytes32 value) external onlyController {
        bytes32Sets[setKey].add(value);
    }

    // @dev remove the given value from the set
    // @param setKey the key of the set
    // @param value the value to remove
    function removeBytes32(bytes32 setKey, bytes32 value) external onlyController {
        bytes32Sets[setKey].remove(value);
    }

    // @dev check whether the given value exists in the set
    // @param setKey the key of the set
    // @param value the value to check
    function containsAddress(bytes32 setKey, address value) external view returns (bool) {
        return addressSets[setKey].contains(value);
    }

    // @dev get the length of the set
    // @param setKey the key of the set
    function getAddressCount(bytes32 setKey) external view returns (uint256) {
        return addressSets[setKey].length();
    }

    // @dev get the values of the set in the given range
    // @param setKey the key of the set
    // @param the start of the range, values at the start index will be returned
    // in the result
    // @param the end of the range, values at the end index will not be returned
    // in the result
    function getAddressValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (address[] memory) {
        return addressSets[setKey].valuesAt(start, end);
    }

    // @dev add the given value to the set
    // @param setKey the key of the set
    // @param value the value to add
    function addAddress(bytes32 setKey, address value) external onlyController {
        addressSets[setKey].add(value);
    }

    // @dev remove the given value from the set
    // @param setKey the key of the set
    // @param value the value to remove
    function removeAddress(bytes32 setKey, address value) external onlyController {
        addressSets[setKey].remove(value);
    }

    // @dev check whether the given value exists in the set
    // @param setKey the key of the set
    // @param value the value to check
    function containsUint(bytes32 setKey, uint256 value) external view returns (bool) {
        return uintSets[setKey].contains(value);
    }

    // @dev get the length of the set
    // @param setKey the key of the set
    function getUintCount(bytes32 setKey) external view returns (uint256) {
        return uintSets[setKey].length();
    }

    // @dev get the values of the set in the given range
    // @param setKey the key of the set
    // @param the start of the range, values at the start index will be returned
    // in the result
    // @param the end of the range, values at the end index will not be returned
    // in the result
    function getUintValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (uint256[] memory) {
        return uintSets[setKey].valuesAt(start, end);
    }

    // @dev add the given value to the set
    // @param setKey the key of the set
    // @param value the value to add
    function addUint(bytes32 setKey, uint256 value) external onlyController {
        uintSets[setKey].add(value);
    }

    // @dev remove the given value from the set
    // @param setKey the key of the set
    // @param value the value to remove
    function removeUint(bytes32 setKey, uint256 value) external onlyController {
        uintSets[setKey].remove(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "./EventUtils.sol";

// @title EventEmitter
// @dev Contract to emit events
// This allows main events to be emitted from a single contract
// Logic contracts can be updated while re-using the same eventEmitter contract
// Peripheral services like monitoring or analytics would be able to continue
// to work without an update and without segregating historical data
contract EventEmitter is RoleModule {
    event EventLog(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        EventUtils.EventLogData eventData
    );

    event EventLog1(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        bytes32 indexed topic1,
        EventUtils.EventLogData eventData
    );

    event EventLog2(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        bytes32 indexed topic1,
        bytes32 indexed topic2,
        EventUtils.EventLogData eventData
    );

    constructor(RoleStore _roleStore) RoleModule(_roleStore) {}

    // @dev emit a general event log
    // @param eventName the name of the event
    // @param eventData the event data
    function emitEventLog(
        string memory eventName,
        EventUtils.EventLogData memory eventData
    ) external onlyController {
        emit EventLog(
            msg.sender,
            eventName,
            eventName,
            eventData
        );
    }

    // @dev emit a general event log
    // @param eventName the name of the event
    // @param topic1 topic1 for indexing
    // @param eventData the event data
    function emitEventLog1(
        string memory eventName,
        bytes32 topic1,
        EventUtils.EventLogData memory eventData
    ) external onlyController {
        emit EventLog1(
            msg.sender,
            eventName,
            eventName,
            topic1,
            eventData
        );
    }

    // @dev emit a general event log
    // @param eventName the name of the event
    // @param topic1 topic1 for indexing
    // @param topic2 topic2 for indexing
    // @param eventData the event data
    function emitEventLog2(
        string memory eventName,
        bytes32 topic1,
        bytes32 topic2,
        EventUtils.EventLogData memory eventData
    ) external onlyController {
        emit EventLog2(
            msg.sender,
            eventName,
            eventName,
            topic1,
            topic2,
            eventData
        );
    }
    // @dev event log for general use
    // @param topic1 event topic 1
    // @param data additional data
    function emitDataLog1(bytes32 topic1, bytes memory data) external onlyController {
        uint256 len = data.length;
        assembly {
            log1(add(data, 32), len, topic1)
        }
    }

    // @dev event log for general use
    // @param topic1 event topic 1
    // @param topic2 event topic 2
    // @param data additional data
    function emitDataLog2(bytes32 topic1, bytes32 topic2, bytes memory data) external onlyController {
        uint256 len = data.length;
        assembly {
            log2(add(data, 32), len, topic1, topic2)
        }
    }

    // @dev event log for general use
    // @param topic1 event topic 1
    // @param topic2 event topic 2
    // @param topic3 event topic 3
    // @param data additional data
    function emitDataLog3(bytes32 topic1, bytes32 topic2, bytes32 topic3, bytes memory data) external onlyController {
        uint256 len = data.length;
        assembly {
            log3(add(data, 32), len, topic1, topic2, topic3)
        }
    }

    // @dev event log for general use
    // @param topic1 event topic 1
    // @param topic2 event topic 2
    // @param topic3 event topic 3
    // @param topic4 event topic 4
    // @param data additional data
    function emitDataLog4(bytes32 topic1, bytes32 topic2, bytes32 topic3, bytes32 topic4, bytes memory data) external onlyController {
        uint256 len = data.length;
        assembly {
            log4(add(data, 32), len, topic1, topic2, topic3, topic4)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Bank.sol";

// @title StrictBank
// @dev a stricter version of Bank
//
// the Bank contract does not have functions to validate the amount of tokens
// transferred in
// the Bank contract will mainly assume that safeTransferFrom calls work correctly
// and that tokens were transferred into it if there was no revert
//
// the StrictBank contract keeps track of its internal token balance
// and uses recordTransferIn to compare its change in balance and return
// the amount of tokens received
contract StrictBank is Bank {
    using SafeERC20 for IERC20;

    // used to record token balances to evaluate amounts transferred in
    mapping (address => uint256) public tokenBalances;

    constructor(RoleStore _roleStore, DataStore _dataStore) Bank(_roleStore, _dataStore) {}

    // @dev records a token transfer into the contract
    // @param token the token to record the transfer for
    // @return the amount of tokens transferred in
    function recordTransferIn(address token) external onlyController returns (uint256) {
        return _recordTransferIn(token);
    }

    // @dev this can be used to update the tokenBalances in case of token burns
    // or similar balance changes
    // the prevBalance is not validated to be more than the nextBalance as this
    // could allow someone to block this call by transferring into the contract
    // @param token the token to record the burn for
    // @return the new balance
    function syncTokenBalance(address token) external onlyController returns (uint256) {
        uint256 nextBalance = IERC20(token).balanceOf(address(this));
        tokenBalances[token] = nextBalance;
        return nextBalance;
    }

    // @dev records a token transfer into the contract
    // @param token the token to record the transfer for
    // @return the amount of tokens transferred in
    function _recordTransferIn(address token) internal returns (uint256) {
        uint256 prevBalance = tokenBalances[token];
        uint256 nextBalance = IERC20(token).balanceOf(address(this));
        tokenBalances[token] = nextBalance;

        return nextBalance - prevBalance;
    }

    // @dev update the internal balance after tokens have been transferred out
    // this is called from the Bank contract
    // @param token the token that was transferred out
    function _afterTransferOut(address token) internal override {
        tokenBalances[token] = IERC20(token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title Market
// @dev Struct for markets
//
// Markets support both spot and perp trading, they are created by specifying a
// long collateral token, short collateral token and index token.
//
// Examples:
//
// - ETH/USD market with long collateral as ETH, short collateral as a stablecoin, index token as ETH
// - BTC/USD market with long collateral as WBTC, short collateral as a stablecoin, index token as BTC
// - SOL/USD market with long collateral as ETH, short collateral as a stablecoin, index token as SOL
//
// Liquidity providers can deposit either the long or short collateral token or
// both to mint liquidity tokens.
//
// The long collateral token is used to back long positions, while the short
// collateral token is used to back short positions.
//
// Liquidity providers take on the profits and losses of traders for the market
// that they provide liquidity for.
//
// Having separate markets allows for risk isolation, liquidity providers are
// only exposed to the markets that they deposit into, this potentially allow
// for permissionless listings.
//
// Traders can use either the long or short token as collateral for the market.
library Market {
    // @param marketToken address of the market token for the market
    // @param indexToken address of the index token for the market
    // @param longToken address of the long token for the market
    // @param shortToken address of the short token for the market
    // @param data for any additional data
    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title MarketPoolInfo
library MarketPoolValueInfo {
    // @dev struct to avoid stack too deep errors for the getPoolValue call
    // @param value the pool value
    // @param longTokenAmount the amount of long token in the pool
    // @param shortTokenAmount the amount of short token in the pool
    // @param longTokenUsd the USD value of the long tokens in the pool
    // @param shortTokenUsd the USD value of the short tokens in the pool
    // @param totalBorrowingFees the total pending borrowing fees for the market
    // @param borrowingFeePoolFactor the pool factor for borrowing fees
    // @param impactPoolAmount the amount of tokens in the impact pool
    // @param longPnl the pending pnl of long positions
    // @param shortPnl the pending pnl of short positions
    // @param netPnl the net pnl of long and short positions
    struct Props {
        int256 poolValue;
        int256 longPnl;
        int256 shortPnl;
        int256 netPnl;

        uint256 longTokenAmount;
        uint256 shortTokenAmount;
        uint256 longTokenUsd;
        uint256 shortTokenUsd;

        uint256 totalBorrowingFees;
        uint256 borrowingFeePoolFactor;

        uint256 impactPoolAmount;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../bank/Bank.sol";

// @title MarketToken
// @dev The market token for a market, stores funds for the market and keeps track
// of the liquidity owners
contract MarketToken is ERC20, Bank {
    constructor(RoleStore _roleStore, DataStore _dataStore) ERC20("GMX Market", "GM") Bank(_roleStore, _dataStore) {
    }

    // @dev mint market tokens to an account
    // @param account the account to mint to
    // @param amount the amount of tokens to mint
    function mint(address account, uint256 amount) external onlyController {
        _mint(account, amount);
    }

    // @dev burn market tokens from an account
    // @param account the account to burn tokens for
    // @param amount the amount of tokens to burn
    function burn(address account, uint256 amount) external onlyController {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../event/EventEmitter.sol";
import "../event/EventUtils.sol";
import "../utils/Cast.sol";

import "./MarketPoolValueInfo.sol";

library MarketEventUtils {
    using EventUtils for EventUtils.AddressItems;
    using EventUtils for EventUtils.UintItems;
    using EventUtils for EventUtils.IntItems;
    using EventUtils for EventUtils.BoolItems;
    using EventUtils for EventUtils.Bytes32Items;
    using EventUtils for EventUtils.BytesItems;
    using EventUtils for EventUtils.StringItems;

    // this event is emitted before a deposit or withdrawal
    // it provides information of the pool state so that the amount
    // of market tokens minted or amount withdrawn from the pool can be checked
    function emitMarketPoolValueInfo(
        EventEmitter eventEmitter,
        bytes32 tradeKey,
        address market,
        MarketPoolValueInfo.Props memory props,
        uint256 marketTokensSupply
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.bytes32Items.initItems(1);
        eventData.bytes32Items.setItem(0, "tradeKey", tradeKey);

        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "market", market);

        eventData.intItems.initItems(4);
        eventData.intItems.setItem(0, "poolValue", props.poolValue);
        eventData.intItems.setItem(1, "longPnl", props.longPnl);
        eventData.intItems.setItem(2, "shortPnl", props.shortPnl);
        eventData.intItems.setItem(3, "netPnl", props.netPnl);

        eventData.uintItems.initItems(8);
        eventData.uintItems.setItem(0, "longTokenAmount", props.longTokenAmount);
        eventData.uintItems.setItem(1, "shortTokenAmount", props.shortTokenAmount);
        eventData.uintItems.setItem(2, "longTokenUsd", props.longTokenUsd);
        eventData.uintItems.setItem(3, "shortTokenUsd", props.shortTokenUsd);
        eventData.uintItems.setItem(4, "totalBorrowingFees", props.totalBorrowingFees);
        eventData.uintItems.setItem(5, "borrowingFeePoolFactor", props.borrowingFeePoolFactor);
        eventData.uintItems.setItem(6, "impactPoolAmount", props.impactPoolAmount);
        eventData.uintItems.setItem(7, "marketTokensSupply", marketTokensSupply);

        eventEmitter.emitEventLog1(
            "MarketPoolValueInfo",
            Cast.toBytes32(market),
            eventData
        );
    }

    // this event is emitted after a deposit or withdrawal
    // it provides information of the updated pool state
    // note that the pool state can change even without a deposit / withdrawal
    // e.g. borrowing fees can increase the pool's value with time, trader pnl
    // will change as index prices change
    function emitMarketPoolValueUpdated(
        EventEmitter eventEmitter,
        bytes32 actionType,
        bytes32 tradeKey,
        address market,
        MarketPoolValueInfo.Props memory props,
        uint256 marketTokensSupply
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.bytes32Items.initItems(2);
        eventData.bytes32Items.setItem(0, "actionType", actionType);
        eventData.bytes32Items.setItem(1, "tradeKey", tradeKey);

        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "market", market);

        eventData.intItems.initItems(4);
        eventData.intItems.setItem(0, "poolValue", props.poolValue);
        eventData.intItems.setItem(1, "longPnl", props.longPnl);
        eventData.intItems.setItem(2, "shortPnl", props.shortPnl);
        eventData.intItems.setItem(3, "netPnl", props.netPnl);

        eventData.uintItems.initItems(8);
        eventData.uintItems.setItem(0, "longTokenAmount", props.longTokenAmount);
        eventData.uintItems.setItem(1, "shortTokenAmount", props.shortTokenAmount);
        eventData.uintItems.setItem(2, "longTokenUsd", props.longTokenUsd);
        eventData.uintItems.setItem(3, "shortTokenUsd", props.shortTokenUsd);
        eventData.uintItems.setItem(4, "totalBorrowingFees", props.totalBorrowingFees);
        eventData.uintItems.setItem(5, "borrowingFeePoolFactor", props.borrowingFeePoolFactor);
        eventData.uintItems.setItem(6, "impactPoolAmount", props.impactPoolAmount);
        eventData.uintItems.setItem(7, "marketTokensSupply", marketTokensSupply);

        eventEmitter.emitEventLog1(
            "MarketPoolValueUpdated",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitPoolAmountUpdated(
        EventEmitter eventEmitter,
        address market,
        address token,
        int256 delta,
        uint256 nextValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(2);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "token", token);

        eventData.intItems.initItems(1);
        eventData.intItems.setItem(0, "delta", delta);

        eventData.uintItems.initItems(1);
        eventData.uintItems.setItem(0, "nextValue", nextValue);

        eventEmitter.emitEventLog1(
            "PoolAmountUpdated",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitSwapImpactPoolAmountUpdated(
        EventEmitter eventEmitter,
        address market,
        address token,
        int256 delta,
        uint256 nextValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(2);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "token", token);

        eventData.intItems.initItems(1);
        eventData.intItems.setItem(0, "delta", delta);

        eventData.uintItems.initItems(1);
        eventData.uintItems.setItem(0, "nextValue", nextValue);

        eventEmitter.emitEventLog1(
            "SwapImpactPoolAmountUpdated",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitPositionImpactPoolDistributed(
        EventEmitter eventEmitter,
        address market,
        uint256 distributionAmount,
        uint256 nextPositionImpactPoolAmount
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "market", market);

        eventData.uintItems.initItems(2);
        eventData.uintItems.setItem(0, "distributionAmount", distributionAmount);
        eventData.uintItems.setItem(1, "nextPositionImpactPoolAmount", nextPositionImpactPoolAmount);

        eventEmitter.emitEventLog1(
            "PositionImpactPoolDistributed",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitPositionImpactPoolAmountUpdated(
        EventEmitter eventEmitter,
        address market,
        int256 delta,
        uint256 nextValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "market", market);

        eventData.intItems.initItems(1);
        eventData.intItems.setItem(0, "delta", delta);

        eventData.uintItems.initItems(1);
        eventData.uintItems.setItem(0, "nextValue", nextValue);

        eventEmitter.emitEventLog1(
            "PositionImpactPoolAmountUpdated",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitOpenInterestUpdated(
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        int256 delta,
        uint256 nextValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(2);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "collateralToken", collateralToken);

        eventData.boolItems.initItems(1);
        eventData.boolItems.setItem(0, "isLong", isLong);

        eventData.intItems.initItems(1);
        eventData.intItems.setItem(0, "delta", delta);

        eventData.uintItems.initItems(1);
        eventData.uintItems.setItem(0, "nextValue", nextValue);

        eventEmitter.emitEventLog1(
            "OpenInterestUpdated",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitVirtualSwapInventoryUpdated(
        EventEmitter eventEmitter,
        address market,
        bool isLongToken,
        bytes32 virtualMarketId,
        int256 delta,
        uint256 nextValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "market", market);

        eventData.boolItems.initItems(1);
        eventData.boolItems.setItem(0, "isLongToken", isLongToken);

        eventData.bytes32Items.initItems(1);
        eventData.bytes32Items.setItem(0, "virtualMarketId", virtualMarketId);

        eventData.intItems.initItems(1);
        eventData.intItems.setItem(0, "delta", delta);

        eventData.uintItems.initItems(1);
        eventData.uintItems.setItem(0, "nextValue", nextValue);

        eventEmitter.emitEventLog2(
            "VirtualSwapInventoryUpdated",
            Cast.toBytes32(market),
            virtualMarketId,
            eventData
        );
    }

    function emitVirtualPositionInventoryUpdated(
        EventEmitter eventEmitter,
        address token,
        bytes32 virtualTokenId,
        int256 delta,
        int256 nextValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "token", token);

        eventData.bytes32Items.initItems(1);
        eventData.bytes32Items.setItem(0, "virtualTokenId", virtualTokenId);

        eventData.intItems.initItems(2);
        eventData.intItems.setItem(0, "delta", delta);
        eventData.intItems.setItem(1, "nextValue", nextValue);

        eventEmitter.emitEventLog2(
            "VirtualPositionInventoryUpdated",
            Cast.toBytes32(token),
            virtualTokenId,
            eventData
        );
    }

    function emitOpenInterestInTokensUpdated(
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        int256 delta,
        uint256 nextValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(2);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "collateralToken", collateralToken);

        eventData.boolItems.initItems(1);
        eventData.boolItems.setItem(0, "isLong", isLong);

        eventData.intItems.initItems(1);
        eventData.intItems.setItem(0, "delta", delta);

        eventData.uintItems.initItems(1);
        eventData.uintItems.setItem(0, "nextValue", nextValue);

        eventEmitter.emitEventLog1(
            "OpenInterestInTokensUpdated",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitCollateralSumUpdated(
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        int256 delta,
        uint256 nextValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(2);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "collateralToken", collateralToken);

        eventData.boolItems.initItems(1);
        eventData.boolItems.setItem(0, "isLong", isLong);

        eventData.intItems.initItems(1);
        eventData.intItems.setItem(0, "delta", delta);

        eventData.uintItems.initItems(1);
        eventData.uintItems.setItem(0, "nextValue", nextValue);

        eventEmitter.emitEventLog1(
            "CollateralSumUpdated",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitBorrowingFactorUpdated(
        EventEmitter eventEmitter,
        address market,
        bool isLong,
        uint256 delta,
        uint256 nextValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "market", market);

        eventData.boolItems.initItems(1);
        eventData.boolItems.setItem(0, "isLong", isLong);

        eventData.uintItems.initItems(2);
        eventData.uintItems.setItem(0, "delta", delta);
        eventData.uintItems.setItem(1, "nextValue", nextValue);

        eventEmitter.emitEventLog1(
            "CumulativeBorrowingFactorUpdated",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitFundingFeeAmountPerSizeUpdated(
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        uint256 delta,
        uint256 value
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(2);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "collateralToken", collateralToken);

        eventData.boolItems.initItems(1);
        eventData.boolItems.setItem(0, "isLong", isLong);

        eventData.uintItems.initItems(2);
        eventData.uintItems.setItem(0, "delta", delta);
        eventData.uintItems.setItem(1, "value", value);

        eventEmitter.emitEventLog1(
            "FundingFeeAmountPerSizeUpdated",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitClaimableFundingAmountPerSizeUpdated(
        EventEmitter eventEmitter,
        address market,
        address collateralToken,
        bool isLong,
        uint256 delta,
        uint256 value
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(2);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "collateralToken", collateralToken);

        eventData.boolItems.initItems(1);
        eventData.boolItems.setItem(0, "isLong", isLong);

        eventData.uintItems.initItems(2);
        eventData.uintItems.setItem(0, "delta", delta);
        eventData.uintItems.setItem(1, "value", value);

        eventEmitter.emitEventLog1(
            "ClaimableFundingAmountPerSizeUpdated",
            Cast.toBytes32(market),
            eventData
        );
    }

    function emitClaimableFundingUpdated(
        EventEmitter eventEmitter,
        address market,
        address token,
        address account,
        uint256 delta,
        uint256 nextValue,
        uint256 nextPoolValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(3);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "token", token);
        eventData.addressItems.setItem(2, "account", account);

        eventData.uintItems.initItems(3);
        eventData.uintItems.setItem(0, "delta", delta);
        eventData.uintItems.setItem(1, "nextValue", nextValue);
        eventData.uintItems.setItem(2, "nextPoolValue", nextPoolValue);

        eventEmitter.emitEventLog1(
            "ClaimableFundingUpdated",
            Cast.toBytes32(account),
            eventData
        );
    }

    function emitFundingFeesClaimed(
        EventEmitter eventEmitter,
        address market,
        address token,
        address account,
        address receiver,
        uint256 amount,
        uint256 nextPoolValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(4);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "token", token);
        eventData.addressItems.setItem(2, "account", account);
        eventData.addressItems.setItem(3, "receiver", receiver);

        eventData.uintItems.initItems(2);
        eventData.uintItems.setItem(0, "amount", amount);
        eventData.uintItems.setItem(1, "nextPoolValue", nextPoolValue);

        eventEmitter.emitEventLog1(
            "FundingFeesClaimed",
            Cast.toBytes32(account),
            eventData
        );
    }

    function emitClaimableFundingUpdated(
        EventEmitter eventEmitter,
        address market,
        address token,
        uint256 timeKey,
        address account,
        uint256 delta,
        uint256 nextValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(3);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "token", token);
        eventData.addressItems.setItem(2, "account", account);

        eventData.uintItems.initItems(3);
        eventData.uintItems.setItem(0, "timeKey", timeKey);
        eventData.uintItems.setItem(1, "delta", delta);
        eventData.uintItems.setItem(2, "nextValue", nextValue);

        eventEmitter.emitEventLog1(
            "ClaimableFundingUpdated",
            Cast.toBytes32(account),
            eventData
        );
    }

    function emitClaimableCollateralUpdated(
        EventEmitter eventEmitter,
        address market,
        address token,
        uint256 timeKey,
        address account,
        uint256 delta,
        uint256 nextValue,
        uint256 nextPoolValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(3);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "token", token);
        eventData.addressItems.setItem(2, "account", account);

        eventData.uintItems.initItems(4);
        eventData.uintItems.setItem(0, "timeKey", timeKey);
        eventData.uintItems.setItem(1, "delta", delta);
        eventData.uintItems.setItem(2, "nextValue", nextValue);
        eventData.uintItems.setItem(3, "nextPoolValue", nextPoolValue);

        eventEmitter.emitEventLog1(
            "ClaimableCollateralUpdated",
            Cast.toBytes32(account),
            eventData
        );
    }

    function emitCollateralClaimed(
        EventEmitter eventEmitter,
        address market,
        address token,
        uint256 timeKey,
        address account,
        address receiver,
        uint256 amount,
        uint256 nextPoolValue
    ) external {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(4);
        eventData.addressItems.setItem(0, "market", market);
        eventData.addressItems.setItem(1, "token", token);
        eventData.addressItems.setItem(2, "account", account);
        eventData.addressItems.setItem(3, "receiver", receiver);

        eventData.uintItems.initItems(3);
        eventData.uintItems.setItem(0, "timeKey", timeKey);
        eventData.uintItems.setItem(1, "amount", amount);
        eventData.uintItems.setItem(2, "nextPoolValue", nextPoolValue);

        eventEmitter.emitEventLog1(
            "CollateralClaimed",
            Cast.toBytes32(account),
            eventData
        );
    }

    function emitUiFeeFactorUpdated(
        EventEmitter eventEmitter,
        address account,
        uint256 uiFeeFactor
    ) external {

        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "account", account);

        eventData.uintItems.initItems(1);
        eventData.uintItems.setItem(0, "uiFeeFactor", uiFeeFactor);

        eventEmitter.emitEventLog1(
            "UiFeeFactorUpdated",
            Cast.toBytes32(account),
            eventData
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../data/Keys.sol";
import "../data/DataStore.sol";

import "./Market.sol";

/**
 * @title MarketStoreUtils
 * @dev Library for market storage functions
 */
library MarketStoreUtils {
    using Market for Market.Props;

    bytes32 public constant MARKET_SALT = keccak256(abi.encode("MARKET_SALT"));
    bytes32 public constant MARKET_KEY = keccak256(abi.encode("MARKET_KEY"));
    bytes32 public constant MARKET_TOKEN = keccak256(abi.encode("MARKET_TOKEN"));
    bytes32 public constant INDEX_TOKEN = keccak256(abi.encode("INDEX_TOKEN"));
    bytes32 public constant LONG_TOKEN = keccak256(abi.encode("LONG_TOKEN"));
    bytes32 public constant SHORT_TOKEN = keccak256(abi.encode("SHORT_TOKEN"));

    function get(DataStore dataStore, address key) public view returns (Market.Props memory) {
        Market.Props memory market;
        if (!dataStore.containsAddress(Keys.MARKET_LIST, key)) {
            return market;
        }

        market.marketToken = dataStore.getAddress(
            keccak256(abi.encode(key, MARKET_TOKEN))
        );

        market.indexToken = dataStore.getAddress(
            keccak256(abi.encode(key, INDEX_TOKEN))
        );

        market.longToken = dataStore.getAddress(
            keccak256(abi.encode(key, LONG_TOKEN))
        );

        market.shortToken = dataStore.getAddress(
            keccak256(abi.encode(key, SHORT_TOKEN))
        );

        return market;
    }

    function getBySalt(DataStore dataStore, bytes32 salt) external view returns (Market.Props memory) {
        address key = dataStore.getAddress(getMarketSaltHash(salt));
        return get(dataStore, key);
    }

    function set(DataStore dataStore, address key, bytes32 salt, Market.Props memory market) external {
        dataStore.addAddress(
            Keys.MARKET_LIST,
            key
        );

        // the salt is based on the market props while the key gives the market's address
        // use the salt to store a reference to the key to allow the key to be retrieved
        // using just the salt value
        dataStore.setAddress(
            getMarketSaltHash(salt),
            key
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, MARKET_TOKEN)),
            market.marketToken
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, INDEX_TOKEN)),
            market.indexToken
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, LONG_TOKEN)),
            market.longToken
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, SHORT_TOKEN)),
            market.shortToken
        );
    }

    function remove(DataStore dataStore, address key) external {
        if (!dataStore.containsAddress(Keys.MARKET_LIST, key)) {
            revert Errors.MarketNotFound(key);
        }

        dataStore.removeAddress(
            Keys.MARKET_LIST,
            key
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, MARKET_TOKEN))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, INDEX_TOKEN))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, LONG_TOKEN))
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, SHORT_TOKEN))
        );
    }

    function getMarketSaltHash(bytes32 salt) internal pure returns (bytes32) {
        return keccak256(abi.encode(MARKET_SALT, salt));
    }

    function getMarketCount(DataStore dataStore) internal view returns (uint256) {
        return dataStore.getAddressCount(Keys.MARKET_LIST);
    }

    function getMarketKeys(DataStore dataStore, uint256 start, uint256 end) internal view returns (address[] memory) {
        return dataStore.getAddressValuesAt(Keys.MARKET_LIST, start, end);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title Position
// @dev Stuct for positions
//
// borrowing fees for position require only a borrowingFactor to track
// an example on how this works is if the global cumulativeBorrowingFactor is 10020%
// a position would be opened with borrowingFactor as 10020%
// after some time, if the cumulativeBorrowingFactor is updated to 10025% the position would
// owe 5% of the position size as borrowing fees
// the total pending borrowing fees of all positions is factored into the calculation of the pool value for LPs
// when a position is increased or decreased, the pending borrowing fees for the position is deducted from the position's
// collateral and transferred into the LP pool
//
// the same borrowing fee factor tracking cannot be applied for funding fees as those calculations consider pending funding fees
// based on the fiat value of the position sizes
//
// for example, if the price of the longToken is $2000 and a long position owes $200 in funding fees, the opposing short position
// claims the funding fees of 0.1 longToken ($200), if the price of the longToken changes to $4000 later, the long position would
// only owe 0.05 longToken ($200)
// this would result in differences between the amounts deducted and amounts paid out, for this reason, the actual token amounts
// to be deducted and to be paid out need to be tracked instead
//
// for funding fees, there are four values to consider:
// 1. long positions with market.longToken as collateral
// 2. long positions with market.shortToken as collateral
// 3. short positions with market.longToken as collateral
// 4. short positions with market.shortToken as collateral
library Position {
    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the position's account
    // @param market the position's market
    // @param collateralToken the position's collateralToken
    struct Addresses {
        address account;
        address market;
        address collateralToken;
    }

    // @param sizeInUsd the position's size in USD
    // @param sizeInTokens the position's size in tokens
    // @param collateralAmount the amount of collateralToken for collateral
    // @param borrowingFactor the position's borrowing factor
    // @param fundingFeeAmountPerSize the position's funding fee per size
    // @param longTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
    // for the market.longToken
    // @param shortTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
    // for the market.shortToken
    // @param increasedAtBlock the block at which the position was last increased
    // @param decreasedAtBlock the block at which the position was last decreased
    struct Numbers {
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        uint256 fundingFeeAmountPerSize;
        uint256 longTokenClaimableFundingAmountPerSize;
        uint256 shortTokenClaimableFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
    }

    // @param isLong whether the position is a long or short
    struct Flags {
        bool isLong;
    }

    function account(Props memory props) internal pure returns (address) {
        return props.addresses.account;
    }

    function setAccount(Props memory props, address value) internal pure {
        props.addresses.account = value;
    }

    function market(Props memory props) internal pure returns (address) {
        return props.addresses.market;
    }

    function setMarket(Props memory props, address value) internal pure {
        props.addresses.market = value;
    }

    function collateralToken(Props memory props) internal pure returns (address) {
        return props.addresses.collateralToken;
    }

    function setCollateralToken(Props memory props, address value) internal pure {
        props.addresses.collateralToken = value;
    }

    function sizeInUsd(Props memory props) internal pure returns (uint256) {
        return props.numbers.sizeInUsd;
    }

    function setSizeInUsd(Props memory props, uint256 value) internal pure {
        props.numbers.sizeInUsd = value;
    }

    function sizeInTokens(Props memory props) internal pure returns (uint256) {
        return props.numbers.sizeInTokens;
    }

    function setSizeInTokens(Props memory props, uint256 value) internal pure {
        props.numbers.sizeInTokens = value;
    }

    function collateralAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.collateralAmount;
    }

    function setCollateralAmount(Props memory props, uint256 value) internal pure {
        props.numbers.collateralAmount = value;
    }

    function borrowingFactor(Props memory props) internal pure returns (uint256) {
        return props.numbers.borrowingFactor;
    }

    function setBorrowingFactor(Props memory props, uint256 value) internal pure {
        props.numbers.borrowingFactor = value;
    }

    function fundingFeeAmountPerSize(Props memory props) internal pure returns (uint256) {
        return props.numbers.fundingFeeAmountPerSize;
    }

    function setFundingFeeAmountPerSize(Props memory props, uint256 value) internal pure {
        props.numbers.fundingFeeAmountPerSize = value;
    }

    function longTokenClaimableFundingAmountPerSize(Props memory props) internal pure returns (uint256) {
        return props.numbers.longTokenClaimableFundingAmountPerSize;
    }

    function setLongTokenClaimableFundingAmountPerSize(Props memory props, uint256 value) internal pure {
        props.numbers.longTokenClaimableFundingAmountPerSize = value;
    }

    function shortTokenClaimableFundingAmountPerSize(Props memory props) internal pure returns (uint256) {
        return props.numbers.shortTokenClaimableFundingAmountPerSize;
    }

    function setShortTokenClaimableFundingAmountPerSize(Props memory props, uint256 value) internal pure {
        props.numbers.shortTokenClaimableFundingAmountPerSize = value;
    }

    function increasedAtBlock(Props memory props) internal pure returns (uint256) {
        return props.numbers.increasedAtBlock;
    }

    function setIncreasedAtBlock(Props memory props, uint256 value) internal pure {
        props.numbers.increasedAtBlock = value;
    }

    function decreasedAtBlock(Props memory props) internal pure returns (uint256) {
        return props.numbers.decreasedAtBlock;
    }

    function setDecreasedAtBlock(Props memory props, uint256 value) internal pure {
        props.numbers.decreasedAtBlock = value;
    }

    function isLong(Props memory props) internal pure returns (bool) {
        return props.flags.isLong;
    }

    function setIsLong(Props memory props, bool value) internal pure {
        props.flags.isLong = value;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../chain/Chain.sol";

// @title Order
// @dev Struct for orders
library Order {
    using Order for Props;

    enum OrderType {
        // @dev MarketSwap: swap token A to token B at the current market price
        // the order will be cancelled if the minOutputAmount cannot be fulfilled
        MarketSwap,
        // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // @dev MarketIncrease: increase position at the current market price
        // the order will be cancelled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // @dev MarketDecrease: decrease position at the current market price
        // the order will be cancelled if the position cannot be decreased at the acceptablePrice
        MarketDecrease,
        // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitDecrease,
        // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        StopLossDecrease,
        // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
        Liquidation
    }

    // to help further differentiate orders
    enum SecondaryOrderType {
        None,
        Adl
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the account of the order
    // @param receiver the receiver for any token transfers
    // this field is meant to allow the output of an order to be
    // received by an address that is different from the creator of the
    // order whether this is for swaps or whether the account is the owner
    // of a position
    // for funding fees and claimable collateral, the funds are still
    // credited to the owner of the position indicated by order.account
    // @param callbackContract the contract to call for callbacks
    // @param uiFeeReceiver the ui fee receiver
    // @param market the trading market
    // @param initialCollateralToken for increase orders, initialCollateralToken
    // is the token sent in by the user, the token will be swapped through the
    // specified swapPath, before being deposited into the position as collateral
    // for decrease orders, initialCollateralToken is the collateral token of the position
    // withdrawn collateral from the decrease of the position will be swapped
    // through the specified swapPath
    // for swaps, initialCollateralToken is the initial token sent for the swap
    // @param swapPath an array of market addresses to swap through
    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd the requested change in position size
    // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
    // is the amount of the initialCollateralToken sent in by the user
    // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
    // collateralToken to withdraw
    // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
    // in for the swap
    // @param orderType the order type
    // @param triggerPrice the trigger price for non-market orders
    // @param acceptablePrice the acceptable execution price for increase / decrease orders
    // @param executionFee the execution fee for keepers
    // @param callbackGasLimit the gas limit for the callbackContract
    // @param minOutputAmount the minimum output amount for decrease orders and swaps
    // note that for decrease orders, multiple tokens could be received, for this reason, the
    // minOutputAmount value is treated as a USD value for validation in decrease orders
    // @param updatedAtBlock the block at which the order was last updated
    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    // @param isLong whether the order is for a long or short
    // @param shouldUnwrapNativeToken whether to unwrap native tokens before
    // transferring to the user
    // @param isFrozen whether the order is frozen
    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }

    // @dev the order account
    // @param props Props
    // @return the order account
    function account(Props memory props) internal pure returns (address) {
        return props.addresses.account;
    }

    // @dev set the order account
    // @param props Props
    // @param value the value to set to
    function setAccount(Props memory props, address value) internal pure {
        props.addresses.account = value;
    }

    // @dev the order receiver
    // @param props Props
    // @return the order receiver
    function receiver(Props memory props) internal pure returns (address) {
        return props.addresses.receiver;
    }

    // @dev set the order receiver
    // @param props Props
    // @param value the value to set to
    function setReceiver(Props memory props, address value) internal pure {
        props.addresses.receiver = value;
    }

    // @dev the order callbackContract
    // @param props Props
    // @return the order callbackContract
    function callbackContract(Props memory props) internal pure returns (address) {
        return props.addresses.callbackContract;
    }

    // @dev set the order callbackContract
    // @param props Props
    // @param value the value to set to
    function setCallbackContract(Props memory props, address value) internal pure {
        props.addresses.callbackContract = value;
    }

    // @dev the order market
    // @param props Props
    // @return the order market
    function market(Props memory props) internal pure returns (address) {
        return props.addresses.market;
    }

    // @dev set the order market
    // @param props Props
    // @param value the value to set to
    function setMarket(Props memory props, address value) internal pure {
        props.addresses.market = value;
    }

    // @dev the order initialCollateralToken
    // @param props Props
    // @return the order initialCollateralToken
    function initialCollateralToken(Props memory props) internal pure returns (address) {
        return props.addresses.initialCollateralToken;
    }

    // @dev set the order initialCollateralToken
    // @param props Props
    // @param value the value to set to
    function setInitialCollateralToken(Props memory props, address value) internal pure {
        props.addresses.initialCollateralToken = value;
    }

    // @dev the order uiFeeReceiver
    // @param props Props
    // @return the order uiFeeReceiver
    function uiFeeReceiver(Props memory props) internal pure returns (address) {
        return props.addresses.uiFeeReceiver;
    }

    // @dev set the order uiFeeReceiver
    // @param props Props
    // @param value the value to set to
    function setUiFeeReceiver(Props memory props, address value) internal pure {
        props.addresses.uiFeeReceiver = value;
    }

    // @dev the order swapPath
    // @param props Props
    // @return the order swapPath
    function swapPath(Props memory props) internal pure returns (address[] memory) {
        return props.addresses.swapPath;
    }

    // @dev set the order swapPath
    // @param props Props
    // @param value the value to set to
    function setSwapPath(Props memory props, address[] memory value) internal pure {
        props.addresses.swapPath = value;
    }

    // @dev the order type
    // @param props Props
    // @return the order type
    function orderType(Props memory props) internal pure returns (OrderType) {
        return props.numbers.orderType;
    }

    // @dev set the order type
    // @param props Props
    // @param value the value to set to
    function setOrderType(Props memory props, OrderType value) internal pure {
        props.numbers.orderType = value;
    }

    function decreasePositionSwapType(Props memory props) internal pure returns (DecreasePositionSwapType) {
        return props.numbers.decreasePositionSwapType;
    }

    function setDecreasePositionSwapType(Props memory props, DecreasePositionSwapType value) internal pure {
        props.numbers.decreasePositionSwapType = value;
    }

    // @dev the order sizeDeltaUsd
    // @param props Props
    // @return the order sizeDeltaUsd
    function sizeDeltaUsd(Props memory props) internal pure returns (uint256) {
        return props.numbers.sizeDeltaUsd;
    }

    // @dev set the order sizeDeltaUsd
    // @param props Props
    // @param value the value to set to
    function setSizeDeltaUsd(Props memory props, uint256 value) internal pure {
        props.numbers.sizeDeltaUsd = value;
    }

    // @dev the order initialCollateralDeltaAmount
    // @param props Props
    // @return the order initialCollateralDeltaAmount
    function initialCollateralDeltaAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.initialCollateralDeltaAmount;
    }

    // @dev set the order initialCollateralDeltaAmount
    // @param props Props
    // @param value the value to set to
    function setInitialCollateralDeltaAmount(Props memory props, uint256 value) internal pure {
        props.numbers.initialCollateralDeltaAmount = value;
    }

    // @dev the order triggerPrice
    // @param props Props
    // @return the order triggerPrice
    function triggerPrice(Props memory props) internal pure returns (uint256) {
        return props.numbers.triggerPrice;
    }

    // @dev set the order triggerPrice
    // @param props Props
    // @param value the value to set to
    function setTriggerPrice(Props memory props, uint256 value) internal pure {
        props.numbers.triggerPrice = value;
    }

    // @dev the order acceptablePrice
    // @param props Props
    // @return the order acceptablePrice
    function acceptablePrice(Props memory props) internal pure returns (uint256) {
        return props.numbers.acceptablePrice;
    }

    // @dev set the order acceptablePrice
    // @param props Props
    // @param value the value to set to
    function setAcceptablePrice(Props memory props, uint256 value) internal pure {
        props.numbers.acceptablePrice = value;
    }

    // @dev set the order executionFee
    // @param props Props
    // @param value the value to set to
    function setExecutionFee(Props memory props, uint256 value) internal pure {
        props.numbers.executionFee = value;
    }

    // @dev the order executionFee
    // @param props Props
    // @return the order executionFee
    function executionFee(Props memory props) internal pure returns (uint256) {
        return props.numbers.executionFee;
    }

    // @dev the order callbackGasLimit
    // @param props Props
    // @return the order callbackGasLimit
    function callbackGasLimit(Props memory props) internal pure returns (uint256) {
        return props.numbers.callbackGasLimit;
    }

    // @dev set the order callbackGasLimit
    // @param props Props
    // @param value the value to set to
    function setCallbackGasLimit(Props memory props, uint256 value) internal pure {
        props.numbers.callbackGasLimit = value;
    }

    // @dev the order minOutputAmount
    // @param props Props
    // @return the order minOutputAmount
    function minOutputAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.minOutputAmount;
    }

    // @dev set the order minOutputAmount
    // @param props Props
    // @param value the value to set to
    function setMinOutputAmount(Props memory props, uint256 value) internal pure {
        props.numbers.minOutputAmount = value;
    }

    // @dev the order updatedAtBlock
    // @param props Props
    // @return the order updatedAtBlock
    function updatedAtBlock(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtBlock;
    }

    // @dev set the order updatedAtBlock
    // @param props Props
    // @param value the value to set to
    function setUpdatedAtBlock(Props memory props, uint256 value) internal pure {
        props.numbers.updatedAtBlock = value;
    }

    // @dev whether the order is for a long or short
    // @param props Props
    // @return whether the order is for a long or short
    function isLong(Props memory props) internal pure returns (bool) {
        return props.flags.isLong;
    }

    // @dev set whether the order is for a long or short
    // @param props Props
    // @param value the value to set to
    function setIsLong(Props memory props, bool value) internal pure {
        props.flags.isLong = value;
    }

    // @dev whether to unwrap the native token before transfers to the user
    // @param props Props
    // @return whether to unwrap the native token before transfers to the user
    function shouldUnwrapNativeToken(Props memory props) internal pure returns (bool) {
        return props.flags.shouldUnwrapNativeToken;
    }

    // @dev set whether the native token should be unwrapped before being
    // transferred to the receiver
    // @param props Props
    // @param value the value to set to
    function setShouldUnwrapNativeToken(Props memory props, bool value) internal pure {
        props.flags.shouldUnwrapNativeToken = value;
    }

    // @dev whether the order is frozen
    // @param props Props
    // @return whether the order is frozen
    function isFrozen(Props memory props) internal pure returns (bool) {
        return props.flags.isFrozen;
    }

    // @dev set whether the order is frozen
    // transferred to the receiver
    // @param props Props
    // @param value the value to set to
    function setIsFrozen(Props memory props, bool value) internal pure {
        props.flags.isFrozen = value;
    }

    // @dev set the order.updatedAtBlock to the current block number
    // @param props Props
    function touch(Props memory props) internal view {
        props.setUpdatedAtBlock(Chain.currentBlockNumber());
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../role/RoleModule.sol";

import "./OracleStore.sol";
import "./OracleUtils.sol";
import "./IPriceFeed.sol";
import "./IRealtimeFeedVerifier.sol";
import "../price/Price.sol";

import "../chain/Chain.sol";
import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../event/EventEmitter.sol";
import "../event/EventUtils.sol";

import "../utils/Bits.sol";
import "../utils/Array.sol";
import "../utils/Precision.sol";
import "../utils/Cast.sol";
import "../utils/Uint256Mask.sol";

// @title Oracle
// @dev Contract to validate and store signed values
// Some calculations e.g. calculating the size in tokens for a position
// may not work with zero / negative prices
// as a result, zero / negative prices are considered empty / invalid
// A market may need to be manually settled in this case
contract Oracle is RoleModule {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;
    using Price for Price.Props;
    using Uint256Mask for Uint256Mask.Mask;

    using EventUtils for EventUtils.AddressItems;
    using EventUtils for EventUtils.UintItems;
    using EventUtils for EventUtils.IntItems;
    using EventUtils for EventUtils.BoolItems;
    using EventUtils for EventUtils.Bytes32Items;
    using EventUtils for EventUtils.BytesItems;
    using EventUtils for EventUtils.StringItems;

    struct ValidatedPrice {
        address token;
        uint256 min;
        uint256 max;
        uint256 timestamp;
        uint256 minBlockNumber;
        uint256 maxBlockNumber;
    }

    // @dev SetPricesCache struct used in setPrices to avoid stack too deep errors
    struct SetPricesCache {
        OracleUtils.ReportInfo info;
        uint256 minBlockConfirmations;
        uint256 maxPriceAge;
        uint256 maxRefPriceDeviationFactor;
        uint256 prevMinOracleBlockNumber;
        ValidatedPrice[] validatedPrices;
    }

    struct SetPricesInnerCache {
        bytes32 feedId;
        uint256 priceIndex;
        uint256 signatureIndex;
        uint256 minPriceIndex;
        uint256 maxPriceIndex;
        uint256[] minPrices;
        uint256[] maxPrices;
        Uint256Mask.Mask minPriceIndexMask;
        Uint256Mask.Mask maxPriceIndexMask;
    }

    uint256 public constant SIGNER_INDEX_LENGTH = 16;
    // subtract 1 as the first slot is used to store number of signers
    uint256 public constant MAX_SIGNERS = 256 / SIGNER_INDEX_LENGTH - 1;
    // signer indexes are recorded in a signerIndexFlags uint256 value to check for uniqueness
    uint256 public constant MAX_SIGNER_INDEX = 256;

    OracleStore public immutable oracleStore;
    IRealtimeFeedVerifier public immutable realtimeFeedVerifier;

    // tokensWithPrices stores the tokens with prices that have been set
    // this is used in clearAllPrices to help ensure that all token prices
    // set in setPrices are cleared after use
    EnumerableSet.AddressSet internal tokensWithPrices;
    mapping(address => Price.Props) public primaryPrices;

    constructor(
        RoleStore _roleStore,
        OracleStore _oracleStore,
        IRealtimeFeedVerifier _realtimeFeedVerifier
    ) RoleModule(_roleStore) {
        oracleStore = _oracleStore;
        realtimeFeedVerifier = _realtimeFeedVerifier;
    }

    // @dev validate and store signed prices
    //
    // The setPrices function is used to set the prices of tokens in the Oracle contract.
    // It accepts an array of tokens and a signerInfo parameter. The signerInfo parameter
    // contains information about the signers that have signed the transaction to set the prices.
    // The first 16 bits of the signerInfo parameter contain the number of signers, and the following
    // bits contain the index of each signer in the oracleStore. The function checks that the number
    // of signers is greater than or equal to the minimum number of signers required, and that
    // the signer indices are unique and within the maximum signer index. The function then calls
    // _setPrices and _setPricesFromPriceFeeds to set the prices of the tokens.
    //
    // Oracle prices are signed as a value together with a precision, this allows
    // prices to be compacted as uint32 values.
    //
    // The signed prices represent the price of one unit of the token using a value
    // with 30 decimals of precision.
    //
    // Representing the prices in this way allows for conversions between token amounts
    // and fiat values to be simplified, e.g. to calculate the fiat value of a given
    // number of tokens the calculation would just be: `token amount * oracle price`,
    // to calculate the token amount for a fiat value it would be: `fiat value / oracle price`.
    //
    // The trade-off of this simplicity in calculation is that tokens with a small USD
    // price and a lot of decimals may have precision issues it is also possible that
    // a token's price changes significantly and results in requiring higher precision.
    //
    // ## Example 1
    //
    // The price of ETH is 5000, and ETH has 18 decimals.
    //
    // The price of one unit of ETH is `5000 / (10 ^ 18), 5 * (10 ^ -15)`.
    //
    // To handle the decimals, multiply the value by `(10 ^ 30)`.
    //
    // Price would be stored as `5000 / (10 ^ 18) * (10 ^ 30) => 5000 * (10 ^ 12)`.
    //
    // For gas optimization, these prices are sent to the oracle in the form of a uint8
    // decimal multiplier value and uint32 price value.
    //
    // If the decimal multiplier value is set to 8, the uint32 value would be `5000 * (10 ^ 12) / (10 ^ 8) => 5000 * (10 ^ 4)`.
    //
    // With this config, ETH prices can have a maximum value of `(2 ^ 32) / (10 ^ 4) => 4,294,967,296 / (10 ^ 4) => 429,496.7296` with 4 decimals of precision.
    //
    // ## Example 2
    //
    // The price of BTC is 60,000, and BTC has 8 decimals.
    //
    // The price of one unit of BTC is `60,000 / (10 ^ 8), 6 * (10 ^ -4)`.
    //
    // Price would be stored as `60,000 / (10 ^ 8) * (10 ^ 30) => 6 * (10 ^ 26) => 60,000 * (10 ^ 22)`.
    //
    // BTC prices maximum value: `(2 ^ 32) / (10 ^ 2) => 4,294,967,296 / (10 ^ 2) => 42,949,672.96`.
    //
    // Decimals of precision: 2.
    //
    // ## Example 3
    //
    // The price of USDC is 1, and USDC has 6 decimals.
    //
    // The price of one unit of USDC is `1 / (10 ^ 6), 1 * (10 ^ -6)`.
    //
    // Price would be stored as `1 / (10 ^ 6) * (10 ^ 30) => 1 * (10 ^ 24)`.
    //
    // USDC prices maximum value: `(2 ^ 64) / (10 ^ 6) => 4,294,967,296 / (10 ^ 6) => 4294.967296`.
    //
    // Decimals of precision: 6.
    //
    // ## Example 4
    //
    // The price of DG is 0.00000001, and DG has 18 decimals.
    //
    // The price of one unit of DG is `0.00000001 / (10 ^ 18), 1 * (10 ^ -26)`.
    //
    // Price would be stored as `1 * (10 ^ -26) * (10 ^ 30) => 1 * (10 ^ 3)`.
    //
    // DG prices maximum value: `(2 ^ 64) / (10 ^ 11) => 4,294,967,296 / (10 ^ 11) => 0.04294967296`.
    //
    // Decimals of precision: 11.
    //
    // ## Decimal Multiplier
    //
    // The formula to calculate what the decimal multiplier value should be set to:
    //
    // Decimals: 30 - (token decimals) - (number of decimals desired for precision)
    //
    // - ETH: 30 - 18 - 4 => 8
    // - BTC: 30 - 8 - 2 => 20
    // - USDC: 30 - 6 - 6 => 18
    // - DG: 30 - 18 - 11 => 1
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param params OracleUtils.SetPricesParams
    function setPrices(
        DataStore dataStore,
        EventEmitter eventEmitter,
        OracleUtils.SetPricesParams memory params
    ) external onlyController {
        if (tokensWithPrices.length() != 0) {
            revert Errors.NonEmptyTokensWithPrices(tokensWithPrices.length());
        }

        _setPricesFromPriceFeeds(dataStore, eventEmitter, params.priceFeedTokens);

        OracleUtils.RealtimeFeedReport[] memory reports = _setPricesFromRealtimeFeeds(dataStore, eventEmitter, params);

        ValidatedPrice[] memory validatedPrices = _setPrices(
            dataStore,
            eventEmitter,
            params
        );

        _validateBlockRanges(reports, validatedPrices);
    }

    // @dev set the primary price
    // @param token the token to set the price for
    // @param price the price value to set to
    function setPrimaryPrice(address token, Price.Props memory price) external onlyController {
        _setPrimaryPrice(token, price);
    }

    // @dev clear all prices
    function clearAllPrices() external onlyController {
        uint256 length = tokensWithPrices.length();
        for (uint256 i; i < length; i++) {
            address token = tokensWithPrices.at(0);
            _removePrimaryPrice(token);
        }
    }

    // @dev get the length of tokensWithPrices
    // @return the length of tokensWithPrices
    function getTokensWithPricesCount() external view returns (uint256) {
        return tokensWithPrices.length();
    }

    // @dev get the tokens of tokensWithPrices for the specified indexes
    // @param start the start index, the value for this index will be included
    // @param end the end index, the value for this index will not be included
    // @return the tokens of tokensWithPrices for the specified indexes
    function getTokensWithPrices(uint256 start, uint256 end) external view returns (address[] memory) {
        return tokensWithPrices.valuesAt(start, end);
    }

    // @dev get the primary price of a token
    // @param token the token to get the price for
    // @return the primary price of a token
    function getPrimaryPrice(address token) external view returns (Price.Props memory) {
        if (token == address(0)) { return Price.Props(0, 0); }

        Price.Props memory price = primaryPrices[token];
        if (price.isEmpty()) {
            revert Errors.EmptyPrimaryPrice(token);
        }

        return price;
    }

    // @dev get the stable price of a token
    // @param dataStore DataStore
    // @param token the token to get the price for
    // @return the stable price of the token
    function getStablePrice(DataStore dataStore, address token) public view returns (uint256) {
        return dataStore.getUint(Keys.stablePriceKey(token));
    }

    // @dev get the multiplier value to convert the external price feed price to the price of 1 unit of the token
    // represented with 30 decimals
    // for example, if USDC has 6 decimals and a price of 1 USD, one unit of USDC would have a price of
    // 1 / (10 ^ 6) * (10 ^ 30) => 1 * (10 ^ 24)
    // if the external price feed has 8 decimals, the price feed price would be 1 * (10 ^ 8)
    // in this case the priceFeedMultiplier should be 10 ^ 46
    // the conversion of the price feed price would be 1 * (10 ^ 8) * (10 ^ 46) / (10 ^ 30) => 1 * (10 ^ 24)
    // formula for decimals for price feed multiplier: 60 - (external price feed decimals) - (token decimals)
    //
    // @param dataStore DataStore
    // @param token the token to get the price feed multiplier for
    // @return the price feed multipler
    function getPriceFeedMultiplier(DataStore dataStore, address token) public view returns (uint256) {
        uint256 multiplier = dataStore.getUint(Keys.priceFeedMultiplierKey(token));

        if (multiplier == 0) {
            revert Errors.EmptyPriceFeedMultiplier(token);
        }

        return multiplier;
    }

    function getRealtimeFeedMultiplier(DataStore dataStore, address token) public view returns (uint256) {
        uint256 multiplier = dataStore.getUint(Keys.realtimeFeedMultiplierKey(token));

        if (multiplier == 0) {
            revert Errors.EmptyRealtimeFeedMultiplier(token);
        }

        return multiplier;
    }

    function validatePrices(
        DataStore dataStore,
        OracleUtils.SetPricesParams memory params
    ) external view returns (ValidatedPrice[] memory) {
        return _validatePrices(dataStore, params);
    }

    function validateRealtimeFeeds(
        DataStore dataStore,
        address[] memory realtimeFeedTokens,
        bytes[] memory realtimeFeedData
    ) external onlyController returns (OracleUtils.RealtimeFeedReport[] memory) {
        return _validateRealtimeFeeds(dataStore, realtimeFeedTokens, realtimeFeedData);
    }

    // @dev validate and set prices
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param params OracleUtils.SetPricesParams
    function _setPrices(
        DataStore dataStore,
        EventEmitter eventEmitter,
        OracleUtils.SetPricesParams memory params
    ) internal returns (ValidatedPrice[] memory) {
        ValidatedPrice[] memory validatedPrices = _validatePrices(dataStore, params);

        for (uint256 i; i < validatedPrices.length; i++) {
            ValidatedPrice memory validatedPrice = validatedPrices[i];

            emitOraclePriceUpdated(
                eventEmitter,
                validatedPrice.token,
                validatedPrice.min,
                validatedPrice.max,
                validatedPrice.timestamp,
                OracleUtils.PriceSourceType.InternalFeed
            );

            _setPrimaryPrice(validatedPrice.token, Price.Props(
                validatedPrice.min,
                validatedPrice.max
            ));
        }

        return validatedPrices;
    }

    function _validatePrices(
        DataStore dataStore,
        OracleUtils.SetPricesParams memory params
    ) internal view returns (ValidatedPrice[] memory) {
        // it is possible for transactions to be executed using just params.priceFeedTokens
        // or just params.realtimeFeedTokens
        // in this case if params.tokens is empty, the function can return
        if (params.tokens.length == 0) {
            return new ValidatedPrice[](0);
        }

        address[] memory signers = _getSigners(dataStore, params);

        SetPricesCache memory cache;

        cache.validatedPrices = new ValidatedPrice[](params.tokens.length);
        cache.minBlockConfirmations = dataStore.getUint(Keys.MIN_ORACLE_BLOCK_CONFIRMATIONS);
        cache.maxPriceAge = dataStore.getUint(Keys.MAX_ORACLE_PRICE_AGE);
        cache.maxRefPriceDeviationFactor = dataStore.getUint(Keys.MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR);

        for (uint256 i; i < params.tokens.length; i++) {
            OracleUtils.ReportInfo memory reportInfo;
            SetPricesInnerCache memory innerCache;

            reportInfo.minOracleBlockNumber = OracleUtils.getUncompactedOracleBlockNumber(params.compactedMinOracleBlockNumbers, i);
            reportInfo.maxOracleBlockNumber = OracleUtils.getUncompactedOracleBlockNumber(params.compactedMaxOracleBlockNumbers, i);

            if (reportInfo.minOracleBlockNumber > reportInfo.maxOracleBlockNumber) {
                revert Errors.InvalidMinMaxBlockNumber(reportInfo.minOracleBlockNumber, reportInfo.maxOracleBlockNumber);
            }

            reportInfo.oracleTimestamp = OracleUtils.getUncompactedOracleTimestamp(params.compactedOracleTimestamps, i);

            if (reportInfo.maxOracleBlockNumber >= Chain.currentBlockNumber()) {
                revert Errors.InvalidBlockNumber(reportInfo.maxOracleBlockNumber, Chain.currentBlockNumber());
            }

            if (reportInfo.oracleTimestamp + cache.maxPriceAge < Chain.currentTimestamp()) {
                revert Errors.MaxPriceAgeExceeded(reportInfo.oracleTimestamp, Chain.currentTimestamp());
            }

            // block numbers must be in ascending order
            if (reportInfo.minOracleBlockNumber < cache.prevMinOracleBlockNumber) {
                revert Errors.BlockNumbersNotSorted(reportInfo.minOracleBlockNumber, cache.prevMinOracleBlockNumber);
            }
            cache.prevMinOracleBlockNumber = reportInfo.minOracleBlockNumber;

            if (Chain.currentBlockNumber() - reportInfo.maxOracleBlockNumber <= cache.minBlockConfirmations) {
                reportInfo.blockHash = Chain.getBlockHash(reportInfo.maxOracleBlockNumber);
            }

            reportInfo.token = params.tokens[i];

            // only allow internal feeds if the token does not have a realtime feed id
            if (dataStore.getBool(Keys.IN_STRICT_PRICE_FEED_MODE)) {
                innerCache.feedId = dataStore.getBytes32(Keys.realtimeFeedIdKey(reportInfo.token));
                if (innerCache.feedId != bytes32(0)) {
                    revert Errors.HasRealtimeFeedId(reportInfo.token, innerCache.feedId);
                }
            }

            reportInfo.precision = 10 ** OracleUtils.getUncompactedDecimal(params.compactedDecimals, i);
            reportInfo.tokenOracleType = dataStore.getBytes32(Keys.oracleTypeKey(reportInfo.token));

            innerCache.minPrices = new uint256[](signers.length);
            innerCache.maxPrices = new uint256[](signers.length);

            for (uint256 j = 0; j < signers.length; j++) {
                innerCache.priceIndex = i * signers.length + j;
                innerCache.minPrices[j] = OracleUtils.getUncompactedPrice(params.compactedMinPrices, innerCache.priceIndex);
                innerCache.maxPrices[j] = OracleUtils.getUncompactedPrice(params.compactedMaxPrices, innerCache.priceIndex);

                if (j == 0) { continue; }

                // validate that minPrices are sorted in ascending order
                if (innerCache.minPrices[j - 1] > innerCache.minPrices[j]) {
                    revert Errors.MinPricesNotSorted(reportInfo.token, innerCache.minPrices[j], innerCache.minPrices[j - 1]);
                }

                // validate that maxPrices are sorted in ascending order
                if (innerCache.maxPrices[j - 1] > innerCache.maxPrices[j]) {
                    revert Errors.MaxPricesNotSorted(reportInfo.token, innerCache.maxPrices[j], innerCache.maxPrices[j - 1]);
                }
            }

            for (uint256 j = 0; j < signers.length; j++) {
                innerCache.signatureIndex = i * signers.length + j;
                innerCache.minPriceIndex = OracleUtils.getUncompactedPriceIndex(params.compactedMinPricesIndexes, innerCache.signatureIndex);
                innerCache.maxPriceIndex = OracleUtils.getUncompactedPriceIndex(params.compactedMaxPricesIndexes, innerCache.signatureIndex);

                if (innerCache.signatureIndex >= params.signatures.length) {
                    revert Errors.ArrayOutOfBoundsBytes(params.signatures, innerCache.signatureIndex, "signatures");
                }

                if (innerCache.minPriceIndex >= innerCache.minPrices.length) {
                    revert Errors.ArrayOutOfBoundsUint256(innerCache.minPrices, innerCache.minPriceIndex, "minPrices");
                }

                if (innerCache.maxPriceIndex >= innerCache.maxPrices.length) {
                    revert Errors.ArrayOutOfBoundsUint256(innerCache.maxPrices, innerCache.maxPriceIndex, "maxPrices");
                }

                // since minPrices, maxPrices have the same length as the signers array
                // and the signers array length is less than MAX_SIGNERS
                // minPriceIndexMask and maxPriceIndexMask should be able to store the indexes
                // using Uint256Mask
                innerCache.minPriceIndexMask.validateUniqueAndSetIndex(innerCache.minPriceIndex, "minPriceIndex");
                innerCache.maxPriceIndexMask.validateUniqueAndSetIndex(innerCache.maxPriceIndex, "maxPriceIndex");

                reportInfo.minPrice = innerCache.minPrices[innerCache.minPriceIndex];
                reportInfo.maxPrice = innerCache.maxPrices[innerCache.maxPriceIndex];

                if (reportInfo.minPrice > reportInfo.maxPrice) {
                    revert Errors.InvalidSignerMinMaxPrice(reportInfo.minPrice, reportInfo.maxPrice);
                }

                OracleUtils.validateSigner(
                    _getSalt(),
                    reportInfo,
                    params.signatures[innerCache.signatureIndex],
                    signers[j]
                );
            }

            uint256 medianMinPrice = Array.getMedian(innerCache.minPrices) * reportInfo.precision;
            uint256 medianMaxPrice = Array.getMedian(innerCache.maxPrices) * reportInfo.precision;

            (bool hasPriceFeed, uint256 refPrice) = _getPriceFeedPrice(dataStore, reportInfo.token);
            if (hasPriceFeed) {
                validateRefPrice(
                    reportInfo.token,
                    medianMinPrice,
                    refPrice,
                    cache.maxRefPriceDeviationFactor
                );

                validateRefPrice(
                    reportInfo.token,
                    medianMaxPrice,
                    refPrice,
                    cache.maxRefPriceDeviationFactor
                );
            }

            if (medianMinPrice == 0 || medianMaxPrice == 0) {
                revert Errors.InvalidOraclePrice(reportInfo.token);
            }

            if (medianMinPrice > medianMaxPrice) {
                revert Errors.InvalidMedianMinMaxPrice(medianMinPrice, medianMaxPrice);
            }

            cache.validatedPrices[i] = ValidatedPrice(
                reportInfo.token, // token
                medianMinPrice, // min
                medianMaxPrice, // max
                reportInfo.oracleTimestamp, // timestamp
                reportInfo.minOracleBlockNumber, // minBlockNumber
                reportInfo.maxOracleBlockNumber // maxBlockNumber
            );
        }

        return cache.validatedPrices;
    }

    function _validateRealtimeFeeds(
        DataStore dataStore,
        address[] memory realtimeFeedTokens,
        bytes[] memory realtimeFeedData
    ) internal returns (OracleUtils.RealtimeFeedReport[] memory) {
        if (realtimeFeedTokens.length != realtimeFeedData.length) {
            revert Errors.InvalidRealtimeFeedLengths(realtimeFeedTokens.length, realtimeFeedData.length);
        }

        OracleUtils.RealtimeFeedReport[] memory reports = new OracleUtils.RealtimeFeedReport[](realtimeFeedTokens.length);

        uint256 minBlockConfirmations = dataStore.getUint(Keys.MIN_ORACLE_BLOCK_CONFIRMATIONS);
        uint256 maxPriceAge = dataStore.getUint(Keys.MAX_ORACLE_PRICE_AGE);

        for (uint256 i; i < realtimeFeedTokens.length; i++) {
            address token = realtimeFeedTokens[i];
            bytes32 feedId = dataStore.getBytes32(Keys.realtimeFeedIdKey(token));
            if (feedId == bytes32(0)) {
                revert Errors.EmptyRealtimeFeedId(token);
            }

            bytes memory data = realtimeFeedData[i];
            bytes memory verifierResponse = realtimeFeedVerifier.verify(data);

            OracleUtils.RealtimeFeedReport memory report = abi.decode(verifierResponse, (OracleUtils.RealtimeFeedReport));

            // feedIds are unique per chain so this validation also ensures that the price was signed
            // for the current chain
            if (feedId != report.feedId) {
                revert Errors.InvalidRealtimeFeedId(token, report.feedId, feedId);
            }

            if (report.bid <= 0 || report.ask <= 0) {
                revert Errors.InvalidRealtimePrices(token, report.bid, report.ask);
            }

            if (report.bid > report.ask) {
                revert Errors.InvalidRealtimeBidAsk(token, report.bid, report.ask);
            }

            // only check the block hash if this is not an estimate gas call (tx.origin != address(0))
            // this helps to prevent estimate gas from failing when executed in the context of the block
            // that the deposit / order / withdrawal was created in
            if (
                !(tx.origin == address(0) && Chain.currentBlockNumber() == report.blocknumberUpperBound) &&
                (Chain.currentBlockNumber() - report.blocknumberUpperBound <= minBlockConfirmations)
            ) {
                bytes32 blockHash = Chain.getBlockHash(report.blocknumberUpperBound);
                if (report.upperBlockhash != blockHash) {
                    revert Errors.InvalidRealtimeBlockHash(token, report.upperBlockhash, blockHash);
                }
            }

            if (report.currentBlockTimestamp + maxPriceAge < Chain.currentTimestamp()) {
                revert Errors.RealtimeMaxPriceAgeExceeded(token, report.currentBlockTimestamp, Chain.currentTimestamp());
            }

            reports[i] = report;
        }

        return reports;
    }

    function _getSigners(
        DataStore dataStore,
        OracleUtils.SetPricesParams memory params
    ) internal view returns (address[] memory) {
        // first 16 bits of signer info contains the number of signers
        address[] memory signers = new address[](params.signerInfo & Bits.BITMASK_16);

        if (signers.length < dataStore.getUint(Keys.MIN_ORACLE_SIGNERS)) {
            revert Errors.MinOracleSigners(signers.length, dataStore.getUint(Keys.MIN_ORACLE_SIGNERS));
        }

        if (signers.length > MAX_SIGNERS) {
            revert Errors.MaxOracleSigners(signers.length, MAX_SIGNERS);
        }

        Uint256Mask.Mask memory signerIndexMask;

        for (uint256 i; i < signers.length; i++) {
            uint256 signerIndex = params.signerInfo >> (16 + 16 * i) & Bits.BITMASK_16;

            if (signerIndex >= MAX_SIGNER_INDEX) {
                revert Errors.MaxSignerIndex(signerIndex, MAX_SIGNER_INDEX);
            }

            signerIndexMask.validateUniqueAndSetIndex(signerIndex, "signerIndex");

            signers[i] = oracleStore.getSigner(signerIndex);

            if (signers[i] == address(0)) {
                revert Errors.EmptySigner(signerIndex);
            }
        }

        return signers;
    }

    function _validateBlockRanges(
        OracleUtils.RealtimeFeedReport[] memory reports,
        ValidatedPrice[] memory validatedPrices
    ) internal pure {
        uint256 largestMinBlockNumber; // defaults to zero
        uint256 smallestMaxBlockNumber = type(uint256).max;

        for (uint256 i; i < reports.length; i++) {
            OracleUtils.RealtimeFeedReport memory report = reports[i];

            if (report.blocknumberLowerBound > largestMinBlockNumber) {
                largestMinBlockNumber = report.blocknumberLowerBound;
            }

            if (report.blocknumberUpperBound < smallestMaxBlockNumber) {
                smallestMaxBlockNumber = report.blocknumberUpperBound;
            }
        }

        for (uint256 i; i < validatedPrices.length; i++) {
            ValidatedPrice memory validatedPrice = validatedPrices[i];

            if (validatedPrice.minBlockNumber > largestMinBlockNumber) {
                largestMinBlockNumber = validatedPrice.minBlockNumber;
            }

            if (validatedPrice.maxBlockNumber < smallestMaxBlockNumber) {
                smallestMaxBlockNumber = validatedPrice.maxBlockNumber;
            }
        }

        if (largestMinBlockNumber > smallestMaxBlockNumber) {
            revert Errors.InvalidBlockRangeSet(largestMinBlockNumber, smallestMaxBlockNumber);
        }
    }

    // it might be possible for the block.chainid to change due to a fork or similar
    // for this reason, this salt is not cached
    function _getSalt() internal view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, "xget-oracle-v1"));
    }

    function validateRefPrice(
        address token,
        uint256 price,
        uint256 refPrice,
        uint256 maxRefPriceDeviationFactor
    ) internal pure {
        uint256 diff = Calc.diff(price, refPrice);
        uint256 diffFactor = Precision.toFactor(diff, refPrice);

        if (diffFactor > maxRefPriceDeviationFactor) {
            revert Errors.MaxRefPriceDeviationExceeded(
                token,
                price,
                refPrice,
                maxRefPriceDeviationFactor
            );
        }
    }

    function _setPrimaryPrice(address token, Price.Props memory price) internal {
        if (price.min > price.max) {
            revert Errors.InvalidMinMaxForPrice(token, price.min, price.max);
        }

        Price.Props memory existingPrice = primaryPrices[token];

        if (!existingPrice.isEmpty()) {
            revert Errors.PriceAlreadySet(token, existingPrice.min, existingPrice.max);
        }

        primaryPrices[token] = price;
        tokensWithPrices.add(token);
    }

    function _removePrimaryPrice(address token) internal {
        delete primaryPrices[token];
        tokensWithPrices.remove(token);
    }

    // there is a small risk of stale pricing due to latency in price updates or if the chain is down
    // this is meant to be for temporary use until low latency price feeds are supported for all tokens
    function _getPriceFeedPrice(DataStore dataStore, address token) internal view returns (bool, uint256) {
        address priceFeedAddress = dataStore.getAddress(Keys.priceFeedKey(token));
        if (priceFeedAddress == address(0)) {
            return (false, 0);
        }

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        (
            /* uint80 roundID */,
            int256 _price,
            /* uint256 startedAt */,
            uint256 timestamp,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();

        if (_price <= 0) {
            revert Errors.InvalidFeedPrice(token, _price);
        }

        uint256 heartbeatDuration = dataStore.getUint(Keys.priceFeedHeartbeatDurationKey(token));
        if (Chain.currentTimestamp() > timestamp && Chain.currentTimestamp() - timestamp > heartbeatDuration) {
            revert Errors.PriceFeedNotUpdated(token, timestamp, heartbeatDuration);
        }

        uint256 price = SafeCast.toUint256(_price);
        uint256 precision = getPriceFeedMultiplier(dataStore, token);

        uint256 adjustedPrice = Precision.mulDiv(price, precision, Precision.FLOAT_PRECISION);

        return (true, adjustedPrice);
    }

    function _setPricesFromRealtimeFeeds(
        DataStore dataStore,
        EventEmitter eventEmitter,
        OracleUtils.SetPricesParams memory params
    ) internal returns (OracleUtils.RealtimeFeedReport[] memory) {
        OracleUtils.RealtimeFeedReport[] memory reports = _validateRealtimeFeeds(
            dataStore,
            params.realtimeFeedTokens,
            params.realtimeFeedData
        );

        uint256 maxRefPriceDeviationFactor = dataStore.getUint(Keys.MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR);

        for (uint256 i; i < params.realtimeFeedTokens.length; i++) {
            address token = params.realtimeFeedTokens[i];

            OracleUtils.RealtimeFeedReport memory report = reports[i];

            uint256 precision = getRealtimeFeedMultiplier(dataStore, token);
            uint256 adjustedBidPrice = Precision.mulDiv(uint256(uint192(report.bid)), precision, Precision.FLOAT_PRECISION);
            uint256 adjustedAskPrice = Precision.mulDiv(uint256(uint192(report.ask)), precision, Precision.FLOAT_PRECISION);

            (bool hasPriceFeed, uint256 refPrice) = _getPriceFeedPrice(dataStore, token);
            if (hasPriceFeed) {
                validateRefPrice(
                    token,
                    adjustedBidPrice,
                    refPrice,
                    maxRefPriceDeviationFactor
                );

                validateRefPrice(
                    token,
                    adjustedAskPrice,
                    refPrice,
                    maxRefPriceDeviationFactor
                );
            }

            Price.Props memory priceProps = Price.Props(
                adjustedBidPrice, // min
                adjustedAskPrice // max
            );

            _setPrimaryPrice(token, priceProps);

            emitOraclePriceUpdated(
                eventEmitter,
                token,
                priceProps.min,
                priceProps.max,
                report.currentBlockTimestamp,
                OracleUtils.PriceSourceType.RealtimeFeed
            );
        }

        return reports;
    }

    // @dev set prices using external price feeds to save costs for tokens with stable prices
    // @param dataStore DataStore
    // @param eventEmitter EventEmitter
    // @param priceFeedTokens the tokens to set the prices using the price feeds for
    function _setPricesFromPriceFeeds(DataStore dataStore, EventEmitter eventEmitter, address[] memory priceFeedTokens) internal {
        for (uint256 i; i < priceFeedTokens.length; i++) {
            address token = priceFeedTokens[i];

            (bool hasPriceFeed, uint256 price) = _getPriceFeedPrice(dataStore, token);

            if (!hasPriceFeed) {
                revert Errors.EmptyPriceFeed(token);
            }

            uint256 stablePrice = getStablePrice(dataStore, token);

            Price.Props memory priceProps;

            if (stablePrice > 0) {
                priceProps = Price.Props(
                    price < stablePrice ? price : stablePrice,
                    price < stablePrice ? stablePrice : price
                );
            } else {
                priceProps = Price.Props(
                    price,
                    price
                );
            }

            _setPrimaryPrice(token, priceProps);

            emitOraclePriceUpdated(
                eventEmitter,
                token,
                priceProps.min,
                priceProps.max,
                Chain.currentTimestamp(),
                OracleUtils.PriceSourceType.PriceFeed
            );
        }
    }

    function emitOraclePriceUpdated(
        EventEmitter eventEmitter,
        address token,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 timestamp,
        OracleUtils.PriceSourceType priceSourceType
    ) internal {
        EventUtils.EventLogData memory eventData;

        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "token", token);

        eventData.uintItems.initItems(4);
        eventData.uintItems.setItem(0, "minPrice", minPrice);
        eventData.uintItems.setItem(1, "maxPrice", maxPrice);
        eventData.uintItems.setItem(2, "timestamp", timestamp);
        eventData.uintItems.setItem(3, "priceSourceType", uint256(priceSourceType));

        eventEmitter.emitEventLog1(
            "OraclePriceUpdate",
            Cast.toBytes32(token),
            eventData
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title Price
// @dev Struct for prices
library Price {
    // @param min the min price
    // @param max the max price
    struct Props {
        uint256 min;
        uint256 max;
    }

    // @dev check if a price is empty
    // @param props Props
    // @return whether a price is empty
    function isEmpty(Props memory props) internal pure returns (bool) {
        return props.min == 0 || props.max == 0;
    }

    // @dev get the average of the min and max values
    // @param props Props
    // @return the average of the min and max values
    function midPrice(Props memory props) internal pure returns (uint256) {
        return (props.max + props.min) / 2;
    }

    // @dev pick either the min or max value
    // @param props Props
    // @param maximize whether to pick the min or max value
    // @return either the min or max value
    function pickPrice(Props memory props, bool maximize) internal pure returns (uint256) {
        return maximize ? props.max : props.min;
    }

    // @dev pick the min or max price depending on whether it is for a long or short position
    // and whether the pending pnl should be maximized or not
    // @param props Props
    // @param isLong whether it is for a long or short position
    // @param maximize whether the pnl should be maximized or not
    // @return the min or max price
    function pickPriceForPnl(Props memory props, bool isLong, bool maximize) internal pure returns (uint256) {
        // for long positions, pick the larger price to maximize pnl
        // for short positions, pick the smaller price to maximize pnl
        if (isLong) {
            return maximize ? props.max : props.min;
        }

        return maximize ? props.min : props.max;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title Calc
 * @dev Library for math functions
 */
library Calc {
    using SignedMath for int256;
    using SafeCast for uint256;

    // this method assumes that min is less than max
    function boundMagnitude(int256 value, uint256 min, uint256 max) internal pure returns (int256) {
        uint256 magnitude = value.abs();

        if (magnitude < min) {
            magnitude = min;
        }

        if (magnitude > max) {
            magnitude = max;
        }

        int256 sign = value == 0 ? int256(1) : value / value.abs().toInt256();

        return magnitude.toInt256() * sign;
    }

    /**
     * @dev Calculates the result of dividing the first number by the second number,
     * rounded up to the nearest integer.
     *
     * @param a the dividend
     * @param b the divisor
     * @return the result of dividing the first number by the second number, rounded up to the nearest integer
     */
    function roundUpDivision(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    /**
     * Calculates the result of dividing the first number by the second number,
     * rounded up to the nearest integer.
     * The rounding is purely on the magnitude of a, if a is negative the result
     * is a larger magnitude negative
     *
     * @param a the dividend
     * @param b the divisor
     * @return the result of dividing the first number by the second number, rounded up to the nearest integer
     */
    function roundUpMagnitudeDivision(int256 a, uint256 b) internal pure returns (int256) {
        if (a < 0) {
            return (a - b.toInt256() + 1) / b.toInt256();
        }

        return (a + b.toInt256() - 1) / b.toInt256();
    }

    /**
     * Adds two numbers together and return a uint256 value, treating the second number as a signed integer.
     *
     * @param a the first number
     * @param b the second number
     * @return the result of adding the two numbers together
     */
    function sumReturnUint256(uint256 a, int256 b) internal pure returns (uint256) {
        if (b > 0) {
            return a + b.abs();
        }

        return a - b.abs();
    }

    /**
     * Adds two numbers together and return an int256 value, treating the second number as a signed integer.
     *
     * @param a the first number
     * @param b the second number
     * @return the result of adding the two numbers together
     */
    function sumReturnInt256(uint256 a, int256 b) internal pure returns (int256) {
        return a.toInt256() + b;
    }

    /**
     * @dev Calculates the absolute difference between two numbers.
     *
     * @param a the first number
     * @param b the second number
     * @return the absolute difference between the two numbers
     */
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    /**
     * Adds two numbers together, the result is bounded to prevent overflows.
     *
     * @param a the first number
     * @param b the second number
     * @return the result of adding the two numbers together
     */
    function boundedAdd(int256 a, int256 b) internal pure returns (int256) {
        // if either a or b is zero or if the signs are different there should not be any overflows
        if (a == 0 || b == 0 || (a < 0 && b > 0) || (a > 0 && b < 0)) {
            return a + b;
        }

        // if adding `b` to `a` would result in a value less than the min int256 value
        // then return the min int256 value
        if (a < 0 && b <= type(int256).min - a) {
            return type(int256).min;
        }

        // if adding `b` to `a` would result in a value more than the max int256 value
        // then return the max int256 value
        if (a > 0 && b >= type(int256).max - a) {
            return type(int256).max;
        }

        return a + b;
    }

    /**
     * Returns a - b, the result is bounded to prevent overflows.
     * Note that this will revert if b is type(int256).min because of the usage of "-b".
     *
     * @param a the first number
     * @param b the second number
     * @return the bounded result of a - b
     */
    function boundedSub(int256 a, int256 b) internal pure returns (int256) {
        // if either a or b is zero or the signs are the same there should not be any overflow
        if (a == 0 || b == 0 || (a > 0 && b > 0) || (a < 0 && b < 0)) {
            return a - b;
        }

        // if adding `-b` to `a` would result in a value greater than the max int256 value
        // then return the max int256 value
        if (a > 0 && -b >= type(int256).max - a) {
            return type(int256).max;
        }

        // if subtracting `b` from `a` would result in a value less than the min int256 value
        // then return the min int256 value
        if (a < 0 && -b <= type(int256).min - a) {
            return type(int256).min;
        }

        return a - b;
    }


    /**
     * Converts the given unsigned integer to a signed integer, using the given
     * flag to determine whether the result should be positive or negative.
     *
     * @param a the unsigned integer to convert
     * @param isPositive whether the result should be positive (if true) or negative (if false)
     * @return the signed integer representation of the given unsigned integer
     */
    function toSigned(uint256 a, bool isPositive) internal pure returns (int256) {
        if (isPositive) {
            return a.toInt256();
        } else {
            return -a.toInt256();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// there is a known issue with prb-math v3.x releases
// https://github.com/PaulRBerg/prb-math/issues/178
// due to this, either prb-math v2.x or v4.x versions should be used instead
import "prb-math/contracts/PRBMathUD60x18.sol";

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./Calc.sol";

/**
 * @title Precision
 * @dev Library for precision values and conversions
 */
library Precision {
    using SafeCast for uint256;
    using SignedMath for int256;

    uint256 public constant FLOAT_PRECISION = 10 ** 30;
    uint256 public constant FLOAT_PRECISION_SQRT = 10 ** 15;

    uint256 public constant WEI_PRECISION = 10 ** 18;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant FLOAT_TO_WEI_DIVISOR = 10 ** 12;

    /**
     * Applies the given factor to the given value and returns the result.
     *
     * @param value The value to apply the factor to.
     * @param factor The factor to apply.
     * @return The result of applying the factor to the value.
     */
    function applyFactor(uint256 value, uint256 factor) internal pure returns (uint256) {
        return mulDiv(value, factor, FLOAT_PRECISION);
    }

    /**
     * Applies the given factor to the given value and returns the result.
     *
     * @param value The value to apply the factor to.
     * @param factor The factor to apply.
     * @return The result of applying the factor to the value.
     */
    function applyFactor(uint256 value, int256 factor) internal pure returns (int256) {
        return mulDiv(value, factor, FLOAT_PRECISION);
    }

    function applyFactor(uint256 value, int256 factor, bool roundUpMagnitude) internal pure returns (int256) {
        return mulDiv(value, factor, FLOAT_PRECISION, roundUpMagnitude);
    }

    function mulDiv(uint256 value, uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return Math.mulDiv(value, numerator, denominator);
    }

    function mulDiv(int256 value, uint256 numerator, uint256 denominator) internal pure returns (int256) {
        return mulDiv(numerator, value, denominator);
    }

    function mulDiv(uint256 value, int256 numerator, uint256 denominator) internal pure returns (int256) {
        uint256 result = mulDiv(value, numerator.abs(), denominator);
        return numerator > 0 ? result.toInt256() : -result.toInt256();
    }

    function mulDiv(uint256 value, int256 numerator, uint256 denominator, bool roundUpMagnitude) internal pure returns (int256) {
        uint256 result = mulDiv(value, numerator.abs(), denominator, roundUpMagnitude);
        return numerator > 0 ? result.toInt256() : -result.toInt256();
    }

    function mulDiv(uint256 value, uint256 numerator, uint256 denominator, bool roundUpMagnitude) internal pure returns (uint256) {
        if (roundUpMagnitude) {
            return Math.mulDiv(value, numerator, denominator, Math.Rounding.Up);
        }

        return Math.mulDiv(value, numerator, denominator);
    }

    function applyExponentFactor(
        uint256 floatValue,
        uint256 exponentFactor
    ) internal pure returns (uint256) {
        // `PRBMathUD60x18.pow` doesn't work for `x` less than one
        if (floatValue < FLOAT_PRECISION) {
            return 0;
        }

        if (exponentFactor == FLOAT_PRECISION) {
            return floatValue;
        }

        // `PRBMathUD60x18.pow` accepts 2 fixed point numbers 60x18
        // we need to convert float (30 decimals) to 60x18 (18 decimals) and then back to 30 decimals
        uint256 weiValue = PRBMathUD60x18.pow(
            floatToWei(floatValue),
            floatToWei(exponentFactor)
        );

        return weiToFloat(weiValue);
    }

    function toFactor(uint256 value, uint256 divisor, bool roundUpMagnitude) internal pure returns (uint256) {
        if (value == 0) { return 0; }

        if (roundUpMagnitude) {
            return Math.mulDiv(value, FLOAT_PRECISION, divisor, Math.Rounding.Up);
        }

        return Math.mulDiv(value, FLOAT_PRECISION, divisor);
    }

    function toFactor(uint256 value, uint256 divisor) internal pure returns (uint256) {
        return toFactor(value, divisor, false);
    }

    function toFactor(int256 value, uint256 divisor) internal pure returns (int256) {
        uint256 result = toFactor(value.abs(), divisor);
        return value > 0 ? result.toInt256() : -result.toInt256();
    }

    /**
     * Converts the given value from float to wei.
     *
     * @param value The value to convert.
     * @return The converted value in wei.
     */
    function floatToWei(uint256 value) internal pure returns (uint256) {
        return value / FLOAT_TO_WEI_DIVISOR;
    }

    /**
     * Converts the given value from wei to float.
     *
     * @param value The value to convert.
     * @return The converted value in float.
     */
    function weiToFloat(uint256 value) internal pure returns (uint256) {
        return value * FLOAT_TO_WEI_DIVISOR;
    }

    /**
     * Converts the given number of basis points to float.
     *
     * @param basisPoints The number of basis points to convert.
     * @return The converted value in float.
     */
    function basisPointsToFloat(uint256 basisPoints) internal pure returns (uint256) {
        return basisPoints * FLOAT_PRECISION / BASIS_POINTS_DIVISOR;
    }
}

pragma solidity 0.8.17;

import { BaseHandler } from "../BaseHandler.sol";
import { ISwapManager } from "../interfaces/ISwapManager.sol";
import { IHandlerContract } from "../interfaces/IHandlerContract.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

/**
 * @title BaseSwapManager
 * @author Umami Devs
 * @notice Abstract base contract for implementing swap managers.
 * @dev This contract provides common functionality for swap manager implementations and enforces
 * swap checks using the `swapChecks` modifier.
 */
abstract contract BaseSwapManager is BaseHandler, ISwapManager {
    error InsufficientOutput();
    error InsufficientInput();
    error InvalidInput();
    error TooMuchInput();

    /**
     * @notice Returns an empty array for callback signatures.
     * @return _ret An empty bytes4[] array.
     */
    function callbackSigs() external pure returns (bytes4[] memory _ret) {
        _ret = new bytes4[](0);
    }

    /**
     * @notice Modifier to enforce swap checks, ensuring sufficient input and output token amounts.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountIn The amount of input tokens to swap.
     * @param _minOut The minimum amount of output tokens to receive.
     */
    modifier swapChecks(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _minOut) {
        uint256 tokenInBalance = ERC20(_tokenIn).balanceOf(address(this));
        if (tokenInBalance < _amountIn) revert InsufficientInput();
        uint256 tokenOutBalanceBefore = ERC20(_tokenOut).balanceOf(address(this));
        _;
        uint256 tokenOutBalanceAfter = ERC20(_tokenOut).balanceOf(address(this));
        uint256 actualOut = tokenOutBalanceAfter - tokenOutBalanceBefore;
        if (actualOut < _minOut) revert InsufficientOutput();
    }

    /**
     * @notice Modifier to enforce swap checks, ensuring sufficient input and output token amounts.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountOut The amount of output tokens to expect.
     * @param _maxIn The max amount of input tokens to send.
     */
    modifier swapChecksExactOutput(address _tokenIn, address _tokenOut, uint256 _amountOut, uint256 _maxIn) {
        uint256 tokenInBalance = ERC20(_tokenIn).balanceOf(address(this));
        uint256 tokenOutBalanceBefore = ERC20(_tokenOut).balanceOf(address(this));
        _;
        uint256 tokenOutBalanceAfter = ERC20(_tokenOut).balanceOf(address(this));
        uint256 actualOut = tokenOutBalanceAfter - tokenOutBalanceBefore;
        if (actualOut != _amountOut) revert InsufficientOutput();
        uint256 actualIn = tokenInBalance - ERC20(_tokenIn).balanceOf(address(this));
        if (actualIn > _maxIn) revert TooMuchInput();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import { IUniswapV3PoolState } from "./IUniswapV3PoolState.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is IUniswapV3PoolState {
    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

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
        address indexed token0, address indexed token1, uint24 indexed fee, int24 tickSpacing, address pool
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
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

/// @title Transfer utilities for tokens and eth
/// @author Umami Devs
library TransferUtils {
    using SafeTransferLib for ERC20;

    /**
     * @notice Helper function to make an ERC20 transfer
     * @param asset the asset to transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(address asset, address recipient, uint256 amount) internal {
        ERC20(asset).safeTransfer(recipient, amount);
    }

    /**
     * @notice Helper function to make an ETH transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferNativeAsset(address recipient, uint256 amount) internal {
        (bool success,) = recipient.call{ value: amount }("");
        require(success, "TransferUtils: failed native token transfer");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { BaseVault } from "./BaseVault.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import { ShareMath } from "../libraries/ShareMath.sol";

import { GlobalACL, REQUEST_HANDLER, AGGREGATE_VAULT_ROLE } from "../Auth.sol";
import { PausableVault } from "../PausableVault.sol";
import { AggregateVault } from "./AggregateVault.sol";
import { AggregateVaultStorage } from "../storage/AggregateVaultStorage.sol";

/// @title AssetVault
/// @author Umami DAO
/// @notice ERC4626-like implementation for vault receipt tokens
contract AssetVault is BaseVault, PausableVault, GlobalACL, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    /// @dev the aggregate vault for the strategy
    AggregateVault public aggregateVault;

    constructor(ERC20 _asset, string memory _name, string memory _symbol, address _aggregateVault)
        BaseVault(_asset, _name, _symbol)
        GlobalACL(AggregateVault(payable(_aggregateVault)).AUTH())
    {
        aggregateVault = AggregateVault(payable(_aggregateVault));
    }

    // DEPOSIT & WITHDRAW
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Deposit a specified amount of assets and mint corresponding shares to the receiver
     * @param assets The amount of assets to deposit
     * @param minOutAfterFees Minimum amount out after fees
     * @param receiver The address to receive the minted shares
     * @return shares The estimate amount of shares minted for the deposited assets
     */
    function deposit(uint256 assets, uint256 minOutAfterFees, address receiver)
        public
        payable
        override
        whenDepositNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        require(
            totalAssets() + assets <= previewVaultCap() + asset.balanceOf(address(this)), "AssetVault: over vault cap"
        );
        // Transfer assets to aggregate vault, transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);
        aggregateVault.handleDeposit{ value: msg.value }(assets, minOutAfterFees, receiver, msg.sender, address(0));

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Redeem a specified amount of shares by burning them and transferring the corresponding amount of assets to the receiver
     * @param shares The amount of shares to redeem
     * @param minOutAfterFees Minimum amount out after fees
     * @param receiver The address to receive the corresponding assets
     * @param owner The address of the share owner
     * @return assets The estimate amount of assets transferred for the redeemed shares
     */
    function redeem(uint256 shares, uint256 minOutAfterFees, address receiver, address owner)
        public
        payable
        override
        whenWithdrawalNotPaused
        nonReentrant
        returns (uint256 assets)
    {
        require(shares > 0, "AssetVault: !shares > 0");
        assets = totalSupply == 0 ? shares : ShareMath.sharesToAsset(shares, pps(), decimals);
        if (msg.sender != owner) _checkAllowance(owner, shares);
        require(assets <= asset.balanceOf(address(aggregateVault)), "AssetVault: assets not available");

        // Check for rounding error since we round down in previewRedeem.
        require(previewRedeem(shares) != 0, "ZERO_ASSETS");

        // transfer shares in
        ERC20(address(this)).safeTransferFrom(owner, address(this), shares);

        // handle withdraw
        aggregateVault.handleWithdraw{ value: msg.value }(shares, minOutAfterFees, receiver, msg.sender, address(0));

        emit Withdraw(owner, receiver, owner, assets, shares);
    }

    // WITH CALLBACKS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Deposit a specified amount of assets and mint corresponding shares to the receiver
     * @param assets The amount of assets to deposit
     * @param minOutAfterFees Minimum amount out after fees
     * @param receiver The address to receive the minted shares
     * @param callback The address to callback to after execution
     * @return shares The estimate amount of shares minted for the deposited assets
     */
    function depositWithCallback(uint256 assets, uint256 minOutAfterFees, address receiver, address callback)
        public
        payable
        whenDepositNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        require(
            totalAssets() + assets <= previewVaultCap() + asset.balanceOf(address(this)), "AssetVault: over vault cap"
        );
        // Transfer assets to aggregate vault, transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);
        aggregateVault.handleDeposit{ value: msg.value }(assets, minOutAfterFees, receiver, msg.sender, callback);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Redeem a specified amount of shares by burning them and transferring the corresponding amount of assets to the receiver
     * @param shares The amount of shares to redeem
     * @param minOutAfterFees Minimum amount out after fees
     * @param receiver The address to receive the corresponding assets
     * @param owner The address of the share owner
     * @param callback The address to callback to after execution
     * @return assets The estimate amount of assets transferred for the redeemed shares
     */
    function redeemWithCallback(
        uint256 shares,
        uint256 minOutAfterFees,
        address receiver,
        address owner,
        address callback
    ) public payable whenWithdrawalNotPaused nonReentrant returns (uint256 assets) {
        require(shares > 0, "AssetVault: !shares > 0");
        assets = totalSupply == 0 ? shares : ShareMath.sharesToAsset(shares, pps(), decimals);

        if (msg.sender != owner) _checkAllowance(owner, shares);

        // Check for rounding error since we round down in previewRedeem.
        require(previewRedeem(shares) != 0, "ZERO_ASSETS");

        // transfer shares in
        ERC20(address(this)).safeTransferFrom(owner, address(this), shares);

        // handle withdrawal
        aggregateVault.handleWithdraw{ value: msg.value }(shares, minOutAfterFees, receiver, msg.sender, callback);

        emit Withdraw(owner, receiver, owner, assets, shares);
    }

    /**
     * @notice Cancels a vault request for this vault
     * @param key The request key to cancel
     */
    function cancelRequest(uint256 key) external {
        AggregateVaultStorage.OCRequest memory request = aggregateVault.getRequest(key);
        require(request.vault == address(this), "AssetVault: invalid vault");
        require(request.sender == msg.sender, "AssetVault: invalid account");

        if (request.isDeposit) {
            asset.safeTransfer(msg.sender, request.amount);
        } else {
            ERC20(address(this)).safeTransfer(msg.sender, request.amount);
        }

        aggregateVault.clearRequest(key);
    }

    // MATH
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Get the total value locked (TVL) of the vault
     * @return totalValueLocked The current total value locked
     */
    function totalAssets() public view override returns (uint256 totalValueLocked) {
        (bool success, bytes memory ret) =
            address(aggregateVault).staticcall(abi.encodeCall(AggregateVault.getVaultTVL, (address(this), false)));

        // bubble up error message
        if (!success) {
            assembly {
                let length := mload(ret)
                revert(add(32, ret), length)
            }
        }
        totalValueLocked = abi.decode(ret, (uint256));
    }

    /**
     * @notice Get the price per share (PPS) of the vault
     * @return pricePerShare The current price per share
     */
    function pps() public view returns (uint256 pricePerShare) {
        (bool success, bytes memory ret) =
            address(aggregateVault).staticcall(abi.encodeCall(AggregateVault.getVaultPPS, (address(this), true, false)));

        // bubble up error message
        if (!success) {
            assembly {
                let length := mload(ret)
                revert(add(32, ret), length)
            }
        }

        pricePerShare = abi.decode(ret, (uint256));
    }

    /**
     * @notice Convert a specified amount of assets to shares
     * @param assets The amount of assets to convert
     * @return - The amount of shares corresponding to the given assets
     */
    function convertToShares(uint256 assets) public view override returns (uint256) {
        return totalSupply == 0 ? assets : ShareMath.assetToShares(assets, pps(), decimals);
    }

    /**
     * @notice Convert a specified amount of shares to assets
     * @param shares The amount of shares to convert
     * @return - The amount of assets corresponding to the given shares
     */
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        return totalSupply == 0 ? shares : ShareMath.sharesToAsset(shares, pps(), decimals);
    }

    /**
     * @notice Preview the amount of shares for a given deposit amount
     * @param assets The amount of assets to deposit
     * @return - The amount of shares for the given deposit amount
     */
    function previewDeposit(uint256 assets) public view override returns (uint256) {
        uint256 assetFee = previewDepositFee(assets);
        if (assetFee >= assets) return 0;
        return convertToShares(assets - assetFee);
    }

    /**
     * @notice Preview the amount of assets for a given redeem amount
     * @param shares The amount of shares to redeem
     * @return The amount of assets for the given redeem amount
     */
    function previewRedeem(uint256 shares) public view override returns (uint256) {
        uint256 assets = ShareMath.sharesToAsset(shares, pps(), decimals);
        uint256 assetFee = previewWithdrawalFee(assets);
        if (assetFee >= assets) return 0;
        return assets - assetFee;
    }

    // DEPOSIT & WITHDRAW LIMIT
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Get the maximum deposit amount for an address
     * @dev _address The address to check the maximum deposit amount for
     * @dev returns the maximum deposit amount for the given address
     */
    function maxDeposit(address) public view override returns (uint256) {
        uint256 cap = previewVaultCap();
        uint256 tvl_ = totalAssets();
        return cap > tvl_ ? cap - tvl_ : 0;
    }

    /**
     * @notice Get the maximum mint amount for an address
     */
    function maxMint(address) public view override returns (uint256) {
        uint256 cap = previewVaultCap();
        uint256 tvl_ = totalAssets();
        return cap > tvl_ ? convertToShares(cap - tvl_) : 0;
    }

    /**
     * @notice Get the maximum withdrawal amount for an address
     * @param owner The address to check the maximum withdrawal amount for
     * @return The maximum withdrawal amount for the given address
     */
    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 aggBalance = asset.balanceOf(address(aggregateVault));
        uint256 userMaxAssets = convertToAssets(balanceOf[owner]);
        return aggBalance > userMaxAssets ? userMaxAssets : aggBalance;
    }

    /**
     * @notice Get the maximum redeem amount for an address
     * @param owner The address to check the maximum redeem amount for
     * @return - The maximum redeem amount for the given address
     */
    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 aggBalance = convertToShares(asset.balanceOf(address(aggregateVault)));
        return aggBalance > balanceOf[owner] ? balanceOf[owner] : aggBalance;
    }

    // UTILS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Pause deposit and withdrawal operations
     */
    function pauseDepositWithdraw() external onlyAggregateVault {
        _pause();
    }

    /**
     * @notice Unpause deposit and withdrawal operations
     */
    function unpauseDepositWithdraw() external onlyAggregateVault {
        _unpause();
    }

    /**
     * @notice Pause deposits operations
     */
    function pauseDeposits() external onlyConfigurator {
        _pauseDeposit();
    }

    /**
     * @notice Unpause deposit operations
     */
    function unpauseDeposits() external onlyConfigurator {
        _unpauseDeposit();
    }

    /**
     * @notice Pause withdrawal operations
     */
    function pauseWithdrawals() external onlyConfigurator {
        _pauseWithdrawal();
    }

    /**
     * @notice Unpause withdrawal operations
     */
    function unpauseWithdrawals() external onlyConfigurator {
        _unpauseWithdrawal();
    }

    /**
     * @notice Update the aggregate vault to a new instance
     * @param _newAggregateVault The new aggregate vault instance to update to
     */
    function updateAggregateVault(AggregateVault _newAggregateVault) external onlyConfigurator {
        aggregateVault = _newAggregateVault;
    }

    /**
     * @notice Mint a specified amount of shares to an address
     * @param _mintAmount The amount of shares to mint
     * @param _toAddress The address to mint
     */
    function mintTo(uint256 _mintAmount, address _toAddress) external validateMintCallAuth(_toAddress) {
        _mint(_toAddress, _mintAmount);
    }

    /**
     * @notice Burn tokens during order execution
     * @param _burnAmount The amount of shares to burn
     */
    function burnShares(uint256 _burnAmount) external onlyRequestHandler {
        _burn(address(this), _burnAmount);
    }

    /**
     * @notice Lodge the underlying assets for a deposit execution
     * @param _assetAmount The amount of assets to lodge
     */
    function lodgeAssets(uint256 _assetAmount, address feeReciever, uint256 _depositFees) external onlyRequestHandler {
        asset.safeTransfer(address(aggregateVault), _assetAmount);
        if (_depositFees > 0 && feeReciever != address(0)) asset.safeTransfer(feeReciever, _depositFees);
    }

    /**
     * @notice Return deposited assets
     */
    function returnAssets(address _to, uint256 _amt) external onlyRequestHandler {
        asset.safeTransfer(_to, _amt);
    }

    /**
     * @notice Return withdraw request shares
     */
    function returnShares(address _to, uint256 _amt) external onlyRequestHandler {
        ERC20(address(this)).safeTransfer(_to, _amt);
    }

    /**
     * @notice Preview the deposit fee for a specified amount of assets
     * @param size The amount of assets to preview the deposit fee for
     * @return totalDepositFee The total deposit fee for the specified amount of assets
     */
    function previewDepositFee(uint256 size) public view returns (uint256 totalDepositFee) {
        (bool success, bytes memory ret) = address(aggregateVault).staticcall(
            abi.encodeCall(AggregateVault.previewDepositFee, (address(asset), size, false))
        );
        if (!success) {
            assembly {
                let length := mload(ret)
                revert(add(32, ret), length)
            }
        }
        totalDepositFee = abi.decode(ret, (uint256));
    }

    /**
     * @notice Preview the withdrawal fee for a specified amount of assets
     * @param size The amount of assets to preview the withdrawal fee for
     * @return totalWithdrawalFee The total withdrawal fee for the specified amount of assets
     */
    function previewWithdrawalFee(uint256 size) public view returns (uint256 totalWithdrawalFee) {
        (bool success, bytes memory ret) = address(aggregateVault).staticcall(
            abi.encodeCall(AggregateVault.previewWithdrawalFee, (address(asset), size, false))
        );
        if (!success) {
            assembly {
                let length := mload(ret)
                revert(add(32, ret), length)
            }
        }
        totalWithdrawalFee = abi.decode(ret, (uint256));
    }

    /**
     * @notice Preview the deposit cap for the vault
     * @return - The current deposit cap for the vault
     */
    function previewVaultCap() public view returns (uint256) {
        return aggregateVault.previewVaultCap(address(asset));
    }

    /**
     * @dev Check the owners spend allowance
     */
    function _checkAllowance(address owner, uint256 shares) internal {
        uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
    }

    /// @dev validate the mint call
    modifier validateMintCallAuth(address _mintTo) {
        require(
            (_mintTo == aggregateVault.getVaultTimelockAddress(address(asset)) && address(aggregateVault) == msg.sender)
                || AUTH.hasRole(REQUEST_HANDLER, msg.sender),
            "AssetVault: !validateMintCallAuth"
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { SafeCast } from "./SafeCast.sol";
import { Solarray } from "./Solarray.sol";

/// @title NettingMath
/// @author Umami Devs
/// @notice Contains math for validating a set of netted parameters
library NettingMath {
    // PUBLIC
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Calculates the GLP exposure and vault ratio for each position
     * @param vaultCumulativeHoldings The vault's cumulative index TVL
     * @param indexComposition The index composition as an array of two uint256 values
     * @param vaultHoldings The amount of the index token allocated to each vault
     * @param externalPosition the external positions
     * @return indexExposure An array of index exposure for each position
     * @return vaultRatio An array of vault ratios for each position
     */
    function vaultDeltaAdjustment(
        uint256 vaultCumulativeHoldings,
        uint256[2] memory indexComposition,
        uint256[2] memory vaultHoldings,
        int256 externalPosition
    ) public pure returns (uint256[2] memory indexExposure, uint256 vaultRatio) {
        indexExposure[0] = vaultCumulativeHoldings * indexComposition[0] / 1e18;
        indexExposure[1] = vaultCumulativeHoldings * indexComposition[1] / 1e18;

        if (externalPosition < 0) {
            indexExposure[1] += uint256(-externalPosition);
        } else {
            indexExposure[1] -= uint256(externalPosition);
        }

        vaultRatio = indexExposure[1] * 1e18 / vaultHoldings[1];
    }

    /**
     * @notice Calculates the netted and exposure matrices for the given positions and GLP composition
     * @param externalPosition The external position for the vaults
     * @param indexComposition The index composition as an array of two uint256 values
     * @param indexHeldDollars The GLP held as an array of five uint256 values
     * @return nettedMatrix A 2x2 matrix of netted positions
     * @return exposureMatrix A 2x2 matrix of exposures
     */
    function calculateNettedPositions(
        int256 externalPosition,
        uint256[2] memory indexComposition,
        uint256[2] memory indexHeldDollars
    ) public pure returns (int256[2][2] memory nettedMatrix, int256[2][2] memory exposureMatrix) {
        exposureMatrix[0] = _vaultExposureInt(indexHeldDollars[0], indexComposition);
        exposureMatrix[1] = _vaultExposureInt(indexHeldDollars[1], indexComposition);

        nettedMatrix[0][0] = exposureMatrix[0][0];
        nettedMatrix[1][1] = exposureMatrix[1][1];

        if (externalPosition > 0) {
            nettedMatrix[0][1] = exposureMatrix[0][1] - externalPosition;
            nettedMatrix[1][0] = exposureMatrix[1][0];
        } else {
            nettedMatrix[0][1] = exposureMatrix[0][1];
            nettedMatrix[1][0] = exposureMatrix[1][0] + externalPosition;
        }
    }

    /**
     * @notice Determines whether the given netted state is within the netted threshold
     * @param vaultCumulativeHoldings The current netted state containing GLP held and external positions
     * @param indexComposition The asset somposition of the udnelrying index
     * @param vaultHoldings The amount of the index token allocated to each vault
     * @param externalPosition The external position for the vaults
     * @param nettedThreshold The threshold for the netted amount
     * @return netted if the vaults are balances
     */
    function isNetted(
        uint256 vaultCumulativeHoldings,
        uint256[2] memory indexComposition,
        uint256[2] memory vaultHoldings,
        int256 externalPosition,
        uint256 nettedThreshold
    ) public pure returns (bool netted) {
        uint256[2] memory indexExposure;
        uint256 vaultRatio;
        // if the vault is 0'd out
        if (vaultCumulativeHoldings < 1e18) return true;
        // note positions are NOT scaled up by a factor x to account for counterparty affect when using gmx.
        // here we take the unscaled externalPositions as input
        (indexExposure, vaultRatio) =
            vaultDeltaAdjustment(vaultCumulativeHoldings, indexComposition, vaultHoldings, externalPosition);

        uint256 upper = 1e18 * (10_000 + nettedThreshold) / 10_000;
        uint256 lower = 1e18 * (10_000 - nettedThreshold) / 10_000;
        netted = true;
        if (vaultRatio > upper || vaultRatio < lower) {
            netted = false;
        }
    }

    // INTERNAL
    // ------------------------------------------------------------------------------------------

    function _vaultExposureInt(uint256 glpHeldDollars, uint256[2] memory indexComposition)
        internal
        pure
        returns (int256[2] memory exposure)
    {
        for (uint256 i = 0; i < 2; i++) {
            exposure[i] = SafeCast.toInt256((glpHeldDollars * indexComposition[i]) / 1e18);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IAssetVault {
    function asset() external returns (address);
    function pauseDepositWithdraw() external;
    function unpauseDepositWithdraw() external;
    function depositPaused() external view returns (bool);
    function withdrawalPaused() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./RoleStore.sol";

/**
 * @title RoleModule
 * @dev Contract for role validation functions
 */
contract RoleModule {
    RoleStore public immutable roleStore;

    /**
     * @dev Constructor that initializes the role store for this contract.
     *
     * @param _roleStore The contract instance to use as the role store.
     */
    constructor(RoleStore _roleStore) {
        roleStore = _roleStore;
    }

    /**
     * @dev Only allows the contract's own address to call the function.
     */
    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert Errors.Unauthorized(msg.sender, "SELF");
        }
        _;
    }

    /**
     * @dev Only allows addresses with the TIMELOCK_MULTISIG role to call the function.
     */
    modifier onlyTimelockMultisig() {
        _validateRole(Role.TIMELOCK_MULTISIG, "TIMELOCK_MULTISIG");
        _;
    }

    /**
     * @dev Only allows addresses with the TIMELOCK_ADMIN role to call the function.
     */
    modifier onlyTimelockAdmin() {
        _validateRole(Role.TIMELOCK_ADMIN, "TIMELOCK_ADMIN");
        _;
    }

    /**
     * @dev Only allows addresses with the CONFIG_KEEPER role to call the function.
     */
    modifier onlyConfigKeeper() {
        _validateRole(Role.CONFIG_KEEPER, "CONFIG_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the CONTROLLER role to call the function.
     */
    modifier onlyController() {
        _validateRole(Role.CONTROLLER, "CONTROLLER");
        _;
    }

    /**
     * @dev Only allows addresses with the GOV_TOKEN_CONTROLLER role to call the function.
     */
    modifier onlyGovTokenController() {
        _validateRole(Role.GOV_TOKEN_CONTROLLER, "GOV_TOKEN_CONTROLLER");
        _;
    }

    /**
     * @dev Only allows addresses with the ROUTER_PLUGIN role to call the function.
     */
    modifier onlyRouterPlugin() {
        _validateRole(Role.ROUTER_PLUGIN, "ROUTER_PLUGIN");
        _;
    }

    /**
     * @dev Only allows addresses with the MARKET_KEEPER role to call the function.
     */
    modifier onlyMarketKeeper() {
        _validateRole(Role.MARKET_KEEPER, "MARKET_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the FEE_KEEPER role to call the function.
     */
    modifier onlyFeeKeeper() {
        _validateRole(Role.FEE_KEEPER, "FEE_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the ORDER_KEEPER role to call the function.
     */
    modifier onlyOrderKeeper() {
        _validateRole(Role.ORDER_KEEPER, "ORDER_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the PRICING_KEEPER role to call the function.
     */
    modifier onlyPricingKeeper() {
        _validateRole(Role.PRICING_KEEPER, "PRICING_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the LIQUIDATION_KEEPER role to call the function.
     */
    modifier onlyLiquidationKeeper() {
        _validateRole(Role.LIQUIDATION_KEEPER, "LIQUIDATION_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the ADL_KEEPER role to call the function.
     */
    modifier onlyAdlKeeper() {
        _validateRole(Role.ADL_KEEPER, "ADL_KEEPER");
        _;
    }

    /**
     * @dev Validates that the caller has the specified role.
     *
     * If the caller does not have the specified role, the transaction is reverted.
     *
     * @param role The key of the role to validate.
     * @param roleName The name of the role to validate.
     */
    function _validateRole(bytes32 role, string memory roleName) internal view {
        if (!roleStore.hasRole(msg.sender, role)) {
            revert Errors.Unauthorized(msg.sender, roleName);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "hardhat/console.sol";

/**
 * @title Printer
 * @dev Library for console functions
 */
library Printer {
    using SafeCast for int256;

    function log(string memory label, int256 value) internal view {
        if (value < 0) {
            console.log(
                "%s -%s",
                label,
                (-value).toUint256()
            );
        } else {
            console.log(
                "%s +%s",
                label,
                value.toUint256()
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library EventUtils {
    struct EmitPositionDecreaseParams {
        bytes32 key;
        address account;
        address market;
        address collateralToken;
        bool isLong;
    }

    struct EventLogData {
        AddressItems addressItems;
        UintItems uintItems;
        IntItems intItems;
        BoolItems boolItems;
        Bytes32Items bytes32Items;
        BytesItems bytesItems;
        StringItems stringItems;
    }

    struct AddressItems {
        AddressKeyValue[] items;
        AddressArrayKeyValue[] arrayItems;
    }

    struct UintItems {
        UintKeyValue[] items;
        UintArrayKeyValue[] arrayItems;
    }

    struct IntItems {
        IntKeyValue[] items;
        IntArrayKeyValue[] arrayItems;
    }

    struct BoolItems {
        BoolKeyValue[] items;
        BoolArrayKeyValue[] arrayItems;
    }

    struct Bytes32Items {
        Bytes32KeyValue[] items;
        Bytes32ArrayKeyValue[] arrayItems;
    }

    struct BytesItems {
        BytesKeyValue[] items;
        BytesArrayKeyValue[] arrayItems;
    }

    struct StringItems {
        StringKeyValue[] items;
        StringArrayKeyValue[] arrayItems;
    }

    struct AddressKeyValue {
        string key;
        address value;
    }

    struct AddressArrayKeyValue {
        string key;
        address[] value;
    }

    struct UintKeyValue {
        string key;
        uint256 value;
    }

    struct UintArrayKeyValue {
        string key;
        uint256[] value;
    }

    struct IntKeyValue {
        string key;
        int256 value;
    }

    struct IntArrayKeyValue {
        string key;
        int256[] value;
    }

    struct BoolKeyValue {
        string key;
        bool value;
    }

    struct BoolArrayKeyValue {
        string key;
        bool[] value;
    }

    struct Bytes32KeyValue {
        string key;
        bytes32 value;
    }

    struct Bytes32ArrayKeyValue {
        string key;
        bytes32[] value;
    }

    struct BytesKeyValue {
        string key;
        bytes value;
    }

    struct BytesArrayKeyValue {
        string key;
        bytes[] value;
    }

    struct StringKeyValue {
        string key;
        string value;
    }

    struct StringArrayKeyValue {
        string key;
        string[] value;
    }

    function initItems(AddressItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.AddressKeyValue[](size);
    }

    function initArrayItems(AddressItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.AddressArrayKeyValue[](size);
    }

    function setItem(AddressItems memory items, uint256 index, string memory key, address value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(AddressItems memory items, uint256 index, string memory key, address[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(UintItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.UintKeyValue[](size);
    }

    function initArrayItems(UintItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.UintArrayKeyValue[](size);
    }

    function setItem(UintItems memory items, uint256 index, string memory key, uint256 value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(UintItems memory items, uint256 index, string memory key, uint256[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(IntItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.IntKeyValue[](size);
    }

    function initArrayItems(IntItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.IntArrayKeyValue[](size);
    }

    function setItem(IntItems memory items, uint256 index, string memory key, int256 value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(IntItems memory items, uint256 index, string memory key, int256[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(BoolItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.BoolKeyValue[](size);
    }

    function initArrayItems(BoolItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.BoolArrayKeyValue[](size);
    }

    function setItem(BoolItems memory items, uint256 index, string memory key, bool value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(BoolItems memory items, uint256 index, string memory key, bool[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(Bytes32Items memory items, uint256 size) internal pure {
        items.items = new EventUtils.Bytes32KeyValue[](size);
    }

    function initArrayItems(Bytes32Items memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.Bytes32ArrayKeyValue[](size);
    }

    function setItem(Bytes32Items memory items, uint256 index, string memory key, bytes32 value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(Bytes32Items memory items, uint256 index, string memory key, bytes32[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(BytesItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.BytesKeyValue[](size);
    }

    function initArrayItems(BytesItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.BytesArrayKeyValue[](size);
    }

    function setItem(BytesItems memory items, uint256 index, string memory key, bytes memory value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(BytesItems memory items, uint256 index, string memory key, bytes[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(StringItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.StringKeyValue[](size);
    }

    function initArrayItems(StringItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.StringArrayKeyValue[](size);
    }

    function setItem(StringItems memory items, uint256 index, string memory key, string memory value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(StringItems memory items, uint256 index, string memory key, string[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../token/TokenUtils.sol";
import "../role/RoleModule.sol";

// @title Bank
// @dev Contract to handle storing and transferring of tokens
contract Bank is RoleModule {
    using SafeERC20 for IERC20;

    DataStore public immutable dataStore;

    constructor(RoleStore _roleStore, DataStore _dataStore) RoleModule(_roleStore) {
        dataStore = _dataStore;
    }

    receive() external payable {
        address wnt = TokenUtils.wnt(dataStore);
        if (msg.sender != wnt) {
            revert Errors.InvalidNativeTokenSender(msg.sender);
        }
    }

    // @dev transfer tokens from this contract to a receiver
    //
    // @param token the token to transfer
    // @param amount the amount to transfer
    // @param receiver the address to transfer to
    function transferOut(
        address token,
        address receiver,
        uint256 amount
    ) external onlyController {
        _transferOut(token, receiver, amount);
    }

    // @dev transfer tokens from this contract to a receiver
    // handles native token transfers as well
    //
    // @param token the token to transfer
    // @param amount the amount to transfer
    // @param receiver the address to transfer to
    // @param shouldUnwrapNativeToken whether to unwrap the wrapped native token
    // before transferring
    function transferOut(
        address token,
        address receiver,
        uint256 amount,
        bool shouldUnwrapNativeToken
    ) external onlyController {
        address wnt = TokenUtils.wnt(dataStore);

        if (token == wnt && shouldUnwrapNativeToken) {
            _transferOutNativeToken(token, receiver, amount);
        } else {
            _transferOut(token, receiver, amount);
        }
    }

    // @dev transfer native tokens from this contract to a receiver
    //
    // @param token the token to transfer
    // @param amount the amount to transfer
    // @param receiver the address to transfer to
    // @param shouldUnwrapNativeToken whether to unwrap the wrapped native token
    // before transferring
    function transferOutNativeToken(
        address receiver,
        uint256 amount
    ) external onlyController {
        address wnt = TokenUtils.wnt(dataStore);
        _transferOutNativeToken(wnt, receiver, amount);
    }

    // @dev transfer tokens from this contract to a receiver
    //
    // @param token the token to transfer
    // @param amount the amount to transfer
    // @param receiver the address to transfer to
    function _transferOut(
        address token,
        address receiver,
        uint256 amount
    ) internal {
        if (receiver == address(this)) {
            revert Errors.SelfTransferNotSupported(receiver);
        }

        TokenUtils.transfer(dataStore, token, receiver, amount);

        _afterTransferOut(token);
    }

    // @dev unwrap wrapped native tokens and transfer the native tokens from
    // this contract to a receiver
    //
    // @param token the token to transfer
    // @param amount the amount to transfer
    // @param receiver the address to transfer to
    function _transferOutNativeToken(
        address token,
        address receiver,
        uint256 amount
    ) internal {
        if (receiver == address(this)) {
            revert Errors.SelfTransferNotSupported(receiver);
        }

        TokenUtils.withdrawAndSendNativeToken(
            dataStore,
            token,
            receiver,
            amount
        );

        _afterTransferOut(token);
    }

    function _afterTransferOut(address /* token */) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title Cast
 * @dev Library for casting functions
 */
library Cast {
    function toBytes32(address value) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(value)));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title Keys
// @dev Keys for values in the DataStore
library Keys {
    // @dev key for the address of the wrapped native token
    bytes32 public constant WNT = keccak256(abi.encode("WNT"));
    // @dev key for the nonce value used in NonceUtils
    bytes32 public constant NONCE = keccak256(abi.encode("NONCE"));

    // @dev for sending received fees
    bytes32 public constant FEE_RECEIVER = keccak256(abi.encode("FEE_RECEIVER"));

    // @dev for holding tokens that could not be sent out
    bytes32 public constant HOLDING_ADDRESS = keccak256(abi.encode("HOLDING_ADDRESS"));

    // @dev key for in strict price feed mode
    bytes32 public constant IN_STRICT_PRICE_FEED_MODE = keccak256(abi.encode("IN_STRICT_PRICE_FEED_MODE"));

    // @dev key for the minimum gas for execution error
    bytes32 public constant MIN_HANDLE_EXECUTION_ERROR_GAS = keccak256(abi.encode("MIN_HANDLE_EXECUTION_ERROR_GAS"));

    // @dev key for the minimum gas that should be forwarded for execution error handling
    bytes32 public constant MIN_HANDLE_EXECUTION_ERROR_GAS_TO_FORWARD = keccak256(abi.encode("MIN_HANDLE_EXECUTION_ERROR_GAS_TO_FORWARD"));

    // @dev key for the min additional gas for execution
    bytes32 public constant MIN_ADDITIONAL_GAS_FOR_EXECUTION = keccak256(abi.encode("MIN_ADDITIONAL_GAS_FOR_EXECUTION"));

    // @dev for a global reentrancy guard
    bytes32 public constant REENTRANCY_GUARD_STATUS = keccak256(abi.encode("REENTRANCY_GUARD_STATUS"));

    // @dev key for deposit fees
    bytes32 public constant DEPOSIT_FEE_TYPE = keccak256(abi.encode("DEPOSIT_FEE_TYPE"));
    // @dev key for withdrawal fees
    bytes32 public constant WITHDRAWAL_FEE_TYPE = keccak256(abi.encode("WITHDRAWAL_FEE_TYPE"));
    // @dev key for swap fees
    bytes32 public constant SWAP_FEE_TYPE = keccak256(abi.encode("SWAP_FEE_TYPE"));
    // @dev key for position fees
    bytes32 public constant POSITION_FEE_TYPE = keccak256(abi.encode("POSITION_FEE_TYPE"));
    // @dev key for ui deposit fees
    bytes32 public constant UI_DEPOSIT_FEE_TYPE = keccak256(abi.encode("UI_DEPOSIT_FEE_TYPE"));
    // @dev key for ui withdrawal fees
    bytes32 public constant UI_WITHDRAWAL_FEE_TYPE = keccak256(abi.encode("UI_WITHDRAWAL_FEE_TYPE"));
    // @dev key for ui swap fees
    bytes32 public constant UI_SWAP_FEE_TYPE = keccak256(abi.encode("UI_SWAP_FEE_TYPE"));
    // @dev key for ui position fees
    bytes32 public constant UI_POSITION_FEE_TYPE = keccak256(abi.encode("UI_POSITION_FEE_TYPE"));

    // @dev key for ui fee factor
    bytes32 public constant UI_FEE_FACTOR = keccak256(abi.encode("UI_FEE_FACTOR"));
    // @dev key for max ui fee receiver factor
    bytes32 public constant MAX_UI_FEE_FACTOR = keccak256(abi.encode("MAX_UI_FEE_FACTOR"));

    // @dev key for the claimable fee amount
    bytes32 public constant CLAIMABLE_FEE_AMOUNT = keccak256(abi.encode("CLAIMABLE_FEE_AMOUNT"));
    // @dev key for the claimable ui fee amount
    bytes32 public constant CLAIMABLE_UI_FEE_AMOUNT = keccak256(abi.encode("CLAIMABLE_UI_FEE_AMOUNT"));

    // @dev key for the market list
    bytes32 public constant MARKET_LIST = keccak256(abi.encode("MARKET_LIST"));

    // @dev key for the deposit list
    bytes32 public constant DEPOSIT_LIST = keccak256(abi.encode("DEPOSIT_LIST"));
    // @dev key for the account deposit list
    bytes32 public constant ACCOUNT_DEPOSIT_LIST = keccak256(abi.encode("ACCOUNT_DEPOSIT_LIST"));

    // @dev key for the withdrawal list
    bytes32 public constant WITHDRAWAL_LIST = keccak256(abi.encode("WITHDRAWAL_LIST"));
    // @dev key for the account withdrawal list
    bytes32 public constant ACCOUNT_WITHDRAWAL_LIST = keccak256(abi.encode("ACCOUNT_WITHDRAWAL_LIST"));

    // @dev key for the position list
    bytes32 public constant POSITION_LIST = keccak256(abi.encode("POSITION_LIST"));
    // @dev key for the account position list
    bytes32 public constant ACCOUNT_POSITION_LIST = keccak256(abi.encode("ACCOUNT_POSITION_LIST"));

    // @dev key for the order list
    bytes32 public constant ORDER_LIST = keccak256(abi.encode("ORDER_LIST"));
    // @dev key for the account order list
    bytes32 public constant ACCOUNT_ORDER_LIST = keccak256(abi.encode("ACCOUNT_ORDER_LIST"));

    // @dev key for the subaccount list
    bytes32 public constant SUBACCOUNT_LIST = keccak256(abi.encode("SUBACCOUNT_LIST"));

    // @dev key for is market disabled
    bytes32 public constant IS_MARKET_DISABLED = keccak256(abi.encode("IS_MARKET_DISABLED"));

    // @dev key for the max swap path length allowed
    bytes32 public constant MAX_SWAP_PATH_LENGTH = keccak256(abi.encode("MAX_SWAP_PATH_LENGTH"));
    // @dev key used to store markets observed in a swap path, to ensure that a swap path contains unique markets
    bytes32 public constant SWAP_PATH_MARKET_FLAG = keccak256(abi.encode("SWAP_PATH_MARKET_FLAG"));
    // @dev key used to store the min market tokens for the first deposit for a market
    bytes32 public constant MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT = keccak256(abi.encode("MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT"));

    // @dev key for whether the create deposit feature is disabled
    bytes32 public constant CREATE_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("CREATE_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the cancel deposit feature is disabled
    bytes32 public constant CANCEL_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the execute deposit feature is disabled
    bytes32 public constant EXECUTE_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_DEPOSIT_FEATURE_DISABLED"));

    // @dev key for whether the create withdrawal feature is disabled
    bytes32 public constant CREATE_WITHDRAWAL_FEATURE_DISABLED = keccak256(abi.encode("CREATE_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the cancel withdrawal feature is disabled
    bytes32 public constant CANCEL_WITHDRAWAL_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the execute withdrawal feature is disabled
    bytes32 public constant EXECUTE_WITHDRAWAL_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_WITHDRAWAL_FEATURE_DISABLED"));

    // @dev key for whether the create order feature is disabled
    bytes32 public constant CREATE_ORDER_FEATURE_DISABLED = keccak256(abi.encode("CREATE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the execute order feature is disabled
    bytes32 public constant EXECUTE_ORDER_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the execute adl feature is disabled
    // for liquidations, it can be disabled by using the EXECUTE_ORDER_FEATURE_DISABLED key with the Liquidation
    // order type, ADL orders have a MarketDecrease order type, so a separate key is needed to disable it
    bytes32 public constant EXECUTE_ADL_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_ADL_FEATURE_DISABLED"));
    // @dev key for whether the update order feature is disabled
    bytes32 public constant UPDATE_ORDER_FEATURE_DISABLED = keccak256(abi.encode("UPDATE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the cancel order feature is disabled
    bytes32 public constant CANCEL_ORDER_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_ORDER_FEATURE_DISABLED"));

    // @dev key for whether the claim funding fees feature is disabled
    bytes32 public constant CLAIM_FUNDING_FEES_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_FUNDING_FEES_FEATURE_DISABLED"));
    // @dev key for whether the claim collateral feature is disabled
    bytes32 public constant CLAIM_COLLATERAL_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_COLLATERAL_FEATURE_DISABLED"));
    // @dev key for whether the claim affiliate rewards feature is disabled
    bytes32 public constant CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED"));
    // @dev key for whether the claim ui fees feature is disabled
    bytes32 public constant CLAIM_UI_FEES_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_UI_FEES_FEATURE_DISABLED"));
    // @dev key for whether the subaccount feature is disabled
    bytes32 public constant SUBACCOUNT_FEATURE_DISABLED = keccak256(abi.encode("SUBACCOUNT_FEATURE_DISABLED"));

    // @dev key for the minimum required oracle signers for an oracle observation
    bytes32 public constant MIN_ORACLE_SIGNERS = keccak256(abi.encode("MIN_ORACLE_SIGNERS"));
    // @dev key for the minimum block confirmations before blockhash can be excluded for oracle signature validation
    bytes32 public constant MIN_ORACLE_BLOCK_CONFIRMATIONS = keccak256(abi.encode("MIN_ORACLE_BLOCK_CONFIRMATIONS"));
    // @dev key for the maximum usable oracle price age in seconds
    bytes32 public constant MAX_ORACLE_PRICE_AGE = keccak256(abi.encode("MAX_ORACLE_PRICE_AGE"));
    // @dev key for the maximum oracle price deviation factor from the ref price
    bytes32 public constant MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR = keccak256(abi.encode("MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR"));
    // @dev key for the percentage amount of position fees to be received
    bytes32 public constant POSITION_FEE_RECEIVER_FACTOR = keccak256(abi.encode("POSITION_FEE_RECEIVER_FACTOR"));
    // @dev key for the percentage amount of swap fees to be received
    bytes32 public constant SWAP_FEE_RECEIVER_FACTOR = keccak256(abi.encode("SWAP_FEE_RECEIVER_FACTOR"));
    // @dev key for the percentage amount of borrowing fees to be received
    bytes32 public constant BORROWING_FEE_RECEIVER_FACTOR = keccak256(abi.encode("BORROWING_FEE_RECEIVER_FACTOR"));

    // @dev key for the base gas limit used when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_BASE_AMOUNT = keccak256(abi.encode("ESTIMATED_GAS_FEE_BASE_AMOUNT"));
    // @dev key for the multiplier used when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR = keccak256(abi.encode("ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR"));

    // @dev key for the base gas limit used when calculating execution fee
    bytes32 public constant EXECUTION_GAS_FEE_BASE_AMOUNT = keccak256(abi.encode("EXECUTION_GAS_FEE_BASE_AMOUNT"));
    // @dev key for the multiplier used when calculating execution fee
    bytes32 public constant EXECUTION_GAS_FEE_MULTIPLIER_FACTOR = keccak256(abi.encode("EXECUTION_GAS_FEE_MULTIPLIER_FACTOR"));

    // @dev key for the estimated gas limit for deposits
    bytes32 public constant DEPOSIT_GAS_LIMIT = keccak256(abi.encode("DEPOSIT_GAS_LIMIT"));
    // @dev key for the estimated gas limit for withdrawals
    bytes32 public constant WITHDRAWAL_GAS_LIMIT = keccak256(abi.encode("WITHDRAWAL_GAS_LIMIT"));
    // @dev key for the estimated gas limit for single swaps
    bytes32 public constant SINGLE_SWAP_GAS_LIMIT = keccak256(abi.encode("SINGLE_SWAP_GAS_LIMIT"));
    // @dev key for the estimated gas limit for increase orders
    bytes32 public constant INCREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("INCREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for decrease orders
    bytes32 public constant DECREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("DECREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for swap orders
    bytes32 public constant SWAP_ORDER_GAS_LIMIT = keccak256(abi.encode("SWAP_ORDER_GAS_LIMIT"));
    // @dev key for the amount of gas to forward for token transfers
    bytes32 public constant TOKEN_TRANSFER_GAS_LIMIT = keccak256(abi.encode("TOKEN_TRANSFER_GAS_LIMIT"));
    // @dev key for the amount of gas to forward for native token transfers
    bytes32 public constant NATIVE_TOKEN_TRANSFER_GAS_LIMIT = keccak256(abi.encode("NATIVE_TOKEN_TRANSFER_GAS_LIMIT"));
    // @dev key for the maximum request block age, after which the request will be considered expired
    bytes32 public constant REQUEST_EXPIRATION_BLOCK_AGE = keccak256(abi.encode("REQUEST_EXPIRATION_BLOCK_AGE"));

    bytes32 public constant MAX_CALLBACK_GAS_LIMIT = keccak256(abi.encode("MAX_CALLBACK_GAS_LIMIT"));
    bytes32 public constant SAVED_CALLBACK_CONTRACT = keccak256(abi.encode("SAVED_CALLBACK_CONTRACT"));

    // @dev key for the min collateral factor
    bytes32 public constant MIN_COLLATERAL_FACTOR = keccak256(abi.encode("MIN_COLLATERAL_FACTOR"));
    // @dev key for the min collateral factor for open interest multiplier
    bytes32 public constant MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER = keccak256(abi.encode("MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER"));
    // @dev key for the min allowed collateral in USD
    bytes32 public constant MIN_COLLATERAL_USD = keccak256(abi.encode("MIN_COLLATERAL_USD"));
    // @dev key for the min allowed position size in USD
    bytes32 public constant MIN_POSITION_SIZE_USD = keccak256(abi.encode("MIN_POSITION_SIZE_USD"));

    // @dev key for the virtual id of tokens
    bytes32 public constant VIRTUAL_TOKEN_ID = keccak256(abi.encode("VIRTUAL_TOKEN_ID"));
    // @dev key for the virtual id of markets
    bytes32 public constant VIRTUAL_MARKET_ID = keccak256(abi.encode("VIRTUAL_MARKET_ID"));
    // @dev key for the virtual inventory for swaps
    bytes32 public constant VIRTUAL_INVENTORY_FOR_SWAPS = keccak256(abi.encode("VIRTUAL_INVENTORY_FOR_SWAPS"));
    // @dev key for the virtual inventory for positions
    bytes32 public constant VIRTUAL_INVENTORY_FOR_POSITIONS = keccak256(abi.encode("VIRTUAL_INVENTORY_FOR_POSITIONS"));

    // @dev key for the position impact factor
    bytes32 public constant POSITION_IMPACT_FACTOR = keccak256(abi.encode("POSITION_IMPACT_FACTOR"));
    // @dev key for the position impact exponent factor
    bytes32 public constant POSITION_IMPACT_EXPONENT_FACTOR = keccak256(abi.encode("POSITION_IMPACT_EXPONENT_FACTOR"));
    // @dev key for the max decrease position impact factor
    bytes32 public constant MAX_POSITION_IMPACT_FACTOR = keccak256(abi.encode("MAX_POSITION_IMPACT_FACTOR"));
    // @dev key for the max position impact factor for liquidations
    bytes32 public constant MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS = keccak256(abi.encode("MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS"));
    // @dev key for the position fee factor
    bytes32 public constant POSITION_FEE_FACTOR = keccak256(abi.encode("POSITION_FEE_FACTOR"));
    // @dev key for the swap impact factor
    bytes32 public constant SWAP_IMPACT_FACTOR = keccak256(abi.encode("SWAP_IMPACT_FACTOR"));
    // @dev key for the swap impact exponent factor
    bytes32 public constant SWAP_IMPACT_EXPONENT_FACTOR = keccak256(abi.encode("SWAP_IMPACT_EXPONENT_FACTOR"));
    // @dev key for the swap fee factor
    bytes32 public constant SWAP_FEE_FACTOR = keccak256(abi.encode("SWAP_FEE_FACTOR"));
    // @dev key for the oracle type
    bytes32 public constant ORACLE_TYPE = keccak256(abi.encode("ORACLE_TYPE"));
    // @dev key for open interest
    bytes32 public constant OPEN_INTEREST = keccak256(abi.encode("OPEN_INTEREST"));
    // @dev key for open interest in tokens
    bytes32 public constant OPEN_INTEREST_IN_TOKENS = keccak256(abi.encode("OPEN_INTEREST_IN_TOKENS"));
    // @dev key for collateral sum for a market
    bytes32 public constant COLLATERAL_SUM = keccak256(abi.encode("COLLATERAL_SUM"));
    // @dev key for pool amount
    bytes32 public constant POOL_AMOUNT = keccak256(abi.encode("POOL_AMOUNT"));
    // @dev key for max pool amount
    bytes32 public constant MAX_POOL_AMOUNT = keccak256(abi.encode("MAX_POOL_AMOUNT"));
    // @dev key for max pool amount for deposit
    bytes32 public constant MAX_POOL_AMOUNT_FOR_DEPOSIT = keccak256(abi.encode("MAX_POOL_AMOUNT_FOR_DEPOSIT"));
    // @dev key for max open interest
    bytes32 public constant MAX_OPEN_INTEREST = keccak256(abi.encode("MAX_OPEN_INTEREST"));
    // @dev key for position impact pool amount
    bytes32 public constant POSITION_IMPACT_POOL_AMOUNT = keccak256(abi.encode("POSITION_IMPACT_POOL_AMOUNT"));
    // @dev key for min position impact pool amount
    bytes32 public constant MIN_POSITION_IMPACT_POOL_AMOUNT = keccak256(abi.encode("MIN_POSITION_IMPACT_POOL_AMOUNT"));
    // @dev key for position impact pool distribution rate
    bytes32 public constant POSITION_IMPACT_POOL_DISTRIBUTION_RATE = keccak256(abi.encode("POSITION_IMPACT_POOL_DISTRIBUTION_RATE"));
    // @dev key for position impact pool distributed at
    bytes32 public constant POSITION_IMPACT_POOL_DISTRIBUTED_AT = keccak256(abi.encode("POSITION_IMPACT_POOL_DISTRIBUTED_AT"));
    // @dev key for swap impact pool amount
    bytes32 public constant SWAP_IMPACT_POOL_AMOUNT = keccak256(abi.encode("SWAP_IMPACT_POOL_AMOUNT"));
    // @dev key for price feed
    bytes32 public constant PRICE_FEED = keccak256(abi.encode("PRICE_FEED"));
    // @dev key for price feed multiplier
    bytes32 public constant PRICE_FEED_MULTIPLIER = keccak256(abi.encode("PRICE_FEED_MULTIPLIER"));
    // @dev key for price feed heartbeat
    bytes32 public constant PRICE_FEED_HEARTBEAT_DURATION = keccak256(abi.encode("PRICE_FEED_HEARTBEAT_DURATION"));
    // @dev key for realtime feed id
    bytes32 public constant REALTIME_FEED_ID = keccak256(abi.encode("REALTIME_FEED_ID"));
    // @dev key for realtime feed multipler
    bytes32 public constant REALTIME_FEED_MULTIPLIER = keccak256(abi.encode("REALTIME_FEED_MULTIPLIER"));
    // @dev key for stable price
    bytes32 public constant STABLE_PRICE = keccak256(abi.encode("STABLE_PRICE"));
    // @dev key for reserve factor
    bytes32 public constant RESERVE_FACTOR = keccak256(abi.encode("RESERVE_FACTOR"));
    // @dev key for open interest reserve factor
    bytes32 public constant OPEN_INTEREST_RESERVE_FACTOR = keccak256(abi.encode("OPEN_INTEREST_RESERVE_FACTOR"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR = keccak256(abi.encode("MAX_PNL_FACTOR"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR_FOR_TRADERS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_TRADERS"));
    // @dev key for max pnl factor for adl
    bytes32 public constant MAX_PNL_FACTOR_FOR_ADL = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_ADL"));
    // @dev key for min pnl factor for adl
    bytes32 public constant MIN_PNL_FACTOR_AFTER_ADL = keccak256(abi.encode("MIN_PNL_FACTOR_AFTER_ADL"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR_FOR_DEPOSITS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_DEPOSITS"));
    // @dev key for max pnl factor for withdrawals
    bytes32 public constant MAX_PNL_FACTOR_FOR_WITHDRAWALS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS"));
    // @dev key for latest ADL block
    bytes32 public constant LATEST_ADL_BLOCK = keccak256(abi.encode("LATEST_ADL_BLOCK"));
    // @dev key for whether ADL is enabled
    bytes32 public constant IS_ADL_ENABLED = keccak256(abi.encode("IS_ADL_ENABLED"));
    // @dev key for funding factor
    bytes32 public constant FUNDING_FACTOR = keccak256(abi.encode("FUNDING_FACTOR"));
    // @dev key for funding exponent factor
    bytes32 public constant FUNDING_EXPONENT_FACTOR = keccak256(abi.encode("FUNDING_EXPONENT_FACTOR"));
    // @dev key for saved funding factor
    bytes32 public constant SAVED_FUNDING_FACTOR_PER_SECOND = keccak256(abi.encode("SAVED_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for funding increase factor
    bytes32 public constant FUNDING_INCREASE_FACTOR_PER_SECOND = keccak256(abi.encode("FUNDING_INCREASE_FACTOR_PER_SECOND"));
    // @dev key for funding decrease factor
    bytes32 public constant FUNDING_DECREASE_FACTOR_PER_SECOND = keccak256(abi.encode("FUNDING_DECREASE_FACTOR_PER_SECOND"));
    // @dev key for min funding factor
    bytes32 public constant MIN_FUNDING_FACTOR_PER_SECOND = keccak256(abi.encode("MIN_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for max funding factor
    bytes32 public constant MAX_FUNDING_FACTOR_PER_SECOND = keccak256(abi.encode("MAX_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for threshold for stable funding
    bytes32 public constant THRESHOLD_FOR_STABLE_FUNDING = keccak256(abi.encode("THRESHOLD_FOR_STABLE_FUNDING"));
    // @dev key for threshold for decrease funding
    bytes32 public constant THRESHOLD_FOR_DECREASE_FUNDING = keccak256(abi.encode("THRESHOLD_FOR_DECREASE_FUNDING"));
    // @dev key for funding fee amount per size
    bytes32 public constant FUNDING_FEE_AMOUNT_PER_SIZE = keccak256(abi.encode("FUNDING_FEE_AMOUNT_PER_SIZE"));
    // @dev key for claimable funding amount per size
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT_PER_SIZE = keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT_PER_SIZE"));
    // @dev key for when funding was last updated at
    bytes32 public constant FUNDING_UPDATED_AT = keccak256(abi.encode("FUNDING_UPDATED_AT"));
    // @dev key for claimable funding amount
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT = keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT"));
    // @dev key for claimable collateral amount
    bytes32 public constant CLAIMABLE_COLLATERAL_AMOUNT = keccak256(abi.encode("CLAIMABLE_COLLATERAL_AMOUNT"));
    // @dev key for claimable collateral factor
    bytes32 public constant CLAIMABLE_COLLATERAL_FACTOR = keccak256(abi.encode("CLAIMABLE_COLLATERAL_FACTOR"));
    // @dev key for claimable collateral time divisor
    bytes32 public constant CLAIMABLE_COLLATERAL_TIME_DIVISOR = keccak256(abi.encode("CLAIMABLE_COLLATERAL_TIME_DIVISOR"));
    // @dev key for claimed collateral amount
    bytes32 public constant CLAIMED_COLLATERAL_AMOUNT = keccak256(abi.encode("CLAIMED_COLLATERAL_AMOUNT"));
    // @dev key for borrowing factor
    bytes32 public constant BORROWING_FACTOR = keccak256(abi.encode("BORROWING_FACTOR"));
    // @dev key for borrowing factor
    bytes32 public constant BORROWING_EXPONENT_FACTOR = keccak256(abi.encode("BORROWING_EXPONENT_FACTOR"));
    // @dev key for skipping the borrowing factor for the smaller side
    bytes32 public constant SKIP_BORROWING_FEE_FOR_SMALLER_SIDE = keccak256(abi.encode("SKIP_BORROWING_FEE_FOR_SMALLER_SIDE"));
    // @dev key for cumulative borrowing factor
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR = keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR"));
    // @dev key for when the cumulative borrowing factor was last updated at
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR_UPDATED_AT = keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR_UPDATED_AT"));
    // @dev key for total borrowing amount
    bytes32 public constant TOTAL_BORROWING = keccak256(abi.encode("TOTAL_BORROWING"));
    // @dev key for affiliate reward
    bytes32 public constant AFFILIATE_REWARD = keccak256(abi.encode("AFFILIATE_REWARD"));
    // @dev key for max allowed subaccount action count
    bytes32 public constant MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT = keccak256(abi.encode("MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT"));
    // @dev key for subaccount action count
    bytes32 public constant SUBACCOUNT_ACTION_COUNT = keccak256(abi.encode("SUBACCOUNT_ACTION_COUNT"));
    // @dev key for subaccount auto top up amount
    bytes32 public constant SUBACCOUNT_AUTO_TOP_UP_AMOUNT = keccak256(abi.encode("SUBACCOUNT_AUTO_TOP_UP_AMOUNT"));
    // @dev key for subaccount order action
    bytes32 public constant SUBACCOUNT_ORDER_ACTION = keccak256(abi.encode("SUBACCOUNT_ORDER_ACTION"));

    // @dev constant for user initiated cancel reason
    string public constant USER_INITIATED_CANCEL = "USER_INITIATED_CANCEL";

    // @dev key for the account deposit list
    // @param account the account for the list
    function accountDepositListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_DEPOSIT_LIST, account));
    }

    // @dev key for the account withdrawal list
    // @param account the account for the list
    function accountWithdrawalListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_WITHDRAWAL_LIST, account));
    }

    // @dev key for the account position list
    // @param account the account for the list
    function accountPositionListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_POSITION_LIST, account));
    }

    // @dev key for the account order list
    // @param account the account for the list
    function accountOrderListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_ORDER_LIST, account));
    }

    // @dev key for the subaccount list
    // @param account the account for the list
    function subaccountListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(SUBACCOUNT_LIST, account));
    }

    // @dev key for the claimable fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    function claimableFeeAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_FEE_AMOUNT, market, token));
    }

    // @dev key for the claimable ui fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    // @param account the account that can claim the ui fee
    function claimableUiFeeAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_UI_FEE_AMOUNT, market, token));
    }

    // @dev key for the claimable ui fee amount for account
    // @param market the market for the fee
    // @param token the token for the fee
    // @param account the account that can claim the ui fee
    function claimableUiFeeAmountKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_UI_FEE_AMOUNT, market, token, account));
    }

    // @dev key for deposit gas limit
    // @param singleToken whether a single token or pair tokens are being deposited
    // @return key for deposit gas limit
    function depositGasLimitKey(bool singleToken) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            DEPOSIT_GAS_LIMIT,
            singleToken
        ));
    }

    // @dev key for withdrawal gas limit
    // @return key for withdrawal gas limit
    function withdrawalGasLimitKey() internal pure returns (bytes32) {
        return keccak256(abi.encode(
            WITHDRAWAL_GAS_LIMIT
        ));
    }

    // @dev key for single swap gas limit
    // @return key for single swap gas limit
    function singleSwapGasLimitKey() internal pure returns (bytes32) {
        return SINGLE_SWAP_GAS_LIMIT;
    }

    // @dev key for increase order gas limit
    // @return key for increase order gas limit
    function increaseOrderGasLimitKey() internal pure returns (bytes32) {
        return INCREASE_ORDER_GAS_LIMIT;
    }

    // @dev key for decrease order gas limit
    // @return key for decrease order gas limit
    function decreaseOrderGasLimitKey() internal pure returns (bytes32) {
        return DECREASE_ORDER_GAS_LIMIT;
    }

    // @dev key for swap order gas limit
    // @return key for swap order gas limit
    function swapOrderGasLimitKey() internal pure returns (bytes32) {
        return SWAP_ORDER_GAS_LIMIT;
    }

    function swapPathMarketFlagKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_PATH_MARKET_FLAG,
            market
        ));
    }

    // @dev key for whether create deposit is disabled
    // @param the create deposit module
    // @return key for whether create deposit is disabled
    function createDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether cancel deposit is disabled
    // @param the cancel deposit module
    // @return key for whether cancel deposit is disabled
    function cancelDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether execute deposit is disabled
    // @param the execute deposit module
    // @return key for whether execute deposit is disabled
    function executeDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether create withdrawal is disabled
    // @param the create withdrawal module
    // @return key for whether create withdrawal is disabled
    function createWithdrawalFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_WITHDRAWAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether cancel withdrawal is disabled
    // @param the cancel withdrawal module
    // @return key for whether cancel withdrawal is disabled
    function cancelWithdrawalFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_WITHDRAWAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether execute withdrawal is disabled
    // @param the execute withdrawal module
    // @return key for whether execute withdrawal is disabled
    function executeWithdrawalFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_WITHDRAWAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether create order is disabled
    // @param the create order module
    // @return key for whether create order is disabled
    function createOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether execute order is disabled
    // @param the execute order module
    // @return key for whether execute order is disabled
    function executeOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether execute adl is disabled
    // @param the execute adl module
    // @return key for whether execute adl is disabled
    function executeAdlFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_ADL_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether update order is disabled
    // @param the update order module
    // @return key for whether update order is disabled
    function updateOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            UPDATE_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether cancel order is disabled
    // @param the cancel order module
    // @return key for whether cancel order is disabled
    function cancelOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether claim funding fees is disabled
    // @param the claim funding fees module
    function claimFundingFeesFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_FUNDING_FEES_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether claim colltareral is disabled
    // @param the claim funding fees module
    function claimCollateralFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_COLLATERAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether claim affiliate rewards is disabled
    // @param the claim affiliate rewards module
    function claimAffiliateRewardsFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether claim ui fees is disabled
    // @param the claim ui fees module
    function claimUiFeesFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_UI_FEES_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether subaccounts are disabled
    // @param the subaccount module
    function subaccountFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SUBACCOUNT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for ui fee factor
    // @param account the fee receiver account
    // @return key for ui fee factor
    function uiFeeFactorKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            UI_FEE_FACTOR,
            account
        ));
    }

    // @dev key for gas to forward for token transfer
    // @param the token to check
    // @return key for gas to forward for token transfer
    function tokenTransferGasLimit(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TOKEN_TRANSFER_GAS_LIMIT,
            token
        ));
   }

   // @dev the default callback contract
   // @param account the user's account
   // @param market the address of the market
   // @param callbackContract the callback contract
   function savedCallbackContract(address account, address market) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           SAVED_CALLBACK_CONTRACT,
           account,
           market
       ));
   }

   // @dev the min collateral factor key
   // @param the market for the min collateral factor
   function minCollateralFactorKey(address market) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           MIN_COLLATERAL_FACTOR,
           market
       ));
   }

   // @dev the min collateral factor for open interest multiplier key
   // @param the market for the factor
   function minCollateralFactorForOpenInterestMultiplierKey(address market, bool isLong) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER,
           market,
           isLong
       ));
   }

   // @dev the key for the virtual token id
   // @param the token to get the virtual id for
   function virtualTokenIdKey(address token) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_TOKEN_ID,
           token
       ));
   }

   // @dev the key for the virtual market id
   // @param the market to get the virtual id for
   function virtualMarketIdKey(address market) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_MARKET_ID,
           market
       ));
   }

   // @dev the key for the virtual inventory for positions
   // @param the virtualTokenId the virtual token id
   function virtualInventoryForPositionsKey(bytes32 virtualTokenId) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_INVENTORY_FOR_POSITIONS,
           virtualTokenId
       ));
   }

   // @dev the key for the virtual inventory for swaps
   // @param the virtualMarketId the virtual market id
   // @param the token to check the inventory for
   function virtualInventoryForSwapsKey(bytes32 virtualMarketId, bool isLongToken) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_INVENTORY_FOR_SWAPS,
           virtualMarketId,
           isLongToken
       ));
   }

    // @dev key for position impact factor
    // @param market the market address to check
    // @param isPositive whether the impact is positive or negative
    // @return key for position impact factor
    function positionImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_FACTOR,
            market,
            isPositive
        ));
   }

    // @dev key for position impact exponent factor
    // @param market the market address to check
    // @return key for position impact exponent factor
    function positionImpactExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_EXPONENT_FACTOR,
            market
        ));
    }

    // @dev key for the max position impact factor
    // @param market the market address to check
    // @return key for the max position impact factor
    function maxPositionImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POSITION_IMPACT_FACTOR,
            market,
            isPositive
        ));
    }

    // @dev key for the max position impact factor for liquidations
    // @param market the market address to check
    // @return key for the max position impact factor
    function maxPositionImpactFactorForLiquidationsKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS,
            market
        ));
    }

    // @dev key for position fee factor
    // @param market the market address to check
    // @param forPositiveImpact whether the fee is for an action that has a positive price impact
    // @return key for position fee factor
    function positionFeeFactorKey(address market, bool forPositiveImpact) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_FEE_FACTOR,
            market,
            forPositiveImpact
        ));
    }

    // @dev key for swap impact factor
    // @param market the market address to check
    // @param isPositive whether the impact is positive or negative
    // @return key for swap impact factor
    function swapImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_FACTOR,
            market,
            isPositive
        ));
    }

    // @dev key for swap impact exponent factor
    // @param market the market address to check
    // @return key for swap impact exponent factor
    function swapImpactExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_EXPONENT_FACTOR,
            market
        ));
    }


    // @dev key for swap fee factor
    // @param market the market address to check
    // @return key for swap fee factor
    function swapFeeFactorKey(address market, bool forPositiveImpact) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_FEE_FACTOR,
            market,
            forPositiveImpact
        ));
    }

    // @dev key for oracle type
    // @param token the token to check
    // @return key for oracle type
    function oracleTypeKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORACLE_TYPE,
            token
        ));
    }

    // @dev key for open interest
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest
    function openInterestKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for open interest in tokens
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest in tokens
    function openInterestInTokensKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST_IN_TOKENS,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for collateral sum for a market
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for collateral sum
    function collateralSumKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            COLLATERAL_SUM,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for amount of tokens in a market's pool
    // @param market the market to check
    // @param token the token to check
    // @return key for amount of tokens in a market's pool
    function poolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POOL_AMOUNT,
            market,
            token
        ));
    }

    // @dev the key for the max amount of pool tokens
    // @param market the market for the pool
    // @param token the token for the pool
    function maxPoolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POOL_AMOUNT,
            market,
            token
        ));
    }

    // @dev the key for the max amount of pool tokens for deposits
    // @param market the market for the pool
    // @param token the token for the pool
    function maxPoolAmountForDepositKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POOL_AMOUNT_FOR_DEPOSIT,
            market,
            token
        ));
    }

    // @dev the key for the max open interest
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function maxOpenInterestKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_OPEN_INTEREST,
            market,
            isLong
        ));
    }

    // @dev key for amount of tokens in a market's position impact pool
    // @param market the market to check
    // @return key for amount of tokens in a market's position impact pool
    function positionImpactPoolAmountKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_POOL_AMOUNT,
            market
        ));
    }

    // @dev key for min amount of tokens in a market's position impact pool
    // @param market the market to check
    // @return key for min amount of tokens in a market's position impact pool
    function minPositionImpactPoolAmountKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_POSITION_IMPACT_POOL_AMOUNT,
            market
        ));
    }

    // @dev key for position impact pool distribution rate
    // @param market the market to check
    // @return key for position impact pool distribution rate
    function positionImpactPoolDistributionRateKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_POOL_DISTRIBUTION_RATE,
            market
        ));
    }

    // @dev key for position impact pool distributed at
    // @param market the market to check
    // @return key for position impact pool distributed at
    function positionImpactPoolDistributedAtKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_POOL_DISTRIBUTED_AT,
            market
        ));
    }

    // @dev key for amount of tokens in a market's swap impact pool
    // @param market the market to check
    // @param token the token to check
    // @return key for amount of tokens in a market's swap impact pool
    function swapImpactPoolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_POOL_AMOUNT,
            market,
            token
        ));
    }

    // @dev key for reserve factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for reserve factor
    function reserveFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            RESERVE_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for open interest reserve factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for open interest reserve factor
    function openInterestReserveFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST_RESERVE_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for max pnl factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for max pnl factor
    function maxPnlFactorKey(bytes32 pnlFactorType, address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_PNL_FACTOR,
            pnlFactorType,
            market,
            isLong
        ));
    }

    // @dev the key for min PnL factor after ADL
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function minPnlFactorAfterAdlKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_PNL_FACTOR_AFTER_ADL,
            market,
            isLong
        ));
    }

    // @dev key for latest adl block
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for latest adl block
    function latestAdlBlockKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            LATEST_ADL_BLOCK,
            market,
            isLong
        ));
    }

    // @dev key for whether adl is enabled
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for whether adl is enabled
    function isAdlEnabledKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            IS_ADL_ENABLED,
            market,
            isLong
        ));
    }

    // @dev key for funding factor
    // @param market the market to check
    // @return key for funding factor
    function fundingFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_FACTOR,
            market
        ));
    }

    // @dev the key for funding exponent
    // @param market the market for the pool
    function fundingExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_EXPONENT_FACTOR,
            market
        ));
    }

    // @dev the key for saved funding factor
    // @param market the market for the pool
    function savedFundingFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SAVED_FUNDING_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for funding increase factor
    // @param market the market for the pool
    function fundingIncreaseFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_INCREASE_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for funding decrease factor
    // @param market the market for the pool
    function fundingDecreaseFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_DECREASE_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for min funding factor
    // @param market the market for the pool
    function minFundingFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_FUNDING_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for max funding factor
    // @param market the market for the pool
    function maxFundingFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_FUNDING_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for threshold for stable funding
    // @param market the market for the pool
    function thresholdForStableFundingKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            THRESHOLD_FOR_STABLE_FUNDING,
            market
        ));
    }

    // @dev the key for threshold for decreasing funding
    // @param market the market for the pool
    function thresholdForDecreaseFundingKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            THRESHOLD_FOR_DECREASE_FUNDING,
            market
        ));
    }

    // @dev key for funding fee amount per size
    // @param market the market to check
    // @param collateralToken the collateralToken to get the key for
    // @param isLong whether to get the key for the long or short side
    // @return key for funding fee amount per size
    function fundingFeeAmountPerSizeKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_FEE_AMOUNT_PER_SIZE,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for claimabel funding amount per size
    // @param market the market to check
    // @param collateralToken the collateralToken to get the key for
    // @param isLong whether to get the key for the long or short side
    // @return key for claimable funding amount per size
    function claimableFundingAmountPerSizeKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_FUNDING_AMOUNT_PER_SIZE,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for when funding was last updated
    // @param market the market to check
    // @return key for when funding was last updated
    function fundingUpdatedAtKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_UPDATED_AT,
            market
        ));
    }

    // @dev key for claimable funding amount
    // @param market the market to check
    // @param token the token to check
    // @return key for claimable funding amount
    function claimableFundingAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_FUNDING_AMOUNT,
            market,
            token
        ));
    }

    // @dev key for claimable funding amount by account
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @return key for claimable funding amount
    function claimableFundingAmountKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_FUNDING_AMOUNT,
            market,
            token,
            account
        ));
    }

    // @dev key for claimable collateral amount
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_AMOUNT,
            market,
            token
        ));
    }

    // @dev key for claimable collateral amount for a timeKey for an account
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralAmountKey(address market, address token, uint256 timeKey, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_AMOUNT,
            market,
            token,
            timeKey,
            account
        ));
    }

    // @dev key for claimable collateral factor for a timeKey
    // @param market the market to check
    // @param token the token to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralFactorKey(address market, address token, uint256 timeKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_FACTOR,
            market,
            token,
            timeKey
        ));
    }

    // @dev key for claimable collateral factor for a timeKey for an account
    // @param market the market to check
    // @param token the token to check
    // @param timeKey the time key for the claimable amount
    // @param account the account to check
    // @return key for claimable funding amount
    function claimableCollateralFactorKey(address market, address token, uint256 timeKey, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_FACTOR,
            market,
            token,
            timeKey,
            account
        ));
    }

    // @dev key for claimable collateral factor
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimedCollateralAmountKey(address market, address token, uint256 timeKey, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMED_COLLATERAL_AMOUNT,
            market,
            token,
            timeKey,
            account
        ));
    }

    // @dev key for borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for borrowing factor
    function borrowingFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            BORROWING_FACTOR,
            market,
            isLong
        ));
    }

    // @dev the key for borrowing exponent
    // @param market the market for the pool
    // @param isLong whether to get the key for the long or short side
    function borrowingExponentFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            BORROWING_EXPONENT_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for cumulative borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for cumulative borrowing factor
    function cumulativeBorrowingFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CUMULATIVE_BORROWING_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for cumulative borrowing factor updated at
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for cumulative borrowing factor updated at
    function cumulativeBorrowingFactorUpdatedAtKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CUMULATIVE_BORROWING_FACTOR_UPDATED_AT,
            market,
            isLong
        ));
    }

    // @dev key for total borrowing amount
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for total borrowing amount
    function totalBorrowingKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TOTAL_BORROWING,
            market,
            isLong
        ));
    }

    // @dev key for affiliate reward amount
    // @param market the market to check
    // @param token the token to get the key for
    // @param account the account to get the key for
    // @return key for affiliate reward amount
    function affiliateRewardKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            AFFILIATE_REWARD,
            market,
            token
        ));
    }

    function maxAllowedSubaccountActionCountKey(address account, address subaccount, bytes32 actionType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT,
            account,
            subaccount,
            actionType
        ));
    }

    function subaccountActionCountKey(address account, address subaccount, bytes32 actionType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SUBACCOUNT_ACTION_COUNT,
            account,
            subaccount,
            actionType
        ));
    }

    function subaccountAutoTopUpAmountKey(address account, address subaccount) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SUBACCOUNT_AUTO_TOP_UP_AMOUNT,
            account,
            subaccount
        ));
    }

    // @dev key for affiliate reward amount for an account
    // @param market the market to check
    // @param token the token to get the key for
    // @param account the account to get the key for
    // @return key for affiliate reward amount
    function affiliateRewardKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            AFFILIATE_REWARD,
            market,
            token,
            account
        ));
    }

    // @dev key for is market disabled
    // @param market the market to check
    // @return key for is market disabled
    function isMarketDisabledKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            IS_MARKET_DISABLED,
            market
        ));
    }

    // @dev key for min market tokens for first deposit
    // @param market the market to check
    // @return key for min market tokens for first deposit
    function minMarketTokensForFirstDepositKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT,
            market
        ));
    }

    // @dev key for price feed address
    // @param token the token to get the key for
    // @return key for price feed address
    function priceFeedKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED,
            token
        ));
    }

    // @dev key for realtime feed ID
    // @param token the token to get the key for
    // @return key for realtime feed ID
    function realtimeFeedIdKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            REALTIME_FEED_ID,
            token
        ));
    }

    // @dev key for realtime feed multiplier
    // @param token the token to get the key for
    // @return key for realtime feed multiplier
    function realtimeFeedMultiplierKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            REALTIME_FEED_MULTIPLIER,
            token
        ));
    }

    // @dev key for price feed multiplier
    // @param token the token to get the key for
    // @return key for price feed multiplier
    function priceFeedMultiplierKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED_MULTIPLIER,
            token
        ));
    }

    function priceFeedHeartbeatDurationKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED_HEARTBEAT_DURATION,
            token
        ));
    }

    // @dev key for stable price value
    // @param token the token to get the key for
    // @return key for stable price value
    function stablePriceKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            STABLE_PRICE,
            token
        ));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ArbSys.sol";

// @title Chain
// @dev Wrap the calls to retrieve chain variables to handle differences
// between chain implementations
library Chain {
    // if the ARBITRUM_CHAIN_ID changes, a new version of this library
    // and contracts depending on it would need to be deployed
    uint256 constant public ARBITRUM_CHAIN_ID = 42161;
    uint256 constant public ARBITRUM_GOERLI_CHAIN_ID = 421613;

    ArbSys constant public arbSys = ArbSys(address(100));

    // @dev return the current block's timestamp
    // @return the current block's timestamp
    function currentTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    // @dev return the current block's number
    // @return the current block's number
    function currentBlockNumber() internal view returns (uint256) {
        if (shouldUseArbSysValues()) {
            return arbSys.arbBlockNumber();
        }

        return block.number;
    }

    // @dev return the current block's hash
    // @return the current block's hash
    function getBlockHash(uint256 blockNumber) internal view returns (bytes32) {
        if (shouldUseArbSysValues()) {
            return arbSys.arbBlockHash(blockNumber);
        }

        return blockhash(blockNumber);
    }

    function shouldUseArbSysValues() internal view returns (bool) {
        return block.chainid == ARBITRUM_CHAIN_ID || block.chainid == ARBITRUM_GOERLI_CHAIN_ID;

    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 * ```solidity
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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../event/EventEmitter.sol";
import "../event/EventUtils.sol";
import "../utils/Cast.sol";

// @title OracleStore
// @dev Stores the list of oracle signers
contract OracleStore is RoleModule {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;

    using EventUtils for EventUtils.AddressItems;
    using EventUtils for EventUtils.UintItems;
    using EventUtils for EventUtils.IntItems;
    using EventUtils for EventUtils.BoolItems;
    using EventUtils for EventUtils.Bytes32Items;
    using EventUtils for EventUtils.BytesItems;
    using EventUtils for EventUtils.StringItems;

    EventEmitter public immutable eventEmitter;

    EnumerableSet.AddressSet internal signers;

    constructor(RoleStore _roleStore, EventEmitter _eventEmitter) RoleModule(_roleStore) {
        eventEmitter = _eventEmitter;
    }

    // @dev adds a signer
    // @param account address of the signer to add
    function addSigner(address account) external onlyController {
        signers.add(account);

        EventUtils.EventLogData memory eventData;
        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "account", account);

        eventEmitter.emitEventLog1(
            "SignerAdded",
            Cast.toBytes32(account),
            eventData
        );
    }

    // @dev removes a signer
    // @param account address of the signer to remove
    function removeSigner(address account) external onlyController {
        signers.remove(account);

        EventUtils.EventLogData memory eventData;
        eventData.addressItems.initItems(1);
        eventData.addressItems.setItem(0, "account", account);

        eventEmitter.emitEventLog1(
            "SignerRemoved",
            Cast.toBytes32(account),
            eventData
        );
    }

    // @dev get the total number of signers
    // @return the total number of signers
    function getSignerCount() external view returns (uint256) {
        return signers.length();
    }

    // @dev get the signer at the specified index
    // @param index the index of the signer to get
    // @return the signer at the specified index
    function getSigner(uint256 index) external view returns (address) {
        return signers.at(index);
    }

    // @dev get the signers for the specified indexes
    // @param start the start index, the value for this index will be included
    // @param end the end index, the value for this index will not be included
    // @return the signers for the specified indexes
    function getSigners(uint256 start, uint256 end) external view returns (address[] memory) {
        return signers.valuesAt(start, end);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../utils/Array.sol";
import "../utils/Bits.sol";
import "../price/Price.sol";
import "../utils/Printer.sol";

// @title OracleUtils
// @dev Library for oracle functions
library OracleUtils {
    using Array for uint256[];

    enum PriceSourceType {
        InternalFeed,
        PriceFeed,
        RealtimeFeed
    }

    enum OracleBlockNumberType {
        Min,
        Max
    }

    // @dev SetPricesParams struct for values required in Oracle.setPrices
    // @param signerInfo compacted indexes of signers, the index is used to retrieve
    // the signer address from the OracleStore
    // @param tokens list of tokens to set prices for
    // @param compactedOracleBlockNumbers compacted oracle block numbers
    // @param compactedOracleTimestamps compacted oracle timestamps
    // @param compactedDecimals compacted decimals for prices
    // @param compactedMinPrices compacted min prices
    // @param compactedMinPricesIndexes compacted min price indexes
    // @param compactedMaxPrices compacted max prices
    // @param compactedMaxPricesIndexes compacted max price indexes
    // @param signatures signatures of the oracle signers
    // @param priceFeedTokens tokens to set prices for based on an external price feed value
    struct SetPricesParams {
        uint256 signerInfo;
        address[] tokens;
        uint256[] compactedMinOracleBlockNumbers;
        uint256[] compactedMaxOracleBlockNumbers;
        uint256[] compactedOracleTimestamps;
        uint256[] compactedDecimals;
        uint256[] compactedMinPrices;
        uint256[] compactedMinPricesIndexes;
        uint256[] compactedMaxPrices;
        uint256[] compactedMaxPricesIndexes;
        bytes[] signatures;
        address[] priceFeedTokens;
        address[] realtimeFeedTokens;
        bytes[] realtimeFeedData;
    }

    struct SimulatePricesParams {
        address[] primaryTokens;
        Price.Props[] primaryPrices;
    }

    struct ReportInfo {
        uint256 minOracleBlockNumber;
        uint256 maxOracleBlockNumber;
        uint256 oracleTimestamp;
        bytes32 blockHash;
        address token;
        bytes32 tokenOracleType;
        uint256 precision;
        uint256 minPrice;
        uint256 maxPrice;
    }

    // bid: min price, highest buy price
    // ask: max price, lowest sell price
    struct RealtimeFeedReport {
        // The feed ID the report has data for
        bytes32 feedId;
        // The time the median value was observed on
        uint32 observationsTimestamp;
        // The median value agreed in an OCR round
        int192 median;
        // The best bid value agreed in an OCR round
        // bid is the highest price that a buyer will buy at
        int192 bid;
        // The best ask value agreed in an OCR round
        // ask is the lowest price that a seller will sell at
        int192 ask;
        // The upper bound of the block range the median value was observed within
        uint64 blocknumberUpperBound;
        // The blockhash for the upper bound of block range (ensures correct blockchain)
        bytes32 upperBlockhash;
        // The lower bound of the block range the median value was observed within
        uint64 blocknumberLowerBound;
        // The timestamp of the current (upperbound) block number
        uint64 currentBlockTimestamp;
    }

    // compacted prices have a length of 32 bits
    uint256 public constant COMPACTED_PRICE_BIT_LENGTH = 32;
    uint256 public constant COMPACTED_PRICE_BITMASK = Bits.BITMASK_32;

    // compacted precisions have a length of 8 bits
    uint256 public constant COMPACTED_PRECISION_BIT_LENGTH = 8;
    uint256 public constant COMPACTED_PRECISION_BITMASK = Bits.BITMASK_8;

    // compacted block numbers have a length of 64 bits
    uint256 public constant COMPACTED_BLOCK_NUMBER_BIT_LENGTH = 64;
    uint256 public constant COMPACTED_BLOCK_NUMBER_BITMASK = Bits.BITMASK_64;

    // compacted timestamps have a length of 64 bits
    uint256 public constant COMPACTED_TIMESTAMP_BIT_LENGTH = 64;
    uint256 public constant COMPACTED_TIMESTAMP_BITMASK = Bits.BITMASK_64;

    // compacted price indexes have a length of 8 bits
    uint256 public constant COMPACTED_PRICE_INDEX_BIT_LENGTH = 8;
    uint256 public constant COMPACTED_PRICE_INDEX_BITMASK = Bits.BITMASK_8;

    function validateBlockNumberWithinRange(
        uint256[] memory minOracleBlockNumbers,
        uint256[] memory maxOracleBlockNumbers,
        uint256 blockNumber
    ) internal pure {
        if (!isBlockNumberWithinRange(
                minOracleBlockNumbers,
                maxOracleBlockNumbers,
                blockNumber
        )) {
            revert Errors.OracleBlockNumberNotWithinRange(
                minOracleBlockNumbers,
                maxOracleBlockNumbers,
                blockNumber
            );
        }
    }

    function isBlockNumberWithinRange(
        uint256[] memory minOracleBlockNumbers,
        uint256[] memory maxOracleBlockNumbers,
        uint256 blockNumber
    ) internal pure returns (bool) {
        if (!minOracleBlockNumbers.areLessThanOrEqualTo(blockNumber)) {
            return false;
        }

        if (!maxOracleBlockNumbers.areGreaterThanOrEqualTo(blockNumber)) {
            return false;
        }

        return true;
    }

    // @dev get the uncompacted price at the specified index
    // @param compactedPrices the compacted prices
    // @param index the index to get the uncompacted price at
    // @return the uncompacted price at the specified index
    function getUncompactedPrice(uint256[] memory compactedPrices, uint256 index) internal pure returns (uint256) {
        uint256 price = Array.getUncompactedValue(
            compactedPrices,
            index,
            COMPACTED_PRICE_BIT_LENGTH,
            COMPACTED_PRICE_BITMASK,
            "getUncompactedPrice"
        );

        if (price == 0) { revert Errors.EmptyCompactedPrice(index); }

        return price;
    }

    // @dev get the uncompacted decimal at the specified index
    // @param compactedDecimals the compacted decimals
    // @param index the index to get the uncompacted decimal at
    // @return the uncompacted decimal at the specified index
    function getUncompactedDecimal(uint256[] memory compactedDecimals, uint256 index) internal pure returns (uint256) {
        uint256 decimal = Array.getUncompactedValue(
            compactedDecimals,
            index,
            COMPACTED_PRECISION_BIT_LENGTH,
            COMPACTED_PRECISION_BITMASK,
            "getUncompactedDecimal"
        );

        return decimal;
    }


    // @dev get the uncompacted price index at the specified index
    // @param compactedPriceIndexes the compacted indexes
    // @param index the index to get the uncompacted price index at
    // @return the uncompacted price index at the specified index
    function getUncompactedPriceIndex(uint256[] memory compactedPriceIndexes, uint256 index) internal pure returns (uint256) {
        uint256 priceIndex = Array.getUncompactedValue(
            compactedPriceIndexes,
            index,
            COMPACTED_PRICE_INDEX_BIT_LENGTH,
            COMPACTED_PRICE_INDEX_BITMASK,
            "getUncompactedPriceIndex"
        );

        return priceIndex;

    }

    // @dev get the uncompacted oracle block numbers
    // note that the returned block numbers may not be sorted
    function getUncompactedOracleBlockNumbers(
        uint256[] memory compactedOracleBlockNumbers,
        uint256 compactedOracleBlockNumbersLength,
        OracleUtils.RealtimeFeedReport[] memory reports,
        OracleBlockNumberType oracleBlockNumberType
    ) internal pure returns (uint256[] memory) {
        uint256[] memory blockNumbers = new uint256[](compactedOracleBlockNumbersLength + reports.length);

        for (uint256 i; i < compactedOracleBlockNumbersLength; i++) {
            blockNumbers[i] = getUncompactedOracleBlockNumber(compactedOracleBlockNumbers, i);
        }

        if (oracleBlockNumberType == OracleBlockNumberType.Min) {
            for (uint256 i; i < reports.length; i++) {
                blockNumbers[compactedOracleBlockNumbersLength + i] = reports[i].blocknumberLowerBound;
            }
        } else if (oracleBlockNumberType == OracleBlockNumberType.Max) {
            for (uint256 i; i < reports.length; i++) {
                blockNumbers[compactedOracleBlockNumbersLength + i] = reports[i].blocknumberUpperBound;
            }
        } else {
            revert Errors.UnsupportedOracleBlockNumberType(uint256(oracleBlockNumberType));
        }

        return blockNumbers;
    }

    // @dev get the uncompacted oracle block number
    // @param compactedOracleBlockNumbers the compacted oracle block numbers
    // @param index the index to get the uncompacted oracle block number at
    // @return the uncompacted oracle block number
    function getUncompactedOracleBlockNumber(uint256[] memory compactedOracleBlockNumbers, uint256 index) internal pure returns (uint256) {
        uint256 blockNumber = Array.getUncompactedValue(
            compactedOracleBlockNumbers,
            index,
            COMPACTED_BLOCK_NUMBER_BIT_LENGTH,
            COMPACTED_BLOCK_NUMBER_BITMASK,
            "getUncompactedOracleBlockNumber"
        );

        if (blockNumber == 0) { revert Errors.EmptyCompactedBlockNumber(index); }

        return blockNumber;
    }

    // @dev get the uncompacted oracle timestamp
    // @param compactedOracleTimestamps the compacted oracle timestamps
    // @param index the index to get the uncompacted oracle timestamp at
    // @return the uncompacted oracle timestamp
    function getUncompactedOracleTimestamp(uint256[] memory compactedOracleTimestamps, uint256 index) internal pure returns (uint256) {
        uint256 timestamp = Array.getUncompactedValue(
            compactedOracleTimestamps,
            index,
            COMPACTED_TIMESTAMP_BIT_LENGTH,
            COMPACTED_TIMESTAMP_BITMASK,
            "getUncompactedOracleTimestamp"
        );

        if (timestamp == 0) { revert Errors.EmptyCompactedTimestamp(index); }

        return timestamp;
    }

    // @dev validate the signer of a price
    // before calling this function, the expectedSigner should be validated to
    // ensure that it is not the zero address
    // @param minOracleBlockNumber the min block number used for the signed message hash
    // @param maxOracleBlockNumber the max block number used for the signed message hash
    // @param oracleTimestamp the timestamp used for the signed message hash
    // @param blockHash the block hash used for the signed message hash
    // @param token the token used for the signed message hash
    // @param precision the precision used for the signed message hash
    // @param minPrice the min price used for the signed message hash
    // @param maxPrice the max price used for the signed message hash
    // @param signature the signer's signature
    // @param expectedSigner the address of the expected signer
    function validateSigner(
        bytes32 salt,
        ReportInfo memory info,
        bytes memory signature,
        address expectedSigner
    ) internal pure {
        bytes32 digest = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encode(
                salt,
                info.minOracleBlockNumber,
                info.maxOracleBlockNumber,
                info.oracleTimestamp,
                info.blockHash,
                info.token,
                info.tokenOracleType,
                info.precision,
                info.minPrice,
                info.maxPrice
            ))
        );

        address recoveredSigner = ECDSA.recover(digest, signature);
        if (recoveredSigner != expectedSigner) {
            revert Errors.InvalidSignature(recoveredSigner, expectedSigner);
        }
    }

    function revertOracleBlockNumberNotWithinRange(
        uint256[] memory minOracleBlockNumbers,
        uint256[] memory maxOracleBlockNumbers,
        uint256 blockNumber
    ) internal pure {
        revert Errors.OracleBlockNumberNotWithinRange(minOracleBlockNumbers, maxOracleBlockNumbers, blockNumber);
    }

    function isOracleError(bytes4 errorSelector) internal pure returns (bool) {
        if (isOracleBlockNumberError(errorSelector)) {
            return true;
        }

        if (isEmptyPriceError(errorSelector)) {
            return true;
        }

        return false;
    }

    function isEmptyPriceError(bytes4 errorSelector) internal pure returns (bool) {
        if (errorSelector == Errors.EmptyPrimaryPrice.selector) {
            return true;
        }

        return false;
    }

    function isOracleBlockNumberError(bytes4 errorSelector) internal pure returns (bool) {
        if (errorSelector == Errors.OracleBlockNumbersAreSmallerThanRequired.selector) {
            return true;
        }

        if (errorSelector == Errors.OracleBlockNumberNotWithinRange.selector) {
            return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @title IPriceFeed
// @dev Interface for a price feed
interface IPriceFeed {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRealtimeFeedVerifier {
    function verify(bytes memory data) external returns (bytes memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title Bits
 * @dev Library for bit values
 */
library Bits {
    // @dev uint256(~0) is 256 bits of 1s
    // @dev shift the 1s by (256 - 8) to get (256 - 8) 0s followed by 8 1s
    uint256 constant public BITMASK_8 = ~uint256(0) >> (256 - 8);
    // @dev shift the 1s by (256 - 16) to get (256 - 16) 0s followed by 16 1s
    uint256 constant public BITMASK_16 = ~uint256(0) >> (256 - 16);
    // @dev shift the 1s by (256 - 32) to get (256 - 32) 0s followed by 32 1s
    uint256 constant public BITMASK_32 = ~uint256(0) >> (256 - 32);
    // @dev shift the 1s by (256 - 64) to get (256 - 64) 0s followed by 64 1s
    uint256 constant public BITMASK_64 = ~uint256(0) >> (256 - 64);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../error/Errors.sol";

/**
 * @title Array
 * @dev Library for array functions
 */
library Array {
    using SafeCast for int256;

    /**
     * @dev Gets the value of the element at the specified index in the given array. If the index is out of bounds, returns 0.
     *
     * @param arr the array to get the value from
     * @param index the index of the element in the array
     * @return the value of the element at the specified index in the array
     */
    function get(bytes32[] memory arr, uint256 index) internal pure returns (bytes32) {
        if (index < arr.length) {
            return arr[index];
        }

        return bytes32(0);
    }

    /**
     * @dev Determines whether all of the elements in the given array are equal to the specified value.
     *
     * @param arr the array to check the elements of
     * @param value the value to compare the elements of the array to
     * @return true if all of the elements in the array are equal to the specified value, false otherwise
     */
    function areEqualTo(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] != value) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Determines whether all of the elements in the given array are greater than the specified value.
     *
     * @param arr the array to check the elements of
     * @param value the value to compare the elements of the array to
     * @return true if all of the elements in the array are greater than the specified value, false otherwise
     */
    function areGreaterThan(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] <= value) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Determines whether all of the elements in the given array are greater than or equal to the specified value.
     *
     * @param arr the array to check the elements of
     * @param value the value to compare the elements of the array to
     * @return true if all of the elements in the array are greater than or equal to the specified value, false otherwise
     */
    function areGreaterThanOrEqualTo(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] < value) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Determines whether all of the elements in the given array are less than the specified value.
     *
     * @param arr the array to check the elements of
     * @param value the value to compare the elements of the array to
     * @return true if all of the elements in the array are less than the specified value, false otherwise
     */
    function areLessThan(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] >= value) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Determines whether all of the elements in the given array are less than or equal to the specified value.
     *
     * @param arr the array to check the elements of
     * @param value the value to compare the elements of the array to
     * @return true if all of the elements in the array are less than or equal to the specified value, false otherwise
     */
    function areLessThanOrEqualTo(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] > value) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Gets the median value of the elements in the given array. For arrays with an odd number of elements, returns the element at the middle index. For arrays with an even number of elements, returns the average of the two middle elements.
     *
     * @param arr the array to get the median value from
     * @return the median value of the elements in the given array
     */
    function getMedian(uint256[] memory arr) internal pure returns (uint256) {
        if (arr.length % 2 == 1) {
            return arr[arr.length / 2];
        }

        return (arr[arr.length / 2] + arr[arr.length / 2 - 1]) / 2;
    }

    /**
     * @dev Gets the uncompacted value at the specified index in the given array of compacted values.
     *
     * @param compactedValues the array of compacted values to get the uncompacted value from
     * @param index the index of the uncompacted value in the array
     * @param compactedValueBitLength the length of each compacted value, in bits
     * @param bitmask the bitmask to use to extract the uncompacted value from the compacted value
     * @return the uncompacted value at the specified index in the array of compacted values
     */
    function getUncompactedValue(
        uint256[] memory compactedValues,
        uint256 index,
        uint256 compactedValueBitLength,
        uint256 bitmask,
        string memory label
    ) internal pure returns (uint256) {
        uint256 compactedValuesPerSlot = 256 / compactedValueBitLength;

        uint256 slotIndex = index / compactedValuesPerSlot;
        if (slotIndex >= compactedValues.length) {
            revert Errors.CompactedArrayOutOfBounds(compactedValues, index, slotIndex, label);
        }

        uint256 slotBits = compactedValues[slotIndex];
        uint256 offset = (index - slotIndex * compactedValuesPerSlot) * compactedValueBitLength;

        uint256 value = (slotBits >> offset) & bitmask;

        return value;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../error/Errors.sol";

library Uint256Mask {
    struct Mask {
        uint256 bits;
    }

    function validateUniqueAndSetIndex(
        Mask memory mask,
        uint256 index,
        string memory label
    ) internal pure {
        if (index >= 256) {
            revert Errors.MaskIndexOutOfBounds(index, label);
        }

        uint256 bit = 1 << index;

        if (mask.bits & bit != 0) {
            revert Errors.DuplicatedIndex(index, label);
        }

        mask.bits = mask.bits | bit;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";

abstract contract BaseVault is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(ERC20 _asset, string memory _name, string memory _symbol) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, uint256, /*minOutAfterFees*/ address receiver)
        public
        payable
        virtual
        returns (uint256 shares)
    {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function redeem(uint256 shares, uint256, /*minOutAfterFees*/ address receiver, address owner)
        public
        payable
        virtual
        returns (uint256 assets)
    {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual { }

    function afterDeposit(uint256 assets, uint256 shares) internal virtual { }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/// @title ShareMath
/// @author Umami Devs
library ShareMath {
    uint256 internal constant PLACEHOLDER_UINT = 1;

    function assetToShares(uint256 assetAmount, uint256 assetPerShare, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");
        return (assetAmount * 10 ** decimals) / assetPerShare;
    }

    function sharesToAsset(uint256 shares, uint256 assetPerShare, uint256 decimals) internal pure returns (uint256) {
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");
        return (shares * assetPerShare) / 10 ** decimals;
    }

    function pricePerShare(uint256 totalSupply, uint256 totalBalance, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 singleShare = 10 ** decimals;
        return totalSupply > 0 ? (singleShare * totalBalance) / totalSupply : singleShare;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title PausableVault
/// @author Umami DAO
/// @notice Pausable deposit/withdraw support for vaults
abstract contract PausableVault {
    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    /// @dev paused deposits only
    event DepositsPaused(address account);

    /// @dev paused deposits only
    event DepositsUnpaused(address account);

    /// @dev paused withdrawals only
    event WithdrawalsPaused(address account);

    /// @dev paused withdrawals only
    event WithdrawalsUnpaused(address account);

    bool private _depositsPaused;

    bool private _withdrawalPaused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _depositsPaused = false;
        _withdrawalPaused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenDepositNotPaused() {
        _requireDepositNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenWithdrawalNotPaused() {
        _requireWithdrawalNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenDepositPaused() {
        _requireDepositPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenWithdrawalPaused() {
        _requireWithdrawalPaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function depositPaused() public view virtual returns (bool) {
        return _depositsPaused;
    }
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */

    function withdrawalPaused() public view virtual returns (bool) {
        return _withdrawalPaused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireDepositNotPaused() internal view virtual {
        require(!depositPaused(), "Pausable: deposit paused");
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireWithdrawalNotPaused() internal view virtual {
        require(!withdrawalPaused(), "Pausable: withdrawal paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requireDepositPaused() internal view virtual {
        require(depositPaused(), "Pausable: deposit not paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requireWithdrawalPaused() internal view virtual {
        require(withdrawalPaused(), "Pausable: withdrawal not paused");
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual {
        if (!depositPaused()) {
            _pauseDeposit();
        }
        if (!withdrawalPaused()) {
            _pauseWithdrawal();
        }
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        if (depositPaused()) {
            _unpauseDeposit();
        }
        if (withdrawalPaused()) {
            _unpauseWithdrawal();
        }
    }

    /**
     * @dev Triggers stopped deposit state.
     *
     * Requirements:
     *
     * - The deposits must not be paused.
     */
    function _pauseDeposit() internal virtual whenDepositNotPaused {
        _depositsPaused = true;
        emit DepositsPaused(msg.sender);
    }

    /**
     * @dev Returns to normal deposit state.
     *
     * Requirements:
     *
     * - The deposits must be paused.
     */
    function _unpauseDeposit() internal virtual whenDepositPaused {
        _depositsPaused = false;
        emit DepositsUnpaused(msg.sender);
    }

    /**
     * @dev Triggers stopped withdrawal state.
     *
     * Requirements:
     *
     * - The withdrawals must not be paused.
     */
    function _pauseWithdrawal() internal virtual whenWithdrawalNotPaused {
        _withdrawalPaused = true;
        emit WithdrawalsPaused(msg.sender);
    }

    /**
     * @dev Returns to normal withdrawal state.
     *
     * Requirements:
     *
     * - The withdrawals must be paused.
     */
    function _unpauseWithdrawal() internal virtual whenWithdrawalPaused {
        _withdrawalPaused = false;
        emit WithdrawalsUnpaused(msg.sender);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";
import "./Role.sol";
import "../error/Errors.sol";

/**
 * @title RoleStore
 * @dev Stores roles and their members.
 */
contract RoleStore {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set internal roles;
    mapping(bytes32 => EnumerableSet.AddressSet) internal roleMembers;
    // checking if an account has a role is a frequently used function
    // roleCache helps to save gas by offering a more efficient lookup
    // vs calling roleMembers[key].contains(account)
    mapping(address => mapping (bytes32 => bool)) roleCache;

    modifier onlyRoleAdmin() {
        if (!hasRole(msg.sender, Role.ROLE_ADMIN)) {
            revert Errors.Unauthorized(msg.sender, "ROLE_ADMIN");
        }
        _;
    }

    constructor() {
        _grantRole(msg.sender, Role.ROLE_ADMIN);
    }

    /**
     * @dev Grants the specified role to the given account.
     *
     * @param account The address of the account.
     * @param roleKey The key of the role to grant.
     */
    function grantRole(address account, bytes32 roleKey) external onlyRoleAdmin {
        _grantRole(account, roleKey);
    }

    /**
     * @dev Revokes the specified role from the given account.
     *
     * @param account The address of the account.
     * @param roleKey The key of the role to revoke.
     */
    function revokeRole(address account, bytes32 roleKey) external onlyRoleAdmin {
        _revokeRole(account, roleKey);
    }

    /**
     * @dev Returns true if the given account has the specified role.
     *
     * @param account The address of the account.
     * @param roleKey The key of the role.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(address account, bytes32 roleKey) public view returns (bool) {
        return roleCache[account][roleKey];
    }

    /**
     * @dev Returns the number of roles stored in the contract.
     *
     * @return The number of roles.
     */
    function getRoleCount() external view returns (uint256) {
        return roles.length();
    }

    /**
     * @dev Returns the keys of the roles stored in the contract.
     *
     * @param start The starting index of the range of roles to return.
     * @param end The ending index of the range of roles to return.
     * @return The keys of the roles.
     */
    function getRoles(uint256 start, uint256 end) external view returns (bytes32[] memory) {
        return roles.valuesAt(start, end);
    }

    /**
     * @dev Returns the number of members of the specified role.
     *
     * @param roleKey The key of the role.
     * @return The number of members of the role.
     */
    function getRoleMemberCount(bytes32 roleKey) external view returns (uint256) {
        return roleMembers[roleKey].length();
    }

    /**
     * @dev Returns the members of the specified role.
     *
     * @param roleKey The key of the role.
     * @param start the start index, the value for this index will be included.
     * @param end the end index, the value for this index will not be included.
     * @return The members of the role.
     */
    function getRoleMembers(bytes32 roleKey, uint256 start, uint256 end) external view returns (address[] memory) {
        return roleMembers[roleKey].valuesAt(start, end);
    }

    function _grantRole(address account, bytes32 roleKey) internal {
        roles.add(roleKey);
        roleMembers[roleKey].add(account);
        roleCache[account][roleKey] = true;
    }

    function _revokeRole(address account, bytes32 roleKey) internal {
        roleMembers[roleKey].remove(account);
        roleCache[account][roleKey] = false;

        if (roleMembers[roleKey].length() == 0) {
            if (roleKey == Role.ROLE_ADMIN) {
                revert Errors.ThereMustBeAtLeastOneRoleAdmin();
            }
            if (roleKey == Role.TIMELOCK_MULTISIG) {
                revert Errors.ThereMustBeAtLeastOneTimelockMultiSig();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/ErrorUtils.sol";
import "../utils/AccountUtils.sol";

import "./IWNT.sol";

/**
 * @title TokenUtils
 * @dev Library for token functions, helps with transferring of tokens and
 * native token functions
 */
library TokenUtils {
    using Address for address;
    using SafeERC20 for IERC20;

    event TokenTransferReverted(string reason, bytes returndata);
    event NativeTokenTransferReverted(string reason);

    /**
     * @dev Returns the address of the WNT token.
     * @param dataStore DataStore contract instance where the address of the WNT token is stored.
     * @return The address of the WNT token.
     */
    function wnt(DataStore dataStore) internal view returns (address) {
        return dataStore.getAddress(Keys.WNT);
    }

    /**
     * @dev Transfers the specified amount of `token` from the caller to `receiver`.
     * limit the amount of gas forwarded so that a user cannot intentionally
     * construct a token call that would consume all gas and prevent necessary
     * actions like request cancellation from being executed
     *
     * @param dataStore The data store that contains the `tokenTransferGasLimit` for the specified `token`.
     * @param token The address of the ERC20 token that is being transferred.
     * @param receiver The address of the recipient of the `token` transfer.
     * @param amount The amount of `token` to transfer.
     */
    function transfer(
        DataStore dataStore,
        address token,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == 0) { return; }
        AccountUtils.validateReceiver(receiver);

        uint256 gasLimit = dataStore.getUint(Keys.tokenTransferGasLimit(token));
        if (gasLimit == 0) {
            revert Errors.EmptyTokenTranferGasLimit(token);
        }

        (bool success0, /* bytes memory returndata */) = nonRevertingTransferWithGasLimit(
            IERC20(token),
            receiver,
            amount,
            gasLimit
        );

        if (success0) { return; }

        address holdingAddress = dataStore.getAddress(Keys.HOLDING_ADDRESS);

        if (holdingAddress == address(0)) {
            revert Errors.EmptyHoldingAddress();
        }

        // in case transfers to the receiver fail due to blacklisting or other reasons
        // send the tokens to a holding address to avoid possible gaming through reverting
        // transfers
        (bool success1, bytes memory returndata) = nonRevertingTransferWithGasLimit(
            IERC20(token),
            holdingAddress,
            amount,
            gasLimit
        );

        if (success1) { return; }

        (string memory reason, /* bool hasRevertMessage */) = ErrorUtils.getRevertMessage(returndata);
        emit TokenTransferReverted(reason, returndata);

        // throw custom errors to prevent spoofing of errors
        // this is necessary because contracts like DepositHandler, WithdrawalHandler, OrderHandler
        // do not cancel requests for specific errors
        revert Errors.TokenTransferError(token, receiver, amount);
    }

    function sendNativeToken(
        DataStore dataStore,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == 0) { return; }

        AccountUtils.validateReceiver(receiver);

        uint256 gasLimit = dataStore.getUint(Keys.NATIVE_TOKEN_TRANSFER_GAS_LIMIT);

        bool success;
        // use an assembly call to avoid loading large data into memory
        // input mem[in…(in+insize)]
        // output area mem[out…(out+outsize))]
        assembly {
            success := call(
                gasLimit, // gas limit
                receiver, // receiver
                amount, // value
                0, // in
                0, // insize
                0, // out
                0 // outsize
            )
        }

        if (success) { return; }

        // if the transfer failed, re-wrap the token and send it to the receiver
        depositAndSendWrappedNativeToken(
            dataStore,
            receiver,
            amount
        );
    }

    /**
     * Deposits the specified amount of native token and sends the specified
     * amount of wrapped native token to the specified receiver address.
     *
     * @param dataStore the data store to use for storing and retrieving data
     * @param receiver the address of the recipient of the wrapped native token transfer
     * @param amount the amount of native token to deposit and the amount of wrapped native token to send
     */
    function depositAndSendWrappedNativeToken(
        DataStore dataStore,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == 0) { return; }
        AccountUtils.validateReceiver(receiver);

        address _wnt = wnt(dataStore);
        IWNT(_wnt).deposit{value: amount}();

        transfer(
            dataStore,
            _wnt,
            receiver,
            amount
        );
    }

    /**
     * @dev Withdraws the specified amount of wrapped native token and sends the
     * corresponding amount of native token to the specified receiver address.
     *
     * limit the amount of gas forwarded so that a user cannot intentionally
     * construct a token call that would consume all gas and prevent necessary
     * actions like request cancellation from being executed
     *
     * @param dataStore the data store to use for storing and retrieving data
     * @param _wnt the address of the WNT contract to withdraw the wrapped native token from
     * @param receiver the address of the recipient of the native token transfer
     * @param amount the amount of wrapped native token to withdraw and the amount of native token to send
     */
    function withdrawAndSendNativeToken(
        DataStore dataStore,
        address _wnt,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == 0) { return; }
        AccountUtils.validateReceiver(receiver);

        IWNT(_wnt).withdraw(amount);

        uint256 gasLimit = dataStore.getUint(Keys.NATIVE_TOKEN_TRANSFER_GAS_LIMIT);

        bool success;
        // use an assembly call to avoid loading large data into memory
        // input mem[in…(in+insize)]
        // output area mem[out…(out+outsize))]
        assembly {
            success := call(
                gasLimit, // gas limit
                receiver, // receiver
                amount, // value
                0, // in
                0, // insize
                0, // out
                0 // outsize
            )
        }

        if (success) { return; }

        // if the transfer failed, re-wrap the token and send it to the receiver
        depositAndSendWrappedNativeToken(
            dataStore,
            receiver,
            amount
        );
    }

    /**
     * @dev Transfers the specified amount of ERC20 token to the specified receiver
     * address, with a gas limit to prevent the transfer from consuming all available gas.
     * adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol
     *
     * @param token the ERC20 contract to transfer the tokens from
     * @param to the address of the recipient of the token transfer
     * @param amount the amount of tokens to transfer
     * @param gasLimit the maximum amount of gas that the token transfer can consume
     * @return a tuple containing a boolean indicating the success or failure of the
     * token transfer, and a bytes value containing the return data from the token transfer
     */
    function nonRevertingTransferWithGasLimit(
        IERC20 token,
        address to,
        uint256 amount,
        uint256 gasLimit
    ) internal returns (bool, bytes memory) {
        bytes memory data = abi.encodeWithSelector(token.transfer.selector, to, amount);
        (bool success, bytes memory returndata) = address(token).call{ gas: gasLimit }(data);

        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (!address(token).isContract()) {
                    return (false, "Call to non-contract");
                }
            }

            // some tokens do not revert on a failed transfer, they will return a boolean instead
            // validate that the returned boolean is true, otherwise indicate that the token transfer failed
            if (returndata.length > 0 && !abi.decode(returndata, (bool))) {
                return (false, returndata);
            }

            // transfers on some tokens do not return a boolean value, they will just revert if a transfer fails
            // for these tokens, if success is true then the transfer should have completed
            return (true, returndata);
        }

        return (false, returndata);
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title ArbSys
// @dev Globally available variables for Arbitrum may have both an L1 and an L2
// value, the ArbSys interface is used to retrieve the L2 value
interface ArbSys {
    function arbBlockNumber() external view returns (uint256);
    function arbBlockHash(uint256 blockNumber) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Errors {
    // AdlHandler errors
    error AdlNotRequired(int256 pnlToPoolFactor, uint256 maxPnlFactorForAdl);
    error InvalidAdl(int256 nextPnlToPoolFactor, int256 pnlToPoolFactor);
    error PnlOvercorrected(int256 nextPnlToPoolFactor, uint256 minPnlFactorForAdl);

    // AdlUtils errors
    error InvalidSizeDeltaForAdl(uint256 sizeDeltaUsd, uint256 positionSizeInUsd);
    error AdlNotEnabled();

    // Bank errors
    error SelfTransferNotSupported(address receiver);
    error InvalidNativeTokenSender(address msgSender);

    // BaseRouter
    error CouldNotSendNativeToken(address receiver, uint256 amount);

    // CallbackUtils errors
    error MaxCallbackGasLimitExceeded(uint256 callbackGasLimit, uint256 maxCallbackGasLimit);

    // Config errors
    error InvalidBaseKey(bytes32 baseKey);
    error InvalidFeeFactor(bytes32 baseKey, uint256 value);

    // Timelock errors
    error ActionAlreadySignalled();
    error ActionNotSignalled();
    error SignalTimeNotYetPassed(uint256 signalTime);
    error InvalidTimelockDelay(uint256 timelockDelay);
    error MaxTimelockDelayExceeded(uint256 timelockDelay);
    error InvalidFeeReceiver(address receiver);
    error InvalidOracleSigner(address receiver);

    // DepositStoreUtils errors
    error DepositNotFound(bytes32 key);

    // DepositUtils errors
    error EmptyDeposit();
    error EmptyDepositAmounts();

    // ExecuteDepositUtils errors
    error MinMarketTokens(uint256 received, uint256 expected);
    error EmptyDepositAmountsAfterSwap();
    error InvalidPoolValueForDeposit(int256 poolValue);
    error InvalidSwapOutputToken(address outputToken, address expectedOutputToken);
    error InvalidReceiverForFirstDeposit(address receiver, address expectedReceiver);
    error InvalidMinMarketTokensForFirstDeposit(uint256 minMarketTokens, uint256 expectedMinMarketTokens);

    // ExchangeUtils errors
    error RequestNotYetCancellable(uint256 requestAge, uint256 requestExpirationAge, string requestType);

    // ExternalHandler errors
    error ExternalCallFailed(bytes data);
    error InvalidExternalCallInput(uint256 targetsLength, uint256 dataListLength);
    error InvalidExternalReceiversInput(uint256 refundTokensLength, uint256 refundReceiversLength);
    error InvalidExternalCallTarget(address target);

    // GlpMigrator errors
    error InvalidGlpAmount(uint256 totalGlpAmountToRedeem, uint256 totalGlpAmount);
    error InvalidExecutionFeeForMigration(uint256 totalExecutionFee, uint256 msgValue);

    // OrderHandler errors
    error OrderNotUpdatable(uint256 orderType);
    error InvalidKeeperForFrozenOrder(address keeper);

    // FeatureUtils errors
    error DisabledFeature(bytes32 key);

    // FeeHandler errors
    error InvalidClaimFeesInput(uint256 marketsLength, uint256 tokensLength);

    // GasUtils errors
    error InsufficientExecutionFee(uint256 minExecutionFee, uint256 executionFee);
    error InsufficientWntAmountForExecutionFee(uint256 wntAmount, uint256 executionFee);
    error InsufficientExecutionGasForErrorHandling(uint256 startingGas, uint256 minHandleErrorGas);
    error InsufficientExecutionGas(uint256 startingGas, uint256 estimatedGasLimit, uint256 minAdditionalGasForExecution);
    error InsufficientHandleExecutionErrorGas(uint256 gas, uint256 minHandleExecutionErrorGas);

    // MarketFactory errors
    error MarketAlreadyExists(bytes32 salt, address existingMarketAddress);

    // MarketStoreUtils errors
    error MarketNotFound(address key);

    // MarketUtils errors
    error EmptyMarket();
    error DisabledMarket(address market);
    error MaxSwapPathLengthExceeded(uint256 swapPathLengh, uint256 maxSwapPathLength);
    error InsufficientPoolAmount(uint256 poolAmount, uint256 amount);
    error InsufficientReserve(uint256 reservedUsd, uint256 maxReservedUsd);
    error InsufficientReserveForOpenInterest(uint256 reservedUsd, uint256 maxReservedUsd);
    error UnableToGetOppositeToken(address inputToken, address market);
    error UnexpectedTokenForVirtualInventory(address token, address market);
    error EmptyMarketTokenSupply();
    error InvalidSwapMarket(address market);
    error UnableToGetCachedTokenPrice(address token, address market);
    error CollateralAlreadyClaimed(uint256 adjustedClaimableAmount, uint256 claimedAmount);
    error OpenInterestCannotBeUpdatedForSwapOnlyMarket(address market);
    error MaxOpenInterestExceeded(uint256 openInterest, uint256 maxOpenInterest);
    error MaxPoolAmountExceeded(uint256 poolAmount, uint256 maxPoolAmount);
    error MaxPoolAmountForDepositExceeded(uint256 poolAmount, uint256 maxPoolAmountForDeposit);
    error UnexpectedBorrowingFactor(uint256 positionBorrowingFactor, uint256 cumulativeBorrowingFactor);
    error UnableToGetBorrowingFactorEmptyPoolUsd();
    error UnableToGetFundingFactorEmptyOpenInterest();
    error InvalidPositionMarket(address market);
    error InvalidCollateralTokenForMarket(address market, address token);
    error PnlFactorExceededForLongs(int256 pnlToPoolFactor, uint256 maxPnlFactor);
    error PnlFactorExceededForShorts(int256 pnlToPoolFactor, uint256 maxPnlFactor);
    error InvalidUiFeeFactor(uint256 uiFeeFactor, uint256 maxUiFeeFactor);
    error EmptyAddressInMarketTokenBalanceValidation(address market, address token);
    error InvalidMarketTokenBalance(address market, address token, uint256 balance, uint256 expectedMinBalance);
    error InvalidMarketTokenBalanceForCollateralAmount(address market, address token, uint256 balance, uint256 collateralAmount);
    error InvalidMarketTokenBalanceForClaimableFunding(address market, address token, uint256 balance, uint256 claimableFundingFeeAmount);
    error UnexpectedPoolValue(int256 poolValue);

    // Oracle errors
    error EmptySigner(uint256 signerIndex);
    error InvalidBlockNumber(uint256 minOracleBlockNumber, uint256 currentBlockNumber);
    error InvalidMinMaxBlockNumber(uint256 minOracleBlockNumber, uint256 maxOracleBlockNumber);
    error HasRealtimeFeedId(address token, bytes32 feedId);
    error InvalidRealtimeFeedLengths(uint256 tokensLength, uint256 dataLength);
    error EmptyRealtimeFeedId(address token);
    error InvalidRealtimeFeedId(address token, bytes32 feedId, bytes32 expectedFeedId);
    error InvalidRealtimeBidAsk(address token, int192 bid, int192 ask);
    error InvalidRealtimeBlockHash(address token, bytes32 blockHash, bytes32 expectedBlockHash);
    error InvalidRealtimePrices(address token, int192 bid, int192 ask);
    error RealtimeMaxPriceAgeExceeded(address token, uint256 oracleTimestamp, uint256 currentTimestamp);
    error MaxPriceAgeExceeded(uint256 oracleTimestamp, uint256 currentTimestamp);
    error MinOracleSigners(uint256 oracleSigners, uint256 minOracleSigners);
    error MaxOracleSigners(uint256 oracleSigners, uint256 maxOracleSigners);
    error BlockNumbersNotSorted(uint256 minOracleBlockNumber, uint256 prevMinOracleBlockNumber);
    error MinPricesNotSorted(address token, uint256 price, uint256 prevPrice);
    error MaxPricesNotSorted(address token, uint256 price, uint256 prevPrice);
    error EmptyPriceFeedMultiplier(address token);
    error EmptyRealtimeFeedMultiplier(address token);
    error InvalidFeedPrice(address token, int256 price);
    error PriceFeedNotUpdated(address token, uint256 timestamp, uint256 heartbeatDuration);
    error MaxSignerIndex(uint256 signerIndex, uint256 maxSignerIndex);
    error InvalidOraclePrice(address token);
    error InvalidSignerMinMaxPrice(uint256 minPrice, uint256 maxPrice);
    error InvalidMedianMinMaxPrice(uint256 minPrice, uint256 maxPrice);
    error NonEmptyTokensWithPrices(uint256 tokensWithPricesLength);
    error InvalidMinMaxForPrice(address token, uint256 min, uint256 max);
    error EmptyPriceFeed(address token);
    error PriceAlreadySet(address token, uint256 minPrice, uint256 maxPrice);
    error MaxRefPriceDeviationExceeded(
        address token,
        uint256 price,
        uint256 refPrice,
        uint256 maxRefPriceDeviationFactor
    );
    error InvalidBlockRangeSet(uint256 largestMinBlockNumber, uint256 smallestMaxBlockNumber);

    // OracleModule errors
    error InvalidPrimaryPricesForSimulation(uint256 primaryTokensLength, uint256 primaryPricesLength);
    error EndOfOracleSimulation();

    // OracleUtils errors
    error EmptyCompactedPrice(uint256 index);
    error EmptyCompactedBlockNumber(uint256 index);
    error EmptyCompactedTimestamp(uint256 index);
    error UnsupportedOracleBlockNumberType(uint256 oracleBlockNumberType);
    error InvalidSignature(address recoveredSigner, address expectedSigner);

    error EmptyPrimaryPrice(address token);

    error OracleBlockNumbersAreSmallerThanRequired(uint256[] oracleBlockNumbers, uint256 expectedBlockNumber);
    error OracleBlockNumberNotWithinRange(
        uint256[] minOracleBlockNumbers,
        uint256[] maxOracleBlockNumbers,
        uint256 blockNumber
    );

    // BaseOrderUtils errors
    error EmptyOrder();
    error UnsupportedOrderType();
    error InvalidOrderPrices(
        uint256 primaryPriceMin,
        uint256 primaryPriceMax,
        uint256 triggerPrice,
        uint256 orderType
    );
    error EmptySizeDeltaInTokens();
    error PriceImpactLargerThanOrderSize(int256 priceImpactUsd, uint256 sizeDeltaUsd);
    error NegativeExecutionPrice(int256 executionPrice, uint256 price, uint256 positionSizeInUsd, int256 priceImpactUsd, uint256 sizeDeltaUsd);
    error OrderNotFulfillableAtAcceptablePrice(uint256 price, uint256 acceptablePrice);

    // IncreaseOrderUtils errors
    error UnexpectedPositionState();

    // OrderUtils errors
    error OrderTypeCannotBeCreated(uint256 orderType);
    error OrderAlreadyFrozen();

    // OrderStoreUtils errors
    error OrderNotFound(bytes32 key);

    // SwapOrderUtils errors
    error UnexpectedMarket();

    // DecreasePositionCollateralUtils errors
    error InsufficientFundsToPayForCosts(uint256 remainingCostUsd, string step);
    error InvalidOutputToken(address tokenOut, address expectedTokenOut);

    // DecreasePositionUtils errors
    error InvalidDecreaseOrderSize(uint256 sizeDeltaUsd, uint256 positionSizeInUsd);
    error UnableToWithdrawCollateral(int256 estimatedRemainingCollateralUsd);
    error InvalidDecreasePositionSwapType(uint256 decreasePositionSwapType);
    error PositionShouldNotBeLiquidated(
        string reason,
        int256 remainingCollateralUsd,
        int256 minCollateralUsd,
        int256 minCollateralUsdForLeverage
    );

    // IncreasePositionUtils errors
    error InsufficientCollateralAmount(uint256 collateralAmount, int256 collateralDeltaAmount);
    error InsufficientCollateralUsd(int256 remainingCollateralUsd);

    // PositionStoreUtils errors
    error PositionNotFound(bytes32 key);

    // PositionUtils errors
    error LiquidatablePosition(
        string reason,
        int256 remainingCollateralUsd,
        int256 minCollateralUsd,
        int256 minCollateralUsdForLeverage
    );

    error EmptyPosition();
    error InvalidPositionSizeValues(uint256 sizeInUsd, uint256 sizeInTokens);
    error MinPositionSize(uint256 positionSizeInUsd, uint256 minPositionSizeUsd);

    // PositionPricingUtils errors
    error UsdDeltaExceedsLongOpenInterest(int256 usdDelta, uint256 longOpenInterest);
    error UsdDeltaExceedsShortOpenInterest(int256 usdDelta, uint256 shortOpenInterest);

    // SwapPricingUtils errors
    error UsdDeltaExceedsPoolValue(int256 usdDelta, uint256 poolUsd);

    // RoleModule errors
    error Unauthorized(address msgSender, string role);

    // RoleStore errors
    error ThereMustBeAtLeastOneRoleAdmin();
    error ThereMustBeAtLeastOneTimelockMultiSig();

    // ExchangeRouter errors
    error InvalidClaimFundingFeesInput(uint256 marketsLength, uint256 tokensLength);
    error InvalidClaimCollateralInput(uint256 marketsLength, uint256 tokensLength, uint256 timeKeysLength);
    error InvalidClaimAffiliateRewardsInput(uint256 marketsLength, uint256 tokensLength);
    error InvalidClaimUiFeesInput(uint256 marketsLength, uint256 tokensLength);

    // SwapUtils errors
    error InvalidTokenIn(address tokenIn, address market);
    error InsufficientOutputAmount(uint256 outputAmount, uint256 minOutputAmount);
    error InsufficientSwapOutputAmount(uint256 outputAmount, uint256 minOutputAmount);
    error DuplicatedMarketInSwapPath(address market);
    error SwapPriceImpactExceedsAmountIn(uint256 amountAfterFees, int256 negativeImpactAmount);

    // SubaccountRouter errors
    error InvalidReceiverForSubaccountOrder(address receiver, address expectedReceiver);

    // SubaccountUtils errors
    error SubaccountNotAuthorized(address account, address subaccount);
    error MaxSubaccountActionCountExceeded(address account, address subaccount, uint256 count, uint256 maxCount);

    // TokenUtils errors
    error EmptyTokenTranferGasLimit(address token);
    error TokenTransferError(address token, address receiver, uint256 amount);
    error EmptyHoldingAddress();

    // AccountUtils errors
    error EmptyAccount();
    error EmptyReceiver();

    // Array errors
    error CompactedArrayOutOfBounds(
        uint256[] compactedValues,
        uint256 index,
        uint256 slotIndex,
        string label
    );

    error ArrayOutOfBoundsUint256(
        uint256[] values,
        uint256 index,
        string label
    );

    error ArrayOutOfBoundsBytes(
        bytes[] values,
        uint256 index,
        string label
    );

    // WithdrawalStoreUtils errors
    error WithdrawalNotFound(bytes32 key);

    // WithdrawalUtils errors
    error EmptyWithdrawal();
    error EmptyWithdrawalAmount();
    error MinLongTokens(uint256 received, uint256 expected);
    error MinShortTokens(uint256 received, uint256 expected);
    error InsufficientMarketTokens(uint256 balance, uint256 expected);
    error InsufficientWntAmount(uint256 wntAmount, uint256 executionFee);
    error InvalidPoolValueForWithdrawal(int256 poolValue);

    // Uint256Mask errors
    error MaskIndexOutOfBounds(uint256 index, string label);
    error DuplicatedIndex(uint256 index, string label);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title EnumerableValues
 * @dev Library to extend the EnumerableSet library with functions to get
 * valuesAt for a range
 */
library EnumerableValues {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * Returns an array of bytes32 values from the given set, starting at the given
     * start index and ending before the given end index.
     *
     * @param set The set to get the values from.
     * @param start The starting index.
     * @param end The ending index.
     * @return An array of bytes32 values.
     */
    function valuesAt(EnumerableSet.Bytes32Set storage set, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        bytes32[] memory items = new bytes32[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    /**
     * Returns an array of address values from the given set, starting at the given
     * start index and ending before the given end index.
     *
     * @param set The set to get the values from.
     * @param start The starting index.
     * @param end The ending index.
     * @return An array of address values.
     */
    function valuesAt(EnumerableSet.AddressSet storage set, uint256 start, uint256 end) internal view returns (address[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        address[] memory items = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    /**
     * Returns an array of uint256 values from the given set, starting at the given
     * start index and ending before the given end index, the item at the end index will not be returned.
     *
     * @param set The set to get the values from.
     * @param start The starting index (inclusive, item at the start index will be returned).
     * @param end The ending index (exclusive, item at the end index will not be returned).
     * @return An array of uint256 values.
     */
    function valuesAt(EnumerableSet.UintSet storage set, uint256 start, uint256 end) internal view returns (uint256[] memory) {
        if (start >= set.length()) {
            return new uint256[](0);
        }

        uint256 max = set.length();
        if (end > max) { end = max; }

        uint256[] memory items = new uint256[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title Role
 * @dev Library for role keys
 */
library Role {
    /**
     * @dev The ROLE_ADMIN role.
     */
    bytes32 public constant ROLE_ADMIN = keccak256(abi.encode("ROLE_ADMIN"));

    /**
     * @dev The TIMELOCK_ADMIN role.
     */
    bytes32 public constant TIMELOCK_ADMIN = keccak256(abi.encode("TIMELOCK_ADMIN"));

    /**
     * @dev The TIMELOCK_MULTISIG role.
     */
    bytes32 public constant TIMELOCK_MULTISIG = keccak256(abi.encode("TIMELOCK_MULTISIG"));

    /**
     * @dev The CONFIG_KEEPER role.
     */
    bytes32 public constant CONFIG_KEEPER = keccak256(abi.encode("CONFIG_KEEPER"));

    /**
     * @dev The CONTROLLER role.
     */
    bytes32 public constant CONTROLLER = keccak256(abi.encode("CONTROLLER"));

    /**
     * @dev The GOV_TOKEN_CONTROLLER role.
     */
    bytes32 public constant GOV_TOKEN_CONTROLLER = keccak256(abi.encode("GOV_TOKEN_CONTROLLER"));

    /**
     * @dev The ROUTER_PLUGIN role.
     */
    bytes32 public constant ROUTER_PLUGIN = keccak256(abi.encode("ROUTER_PLUGIN"));

    /**
     * @dev The MARKET_KEEPER role.
     */
    bytes32 public constant MARKET_KEEPER = keccak256(abi.encode("MARKET_KEEPER"));

    /**
     * @dev The FEE_KEEPER role.
     */
    bytes32 public constant FEE_KEEPER = keccak256(abi.encode("FEE_KEEPER"));

    /**
     * @dev The ORDER_KEEPER role.
     */
    bytes32 public constant ORDER_KEEPER = keccak256(abi.encode("ORDER_KEEPER"));

    /**
     * @dev The FROZEN_ORDER_KEEPER role.
     */
    bytes32 public constant FROZEN_ORDER_KEEPER = keccak256(abi.encode("FROZEN_ORDER_KEEPER"));

    /**
     * @dev The PRICING_KEEPER role.
     */
    bytes32 public constant PRICING_KEEPER = keccak256(abi.encode("PRICING_KEEPER"));
    /**
     * @dev The LIQUIDATION_KEEPER role.
     */
    bytes32 public constant LIQUIDATION_KEEPER = keccak256(abi.encode("LIQUIDATION_KEEPER"));
    /**
     * @dev The ADL_KEEPER role.
     */
    bytes32 public constant ADL_KEEPER = keccak256(abi.encode("ADL_KEEPER"));
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library ErrorUtils {
    // To get the revert reason, referenced from https://ethereum.stackexchange.com/a/83577
    function getRevertMessage(bytes memory result) internal pure returns (string memory, bool) {
        // If the result length is less than 68, then the transaction either panicked or failed silently
        if (result.length < 68) {
            return ("", false);
        }

        bytes4 errorSelector = getErrorSelectorFromData(result);

        // 0x08c379a0 is the selector for Error(string)
        // referenced from https://blog.soliditylang.org/2021/04/21/custom-errors/
        if (errorSelector == bytes4(0x08c379a0)) {
            assembly {
                result := add(result, 0x04)
            }

            return (abi.decode(result, (string)), true);
        }

        // error may be a custom error, return an empty string for this case
        return ("", false);
    }

    function getErrorSelectorFromData(bytes memory data) internal pure returns (bytes4) {
        bytes4 errorSelector;

        assembly {
            errorSelector := mload(add(data, 0x20))
        }

        return errorSelector;
    }

    function revertWithParsedMessage(bytes memory result) internal pure {
        (string memory revertMessage, bool hasRevertMessage) = getRevertMessage(result);

        if (hasRevertMessage) {
            revert(revertMessage);
        } else {
            revertWithCustomError(result);
        }
    }

    function revertWithCustomError(bytes memory result) internal pure {
        // referenced from https://ethereum.stackexchange.com/a/123588
        uint256 length = result.length;
        assembly {
            revert(add(result, 0x20), length)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../error/Errors.sol";

library AccountUtils {
    function validateAccount(address account) internal pure {
        if (account == address(0)) {
            revert Errors.EmptyAccount();
        }
    }

    function validateReceiver(address receiver) internal pure {
        if (receiver == address(0)) {
            revert Errors.EmptyReceiver();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IWNT
 * @dev Interface for Wrapped Native Tokens, e.g. WETH
 * The contract is named WNT instead of WETH for a more general reference name
 * that can be used on any blockchain
 */
interface IWNT {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}