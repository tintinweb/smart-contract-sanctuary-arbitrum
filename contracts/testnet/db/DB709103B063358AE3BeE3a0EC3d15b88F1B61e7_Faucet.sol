// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function mint(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract Faucet {
    /*==================================================== Events =============================================================*/
    event Minted(
        address token,
        address indexed to,
        uint256 amount,
        uint256 remainingSupply
    );

    function mint(address token, address to, uint256 amount) external {
        IERC20(token).mint(to, amount);
        emit Minted(token, to, amount, IERC20(token).balanceOf(address(this)));
    }
}