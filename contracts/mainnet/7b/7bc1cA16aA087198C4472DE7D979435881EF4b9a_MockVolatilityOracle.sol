// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVolatilityOracle {
  function getVolatility() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IVolatilityOracle } from "../interfaces/IVolatilityOracle.sol";

contract MockVolatilityOracle {
  uint256 public volatility = 150;

  function updateVolatility(uint256 _volatility) external returns (bool) {
    volatility = _volatility;
    return true;
  }

  function getVolatility() public view returns (uint256) {
    return volatility;
  }

  function getVolatility(uint256) public view returns (uint256) {
    return volatility;
  }
}