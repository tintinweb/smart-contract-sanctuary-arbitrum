/**
 *Submitted for verification at Arbiscan.io on 2024-06-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

contract Rescuer {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function withdrawEther(address recipient) public onlyOwner {
        payable(address(recipient)).transfer(address(this).balance);
    }

    function withdrawTokens(address token, address recipient) public onlyOwner {
        uint balance = getTokenBalance(token);
        safeTransfer(token, recipient, balance);
    }

    function getTokenBalance(address token) internal view returns (uint) {
        // bytes4(keccak256(bytes('balanceOf(address)')));
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231, address(this)));
        require(success && data.length >= 32, 'BALANCE_QUERY_FAILED');
        return abi.decode(data, (uint));
    }
}