//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IRandomizer.sol";

// Single implementation of randomizer. Currently does not use ChainLink VRF as CL is not supported on Arbitrum.
// When CL supports Arbitrum, the goal is to switch this contract to use VRF.
// Open for all to use.
contract RandomizerMock is IRandomizer {
    event RandomRequest(uint256 indexed _requestId, uint256 indexed _commitId);
    event RandomSeeded(uint256 indexed _commitId);

    // RandomIds that are a part of this commit.
    mapping(uint256 => uint256) internal commitIdToRandomSeed;
    mapping(uint256 => uint256) internal requestIdToCommitId;

    uint256 public lastIncrementBlockNum;
    uint256 public commitId;
    uint256 public requestIdCur;
    uint256 public nextCommitIdToSeed;
    uint256 public pendingCommits;
    // The number of blocks after the increment ID was incremeneted that the seed must be supplied after
    uint8 public numBlocksAfterIncrement;
    // The number of blocks between the last increment and the next time the commit will be incremented.
    // This only applies to other contracts requesting a random, and us piggy backing of of
    // their request to increment the ID.
    uint8 public numBlocksUntilNextIncrement;

    constructor() {
        numBlocksAfterIncrement = 1;
        requestIdCur = 1;
        nextCommitIdToSeed = 1;
        commitId = 1;
        numBlocksUntilNextIncrement = 0;
    }

    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external {
        numBlocksAfterIncrement = _numBlocksAfterIncrement;
    }

    function setNumBlocksUntilNextIncrement(uint8 _numBlocksUntilNextIncrement) external {
        numBlocksUntilNextIncrement = _numBlocksUntilNextIncrement;
    }

    function incrementCommitId() external {
        require(pendingCommits > 0, "No pending requests");
        _incrementCommitId();
    }

    function addRandomForCommit(uint256 _seed) external {
        require(block.number >= lastIncrementBlockNum + numBlocksAfterIncrement, "No random on same block");
        require(commitId > nextCommitIdToSeed, "Commit id must be higher");

        commitIdToRandomSeed[nextCommitIdToSeed] = _seed;

        emit RandomSeeded(nextCommitIdToSeed);

        nextCommitIdToSeed++;
    }

    function requestRandomNumber() external override returns (uint256) {
        uint256 _requestId = requestIdCur;

        requestIdToCommitId[_requestId] = commitId;

        requestIdCur++;
        pendingCommits++;

        emit RandomRequest(_requestId, commitId);

        // If not caught up on seeding, don't bother pushing the commit id foward.
        // Will save us gas later.
        if (
            commitId == nextCommitIdToSeed &&
            numBlocksUntilNextIncrement > 0 &&
            lastIncrementBlockNum + numBlocksUntilNextIncrement <= block.number
        ) {
            _incrementCommitId();
        }

        return _requestId;
    }

    function _incrementCommitId() private {
        commitId++;
        lastIncrementBlockNum = block.number;
        pendingCommits = 0;
    }

    function revealRandomNumber(uint256 _requestId) external view override returns (uint256) {
        uint256 _commitIdForRequest = requestIdToCommitId[_requestId];
        require(_commitIdForRequest > 0, "Bad request ID");

        uint256 _randomSeed = commitIdToRandomSeed[_commitIdForRequest];
        require(_randomSeed > 0, "Random seed not set");

        // Combine the seed with the request id so each request id on this commit has a different number
        uint256 randomNumber = uint256(keccak256(abi.encode(_randomSeed, _requestId)));

        return randomNumber;
    }

    function isRandomReady(uint256 _requestId) external view override returns (bool) {
        return commitIdToRandomSeed[requestIdToCommitId[_requestId]] != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IRandomizer {
    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns (uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId) external view returns (uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns (bool);
}