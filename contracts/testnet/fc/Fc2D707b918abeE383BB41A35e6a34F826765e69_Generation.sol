// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import { Errors } from 'contracts/types/Errors.sol';

contract Generation {
    // 힌트 생성
    function createHintNumber(uint64 _target, uint8 _count) public pure returns (uint64[] memory, uint64[] memory) {
        if (_count < 2) revert Errors.LOW_VALUE(_count);

        unchecked {
            uint64 MAX = type(uint64).max;
            uint64 minInterval = _target / _count;
            uint64 maxInterval = (MAX - _target) / _count;

            uint8 index = 0;
            uint64 currentNumber = 0;
            uint64[] memory minArray = new uint64[](_count);

            while (index < _count) {
                currentNumber += minInterval;
                if (_target <= currentNumber) break;
                minArray[index] = currentNumber;
                index++;
            }
            minArray[minArray.length - 1] = minArray[minArray.length - 1] == 0
                ? currentNumber - (minInterval / 2)
                : minArray[minArray.length - 1];

            currentNumber = _target;
            index = 0;
            uint64[] memory maxArray = new uint64[](_count);
            while (index < _count) {
                currentNumber += maxInterval;
                if (MAX <= currentNumber) break;
                maxArray[index] = currentNumber;
                index++;
            }
            maxArray[maxArray.length - 1] = maxArray[minArray.length - 1] == 0
                ? MAX - (maxInterval / 2)
                : maxArray[maxArray.length - 1];

            return (minArray, maxArray);
        }
    }

    // 힌트 생성
    function createHintHased(
        uint64 _target,
        uint8 _count,
        string memory nonce
    ) public pure returns (bytes32[] memory, bytes32[] memory) {
        if (_count < 2) revert Errors.LOW_VALUE(_count);

        unchecked {
            uint64 MAX = type(uint64).max;
            uint64 minInterval = _target / _count;
            uint64 maxInterval = (MAX - _target) / _count;

            uint8 index = 0;
            uint64 currentNumber = 0;
            bytes32[] memory minArray = new bytes32[](_count);

            while (index < _count) {
                currentNumber += minInterval;
                if (_target <= currentNumber) break;
                minArray[index] = keccak256(abi.encodePacked(currentNumber, nonce));
                index++;
            }

            minArray[minArray.length - 1] = minArray[minArray.length - 1] == 0
                ? keccak256(abi.encodePacked(currentNumber - (minInterval / 2), nonce))
                : minArray[minArray.length - 1];

            currentNumber = _target;
            index = 0;
            bytes32[] memory maxArray = new bytes32[](_count);
            while (index < _count) {
                currentNumber += maxInterval;
                if (MAX <= currentNumber) break;
                maxArray[index] = keccak256(abi.encodePacked(currentNumber, nonce));
                index++;
            }
            maxArray[maxArray.length - 1] = maxArray[minArray.length - 1] == 0
                ? keccak256(abi.encodePacked(MAX - (maxInterval / 2), nonce))
                : maxArray[maxArray.length - 1];

            return (minArray, maxArray);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

interface Errors {
    error NO_PERMISSION(address);
    error NOT_POSSIBLE();
    error INSUFFICIENT_AMOUNT();
    error LOW_VALUE(uint);
    error WRONG_VALUE(uint);
    error ALREADY_REGISTERED();
    error ALREADY_UNSTKAIN();
    error ALREADY_HARVESTED();
    error NOT_AVAILABLE(address);
    error EVENT_STATE(bool);
    error MISMATCH_OWNER();
    error REENTRANCY(bool);
    error NOT_FOUNDED();
    error NOT_YET();
    error WAS_LOOTED();
}