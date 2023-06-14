//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract CoreRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _OWNER_UPGRADE_MODULE = 0x3f34f4B9A1F8A0B49B3309Be15673A3f631837cb;
    address private constant _ACCOUNT_MODULE = 0x8e38e7AB667046C18868517C4c6310303d2A3c4F;
    address private constant _ASSOCIATED_SYSTEMS_MODULE = 0x3aC3a772d20446f59d9E3EA03b01B4A3A9A9F474;
    address private constant _COLLATERAL_CONFIGURATION_MODULE = 0xaFAAAC6e184a1aCbeBEd30B15826717172d66596;
    address private constant _COLLATERAL_MODULE = 0xBC7706cB13d95fcAC338Ea3a5817eF694E7102c2;
    address private constant _FEATURE_FLAG_MODULE = 0xfb47177Dc75F3910b8bC6525b4835cCa67a12C48;
    address private constant _FEE_CONFIGURATION_MODULE = 0xf9b5462953F75fD6528bA337476574E9d905A48d;
    address private constant _LIQUIDATION_MODULE = 0x4b52a332FC0089F1C23840aDBC086778FF973a16;
    address private constant _PERIPHERY_MODULE = 0xF7B56B63863B4e72c29892927eb8F59dF3eec42C;
    address private constant _PRODUCT_MODULE = 0xd084Db9aA06Cd93d0e4B1D113e1d58306fBC423E;
    address private constant _RISK_CONFIGURATION_MODULE = 0x8056591c9253d58e998D275123A3b4d42c872E15;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x8da5cb5b) {
                    if lt(sig,0x60988e09) {
                        if lt(sig,0x3659cfe6) {
                            switch sig
                            case 0x00cd9ef3 { result := _ACCOUNT_MODULE } // AccountModule.grantPermission()
                            case 0x0670a130 { result := _RISK_CONFIGURATION_MODULE } // RiskConfigurationModule.getProtocolRiskConfiguration()
                            case 0x117b3e37 { result := _RISK_CONFIGURATION_MODULE } // RiskConfigurationModule.getMarketRiskConfiguration()
                            case 0x1213d453 { result := _ACCOUNT_MODULE } // AccountModule.isAuthorized()
                            case 0x15b3695a { result := _ACCOUNT_MODULE } // AccountModule.onlyAuthorized()
                            case 0x1627540c { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.nominateNewOwner()
                            case 0x2d22bef9 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.initOrUpgradeNft()
                            leave
                        }
                        switch sig
                        case 0x3659cfe6 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.upgradeTo()
                        case 0x3b969888 { result := _RISK_CONFIGURATION_MODULE } // RiskConfigurationModule.configureMarketRisk()
                        case 0x40a399ef { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowAll()
                        case 0x47c1c561 { result := _ACCOUNT_MODULE } // AccountModule.renouncePermission()
                        case 0x53a47bb7 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.nominatedOwner()
                        case 0x5a4066e8 { result := _PRODUCT_MODULE } // ProductModule.getAccountUnrealizedPnL()
                        case 0x5e52ad6e { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagDenyAll()
                        leave
                    }
                    if lt(sig,0x77432aeb) {
                        switch sig
                        case 0x60988e09 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.getAssociatedSystem()
                        case 0x61525e71 { result := _LIQUIDATION_MODULE } // LiquidationModule.liquidate()
                        case 0x61cd07a6 { result := _PRODUCT_MODULE } // ProductModule.registerProduct()
                        case 0x6b7d6c94 { result := _COLLATERAL_MODULE } // CollateralModule.getAccountCollateralBalance()
                        case 0x715cb7d2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setDeniers()
                        case 0x718fe928 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.renounceNomination()
                        case 0x75bf2444 { result := _COLLATERAL_CONFIGURATION_MODULE } // CollateralConfigurationModule.getCollateralConfigurations()
                        leave
                    }
                    switch sig
                    case 0x77432aeb { result := _PRODUCT_MODULE } // ProductModule.propagateTakerOrder()
                    case 0x79ba5097 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.acceptOwnership()
                    case 0x7d632bd2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagAllowAll()
                    case 0x7dec8b55 { result := _ACCOUNT_MODULE } // AccountModule.notifyAccountTransfer()
                    case 0x83802968 { result := _COLLATERAL_MODULE } // CollateralModule.deposit()
                    case 0x89b0c315 { result := _FEE_CONFIGURATION_MODULE } // FeeConfigurationModule.configureMarketFee()
                    case 0x8d34166b { result := _ACCOUNT_MODULE } // AccountModule.hasPermission()
                    leave
                }
                if lt(sig,0xbcae3ea0) {
                    if lt(sig,0xa7627288) {
                        switch sig
                        case 0x8da5cb5b { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.owner()
                        case 0x91734c14 { result := _PRODUCT_MODULE } // ProductModule.closeAccount()
                        case 0x95997c51 { result := _COLLATERAL_MODULE } // CollateralModule.withdraw()
                        case 0x959b1b01 { result := _FEE_CONFIGURATION_MODULE } // FeeConfigurationModule.getMarketFeeConfiguration()
                        case 0xa0778144 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.addToFeatureFlagAllowlist()
                        case 0xa148bf10 { result := _ACCOUNT_MODULE } // AccountModule.getAccountTokenAddress()
                        case 0xa32e3038 { result := _PRODUCT_MODULE } // ProductModule.getAccountAnnualizedExposures()
                        leave
                    }
                    switch sig
                    case 0xa7627288 { result := _ACCOUNT_MODULE } // AccountModule.revokePermission()
                    case 0xa796fecd { result := _ACCOUNT_MODULE } // AccountModule.getAccountPermissions()
                    case 0xaaf10f42 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.getImplementation()
                    case 0xad1fd645 { result := _PRODUCT_MODULE } // ProductModule.propagateMakerOrder()
                    case 0xaeb22934 { result := _PERIPHERY_MODULE } // PeripheryModule.setPeriphery()
                    case 0xb68a7ab9 { result := _COLLATERAL_MODULE } // CollateralModule.getAccountCollateralBalanceAvailable()
                    case 0xb7746b59 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.removeFromFeatureFlagAllowlist()
                    leave
                }
                if lt(sig,0xdc0b3f52) {
                    switch sig
                    case 0xbcae3ea0 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagDenyAll()
                    case 0xbf60c31d { result := _ACCOUNT_MODULE } // AccountModule.getAccountOwner()
                    case 0xc7f62cda { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.simulateUpgradeTo()
                    case 0xcadb09a5 { result := _ACCOUNT_MODULE } // AccountModule.createAccount()
                    case 0xcf635949 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.isFeatureAllowed()
                    case 0xd7193e8e { result := _COLLATERAL_CONFIGURATION_MODULE } // CollateralConfigurationModule.configureCollateral()
                    case 0xd9c7e37b { result := _COLLATERAL_MODULE } // CollateralModule.getTotalAccountValue()
                    leave
                }
                switch sig
                case 0xdc0b3f52 { result := _COLLATERAL_CONFIGURATION_MODULE } // CollateralConfigurationModule.getCollateralConfiguration()
                case 0xdf2b1369 { result := _RISK_CONFIGURATION_MODULE } // RiskConfigurationModule.configureProtocolRisk()
                case 0xe12c8160 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowlist()
                case 0xe762c95b { result := _PRODUCT_MODULE } // ProductModule.propagateCashflow()
                case 0xe80bba27 { result := _COLLATERAL_MODULE } // CollateralModule.getAccountLiquidationBoosterBalance()
                case 0xed429cf7 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getDeniers()
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