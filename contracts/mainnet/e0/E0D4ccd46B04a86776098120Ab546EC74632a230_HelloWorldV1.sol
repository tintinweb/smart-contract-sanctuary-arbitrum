pragma solidity ^0.8.0;

contract HelloWorldV1 {
    string public text;

    constructor() {}

    function setText(string memory _newText) public {
        text = _newText;
    }
}