// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Interfaces
import {IRegistry} from "./IRegistry.sol";
import {IStrategy} from "./IStrategy.sol";
// Internal Libraries
import {Metadata} from "../libraries/Metadata.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Allo Interface
/// @author @thelostone-mc <[email protected]>, @0xKurt <[email protected]>, @codenamejason <[email protected]>, @0xZakk <[email protected]>, @nfrgosselin <[email protected]>
/// @notice Interface for the Allo contract. It exposes all functions needed to use the Allo protocol.
interface IAllo {
    /// ======================
    /// ======= Structs ======
    /// ======================

    /// @notice the Pool struct that all strategy pools are based from
    struct Pool {
        bytes32 profileId;
        IStrategy strategy;
        address token;
        Metadata metadata;
        bytes32 managerRole;
        bytes32 adminRole;
    }

    /// ======================
    /// ======= Events =======
    /// ======================

    /// @notice Event emitted when a new pool is created
    /// @param poolId ID of the pool created
    /// @param profileId ID of the profile the pool is associated with
    /// @param strategy Address of the strategy contract
    /// @param token Address of the token pool was funded with when created
    /// @param amount Amount pool was funded with when created
    /// @param metadata Pool metadata
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed profileId,
        IStrategy strategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    /// @notice Emitted when a pools metadata is updated
    /// @param poolId ID of the pool updated
    /// @param metadata Pool metadata that was updated
    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    /// @notice Emitted when a pool is funded
    /// @param poolId ID of the pool funded
    /// @param amount Amount funded to the pool
    /// @param fee Amount of the fee paid to the treasury
    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);

    /// @notice Emitted when the base fee is paid
    /// @param poolId ID of the pool the base fee was paid for
    /// @param amount Amount of the base fee paid
    event BaseFeePaid(uint256 indexed poolId, uint256 amount);

    /// @notice Emitted when the treasury address is updated
    /// @param treasury Address of the new treasury
    event TreasuryUpdated(address treasury);

    /// @notice Emitted when the percent fee is updated
    /// @param percentFee New percentage for the fee
    event PercentFeeUpdated(uint256 percentFee);

    /// @notice Emitted when the base fee is updated
    /// @param baseFee New base fee amount
    event BaseFeeUpdated(uint256 baseFee);

    /// @notice Emitted when the registry address is updated
    /// @param registry Address of the new registry
    event RegistryUpdated(address registry);

    /// @notice Emitted when a strategy is approved and added to the cloneable strategies
    /// @param strategy Address of the strategy approved
    event StrategyApproved(address strategy);

    /// @notice Emitted when a strategy is removed from the cloneable strategies
    /// @param strategy Address of the strategy removed
    event StrategyRemoved(address strategy);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Initialize the Allo contract
    /// @param _owner Address of the owner
    /// @param _registry Address of the registry contract
    /// @param _treasury Address of the treasury
    /// @param _percentFee Percentage for the fee
    /// @param _baseFee Base fee amount
    function initialize(
        address _owner,
        address _registry,
        address payable _treasury,
        uint256 _percentFee,
        uint256 _baseFee
    ) external;

    /// @notice Updates a pools metadata.
    /// @dev 'msg.sender' must be a pool admin.
    /// @param _poolId The ID of the pool to update
    /// @param _metadata The new metadata to set
    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) external;

    /// @notice Update the registry address.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _registry The new registry address
    function updateRegistry(address _registry) external;

    /// @notice Updates the treasury address.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _treasury The new treasury address
    function updateTreasury(address payable _treasury) external;

    /// @notice Updates the percentage for the fee.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _percentFee The new percentage for the fee
    function updatePercentFee(uint256 _percentFee) external;

    /// @notice Updates the base fee.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _baseFee The new base fee
    function updateBaseFee(uint256 _baseFee) external;

    /// @notice Adds a strategy to the cloneable strategies.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _strategy The address of the strategy to add
    function addToCloneableStrategies(address _strategy) external;

    /// @notice Removes a strategy from the cloneable strategies.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _strategy The address of the strategy to remove
    function removeFromCloneableStrategies(address _strategy) external;

    /// @notice Adds a pool manager to the pool.
    /// @dev 'msg.sender' must be a pool admin.
    /// @param _poolId The ID of the pool to add the manager to
    /// @param _manager The address of the manager to add
    function addPoolManager(uint256 _poolId, address _manager) external;

    /// @notice Removes a pool manager from the pool.
    /// @dev 'msg.sender' must be a pool admin.
    /// @param _poolId The ID of the pool to remove the manager from
    /// @param _manager The address of the manager to remove
    function removePoolManager(uint256 _poolId, address _manager) external;

    /// @notice Recovers funds from a pool.
    /// @dev 'msg.sender' must be a pool admin.
    /// @param _token The token to recover
    /// @param _recipient The address to send the recovered funds to
    function recoverFunds(address _token, address _recipient) external;

    /// @notice Registers a recipient and emits {Registered} event if successful and may be handled differently by each strategy.
    /// @param _poolId The ID of the pool to register the recipient for
    function registerRecipient(uint256 _poolId, bytes memory _data) external payable returns (address);

    /// @notice Registers a batch of recipients.
    /// @param _poolIds The pool ID's to register the recipients for
    /// @param _data The data to pass to the strategy and may be handled differently by each strategy
    function batchRegisterRecipient(uint256[] memory _poolIds, bytes[] memory _data)
        external
        returns (address[] memory);

    /// @notice Funds a pool.
    /// @dev 'msg.value' must be greater than 0 if the token is the native token
    ///       or '_amount' must be greater than 0 if the token is not the native token.
    /// @param _poolId The ID of the pool to fund
    /// @param _amount The amount to fund the pool with
    function fundPool(uint256 _poolId, uint256 _amount) external payable;

    /// @notice Allocates funds to a recipient.
    /// @dev Each strategy will handle the allocation of funds differently.
    /// @param _poolId The ID of the pool to allocate funds from
    /// @param _data The data to pass to the strategy and may be handled differently by each strategy.
    function allocate(uint256 _poolId, bytes memory _data) external payable;

    /// @notice Allocates funds to multiple recipients.
    /// @dev Each strategy will handle the allocation of funds differently
    function batchAllocate(uint256[] calldata _poolIds, bytes[] memory _datas) external;

    /// @notice Distributes funds to recipients and emits {Distributed} event if successful
    /// @dev Each strategy will handle the distribution of funds differently
    /// @param _poolId The ID of the pool to distribute from
    /// @param _recipientIds The recipient ids to distribute to
    /// @param _data The data to pass to the strategy and may be handled differently by each strategy
    function distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) external;

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Checks if an address is a pool admin.
    /// @param _poolId The ID of the pool to check
    /// @param _address The address to check
    /// @return 'true' if the '_address' is a pool admin, otherwise 'false'
    function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool);

    /// @notice Checks if an address is a pool manager.
    /// @param _poolId The ID of the pool to check
    /// @param _address The address to check
    /// @return 'true' if the '_address' is a pool manager, otherwise 'false'
    function isPoolManager(uint256 _poolId, address _address) external view returns (bool);

    /// @notice Checks if a strategy is cloneable (is in the cloneableStrategies mapping).
    /// @param _strategy The address of the strategy to check
    /// @return 'true' if the '_strategy' is cloneable, otherwise 'false'
    function isCloneableStrategy(address _strategy) external view returns (bool);

    /// @notice Returns the address of the strategy for a given 'poolId'
    /// @param _poolId The ID of the pool to check
    /// @return strategy The address of the strategy for the ID of the pool passed in
    function getStrategy(uint256 _poolId) external view returns (address);

    /// @notice Returns the current percent fee
    /// @return percentFee The current percentage for the fee
    function getPercentFee() external view returns (uint256);

    /// @notice Returns the current base fee
    /// @return baseFee The current base fee
    function getBaseFee() external view returns (uint256);

    /// @notice Returns the current treasury address
    /// @return treasury The current treasury address
    function getTreasury() external view returns (address payable);

    /// @notice Returns the current registry address
    /// @return registry The current registry address
    function getRegistry() external view returns (IRegistry);

    /// @notice Returns the 'Pool' struct for a given 'poolId'
    /// @param _poolId The ID of the pool to check
    /// @return pool The 'Pool' struct for the ID of the pool passed in
    function getPool(uint256 _poolId) external view returns (Pool memory);

    /// @notice Returns the current fee denominator
    /// @dev 1e18 represents 100%
    /// @return feeDenominator The current fee denominator
    function getFeeDenominator() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Internal Libraries
