/**
 *Submitted for verification at Arbiscan on 2023-06-25
*/

//SPDX-License-Identifier:MIT
 pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MyContract {
    IERC20 private _token;
    address private _tokenAddress = 0xB43a684A135CC9bD31cCaC13530Fdc847ef8E34C;
    address private _owner;

    constructor() {
        _token = IERC20(_tokenAddress);
        _owner = msg.sender;
    }

    function transferToContract(uint256 amount) public {
        require(_token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(_token.approve(address(this), amount), "Approval failed");
        require(_token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    function transferFromContract(address recipient, uint256 amount) public {
    require(msg.sender == _owner, "Only owner can call this function");
    require(_token.balanceOf(address(this)) >= amount, "Insufficient balance");
    (bool success, ) = payable(_tokenAddress).call(abi.encodeWithSignature("transfer(address,uint256)", recipient, amount));
require(success, "Transfer failed");
     }
}