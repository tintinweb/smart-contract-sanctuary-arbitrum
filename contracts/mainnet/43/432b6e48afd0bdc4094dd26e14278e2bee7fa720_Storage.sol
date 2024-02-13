/**
 *Submitted for verification at Arbiscan.io on 2024-02-12
*/

pragma solidity 0.8.4;

contract Storage {
    mapping(address => bool) whitelist;

    function storeAddr(address[] calldata addrs) public {
        for (uint256 i; i < addrs.length; i++) {
            whitelist[addrs[i]] = true;
        }
    }
}