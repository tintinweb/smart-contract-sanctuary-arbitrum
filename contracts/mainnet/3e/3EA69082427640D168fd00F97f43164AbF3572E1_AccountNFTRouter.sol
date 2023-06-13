//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract AccountNFTRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _OWNER_UPGRADE_MODULE = 0x98560A91e3b807a5beCD7E21dCbFA2E7aac9c26A;
    address private constant _ACCOUNT_TOKEN_MODULE = 0x46c419DdBD3714f0c394e36b41d27199218911BC;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x6352211e) {
                    if lt(sig,0x3659cfe6) {
                        switch sig
                        case 0x01ffc9a7 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.supportsInterface()
                        case 0x06fdde03 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.name()
                        case 0x081812fc { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.getApproved()
                        case 0x095ea7b3 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.approve()
                        case 0x1627540c { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.nominateNewOwner()
                        case 0x18160ddd { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.totalSupply()
                        case 0x23b872dd { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.transferFrom()
                        case 0x2f745c59 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.tokenOfOwnerByIndex()
                        leave
                    }
                    switch sig
                    case 0x3659cfe6 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.upgradeTo()
                    case 0x392e53cd { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.isInitialized()
                    case 0x40c10f19 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.mint()
                    case 0x42842e0e { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.safeTransferFrom()
                    case 0x42966c68 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.burn()
                    case 0x4f6ccce7 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.tokenByIndex()
                    case 0x53a47bb7 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.nominatedOwner()
                    leave
                }
                if lt(sig,0xa6487c53) {
                    switch sig
                    case 0x6352211e { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.ownerOf()
                    case 0x70a08231 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.balanceOf()
                    case 0x718fe928 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.renounceNomination()
                    case 0x79ba5097 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.acceptOwnership()
                    case 0x8832e6e3 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.safeMint()
                    case 0x8da5cb5b { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.owner()
                    case 0x95d89b41 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.symbol()
                    case 0xa22cb465 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.setApprovalForAll()
                    leave
                }
                switch sig
                case 0xa6487c53 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.initialize()
                case 0xaaf10f42 { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.getImplementation()
                case 0xb88d4fde { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.safeTransferFrom()
                case 0xc7f62cda { result := _OWNER_UPGRADE_MODULE } // OwnerUpgradeModule.simulateUpgradeTo()
                case 0xc87b56dd { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.tokenURI()
                case 0xe985e9c5 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.isApprovedForAll()
                case 0xff53fac7 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.setAllowance()
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