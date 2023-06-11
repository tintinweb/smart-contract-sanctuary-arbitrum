/**
 *Submitted for verification at Arbiscan on 2023-06-11
*/

// SPDX-License-Identifier: MIT
// creates pool and gauge seamlessly.
pragma solidity ^0.8.16;

interface IFactory {
    function createPool(
        address _tokenA,
        address _tokenB,
        uint24 _fee
    ) external;
}

interface IVoter {
    function createCLGauge(
        address _tokenA,
        address _tokenB,
        uint24 _fee
    ) external;
}

contract RamsesInitializationHelper {
    address public clFactory = 0xAA2cd7477c451E703f3B9Ba5663334914763edF8;
    address public voterAddress = 0xAAA2564DEb34763E3d05162ed3f5C2658691f499;

    IFactory factory = IFactory(clFactory);
    IVoter voter = IVoter(voterAddress);

    function init(
        address _A,
        address _B,
        uint24 _fee
    ) external {
        factory.createPool(_A, _B, _fee);
        voter.createCLGauge(_A, _B, _fee);
    }
}