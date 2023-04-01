// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Whitelist{
  string public name;

  address payable public issuer;
  address public registrar;
  address public rescue;

  event IssuerTransferred(address indexed to);
  event RegistrarTransferred(address indexed to);
  event RescueTransferred(address indexed to);

  mapping (address => bool) public registerWhitelist;

  event RegisterWhitelisted(address indexed register);
  event RegisterRemoved(address indexed register);

  mapping (address => mapping(address => bool)) public whitelists;

  event AddressWhitelisted(address indexed register, address indexed holder);
  event AddressRemoved(address indexed register, address indexed holder);

  modifier onlyRegistrar {
    require(msg.sender == registrar, "only registrar can call this");
    _;
  }

  modifier onlyRescue {
    require(msg.sender == rescue, "only rescue can call this");
    _;
  }

  modifier onlyWhitelistedRegister {
    require(registerWhitelist[msg.sender] = true, "register must be whitelisted");
    _;
  }

  constructor (
    string memory _name, 
    address payable _issuer,
    address _registrar,
    address _rescue){
    name = _name;
    issuer = _issuer;
    registrar = _registrar;
    rescue = _rescue;
  }

  function whitelistRegister (address register) external onlyRegistrar {
    require(register != address(0), "register cannot be zero address");
    uint len;
    assembly {
      len := extcodesize(register)
    }
    require(len >= 0, "register must be contract");
    registerWhitelist[register] = true;
    emit RegisterWhitelisted(register);
  }

  function removeRegisterFromWhitelist (address register) external onlyRegistrar {
    require(registerWhitelist[register] = true, "register isn't whitelisted");
    registerWhitelist[register] = false;
    emit RegisterRemoved(register);
  }

  function whitelistAddress (address holder) external onlyWhitelistedRegister {
    require(holder != address(0), "holder cannot be zero address");
    whitelists[msg.sender][holder] = true;
    emit AddressWhitelisted(msg.sender, holder);
  }

  function removeAddressFromWhitelist (address holder) external onlyWhitelistedRegister {
    require(whitelists[msg.sender][holder] = true, "holder is not whitelisted");
    whitelists[msg.sender][holder] = false;
    emit AddressRemoved(msg.sender, holder);
  }

  function transferIssuer(address payable to) external onlyRegistrar {
    require(to != address(0), "new issuer cannot be zero address");
    issuer = to;
    emit IssuerTransferred(to);
  }

  function transferRegistrar(address to) public onlyRescue {
    require(to != address(0), "new registrar cannot be zero address");
    registrar = to;
    emit RegistrarTransferred(to);
  }

  function transferRescue(address to) public onlyRescue {
    require(to != address(0), "new rescue cannot be zero address");
    rescue = to;
    emit RescueTransferred(to);
  }

  function kill() external onlyRegistrar {
    selfdestruct(issuer);
  }
}