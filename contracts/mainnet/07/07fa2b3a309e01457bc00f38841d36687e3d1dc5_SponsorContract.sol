/**
 *Submitted for verification at Arbiscan.io on 2024-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract SponsorContract {
    address owner;
    mapping(address => bool) public paymasters;

    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict certain functions to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Function for the owner to register paymasters
    function addPaymaster(address _paymaster) public onlyOwner {
        paymasters[_paymaster] = true;
    }

    // Function to remove a paymaster
    function removePaymaster(address _paymaster) public onlyOwner {
        paymasters[_paymaster] = false;
    }

    // Function to sponsor a transaction
    function sponsorTransaction(address payable _to, uint _value, bytes memory _data, uint _gasLimit) public payable {
        require(paymasters[msg.sender], "Not a registered paymaster");

        // Initial gas available
        uint initialGas = gasleft();

        // This will perform the call with the specified value and data
        (bool success, ) = _to.call{value: _value, gas: _gasLimit}(_data);
        require(success, "Transaction failed");

        // Calculate the gas used and the total cost
        uint gasUsed = initialGas - gasleft() + _gasLimit;
        uint gasCost = gasUsed * tx.gasprice;

        // Refund the paymaster for the gas used in ETH
        payable(msg.sender).transfer(gasCost);
    }

    // Function to receive ETH
    receive() external payable {}
}