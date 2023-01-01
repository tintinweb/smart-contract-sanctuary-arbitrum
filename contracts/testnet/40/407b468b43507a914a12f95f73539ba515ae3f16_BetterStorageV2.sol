/**
 *Submitted for verification at Arbiscan on 2022-12-31
*/

pragma solidity ^0.8.7;

contract IBetterStorage {
    string public StoredValue;
}

/** 
 * @title improved version of 1_Storage.sol from Remix
 * @dev version 2
 * 
 * SPDX-License-Identifier: PolyForm-Small-Business-1.0.0
 */
contract BetterStorageV2 {
    string public StoredValue;
    address public Owner;
    address private OLD_CONTRACT_ADDRESS;
    IBetterStorage private OldContract;

    event StoredValueChanged(string indexed _oldValue, string indexed _newValue);

    constructor() {
        Owner = msg.sender;
        _updateAddressToOldContract(0x30fc388ED5C45A9Bd28C1c3A6E1771CE79B51F15);
        StoredValue = getDataFromTheOtherContract();
    }

    function setContractForDataImport(address _newAddress) external onlyOwner {
        _updateAddressToOldContract(_newAddress);
    }

    function _updateAddressToOldContract(address _newAddress) private {
        OLD_CONTRACT_ADDRESS = _newAddress;
        OldContract = IBetterStorage(OLD_CONTRACT_ADDRESS);
    }

    function getDataFromTheOtherContract() public view returns (string memory) {
        return OldContract.StoredValue();
    }

    modifier onlyOwner() {
        require (msg.sender == Owner, "peons and normies cannot do this highly coveted activity");
        _;
    }

    function setValue(string memory _newValue) public {
        emit StoredValueChanged(StoredValue, _newValue);
        StoredValue = _newValue;
    }
}