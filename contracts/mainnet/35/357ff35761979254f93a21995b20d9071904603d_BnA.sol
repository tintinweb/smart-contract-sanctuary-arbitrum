/**
 *Submitted for verification at Arbiscan on 2023-03-10
*/

/**
 *Submitted for verification at polygonscan.com on 2023-01-05
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-29
*/

// File: contracts/interfaces/IERC20.sol

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}

// File: contracts/BnA.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

/** @title BnA: Balance and Allowance */
/** @author Zergity */

contract BnA {
    address private constant COIN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getBnA(
        address[] calldata tokens,
        address[] calldata owners,
        address[] calldata spenders
    ) external view returns (uint[] memory rets, uint blockNumber) {
        rets = new uint[](tokens.length * owners.length * (1 + spenders.length));
        uint n = 0;
        for (uint i = 0; i < tokens.length; ++i) {
            IERC20 token = IERC20(tokens[i]);
            for (uint j = 0; j < owners.length; ++j) {
                address owner = owners[j];

                if (address(token) == COIN) {
                    rets[n] = owner.balance;
                    n += 1 + spenders.length;
                    continue;
                }

                try token.balanceOf(owner) returns (uint balance) {
                    rets[n] = balance;
                } catch (bytes memory /*lowLevelData*/) {}
                n++;

                for (uint k = 0; k < spenders.length; ++k) {
                    try token.allowance(owner, spenders[k]) returns (uint allowance) {
                        rets[n] = allowance;
                    } catch (bytes memory /*lowLevelData*/) {}
                    n++;
                }
            }
        }
        blockNumber = block.number;
    }
}