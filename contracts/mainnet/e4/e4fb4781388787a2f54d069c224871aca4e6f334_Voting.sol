/**
 *Submitted for verification at Arbiscan on 2022-07-20
*/

pragma solidity ^0.8.10; //We have to specify what version of compiler this code will use

contract Voting {
  /* mapping is equivalent to an associate array or hash
  The key of the mapping is candidate name stored as type bytes32 and value is
  an unsigned integer which used to store the vote count
  */
  mapping (bytes => uint8) public votesReceived;
  
  /* Solidity doesn't let you create an array of strings yet. We will use an array of bytes32 instead to store
  the list of candidates
  */
  
  bytes public candidateList;

  // Initialize all the contestants
  constructor(bytes memory candidateNames) {
    candidateList = candidateNames;
  }

  function totalVotesFor(bytes memory candidate) public returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  function voteForCandidate(bytes memory candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }

  function validCandidate(bytes memory candidate) public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == bytes1(candidate)) {
        return true;
      }
    }
    return false;
  }

  // This function returns the list of candidates.
  function getCandidateList() public returns (bytes memory) {
    return candidateList;
  }
}