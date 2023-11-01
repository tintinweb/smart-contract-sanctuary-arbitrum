// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract CryptoWorldRule {
    event RuleMessage(string message);

    function ruleTheWorld() public {
        emit RuleMessage("Crypto will rule this world");
    }
}