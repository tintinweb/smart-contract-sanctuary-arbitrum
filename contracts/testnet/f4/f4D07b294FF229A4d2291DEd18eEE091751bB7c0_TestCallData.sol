/**
 *Submitted for verification at Arbiscan on 2023-03-08
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

contract TestCallData {
    event CalledWithData(bytes4 sig, bytes dataCalledWith);

    fallback() external {
        emit CalledWithData(msg.sig, msg.data);
    }
}