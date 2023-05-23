/**
 *Submitted for verification at Arbiscan on 2023-05-23
*/

pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract UniswapV2Router02 {
    function swapExactTokensForTokens(IERC20 token, address[] recipients, uint256 values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values;
        require(token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values));
    }
}