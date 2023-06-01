/**
 *Submitted for verification at Arbiscan on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library TokenInfoStructs {
    struct TokenInfo {
        string name;
        string symbol;
        uint256 decimals;
        uint256 balance;
        uint256 totalSupply;
    }
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface TokenInfoInterface {
    function getTokenInfo(address token, address account) external view returns(TokenInfoStructs.TokenInfo memory tokenInfo);
}

contract TokenInfoContract {
    address public tokenInfoContract;

    constructor(address _tokenInfoContract) {
        tokenInfoContract = _tokenInfoContract;
    }

    function isTokenAddress(address token, address account) public view returns(bool, TokenInfoStructs.TokenInfo memory info) {
        try TokenInfoInterface(tokenInfoContract).getTokenInfo(token, account) returns (TokenInfoStructs.TokenInfo memory tokenInfo) {
                info = tokenInfo;
                return (true, tokenInfo);
            } catch {
                info.name = "";
                info.symbol = "";
                info.decimals = 0;
                info.balance = 0;
                info.totalSupply=  0;
                return (false, info);
            }
    }
}