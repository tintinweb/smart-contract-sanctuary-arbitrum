/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

pragma solidity ^0.4.11;

contract Token {
    function transfer(address to, uint256 value) public returns (bool);
}

contract Multisender {
    function multisend(address tokenAddr, address[] to, uint256[] value) public returns (bool) {
        require(to.length == value.length && to.length <= 1000);

        for (uint i = 0; i < to.length; i++) {
            require(Token(tokenAddr).transfer(to[i], value[i] * 10**18));
        }

        return true;
    }
}