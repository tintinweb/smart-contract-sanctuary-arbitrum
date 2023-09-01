/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract AdvancedEventEmitter {

    // ------------------------------------------------------------------
    // uint256

    event Uint256_Event();
    event Uint256_Event(uint256 indexed a, uint256 indexed b, uint256 indexed c);

    function emitUint256Empty() external {
        emit Uint256_Event();
    }
    function emitUint256(uint256 a, uint256 b, uint256 c) external {
        emit Uint256_Event(a, b, c);
    }

    // ------------------------------------------------------------------
    // Address

    event Address_Event();
    event Address_Event(address indexed a, address indexed b, address indexed c);

    function emitAddressEmpty() external {
        emit Address_Event();
    }
    function emitAddress(address a, address b, address c) external {
        emit Address_Event(a, b, c);
    }

    // ------------------------------------------------------------------
    // Bytes

    event Bytes_Event();
    event Bytes_Event(bytes indexed a, bytes indexed b, bytes indexed c);

    function emitBytesEmpty() external {
        emit Bytes_Event();
    }
    function emitBytes(bytes memory a, bytes memory b, bytes memory c) external {
        emit Bytes_Event(a, b, c);
    }

    // ------------------------------------------------------------------
    // Bool

    event Bool_Event();
    event Bool_Event(bool indexed a, bool indexed b, bool indexed c);

    function emitBoolEmpty() external {
        emit Bool_Event();
    }
    function emitBool(bool a, bool b, bool c) external {
        emit Bool_Event(a, b, c);
    }

    // ------------------------------------------------------------------
    // AddressArray

    event AddressArray_Event();
    event AddressArray_Event(address[] indexed a, address[] indexed b, address[] indexed c);

    function emitAddressArrayEmpty() external {
        emit AddressArray_Event();
    }
    function emitAddressArray(address[] memory a, address[] memory b, address[] memory c) external {
        emit AddressArray_Event(a, b, c);
    }

    // ------------------------------------------------------------------
    // Mixed

    event Mixed_Event(address indexed a, uint256 indexed b, bool indexed c);

    function emitMixed(address from, uint256 amount, bool flag) external {
        emit Mixed_Event(from, amount, flag);
    }

    // ------------------------------------------------------------------
    // Mixed

    event Mixed_Event2(string indexed a, bytes indexed b, bytes8 indexed c);

    function emitMixed(string memory a, bytes memory b, bytes8 c) external {
        emit Mixed_Event2(a, b, c);
    }
}