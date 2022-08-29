// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './Admin.sol';
import './SafeERC20.sol';

contract TokenAirdrop is Admin {

    using SafeERC20 for IERC20;

    event NewAirdrop(address indexed token, address indexed account, uint256 amount);

    event Claim(address indexed token, address indexed account, uint256 amount);

    // token => account => balance
    mapping (address => mapping (address => uint256)) public balances;

    struct Balance {
        address account;
        uint256 amount;
    }

    function newAirdrop(address token, Balance[] memory bals) external _onlyAdmin_ {
        for (uint256 i = 0; i < bals.length; i++) {
            Balance memory b = bals[i];
            balances[token][b.account] += b.amount;
            emit NewAirdrop(token, b.account, b.amount);
        }
    }

    function emergencyWithdraw(address token, address to) external _onlyAdmin_ {
        if (token == address(0)) {
            (bool success, ) = payable(to).call{value: address(this).balance}('');
            require(success, 'TokenAirdrop: Transfer ETH fail');
        } else {
            IERC20(token).safeTransfer(to, IERC20(token).balanceOf(address(this)));
        }
    }

    function claim(address token) external {
        uint256 amount = balances[token][msg.sender];
        require(amount > 0, 'TokenAirdrop: Nothing to claim');
        balances[token][msg.sender] = 0;
        if (token == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: amount}('');
            require(success, 'TokenAirdrop: Transfer ETH fail');
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
        emit Claim(token, msg.sender, amount);
    }

    receive() external payable {}

    //================================================================================
    // Helpers
    //================================================================================
    function getBalances(address token, address[] memory accounts) external view returns (uint256[] memory bals) {
        bals = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            bals[i] = balances[token][accounts[i]];
        }
    }

}