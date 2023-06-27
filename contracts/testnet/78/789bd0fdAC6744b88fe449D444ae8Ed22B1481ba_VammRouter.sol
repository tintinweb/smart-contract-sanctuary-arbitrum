//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract VammRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _OWNER_UPGRADE_MODULE = 0xF7A6bb7C15a2C20dEda45fE43130d612a2Ef4b5B;
    address private constant _ACCOUNT_BALANCE_MODULE = 0x72a6BD83D056A2792Cbac541f7818ABaBE6AeD83;
    address private constant _FEATURE_FLAG_MODULE = 0x696105c65E16Bf3A65710FcE7E20b1D3cD1A58c9;
    address private constant _POOL_CONFIGURATION_MODULE = 0xEdeadb3892598Abd40DB5F57E35ED89Ac3193866;
    address private constant _POOL_MODULE = 0xF27E45B9D8344A8088a4D994777005DBb4e5946E;
    address private constant _VAMM_MODULE = 0x99D2244224303BFaB4C0592746D5D088d606B6D8;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0xa0778144) {
                    if lt(sig,0x5e52ad6e) {
                        if lt(sig,0x3682ad2f) {
                            switch sig
                            case 0x01ffc9a7 { result := _POOL_MODULE } // PoolModule.supportsInterface()
                            case 0x06fdde03 { result := _POOL_MODULE } // PoolModule.name()
                            case 0x1374accd { result := _VAMM_MODULE } // VammModule.getVammLiquidity()
                            case 0x1627540c { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.nominateNewOwner()
                            case 0x3659cfe6 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.upgradeTo()
                            leave
                        }
                        switch sig
                        case 0x3682ad2f { result := _VAMM_MODULE } // VammModule.getVammConfig()
                        case 0x3b050d0e { result := _VAMM_MODULE } // VammModule.getVammPositionsInAccount()
                        case 0x40a399ef { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowAll()
                        case 0x53a47bb7 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.nominatedOwner()
                        case 0x5a8f58cc { result := _VAMM_MODULE } // VammModule.getVammTick()
                        leave
                    }
                    if lt(sig,0x79ba5097) {
                        switch sig
                        case 0x5e52ad6e { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagDenyAll()
                        case 0x6d810bb0 { result := _VAMM_MODULE } // VammModule.getDatedIRSTwap()
                        case 0x715cb7d2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setDeniers()
                        case 0x718fe928 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.renounceNomination()
                        case 0x75cb63ae { result := _VAMM_MODULE } // VammModule.createVamm()
                        leave
                    }
                    switch sig
                    case 0x79ba5097 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.acceptOwnership()
                    case 0x7d632bd2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagAllowAll()
                    case 0x8d19cecc { result := _POOL_MODULE } // PoolModule.executeDatedTakerOrder()
                    case 0x8da5cb5b { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.owner()
                    case 0x9b236703 { result := _POOL_MODULE } // PoolModule.initiateDatedMakerOrder()
                    leave
                }
                if lt(sig,0xcdb88ad1) {
                    if lt(sig,0xc126f7a1) {
                        switch sig
                        case 0xa0778144 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.addToFeatureFlagAllowlist()
                        case 0xaaf10f42 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.getImplementation()
                        case 0xac7f82c9 { result := _VAMM_MODULE } // VammModule.getVammSqrtPriceX96()
                        case 0xb7746b59 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.removeFromFeatureFlagAllowlist()
                        case 0xbcae3ea0 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagDenyAll()
                        leave
                    }
                    switch sig
                    case 0xc126f7a1 { result := _ACCOUNT_BALANCE_MODULE } // AccountBalanceModule.getAccountUnfilledBases()
                    case 0xc2755ae7 { result := _POOL_CONFIGURATION_MODULE } // PoolConfigurationModule.setProductAddress()
                    case 0xc3392f7a { result := _VAMM_MODULE } // VammModule.getAdjustedDatedIRSTwap()
                    case 0xc7f62cda { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.simulateUpgradeTo()
                    case 0xcab146c9 { result := _POOL_MODULE } // PoolModule.closeUnfilledBase()
                    leave
                }
                if lt(sig,0xed429cf7) {
                    switch sig
                    case 0xcdb88ad1 { result := _POOL_CONFIGURATION_MODULE } // PoolConfigurationModule.setPauseState()
                    case 0xcf635949 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.isFeatureAllowed()
                    case 0xde84ba9f { result := _ACCOUNT_BALANCE_MODULE } // AccountBalanceModule.getAccountFilledBalances()
                    case 0xe12c8160 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowlist()
                    case 0xe3a05a2d { result := _VAMM_MODULE } // VammModule.getVammTrackerQuoteTokenGrowthGlobalX128()
                    leave
                }
                switch sig
                case 0xed429cf7 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getDeniers()
                case 0xf7860225 { result := _VAMM_MODULE } // VammModule.configureVamm()
                case 0xfa80bcd4 { result := _VAMM_MODULE } // VammModule.getVammTickBitmap()
                case 0xfc1c9a0a { result := _VAMM_MODULE } // VammModule.getVammTickInfo()
                case 0xfda251c1 { result := _VAMM_MODULE } // VammModule.getVammTrackerBaseTokenGrowthGlobalX128()
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