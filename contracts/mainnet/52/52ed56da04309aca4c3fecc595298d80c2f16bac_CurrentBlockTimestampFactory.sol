// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IValueFactory} from "../interfaces/IValueFactory.sol";

/**
 * @title CurrentBlockTimestampFactory - An on-chain value factory that returns the current block timestamp
 * @dev Designed to be used with Safe + ExtensibleFallbackHandler + ComposableCoW
 * @author mfw78 <[email protected]>
 */
contract CurrentBlockTimestampFactory is IValueFactory {
    function getValue(bytes calldata) external view override returns (bytes32) {
        return bytes32(block.timestamp);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IValueFactory - An interface for on-chain value determination
 * @author mfw78 <[email protected]>
 * @dev Designed to be used with Safe + ExtensibleFallbackHandler + ComposableCoW
 */
interface IValueFactory {
    /**
     * Return a value at the time of the call
     * @param data Implementation specific off-chain data
     * @return value The value at the time of the call
     */
    function getValue(bytes calldata data) external view returns (bytes32 value);
}