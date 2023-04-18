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

  Multi-Proxy Admin

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

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _setOwner(_msgSender());
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier isOwner() virtual {
    require(_msgSender() == _owner, "Caller must be the owner.");

    _;
  }

  function transferOwnership(address newOwner) external virtual isOwner {
    require(newOwner != address(0));

    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

abstract contract ReentrancyGuard is Ownable {
  bool internal locked;

  modifier nonReEntrant() {
    require(!locked, "No re-entrancy.");

    locked = true;
    _;
    locked = false;
  }
}

interface IProxy {
  function setOwner(address _owner) external;
  function setImplementation(address _implementation) external;
}

contract upfrontMultiProxyAdmin is ReentrancyGuard {
  address private MULTISIGN_ADDRESS;

  struct proxyInterfaceDataStruct {
    bool exists;
    IProxy iface;
  }

  mapping(address => proxyInterfaceDataStruct) private proxyInterfaceData;

  modifier isProxyInterface(address payable _proxy) {
    require(_proxy != address(this));

    if (!proxyInterfaceData[_proxy].exists) {
      require(Address.isContract(_proxy), "Not a contract.");

      proxyInterfaceData[_proxy].exists = true;
      proxyInterfaceData[_proxy].iface = IProxy(_proxy);
    }

    _;
  }

  modifier isOwner() override {
    require(_msgSender() == owner() || (MULTISIGN_ADDRESS != address(0) && _msgSender() == MULTISIGN_ADDRESS), "Caller must be the owner or the Multi-Signature Wallet.");

    _;
  }

  function setMultiSignatureWallet(address _address) external isOwner {
    require(_address != address(0));

    MULTISIGN_ADDRESS = _address;
  }

  function getProxyOwner(address _proxy) external view returns (address) {
    (bool success, bytes memory result) = _proxy.staticcall(abi.encodeWithSignature("owner()"));

    require(success);

    return abi.decode(result, (address));
  }

  function setProxyOwner(address payable _proxy, address _owner) external isOwner isProxyInterface(_proxy) {
    proxyInterfaceData[_proxy].iface.setOwner(_owner);
  }

  function getProxyImplementation(address _proxy) external view returns (address) {
    (bool success, bytes memory result) = _proxy.staticcall(abi.encodeWithSignature("getImplementation()"));

    require(success);

    return abi.decode(result, (address));
  }

  function setProxyImplementation(address payable _proxy, address _implementation) external isOwner isProxyInterface(_proxy) {
    proxyInterfaceData[_proxy].iface.setImplementation(_implementation);
  }

  function callProxyImplementation(address payable _proxy, bytes[] memory _data) external payable isOwner nonReEntrant returns (bytes[] memory) {
    uint256 cnt = _data.length;
    bytes[] memory results = new bytes[](cnt);

    unchecked {
      for (uint256 i; i < cnt; i++) {
        (bool success, bytes memory result) = payable(_proxy).call{ value: 0 }(_data[i]);

        if (success) {
          results[i] = result;

          continue;
        }

        if (result.length == 0) { revert("Function call reverted."); }

        assembly {
          let size := mload(result)

          revert(add(32, result), size)
        }
      }

      return results;
    }
  }
}