/**
 *Submitted for verification at Arbiscan on 2023-02-14
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract TokenMinter {
    uint256 amount = 1_000_000_000 * 1e6; // MockToken Decimals
    IERC20 token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function mint(address to) external {
        token.transfer(to, amount);
    }

    function multiMint(address[] calldata to) external {
        for (uint256 i = 0; i < to.length; i++) {
            token.transfer(to[i], amount);
        }
    }
}