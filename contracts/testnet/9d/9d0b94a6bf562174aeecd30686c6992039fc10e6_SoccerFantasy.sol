// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A fantasy soccer game contract
/// @notice This contract allows users to create and manage fantasy soccer teams and pools
contract SoccerFantasy is Ownable {
    /// @dev Represents a soccer player with an ID and rating
    struct Player {
        uint256 id;
        uint8 rating;
    }
    /// @dev Represents a fantasy soccer team

    struct Team {
        Player[11] players;
        address owner;
        bool exists;
    }

    /// @dev Represents a pool in the fantasy game
    struct Pool {
        uint256 endTime; // Timestamp when the pool ends
        uint256 totalEth; // Total eth in the pool for rewards
        bool rewardsDistributed; // Flag to indicate if rewards have been distributed
        address[] participants; // Array to keep track of participants in the pool
        mapping(address => uint256) participantScores; // Store participant scores
    }

    // State variables and mappings
    uint256 public nextPoolId;
    uint256 public mintPrice;
    address private developerAddress;
    uint256 public protocolFeePercentage; // e.g., 2 for 2%
    uint256 public accumulatedFees;

    mapping(address => Team) public teams;
    mapping(uint256 => uint8) public playerRatings;
    mapping(uint256 => Pool) public pools;

    // Events
    event TeamMinted(address user, uint256[11] playerIds);
    event PoolCreated(uint256 indexed poolId, uint256 endTime);
    event PoolEndTimeUpdated(uint256 indexed poolId, uint256 newEndTime);
    event TeamMintedForPool(address indexed user, uint256 indexed poolId);
    event TeamRegistered(address user, uint256[11] playerIds);
    event RewardsDistributed(
        uint256 indexed poolId,
        address indexed participant,
        uint256 reward
    );

    /// @dev Contract constructor
    /// @param _mintPrice Price for minting a team
    /// @param initialOwner Owner of the contract
    constructor(
        uint256 _mintPrice,
        address initialOwner,
        address _developerAddress,
        uint256 _protocolFeePercentage
    ) Ownable(initialOwner) {
        mintPrice = _mintPrice;
        developerAddress = _developerAddress;
        protocolFeePercentage = _protocolFeePercentage;
    }

    function getTeam(address owner) public view returns (Team memory) {
        Team storage team = teams[owner];
        return team;
    }

    function getPoolEndTime(uint256 poolId) public view returns (uint256) {
        require(poolExists(poolId), "Pool does not exist");
        Pool storage pool = pools[poolId];
        return pool.endTime;
    }

    function getPoolParticipants(
        uint256 poolId
    ) public view returns (address[] memory) {
        require(poolExists(poolId), "Pool does not exist");
        Pool storage pool = pools[poolId];
        return pool.participants;
    }

    function getPoolTotalEth(uint256 poolId) public view returns (uint256) {
        require(poolExists(poolId), "Pool does not exist");
        Pool storage pool = pools[poolId];
        return pool.totalEth;
    }

    function poolExists(uint256 poolId) public view returns (bool) {
        return pools[poolId].endTime != 0;
    }

    /// @notice Registers a new team with given player IDs
    /// @param playerIds Array of player IDs for the team
    function registerTeam(uint256[11] memory playerIds) public {
        Team storage team = teams[msg.sender];
        for (uint256 i = 0; i < 11; i++) {
            team.players[i] = Player(playerIds[i], 0);
        }
        team.exists = true;
        team.owner = msg.sender;
        emit TeamRegistered(msg.sender, playerIds);
    }

    // New Function to Set Protocol Fee
    function setProtocolFee(uint256 newFee) public onlyOwner {
        protocolFeePercentage = newFee;
    }

    // New Function to Set Developer Address
    function setDeveloperAddress(address newAddress) public onlyOwner {
        developerAddress = newAddress;
    }

    /// @notice Mints a team and adds it to a pool
    /// @param _poolId ID of the pool to add the team to
    function mintTeam(
        // uint256[11] calldata playerIds,
        uint256 _poolId
    ) public payable {
        Team storage team = teams[msg.sender];

        require(msg.value == mintPrice, "Incorrect mint price");
        require(team.exists, "Team does not exist");
        require(poolExists(_poolId), "Specified pool does not exist");
        require(
            !isParticipantInPool(_poolId, msg.sender),
            "Already participated in this pool"
        );

        uint256 fee = (msg.value * protocolFeePercentage) / 100;
        uint256 remainingValue = msg.value - fee;

        // Transfer fee to developer
        accumulatedFees += fee;

        pools[_poolId].participants.push(msg.sender);
        pools[_poolId].totalEth += remainingValue;

        emit TeamMintedForPool(msg.sender, _poolId);
    }

    // Set player ratings, owner only
    function setPlayerRating(uint256 playerId, uint8 rating) public onlyOwner {
        require(playerId > 0, "Invalid player ID");
        require(rating >= 0, "Invalid player rating");
        require(rating <= 10, "Invalid player rating");

        playerRatings[playerId] = rating;
    }

    // Owner creates a new pool with an end time
    function createPool(uint256 _endTime) public onlyOwner {
        require(_endTime > block.timestamp, "End time must be in the future");

        Pool storage newPool = pools[nextPoolId];
        newPool.endTime = _endTime;
        newPool.totalEth = 0;
        newPool.rewardsDistributed = false;
        newPool.participants = new address[](0);

        emit PoolCreated(nextPoolId, _endTime);
        nextPoolId++;
    }

    // Owner updates the end time of a pool
    function updatePoolEndTime(
        uint256 _poolId,
        uint256 _newEndTime
    ) public onlyOwner {
        require(poolExists(_poolId), "Specified pool does not exist");
        require(
            _newEndTime > block.timestamp,
            "New end time must be in the future"
        );
        require(pools[_poolId].endTime != 0, "Pool does not exist");
        pools[_poolId].endTime = _newEndTime;
        emit PoolEndTimeUpdated(_poolId, _newEndTime);
    }

    function isParticipantInPool(
        uint256 poolId,
        address participant
    ) public view returns (bool) {
        require(poolExists(poolId), "Pool does not exist");
        Pool storage pool = pools[poolId];
        for (uint256 i = 0; i < pool.participants.length; i++) {
            if (pool.participants[i] == participant) {
                return true;
            }
        }
        return false;
    }

    // Function to calculate a team's total score
    function calculateTeamScore(
        address teamOwner
    ) public view returns (uint256) {
        uint256 score = 0;
        Team storage team = teams[teamOwner];
        for (uint256 i = 0; i < team.players.length; i++) {
            score += playerRatings[team.players[i].id];
        }
        return score;
    }

    /// @notice Distributes rewards for a pool
    /// @param _poolId ID of the pool to distribute rewards for
    function distributeRewards(uint256 _poolId) public {
        Pool storage pool = pools[_poolId];
        require(pool.endTime != 0, "Pool does not exist");
        require(block.timestamp > pool.endTime, "Pool has not ended yet");
        require(!pool.rewardsDistributed, "Rewards already distributed");

        uint256 totalScore = 0;
        uint256 precision = 1e18; // High precision factor

        // Calculate total score for each participant's team
        for (uint256 i = 0; i < pool.participants.length; i++) {
            address participant = pool.participants[i];
            uint256 teamScore = calculateTeamScore(participant);
            pool.participantScores[participant] = teamScore;
            totalScore += teamScore;
        }

        // Distribute rewards based on team score
        uint256 totalEthWithPrecision = pool.totalEth * precision;

        // Distribute rewards based on team score with high precision
        for (uint256 i = 0; i < pool.participants.length; i++) {
            address participant = pool.participants[i];
            uint256 participantScore = pool.participantScores[participant];
            uint256 reward = (totalEthWithPrecision * participantScore) /
                (totalScore * precision);

            // Transfer reward to participant
            (bool sent, ) = participant.call{value: reward}("");
            require(sent, "Failed to send Ether");

            pool.totalEth -= reward;
            emit RewardsDistributed(_poolId, participant, reward);
        }

        pool.rewardsDistributed = true;
    }

    // Function for the developer to withdraw accumulated fees
    function withdrawFees() public {
        require(
            msg.sender == developerAddress,
            "Only developer can withdraw fees"
        );

        uint256 fees = accumulatedFees;
        accumulatedFees = 0;

        (bool success, ) = developerAddress.call{value: fees}("");
        require(success, "Failed to send Ether");
    }

    // Functions to allow the contract to receive Ether
    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}