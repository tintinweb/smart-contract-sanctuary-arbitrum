/**
 *Submitted for verification at Arbiscan on 2022-12-31
*/

pragma solidity ^0.8.7;

/** 
 * @title improved version of 1_Storage.sol
 * 
 * SPDX-License-Identifier: PolyForm-Small-Business-1.0.0
 */
contract BetterStorage {
    string public StoredValue;

    constructor(string memory _initialValue) {
        StoredValue = _initialValue;
    }

    function setValue(string memory _newValue) public {
        StoredValue = _newValue;
    }
}