/**
 *Submitted for verification at Arbiscan.io on 2024-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract TransparentUpgradeableProxy {
    // Storage slot for the implementation address
    bytes32 private constant implementationSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    // Storage slot for the admin address
    bytes32 private constant adminSlot = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event Upgraded(address indexed implementation);

    constructor(address _logic, address _adminAddress) {
        _setImplementation(_logic);
        _setAdmin(_adminAddress);
    }

    function _setImplementation(address _logic) private {
        bytes32 slot = implementationSlot;
        assembly {
            sstore(slot, _logic)
        }
    }

    function _setAdmin(address _adminAddress) private {
        bytes32 slot = adminSlot;
        assembly {
            sstore(slot, _adminAddress)
        }
    }

    function implementation() external view returns (address impl) {
        bytes32 slot = implementationSlot;
        assembly {
            impl := sload(slot)
        }
    }

    function admin() external view returns (address adm) {
        bytes32 slot = adminSlot;
        assembly {
            adm := sload(slot)
        }
    }

    function upgradeTo(address newImplementation) external {
        require(msg.sender == _admin(), "Proxy: caller is not the admin");
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    fallback() external payable {
        address _impl = _implementation();
        require(_impl != address(0), "Proxy: implementation not set");

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}

    function _implementation() internal view returns (address impl) {
        bytes32 slot = implementationSlot;
        assembly {
            impl := sload(slot)
        }
    }

    function _admin() internal view returns (address adm) {
        bytes32 slot = adminSlot;
        assembly {
            adm := sload(slot)
        }
    }
}