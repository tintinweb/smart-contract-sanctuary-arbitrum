// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IPriceFeedMockOwnable.sol";

contract PriceFeedMockOwnable is IPriceFeedMockOwnable {
  mapping(address => uint256) public tokenPrices;
  bool public anybodyCanSetPrices = true;
  address public owner;
  mapping(address => bool) public priceSetters;
  bool public malfunction = false;

  error OracleMalfunctionSet();

  constructor(address _newOwner) {
    owner = _newOwner;
    priceSetters[_newOwner] = true;
  }

  function setPrice(address _token, uint256 _price) external {
    require(_checkCaller(), "Caller cannot set price");
    tokenPrices[_token] = _price;
  }

  function makeOracleMalfunction(bool _setting) external {
    require(_checkCaller(), "Caller cannot set malfunction");
    malfunction = _setting;
  }

  function setAnybodyCanSet(bool _setting) external {
    require(
      msg.sender == owner,
      "PriceFeedMock: Only owner can flip this"
    );
    anybodyCanSetPrices = _setting;
  }

  function setPriceSetter(address _setter, bool _setting) external {
    require(
      msg.sender == owner,
      "PriceFeedMock: Only owner can add a setter"
    );
    priceSetters[_setter] = _setting;
  }

  function getPrice(
    address _token, 
    bool _maximise, 
    bool _includeAmmPrice, 
    bool _useSwapPricing) external view returns (uint256) {
      if (malfunction) {
        revert OracleMalfunctionSet();
      }
      return tokenPrices[_token];
  }

  function _checkCaller() internal view returns(bool) {
    if(anybodyCanSetPrices) {
      return true;
    } else {
      return (priceSetters[msg.sender]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5 <0.9.0;

interface IPriceFeedMockOwnable {
  function getPrice(
    address _token, 
    bool _maximise,
    bool _includeAmmPrice, 
    bool _useSwapPricing) external view returns (uint256);
}