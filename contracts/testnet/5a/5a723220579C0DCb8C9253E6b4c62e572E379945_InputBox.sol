// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

/// @title Canonical Machine Constants Library
///
/// @notice Defines several constants related to the reference implementation
/// of the RISC-V machine that runs Linux, also known as the "Cartesi Machine".
library CanonicalMachine {
    /// @notice Base-2 logarithm of number of bytes.
    type Log2Size is uint64;

    /// @notice Machine word size (8 bytes).
    Log2Size constant WORD_LOG2_SIZE = Log2Size.wrap(3);

    /// @notice Machine address space size (2^64 bytes).
    Log2Size constant MACHINE_LOG2_SIZE = Log2Size.wrap(64);

    /// @notice Keccak-256 output size (32 bytes).
    Log2Size constant KECCAK_LOG2_SIZE = Log2Size.wrap(5);

    /// @notice Maximum input size (32 megabytes).
    Log2Size constant INPUT_MAX_LOG2_SIZE = Log2Size.wrap(25);

    /// @notice Maximum voucher metadata memory range (2 megabytes).
    Log2Size constant VOUCHER_METADATA_LOG2_SIZE = Log2Size.wrap(21);

    /// @notice Maximum notice metadata memory range (2 megabytes).
    Log2Size constant NOTICE_METADATA_LOG2_SIZE = Log2Size.wrap(21);

    /// @notice Maximum epoch voucher memory range (128 megabytes).
    Log2Size constant EPOCH_VOUCHER_LOG2_SIZE = Log2Size.wrap(37);

    /// @notice Maximum epoch notice memory range (128 megabytes).
    Log2Size constant EPOCH_NOTICE_LOG2_SIZE = Log2Size.wrap(37);

    /// @notice Unwrap `s` into its underlying uint64 value.
    /// @param s Base-2 logarithm of some number of bytes
    function uint64OfSize(Log2Size s) internal pure returns (uint64) {
        return Log2Size.unwrap(s);
    }

    /// @notice Return the position of an intra memory range on a memory range
    ///         with contents with the same size.
    /// @param index Index of intra memory range
    /// @param log2Size Base-2 logarithm of intra memory range size
    function getIntraMemoryRangePosition(
        uint64 index,
        Log2Size log2Size
    ) internal pure returns (uint64) {
        return index << Log2Size.unwrap(log2Size);
    }
}

// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

/// @title Input Box interface
interface IInputBox {
    /// @notice Emitted when an input is added to a DApp's input box.
    /// @param dapp The address of the DApp
    /// @param inboxInputIndex The index of the input in the input box
    /// @param sender The address that sent the input
    /// @param input The contents of the input
    /// @dev MUST be triggered on a successful call to `addInput`.
    event InputAdded(
        address indexed dapp,
        uint256 indexed inboxInputIndex,
        address sender,
        bytes input
    );

    /// @notice Add an input to a DApp's input box.
    /// @param _dapp The address of the DApp
    /// @param _input The contents of the input
    /// @return The hash of the input plus some extra metadata
    /// @dev MUST fire an `InputAdded` event accordingly.
    function addInput(
        address _dapp,
        bytes calldata _input
    ) external returns (bytes32);

    /// @notice Get the number of inputs in a DApp's input box.
    /// @param _dapp The address of the DApp
    /// @return Number of inputs in the DApp's input box
    function getNumberOfInputs(address _dapp) external view returns (uint256);

    /// @notice Get the hash of an input in a DApp's input box.
    /// @param _dapp The address of the DApp
    /// @param _index The index of the input in the DApp's input box
    /// @return The hash of the input at the provided index in the DApp's input box
    /// @dev `_index` MUST be in the interval `[0,n)` where `n` is the number of
    ///      inputs in the DApp's input box. See the `getNumberOfInputs` function.
    function getInputHash(
        address _dapp,
        uint256 _index
    ) external view returns (bytes32);
}

// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

import {IInputBox} from "./IInputBox.sol";
import {LibInput} from "../library/LibInput.sol";

/// @title Input Box
///
/// @notice Trustless and permissionless contract that receives arbitrary blobs
/// (called "inputs") from anyone and adds a compound hash to an append-only list
/// (called "input box"). Each DApp has its own input box.
///
/// The hash that is stored on-chain is composed by the hash of the input blob,
/// the block number and timestamp, the input sender address, and the input index.
///
/// Data availability is guaranteed by the emission of `InputAdded` events
/// on every successful call to `addInput`. This ensures that inputs can be
/// retrieved by anyone at any time, without having to rely on centralized data
/// providers.
///
/// From the perspective of this contract, inputs are encoding-agnostic byte
/// arrays. It is up to the DApp to interpret, validate and act upon inputs.
contract InputBox is IInputBox {
    /// @notice Mapping from DApp address to list of input hashes.
    /// @dev See the `getNumberOfInputs`, `getInputHash` and `addInput` functions.
    mapping(address => bytes32[]) internal inputBoxes;

    function addInput(
        address _dapp,
        bytes calldata _input
    ) external override returns (bytes32) {
        bytes32[] storage inputBox = inputBoxes[_dapp];
        uint256 inboxInputIndex = inputBox.length;

        bytes32 inputHash = LibInput.computeInputHash(
            msg.sender,
            block.number,
            block.timestamp,
            _input,
            inboxInputIndex
        );

        // add input to correct inbox
        inputBox.push(inputHash);

        // block.number and timestamp can be retrieved by the event metadata itself
        emit InputAdded(_dapp, inboxInputIndex, msg.sender, _input);

        return inputHash;
    }

    function getNumberOfInputs(
        address _dapp
    ) external view override returns (uint256) {
        return inputBoxes[_dapp].length;
    }

    function getInputHash(
        address _dapp,
        uint256 _index
    ) external view override returns (bytes32) {
        return inputBoxes[_dapp][_index];
    }
}

// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

import {CanonicalMachine} from "../common/CanonicalMachine.sol";

/// @title Input Library
library LibInput {
    using CanonicalMachine for CanonicalMachine.Log2Size;

    /// @notice Summarize input data in a single hash.
    /// @param sender `msg.sender`
    /// @param blockNumber `block.number`
    /// @param blockTimestamp `block.timestamp`
    /// @param input The input blob
    /// @param inboxInputIndex The index of the input in the input box
    /// @return The input hash
    function computeInputHash(
        address sender,
        uint256 blockNumber,
        uint256 blockTimestamp,
        bytes calldata input,
        uint256 inboxInputIndex
    ) internal pure returns (bytes32) {
        // Currently sending an input larger than driveSize surpasses the block gas limit
        // But we keep the following check in case this changes in the future
        require(
            input.length <=
                (1 << CanonicalMachine.INPUT_MAX_LOG2_SIZE.uint64OfSize()),
            "input len: [0,driveSize]"
        );

        bytes32 keccakMetadata = keccak256(
            abi.encode(
                sender,
                blockNumber,
                blockTimestamp,
                0, //TODO decide how to deal with epoch index
                inboxInputIndex // input index in the input box
            )
        );

        bytes32 keccakInput = keccak256(input);

        return keccak256(abi.encode(keccakMetadata, keccakInput));
    }
}