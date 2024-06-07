// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { AccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";
import { ITraderV0, TraderV0InitializerParams } from "./trader/trader/ITraderV0.sol";
import { IGMX_Swap_Module } from "./trader/modules/gmx/swap/IGMX_Swap_Module.sol";
import { IGMX_PositionRouter_Module } from "./trader/modules/gmx/position/IGMX_PositionRouter_Module.sol";
import { IGMX_OrderBook_Module } from "./trader/modules/gmx/orderbook/IGMX_OrderBook_Module.sol";
import { IGMX_GLP_Module } from "./trader/modules/gmx/glp/IGMX_GLP_Module.sol";
import { ICamelot_LP_Module } from "./trader/modules/camelot/lp/ICamelot_LP_Module.sol";
import { ICamelot_NFTPool_Module } from "./trader/modules/camelot/nftpool/ICamelot_NFTPool_Module.sol";
import { ICamelot_NitroPool_Module } from "./trader/modules/camelot/nitropool/ICamelot_NitroPool_Module.sol";
import { ICamelot_Swap_Module } from "./trader/modules/camelot/swap/ICamelot_Swap_Module.sol";
import { ICamelot_V3LP_Module } from "./trader/modules/camelot/v3LP/ICamelot_V3LP_Module.sol";
import { ICamelot_V3Swap_Module } from "./trader/modules/camelot/v3Swap/ICamelot_V3Swap_Module.sol";
import { ICamelot_Storage_Module } from "./trader/modules/camelot/storage/ICamelot_Storage_Module.sol";
import { ILyra_Storage_Module } from "./trader/modules/lyra/storage/ILyra_Storage_Module.sol";
import { ILyra_LP_Module } from "./trader/modules/lyra/lp/ILyra_LP_Module.sol";
import { ILyra_Options_Module } from "./trader/modules/lyra/options/ILyra_Options_Module.sol";
import { ILyra_Rewards_Module } from "./trader/modules/lyra/rewards/ILyra_Rewards_Module.sol";
import { IAave_Lending_Module } from "./trader/modules/aave/IAave_Lending_Module.sol";
import { ITraderJoe_Swap_Module } from "./trader/modules/traderjoe/swap/ITraderJoe_Swap_Module.sol";
import { ITraderJoe_Legacy_LP_Module } from "./trader/modules/traderjoe/legacy_lp/ITraderJoe_Legacy_LP_Module.sol";
import { ITraderJoe_LP_Module } from "./trader/modules/traderjoe/lp/ITraderJoe_LP_Module.sol";
import { IInch_Swap_Module } from "./trader/modules/inch/swap/IInch_Swap_Module.sol";
import { IInch_LimitOrder_Module } from "./trader/modules/inch/limitorder/IInch_LimitOrder_Module.sol";
import { IRysk_LP_Module } from "./trader/modules/rysk/lp/IRysk_LP_Module.sol";
import { IRysk_Options_Module } from "./trader/modules/rysk/options/IRysk_Options_Module.sol";
import { IWETH_Module } from "./trader/modules/WETH.sol";
import { IRodeo_Module } from "./trader/modules/Rodeo.sol";
import { IGMXV2_Module } from "./trader/modules/GMXV2.sol";
import { IDolomite_Module } from "./trader/modules/Dolomite.sol";
import { ID2_Module } from "./trader/modules/D2.sol";

