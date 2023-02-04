// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract BitLog {

    mapping(bytes32 => uint256) private _commitId;
    mapping(uint256 => address) private _commitAuthor;
    mapping(uint256 => uint256) private _commitTime;
    mapping(address => uint256) private _commits;

    event AddCommitEvent(address sender_, address addr_);

    function addCommit(uint256 commitId_, address author_) public returns (bytes32) {
        bytes32 _hash = keccak256(abi.encodePacked(author_, _commits[author_]++));
        _commitId[_hash] = commitId_;
        _commitAuthor[commitId_] = author_;
        _commitTime[commitId_] = block.timestamp;
        emit AddCommitEvent(msg.sender, author_);
        return _hash;
    }

    function getCommitId(bytes32 commitId_) public view returns (uint256) {
        return _commitId[commitId_];
    }

    function getCommitAuthor(uint256 commit_) public view returns (address) {
        return _commitAuthor[commit_];
    }

    function getCommitTime(uint256 commit_) public view returns (uint256) {
        return _commitTime[commit_];
    }

    function getNumCommits(address addr_) public view returns (uint256) {
        return _commits[addr_];
    }

    function getAllCommits(address addr_, uint256 index_) public pure returns (bytes32[] memory) {
        bytes32[] memory commits = new bytes32[](index_);
        for (uint256 i = 0; i < index_; i++) {
            commits[i] = keccak256(abi.encodePacked(addr_, i));
        }
        return commits;
    }

}