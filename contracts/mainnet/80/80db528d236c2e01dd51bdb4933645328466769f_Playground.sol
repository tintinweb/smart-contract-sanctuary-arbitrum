/**
 *Submitted for verification at Arbiscan.io on 2024-06-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.6;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}

contract Playground {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function withdrawEther(address recipient) public onlyOwner {
        payable(address(recipient)).transfer(address(this).balance);
    }

    function withdrawTokens(address token, address recipient) public onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        safeTransfer(token, recipient, balance);
    }
}