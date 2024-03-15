//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract PerpsMarketRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _ACCOUNT_MODULE = 0xBb0CBCa9CE28a8C6c7Aaa13584A76c0B1a35Fff7;
    address private constant _ASSOCIATED_SYSTEMS_MODULE = 0xD5FcCd43205CEF11FbaF9b38dF15ADbe1B186869;
    address private constant _CORE_MODULE = 0x04412b2aE241C602Be87Bc1114238d50d08398Fb;
    address private constant _PERPS_MARKET_FACTORY_MODULE = 0xf12B26b9F28a0220b98d1FbBb7737Df699B59202;
    address private constant _PERPS_ACCOUNT_MODULE = 0x4e8f55f1948D3E61A1FD3Cd38Ce05EFC77bffEb5;
    address private constant _PERPS_MARKET_MODULE = 0x27A64e368cf200C4d106b3F225cDbB2d02448376;
    address private constant _ASYNC_ORDER_MODULE = 0x4E2469BcbBAe65BDf9E83aff58d4677E5f2F9fB3;
    address private constant _ASYNC_ORDER_SETTLEMENT_PYTH_MODULE = 0x4bF3C1Af0FaA689e3A808e6Ad7a8d89d07BB9EC7;
    address private constant _ASYNC_ORDER_CANCEL_MODULE = 0x8Fcd33e3C477a034FcFb10A4f35fC35f26FfB9EF;
    address private constant _FEATURE_FLAG_MODULE = 0x79AE4AAC073c6f153644647Af14F202ca8cc39C5;
    address private constant _LIQUIDATION_MODULE = 0xAD35498D97f3b1a0B99de42da7Ad81c91156BA77;
    address private constant _MARKET_CONFIGURATION_MODULE = 0x98d601E04527a0acBB603BaD845D9b7B8840de1c;
    address private constant _GLOBAL_PERPS_MARKET_MODULE = 0x86770a2940efF6a778768592B42A6668FfB162a4;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x83a7db27) {
                    if lt(sig,0x3ce80659) {
                        if lt(sig,0x1b68d8fa) {
                            if lt(sig,0x0e7cace9) {
                                switch sig
                                case 0x00cd9ef3 { result := _ACCOUNT_MODULE } // AccountModule.grantPermission()
                                case 0x01ffc9a7 { result := _PERPS_MARKET_FACTORY_MODULE } // PerpsMarketFactoryModule.supportsInterface()
                                case 0x033723d9 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setLockedOiRatio()
                                case 0x048577de { result := _LIQUIDATION_MODULE } // LiquidationModule.liquidate()
                                case 0x04aa363e { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.getWithdrawableMargin()
                                case 0x05db8a69 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.getSupportedCollaterals()
                                case 0x06e4ba89 { result := _ASYNC_ORDER_MODULE } // AsyncOrderModule.computeOrderFeesWithPrice()
                                case 0x0a7dad2d { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.getAvailableMargin()
                                leave
                            }
                            switch sig
                            case 0x0e7cace9 { result := _PERPS_MARKET_MODULE } // PerpsMarketModule.maxOpenInterest()
                            case 0x117d4128 { result := _ASYNC_ORDER_MODULE } // AsyncOrderModule.getOrder()
                            case 0x1213d453 { result := _ACCOUNT_MODULE } // AccountModule.isAuthorized()
                            case 0x12fde4b7 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.getFeeCollector()
                            case 0x1627540c { result := _CORE_MODULE } // CoreModule.nominateNewOwner()
                            case 0x19a99bf5 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getMaxMarketSize()
                            case 0x1b5dccdb { result := _ACCOUNT_MODULE } // AccountModule.getAccountLastInteraction()
                            leave
                        }
                        if lt(sig,0x2daf43bc) {
                            switch sig
                            case 0x1b68d8fa { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getFundingParameters()
                            case 0x1f4653bb { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.getKeeperCostNodeId()
                            case 0x22a73967 { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.getOpenPosition()
                            case 0x25e5409e { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setLiquidationParameters()
                            case 0x26641806 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setSettlementStrategy()
                            case 0x26e77e84 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.getKeeperRewardGuards()
                            case 0x2b267635 { result := _PERPS_MARKET_MODULE } // PerpsMarketModule.size()
                            case 0x2d22bef9 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.initOrUpgradeNft()
                            leave
                        }
                        switch sig
                        case 0x2daf43bc { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.totalAccountOpenInterest()
                        case 0x31edc046 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getLockedOiRatio()
                        case 0x35254238 { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.getAccountOpenPositions()
                        case 0x3659cfe6 { result := _CORE_MODULE } // CoreModule.upgradeTo()
                        case 0x3b217f67 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getMaxMarketValue()
                        case 0x3bef7df4 { result := _PERPS_MARKET_FACTORY_MODULE } // PerpsMarketFactoryModule.initializeFactory()
                        case 0x3c0f0753 { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.getRequiredMargins()
                        leave
                    }
                    if lt(sig,0x6809fb4d) {
                        if lt(sig,0x5443e33e) {
                            switch sig
                            case 0x3ce80659 { result := _LIQUIDATION_MODULE } // LiquidationModule.liquidateFlaggedAccounts()
                            case 0x404a68aa { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setMaxMarketSize()
                            case 0x40a399ef { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowAll()
                            case 0x41c2e8bd { result := _PERPS_MARKET_MODULE } // PerpsMarketModule.getMarketSummary()
                            case 0x462b9a2d { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getPriceData()
                            case 0x47c1c561 { result := _ACCOUNT_MODULE } // AccountModule.renouncePermission()
                            case 0x4f778fb4 { result := _PERPS_MARKET_MODULE } // PerpsMarketModule.indexPrice()
                            case 0x53a47bb7 { result := _CORE_MODULE } // CoreModule.nominatedOwner()
                            leave
                        }
                        switch sig
                        case 0x5443e33e { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getMaxLiquidationParameters()
                        case 0x55576c59 { result := _PERPS_MARKET_FACTORY_MODULE } // PerpsMarketFactoryModule.setPerpsMarketName()
                        case 0x5a6a77bf { result := _ASYNC_ORDER_MODULE } // AsyncOrderModule.requiredMarginForOrderWithPrice()
                        case 0x5dbd5c9b { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.getCollateralAmount()
                        case 0x5e52ad6e { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagDenyAll()
                        case 0x60988e09 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.getAssociatedSystem()
                        case 0x65c5a0fe { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.totalGlobalCollateralValue()
                        leave
                    }
                    if lt(sig,0x774f7b07) {
                        switch sig
                        case 0x6809fb4d { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.updateReferrerShare()
                        case 0x6aba84a7 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.setSynthDeductionPriority()
                        case 0x6c321c8a { result := _PERPS_MARKET_FACTORY_MODULE } // PerpsMarketFactoryModule.utilizationRate()
                        case 0x6fa1b1a0 { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.getOpenPositionSize()
                        case 0x715cb7d2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setDeniers()
                        case 0x718fe928 { result := _CORE_MODULE } // CoreModule.renounceNomination()
                        case 0x74d745fc { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.addSettlementStrategy()
                        leave
                    }
                    switch sig
                    case 0x774f7b07 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.getPerAccountCaps()
                    case 0x79ba5097 { result := _CORE_MODULE } // CoreModule.acceptOwnership()
                    case 0x7c3a00fd { result := _PERPS_MARKET_FACTORY_MODULE } // PerpsMarketFactoryModule.interestRate()
                    case 0x7d632bd2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagAllowAll()
                    case 0x7dec8b55 { result := _ACCOUNT_MODULE } // AccountModule.notifyAccountTransfer()
                    case 0x7e947ea4 { result := _PERPS_MARKET_FACTORY_MODULE } // PerpsMarketFactoryModule.createMarket()
                    case 0x7f73a891 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setSettlementStrategyEnabled()
                    leave
                }
                if lt(sig,0xc2382277) {
                    if lt(sig,0xaac23e8c) {
                        if lt(sig,0x9f978860) {
                            switch sig
                            case 0x83a7db27 { result := _PERPS_MARKET_MODULE } // PerpsMarketModule.skew()
                            case 0x8d34166b { result := _ACCOUNT_MODULE } // AccountModule.hasPermission()
                            case 0x8da5cb5b { result := _CORE_MODULE } // CoreModule.owner()
                            case 0x96e9f7a0 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.setKeeperRewardGuards()
                            case 0x9734ba0f { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.getAccountCollateralIds()
                            case 0x98ef15a2 { result := _ASYNC_ORDER_MODULE } // AsyncOrderModule.computeOrderFees()
                            case 0x9b922bba { result := _LIQUIDATION_MODULE } // LiquidationModule.canLiquidate()
                            case 0x9dca362f { result := _ACCOUNT_MODULE } // AccountModule.createAccount()
                            leave
                        }
                        switch sig
                        case 0x9f978860 { result := _ASYNC_ORDER_MODULE } // AsyncOrderModule.commitOrder()
                        case 0xa0778144 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.addToFeatureFlagAllowlist()
                        case 0xa148bf10 { result := _ACCOUNT_MODULE } // AccountModule.getAccountTokenAddress()
                        case 0xa42dce80 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.setFeeCollector()
                        case 0xa7627288 { result := _ACCOUNT_MODULE } // AccountModule.revokePermission()
                        case 0xa788d01f { result := _LIQUIDATION_MODULE } // LiquidationModule.flaggedAccounts()
                        case 0xa796fecd { result := _ACCOUNT_MODULE } // AccountModule.getAccountPermissions()
                        leave
                    }
                    if lt(sig,0xb8830a25) {
                        switch sig
                        case 0xaac23e8c { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getOrderFees()
                        case 0xaaf10f42 { result := _CORE_MODULE } // CoreModule.getImplementation()
                        case 0xac53c5ae { result := _LIQUIDATION_MODULE } // LiquidationModule.liquidateFlagged()
                        case 0xafe79200 { result := _PERPS_MARKET_FACTORY_MODULE } // PerpsMarketFactoryModule.minimumCredit()
                        case 0xb4ed6320 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.getInterestRateParameters()
                        case 0xb568ae42 { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.totalCollateralValue()
                        case 0xb5848488 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.updatePriceData()
                        case 0xb7746b59 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.removeFromFeatureFlagAllowlist()
                        leave
                    }
                    switch sig
                    case 0xb8830a25 { result := _ASYNC_ORDER_MODULE } // AsyncOrderModule.requiredMarginForOrder()
                    case 0xbb36f896 { result := _LIQUIDATION_MODULE } // LiquidationModule.liquidationCapacity()
                    case 0xbb58672c { result := _PERPS_ACCOUNT_MODULE } // PerpsAccountModule.modifyCollateral()
                    case 0xbcae3ea0 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagDenyAll()
                    case 0xbcec0d0f { result := _PERPS_MARKET_FACTORY_MODULE } // PerpsMarketFactoryModule.reportedDebt()
                    case 0xbe0cbb59 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.setInterestRateParameters()
                    case 0xbf60c31d { result := _ACCOUNT_MODULE } // AccountModule.getAccountOwner()
                    leave
                }
                if lt(sig,0xe12c8160) {
                    if lt(sig,0xcf635949) {
                        switch sig
                        case 0xc2382277 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setFundingParameters()
                        case 0xc624440a { result := _PERPS_MARKET_FACTORY_MODULE } // PerpsMarketFactoryModule.name()
                        case 0xc6f79537 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.initOrUpgradeToken()
                        case 0xc7f62cda { result := _CORE_MODULE } // CoreModule.simulateUpgradeTo()
                        case 0xc7f8a94f { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setMaxLiquidationParameters()
                        case 0xcadb09a5 { result := _ACCOUNT_MODULE } // AccountModule.createAccount()
                        case 0xcae77b70 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.getReferrerShare()
                        case 0xce76756f { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.updateInterestRate()
                        leave
                    }
                    switch sig
                    case 0xcf635949 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.isFeatureAllowed()
                    case 0xd245d983 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.registerUnmanagedSystem()
                    case 0xd435b2a2 { result := _PERPS_MARKET_MODULE } // PerpsMarketModule.currentFundingRate()
                    case 0xdbc91396 { result := _ASYNC_ORDER_CANCEL_MODULE } // AsyncOrderCancelModule.cancelOrder()
                    case 0xdd661eea { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setMaxMarketValue()
                    case 0xddf5a974 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.setCollateralConfiguration()
                    case 0xdeff90ef { result := _PERPS_MARKET_MODULE } // PerpsMarketModule.fillPrice()
                    leave
                }
                if lt(sig,0xf74c377f) {
                    switch sig
                    case 0xe12c8160 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowlist()
                    case 0xe3bc36bf { result := _PERPS_MARKET_MODULE } // PerpsMarketModule.metadata()
                    case 0xec2c9016 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.getMarkets()
                    case 0xecfebba2 { result := _ASYNC_ORDER_MODULE } // AsyncOrderModule.getSettlementRewardCost()
                    case 0xed429cf7 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getDeniers()
                    case 0xf265db02 { result := _PERPS_MARKET_MODULE } // PerpsMarketModule.currentFundingVelocity()
                    case 0xf5322087 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.updateKeeperCostNodeId()
                    leave
                }
                switch sig
                case 0xf74c377f { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getSettlementStrategy()
                case 0xf842fa86 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setOrderFees()
                case 0xf89648fb { result := _ASYNC_ORDER_SETTLEMENT_PYTH_MODULE } // AsyncOrderSettlementPythModule.settleOrder()
                case 0xf94363a6 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getLiquidationParameters()
                case 0xfa0e70a7 { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.setPerAccountCaps()
                case 0xfd51558e { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.getCollateralConfiguration()
                case 0xfea84a3f { result := _GLOBAL_PERPS_MARKET_MODULE } // GlobalPerpsMarketModule.getSynthDeductionPriority()
                leave
            }

            implementation := findImplementation(sig32)
        }

        if (implementation == address(0)) {
            revert UnknownSelector(sig4);
        }

        // Delegatecall to the implementation contract
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}