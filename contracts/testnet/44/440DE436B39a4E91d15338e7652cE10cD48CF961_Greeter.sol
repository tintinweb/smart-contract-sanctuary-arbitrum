/**
 *Submitted for verification at Arbiscan on 2022-05-12
*/

contract Greeter {
    string private greeting;
    address owner;

    constructor(string memory _greeting) {
        greeting = _greeting;
        owner = msg.sender;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        require(msg.sender == owner, "not an owner!");
        greeting = _greeting;
    }
}