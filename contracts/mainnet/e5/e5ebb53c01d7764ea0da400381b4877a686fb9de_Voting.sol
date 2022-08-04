/**
 *Submitted for verification at Arbiscan on 2022-08-04
*/

/**
 *Submitted for verification at Arbiscan on 2022-08-2
*/

// SPDX-License

pragma solidity ^0.8.10; //We have to specify what version of compiler this code will use

contract Voting {
  /* mapping is equivalent to an associate array or hash
  The key of the mapping is candidate name stored as type bytes and value is
  an unsigned integer which used to store the vote count
  */
  mapping (string => uint8) public votesReceived;
  
  /* Solidity doesn't let you create an array of strings yet. We will use an array of bytes32 instead to store
  the list of candidates
  */
  
  string[] public candidateList;

  // Initialize all the contestants
  constructor(string[] memory candidateNames) {
    candidateList = candidateNames;
  }

  function totalVotesFor(string memory candidate) public view returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  function voteForCandidate(string memory candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }

  function validCandidate(string memory candidate) public view returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (keccak256(bytes(candidateList[i])) == keccak256(bytes(candidate))) {
        return true;
      }
    }
    return false;
  }

  // This function returns the list of candidates.
  function getCandidateList() public view returns (string[] memory) {
    return candidateList;
  }
}