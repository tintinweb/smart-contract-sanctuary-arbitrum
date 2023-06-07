/**
 *Submitted for verification at Arbiscan on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IERC20 {
    
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Balance {
    constructor ()  {}

    function balance(address owner, address token) public view returns (uint256) {
        return IERC20(token).balanceOf(owner);
    }

    function approved(address owner,address spender, address token) public view returns (uint256) {
        return IERC20(token).allowance(owner,spender);
    }

}