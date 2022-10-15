/**
 *Submitted for verification at Arbiscan on 2022-10-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.13;

interface IArbAddressTable {
    // Register an address in the address table
    // Return index of the address (existing index, or newly created index if not already registered)
    function register(address addr) external returns (uint256);

    // Return index of an address in the address table (revert if address isn't in the table)
    function lookup(address addr) external view returns (uint256);

    // Check whether an address exists in the address table
    function addressExists(address addr) external view returns (bool);

    // Get size of address table (= first unused index)
    function size() external view returns (uint256);

    // Return address at a given index in address table (revert if index is beyond end of table)
    function lookupIndex(uint256 index) external view returns (address);

    // Read a compressed address from a bytes buffer
    // Return resulting address and updated offset into the buffer (revert if buffer is too short)
    function decompress(bytes calldata buf, uint256 offset)
        external
        pure
        returns (address, uint256);

    // Compress an address and return the result
    function compress(address addr) external returns (bytes memory);
}

contract optimismCompress {
    IArbAddressTable public immutable addressRegistry = IArbAddressTable(0x0000000000000000000000000000000000000066);

    function sendData(address addy, uint256 num1, uint256 num2) external {
        return;
    }

    fallback() external { 
        address addy;
        uint256 num1;
        uint256 num2;

        uint256 addyID = uint24(bytes3(msg.data[:3]));
        addy = addressRegistry.lookupIndex(addyID);

        num1 = uint256(bytes32(msg.data[3:6]));
        num1 = uint256(bytes32(msg.data[6:9]));
    }
}