contract Strategy is AccessControl {
    struct State {
        mapping(bytes4 => address) selectors;
    }

    bytes32 internal constant STATE_SLOT = keccak256('strategy');

    constructor(
      address[] memory targets,
      TraderV0InitializerParams memory traderParams,
      address[] memory assets,
      address[] memory oracles
    ) {
        _grantRole(0x00, msg.sender);
        _grantRole(keccak256("EXECUTOR_ROLE"), msg.sender);
        State storage s;
        bytes32 slot = STATE_SLOT;
        assembly { s.slot := slot }

        address t = targets[0];
        s.selectors[ITraderV0.setVault.selector] = t;
        s.selectors[ITraderV0.approve.selector] = t;
        s.selectors[ITraderV0.custodyFunds.selector] = t;
        s.selectors[ITraderV0.returnFunds.selector] = t;
        s.selectors[ITraderV0.withdrawFees.selector] = t;
        s.selectors[ITraderV0.setFeeRates.selector] = t;
        s.selectors[ITraderV0.setFeeReceiver.selector] = t;
        s.selectors[ITraderV0.getAllowedTokens.selector] = t;
        s.selectors[ITraderV0.getAllowedSpenders.selector] = t;
        s.selectors[ITraderV0.name.selector] = t;
        s.selectors[ITraderV0.feeReceiver.selector] = t;
        s.selectors[ITraderV0.vault.selector] = t;
        s.selectors[ITraderV0.baseAsset.selector] = t;
        s.selectors[ITraderV0.performanceFeeRate.selector] = t;
        s.selectors[ITraderV0.managementFeeRate.selector] = t;
        s.selectors[ITraderV0.custodyTime.selector] = t;
        s.selectors[ITraderV0.custodiedAmount.selector] = t;
        s.selectors[ITraderV0.totalFees.selector] = t;
        s.selectors[ITraderV0.MAX_PERFORMANCE_FEE_RATE.selector] = t;
        s.selectors[ITraderV0.MAX_MANAGEMENT_FEE_RATE.selector] = t;
        initialize(t, abi.encodeWithSelector(ITraderV0.initializeTraderV0.selector, traderParams));

        t = targets[1];
        s.selectors[IGMX_Swap_Module.gmx_swap.selector] = t;
        s.selectors[IGMX_Swap_Module.gmx_swapETHToTokens.selector] = t;
        s.selectors[IGMX_Swap_Module.gmx_swapTokensToETH.selector] = t;
        t = targets[2];
        s.selectors[IGMX_PositionRouter_Module.gmx_createIncreasePosition.selector] = t;
        s.selectors[IGMX_PositionRouter_Module.gmx_createIncreasePositionETH.selector] = t;
        s.selectors[IGMX_PositionRouter_Module.gmx_createDecreasePosition.selector] = t;
        s.selectors[IGMX_PositionRouter_Module.gmx_cancelIncreasePosition.selector] = t;
        s.selectors[IGMX_PositionRouter_Module.gmx_cancelDecreasePosition.selector] = t;
        t = targets[3];
        s.selectors[IGMX_OrderBook_Module.gmx_createIncreaseOrder.selector] = t;
        s.selectors[IGMX_OrderBook_Module.gmx_createDecreaseOrder.selector] = t;
        s.selectors[IGMX_OrderBook_Module.gmx_createSwapOrder.selector] = t;
        s.selectors[IGMX_OrderBook_Module.gmx_updateIncreaseOrder.selector] = t;
        s.selectors[IGMX_OrderBook_Module.gmx_updateDecreaseOrder.selector] = t;
        s.selectors[IGMX_OrderBook_Module.gmx_cancelIncreaseOrder.selector] = t;
        s.selectors[IGMX_OrderBook_Module.gmx_cancelDecreaseOrder.selector] = t;
        s.selectors[IGMX_OrderBook_Module.gmx_cancelSwapOrder.selector] = t;
        s.selectors[IGMX_OrderBook_Module.gmx_cancelMultiple.selector] = t;
        t = targets[4];
        s.selectors[IGMX_GLP_Module.gmx_mintAndStakeGlp.selector] = t;
        s.selectors[IGMX_GLP_Module.gmx_mintAndStakeGlpETH.selector] = t;
        s.selectors[IGMX_GLP_Module.gmx_unstakeAndRedeemGlp.selector] = t;
        s.selectors[IGMX_GLP_Module.gmx_unstakeAndRedeemGlpETH.selector] = t;
        s.selectors[IGMX_GLP_Module.gmx_claim.selector] = t;
        s.selectors[IGMX_GLP_Module.gmx_compound.selector] = t;
        s.selectors[IGMX_GLP_Module.gmx_handleRewards.selector] = t;
        s.selectors[IGMX_GLP_Module.gmx_unstakeGmx.selector] = t;
        s.selectors[IGMX_GLP_Module.gmx_unstakeEsGmx.selector] = t;
        t = targets[5];
        s.selectors[ICamelot_LP_Module.camelot_addLiquidity.selector] = t;
        s.selectors[ICamelot_LP_Module.camelot_addLiquidityETH.selector] = t;
        s.selectors[ICamelot_LP_Module.camelot_removeLiquidity.selector] = t;
        s.selectors[ICamelot_LP_Module.camelot_removeLiquidityETH.selector] = t;
        t = targets[6];
        s.selectors[ICamelot_NFTPool_Module.camelot_nftpool_createPosition.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.camelot_nftpool_addToPosition.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.camelot_nftpool_harvestPosition.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.camelot_nftpool_withdrawFromPosition.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.camelot_nftpool_renewLockPosition.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.camelot_nftpool_lockPosition.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.camelot_nftpool_splitPosition.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.camelot_nftpool_mergePositions.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.camelot_nftpool_emergencyWithdraw.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.onERC721Received.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.onNFTHarvest.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.onNFTAddToPosition.selector] = t;
        s.selectors[ICamelot_NFTPool_Module.onNFTWithdraw.selector] = t;
        t = targets[7];
        s.selectors[ICamelot_NitroPool_Module.camelot_nitropool_transfer.selector] = t;
        s.selectors[ICamelot_NitroPool_Module.camelot_nitropool_withdraw.selector] = t;
        s.selectors[ICamelot_NitroPool_Module.camelot_nitropool_emergencyWithdraw.selector] = t;
        s.selectors[ICamelot_NitroPool_Module.camelot_nitropool_harvest.selector] = t;
        t = targets[8];
        s.selectors[ICamelot_Swap_Module.camelot_swapExactTokensForTokens.selector] = t;
        s.selectors[ICamelot_Swap_Module.camelot_swapExactETHForTokens.selector] = t;
        s.selectors[ICamelot_Swap_Module.camelot_swapExactTokensForETH.selector] = t;
        t = targets[9];
        s.selectors[ICamelot_V3LP_Module.camelot_v3_mint.selector] = t;
        s.selectors[ICamelot_V3LP_Module.camelot_v3_burn.selector] = t;
        s.selectors[ICamelot_V3LP_Module.camelot_v3_collect.selector] = t;
        s.selectors[ICamelot_V3LP_Module.camelot_v3_increaseLiquidity.selector] = t;
        s.selectors[ICamelot_V3LP_Module.camelot_v3_decreaseLiquidity.selector] = t;
        s.selectors[ICamelot_V3LP_Module.camelot_v3_decreaseLiquidityAndCollect.selector] = t;
        s.selectors[ICamelot_V3LP_Module.camelot_v3_decreaseLiquidityCollectAndBurn.selector] = t;
        t = targets[10];
        s.selectors[ICamelot_V3Swap_Module.camelot_v3_swap.selector] = t;
        t = targets[11];
        s.selectors[ICamelot_Storage_Module.manageNFTPools.selector] = t;
        s.selectors[ICamelot_Storage_Module.manageNitroPools.selector] = t;
        s.selectors[ICamelot_Storage_Module.manageExecutors.selector] = t;
        s.selectors[ICamelot_Storage_Module.manageReceivers.selector] = t;
        s.selectors[ICamelot_Storage_Module.getAllowedNFTPools.selector] = t;
        s.selectors[ICamelot_Storage_Module.getAllowedNitroPools.selector] = t;
        s.selectors[ICamelot_Storage_Module.getAllowedExecutors.selector] = t;
        s.selectors[ICamelot_Storage_Module.getAllowedReceivers.selector] = t;
        t = targets[12];
        s.selectors[ILyra_Storage_Module.addLyraMarket.selector] = t;
        s.selectors[ILyra_Storage_Module.removeLyraMarket.selector] = t;
        s.selectors[ILyra_Storage_Module.getAllowedLyraMarkets.selector] = t;
        s.selectors[ILyra_Storage_Module.getAllowedLyraPools.selector] = t;
        s.selectors[ILyra_Storage_Module.getLyraPoolQuoteAsset.selector] = t;
        t = targets[13];
        s.selectors[ILyra_LP_Module.lyra_initiateDeposit.selector] = t;
        s.selectors[ILyra_LP_Module.lyra_initiateWithdraw.selector] = t;
        t = targets[14];
        s.selectors[ILyra_Options_Module.lyra_openPosition.selector] = t;
        s.selectors[ILyra_Options_Module.lyra_addCollateral.selector] = t;
        s.selectors[ILyra_Options_Module.lyra_closePosition.selector] = t;
        s.selectors[ILyra_Options_Module.lyra_forceClosePosition.selector] = t;
        t = targets[15];
        s.selectors[ILyra_Rewards_Module.lyra_claimRewards.selector] = t;
        s.selectors[ILyra_Rewards_Module.lyra_claimAndDump.selector] = t;
        s.selectors[ILyra_Rewards_Module.lyra_dump.selector] = t;
        t = targets[16];
        s.selectors[IAave_Lending_Module.aave_supply.selector] = t;
        s.selectors[IAave_Lending_Module.aave_withdraw.selector] = t;
        s.selectors[IAave_Lending_Module.aave_borrow.selector] = t;
        s.selectors[IAave_Lending_Module.aave_repay.selector] = t;
        s.selectors[IAave_Lending_Module.aave_swapBorrowRateMode.selector] = t;
        s.selectors[IAave_Lending_Module.aave_setUserEMode.selector] = t;
        t = targets[17];
        s.selectors[ITraderJoe_Swap_Module.traderjoe_swapExactTokensForTokens.selector] = t;
        s.selectors[ITraderJoe_Swap_Module.traderjoe_swapExactTokensForNATIVE.selector] = t;
        s.selectors[ITraderJoe_Swap_Module.traderjoe_swapExactNATIVEForTokens.selector] = t;
        s.selectors[ITraderJoe_Swap_Module.traderjoe_swapTokensForExactTokens.selector] = t;
        s.selectors[ITraderJoe_Swap_Module.traderjoe_swapTokensForExactNATIVE.selector] = t;
        s.selectors[ITraderJoe_Swap_Module.traderjoe_swapNATIVEForExactTokens.selector] = t;
        s.selectors[ITraderJoe_Swap_Module.traderjoe_swapExactTokensForTokensSupportingFeeOnTransferTokens.selector] = t;
        s.selectors[ITraderJoe_Swap_Module.traderjoe_swapExactTokensForNATIVESupportingFeeOnTransferTokens.selector] = t;
        s.selectors[ITraderJoe_Swap_Module.traderjoe_swapExactNATIVEForTokensSupportingFeeOnTransferTokens.selector] = t;
        t = targets[18];
        s.selectors[ITraderJoe_Legacy_LP_Module.traderjoe_legacy_addLiquidity.selector] = t;
        s.selectors[ITraderJoe_Legacy_LP_Module.traderjoe_legacy_addLiquidityAVAX.selector] = t;
        s.selectors[ITraderJoe_Legacy_LP_Module.traderjoe_legacy_removeLiquidity.selector] = t;
        s.selectors[ITraderJoe_Legacy_LP_Module.traderjoe_legacy_removeLiquidityAVAX.selector] = t;
        s.selectors[ITraderJoe_Legacy_LP_Module.traderjoe_legacy_setApprovalForAll.selector] = t;
        t = targets[19];
        s.selectors[ITraderJoe_LP_Module.traderjoe_addLiquidity.selector] = t;
        s.selectors[ITraderJoe_LP_Module.traderjoe_addLiquidityNATIVE.selector] = t;
        s.selectors[ITraderJoe_LP_Module.traderjoe_removeLiquidity.selector] = t;
        s.selectors[ITraderJoe_LP_Module.traderjoe_removeLiquidityNATIVE.selector] = t;
        s.selectors[ITraderJoe_LP_Module.traderjoe_approveForAll.selector] = t;
        t = targets[20];
        s.selectors[IInch_Swap_Module.inch_swap.selector] = t;
        s.selectors[IInch_Swap_Module.inch_uniswapV3Swap.selector] = t;
        s.selectors[IInch_Swap_Module.inch_clipperSwap.selector] = t;
        t = targets[21];
        s.selectors[IInch_LimitOrder_Module.inch_fillOrder.selector] = t;
        s.selectors[IInch_LimitOrder_Module.inch_cancelOrder.selector] = t;
        s.selectors[IInch_LimitOrder_Module.inch_addOrder.selector] = t;
        s.selectors[IInch_LimitOrder_Module.inch_removeOrder.selector] = t;
        s.selectors[IInch_LimitOrder_Module.isValidSignature.selector] = t;
        s.selectors[IInch_LimitOrder_Module.inch_getHashes.selector] = t;
        s.selectors[IInch_LimitOrder_Module.inch_getOracleForAsset.selector] = t;
        initialize(t, abi.encodeWithSelector(IInch_LimitOrder_Module.init_Inch_LimitOrder.selector, assets, oracles));
        t = targets[22];
        s.selectors[IRysk_LP_Module.rysk_deposit.selector] = t;
        s.selectors[IRysk_LP_Module.rysk_redeem.selector] = t;
        s.selectors[IRysk_LP_Module.rysk_initiateWithdraw.selector] = t;
        s.selectors[IRysk_LP_Module.rysk_completeWithdraw.selector] = t;
        t = targets[23];
        s.selectors[IRysk_Options_Module.rysk_executeOrder.selector] = t;
        s.selectors[IRysk_Options_Module.rysk_executeBuyBackOrder.selector] = t;
        s.selectors[IRysk_Options_Module.rysk_executeStrangle.selector] = t;
        t = targets[24];
        s.selectors[IWETH_Module.weth_deposit.selector] = t;
        s.selectors[IWETH_Module.weth_withdraw.selector] = t;
        t = targets[25];
        s.selectors[IRodeo_Module.rodeo_mint.selector] = t;
        s.selectors[IRodeo_Module.rodeo_edit.selector] = t;
        s.selectors[IRodeo_Module.rodeo_burn.selector] = t;
        t = targets[26];
        s.selectors[IGMXV2_Module.gmxv2_create.selector] = t;
        s.selectors[IGMXV2_Module.gmxv2_update.selector] = t;
        s.selectors[IGMXV2_Module.gmxv2_cancel.selector] = t;
        s.selectors[IGMXV2_Module.gmxv2_claimFees.selector] = t;
        t = targets[27];
        s.selectors[IDolomite_Module.dolomite_depositWei.selector] = t;
        s.selectors[IDolomite_Module.dolomite_depositETH.selector] = t;
        s.selectors[IDolomite_Module.dolomite_depositWeiIntoDefaultAccount.selector] = t;
        s.selectors[IDolomite_Module.dolomite_depositETHIntoDefaultAccount.selector] = t;
        s.selectors[IDolomite_Module.dolomite_withdrawWei.selector] = t;
        s.selectors[IDolomite_Module.dolomite_withdrawETH.selector] = t;
        s.selectors[IDolomite_Module.dolomite_withdrawWeiFromDefaultAccount.selector] = t;
        s.selectors[IDolomite_Module.dolomite_withdrawETHFromDefaultAccount.selector] = t;
        s.selectors[IDolomite_Module.dolomite_depositPar.selector] = t;
        s.selectors[IDolomite_Module.dolomite_depositParIntoDefaultAccount.selector] = t;
        s.selectors[IDolomite_Module.dolomite_withdrawPar.selector] = t;
        s.selectors[IDolomite_Module.dolomite_withdrawParFromDefaultAccount.selector] = t;
        s.selectors[IDolomite_Module.dolomite_openBorrowPosition.selector] = t;
        s.selectors[IDolomite_Module.dolomite_closeBorrowPosition.selector] = t;
        s.selectors[IDolomite_Module.dolomite_transferBetweenAccounts.selector] = t;
        s.selectors[IDolomite_Module.dolomite_repayAllForBorrowPosition.selector] = t;
        s.selectors[IDolomite_Module.dolomite_openBorrowPositionWithDifferentAccounts.selector] = t;
        s.selectors[IDolomite_Module.dolomite_closeBorrowPositionWithDifferentAccounts.selector] = t;
        s.selectors[IDolomite_Module.dolomite_transferBetweenAccountsWithDifferentAccounts.selector] = t;
        s.selectors[IDolomite_Module.dolomite_repayAllForBorrowPositionWithDifferentAccounts.selector] = t;
        t = targets[28];
        s.selectors[ID2_Module.d2_deposit.selector] = t;
        s.selectors[ID2_Module.d2_withdraw.selector] = t;
    }

    function initialize(address target, bytes memory data) internal {
        (bool success,) = target.delegatecall(data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        State storage s;
        bytes32 slot = STATE_SLOT;
        assembly { s.slot := slot }
        address target = s.selectors[msg.sig];
        if (target == address(0)) {
            revert("unknown signature");
        }
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControl } from './IAccessControl.sol';
import { AccessControlInternal } from './AccessControlInternal.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControl is IAccessControl, AccessControlInternal {
    /**
     * @inheritdoc IAccessControl
     */
    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return _getRoleAdmin(role);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role) external {
        _renounceRole(role);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IVault.sol";

/**
 * @param   _name                       Strategy name
 * @param   _allowedTokens              ERC-20 tokens to include in the strategy's mandate
 * @param   _allowedSpenders            Addresses which can receive ERC-20 token approval
 * @param   _initialPerformanceFeeRate  Initial value of the performance fee, in units of 1e18 = 100%
 * @param   _initialManagementFeeRate   Initial value of the management fee, in units of 1e18 = 100%
 */
struct TraderV0InitializerParams {
    string _name;
    address[] _allowedTokens;
    address[] _allowedSpenders;
    uint256 _initialPerformanceFeeRate;
    uint256 _initialManagementFeeRate;
}

/**
 * @title   DSquared Trader V0 Core Interface
 * @notice  Interfaces with the Vault contract, handling custody, returning, and fee-taking
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ITraderV0 {
    // ---------- Construction and Initialization ----------

    function initializeTraderV0(TraderV0InitializerParams calldata _params) external;

    /**
     * @notice  Set this strategy's vault address
     * @dev     May only be set once
     * @param   _vault  Vault address
     */
    function setVault(address _vault) external;

    // ---------- Operation ----------

    /**
     * @notice  Approve a whitelisted spender to handle one of the whitelisted tokens
     * @param   _token      Token to set approval for
     * @param   _spender    Spending address
     * @param   _amount     Token amount
     */
    function approve(address _token, address _spender, uint256 _amount) external;

    /**
     * @notice  Take custody of the vault's funds
     * @dev     Relies on Vault contract to revert if called out of sequence.
     */
    function custodyFunds() external;

    /**
     * @notice  Return the vault's funds and take fees if enabled
     * @dev     WARNING: Unwind all positions back into the base asset before returning funds.
     * @dev     Relies on Vault contract to revert if called out of sequence.
     */
    function returnFunds() external;

    /**
     * @notice  Withdraw all accumulated fees
     * @dev     This should be done before the start of the next epoch to avoid fees becoming mixed with vault funds
     */
    function withdrawFees() external;

    // --------- Configuration ----------

    /**
     * @notice  Set new performance and management fees
     * @notice  May not be set while funds are custodied
     * @param   _performanceFeeRate     New management fee (100% = 1e18)
     * @param   _managementFeeRate      New management fee (100% = 1e18)
     */
    function setFeeRates(uint256 _performanceFeeRate, uint256 _managementFeeRate) external;

    /**
     * @notice  Set a new fee receiver address
     * @param   _feeReceiver   Address which will receive fees from the contract
     */
    function setFeeReceiver(address _feeReceiver) external;

    // --------- View Functions ---------

    /**
     * @notice  View all tokens the contract is allowed to handle
     * @return  List of token addresses
     */
    function getAllowedTokens() external view returns (address[] memory);

    /**
     * @notice  View all addresses which can recieve token approvals
     * @return  List of addresses
     */
    function getAllowedSpenders() external view returns (address[] memory);

    // ----- State Variable Getters -----

    /// @notice Strategy name
    function name() external view returns (string memory);

    /// @notice Address receiving fees
    function feeReceiver() external view returns (address);

    /// @notice Vault address
    function vault() external view returns (IVault);

    /// @notice Underlying asset of the strategy's vault
    function baseAsset() external view returns (IERC20);

    /// @notice Performance fee as percentage of profits, in units of 1e18 = 100%
    function performanceFeeRate() external view returns (uint256);

    /// @notice Management fee as percentage of base assets, in units of 1e18 = 100%
    function managementFeeRate() external view returns (uint256);

    /// @notice Timestamp when funds were taken into custody, in Unix epoch seconds
    function custodyTime() external view returns (uint256);

    /// @notice Amount of base asset taken into custody
    function custodiedAmount() external view returns (uint256);

    /// @notice Accumulated management and performance fees
    function totalFees() external view returns (uint256);

    /// @notice Maximum allowable performance fee as percentage of profits, in units of 1e18 = 100%
    function MAX_PERFORMANCE_FEE_RATE() external view returns (uint256);

    /// @notice Maximum allowable management fee as percentage of base assets per year, in units of 1e18 = 100%
    function MAX_MANAGEMENT_FEE_RATE() external view returns (uint256);

    // --------- Hooks ---------

    receive() external payable;

    // ----- Events -----

    event FundsReturned(uint256 startingBalance, uint256 closingBalance, uint256 performanceFee, uint256 managementFee);
    event FeesWithdrawn(address indexed withdrawer, uint256 amount);

    event FeesSet(uint256 oldPerformanceFee, uint256 newPerformanceFee, uint256 oldManagementFee, uint256 newManagementFee);
    event FeeReceiverSet(address oldFeeReceiver, address newFeeReceiver);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/gmx_interfaces/IRouter.sol";

/**
 * @title   DSquared GMX Swap Module Interface
 * @notice  Allows direct swapping via the GMX Router contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface IGMX_Swap_Module {
    // ---------- Functions ----------
    function gmx_swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function gmx_swapETHToTokens(uint256 _valueIn, address[] memory _path, uint256 _minOut, address _receiver) external;

    function gmx_swapTokensToETH(address[] memory _path, uint256 _amountIn, uint256 _minOut, address payable _receiver) external;

    // ---------- Getters ----------

    function gmx_router() external view returns (IRouter);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/gmx_interfaces/IRouter.sol";
import "../../../external/gmx_interfaces/IPositionRouter.sol";

/**
 * @title   DSquared GMX PositionRouter Module Interface
 * @notice  Allows leveraged long/short positions to be opened on the GMX Position Router
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface IGMX_PositionRouter_Module {
    // ---------- Functions ----------

    function init_GMX_PositionRouter() external;

    /**
     * @dev     Approval must be handled via another function
     */
    function gmx_createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    /**
     * @dev     Note the _valueIn parameter, which does not exist in the direct GMX call
     * @param   _valueIn    Wei of the contract's ETH to transfer as msg.value with the createIncreasePosition call
     */
    function gmx_createIncreasePositionETH(
        uint256 _valueIn,
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function gmx_createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function gmx_cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function gmx_cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    // ---------- Getters ----------

    function gmx_router() external view returns (IRouter);

    function gmx_positionRouter() external view returns (IPositionRouter);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/gmx_interfaces/IRouter.sol";
import "../../../external/gmx_interfaces/IOrderBook.sol";

/**
 * @title   DSquared GMX OrderBook Module Interface
 * @notice  Allows limit orders to be opened on the GMX Order Book
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface IGMX_OrderBook_Module {
    function init_GMX_OrderBook() external;

    // ---------- Functions ----------

    function gmx_createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function gmx_createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee
    ) external payable;

    function gmx_createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable;

    function gmx_updateIncreaseOrder(uint256 _orderIndex, uint256 _sizeDelta, uint256 _triggerPrice, bool _triggerAboveThreshold) external;

    function gmx_updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function gmx_cancelIncreaseOrder(uint256 _orderIndex) external;

    function gmx_cancelDecreaseOrder(uint256 _orderIndex) external;

    function gmx_cancelSwapOrder(uint256 _orderIndex) external;

    function gmx_cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    // ---------- Getters ----------

    function gmx_router() external view returns (IRouter);

    function gmx_orderBook() external view returns (IOrderBook);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/gmx_interfaces/IRewardRouterV2.sol";

/**
 * @title   DSquared GMX GLP Module Interface
 * @notice  Allows depositing, withdrawing, and claiming rewards in the GLP ecosystem
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface IGMX_GLP_Module {
    // ---------- Functions ----------
    function gmx_mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);

    function gmx_mintAndStakeGlpETH(uint256 _valueIn, uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);

    function gmx_unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);

    function gmx_unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) external returns (uint256);

    function gmx_claim() external;

    function gmx_compound() external;

    function gmx_handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function gmx_unstakeGmx(uint256 _amount) external;

    function gmx_unstakeEsGmx(uint256 _amount) external;

    // ---------- Getters ----------

    function gmx_GLPRewardRouter() external returns (IRewardRouterV2);

    function gmx_GMXRewardRouter() external returns (IRewardRouterV2);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   DSquared Camelot LP Module Interface
 * @notice  Allows adding and removing liquidity via the CamelotRouter contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ICamelot_LP_Module {
    // ---------- Functions ----------

    function camelot_addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external;

    function camelot_addLiquidityETH(
        uint valueIn,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external;

    function camelot_removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external;

    function camelot_removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external;

    // ---------- Getters ----------
    function camelot_router() external view returns (address);

    function weth() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   DSquared Camelot NFTPool Module Interface
 * @notice  Allows integration with Camelot NFT Pools
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ICamelot_NFTPool_Module {
    // ---------- Functions ----------

    function camelot_nftpool_createPosition(address _poolAddress, uint256 _amount, uint256 _lockDuration) external;

    function camelot_nftpool_addToPosition(address _poolAddress, uint256 _tokenId, uint256 _amountToAdd) external;

    function camelot_nftpool_harvestPosition(address _poolAddress, uint256 _tokenId) external;

    function camelot_nftpool_withdrawFromPosition(address _poolAddress, uint256 _tokenId, uint256 _amountToWithdraw) external;

    function camelot_nftpool_renewLockPosition(address _poolAddress, uint256 _tokenId) external;

    function camelot_nftpool_lockPosition(address _poolAddress, uint256 _tokenId, uint256 _lockDuration) external;

    function camelot_nftpool_splitPosition(address _poolAddress, uint256 _tokenId, uint256 _splitAmount) external;

    function camelot_nftpool_mergePositions(address _poolAddress, uint256[] calldata _tokenIds, uint256 _lockDuration) external;

    function camelot_nftpool_emergencyWithdraw(address _poolAddress, uint256 _tokenId) external;

    // ---------- Callbacks ----------

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4);

    function onNFTHarvest(
        address operator,
        address to,
        uint256 tokenId,
        uint256 grailAmount,
        uint256 xGrailAmount
    ) external pure returns (bool);

    function onNFTAddToPosition(address operator, uint256 tokenId, uint256 lpAmount) external pure returns (bool);

    function onNFTWithdraw(address operator, uint256 tokenId, uint256 lpAmount) external pure returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   DSquared Camelot NitroPool Module Interface
 * @notice  Allows integration with Camelot Nitro Pools
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ICamelot_NitroPool_Module {
    // ---------- Functions ----------

    function camelot_nitropool_transfer(address _nitroPoolAddress, address _nftPoolAddress, uint256 _tokenId) external;

    function camelot_nitropool_withdraw(address _poolAddress, uint256 _tokenId) external;

    function camelot_nitropool_emergencyWithdraw(address _poolAddress, uint256 _tokenId) external;

    function camelot_nitropool_harvest(address _poolAddress) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   DSquared Camelot Swap Module Interface
 * @notice  Allows direct swapping via the CamelotRouter contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ICamelot_Swap_Module {
    // ---------- Functions ----------

    function camelot_swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function camelot_swapExactETHForTokens(
        uint valueIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function camelot_swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    // ---------- Getters ----------

    function camelot_router() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../storage/Camelot_Common_Storage.sol";
import "../../../external/camelot_interfaces/INonfungiblePositionManager.sol";
import "../../../external/camelot_interfaces/IOdosRouter.sol";

/**
 * @title   DSquared Camelot V3 LP Module Interface
 * @notice  Allows adding and removing liquidity via the NonfungiblePositionManager contract
 * @notice  Allows swapping via the OdosRouter contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ICamelot_V3LP_Module {
    // ---------- Functions ----------

    function camelot_v3_mint(uint256 valueIn, INonfungiblePositionManager.MintParams calldata params) external returns (uint256);

    function camelot_v3_burn(uint256 tokenId) external;

    function camelot_v3_collect(INonfungiblePositionManager.CollectParams memory params) external;

    function camelot_v3_increaseLiquidity(uint256 valueIn, INonfungiblePositionManager.IncreaseLiquidityParams calldata params) external;

    function camelot_v3_decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams calldata params) external;

    function camelot_v3_decreaseLiquidityAndCollect(
        INonfungiblePositionManager.DecreaseLiquidityParams calldata decreaseParams,
        INonfungiblePositionManager.CollectParams memory collectParams
    ) external;

    function camelot_v3_decreaseLiquidityCollectAndBurn(
        INonfungiblePositionManager.DecreaseLiquidityParams calldata decreaseParams,
        INonfungiblePositionManager.CollectParams memory collectParams,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../storage/Camelot_Common_Storage.sol";
import "../../../external/camelot_interfaces/INonfungiblePositionManager.sol";
import "../../../external/camelot_interfaces/IOdosRouter.sol";

/**
 * @title   DSquared Camelot V3 Swap Module Interface
 * @notice  Allows swapping via the OdosRouter contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ICamelot_V3Swap_Module {
    // ---------- Functions ----------

    function camelot_v3_swap(
        uint256 valueIn,
        IOdosRouter.inputToken[] memory inputs,
        IOdosRouter.outputToken[] memory outputs,
        uint256 valueOutQuote,
        uint256 valueOutMin,
        address executor,
        bytes calldata pathDefinition
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/camelot_interfaces/INFTPoolFactory.sol";

/**
 * @title   DSquared Camelot Storage Module Interface
 * @notice  Allows interacting with Camelot common storage
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ICamelot_Storage_Module {
    // --------- External Functions ---------

    function manageNFTPools(address[] calldata _pools, bool[] calldata _status) external;

    function manageNitroPools(address[] calldata _pools, bool[] calldata _status, uint256[] calldata _indexes) external;

    function manageExecutors(address[] calldata _executors, bool[] calldata _status) external;

    function manageReceivers(address[] calldata _receivers, bool[] calldata _status) external;

    // --------- Getter Functions ---------

    function camelot_nftpool_factory() external view returns (INFTPoolFactory);

    function getAllowedNFTPools() external view returns (address[] memory);

    function getAllowedNitroPools() external view returns (address[] memory);

    function getAllowedExecutors() external view returns (address[] memory);

    function getAllowedReceivers() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/lyra_interfaces/ILyraRegistry.sol";

/**
 * @title   DSquared Lyra Storage Module Interface
 * @notice  Protocol addresses, constants, and functions used by all Lyra modules
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ILyra_Storage_Module {
    // ----- Events -----

    event NewLyraMarket(address market, address pool);
    event RemovedLyraMarket(address market, address pool);

    // --------- External Functions ---------

    function addLyraMarket(address _optionMarket) external;

    function removeLyraMarket(address _optionMarket) external;

    // --------- Views ---------

    function getAllowedLyraMarkets() external view returns (address[] memory);

    function getAllowedLyraPools() external view returns (address[] memory);

    function getLyraPoolQuoteAsset(address _pool) external view returns (address);

    function lyra_registry() external view returns (ILyraRegistry);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title   DSquared Lyra LP Module Interface
 * @notice  Allows depositing and withdrawing liquidity via the Lyra LiquidityPool Contract
 * @dev     All known Lyra pools require USDC. Any integrating strategy must have USDC in its token mandate.
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ILyra_LP_Module {
    // ---------- Functions ----------

    function lyra_initiateDeposit(address pool, address beneficiary, uint256 amountQuote) external;

    function lyra_initiateWithdraw(address pool, address beneficiary, uint256 amountLiquidityToken) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/lyra_interfaces/IOptionMarket.sol";

/**
 * @title   DSquared Lyra Options Module Interface
 * @notice  Allows opening and closing options positions via the Lyra OptionMarket Contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ILyra_Options_Module {
    function lyra_openPosition(address market, IOptionMarket.TradeInputParameters memory params) external;

    function lyra_addCollateral(address market, uint256 positionId, uint256 amountCollateral) external;

    function lyra_closePosition(address market, IOptionMarket.TradeInputParameters memory params) external;

    function lyra_forceClosePosition(address market, IOptionMarket.TradeInputParameters memory params) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title   DSquared Lyra Rewards Module Interface
 * @notice  Allows claiming rewards from Lyra MultiDistributor
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ILyra_Rewards_Module {
    struct SwapInput {
        address[] path;
        uint256 minOut;
    }

    function lyra_claimRewards(uint[] memory _claimList) external;

    function lyra_claimAndDump(uint[] memory _claimList, SwapInput[] memory _inputs) external;

    function lyra_dump(SwapInput[] memory _inputs) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../external/aave_interfaces/IPool.sol";

/**
 * @title   DSquared Aave Lending Module Interface
 * @notice  Allows lending and borrowing via the Aave Pool Contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface IAave_Lending_Module {
    // ---------- Functions ----------

    function aave_supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function aave_withdraw(address asset, uint256 amount, address to) external;

    function aave_borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address to) external;

    function aave_repay(address asset, uint256 amount, uint256 interestRateMode, address to) external;

    function aave_swapBorrowRateMode(address asset, uint256 interestRateMode) external;

    function aave_setUserEMode(uint8 categoryId) external;

    // ---------- Getters ----------

    function aave_pool() external view returns (IPool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILBRouter } from "../../../external/traderjoe_interfaces/ILBRouter.sol";

/**
 * @title   DSquared
 * @notice  Allows direct swapping via the LBRouter contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ITraderJoe_Swap_Module {
    // ---------- Functions ----------

    function traderjoe_swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        ILBRouter.Path memory path,
        address to,
        uint256 deadline
    ) external;

    function traderjoe_swapExactTokensForNATIVE(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        ILBRouter.Path memory path,
        address payable to,
        uint256 deadline
    ) external;

    function traderjoe_swapExactNATIVEForTokens(
        uint256 valueIn,
        uint256 amountOutMin,
        ILBRouter.Path memory path,
        address to,
        uint256 deadline
    ) external;

    function traderjoe_swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        ILBRouter.Path memory path,
        address to,
        uint256 deadline
    ) external;

    function traderjoe_swapTokensForExactNATIVE(
        uint256 amountOut,
        uint256 amountInMax,
        ILBRouter.Path memory path,
        address payable to,
        uint256 deadline
    ) external;

    function traderjoe_swapNATIVEForExactTokens(
        uint256 valueIn,
        uint256 amountOut,
        ILBRouter.Path memory path,
        address to,
        uint256 deadline
    ) external payable;

    function traderjoe_swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        ILBRouter.Path memory path,
        address to,
        uint256 deadline
    ) external;

    function traderjoe_swapExactTokensForNATIVESupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        ILBRouter.Path memory path,
        address payable to,
        uint256 deadline
    ) external;

    function traderjoe_swapExactNATIVEForTokensSupportingFeeOnTransferTokens(
        uint256 valueIn,
        uint256 amountOutMin,
        ILBRouter.Path memory path,
        address to,
        uint256 deadline
    ) external payable;

    // ---------- Getters ----------

    function traderjoe_router() external view returns (ILBRouter);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILBLegacyRouter } from "../../../external/traderjoe_interfaces/ILBLegacyRouter.sol";
import "../../../external/traderjoe_interfaces/ILBLegacyFactory.sol";

/**
 * @title   DSquared TraderJoe Legacy LP Module Interface
 * @notice  Allows adding/removing liquidity via the TraderJoe LBLegacyRouter contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ITraderJoe_Legacy_LP_Module {
    // ---------- Functions ----------

    function traderjoe_legacy_addLiquidity(ILBLegacyRouter.LiquidityParameters calldata liquidityParameters) external;

    function traderjoe_legacy_addLiquidityAVAX(uint256 valueIn, ILBLegacyRouter.LiquidityParameters calldata liquidityParameters) external;

    function traderjoe_legacy_removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external;

    function traderjoe_legacy_removeLiquidityAVAX(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external;

    function traderjoe_legacy_setApprovalForAll(address tokenX, address tokenY, uint256 binStep) external;

    // ---------- Getters ----------

    function traderjoe_legacy_router() external view returns (ILBLegacyRouter);

    function traderjoe_legacy_factory() external view returns (ILBLegacyFactory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILBRouter } from "../../../external/traderjoe_interfaces/ILBRouter.sol";
import "../../../external/traderjoe_interfaces/ILBFactory.sol";

/**
 * @title   DSquared
 * @notice  Allows adding/removing liquidity via the TraderJoe LBRouter contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface ITraderJoe_LP_Module {
    // ---------- Functions ----------

    function traderjoe_addLiquidity(ILBRouter.LiquidityParameters calldata liquidityParameters) external;

    function traderjoe_addLiquidityNATIVE(uint256 valueIn, ILBRouter.LiquidityParameters calldata liquidityParameters) external;

    function traderjoe_removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external;

    function traderjoe_removeLiquidityNATIVE(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external;

    function traderjoe_approveForAll(address tokenX, address tokenY, uint256 binStep) external;

    // ---------- Getters ----------

    function traderjoe_router() external view returns (ILBRouter);

    function traderjoe_factory() external view returns (ILBFactory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/inch_interfaces/IAggregationRouter.sol";
import "../../../external/inch_interfaces/IAggregationExecutor.sol";
import "../../../external/clipper_interfaces/IClipperExchangeInterface.sol";

/**
 * @title   DSquared Inch Swap Module Interface
 * @notice  Allows swapping via the 1Inch AggregationRouter contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface IInch_Swap_Module {
    // ---------- Functions ----------

    function inch_swap(
        uint256 valueIn,
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external returns (uint256 returnAmount, uint256 spentAmount);

    function inch_uniswapV3Swap(
        uint256 valueIn,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external returns (uint256 returnAmount);

    function inch_clipperSwap(
        uint256 valueIn,
        IClipperExchangeInterface clipperExchange,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) external returns (uint256 returnAmount);

    // ---------- Getters ----------

    function inch_aggregation_router() external view returns (IAggregationRouter);

    function inch_clipper_exchange() external view returns (IClipperExchangeInterface);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/inch_interfaces/IAggregationRouter.sol";

/**
 * @title   HessianX Inch LimitOrder Module Interface
 * @notice  Allows filling, creating and cancelling limit orders via the 1Inch AggregationRouter contract
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface IInch_LimitOrder_Module {
    // ---------- Functions ----------

    function inch_fillOrder(
        uint256 valueIn,
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount
    ) external;

    function inch_cancelOrder(OrderLib.Order calldata order) external;

    function inch_addOrder(OrderLib.Order calldata order) external;

    function inch_removeOrder(OrderLib.Order calldata order) external;

    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);

    function init_Inch_LimitOrder(address[] memory _assets, address[] memory _oracles) external;

    // ---------- Getters ----------

    function inch_aggregation_router() external view returns (IAggregationRouter);

    function SLIPPAGE_PERCENTAGE() external view returns (uint32);

    function inch_getHashes() external view returns (bytes32[] memory);

    function inch_getOracleForAsset(address asset) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/rysk_interfaces/Rysk_ILiquidityPool.sol";

/**
 * @title   DSquared Rysk LP Module Interface
 * @notice  Allows depositing, redeeming and withdrawing liquidity via the Rysk LiquidityPool Contract
 * @dev     Requires USDC. Any integrating strategy must have USDC in its token mandate.
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface IRysk_LP_Module {
    // ---------- Functions ----------

    function rysk_deposit(uint256 _amount) external;

    function rysk_redeem(uint256 _shares) external;

    function rysk_initiateWithdraw(uint256 _shares) external;

    function rysk_completeWithdraw() external;

    // ---------- Views ----------

    function rysk_liquidity_pool() external view returns (Rysk_ILiquidityPool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/rysk_interfaces/IAlphaOptionHandler.sol";

/**
 * @title   DSquared
 * @notice  Allows executing options via the Rysk AlphaOptionHandler contract
 * @dev     Requires USDC. Any integrating strategy must have USDC in its token mandate.
 * @dev     This contract is ONLY suitable for use with underlying tokens with 18 decimals.
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
interface IRysk_Options_Module {
    // ---------- Functions ----------

    function rysk_executeOrder(uint256 _orderId) external;

    function rysk_executeBuyBackOrder(uint256 _orderId) external;

    function rysk_executeStrangle(uint256 _orderId1, uint256 _orderId2) external;

    // ---------- Views ----------

    function rysk_alpha_option_handler() external view returns (IAlphaOptionHandler);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "./dsq/DSQ_Common_Roles.sol";
import "../external/IWETH.sol";

interface IWETH_Module {
    function weth_deposit(uint256 amount) external;
    function weth_withdraw(uint256 amount) external;
}

contract WETH_Module is IWETH_Module, AccessControl, ReentrancyGuard, DSQ_Common_Roles {
    IWETH public immutable weth;

    constructor(address _weth) {
      require(_weth != address(0), "WETH_Module: Zero address");
      weth = IWETH(_weth);
    }

    function weth_deposit(uint256 amount) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        weth.deposit{value: amount}();
    }

    function weth_withdraw(uint256 amount) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        weth.withdraw(amount);
    }
}

abstract contract WETH_Cutter is DiamondWritableInternal, ERC165Base {
    function cut_WETH(address _facet) internal {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = IWETH_Module.weth_deposit.selector;
        selectors[1] = IWETH_Module.weth_withdraw.selector;
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut({
          target: _facet, action: FacetCutAction.ADD, selectors: selectors
        });
        _diamondCut(cuts, address(0), "");
        _setSupportsInterface(type(IWETH_Module).interfaceId, true);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "./dsq/DSQ_Common_Roles.sol";

interface IRodeoPositionManager {
    function mint(address to, address pol, uint256 str, uint256 amt, uint256 bor, bytes calldata dat) external;
    function edit(uint256 id, int256 amt, int256 bor, bytes calldata dat) external;
    function burn(uint256 id) external;
}

interface IRodeoPool {
    function mint(uint256 amt, address usr) external;
    function burn(uint256 sha, address usr) external;
}

interface IRodeo_Module {
    function rodeo_mint(address pool, uint256 strategy, uint256 amount, uint256 borrow) external;
    function rodeo_edit(uint256 id, int256 amount, int256 borrow) external;
    function rodeo_burn(uint256 id) external;
    function rodeo_pool_mint(uint256 amount) external;
    function rodeo_pool_burn(uint256 shares) external;
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4);
}

contract Rodeo_Module is IRodeo_Module, AccessControl, ReentrancyGuard, DSQ_Common_Roles {
    IRodeoPositionManager public immutable pm;
    IRodeoPool public immutable pool;

    constructor(address _pm, address _pool) {
        require(_pm != address(0), "Rodeo_Module: Zero address");
        pm = IRodeoPositionManager(_pm);
        pool = IRodeoPool(_pool);
    }

    function rodeo_mint(address pool, uint256 strategy, uint256 amount, uint256 borrow) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        pm.mint(address(this), pool, strategy, amount, borrow, "");
    }

    function rodeo_edit(uint256 id, int256 amount, int256 borrow) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        pm.edit(id, amount, borrow, "");
    }

    function rodeo_burn(uint256 id) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        pm.burn(id);
    }

    function rodeo_pool_mint(uint256 amount) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        pool.mint(amount, address(this));
    }

    function rodeo_pool_burn(uint256 shares) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        pool.burn(shares, address(this));
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

abstract contract Rodeo_Cutter is DiamondWritableInternal, ERC165Base {
    function cut_Rodeo(address _facet) internal {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = IRodeo_Module.rodeo_mint.selector;
        selectors[1] = IRodeo_Module.rodeo_edit.selector;
        selectors[2] = IRodeo_Module.rodeo_burn.selector;
        selectors[3] = IRodeo_Module.rodeo_pool_mint.selector;
        selectors[4] = IRodeo_Module.rodeo_pool_burn.selector;
        //selectors[5] = IRodeo_Module.onERC721Received.selector; // Added by Camelot
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut({
          target: _facet, action: FacetCutAction.ADD, selectors: selectors
        });
        _diamondCut(cuts, address(0), "");
        _setSupportsInterface(type(IRodeo_Module).interfaceId, true);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "./dsq/DSQ_Common_Roles.sol";

interface IERC20 {
  function approve(address spender, uint256 amount) external;
}

interface IExchangeRouter {
    enum OrderType {
        MarketSwap,
        LimitSwap,
        MarketIncrease,
        LimitIncrease,
        MarketDecrease,
        LimitDecrease,
        StopLossDecrease
    }
    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }
    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }
    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }
    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }

    function sendWnt(address receiver, uint256 amount) external payable;
    function sendTokens(address token, address receiver, uint256 amount) external payable;
    function createOrder(CreateOrderParams calldata params) external payable returns (bytes32);
    function updateOrder(bytes32 key, uint256 sizeDeltaUsd, uint256 acceptablePrice, uint256 triggerPrice, uint256 minOutputAmount) external payable;
    function cancelOrder(bytes32 key) external payable;
    function claimFundingFees(address[] memory markets, address[] memory tokens, address receiver) external payable;
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
    function router() external returns (address);
}

interface IGMXV2_Module {
    function gmxv2_create(
        address market, address collateral, address[] calldata path,
        IExchangeRouter.OrderType orderType, IExchangeRouter.DecreasePositionSwapType decreasePositionSwapType, bool isLong,
        uint256 sizeDeltaUsd, uint256 initialCollateralDeltaAmount,
        uint256 triggerPrice, uint256 acceptablePrice, uint256 minOutputAmount,
        uint256 executionFee
    ) external payable;
    function gmxv2_update(bytes32 key, uint256 sizeDeltaUsd, uint256 acceptablePrice, uint256 triggerPrice, uint256 minOutputAmount) external;
    function gmxv2_cancel(bytes32 key) external;
    function gmxv2_claimFees(address[] memory markets, address[] memory tokens) external;
}

contract GMXV2_Module is IGMXV2_Module, AccessControl, ReentrancyGuard, DSQ_Common_Roles {
    IExchangeRouter public immutable exchangeRouter;
    address public immutable orderVault;

    constructor(address _exchangeRouter, address _orderVault) {
        exchangeRouter = IExchangeRouter(_exchangeRouter);
        orderVault = _orderVault;
    }

    function gmxv2_create(
      address market, address collateral, address[] calldata path,
      IExchangeRouter.OrderType orderType, IExchangeRouter.DecreasePositionSwapType decreasePositionSwapType, bool isLong,
      uint256 sizeDeltaUsd, uint256 initialCollateralDeltaAmount,
      uint256 triggerPrice, uint256 acceptablePrice, uint256 minOutputAmount,
      uint256 executionFee
    ) external payable onlyRole(EXECUTOR_ROLE) nonReentrant {
          IExchangeRouter.CreateOrderParams memory params = IExchangeRouter.CreateOrderParams({
              addresses: IExchangeRouter.CreateOrderParamsAddresses({
                  receiver: address(this),
                  callbackContract: address(0),
                  uiFeeReceiver: address(0),
                  market: market,
                  initialCollateralToken: collateral,
                  swapPath: path
              }),
              numbers: IExchangeRouter.CreateOrderParamsNumbers({
                  sizeDeltaUsd: sizeDeltaUsd,
                  initialCollateralDeltaAmount: initialCollateralDeltaAmount,
                  triggerPrice: triggerPrice,
                  acceptablePrice: acceptablePrice,
                  executionFee: executionFee,
                  callbackGasLimit: 0,
                  minOutputAmount: minOutputAmount
              }),
              orderType: orderType,
              decreasePositionSwapType: decreasePositionSwapType,
              isLong: isLong,
              shouldUnwrapNativeToken: false,
              referralCode: ""
          });
          if (orderType == IExchangeRouter.OrderType.LimitSwap || orderType == IExchangeRouter.OrderType.MarketIncrease || orderType == IExchangeRouter.OrderType.LimitIncrease) {
              IERC20(collateral).approve(exchangeRouter.router(), initialCollateralDeltaAmount);
              bytes[] memory data = new bytes[](3);
              data[0] = abi.encodeWithSelector(IExchangeRouter.sendWnt.selector, orderVault, executionFee);
              data[1] = abi.encodeWithSelector(IExchangeRouter.sendTokens.selector, collateral, orderVault, initialCollateralDeltaAmount);
              data[2] = abi.encodeWithSelector(IExchangeRouter.createOrder.selector, params);
              exchangeRouter.multicall{value: executionFee}(data);
          } else {
              bytes[] memory data = new bytes[](2);
              data[0] = abi.encodeWithSelector(IExchangeRouter.sendWnt.selector, orderVault, executionFee);
              data[1] = abi.encodeWithSelector(IExchangeRouter.createOrder.selector, params);
              exchangeRouter.multicall{value: executionFee}(data);
          }
    }

    function gmxv2_update(
      bytes32 key, uint256 sizeDeltaUsd, uint256 acceptablePrice, uint256 triggerPrice, uint256 minOutputAmount
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        exchangeRouter.updateOrder(key, sizeDeltaUsd, acceptablePrice, triggerPrice, minOutputAmount);
    }

    function gmxv2_cancel(bytes32 key) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        exchangeRouter.cancelOrder(key);
    }

    function gmxv2_claimFees(address[] memory markets, address[] memory tokens) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        exchangeRouter.claimFundingFees(markets, tokens, address(this));
    }
}

abstract contract GMXV2_Cutter is DiamondWritableInternal, ERC165Base {
    function cut_GMXV2(address _facet) internal {
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = IGMXV2_Module.gmxv2_create.selector;
        selectors[1] = IGMXV2_Module.gmxv2_update.selector;
        selectors[2] = IGMXV2_Module.gmxv2_cancel.selector;
        selectors[3] = IGMXV2_Module.gmxv2_claimFees.selector;
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut({
          target: _facet, action: FacetCutAction.ADD, selectors: selectors
        });
        _diamondCut(cuts, address(0), "");
        _setSupportsInterface(type(IGMXV2_Module).interfaceId, true);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "./dsq/DSQ_Common_Roles.sol";
import "../external/dolomite_interfaces/IDepositWithdrawalProxy.sol";
import "../external/dolomite_interfaces/IBorrowPositionProxyV1.sol";
import "../external/dolomite_interfaces/IBorrowPositionProxyV2.sol";
import { AccountBalanceLib } from "../external/dolomite_interfaces/AccountBalanceLib.sol";


interface IDolomite_Module {
    function dolomite_depositWei(
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei
    ) external;

    function dolomite_depositETH(
        uint256 _toAccountNumber
    ) external payable;

    function dolomite_depositWeiIntoDefaultAccount(
        uint256 _marketId,
        uint256 _amountWei
    ) external;

    function dolomite_depositETHIntoDefaultAccount() external payable;

    function dolomite_withdrawWei(
        uint256 _fromAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_withdrawETH(
        uint256 _fromAccountNumber,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_withdrawWeiFromDefaultAccount(
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_withdrawETHFromDefaultAccount(
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_depositPar(
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountPar
    ) external;

    function dolomite_depositParIntoDefaultAccount(
        uint256 _marketId,
        uint256 _amountPar
    ) external;

    function dolomite_withdrawPar(
        uint256 _fromAccountNumber,
        uint256 _marketId,
        uint256 _amountPar,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_withdrawParFromDefaultAccount(
        uint256 _marketId,
        uint256 _amountPar,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_closeBorrowPosition(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external;

    function dolomite_transferBetweenAccounts(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_repayAllForBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_openBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_closeBorrowPositionWithDifferentAccounts(
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external;

    function dolomite_transferBetweenAccountsWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    function dolomite_repayAllForBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

}

contract Dolomite_Module is IDolomite_Module, AccessControl, ReentrancyGuard, DSQ_Common_Roles {
    IDepositWithdrawalProxy public immutable depositWithdrawalProxy;
    IBorrowPositionProxyV2 public immutable borrowPositionProxy;

    constructor(address _depositWithdrawalProxy, address _borrowPositionProxy) {
        require(_depositWithdrawalProxy != address(0), "Rodeo_Module: Zero address");
        require(_borrowPositionProxy != address(0), "Rodeo_Module: Zero address");
        depositWithdrawalProxy = IDepositWithdrawalProxy(_depositWithdrawalProxy);
        borrowPositionProxy = IBorrowPositionProxyV2(_borrowPositionProxy);
    }

    function dolomite_depositWei(
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.depositWei(_toAccountNumber, _marketId, _amountWei);
    }

    function dolomite_depositETH(
        uint256 _toAccountNumber
    ) external payable onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.depositETH{value: msg.value}(_toAccountNumber);
    }

    function dolomite_depositWeiIntoDefaultAccount(
        uint256 _marketId,
        uint256 _amountWei
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.depositWeiIntoDefaultAccount(_marketId, _amountWei);
    }

    function dolomite_depositETHIntoDefaultAccount() external payable onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.depositETHIntoDefaultAccount{value: msg.value}();
    }

    function dolomite_withdrawWei(
        uint256 _fromAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.withdrawWei(_fromAccountNumber, _marketId, _amountWei, _balanceCheckFlag);
    }

    function dolomite_withdrawETH(
        uint256 _fromAccountNumber,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.withdrawETH(_fromAccountNumber, _amountWei, _balanceCheckFlag);
    }

    function dolomite_withdrawWeiFromDefaultAccount(
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.withdrawWeiFromDefaultAccount(_marketId, _amountWei, _balanceCheckFlag);
    }

    function dolomite_withdrawETHFromDefaultAccount(
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.withdrawETHFromDefaultAccount(_amountWei, _balanceCheckFlag);
    }

    function dolomite_depositPar(
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountPar
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.depositPar(_toAccountNumber, _marketId, _amountPar);
    }

    function dolomite_depositParIntoDefaultAccount(
        uint256 _marketId,
        uint256 _amountPar
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.depositParIntoDefaultAccount(_marketId, _amountPar);
    }

    function dolomite_withdrawPar(
        uint256 _fromAccountNumber,
        uint256 _marketId,
        uint256 _amountPar,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.withdrawPar(_fromAccountNumber, _marketId, _amountPar, _balanceCheckFlag);
    }

    function dolomite_withdrawParFromDefaultAccount(
        uint256 _marketId,
        uint256 _amountPar,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        depositWithdrawalProxy.withdrawParFromDefaultAccount(_marketId, _amountPar, _balanceCheckFlag);
    }

    function dolomite_openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        borrowPositionProxy.openBorrowPosition(_fromAccountNumber, _toAccountNumber, _collateralMarketId, _amountWei, _balanceCheckFlag);
    }

    function dolomite_closeBorrowPosition(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        borrowPositionProxy.closeBorrowPosition(_borrowAccountNumber, _toAccountNumber, _collateralMarketIds);
    }

    function dolomite_transferBetweenAccounts(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        borrowPositionProxy.transferBetweenAccounts(_fromAccountNumber, _toAccountNumber, _marketId, _amountWei, _balanceCheckFlag);
    }

    function dolomite_repayAllForBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        borrowPositionProxy.repayAllForBorrowPosition(_fromAccountNumber, _borrowAccountNumber, _marketId, _balanceCheckFlag);
    }

    function dolomite_openBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        borrowPositionProxy.openBorrowPositionWithDifferentAccounts(_fromAccountOwner, _fromAccountNumber, _toAccountOwner, _toAccountNumber, _collateralMarketId, _amountWei, _balanceCheckFlag);
    }

    function dolomite_closeBorrowPositionWithDifferentAccounts(
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        borrowPositionProxy.closeBorrowPositionWithDifferentAccounts(_borrowAccountOwner, _borrowAccountNumber, _toAccountOwner, _toAccountNumber, _collateralMarketIds);
    }

    function dolomite_transferBetweenAccountsWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        borrowPositionProxy.transferBetweenAccountsWithDifferentAccounts(_fromAccountOwner, _fromAccountNumber, _toAccountOwner, _toAccountNumber, _marketId, _amountWei, _balanceCheckFlag);
    }

    function dolomite_repayAllForBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        borrowPositionProxy.repayAllForBorrowPositionWithDifferentAccounts(_fromAccountOwner, _fromAccountNumber, _borrowAccountOwner, _borrowAccountNumber, _marketId, _balanceCheckFlag);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "./dsq/DSQ_Common_Roles.sol";

interface ID2Vault {
    function asset() external view returns (address);
    function deposit(uint256 assets, address receiver) external;
    function withdraw(uint256 assets, address receiver, address owner) external;
}

interface ID2_Module {
    function d2_deposit(address vault, uint256 assets) external;
    function d2_withdraw(address vault, uint256 assets) external;
}

contract D2_Module is ID2_Module, AccessControl, ReentrancyGuard, DSQ_Common_Roles {
    function d2_deposit(address vault, uint256 assets) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        ID2Vault(vault).deposit(assets, address(this));
    }

    function d2_withdraw(address vault, uint256 assets) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        ID2Vault(vault).withdraw(assets, address(this), address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControlInternal } from './IAccessControlInternal.sol';

/**
 * @title AccessControl interface
 */
interface IAccessControl is IAccessControlInternal {
    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function grantRole(bytes32 role, address account) external;

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function renounceRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(
        bytes32 role,
        address account
    ) internal view virtual returns (bool) {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(
        bytes32 role
    ) internal view virtual returns (bytes32) {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

struct Epoch {
    uint256 fundingStart;
    uint256 epochStart;
    uint256 epochEnd;
}

interface IVault {
    function custodyFunds() external returns (uint256);

    function returnFunds(uint256 _amount) external;

    function asset() external returns (address);

    function getCurrentEpochInfo() external view returns (Epoch memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRouter {
    function approvePlugin(address _plugin) external;

    function denyPlugin(address _plugin) external;

    function directPoolDeposit(address _token, uint256 _amount) external;

    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function swapETHToTokens(address[] memory _path, uint256 _minOut, address _receiver) external payable;

    function swapTokensToETH(address[] memory _path, uint256 _amountIn, uint256 _minOut, address payable _receiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPositionRouter {
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IOrderBook {
    function getSwapOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        );

    function getIncreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    struct IncreaseOrder {
        address account;
        address purchaseToken;
        uint256 purchaseTokenAmount;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }
    struct DecreaseOrder {
        address account;
        address collateralToken;
        uint256 collateralDelta;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }
    struct SwapOrder {
        address account;
        address[] path;
        uint256 amountIn;
        uint256 minOut;
        uint256 triggerRatio;
        bool triggerAboveThreshold;
        bool shouldUnwrap;
        uint256 executionFee;
    }

    function minExecutionFee() external view returns (uint256);

    function increaseOrdersIndex(address) external view returns (uint256);

    function decreaseOrdersIndex(address) external view returns (uint256);

    function increaseOrders(address, uint256 _orderIndex) external view returns (IncreaseOrder memory);

    function decreaseOrders(address, uint256 _orderIndex) external view returns (DecreaseOrder memory);

    function swapOrders(address, uint256 _orderIndex) external view returns (SwapOrder memory);

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable;

    function updateIncreaseOrder(uint256 _orderIndex, uint256 _sizeDelta, uint256 _triggerPrice, bool _triggerAboveThreshold) external;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function cancelSwapOrder(uint256 _orderIndex) external;

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    event CreateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event CancelSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event UpdateSwapOrder(
        address indexed account,
        uint256 ordexIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event ExecuteSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 amountOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRewardRouterV2 {
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);

    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);

    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) external returns (uint256);

    function claim() external;

    function compound() external;

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function unstakeGmx(uint256 _amount) external;

    function unstakeEsGmx(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        if (l.status == 2) revert ReentrancyGuard__ReentrantCall();
        l.status = 2;
        _;
        l.status = 1;
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../dsq/DSQ_Common_Roles.sol";

/**
 * @title   DSquared Camelot Common Storage
 * @notice  Protocol addresses and constants used by all Camelot modules
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
abstract contract Camelot_Common_Storage is DSQ_Common_Roles {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct CamelotCommonStorage {
        /// @notice Set of allowed Camelot NFT pools
        EnumerableSet.AddressSet allowedNFTPools;
        /// @notice Set of allowed Camelot nitro pools
        EnumerableSet.AddressSet allowedNitroPools;
        /// @notice Set of allowed Odos executors
        EnumerableSet.AddressSet allowedExecutors;
        /// @notice Set of allowed Camelot V3 pools to be input receivers
        EnumerableSet.AddressSet allowedReceivers;
    }

    /// @dev    EIP-2535 Diamond Storage struct location
    bytes32 internal constant CAMELOT_POSITION = bytes32(uint256(keccak256("Camelot_Common.storage")) - 1);

    function getCamelotCommonStorage() internal pure returns (CamelotCommonStorage storage storageStruct) {
        bytes32 position = CAMELOT_POSITION;
        // solhint-disable no-inline-assembly
        assembly {
            storageStruct.slot := position
        }
    }

    // --------- Internal Functions ---------

    /**
     * @notice  Validates a Camelot NFT pool
     * @param   _pool   Pool address
     */
    function validateNFTPool(address _pool) internal view {
        require(getCamelotCommonStorage().allowedNFTPools.contains(_pool), "Invalid NFT Pool");
    }

    /**
     * @notice  Validates a Camelot nitro pool
     * @param   _pool   Pool address
     */
    function validateNitroPool(address _pool) internal view {
        require(getCamelotCommonStorage().allowedNitroPools.contains(_pool), "Invalid Nitro Pool");
    }

    /**
     * @notice  Validates an Odos executor
     * @param   _executor   Executor address
     */
    function validateExecutor(address _executor) internal view {
        require(getCamelotCommonStorage().allowedExecutors.contains(_executor), "Invalid Executor");
    }

    /**
     * @notice  Validates an Odos input receiver
     * @param   _receiver   Input receiver address
     */
    function validateReceiver(address _receiver) internal view {
        require(getCamelotCommonStorage().allowedReceivers.contains(_receiver), "Invalid Receiver");
    }
}

// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.13;

interface INonfungiblePositionManager {
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct MintParams {
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint88 nonce,
            address operator,
            address token0,
            address token1,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function multicall(bytes[] calldata data) external;

    function refundNativeToken() external;

    function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable;

    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function sweepToken(address token, uint256 amountMinimum, address recipient) external;

    function unwrapWNativeToken(uint256 amountMinimum, address recipient) external;
}

// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.13;

interface IOdosRouter {
    /// @dev Contains all information needed to describe an input token being swapped from
    struct inputToken {
        address tokenAddress;
        uint256 amountIn;
        address receiver;
        bytes permit;
    }
    /// @dev Contains all information needed to describe an output token being swapped to
    struct outputToken {
        address tokenAddress;
        uint256 relativeValue;
        address receiver;
    }

    function swap(
        inputToken[] memory inputs,
        outputToken[] memory outputs,
        uint256 valueOutQuote,
        uint256 valueOutMin,
        address executor,
        bytes calldata pathDefinition
    ) external payable returns (uint256[] memory amountsOut, uint256 gasLeft);
}

pragma solidity ^0.8.13;

interface INFTPoolFactory {
    function getPool(address _lpToken) external view returns (address);
}

//SPDX-License-Identifier:ISC

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// For full documentation refer to @lyrafinance/protocol/contracts/periphery/LyraRegistry.sol";
/// @dev inputs/returns that contain Lyra contracts replaced with addresses (as opposed to LyraRegistry.sol)
///      so that interacting contracts are not required to import Lyra contracts
interface ILyraRegistry {
    struct OptionMarketAddresses {
        address liquidityPool;
        address liquidityToken;
        address greekCache;
        address optionMarket;
        address optionMarketPricer;
        address optionToken;
        address poolHedger;
        address shortCollateral;
        address gwavOracle;
        IERC20 quoteAsset;
        IERC20 baseAsset;
    }

    function optionMarkets() external view returns (address[] memory);

    function marketAddress(address market) external view returns (OptionMarketAddresses memory);

    function globalAddresses(bytes32 name) external view returns (address);

    function getMarketAddresses(address optionMarket) external view returns (OptionMarketAddresses memory);

    function getGlobalAddress(bytes32 contractName) external view returns (address globalContract);

    event GlobalAddressUpdated(bytes32 indexed name, address addr);

    event MarketUpdated(address indexed optionMarket, OptionMarketAddresses market);

    event MarketRemoved(address indexed market);

    error RemovingInvalidMarket(address thrower, address market);

    error NonExistentMarket(address optionMarket);

    error NonExistentGlobalContract(bytes32 contractName);
}

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.13;

import "./ILiquidityPool.sol";
import "./ISynthetixAdapter.sol";
import "./IOptionMarketPricer.sol";

// For full documentation refer to @lyrafinance/protocol/contracts/OptionMarket.sol";
interface IOptionMarket {
    enum TradeDirection {
        OPEN,
        CLOSE,
        LIQUIDATE
    }

    enum OptionType {
        LONG_CALL,
        LONG_PUT,
        SHORT_CALL_BASE,
        SHORT_CALL_QUOTE,
        SHORT_PUT_QUOTE
    }

    /// @notice For returning more specific errors
    enum NonZeroValues {
        BASE_IV,
        SKEW,
        STRIKE_PRICE,
        ITERATIONS,
        STRIKE_ID
    }

    ///////////////////
    // Internal Data //
    ///////////////////

    struct Strike {
        // strike listing identifier
        uint id;
        // strike price
        uint strikePrice;
        // volatility component specific to the strike listing (boardIv * skew = vol of strike)
        uint skew;
        // total user long call exposure
        uint longCall;
        // total user short call (base collateral) exposure
        uint shortCallBase;
        // total user short call (quote collateral) exposure
        uint shortCallQuote;
        // total user long put exposure
        uint longPut;
        // total user short put (quote collateral) exposure
        uint shortPut;
        // id of board to which strike belongs
        uint boardId;
    }

    struct OptionBoard {
        // board identifier
        uint id;
        // expiry of all strikes belonging to board
        uint expiry;
        // volatility component specific to board (boardIv * skew = vol of strike)
        uint iv;
        // admin settable flag blocking all trading on this board
        bool frozen;
        // list of all strikes belonging to this board
        uint[] strikeIds;
    }

    ///////////////
    // In-memory //
    ///////////////

    struct OptionMarketParameters {
        // max allowable expiry of added boards
        uint maxBoardExpiry;
        // security module address
        address securityModule;
        // fee portion reserved for Lyra DAO
        uint feePortionReserved;
        // expected fee charged to LPs, used for pricing short_call_base settlement
        uint staticBaseSettlementFee;
    }

    struct TradeInputParameters {
        // id of strike
        uint strikeId;
        // OptionToken ERC721 id for position (set to 0 for new positions)
        uint positionId;
        // number of sub-orders to break order into (reduces slippage)
        uint iterations;
        // type of option to trade
        OptionType optionType;
        // number of contracts to trade
        uint amount;
        // final amount of collateral to leave in OptionToken position
        uint setCollateralTo;
        // revert trade if totalCost is below this value
        uint minTotalCost;
        // revert trade if totalCost is above this value
        uint maxTotalCost;
        // referrer emitted in Trade event, no on-chain interaction
        address referrer;
    }

    struct TradeParameters {
        bool isBuy;
        bool isForceClose;
        TradeDirection tradeDirection;
        OptionType optionType;
        uint amount;
        uint expiry;
        uint strikePrice;
        ILiquidityPool.Liquidity liquidity;
        ISynthetixAdapter.ExchangeParams exchangeParams;
    }

    struct TradeEventData {
        uint strikeId;
        uint expiry;
        uint strikePrice;
        OptionType optionType;
        TradeDirection tradeDirection;
        uint amount;
        uint setCollateralTo;
        bool isForceClose;
        uint spotPrice;
        uint reservedFee;
        uint totalCost;
    }

    struct LiquidationEventData {
        address rewardBeneficiary;
        address caller;
        uint returnCollateral; // quote || base
        uint lpPremiums; // quote || base
        uint lpFee; // quote || base
        uint liquidatorFee; // quote || base
        uint smFee; // quote || base
        uint insolventAmount; // quote
    }

    struct Result {
        uint positionId;
        uint totalCost;
        uint totalFee;
    }

    ///////////////
    // Variables //
    ///////////////

    /// @notice claim all reserved option fees
    function smClaim() external;

    ///////////
    // Views //
    ///////////

    function getOptionMarketParams() external view returns (OptionMarketParameters memory);

    function getLiveBoards() external view returns (uint[] memory _liveBoards);

    function getNumLiveBoards() external view returns (uint numLiveBoards);

    function getStrikeAndExpiry(uint strikeId) external view returns (uint strikePrice, uint expiry);

    function getBoardStrikes(uint boardId) external view returns (uint[] memory strikeIds);

    function getStrike(uint strikeId) external view returns (Strike memory);

    function getOptionBoard(uint boardId) external view returns (OptionBoard memory);

    function getStrikeAndBoard(uint strikeId) external view returns (Strike memory, OptionBoard memory);

    function getBoardAndStrikeDetails(uint boardId) external view returns (OptionBoard memory, Strike[] memory, uint[] memory, uint);

    ////////////////////
    // User functions //
    ////////////////////

    function openPosition(TradeInputParameters memory params) external returns (Result memory result);

    function closePosition(TradeInputParameters memory params) external returns (Result memory result);

    /**
     * @notice Attempts to reduce or fully close position within cost bounds while ignoring delta trading cutoffs.
     *
     * @param params The parameters for the requested trade
     */
    function forceClosePosition(TradeInputParameters memory params) external returns (Result memory result);

    function addCollateral(uint positionId, uint amountCollateral) external;

    function liquidatePosition(uint positionId, address rewardBeneficiary) external;

    /////////////////////////////////
    // Board Expiry and settlement //
    /////////////////////////////////

    function settleExpiredBoard(uint boardId) external;

    function getSettlementParameters(uint strikeId) external view returns (uint strikePrice, uint priceAtExpiry, uint strikeToBaseReturned);

    ////////////
    // Events //
    ////////////

    /**
     * @dev Emitted when a Board is created.
     */
    event BoardCreated(uint indexed boardId, uint expiry, uint baseIv, bool frozen);

    /**
     * @dev Emitted when a Board frozen is updated.
     */
    event BoardFrozen(uint indexed boardId, bool frozen);

    /**
     * @dev Emitted when a Board new baseIv is set.
     */
    event BoardBaseIvSet(uint indexed boardId, uint baseIv);

    /**
     * @dev Emitted when a Strike new skew is set.
     */
    event StrikeSkewSet(uint indexed strikeId, uint skew);

    /**
     * @dev Emitted when a Strike is added to a board
     */
    event StrikeAdded(uint indexed boardId, uint indexed strikeId, uint strikePrice, uint skew);

    /**
     * @dev Emitted when parameters for the option market are adjusted
     */
    event OptionMarketParamsSet(OptionMarketParameters optionMarketParams);

    /**
     * @dev Emitted whenever the security module claims their portion of fees
     */
    event SMClaimed(address securityModule, uint quoteAmount, uint baseAmount);

    /**
     * @dev Emitted when a Position is opened, closed or liquidated.
     */
    event Trade(
        address indexed trader,
        uint indexed positionId,
        address indexed referrer,
        TradeEventData trade,
        IOptionMarketPricer.TradeResult[] tradeResults,
        LiquidationEventData liquidation,
        uint longScaleFactor,
        uint timestamp
    );

    /**
     * @dev Emitted when a Board is liquidated.
     */
    event BoardSettled(
        uint indexed boardId,
        uint spotPriceAtExpiry,
        uint totalUserLongProfitQuote,
        uint totalBoardLongCallCollateral,
        uint totalBoardLongPutCollateral,
        uint totalAMMShortCallProfitBase,
        uint totalAMMShortCallProfitQuote,
        uint totalAMMShortPutProfitQuote
    );

    ////////////
    // Errors //
    ////////////
    // General purpose
    error ExpectedNonZeroValue(address thrower, NonZeroValues valueType);

    // Admin
    error InvalidOptionMarketParams(address thrower, OptionMarketParameters optionMarketParams);

    // Board related
    error InvalidBoardId(address thrower, uint boardId);
    error InvalidExpiryTimestamp(address thrower, uint currentTime, uint expiry, uint maxBoardExpiry);
    error BoardNotFrozen(address thrower, uint boardId);
    error BoardAlreadySettled(address thrower, uint boardId);
    error BoardNotExpired(address thrower, uint boardId);

    // Strike related
    error InvalidStrikeId(address thrower, uint strikeId);
    error StrikeSkewLengthMismatch(address thrower, uint strikesLength, uint skewsLength);

    // Trade
    error TotalCostOutsideOfSpecifiedBounds(address thrower, uint totalCost, uint minCost, uint maxCost);
    error BoardIsFrozen(address thrower, uint boardId);
    error BoardExpired(address thrower, uint boardId, uint boardExpiry, uint currentTime);
    error TradeIterationsHasRemainder(address thrower, uint iterations, uint expectedAmount, uint tradeAmount, uint totalAmount);

    // Access
    error OnlySecurityModule(address thrower, address caller, address securityModule);

    // Token transfers
    error BaseTransferFailed(address thrower, address from, address to, uint amount);
    error QuoteTransferFailed(address thrower, address from, address to, uint amount);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { IPoolAddressesProvider } from "./IPoolAddressesProvider.sol";
import { DataTypes } from "./DataTypes.sol";

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {
    /**
     * @dev Emitted on mintUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
     * @param amount The amount of supplied assets
     * @param referralCode The referral code used
     **/
    event MintUnbacked(address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode);

    /**
     * @dev Emitted on backUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param backer The address paying for the backing
     * @param amount The amount added as backing
     * @param fee The amount paid in fees
     **/
    event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     **/
    event Supply(address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode);

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
     **/
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount, bool useATokens);

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    event SwapBorrowRateMode(address indexed reserve, address indexed user, DataTypes.InterestRateMode interestRateMode);

    /**
     * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
     * @param asset The address of the underlying asset of the reserve
     * @param totalDebt The total isolation mode debt for the reserve
     */
    event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

    /**
     * @dev Emitted when the user selects a certain asset category for eMode
     * @param user The address of the user
     * @param categoryId The category id
     **/
    event UserEModeSet(address indexed user, uint8 categoryId);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param stableBorrowRate The next stable borrow rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     **/
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @dev Mints an `amount` of aTokens to the `onBehalfOf`
     * @param asset The address of the underlying asset to mint
     * @param amount The amount to mint
     * @param onBehalfOf The address that will receive the aTokens
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function mintUnbacked(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @dev Back the current unbacked underlying with `amount` and pay `fee`.
     * @param asset The address of the underlying asset to back
     * @param amount The amount to back
     * @param fee The amount paid in fees
     **/
    function backUnbacked(address asset, uint256 amount, uint256 fee) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     **/
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     **/
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return The final amount repaid
     **/
    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256);

    /**
     * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
     * @param asset The address of the underlying asset borrowed
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

    /**
     * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
     *        much has been borrowed at a stable rate and suppliers are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(address collateralAsset, address debtAsset, address user, uint256 debtToCover, bool receiveAToken) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param interestRateModes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param aTokenAddress The address of the aToken that will be assigned to the reserve
     * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     **/
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     **/
    function dropReserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     **/
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     **/
    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice Validates and finalizes an aToken transfer
     * @dev Only callable by the overlying aToken of the `asset`
     * @param asset The address of the underlying asset of the aToken
     * @param from The user from which the aTokens are transferred
     * @param to The user receiving the aTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The aToken balance of the `from` user before the transfer
     * @param balanceToBefore The aToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     **/
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     **/
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     **/
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Updates the protocol fee on the bridging
     * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
     */
    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

    /**
     * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
     * - A part is sent to aToken holders as extra, one time accumulated interest
     * - A part is collected by the protocol treasury
     * @dev The total premium is calculated on the total borrowed amount
     * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
     * @dev Only callable by the PoolConfigurator contract
     * @param flashLoanPremiumTotal The total premium, expressed in bps
     * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
     */
    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external;

    /**
     * @notice Configures a new category for the eMode.
     * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
     * The category 0 is reserved as it's the default for volatile assets
     * @param id The id of the category
     * @param config The configuration of the category
     */
    function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

    /**
     * @notice Returns the data of an eMode category
     * @param id The id of the category
     * @return The configuration data of the category
     */
    function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

    /**
     * @notice Allows a user to use the protocol in eMode
     * @param categoryId The id of the category
     */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Returns the eMode the user is using
     * @param user The address of the user
     * @return The eMode id
     */
    function getUserEMode(address user) external view returns (uint256);

    /**
     * @notice Resets the isolation mode total debt of the given asset to zero
     * @dev It requires the given asset has zero debt ceiling
     * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
     */
    function resetIsolationModeTotalDebt(address asset) external;

    /**
     * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
     * @return The percentage of available liquidity to borrow, expressed in bps
     */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the bridge fees sent to protocol
     * @return The bridge fee sent to the protocol treasury
     */
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
     * @param assets The list of reserves for which the minting needs to be executed
     **/
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @dev Deprecated: Use the `supply` function instead
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IJoeFactory } from "./IJoeFactory.sol";
import { ILBFactory } from "./ILBFactory.sol";
import { ILBLegacyFactory } from "./ILBLegacyFactory.sol";
import { ILBLegacyRouter } from "./ILBLegacyRouter.sol";
import { ILBPair } from "./ILBPair.sol";
import { ILBToken } from "./ILBToken.sol";
import { IWNATIVE } from "./IWNATIVE.sol";

/**
 * @title Liquidity Book Router Interface
 * @author Trader Joe
 * @notice Required interface of LBRouter contract
 */
interface ILBRouter {
    error LBRouter__SenderIsNotWNATIVE();
    error LBRouter__PairNotCreated(address tokenX, address tokenY, uint256 binStep);
    error LBRouter__WrongAmounts(uint256 amount, uint256 reserve);
    error LBRouter__SwapOverflows(uint256 id);
    error LBRouter__BrokenSwapSafetyCheck();
    error LBRouter__NotFactoryOwner();
    error LBRouter__TooMuchTokensIn(uint256 excess);
    error LBRouter__BinReserveOverflows(uint256 id);
    error LBRouter__IdOverflows(int256 id);
    error LBRouter__LengthsMismatch();
    error LBRouter__WrongTokenOrder();
    error LBRouter__IdSlippageCaught(uint256 activeIdDesired, uint256 idSlippage, uint256 activeId);
    error LBRouter__AmountSlippageCaught(uint256 amountXMin, uint256 amountX, uint256 amountYMin, uint256 amountY);
    error LBRouter__IdDesiredOverflows(uint256 idDesired, uint256 idSlippage);
    error LBRouter__FailedToSendNATIVE(address recipient, uint256 amount);
    error LBRouter__DeadlineExceeded(uint256 deadline, uint256 currentTimestamp);
    error LBRouter__AmountSlippageBPTooBig(uint256 amountSlippage);
    error LBRouter__InsufficientAmountOut(uint256 amountOutMin, uint256 amountOut);
    error LBRouter__MaxAmountInExceeded(uint256 amountInMax, uint256 amountIn);
    error LBRouter__InvalidTokenPath(address wrongToken);
    error LBRouter__InvalidVersion(uint256 version);
    error LBRouter__WrongNativeLiquidityParameters(address tokenX, address tokenY, uint256 amountX, uint256 amountY, uint256 msgValue);

    /**
     * @dev This enum represents the version of the pair requested
     * - V1: Joe V1 pair
     * - V2: LB pair V2. Also called legacyPair
     * - V2_1: LB pair V2.1 (current version)
     */
    enum Version {
        V1,
        V2,
        V2_1
    }

    /**
     * @dev The liquidity parameters, such as:
     * - tokenX: The address of token X
     * - tokenY: The address of token Y
     * - binStep: The bin step of the pair
     * - amountX: The amount to send of token X
     * - amountY: The amount to send of token Y
     * - amountXMin: The min amount of token X added to liquidity
     * - amountYMin: The min amount of token Y added to liquidity
     * - activeIdDesired: The active id that user wants to add liquidity from
     * - idSlippage: The number of id that are allowed to slip
     * - deltaIds: The list of delta ids to add liquidity (`deltaId = activeId - desiredId`)
     * - distributionX: The distribution of tokenX with sum(distributionX) = 100e18 (100%) or 0 (0%)
     * - distributionY: The distribution of tokenY with sum(distributionY) = 100e18 (100%) or 0 (0%)
     * - to: The address of the recipient
     * - refundTo: The address of the recipient of the refunded tokens if too much tokens are sent
     * - deadline: The deadline of the transaction
     */
    struct LiquidityParameters {
        IERC20 tokenX;
        IERC20 tokenY;
        uint256 binStep;
        uint256 amountX;
        uint256 amountY;
        uint256 amountXMin;
        uint256 amountYMin;
        uint256 activeIdDesired;
        uint256 idSlippage;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        address to;
        address refundTo;
        uint256 deadline;
    }

    /**
     * @dev The path parameters, such as:
     * - pairBinSteps: The list of bin steps of the pairs to go through
     * - versions: The list of versions of the pairs to go through
     * - tokenPath: The list of tokens in the path to go through
     */
    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function getFactory() external view returns (ILBFactory);

    function getLegacyFactory() external view returns (ILBLegacyFactory);

    function getV1Factory() external view returns (IJoeFactory);

    function getLegacyRouter() external view returns (ILBLegacyRouter);

    function getWNATIVE() external view returns (IWNATIVE);

    function getIdFromPrice(ILBPair LBPair, uint256 price) external view returns (uint24);

    function getPriceFromId(ILBPair LBPair, uint24 id) external view returns (uint256);

    function getSwapIn(
        ILBPair LBPair,
        uint128 amountOut,
        bool swapForY
    ) external view returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(
        ILBPair LBPair,
        uint128 amountIn,
        bool swapForY
    ) external view returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep) external returns (ILBPair pair);

    function addLiquidity(
        LiquidityParameters calldata liquidityParameters
    )
        external
        returns (
            uint256 amountXAdded,
            uint256 amountYAdded,
            uint256 amountXLeft,
            uint256 amountYLeft,
            uint256[] memory depositIds,
            uint256[] memory liquidityMinted
        );

    function addLiquidityNATIVE(
        LiquidityParameters calldata liquidityParameters
    )
        external
        payable
        returns (
            uint256 amountXAdded,
            uint256 amountYAdded,
            uint256 amountXLeft,
            uint256 amountYLeft,
            uint256[] memory depositIds,
            uint256[] memory liquidityMinted
        );

    function removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function removeLiquidityNATIVE(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountNATIVEMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountNATIVE);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForNATIVE(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNATIVEForTokens(
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapTokensForExactNATIVE(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapNATIVEForExactTokens(
        uint256 amountOut,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amountsIn);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForNATIVESupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNATIVEForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function sweep(IERC20 token, address to, uint256 amount) external;

    function sweepLBToken(ILBToken _lbToken, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILBFactory } from "./ILBFactory.sol";
import { IJoeFactory } from "./IJoeFactory.sol";
import { ILBLegacyPair } from "./ILBLegacyPair.sol";
import { ILBToken } from "./ILBToken.sol";
import { IWNATIVE } from "./IWNATIVE.sol";

/// @title Liquidity Book Router Interface
/// @author Trader Joe
/// @notice Required interface of LBRouter contract
interface ILBLegacyRouter {
    struct LiquidityParameters {
        IERC20 tokenX;
        IERC20 tokenY;
        uint256 binStep;
        uint256 amountX;
        uint256 amountY;
        uint256 amountXMin;
        uint256 amountYMin;
        uint256 activeIdDesired;
        uint256 idSlippage;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        address to;
        uint256 deadline;
    }

    function factory() external view returns (address);

    function wavax() external view returns (address);

    function oldFactory() external view returns (address);

    function getIdFromPrice(ILBLegacyPair LBPair, uint256 price) external view returns (uint24);

    function getPriceFromId(ILBLegacyPair LBPair, uint24 id) external view returns (uint256);

    function getSwapIn(ILBLegacyPair lbPair, uint256 amountOut, bool swapForY) external view returns (uint256 amountIn, uint256 feesIn);

    function getSwapOut(ILBLegacyPair lbPair, uint256 amountIn, bool swapForY) external view returns (uint256 amountOut, uint256 feesIn);

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep) external returns (ILBLegacyPair pair);

    function addLiquidity(
        LiquidityParameters calldata liquidityParameters
    ) external returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function addLiquidityAVAX(
        LiquidityParameters calldata liquidityParameters
    ) external payable returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function removeLiquidityAVAX(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMinAVAX,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amountsIn);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMinAVAX,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function sweep(IERC20 token, address to, uint256 amount) external;

    function sweepLBToken(ILBToken _lbToken, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILBLegacyPair } from "./ILBLegacyPair.sol";
import { IPendingOwnable } from "./IPendingOwnable.sol";

/// @title Liquidity Book Factory Interface
/// @author Trader Joe
/// @notice Required interface of LBFactory contract
interface ILBLegacyFactory is IPendingOwnable {
    /// @dev Structure to store the LBPair information, such as:
    /// - binStep: The bin step of the LBPair
    /// - LBPair: The address of the LBPair
    /// - createdByOwner: Whether the pair was created by the owner of the factory
    /// - ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
    struct LBPairInformation {
        uint16 binStep;
        ILBLegacyPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBLegacyPair LBPair, uint256 pid);

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event FeeParametersSet(
        address indexed sender,
        ILBLegacyPair indexed LBPair,
        uint256 binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event FactoryLockedStatusUpdated(bool unlocked);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBLegacyPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator,
        uint256 sampleLifetime
    );

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function MAX_FEE() external pure returns (uint256);

    function MIN_BIN_STEP() external pure returns (uint256);

    function MAX_BIN_STEP() external pure returns (uint256);

    function MAX_PROTOCOL_SHARE() external pure returns (uint256);

    function LBPairImplementation() external view returns (address);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAsset(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function feeRecipient() external view returns (address);

    function flashLoanFee() external view returns (uint256);

    function creationUnlocked() external view returns (bool);

    function allLBPairs(uint256 id) external returns (ILBLegacyPair);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep) external view returns (LBPairInformation memory);

    function getPreset(
        uint16 binStep
    )
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            uint256 sampleLifetime
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY) external view returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address LBPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep) external returns (ILBLegacyPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint256 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint16 sampleLifetime
    ) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function setFactoryLockedState(bool locked) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBLegacyPair LBPair) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ILBPair.sol";
import "./IPendingOwnable.sol";

/// @title Liquidity Book Factory Interface
/// @author Trader Joe
/// @notice Required interface of LBFactory contract
interface ILBFactory is IPendingOwnable {
    /// @dev Structure to store the LBPair information, such as:
    /// - binStep: The bin step of the LBPair
    /// - LBPair: The address of the LBPair
    /// - createdByOwner: Whether the pair was created by the owner of the factory
    /// - ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid);

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event FeeParametersSet(
        address indexed sender,
        ILBPair indexed LBPair,
        uint256 binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulated
    );

    event FactoryLockedStatusUpdated(bool unlocked);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulated,
        uint256 sampleLifetime
    );

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function MAX_FEE() external pure returns (uint256);

    function MIN_BIN_STEP() external pure returns (uint256);

    function MAX_BIN_STEP() external pure returns (uint256);

    function MAX_PROTOCOL_SHARE() external pure returns (uint256);

    function LBPairImplementation() external view returns (address);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAsset(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function feeRecipient() external view returns (address);

    function flashLoanFee() external view returns (uint256);

    function creationUnlocked() external view returns (bool);

    function allLBPairs(uint256 id) external returns (ILBPair);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep) external view returns (LBPairInformation memory);

    function getPreset(
        uint16 binStep
    )
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            uint256 sampleLifetime
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY) external view returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address LBPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep) external returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint256 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulated,
        uint16 sampleLifetime
    ) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulated
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function setFactoryLockedState(bool locked) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair LBPair) external;
}

// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAggregationExecutor.sol";
import "./OrderLib.sol";
import "../clipper_interfaces/IClipperExchangeInterface.sol";

interface IAggregationRouter {
    event OrderFilled(address indexed maker, bytes32 orderHash, uint256 remaining);

    error UnknownOrder();
    error AccessDenied();
    error AlreadyFilled();
    error PermitLengthTooLow();
    error ZeroTargetIsForbidden();
    error RemainingAmountIsZero();
    error PrivateOrder();
    error BadSignature();
    error ReentrancyDetected();
    error PredicateIsNotTrue();
    error OnlyOneAmountShouldBeZero();
    error TakingAmountTooHigh();
    error MakingAmountTooLow();
    error SwapWithZeroAmount();
    error TransferFromMakerToTakerFailed();
    error TransferFromTakerToMakerFailed();
    error WrongAmount();
    error WrongGetter();
    error GetAmountCallFailed();
    error TakingAmountIncreased();
    error SimulationResults(bool success, bytes res);
    event OrderCanceled(address indexed maker, bytes32 orderHash, uint256 remainingRaw);

    enum DynamicField {
        MakerAssetData,
        TakerAssetData,
        GetMakingAmount,
        GetTakingAmount,
        Predicate,
        Permit,
        PreInteraction,
        PostInteraction
    }

    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);

    function uniswapV3Swap(uint256 amount, uint256 minReturn, uint256[] calldata pools) external payable returns (uint256 returnAmount);

    function unoswap(
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function clipperSwap(
        IClipperExchangeInterface clipperExchange,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) external payable returns (uint256 returnAmount);

    function fillOrder(
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount
    ) external payable returns (uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);

    function cancelOrder(OrderLib.Order calldata order) external returns (uint256 orderRemaining, bytes32 orderHash);

    function hashOrder(OrderLib.Order calldata order) external view returns (bytes32);

    function remaining(bytes32 orderHash) external view returns (uint256 amount);
}

// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
}

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable; // 0x4b64e492
}

pragma solidity ^0.8.13;

/// @title Clipper interface subset used in swaps
interface IClipperExchangeInterface {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function sellEthForToken(
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        address destinationAddress,
        Signature calldata theSignature,
        bytes calldata auxiliaryData
    ) external payable;

    function sellTokenForEth(
        address inputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        address destinationAddress,
        Signature calldata theSignature,
        bytes calldata auxiliaryData
    ) external;

    function swap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        address destinationAddress,
        Signature calldata theSignature,
        bytes calldata auxiliaryData
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOptionRegistry.sol";
import "./IAccounting.sol";
import "./Types.sol";

interface Rysk_ILiquidityPool {
    function deposit(uint256 _amount) external returns (bool);

    function initiateWithdraw(uint256 _shares) external;

    function completeWithdraw() external returns (uint256);

    function executeEpochCalculation() external;

    function strikeAsset() external view returns (address);

    function underlyingAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function collateralAllocated() external view returns (uint256);

    function ephemeralLiabilities() external view returns (int256);

    function ephemeralDelta() external view returns (int256);

    function depositEpoch() external view returns (uint256);

    function withdrawalEpoch() external view returns (uint256);

    function depositEpochPricePerShare(uint256 epoch) external view returns (uint256 price);

    function withdrawalEpochPricePerShare(uint256 epoch) external view returns (uint256 price);

    function depositReceipts(address depositor) external view returns (IAccounting.DepositReceipt memory);

    function withdrawalReceipts(address withdrawer) external view returns (IAccounting.WithdrawalReceipt memory);

    function pendingDeposits() external view returns (uint256);

    function pendingWithdrawals() external view returns (uint256);

    function partitionedFunds() external view returns (uint256);

    /////////////////////////////////////
    /// governance settable variables ///
    /////////////////////////////////////

    function bufferPercentage() external view returns (uint256);

    function collateralCap() external view returns (uint256);

    /////////////////
    /// functions ///
    /////////////////

    function handlerIssue(Types.OptionSeries memory optionSeries) external returns (address);

    function resetEphemeralValues() external;

    function getAssets() external view returns (uint256);

    function redeem(uint256) external returns (uint256);

    function handlerWriteOption(
        Types.OptionSeries memory optionSeries,
        address seriesAddress,
        uint256 amount,
        IOptionRegistry optionRegistry,
        uint256 premium,
        int256 delta,
        address recipient
    ) external returns (uint256);

    function handlerBuybackOption(
        Types.OptionSeries memory optionSeries,
        uint256 amount,
        IOptionRegistry optionRegistry,
        address seriesAddress,
        uint256 premium,
        int256 delta,
        address seller
    ) external returns (uint256);

    function handlerIssueAndWriteOption(
        Types.OptionSeries memory optionSeries,
        uint256 amount,
        uint256 premium,
        int256 delta,
        address recipient
    ) external returns (uint256, address);

    function getPortfolioDelta() external view returns (int256);

    function quotePriceWithUtilizationGreeks(
        Types.OptionSeries memory optionSeries,
        uint256 amount,
        bool toBuy
    ) external view returns (uint256 quote, int256 delta);

    function checkBuffer() external view returns (int256 bufferRemaining);

    function getBalance(address asset) external view returns (uint256);

    function pauseUnpauseTrading(bool _pause) external;

    function maxTimeDeviationThreshold() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    event DepositEpochExecuted(uint256 _epoch);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Types.sol";

interface IAlphaOptionHandler {
    function executeOrder(uint256 _orderId) external;

    function executeBuyBackOrder(uint256 _orderId) external;

    function executeStrangle(uint256 _orderId1, uint256 _orderId2) external;

    function createStrangle(
        Types.OptionSeries memory _optionSeriesCall,
        Types.OptionSeries memory _optionSeriesPut,
        uint256 _amountCall,
        uint256 _amountPut,
        uint256 _priceCall,
        uint256 _pricePut,
        uint256 _orderExpiry,
        address _buyerAddress,
        uint256[2] memory _callSpotMovementRange,
        uint256[2] memory _putSpotMovementRange
    ) external returns (uint256, uint256);

    function createOrder(
        Types.OptionSeries memory _optionSeries,
        uint256 _amount,
        uint256 _price,
        uint256 _orderExpiry,
        address _buyerAddress,
        bool _isBuyBack,
        uint256[2] memory _spotMovementRange
    ) external returns (uint256);

    function orderStores(uint256 _orderId) external view returns (Types.Order memory order);

    function orderIdCounter() external view returns (uint256);

    event OrderCreated(uint256 _orderId);
    event OrderExecuted(uint256 _orderId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165Base } from './IERC165Base.sol';
import { ERC165BaseInternal } from './ERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165Base is IERC165Base, ERC165BaseInternal {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondWritableInternal } from './IDiamondWritableInternal.sol';

abstract contract DiamondWritableInternal is IDiamondWritableInternal {
    using AddressUtils for address;

    bytes32 private constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 private constant CLEAR_SELECTOR_MASK =
        bytes32(uint256(0xffffffff << 224));

    /**
     * @notice update functions callable on Diamond proxy
     * @param facetCuts array of structured Diamond facet update data
     * @param target optional recipient of initialization delegatecall
     * @param data optional initialization call data
     */
    function _diamondCut(
        FacetCut[] memory facetCuts,
        address target,
        bytes memory data
    ) internal {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        unchecked {
            uint256 originalSelectorCount = l.selectorCount;
            uint256 selectorCount = originalSelectorCount;
            bytes32 selectorSlot;

            // Check if last selector slot is not full
            if (selectorCount & 7 > 0) {
                // get last selectorSlot
                selectorSlot = l.selectorSlots[selectorCount >> 3];
            }

            for (uint256 i; i < facetCuts.length; i++) {
                FacetCut memory facetCut = facetCuts[i];
                FacetCutAction action = facetCut.action;

                if (facetCut.selectors.length == 0)
                    revert DiamondWritable__SelectorNotSpecified();

                if (action == FacetCutAction.ADD) {
                    (selectorCount, selectorSlot) = _addFacetSelectors(
                        l,
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                } else if (action == FacetCutAction.REPLACE) {
                    _replaceFacetSelectors(l, facetCut);
                } else if (action == FacetCutAction.REMOVE) {
                    (selectorCount, selectorSlot) = _removeFacetSelectors(
                        l,
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                }
            }

            if (selectorCount != originalSelectorCount) {
                l.selectorCount = uint16(selectorCount);
            }

            // If last selector slot is not full
            if (selectorCount & 7 > 0) {
                l.selectorSlots[selectorCount >> 3] = selectorSlot;
            }

            emit DiamondCut(facetCuts, target, data);
            _initialize(target, data);
        }
    }

    function _addFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            if (
                facetCut.target != address(this) &&
                !facetCut.target.isContract()
            ) revert DiamondWritable__TargetHasNoCode();

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                if (address(bytes20(oldFacet)) != address(0))
                    revert DiamondWritable__SelectorAlreadyAdded();

                // add facet for selector
                l.facets[selector] =
                    bytes20(facetCut.target) |
                    bytes32(selectorCount);
                uint256 selectorInSlotPosition = (selectorCount & 7) << 5;

                // clear selector position in slot and add selector
                selectorSlot =
                    (selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);

                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    l.selectorSlots[selectorCount >> 3] = selectorSlot;
                    selectorSlot = 0;
                }

                selectorCount++;
            }

            return (selectorCount, selectorSlot);
        }
    }

    function _removeFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            if (facetCut.target != address(0))
                revert DiamondWritable__RemoveTargetNotZeroAddress();

            uint256 selectorSlotCount = selectorCount >> 3;
            uint256 selectorInSlotIndex = selectorCount & 7;

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                if (address(bytes20(oldFacet)) == address(0))
                    revert DiamondWritable__SelectorNotFound();

                if (address(bytes20(oldFacet)) == address(this))
                    revert DiamondWritable__SelectorIsImmutable();

                if (selectorSlot == 0) {
                    selectorSlotCount--;
                    selectorSlot = l.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }

                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                // adding a block here prevents stack too deep error
                {
                    // replace selector with last selector in l.facets
                    lastSelector = bytes4(
                        selectorSlot << (selectorInSlotIndex << 5)
                    );

                    if (lastSelector != selector) {
                        // update last selector slot position info
                        l.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(l.facets[lastSelector]);
                    }

                    delete l.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = l.selectorSlots[
                        oldSelectorsSlotCount
                    ];

                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    // update storage with the modified slot
                    l.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    selectorSlot =
                        (selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                if (selectorInSlotIndex == 0) {
                    delete l.selectorSlots[selectorSlotCount];
                    selectorSlot = 0;
                }
            }

            selectorCount = (selectorSlotCount << 3) | selectorInSlotIndex;

            return (selectorCount, selectorSlot);
        }
    }

    function _replaceFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        FacetCut memory facetCut
    ) internal {
        unchecked {
            if (!facetCut.target.isContract())
                revert DiamondWritable__TargetHasNoCode();

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                if (oldFacetAddress == address(0))
                    revert DiamondWritable__SelectorNotFound();
                if (oldFacetAddress == address(this))
                    revert DiamondWritable__SelectorIsImmutable();
                if (oldFacetAddress == facetCut.target)
                    revert DiamondWritable__ReplaceTargetIsIdentical();

                // replace old facet address
                l.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(facetCut.target);
            }
        }
    }

    function _initialize(address target, bytes memory data) private {
        if ((target == address(0)) != (data.length == 0))
            revert DiamondWritable__InvalidInitializationParameters();

        if (target != address(0)) {
            if (target != address(this)) {
                if (!target.isContract())
                    revert DiamondWritable__TargetHasNoCode();
            }

            (bool success, ) = target.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   DSquared Common Roles
 * @notice  Access control roles available to all strategy contracts
 * @author  HessianX
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedOriole
 */
abstract contract DSQ_Common_Roles {
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { AccountBalanceLib } from "./AccountBalanceLib.sol";


/**
 * @title   IDepositWithdrawalProxy
 * @author  Dolomite
 *
 * @notice  Interface for making easy deposits or withdrawals for DolomiteMargin.
 */
interface IDepositWithdrawalProxy {
    // ========================= Functions =========================

    function initializeETHMarket(address payable _weth) external;

    /**
     *
     * @param  _toAccountIndex  The index into which `msg.sender` will be depositing
     * @param  _marketId        The ID of the market being deposited
     * @param  _amountWei       The amount, in Wei, to deposit. Use `uint(-1)` to deposit `msg.sender`'s entire balance
     */
    function depositWei(
        uint256 _toAccountIndex,
        uint256 _marketId,
        uint256 _amountWei
    ) external;

    /**
     * Same as `depositWei` but converts the `msg.sender`'s sent ETH into WETH before depositing into `DolomiteMargin`.
     *
     * @param  _toAccountIndex  The index into which `msg.sender` will be depositing
     */
    function depositETH(
        uint256 _toAccountIndex
    ) external payable;

    /**
     * @dev Same as `depositWei` but defaults to account index 0 to save additional call data
     *
     * @param  _marketId    The ID of the market being deposited
     * @param  _amountWei   The amount, in Wei, to deposit. Use `uint(-1)` to deposit `msg.sender`'s entire balance
     */
    function depositWeiIntoDefaultAccount(
        uint256 _marketId,
        uint256 _amountWei
    ) external;

    /**
     * Same as `depositWeiIntoDefaultAccount` but converts the `msg.sender`'s sent ETH into WETH before depositing into
     * `DolomiteMargin`.
     */
    function depositETHIntoDefaultAccount() external payable;

    /**
     *
     * @param  _fromAccountIndex    The index from which `msg.sender` will be withdrawing
     * @param  _marketId            The ID of the market being withdrawn
     * @param  _amountWei           The amount, in Wei, to withdraw. Use `uint(-1)` to withdraw `msg.sender`'s entire
     *                              balance
     * @param  _balanceCheckFlag    Use `BalanceCheckFlag.Both` or `BalanceCheckFlag.From` to check that
     *                              `_fromAccountIndex` balance is non-negative after the withdrawal settles.
     */
    function withdrawWei(
        uint256 _fromAccountIndex,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * Same as `withdrawWei` but for withdrawing ETH. The user will receive unwrapped ETH from DolomiteMargin.
     *
     * @param  _fromAccountIndex    The index from which `msg.sender` will be withdrawing
     * @param  _amountWei           The amount, in Wei, to withdraw. Use `uint(-1)` to withdraw `msg.sender`'s entire
     *                              balance.
     * @param  _balanceCheckFlag    Use `BalanceCheckFlag.Both` or `BalanceCheckFlag.From` to check that
     *                              `_fromAccountIndex` balance is non-negative after the withdrawal settles.
     */
    function withdrawETH(
        uint256 _fromAccountIndex,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @dev Same as `withdrawWei` but defaults to account index 0 to save additional call data
     *
     * @param  _marketId            The ID of the market being withdrawn
     * @param  _amountWei           The amount, in Wei, to withdraw. Use `uint(-1)` to withdraw `msg.sender`'s entire
     *                              balance
     * @param  _balanceCheckFlag    Use `BalanceCheckFlag.Both` or `BalanceCheckFlag.From` to check that
     *                              `_fromAccountIndex` balance is non-negative after the withdrawal settles.
     */
    function withdrawWeiFromDefaultAccount(
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * Same as `withdrawWeiFromDefaultAccount` but for withdrawing ETH. The user will receive unwrapped ETH from
     * DolomiteMargin.
     *
     * @param  _amountWei           The amount, in Wei, to withdraw. Use `uint(-1)` to withdraw `msg.sender`'s entire
     *                              balance
     * @param  _balanceCheckFlag    Use `BalanceCheckFlag.Both` or `BalanceCheckFlag.From` to check that
     *                              `_fromAccountIndex` balance is non-negative after the withdrawal settles.
     */
    function withdrawETHFromDefaultAccount(
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     *
     * @param  _toAccountIndex  The index into which `msg.sender` will be depositing
     * @param  _marketId        The ID of the market being deposited
     * @param  _amountPar       The amount, in Par, to deposit.
     */
    function depositPar(
        uint256 _toAccountIndex,
        uint256 _marketId,
        uint256 _amountPar
    ) external;

    /**
     * @dev Same as `depositPar` but defaults to account index 0 to save additional call data
     *
     * @param  _marketId    The ID of the market being deposited
     * @param  _amountPar   The amount, in Par, to deposit.
     */
    function depositParIntoDefaultAccount(
        uint256 _marketId,
        uint256 _amountPar
    ) external;

    /**
     *
     * @param  _fromAccountIndex    The index from which `msg.sender` will be withdrawing
     * @param  _marketId            The ID of the market being withdrawn
     * @param  _amountPar           The amount, in Par, to withdraw. Use `uint(-1)` to withdraw `msg.sender`'s entire
     *                              balance
     * @param  _balanceCheckFlag    Use `BalanceCheckFlag.Both` or `BalanceCheckFlag.From` to check that
     *                              `_fromAccountIndex` balance is non-negative after the withdrawal settles.
     */
    function withdrawPar(
        uint256 _fromAccountIndex,
        uint256 _marketId,
        uint256 _amountPar,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @dev Same as `withdrawPar` but defaults to account index 0 to save additional call data
     *
     * @param  _marketId            The ID of the market being withdrawn
     * @param  _amountPar           The amount, in Par, to withdraw. Use `uint(-1)` to withdraw `msg.sender`'s entire
     *                              balance
     * @param  _balanceCheckFlag    Use `BalanceCheckFlag.Both` or `BalanceCheckFlag.From` to check that
     *                              `_fromAccountIndex` balance is non-negative after the withdrawal settles.
     */
    function withdrawParFromDefaultAccount(
        uint256 _marketId,
        uint256 _amountPar,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { AccountBalanceLib } from "./AccountBalanceLib.sol";


/**
 * @title   IBorrowPositionProxyV1
 * @author  Dolomite
 *
 * @notice  Interface for allowing the transfer of assets between account numbers. Emits an event to allow for easy
 *          indexing of a subgraph for getting active borrow positions.
 */
interface IBorrowPositionProxyV1 {

    // ========================= Events =========================

    event BorrowPositionOpen(address indexed _borrower, uint256 indexed _borrowAccountNumber);

    // ========================= Functions =========================

    /**
     *
     * @param  _fromAccountNumber   The index from which `msg.sender` will be sourcing the deposit
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing
     * @param  _collateralMarketId  The ID of the market being deposited
     * @param  _amountWei           The amount, in Wei, to deposit
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  This method can only be called once the user's debt has been reduced to zero. Sends all
     *          `_collateralMarketIds` from `_borrowAccountNumber` to `_toAccountNumber`.
     *
     * @param  _borrowAccountNumber The index from which `msg.sender` collateral will be withdrawn
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing leftover collateral
     * @param  _collateralMarketIds The IDs of the markets being withdrawn, to close the position
     */
    function closeBorrowPosition(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external;

    /**
     *
     * @param  _fromAccountNumber   The index from which `msg.sender` will be withdrawing assets
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _amountWei           The amount, in Wei, to transfer
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function transferBetweenAccounts(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     *
     * @param  _fromAccountNumber   The index from which `msg.sender` will be depositing assets
     * @param  _borrowAccountNumber The index of the borrow position for that will receive the deposited assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_borrowAccountNumber`, or both accounts
     *                              can go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function repayAllForBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IAuthorizationBase } from "./IAuthorizationBase.sol";
import { IBorrowPositionProxyV1 } from "./IBorrowPositionProxyV1.sol";
import { AccountBalanceLib } from "./AccountBalanceLib.sol";


/**
 * @title   IBorrowPositionProxyV2
 * @author  Dolomite
 *
 * @notice  Interface for allowing only trusted callers to invoke borrow related functions for transferring funds
 *          between account owners.
 */
interface IBorrowPositionProxyV2 is IAuthorizationBase, IBorrowPositionProxyV1 {

    // ========================= Functions =========================

    /**
     *
     * @param  _fromAccountOwner    The account from which the user will be sourcing the deposit
     * @param  _fromAccountNumber   The index from which `_toAccountOwner` will be sourcing the deposit
     * @param  _toAccountOwner      The account into which `_fromAccountOwner` will be depositing
     * @param  _toAccountNumber     The index into which `_fromAccountOwner` will be depositing
     * @param  _collateralMarketId  The ID of the market being deposited
     * @param  _amountWei           The amount, in Wei, to deposit
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function openBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  This method can only be called once the user's debt has been reduced to zero. Sends all
     *          `_collateralMarketIds` from `_borrowAccountNumber` to `_toAccountNumber`.
     *
     * @param  _borrowAccountOwner  The account from which collateral will be withdrawn
     * @param  _borrowAccountNumber The index from which `msg.sender` collateral will be withdrawn
     * @param  _toAccountOwner      The account into which `_borrowAccountOwner` will be depositing leftover collateral
     * @param  _toAccountNumber     The index into which `_borrowAccountOwner` will be depositing leftover collateral
     * @param  _collateralMarketIds The IDs of the markets being withdrawn, to close the position
     */
    function closeBorrowPositionWithDifferentAccounts(
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external;

    /**
     *
     * @param  _fromAccountOwner    The account from which assets will be withdrawn
     * @param  _fromAccountNumber   The index from which `msg.sender` will be withdrawing assets
     * @param  _toAccountOwner      The account to which assets will be deposited
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _amountWei           The amount, in Wei, to transfer
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function transferBetweenAccountsWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     *
     * @param  _fromAccountOwner    The account from which assets will be withdrawn for repayment
     * @param  _fromAccountNumber   The index from which `msg.sender` will be depositing assets
     * @param  _borrowAccountOwner  The account of the borrow position that will receive the deposited assets
     * @param  _borrowAccountNumber The index of the borrow position for that will receive the deposited assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_borrowAccountNumber`, or both accounts
     *                              can go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function repayAllForBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "./IDolomiteMargin.sol";
import { IDolomiteStructs } from "./IDolomiteStructs.sol";

import { Require } from "./Require.sol";
import { TypesLib } from "./TypesLib.sol";


/**
 * @title   AccountBalanceLib
 * @author  Dolomite
 *
 * @notice  Library contract that checks a user's balance after transaction to be non-negative
 */
library AccountBalanceLib {
    using TypesLib for IDolomiteStructs.Par;

    // ============ Types ============

    /// Checks that either BOTH, FROM, or TO accounts all have non-negative balances
    enum BalanceCheckFlag {
        Both,
        From,
        To,
        None
    }

    // ============ Constants ============

    bytes32 private constant _FILE = "AccountBalanceLib";

    // ============ Functions ============

    /**
     *  Checks that the account's balance is non-negative. Reverts if the check fails
     */
    function verifyBalanceIsNonNegative(
        IDolomiteMargin dolomiteMargin,
        address _accountOwner,
        uint256 _accountNumber,
        uint256 _marketId
    ) internal view {
        IDolomiteStructs.AccountInfo memory account = IDolomiteStructs.AccountInfo({
            owner: _accountOwner,
            number: _accountNumber
        });
        IDolomiteStructs.Par memory par = dolomiteMargin.getAccountPar(account, _marketId);
        Require.that(
            par.isPositive() || par.isZero(),
            _FILE,
            "account cannot go negative",
            _accountOwner,
            _accountNumber,
            _marketId
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
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

//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

// For full documentation refer to @lyrafinance/protocol/contracts/LiquidityPool.sol";
interface ILiquidityPool {
    struct Collateral {
        uint quote;
        uint base;
    }

    /// These values are all in quoteAsset amounts.
    struct Liquidity {
        // Amount of liquidity available for option collateral and premiums
        uint freeLiquidity;
        // Amount of liquidity available for withdrawals - different to freeLiquidity
        uint burnableLiquidity;
        // Amount of liquidity reserved for long options sold to traders
        uint reservedCollatLiquidity;
        // Portion of liquidity reserved for delta hedging (quote outstanding)
        uint pendingDeltaLiquidity;
        // Current value of delta hedge
        uint usedDeltaLiquidity;
        // Net asset value, including everything and netOptionValue
        uint NAV;
    }

    struct QueuedDeposit {
        uint id;
        // Who will receive the LiquidityToken minted for this deposit after the wait time
        address beneficiary;
        // The amount of quoteAsset deposited to be converted to LiquidityToken after wait time
        uint amountLiquidity;
        // The amount of LiquidityToken minted. Will equal to 0 if not processed
        uint mintedTokens;
        uint depositInitiatedTime;
    }

    struct QueuedWithdrawal {
        uint id;
        // Who will receive the quoteAsset returned after burning the LiquidityToken
        address beneficiary;
        // The amount of LiquidityToken being burnt after the wait time
        uint amountTokens;
        // The amount of quote transferred. Will equal to 0 if process not started
        uint quoteSent;
        uint withdrawInitiatedTime;
    }

    struct LiquidityPoolParameters {
        // The minimum amount of quoteAsset for a deposit, or the amount of LiquidityToken for a withdrawal
        uint minDepositWithdraw;
        // Time between initiating a deposit and when it can be processed
        uint depositDelay;
        // Time between initiating a withdrawal and when it can be processed
        uint withdrawalDelay;
        // Fee charged on withdrawn funds
        uint withdrawalFee;
        // Percentage of NAV below which the liquidity CB fires
        uint liquidityCBThreshold;
        // Length of time after the liq. CB stops firing during which deposits/withdrawals are still blocked
        uint liquidityCBTimeout;
        // Difference between the spot and GWAV baseline IVs after which point the vol CB will fire
        uint ivVarianceCBThreshold;
        // Difference between the spot and GWAV skew ratios after which point the vol CB will fire
        uint skewVarianceCBThreshold;
        // Length of time after the (base) vol. CB stops firing during which deposits/withdrawals are still blocked
        uint ivVarianceCBTimeout;
        // Length of time after the (skew) vol. CB stops firing during which deposits/withdrawals are still blocked
        uint skewVarianceCBTimeout;
        // The address of the "guardian"
        address guardianMultisig;
        // Length of time a deposit/withdrawal since initiation for before a guardian can force process their transaction
        uint guardianDelay;
        // When a new board is listed, block deposits/withdrawals
        uint boardSettlementCBTimeout;
        // When exchanging, don't exchange if fee is above this value
        uint maxFeePaid;
    }

    struct CircuitBreakerParameters {
        // Percentage of NAV below which the liquidity CB fires
        uint liquidityCBThreshold;
        // Length of time after the liq. CB stops firing during which deposits/withdrawals are still blocked
        uint liquidityCBTimeout;
        // Difference between the spot and GWAV baseline IVs after which point the vol CB will fire
        uint ivVarianceCBThreshold;
        // Difference between the spot and GWAV skew ratios after which point the vol CB will fire
        uint skewVarianceCBThreshold;
        // Length of time after the (base) vol. CB stops firing during which deposits/withdrawals are still blocked
        uint ivVarianceCBTimeout;
        // Length of time after the (skew) vol. CB stops firing during which deposits/withdrawals are still blocked
        uint skewVarianceCBTimeout;
        // When a new board is listed, block deposits/withdrawals
        uint boardSettlementCBTimeout;
        // Timeout on deposits and withdrawals in a contract adjustment event
        uint contractAdjustmentCBTimeout;
    }

    function poolHedger() external view returns (address);

    function queuedDeposits(uint id) external view returns (QueuedDeposit memory);

    function totalQueuedDeposits() external view returns (uint);

    function queuedDepositHead() external view returns (uint);

    function nextQueuedDepositId() external view returns (uint);

    function queuedWithdrawals(uint id) external view returns (QueuedWithdrawal memory);

    function totalQueuedWithdrawals() external view returns (uint);

    function queuedWithdrawalHead() external view returns (uint);

    function nextQueuedWithdrawalId() external view returns (uint);

    function CBTimestamp() external view returns (uint);

    /// @dev Amount of collateral locked for outstanding calls and puts sold to users
    function lockedCollateral() external view returns (Collateral memory);

    /// @dev Total amount of quoteAsset reserved for all settled options that have yet to be paid out
    function totalOutstandingSettlements() external view returns (uint);

    /// @dev Total value not transferred to this contract for all shorts that didn't have enough collateral after expiry
    function insolventSettlementAmount() external view returns (uint);

    /// @dev Total value not transferred to this contract for all liquidations that didn't have enough collateral when liquidated
    function liquidationInsolventAmount() external view returns (uint);

    function initiateDeposit(address beneficiary, uint amountQuote) external;

    function initiateWithdraw(address beneficiary, uint amountLiquidityToken) external;

    function processDepositQueue(uint limit) external;

    function processWithdrawalQueue(uint limit) external;

    function updateCBs() external;

    function getTotalTokenSupply() external view returns (uint);

    function getTokenPriceWithCheck() external view returns (uint tokenPrice, bool isStale, uint circuitBreakerExpiry);

    function getTokenPrice() external view returns (uint);

    function getLiquidity() external view returns (Liquidity memory);

    function getTotalPoolValueQuote() external view returns (uint);

    function exchangeBase() external;

    function getLpParams() external view returns (LiquidityPoolParameters memory);

    ////////////
    // Events //
    ////////////

    /// @dev Emitted whenever the pool paramters are updated
    event LiquidityPoolParametersUpdated(LiquidityPoolParameters lpParams);

    /// @dev Emitted whenever the poolHedger address is modified
    event PoolHedgerUpdated(address poolHedger);

    /// @dev Emitted when quote is locked.
    event PutCollateralLocked(uint quoteLocked, uint lockedCollateralQuote);

    /// @dev Emitted when AMM put collateral is freed.
    event PutCollateralFreed(uint quoteFreed, uint lockedCollateralQuote);

    /// @dev Emitted when base is locked.
    event CallCollateralLocked(uint baseLocked, uint lockedCollateralBase);

    /// @dev Emitted when AMM call collateral is freed.
    event CallCollateralFreed(uint baseFreed, uint lockedCollateralBase);

    /// @dev Emitted when a board is settled.
    event BoardSettlement(uint insolventSettlementAmount, uint amountQuoteReserved, uint totalOutstandingSettlements);

    /// @dev Emitted when reserved quote is sent.
    event OutstandingSettlementSent(address indexed user, uint amount, uint totalOutstandingSettlements);

    /// @dev Emitted whenever quote is exchanged for base
    event BasePurchased(uint quoteSpent, uint baseReceived);

    /// @dev Emitted whenever base is exchanged for quote
    event BaseSold(uint amountBase, uint quoteReceived);

    /// @dev Emitted whenever premium is sent to a trader closing their position
    event PremiumTransferred(address indexed recipient, uint recipientPortion, uint optionMarketPortion);

    /// @dev Emitted whenever quote is sent to the PoolHedger
    event QuoteTransferredToPoolHedger(uint amountQuote);

    /// @dev Emitted whenever the insolvent settlement amount is updated (settlement and excess)
    event InsolventSettlementAmountUpdated(uint amountQuoteAdded, uint totalInsolventSettlementAmount);

    /// @dev Emitted whenever a user deposits and enters the queue.
    event DepositQueued(
        address indexed depositor,
        address indexed beneficiary,
        uint indexed depositQueueId,
        uint amountDeposited,
        uint totalQueuedDeposits,
        uint timestamp
    );

    /// @dev Emitted whenever a deposit gets processed. Note, can be processed without being queued.
    ///  QueueId of 0 indicates it was not queued.
    event DepositProcessed(
        address indexed caller,
        address indexed beneficiary,
        uint indexed depositQueueId,
        uint amountDeposited,
        uint tokenPrice,
        uint tokensReceived,
        uint timestamp
    );

    /// @dev Emitted whenever a deposit gets processed. Note, can be processed without being queued.
    ///  QueueId of 0 indicates it was not queued.
    event WithdrawProcessed(
        address indexed caller,
        address indexed beneficiary,
        uint indexed withdrawalQueueId,
        uint amountWithdrawn,
        uint tokenPrice,
        uint quoteReceived,
        uint totalQueuedWithdrawals,
        uint timestamp
    );
    event WithdrawPartiallyProcessed(
        address indexed caller,
        address indexed beneficiary,
        uint indexed withdrawalQueueId,
        uint amountWithdrawn,
        uint tokenPrice,
        uint quoteReceived,
        uint totalQueuedWithdrawals,
        uint timestamp
    );
    event WithdrawQueued(
        address indexed withdrawer,
        address indexed beneficiary,
        uint indexed withdrawalQueueId,
        uint amountWithdrawn,
        uint totalQueuedWithdrawals,
        uint timestamp
    );

    /// @dev Emitted whenever the CB timestamp is updated
    event CircuitBreakerUpdated(
        uint newTimestamp,
        bool ivVarianceThresholdCrossed,
        bool skewVarianceThresholdCrossed,
        bool liquidityThresholdCrossed
    );

    /// @dev Emitted whenever the CB timestamp is updated from a board settlement
    event BoardSettlementCircuitBreakerUpdated(uint newTimestamp);

    /// @dev Emitted whenever a queue item is checked for the ability to be processed
    event CheckingCanProcess(uint entryId, bool boardNotStale, bool validEntry, bool guardianBypass, bool delaysExpired);

    ////////////
    // Errors //
    ////////////
    // Admin
    error InvalidLiquidityPoolParameters(address thrower, LiquidityPoolParameters lpParams);
    error InvalidCircuitBreakerParameters(address thrower, CircuitBreakerParameters cbParams);

    // Deposits and withdrawals
    error InvalidBeneficiaryAddress(address thrower, address beneficiary);
    error MinimumDepositNotMet(address thrower, uint amountQuote, uint minDeposit);
    error MinimumWithdrawNotMet(address thrower, uint amountQuote, uint minWithdraw);

    // Liquidity and accounting
    error LockingMoreQuoteThanIsFree(address thrower, uint quoteToLock, uint freeLiquidity, Collateral lockedCollateral);
    error SendPremiumNotEnoughCollateral(address thrower, uint premium, uint reservedFee, uint freeLiquidity);
    error NotEnoughFreeToReclaimInsolvency(address thrower, uint amountQuote, Liquidity liquidity);
    error OptionValueDebtExceedsTotalAssets(address thrower, int totalAssetValue, int optionValueDebt);
    error NegativeTotalAssetValue(address thrower, int totalAssetValue);

    // Access
    error OnlyPoolHedger(address thrower, address caller, address poolHedger);
    error OnlyOptionMarket(address thrower, address caller, address optionMarket);
    error OnlyShortCollateral(address thrower, address caller, address poolHedger);

    // Token transfers (amounts denominated in token decimals)
    error QuoteTransferFailed(address thrower, address from, address to, uint realAmount);
    error BaseTransferFailed(address thrower, address from, address to, uint realAmount);

    // @dev Emmitted whenever a position can not be opened as the hedger is unable to hedge
    error UnableToHedgeDelta(address thrower, uint amountOptions, bool increasesDelta);
}

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.13;

import "./IAddressResolver.sol";
import "./ISynthetix.sol";
import "./IExchanger.sol";
import "./IExchangeRates.sol";
import "./IDelegateApprovals.sol";

// For full documentation refer to @lyrafinance/protocol/contracts/SynthetixAdapter.sol";
interface ISynthetixAdapter {
    struct ExchangeParams {
        // snx oracle exchange rate for base
        uint spotPrice;
        // snx quote asset identifier key
        bytes32 quoteKey;
        // snx base asset identifier key
        bytes32 baseKey;
        // snx spot exchange rate from quote to base
        uint quoteBaseFeeRate;
        // snx spot exchange rate from base to quote
        uint baseQuoteFeeRate;
    }

    /// @dev Pause the whole system. Note; this will not pause settling previously expired options.
    function isMarketPaused(address market) external view returns (bool);

    function isGlobalPaused() external view returns (bool);

    function addressResolver() external view returns (address);

    function synthetix() external view returns (address);

    function exchanger() external view returns (address);

    function exchangeRates() external view returns (address);

    function delegateApprovals() external view returns (address);

    // Variables related to calculating premium/fees
    function quoteKey(address market) external view returns (bytes32);

    function baseKey(address market) external view returns (bytes32);

    function rewardAddress(address market) external view returns (bytes32);

    function trackingCode(address market) external view returns (bytes32);

    function updateSynthetixAddresses() external;

    /////////////
    // Getters //
    /////////////

    function rateAndCarry(address /*optionMarket*/) external view returns (int rateAndCarry);

    function getSpotPriceForMarket(address _contractAddress) external view returns (uint spotPrice);

    function getSpotPrice(bytes32 to) external view returns (uint);

    function getExchangeParams(address optionMarket) external view returns (ExchangeParams memory exchangeParams);

    function requireNotGlobalPaused(address optionMarket) external view;

    /////////////////////////////////////////
    // Exchanging QuoteAsset for BaseAsset //
    /////////////////////////////////////////

    function exchangeFromExactQuote(address optionMarket, uint amountQuote) external returns (uint baseReceived);

    function exchangeToExactBase(
        ExchangeParams memory exchangeParams,
        address optionMarket,
        uint amountBase
    ) external returns (uint quoteSpent, uint baseReceived);

    function exchangeToExactBaseWithLimit(
        ExchangeParams memory exchangeParams,
        address optionMarket,
        uint amountBase,
        uint quoteLimit
    ) external returns (uint quoteSpent, uint baseReceived);

    function estimateExchangeToExactBase(ExchangeParams memory exchangeParams, uint amountBase) external pure returns (uint quoteNeeded);

    /////////////////////////////////////////
    // Exchanging BaseAsset for QuoteAsset //
    /////////////////////////////////////////

    function exchangeFromExactBase(address optionMarket, uint amountBase) external returns (uint quoteReceived);

    function exchangeToExactQuote(
        ExchangeParams memory exchangeParams,
        address optionMarket,
        uint amountQuote
    ) external returns (uint baseSpent, uint quoteReceived);

    function exchangeToExactQuoteWithLimit(
        ExchangeParams memory exchangeParams,
        address optionMarket,
        uint amountQuote,
        uint baseLimit
    ) external returns (uint baseSpent, uint quoteReceived);

    function estimateExchangeToExactQuote(ExchangeParams memory exchangeParams, uint amountQuote) external pure returns (uint baseNeeded);

    ////////////
    // Events //
    ////////////

    /**
     * @dev Emitted when the address resolver is set.
     */
    event AddressResolverSet(IAddressResolver addressResolver);
    /**
     * @dev Emitted when synthetix contracts are updated.
     */
    event SynthetixAddressesUpdated(
        ISynthetix synthetix,
        IExchanger exchanger,
        IExchangeRates exchangeRates,
        IDelegateApprovals delegateApprovals
    );
    /**
     * @dev Emitted when values for a given option market are set.
     */
    event GlobalsSetForContract(address indexed market, bytes32 quoteKey, bytes32 baseKey, address rewardAddress, bytes32 trackingCode);
    /**
     * @dev Emitted when GlobalPause.
     */
    event GlobalPausedSet(bool isPaused);
    /**
     * @dev Emitted when single market paused.
     */
    event MarketPausedSet(address indexed contractAddress, bool isPaused);
    /**
     * @dev Emitted when an exchange for base to quote occurs.
     * Which base and quote were swapped can be determined by the given marketAddress.
     */
    event BaseSwappedForQuote(address indexed marketAddress, address indexed exchanger, uint baseSwapped, uint quoteReceived);
    /**
     * @dev Emitted when an exchange for quote to base occurs.
     * Which base and quote were swapped can be determined by the given marketAddress.
     */
    event QuoteSwappedForBase(address indexed marketAddress, address indexed exchanger, uint quoteSwapped, uint baseReceived);

    ////////////
    // Errors //
    ////////////
    // Admin
    error InvalidRewardAddress(address thrower, address rewardAddress);

    // Market Paused
    error AllMarketsPaused(address thrower, address marketAddress);
    error MarketIsPaused(address thrower, address marketAddress);

    // Exchanging
    error ReceivedZeroFromExchange(address thrower, bytes32 fromKey, bytes32 toKey, uint amountSwapped, uint amountReceived);
    error QuoteBaseExchangeExceedsLimit(
        address thrower,
        uint amountBaseRequested,
        uint quoteToSpend,
        uint quoteLimit,
        uint spotPrice,
        bytes32 quoteKey,
        bytes32 baseKey
    );
    error BaseQuoteExchangeExceedsLimit(
        address thrower,
        uint amountQuoteRequested,
        uint baseToSpend,
        uint baseLimit,
        uint spotPrice,
        bytes32 baseKey,
        bytes32 quoteKey
    );
    error RateIsInvalid(address thrower, uint spotPrice, bool invalid);
}

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.13;

import "./IOptionMarket.sol";
import "./IOptionGreekCache.sol";

// For full documentation refer to @lyrafinance/protocol/contracts/OptionMarketPricer.sol";
interface IOptionMarketPricer {
    struct PricingParameters {
        // Percentage of option price that is charged as a fee
        uint optionPriceFeeCoefficient;
        // Refer to: getTimeWeightedFee()
        uint optionPriceFee1xPoint;
        uint optionPriceFee2xPoint;
        // Percentage of spot price that is charged as a fee per option
        uint spotPriceFeeCoefficient;
        // Refer to: getTimeWeightedFee()
        uint spotPriceFee1xPoint;
        uint spotPriceFee2xPoint;
        // Refer to: getVegaUtilFee()
        uint vegaFeeCoefficient;
        // The amount of options traded to move baseIv for the board up or down 1 point (depending on trade direction)
        uint standardSize;
        // The relative move of skew for a given strike based on standard sizes traded
        uint skewAdjustmentFactor;
    }

    struct TradeLimitParameters {
        // Delta cutoff past which no options can be traded (optionD > minD && optionD < 1 - minD) - using call delta
        int minDelta;
        // Delta cutoff at which ForceClose can be called (optionD < minD || optionD > 1 - minD) - using call delta
        int minForceCloseDelta;
        // Time when trading closes. Only ForceClose can be called after this
        uint tradingCutoff;
        // Lowest baseIv for a board that can be traded for regular option opens/closes
        uint minBaseIV;
        // Maximal baseIv for a board that can be traded for regular option opens/closes
        uint maxBaseIV;
        // Lowest skew for a strike that can be traded for regular option opens/closes
        uint minSkew;
        // Maximal skew for a strike that can be traded for regular option opens/closes
        uint maxSkew;
        // Minimal vol traded for regular option opens/closes (baseIv * skew)
        uint minVol;
        // Maximal vol traded for regular option opens/closes (baseIv * skew)
        uint maxVol;
        // Absolute lowest skew that ForceClose can go to
        uint absMinSkew;
        // Absolute highest skew that ForceClose can go to
        uint absMaxSkew;
        // Cap the skew the abs max/min skews - only relevant to liquidations
        bool capSkewsToAbs;
    }

    struct VarianceFeeParameters {
        uint defaultVarianceFeeCoefficient;
        uint forceCloseVarianceFeeCoefficient;
        // coefficient that allows the skew component of the fee to be scaled up
        uint skewAdjustmentCoefficient;
        // measures the difference of the skew to a reference skew
        uint referenceSkew;
        // constant to ensure small vega terms have a fee
        uint minimumStaticSkewAdjustment;
        // coefficient that allows the vega component of the fee to be scaled up
        uint vegaCoefficient;
        // constant to ensure small vega terms have a fee
        uint minimumStaticVega;
        // coefficient that allows the ivVariance component of the fee to be scaled up
        uint ivVarianceCoefficient;
        // constant to ensure small variance terms have a fee
        uint minimumStaticIvVariance;
    }

    ///////////////
    // In-memory //
    ///////////////
    struct TradeResult {
        uint amount;
        uint premium;
        uint optionPriceFee;
        uint spotPriceFee;
        VegaUtilFeeComponents vegaUtilFee;
        VarianceFeeComponents varianceFee;
        uint totalFee;
        uint totalCost;
        uint volTraded;
        uint newBaseIv;
        uint newSkew;
    }

    struct VegaUtilFeeComponents {
        int preTradeAmmNetStdVega;
        int postTradeAmmNetStdVega;
        uint vegaUtil;
        uint volTraded;
        uint NAV;
        uint vegaUtilFee;
    }

    struct VarianceFeeComponents {
        uint varianceFeeCoefficient;
        uint vega;
        uint vegaCoefficient;
        uint skew;
        uint skewCoefficient;
        uint ivVariance;
        uint ivVarianceCoefficient;
        uint varianceFee;
    }

    struct VolComponents {
        uint vol;
        uint baseIv;
        uint skew;
    }

    ///////////////
    // Variables //
    ///////////////

    function pricingParams() external view returns (PricingParameters memory);

    function tradeLimitParams() external view returns (TradeLimitParameters memory);

    function varianceFeeParams() external view returns (VarianceFeeParameters memory);

    function ivImpactForTrade(
        IOptionMarket.TradeParameters memory trade,
        uint boardBaseIv,
        uint strikeSkew
    ) external view returns (uint newBaseIv, uint newSkew);

    function getTradeResult(
        IOptionMarket.TradeParameters memory trade,
        IOptionGreekCache.TradePricing memory pricing,
        uint newBaseIv,
        uint newSkew
    ) external view returns (TradeResult memory tradeResult);

    function getTimeWeightedFee(uint expiry, uint pointA, uint pointB, uint coefficient) external view returns (uint timeWeightedFee);

    function getVegaUtilFee(
        IOptionMarket.TradeParameters memory trade,
        IOptionGreekCache.TradePricing memory pricing
    ) external view returns (VegaUtilFeeComponents memory vegaUtilFeeComponents);

    function getVarianceFee(
        IOptionMarket.TradeParameters memory trade,
        IOptionGreekCache.TradePricing memory pricing,
        uint skew
    ) external view returns (VarianceFeeComponents memory varianceFeeComponents);

    /////////////////////////////
    // External View functions //
    /////////////////////////////

    function getPricingParams() external view returns (PricingParameters memory pricingParameters);

    function getTradeLimitParams() external view returns (TradeLimitParameters memory tradeLimitParameters);

    function getVarianceFeeParams() external view returns (VarianceFeeParameters memory varianceFeeParameters);

    ////////////
    // Events //
    ////////////

    event PricingParametersSet(PricingParameters pricingParams);
    event TradeLimitParametersSet(TradeLimitParameters tradeLimitParams);
    event VarianceFeeParametersSet(VarianceFeeParameters varianceFeeParams);

    ////////////
    // Errors //
    ////////////
    // Admin
    error InvalidTradeLimitParameters(address thrower, TradeLimitParameters tradeLimitParams);
    error InvalidPricingParameters(address thrower, PricingParameters pricingParams);

    // Trade limitations
    error TradingCutoffReached(address thrower, uint tradingCutoff, uint boardExpiry, uint currentTime);
    error ForceCloseSkewOutOfRange(address thrower, bool isBuy, uint newSkew, uint minSkew, uint maxSkew);
    error VolSkewOrBaseIvOutsideOfTradingBounds(
        address thrower,
        bool isBuy,
        VolComponents currentVol,
        VolComponents newVol,
        VolComponents tradeBounds
    );
    error TradeDeltaOutOfRange(address thrower, int strikeCallDelta, int minDelta, int maxDelta);
    error ForceCloseDeltaOutOfRange(address thrower, int strikeCallDelta, int minDelta, int maxDelta);

    // Access
    error OnlyOptionMarket(address thrower, address caller, address optionMarket);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param oldAddress The old address of the Pool
     * @param newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param oldAddress The old address of the PoolConfigurator
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice Returns the id of the Aave market to which this contract points to.
     * @return The market id
     **/
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple Aave markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     **/
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     **/
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     **/
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     **/
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     **/
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     **/
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     **/
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        address priceSource;
        string label;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveAToken;
        address priceOracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool useATokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteSetUserEModeParams {
        uint256 reservesCount;
        address oracle;
        uint8 categoryId;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
        uint8 fromEModeCategory;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        uint256[] interestRateModes;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address addressesProvider;
        uint8 userEModeCategory;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
        bool isolationModeActive;
        address isolationModeCollateralAddress;
        uint256 isolationModeDebtCeiling;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct CalculateInterestRatesParams {
        uint256 unbacked;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address aToken;
    }

    struct InitReserveParams {
        address asset;
        address aTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

/// @title Joe V1 Factory Interface
/// @notice Interface to interact with Joe V1 Factory
interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILBFactory } from "./ILBFactory.sol";
import { ILBFlashLoanCallback } from "./ILBFlashLoanCallback.sol";
import { ILBToken } from "./ILBToken.sol";

interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__AlreadyInitialized();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(
        uint40 lookupTimestamp
    ) external view returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY) external view returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY) external view returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(
        address to,
        bytes32[] calldata liquidityConfigs,
        address refundTo
    ) external returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amountsToBurn
    ) external returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function forceDecay() external;

    function approveForAll(address spender, bool approved) external;

    function isApprovedForAll(address owner, address spender) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Liquidity Book Token Interface
/// @author Trader Joe
/// @notice Required interface of LBToken contract
interface ILBToken is IERC165 {
    event TransferSingle(address indexed sender, address indexed from, address indexed to, uint256 id, uint256 amount);

    event TransferBatch(address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts);

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory batchBalances);

    function totalSupply(uint256 id) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function setApprovalForAll(address sender, bool approved) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata id, uint256[] calldata amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title WNATIVE Interface
 * @notice Required interface of Wrapped NATIVE contract
 */
interface IWNATIVE is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILBLegacyToken } from "./ILBLegacyToken.sol";

/// @title Liquidity Book Pair V2 Interface
/// @author Trader Joe
/// @notice Required interface of LBPair contract
interface ILBLegacyPair is ILBLegacyToken {
    /// @dev Structure to store the protocol fees:
    /// - binStep: The bin step
    /// - baseFactor: The base factor
    /// - filterPeriod: The filter period, where the fees stays constant
    /// - decayPeriod: The decay period, where the fees are halved
    /// - reductionFactor: The reduction factor, used to calculate the reduction of the accumulator
    /// - variableFeeControl: The variable fee control, used to control the variable fee, can be 0 to disable them
    /// - protocolShare: The share of fees sent to protocol
    /// - maxVolatilityAccumulated: The max value of volatility accumulated
    /// - volatilityAccumulated: The value of volatility accumulated
    /// - volatilityReference: The value of volatility reference
    /// - indexRef: The index reference
    /// - time: The last time the accumulator was called
    struct FeeParameters {
        // 144 lowest bits in slot
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
        // 112 highest bits in slot
        uint24 volatilityAccumulated;
        uint24 volatilityReference;
        uint24 indexRef;
        uint40 time;
    }

    /// @dev Structure used during swaps to distributes the fees:
    /// - total: The total amount of fees
    /// - protocol: The amount of fees reserved for protocol
    struct FeesDistribution {
        uint128 total;
        uint128 protocol;
    }

    /// @dev Structure to store the reserves of bins:
    /// - reserveX: The current reserve of tokenX of the bin
    /// - reserveY: The current reserve of tokenY of the bin
    struct Bin {
        uint112 reserveX;
        uint112 reserveY;
        uint256 accTokenXPerShare;
        uint256 accTokenYPerShare;
    }

    /// @dev Structure to store the information of the pair such as:
    /// slot0:
    /// - activeId: The current id used for swaps, this is also linked with the price
    /// - reserveX: The sum of amounts of tokenX across all bins
    /// slot1:
    /// - reserveY: The sum of amounts of tokenY across all bins
    /// - oracleSampleLifetime: The lifetime of an oracle sample
    /// - oracleSize: The current size of the oracle, can be increase by users
    /// - oracleActiveSize: The current active size of the oracle, composed only from non empty data sample
    /// - oracleLastTimestamp: The current last timestamp at which a sample was added to the circular buffer
    /// - oracleId: The current id of the oracle
    /// slot2:
    /// - feesX: The current amount of fees to distribute in tokenX (total, protocol)
    /// slot3:
    /// - feesY: The current amount of fees to distribute in tokenY (total, protocol)
    struct PairInformation {
        uint24 activeId;
        uint136 reserveX;
        uint136 reserveY;
        uint16 oracleSampleLifetime;
        uint16 oracleSize;
        uint16 oracleActiveSize;
        uint40 oracleLastTimestamp;
        uint16 oracleId;
        FeesDistribution feesX;
        FeesDistribution feesY;
    }

    /// @dev Structure to store the debts of users
    /// - debtX: The tokenX's debt
    /// - debtY: The tokenY's debt
    struct Debts {
        uint256 debtX;
        uint256 debtY;
    }

    /// @dev Structure to store fees:
    /// - tokenX: The amount of fees of token X
    /// - tokenY: The amount of fees of token Y
    struct Fees {
        uint128 tokenX;
        uint128 tokenY;
    }

    /// @dev Structure to minting informations:
    /// - amountXIn: The amount of token X sent
    /// - amountYIn: The amount of token Y sent
    /// - amountXAddedToPair: The amount of token X that have been actually added to the pair
    /// - amountYAddedToPair: The amount of token Y that have been actually added to the pair
    /// - activeFeeX: Fees X currently generated
    /// - activeFeeY: Fees Y currently generated
    /// - totalDistributionX: Total distribution of token X. Should be 1e18 (100%) or 0 (0%)
    /// - totalDistributionY: Total distribution of token Y. Should be 1e18 (100%) or 0 (0%)
    /// - id: Id of the current working bin when looping on the distribution array
    /// - amountX: The amount of token X deposited in the current bin
    /// - amountY: The amount of token Y deposited in the current bin
    /// - distributionX: Distribution of token X for the current working bin
    /// - distributionY: Distribution of token Y for the current working bin
    struct MintInfo {
        uint256 amountXIn;
        uint256 amountYIn;
        uint256 amountXAddedToPair;
        uint256 amountYAddedToPair;
        uint256 activeFeeX;
        uint256 activeFeeY;
        uint256 totalDistributionX;
        uint256 totalDistributionY;
        uint256 id;
        uint256 amountX;
        uint256 amountY;
        uint256 distributionX;
        uint256 distributionY;
    }

    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        bool swapForY,
        uint256 amountIn,
        uint256 amountOut,
        uint256 volatilityAccumulated,
        uint256 fees
    );

    event FlashLoan(address indexed sender, address indexed receiver, IERC20 token, uint256 amount, uint256 fee);

    event CompositionFee(address indexed sender, address indexed recipient, uint256 indexed id, uint256 feesX, uint256 feesY);

    event DepositedToBin(address indexed sender, address indexed recipient, uint256 indexed id, uint256 amountX, uint256 amountY);

    event WithdrawnFromBin(address indexed sender, address indexed recipient, uint256 indexed id, uint256 amountX, uint256 amountY);

    event FeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event ProtocolFeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event OracleSizeIncreased(uint256 previousSize, uint256 newSize);

    function tokenX() external view returns (IERC20);

    function tokenY() external view returns (IERC20);

    function factory() external view returns (address);

    function getReservesAndId() external view returns (uint256 reserveX, uint256 reserveY, uint256 activeId);

    function getGlobalFees() external view returns (uint128 feesXTotal, uint128 feesYTotal, uint128 feesXProtocol, uint128 feesYProtocol);

    function getOracleParameters()
        external
        view
        returns (
            uint256 oracleSampleLifetime,
            uint256 oracleSize,
            uint256 oracleActiveSize,
            uint256 oracleLastTimestamp,
            uint256 oracleId,
            uint256 min,
            uint256 max
        );

    function getOracleSampleFrom(
        uint256 timeDelta
    ) external view returns (uint256 cumulativeId, uint256 cumulativeAccumulator, uint256 cumulativeBinCrossed);

    function feeParameters() external view returns (FeeParameters memory);

    function findFirstNonEmptyBinId(uint24 id_, bool sentTokenY) external view returns (uint24 id);

    function getBin(uint24 id) external view returns (uint256 reserveX, uint256 reserveY);

    function pendingFees(address account, uint256[] memory ids) external view returns (uint256 amountX, uint256 amountY);

    function swap(bool sentTokenY, address to) external returns (uint256 amountXOut, uint256 amountYOut);

    function flashLoan(address receiver, IERC20 token, uint256 amount, bytes calldata data) external;

    function mint(
        uint256[] calldata ids,
        uint256[] calldata distributionX,
        uint256[] calldata distributionY,
        address to
    ) external returns (uint256 amountXAddedToPair, uint256 amountYAddedToPair, uint256[] memory liquidityMinted);

    function burn(uint256[] calldata ids, uint256[] calldata amounts, address to) external returns (uint256 amountX, uint256 amountY);

    function increaseOracleLength(uint16 newSize) external;

    function collectFees(address account, uint256[] calldata ids) external returns (uint256 amountX, uint256 amountY);

    function collectProtocolFees() external returns (uint128 amountX, uint128 amountY);

    function setFeesParameters(bytes32 packedFeeParameters) external;

    function forceDecay() external;

    function initialize(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 sampleLifetime, bytes32 packedFeeParameters) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Liquidity Book Pending Ownable Interface
/// @author Trader Joe
/// @notice Required interface of Pending Ownable contract used for LBFactory
interface IPendingOwnable {
    event PendingOwnerSet(address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library OrderLib {
    struct Order {
        uint256 salt;
        address makerAsset;
        address takerAsset;
        address maker;
        address receiver;
        address allowedSender; // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;
        uint256 offsets;
        // bytes makerAssetData;
        // bytes takerAssetData;
        // bytes getMakingAmount; // this.staticcall(abi.encodePacked(bytes, swapTakerAmount)) => (swapMakerAmount)
        // bytes getTakingAmount; // this.staticcall(abi.encodePacked(bytes, swapMakerAmount)) => (swapTakerAmount)
        // bytes predicate;       // this.staticcall(bytes) => (bool)
        // bytes permit;          // On first fill: permit.1.call(abi.encodePacked(permit.selector, permit.2))
        // bytes preInteraction;
        // bytes postInteraction;
        bytes interactions; // concat(makerAssetData, takerAssetData, getMakingAmount, getTakingAmount, predicate, permit, preIntercation, postInteraction)
    }

    bytes32 internal constant _LIMIT_ORDER_TYPEHASH =
        keccak256(
            "Order("
            "uint256 salt,"
            "address makerAsset,"
            "address takerAsset,"
            "address maker,"
            "address receiver,"
            "address allowedSender,"
            "uint256 makingAmount,"
            "uint256 takingAmount,"
            "uint256 offsets,"
            "bytes interactions"
            ")"
        );

    enum DynamicField {
        MakerAssetData,
        TakerAssetData,
        GetMakingAmount,
        GetTakingAmount,
        Predicate,
        Permit,
        PreInteraction,
        PostInteraction
    }

    function getterIsFrozen(bytes calldata getter) internal pure returns (bool) {
        return getter.length == 1 && getter[0] == "x";
    }

    function _get(Order calldata order, DynamicField field) private pure returns (bytes calldata) {
        uint256 bitShift = uint256(field) << 5; // field * 32
        return order.interactions[uint32((order.offsets << 32) >> bitShift):uint32(order.offsets >> bitShift)];
    }

    function makerAssetData(Order calldata order) internal pure returns (bytes calldata) {
        return _get(order, DynamicField.MakerAssetData);
    }

    function takerAssetData(Order calldata order) internal pure returns (bytes calldata) {
        return _get(order, DynamicField.TakerAssetData);
    }

    function getMakingAmount(Order calldata order) internal pure returns (bytes calldata) {
        return _get(order, DynamicField.GetMakingAmount);
    }

    function getTakingAmount(Order calldata order) internal pure returns (bytes calldata) {
        return _get(order, DynamicField.GetTakingAmount);
    }

    function predicate(Order calldata order) internal pure returns (bytes calldata) {
        return _get(order, DynamicField.Predicate);
    }

    function permit(Order calldata order) internal pure returns (bytes calldata) {
        return _get(order, DynamicField.Permit);
    }

    function preInteraction(Order calldata order) internal pure returns (bytes calldata) {
        return _get(order, DynamicField.PreInteraction);
    }

    function postInteraction(Order calldata order) internal pure returns (bytes calldata) {
        return _get(order, DynamicField.PostInteraction);
    }

    function hash(Order calldata order, bytes32 domainSeparator) internal pure returns (bytes32 result) {
        bytes calldata interactions = order.interactions;
        bytes32 typehash = _LIMIT_ORDER_TYPEHASH;
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            // keccak256(abi.encode(_LIMIT_ORDER_TYPEHASH, orderWithoutInteractions, keccak256(order.interactions)));
            calldatacopy(ptr, interactions.offset, interactions.length)
            mstore(add(ptr, 0x140), keccak256(ptr, interactions.length))
            calldatacopy(add(ptr, 0x20), order, 0x120)
            mstore(ptr, typehash)
            result := keccak256(ptr, 0x160)
        }
        result = ECDSA.toTypedDataHash(domainSeparator, result);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import { Types } from "./Types.sol";

interface IOptionRegistry {
    //////////////////////////////////////////////////////
    /// access-controlled state changing functionality ///
    //////////////////////////////////////////////////////

    /**
     * @notice Either retrieves the option token if it already exists, or deploy it
     * @param  optionSeries option series to issue
     * @return the address of the option
     */
    function issue(Types.OptionSeries memory optionSeries) external returns (address);

    /**
     * @notice Open an options contract using collateral from the liquidity pool
     * @param  _series the address of the option token to be created
     * @param  amount the amount of options to deploy
     * @param  collateralAmount the collateral required for the option
     * @dev only callable by the liquidityPool
     * @return if the transaction succeeded
     * @return the amount of collateral taken from the liquidityPool
     */
    function open(address _series, uint256 amount, uint256 collateralAmount) external returns (bool, uint256);

    /**
     * @notice Close an options contract (oToken) before it has expired
     * @param  _series the address of the option token to be burnt
     * @param  amount the amount of options to burn
     * @dev only callable by the liquidityPool
     * @return if the transaction succeeded
     */
    function close(address _series, uint256 amount) external returns (bool, uint256);

    /////////////////////////////////////////////
    /// external state changing functionality ///
    /////////////////////////////////////////////

    /**
     * @notice Settle an options vault
     * @param  _series the address of the option token to be burnt
     * @return success if the transaction succeeded
     * @return collatReturned the amount of collateral returned from the vault
     * @return collatLost the amount of collateral used to pay ITM options on vault settle
     * @return amountShort number of oTokens that the vault was short
     * @dev callable by anyone but returns funds to the liquidityPool
     */
    function settle(address _series) external returns (bool success, uint256 collatReturned, uint256 collatLost, uint256 amountShort);

    ///////////////////////
    /// complex getters ///
    ///////////////////////

    /**
     * @notice Send collateral funds for an option to be minted
     * @dev series.strike should be scaled by 1e8.
     * @param  series details of the option series
     * @param  amount amount of options to mint
     * @return amount transferred
     */
    function getCollateral(Types.OptionSeries memory series, uint256 amount) external view returns (uint256);

    /**
     * @notice Retrieves the option token if it exists
     * @param  underlying is the address of the underlying asset of the option
     * @param  strikeAsset is the address of the collateral asset of the option
     * @param  expiration is the expiry timestamp of the option
     * @param  isPut the type of option
     * @param  strike is the strike price of the option - 1e18 format
     * @param  collateral is the address of the asset to collateralize the option with
     * @return the address of the option
     */
    function getOtoken(
        address underlying,
        address strikeAsset,
        uint256 expiration,
        bool isPut,
        uint256 strike,
        address collateral
    ) external view returns (address);

    ///////////////////////////
    /// non-complex getters ///
    ///////////////////////////

    function getSeriesInfo(address series) external view returns (Types.OptionSeries memory);

    function getSeries(Types.OptionSeries memory _series) external view returns (address);

    function vaultIds(address series) external view returns (uint256);

    function gammaController() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9;

/// @title Accounting contract to calculate the dhv token value and handle deposit/withdraw mechanics

interface IAccounting {
    struct DepositReceipt {
        uint128 epoch;
        uint128 amount; // collateral decimals
        uint256 unredeemedShares; // e18
    }

    struct WithdrawalReceipt {
        uint128 epoch;
        uint128 shares; // e18
    }

    /**
     * @notice logic for adding liquidity to the options liquidity pool
     * @param  depositor the address making the deposit
     * @param  _amount amount of the collateral asset to deposit
     * @return depositAmount the amount to deposit from the round
     * @return unredeemedShares number of shares held in the deposit receipt that havent been redeemed
     */
    function deposit(address depositor, uint256 _amount) external returns (uint256 depositAmount, uint256 unredeemedShares);

    /**
     * @notice logic for allowing a user to redeem their shares from a previous epoch
     * @param  redeemer the address making the deposit
     * @param  shares amount of the collateral asset to deposit
     * @return toRedeem the amount to actually redeem
     * @return depositReceipt the updated deposit receipt after the redeem has completed
     */
    function redeem(address redeemer, uint256 shares) external returns (uint256 toRedeem, DepositReceipt memory depositReceipt);

    /**
     * @notice logic for accounting a user to initiate a withdraw request from the pool
     * @param  withdrawer the address carrying out the withdrawal
     * @param  shares the amount of shares to withdraw for
     * @return withdrawalReceipt the new withdrawal receipt to pass to the liquidityPool
     */
    function initiateWithdraw(address withdrawer, uint256 shares) external returns (WithdrawalReceipt memory withdrawalReceipt);

    /**
     * @notice logic for accounting a user to complete a withdrawal
     * @param  withdrawer the address carrying out the withdrawal
     * @return withdrawalAmount  the amount of collateral to withdraw
     * @return withdrawalShares  the number of shares to withdraw
     * @return withdrawalReceipt the new withdrawal receipt to pass to the liquidityPool
     */
    function completeWithdraw(
        address withdrawer
    ) external returns (uint256 withdrawalAmount, uint256 withdrawalShares, WithdrawalReceipt memory withdrawalReceipt);

    /**
     * @notice execute the next epoch
     * @param totalSupply  the total number of share tokens
     * @param assets the amount of collateral assets
     * @param liabilities the amount of liabilities of the pool
     * @return newPricePerShareDeposit the price per share for deposits
     * @return newPricePerShareWithdrawal the price per share for withdrawals
     * @return sharesToMint the number of shares to mint this epoch
     * @return totalWithdrawAmount the amount of collateral to set aside for partitioning
     * @return amountNeeded the amount needed to reach the total withdraw amount if collateral balance of lp is insufficient
     */
    function executeEpochCalculation(
        uint256 totalSupply,
        uint256 assets,
        int256 liabilities
    )
        external
        view
        returns (
            uint256 newPricePerShareDeposit,
            uint256 newPricePerShareWithdrawal,
            uint256 sharesToMint,
            uint256 totalWithdrawAmount,
            uint256 amountNeeded
        );

    /**
     * @notice get the number of shares for a given amount
     * @param _amount  the amount to convert to shares - assumed in collateral decimals
     * @param assetPerShare the amount of assets received per share
     * @return shares the number of shares based on the amount - assumed in e18
     */
    function sharesForAmount(uint256 _amount, uint256 assetPerShare) external view returns (uint256 shares);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Types {
    struct OptionSeries {
        uint64 expiration;
        uint128 strike;
        bool isPut;
        address underlying;
        address strikeAsset;
        address collateral;
    }
    struct PortfolioValues {
        int256 delta;
        int256 gamma;
        int256 vega;
        int256 theta;
        int256 callPutsValue;
        uint256 timestamp;
        uint256 spotPrice;
    }
    struct Option {
        uint64 expiration;
        uint128 strike;
        bool isPut;
        bool isBuyable;
        bool isSellable;
    }
    struct Order {
        OptionSeries optionSeries;
        uint256 amount;
        uint256 price;
        uint256 orderExpiry;
        address buyer;
        address seriesAddress;
        uint128 lowerSpotMovementRange;
        uint128 upperSpotMovementRange;
        bool isBuyBack;
    }
    // strike and expiry date range for options
    struct OptionParams {
        uint128 minCallStrikePrice;
        uint128 maxCallStrikePrice;
        uint128 minPutStrikePrice;
        uint128 maxPutStrikePrice;
        uint128 minExpiry;
        uint128 maxExpiry;
    }

    struct UtilizationState {
        uint256 totalOptionPrice; //e18
        int256 totalDelta; // e18
        uint256 collateralToAllocate; //collateral decimals
        uint256 utilizationBefore; // e18
        uint256 utilizationAfter; //e18
        uint256 utilizationPrice; //e18
        bool isDecreased;
        uint256 deltaTiltAmount; //e18
        uint256 underlyingPrice; // strike asset decimals
        uint256 iv; // e18
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165BaseInternal } from './IERC165BaseInternal.sol';

interface IERC165Base is IERC165, IERC165BaseInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165BaseInternal } from './IERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165BaseInternal is IERC165BaseInternal {
    /**
     * @notice indicates whether an interface is already supported based on the interfaceId
     * @param interfaceId id of interface to check
     * @return bool indicating whether interface is supported
     */
    function _supportsInterface(
        bytes4 interfaceId
    ) internal view virtual returns (bool) {
        return ERC165BaseStorage.layout().supportedInterfaces[interfaceId];
    }

    /**
     * @notice sets status of interface support
     * @param interfaceId id of interface to set status for
     * @param status boolean indicating whether interface will be set as supported
     */
    function _setSupportsInterface(
        bytes4 interfaceId,
        bool status
    ) internal virtual {
        if (interfaceId == 0xffffffff) revert ERC165Base__InvalidInterfaceId();
        ERC165BaseStorage.layout().supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165BaseStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
library DiamondBaseStorage {
    struct Layout {
        // function selector => (facet address, selector slot position)
        mapping(bytes4 => bytes32) facets;
        // total number of selectors registered
        uint16 selectorCount;
        // array of selector slots with 8 selectors per slot
        mapping(uint256 => bytes32) selectorSlots;
        address fallbackAddress;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.DiamondBase');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IDiamondWritableInternal {
    enum FacetCutAction {
        ADD,
        REPLACE,
        REMOVE
    }

    event DiamondCut(FacetCut[] facetCuts, address target, bytes data);

    error DiamondWritable__InvalidInitializationParameters();
    error DiamondWritable__RemoveTargetNotZeroAddress();
    error DiamondWritable__ReplaceTargetIsIdentical();
    error DiamondWritable__SelectorAlreadyAdded();
    error DiamondWritable__SelectorIsImmutable();
    error DiamondWritable__SelectorNotFound();
    error DiamondWritable__SelectorNotSpecified();
    error DiamondWritable__TargetHasNoCode();

    struct FacetCut {
        address target;
        FacetCutAction action;
        bytes4[] selectors;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IAuthorizationBase
 * @author  Dolomite
 *
 * @notice  Interface for allowing only trusted callers to invoke functions that use the `requireIsCallerAuthorized`
 *          modifier.
 */
interface IAuthorizationBase {

    function setIsCallerAuthorized(address _caller, bool _isAuthorized) external;

    function isCallerAuthorized(address _caller) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomiteMarginAdmin } from "./IDolomiteMarginAdmin.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteMargin
 * @author  Dolomite
 *
 * @notice  The interface for interacting with the main entry-point to DolomiteMargin
 */
interface IDolomiteMargin is IDolomiteMarginAdmin {

    // ==================================================
    // ================= Write Functions ================
    // ==================================================

    /**
     * The main entry-point to DolomiteMargin that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        AccountInfo[] calldata accounts,
        ActionArgs[] calldata actions
    ) external;

    /**
     * Approves/disapproves any number of operators. An operator is an external address that has the
     * same permissions to manipulate an account as the owner of the account. Operators are simply
     * addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
     *
     * Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
     * operator is a smart contract and implements the IAutoTrader interface.
     *
     * @param  args  A list of OperatorArgs which have an address and a boolean. The boolean value
     *               denotes whether to approve (true) or revoke approval (false) for that address.
     */
    function setOperators(
        OperatorArg[] calldata args
    ) external;

    // ==================================================
    // ================= Read Functions ================
    // ==================================================

    // ============ Getters for Markets ============

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  token    The token to query
     * @return          The token's marketId if the token is valid
     */
    function getMarketIdByTokenAddress(
        address token
    ) external view returns (uint256);

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  marketId  The market to query
     * @return           The token address
     */
    function getMarketTokenAddress(
        uint256 marketId
    ) external view returns (address);

    /**
     * Return the maximum amount of the market that can be supplied on Dolomite. Always 0 or positive.
     *
     * @param  marketId  The market to query
     * @return           The max amount of the market that can be supplied
     */
    function getMarketMaxWei(
        uint256 marketId
    ) external view returns (Wei memory);

    /**
     * Return true if a particular market is in closing mode. Additional borrows cannot be taken
     * from a market that is closing.
     *
     * @param  marketId  The market to query
     * @return           True if the market is closing
     */
    function getMarketIsClosing(
        uint256 marketId
    )
    external
    view
    returns (bool);

    /**
     * Get the price of the token for a market.
     *
     * @param  marketId  The market to query
     * @return           The price of each atomic unit of the token
     */
    function getMarketPrice(
        uint256 marketId
    ) external view returns (MonetaryPrice memory);

    /**
     * Get the total number of markets.
     *
     * @return  The number of markets
     */
    function getNumMarkets() external view returns (uint256);

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalPar(
        uint256 marketId
    ) external view returns (TotalPar memory);

    /**
     * Get the most recently cached interest index for a market.
     *
     * @param  marketId  The market to query
     * @return           The most recent index
     */
    function getMarketCachedIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the interest index for a market if it were to be updated right now.
     *
     * @param  marketId  The market to query
     * @return           The estimated current index
     */
    function getMarketCurrentIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the price oracle address for a market.
     *
     * @param  marketId  The market to query
     * @return           The price oracle address
     */
    function getMarketPriceOracle(
        uint256 marketId
    ) external view returns (IDolomitePriceOracle);

    /**
     * Get the interest-setter address for a market.
     *
     * @param  marketId  The market to query
     * @return           The interest-setter address
     */
    function getMarketInterestSetter(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter);

    /**
     * Get the margin premium for a market. A margin premium makes it so that any positions that
     * include the market require a higher collateralization to avoid being liquidated.
     *
     * @param  marketId  The market to query
     * @return           The market's margin premium
     */
    function getMarketMarginPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketSpreadPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Return true if this market can be removed and its ID can be recycled and reused
     *
     * @param  marketId  The market to query
     * @return           True if the market is recyclable
     */
    function getMarketIsRecyclable(
        uint256 marketId
    ) external view returns (bool);

    /**
     * Gets the recyclable markets, up to `n` length. If `n` is greater than the length of the list, 0's are returned
     * for the empty slots.
     *
     * @param  n    The number of markets to get, bounded by the linked list being smaller than `n`
     * @return      The list of recyclable markets, in the same order held by the linked list
     */
    function getRecyclableMarkets(
        uint256 n
    ) external view returns (uint[] memory);

    /**
     * Get the current borrower interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current interest rate
     */
    function getMarketInterestRate(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter.InterestRate memory);

    /**
     * Get basic information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A Market struct with the current state of the market
     */
    function getMarket(
        uint256 marketId
    ) external view returns (Market memory);

    /**
     * Get comprehensive information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A tuple containing the values:
     *                    - A Market struct with the current state of the market
     *                    - The current estimated interest index
     *                    - The current token price
     *                    - The current market interest rate
     */
    function getMarketWithInfo(
        uint256 marketId
    )
    external
    view
    returns (
        Market memory,
        InterestIndex memory,
        MonetaryPrice memory,
        IDolomiteInterestSetter.InterestRate memory
    );

    /**
     * Get the number of excess tokens for a market. The number of excess tokens is calculated by taking the current
     * number of tokens held in DolomiteMargin, adding the number of tokens owed to DolomiteMargin by borrowers, and
     * subtracting the number of tokens owed to suppliers by DolomiteMargin.
     *
     * @param  marketId  The market to query
     * @return           The number of excess tokens
     */
    function getNumExcessTokens(
        uint256 marketId
    ) external view returns (Wei memory);

    // ============ Getters for Accounts ============

    /**
     * Get the principal value for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountPar(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the principal value for a particular account and market, with no check the market is valid. Meaning, markets
     * that don't exist return 0.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountParNoMarketCheck(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the token balance for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The token amount
     */
    function getAccountWei(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Wei memory);

    /**
     * Get the status of an account (Normal, Liquidating, or Vaporizing).
     *
     * @param  account  The account to query
     * @return          The account's status
     */
    function getAccountStatus(
        AccountInfo calldata account
    ) external view returns (AccountStatus);

    /**
     * Get a list of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256[] memory);

    /**
     * Get the number of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the marketId for an account's market with a non-zero balance at the given index
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketWithBalanceAtIndex(
        AccountInfo calldata account,
        uint256 index
    ) external view returns (uint256);

    /**
     * Get the number of markets with which an account has a negative balance.
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithDebt(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the total supplied and total borrowed value of an account.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account
     *                   - The borrowed value of the account
     */
    function getAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get the total supplied and total borrowed values of an account adjusted by the marginPremium
     * of each market. Supplied values are divided by (1 + marginPremium) for each market and
     * borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
     * adjusted values gives the margin-ratio of the account which will be compared to the global
     * margin-ratio when determining if the account can be liquidated.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account (adjusted for marginPremium)
     *                   - The borrowed value of the account (adjusted for marginPremium)
     */
    function getAdjustedAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The market IDs for each market
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(
        AccountInfo calldata account
    ) external view returns (uint[] memory, address[] memory, Par[] memory, Wei[] memory);

    // ============ Getters for Account Permissions ============

    /**
     * Return true if a particular address is approved as an operator for an owner's accounts.
     * Approved operators can act on the accounts of the owner as if it were the operator's own.
     *
     * @param  owner     The owner of the accounts
     * @param  operator  The possible operator
     * @return           True if operator is approved for owner's accounts
     */
    function getIsLocalOperator(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * Return true if a particular address is approved as a global operator. Such an address can
     * act on any account as if it were the operator's own.
     *
     * @param  operator  The address to query
     * @return           True if operator is a global operator
     */
    function getIsGlobalOperator(
        address operator
    ) external view returns (bool);

    /**
     * Checks if the autoTrader can only be called invoked by a global operator
     *
     * @param  autoTrader    The trader that should be checked for special call privileges.
     */
    function getIsAutoTraderSpecial(address autoTrader) external view returns (bool);

    /**
     * @return The address that owns the DolomiteMargin protocol
     */
    function owner() external view returns (address);

    // ============ Getters for Risk Params ============

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @return  The global margin-ratio
     */
    function getMarginRatio() external view returns (Decimal memory);

    /**
     * Get the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     *
     * @return  The global liquidation spread
     */
    function getLiquidationSpread() external view returns (Decimal memory);

    /**
     * Get the adjusted liquidation spread for some market pair. This is equal to the global
     * liquidation spread multiplied by (1 + spreadPremium) for each of the two markets.
     *
     * @param  heldMarketId  The market for which the account has collateral
     * @param  owedMarketId  The market for which the account has borrowed tokens
     * @return               The adjusted liquidation spread
     */
    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal memory);

    /**
     * Get the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     *
     * @return  The global earnings rate
     */
    function getEarningsRate() external view returns (Decimal memory);

    /**
     * Get the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     *
     * @return  The global minimum borrow value
     */
    function getMinBorrowedValue() external view returns (MonetaryValue memory);

    /**
     * Get all risk parameters in a single struct.
     *
     * @return  All global risk parameters
     */
    function getRiskParams() external view returns (RiskParams memory);

    /**
     * Get all risk parameter limits in a single struct. These are the maximum limits at which the
     * risk parameters can be set by the admin of DolomiteMargin.
     *
     * @return  All global risk parameter limits
     */
    function getRiskLimits() external view returns (RiskLimits memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteAccountRiskOverrideSetter } from "./IDolomiteAccountRiskOverrideSetter.sol";
import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomiteOracleSentinel } from "./IDolomiteOracleSentinel.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteStructs
 * @author  Dolomite
 *
 * @notice  This interface defines the structs used by DolomiteMargin
 */
interface IDolomiteStructs {

    // ========================= Enums =========================

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    // ========================= Structs =========================

    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    /**
     * Most-recently-cached account status.
     *
     * Normal: Can only be liquidated if the account values are violating the global margin-ratio.
     * Liquid: Can be liquidated no matter the account values.
     *         Can be vaporized if there are no more positive account values.
     * Vapor:  Has only negative (or zeroed) account values. Can be vaporized.
     *
     */
    enum AccountStatus {
        Normal,
        Liquid,
        Vapor
    }

    /*
     * Arguments that are passed to DolomiteMargin in an ordered list as part of a single operation.
     * Each ActionArgs has an actionType which specifies which action struct that this data will be
     * parsed into before being processed.
     */
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Decimal {
        uint256 value;
    }

    struct InterestIndex {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

    struct Market {
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Whether this market can be removed and its ID can be recycled and reused
        bool isRecyclable;

        // Total aggregated supply and borrow amount of the entire market
        TotalPar totalPar;

        // Interest index of the market
        InterestIndex index;

        // Contract address of the price oracle for this market
        IDolomitePriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IDolomiteInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal spreadPremium;

        // The maximum amount that can be held by the external. This allows the external to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be below 0.
        Wei maxWei;
    }

    struct MarketV2 {
        // Contract address of the associated ERC20 token
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Total aggregated supply and borrow amount of the entire market
        TotalPar totalPar;

        // Interest index of the market
        InterestIndex index;

        // Contract address of the price oracle for this market
        IDolomitePriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IDolomiteInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal liquidationSpreadPremium;

        // The maximum amount that can be held by the protocol. This allows the protocol to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be below 0.
        Wei maxSupplyWei;

        // The maximum amount that can be borrowed by the protocol. This allows the protocol to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be greater than 0.
        Wei maxBorrowWei;

        // The percentage of interest paid that is passed along from borrowers to suppliers. Setting this to 0 will
        // default to RiskParams.earningsRate.
        Decimal earningsRateOverride;
    }

    /*
     * The price of a base-unit of an asset. Has `36 - token.decimals` decimals
     */
    struct MonetaryPrice {
        uint256 value;
    }

    struct MonetaryValue {
        uint256 value;
    }

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    struct Par {
        bool sign;
        uint128 value;
    }

    struct RiskLimits {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        // The highest min margin ratio premium that can be applied to a particular market. Meaning, a value of 100%
        // (1e18) would require borrowers to maintain an extra 100% collateral to maintain a healthy margin ratio. This
        // value works by increasing the debt owed and decreasing the supply held for the particular market by this
        // amount, plus 1e18 (since a value of 10% needs to be applied as `decimal.plusOne`)
        uint64 marginPremiumMax;
        // The highest liquidation reward that can be applied to a particular market. This percentage is applied
        // in addition to the liquidation spread in `RiskParams`. Meaning a value of 1e18 is 100%. It is calculated as:
        // `liquidationSpread * Decimal.onePlus(spreadPremium)`
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    struct RiskLimitsV2 {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        // The highest min margin ratio premium that can be applied to a particular market. Meaning, a value of 100%
        // (1e18) would require borrowers to maintain an extra 100% collateral to maintain a healthy margin ratio. This
        // value works by increasing the debt owed and decreasing the supply held for the particular market by this
        // amount, plus 1e18 (since a value of 10% needs to be applied as `decimal.plusOne`)
        uint64 marginPremiumMax;
        // The highest liquidation reward that can be applied to a particular market. This percentage is applied
        // in addition to the liquidation spread in `RiskParams`. Meaning a value of 1e18 is 100%. It is calculated as:
        // `liquidationSpread * Decimal.onePlus(spreadPremium)`
        uint64 liquidationSpreadPremiumMax;
        // The highest that the borrow interest rate can ever be. If the rate returned is ever higher, the rate is
        // capped at this value instead of reverting. The goal is to keep Dolomite operational under all circumstances
        // instead of inadvertently DOS'ing the protocol.
        uint96 interestRateMax;
        // The highest that the minBorrowedValue can be. This is the minimum amount of value that must be borrowed.
        // Typically a value of $100 (100 * 1e18) is more than sufficient.
        uint128 minBorrowedValueMax;
    }

    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        MonetaryValue minBorrowedValue;

        // The maximum number of markets a user can have a non-zero balance for a given account.
        uint256 accountMaxNumberOfMarketsWithBalances;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParamsV2 {
        // Required ratio of over-collateralization
        Decimal marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        MonetaryValue minBorrowedValue;

        // The maximum number of markets a user can have a non-zero balance for a given account.
        uint256 accountMaxNumberOfMarketsWithBalances;

        // The oracle sentinel used to disable borrowing/liquidations if the sequencer goes down
        IDolomiteOracleSentinel oracleSentinel;

        // The gas limit used for making callbacks via `IExternalCallback::onInternalBalanceChange` to smart contract
        // wallets. Setting to 0 will effectively disable callbacks; setting it super large is not desired since it
        // could lead to DOS attacks on the protocol; however, hard coding a max value isn't preferred since some chains
        // can calculate gas usage differently (like ArbGas before Arbitrum rolled out nitro)
        uint256 callbackGasLimit;

        // Certain addresses are allowed to borrow with different LTV requirements. When an account's risk is overrode,
        // the global risk parameters are ignored and the account's risk parameters are used instead.
        mapping(address => IDolomiteAccountRiskOverrideSetter) accountRiskOverrideSetterMap;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct TotalWei {
        uint128 borrow;
        uint128 supply;
    }

    struct Wei {
        bool sign;
        uint256 value;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   Require
 * @author  dYdX
 *
 * @notice  Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 private constant _ASCII_ZERO = 48; // '0'
    uint256 private constant _ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 private constant _ASCII_LOWER_EX = 120; // 'x'
    bytes2 private constant _COLON = 0x3a20; // ': '
    bytes2 private constant _COMMA = 0x2c20; // ', '
    bytes2 private constant _LPAREN = 0x203c; // ' <'
    bytes1 private constant _RPAREN = 0x3e; // '>'
    uint256 private constant _FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason)
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _COMMA,
                    _stringify(payloadC),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _COMMA,
                    _stringify(payloadC),
                    _RPAREN
                )
            )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
    internal
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solhint-disable-next-line no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringifyFunctionSelector(
        bytes4 input
    )
    internal
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(bytes32(input) >> 224);

        // bytes4 are "0x" followed by 4 bytes of data which take up 2 characters each
        bytes memory result = new bytes(10);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 4; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[9 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[8 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            i--;

            // take last decimal digit
            bstr[i] = bytes1(uint8(_ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function _stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(uint160(input));

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _char(
        uint256 input
    )
    private
    pure
    returns (bytes1)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return bytes1(uint8(input + _ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return bytes1(uint8(input + _ASCII_RELATIVE_ZERO));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";
import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   TypesLib
 * @author  dYdX
 *
 * @notice  Library for interacting with the basic structs used in DolomiteMargin
 */
library TypesLib {
    using DolomiteMarginMath for uint256;

    // ============ Par (Principal Amount) ============

    function zeroPar()
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return IDolomiteStructs.Par({
            sign: false,
            value: 0
        });
    }

    function sub(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return add(a, negative(b));
    }

    function add(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        IDolomiteStructs.Par memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = a.value + b.value;
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = a.value - b.value;
            } else {
                result.sign = b.sign;
                result.value = b.value - a.value;
            }
        }
        return result;
    }

    function equals(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return IDolomiteStructs.Par({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value == 0;
    }

    function isLessThanZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value > 0 && !a.sign;
    }

    function isGreaterThanOrEqualToZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return isZero(a) || a.sign;
    }

    // ============ Wei (Token Amount) ============

    function zeroWei()
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return IDolomiteStructs.Wei({
            sign: false,
            value: 0
        });
    }

    function sub(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return add(a, negative(b));
    }

    function add(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        IDolomiteStructs.Wei memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = a.value + b.value;
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = a.value - b.value;
            } else {
                result.sign = b.sign;
                result.value = b.value - a.value;
            }
        }
        return result;
    }

    function equals(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return IDolomiteStructs.Wei({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value == 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISynthetix {
    function exchange(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey) external returns (uint amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

// https://docs.synthetix.io/contracts/source/interfaces/iexchanger
interface IExchanger {
    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint exchangeFeeRate);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

// https://docs.synthetix.io/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IDelegateApprovals {
    function approveExchangeOnBehalf(address delegate) external;

    function canExchangeOnBehalf(address exchanger, address beneficiary) external view returns (bool);
}

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.13;

import "./IOptionMarket.sol";

// For full documentation refer to @lyrafinance/protocol/contracts/interfaces/IOptionGreekCache.sol";
interface IOptionGreekCache {
    struct GreekCacheParameters {
        // Cap the number of strikes per board to avoid hitting gasLimit constraints
        uint maxStrikesPerBoard;
        // How much spot price can move since last update before deposits/withdrawals are blocked
        uint acceptableSpotPricePercentMove;
        // How much time has passed since last update before deposits/withdrawals are blocked
        uint staleUpdateDuration;
        // Length of the GWAV for the baseline volatility used to fire the vol circuit breaker
        uint varianceIvGWAVPeriod;
        // Length of the GWAV for the skew ratios used to fire the vol circuit breaker
        uint varianceSkewGWAVPeriod;
        // Length of the GWAV for the baseline used to determine the NAV of the pool
        uint optionValueIvGWAVPeriod;
        // Length of the GWAV for the skews used to determine the NAV of the pool
        uint optionValueSkewGWAVPeriod;
        // Minimum skew that will be fed into the GWAV calculation
        // Prevents near 0 values being used to heavily manipulate the GWAV
        uint gwavSkewFloor;
        // Maximum skew that will be fed into the GWAV calculation
        uint gwavSkewCap;
    }

    struct ForceCloseParameters {
        // Length of the GWAV for the baseline vol used in ForceClose() and liquidations
        uint ivGWAVPeriod;
        // Length of the GWAV for the skew ratio used in ForceClose() and liquidations
        uint skewGWAVPeriod;
        // When a user buys back an option using ForceClose() we increase the GWAV vol to penalise the trader
        uint shortVolShock;
        // Increase the penalty when within the trading cutoff
        uint shortPostCutoffVolShock;
        // When a user sells back an option to the AMM using ForceClose(), we decrease the GWAV to penalise the seller
        uint longVolShock;
        // Increase the penalty when within the trading cutoff
        uint longPostCutoffVolShock;
        // Same justification as shortPostCutoffVolShock
        uint liquidateVolShock;
        // Increase the penalty when within the trading cutoff
        uint liquidatePostCutoffVolShock;
        // Minimum price the AMM will sell back an option at for force closes (as a % of current spot)
        uint shortSpotMin;
        // Minimum price the AMM will sell back an option at for liquidations (as a % of current spot)
        uint liquidateSpotMin;
    }

    struct MinCollateralParameters {
        // Minimum collateral that must be posted for a short to be opened (denominated in quote)
        uint minStaticQuoteCollateral;
        // Minimum collateral that must be posted for a short to be opened (denominated in base)
        uint minStaticBaseCollateral;
        /* Shock Vol:
         * Vol used to compute the minimum collateral requirements for short positions.
         * This value is derived from the following chart, created by using the 4 values listed below.
         *
         *     vol
         *      |
         * volA |____
         *      |    \
         * volB |     \___
         *      |___________ time to expiry
         *         A   B
         */
        uint shockVolA;
        uint shockVolPointA;
        uint shockVolB;
        uint shockVolPointB;
        // Static percentage shock to the current spot price for calls
        uint callSpotPriceShock;
        // Static percentage shock to the current spot price for puts
        uint putSpotPriceShock;
    }

    ///////////////////
    // Cache storage //
    ///////////////////
    struct GlobalCache {
        uint minUpdatedAt;
        uint minUpdatedAtPrice;
        uint maxUpdatedAtPrice;
        uint maxSkewVariance;
        uint maxIvVariance;
        NetGreeks netGreeks;
    }

    struct OptionBoardCache {
        uint id;
        uint[] strikes;
        uint expiry;
        uint iv;
        NetGreeks netGreeks;
        uint updatedAt;
        uint updatedAtPrice;
        uint maxSkewVariance;
        uint ivVariance;
    }

    struct StrikeCache {
        uint id;
        uint boardId;
        uint strikePrice;
        uint skew;
        StrikeGreeks greeks;
        int callExposure; // long - short
        int putExposure; // long - short
        uint skewVariance; // (GWAVSkew - skew)
    }

    // These are based on GWAVed iv
    struct StrikeGreeks {
        int callDelta;
        int putDelta;
        uint stdVega;
        uint callPrice;
        uint putPrice;
    }

    // These are based on GWAVed iv
    struct NetGreeks {
        int netDelta;
        int netStdVega;
        int netOptionValue;
    }

    ///////////////
    // In-memory //
    ///////////////
    struct TradePricing {
        uint optionPrice;
        int preTradeAmmNetStdVega;
        int postTradeAmmNetStdVega;
        int callDelta;
        uint volTraded;
        uint ivVariance;
        uint vega;
    }

    struct BoardGreeksView {
        NetGreeks boardGreeks;
        uint ivGWAV;
        StrikeGreeks[] strikeGreeks;
        uint[] skewGWAVs;
    }

    function getPriceForForceClose(
        IOptionMarket.TradeParameters memory trade,
        IOptionMarket.Strike memory strike,
        uint expiry,
        uint newVol,
        bool isPostCutoff
    ) external view returns (uint optionPrice, uint forceCloseVol);

    function getMinCollateral(
        IOptionMarket.OptionType optionType,
        uint strikePrice,
        uint expiry,
        uint spotPrice,
        uint amount
    ) external view returns (uint minCollateral);

    function getShockVol(uint timeToMaturity) external view returns (uint);

    function updateBoardCachedGreeks(uint boardId) external;

    function isGlobalCacheStale(uint spotPrice) external view returns (bool);

    function isBoardCacheStale(uint boardId) external view returns (bool);

    /////////////////////////////
    // External View functions //
    /////////////////////////////

    /// @notice Get the current cached global netDelta exposure.
    function getGlobalNetDelta() external view returns (int);

    /// @notice Get the current global net option value
    function getGlobalOptionValue() external view returns (int);

    /// @notice Returns the BoardGreeksView struct given a specific boardId
    function getBoardGreeksView(uint boardId) external view returns (BoardGreeksView memory);

    /// @notice Get StrikeCache given a specific strikeId
    function getStrikeCache(uint strikeId) external view returns (StrikeCache memory);

    /// @notice Get OptionBoardCache given a specific boardId
    function getOptionBoardCache(uint boardId) external view returns (OptionBoardCache memory);

    /// @notice Get the global cache
    function getGlobalCache() external view returns (GlobalCache memory);

    /// @notice Returns ivGWAV for a given boardId and GWAV time interval
    function getIvGWAV(uint boardId, uint secondsAgo) external view returns (uint ivGWAV);

    /// @notice Returns skewGWAV for a given strikeId and GWAV time interval
    function getSkewGWAV(uint strikeId, uint secondsAgo) external view returns (uint skewGWAV);

    /// @notice Get the GreekCacheParameters
    function getGreekCacheParams() external view returns (GreekCacheParameters memory);

    /// @notice Get the ForceCloseParamters
    function getForceCloseParams() external view returns (ForceCloseParameters memory);

    /// @notice Get the MinCollateralParamters
    function getMinCollatParams() external view returns (MinCollateralParameters memory);

    ////////////
    // Events //
    ////////////

    event GreekCacheParametersSet(GreekCacheParameters params);
    event ForceCloseParametersSet(ForceCloseParameters params);
    event MinCollateralParametersSet(MinCollateralParameters params);

    event StrikeCacheUpdated(StrikeCache strikeCache);
    event BoardCacheUpdated(OptionBoardCache boardCache);
    event GlobalCacheUpdated(GlobalCache globalCache);

    event BoardCacheRemoved(uint boardId);
    event StrikeCacheRemoved(uint strikeId);
    event BoardIvUpdated(uint boardId, uint newIv, uint globalMaxIvVariance);
    event StrikeSkewUpdated(uint strikeId, uint newSkew, uint globalMaxSkewVariance);

    ////////////
    // Errors //
    ////////////
    // Admin
    error InvalidGreekCacheParameters(address thrower, GreekCacheParameters greekCacheParams);
    error InvalidForceCloseParameters(address thrower, ForceCloseParameters forceCloseParams);
    error InvalidMinCollatParams(address thrower, MinCollateralParameters minCollatParams);

    // Board related
    error BoardStrikeLimitExceeded(address thrower, uint boardId, uint newStrikesLength, uint maxStrikesPerBoard);
    error InvalidBoardId(address thrower, uint boardId);
    error CannotUpdateExpiredBoard(address thrower, uint boardId, uint expiry, uint currentTimestamp);

    // Access
    error OnlyIOptionMarket(address thrower, address caller, address optionMarket);
    error OnlyIOptionMarketPricer(address thrower, address caller, address optionMarketPricer);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(address sender, IERC20 token, uint256 amount, uint256 fee, bytes calldata data) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Liquidity Book V2 Token Interface
/// @author Trader Joe
/// @notice Required interface of LBToken contract
interface ILBLegacyToken is IERC165 {
    event TransferSingle(address indexed sender, address indexed from, address indexed to, uint256 id, uint256 amount);

    event TransferBatch(address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts);

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory batchBalances);

    function totalSupply(uint256 id) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function setApprovalForAll(address sender, bool approved) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata id, uint256[] calldata amount) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165Internal } from '../../../interfaces/IERC165Internal.sol';

interface IERC165BaseInternal is IERC165Internal {
    error ERC165Base__InvalidInterfaceId();
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteInterestSetter
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that for an interest setter that can be used to determine the interest
 *          rate of a market.
 */
interface IDolomiteInterestSetter {

    // ============ Enum ============

    enum InterestSetterType {
        None,
        Linear,
        DoubleExponential,
        Other
    }

    // ============ Structs ============

    struct InterestRate {
        uint256 value;
    }

    // ============ Functions ============

    /**
     * Get the interest rate of a token given some borrowed and supplied amounts
     *
     * @param  token        The address of the ERC20 token for the market
     * @param  borrowWei    The total borrowed token amount for the market
     * @param  supplyWei    The total supplied token amount for the market
     * @return              The interest rate per second
     */
    function getInterestRate(
        address token,
        uint256 borrowWei,
        uint256 supplyWei
    )
    external
    view
    returns (InterestRate memory);

    function interestSetterType() external pure returns (InterestSetterType);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";
import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomiteMarginAdmin
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that can be called by the owner of DolomiteMargin.
 */
interface IDolomiteMarginAdmin is IDolomiteStructs {

    // ============ Token Functions ============

    /**
     * Withdraw an ERC20 token for which there is an associated market. Only excess tokens can be withdrawn. The number
     * of excess tokens is calculated by taking the current number of tokens held in DolomiteMargin, adding the number
     * of tokens owed to DolomiteMargin by borrowers, and subtracting the number of tokens owed to suppliers by
     * DolomiteMargin.
     */
    function ownerWithdrawExcessTokens(
        uint256 marketId,
        address recipient
    )
    external
    returns (uint256);

    /**
     * Withdraw an ERC20 token for which there is no associated market.
     */
    function ownerWithdrawUnsupportedTokens(
        address token,
        address recipient
    )
    external
    returns (uint256);

    // ============ Market Functions ============

    /**
     * Sets the number of non-zero balances an account may have within the same `accountIndex`. This ensures a user
     * cannot DOS the system by filling their account with non-zero balances (which linearly increases gas costs when
     * checking collateralization) and disallowing themselves to close the position, because the number of gas units
     * needed to process their transaction exceed the block's gas limit. In turn, this would  prevent the user from also
     * being liquidated, causing the all of the capital to be "stuck" in the position.
     *
     * Lowering this number does not "freeze" user accounts that have more than the new limit of balances, because this
     * variable is enforced by checking the users number of non-zero balances against the max or if it sizes down before
     * each transaction finishes.
     */
    function ownerSetAccountMaxNumberOfMarketsWithBalances(
        uint256 accountMaxNumberOfMarketsWithBalances
    )
    external;

    /**
     * Add a new market to DolomiteMargin. Must be for a previously-unsupported ERC20 token.
     */
    function ownerAddMarket(
        address token,
        IDolomitePriceOracle priceOracle,
        IDolomiteInterestSetter interestSetter,
        Decimal calldata marginPremium,
        Decimal calldata spreadPremium,
        uint256 maxWei,
        bool isClosing,
        bool isRecyclable
    )
    external;

    /**
     * Removes a market from DolomiteMargin, sends any remaining tokens in this contract to `salvager` and invokes the
     * recyclable callback
     */
    function ownerRemoveMarkets(
        uint[] calldata marketIds,
        address salvager
    )
    external;

    /**
     * Set (or unset) the status of a market to "closing". The borrowedValue of a market cannot increase while its
     * status is "closing".
     */
    function ownerSetIsClosing(
        uint256 marketId,
        bool isClosing
    )
    external;

    /**
     * Set the price oracle for a market.
     */
    function ownerSetPriceOracle(
        uint256 marketId,
        IDolomitePriceOracle priceOracle
    )
    external;

    /**
     * Set the interest-setter for a market.
     */
    function ownerSetInterestSetter(
        uint256 marketId,
        IDolomiteInterestSetter interestSetter
    )
    external;

    /**
     * Set a premium on the minimum margin-ratio for a market. This makes it so that any positions that include this
     * market require a higher collateralization to avoid being liquidated.
     */
    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal calldata marginPremium
    )
    external;

    function ownerSetMaxWei(
        uint256 marketId,
        uint256 maxWei
    )
    external;

    /**
     * Set a premium on the liquidation spread for a market. This makes it so that any liquidations that include this
     * market have a higher spread than the global default.
     */
    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal calldata spreadPremium
    )
    external;

    // ============ Risk Functions ============

    /**
     * Set the global minimum margin-ratio that every position must maintain to prevent being liquidated.
     */
    function ownerSetMarginRatio(
        Decimal calldata ratio
    )
    external;

    /**
     * Set the global liquidation spread. This is the spread between oracle prices that incentivizes the liquidation of
     * risky positions.
     */
    function ownerSetLiquidationSpread(
        Decimal calldata spread
    )
    external;

    /**
     * Set the global earnings-rate variable that determines what percentage of the interest paid by borrowers gets
     * passed-on to suppliers.
     */
    function ownerSetEarningsRate(
        Decimal calldata earningsRate
    )
    external;

    /**
     * Set the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     */
    function ownerSetMinBorrowedValue(
        MonetaryValue calldata minBorrowedValue
    )
    external;

    // ============ Global Operator Functions ============

    /**
     * Approve (or disapprove) an address that is permissioned to be an operator for all accounts in DolomiteMargin.
     * Intended only to approve smart-contracts.
     */
    function ownerSetGlobalOperator(
        address operator,
        bool approved
    )
    external;

    /**
     * Approve (or disapprove) an auto trader that can only be called by a global operator. IE for expirations
     */
    function ownerSetAutoTraderSpecial(
        address autoTrader,
        bool special
    )
    external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomitePriceOracle
 * @author  Dolomite
 *
 * @notice  Interface that Price Oracles for DolomiteMargin must implement in order to report prices.
 */
interface IDolomitePriceOracle {

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^(36 - decimals).
     *                So a USD-stable coin with 6 decimal places would return `price * 10^30`.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(
        address token
    )
    external
    view
    returns (IDolomiteStructs.MonetaryPrice memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomiteAccountRiskOverrideSetter
 * @author  Dolomite
 *
 * @notice  Interface that can be implemented by any contract that needs to implement risk overrides for an account.
 */
interface IDolomiteAccountRiskOverrideSetter {

    /**
     * @notice  Gets the risk overrides for a given account owner.
     *
     * @param  _accountOwner               The owner of the account whose risk override should be retrieved.
     * @return  marginRatioOverride         The margin ratio override for this account.
     * @return  liquidationSpreadOverride   The liquidation spread override for this account.
     */
    function getAccountRiskOverride(
        address _accountOwner
    )
    external
    view
    returns
    (
        IDolomiteStructs.Decimal memory marginRatioOverride,
        IDolomiteStructs.Decimal memory liquidationSpreadOverride
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteOracleSentinel
 * @author  Dolomite
 *
 * Interface that Dolomite pings to check if the Blockchain or L2 is alive, if liquidations should be processed, and if
 * markets should are in size-down only mode.
 */
interface IDolomiteOracleSentinel {

    // ============ Events ============

    event GracePeriodSet(
        uint256 gracePeriod
    );

    // ============ Functions ============

    /**
     * @dev Allows the owner to set the grace period duration, which specifies how long the system will disallow
     *      liquidations after sequencer is back online. Only callable by the owner.
     *
     * @param  _gracePeriod  The new duration of the grace period
     */
    function ownerSetGracePeriod(
        uint256 _gracePeriod
    )
    external;

    /**
     * @return True if new borrows should be allowed, false otherwise
     */
    function isBorrowAllowed() external view returns (bool);

    /**
     * @return True if liquidations should be allowed, false otherwise
     */
    function isLiquidationAllowed() external view returns (bool);

    /**
     * @return  The duration between when the feed comes back online and when the system will allow liquidations to be
     *          processed normally
     */
    function gracePeriod() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { Require } from "./Require.sol";


/**
 * @title   DolomiteMarginMath
 * @author  dYdX
 *
 * @notice  Library for non-standard Math functions
 */
library DolomiteMarginMath {

    // ============ Constants ============

    bytes32 internal constant _FILE = "DolomiteMarginMath";

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        return target * numerator / denominator;
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.1 rounds to 102
     * instead of 101.
     */
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            return 0;
        }
        return (((target * numerator) - 1) / denominator) + 1;
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.5 rounds to 102
     * instead of 101.
     */
    function getPartialRoundHalfUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            return 0;
        }
        return (((target * numerator) + (denominator / 2)) / denominator);
    }

    function to128(
        uint256 number
    )
    internal
    pure
    returns (uint128)
    {
        uint128 result = uint128(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint128",
            number
        );
        return result;
    }

    function to96(
        uint256 number
    )
    internal
    pure
    returns (uint96)
    {
        uint96 result = uint96(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint96",
            number
        );
        return result;
    }

    function to32(
        uint256 number
    )
    internal
    pure
    returns (uint32)
    {
        uint32 result = uint32(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint32",
            number
        );
        return result;
    }
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