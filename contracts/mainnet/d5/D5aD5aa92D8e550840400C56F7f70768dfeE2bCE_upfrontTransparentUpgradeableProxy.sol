/**
 *Submitted for verification at Arbiscan on 2023-04-18
*/

// SPDX-License-Identifier: MIT

/*
               __                 _   
  _   _ _ __  / _|_ __ ___  _ __ | |_ 
 | | | | '_ \| |_| '__/ _ \| '_ \| __|
 | |_| | |_) |  _| | | (_) | | | | |_ 
  \__,_| .__/|_| |_|  \___/|_| |_|\__|
       |_|                            

  Transparent Upgradeable Proxy

  Authors: <dotfx>
  Date: 2023/04/11
  Version: 1.0.0
*/

pragma solidity >=0.8.18 <0.9.0;

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
}

library StorageSlot {
  function getAddressSlot(bytes32 _slot) internal view returns (address) {
    address addr;

    assembly {
      addr := sload(_slot)
    }

    return addr;
  }

  function setAddressSlot(bytes32 _slot, address _addr) internal {
    assembly {
      sstore(_slot, _addr)
    }
  }
}

contract upfrontTransparentUpgradeableProxy {
  bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
  bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event ImplementationUpgraded(address indexed implementation);

  modifier isOwner() {
    if (msg.sender == _getOwner()) {
      _;
    } else {
      _fallback();
    }
  }

  constructor() payable {
    _setOwner(msg.sender);
  }

  receive() external payable virtual { _fallback(); }
  fallback() external payable virtual { _fallback(); }

  function owner() external view returns (address) {
    return _getOwner();
  }

  function setOwner(address newOwner) external virtual isOwner {
    require(newOwner != address(0));

    _setOwner(newOwner);
  }

  function getImplementation() external view returns (address) {
    return _getImplementation();
  }

  function setImplementation(address payable _implementation) external payable isOwner {
    _setImplementation(_implementation);
  }

  function _getOwner() internal view returns (address) {
    return StorageSlot.getAddressSlot(ADMIN_SLOT);
  }

  function _setOwner(address newOwner) internal {
    require(newOwner != address(0));

    address oldOwner = _getOwner();

    StorageSlot.setAddressSlot(ADMIN_SLOT, newOwner);

    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _getImplementation() internal view returns (address) {
    return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT);
  }

  function _setImplementation(address _implementation) internal {
    require(Address.isContract(_implementation), "Not a contract.");

    StorageSlot.setAddressSlot(IMPLEMENTATION_SLOT, _implementation);

    emit ImplementationUpgraded(_implementation);
  }

  function _delegate(address _implementation) internal virtual returns (bytes memory) {
    assembly {
      let csize := calldatasize()

      calldatacopy(0, 0, csize)

      let result := delegatecall(gas(), _implementation, 0, csize, 0, 0)
      let rsize := returndatasize()

      returndatacopy(0, 0, rsize)

      switch result
        case 0 { revert(0, rsize) }
        default { return(0, rsize) }
    }
  }

  function _fallback() internal virtual {
    _delegate(_getImplementation());
  }
}