// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDeployer {
  function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable createdContract);
}

contract Deployer {
  IDeployer public immutable deployer;

  constructor() {
    // Use EIP-2470 SingletonFactory address by default
    deployer = IDeployer(0xce0042B868300000d44A59004Da54A005ffdcf9f);
    emit Deployed(tx.origin, address(this));
  }

  event Deployed(address indexed sender, address indexed addr);

  function deploy(bytes memory _initCode, bytes32 _salt) external {
    address createdContract = deployer.deploy(_initCode, _salt);
    require(createdContract != address(0), "Deploy failed");
    emit Deployed(msg.sender, createdContract);
  }
}