// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract Vault {

    /// ███ Storages █████████████████████████████████████████████████████████

    string  public name;
    uint256 public value;
    address public owner;


    /// ███ Storage initializer ██████████████████████████████████████████████

    function initialize(address _owner, string memory _name) external {
        owner = _owner;
        name = _name;
    }


    /// ███ Actions ██████████████████████████████████████████████████████████

    function setValue(uint256 _value) external {
        value = _value;
    }
}