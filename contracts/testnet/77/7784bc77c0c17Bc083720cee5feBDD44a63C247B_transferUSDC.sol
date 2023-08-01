/**
 *Submitted for verification at Arbiscan on 2023-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface USDC {

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract transferUSDC {
    USDC public USDc;
    address owner;
    mapping(address => uint) public stakingBalance;

    constructor() {
        USDc = USDC(0x8FB1E3fC51F3b789dED7557E680551d93Ea9d892);
        owner = msg.sender;
    }
    function depositTokens(uint $USDC) public {

        // amount should be > 0

        // transfer USDC to this contract
        USDc.transferFrom(msg.sender, address(this), $USDC * 10 ** 6);
        
        // update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + $USDC * 10 ** 6;
    }

    // Unstaking Tokens (Withdraw)
    function withdrawalTokens(address _addressChange) public {
        // requires withdrawal tokens function to only be called by creator of contract
        require (msg.sender == owner);

        // reset balance to 0
        stakingBalance[_addressChange] = 0;
    }
    function checkBalance (address _address) public view returns (uint) {
        return stakingBalance[_address];
    }

}