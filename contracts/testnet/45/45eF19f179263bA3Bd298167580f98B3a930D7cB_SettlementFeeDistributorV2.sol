// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;


/**
 * @author Heisenberg
 * @title Buffer SettlementFeeDistributor
 * @notice Distributes the SettlementFee Collected by the Buffer Protocol
 */

contract SettlementFeeDistributorV2 {

    event Distributed(address indexed sender);
    function distribute() external {
        emit Distributed(msg.sender);
    }

}