/**
 *Submitted for verification at Arbiscan on 2022-11-09
*/

contract Whitelist {
    event Whitelisted(address indexed addr);
    receive() payable external {
        require(msg.value == 0);
        emit Whitelisted(msg.sender);
    }
}