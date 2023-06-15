/**
 *Submitted for verification at Arbiscan on 2023-06-14
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.9;

/**
 *  @title ReputeX Score Request
 *
 *  @author ReputeX.io
 *
 *  @notice A smart contract to request the generation of ReputeX scores 
 *  for addresses on specific chains
 *
 *  @dev This contract allows users to request the generation of 
 *  ReputeX scores for their addresses on specific chains
 *
 *  @custom:experimental This is an experimental contract.
 *
 */
contract ReputeXScoreRequest {

    /// Emitted when generateScore function is called
    event GenerateReputeXScore(address indexed scoreAddress, uint256 chainId);

    struct RequestScoreData {
        address userAddress;
        uint256 chainId;
    }
   
    /// Mapping individual RequestScoreData details
    mapping(address => RequestScoreData) public scores;

  
    /**
     * @dev Request for generating ReputeX score for a given address and on given chain
     * @param _address address for which score will be generated
     * @param _chainId chain ID on which score is required
     */
    function generateScore(address _address,uint256 _chainId) public {
        scores[_address] = RequestScoreData(_address, _chainId);
        emit GenerateReputeXScore(_address, _chainId);
    }
}