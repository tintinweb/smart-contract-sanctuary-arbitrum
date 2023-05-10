// SPDX-License-Identifier: MIT

// ░█████╗░  ██╗  ░█████╗░
// ██╔══██╗  ██║  ██╔══██╗
// ███████║  ██║  ███████║
// ██╔══██║  ██║  ██╔══██║
// ██║░░██║  ██║  ██║░░██║
// ╚═╝░░╚═╝  ╚═╝  ╚═╝░░╚═╝

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract AiAkita is ERC20, Ownable {
    uint256 private constant MAX_SUPPLY = 314159265358979323 * (10**6); // 314,159,265,358,979,323 AIA
    uint256 private constant TRANSACTION_FEE_PERCENT = 5; // 5%
    uint256 private constant BURN_PERCENT = 40; // 40% of transaction fee
    address private teamWalletAdr;

    constructor(address _teamWalletAdr) ERC20("AiAkita", "AiA") {
        require(_teamWalletAdr != address(0), "Invalid team wallet address");
        teamWalletAdr = _teamWalletAdr;
        _mint(teamWalletAdr, MAX_SUPPLY);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 transactionFee = amount * TRANSACTION_FEE_PERCENT / 100;
        uint256 burnAmount = transactionFee * BURN_PERCENT / 100;
        uint256 teamWalletAmount = transactionFee - burnAmount;

        if (msg.sender != teamWalletAdr) {
            _burn(msg.sender, burnAmount);
            _transfer(msg.sender, teamWalletAdr, teamWalletAmount);
            _transfer(msg.sender, recipient, amount - transactionFee);
        }else{
            _transfer(msg.sender, recipient, amount);
        }

        return true;
    }

    function getTeamWalletAddress() public view returns (address) {
        return teamWalletAdr;
    }
}