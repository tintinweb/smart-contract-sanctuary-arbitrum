// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract FollowContract {

    mapping (address => mapping (address => bool)) followMap;

    event Follow(address indexed user, address follower, uint timestamp);
    event UnFollow(address indexed user, address follower, uint timestamp);

    function followUser(address user) external {
        require(followMap[user][msg.sender] != true, "user is already followed");

        followMap[user][msg.sender] = true;
        emit Follow(user, msg.sender, block.timestamp);
    }

    function unFollowUser(address user) external {
        require(followMap[user][msg.sender] == true, "user is not following");

        followMap[user][msg.sender] = false;
        emit UnFollow(user, msg.sender, block.timestamp);
    }

    function isFollowing(address user, address follower) external view returns (bool) {
        return followMap[user][follower];
    } 

}