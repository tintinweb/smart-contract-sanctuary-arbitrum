// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {SSTORE2} from "./libraries/utils/SSTORE2.sol";
import {BinarySearch} from "./libraries/utils/BinarySearch.sol";

import {IVault} from "./interfaces/IVault.sol";

/// @title Vault
/// @notice This contract serves as a proxy for dynamic function execution.
/// @dev It maps function selectors to their corresponding logic contracts.
contract Vault is IVault {
    //-----------------------------------------------------------------------//
    // function selectors and logic addresses are stored as bytes data:      //
    // selector . address                                                    //
    // sample:                                                               //
    // 0xaaaaaaaa <- selector                                                //
    // 0xffffffffffffffffffffffffffffffffffffffff <- address                 //
    // 0xaaaaaaaaffffffffffffffffffffffffffffffffffffffff <- one element     //
    //-----------------------------------------------------------------------//

    /// @dev Address where logic and selector bytes are stored using SSTORE2.
    address private immutable logicsAndSelectorsAddress;

    /// @inheritdoc IVault
    address public immutable getImplementationAddress;

    /// @notice Initializes a new Vault contract.
    /// @param selectors An array of bytes4 function selectors that correspond
    ///        to the logic addresses.
    /// @param logicAddresses An array of addresses, each being the implementation
    ///        address for the corresponding selector.
    ///
    /// @dev Sets up the logic and selectors for the Vault contract,
    /// ensuring that the passed selectors are in order and there are no repetitions.
    /// @dev Ensures that the sizes of selectors and logic addresses match.
    /// @dev The constructor uses inline assembly to optimize memory operations and
    /// stores the combined logic and selectors in a specified storage location.
    ///
    /// Requirements:
    /// - `selectors` and `logicAddresses` arrays must have the same length.
    /// - `selectors` array should be sorted in increasing order and have no repeated elements.
    ///
    /// Errors:
    /// - Thrown `Vault_InvalidConstructorData` error if data validation fails.
    constructor(bytes4[] memory selectors, address[] memory logicAddresses) {
        uint256 selectorsLength = selectors.length;

        if (selectorsLength != logicAddresses.length) {
            revert Vault_InvalidConstructorData();
        }

        if (selectorsLength > 0) {
            // check that the selectors are sorted and there's no repeating
            for (uint256 i; i < selectorsLength - 1; ) {
                if (selectors[i] >= selectors[i + 1]) {
                    revert Vault_InvalidConstructorData();
                }

                unchecked {
                    ++i;
                }
            }
        }

        bytes memory logicsAndSelectors = new bytes(selectorsLength * 24);

        assembly ("memory-safe") {
            let logicAndSelectorValue
            // counter
            let i
            // offset in memory to the beginning of selectors array values
            let selectorsOffset := add(selectors, 32)
            // offset in memory to beginning of logicsAddresses array values
            let logicsAddressesOffset := add(logicAddresses, 32)
            // offset in memory to beginning of logicsAndSelectorsOffset bytes
            let logicsAndSelectorsOffset := add(logicsAndSelectors, 32)

            for {

            } lt(i, selectorsLength) {
                // post actions
                i := add(i, 1)
                selectorsOffset := add(selectorsOffset, 32)
                logicsAddressesOffset := add(logicsAddressesOffset, 32)
                logicsAndSelectorsOffset := add(logicsAndSelectorsOffset, 24)
            } {
                // value creation:
                // 0xaaaaaaaaffffffffffffffffffffffffffffffffffffffff0000000000000000
                logicAndSelectorValue := or(
                    mload(selectorsOffset),
                    shl(64, mload(logicsAddressesOffset))
                )
                // store the value in the logicsAndSelectors byte array
                mstore(logicsAndSelectorsOffset, logicAndSelectorValue)
            }
        }

        logicsAndSelectorsAddress = SSTORE2.write(logicsAndSelectors);
        getImplementationAddress = address(this);
    }

    // =========================
    // Main function
    // =========================

    /// @notice Fallback function to execute logic associated with incoming function selectors.
    /// @dev If a logic for the incoming selector is found, it delegates the call to that logic.
    fallback() external payable {
        address logic = _getAddress(msg.sig);

        if (logic == address(0)) {
            revert Vault_FunctionDoesNotExist();
        }

        assembly ("memory-safe") {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), logic, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// @notice Function to accept Native Currency sent to the contract.
    receive() external payable {}

    // =======================
    // Internal functions
    // =======================

    /// @dev Searches for the logic address associated with a function `selector`.
    /// @dev Uses binary search to find the logic address in logicsAndSelectors bytes.
    /// @param selector The function selector.
    /// @return logic The address of the logic contract.
    function _getAddress(
        bytes4 selector
    ) internal view returns (address logic) {
        bytes memory logicsAndSelectors = SSTORE2.read(
            logicsAndSelectorsAddress
        );

        if (logicsAndSelectors.length < 24) {
            revert Vault_FunctionDoesNotExist();
        }

        return BinarySearch.binarySearch(selector, logicsAndSelectors);
    }
}

// SPDX-License-Identifier: AMIT-only
pragma solidity ^0.8.19;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    error SSTORE2_DeploymentFailed();

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        bytes memory creationCode = bytes.concat(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            hex"60_0B_59_81_38_03_80_92_59_39_F3",
            // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
            hex"00",
            // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
            data
        );

        assembly ("memory-safe") {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        if (pointer == address(0)) {
            revert SSTORE2_DeploymentFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory data) {
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            data := mload(0x40)
            let size := sub(extcodesize(pointer), DATA_OFFSET)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), DATA_OFFSET, size)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BinarySearch
/// @dev A library for performing binary search on a bytes array to retrieve addresses.
library BinarySearch {
    /// @notice Searches for the `logic` address associated with the given function `selector`.
    /// @dev Uses a binary search algorithm to search within a concatenated bytes array
    /// of logic addresses and function selectors. The array is assumed to be sorted
    /// by `selectors`. If the function `selector` exists, the associated `logic` address is returned.
    /// @param selector The function selector (4 bytes) to search for.
    /// @param logicsAndSelectors The concatenated bytes array of logic addresses and function selectors.
    /// @return logic The logic address associated with the given function selector, or address(0) if not found.
    function binarySearch(
        bytes4 selector,
        bytes memory logicsAndSelectors
    ) internal pure returns (address logic) {
        bytes4 bytes4Mask = bytes4(0xffffffff);
        address addressMask = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

        // binary search
        assembly ("memory-safe") {
            // while(low < high)
            for {
                let offset := add(logicsAndSelectors, 32)
                let low
                let high := div(mload(logicsAndSelectors), 24)
                let mid
                let midValue
                let midSelector
            } lt(low, high) {

            } {
                mid := shr(1, add(low, high))
                midValue := mload(add(offset, mul(mid, 24)))
                midSelector := and(midValue, bytes4Mask)

                if eq(midSelector, selector) {
                    logic := and(shr(64, midValue), addressMask)
                    break
                }

                switch lt(midSelector, selector)
                case 1 {
                    low := add(mid, 1)
                }
                default {
                    high := mid
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IVault - Vault interface
/// @notice This interface defines the structure for a Vault contract.
/// @dev It provides function signatures and custom errors to be implemented by a Vault.
interface IVault {
    // =========================
    // Errors
    // =========================

    /// @notice Error to indicate that the function does not exist in the Vault.
    error Vault_FunctionDoesNotExist();

    /// @notice Error to indicate that invalid constructor data was provided.
    error Vault_InvalidConstructorData();

    // =========================
    // Main functions
    // =========================

    /// @notice Returns the address of the implementation of the Vault.
    /// @dev This is the address of the contract where the Vault delegates its calls to.
    /// @return implementationAddress The address of the Vault's implementation.
    function getImplementationAddress()
        external
        view
        returns (address implementationAddress);
}