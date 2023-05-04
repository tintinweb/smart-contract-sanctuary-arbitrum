// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Create Call - Allows to use the different create opcodes to deploy a contract
/// @author Richard Meissner - <[email protected]>
contract CreateCall {
    event ContractCreation(address newContract);

    function performCreate2(
        uint256 value,
        bytes memory deploymentData,
        bytes32 salt
    ) public payable returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create2(value, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);
    }

    function performCreate(uint256 value, bytes memory deploymentData) public returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create(value, add(deploymentData, 0x20), mload(deploymentData))
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

error GreeterError();

contract Greeter {
    string public greeting;
    bool public flag;
    uint256 public number;

    constructor(string memory _greeting) payable {
        greeting = _greeting;
    }

    function randomstringwithhorsesthatetherscancannotguess() public view returns (string memory) {
        return greeting;
    }

    // function randomstringwithhorsesthatetherscancannotguess2() public pure returns (uint256) {
    //     uint256 x = 1;
    //     uint256 y = x.add(1);
    //     return y;
    // }

    // function func1() public pure returns (uint128) {
    //     uint128 x = 1;
    //     uint128 y = x.add(1);
    //     return y;
    // }

    // function func2() public pure returns (uint128) {
    //     uint128 x = 1;
    //     uint128 y = x.add(1);
    //     return y;
    // }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function throwError() external pure {
        revert GreeterError();
    }
}