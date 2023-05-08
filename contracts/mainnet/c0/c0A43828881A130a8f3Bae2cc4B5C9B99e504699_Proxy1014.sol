/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity <=0.8.17;

contract Proxy1014 {
    fallback(bytes calldata data) payable external returns(bytes memory){
        (bool r1, bytes memory result) = address(0xe8a78423BD38ac8314af0218942e4483a12Ec808).delegatecall(data);
        require(r1, "Locked Item");
        return result;
    }

    receive() payable external {
    }
}