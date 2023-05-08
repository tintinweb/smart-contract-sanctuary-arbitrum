/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT
interface IToken {
    function transfer(address to, uint256 value) external returns (bool);
}

contract Airdrop {
    function multisend(address tokenAddr, address[] memory to, uint256[] memory value) public {
        require(to.length == value.length && to.length <= 2000);

        for (uint i = 0; i < to.length; i++) {
            require(IToken(tokenAddr).transfer(to[i], value[i] *10**18));
        }
    }
}