import {Metadata} from "../libraries/Metadata.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title IRegistry Interface
/// @author @thelostone-mc <[email protected]>, @0xKurt <[email protected]>, @codenamejason <[email protected]>, @0xZakk <[email protected]>, @nfrgosselin <[email protected]>
/// @notice Interface for the Registry contract and exposes all functions needed to use the Registry
///         within the Allo protocol.
/// @dev The Registry Interface is used to interact with the Allo protocol and create profiles
///      that can be used to interact with the Allo protocol. The Registry is the main contract
///      that all other contracts interact with to get the 'Profile' information needed to
///      interact with the Allo protocol. The Registry is also used to create new profiles
///      and update existing profiles. The Registry is also used to add and remove members
///      from a profile. The Registry will not always be used in a strategy and will depend on
///      the strategy being used.
interface IRegistry {
    /// ======================
    /// ======= Structs ======
    /// ======================

    /// @dev The Profile struct that all profiles are based from
    struct Profile {
        bytes32 id;
        uint256 nonce;
        string name;
        Metadata metadata;
        address owner;
        address anchor;
    }

    /// ======================
    /// ======= Events =======
    /// ======================

    /// @dev Emitted when a profile is created. This will return your anchor address.
    event ProfileCreated(
        bytes32 indexed profileId, uint256 nonce, string name, Metadata metadata, address owner, address anchor
    );

    /// @dev Emitted when a profile name is updated. This will update the anchor when the name is updated and return it.
    event ProfileNameUpdated(bytes32 indexed profileId, string name, address anchor);

    /// @dev Emitted when a profile's metadata is updated.
    event ProfileMetadataUpdated(bytes32 indexed profileId, Metadata metadata);

    /// @dev Emitted when a profile owner is updated.
    event ProfileOwnerUpdated(bytes32 indexed profileId, address owner);

    /// @dev Emitted when a profile pending owner is updated.
    event ProfilePendingOwnerUpdated(bytes32 indexed profileId, address pendingOwner);

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @dev Returns the 'Profile' for a '_profileId' passed
    /// @param _profileId The 'profileId' to return the 'Profile' for
    /// @return profile The 'Profile' for the '_profileId' passed
    function getProfileById(bytes32 _profileId) external view returns (Profile memory profile);

    /// @dev Returns the 'Profile' for an '_anchor' passed
    /// @param _anchor The 'anchor' to return the 'Profile' for
    /// @return profile The 'Profile' for the '_anchor' passed
    function getProfileByAnchor(address _anchor) external view returns (Profile memory profile);

    /// @dev Returns a boolean if the '_account' is a member or owner of the '_profileId' passed in
    /// @param _profileId The 'profileId' to check if the '_account' is a member or owner of
    /// @param _account The 'account' to check if they are a member or owner of the '_profileId' passed in
    /// @return isOwnerOrMemberOfProfile A boolean if the '_account' is a member or owner of the '_profileId' passed in
    function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account)
        external
        view
        returns (bool isOwnerOrMemberOfProfile);

    /// @dev Returns a boolean if the '_account' is an owner of the '_profileId' passed in
    /// @param _profileId The 'profileId' to check if the '_account' is an owner of
    /// @param _owner The 'owner' to check if they are an owner of the '_profileId' passed in
    /// @return isOwnerOfProfile A boolean if the '_account' is an owner of the '_profileId' passed in
    function isOwnerOfProfile(bytes32 _profileId, address _owner) external view returns (bool isOwnerOfProfile);

    /// @dev Returns a boolean if the '_account' is a member of the '_profileId' passed in
    /// @param _profileId The 'profileId' to check if the '_account' is a member of
    /// @param _member The 'member' to check if they are a member of the '_profileId' passed in
    /// @return isMemberOfProfile A boolean if the '_account' is a member of the '_profileId' passed in
    function isMemberOfProfile(bytes32 _profileId, address _member) external view returns (bool isMemberOfProfile);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @dev Creates a new 'Profile' and returns the 'profileId' of the new profile
    ///
    /// Note: The 'name' and 'nonce' are used to generate the 'anchor' address
    ///
    /// Requirements: None, anyone can create a new profile
    ///
    /// @param _nonce The nonce to use to generate the 'anchor' address
    /// @param _name The name to use to generate the 'anchor' address
    /// @param _metadata The 'Metadata' to use to generate the 'anchor' address
    /// @param _owner The 'owner' to use to generate the 'anchor' address
    /// @param _members The 'members' to use to generate the 'anchor' address
    /// @return profileId The 'profileId' of the new profile
    function createProfile(
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32 profileId);

    /// @dev Updates the 'name' of the '_profileId' passed in and returns the new 'anchor' address
    ///
    /// Requirements: Only the 'Profile' owner can update the name
    ///
    /// Note: The 'name' and 'nonce' are used to generate the 'anchor' address and this will update the 'anchor'
    ///       so please use caution. You can always recreate your 'anchor' address by updating the name back
    ///       to the original name used to create the profile.
    ///
    /// @param _profileId The 'profileId' to update the name for
    /// @param _name The new 'name' value
    /// @return anchor The new 'anchor' address
    function updateProfileName(bytes32 _profileId, string memory _name) external returns (address anchor);

    /// @dev Updates the 'Metadata' of the '_profileId' passed in
    ///
    /// Requirements: Only the 'Profile' owner can update the metadata
    ///
    /// @param _profileId The 'profileId' to update the metadata for
    /// @param _metadata The new 'Metadata' value
    function updateProfileMetadata(bytes32 _profileId, Metadata memory _metadata) external;

    /// @dev Updates the pending 'owner' of the '_profileId' passed in
    ///
    /// Requirements: Only the 'Profile' owner can update the pending owner
    ///
    /// @param _profileId The 'profileId' to update the pending owner for
    /// @param _pendingOwner The new pending 'owner' value
    function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner) external;

    /// @dev Accepts the pending 'owner' of the '_profileId' passed in
    ///
    /// Requirements: Only the pending owner can accept the ownership
    ///
    /// @param _profileId The 'profileId' to accept the ownership for
    function acceptProfileOwnership(bytes32 _profileId) external;

    /// @dev Adds members to the '_profileId' passed in
    ///
    /// Requirements: Only the 'Profile' owner can add members
    ///
    /// @param _profileId The 'profileId' to add members to
    /// @param _members The members to add to the '_profileId' passed in
    function addMembers(bytes32 _profileId, address[] memory _members) external;

    /// @dev Removes members from the '_profileId' passed in
    ///
    /// Requirements: Only the 'Profile' owner can remove members
    ///
    /// @param _profileId The 'profileId' to remove members from
    /// @param _members The members to remove from the '_profileId' passed in
    function removeMembers(bytes32 _profileId, address[] memory _members) external;

    /// @dev Recovers funds from the contract
    ///
    /// Requirements: Must be the Allo owner
    ///
    /// @param _token The token you want to use to recover funds
    /// @param _recipient The recipient of the recovered funds
    function recoverFunds(address _token, address _recipient) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Interfaces
