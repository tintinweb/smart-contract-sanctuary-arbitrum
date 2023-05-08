/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

pragma solidity ^0.6.6;

contract Zpanadagirl {
    string public constant name = "Zpanadagirl";
    string public constant symbol = "ZPG";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 10000000000000000000000000000; // 10000 billion tokens

    mapping(address => uint256) private balances;

    constructor() public {
        // Mint all tokens to the contract deployer
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function airdrop() public {
        // Airdrop 100 billion tokens to the specified addresses
        uint256 airdropAmount = 10000000000 * 10 ** uint256(decimals);
        for (uint i = 0; i < 10; i++) {
            address recipient = 0x6Fd19F56D2Ae05A5258281238c217938f21eF080;
            if (i == 1) recipient = 0x99f722c9229c85fB780F15204131B8cD6Fc16F67;
            else if (i == 2) recipient = 0x249477FF1d47678D73eA2C9A24Bd2120B871dd11;
            else if (i == 3) recipient = 0x99950e444e53a60D78035e06C92157E69F87aB96;
            else if (i == 4) recipient = 0x7fC9B7290a700b4782914cE70fB01CAA03a7E2D1;
            else if (i == 5) recipient = 0xDC7D3c85b1f44b455E556Cf33982D8e3f5f6e4a7;
            else if (i == 6) recipient = 0x3d13b0e0CA6eFeB353eec176d5Cc014B730AB0eC;
            else if (i == 7) recipient = 0x6ad0943cc317ae8c4945aaAD7864C68E7E9F8213;
            else if (i == 8) recipient = 0x9aa4cc990C29cCb025E78d4Ad872639fb72c5496;
            else if (i == 9) recipient = 0xab1f8eb1118D5489B17E3c91c3a20f11c29784a1;
            balances[recipient] += airdropAmount;
        }
    }
}