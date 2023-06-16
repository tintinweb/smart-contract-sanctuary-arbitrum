//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract CoreRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _INITIAL_MODULE_BUNDLE = 0xB7d1b1511BbAA213AE339E84c6E056BcbD6c5946;
    address private constant _FEATURE_FLAG_MODULE = 0x1F5971B28458d456627d72fCDe826Bb9653386Cf;
    address private constant _ACCOUNT_MODULE = 0x1af2636f34483fB709C91F8Bf4732429Fe681b1c;
    address private constant _ASSOCIATE_DEBT_MODULE = 0x9c8B1FE055BBE5854Ee559eBd95bf2DD51047FEC;
    address private constant _ASSOCIATED_SYSTEMS_MODULE = 0x247814db4369f8E952F60A6409C16A928672dcc6;
    address private constant _CCIP_RECEIVER_MODULE = 0xd538CF9649fd65aAaaB92829e0Fc13f371A1d3fe;
    address private constant _COLLATERAL_MODULE = 0xeB5b29e7a2E8a5F50D3BB81B2B6c223EF6Fd3BE8;
    address private constant _COLLATERAL_CONFIGURATION_MODULE = 0xE851b0A420074f4Db3BfcAC03722A7CCAB818676;
    address private constant _CROSS_CHAIN_POOL_MODULE = 0xCD7A2bebaB14f40162287f5EA1635922803b1f01;
    address private constant _CROSS_CHAIN_UPKEEP_MODULE = 0xAC1d377Fb74aAEECA27C697432318066157Ff5c7;
    address private constant _CROSS_CHAIN_USDMODULE = 0xB409b21634F356cb3372F077920ECDd4017AbFc6;
    address private constant _ISSUE_USDMODULE = 0x46D3a0308b70a221AE65865d62308197D4c95400;
    address private constant _LIQUIDATION_MODULE = 0xd9542412D32d33D9eFAF478A997BD94476074B0b;
    address private constant _MARKET_COLLATERAL_MODULE = 0xC6F85E8Cc2F13521f909810d03Ca66397a813eDb;
    address private constant _MARKET_MANAGER_MODULE = 0x62c12039029Da4008e21fB026ed32d4207d80878;
    address private constant _MULTICALL_MODULE = 0xFab8F34e42f59F2Eb3bb68c2Eb8039D5ea35d1eE;
    address private constant _POOL_CONFIGURATION_MODULE = 0xBd2117D4D53F9cedbdA10E216b2b857366b674ad;
    address private constant _POOL_MODULE = 0xad2AB207da822dEd242b678f855ecbcA30860b58;
    address private constant _REWARDS_MANAGER_MODULE = 0xe17b5ec91a4a68887634fef472cD1Ef556AabDb0;
    address private constant _UTILS_MODULE = 0xfcD8a3C86272CAb1E409117ee369dc3a79683418;
    address private constant _VAULT_MODULE = 0x4E3e02627Dd2Ac579eafd6B33Cc5a569856b61D2;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x8149581e) {
                    if lt(sig,0x3e033a06) {
                        if lt(sig,0x198f0aa1) {
                            if lt(sig,0x10b0cf76) {
                                switch sig
                                case 0x00cd9ef3 { result := _ACCOUNT_MODULE } // AccountModule.grantPermission()
                                case 0x01ffc9a7 { result := _UTILS_MODULE } // UtilsModule.supportsInterface()
                                case 0x07003f0a { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.isMarketCapacityLocked()
                                case 0x078145a8 { result := _VAULT_MODULE } // VaultModule.getVaultCollateral()
                                case 0x09449ae2 { result := _CROSS_CHAIN_POOL_MODULE } // CrossChainPoolModule._recvCreateCrossChainPool()
                                case 0x0bae9893 { result := _COLLATERAL_MODULE } // CollateralModule.createLock()
                                case 0x0c72a309 { result := _CROSS_CHAIN_POOL_MODULE } // CrossChainPoolModule.getThisChainPoolTotalDebt()
                                case 0x0ca76175 { result := _CROSS_CHAIN_UPKEEP_MODULE } // CrossChainUpkeepModule.handleOracleFulfillment()
                                case 0x0dd2395a { result := _REWARDS_MANAGER_MODULE } // RewardsManagerModule.getRewardRate()
                                leave
                            }
                            switch sig
                            case 0x10b0cf76 { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.depositMarketUsd()
                            case 0x11aa282d { result := _ASSOCIATE_DEBT_MODULE } // AssociateDebtModule.associateDebt()
                            case 0x11e72a43 { result := _POOL_MODULE } // PoolModule.setPoolName()
                            case 0x1213d453 { result := _ACCOUNT_MODULE } // AccountModule.isAuthorized()
                            case 0x12e1c673 { result := _MARKET_COLLATERAL_MODULE } // MarketCollateralModule.getMaximumMarketCollateral()
                            case 0x140a7cfe { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.withdrawMarketUsd()
                            case 0x150834a3 { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getMarketCollateral()
                            case 0x1627540c { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.nominateNewOwner()
                            case 0x170c1351 { result := _REWARDS_MANAGER_MODULE } // RewardsManagerModule.registerRewardsDistributor()
                            leave
                        }
                        if lt(sig,0x2fa7bb65) {
                            switch sig
                            case 0x198f0aa1 { result := _COLLATERAL_MODULE } // CollateralModule.cleanExpiredLocks()
                            case 0x1b5dccdb { result := _ACCOUNT_MODULE } // AccountModule.getAccountLastInteraction()
                            case 0x1d90e392 { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.setMarketMinDelegateTime()
                            case 0x1eb60770 { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getWithdrawableMarketUsd()
                            case 0x1f1b33b9 { result := _POOL_MODULE } // PoolModule.revokePoolNomination()
                            case 0x21f1d9e5 { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getUsdToken()
                            case 0x2685f42b { result := _REWARDS_MANAGER_MODULE } // RewardsManagerModule.removeRewardsDistributor()
                            case 0x2a5354d2 { result := _LIQUIDATION_MODULE } // LiquidationModule.isVaultLiquidatable()
                            case 0x2d22bef9 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.initOrUpgradeNft()
                            leave
                        }
                        switch sig
                        case 0x2fa7bb65 { result := _LIQUIDATION_MODULE } // LiquidationModule.isPositionLiquidatable()
                        case 0x2fb8ff24 { result := _VAULT_MODULE } // VaultModule.getVaultDebt()
                        case 0x33cc422b { result := _VAULT_MODULE } // VaultModule.getPositionCollateral()
                        case 0x34078a01 { result := _POOL_MODULE } // PoolModule.setMinLiquidityRatio()
                        case 0x340824d7 { result := _CROSS_CHAIN_USDMODULE } // CrossChainUSDModule.transferCrossChain()
                        case 0x3593bbd2 { result := _VAULT_MODULE } // VaultModule.getPositionDebt()
                        case 0x3659cfe6 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.upgradeTo()
                        case 0x3b390b57 { result := _POOL_CONFIGURATION_MODULE } // PoolConfigurationModule.getPreferredPool()
                        leave
                    }
                    if lt(sig,0x6141f7a2) {
                        if lt(sig,0x53a47bb7) {
                            switch sig
                            case 0x3e033a06 { result := _LIQUIDATION_MODULE } // LiquidationModule.liquidate()
                            case 0x3f395d26 { result := _CROSS_CHAIN_POOL_MODULE } // CrossChainPoolModule.getPoolCrossChainInfo()
                            case 0x40a399ef { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowAll()
                            case 0x446d50e5 { result := _POOL_MODULE } // PoolModule.getPoolLastConfigurationTime()
                            case 0x4585e33b { result := _CROSS_CHAIN_UPKEEP_MODULE } // CrossChainUpkeepModule.performUpkeep()
                            case 0x460d2049 { result := _REWARDS_MANAGER_MODULE } // RewardsManagerModule.claimRewards()
                            case 0x47c1c561 { result := _ACCOUNT_MODULE } // AccountModule.renouncePermission()
                            case 0x48741626 { result := _POOL_CONFIGURATION_MODULE } // PoolConfigurationModule.getApprovedPools()
                            case 0x51a40994 { result := _COLLATERAL_CONFIGURATION_MODULE } // CollateralConfigurationModule.getCollateralPrice()
                            leave
                        }
                        switch sig
                        case 0x53a47bb7 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.nominatedOwner()
                        case 0x5424901b { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getMarketMinDelegateTime()
                        case 0x5a7ff7c5 { result := _REWARDS_MANAGER_MODULE } // RewardsManagerModule.distributeRewards()
                        case 0x5d8c8844 { result := _POOL_MODULE } // PoolModule.setPoolConfiguration()
                        case 0x5e52ad6e { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagDenyAll()
                        case 0x5f6a1679 { result := _CROSS_CHAIN_POOL_MODULE } // CrossChainPoolModule.createCrossChainPool()
                        case 0x60248c55 { result := _VAULT_MODULE } // VaultModule.getVaultCollateralRatio()
                        case 0x60988e09 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.getAssociatedSystem()
                        leave
                    }
                    if lt(sig,0x728517e6) {
                        switch sig
                        case 0x6141f7a2 { result := _POOL_MODULE } // PoolModule.nominatePoolOwner()
                        case 0x644cb0f3 { result := _COLLATERAL_CONFIGURATION_MODULE } // CollateralConfigurationModule.configureCollateral()
                        case 0x645657d8 { result := _REWARDS_MANAGER_MODULE } // RewardsManagerModule.updateRewards()
                        case 0x6dd5b69d { result := _UTILS_MODULE } // UtilsModule.getConfig()
                        case 0x6e04ff0d { result := _CROSS_CHAIN_UPKEEP_MODULE } // CrossChainUpkeepModule.checkUpkeep()
                        case 0x6f146460 { result := _CROSS_CHAIN_POOL_MODULE } // CrossChainPoolModule.getPoolLastHeartbeat()
                        case 0x6fd5bdce { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.setMinLiquidityRatio()
                        case 0x715cb7d2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setDeniers()
                        case 0x718fe928 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.renounceNomination()
                        leave
                    }
                    switch sig
                    case 0x728517e6 { result := _VAULT_MODULE } // VaultModule.releaseExitedCollateral()
                    case 0x738d0bfb { result := _CROSS_CHAIN_POOL_MODULE } // CrossChainPoolModule.setCrossChainPoolConfiguration()
                    case 0x75bf2444 { result := _COLLATERAL_CONFIGURATION_MODULE } // CollateralConfigurationModule.getCollateralConfigurations()
                    case 0x79ba5097 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.acceptOwnership()
                    case 0x7b0532a4 { result := _VAULT_MODULE } // VaultModule.delegateCollateral()
                    case 0x7d632bd2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagAllowAll()
                    case 0x7d8a4140 { result := _LIQUIDATION_MODULE } // LiquidationModule.liquidateVault()
                    case 0x7dec8b55 { result := _ACCOUNT_MODULE } // AccountModule.notifyAccountTransfer()
                    leave
                }
                if lt(sig,0xbf60c31d) {
                    if lt(sig,0xa3aa8b51) {
                        if lt(sig,0x8da5cb5b) {
                            switch sig
                            case 0x8149581e { result := _UTILS_MODULE } // UtilsModule.configureChainlinkCrossChain()
                            case 0x830e23b5 { result := _UTILS_MODULE } // UtilsModule.setSupportedCrossChainNetworks()
                            case 0x83802968 { result := _COLLATERAL_MODULE } // CollateralModule.deposit()
                            case 0x84f29b6d { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getMinLiquidityRatio()
                            case 0x85572ffb { result := _CCIP_RECEIVER_MODULE } // CcipReceiverModule.ccipReceive()
                            case 0x85d99ebc { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getMarketNetIssuance()
                            case 0x86e3b1cf { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getMarketReportedDebt()
                            case 0x881771c6 { result := _CROSS_CHAIN_POOL_MODULE } // CrossChainPoolModule.getThisChainPoolCumulativeMarketDebt()
                            case 0x8d34166b { result := _ACCOUNT_MODULE } // AccountModule.hasPermission()
                            leave
                        }
                        switch sig
                        case 0x8da5cb5b { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.owner()
                        case 0x927482ff { result := _COLLATERAL_MODULE } // CollateralModule.getAccountAvailableCollateral()
                        case 0x95909ba3 { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getMarketDebtPerShare()
                        case 0x95997c51 { result := _COLLATERAL_MODULE } // CollateralModule.withdraw()
                        case 0x9851af01 { result := _POOL_MODULE } // PoolModule.getNominatedPoolOwner()
                        case 0x9dca362f { result := _ACCOUNT_MODULE } // AccountModule.createAccount()
                        case 0xa0778144 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.addToFeatureFlagAllowlist()
                        case 0xa0c12269 { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.distributeDebtToPools()
                        case 0xa148bf10 { result := _ACCOUNT_MODULE } // AccountModule.getAccountTokenAddress()
                        leave
                    }
                    if lt(sig,0xac9650d8) {
                        switch sig
                        case 0xa3aa8b51 { result := _MARKET_COLLATERAL_MODULE } // MarketCollateralModule.withdrawMarketCollateral()
                        case 0xa4e6306b { result := _MARKET_COLLATERAL_MODULE } // MarketCollateralModule.depositMarketCollateral()
                        case 0xa5d49393 { result := _UTILS_MODULE } // UtilsModule.configureOracleManager()
                        case 0xa7627288 { result := _ACCOUNT_MODULE } // AccountModule.revokePermission()
                        case 0xa796fecd { result := _ACCOUNT_MODULE } // AccountModule.getAccountPermissions()
                        case 0xa79b9ec9 { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.registerMarket()
                        case 0xaa8c6369 { result := _COLLATERAL_MODULE } // CollateralModule.getLocks()
                        case 0xaaf10f42 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.getImplementation()
                        case 0xabd2f8fa { result := _CROSS_CHAIN_UPKEEP_MODULE } // CrossChainUpkeepModule._recvPoolHeartbeat()
                        leave
                    }
                    switch sig
                    case 0xac9650d8 { result := _MULTICALL_MODULE } // MulticallModule.multicall()
                    case 0xb01ceccd { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getOracleManager()
                    case 0xb7746b59 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.removeFromFeatureFlagAllowlist()
                    case 0xb790a1ae { result := _POOL_CONFIGURATION_MODULE } // PoolConfigurationModule.addApprovedPool()
                    case 0xbaa2a264 { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getMarketTotalDebt()
                    case 0xbbdd7c5a { result := _POOL_MODULE } // PoolModule.getPoolOwner()
                    case 0xbcae3ea0 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagDenyAll()
                    case 0xbcdb3b6c { result := _CROSS_CHAIN_POOL_MODULE } // CrossChainPoolModule._recvSetCrossChainPoolConfiguration()
                    leave
                }
                if lt(sig,0xdbdea94c) {
                    if lt(sig,0xcb6da0ad) {
                        switch sig
                        case 0xbf60c31d { result := _ACCOUNT_MODULE } // AccountModule.getAccountOwner()
                        case 0xc2b0cf41 { result := _MARKET_COLLATERAL_MODULE } // MarketCollateralModule.getMarketCollateralAmount()
                        case 0xc6f79537 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.initOrUpgradeToken()
                        case 0xc707a39f { result := _POOL_MODULE } // PoolModule.acceptPoolOwnership()
                        case 0xc7f62cda { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.simulateUpgradeTo()
                        case 0xca5bed77 { result := _POOL_MODULE } // PoolModule.renouncePoolNomination()
                        case 0xca64db2e { result := _CROSS_CHAIN_UPKEEP_MODULE } // CrossChainUpkeepModule._bytesToHexString()
                        case 0xcaab529b { result := _POOL_MODULE } // PoolModule.createPool()
                        case 0xcadb09a5 { result := _ACCOUNT_MODULE } // AccountModule.createAccount()
                        leave
                    }
                    switch sig
                    case 0xcb6da0ad { result := _CROSS_CHAIN_POOL_MODULE } // CrossChainPoolModule.getThisChainPoolLiquidity()
                    case 0xcf635949 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.isFeatureAllowed()
                    case 0xd13f32e3 { result := _CROSS_CHAIN_UPKEEP_MODULE } // CrossChainUpkeepModule._codeAt()
                    case 0xd1fd27b3 { result := _UTILS_MODULE } // UtilsModule.setConfig()
                    case 0xd245d983 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.registerUnmanagedSystem()
                    case 0xd3264e43 { result := _ISSUE_USDMODULE } // IssueUSDModule.burnUsd()
                    case 0xd328a91e { result := _CROSS_CHAIN_UPKEEP_MODULE } // CrossChainUpkeepModule.getDONPublicKey()
                    case 0xd4f88381 { result := _MARKET_COLLATERAL_MODULE } // MarketCollateralModule.getMarketCollateralValue()
                    leave
                }
                if lt(sig,0xef45148e) {
                    switch sig
                    case 0xdbdea94c { result := _MARKET_COLLATERAL_MODULE } // MarketCollateralModule.configureMaximumMarketCollateral()
                    case 0xdc0a5384 { result := _VAULT_MODULE } // VaultModule.getPositionCollateralRatio()
                    case 0xdc0b3f52 { result := _COLLATERAL_CONFIGURATION_MODULE } // CollateralConfigurationModule.getCollateralConfiguration()
                    case 0xdf16a074 { result := _ISSUE_USDMODULE } // IssueUSDModule.mintUsd()
                    case 0xdfb83437 { result := _MARKET_MANAGER_MODULE } // MarketManagerModule.getMarketFees()
                    case 0xe12c8160 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowlist()
                    case 0xe1b440d0 { result := _POOL_CONFIGURATION_MODULE } // PoolConfigurationModule.removeApprovedPool()
                    case 0xe7098c0c { result := _POOL_CONFIGURATION_MODULE } // PoolConfigurationModule.setPreferredPool()
                    case 0xed429cf7 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getDeniers()
                    leave
                }
                switch sig
                case 0xef45148e { result := _COLLATERAL_MODULE } // CollateralModule.getAccountCollateral()
                case 0xef50a3ab { result := _POOL_MODULE } // PoolModule.rebalancePool()
                case 0xefecf137 { result := _POOL_MODULE } // PoolModule.getPoolConfiguration()
                case 0xf544d66e { result := _VAULT_MODULE } // VaultModule.getPosition()
                case 0xf86e6f91 { result := _POOL_MODULE } // PoolModule.getPoolName()
                case 0xf896503a { result := _UTILS_MODULE } // UtilsModule.getConfigAddress()
                case 0xf92bb8c9 { result := _UTILS_MODULE } // UtilsModule.getConfigUint()
                case 0xfd85c1f8 { result := _POOL_MODULE } // PoolModule.getMinLiquidityRatio()
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