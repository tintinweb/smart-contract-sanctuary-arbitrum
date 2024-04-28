// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Withdrawer {
    function withdrawNativeToken() external {
        address payable master = payable(
            0x773d33d35C0c0D9044FA5Ba5781D63f304Ba4663
        ); // set master address here
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract has no balance");
        require(msg.sender == master, "You are not master");
        master.transfer(contractBalance);
    }

    function withdrawTokens(address _tokenAddress) external {
        address master = 0x773d33d35C0c0D9044FA5Ba5781D63f304Ba4663; // set master address here
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance > 0, "Contract has no balance");
        require(msg.sender == master, "You are not master");
        // Transfer the tokens to the owner
        token.transfer(master, contractBalance);
    }
}