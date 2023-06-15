/**
 *Submitted for verification at Arbiscan on 2023-06-14
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.9;

/**
 *  @title ReputeX Contract to create score.
 *
 *  @author ReputeX.io
 *
 *  @notice A smart contract to manage ReputeX scores for addresses
 *
 *  @dev This contract allows the owner to add ReputeX scores for specific addresses
 *
 *  @custom:experimental This is an experimental contract.
 *
 */
contract ReputeXScoreRegistry {
    struct ReputeXScoreData {
        address userAddress;
        uint256 score;
        string message;
    }

    /// Emitted when addScore function is called
    event ReputeXScoreCreated(address indexed userAddress, uint256 score, string message);

    /// Mapping individual ReputeXScoreData details
    mapping(address => ReputeXScoreData) public scores;
    address public owner;

    /**
     * @dev Contract constructor
     * Sets the contract owner to the deployer
     */
    constructor() {
        owner = msg.sender;
    }

    /// Modifier for default owner role
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    /**
     * @dev Adds a ReputeX score for a given address
     * @param _userAddress address for which score is generated
     * @param _score ReputeX score for given address
     * @param _message Message associated with the score
     */
    function addScore(address _userAddress, uint256 _score,string memory _message) public onlyOwner {
        scores[_userAddress] = ReputeXScoreData(_userAddress, _score, _message);
        emit ReputeXScoreCreated(_userAddress, _score, _message);
    }
}