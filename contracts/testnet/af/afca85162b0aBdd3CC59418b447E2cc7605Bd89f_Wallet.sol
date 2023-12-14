// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//     function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[3] calldata _pubSignals) public view returns (bool) {

interface IVerifier {
  function verifyProof(
    uint256[2] calldata _pA,
    uint256[2][2] calldata _pB,
    uint256[2] calldata _pC,
    uint256[3] calldata _pubSignals
  ) external view returns (bool);
}

contract Wallet {
    uint256 private featureVectorHash;
    uint256 private hashOfPersonalInfoHash;
    mapping (uint256 => bool) private usedNullifierHash;
    uint256[128] private commitment;
    address private owner;
    address private verifierAddress;

    event RecoveryRegistered(address indexed owner, uint256 featureVectorHash);
    event WalletRecovered(address indexed newOwner, uint256 nullifierHash);


    constructor(address _verifierAddress){
        owner = msg.sender;
        verifierAddress = _verifierAddress;
    }
 
    function registerForRecovery(uint256 _featureVectorHash, uint256 _hashOfPersonalInfoHash, uint256[128] memory _commitment) public returns(bool){
        require(msg.sender == owner, "Only owner can register for recovery");
        featureVectorHash = _featureVectorHash;
        hashOfPersonalInfoHash = _hashOfPersonalInfoHash;
        commitment = _commitment;
        emit RecoveryRegistered(owner, _featureVectorHash);
        return true;
    }

    function recoverWallet(uint256[2] memory _a, uint256[2][2] memory _b, uint256[2] memory _c, uint256[3] memory _input) public returns(bool){
        require(IVerifier(verifierAddress).verifyProof(_a, _b, _c, _input), "Invalid proof");
        require(_input[0] == featureVectorHash, "Invalid feature vector hash");
        require(_input[2] == hashOfPersonalInfoHash, "Invalid hash of personal info hash");
        require(!usedNullifierHash[_input[1]], "Nullifier hash already used");
        usedNullifierHash[_input[1]] = true;
        owner = msg.sender;
        emit WalletRecovered(msg.sender, _input[1]);
        return true;
    }

    function removeRecovery(uint256[128] memory _zeroCommitment) public returns(bool){
        require(msg.sender == owner, "Only owner can remove recovery");
        bool hasNonZeroElement=false;
        for(uint i = 0; i < 128; i++){
            if(_zeroCommitment[i] != 0){
                hasNonZeroElement = true;
                break;
            }   
        }
        require(hasNonZeroElement==false, "Invalid ZeroCommitment");
        featureVectorHash = 0;
        hashOfPersonalInfoHash = 0;
        commitment = _zeroCommitment;
        return true;
    }

    function getFeatureVectorHash() public view returns (uint256) {
        return featureVectorHash;
    }

    function getHashOfPersonalInfoHash() public view returns (uint256) {
        return hashOfPersonalInfoHash;
    }

    function getCommitment() public view returns (uint256[128] memory) {
        return commitment;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getVerifierAddress() public view returns (address) {
        return verifierAddress;
    }

    function setVerifierAddress(address _verifierAddress) public {
        require(msg.sender == owner, "Only owner can set verifier address");
        verifierAddress = _verifierAddress;
    }

}