/**
 *Submitted for verification at Arbiscan on 2023-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FairLaunch {
    string public name = "FairLaunch";
    string public symbol = "FL";
    uint256 public totalSupply = 10000000 * 10**18; // 10 million FL tokens, assuming 18 decimal places precision

    mapping(address => uint256) public balances;
    mapping(address => bool) public isAuthorized;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function getAirdropAmount(address wallet) public view returns (uint256) {
        if (balances[wallet] == 0 || !isAuthorized[msg.sender]) {
            return 0; // Wallet is not eligible for airdrop or server is not authorized
        }

        return balances[wallet];
    }

    function claimAirdrop() public {
        require(balances[msg.sender] > 0 && isAuthorized[msg.sender], "Not eligible for airdrop or unauthorized");

        uint256 airdropAmount = balances[msg.sender];
        balances[msg.sender] = 0;
        totalSupply -= airdropAmount;

        // Emit an event with the airdrop details
        emit AirdropClaimed(msg.sender, airdropAmount, totalSupply);
    }

    function authorizeServer(address server) public {
        require(!isAuthorized[server], "Server is already authorized");

        isAuthorized[server] = true;
    }

    event AirdropClaimed(address indexed wallet, uint256 amount, uint256 remainingSupply);
}