/**
 *Submitted for verification at Arbiscan on 2023-01-30
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Distribution {
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function distributeToken(IERC20 token, address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], amounts[i]);
        }
    }
    
    receive() external payable {}
}