// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

contract SnapshotSigner {
    address public immutable deployedAt;
    address public immutable signMessageLib;

    error InvalidAddress(address givenAddress);
    error InvalidCall();
    error SignMessageLibCallFailed();

    struct Domain {
        string name;
        string version;
    }
    bytes32 private constant DOMAIN_TYPE_HASH = keccak256("EIP712Domain(string name,string version)");

    struct Vote {
        address from;
        string space;
        uint64 timestamp;
        bytes32 proposal;
        uint32 choice;
        string reason;
        string app;
        string metadata;
    }
    bytes32 private constant VOTE_TYPE_HASH =
        keccak256(
            "Vote(address from,string space,uint64 timestamp,bytes32 proposal,uint32 choice,string reason,string app,string metadata)"
        );

    struct VoteArray {
        address from;
        string space;
        uint64 timestamp;
        bytes32 proposal;
        uint32[] choice;
        string reason;
        string app;
        string metadata;
    }
    bytes32 private constant VOTE_ARRAY_TYPE_HASH =
        keccak256(
            "Vote(address from,string space,uint64 timestamp,bytes32 proposal,uint32[] choice,string reason,string app,string metadata)"
        );

    struct VoteString {
        address from;
        string space;
        uint64 timestamp;
        bytes32 proposal;
        string choice;
        string reason;
        string app;
        string metadata;
    }
    bytes32 private constant VOTE_STRING_TYPE_HASH =
        keccak256(
            "Vote(address from,string space,uint64 timestamp,bytes32 proposal,string choice,string reason,string app,string metadata)"
        );

    constructor(address _signMessageLib) {
        if (_signMessageLib == address(0)) {
            revert InvalidAddress(_signMessageLib);
        }
        signMessageLib = _signMessageLib;
        deployedAt = address(this);
    }

    /**
     * @notice Marks a snapshot vote message as signed.
     * @param vote The snapshot single choice vote message.
     */
    function signSnapshotVote(Vote calldata vote, Domain calldata domain) external {
        _sign(
            abi.encode(
                VOTE_TYPE_HASH,
                vote.from,
                keccak256(bytes(vote.space)),
                vote.timestamp,
                vote.proposal,
                vote.choice,
                keccak256(bytes(vote.reason)),
                keccak256(bytes(vote.app)),
                keccak256(bytes(vote.metadata))
            ),
            domain
        );
    }

    /**
     * @notice Marks a snapshot vote message as signed.
     * @param vote The snapshot multiple choice vote message.
     */
    function signSnapshotArrayVote(VoteArray calldata vote, Domain calldata domain) external {
        _sign(
            abi.encode(
                VOTE_ARRAY_TYPE_HASH,
                vote.from,
                keccak256(bytes(vote.space)),
                vote.timestamp,
                vote.proposal,
                vote.choice,
                keccak256(bytes(vote.reason)),
                keccak256(bytes(vote.app)),
                keccak256(bytes(vote.metadata))
            ),
            domain
        );
    }

    /**
     * @notice Marks a snapshot vote message as signed.
     * @param vote The snapshot string vote message.
     */
    function signSnapshotStringVote(VoteString calldata vote, Domain calldata domain) external {
        _sign(
            abi.encode(
                VOTE_STRING_TYPE_HASH,
                vote.from,
                keccak256(bytes(vote.space)),
                vote.timestamp,
                vote.proposal,
                keccak256(bytes(vote.choice)),
                keccak256(bytes(vote.reason)),
                keccak256(bytes(vote.app)),
                keccak256(bytes(vote.metadata))
            ),
            domain
        );
    }

    function _sign(bytes memory message, Domain calldata domain) internal {
        // First, make sure we're being delegatecalled
        if (address(this) == deployedAt) {
            revert InvalidCall();
        }

        // Then forward to the Safe SignMessageLib in another delegatecall
        (bool success, ) = signMessageLib.delegatecall(
            abi.encodeWithSignature(
                "signMessage(bytes)",
                abi.encodePacked(_toTypedDataHash(_buildDomainSeparator(domain), keccak256(message)))
            )
        );

        if (!success) {
            revert SignMessageLibCallFailed();
        }
    }

    function _buildDomainSeparator(Domain calldata domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPE_HASH, keccak256(bytes(domain.name)), keccak256(bytes(domain.version))));
    }

    /**
     * taken from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MessageHashUtils.sol
     * Copyright (c) 2016-2023 zOS Global Limited and contributors
     * released under MIT license
     *
     * @dev Returns the keccak256 digest of an EIP-712 typed data (ERC-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function _toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}