//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract DatedIrsRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _OWNER_UPGRADE_MODULE = 0x0FC499dde2Fe64F2a07859868D1E2E3d13792A0D;
    address private constant _MARKET_CONFIGURATION_MODULE = 0xEB1b60d1AaEE4B7b0B3b44133d2eeB700109B35b;
    address private constant _PRODUCT_IRSMODULE = 0x465ad81639888EB66315e07fEdcb6C2102aA1E24;
    address private constant _RATE_ORACLE_MODULE = 0xa91491F54D228f35441DF97B86a3d0C0ADCD45e7;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x745465c3) {
                    if lt(sig,0x481f7e9f) {
                        switch sig
                        case 0x01ffc9a7 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.supportsInterface()
                        case 0x06fdde03 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.name()
                        case 0x15cd01a0 { result := _RATE_ORACLE_MODULE } // RateOracleModule.getRateIndexCurrent()
                        case 0x1627540c { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.nominateNewOwner()
                        case 0x3659cfe6 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.upgradeTo()
                        case 0x37fb7d8b { result := _PRODUCT_IRSMODULE } // ProductIRSModule.propagateMakerOrder()
                        case 0x3cbe1f9a { result := _RATE_ORACLE_MODULE } // RateOracleModule.getVariableOracleAddress()
                        leave
                    }
                    switch sig
                    case 0x481f7e9f { result := _RATE_ORACLE_MODULE } // RateOracleModule.setVariableOracle()
                    case 0x4aba1dea { result := _PRODUCT_IRSMODULE } // ProductIRSModule.getAccountAnnualizedExposures()
                    case 0x4f126281 { result := _RATE_ORACLE_MODULE } // RateOracleModule.backfillRateIndexAtMaturityCache()
                    case 0x53a47bb7 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.nominatedOwner()
                    case 0x5e4a1866 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.configureProduct()
                    case 0x6e9eeb0a { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getMarketConfiguration()
                    case 0x718fe928 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.renounceNomination()
                    leave
                }
                if lt(sig,0xaaf10f42) {
                    switch sig
                    case 0x745465c3 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.closeAccount()
                    case 0x77e44407 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.baseToAnnualizedExposure()
                    case 0x78323046 { result := _RATE_ORACLE_MODULE } // RateOracleModule.getRateIndexMaturity()
                    case 0x79ba5097 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.acceptOwnership()
                    case 0x87861ac5 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.settle()
                    case 0x8a9900c0 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.getAccountUnrealizedPnL()
                    case 0x8da5cb5b { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.owner()
                    leave
                }
                switch sig
                case 0xaaf10f42 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.getImplementation()
                case 0xae0e380c { result := _RATE_ORACLE_MODULE } // RateOracleModule.updateRateIndexAtMaturityCache()
                case 0xb11a02fc { result := _PRODUCT_IRSMODULE } // ProductIRSModule.getCoreProxyAddress()
                case 0xb1efe7ff { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.configureMarket()
                case 0xc7f62cda { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.simulateUpgradeTo()
                case 0xf7432a6a { result := _PRODUCT_IRSMODULE } // ProductIRSModule.initiateTakerOrder()
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