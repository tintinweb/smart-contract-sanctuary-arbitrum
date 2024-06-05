// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Interface for the PluriStaking contract.
interface IPluriStaking {
    /// @notice Called to trigger the auto minting of rewards in the PluriStaking contract.
    /// @param minter Address which will receive the minted tokens.
    /// @return True if auto minting is successful.
    function autoMint(address minter) external returns (bool);
}

/// @title PluriFaucet
/// @notice Manages the cooldown period for reward distribution in the Pluri token ecosystem.
contract PluriFaucet {
    // Interface to interact with the PluriStaking contract.
    IPluriStaking private pluriStaking;

    // Address of the PluriStaking contract.
    address public pluriStakingAddress;

    // Mapping to track the last time an address called the autoMint function.
    mapping(address => uint256) public lastAccessTime;

    // Cooldown period for calling autoMint. Set to 1 day.
    uint256 public constant COOLDOWN_PERIOD = 1 days;

    /// @notice Constructs the PluriFaucet contract.
    /// @param _pluriStakingAddress Address of the PluriStaking contract.
    constructor(address _pluriStakingAddress) {
        pluriStakingAddress = _pluriStakingAddress;
        pluriStaking = IPluriStaking(_pluriStakingAddress);
    }

    /// @notice Allows an address to call the autoMint function, subject to a cooldown period.
    /// @dev Ensures that each address can only trigger autoMint once every cooldown period.
    /// @param addressToMint Address which will receive the minted tokens.
    function callAutoMint(address addressToMint) external returns (bool) {
        require(addressToMint != address(0), "Pluri Error: Address cannot be 0");
        require(block.timestamp >= lastAccessTime[msg.sender] + COOLDOWN_PERIOD, "Pluri Error: 24 Hour cooldown period not yet elapsed");
        require(pluriStaking.autoMint(addressToMint), "Pluri Error: Auto minting failed");
        lastAccessTime[msg.sender] = block.timestamp;
        return true;
    }
}