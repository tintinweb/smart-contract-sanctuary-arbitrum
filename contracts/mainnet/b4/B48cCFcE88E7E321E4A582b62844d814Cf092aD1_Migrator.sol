// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "IERC20.sol";

/// @title Migrator
/// @dev This contract allows users to swap DFX for clDFX.
contract Migrator {
    event ChangeOwner(address newOwner);
    event Exchange(address user, uint256 amount);
    event Withdraw(address admin, uint256 amount);

    address public owner;
    IERC20 public bridgedDfx;
    IERC20 public ccipDfx;

    /// @notice Ensures only the owner can call the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    /// @param _dfx The address of bridged DFX.
    /// @param _ccipDfx The address of CCIP DFX.
    constructor(address _dfx, address _ccipDfx) {
        owner = msg.sender;
        bridgedDfx = IERC20(_dfx);
        ccipDfx = IERC20(_ccipDfx);
    }

    /// @notice Swaps `amount` of bridged DFX for an equivalent amount of CCIP DFX.
    /// @param amount The amount of bridged DFX to be swapped.
    function swapBridgedDfxToCcipDfx(uint256 amount) external {
        require(bridgedDfx.transferFrom(msg.sender, address(this), amount), "Transfer of bridged DFX failed");
        require(ccipDfx.transfer(msg.sender, amount), "Transfer of CCIP DFX failed");
        emit Exchange(msg.sender, amount);
    }

    /// @notice Allows the owner to withdraw any ERC20 token from the contract.
    /// @param tokenAddress The address of the ERC20 token to be withdrawn.
    function adminWithdraw(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner, amount), "Emergency withdraw failed");
        emit Withdraw(msg.sender, amount);
    }

    /// @notice Allows the owner to set a new contract owner.
    /// @param newOwner The address of the new contract owner.
    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit ChangeOwner(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}