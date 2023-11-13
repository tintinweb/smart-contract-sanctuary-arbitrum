// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IAdminACLV0 {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     * @param previousSuperAdmin The previous superAdmin address.
     * @param newSuperAdmin The new superAdmin address.
     * @param genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     */
    event SuperAdminTransferred(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin,
        address[] genArt721CoreAddressesToUpdate
    );

    /// Type of the Admin ACL contract, e.g. "AdminACLV0"
    function AdminACLType() external view returns (string memory);

    /// super admin address
    function superAdmin() external view returns (address);

    /**
     * @notice Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external;

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function renounceOwnershipOn(address _contract) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
/// use the Royalty Registry's IManifold interface for token royalties
import "./IManifold.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 flagship and derivative implementations.
 * This interface extends the IManifold royalty interface in order to
 * add support the Royalty Registry by default.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Base is IManifold {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     */
    event Mint(address indexed _to, uint256 indexed _tokenId);

    /**
     * @notice currentMinter updated to `_currentMinter`.
     * @dev Implemented starting with V3 core
     */
    event MinterUpdated(address indexed _currentMinter);

    /**
     * @notice Platform updated on bytes32-encoded field `_field`.
     */
    event PlatformUpdated(bytes32 indexed _field);

    /**
     * @notice Project ID `_projectId` updated on bytes32-encoded field
     * `_update`.
     */
    event ProjectUpdated(uint256 indexed _projectId, bytes32 indexed _update);

    event ProposedArtistAddressesAndSplits(
        uint256 indexed _projectId,
        address _artistAddress,
        address _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    );

    event AcceptedArtistAddressesAndSplits(uint256 indexed _projectId);

    // version and type of the core contract
    // coreVersion is a string of the form "0.x.y"
    function coreVersion() external view returns (string memory);

    // coreType is a string of the form "GenArt721CoreV3"
    function coreType() external view returns (string memory);

    // owner (pre-V3 was named admin) of contract
    // this is expected to be an Admin ACL contract for V3
    function owner() external view returns (address);

    // Admin ACL contract for V3, will be at the address owner()
    function adminACLContract() external returns (IAdminACLV0);

    // backwards-compatible (pre-V3) admin - equal to owner()
    function admin() external view returns (address);

    /**
     * Function determining if _sender is allowed to call function with
     * selector _selector on contract `_contract`. Intended to be used with
     * peripheral contracts such as minters, as well as internally by the
     * core contract itself.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);

    /// getter function of public variable
    function startingProjectId() external view returns (uint256);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(
        uint256 tokenId
    ) external view returns (uint256 projectId);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySales(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySalesPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    function projectIdToSecondaryMarketRoyaltyPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    function projectURIInfo(
        uint256 _projectId
    ) external view returns (string memory projectBaseURI);

    // @dev new function in V3
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        );

    function projectDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory projectName,
            string memory artist,
            string memory description,
            string memory website,
            string memory license
        );

    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        );

    function projectScriptByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (string memory);

    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);

    // function to set a token's hash (must be guarded)
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hash) external;

    // @dev gas-optimized signature in V3 for `mint`
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev Royalty Registry interface, used to support the Royalty Registry.
/// @dev Source: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/specs/IManifold.sol

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {
    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(
        uint256 tokenId
    ) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IPseudorandomAtomic {
    /**
     * @notice This function atomically returns a pseudorandom bytes32 value.
     * @param _entropy entropy to be included during the pseudorandom
     * generation process. An example of entropy might be the hash of a core
     * contract's address, and the ID of the token being generated.
     */
    function getPseudorandomAtomic(bytes32 _entropy) external returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IRandomizer_V3CoreBase {
    /**
     * @notice This function is intended to be called by a core contract, and
     * the core contract can be assured that the randomizer will call back to
     * the calling contract to set the token hash seed for `_tokenId` via
     * `setTokenHash_8PT`.
     * @dev This function may revert if hash seed generation is improperly
     * configured (for example, if in polyptych mode, but no hash seed has been
     * previously configured).
     * @dev This function is not specifically gated to any specific caller, but
     * will only call back to the calling contract, `msg.sender`, to set the
     * specified token's hash seed.
     * A third party contract calling this function will not be able to set the
     * token hash seed on a different core contract.
     * @param _tokenId The token ID must be assigned a hash.
     */
    function assignTokenHash(uint256 _tokenId) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IRandomizer_V3CoreBase.sol";

interface ISharedRandomizerV0 is IRandomizer_V3CoreBase {
    /**
     * @notice The pseudorandom atomic contract that is used to generate
     * pseudorandom values for this randomizer was updated.
     */
    event PseudorandomAtomicContractUpdated(
        address indexed pseudorandomAtomicContract
    );

    /**
     * @notice Contract at `hashSeedSetterContract` allowed to assign
     * token hash seeds on core contract `coreContract` for project
     * `projectId`.
     */
    event HashSeedSetterForProjectUpdated(
        address indexed coreContract,
        uint256 indexed projectId,
        address indexed hashSeedSetterContract
    );

    /**
     * @notice Project with ID `projectId` is is or is not using a hash seed
     * setter contract to assign token hash seeds on core contract.
     */
    event ProjectUsingHashSeedSetterUpdated(
        address coreContract,
        uint256 projectId,
        bool usingHashSeedSetter
    );

    /**
     * @notice Allows the artist of a project to set the contract that is
     * allowed to assign hash seeds to tokens. Typically, this is expected to
     * be a minter contract, such as `MinterPolyptychV1`.
     * @param coreContract - the core contract that is being configured
     * @param projectId - the project ID that is being configured
     * @param hashSeedSetterContract - the contract that is allowed to assign
     * hash seeds to tokens
     */
    function setHashSeedSetterContract(
        address coreContract,
        uint256 projectId,
        address hashSeedSetterContract
    ) external;

    /**
     * @notice Allows the artist of a project to configure their project to
     * only allow the specified hash seed setter contract to assign new token
     * hash seeds. When this is enabled, the hash seed setter contract is
     * responsible for assigning hash seeds to tokens, and the randomizer
     * contract will not use the pseudorandom atomic contract to generate
     * hash seeds.
     * An example use case is where the artist wants to mint a polyptych panel
     * (second, third, etc.) of a project, and therefore wants to re-use
     * specific hash seeds of the original project.
     * @param coreContract - The address of the core contract
     * @param projectId - The ID of the project to be toggled
     */
    function toggleProjectUseAssignedHashSeed(
        address coreContract,
        uint256 projectId
    ) external;

    /**
     * @notice Pre-set the hash seed for a token. This function is only
     * callable by the hash seed setter contract of the project.
     * @param coreContract - The address of the core contract of `tokenId`
     * @param tokenId - The ID of the token to set the hash seed for
     * @param hashSeed - The hash seed to set for `tokenId`
     * @dev Only callable by the hash seed setter contract of `coreContract`.
     */
    function preSetHashSeed(
        address coreContract,
        uint256 tokenId,
        bytes12 hashSeed
    ) external;

    /**
     * @notice Boolean representing whether or not project with ID `projectId`
     * on core contract `coreContract` is currently using a hash seed setter
     * contract to assign hash seeds to tokens.
     */
    function projectUsesHashSeedSetter(
        address coreContract,
        uint256 projectId
    ) external view returns (bool usingHashSeedSetter);

    /**
     * Returns the hash seed setter contract for a given core contract.
     * Returns address(0) if no hash seed setter contract is set for the core.
     * @param coreContract - The address of the core contract
     * @param projectId - The ID of the project to query
     */
    function hashSeedSetterContracts(
        address coreContract,
        uint256 projectId
    ) external view returns (address hashSeedSetterContract);

    /**
     * Returns the current pre-assigned hash seed for a given token ID.
     * Returns bytes12(0) if no hash seed has been set for the token.
     * Note that this only returns the pre-assigned hash seed for tokens that
     * are configured to use a hash seed setter contract. In typical cases
     * where the project is not configured to use a hash seed setter contract,
     * the hash seed is generated on-chain by the pseudorandom atomic contract
     * and is not stored on-chain in this randomizer contract, and therefore
     * this function will return bytes12(0).
     * @param coreContract - The address of the core contract of `tokenId`
     * @param tokenId - The ID of the token to get the hash seed for
     * @return hashSeed - The stored hash seed for `tokenId`
     */
    function preAssignedHashSeed(
        address coreContract,
        uint256 tokenId
    ) external view returns (bytes12 hashSeed);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

// @dev fixed to specific solidity version for clarity and for more clear
// source code verification purposes.
pragma solidity 0.8.19;

import "../../interfaces/v0.8.x/IGenArt721CoreContractV3_Base.sol";
import "../../interfaces/v0.8.x/ISharedRandomizerV0.sol";
import "../../interfaces/v0.8.x/IPseudorandomAtomic.sol";

/**
 * @title A shared randomizer contract that enables support of many Art Blocks
 * and Art Blocks Engine core contracts with a single randomizer.
 * @notice This randomizer is designed to be used with many core contracts that
 * implement the `IGenArt721CoreContractV3_Base` interface. It exclusively uses
 * atomic callbacks, and will assign a token's hash before returning from the
 * `assignTokenHash` function, as long as the call does not revert.
 *
 * The randomizer generates a token's hash seed in one of two ways:
 * 1. If the project of the token is specified as using a hash seed setter
 * contract, the randomizer will assign the token the hash seed as previously
 * pre-set by the project's hash seed setter contract. If no hash seed has
 * been set, the randomizer will revert (will not assign null token hash).
 * 2. If the project of the token is not specified as using a hash seed setter
 * contract, the randomizer will generate a new hash seed using the
 * `IPseudorandomAtomic` contract, which is immutable and set during
 * deployment.
 *
 * @dev When using this randomizer for ployptych minting, several requirements
 * may be required by the hash seed setter contract, including the possibility
 * that a token's hash seed must be available in a public getter function on
 * the core contract. Please inspect the hash seed setter contract to ensure
 * that all requirements are met.
 *
 * @notice Privileged Roles and Ownership:
 * Privileged roles and abilities are controlled by each core contract's
 * artists.
 * These roles hold extensive power and can influence the behavior of this
 * randomizer.
 * Care must be taken to ensure that the artist addresses are secure.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to only the Artist address:
 * - setHashSeedSetterContract
 * - toggleProjectUseAssignedHashSeed
 * ----------------------------------------------------------------------------
 * The following function is restricted to only the hash seed setter contract
 * of a given core contract:
 * - preSetHashSeed
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on minters,
 * registries, and other contracts that may interact with this randomizer.
 */
contract SharedRandomizerV0 is ISharedRandomizerV0 {
    IPseudorandomAtomic public immutable pseudorandomAtomicContract;

    // constant used to obtain the project ID from the token ID
    uint256 internal constant ONE_MILLION = 1_000_000;

    // mapping of core contract => token ID => pre-assigned hash seed
    // @dev this mapping is only used when the project is configured as using
    // a hash seed setter contract. It is not populated when the project is
    // using pseudorandomAtomicContract.
    mapping(address coreContract => mapping(uint256 tokenId => bytes12 preAssignedHashSeed))
        private _preAssignedHashSeeds;

    // mapping of core contract => project ID => usesHashSeedSetter Contract
    mapping(address coreContract => mapping(uint256 projectId => bool usesHashSeedSetter))
        private _projectUsesHashSeedSetter;

    // mapping of core contract => projectId => hash seed setter contract
    mapping(address coreContract => mapping(uint256 projectId => address hashSeedSetterContract))
        private _hashSeedSetterContracts;

    // modifier to restrict access to only Artist allowed calls
    function _onlyArtist(
        address coreContract,
        uint256 projectId
    ) internal view {
        require(
            msg.sender ==
                IGenArt721CoreContractV3_Base(coreContract)
                    .projectIdToArtistAddress(projectId),
            "Only Artist"
        );
    }

    /**
     * Modifier to restrict access to only calls by the hash seed setter
     * contract of a given project.
     * @param coreContract core contract address associated with the project
     * @param projectId project ID being set
     */
    function _onlyHashSeedSetterContract(
        address coreContract,
        uint256 projectId
    ) internal view {
        require(
            msg.sender == _hashSeedSetterContracts[coreContract][projectId],
            "Only Hash Seed Setter Contract"
        );
    }

    /**
     *
     * @param pseudorandomAtomicContract_ Address of the pseudorandom atomic
     * contract to use for atomically generating random values. This contract
     * does not have an owner, and therefore the pseudorandom atomic contract
     * address cannot be changed after deployment.
     */
    constructor(address pseudorandomAtomicContract_) {
        pseudorandomAtomicContract = IPseudorandomAtomic(
            pseudorandomAtomicContract_
        );
        emit PseudorandomAtomicContractUpdated({
            pseudorandomAtomicContract: pseudorandomAtomicContract_
        });
    }

    /**
     * @inheritdoc ISharedRandomizerV0
     */
    function setHashSeedSetterContract(
        address coreContract,
        uint256 projectId,
        address hashSeedSetterContract
    ) external {
        _onlyArtist({projectId: projectId, coreContract: coreContract});
        _hashSeedSetterContracts[coreContract][
            projectId
        ] = hashSeedSetterContract;
        emit HashSeedSetterForProjectUpdated({
            coreContract: coreContract,
            projectId: projectId,
            hashSeedSetterContract: hashSeedSetterContract
        });
    }

    /**
     * @inheritdoc ISharedRandomizerV0
     */
    function toggleProjectUseAssignedHashSeed(
        address coreContract,
        uint256 projectId
    ) external {
        _onlyArtist({projectId: projectId, coreContract: coreContract});
        _projectUsesHashSeedSetter[coreContract][
            projectId
        ] = !_projectUsesHashSeedSetter[coreContract][projectId];
        emit ProjectUsingHashSeedSetterUpdated({
            coreContract: coreContract,
            projectId: projectId,
            usingHashSeedSetter: _projectUsesHashSeedSetter[coreContract][
                projectId
            ]
        });
    }

    /**
     * @inheritdoc ISharedRandomizerV0
     */
    function preSetHashSeed(
        address coreContract,
        uint256 tokenId,
        bytes12 hashSeed
    ) external {
        uint256 projectId = _tokenIdToProjectId(tokenId);
        _onlyHashSeedSetterContract({
            projectId: projectId,
            coreContract: coreContract
        });
        _preAssignedHashSeeds[coreContract][tokenId] = hashSeed;
        // @dev event indicating token hash seed assigned is not required for
        // subgraph indexing because token hash seeds are still assigned
        // atomically in `assignTokenHash` function. If token hash seeds were
        // assigned async, event emission may be required to support subgraph
        // indexing.
    }

    /**
     * @inheritdoc IRandomizer_V3CoreBase
     */
    function assignTokenHash(uint256 tokenId) external {
        // @dev This function is not specifically gated to any specific caller,
        // but will only call back to the calling contract, `msg.sender`, to
        // set the specified token's hash seed.
        // A third party contract calling this function will not be able to set
        // the token hash seed on a different core contract.
        // @dev variables are named to improve readability
        address coreContract = msg.sender;
        uint256 projectId = _tokenIdToProjectId(tokenId);
        bytes32 hashSeed;
        if (_projectUsesHashSeedSetter[coreContract][projectId]) {
            hashSeed = _preAssignedHashSeeds[coreContract][tokenId];
        } else {
            hashSeed = _getPseudorandomAtomic({
                coreContract: coreContract,
                tokenId: tokenId
            });
        }
        // verify that the hash seed is non-zero
        require(hashSeed != 0, "Only non-zero hash seed");
        // assign the token hash seed on the core contract
        IGenArt721CoreContractV3_Base(coreContract).setTokenHash_8PT({
            _tokenId: tokenId,
            _hash: hashSeed
        });
    }

    /**
     * @inheritdoc ISharedRandomizerV0
     */
    function projectUsesHashSeedSetter(
        address coreContract,
        uint256 projectId
    ) external view returns (bool usingHashSeedSetter) {
        return _projectUsesHashSeedSetter[coreContract][projectId];
    }

    /**
     * @inheritdoc ISharedRandomizerV0
     */
    function hashSeedSetterContracts(
        address coreContract,
        uint256 projectId
    ) external view returns (address _hashSeedSetterContract) {
        return _hashSeedSetterContracts[coreContract][projectId];
    }

    /**
     * @inheritdoc ISharedRandomizerV0
     */
    function preAssignedHashSeed(
        address coreContract,
        uint256 tokenId
    ) external view returns (bytes12 _hashSeed) {
        return _preAssignedHashSeeds[coreContract][tokenId];
    }

    /**
     * @notice Internal function to atomically obtain a pseudorandom number
     * from the configured pseudorandom contract.
     * @param coreContract - The core contract that is requesting an atomic
     * pseudorandom number.
     * @param tokenId - The token ID on `coreContract` that is associated
     * with the pseudorandom number request.
     */
    function _getPseudorandomAtomic(
        address coreContract,
        uint256 tokenId
    ) internal returns (bytes32) {
        return
            pseudorandomAtomicContract.getPseudorandomAtomic(
                keccak256(abi.encodePacked(coreContract, tokenId))
            );
    }

    /**
     * @notice Gets the project ID for a given `tokenId`.
     * @param tokenId Token ID to be queried.
     * @return projectId Project ID for given `tokenId`.
     */
    function _tokenIdToProjectId(
        uint256 tokenId
    ) internal pure returns (uint256 projectId) {
        return tokenId / ONE_MILLION;
    }
}