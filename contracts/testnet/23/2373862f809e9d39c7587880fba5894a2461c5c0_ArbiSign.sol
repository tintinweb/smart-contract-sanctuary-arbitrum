/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract ArbiSign {

    mapping(bytes32 => mapping(address => uint256)) public signaturesByContent;
    mapping(bytes32 => address[]) public signersByContentHash;
    mapping(address => bytes32[]) public userSignatures;

    event ContentSigned(address indexed signer, bytes32 indexed contentHash, uint256 timestamp);

    function signContent(string memory _content) external {
        bytes32 contentHash = keccak256(abi.encodePacked(_content));
        require(signaturesByContent[contentHash][msg.sender] == 0, "Content already signed by this address");

        uint256 timestamp = block.timestamp;
        signaturesByContent[contentHash][msg.sender] = timestamp;
        signersByContentHash[contentHash].push(msg.sender);
        userSignatures[msg.sender].push(contentHash);

        emit ContentSigned(msg.sender, contentHash, timestamp);
    }

    function verifySignature(string memory _content, address _signer) external view returns (bool) {
         bytes32 contentHash = keccak256(abi.encodePacked(_content));
        return signaturesByContent[contentHash][_signer] > 0;
    }

  function getSignaturesByAddress(address _signer, uint startIndex, uint pageSize) external view returns (bytes32[] memory, uint256[] memory, uint) {
        uint length = userSignatures[_signer].length;

        uint endIndex = startIndex + pageSize;
        if (endIndex > length) endIndex = length;
        uint returnSize = endIndex - startIndex;

        bytes32[] memory hashes = new bytes32[](returnSize);
        uint256[] memory timestamps = new uint256[](returnSize);

        for (uint i = startIndex; i < endIndex; i++) {
            hashes[i - startIndex] = userSignatures[_signer][i];
            timestamps[i - startIndex] = signaturesByContent[hashes[i - startIndex]][_signer];
        }

        uint totalPages = (length / pageSize) + ((length % pageSize > 0) ? 1 : 0);

        return (hashes, timestamps, totalPages);
    }

    function getSignaturesByContentHash(bytes32 _contentHash, uint startIndex, uint pageSize) external view returns (address[] memory, uint256[] memory, uint) {
        uint length = signersByContentHash[_contentHash].length;

        uint endIndex = startIndex + pageSize;
        if (endIndex > length) endIndex = length;
        uint returnSize = endIndex - startIndex;

        address[] memory signers = new address[](returnSize);
        uint256[] memory timestamps = new uint256[](returnSize);

        for (uint i = startIndex; i < endIndex; i++) {
            signers[i - startIndex] = signersByContentHash[_contentHash][i];
            timestamps[i - startIndex] = signaturesByContent[_contentHash][signers[i - startIndex]];
        }

        uint totalPages = (length / pageSize) + ((length % pageSize > 0) ? 1 : 0);

        return (signers, timestamps, totalPages);
    }

    function getTotalSignaturesByAddress(address _signer) external view returns (uint) {
        return userSignatures[_signer].length;
    }

    function getTotalSignersByContentHash(bytes32 _contentHash) external view returns (uint) {
        return signersByContentHash[_contentHash].length;
    }
}