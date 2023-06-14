/**
 *Submitted for verification at Arbiscan on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IVulnerableContract {
    function callContract(address yourAddress) external returns (bool);
    function callContractAgain(address yourAddress, bytes4 selector) external returns (bool);
}

contract OtherContract {
    uint256 public s_variable;
    address public owner;
    IVulnerableContract public vulnerableContract;

    constructor(address _vulnerableContractAddress) {
        owner = msg.sender;
        vulnerableContract = IVulnerableContract(_vulnerableContractAddress);
    }

    function doSomething() public {
        s_variable = 123;
    }

    function callVulnerableContract() public {
        vulnerableContract.callContract(address(this));
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}