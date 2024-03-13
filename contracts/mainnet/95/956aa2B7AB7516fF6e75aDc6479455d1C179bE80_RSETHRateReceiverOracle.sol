// SPDX-License-Identifier: GPL-3.0-or-later

interface IOracle {
    function priceDecimals() external view returns (uint256);

    function getData() external view returns (uint256, bool);
}

// SPDX-License-Identifier: GPL-3.0

/// @dev https://github.com/Kelp-DAO/LRT-rsETH/blob/main/contracts/cross-chain/RSETHRateReceiver.sol
interface IRSETHRateReceiver {
    /// @notice Gets the last stored rate in the contract
    function getRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {IOracle} from "../interfaces/IOracle.sol";
import {IRSETHRateReceiver} from "../interfaces/IRSETHRateReceiver.sol";

/**
 * @title RSETHRateReceiver Oracle
 *
 * @notice Provides a rsETH:ETH rate for a button wrapper to use
 */
contract RSETHRateReceiverOracle is IOracle {
    /// @dev The output price has a 18 decimal point precision.
    uint256 public constant PRICE_DECIMALS = 18;
    // The address of the RSETHRateReceiver contract
    IRSETHRateReceiver public immutable rsethRateReceiver;

    constructor(IRSETHRateReceiver rsethRateReceiver_) {
        rsethRateReceiver = rsethRateReceiver_;
    }

    /**
     * @notice Fetches the decimal precision used in the market price from chainlink
     * @return priceDecimals_: Number of decimals in the price
     */
    function priceDecimals() external pure override returns (uint256) {
        return PRICE_DECIMALS;
    }

    /**
     * @notice Fetches the latest rsETH:ETH exchange rate from RSETHRateReceiver contract.
     * The returned value is specifically how much ETH is represented by 1e18 raw units of rsETH.
     * @dev The returned value is considered to be always valid since it is derived directly from
     *   the source token.
     * @return Value: Latest market price as an `priceDecimals` decimal fixed point number.
     *         valid: Boolean indicating an value was fetched successfully.
     */
    function getData() external view override returns (uint256, bool) {
        return (rsethRateReceiver.getRate(), true);
    }
}