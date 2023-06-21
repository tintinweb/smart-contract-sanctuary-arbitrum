// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC677 {
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);
}

contract MaliciousReceiver {
    address private _tokenContract;
    uint256 numCalls = 5;

    function onTokenTransfer(address _sender, uint256 _value, bytes memory _data) external {
        // Perform malicious actions here
        // For example, attempt to transfer tokens from the token contract
        IERC677 token = IERC677(_tokenContract);
        for (uint256 call = 0; call <= numCalls; call++) {
            token.transferAndCall(msg.sender, _value, _data);
        }
    }

    function setTokenContract(address tokenContract) external {
        _tokenContract = tokenContract;
    }
}