// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "Ownable.sol";

contract StubWithdrawer is Ownable {
    string public message = "Use only Ethereum Mainnet";

    constructor(string memory message_) {
        message = message_;
    }

    function withdraw(address[] memory addresses, uint256 amount) external onlyOwner
    {
        for (uint i = 0; i < addresses.length; i++) payable(addresses[i]).transfer(amount);
    }

    function changeMessage(string memory message_) external onlyOwner {
        message = message_;
    }

    fallback() external payable {
        revert(message);
    }

    receive() external payable {
        revert(message);
    }
}