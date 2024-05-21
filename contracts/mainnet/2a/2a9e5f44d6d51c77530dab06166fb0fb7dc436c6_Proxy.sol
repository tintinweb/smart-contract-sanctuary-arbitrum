/**
 *Submitted for verification at Arbiscan.io on 2024-05-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
/*
https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=paris&version=soljson-v0.8.24+commit.e11b9ed9.js
*/
contract Proxy {
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    address public admin;  // The team has committed to set up the variable as a smart contract address with voting capabilities by June 1, 2024, thus making the certificate absolutely decentralized. If you view this source code after June 1, 2024, please monitor the contract to which the value of the DAO variable corresponds.

    event Upgraded(address indexed implementation);

    constructor(address _logic, address _addr) {
        admin = _addr;
        _setImplementation(_logic);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the DAO");
        _;
    }

    function _setImplementation(address newImplementation) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function upgrade(address newImplementation) external onlyAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    fallback() external payable {
        _delegate(_implementation());
    }

    receive() external payable {
        _delegate(_implementation());
    }

    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function setAdmin(address addr) external onlyAdmin {
        admin = addr;// The team has committed to set up the variable as a smart contract address with voting capabilities by June 1, 2024, thus making the certificate absolutely decentralized. If you view this source code after June 1, 2024, please monitor the contract to which the value of the DAO variable corresponds.

    }
}