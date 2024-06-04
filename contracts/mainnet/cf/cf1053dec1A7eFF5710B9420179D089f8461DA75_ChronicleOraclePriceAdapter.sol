// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

import { IPriceAdapter } from "src/oracles/interfaces/IPriceAdapter.sol";
import { IChronicle } from "src/oracles/interfaces/IChronicle.sol";

contract ChronicleOraclePriceAdapter is IPriceAdapter {
  IChronicle public priceFeed;

  constructor(address priceFeed_) {
    priceFeed = IChronicle(priceFeed_);
  }

  /// @notice Return the price in 18 decimals
  function getPrice() external view returns (uint256 price) {
    price = priceFeed.read();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/*
@title IChronicle
@notice Interface for Chronicle Protocol's oracle products
*/

interface IChronicle {
  /// @notice Returns the oracle's identifier.
  /// @return wat The oracle's identifier.

  function wat() external view returns (bytes32 wat);

  /// @notice Returns the oracle's current value.
  /// @dev Reverts if no value set.
  /// @return value The oracle's current value.

  function read() external view returns (uint value);

  /// @notice Returns the oracle's current value and its age.
  /// @dev Reverts if no value set.
  /// @return value The oracle's current value.
  /// @return age The value's age.

  function readWithAge() external view returns (uint value, uint age);

  /// @notice Returns the oracle's current value.
  /// @return isValid True if value exists, false otherwise.
  /// @return value The oracle's current value if it exists, zero otherwise.

  function tryRead() external view returns (bool isValid, uint value);

  /// @notice Returns the oracle's current value and its age.
  /// @return isValid True if value exists, false otherwise.
  /// @return value The oracle's current value if it exists, zero otherwise.
  /// @return age The value's age if value exists, zero otherwise.

  function tryReadWithAge() external view returns (bool isValid, uint value, uint age);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IPriceAdapter {
  function getPrice() external view returns (uint256 price);
}