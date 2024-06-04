//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract SpotMarketRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _CORE_MODULE = 0x30a38F5Ee7D4619049188EaBb309aa6a13475036;
    address private constant _SPOT_MARKET_FACTORY_MODULE = 0x4305B7dD371018Eed6d89F723b4eB20569A4a6b9;
    address private constant _ATOMIC_ORDER_MODULE = 0x16C53F031582255bdAa73462F18318Debc5c5615;
    address private constant _ASYNC_ORDER_MODULE = 0x8eeF296cd61916D958e6f64c811bC905517D9bc2;
    address private constant _ASYNC_ORDER_SETTLEMENT_MODULE = 0x5F56D99D07183D0b8ddD4256d50B9C19e9D056fe;
    address private constant _ASYNC_ORDER_CONFIGURATION_MODULE = 0x72ed2071E76BC6Dbc412609eDa87646f032BECD2;
    address private constant _WRAPPER_MODULE = 0x5ce7D37f887cC816aC1eaef51CC4351392733626;
    address private constant _MARKET_CONFIGURATION_MODULE = 0x5887027Ecf02c1cd598BAFA0D027dc7d98Cd7dbf;
    address private constant _FEATURE_FLAG_MODULE = 0x53870eb1B6c23025c5644921Cf1Aa9cca2EcfCdC;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x7d632bd2) {
                    if lt(sig,0x4d4bfbd5) {
                        if lt(sig,0x3659cfe6) {
                            if lt(sig,0x298b26bf) {
                                switch sig
                                case 0x01ffc9a7 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.supportsInterface()
                                case 0x025f6120 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setFeeCollector()
                                case 0x1627540c { result := _CORE_MODULE } // CoreModule.nominateNewOwner()
                                case 0x1c216a0e { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.acceptMarketOwnership()
                                case 0x21f7f58f { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setCollateralLeverage()
                                leave
                            }
                            switch sig
                            case 0x298b26bf { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.renounceMarketNomination()
                            case 0x2d22bef9 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.initOrUpgradeNft()
                            case 0x2e535d61 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.createSynth()
                            case 0x2efaa971 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getCustomTransactorFees()
                            case 0x32598e61 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getMarketFees()
                            leave
                        }
                        if lt(sig,0x4138dc53) {
                            switch sig
                            case 0x3659cfe6 { result := _CORE_MODULE } // CoreModule.upgradeTo()
                            case 0x37fb3369 { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.buy()
                            case 0x3d1a60e4 { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.sellExactIn()
                            case 0x3e0c76ca { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.getSynthImpl()
                            case 0x40a399ef { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowAll()
                            leave
                        }
                        switch sig
                        case 0x4138dc53 { result := _ASYNC_ORDER_MODULE } // AsyncOrderModule.cancelOrder()
                        case 0x45f2601c { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setMarketUtilizationFees()
                        case 0x462b9a2d { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.getPriceData()
                        case 0x480be91f { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setAtomicFixedFee()
                        case 0x4ce94d9d { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.sellExactOut()
                        leave
                    }
                    if lt(sig,0x673a21e5) {
                        if lt(sig,0x5e52ad6e) {
                            switch sig
                            case 0x4d4bfbd5 { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.sell()
                            case 0x5381ce16 { result := _ASYNC_ORDER_MODULE } // AsyncOrderModule.getAsyncOrderClaim()
                            case 0x53a47bb7 { result := _CORE_MODULE } // CoreModule.nominatedOwner()
                            case 0x5497eb23 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getFeeCollector()
                            case 0x5950864b { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.nominateMarketOwner()
                            leave
                        }
                        switch sig
                        case 0x5e52ad6e { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagDenyAll()
                        case 0x5fdf4e98 { result := _WRAPPER_MODULE } // WrapperModule.getWrapper()
                        case 0x60988e09 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.getAssociatedSystem()
                        case 0x61dcca86 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setAsyncFixedFee()
                        case 0x6539b1c3 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setWrapperFees()
                        leave
                    }
                    if lt(sig,0x715cb7d2) {
                        switch sig
                        case 0x673a21e5 { result := _WRAPPER_MODULE } // WrapperModule.setWrapper()
                        case 0x687ed93d { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.quoteSellExactIn()
                        case 0x69e0365f { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.getSynth()
                        case 0x6ad77077 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.updateReferrerShare()
                        case 0x70d9a0c6 { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.quoteBuyExactOut()
                        leave
                    }
                    switch sig
                    case 0x715cb7d2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setDeniers()
                    case 0x718fe928 { result := _CORE_MODULE } // CoreModule.renounceNomination()
                    case 0x784dad9e { result := _WRAPPER_MODULE } // WrapperModule.unwrap()
                    case 0x79ba5097 { result := _CORE_MODULE } // CoreModule.acceptOwnership()
                    case 0x7cbe2075 { result := _ASYNC_ORDER_CONFIGURATION_MODULE } // AsyncOrderConfigurationModule.setSettlementStrategy()
                    leave
                }
                if lt(sig,0xbd1cdfb5) {
                    if lt(sig,0xa05ee4f6) {
                        if lt(sig,0x9444ac48) {
                            switch sig
                            case 0x7d632bd2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagAllowAll()
                            case 0x7f73a891 { result := _ASYNC_ORDER_CONFIGURATION_MODULE } // AsyncOrderConfigurationModule.setSettlementStrategyEnabled()
                            case 0x8d105571 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getMarketSkewScale()
                            case 0x8da5cb5b { result := _CORE_MODULE } // CoreModule.owner()
                            case 0x911414c6 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.updatePriceData()
                            leave
                        }
                        switch sig
                        case 0x9444ac48 { result := _ASYNC_ORDER_SETTLEMENT_MODULE } // AsyncOrderSettlementModule.settleOrder()
                        case 0x95fcd547 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setCustomTransactorFees()
                        case 0x97b30e6d { result := _ASYNC_ORDER_CONFIGURATION_MODULE } // AsyncOrderConfigurationModule.addSettlementStrategy()
                        case 0x983220bb { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.buyExactOut()
                        case 0x9a40f8cb { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.setMarketSkewScale()
                        leave
                    }
                    if lt(sig,0xab75d950) {
                        switch sig
                        case 0xa05ee4f6 { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.getMarketSkew()
                        case 0xa0778144 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.addToFeatureFlagAllowlist()
                        case 0xa12d9400 { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.buyExactIn()
                        case 0xa7b8cb9f { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.getMarketOwner()
                        case 0xaaf10f42 { result := _CORE_MODULE } // CoreModule.getImplementation()
                        leave
                    }
                    switch sig
                    case 0xab75d950 { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.quoteBuyExactIn()
                    case 0xafe79200 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.minimumCredit()
                    case 0xb7746b59 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.removeFromFeatureFlagAllowlist()
                    case 0xbcae3ea0 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagDenyAll()
                    case 0xbcec0d0f { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.reportedDebt()
                    leave
                }
                if lt(sig,0xd393340e) {
                    if lt(sig,0xc99d0cdd) {
                        switch sig
                        case 0xbd1cdfb5 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.renounceMarketOwnership()
                        case 0xc4b41a2e { result := _ATOMIC_ORDER_MODULE } // AtomicOrderModule.quoteSellExactOut()
                        case 0xc624440a { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.name()
                        case 0xc6f79537 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.initOrUpgradeToken()
                        case 0xc7f62cda { result := _CORE_MODULE } // CoreModule.simulateUpgradeTo()
                        leave
                    }
                    switch sig
                    case 0xc99d0cdd { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.upgradeSynthImpl()
                    case 0xcdfaef0f { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getCollateralLeverage()
                    case 0xcf635949 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.isFeatureAllowed()
                    case 0xd245d983 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.registerUnmanagedSystem()
                    case 0xd2a25290 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.getNominatedMarketOwner()
                    leave
                }
                if lt(sig,0xed429cf7) {
                    switch sig
                    case 0xd393340e { result := _ASYNC_ORDER_MODULE } // AsyncOrderModule.commitOrder()
                    case 0xd7ce770c { result := _WRAPPER_MODULE } // WrapperModule.wrap()
                    case 0xe12c8160 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowlist()
                    case 0xec04ceb1 { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.setSynthImplementation()
                    case 0xec846bac { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.setDecayRate()
                    leave
                }
                switch sig
                case 0xed429cf7 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getDeniers()
                case 0xf375f324 { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getMarketUtilizationFees()
                case 0xf74c377f { result := _ASYNC_ORDER_CONFIGURATION_MODULE } // AsyncOrderConfigurationModule.getSettlementStrategy()
                case 0xfa4b28ed { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getReferrerShare()
                case 0xfec9f9da { result := _SPOT_MARKET_FACTORY_MODULE } // SpotMarketFactoryModule.setSynthetix()
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