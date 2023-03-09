/**
 *Submitted for verification at Arbiscan on 2023-03-08
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

contract TestCallData {
    event CalledWithData(bytes dataCalledWith);
    event CalledWithSigAndData(bytes4 sig, bytes dataCalledWith);

    function testFunction(bytes calldata someData) external {
        emit CalledWithData(someData);
    }

    fallback() external {
        emit CalledWithSigAndData(msg.sig, msg.data);
    }
}