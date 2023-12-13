/**
 *Submitted for verification at Arbiscan.io on 2023-12-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStakingRegistry {
    function stake() external payable;

    function unRegister() external;

    function withdrawStake() external;

    function slashStake(address _clientAddress) external;
}


contract SlashingManager {
    error NotSlasher();

    address public immutable SLASHER_ADDRESS;

    event SlashClients(uint256 indexed instanceId);

    /// @notice Constructor for SlashingManager
    /// @param _slasherAddress Address of slasher
    constructor(address _slasherAddress) {
        SLASHER_ADDRESS = _slasherAddress;
    }

    /// @notice Function to slash client stake
    /// @dev This function is used to slash client stake
    /// @param _clientAddress Address of malicious client
    /// @param _stakingRegistry Address of staking registry
    function slash(
        address[] calldata _clientAddress,
        uint256 _instanceId,
        address _stakingRegistry
    ) external {
        if (msg.sender != SLASHER_ADDRESS) {
            revert NotSlasher();
        }
        IStakingRegistry stakingRegistry = IStakingRegistry(_stakingRegistry);
        for (uint256 i = 0; i < _clientAddress.length; i++) {
            stakingRegistry.slashStake(_clientAddress[i]);
        }
        emit SlashClients(_instanceId);
    }

    /// @notice Function to get slasher address
    /// @dev This function is used to get slasher address
    /// @return Address of slasher
    function getSlasherAddress() external view returns (address) {
        return SLASHER_ADDRESS;
    }
}