// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "IGaugeFactory.sol";
import "Gauge.sol";

contract GaugeFactory is IGaugeFactory {
    address public last_gauge;

    function createGauge(address _pool, address _internal_bribe, address _external_bribe, address _ve, bool isPair, address[] memory allowedRewards) external returns (address) {
        last_gauge = address(new Gauge(_pool, _internal_bribe, _external_bribe, _ve, msg.sender, isPair, allowedRewards));
        return last_gauge;
    }
}