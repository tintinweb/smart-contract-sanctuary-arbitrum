// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
contract ChildChainFeesFactoryInterface {
    function createFees(address _pair) external returns (address fees) {}
}