import {IAllo} from "./IAllo.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title IStrategy Interface
/// @author @thelostone-mc <[email protected]>, @0xKurt <[email protected]>, @codenamejason <[email protected]>, @0xZakk <[email protected]>, @nfrgosselin <[email protected]> @0xZakk <[email protected]>, @nfrgosselin <[email protected]>
/// @notice BaseStrategy is the base contract that all strategies should inherit from and uses this interface.

interface IStrategy {
    /// ======================
    /// ======= Storage ======
    /// ======================

    /// @notice The Status enum that all recipients are based from
    enum Status {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed,
        InReview,
        Canceled
    }

    /// @notice Payout summary struct to hold the payout data
    struct PayoutSummary {
        address recipientAddress;
        uint256 amount;
    }

    /// ======================
    /// ======= Events =======
    /// ======================

    /// @notice Emitted when strategy is initialized.
    /// @param poolId The ID of the pool
    /// @param data The data passed to the 'initialize' function
    event Initialized(uint256 poolId, bytes data);

    /// @notice Emitted when a recipient is registered.
    /// @param recipientId The ID of the recipient
    /// @param data The data passed to the 'registerRecipient' function
    /// @param sender The sender
    event Registered(address indexed recipientId, bytes data, address sender);

    /// @notice Emitted when a recipient is allocated to.
    /// @param recipientId The ID of the recipient
    /// @param amount The amount allocated
    /// @param token The token allocated
    event Allocated(address indexed recipientId, uint256 amount, address token, address sender);

    /// @notice Emitted when tokens are distributed.
    /// @param recipientId The ID of the recipient
    /// @param recipientAddress The recipient
    /// @param amount The amount distributed
    /// @param sender The sender
    event Distributed(address indexed recipientId, address recipientAddress, uint256 amount, address sender);

    /// @notice Emitted when pool is set to active status.
    /// @param active The status of the pool
    event PoolActive(bool active);

    /// ======================
    /// ======= Views ========
    /// ======================

    /// @notice Getter for the address of the Allo contract.
    /// @return The 'Allo' contract
    function getAllo() external view returns (IAllo);

    /// @notice Getter for the 'poolId' for this strategy.
    /// @return The ID of the pool
    function getPoolId() external view returns (uint256);

    /// @notice Getter for the 'id' of the strategy.
    /// @return The ID of the strategy
    function getStrategyId() external view returns (bytes32);

    /// @notice Checks whether a allocator is valid or not, will usually be true for all strategies
    ///      and will depend on the strategy implementation.
    /// @param _allocator The allocator to check
    /// @return Whether the allocator is valid or not
    function isValidAllocator(address _allocator) external view returns (bool);

    /// @notice whether pool is active.
    /// @return Whether the pool is active or not
    function isPoolActive() external returns (bool);

    /// @notice Checks the amount of tokens in the pool.
    /// @return The balance of the pool
    function getPoolAmount() external view returns (uint256);

    /// @notice Increases the balance of the pool.
    /// @param _amount The amount to increase the pool by
    function increasePoolAmount(uint256 _amount) external;

    /// @notice Checks the status of a recipient probably tracked in a mapping, but will depend on the implementation
    ///      for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those
    ///      since there is no need for Pending or Rejected.
    /// @param _recipientId The ID of the recipient
    /// @return The status of the recipient
    function getRecipientStatus(address _recipientId) external view returns (Status);

    /// @notice Checks the amount allocated to a recipient for distribution.
    /// @dev Input the values you would send to distribute(), get the amounts each recipient in the array would receive.
    ///      The encoded '_data' will be determined by the strategy, and will be used to determine the payout.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The encoded data
    function getPayouts(address[] memory _recipientIds, bytes[] memory _data)
        external
        view
        returns (PayoutSummary[] memory);

    /// ======================
    /// ===== Functions ======
    /// ======================

    /// @notice
    /// @dev The default BaseStrategy version will not use the data  if a strategy wants to use it, they will overwrite it,
    ///      use it, and then call super.initialize().
    /// @param _poolId The ID of the pool
    /// @param _data The encoded data
    function initialize(uint256 _poolId, bytes memory _data) external;

    /// @notice This will register a recipient, set their status (and any other strategy specific values), and
    ///         return the ID of the recipient.
    /// @dev Able to change status all the way up to 'Accepted', or to 'Pending' and if there are more steps, additional
    ///      functions should be added to allow the owner to check this. The owner could also check attestations directly
    ///      and then accept for instance. The '_data' will be determined by the strategy implementation.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return The ID of the recipient
    function registerRecipient(bytes memory _data, address _sender) external payable returns (address);

    /// @notice This will allocate to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function allocate(bytes memory _data, address _sender) external payable;

