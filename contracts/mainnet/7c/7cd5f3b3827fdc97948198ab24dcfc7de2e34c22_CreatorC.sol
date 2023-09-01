/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;

/// @title CreatorC
/// @notice Help you record your creative process and create a blockchain stamp
/// @dev a project commit system
contract CreatorC {
    /// @dev Commit struct, a commit of a project
    struct Commit {
        string userId;
        string commitId;
        string username;
        string fileHash;
    }

    /// @dev Member struct
    struct Member {
        string name;
        /// @dev Mapping the uuid of the project to the commits of the project
        mapping(string => Commit[]) commits;
    }

    /// @dev Mapping of members
    mapping(address => Member) internal members;

    /// @dev constructor
    constructor() {}

    /// @dev event when a commit is created
    event CommitCreated(
        address indexed account,
        string indexed userId,
        string commitId,
        string username,
        uint256 indexed commitIndex,
        uint256 blockNumber,
        uint256 txGasprice,
        uint256 gasleft
    );

    /// @dev adds a commit to the members struct
    /// @param userId - user id
    /// @param commitId - commit id
    /// @param username - user name
    /// @param fileHash - commit file hash
    function createCommit(
        string memory userId,
        string memory commitId,
        string memory username,
        string memory fileHash
    ) public {
        // get the member
        Member storage member = members[msg.sender];
        member.name = username;

        // create the commit
        Commit memory commit;
        commit.userId = userId;
        commit.commitId = commitId;
        commit.username = username;
        commit.fileHash = fileHash;

        // add the commit to the members struct
        member.commits[userId].push(commit);

        // emit event
        emit CommitCreated(
            msg.sender,
            userId,
            commitId,
            username,
            member.commits[userId].length - 1,
            block.number,
            tx.gasprice,
            gasleft()
        );
    }
}