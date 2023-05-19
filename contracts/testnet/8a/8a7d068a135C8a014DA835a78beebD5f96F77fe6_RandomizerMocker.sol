/**
 *Submitted for verification at Arbiscan on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// // Randomizer protocol interface
// interface IRandomizer {
//     function request(uint256 callbackGasLimit) external returns (uint256);
//     function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
//     function clientWithdrawTo(address _to, uint256 _amount) external;
// }

interface ICaller {
    function randomizerCallback(uint256 _id, bytes32 _value) external;
}

contract RandomizerMocker {
    uint256 public requestId = 100;

    function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256) {
        requestId++;
        return requestId;
    }

    function mockRandomizerCallback(uint256 _requestId, address callerAddress, uint256 mockResult) external{
        bytes32 random = bytes32(mockResult);
        ICaller(callerAddress).randomizerCallback(_requestId, random);
    }

}