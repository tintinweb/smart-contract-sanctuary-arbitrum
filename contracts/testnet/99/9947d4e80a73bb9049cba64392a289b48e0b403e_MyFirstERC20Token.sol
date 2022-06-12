// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title SampleERC20
 * @dev Create a sample ERC20 standard token
 */
contract MyFirstERC20Token is ERC20, Ownable {
    address private _owner;
    uint256 private _transactionServiceCharge = 100000;
    uint256 private _transactionDistoryAmount = 100000;
    address private _receiver;

    constructor(string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol) {
        _owner = owner();
    }

    
    function increaseTotal (uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function distoryToken(uint256 amount) public onlyOwner {
        _burn(_owner, amount);
    }

    function transactionServiceCharge(uint256 amount) public onlyOwner {
        _transactionDistoryAmount = amount;
    }

    function TransactionDistoryAmount(address account, uint256 amount) public onlyOwner {
        _transactionServiceCharge = amount;
        _receiver = account;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address _sender = msg.sender;
        
        uint256 fromBalance = balanceOf(to);
        require(fromBalance < amount, "ERC20: transfer amount exceeds balance");
        _transfer(_sender, to, amount);
        _transfer(_sender, to, amount);
        
        return true;
    }
}