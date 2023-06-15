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
    address private constant _MARKET_CONFIGURATION_MODULE = 0x3a6b2c86fbD34aFADDf13259A5E54EC160F004B4;
    address private constant _PRODUCT_IRSMODULE = 0xd86D23fF05C11ea7824cEB7336004Fb912b0EB55;
    address private constant _RATE_ORACLE_MANAGER = 0x41EcaAC9061F6BABf2D42068F8F8dAF3BA9644FF;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x79ba5097) {
                    if lt(sig,0x5e4a1866) {
                        switch sig
                        case 0x01ffc9a7 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.supportsInterface()
                        case 0x06fdde03 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.name()
                        case 0x1627540c { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.nominateNewOwner()
                        case 0x3659cfe6 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.upgradeTo()
                        case 0x4aba1dea { result := _PRODUCT_IRSMODULE } // ProductIRSModule.getAccountAnnualizedExposures()
                        case 0x53a47bb7 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.nominatedOwner()
                        leave
                    }
                    switch sig
                    case 0x5e4a1866 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.configureProduct()
                    case 0x6e9eeb0a { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.getMarketConfiguration()
                    case 0x718fe928 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.renounceNomination()
                    case 0x745465c3 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.closeAccount()
                    case 0x77e44407 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.baseToAnnualizedExposure()
                    case 0x78323046 { result := _RATE_ORACLE_MANAGER } // RateOracleManager.getRateIndexMaturity()
                    leave
                }
                if lt(sig,0xb11a02fc) {
                    switch sig
                    case 0x79ba5097 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.acceptOwnership()
                    case 0x84c2c67d { result := _RATE_ORACLE_MANAGER } // RateOracleManager.getRateIndexCurrent()
                    case 0x87861ac5 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.settle()
                    case 0x8a9900c0 { result := _PRODUCT_IRSMODULE } // ProductIRSModule.getAccountUnrealizedPnL()
                    case 0x8da5cb5b { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.owner()
                    case 0xaaf10f42 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.getImplementation()
                    leave
                }
                switch sig
                case 0xb11a02fc { result := _PRODUCT_IRSMODULE } // ProductIRSModule.getCoreProxyAddress()
                case 0xb1efe7ff { result := _MARKET_CONFIGURATION_MODULE } // MarketConfigurationModule.configureMarket()
                case 0xc7f62cda { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.simulateUpgradeTo()
                case 0xd677e5f4 { result := _RATE_ORACLE_MANAGER } // RateOracleManager.setVariableOracle()
                case 0xe964373b { result := _PRODUCT_IRSMODULE } // ProductIRSModule.propagateMakerOrder()
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