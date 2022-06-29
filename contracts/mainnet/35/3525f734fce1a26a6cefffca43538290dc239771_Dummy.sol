/**
 *Submitted for verification at Arbiscan on 2022-06-29
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Dummy {
    address constant UNISWAP_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    constructor(){
        IERC20(USDC).approve(UNISWAP_ROUTER, type(uint256).max);
    }
}