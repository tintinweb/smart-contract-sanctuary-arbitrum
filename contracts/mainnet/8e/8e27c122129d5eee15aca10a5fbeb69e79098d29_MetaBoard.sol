// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {IMetaBoardV1} from "../interface/IMetaBoardV1.sol";
import {LibMeta} from "../lib/LibMeta.sol";

contract MetaBoard is IMetaBoardV1 {
    /// @inheritdoc IMetaBoardV1
    function emitMeta(uint256 subject, bytes calldata meta) external {
        LibMeta.checkMetaUnhashedV1(meta);
        emit MetaV1(msg.sender, subject, meta);
    }

    /// Exposes native hashing algorithm (keccak256) to facilitate indexing data
    /// under its hash. This avoids the need to roll a new interface to include
    /// hashes in the event logs.
    function hash(bytes calldata data) external pure returns (bytes32) {
        return keccak256(data);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {IMetaV1} from "./IMetaV1.sol";

/// Defines a general purpose contract that anon may call to emit ANY metadata.
/// Anons MAY send garbage and malicious metadata so it is up to tooling to
/// discard any suspect data before use, and generally treat it all as untrusted.
interface IMetaBoardV1 is IMetaV1 {
    /// Emit a single MetaV1 event. Typically this is sufficient for most use
    /// cases as a single MetaV1 event can contain many metas as a single
    /// cbor-seq. Metadata MUST match the metadata V1 specification for Rain
    /// metadata or tooling MAY drop it. `IMetaBoardV1` contracts MUST revert any
    /// metadata that does not start with the Rain metadata magic number.
    /// @param subject As per `IMetaV1` event.
    /// @param meta As per `IMetaV1` event.
    function emitMeta(uint256 subject, bytes calldata meta) external;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {IMetaV1, UnexpectedMetaHash, NotRainMetaV1, META_MAGIC_NUMBER_V1} from "../interface/IMetaV1.sol";

/// @title LibMeta
/// @notice Need a place to put data that can be handled offchain like ABIs that
/// IS NOT etherscan.
library LibMeta {
    /// Returns true if the metadata bytes are prefixed by the Rain meta magic
    /// number. DOES NOT attempt to validate the body of the metadata as offchain
    /// tooling will be required for this.
    /// @param meta The data that may be rain metadata.
    /// @return True if `meta` is metadata, false otherwise.
    function isRainMetaV1(bytes memory meta) internal pure returns (bool) {
        if (meta.length < 8) return false;
        uint256 mask = type(uint64).max;
        uint256 magicNumber = META_MAGIC_NUMBER_V1;
        assembly ("memory-safe") {
            magicNumber := and(mload(add(meta, 8)), mask)
        }
        return magicNumber == META_MAGIC_NUMBER_V1;
    }

    /// Reverts if the provided `meta` is NOT metadata according to
    /// `isRainMetaV1`.
    /// @param meta The metadata bytes to check.
    function checkMetaUnhashedV1(bytes memory meta) internal pure {
        if (!isRainMetaV1(meta)) {
            revert NotRainMetaV1(meta);
        }
    }

    /// Reverts if the provided `meta` is NOT metadata according to
    /// `isRainMetaV1` OR it does not match the expected hash of its data.
    /// @param meta The metadata to check.
    function checkMetaHashedV1(bytes32 expectedHash, bytes memory meta) internal pure {
        bytes32 actualHash = keccak256(meta);
        if (expectedHash != actualHash) {
            revert UnexpectedMetaHash(expectedHash, actualHash);
        }
        checkMetaUnhashedV1(meta);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

/// Thrown when hashed metadata does NOT match the expected hash.
/// @param expectedHash The hash expected by the `IMetaV1` contract.
/// @param actualHash The hash of the metadata seen by the `IMetaV1` contract.
error UnexpectedMetaHash(bytes32 expectedHash, bytes32 actualHash);

/// Thrown when some bytes are expected to be rain meta and are not.
/// @param unmeta the bytes that are not meta.
error NotRainMetaV1(bytes unmeta);

/// @dev Randomly generated magic number with first bytes oned out.
/// https://github.com/rainprotocol/specs/blob/main/metadata-v1.md
uint64 constant META_MAGIC_NUMBER_V1 = 0xff0a89c674ee7874;

/// @title IMetaV1
interface IMetaV1 {
    /// An onchain wrapper to carry arbitrary Rain metadata. Assigns the sender
    /// to the metadata so that tooling can easily drop/ignore data from unknown
    /// sources. As metadata is about something, the subject MUST be provided.
    /// @param sender The msg.sender.
    /// @param subject The entity that the metadata is about. MAY be the address
    /// of the emitting contract (as `uint256`) OR anything else. The
    /// interpretation of the subject is context specific, so will often be a
    /// hash of some data/thing that this metadata is about.
    /// @param meta Rain metadata V1 compliant metadata bytes.
    /// https://github.com/rainprotocol/specs/blob/main/metadata-v1.md
    event MetaV1(address sender, uint256 subject, bytes meta);
}