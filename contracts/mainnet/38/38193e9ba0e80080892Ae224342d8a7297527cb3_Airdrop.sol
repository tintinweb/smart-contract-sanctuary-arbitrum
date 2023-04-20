/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Airdrop {
    address private _owner;
    uint256 private _amount = 1000 * 1e6;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    constructor() {
        _owner = msg.sender;
    }
    
    function airdrop(IERC20 token, address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], _amount);
        }
    }

    function withdraw(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.transfer(to, amount);
    }

    function set(uint256 value) external onlyOwner {
        _amount = value;
    }

    receive() external payable {}
}