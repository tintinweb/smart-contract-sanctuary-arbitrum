/**
 *Submitted for verification at Arbiscan.io on 2024-04-30
*/

//SPDX-License-Identifier: UNLICENSED
//mainnet 0x000000000344F30E2aa0CbD5EE9fa936DA3573Ec
pragma solidity 0.8.19;

contract Proxy {
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    struct AddressSlot {
        address value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function setLogicContract(address _c) public returns (bool success){
        require(msg.sender==getAddressSlot(_ADMIN_SLOT).value, "!admin");
        getAddressSlot(_IMPLEMENTATION_SLOT).value = _c;
        return true;
    }

    fallback () payable external {
        address target = getAddressSlot(_IMPLEMENTATION_SLOT).value;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    constructor(){
        getAddressSlot(_ADMIN_SLOT).value=0x518080133E67cF6fF29785b3CB74d6be8aE278a2;
    }
}