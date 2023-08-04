// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IFoxifyReferral.sol";

contract FoxifyReferral is IFoxifyReferral {
    uint256 public maxTeamID;
    mapping(uint256 => address) public teamOwner;
    mapping(address => uint256) public userTeamID;

    /**
     * @notice Create a new team.
     * @return teamID Newly created team id.
     */
    function createTeam() external returns (uint256 teamID) {
        maxTeamID += 1;
        teamID = maxTeamID;
        teamOwner[teamID] = msg.sender;
        emit TeamCreated(teamID, msg.sender);
    }

    /**
     * @notice Create a new team.
     * @param teamID The id of team for join.
     * @return True if the operation was successful, false otherwise.
     */
    function joinTeam(uint256 teamID) external returns (bool) {
        require(teamID > 0 && teamID <= maxTeamID, "FoxifyReferral: Invalid team id");
        userTeamID[msg.sender] = teamID;
        emit TeamJoined(teamID, msg.sender);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFoxifyReferral {
    function maxTeamID() external view returns (uint256);

    function teamOwner(uint256) external view returns (address);

    function userTeamID(address) external view returns (uint256);

    event TeamCreated(uint256 teamID, address owner);
    event TeamJoined(uint256 indexed teamID, address indexed user);
}