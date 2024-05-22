// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;


interface IBalanceOf {
    function balanceOf(address account) external view returns (uint256);
}

contract BalanceChecker {
    function getBalancesERC20(address[] calldata addresses, address token_address) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](addresses.length);
        IBalanceOf token = IBalanceOf(token_address);
        for (uint256 i = 0; i < addresses.length; i++) {
            balances[i] = token.balanceOf(addresses[i]);
        }
        return balances;
    }

    function getBalances(address[] calldata addresses) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            balances[i] = addresses[i].balance;
        }
        return balances;
    }

    function balancesOf(address addr, address[] calldata erc20_tokens) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](erc20_tokens.length + 1);
        balances[0] = addr.balance;
        for (uint256 i = 0; i < erc20_tokens.length; i++) {
            balances[i+1] = IBalanceOf(erc20_tokens[i]).balanceOf(addr);
        }
        return balances;
    }
}