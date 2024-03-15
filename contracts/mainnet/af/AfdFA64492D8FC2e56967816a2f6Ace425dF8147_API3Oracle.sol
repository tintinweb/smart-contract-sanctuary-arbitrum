// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Actual interface taken from https://arbiscan.io/address/0x1bEB65b15689cCAeb5dA191c9fd5F94513923Cab#code#F11
// This should be a useful reference but at time of writing it is unclear how the import resolves to source code:
//   https://github.com/api3dao/contracts/blob/main/contracts/v0.8/interfaces/IDapiProxy.sol
interface IDapiProxy {
    function read() external view returns (int224 value, uint32 timestamp);
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IOracle {
    function priceDecimals() external view returns (uint256);

    function getData() external view returns (uint256, bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {IOracle} from "../interfaces/IOracle.sol";
import {IDapiProxy} from "../interfaces/IDapiProxy.sol";

/**
 * @title API3 Oracle
 *
 * @notice Provides a value onchain from a API3 oracle
 */
contract API3Oracle is IOracle {
    /// @dev Per the docs API3 values are always 18 decimal format:
    ///   https://docs.api3.org/guides/dapis/read-a-dapi/#:~:text=the%20latest%20value%20with%2018%20decimals
    uint256 public constant PRICE_DECIMALS = 18;
    // The address of the API3 DapiProxy contract
    IDapiProxy public immutable oracle;
    uint256 public immutable stalenessThresholdSecs;

    constructor(address _oracle, uint256 _stalenessThresholdSecs) {
        oracle = IDapiProxy(_oracle);
        stalenessThresholdSecs = _stalenessThresholdSecs;
    }

    /**
     * @notice Fetches the decimal precision used in the market price from API3
     * @return priceDecimals_: Number of decimals in the price
     */
    function priceDecimals() external pure override returns (uint256) {
        return PRICE_DECIMALS;
    }

    /**
     * @notice Fetches the latest market price from API3
     * @return Value: Latest market price.
     *         valid: Boolean indicating an value was fetched successfully.
     */
    function getData() external view override returns (uint256, bool) {
        (int224 value, uint32 timestamp) = oracle.read();
        // Return invalid if value cannot be converted into a uint256
        if (value < 0) {
            return (0, false);
        }
        uint256 diff = block.timestamp - uint256(timestamp);
        return (uint256(int256(value)), diff <= stalenessThresholdSecs);
    }
}