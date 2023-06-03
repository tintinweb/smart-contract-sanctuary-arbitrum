// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}
contract Test {
    function mint() public {
        IERC20 usdc = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
        usdc.approve(0x63Cd89E59D2F4D3fccC2B00483e58b2E752470B5,115792089237316195423570985008687907853269984665640564039457584007913129639935);

    }
}