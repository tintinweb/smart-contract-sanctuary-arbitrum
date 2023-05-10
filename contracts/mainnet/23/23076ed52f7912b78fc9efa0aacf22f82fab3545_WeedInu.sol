// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "ERC20.sol";
import "Ownable.sol";

contract WeedInu is ERC20, Ownable {
    uint256 private constant MAX_TRANSACTION_AMOUNT = (420_000_000 * 10**18) / 100;
    uint256 private constant BURN_FEE_PERCENT = 2;
    uint256 private constant SEND_FEE_PERCENT = 3;

    constructor() payable ERC20("Weed Inu", "WEED") {
        uint256 totalSupply = 420_000_000 * 10**18;
        _mint(msg.sender, totalSupply);
        transferOwnership(0x4D7Df2f83f210648f398D76613F69b9E85562D5c);
    }

    address public marketingWallet = 0x5Ab6eBd609657FE19bFF46Bf74F89Fdc93a5Fd05;
    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public maxWalletBalance = (420_000_000 * 10**18) / 100;
    uint256 private numTokensToBurn;
    uint256 private numTokensToSend;

    function transferWithFee(address recipient, uint256 amount) private {
        numTokensToBurn = (amount * BURN_FEE_PERCENT) / 100;
        numTokensToSend = (amount * SEND_FEE_PERCENT) / 100;
        _transfer(_msgSender(), _burnAddress, numTokensToBurn);
        _transfer(_msgSender(), marketingWallet, numTokensToSend);
        _transfer(_msgSender(), recipient, amount - numTokensToBurn - numTokensToSend);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(
            balanceOf(recipient) + amount <= maxWalletBalance ||
            recipient == marketingWallet ||
            recipient == owner() ||
            recipient == _burnAddress,
            "Recipient's wallet balance exceeds max wallet balance."
        );
        require(
            amount <= MAX_TRANSACTION_AMOUNT ||
            _msgSender() == marketingWallet ||
            _msgSender() == owner(),
            "Transaction amount exceeds max transaction amount."
        );
        transferWithFee(recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(
            balanceOf(recipient) + amount <= maxWalletBalance ||
            recipient == marketingWallet ||
            recipient == owner() ||
            recipient == _burnAddress,
            "Recipient's wallet balance exceeds max wallet balance."
        );
        require(
            amount <= MAX_TRANSACTION_AMOUNT ||
            sender == marketingWallet ||
            sender == owner(),
            "Transaction amount exceeds max transaction amount."
        );
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        transferWithFee(recipient, amount);
        return true;
    }
}