    /// @notice This will distribute funds (tokens) to recipients.
    /// @dev most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    /// this contract will need to track the amount paid already, so that it doesn't double pay.
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Errors
/// @author @thelostone-mc <[email protected]>, @KurtMerbeth <[email protected]>, @codenamejason <[email protected]>
/// @notice Library containing all custom errors the protocol may revert with.
contract Errors {
    /// ======================
    /// ====== Generic =======
    /// ======================

    /// @notice Thrown as a general error when input / data is invalid
    error INVALID();

    /// @notice Thrown when mismatch in decoding data
    error MISMATCH();

    /// @notice Thrown when not enough funds are available
    error NOT_ENOUGH_FUNDS();

    /// @notice Thrown when user is not authorized
    error UNAUTHORIZED();

    /// @notice Thrown when address is the zero address
    error ZERO_ADDRESS();

    /// ======================
    /// ====== Registry ======
    /// ======================

    /// @dev Thrown when the nonce passed has been used or not available
    error NONCE_NOT_AVAILABLE();

    /// @dev Thrown when the 'msg.sender' is not the pending owner on ownership transfer
    error NOT_PENDING_OWNER();

    /// @dev Thrown if the anchor creation fails
    error ANCHOR_ERROR();

    /// ======================
    /// ======== Allo ========
    /// ======================

    /// @notice Thrown when the strategy is not approved
    error NOT_APPROVED_STRATEGY();

    /// @notice Thrown when the strategy is approved and should be cloned
    error IS_APPROVED_STRATEGY();

    /// @notice Thrown when the fee is below 1e18 which is the fee percentage denominator
    error INVALID_FEE();

    /// ======================
    /// ===== IStrategy ======
    /// ======================

    /// @notice Thrown when data is already intialized
    error ALREADY_INITIALIZED();

    /// @notice Thrown when data is yet to be initialized
    error NOT_INITIALIZED();

    /// @notice Thrown when an invalid address is used
    error INVALID_ADDRESS();

    /// @notice Thrown when a pool is inactive
    error POOL_INACTIVE();

    /// @notice Thrown when a pool is already active
    error POOL_ACTIVE();

    /// @notice Thrown when two arrays length are not equal
    error ARRAY_MISMATCH();

    /// @notice Thrown when the registration is invalid.
    error INVALID_REGISTRATION();

    /// @notice Thrown when the metadata is invalid.
    error INVALID_METADATA();

    /// @notice Thrown when the recipient is not accepted.
    error RECIPIENT_NOT_ACCEPTED();

    /// @notice Thrown when recipient is already accepted.
    error RECIPIENT_ALREADY_ACCEPTED();

    /// @notice Thrown when registration is not active.
    error REGISTRATION_NOT_ACTIVE();

    /// @notice Thrown when there is an error in recipient.
    error RECIPIENT_ERROR(address recipientId);

    /// @notice Thrown when the allocation is not active.
    error ALLOCATION_NOT_ACTIVE();

    /// @notice Thrown when the allocation is not ended.
    error ALLOCATION_NOT_ENDED();

    /// @notice Thrown when the allocation is active.
    error ALLOCATION_ACTIVE();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Metadata
/// @author @thelostone-mc <[email protected]>, @0xKurt <[email protected]>, @codenamejason <[email protected]>, @0xZakk <[email protected]>, @nfrgosselin <[email protected]>
/// @notice Metadata is used to define the metadata for the protocol that is used throughout the system.
struct Metadata {
    /// @notice Protocol ID corresponding to a specific protocol (currently using IPFS = 1)
    uint256 protocol;
    /// @notice Pointer (hash) to fetch metadata for the specified protocol
    string pointer;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Native token information
/// @author @thelostone-mc <[email protected]>, @0xKurt <[email protected]>, @codenamejason <[email protected]>, @0xZakk <[email protected]>, @nfrgosselin <[email protected]>
/// @notice This is used to define the address of the native token for the protocol
contract Native {
    /// @notice Address of the native token
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
// Internal Libraries
import "./Native.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Transfer contract
/// @author @thelostone-mc <[email protected]>, @0xKurt <[email protected]>, @codenamejason <[email protected]>, @0xZakk <[email protected]>, @nfrgosselin <[email protected]>
/// @notice A helper contract to transfer tokens within Allo protocol
/// @dev Handles the transfer of tokens to an address
contract Transfer is Native {
    /// @notice Thrown when the amount of tokens sent does not match the amount of tokens expected
    error AMOUNT_MISMATCH();

    /// @notice This holds the details for a transfer
    struct TransferData {
        address from;
        address to;
        uint256 amount;
    }

    /// @notice Transfer an amount of a token to an array of addresses
    /// @param _token The address of the token
    /// @param _transferData TransferData[]
    /// @return Whether the transfer was successful or not
    function _transferAmountsFrom(address _token, TransferData[] memory _transferData) internal returns (bool) {
        uint256 msgValue = msg.value;

        for (uint256 i; i < _transferData.length;) {
            TransferData memory transferData = _transferData[i];

            if (_token == NATIVE) {
                msgValue -= transferData.amount;
                SafeTransferLib.safeTransferETH(transferData.to, transferData.amount);
            } else {
                SafeTransferLib.safeTransferFrom(_token, transferData.from, transferData.to, transferData.amount);
            }

            unchecked {
                i++;
            }
        }

        if (msgValue != 0) revert AMOUNT_MISMATCH();

        return true;
    }

    /// @notice Transfer an amount of a token to an address
    /// @param _token The address of the token
    /// @param _transferData Individual TransferData
    /// @return Whether the transfer was successful or not
    function _transferAmountFrom(address _token, TransferData memory _transferData) internal returns (bool) {
        uint256 amount = _transferData.amount;
        if (_token == NATIVE) {
            // Native Token
            if (msg.value < amount) revert AMOUNT_MISMATCH();

            SafeTransferLib.safeTransferETH(_transferData.to, amount);
        } else {
            SafeTransferLib.safeTransferFrom(_token, _transferData.from, _transferData.to, amount);
        }
        return true;
    }

    /// @notice Transfer an amount of a token to an address
    /// @param _token The token to transfer
    /// @param _to The address to transfer to
    /// @param _amount The amount to transfer
    function _transferAmount(address _token, address _to, uint256 _amount) internal {
        if (_token == NATIVE) {
            SafeTransferLib.safeTransferETH(_to, _amount);
        } else {
            SafeTransferLib.safeTransfer(_token, _to, _amount);
        }
    }

    /// @notice Get the balance of a token for an account
    /// @param _token The token to get the balance of
    /// @param _account The account to get the balance for
    /// @return The balance of the token for the account
    function _getBalance(address _token, address _account) internal view returns (uint256) {
        if (_token == NATIVE) {
            return payable(_account).balance;
        } else {
            return SafeTransferLib.balanceOf(_token, _account);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Interfaces
import "../core/interfaces/IStrategy.sol";

// Libraries
import {Transfer} from "../core/libraries/Transfer.sol";
import {Errors} from "../core/libraries/Errors.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title BaseStrategy Contract
/// @author @thelostone-mc <[email protected]>, @0xKurt <[email protected]>, @codenamejason <[email protected]>, @0xZakk <[email protected]>, @nfrgosselin <[email protected]>
/// @notice This contract is the base contract for all strategies
/// @dev This contract is implemented by all strategies.
abstract contract BaseStrategy is IStrategy, Transfer, Errors {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    IAllo internal immutable allo;
    bytes32 internal immutable strategyId;
    bool internal poolActive;
    uint256 internal poolId;
    uint256 internal poolAmount;

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    /// @notice Constructor to set the Allo contract and "strategyId'.
    /// @param _allo Address of the Allo contract.
    /// @param _name Name of the strategy
    constructor(address _allo, string memory _name) {
        allo = IAllo(_allo);
        strategyId = keccak256(abi.encode(_name));
    }

    /// ====================================
    /// =========== Modifiers ==============
    /// ====================================

    /// @notice Modifier to check if the 'msg.sender' is the Allo contract.
    /// @dev Reverts if the 'msg.sender' is not the Allo contract.
    modifier onlyAllo() {
        _checkOnlyAllo();
        _;
    }

    /// @notice Modifier to check if the '_sender' is a pool manager.
    /// @dev Reverts if the '_sender' is not a pool manager.
    /// @param _sender The address to check if they are a pool manager
    modifier onlyPoolManager(address _sender) {
        _checkOnlyPoolManager(_sender);
        _;
    }

    /// @notice Modifier to check if the pool is active.
    /// @dev Reverts if the pool is not active.
    modifier onlyActivePool() {
        _checkOnlyActivePool();
        _;
    }

    /// @notice Modifier to check if the pool is inactive.
    /// @dev Reverts if the pool is active.
    modifier onlyInactivePool() {
        _checkInactivePool();
        _;
    }

    /// @notice Modifier to check if the pool is initialized.
    /// @dev Reverts if the pool is not initialized.
    modifier onlyInitialized() {
        _checkOnlyInitialized();
        _;
    }

    /// ================================
    /// =========== Views ==============
    /// ================================

    /// @notice Getter for the 'Allo' contract.
    /// @return The Allo contract
    function getAllo() external view override returns (IAllo) {
        return allo;
    }

    /// @notice Getter for the 'poolId'.
    /// @return The ID of the pool
    function getPoolId() external view override returns (uint256) {
        return poolId;
    }

    /// @notice Getter for the 'strategyId'.
    /// @return The ID of the strategy
    function getStrategyId() external view override returns (bytes32) {
        return strategyId;
    }

    /// @notice Getter for the 'poolAmount'.
    /// @return The balance of the pool
    function getPoolAmount() external view virtual override returns (uint256) {
        return poolAmount;
    }

    /// @notice Getter for whether or not the pool is active.
    /// @return 'true' if the pool is active, otherwise 'false'
    function isPoolActive() external view override returns (bool) {
        return _isPoolActive();
    }

    /// @notice Getter for the status of a recipient.
    /// @param _recipientId The ID of the recipient
    /// @return The status of the recipient
    function getRecipientStatus(address _recipientId) external view virtual returns (Status) {
        return _getRecipientStatus(_recipientId);
    }

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the 'Basetrategy'.
    /// @dev Will revert if the poolId is invalid or already initialized
    /// @param _poolId ID of the pool
    function __BaseStrategy_init(uint256 _poolId) internal virtual onlyAllo {
        // check if pool ID is not initialized already, if it is, revert
        if (poolId != 0) revert ALREADY_INITIALIZED();

        // check if pool ID is valid and not zero (0), if it is, revert
        if (_poolId == 0) revert INVALID();
        poolId = _poolId;
    }

    /// @notice Increases the pool amount.
    /// @dev Increases the 'poolAmount' by '_amount'. Only 'Allo' contract can call this.
    /// @param _amount The amount to increase the pool by
    function increasePoolAmount(uint256 _amount) external override onlyAllo {
        _beforeIncreasePoolAmount(_amount);
        poolAmount += _amount;
        _afterIncreasePoolAmount(_amount);
    }

    /// @notice Registers a recipient.
    /// @dev Registers a recipient and returns the ID of the recipient. The encoded '_data' will be determined by the
    ///      strategy implementation. Only 'Allo' contract can call this when it is initialized.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return recipientId The recipientId
    function registerRecipient(bytes memory _data, address _sender)
        external
        payable
        onlyAllo
        onlyInitialized
        returns (address recipientId)
    {
        _beforeRegisterRecipient(_data, _sender);
        recipientId = _registerRecipient(_data, _sender);
        _afterRegisterRecipient(_data, _sender);
    }

    /// @notice Allocates to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation. Only 'Allo' contract can
    ///      call this when it is initialized.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function allocate(bytes memory _data, address _sender) external payable onlyAllo onlyInitialized {
        _beforeAllocate(_data, _sender);
        _allocate(_data, _sender);
        _afterAllocate(_data, _sender);
    }

    /// @notice Distributes funds (tokens) to recipients.
    /// @dev The encoded '_data' will be determined by the strategy implementation. Only 'Allo' contract can
    ///      call this when it is initialized.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
        onlyAllo
        onlyInitialized
    {
        _beforeDistribute(_recipientIds, _data, _sender);
        _distribute(_recipientIds, _data, _sender);
        _afterDistribute(_recipientIds, _data, _sender);
    }

    /// @notice Gets the payout summary for recipients.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to get the payout summary for the recipients
    /// @return The payout summary for the recipients
    function getPayouts(address[] memory _recipientIds, bytes[] memory _data)
        external
        view
        virtual
        override
        returns (PayoutSummary[] memory)
    {
        uint256 recipientLength = _recipientIds.length;
        // check if the length of the recipient IDs and data arrays are equal, if they are not, revert
        if (recipientLength != _data.length) revert ARRAY_MISMATCH();

        PayoutSummary[] memory payouts = new PayoutSummary[](recipientLength);
        for (uint256 i; i < recipientLength;) {
            payouts[i] = _getPayout(_recipientIds[i], _data[i]);
            unchecked {
                i++;
            }
        }
        return payouts;
    }

    /// @notice Checks if the '_allocator' is a valid allocator.
    /// @dev How the allocator is determined is up to the strategy implementation.
    /// @param _allocator The address to check if it is a valid allocator for the strategy.
    /// @return 'true' if the address is a valid allocator, 'false' otherwise
    function isValidAllocator(address _allocator) external view virtual override returns (bool) {
        return _isValidAllocator(_allocator);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Checks if the 'msg.sender' is the Allo contract.
    /// @dev Reverts if the 'msg.sender' is not the Allo contract.
    function _checkOnlyAllo() internal view {
        if (msg.sender != address(allo)) revert UNAUTHORIZED();
    }

    /// @notice Checks if the '_sender' is a pool manager.
    /// @dev Reverts if the '_sender' is not a pool manager.
    /// @param _sender The address to check if they are a pool manager
    function _checkOnlyPoolManager(address _sender) internal view {
        if (!allo.isPoolManager(poolId, _sender)) revert UNAUTHORIZED();
    }

    /// @notice Checks if the pool is active.
    /// @dev Reverts if the pool is not active.
    function _checkOnlyActivePool() internal view {
        if (!poolActive) revert POOL_INACTIVE();
    }

    /// @notice Checks if the pool is inactive.
    /// @dev Reverts if the pool is active.
    function _checkInactivePool() internal view {
        if (poolActive) revert POOL_ACTIVE();
    }

    /// @notice Checks if the pool is initialized.
    /// @dev Reverts if the pool is not initialized.
    function _checkOnlyInitialized() internal view {
        if (poolId == 0) revert NOT_INITIALIZED();
    }

    /// @notice Set the pool to active or inactive status.
    /// @dev This will emit a 'PoolActive()' event. Used by the strategy implementation.
    /// @param _active The status to set, 'true' means active, 'false' means inactive
    function _setPoolActive(bool _active) internal {
        poolActive = _active;
        emit PoolActive(_active);
    }

    /// @notice Checks if the pool is active.
    /// @dev Used by the strategy implementation.
    /// @return 'true' if the pool is active, otherwise 'false'
    function _isPoolActive() internal view virtual returns (bool) {
        return poolActive;
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return 'true' if the allocator is valid, otherwise 'false'
    function _isValidAllocator(address _allocator) internal view virtual returns (bool);

    /// @notice This will register a recipient, set their status (and any other strategy specific values), and
    ///         return the ID of the recipient.
    /// @dev Able to change status all the way up to Accepted, or to Pending and if there are more steps, additional
    ///      functions should be added to allow the owner to check this. The owner could also check attestations directly
    ///      and then Accept for instance.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return The ID of the recipient
    function _registerRecipient(bytes memory _data, address _sender) internal virtual returns (address);

    /// @notice This will allocate to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _allocate(bytes memory _data, address _sender) internal virtual;

    /// @notice This will distribute funds (tokens) to recipients.
    /// @dev most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    /// this contract will need to track the amount paid already, so that it doesn't double pay.
    /// @param _recipientIds The ids of the recipients to distribute to
    /// @param _data Data required will depend on the strategy implementation
    /// @param _sender The address of the sender
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual;

    /// @notice This will get the payout summary for a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _recipientId The ID of the recipient
    /// @param _data The data to use to get the payout summary for the recipient
    /// @return The payout summary for the recipient
    function _getPayout(address _recipientId, bytes memory _data)
        internal
        view
        virtual
        returns (PayoutSummary memory);

    /// @notice This will get the status of a recipient.
    /// @param _recipientId The ID of the recipient
    /// @return The status of the recipient
    function _getRecipientStatus(address _recipientId) internal view virtual returns (Status);

    /// ===================================
    /// ============== Hooks ==============
    /// ===================================

    /// @notice Hook called before increasing the pool amount.
    /// @param _amount The amount to increase the pool by
    function _beforeIncreasePoolAmount(uint256 _amount) internal virtual {}

    /// @notice Hook called after increasing the pool amount.
    /// @param _amount The amount to increase the pool by
    function _afterIncreasePoolAmount(uint256 _amount) internal virtual {}

    /// @notice Hook called before registering a recipient.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    function _beforeRegisterRecipient(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called after registering a recipient.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    function _afterRegisterRecipient(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called before allocating to a recipient.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _beforeAllocate(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called after allocating to a recipient.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _afterAllocate(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called before distributing funds (tokens) to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function _beforeDistribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called after distributing funds (tokens) to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function _afterDistribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import {IAllo} from "../../core/interfaces/IAllo.sol";
import {IRegistry} from "../../core/interfaces/IRegistry.sol";
// Core Contracts
import {BaseStrategy} from "../BaseStrategy.sol";
// Internal Libraries
import {Metadata} from "../../core/libraries/Metadata.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title QVBaseStrategy
/// @notice Base strategy for quadratic voting strategies
/// @author @thelostone-mc <[email protected]>, @0xKurt <[email protected]>, @codenamejason <[email protected]>, @0xZakk <[email protected]>, @nfrgosselin <[email protected]>
abstract contract QVBaseStrategy is BaseStrategy {
    /// ======================
    /// ======= Events =======
    /// ======================

    /// @notice Emitted when a recipient updates their registration
    /// @param recipientId ID of the recipient
    /// @param applicationId ID of the recipient's application
    /// @param data The encoded data - (address recipientId, address recipientAddress, Metadata metadata)
    /// @param sender The sender of the transaction
    /// @param status The updated status of the recipient
    event UpdatedRegistration(
        address indexed recipientId, uint256 applicationId, bytes data, address sender, Status status
    );

    /// @notice Emitted when a recipient is registered
    /// @param recipientId ID of the recipient
    /// @param applicationId ID of the recipient's application
    /// @param status The status of the recipient
    /// @param sender The sender of the transaction
    event RecipientStatusUpdated(address indexed recipientId, uint256 applicationId, Status status, address sender);

    /// @notice Emitted when the pool timestamps are updated
    /// @param registrationStartTime The start time for the registration
    /// @param registrationEndTime The end time for the registration
    /// @param allocationStartTime The start time for the allocation
    /// @param allocationEndTime The end time for the allocation
    /// @param sender The sender of the transaction
    event TimestampsUpdated(
        uint64 registrationStartTime,
        uint64 registrationEndTime,
        uint64 allocationStartTime,
        uint64 allocationEndTime,
        address sender
    );

    /// @notice Emitted when a recipient receives votes
    /// @param recipientId ID of the recipient
    /// @param votes The votes allocated to the recipient
    /// @param allocator The allocator assigning the votes
    event Allocated(address indexed recipientId, uint256 votes, address allocator);

    /// @notice Emitted when a recipient is reviewed
    /// @param recipientId ID of the recipient
    /// @param applicationId ID of the recipient's application
    /// @param status The status of the recipient
    /// @param sender The sender of the transaction
    event Reviewed(address indexed recipientId, uint256 applicationId, Status status, address sender);

    /// ======================
    /// ======= Storage ======
    /// ======================

    // slot 0
    /// @notice The total number of votes cast for all recipients
    uint256 public totalRecipientVotes;

    // slot 1
    /// @notice The number of votes required to review a recipient
    uint256 public reviewThreshold;

    // slot 2
    /// @notice The start and end times for registrations and allocations
    /// @dev The values will be in milliseconds since the epoch
    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    // slot 3
    /// @notice Whether or not the strategy is using registry gating
    bool public registryGating;

    /// @notice Whether or not the strategy requires metadata
    bool public metadataRequired;

    /// @notice Whether the distribution started or not
    bool public distributionStarted;

    /// @notice The registry contract
    IRegistry private _registry;

    // slots [4...n]
    /// @notice The status of the recipient for this strategy only
    /// @dev There is a core `IStrategy.RecipientStatus` that this should map to
    enum InternalRecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed
    }

    /// @notice The parameters used to initialize the strategy
    struct InitializeParams {
        // slot 0
        bool registryGating;
        bool metadataRequired;
        // slot 1
        uint256 reviewThreshold;
        // slot 2
        uint64 registrationStartTime;
        uint64 registrationEndTime;
        uint64 allocationStartTime;
        uint64 allocationEndTime;
    }

    /// @notice The details of the recipient
    struct Recipient {
        // slot 0
        uint256 totalVotesReceived;
        // slot 1
        bool useRegistryAnchor;
        address recipientAddress;
        Metadata metadata;
        Status recipientStatus;
        // slot 2
        uint256 applicationId;
    }

    /// @notice The details of the allocator
    struct Allocator {
        // slot 0
        uint256 voiceCredits;
        // slots [1...n]
        mapping(address => uint256) voiceCreditsCastToRecipient;
        mapping(address => uint256) votesCastToRecipient;
    }

    /// @notice The details of the recipient are returned using their ID
    /// @dev recipientId => Recipient
    mapping(address => Recipient) public recipients;

    /// @notice The details of the allocator are returned using their address
    /// @dev allocator address => Allocator
    mapping(address => Allocator) public allocators;

    /// @notice Returns whether or not the recipient has been paid out using their ID
    /// @dev recipientId => paid out
    mapping(address => bool) public paidOut;

    // recipientId -> applicationId -> status -> count
    mapping(address => mapping(uint256 => mapping(Status => uint256))) public reviewsByStatus;

    // recipientId -> applicationId -> reviewer -> status
    mapping(address => mapping(uint256 => mapping(address => Status))) public reviewedByManager;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    /// @notice Modifier to check if the registration is active
    /// @dev Reverts if the registration is not active
    modifier onlyActiveRegistration() {
        _checkOnlyActiveRegistration();
        _;
    }

    /// @notice Modifier to check if the allocation is active
    /// @dev Reverts if the allocation is not active
    modifier onlyActiveAllocation() {
        _checkOnlyActiveAllocation();
        _;
    }

    /// @notice Modifier to check if the allocation has ended
    /// @dev Reverts if the allocation has not ended
    modifier onlyAfterAllocation() {
        _checkOnlyAfterAllocation();
        _;
    }

    /// @notice Modifier to check if the allocation has ended
    /// @dev This will revert if the allocation has ended.
    modifier onlyBeforeAllocationEnds() {
        _checkOnlyBeforeAllocationEnds();
        _;
    }

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ====================================
    /// =========== Initialize =============
    /// ====================================

    /// @notice Initialize the strategy
    /// @param _poolId The ID of the pool
    /// @param _data The initialization data for the strategy
    function initialize(uint256 _poolId, bytes memory _data) external virtual;

    /// @notice Internal initialize function
    /// @param _poolId The ID of the pool
    /// @param _params The initialize params for the strategy
    function __QVBaseStrategy_init(uint256 _poolId, InitializeParams memory _params) internal {
        __BaseStrategy_init(_poolId);

        registryGating = _params.registryGating;
        metadataRequired = _params.metadataRequired;
        _registry = allo.getRegistry();

        reviewThreshold = _params.reviewThreshold;

        _updatePoolTimestamps(
            _params.registrationStartTime,
            _params.registrationEndTime,
            _params.allocationStartTime,
            _params.allocationEndTime
        );
    }

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Get the recipient
    /// @param _recipientId ID of the recipient
    /// @return The recipient
    function getRecipient(address _recipientId) external view returns (Recipient memory) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get recipient status
    /// @param _recipientId Id of the recipient
    function _getRecipientStatus(address _recipientId) internal view virtual override returns (Status) {
        return _getRecipient(_recipientId).recipientStatus;
    }

    /// @notice Checks if a pool is active or not
    /// @return Whether the pool is active or not
    function _isPoolActive() internal view virtual override returns (bool) {
        if (registrationStartTime <= block.timestamp && block.timestamp <= registrationEndTime) {
            return true;
        }
        return false;
    }

    /// @notice Review recipient(s) application(s)
    /// @dev You can review multiple recipients at once or just one. This can only be called by a pool manager and
    ///      only during active registration.
    /// @param _recipientIds Ids of the recipients
    /// @param _recipientStatuses Statuses of the recipients
    function reviewRecipients(address[] calldata _recipientIds, Status[] calldata _recipientStatuses)
        external
        virtual
        onlyPoolManager(msg.sender)
        onlyBeforeAllocationEnds
    {
        // make sure the arrays are the same length
        uint256 recipientLength = _recipientIds.length;
        if (recipientLength != _recipientStatuses.length) revert INVALID();

        for (uint256 i; i < recipientLength;) {
            Status recipientStatus = _recipientStatuses[i];
            address recipientId = _recipientIds[i];
            Recipient storage recipient = recipients[recipientId];
            uint256 applicationId = recipient.applicationId;

            // if the status is none or appealed then revert
            if (recipientStatus == Status.None || recipientStatus == Status.Appealed) {
                revert RECIPIENT_ERROR(recipientId);
            }

            if (reviewedByManager[recipientId][applicationId][msg.sender] > Status.None) {
                revert RECIPIENT_ERROR(recipientId);
            }

            // track the review cast for the recipient and update status counter
            reviewedByManager[recipientId][applicationId][msg.sender] = recipientStatus;
            reviewsByStatus[recipientId][applicationId][recipientStatus]++;

            // update the recipient status if the review threshold has been reached
            if (reviewsByStatus[recipientId][applicationId][recipientStatus] >= reviewThreshold) {
                recipient.recipientStatus = recipientStatus;

                emit RecipientStatusUpdated(recipientId, applicationId, recipientStatus, address(0));
            }

            emit Reviewed(recipientId, applicationId, recipientStatus, msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set the start and end dates for the pool
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function updatePoolTimestamps(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) external onlyPoolManager(msg.sender) {
        _updatePoolTimestamps(_registrationStartTime, _registrationEndTime, _allocationStartTime, _allocationEndTime);
    }

    /// @notice Withdraw the tokens from the pool
    /// @dev Callable by the pool manager only 30 days after the allocation has ended
    /// @param _token The token to withdraw
    function withdraw(address _token) external onlyPoolManager(msg.sender) {
        if (block.timestamp <= allocationEndTime + 30 days) {
            revert INVALID();
        }

        uint256 amount = _getBalance(_token, address(this));

        // Transfer the tokens to the 'msg.sender' (pool manager calling function)
        _transferAmount(_token, msg.sender, amount);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Check if the registration is active
    /// @dev Reverts if the registration is not active
    function _checkOnlyActiveRegistration() internal view virtual {
        if (registrationStartTime > block.timestamp || block.timestamp > registrationEndTime) {
            revert REGISTRATION_NOT_ACTIVE();
        }
    }

    /// @notice Check if the allocation is active
    /// @dev Reverts if the allocation is not active
    function _checkOnlyActiveAllocation() internal view virtual {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
    }

    /// @notice Check if the allocation has ended
    /// @dev Reverts if the allocation has not ended
    function _checkOnlyAfterAllocation() internal view virtual {
        if (block.timestamp <= allocationEndTime) revert ALLOCATION_NOT_ENDED();
    }

    /// @notice Checks if the allocation has not ended and reverts if it has.
    /// @dev This will revert if the allocation has ended.
    function _checkOnlyBeforeAllocationEnds() internal view {
        if (block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
    }

    /// @notice Set the start and end dates for the pool
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function _updatePoolTimestamps(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) internal {
        // validate the timestamps for this strategy
        if (
            block.timestamp > _registrationStartTime || _registrationStartTime > _registrationEndTime
                || _registrationStartTime > _allocationStartTime || _allocationStartTime > _allocationEndTime
                || _registrationEndTime > _allocationEndTime
        ) {
            revert INVALID();
        }

        // Set the new values
        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        // emit the event
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime, msg.sender
        );
    }

    /// @notice Submit application to pool
    /// @dev The '_data' parameter is encoded as follows:
    ///     - If registryGating is true, then the data is encoded as (address recipientId, address recipientAddress, Metadata metadata)
    ///     - If registryGating is false, then the data is encoded as (address recipientAddress, address registryAnchor, Metadata metadata)
    /// @param _data The data to be decoded
    /// @param _sender The sender of the transaction
    /// @return recipientId The ID of the recipient
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyActiveRegistration
        returns (address recipientId)
    {
        address recipientAddress;
        address registryAnchor;
        bool isUsingRegistryAnchor;

        Metadata memory metadata;

        // decode data custom to this strategy
        if (registryGating) {
            (recipientId, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));

            // when registry gating is enabled, the recipientId must be a profile member
            if (!_isProfileMember(recipientId, _sender)) revert UNAUTHORIZED();
        } else {
            (recipientAddress, registryAnchor, metadata) = abi.decode(_data, (address, address, Metadata));
            isUsingRegistryAnchor = registryAnchor != address(0);
            recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;

            // when using registry anchor, the ID of the recipient must be a profile member
            if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) revert UNAUTHORIZED();
        }

        // make sure that if metadata is required, it is provided
        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        // make sure the recipient address is not the zero address
        if (recipientAddress == address(0)) revert RECIPIENT_ERROR(recipientId);

        Recipient storage recipient = recipients[recipientId];

        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.metadata = metadata;
        recipient.useRegistryAnchor = registryGating ? true : isUsingRegistryAnchor;
        ++recipient.applicationId;

        Status currentStatus = recipient.recipientStatus;

        if (currentStatus == Status.None) {
            // recipient registering new application
            recipient.recipientStatus = Status.Pending;
            emit Registered(recipientId, _data, _sender);
        } else {
            // recipient updating rejected/pending/appealed/accepted application
            if (currentStatus == Status.Rejected) {
                recipient.recipientStatus = Status.Appealed;
            } else if (currentStatus == Status.Accepted) {
                // recipient updating already accepted application
                recipient.recipientStatus = Status.Pending;
            }

            // emit the new status with the '_data' that was passed in
            emit UpdatedRegistration(recipientId, recipient.applicationId, _data, _sender, recipient.recipientStatus);
        }
    }

    /// @notice Distribute the tokens to the recipients
    /// @dev The '_sender' must be a pool manager and the allocation must have ended
    /// @param _recipientIds The recipient ids
    /// @param _sender The sender of the transaction
    function _distribute(address[] memory _recipientIds, bytes memory, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
        onlyAfterAllocation
    {
        uint256 payoutLength = _recipientIds.length;
        for (uint256 i; i < payoutLength;) {
            address recipientId = _recipientIds[i];
            Recipient storage recipient = recipients[recipientId];

            PayoutSummary memory payout = _getPayout(recipientId, "");
            uint256 amount = payout.amount;

            if (paidOut[recipientId] || !_isAcceptedRecipient(recipientId) || amount == 0) {
                revert RECIPIENT_ERROR(recipientId);
            }

            IAllo.Pool memory pool = allo.getPool(poolId);
            _transferAmount(pool.token, recipient.recipientAddress, amount);

            paidOut[recipientId] = true;

            emit Distributed(recipientId, recipient.recipientAddress, amount, _sender);
            unchecked {
                ++i;
            }
        }
        if (!distributionStarted) {
            distributionStarted = true;
        }
    }

    /// @notice Check if sender is a profile member
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    /// @return If the '_sender' is a profile member
    function _isProfileMember(address _anchor, address _sender) internal view returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Getter for a recipient using the ID
    /// @param _recipientId ID of the recipient
    /// @return The recipient
    function _getRecipient(address _recipientId) internal view returns (Recipient memory) {
        return recipients[_recipientId];
    }

    /// ====================================
    /// ============ QV Helper ==============
    /// ====================================

    /// @notice Calculate the square root of a number (Babylonian method)
    /// @param x The number
    /// @return y The square root
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Allocate voice credits to a recipient
    /// @dev This can only be called during active allocation period
    /// @param _allocator The allocator details
    /// @param _recipient The recipient details
    /// @param _recipientId The ID of the recipient
    /// @param _voiceCreditsToAllocate The voice credits to allocate to the recipient
    /// @param _sender The sender of the transaction
    function _qv_allocate(
        Allocator storage _allocator,
        Recipient storage _recipient,
        address _recipientId,
        uint256 _voiceCreditsToAllocate,
        address _sender
    ) internal onlyActiveAllocation {
        // check the `_voiceCreditsToAllocate` is > 0
        if (_voiceCreditsToAllocate == 0) revert INVALID();

        // check if the recipient is accepted
        if (!_isAcceptedRecipient(_recipientId)) revert RECIPIENT_ERROR(_recipientId);

        // update the allocator voice credits
        _allocator.voiceCredits += _voiceCreditsToAllocate;

        // creditsCastToRecipient is the voice credits used to cast a vote to the recipient
        // votesCastToRecipient is the actual votes cast to the recipient
        uint256 creditsCastToRecipient = _allocator.voiceCreditsCastToRecipient[_recipientId];
        uint256 votesCastToRecipient = _allocator.votesCastToRecipient[_recipientId];

        // get the total credits and calculate the vote result
        uint256 totalCredits = _voiceCreditsToAllocate + creditsCastToRecipient;
        // determine actual votes cast
        uint256 voteResult = _sqrt(totalCredits * 1e18);

        // update the values
        voteResult -= votesCastToRecipient;
        totalRecipientVotes += voteResult;
        _recipient.totalVotesReceived += voteResult;

        _allocator.voiceCreditsCastToRecipient[_recipientId] += _voiceCreditsToAllocate;
        _allocator.votesCastToRecipient[_recipientId] += voteResult;

        // emit the event with the vote results
        emit Allocated(_recipientId, voteResult, _sender);
    }

    /// @notice Returns if the recipient is accepted
    /// @param _recipientId The recipient id
    /// @return If the recipient is accepted
    function _isAcceptedRecipient(address _recipientId) internal view virtual returns (bool);

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return If the allocator is valid
    function _isValidAllocator(address _allocator) internal view virtual override returns (bool);

    /// @notice Checks if the allocator has voice credits left
    /// @param _voiceCreditsToAllocate The voice credits to allocate
    /// @param _allocatedVoiceCredits The allocated voice credits
    /// @return If the allocator has voice credits left
    function _hasVoiceCreditsLeft(uint256 _voiceCreditsToAllocate, uint256 _allocatedVoiceCredits)
        internal
        view
        virtual
        returns (bool);

    /// @notice Get the payout for a single recipient
    /// @param _recipientId The ID of the recipient
    /// @return The payout as a 'PayoutSummary' struct
    function _getPayout(address _recipientId, bytes memory)
        internal
        view
        virtual
        override
        returns (PayoutSummary memory)
    {
        Recipient memory recipient = recipients[_recipientId];

        // Calculate the payout amount based on the percentage of total votes
        uint256 amount;
        if (!paidOut[_recipientId] && totalRecipientVotes != 0) {
            amount = poolAmount * recipient.totalVotesReceived / totalRecipientVotes;
        }
        return PayoutSummary(recipient.recipientAddress, amount);
    }

    function _beforeIncreasePoolAmount(uint256) internal virtual override {
        if (distributionStarted) {
            revert INVALID();
        }
    }

    /// @notice Contract should be able to receive NATIVE
    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {Multicall} from "lib/openzeppelin-contracts/contracts/utils/Multicall.sol";
// Strategy Contracts
import {QVBaseStrategy} from "../qv-base/QVBaseStrategy.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co
contract QVSimpleStrategy is QVBaseStrategy, Multicall {
    /// ======================
    /// ======= Events =======
    /// ======================

    /// @notice Emitted when an allocator is added
    /// @param allocator The allocator address
    /// @param sender The sender of the transaction
    event AllocatorAdded(address indexed allocator, address sender);

    /// @notice Emitted when an allocator is removed
    /// @param allocator The allocator address
    /// @param sender The sender of the transaction
    event AllocatorRemoved(address indexed allocator, address sender);

    /// ======================
    /// ======= Storage ======
    /// ======================

    /// @notice The maximum voice credits per allocator
    uint256 public maxVoiceCreditsPerAllocator;

    /// @notice The details of the allowed allocator
    /// @dev allocator => bool
    mapping(address => bool) public allowedAllocators;

    /// ======================
    /// ======= Struct =======
    /// ======================

    /// @notice The parameters used to initialize the strategy
    struct InitializeParamsSimple {
        // slot 0
        uint256 maxVoiceCreditsPerAllocator;
        // slot 1..n
        InitializeParams params;
    }

    /// ====================================
    /// ========== Constructor =============
    /// ====================================
    constructor(address _allo, string memory _name) QVBaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initialize the strategy
    /// @param _poolId The ID of the pool
    /// @param _data The initialization data for the strategy
    /// @custom:data (InitializeParamsSimple)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override onlyAllo {
        (InitializeParamsSimple memory initializeParamsSimple) = abi.decode(_data, (InitializeParamsSimple));
        __QVBaseStrategy_init(_poolId, initializeParamsSimple.params);

        maxVoiceCreditsPerAllocator = initializeParamsSimple.maxVoiceCreditsPerAllocator;
        emit Initialized(_poolId, _data);
    }

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Add allocator
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorAdded` event
    /// @param _allocator The allocator address
    function addAllocator(address _allocator) external onlyPoolManager(msg.sender) {
        allowedAllocators[_allocator] = true;

        emit AllocatorAdded(_allocator, msg.sender);
    }

    /// @notice Remove allocator
    /// @dev Only the pool manager(s) can call this function and emits an `AllocatorRemoved` event
    /// @param _allocator The allocator address
    function removeAllocator(address _allocator) external onlyPoolManager(msg.sender) {
        allowedAllocators[_allocator] = false;

        emit AllocatorRemoved(_allocator, msg.sender);
    }

    /// @notice Allocate votes to a recipient
    /// @param _data The data
    /// @param _sender The sender of the transaction
    /// @dev Only the pool manager(s) can call this function
    function _allocate(bytes memory _data, address _sender) internal virtual override {
        (address recipientId, uint256 voiceCreditsToAllocate) = abi.decode(_data, (address, uint256));

        // spin up the structs in storage for updating
        Recipient storage recipient = recipients[recipientId];
        Allocator storage allocator = allocators[_sender];

        // check that the sender can allocate votes
        if (!_isValidAllocator(_sender)) revert UNAUTHORIZED();

        // check that the recipient is accepted
        if (!_isAcceptedRecipient(recipientId)) revert RECIPIENT_ERROR(recipientId);

        // check that the recipient has voice credits left to allocate
        if (!_hasVoiceCreditsLeft(voiceCreditsToAllocate, allocator.voiceCredits)) revert INVALID();

        _qv_allocate(allocator, recipient, recipientId, voiceCreditsToAllocate, _sender);
    }

    /// @notice Returns if the recipient is accepted
    /// @param _recipientId The recipient id
    /// @return true if the recipient is accepted
    function _isAcceptedRecipient(address _recipientId) internal view override returns (bool) {
        return recipients[_recipientId].recipientStatus == Status.Accepted;
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return true if the allocator is valid
    function _isValidAllocator(address _allocator) internal view override returns (bool) {
        return allowedAllocators[_allocator];
    }

    /// @notice Checks if the allocator has voice credits left
    /// @param _voiceCreditsToAllocate The voice credits to allocate
    /// @param _allocatedVoiceCredits The allocated voice credits
    /// @return true if the allocator has voice credits left
    function _hasVoiceCreditsLeft(uint256 _voiceCreditsToAllocate, uint256 _allocatedVoiceCredits)
        internal
        view
        override
        returns (bool)
    {
        return _voiceCreditsToAllocate + _allocatedVoiceCredits <= maxVoiceCreditsPerAllocator;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for gas griefing protection.
/// - For ERC20s, this implementation won't check that a token has code,
/// responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    ///
    /// Note: This implementation does NOT protect against gas griefing.
    /// Please use `forceSafeTransferETH` for gas griefing protection.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overridden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` argument is already written to the memory word at 0x60.
            amount := mload(0x60)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x34.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}