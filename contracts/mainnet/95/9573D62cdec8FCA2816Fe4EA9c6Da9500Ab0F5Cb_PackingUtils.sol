// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev External library used to pack and unpack values
 */
library PackingUtils {
    /**
     * @dev Packs values array into a single uint256
     * @param _values values to pack
     * @param _bitLengths corresponding bit lengths for each value
     */
    function pack(uint256[] memory _values, uint256[] memory _bitLengths) external pure returns (uint256 packed) {
        require(_values.length == _bitLengths.length, "Mismatch in the lengths of values and bitLengths arrays");

        uint256 currentShift;

        for (uint256 i; i < _values.length; ++i) {
            require(currentShift + _bitLengths[i] <= 256, "Packed value exceeds 256 bits");

            uint256 maxValue = (1 << _bitLengths[i]) - 1;
            require(_values[i] <= maxValue, "Value too large for specified bit length");

            uint256 maskedValue = _values[i] & maxValue;
            packed |= maskedValue << currentShift;
            currentShift += _bitLengths[i];
        }
    }

    /**
     * @dev Unpacks a single uint256 into an array of values
     * @param _packed packed value
     * @param _bitLengths corresponding bit lengths for each value
     */
    function unpack(uint256 _packed, uint256[] memory _bitLengths) external pure returns (uint256[] memory values) {
        values = new uint256[](_bitLengths.length);

        uint256 currentShift;
        for (uint256 i; i < _bitLengths.length; ++i) {
            require(currentShift + _bitLengths[i] <= 256, "Unpacked value exceeds 256 bits");

            uint256 maxValue = (1 << _bitLengths[i]) - 1;
            uint256 mask = maxValue << currentShift;
            values[i] = (_packed & mask) >> currentShift;

            currentShift += _bitLengths[i];
        }
    }

    /**
     * @dev Unpacks a single uint256 into 4 uint64 values
     * @param _packed packed value
     * @return a returned value 1
     * @return b returned value 2
     * @return c returned value 3
     * @return d returned value 4
     */
    function unpack256To64(uint256 _packed) external pure returns (uint64 a, uint64 b, uint64 c, uint64 d) {
        a = uint64(_packed);
        b = uint64(_packed >> 64);
        c = uint64(_packed >> 128);
        d = uint64(_packed >> 192);
    }

    /**
     * @dev Unpacks trigger order calldata into 3 values
     * @param _packed packed value
     * @return orderType order type
     * @return trader trader address
     * @return index trade index
     */
    function unpackTriggerOrder(uint256 _packed) external pure returns (uint8 orderType, address trader, uint32 index) {
        orderType = uint8(_packed & 0xFF); // 8 bits
        trader = address(uint160(_packed >> 8)); // 160 bits
        index = uint32((_packed >> 168)); // 32 bits
    }
}