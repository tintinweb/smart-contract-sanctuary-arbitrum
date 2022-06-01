/**
 *Submitted for verification at Arbiscan on 2022-05-31
*/

pragma solidity ^0.8.0;

// test(123)
// 0x29e99f07000000000000000000000000000000000000000000000000000000000000007b
contract SelfCallContract {
    uint public counter = 0;

    fallback () external payable {}

    function callself(address target, bytes calldata data) payable external {
        (bool success, ) = target.call{value: msg.value}(data);
    }

    function test(uint number) external {
        require(msg.sender == address(this), "Not internal call");
        counter = number;
    }
}