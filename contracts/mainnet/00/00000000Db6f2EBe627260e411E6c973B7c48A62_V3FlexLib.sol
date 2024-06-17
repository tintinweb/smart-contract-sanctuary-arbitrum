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
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Script Storage Library - Minimal Interface for Reader Contracts
 * @notice This interface defines the minimal expected read function(s) for a Bytecode Storage Reader contract.
 */
interface IBytecodeStorageReader_Base {
    /**
     * @notice Read a string from a data contract deployed via BytecodeStorage.
     * @dev may also support reading additional stored data formats in the future.
     * @param address_ address of contract deployed via BytecodeStorage to be read
     * @return data The string data stored at the specific address.
     */
    function readFromBytecode(
        address address_
    ) external view returns (string memory data);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 flagship and derivative implementations.
 * This interface extends the IManifold royalty interface in order to
 * add support the Royalty Registry by default.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Base {
    // This interface emits generic events that contain fields that indicate
    // which parameter has been updated. This is sufficient for application
    // state management, while also simplifying the contract and indexing code.
    // This was done as an alternative to having custom events that emit what
    // field-values have changed for each event, given that changed values can
    // be introspected by indexers due to the design of this smart contract
    // exposing these state changes via publicly viewable fields.

    /**
     * @notice Project's royalty splitter was updated to `_splitter`.
     * @dev New event in v3.2
     * @param projectId The project ID.
     * @param royaltySplitter The new splitter address to receive royalties.
     */
    event ProjectRoyaltySplitterUpdated(
        uint256 indexed projectId,
        address indexed royaltySplitter
    );

    // The following fields are used to indicate which contract-level parameter
    // has been updated in the `PlatformUpdated` event:
    // @dev only append to the end of this enum in the case of future updates
    enum PlatformUpdatedFields {
        FIELD_NEXT_PROJECT_ID, // 0
        FIELD_NEW_PROJECTS_FORBIDDEN, // 1
        FIELD_DEFAULT_BASE_URI, // 2
        FIELD_RANDOMIZER_ADDRESS, // 3
        FIELD_NEXT_CORE_CONTRACT, // 4
        FIELD_ARTBLOCKS_DEPENDENCY_REGISTRY_ADDRESS, // 5
        FIELD_ARTBLOCKS_ON_CHAIN_GENERATOR_ADDRESS, // 6
        FIELD_PROVIDER_SALES_ADDRESSES, // 7
        FIELD_PROVIDER_PRIMARY_SALES_PERCENTAGES, // 8
        FIELD_PROVIDER_SECONDARY_SALES_BPS, // 9
        FIELD_SPLIT_PROVIDER, // 10
        FIELD_BYTECODE_STORAGE_READER // 11
    }

    // The following fields are used to indicate which project-level parameter
    // has been updated in the `ProjectUpdated` event:
    // @dev only append to the end of this enum in the case of future updates
    enum ProjectUpdatedFields {
        FIELD_PROJECT_COMPLETED, // 0
        FIELD_PROJECT_ACTIVE, // 1
        FIELD_PROJECT_ARTIST_ADDRESS, // 2
        FIELD_PROJECT_PAUSED, // 3
        FIELD_PROJECT_CREATED, // 4
        FIELD_PROJECT_NAME, // 5
        FIELD_PROJECT_ARTIST_NAME, // 6
        FIELD_PROJECT_SECONDARY_MARKET_ROYALTY_PERCENTAGE, // 7
        FIELD_PROJECT_DESCRIPTION, // 8
        FIELD_PROJECT_WEBSITE, // 9
        FIELD_PROJECT_LICENSE, // 10
        FIELD_PROJECT_MAX_INVOCATIONS, // 11
        FIELD_PROJECT_SCRIPT, // 12
        FIELD_PROJECT_SCRIPT_TYPE, // 13
        FIELD_PROJECT_ASPECT_RATIO, // 14
        FIELD_PROJECT_BASE_URI, // 15
        FIELD_PROJECT_PROVIDER_SECONDARY_FINANCIALS // 16
    }

    /**
     * @notice Error codes for the GenArt721 contract. Used by the GenArt721Error
     * custom error.
     * @dev only append to the end of this enum in the case of future updates
     */
    enum ErrorCodes {
        OnlyNonZeroAddress, // 0
        OnlyNonEmptyString, // 1
        OnlyNonEmptyBytes, // 2
        TokenDoesNotExist, // 3
        ProjectDoesNotExist, // 4
        OnlyUnlockedProjects, // 5
        OnlyAdminACL, // 6
        OnlyArtist, // 7
        OnlyArtistOrAdminACL, // 8
        OnlyAdminACLOrRenouncedArtist, // 9
        OnlyMinterContract, // 10
        MaxInvocationsReached, // 11
        ProjectMustExistAndBeActive, // 12
        PurchasesPaused, // 13
        OnlyRandomizer, // 14
        TokenHashAlreadySet, // 15
        NoZeroHashSeed, // 16
        OverMaxSumOfPercentages, // 17
        IndexOutOfBounds, // 18
        OverMaxSumOfBPS, // 19
        MaxOf100Percent, // 20
        PrimaryPayeeIsZeroAddress, // 21
        SecondaryPayeeIsZeroAddress, // 22
        MustMatchArtistProposal, // 23
        NewProjectsForbidden, // 24
        NewProjectsAlreadyForbidden, // 25
        OnlyArtistOrAdminIfLocked, // 26
        OverMaxSecondaryRoyaltyPercentage, // 27
        OnlyMaxInvocationsDecrease, // 28
        OnlyGteInvocations, // 29
        ScriptIdOutOfRange, // 30
        NoScriptsToRemove, // 31
        ScriptTypeAndVersionFormat, // 32
        AspectRatioTooLong, // 33
        AspectRatioNoNumbers, // 34
        AspectRatioImproperFormat, // 35
        OnlyNullPlatformProvider, // 36
        ContractInitialized // 37
    }

    /**
     * @notice Emits an error code `_errorCode` in the GenArt721Error event.
     * @dev Emitting error codes instead of error strings saves significant
     * contract bytecode size, allowing for more contract functionality within
     * the 24KB contract size limit.
     * @param _errorCode The error code to emit. See ErrorCodes enum.
     */
    error GenArt721Error(ErrorCodes _errorCode);

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

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Engine.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 Engine Flex and derivative implementations.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Engine_Flex is
    IGenArt721CoreContractV3_Engine
{
    /**
     * @notice When an external asset dependency is updated or added, this event is emitted.
     * @param _projectId The project ID of the project that was updated.
     * @param _index The index of the external asset dependency that was updated.
     * @param _cid Field that contains the CID of the dependency if IPFS or ARWEAVE, empty string of ONCHAIN, or a string representation
     * of the Art Blocks Dependency Registry's `dependencyNameAndVersion` if ART_BLOCKS_DEPENDENCY_REGISTRY.
     * @param _dependencyType The type of the external asset dependency.
     * @param _externalAssetDependencyCount The number of external asset dependencies.
     */
    event ExternalAssetDependencyUpdated(
        uint256 indexed _projectId,
        uint256 indexed _index,
        string _cid,
        ExternalAssetDependencyType _dependencyType,
        uint24 _externalAssetDependencyCount
    );

    /**
     * @notice The project id `_projectId` has had an external asset dependency removed at index `_index`.
     */
    event ExternalAssetDependencyRemoved(
        uint256 indexed _projectId,
        uint256 indexed _index
    );

    /**
     * @notice The preferred gateway for dependency type `_dependencyType` has been updated to `_gatewayAddress`.
     */
    event GatewayUpdated(
        ExternalAssetDependencyType indexed _dependencyType,
        string _gatewayAddress
    );

    /**
     * @notice The project id `_projectId` has had all external asset dependencies locked.
     * @dev This is a one-way operation. Once locked, the external asset dependencies cannot be updated.
     */
    event ProjectExternalAssetDependenciesLocked(uint256 indexed _projectId);

    /**
     * @notice An external asset dependency type. Can be one of IPFS, ARWEAVE, ONCHAIN, or ART_BLOCKS_DEPENDENCY_REGISTRY.
     */
    enum ExternalAssetDependencyType {
        IPFS,
        ARWEAVE,
        ONCHAIN,
        ART_BLOCKS_DEPENDENCY_REGISTRY
    }

    /**
     * @notice Project storage that relate to Flex data.
     */
    struct ProjectFlex {
        bool externalAssetDependenciesLocked;
        uint24 externalAssetDependencyCount;
        mapping(uint256 => ExternalAssetDependency) externalAssetDependencies;
    }

    /**
     * @notice An external asset dependency, without the retrieved data of any ONCHAIN assets. This reflects what is
     * stored in this contract's storage.
     * @param CID field that contains the CID of the dependency if IPFS or ARWEAVE, empty string of ONCHAIN, or a string representation
     * of the Art Blocks Dependency Registry's `dependencyNameAndVersion` if ART_BLOCKS_DEPENDENCY_REGISTRY.
     * @param dependencyType field that contains the type of the dependency.
     * @param bytecodeAddress field that contains the address of the bytecode for this dependency if ONCHAIN, null address otherwise.
     */
    struct ExternalAssetDependency {
        string cid;
        ExternalAssetDependencyType dependencyType;
        address bytecodeAddress;
    }

    /**
     * @notice An external asset dependency with data. This is a convenience struct.
     * @param CID field that contains the CID of the dependency if IPFS or ARWEAVE, empty string of ONCHAIN, or a string representation
     * of the Art Blocks Dependency Registry's `dependencyNameAndVersion` if ART_BLOCKS_DEPENDENCY_REGISTRY.
     * @param dependencyType field that contains the type of the dependency.
     * @param bytecodeAddress field that contains the address of the bytecode for this dependency if ONCHAIN, null address otherwise.
     * @param data field that contains the data retrieved from this bytecode address if ONCHAIN, empty string otherwise.
     */
    struct ExternalAssetDependencyWithData {
        string cid;
        ExternalAssetDependencyType dependencyType;
        address bytecodeAddress;
        string data;
    }

    // preferredIPFSGateway is a url string
    function preferredIPFSGateway() external view returns (string memory);

    // preferredArweaveGateway is a url string
    function preferredArweaveGateway() external view returns (string memory);

    // updates the preferred IPFS gateway
    function updateIPFSGateway(string calldata _gateway) external;

    // updates the preferred Arweave gateway
    function updateArweaveGateway(string calldata _gateway) external;

    // locks the external asset dependencies for a project
    function lockProjectExternalAssetDependencies(uint256 _projectId) external;

    // updates the external asset dependency for a project at a given index
    function updateProjectExternalAssetDependency(
        uint256 _projectId,
        uint256 _index,
        string memory _cidOrData,
        ExternalAssetDependencyType _dependencyType
    ) external;

    // adds an external asset dependency for a project
    function addProjectExternalAssetDependency(
        uint256 _projectId,
        string memory _cidOrData,
        ExternalAssetDependencyType _dependencyType
    ) external;

    // removes an external asset dependency for a project at a given index
    function removeProjectExternalAssetDependency(
        uint256 _projectId,
        uint256 _index
    ) external;

    // getter function for project external asset dependencies
    function projectExternalAssetDependencyByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (ExternalAssetDependencyWithData memory);

    // getter function project external asset dependency count
    function projectExternalAssetDependencyCount(
        uint256 _projectId
    ) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";
import "./ISplitProviderV0.sol";

/**
 * @notice Struct representing Engine contract configuration.
 * @param tokenName Name of token.
 * @param tokenSymbol Token symbol.
 * @param renderProviderAddress address to send render provider revenue to
 * @param randomizerContract Randomizer contract.
 * @param splitProviderAddress Address to use as royalty splitter provider for the contract.
 * @param minterFilterAddress Address of the Minter Filter to set as the Minter
 * on the contract.
 * @param startingProjectId The initial next project ID.
 * @param autoApproveArtistSplitProposals Whether or not to always
 * auto-approve proposed artist split updates.
 * @param nullPlatformProvider Enforce always setting zero platform provider fees and addresses.
 * @param allowArtistProjectActivation Allow artist to activate their own projects.
 * @dev _startingProjectId should be set to a value much, much less than
 * max(uint248), but an explicit input type of `uint248` is used as it is
 * safer to cast up to `uint256` than it is to cast down for the purposes
 * of setting `_nextProjectId`.
 */
struct EngineConfiguration {
    string tokenName;
    string tokenSymbol;
    address renderProviderAddress;
    address platformProviderAddress;
    address newSuperAdminAddress;
    address randomizerContract;
    address splitProviderAddress;
    address minterFilterAddress;
    uint248 startingProjectId;
    bool autoApproveArtistSplitProposals;
    bool nullPlatformProvider;
    bool allowArtistProjectActivation;
}

interface IGenArt721CoreContractV3_Engine is IGenArt721CoreContractV3_Base {
    // @dev new function in V3.2
    /**
     * @notice Initializes the contract with the provided `engineConfiguration`.
     * This function should be called atomically, immediately after deployment.
     * Only callable once. Validation on `engineConfiguration` is performed by caller.
     * @param engineConfiguration EngineConfiguration to configure the contract with.
     * @param adminACLContract_ Address of admin access control contract, to be
     * set as contract owner.
     * @param defaultBaseURIHost Base URI prefix to initialize default base URI with.
     * @param bytecodeStorageReaderContract_ Address of the bytecode storage reader contract.
     */
    function initialize(
        EngineConfiguration calldata engineConfiguration,
        address adminACLContract_,
        string memory defaultBaseURIHost,
        address bytecodeStorageReaderContract_
    ) external;

    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 renderProviderRevenue_,
            address payable renderProviderAddress_,
            uint256 platformProviderRevenue_,
            address payable platformProviderAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev The render provider primary sales payment address
    function renderProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider primary sales payment address
    function platformProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Percentage of primary sales allocated to the render provider
    function renderProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev Percentage of primary sales allocated to the platform provider
    function platformProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    /** @notice The default render provider payment address for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default render provider payment address for secondary sales royalties.
     */
    function defaultRenderProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    /** @notice The default platform provider payment address for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default platform provider payment address for secondary sales royalties.
     */
    function defaultPlatformProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    /** @notice The default render provider payment basis points for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default render provider payment basis points for secondary sales royalties.
     */
    function defaultRenderProviderSecondarySalesBPS()
        external
        view
        returns (uint256);

    /** @notice The default platform provider payment basis points for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default platform provider payment basis points for secondary sales royalties.
     */
    function defaultPlatformProviderSecondarySalesBPS()
        external
        view
        returns (uint256);

    /**
     * @notice The address of the current split provider being used by the contract.
     * @return The address of the current split provider.
     */
    function splitProvider() external view returns (ISplitProviderV0);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc. to support the 0xSplits V2 integration
// Sourced from:
//  - https://github.com/0xSplits/splits-contracts-monorepo/blob/main/packages/splits-v2/src/libraries/SplitV2.sol
//  - https://github.com/0xSplits/splits-contracts-monorepo/blob/main/packages/splits-v2/src/splitters/SplitFactoryV2.sol

pragma solidity ^0.8.0;

interface ISplitFactoryV2 {
    /* -------------------------------------------------------------------------- */
    /*                                   STRUCTS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Split struct
     * @dev This struct is used to store the split information.
     * @dev There are no hard caps on the number of recipients/totalAllocation/allocation unit. Thus the chain and its
     * gas limits will dictate these hard caps. Please double check if the split you are creating can be distributed on
     * the chain.
     * @param recipients The recipients of the split.
     * @param allocations The allocations of the split.
     * @param totalAllocation The total allocation of the split.
     * @param distributionIncentive The incentive for distribution. Limits max incentive to 6.5%.
     */
    struct Split {
        address[] recipients;
        uint256[] allocations;
        uint256 totalAllocation;
        uint16 distributionIncentive;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 FUNCTIONS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Create a new split with params and owner.
     * @param _splitParams Params to create split with.
     * @param _owner Owner of created split.
     * @param _creator Creator of created split.
     * @param _salt Salt for create2.
     * @return split Address of the created split.
     */
    function createSplitDeterministic(
        Split calldata _splitParams,
        address _owner,
        address _creator,
        bytes32 _salt
    ) external returns (address split);

    /**
     * @notice Predict the address of a new split and check if it is deployed.
     * @param _splitParams Params to create split with.
     * @param _owner Owner of created split.
     * @param _salt Salt for create2.
     */
    function isDeployed(
        Split calldata _splitParams,
        address _owner,
        bytes32 _salt
    ) external view returns (address split, bool exists);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

import {ISplitFactoryV2} from "./integration-refs/splits-0x-v2/ISplitFactoryV2.sol";

interface ISplitProviderV0 {
    /**
     * @notice SplitInputs struct defines the inputs for requested splitters.
     * It is defined in a way easily communicated from the Art Blocks GenArt721V3 contract,
     * to allow for easy integration and minimal additional bytecode in the GenArt721V3 contract.
     */
    struct SplitInputs {
        address platformProviderSecondarySalesAddress;
        uint16 platformProviderSecondarySalesBPS;
        address renderProviderSecondarySalesAddress;
        uint16 renderProviderSecondarySalesBPS;
        uint8 artistTotalRoyaltyPercentage;
        address artist;
        address additionalPayee;
        uint8 additionalPayeePercentage;
    }

    /**
     * @notice Emitted when a new splitter contract is created.
     * @param splitter address of the splitter contract
     */
    event SplitterCreated(address indexed splitter);

    /**
     * @notice Gets or creates an immutable splitter contract at a deterministic address.
     * Splits in the splitter contract are determined by the input split parameters,
     * so we can safely create the splitter contract at a deterministic address (or use
     * the existing splitter contract if it already exists at that address).
     * @dev Uses the 0xSplits v2 implementation to create a splitter contract
     * @param splitInputs The split input parameters.
     * @return splitter The newly created splitter contract address.
     */
    function getOrCreateSplitter(
        SplitInputs calldata splitInputs
    ) external returns (address);

    /**
     * @notice Indicates the type of the contract, e.g. `SplitProviderV0`.
     * @return type_ The type of the contract.
     */
    function type_() external pure returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import {LibZip} from "solady/src/utils/LibZip.sol";

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Script Storage Library
 * @notice Utilize contract bytecode as persistent storage for large chunks of script string data.
 *         V2 includes optional on-chain compression/decompression via solady LibZip.
 *         This library is intended to have an external deployed copy that is released in the future,
 *         and, as such, has been designed to support both updated V2 and V1 (versioned, with purging removed)
 *         reads as well as backwards-compatible reads for both a) the unversioned "V0" storage contracts
 *         which were deployed by the original version of this libary and b) contracts that were deployed
 *         using one of the SSTORE2 implementations referenced below.
 *         For these pre-V1 storage contracts (which themselves did not have any explicit versioning semantics)
 *         backwards-compatible reads are optimistic, and only expected to work for contracts actually
 *         deployed by the original version of this library – and may fail ungracefully if attempted to be
 *         used to read from other contracts.
 *         This library is split into two components, intended to be updated in tandem, and thus included
 *         here in the same source file. One component is an internal library that is intended to be embedded
 *         directly into other contracts and provides all _write_ functionality. The other is a public library
 *         that is intended to be deployed as a standalone contract and provides all _read_ functionality.
 *
 * @author Art Blocks Inc.
 * @author Modified from 0xSequence (https://github.com/0xsequence/sstore2/blob/master/contracts/SSTORE2.sol)
 * @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
 * @author Utilizes LibZip from solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibZip.sol)
 *
 * @dev Compared to the above two rerferenced libraries, this contracts-as-storage implementation makes a few
 *      notably different design decisions:
 *      - uses the `string` data type for input/output on reads, rather than speaking in bytes directly,
 *        with an exception for optionally compressed data which are input as bytes
 *      - stores the "writer" address (library user) in the deployed contract bytes, which is useful for
 *        on-chain introspection and provenance purposes
 *      - stores a very simple versioning string in the deployed contract bytes, which captures the version
 *        of the library that was used to deploy the storage contract and useful for supporting future
 *        compatibility management as this library evolves (e.g. in response to EOF v1 migration plans)
 *      - stores a bool indicating if the stored data are compressed.
 *      Also, given that much of this library is written in assembly, this library makes use of a slightly
 *      different convention (when compared to the rest of the Art Blocks smart contract repo) around
 *      pre-defining return values in some cases in order to simplify need to directly memory manage these
 *      return values.
 */

/**
 * @title Art Blocks Script Storage Library (Public, Reads)
 * @author Art Blocks Inc.
 * @notice The public library for reading from storage contracts. This library is intended to be deployed as a
 *         standalone contract, and provides all _read_ functionality.
 */
library BytecodeStorageReader {
    // Define the set of known valid version strings that may be stored in the deployed storage contract bytecode
    // note: These are all intentionally exactly 32-bytes and are null-terminated. Null-termination is used due
    //       to this being the standard expected formatting in common web3 tooling such as ethers.js. Please see
    //       the following for additional context: https://docs.ethers.org/v5/api/utils/strings/#Bytes32String
    // Used for storage contracts that were deployed by an unknown source
    bytes32 public constant UNKNOWN_VERSION_STRING =
        "UNKNOWN_VERSION_STRING_________ ";
    // Pre-dates versioning string, so this doesn't actually exist in any deployed contracts,
    // but is useful for backwards-compatible semantics with original version of this library
    bytes32 public constant V0_VERSION_STRING =
        "BytecodeStorage_V0.0.0_________ ";
    // The first versioned storage contract, deployed by an updated version of this library
    bytes32 public constant V1_VERSION_STRING =
        "BytecodeStorage_V1.0.0_________ ";
    // The first versioned storage contract, deployed by an updated version of this library
    bytes32 public constant V2_VERSION_STRING =
        "BytecodeStorage_V2.0.0_________ ";
    // The current version of this library.
    bytes32 public constant CURRENT_VERSION = V2_VERSION_STRING;

    //---------------------------------------------------------------------------------------------------------------//
    // Starting Index | Size | Ending Index | Description                                                            //
    //---------------------------------------------------------------------------------------------------------------//
    // 0              | N/A  | 0            |                                                                        //
    // 0              | 1    | 1            | single byte opcode for making the storage contract non-executable      //
    // 1              | 32   | 33           | the 32 byte slot used for storing a basic versioning string            //
    // 33             | 32   | 65           | the 32 bytes for storing the deploying contract's (0-padded) address   //
    // 65             | 1    | 66           | single byte indicating if the stored data are compressed               //
    //---------------------------------------------------------------------------------------------------------------//
    // Define the offset for where the "meta bytes" end, and the "data bytes" begin. Note that this is a manually
    // calculated value, and must be updated if the above table is changed. It is expected that tests will fail
    // loudly if these values are not updated in-step with eachother.
    uint256 private constant VERSION_OFFSET = 1;
    uint256 private constant ADDRESS_OFFSET = 33;
    uint256 private constant COMPRESSION_OFFSET = 65;
    uint256 private constant DATA_OFFSET = 66;

    // Define the set of known *historic* offset values for where the "meta bytes" end, and the "data bytes" begin.
    // SSTORE2 deployed storage contracts take the general format of:
    // concat(0x00, data)
    // note: this is true for both variants of the SSTORE2 library
    uint256 private constant SSTORE2_DATA_OFFSET = 1;
    // V0 deployed storage contracts take the general format of:
    // concat(gated-cleanup-logic, deployer-address, data)
    uint256 private constant V0_ADDRESS_OFFSET = 72;
    uint256 private constant V0_DATA_OFFSET = 104;
    // V1 deployed storage contracts take the general format of:
    // concat(invalid opcode, version, deployer-address, data)
    uint256 private constant V1_ADDRESS_OFFSET = 33;
    uint256 private constant V1_DATA_OFFSET = 65;
    // V2 deployed storage contracts take the general format of:
    // concat(invalid opcode, version, deployer-address, compression-bool, data)
    uint256 private constant V2_ADDRESS_OFFSET = ADDRESS_OFFSET;
    uint256 private constant V2_DATA_OFFSET = DATA_OFFSET;

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Read a string from contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 or V2 format
     * @return data string read from contract bytecode
     * @dev This function performs input validation that the contract to read is in an expected format
     */
    function readFromBytecode(
        address _address
    ) public view returns (string memory data) {
        (
            uint256 dataOffset,
            bool isCompressed
        ) = _bytecodeDataOffsetAndIsCompressedAt(_address);
        if (isCompressed) {
            return
                string(
                    LibZip.flzDecompress(
                        readBytesFromBytecode(_address, dataOffset)
                    )
                );
        } else {
            return string(readBytesFromBytecode(_address, dataOffset));
        }
    }

    /**
     * @notice Read the bytes from contract bytecode that was written to the EVM using SSTORE2
     * @param _address address of deployed contract with bytecode stored in the SSTORE2 format
     * @return data bytes read from contract bytecode
     * @dev This function performs no input validation on the provided contract,
     *      other than that there is content to read (but not that its a "storage contract")
     */
    function readBytesFromSSTORE2Bytecode(
        address _address
    ) public view returns (bytes memory data) {
        return readBytesFromBytecode(_address, SSTORE2_DATA_OFFSET);
    }

    /**
     * @notice Read the bytes from contract bytecode, with an explicitly provided starting offset
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @param _offset offset to read from in contract bytecode, explicitly provided (not calculated)
     * @return data bytes read from contract bytecode
     * @dev This function performs no input validation on the provided contract,
     *      other than that there is content to read (but not that its a "storage contract")
     */
    function readBytesFromBytecode(
        address _address,
        uint256 _offset
    ) public view returns (bytes memory data) {
        // get the size of the bytecode
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < _offset
        if (bytecodeSize < _offset) {
            revert("ContractAsStorage: Read Error");
        }

        // handle case where address contains code >= dataOffset
        // decrement by dataOffset to account for header info
        uint256 size;
        unchecked {
            size = bytecodeSize - _offset;
        }

        assembly {
            // allocate free memory
            data := mload(0x40)
            // update free memory pointer
            // use and(x, not(0x1f) as cheaper equivalent to sub(x, mod(x, 0x20)).
            // adding 0x1f to size + logic above ensures the free memory pointer
            // remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length of data in first 32 bytes
            mstore(data, size)
            // copy code to memory, excluding the deployer-address
            extcodecopy(_address, add(data, 0x20), _offset, size)
        }
    }

    /**
     * @notice Get address for deployer for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return writerAddress address read from contract bytecode
     */
    function getWriterAddressForBytecode(
        address _address
    ) public view returns (address) {
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // the dataOffset for the bytecode
        uint256 addressOffset = _bytecodeAddressOffsetAt(_address);
        // handle case where address contains code < addressOffset + 32 (address takes a whole slot)
        if (bytecodeSize < (addressOffset + 32)) {
            revert("ContractAsStorage: Read Error");
        }

        assembly {
            // allocate free memory
            let writerAddress := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // copy the 32-byte address of the data contract writer to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like::
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | data |
            extcodecopy(
                _address,
                writerAddress,
                addressOffset,
                0x20 // full 32-bytes, as address is expected to be zero-padded
            )
            return(
                writerAddress,
                0x20 // return size is entire slot, as it is zero-padded
            )
        }
    }

    /**
     * @notice Get version for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return version version read from contract bytecode
     */
    function getLibraryVersionForBytecode(
        address _address
    ) public view returns (bytes32) {
        return _bytecodeVersionAt(_address);
    }

    /**
     * @notice Get if data are stored in compressed format for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0, V1, or V2 format
     * @return isCompressed boolean indicating if the stored data are compressed
     */
    function getIsCompressedForBytecode(
        address _address
    ) public view returns (bool) {
        (, bool isCompressed) = _bytecodeDataOffsetAndIsCompressedAt(_address);
        return isCompressed;
    }

    /**
     * Utility function to get the compressed form of a message string using solady LibZip's
     * flz compress algorithm.
     * The compressed message is returned as bytes, which may be used as the input to
     * the function `BytecodeStorageWriter.writeToBytecodeCompressed`.
     * @param _data string to be compressed
     * @return bytes compressed bytes
     */
    function getCompressed(
        string memory _data
    ) public pure returns (bytes memory) {
        return LibZip.flzCompress(bytes(_data));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the size of the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return size size of the bytecode code at `_address`
     */
    function _bytecodeSizeAt(
        address _address
    ) private view returns (uint256 size) {
        assembly {
            size := extcodesize(_address)
        }
        if (size == 0) {
            revert("ContractAsStorage: Read Error");
        }
    }

    /**
     * @notice Returns the offset of the data in the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return dataOffset offset of data in bytecode if a known version, otherwise 0
     * @return isCompressed bool indicating if the stored data are compressed
     */
    function _bytecodeDataOffsetAndIsCompressedAt(
        address _address
    ) private view returns (uint256 dataOffset, bool isCompressed) {
        bytes32 version = _bytecodeVersionAt(_address);
        if (version == V2_VERSION_STRING) {
            dataOffset = V2_DATA_OFFSET;
            isCompressed = _isCompressedAt(_address, version);
        } else if (version == V1_VERSION_STRING) {
            dataOffset = V1_DATA_OFFSET;
            // isCompressed remains false, as V1 contracts do not support compression
        } else if (version == V0_VERSION_STRING) {
            dataOffset = V0_DATA_OFFSET;
            // isCompressed remains false, as V0 contracts do not support compression
        } else {
            // unknown version, revert
            revert("ContractAsStorage: Unsupported Version");
        }
    }

    /**
     * @notice Returns the offset of the address in the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return addressOffset offset of address in bytecode if a known version, otherwise 0
     */
    function _bytecodeAddressOffsetAt(
        address _address
    ) private view returns (uint256 addressOffset) {
        bytes32 version = _bytecodeVersionAt(_address);
        if (version == V2_VERSION_STRING) {
            addressOffset = V2_ADDRESS_OFFSET;
        } else if (version == V1_VERSION_STRING) {
            addressOffset = V1_ADDRESS_OFFSET;
        } else if (version == V0_VERSION_STRING) {
            addressOffset = V0_ADDRESS_OFFSET;
        } else {
            // unknown version, revert
            revert("ContractAsStorage: Unsupported Version");
        }
    }

    /**
     * @notice Get version string for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return version version string read from contract bytecode
     */
    function _bytecodeVersionAt(
        address _address
    ) private view returns (bytes32 version) {
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < minimum expected version string size,
        // by returning early with the unknown version string
        if (bytecodeSize < (VERSION_OFFSET + 32)) {
            return UNKNOWN_VERSION_STRING;
        }

        assembly {
            // allocate free memory
            let versionString := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // copy the 32-byte version string of the bytecode library to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like:
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | data |
            extcodecopy(
                _address,
                versionString,
                VERSION_OFFSET,
                0x20 // 32-byte version string
            )
            // note: must check against literal strings, as Yul does not allow for
            //       dynamic strings in switch statements.
            switch mload(versionString)
            case "BytecodeStorage_V2.0.0_________ " {
                version := V2_VERSION_STRING
            }
            case "BytecodeStorage_V1.0.0_________ " {
                version := V1_VERSION_STRING
            }
            case 0x2060486000396000513314601057fe5b60013614601957fe5b6000357fff0000 {
                // the v0 variant of this library pre-dates formal versioning w/ version strings,
                // so we check the first 32 bytes of the execution bytecode itself which
                // is static and known across all storage contracts deployed with the first version
                // of this library.
                version := V0_VERSION_STRING
            }
            default {
                version := UNKNOWN_VERSION_STRING
            }
        }
    }

    /**
     * @notice Get if stored data are compressed for given contract bytecode
     * @param _address address of deployed contract with bytecode stored
     * @param _version version string of the bytecode library used to deploy the contract at `_address`
     * @return isCompressed bool indicating if the stored data are compressed
     */
    function _isCompressedAt(
        address _address,
        bytes32 _version
    ) private view returns (bool isCompressed) {
        // @dev if branch no coverage - unreachable as used, remains for redundant safety
        if (_version == V0_VERSION_STRING || _version == V1_VERSION_STRING) {
            // V0 and V1 and unknown contracts do not support compression
            return false;
        }
        // @dev if branch no coverage - unreachable as used, remains for redundant safety
        if (_version != V2_VERSION_STRING) {
            // unsupported version, throw error
            revert("ContractAsStorage: Unsupported Version");
        }
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < minimum expected version string size,
        // by returning early with false
        if (bytecodeSize < (COMPRESSION_OFFSET + 1)) {
            return false;
        }

        assembly {
            // allocate free memory
            let compressedByte := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // zero out word at compressedByte (solidity does not guarantee zeroed memory beyond free memory pointer)
            mstore(compressedByte, 0x00)
            // copy the 1-byte compressed flag of the bytecode library to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like:
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | isCompressed | data |
            extcodecopy(
                _address,
                compressedByte,
                COMPRESSION_OFFSET,
                0x1 // 1-byte version string
            )
            // check if the compressed flag is set
            switch mload(compressedByte)
            case 0x00 {
                isCompressed := false
            }
            default {
                isCompressed := true
            }
        }
    }
}

/**
 * @title Art Blocks Script Storage Library (Internal, Writes)
 * @author Art Blocks Inc.
 * @notice The internal library for writing to storage contracts. This library is intended to be deployed
 *         within library client contracts that use this library to perform _write_ operations on storage.
 */
library BytecodeStorageWriter {
    /*//////////////////////////////////////////////////////////////
                           WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Write a string to contract bytecode
     * @param _data string to be written to contract. No input validation is performed on this parameter.
     * @return address_ address of deployed contract with bytecode stored in the V2 format
     */
    function writeToBytecode(
        string memory _data
    ) internal returns (address address_) {
        // prefix bytecode with
        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // a.) creation code returns all code in the contract except for the first 11 (0B in hex) bytes, as these 11
            //     bytes are the creation code itself which we do not want to store in the deployed storage contract result
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x60_0B            | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xF3    |  0xF3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (11 bytes)
            hex"60_0B_59_81_38_03_80_92_59_39_F3",
            //---------------------------------------------------------------------------------------------------------------//
            // b.) ensure that the deployed storage contract is non-executeable (first opcode is the `invalid` opcode)
            //---------------------------------------------------------------------------------------------------------------//
            //---------------------------------------------------------------------------------------------------------------//
            // 0xFE    |  0xFE               | INVALID      |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"FE",
            //---------------------------------------------------------------------------------------------------------------//
            // c.) store the version string, which is already represented as a 32-byte value
            //---------------------------------------------------------------------------------------------------------------//
            // (32 bytes)
            BytecodeStorageReader.CURRENT_VERSION,
            //---------------------------------------------------------------------------------------------------------------//
            // d.) store the deploying-contract's address with 0-padding to fit a 20-byte address into a 32-byte slot
            //---------------------------------------------------------------------------------------------------------------//
            // (12 bytes)
            hex"00_00_00_00_00_00_00_00_00_00_00_00",
            // (20 bytes)
            address(this),
            //---------------------------------------------------------------------------------------------------------------//
            // e.) store the bool indicating if the data is compressed. true for this function.
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"00",
            // uploaded data (stored as bytecode) comes last
            _data
        );

        assembly {
            // deploy a new contract with the generated creation code.
            // start 32 bytes into creationCode to avoid copying the byte length.
            address_ := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        // address must be non-zero if contract was deployed successfully
        require(address_ != address(0), "ContractAsStorage: Write Error");
    }

    /**
     * @notice Write a string to contract bytecode, input as compressed bytes from solady LibZip
     * @param _dataCompressed compressed bytes to be written to contract. No input validation is performed on this parameter.
     * @return address_ address of deployed contract with bytecode stored in the V2 format
     */
    function writeToBytecodeCompressed(
        bytes memory _dataCompressed
    ) internal returns (address address_) {
        // prefix bytecode with
        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // a.) creation code returns all code in the contract except for the first 11 (0B in hex) bytes, as these 11
            //     bytes are the creation code itself which we do not want to store in the deployed storage contract result
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x60_0B            | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xF3    |  0xF3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (11 bytes)
            hex"60_0B_59_81_38_03_80_92_59_39_F3",
            //---------------------------------------------------------------------------------------------------------------//
            // b.) ensure that the deployed storage contract is non-executeable (first opcode is the `invalid` opcode)
            //---------------------------------------------------------------------------------------------------------------//
            //---------------------------------------------------------------------------------------------------------------//
            // 0xFE    |  0xFE               | INVALID      |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"FE",
            //---------------------------------------------------------------------------------------------------------------//
            // c.) store the version string, which is already represented as a 32-byte value
            //---------------------------------------------------------------------------------------------------------------//
            // (32 bytes)
            BytecodeStorageReader.CURRENT_VERSION,
            //---------------------------------------------------------------------------------------------------------------//
            // d.) store the deploying-contract's address with 0-padding to fit a 20-byte address into a 32-byte slot
            //---------------------------------------------------------------------------------------------------------------//
            // (12 bytes)
            hex"00_00_00_00_00_00_00_00_00_00_00_00",
            // (20 bytes)
            address(this),
            //---------------------------------------------------------------------------------------------------------------//
            // e.) store the bool indicating if the data is compressed. true for this function.
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"01",
            // uploaded compressed data (stored as bytecode) comes last
            _dataCompressed
        );

        assembly {
            // deploy a new contract with the generated creation code.
            // start 32 bytes into creationCode to avoid copying the byte length.
            address_ := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        // address must be non-zero if contract was deployed successfully
        require(address_ != address(0), "ContractAsStorage: Write Error");
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import {IGenArt721CoreContractV3_Engine_Flex} from "../../interfaces/v0.8.x/IGenArt721CoreContractV3_Engine_Flex.sol";
import {IBytecodeStorageReader_Base} from "../../interfaces/v0.8.x/IBytecodeStorageReader_Base.sol";

import {BytecodeStorageWriter} from "./BytecodeStorageV2.sol";

/**
 * @title Art Blocks V3 Engine Flex - External Helper Library
 * @notice This library is designed to offload bytecode from the V3 Engine
 * Flex contract. It implements logic that may be accessed via DELEGATECALL for
 * operations related to the V3 Engine Flex contract.
 * @author Art Blocks Inc.
 */

library V3FlexLib {
    using BytecodeStorageWriter for string;
    using BytecodeStorageWriter for bytes;
    // For the purposes of this implementation, due to the limited scope and
    // existing legacy infrastructure, the library emits the events
    // defined in IGenArt721CoreContractV3_Engine_Flex.sol. The events are
    // manually duplicated here
    /**
     * @notice When an external asset dependency is updated or added, this event is emitted.
     * @param _projectId The project ID of the project that was updated.
     * @param _index The index of the external asset dependency that was updated.
     * @param _cid Field that contains the CID of the dependency if IPFS or ARWEAVE,
     * empty string of ONCHAIN, or a string representation of the Art Blocks Dependency
     * Registry's `dependencyNameAndVersion` if ART_BLOCKS_DEPENDENCY_REGISTRY.
     * @param _dependencyType The type of the external asset dependency.
     * @param _externalAssetDependencyCount The number of external asset dependencies.
     */
    event ExternalAssetDependencyUpdated(
        uint256 indexed _projectId,
        uint256 indexed _index,
        string _cid,
        IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependencyType _dependencyType,
        uint24 _externalAssetDependencyCount
    );

    /**
     * @notice The project id `_projectId` has had an external asset dependency removed at index `_index`.
     */
    event ExternalAssetDependencyRemoved(
        uint256 indexed _projectId,
        uint256 indexed _index
    );

    /**
     * @notice The preferred gateway for dependency type `_dependencyType` has been updated to `_gatewayAddress`.
     */
    event GatewayUpdated(
        IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependencyType indexed _dependencyType,
        string _gatewayAddress
    );

    /**
     * @notice The project id `_projectId` has had all external asset dependencies locked.
     * @dev This is a one-way operation. Once locked, the external asset dependencies cannot be updated.
     */
    event ProjectExternalAssetDependenciesLocked(uint256 indexed _projectId);

    // position of V3 Flex Lib storage, using a diamond storage pattern
    // for this library
    bytes32 constant V3_FLEX_LIB_STORAGE_POSITION =
        keccak256("v3flexlib.storage");

    // project-level variables
    /**
     * Struct used to store a project's currently configured price, and
     * whether or not the price has been configured.
     */
    struct FlexProjectData {
        bool externalAssetDependenciesLocked;
        uint24 externalAssetDependencyCount;
        mapping(uint256 => IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependency) externalAssetDependencies;
    }

    // Diamond storage pattern is used in this library
    struct V3FlexLibStorage {
        string preferredIPFSGateway;
        string preferredArweaveGateway;
        mapping(uint256 projectId => FlexProjectData) flexProjectsData;
    }

    /**
     * @notice Updates preferredIPFSGateway to `_gateway`.
     * @param _gateway The new preferred IPFS gateway.
     */
    function updateIPFSGateway(string calldata _gateway) external {
        s().preferredIPFSGateway = _gateway;
        emit GatewayUpdated({
            _dependencyType: IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyType
                .IPFS,
            _gatewayAddress: _gateway
        });
    }

    /**
     * @notice Updates preferredArweaveGateway to `_gateway`.
     * @param _gateway The new preferred Arweave gateway.
     */
    function updateArweaveGateway(string calldata _gateway) external {
        s().preferredArweaveGateway = _gateway;
        emit GatewayUpdated({
            _dependencyType: IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyType
                .ARWEAVE,
            _gatewayAddress: _gateway
        });
    }

    /**
     * @notice Locks external asset dependencies for project `_projectId`.
     * Reverts if the external asset dependencies are already locked.
     * @dev This is a one-way operation. Once locked, the external asset dependencies cannot be updated.
     * @param _projectId Project to be locked.
     */
    function lockProjectExternalAssetDependencies(uint256 _projectId) external {
        FlexProjectData storage flexProjectData = getFlexProjectData(
            _projectId
        );
        _onlyUnlockedProjectExternalAssetDependencies(flexProjectData);
        flexProjectData.externalAssetDependenciesLocked = true;
        emit ProjectExternalAssetDependenciesLocked(_projectId);
    }

    /**
     * @notice Updates external asset dependency for project `_projectId`.
     * @dev Making this an external function adds roughly 1% to the gas cost of adding an asset, but
     * significantly reduces the bytecode of contracts using this library.
     * @param _projectId Project to be updated.
     * @param _index Asset index.
     * @param _cidOrData Field that contains the CID of the dependency if IPFS or ARWEAVE,
     * empty string of ONCHAIN, or a string representation of the Art Blocks Dependency
     * Registry's `dependencyNameAndVersion` if ART_BLOCKS_DEPENDENCY_REGISTRY.
     * @param _dependencyType Asset dependency type.
     *  0 - IPFS
     *  1 - ARWEAVE
     *  2 - ONCHAIN
     *  3 - ART_BLOCKS_DEPENDENCY_REGISTRY
     */
    function updateProjectExternalAssetDependency(
        uint256 _projectId,
        uint256 _index,
        string memory _cidOrData,
        IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependencyType _dependencyType
    ) external {
        FlexProjectData storage flexProjectData = getFlexProjectData(
            _projectId
        );
        _onlyUnlockedProjectExternalAssetDependencies(flexProjectData);
        uint24 assetCount = flexProjectData.externalAssetDependencyCount;
        require(_index < assetCount, "Asset index out of range");
        // @dev dependencyNameAndVersion are not validated against the dependency registry
        // due to limitations of L1 reads on L2 networks at this time

        IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependency
            storage _oldDependency = flexProjectData.externalAssetDependencies[
                _index
            ];
        IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependencyType _oldDependencyType = _oldDependency
                .dependencyType;
        // update the asset's dependency type to new value in storage
        flexProjectData
            .externalAssetDependencies[_index]
            .dependencyType = _dependencyType;
        // if the incoming dependency type is onchain, we need to write the data to bytecode
        if (
            _dependencyType ==
            IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyType
                .ONCHAIN
        ) {
            if (
                _oldDependencyType !=
                IGenArt721CoreContractV3_Engine_Flex
                    .ExternalAssetDependencyType
                    .ONCHAIN
            ) {
                // we only need to set the cid to an empty string if we are replacing an offchain asset
                // an onchain asset will already have an empty cid
                flexProjectData.externalAssetDependencies[_index].cid = "";
            }

            flexProjectData
                .externalAssetDependencies[_index]
                .bytecodeAddress = _cidOrData.writeToBytecode();
            // we don't want to emit data, so we emit the cid as an empty string
            _cidOrData = "";
        } else {
            // incoming dependency type is not ONCHAIN, so we set the cid directly with either
            // the incoming cid or string representation of the dependencyNameAndVersion
            flexProjectData.externalAssetDependencies[_index].cid = _cidOrData;
            // clear any previously populated bytecode address
            flexProjectData
                .externalAssetDependencies[_index]
                .bytecodeAddress = address(0);
        }
        emit ExternalAssetDependencyUpdated({
            _projectId: _projectId,
            _index: _index,
            _cid: _cidOrData,
            _dependencyType: _dependencyType,
            _externalAssetDependencyCount: assetCount
        });
    }

    /**
     * @notice Updates external asset dependency for project `_projectId` of type
     * ONCHAIN using on-chain compression. This function stores the string
     * in a compressed format on-chain. For reads, the compressed script is
     * decompressed on-chain, ensuring the original text is reconstructed without
     * external dependencies.
     * @param _projectId Project to be updated.
     * @param _index Asset index.
     * @param _compressedString Pre-compressed string asset to be added.
     */
    function updateProjectExternalAssetDependencyOnChainCompressed(
        uint256 _projectId,
        uint256 _index,
        bytes memory _compressedString
    ) external {
        FlexProjectData storage flexProjectData = getFlexProjectData(
            _projectId
        );
        _onlyUnlockedProjectExternalAssetDependencies(flexProjectData);

        // check that the index is within the range of the asset count
        uint24 assetCount = flexProjectData.externalAssetDependencyCount;
        require(_index < assetCount, "Asset index out of range");

        // EFFECTS
        // overwrite the relevant fields of the previous asset, assigning bytecodeAddress directly
        IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependency
            storage currentDependency = flexProjectData
                .externalAssetDependencies[_index];
        currentDependency.cid = "";
        currentDependency.dependencyType = IGenArt721CoreContractV3_Engine_Flex
            .ExternalAssetDependencyType
            .ONCHAIN;
        currentDependency.bytecodeAddress = _compressedString
            .writeToBytecodeCompressed();

        // emit the event
        emit ExternalAssetDependencyUpdated({
            _projectId: _projectId,
            _index: _index,
            _cid: "",
            _dependencyType: IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyType
                .ONCHAIN,
            _externalAssetDependencyCount: assetCount
        });
    }

    /**
     * @notice Updates external asset dependency for project `_projectId` at
     * index `_index`, with data at BytecodeStorage-compatible address
     * `_assetAddress`.
     * @param _projectId Project to be updated.
     * @param _index Asset index.
     * @param _assetAddress Address of the on-chain asset.
     */
    function updateProjectAssetDependencyOnChainAtAddress(
        uint256 _projectId,
        uint256 _index,
        address _assetAddress
    ) external {
        // CHECKS
        FlexProjectData storage flexProjectData = getFlexProjectData(
            _projectId
        );
        _onlyUnlockedProjectExternalAssetDependencies(flexProjectData);
        uint24 assetCount = flexProjectData.externalAssetDependencyCount;
        require(_index < assetCount, "Asset index out of range");

        // EFFECTS
        // overwrite the relevant fields of the previous asset
        IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependency
            storage currentDependency = flexProjectData
                .externalAssetDependencies[_index];
        currentDependency.cid = "";
        currentDependency.dependencyType = IGenArt721CoreContractV3_Engine_Flex
            .ExternalAssetDependencyType
            .ONCHAIN;
        currentDependency.bytecodeAddress = _assetAddress;

        // emit the event
        emit ExternalAssetDependencyUpdated({
            _projectId: _projectId,
            _index: _index,
            _cid: "",
            _dependencyType: IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyType
                .ONCHAIN,
            _externalAssetDependencyCount: assetCount
        });
    }

    /**
     * @notice Removes external asset dependency for project `_projectId` at index `_index`.
     * Removal is done by swapping the element to be removed with the last element in the array, then deleting this last element.
     * Assets with indices higher than `_index` can have their indices adjusted as a result of this operation.
     * @param _projectId Project to be updated.
     * @param _index Asset index
     */
    function removeProjectExternalAssetDependency(
        uint256 _projectId,
        uint256 _index
    ) external {
        FlexProjectData storage flexProjectData = getFlexProjectData(
            _projectId
        );
        _onlyUnlockedProjectExternalAssetDependencies(flexProjectData);
        // ensure the index is within the range of the asset count
        uint24 assetCount = flexProjectData.externalAssetDependencyCount;
        require(_index < assetCount, "Asset index out of range");
        // @dev solidity underflow will revert on the following statement if assetCount is 0
        uint24 lastElementIndex = assetCount - 1;
        // for UX purposes, only allow removal of the last lastElementIndex
        require(_index == lastElementIndex, "Only removal of last asset");

        // @dev simply delete last element; no need to copy last to deleted index due to require statement above

        delete flexProjectData.externalAssetDependencies[lastElementIndex];

        flexProjectData.externalAssetDependencyCount = lastElementIndex;

        emit ExternalAssetDependencyRemoved({
            _projectId: _projectId,
            _index: _index
        });
    }

    /**
     * @notice Adds external asset dependency for project `_projectId`.
     * @dev Making this an external function adds roughly 1% to the gas cost of adding an asset, but
     * significantly reduces the bytecode of contracts using this library.
     * @param _projectId Project to be updated.
     * @param _cidOrData Field that contains the CID of the dependency if IPFS or ARWEAVE,
     * empty string of ONCHAIN, or a string representation of the Art Blocks Dependency
     * Registry's `dependencyNameAndVersion` if ART_BLOCKS_DEPENDENCY_REGISTRY.
     * @param _dependencyType Asset dependency type.
     *  0 - IPFS
     *  1 - ARWEAVE
     *  2 - ONCHAIN
     *  3 - ART_BLOCKS_DEPENDENCY_REGISTRY
     */
    function addProjectExternalAssetDependency(
        uint256 _projectId,
        string memory _cidOrData,
        IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependencyType _dependencyType
    ) external {
        FlexProjectData storage flexProjectData = getFlexProjectData(
            _projectId
        );
        _onlyUnlockedProjectExternalAssetDependencies(flexProjectData);
        // @dev dependencyNameAndVersion are not validated against the dependency registry
        // due to limitations of L1 reads on L2 networks at this time

        uint24 assetCount = flexProjectData.externalAssetDependencyCount;
        address _bytecodeAddress = address(0);
        // if the incoming dependency type is onchain, we need to write the data to bytecode
        if (
            _dependencyType ==
            IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyType
                .ONCHAIN
        ) {
            _bytecodeAddress = _cidOrData.writeToBytecode();
            // we don't want to assign or emit data, so we emit the cid as an empty string
            _cidOrData = "";
        }

        // append the new asset to the end of the project's asset storage array
        flexProjectData.externalAssetDependencies[
            assetCount
        ] = IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependency({
            cid: _cidOrData,
            dependencyType: _dependencyType,
            bytecodeAddress: _bytecodeAddress
        });
        // increment the project's asset count
        flexProjectData.externalAssetDependencyCount = assetCount + 1;

        // emit event indicating the asset has been added
        emit ExternalAssetDependencyUpdated({
            _projectId: _projectId,
            _index: assetCount,
            _cid: _cidOrData,
            _dependencyType: _dependencyType,
            _externalAssetDependencyCount: assetCount + 1
        });
    }

    /**
     * @notice Adds external asset dependency for project `_projectId` of type
     * ONCHAIN using on-chain compression. This function stores the string
     * in a compressed format on-chain. For reads, the compressed script is
     * decompressed on-chain, ensuring the original text is reconstructed without
     * external dependencies.
     * @param _projectId Project to be updated.
     * @param _compressedString Pre-compressed string asset to be added.
     */
    function addProjectExternalAssetDependencyOnChainCompressed(
        uint256 _projectId,
        bytes memory _compressedString
    ) external {
        FlexProjectData storage flexProjectData = getFlexProjectData(
            _projectId
        );
        _onlyUnlockedProjectExternalAssetDependencies(flexProjectData);

        // append the new asset to the end of the project's asset storage array
        uint24 assetCount = flexProjectData.externalAssetDependencyCount;
        flexProjectData.externalAssetDependencies[
            assetCount
        ] = IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependency({
            cid: "",
            dependencyType: IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyType
                .ONCHAIN,
            bytecodeAddress: _compressedString.writeToBytecodeCompressed()
        });

        // increment the asset count
        flexProjectData.externalAssetDependencyCount = assetCount + 1;

        // emit event indicating the asset has been added
        emit ExternalAssetDependencyUpdated({
            _projectId: _projectId,
            _index: assetCount,
            _cid: "",
            _dependencyType: IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyType
                .ONCHAIN,
            _externalAssetDependencyCount: assetCount + 1
        });
    }

    /**
     * @notice Adds an on-chain external asset dependency for project
     * `_projectId`, with data at BytecodeStorage-compatible address
     * `_assetAddress`.
     * @param _projectId Project to be updated.
     * @param _assetAddress  Address of the BytecodeStorageReader-compatible on-chain asset.
     */
    function addProjectAssetDependencyOnChainAtAddress(
        uint256 _projectId,
        address _assetAddress
    ) external {
        FlexProjectData storage flexProjectData = getFlexProjectData(
            _projectId
        );
        _onlyUnlockedProjectExternalAssetDependencies(flexProjectData);

        // append the new asset to the end of the project's asset storage array
        uint24 assetCount = flexProjectData.externalAssetDependencyCount;
        flexProjectData.externalAssetDependencies[
            assetCount
        ] = IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependency({
            cid: "",
            dependencyType: IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyType
                .ONCHAIN,
            bytecodeAddress: _assetAddress
        });

        // increment the asset count
        flexProjectData.externalAssetDependencyCount = assetCount + 1;

        // emit event indicating the asset has been added
        emit ExternalAssetDependencyUpdated({
            _projectId: _projectId,
            _index: assetCount,
            _cid: "",
            _dependencyType: IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyType
                .ONCHAIN,
            _externalAssetDependencyCount: assetCount + 1
        });
    }

    /**
     * @notice Returns external asset dependency count for project `_projectId` at index `_index`.
     */
    function projectExternalAssetDependencyCount(
        uint256 _projectId
    ) external view returns (uint256) {
        FlexProjectData storage flexProjectData = getFlexProjectData(
            _projectId
        );
        return uint256(flexProjectData.externalAssetDependencyCount);
    }

    /**
     * @notice Returns external asset dependency for project `_projectId` at index `_index`.
     * If the dependencyType is ONCHAIN, the `data` field will contain the extrated bytecode data and `cid`
     * will be an empty string. Conversly, for any other dependencyType, the `data` field will be an empty string
     * and the `bytecodeAddress` will point to the zero address.
     * @param _projectId Project to get external asset dependency for.
     * @param _index Index of the external asset dependency.
     * @param _bytecodeStorageReaderContract The bytecode storage reader contract to use for reading on-chain
     * dependencies; only used if the dependency is of type ONCHAIN.
     */
    function projectExternalAssetDependencyByIndex(
        uint256 _projectId,
        uint256 _index,
        IBytecodeStorageReader_Base _bytecodeStorageReaderContract
    )
        external
        view
        returns (
            IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependencyWithData
                memory
        )
    {
        FlexProjectData storage flexProjectData = getFlexProjectData(
            _projectId
        );
        IGenArt721CoreContractV3_Engine_Flex.ExternalAssetDependency
            storage _dependency = flexProjectData.externalAssetDependencies[
                _index
            ];
        address _bytecodeAddress = _dependency.bytecodeAddress;

        return
            IGenArt721CoreContractV3_Engine_Flex
                .ExternalAssetDependencyWithData({
                    dependencyType: _dependency.dependencyType,
                    cid: _dependency.cid,
                    bytecodeAddress: _bytecodeAddress,
                    data: (_dependency.dependencyType ==
                        IGenArt721CoreContractV3_Engine_Flex
                            .ExternalAssetDependencyType
                            .ONCHAIN)
                        ? _bytecodeStorageReaderContract.readFromBytecode(
                            _bytecodeAddress
                        )
                        : ""
                });
    }

    /**
     * @notice Returns the preferred IPFS gateway.
     */
    function preferredIPFSGateway() external view returns (string memory) {
        return s().preferredIPFSGateway;
    }

    /**
     * @notice Returns the preferred Arweave gateway.
     */
    function preferredArweaveGateway() external view returns (string memory) {
        return s().preferredArweaveGateway;
    }

    /**
     * @notice Loads the FlexProjectData for a given project.
     * @param projectId Project Id to get FlexProjectData for
     */
    function getFlexProjectData(
        uint256 projectId
    ) internal view returns (FlexProjectData storage) {
        return s().flexProjectsData[projectId];
    }

    /**
     * @notice Return the storage struct for reading and writing. This library
     * uses a diamond storage pattern when managing storage.
     * @return storageStruct The V3FlexLibStorage struct.
     */
    function s()
        internal
        pure
        returns (V3FlexLibStorage storage storageStruct)
    {
        bytes32 position = V3_FLEX_LIB_STORAGE_POSITION;
        assembly ("memory-safe") {
            storageStruct.slot := position
        }
    }

    function _onlyUnlockedProjectExternalAssetDependencies(
        FlexProjectData storage flexProjectData
    ) private view {
        require(
            !flexProjectData.externalAssetDependenciesLocked,
            "External dependencies locked"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for compressing and decompressing bytes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibZip.sol)
/// @author Calldata compression by clabby (https://github.com/clabby/op-kompressor)
/// @author FastLZ by ariya (https://github.com/ariya/FastLZ)
///
/// @dev Note:
/// The accompanying solady.js library includes implementations of
/// FastLZ and calldata operations for convenience.
library LibZip {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     FAST LZ OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // LZ77 implementation based on FastLZ.
    // Equivalent to level 1 compression and decompression at the following commit:
    // https://github.com/ariya/FastLZ/commit/344eb4025f9ae866ebf7a2ec48850f7113a97a42
    // Decompression is backwards compatible.

    /// @dev Returns the compressed `data`.
    function flzCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function ms8(d_, v_) -> _d {
                mstore8(d_, v_)
                _d := add(d_, 1)
            }
            function u24(p_) -> _u {
                _u := mload(p_)
                _u := or(shl(16, byte(2, _u)), or(shl(8, byte(1, _u)), byte(0, _u)))
            }
            function cmp(p_, q_, e_) -> _l {
                for { e_ := sub(e_, q_) } lt(_l, e_) { _l := add(_l, 1) } {
                    e_ := mul(iszero(byte(0, xor(mload(add(p_, _l)), mload(add(q_, _l))))), e_)
                }
            }
            function literals(runs_, src_, dest_) -> _o {
                for { _o := dest_ } iszero(lt(runs_, 0x20)) { runs_ := sub(runs_, 0x20) } {
                    mstore(ms8(_o, 31), mload(src_))
                    _o := add(_o, 0x21)
                    src_ := add(src_, 0x20)
                }
                if iszero(runs_) { leave }
                mstore(ms8(_o, sub(runs_, 1)), mload(src_))
                _o := add(1, add(_o, runs_))
            }
            function mt(l_, d_, o_) -> _o {
                for { d_ := sub(d_, 1) } iszero(lt(l_, 263)) { l_ := sub(l_, 262) } {
                    o_ := ms8(ms8(ms8(o_, add(224, shr(8, d_))), 253), and(0xff, d_))
                }
                if iszero(lt(l_, 7)) {
                    _o := ms8(ms8(ms8(o_, add(224, shr(8, d_))), sub(l_, 7)), and(0xff, d_))
                    leave
                }
                _o := ms8(ms8(o_, add(shl(5, l_), shr(8, d_))), and(0xff, d_))
            }
            function setHash(i_, v_) {
                let p_ := add(mload(0x40), shl(2, i_))
                mstore(p_, xor(mload(p_), shl(224, xor(shr(224, mload(p_)), v_))))
            }
            function getHash(i_) -> _h {
                _h := shr(224, mload(add(mload(0x40), shl(2, i_))))
            }
            function hash(v_) -> _r {
                _r := and(shr(19, mul(2654435769, v_)), 0x1fff)
            }
            function setNextHash(ip_, ipStart_) -> _ip {
                setHash(hash(u24(ip_)), sub(ip_, ipStart_))
                _ip := add(ip_, 1)
            }
            result := mload(0x40)
            codecopy(result, codesize(), 0x8000) // Zeroize the hashmap.
            let op := add(result, 0x8000)
            let a := add(data, 0x20)
            let ipStart := a
            let ipLimit := sub(add(ipStart, mload(data)), 13)
            for { let ip := add(2, a) } lt(ip, ipLimit) {} {
                let r := 0
                let d := 0
                for {} 1 {} {
                    let s := u24(ip)
                    let h := hash(s)
                    r := add(ipStart, getHash(h))
                    setHash(h, sub(ip, ipStart))
                    d := sub(ip, r)
                    if iszero(lt(ip, ipLimit)) { break }
                    ip := add(ip, 1)
                    if iszero(gt(d, 0x1fff)) { if eq(s, u24(r)) { break } }
                }
                if iszero(lt(ip, ipLimit)) { break }
                ip := sub(ip, 1)
                if gt(ip, a) { op := literals(sub(ip, a), a, op) }
                let l := cmp(add(r, 3), add(ip, 3), add(ipLimit, 9))
                op := mt(l, d, op)
                ip := setNextHash(setNextHash(add(ip, l), ipStart), ipStart)
                a := ip
            }
            // Copy the result to compact the memory, overwriting the hashmap.
            let end := sub(literals(sub(add(ipStart, mload(data)), a), a, op), 0x7fe0)
            let o := add(result, 0x20)
            mstore(result, sub(end, o)) // Store the length.
            for {} iszero(gt(o, end)) { o := add(o, 0x20) } { mstore(o, mload(add(o, 0x7fe0))) }
            mstore(end, 0) // Zeroize the slot after the string.
            mstore(0x40, add(end, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Returns the decompressed `data`.
    function flzDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let op := add(result, 0x20)
            let end := add(add(data, 0x20), mload(data))
            for { data := add(data, 0x20) } lt(data, end) {} {
                let w := mload(data)
                let c := byte(0, w)
                let t := shr(5, c)
                if iszero(t) {
                    mstore(op, mload(add(data, 1)))
                    data := add(data, add(2, c))
                    op := add(op, add(1, c))
                    continue
                }
                for {
                    let g := eq(t, 7)
                    let l := add(2, xor(t, mul(g, xor(t, add(7, byte(1, w)))))) // M
                    let s := add(add(shl(8, and(0x1f, c)), byte(add(1, g), w)), 1) // R
                    let r := sub(op, s)
                    let f := xor(s, mul(gt(s, 0x20), xor(s, 0x20)))
                    let j := 0
                } 1 {} {
                    mstore(add(op, j), mload(add(r, j)))
                    j := add(j, f)
                    if lt(j, l) { continue }
                    data := add(data, add(2, g))
                    op := add(op, l)
                    break
                }
            }
            mstore(result, sub(op, add(result, 0x20))) // Store the length.
            mstore(op, 0) // Zeroize the slot after the string.
            mstore(0x40, add(op, 0x20)) // Allocate the memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    CALLDATA OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Calldata compression and decompression using selective run length encoding:
    // - Sequences of 0x00 (up to 128 consecutive).
    // - Sequences of 0xff (up to 32 consecutive).
    //
    // A run length encoded block consists of two bytes:
    // (0) 0x00
    // (1) A control byte with the following bit layout:
    //     - [7]     `0: 0x00, 1: 0xff`.
    //     - [0..6]  `runLength - 1`.
    //
    // The first 4 bytes are bitwise negated so that the compressed calldata
    // can be dispatched into the `fallback` and `receive` functions.

    /// @dev Returns the compressed `data`.
    function cdCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function rle(v_, o_, d_) -> _o, _d {
                mstore(o_, shl(240, or(and(0xff, add(d_, 0xff)), and(0x80, v_))))
                _o := add(o_, 2)
            }
            result := mload(0x40)
            let o := add(result, 0x20)
            let z := 0 // Number of consecutive 0x00.
            let y := 0 // Number of consecutive 0xff.
            for { let end := add(data, mload(data)) } iszero(eq(data, end)) {} {
                data := add(data, 1)
                let c := byte(31, mload(data))
                if iszero(c) {
                    if y { o, y := rle(0xff, o, y) }
                    z := add(z, 1)
                    if eq(z, 0x80) { o, z := rle(0x00, o, 0x80) }
                    continue
                }
                if eq(c, 0xff) {
                    if z { o, z := rle(0x00, o, z) }
                    y := add(y, 1)
                    if eq(y, 0x20) { o, y := rle(0xff, o, 0x20) }
                    continue
                }
                if y { o, y := rle(0xff, o, y) }
                if z { o, z := rle(0x00, o, z) }
                mstore8(o, c)
                o := add(o, 1)
            }
            if y { o, y := rle(0xff, o, y) }
            if z { o, z := rle(0x00, o, z) }
            // Bitwise negate the first 4 bytes.
            mstore(add(result, 4), not(mload(add(result, 4))))
            mstore(result, sub(o, add(result, 0x20))) // Store the length.
            mstore(o, 0) // Zeroize the slot after the string.
            mstore(0x40, add(o, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Returns the decompressed `data`.
    function cdDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                result := mload(0x40)
                let o := add(result, 0x20)
                let s := add(data, 4)
                let v := mload(s)
                let end := add(data, mload(data))
                mstore(s, not(v)) // Bitwise negate the first 4 bytes.
                for {} lt(data, end) {} {
                    data := add(data, 1)
                    let c := byte(31, mload(data))
                    if iszero(c) {
                        data := add(data, 1)
                        let d := byte(31, mload(data))
                        // Fill with either 0xff or 0x00.
                        mstore(o, not(0))
                        if iszero(gt(d, 0x7f)) { codecopy(o, codesize(), add(d, 1)) }
                        o := add(o, add(and(d, 0x7f), 1))
                        continue
                    }
                    mstore8(o, c)
                    o := add(o, 1)
                }
                mstore(s, v) // Restore the first 4 bytes.
                mstore(result, sub(o, add(result, 0x20))) // Store the length.
                mstore(o, 0) // Zeroize the slot after the string.
                mstore(0x40, add(o, 0x20)) // Allocate the memory.
            }
        }
    }

    /// @dev To be called in the `fallback` function.
    /// ```
    ///     fallback() external payable { LibZip.cdFallback(); }
    ///     receive() external payable {} // Silence compiler warning to add a `receive` function.
    /// ```
    /// For efficiency, this function will directly return the results, terminating the context.
    /// If called internally, it must be called at the end of the function.
    function cdFallback() internal {
        assembly {
            if iszero(calldatasize()) { return(calldatasize(), calldatasize()) }
            let o := 0
            let f := not(3) // For negating the first 4 bytes.
            for { let i := 0 } lt(i, calldatasize()) {} {
                let c := byte(0, xor(add(i, f), calldataload(i)))
                i := add(i, 1)
                if iszero(c) {
                    let d := byte(0, xor(add(i, f), calldataload(i)))
                    i := add(i, 1)
                    // Fill with either 0xff or 0x00.
                    mstore(o, not(0))
                    if iszero(gt(d, 0x7f)) { codecopy(o, codesize(), add(d, 1)) }
                    o := add(o, add(and(d, 0x7f), 1))
                    continue
                }
                mstore8(o, c)
                o := add(o, 1)
            }
            let success := delegatecall(gas(), address(), 0x00, o, codesize(), 0x00)
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(success) { revert(0x00, returndatasize()) }
            return(0x00, returndatasize())
        }
    }
}