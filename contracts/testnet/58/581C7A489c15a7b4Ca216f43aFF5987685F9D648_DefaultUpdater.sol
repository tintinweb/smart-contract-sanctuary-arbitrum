// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IProxyUpdater
 * @notice Interface that must be inherited by each proxy updater. Contracts that
           inherit from this interface are meant to be set as the implementation of a proxy during
           an upgrade, then delegatecalled by the proxy's owner to change the value of a storage
           slot within the proxy.
 */
interface IProxyUpdater {
    /**
     * @notice Sets a proxy's storage slot value at a given storage slot key and offset.
     *
     * @param _key     Storage slot key to modify.
     * @param _offset  Bytes offset of the new storage slot value from the right side of the storage
       slot. An offset of 0 means the new value will start at the right-most byte of the storage
       slot.
     * @param _value New value of the storage slot at the given key and offset. The length of the
                     value is in the range [1, 32] (inclusive).
     */
    function setStorage(bytes32 _key, uint8 _offset, bytes memory _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ProxyUpdater } from "./ProxyUpdater.sol";

/**
 * @title DefaultUpdater
 * @notice Proxy updater that works with Transparent proxies, including the default Proxy contracts
   used in the Sphinx system.
 */
contract DefaultUpdater is ProxyUpdater {
    /**
     * @notice The storage slot that holds the address of the owner.
     *         bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
     */
    bytes32 internal constant OWNER_KEY =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @notice A modifier that reverts if not called by the owner or by address(0) to allow
     *         eth_call to interact with this proxy without needing to use low-level storage
     *         inspection. We assume that nobody is able to trigger calls from address(0) during
     *         normal EVM execution.
     */
    modifier ifAdmin() {
        require(
            msg.sender == _getAdmin() || msg.sender == address(0),
            "DefaultUpdater: caller is not admin"
        );
        _;
    }

    /**
     * Only callable by the owner.
     * @inheritdoc ProxyUpdater
     */
    function setStorage(bytes32 _key, uint8 _offset, bytes memory _value) public override ifAdmin {
        super.setStorage(_key, _offset, _value);
    }

    /**
     * @notice Queries the owner of the proxy contract.
     *
     * @return Owner address.
     */
    function _getAdmin() internal view returns (address) {
        address owner;
        assembly {
            owner := sload(OWNER_KEY)
        }
        return owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IProxyUpdater } from "../interfaces/IProxyUpdater.sol";

/**
 * @title ProxyUpdater
 * @notice An abstract contract for setting storage slot values within a proxy at a given storage
        slot key and offset.
 */
abstract contract ProxyUpdater is IProxyUpdater {
    /**
     * @notice Sets a proxy's storage slot value at a given storage slot key and offset. Note that
       this will thrown an error if the length of the storage slot value plus the offset (both in
       bytes) is greater than 32.
     *
     *         To illustrate how this function works, consider the following example. Say we call
     *         this function on some storage slot key with the input parameters:
     *         `_offset = 2`
     *         `_value = 0x22222222`
     *
     *         Say the storage slot value prior to calling this function is:
     *         0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
     *
     *         This function works by creating a bit mask at the location of the value, which in
     *         this case is at an `offset` of 2 and is 4 bytes long (extending left from the
     *         offset). The bit mask would be:
     *         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFF
     *
     *         Applying this bit mask to the existing slot value, we get:
     *         0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC00000000CCCC
     *
     *         Then, we offset the new value to the correct location in the storage slot:
     *         0x0000000000000000000000000000000000000000000000000000222222220000
     *
     *         Lastly, add these two values together to get the new storage slot value:
     *         0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC22222222CCCC
     *
     * @param _key     Storage slot key to modify.
     * @param _offset  Bytes offset of the new storage slot value from the right side of the storage
       slot. An offset of 0 means the new value will start at the right-most byte of the storage
       slot.
     * @param _value New value of the storage slot at the given key and offset. The length of the
                     value is in the range [1, 32] bytes (inclusive).
     */
    function setStorage(bytes32 _key, uint8 _offset, bytes memory _value) public virtual {
        require(_value.length <= 32, "ProxyUpdater: value is too large");

        bytes32 valueBytes32 = bytes32(_value);

        // If the length of the new value equals the size of the storage slot, we can just replace
        // the entire slot value.
        if (_value.length == 32) {
            assembly {
                sstore(_key, valueBytes32)
            }
        } else {
            // Load the existing storage slot value.
            bytes32 currVal;
            assembly {
                currVal := sload(_key)
            }

            // Convert lengths from bytes to bits. Makes calculations easier to read.
            uint256 valueLengthBits = _value.length * 8;
            uint256 offsetBits = _offset * 8;

            // Create a bit mask that will set the values of the existing storage slot to 0 at the
            // location of the new value. It's worth noting that the expresion:
            // `(2 ** (valueLengthBits) - 1)` would revert if `valueLengthBits = 256`. However,
            // this will never happen because values of length 32 are set directly in the
            // if-statement above.
            uint256 mask = ~((2 ** (valueLengthBits) - 1) << offsetBits);

            // Apply the bit mask to the existing storage slot value.
            bytes32 maskedCurrVal = bytes32(mask) & currVal;

            // Calculate the offset of the value from the left side of the storage slot.
            // Denominated in bits for consistency.
            uint256 leftOffsetBits = 256 - offsetBits - valueLengthBits;

            // Shift the value right so that it's aligned with the bitmasked location.
            bytes32 rightShiftedValue = (valueBytes32 >> leftOffsetBits);

            // Create the new storage slot value by adding the bit masked slot value to the new
            // value.
            uint256 newVal = uint256(maskedCurrVal) + uint256(rightShiftedValue);

            // Set the new value of the storage slot.
            assembly {
                sstore(_key, newVal)
            }
        }
    }
}