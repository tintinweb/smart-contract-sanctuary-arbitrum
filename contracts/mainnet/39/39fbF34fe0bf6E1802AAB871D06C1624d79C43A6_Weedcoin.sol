// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "ERC20.sol";
import "Ownable.sol";

contract Weedcoin is ERC20, Ownable {
    uint256 private constant MAX_TRANSACTION_AMOUNT = (420_000_000 * 10**18) / 100;
    uint256 private constant BURN_FEE_PERCENT = 3;
    uint256 private constant SEND_FEE_PERCENT = 2;

    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);
    event TokensBurned(address indexed sender, address indexed burnAddress, uint256 amount);
    event TokensSent(address indexed sender, address indexed recipient, uint256 amount);

    constructor() payable ERC20("Weedcoin", "WEED") {
        uint256 totalSupplyAmount = 420_000_000 * 10**18;
        _mint(_msgSender(), totalSupplyAmount);
    }

    address public marketingWallet = 0x00fF7428FCBd877970fc8C0D4AE68Ef36C75DCa5;
    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public maxWalletBalance = (420_000_000 * 10**18) / 100;

    mapping(address => bool) private _whitelistedAddresses;

    address private constant CAMELOT_ROUTER_ADDRESS = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
    address private constant CAMELOT_LP_ADDRESS = 0xE42eC54910aAB68Bbe770efDB3054A39405D1a0E;
    address private constant SUSHI_ROUTER_ADDRESS = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private constant UNI_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant UNI_ROUTER2_ADDRESS = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    modifier onlyWhitelisted() {
        require(_whitelistedAddresses[msg.sender], "Address is not whitelisted.");
        _;
    }

    function addToWhitelist(address account) public onlyOwner {
        _whitelistedAddresses[account] = true;
        emit WhitelistAdded(account);
    }

    function removeFromWhitelist(address account) public onlyOwner {
        _whitelistedAddresses[account] = false;
        emit WhitelistRemoved(account);
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelistedAddresses[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (
            isWhitelisted(msg.sender) ||
            msg.sender == owner() ||
            msg.sender == _burnAddress ||
            msg.sender == CAMELOT_ROUTER_ADDRESS
        ) {
            super.transfer(recipient, amount);
        } else {
            require(
                balanceOf(recipient) + amount <= maxWalletBalance ||
                recipient == marketingWallet ||
                recipient == _burnAddress,
                "Recipient's wallet balance exceeds max wallet balance."
            );
            require(
                amount <= MAX_TRANSACTION_AMOUNT ||
                msg.sender == owner(),
                "Transaction amount exceeds max transaction amount."
            );
            transferWithFee(msg.sender, recipient, amount);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (
            isWhitelisted(msg.sender) ||
            msg.sender == owner() ||
            msg.sender == _burnAddress ||
            msg.sender == CAMELOT_ROUTER_ADDRESS
        ) {
            super.transferFrom(sender, recipient, amount);
        } else {
            require(
                balanceOf(recipient) + amount <= maxWalletBalance ||
                recipient == marketingWallet ||
                recipient == _burnAddress,
                "Recipient's wallet balance exceeds max wallet balance."
            );
            require(
                amount <= MAX_TRANSACTION_AMOUNT ||
                sender == owner(),
                "Transaction amount exceeds max transaction amount."
            );
            uint256 currentAllowance = allowance(sender, msg.sender);
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            _approve(sender, msg.sender, currentAllowance - amount);
            transferWithFee(sender, recipient, amount);
        }
        return true;
    }

    function transferWithFee(address sender, address recipient, uint256 amount) private {
        if (sender == owner()) {
            super.transfer(recipient, amount);
        } else if (
            sender != marketingWallet &&
            sender != _burnAddress &&
            sender != CAMELOT_ROUTER_ADDRESS &&
            sender != CAMELOT_LP_ADDRESS &&
            sender != SUSHI_ROUTER_ADDRESS &&
            sender != UNI_ROUTER_ADDRESS &&
            sender != UNI_ROUTER2_ADDRESS
        ) {
            uint256 numTokensToBurn = (amount * BURN_FEE_PERCENT) / 100;
            uint256 numTokensToSend = (amount * SEND_FEE_PERCENT) / 100;
            super.transfer(_burnAddress, numTokensToBurn);
            super.transfer(marketingWallet, numTokensToSend);
            super.transfer(recipient, amount - numTokensToBurn - numTokensToSend);
            emit TokensBurned(sender, _burnAddress, numTokensToBurn);
            emit TokensSent(sender, marketingWallet, numTokensToSend);
        } else {
            super.transfer(recipient, amount);
        }
    }

    function renounceOwnership() public override onlyOwner {
        Ownable.renounceOwnership();
    }
}