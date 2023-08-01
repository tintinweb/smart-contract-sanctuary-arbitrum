/**
 *Submitted for verification at Arbiscan on 2023-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ArbGasInfo {
    function getL1BaseFeeEstimate() external view returns (uint256);
    function getCurrentTxL1GasFees() external view returns (uint256);
}

contract Arb {
    ArbGasInfo constant internal ARB_GAS_INFO = ArbGasInfo(0x000000000000000000000000000000000000006C);

    event Execute(
        uint256 _l2GasUsed,
        uint256 _l2GasPrice,
        uint256 _l1BaseFeeEstimate,
        uint256 _currentTxL1GasFees
    );

    function execute() external {
        emit Execute(
            gasleft(),
            tx.gasprice,
            ARB_GAS_INFO.getL1BaseFeeEstimate(),
            ARB_GAS_INFO.getCurrentTxL1GasFees()
        );
    }
}