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
    address private constant _ACCOUNT_BALANCE_MODULE = 0x980AAae5D8e40f1042623E1177BE93DDDdFC47D5;
    address private constant _FEATURE_FLAG_MODULE = 0x5AE480fFe0582Ed7E59C34ec18abFE0F9f1fb4A9;
    address private constant _POOL_CONFIGURATION = 0x02D56b66DC2A748d6fE7Fd48F3a80EEaB402b4bF;
    address private constant _POOL_MODULE = 0x575Bf19C89e91278A5A29c83e5401974bcBA2894;
    address private constant _VAMM_MODULE = 0x30FFB8673e20D83B594675b71B065f22fCB15448;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x8da5cb5b) {
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
                    switch sig
                    case 0x5e52ad6e { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagDenyAll()
                    case 0x6d810bb0 { result := _VAMM_MODULE } // VammModule.getDatedIRSTwap()
                    case 0x715cb7d2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setDeniers()
                    case 0x718fe928 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.renounceNomination()
                    case 0x75cb63ae { result := _VAMM_MODULE } // VammModule.createVamm()
                    case 0x79ba5097 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.acceptOwnership()
                    case 0x7d632bd2 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.setFeatureFlagAllowAll()
                    case 0x7e2be1ad { result := _VAMM_MODULE } // VammModule.getVammTrackerFixedTokenGrowthGlobalX128()
                    case 0x8d19cecc { result := _POOL_MODULE } // PoolModule.executeDatedTakerOrder()
                    leave
                }
                if lt(sig,0xcab146c9) {
                    if lt(sig,0xb7746b59) {
                        switch sig
                        case 0x8da5cb5b { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.owner()
                        case 0x9b236703 { result := _POOL_MODULE } // PoolModule.initiateDatedMakerOrder()
                        case 0xa0778144 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.addToFeatureFlagAllowlist()
                        case 0xaaf10f42 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.getImplementation()
                        case 0xac7f82c9 { result := _VAMM_MODULE } // VammModule.getVammSqrtPriceX96()
                        leave
                    }
                    switch sig
                    case 0xb7746b59 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.removeFromFeatureFlagAllowlist()
                    case 0xbcae3ea0 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagDenyAll()
                    case 0xc126f7a1 { result := _ACCOUNT_BALANCE_MODULE } // AccountBalanceModule.getAccountUnfilledBases()
                    case 0xc3392f7a { result := _VAMM_MODULE } // VammModule.getAdjustedDatedIRSTwap()
                    case 0xc7f62cda { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.simulateUpgradeTo()
                    leave
                }
                switch sig
                case 0xcab146c9 { result := _POOL_MODULE } // PoolModule.closeUnfilledBase()
                case 0xcf635949 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.isFeatureAllowed()
                case 0xde84ba9f { result := _ACCOUNT_BALANCE_MODULE } // AccountBalanceModule.getAccountFilledBalances()
                case 0xe12c8160 { result := _FEATURE_FLAG_MODULE } // FeatureFlagModule.getFeatureFlagAllowlist()
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