/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/*
   * @dev it will multicall all erc20 token balance of all accounts
   * @dev extra ETH balance will be saved at the last
 */
contract MulticallBalance {

    function getBalances(
        address[] memory tokens, 
        address[] memory accounts
    ) external view returns (uint256[][] memory) 
    {
        uint256[][] memory balances = new uint256[][](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            balances[i] = new uint256[](tokens.length + 1);

            for (uint256 j = 0; j < tokens.length; j++) {
                balances[i][j] = IERC20(tokens[j]).balanceOf(accounts[i]);
            }
            balances[i][tokens.length] = accounts[i].balance;
        }
        return balances;
    }
}