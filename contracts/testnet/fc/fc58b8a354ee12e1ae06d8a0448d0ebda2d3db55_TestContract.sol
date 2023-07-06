/**
 *Submitted for verification at Arbiscan on 2023-07-05
*/

pragma solidity ^0.8.0;

contract TestContract {
    // Define the custom type
    struct testType {
        uint256 id;
        string name;
    }

    // Define an instance of the custom type
    testType public myTest;

    // Event that emits when a write operation is performed
    event WriteEvent(testType indexed _data);

    // Function to perform a write operation on the custom type
    function writeToTest(uint256 _id, string memory _name) public {
        myTest = testType(_id, _name);
        emit WriteEvent(myTest);
    }

    // Function to retrieve the current value of the custom type
    function readFromTest() public view returns (testType memory) {
        return myTest;
    }
}