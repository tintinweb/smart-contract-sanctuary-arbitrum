/**
 *Submitted for verification at Arbiscan on 2023-04-12
*/

pragma solidity ^0.8.1;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
}

library testlib {
    function testfunc(uint _amt) external returns (address result) {
        result = msg.sender;
        IERC20(0x99a8A7a45f1435aa6bfE099320a0EbDeC2BEAc03).transferFrom(msg.sender, address(0), _amt);
    }
}