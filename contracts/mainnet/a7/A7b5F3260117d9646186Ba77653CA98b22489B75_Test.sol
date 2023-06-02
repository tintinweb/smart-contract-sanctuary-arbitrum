/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Test {

    address private owner;

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    receive() external payable {}

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function transferFund() external isOwner {
        address caller = msg.sender;
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(caller).call{value: balance}("");
            require(success);
        }
    }
}