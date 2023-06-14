/**
 *Submitted for verification at Arbiscan on 2023-06-13
*/

// SPDX-License-Identifier: None

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.8.9;

// Defines a contract named `HelloWorld`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract ScoreRegistry {

    struct ScoreData {
        address userAddress;
        uint256 score;
        string message;
    }
   //Emitted when update function is called
   //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
    event ScoreUpdated(address indexed userAddress, uint256 score, string message);

   // Declares a state variable `message` of type `string`.
   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
    mapping(address => ScoreData) public scores;
    address public owner;

   // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
   // Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
   constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function addScore(address _userAddress, uint256 _score,string memory _message) public onlyOwner {
        scores[_userAddress] = ScoreData(_userAddress, _score, _message);
        emit ScoreUpdated(_userAddress, _score, _message);
    }
}