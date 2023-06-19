// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Verifier {
    address public immutable firstInput;
    address public immutable secondInput;
    uint256 public number;

    constructor(address _firstInput, address _secondInput) {
        if (_firstInput == address(0)) revert ZeroAddress();
        if (_secondInput == address(0)) revert ZeroAddress();
        firstInput = _firstInput;
        secondInput = _secondInput;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function selfDestruct() public {
        selfdestruct(payable(msg.sender));
    }

    error ZeroAddress();
}