//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract AccountsRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _BASE_MODULE = 0xA8fD64C70cad96FBFF9c15bBC3C2E032Ada41472;
    address private constant _BRIDGING_MODULE = 0x3200C61F541dE25654891371E8D35C280eB87dbb;
    address private constant _ACCOUNT_UTILS_MODULE = 0xC4cFFB595d8ab179EAebe56799eBAf2901e5fB01;
    address private constant _RECOVERY_MODULE = 0x884dBAD85355eDd71FaC528fE613eb4Cd1b4E3a9;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x926fee8d) {
                    if lt(sig,0x5f406ec2) {
                        switch sig
                        case 0x04e9f64c { result := _BASE_MODULE } // BaseModule.removeTrustedForwarder()
                        case 0x078af012 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.updateUSDCAddress()
                        case 0x0b9e332a { result := _BASE_MODULE } // BaseModule.setRecoveryKeyStatus()
                        case 0x29543cc9 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.isValidOperationKey()
                        case 0x3659cfe6 { result := _BASE_MODULE } // BaseModule.upgradeTo()
                        case 0x389197db { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.upgradeProtocolBeaconParameters()
                        case 0x509a3001 { result := _BRIDGING_MODULE } // BridgingModule.processWormholeBridgeMessage()
                        case 0x52a68f2f { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.updateWormholeCircleBridge()
                        case 0x572b6c05 { result := _BASE_MODULE } // BaseModule.isTrustedForwarder()
                        leave
                    }
                    switch sig
                    case 0x5f406ec2 { result := _BASE_MODULE } // BaseModule.addTrustedForwarder()
                    case 0x620d9799 { result := _RECOVERY_MODULE } // RecoveryModule.getFundsRecoveryAddress()
                    case 0x632f57f5 { result := _RECOVERY_MODULE } // RecoveryModule.setFundsRecoveryAddress()
                    case 0x697b9aab { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.getMaxWithdrawalFee()
                    case 0x70384a3e { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.getWormholeCircleBridgeParams()
                    case 0x7a640eb5 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.getCircleBridgeParams()
                    case 0x84b0196e { result := _BASE_MODULE } // BaseModule.eip712Domain()
                    case 0x8663d3e5 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.isValidSudoKey()
                    case 0x8e596830 { result := _RECOVERY_MODULE } // RecoveryModule.recoverUSDCToEVMChain()
                    leave
                }
                if lt(sig,0xc4d66de8) {
                    switch sig
                    case 0x926fee8d { result := _BASE_MODULE } // BaseModule.trustedForwarders()
                    case 0x9be65a60 { result := _RECOVERY_MODULE } // RecoveryModule.recoverToken()
                    case 0xa0c1e03c { result := _BRIDGING_MODULE } // BridgingModule.bridgeUSDCWithCCTPSolana()
                    case 0xaaf10f42 { result := _BASE_MODULE } // BaseModule.getImplementation()
                    case 0xae398e4b { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.updateCircleBridgeParams()
                    case 0xb440078e { result := _BRIDGING_MODULE } // BridgingModule.bridgeUSDCWithWormholeEVM()
                    case 0xba0f2637 { result := _BASE_MODULE } // BaseModule.isValidNonce()
                    case 0xbc06e81d { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.getUSDCAddress()
                    case 0xbc8ea8fd { result := _BASE_MODULE } // BaseModule.setOperationKeyStatus()
                    leave
                }
                switch sig
                case 0xc4d66de8 { result := _BASE_MODULE } // BaseModule.initialize()
                case 0xc7f62cda { result := _BASE_MODULE } // BaseModule.simulateUpgradeTo()
                case 0xd4acccfb { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.infinexProtocolConfigBeacon()
                case 0xd61fa209 { result := _BRIDGING_MODULE } // BridgingModule.getBridgeMaxAmount()
                case 0xd6cb2cdd { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.getWormholeCircleBridge()
                case 0xdd075d9b { result := _RECOVERY_MODULE } // RecoveryModule.bridgeUSDCWithWormholeForRecovery()
                case 0xf5eb6656 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.isValidRecoveryKey()
                case 0xfeabd094 { result := _BASE_MODULE } // BaseModule.setSudoKeyStatus()
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