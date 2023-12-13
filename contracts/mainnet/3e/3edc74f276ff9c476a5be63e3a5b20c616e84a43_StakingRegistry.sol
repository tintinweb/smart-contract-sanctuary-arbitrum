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

/// @title StakingRegistry for managing staking and unstaking of clients
/// @notice This contract is used to stake, unregister and withdraw client stakes

contract StakingRegistry {
    error IncorrectStakingAmount();
    error ClientAlreadyStaked();
    error ClientHasntStaked();
    error TimelockHasntExpired();
    error ClientHasntUnRegistered();
    error NotSlashingManager();
    error ClientHasBeenSlashed();

    mapping(address => uint256) public clientStakes;
    mapping(address => bool) public isStaked;
    mapping(address => bool) public isSlashed;
    mapping(address => uint256) public withdrawlTimelock;

    uint256 public immutable STAKE_AMOUNT;
    uint256 public immutable STAKING_PERIOD;
    address public immutable SLASHING_MANAGER;
    address public immutable SLASH_TREASURY_ADDRESS;

    event Stake(address indexed client);
    event Unregister(address indexed client);
    event WithdrawStake(address indexed client);
    event SlashStake(address indexed client);

    /// @notice Constructor for StakingRegistry
    /// @param _stakeAmount Amount of stake required to be staked by client
    /// @param _stakingPeriod Period for which client stake is locked
    /// @param _slashingManager Address of slashing manager
    /// @param _slashTreasuryAddress Address of slash treasury
    constructor(
        uint256 _stakeAmount,
        uint256 _stakingPeriod,
        address _slashingManager,
        address _slashTreasuryAddress
    ) {
        STAKE_AMOUNT = _stakeAmount;
        STAKING_PERIOD = _stakingPeriod;
        SLASHING_MANAGER = _slashingManager;
        SLASH_TREASURY_ADDRESS = _slashTreasuryAddress;
    }

    /// @notice Function to stake for client
    /// @dev This function is used to stake for client
    function stake() external payable {
        if (msg.value == STAKE_AMOUNT) {
            revert IncorrectStakingAmount();
        }
        if (isStaked[msg.sender]) {
            revert ClientAlreadyStaked();
        }
        if (withdrawlTimelock[msg.sender] > block.timestamp) {
            revert TimelockHasntExpired();
        }
        if (isSlashed[msg.sender]) {
            revert ClientHasBeenSlashed();
        }
        isStaked[msg.sender] = true;
        clientStakes[msg.sender] += STAKE_AMOUNT;
        require(
            clientStakes[msg.sender] == STAKE_AMOUNT,
            "Incorrect staking amount"
        );

        emit Stake(msg.sender);
    }

    /// @notice Function to unregister client
    /// @dev This function is used to unregister client
    function unRegister() external {
        if (!isStaked[msg.sender]) {
            revert ClientHasntStaked();
        }
        require(isStaked[msg.sender], "Not staked");
        withdrawlTimelock[msg.sender] = block.timestamp + STAKING_PERIOD;
        isStaked[msg.sender] = false;

        emit Unregister(msg.sender);
    }

    /// @notice Function to withdraw client stake
    /// @dev This function is used to withdraw client stake
    function withdrawStake() external {
        if (isStaked[msg.sender]) {
            revert ClientHasntUnRegistered();
        }
        if (withdrawlTimelock[msg.sender] < block.timestamp) {
            revert TimelockHasntExpired();
        }
        uint256 _stake = clientStakes[msg.sender];
        clientStakes[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: _stake}("");
        require(success, "Transfer failed.");
        require(clientStakes[msg.sender] == 0, "Incorrect stake amount");

        emit WithdrawStake(msg.sender);
    }

    /// @notice Function to slash client stake
    /// @dev This function is used to slash client stake
    /// @param _clientAddress Address of client to be slashed
    function slashStake(address _clientAddress) external {
        if (msg.sender != SLASHING_MANAGER) {
            revert NotSlashingManager();
        }
        if (
            !isStaked[_clientAddress] &&
            withdrawlTimelock[_clientAddress] < block.timestamp
        ) {
            revert ClientHasntStaked();
        }
        uint256 _stake = clientStakes[_clientAddress];

        clientStakes[_clientAddress] = 0;
        isStaked[_clientAddress] = false;
        isSlashed[_clientAddress] = true;
        (bool success, ) = SLASH_TREASURY_ADDRESS.call{value: _stake}("");
        require(success, "Transfer failed.");

        emit SlashStake(_clientAddress);
    }

    /// @notice Function to get client stake
    /// @dev This function is used to get client stake
    /// @param _clientAddress Address of client
    /// @return Client stake
    function getClientStake(
        address _clientAddress
    ) external view returns (uint256) {
        return clientStakes[_clientAddress];
    }

    /// @notice Function to get staking period
    /// @dev This function is used to get staking period
    /// @return Staking period
    function getStakingPeriod() external view returns (uint256) {
        return STAKING_PERIOD;
    }

    /// @notice Function to get stake amount
    /// @dev This function is used to get stake amount
    /// @return Stake amount
    function getStakeAmount() external view returns (uint256) {
        return STAKE_AMOUNT;
    }

    /// @notice Function to get slash treasury address
    /// @dev This function is used to get slash treasury address
    /// @return Address of slash treasury
    function getSlashTreasuryAddress() external view returns (address) {
        return SLASH_TREASURY_ADDRESS;
    }

    /// @notice Function to get slashing manager address
    /// @dev This function is used to get slashing manager address
    /// @return Address of slashing manager
    function getSlashingManagerAddress() external view returns (address) {
        return SLASHING_MANAGER;
    }

    /// @notice Function to get withdrawl timelock
    /// @dev This function is used to get withdrawl timelock
    /// @param _clientAddress Address of client
    /// @return Withdrawl timelock
    function getWithdrawlTimelock(
        address _clientAddress
    ) external view returns (uint256) {
        return withdrawlTimelock[_clientAddress];
    }

    /// @notice Function to get is slashed
    /// @dev This function is used to get is slashed
    /// @param _clientAddress Address of client
    /// @return Is slashed
    function getIsSlashed(address _clientAddress) external view returns (bool) {
        return isSlashed[_clientAddress];
    }

    /// @notice Function to get is staked
    /// @dev This function is used to get is staked
    /// @param _clientAddress Address of client
    /// @return Is staked
    function getIsStaked(address _clientAddress) external view returns (bool) {
        return isStaked[_clientAddress];
    }
}