/**
 *Submitted for verification at Arbiscan.io on 2023-12-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SlashTreasury {
    error NotAdmin();
    error NotEnoughBalance();

    address public immutable ADMIN_ADDRESS;

    event Withdraw(uint256 amount);
    event Recieved(uint256 amount);

    /// @notice Constructor for SlashTreasury
    /// @param _adminAddress Address of admin
    constructor(address _adminAddress) {
        ADMIN_ADDRESS = _adminAddress;
    }

    /// @notice Function to withdraw from treasury
    /// @dev This function is used to withdraw from treasury
    function withdraw(uint256 _amount) external {
        if (msg.sender != ADMIN_ADDRESS) {
            revert NotAdmin();
        }
        if (address(this).balance < _amount) {
            revert NotEnoughBalance();
        }
        (bool success, ) = ADMIN_ADDRESS.call{value: _amount}("");
        require(success, "Transfer failed.");

        emit Withdraw(_amount);
    }

    /// @notice Function to get admin address
    /// @dev This function is used to get admin address
    /// @return Address of admin
    function getAdminAddress() external view returns (address) {
        return ADMIN_ADDRESS;
    }

    receive() external payable {
        emit Recieved(msg.value);
    }
}