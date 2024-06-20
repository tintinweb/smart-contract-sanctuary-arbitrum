//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract AccountsRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _APP_MODULE = 0xB09a1a16a9306a0A882A518C9F0d8B4bf42291D1;
    address private constant _BASE_MODULE = 0x0fE1d2a0bDf1c7F57981c6E677525e0008965637;
    address private constant _BRIDGING_MODULE = 0xFbe4746294a7e465713134224c445c8cA2e420E5;
    address private constant _ACCOUNT_UTILS_MODULE = 0xF65dC71ac1861cc4d6f00D9f53d567b03742fe84;
    address private constant _RECOVERY_MODULE = 0x0e1fdAfd756a9788C6BCD84a37BC43D4D5DDcB30;
    address private constant _WITHDRAW_MODULE = 0xFFcCbea112d48F7FEd89a99a10A2405aBF637cD7;
    
    receive() external payable {}

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x84b0196e) {
                    if lt(sig,0x4ffe193d) {
                        if lt(sig,0x29543cc9) {
                            switch sig
                            case 0x01fd453b { result := _WITHDRAW_MODULE } // WithdrawModule.allowlistedWithdrawalAddressValidFrom()
                            case 0x01ffc9a7 { result := _BASE_MODULE } // BaseModule.supportsInterface()
                            case 0x04e9f64c { result := _BASE_MODULE } // BaseModule.removeTrustedForwarder()
                            case 0x078af012 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.updateUSDCAddress()
                            case 0x0b9e332a { result := _BASE_MODULE } // BaseModule.setRecoveryKeyStatus()
                            case 0x1311b246 { result := _WITHDRAW_MODULE } // WithdrawModule.setAllowlistedWithdrawalAddress()
                            case 0x150b7a02 { result := _BASE_MODULE } // BaseModule.onERC721Received()
                            case 0x194d9a48 { result := _WITHDRAW_MODULE } // WithdrawModule.withdrawERC1155ToAllowlistedAddress()
                            case 0x24c709ea { result := _RECOVERY_MODULE } // RecoveryModule.recoverERC1155Batch()
                            leave
                        }
                        switch sig
                        case 0x29543cc9 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.isValidOperationKey()
                        case 0x3659cfe6 { result := _BASE_MODULE } // BaseModule.upgradeTo()
                        case 0x389197db { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.upgradeProtocolBeaconParameters()
                        case 0x3a181eba { result := _WITHDRAW_MODULE } // WithdrawModule.withdrawERC1155BatchToAllowlistedAddress()
                        case 0x446dfab9 { result := _WITHDRAW_MODULE } // WithdrawModule.getAllowlistDelay()
                        case 0x447026eb { result := _APP_MODULE } // AppModule.deprecateAppAccount()
                        case 0x453fbd6e { result := _BASE_MODULE } // BaseModule.reinitializeLegacyAccount()
                        case 0x4fbf0255 { result := _APP_MODULE } // AppModule.getAppBeacon()
                        leave
                    }
                    if lt(sig,0x61ec4a34) {
                        switch sig
                        case 0x4ffe193d { result := _WITHDRAW_MODULE } // WithdrawModule.withdrawERC721ToAllowlistedAddress()
                        case 0x509a3001 { result := _BRIDGING_MODULE } // BridgingModule.processWormholeBridgeMessage()
                        case 0x52a68f2f { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.updateWormholeCircleBridge()
                        case 0x52d8bfc2 { result := _RECOVERY_MODULE } // RecoveryModule.recoverEther()
                        case 0x535e1547 { result := _BASE_MODULE } // BaseModule.accountVersion()
                        case 0x55965ed3 { result := _WITHDRAW_MODULE } // WithdrawModule.isAllowlistedWithdrawalAddress()
                        case 0x572b6c05 { result := _BASE_MODULE } // BaseModule.isTrustedForwarder()
                        case 0x5f406ec2 { result := _BASE_MODULE } // BaseModule.addTrustedForwarder()
                        leave
                    }
                    switch sig
                    case 0x61ec4a34 { result := _APP_MODULE } // AppModule.transferEthToApp()
                    case 0x620d9799 { result := _RECOVERY_MODULE } // RecoveryModule.getFundsRecoveryAddress()
                    case 0x632f57f5 { result := _RECOVERY_MODULE } // RecoveryModule.setFundsRecoveryAddress()
                    case 0x6635c9ac { result := _APP_MODULE } // AppModule.transferERC721TokenToApp()
                    case 0x697b9aab { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.getMaxWithdrawalFee()
                    case 0x70384a3e { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.getWormholeCircleBridgeParams()
                    case 0x7a640eb5 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.getCircleBridgeParams()
                    case 0x819d4cc6 { result := _RECOVERY_MODULE } // RecoveryModule.recoverERC721()
                    leave
                }
                if lt(sig,0xbe1695e9) {
                    if lt(sig,0xaaf10f42) {
                        switch sig
                        case 0x84b0196e { result := _BASE_MODULE } // BaseModule.eip712Domain()
                        case 0x8663d3e5 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.isValidSudoKey()
                        case 0x89580cd6 { result := _RECOVERY_MODULE } // RecoveryModule.recoverERC1155()
                        case 0x8e596830 { result := _RECOVERY_MODULE } // RecoveryModule.recoverUSDCToEVMChain()
                        case 0x90aebde7 { result := _WITHDRAW_MODULE } // WithdrawModule.withdrawEtherToAllowlistedAddress()
                        case 0x926fee8d { result := _BASE_MODULE } // BaseModule.trustedForwarders()
                        case 0x9a1b97df { result := _BASE_MODULE } // BaseModule.reinitialize()
                        case 0x9be65a60 { result := _RECOVERY_MODULE } // RecoveryModule.recoverToken()
                        case 0xa0c1e03c { result := _BRIDGING_MODULE } // BridgingModule.bridgeUSDCWithCCTPSolana()
                        leave
                    }
                    switch sig
                    case 0xaaf10f42 { result := _BASE_MODULE } // BaseModule.getImplementation()
                    case 0xae398e4b { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.updateCircleBridgeParams()
                    case 0xb440078e { result := _BRIDGING_MODULE } // BridgingModule.bridgeUSDCWithWormholeEVM()
                    case 0xb7e53d18 { result := _APP_MODULE } // AppModule.upgradeAppAccount()
                    case 0xba0f2637 { result := _BASE_MODULE } // BaseModule.isValidNonce()
                    case 0xbc06e81d { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.getUSDCAddress()
                    case 0xbc197c81 { result := _BASE_MODULE } // BaseModule.onERC1155BatchReceived()
                    case 0xbc8ea8fd { result := _BASE_MODULE } // BaseModule.setOperationKeyStatus()
                    leave
                }
                if lt(sig,0xdd075d9b) {
                    switch sig
                    case 0xbe1695e9 { result := _APP_MODULE } // AppModule.transferERC20TokenToApp()
                    case 0xc0b7394c { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.isAuthorizedRecoveryParty()
                    case 0xc4d66de8 { result := _BASE_MODULE } // BaseModule.initialize()
                    case 0xc7ddabc9 { result := _APP_MODULE } // AppModule.deployAppAccount()
                    case 0xc7f62cda { result := _BASE_MODULE } // BaseModule.simulateUpgradeTo()
                    case 0xd4acccfb { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.infinexProtocolConfigBeacon()
                    case 0xd61fa209 { result := _BRIDGING_MODULE } // BridgingModule.getBridgeMaxAmount()
                    case 0xd6cb2cdd { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.getWormholeCircleBridge()
                    leave
                }
                switch sig
                case 0xdd075d9b { result := _RECOVERY_MODULE } // RecoveryModule.bridgeUSDCWithWormholeForRecovery()
                case 0xe75c6783 { result := _WITHDRAW_MODULE } // WithdrawModule.withdrawERC20ToAllowlistedAddress()
                case 0xe8f68919 { result := _APP_MODULE } // AppModule.transferERC1155TokenToApp()
                case 0xf23a6e61 { result := _BASE_MODULE } // BaseModule.onERC1155Received()
                case 0xf462ccf5 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.isAuthorizedOperationsParty()
                case 0xf5eb6656 { result := _ACCOUNT_UTILS_MODULE } // AccountUtilsModule.isValidRecoveryKey()
                case 0xf8f8594d { result := _APP_MODULE } // AppModule.transferERC1155BatchedTokenToApp()
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