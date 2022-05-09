/**
 *Submitted for verification at Arbiscan on 2022-05-09
*/

contract MyContract {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
}