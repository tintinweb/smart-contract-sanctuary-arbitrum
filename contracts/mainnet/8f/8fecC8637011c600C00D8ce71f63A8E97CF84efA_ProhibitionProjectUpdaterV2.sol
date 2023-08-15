/**
 *Submitted for verification at Arbiscan on 2023-08-14
*/

// SPDX-License-Identifier: MIT
// Created by: Thomas Lipari + VenturePunk
pragma solidity ^0.8.18;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

interface IFilteredMinterV0 {
    /**
     * @notice Price per token in wei updated for project `_projectId` to
     * `_pricePerTokenInWei`.
     */
    event PricePerTokenInWeiUpdated(
        uint256 indexed _projectId,
        uint256 indexed _pricePerTokenInWei
    );

    /**
     * @notice Currency updated for project `_projectId` to symbol
     * `_currencySymbol` and address `_currencyAddress`.
     */
    event ProjectCurrencyInfoUpdated(
        uint256 indexed _projectId,
        address indexed _currencyAddress,
        string _currencySymbol
    );

    /// togglePurchaseToDisabled updated
    event PurchaseToDisabledUpdated(
        uint256 indexed _projectId,
        bool _purchaseToDisabled
    );

    // getter function of public variable
    function minterType() external view returns (string memory);

    function genArt721CoreAddress() external returns (address);

    function minterFilterAddress() external returns (address);

    // Triggers a purchase of a token from the desired project, to the
    // TX-sending address.
    function purchase(
        uint256 _projectId
    ) external payable returns (uint256 tokenId);

    // Triggers a purchase of a token from the desired project, to the specified
    // receiving address.
    function purchaseTo(
        address _to,
        uint256 _projectId
    ) external payable returns (uint256 tokenId);

    // Toggles the ability for `purchaseTo` to be called directly with a
    // specified receiving address that differs from the TX-sending address.
    function togglePurchaseToDisabled(uint256 _projectId) external;

    // Called to make the minter contract aware of the max invocations for a
    // given project.
    function setProjectMaxInvocations(uint256 _projectId) external;

    // Gets if token price is configured, token price in wei, currency symbol,
    // and currency address, assuming this is project's minter.
    // Supersedes any defined core price.
    function getPriceInfo(
        uint256 _projectId
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        );
}

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for generic project minter configuration updates.
 * @dev keys represent strings of finite length encoded in bytes32 to minimize
 * gas.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterV1 is IFilteredMinterV0 {
    /// ANY
    /**
     * @notice Generic project minter configuration event. Removes key `_key`
     * for project `_projectId`.
     */
    event ConfigKeyRemoved(uint256 indexed _projectId, bytes32 _key);

    /// BOOL
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(uint256 indexed _projectId, bytes32 _key, bool _value);

    /// UINT256
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of uint256 at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of uint256 at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /// ADDRESS
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of addresses at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of addresses at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /// BYTES32
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of bytes32 at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of bytes32 at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @dev Strings not supported. Recommend conversion of (short) strings to
     * bytes32 to remain gas-efficient.
     */
}

/**
 * @title This interface extends the IFilteredMinterV1 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterV2 is IFilteredMinterV1 {
    /**
     * @notice Local max invocations for project `_projectId`, tied to core contract `_coreContractAddress`,
     * updated to `_maxInvocations`.
     */
    event ProjectMaxInvocationsLimitUpdated(uint256 indexed _projectId, uint256 _maxInvocations);

    // Sets the local max invocations for a given project, checking that the provided max invocations is
    // less than or equal to the global max invocations for the project set on the core contract.
    // This does not impact the max invocations value defined on the core contract.
    function manuallyLimitProjectMaxInvocations(uint256 _projectId, uint256 _maxInvocations) external;
}

/**
 * @title This interface extends the IFilteredMinterV1 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IMinterScheduledSetPriceV4_PROHIBITION is IFilteredMinterV2 {
    event SaleStartTimeUpdated(uint256 indexed projectId, uint256 timestampStart);

    struct ProjectConfig {
        bool maxHasBeenInvoked;
        bool priceIsConfigured;
        uint24 maxInvocations;
        uint64 timestampStart;
        uint256 pricePerTokenInWei;
    }

    function manuallyLimitProjectMaxInvocations(uint256 _projectId, uint256 _maxInvocations) external;
    function togglePurchaseToDisabled(uint256 _projectId) external;
    function updatePricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) external;
    function updateStartTime(uint256 _projectId, uint256 _timestampStart) external;
    function artistMint(address _to, uint256 _projectId) external payable returns (uint256 tokenId);

    function getSaleInfo(uint256 _projectId)
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress,
            uint64 timestampStart
        );
}

/**
 * @title This interface extends the IFilteredMinterV1 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IMinterScheduledSetPriceV4_PROHIBITION_V2 is IMinterScheduledSetPriceV4_PROHIBITION {
    event TxPurchaseLimitUpdated(uint256 indexed projectId, uint256 txPurchaseLimit);
    event MerkleRootUpdated(uint256 indexed projectId, bytes32 merkleRoot);

    /**
     * @notice Returns a merkle root for project with claims
     * @param _projectId Project ID to get merkle root for
     * @return _merkleRoot Merkle root for project
     */
    function merkleRoot(uint256 _projectId) external view returns (bytes32 _merkleRoot);

    /**
     * @notice Returns the transaction purchase limit for a project
     * @param _projectId Project ID the limit is for
     * @return _txPurchaseLimit Transaction purchase limit for project
     */
    function txPurchaseLimit(uint256 _projectId) external view returns (uint256 _txPurchaseLimit);

    /**
     * @notice Allows the artist to add a merkle root for a project
     * @param _projectId Project ID to update purchase limit for
     * @param _merkleRoot Merkle root for project
     */
    function updateMerkleRoot(uint256 _projectId, bytes32 _merkleRoot) external;

    /**
     * @notice Allows the artist to update transaction purchase limit for a project
     * @param _projectId Project ID to update purchase limit for
     * @param _txPurchaseLimit New transaction purchase limit for project
     */
    function updateProjectPurchaseLimit(uint256 _projectId, uint256 _txPurchaseLimit) external;

    /**
     * @notice Purchases multiple tokens from project `_projectId`.
     * @param _projectId Project ID to mint a token on.
     * @param _count number to mint
     * @return startAndEndTokenIds First and last Token ID of minted tokens
     */
    function purchaseBatch(uint256 _projectId, uint256 _count)
        external
        payable
        returns (uint256[] memory startAndEndTokenIds);

    /**
     * @notice Purchases multiple tokens from project `_projectId` and sets
     * the tokens' owner to each address in `_toList`.
     * @param _toList Addresses to be the new tokens' owners.
     * @param _projectId Project ID to mint a token on.
     * @return startAndEndTokenIds First and last Token ID of minted tokens
     */
    function purchaseToBatch(address[] calldata _toList, uint256 _projectId)
        external
        payable
        returns (uint256[] memory startAndEndTokenIds);

    /**
     * @notice allows artist to batch mint a token
     */
    function artistMintBatch(address[] calldata _toList, uint256 _projectId)
        external
        payable
        returns (uint256[] memory startAndEndTokenIds);

    /**
     * @notice Claims one or multiple tokens from project `_projectId` using a merkle proof.
     * @param _projectId Project ID to claim a token on.
     * @param _amount Amount of tokens to claim.
     * @param _proof Merkle proof for the token being claimed.
     * @param _leafAddr Address of the leaf node for the token being claimed.
     * @param _leafAmount Amount of the leaf node for the token being claimed.
     * @return _startAndEndTokenIds First and last Token ID of claimed tokens
     */

    function claim(uint256 _projectId, uint256 _amount, bytes32 _proof, address _leafAddr, uint256 _leafAmount)
        external
        returns (uint256[] memory _startAndEndTokenIds);
}

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for linear descending auctions.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterDALinV0 is IFilteredMinterV0 {
    /// Auction details updated for project `projectId`.
    event SetAuctionDetails(
        uint256 indexed projectId,
        uint256 _auctionTimestampStart,
        uint256 _auctionTimestampEnd,
        uint256 _startPrice,
        uint256 _basePrice
    );

    /// Auction details cleared for project `projectId`.
    event ResetAuctionDetails(uint256 indexed projectId);

    /// Minimum allowed auction length updated
    event MinimumAuctionLengthSecondsUpdated(
        uint256 _minimumAuctionLengthSeconds
    );

    function minimumAuctionLengthSeconds() external view returns (uint256);
}

/**
 * @title This interface extends the IFilteredMinterDALinV0 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterDALinV1 is IFilteredMinterDALinV0, IFilteredMinterV2 {}

/**
 * @title This interface extends the IFilteredMinterDALinV0 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterDALinV1_PROHIBITION is IFilteredMinterDALinV1 {
    function manuallyLimitProjectMaxInvocations(uint256 _projectId, uint256 _maxInvocations) external;
    function togglePurchaseToDisabled(uint256 _projectId) external;
    function artistMint(address _to, uint256 _projectId) external payable returns (uint256 tokenId);
    function setAuctionDetails(
        uint256 _projectId,
        uint256 _auctionTimestampStart,
        uint256 _auctionTimestampEnd,
        uint256 _startPrice,
        uint256 _basePrice
    ) external;
}

// Created By: Art Blocks Inc.

/**
 * @title This interface extends the IFilteredMinterDALinV0 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IMinterArtistMint {
    function artistMint(address _to, uint256 _projectId) external payable returns (uint256 tokenId);
}

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

interface IMinterFilterV0 {
    /**
     * @notice Emitted when contract is deployed to notify indexing services
     * of the new contract deployment.
     */
    event Deployed();

    /**
     * @notice Approved minter `_minterAddress`.
     */
    event MinterApproved(address indexed _minterAddress, string _minterType);

    /**
     * @notice Revoked approval for minter `_minterAddress`
     */
    event MinterRevoked(address indexed _minterAddress);

    /**
     * @notice Minter `_minterAddress` of type `_minterType`
     * registered for project `_projectId`.
     */
    event ProjectMinterRegistered(
        uint256 indexed _projectId,
        address indexed _minterAddress,
        string _minterType
    );

    /**
     * @notice Any active minter removed for project `_projectId`.
     */
    event ProjectMinterRemoved(uint256 indexed _projectId);

    function genArt721CoreAddress() external returns (address);

    function setMinterForProject(uint256, address) external;

    function removeMinterForProject(uint256) external;

    function mint(
        address _to,
        uint256 _projectId,
        address sender
    ) external returns (uint256);

    function getMinterForProject(uint256) external view returns (address);

    function projectHasMinter(uint256) external view returns (bool);
}

/**
 * @title Minter filter contract that allows filtered minters to be set
 * on a per-project basis.
 * This is designed to be used with IGenArt721CoreContractV3 contracts.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with limited powers.
 * Privileged roles and abilities are controlled by the core contract's Admin
 * ACL contract and a project's artist. Both of these roles hold extensive
 * power and can modify a project's current minter.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the core contract's Admin ACL
 * contract:
 * - addApprovedMinter
 * - removeApprovedMinter
 * - removeMintersForProjects
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the core contract's Admin ACL
 * contract or a project's artist:
 * - setMinterForProject
 * - removeMinterForProject
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on minters
 */
interface IMinterFilterV1 is IMinterFilterV0 {
    /// version & type of this core contract
    function MINTER_FILTER_VERSION() external returns (bytes32);

    function minterFilterVersion() external pure returns (string memory);

    function MINTER_FILTER_TYPE() external returns (bytes32);

    function minterFilterType() external pure returns (string memory);

    /**
     * @notice Approves minter `_minterAddress`.
     * @param _minterAddress Minter to be added as an approved minter.
     */
    function addApprovedMinter(address _minterAddress) external;

    /**
     * @notice Removes previously approved minter `_minterAddress`.
     * @param _minterAddress Minter to remove.
     */
    function removeApprovedMinter(address _minterAddress) external;

    /**
     * @notice Sets minter for project `_projectId` to minter
     * `_minterAddress`.
     * @param _projectId Project ID to set minter for.
     * @param _minterAddress Minter to be the project's minter.
     */
    function setMinterForProject(uint256 _projectId, address _minterAddress) external;

    /**
     * @notice Updates project `_projectId` to have no configured minter.
     * @param _projectId Project ID to remove minter.
     * @dev requires project to have an assigned minter
     */
    function removeMinterForProject(uint256 _projectId) external;

    /**
     * @notice Updates an array of project IDs to have no configured minter.
     * @param _projectIds Array of project IDs to remove minters for.
     * @dev requires all project IDs to have an assigned minter
     * @dev caution with respect to single tx gas limits
     */
    function removeMintersForProjects(uint256[] calldata _projectIds) external;

    /**
     * @notice Mint a token from project `_projectId` to `_to`, originally
     * purchased by `sender`.
     * @param _to The new token's owner.
     * @param _projectId Project ID to mint a new token on.
     * @param sender Address purchasing a new token.
     * @return _tokenId Token ID of minted token
     * @dev reverts w/nonexistent key error when project has no assigned minter
     */
    function mint(address _to, uint256 _projectId, address sender) external returns (uint256 _tokenId);

    /**
     * @notice Gets the assigned minter for project `_projectId`.
     * @param _projectId Project ID to query.
     * @return address Minter address assigned to project `_projectId`
     * @dev requires project to have an assigned minter
     */
    function getMinterForProject(uint256 _projectId) external view returns (address);

    /**
     * @notice Queries if project `_projectId` has an assigned minter.
     * @param _projectId Project ID to query.
     * @return bool true if project has an assigned minter, else false
     */
    function projectHasMinter(uint256 _projectId) external view returns (bool);

    /**
     * @notice Gets quantity of projects that have assigned minters.
     * @return uint256 quantity of projects that have assigned minters
     */
    function getNumProjectsWithMinters() external view returns (uint256);

    /**
     * @notice Get project ID and minter address at index `_index` of
     * enumerable map.
     * @param _index enumerable map index to query.
     * @return projectId project ID at index `_index`
     * @return minterAddress minter address for project at index `_index`
     * @return minterType minter type of minter at minterAddress
     * @dev index must be < quantity of projects that have assigned minters
     */
    function getProjectAndMinterInfoAt(uint256 _index)
        external
        view
        returns (uint256 projectId, address minterAddress, string memory minterType);
}

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

interface IAdminACLV0 {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     * @param previousSuperAdmin The previous superAdmin address.
     * @param newSuperAdmin The new superAdmin address.
     * @param genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     */
    event SuperAdminTransferred(
        address indexed previousSuperAdmin, address indexed newSuperAdmin, address[] genArt721CoreAddressesToUpdate
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
    function transferOwnershipOn(address _contract, address _newAdminACL) external;

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function renounceOwnershipOn(address _contract) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     */
    function allowed(address _sender, address _contract, bytes4 _selector) external view returns (bool);
}

interface IAdminACLV0_PROHIBITION is IAdminACLV0 {
    /**
     * @notice Emitted when function caller is updated.
     * @param contractAddress Contract that the selector caller is being set for.
     * @param selector Selector of the function we're giving the privilege to call.
     * @param caller Caller address that is allowed to call the function.
     * @param approved Boolean value indicating if the caller is approved or not.
     */
    event ContractSelectorApprovalUpdated(
        address indexed contractAddress, bytes4 indexed selector, address indexed caller, bool approved
    );

    /**
     * @notice Emitted when verified artist is updated.
     * @param contractAddress Contract that the selector caller is being set for.
     * @param caller Address of the artist.
     * @param approved Boolean value indicating if the caller is approved or not.
     */
    event ContractArtistApprovalUpdated(address indexed contractAddress, address indexed caller, bool approved);

    /**
     * @notice Retrieve whether of the caller is allowed to call a contract's function
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @param _caller The caller address.
     * @return isApproved The approval status.
     */
    function getContractSelectorApproval(address _contract, bytes4 _selector, address _caller)
        external
        view
        returns (bool);

    /**
     * @notice Retrieve whether of the caller is allowed to call a functions for a project
     * @param _contract The contract address.
     * @param _caller The caller address.
     * @return isApproved The approval status.
     */
    function getContractArtistApproval(address _contract, address _caller) external view returns (bool);

    /**
     * @notice Allowed caller can to set a contract function caller.
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @param _caller The caller address.
     * @dev this function is gated to only superAdmin address or allowed caller.
     */
    function toggleContractSelectorApproval(address _contract, bytes4 _selector, address _caller) external;

    /**
     * @notice Toggles verification for artists to call functions relating to their projects on a contract
     * @param _contract The contract address.
     * @param _caller The caller address.
     * @dev this function is gated to only allwed addressed.
     */
    function toggleContractArtistApproval(address _contract, address _caller) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function (or functions for projects) with
     * method `_selector` on `_contract`. Returns true if sender is superAdmin.
     * @param _sender The sender address.
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @param _projectId The project ID.
     * @return isApproved The approval status.
     * @dev this function is public insteaad of internal so that the right to toggle approvals can also be delegated
     */
    function allowed(address _sender, address _contract, bytes4 _selector, uint256 _projectId)
        external
        view
        returns (bool);
}

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

// Created By: Art Blocks Inc.

/// use the Royalty Registry's IManifold interface for token royalties

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
    function adminACLAllowed(address _sender, address _contract, bytes4 _selector) external view returns (bool);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(uint256 tokenId) external view returns (uint256 projectId);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(uint256 _projectId) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySales(uint256 _projectId) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySalesPercentage(uint256 _projectId) external view returns (uint256);

    function projectIdToSecondaryMarketRoyaltyPercentage(uint256 _projectId) external view returns (uint256);

    function projectURIInfo(uint256 _projectId) external view returns (string memory projectBaseURI);

    // @dev new function in V3
    function projectStateData(uint256 _projectId)
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

    function projectDetails(uint256 _projectId)
        external
        view
        returns (
            string memory projectName,
            string memory artist,
            string memory description,
            string memory website,
            string memory license
        );

    function projectScriptDetails(uint256 _projectId)
        external
        view
        returns (string memory scriptTypeAndVersion, string memory aspectRatio, uint256 scriptCount);

    function projectScriptByIndex(uint256 _projectId, uint256 _index) external view returns (string memory);

    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);

    // function to set a token's hash (must be guarded)
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hash) external;

    // @dev gas-optimized signature in V3 for `mint`
    function mint_Ecf(address _to, uint256 _projectId, address _by) external returns (uint256 tokenId);
}

interface IGenArt721CoreContractV3_Engine is IGenArt721CoreContractV3_Base {
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

    // @dev The render provider secondary sales royalties payment address
    function renderProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider secondary sales royalties payment address
    function platformProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Basis points of secondary sales allocated to the render provider
    function renderProviderSecondarySalesBPS() external view returns (uint256);

    // @dev Basis points of secondary sales allocated to the platform provider
    function platformProviderSecondarySalesBPS()
        external
        view
        returns (uint256);

    // function to read the hash-seed for a given tokenId
    function tokenIdToHashSeed(
        uint256 _tokenId
    ) external view returns (bytes12);
}

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
     * @param _cid The content ID of the external asset dependency. This is an empty string
     * if the dependency type is ONCHAIN.
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
     * @notice An external asset dependency type. Can be one of IPFS, ARWEAVE, or ONCHAIN.
     */
    enum ExternalAssetDependencyType {
        IPFS,
        ARWEAVE,
        ONCHAIN
    }

    /**
     * @notice An external asset dependency. This is a struct that contains the CID of the dependency,
     * the type of the dependency, and the address of the bytecode for this dependency.
     */
    struct ExternalAssetDependency {
        string cid;
        ExternalAssetDependencyType dependencyType;
        address bytecodeAddress;
    }

    /**
     * @notice An external asset dependency with data. This is a convenience struct that contains the CID of the dependency,
     * the type of the dependency, the address of the bytecode for this dependency, and the data retrieved from this bytecode address.
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

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 Engine Flex and derivative implementations.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Engine_Flex_PROHIBITION is IGenArt721CoreContractV3_Engine_Flex {
    /**
     * Function determining if _sender is allowed to call function with
     * selector _selector on contract `_contract` for project `_projectId`.
     * Intended to be used with peripheral contracts such as minters, as well
     * as internally by the core contract itself.
     */
    function adminACLAllowed(address _sender, address _contract, bytes4 _selector, uint256 _projectId)
        external
        returns (bool);

    function addProject(string memory _projectName, address payable _artistAddress) external;

    function updateProjectName(uint256 _projectId, string memory _projectName) external;

    function toggleProjectIsActive(uint256 _projectId) external;

    function toggleProjectIsPaused(uint256 _projectId) external;

    function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) external;

    function updateProjectSecondaryMarketRoyaltyPercentage(uint256 _projectId, uint256 _secondMarketRoyalty) external;

    function updateProjectDescription(uint256 _projectId, string memory _projectDescription) external;

    function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) external;

    function updateProjectLicense(uint256 _projectId, string memory _projectLicense) external;

    function updateProjectMaxInvocations(uint256 _projectId, uint24 _maxInvocations) external;

    function addProjectScript(uint256 _projectId, string memory _script) external;

    function updateProjectScript(uint256 _projectId, uint256 _scriptId, string memory _script) external;

    function updateProjectAspectRatio(uint256 _projectId, string memory _aspectRatio) external;

    function updateProjectScriptType(uint256 _projectId, bytes32 _scriptTypeAndVersion) external;

    function proposeArtistPaymentAddressesAndSplits(
        uint256 _projectId,
        address payable _artistAddress,
        address payable _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address payable _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    ) external;
}

contract ProhibitionProjectUpdaterV2 is Ownable {
    IGenArt721CoreContractV3_Engine_Flex_PROHIBITION public genArt721CoreContract;
    IMinterFilterV1 public minterFilterContract;
    IMinterScheduledSetPriceV4_PROHIBITION_V2 public minterSetPriceContract;
    IFilteredMinterDALinV1_PROHIBITION public minterDALinContract;

    // String values
    bytes32 constant PROJECT_NAME = keccak256("projectName");
    bytes32 constant PROJECT_ARTIST_NAME = keccak256("projectArtistName");
    bytes32 constant PROJECT_LICENSE = keccak256("projectLicense");
    bytes32 constant PROJECT_DESCRIPTION = keccak256("projectDescription");
    bytes32 constant PROJECT_WEBSITE = keccak256("projectWebsite");
    bytes32 constant PROJECT_ASPECT_RATIO = keccak256("projectAspectRatio");
    bytes32 constant PROJECT_SCRIPT_TYPE = keccak256("projectScriptType");
    bytes32 constant MINTER_FILTER_SET_MINTER = keccak256("projectScriptType");
    // Number values
    bytes32 constant SECONDARY_MARKET_ROYALTY = keccak256("secondaryMarketRoyalty");
    bytes32 constant PROJECT_MAX_INVOCATIONS = keccak256("maxInvocations");
    // Whether or not creating projects is allowed
    bool public PROJECT_CREATION_OPEN = true;

    struct UpdateStringField {
        string field;
        string value;
    }

    struct UpdateNumberField {
        string field;
        uint256 value;
    }

    struct SetPriceConfig {
        uint256 pricePerTokenInWei;
        uint256 timestampStart;
        uint256 txPurchaseLimit;
        bytes32 merkleRoot;
    }

    struct DALinConfig {
        uint256 auctionTimestampStart;
        uint256 auctionTimestampEnd;
        uint256 startPrice;
        uint256 basePrice;
    }

    constructor(
        address _genArt721CoreContract,
        address _minterFilterContract,
        address _minterSetPriceContract,
        address _minterDALinContract
    ) Ownable() {
        genArt721CoreContract = IGenArt721CoreContractV3_Engine_Flex_PROHIBITION(_genArt721CoreContract);
        minterFilterContract = IMinterFilterV1(_minterFilterContract);
        minterSetPriceContract = IMinterScheduledSetPriceV4_PROHIBITION_V2(_minterSetPriceContract);
        minterDALinContract = IFilteredMinterDALinV1_PROHIBITION(_minterDALinContract);
    }

    function _creatingProjectsAllowed(address _msgSender) internal view {
        require(
            PROJECT_CREATION_OPEN || _msgSender == owner(),
            "ProhibitionProjectUpdater: Creating projects is not allowed"
        );
    }

    function _onlyProjectArtist(uint256 _projectId) internal view {
        require(
            genArt721CoreContract.projectIdToArtistAddress(_projectId) == msg.sender,
            "ProhibitionProjectUpdater: Only the artist can update the project"
        );
    }

    function updateGenArt721CoreContract(address _genArt721CoreContract) external onlyOwner {
        genArt721CoreContract = IGenArt721CoreContractV3_Engine_Flex_PROHIBITION(_genArt721CoreContract);
    }

    function updateMinterFilterContract(address _minterFilterContract) external onlyOwner {
        minterFilterContract = IMinterFilterV1(_minterFilterContract);
    }

    function updateMinterSetPriceContract(address _minterSetPriceContract) external onlyOwner {
        minterSetPriceContract = IMinterScheduledSetPriceV4_PROHIBITION_V2(_minterSetPriceContract);
    }

    function updateMinterDALinContract(address _minterDALinContract) external onlyOwner {
        minterDALinContract = IFilteredMinterDALinV1_PROHIBITION(_minterDALinContract);
    }

    function toggleProjectCreationOpen() external onlyOwner {
        PROJECT_CREATION_OPEN = !PROJECT_CREATION_OPEN;
    }

    function _getUpdateNumberMethod(string memory _field, uint256 _projectId, uint256 _value) internal {
        if (keccak256(bytes(_field)) == SECONDARY_MARKET_ROYALTY) {
            genArt721CoreContract.updateProjectSecondaryMarketRoyaltyPercentage(_projectId, _value);
        } else if (keccak256(bytes(_field)) == PROJECT_MAX_INVOCATIONS) {
            genArt721CoreContract.updateProjectMaxInvocations(_projectId, uint24(_value));
        } else {
            revert("ProhibitionProjectUpdater: Invalid number field");
        }
    }

    function _updateStringMethod(string memory _field, uint256 _projectId, string memory _value) internal {
        if (keccak256(bytes(_field)) == PROJECT_NAME) {
            genArt721CoreContract.updateProjectName(_projectId, _value);
        } else if (keccak256(bytes(_field)) == PROJECT_ARTIST_NAME) {
            genArt721CoreContract.updateProjectArtistName(_projectId, _value);
        } else if (keccak256(bytes(_field)) == PROJECT_LICENSE) {
            genArt721CoreContract.updateProjectLicense(_projectId, _value);
        } else if (keccak256(bytes(_field)) == PROJECT_DESCRIPTION) {
            genArt721CoreContract.updateProjectDescription(_projectId, _value);
        } else if (keccak256(bytes(_field)) == PROJECT_WEBSITE) {
            genArt721CoreContract.updateProjectWebsite(_projectId, _value);
        } else if (keccak256(bytes(_field)) == PROJECT_ASPECT_RATIO) {
            genArt721CoreContract.updateProjectAspectRatio(_projectId, _value);
        } else if (keccak256(bytes(_field)) == PROJECT_SCRIPT_TYPE) {
            genArt721CoreContract.updateProjectScriptType(_projectId, this.stringToBytes32(_value));
        } else {
            revert("ProhibitionProjectUpdater: Invalid string field");
        }
    }

    function _updateProjectValues(
        uint256 _projectId,
        UpdateStringField[] calldata _updateStringFields,
        UpdateNumberField[] calldata _updateNumberFields
    ) internal {
        for (uint256 i = 0; i < _updateStringFields.length;) {
            _updateStringMethod(_updateStringFields[i].field, _projectId, _updateStringFields[i].value);
            unchecked {
                i++;
            }
        }

        for (uint256 i = 0; i < _updateNumberFields.length;) {
            _getUpdateNumberMethod(_updateNumberFields[i].field, _projectId, _updateNumberFields[i].value);
            unchecked {
                i++;
            }
        }
    }

    function createProject(
        string memory _projectName,
        UpdateStringField[] calldata _updateStringFields,
        UpdateNumberField[] calldata _updateNumberFields
    ) external {
        _creatingProjectsAllowed(msg.sender);
        uint256 projectId = genArt721CoreContract.nextProjectId();
        genArt721CoreContract.addProject(_projectName, payable(msg.sender));
        _updateProjectValues(projectId, _updateStringFields, _updateNumberFields);
    }

    function createProject(
        string memory _projectName,
        UpdateStringField[] calldata _updateStringFields,
        UpdateNumberField[] calldata _updateNumberFields,
        SetPriceConfig calldata _setPriceConfig
    ) external {
        _creatingProjectsAllowed(msg.sender);
        uint256 projectId = genArt721CoreContract.nextProjectId();
        genArt721CoreContract.addProject(_projectName, payable(msg.sender));
        _updateProjectValues(projectId, _updateStringFields, _updateNumberFields);
        _setFlatPriceMinter(projectId, _setPriceConfig);
    }

    function createProject(
        string memory _projectName,
        UpdateStringField[] calldata _updateStringFields,
        UpdateNumberField[] calldata _updateNumberFields,
        DALinConfig calldata _daLinConfig
    ) external {
        _creatingProjectsAllowed(msg.sender);
        uint256 projectId = genArt721CoreContract.nextProjectId();
        genArt721CoreContract.addProject(_projectName, payable(msg.sender));
        _updateProjectValues(projectId, _updateStringFields, _updateNumberFields);
        _setDALinMinter(projectId, _daLinConfig);
    }

    function updateProject(
        uint256 _projectId,
        UpdateStringField[] calldata _updateStringFields,
        UpdateNumberField[] calldata _updateNumberFields
    ) external {
        _onlyProjectArtist(_projectId);
        _updateProjectValues(_projectId, _updateStringFields, _updateNumberFields);
    }

    function updateProject(
        uint256 _projectId,
        UpdateStringField[] calldata _updateStringFields,
        UpdateNumberField[] calldata _updateNumberFields,
        SetPriceConfig calldata _setPriceConfig
    ) external {
        _onlyProjectArtist(_projectId);
        _updateProjectValues(_projectId, _updateStringFields, _updateNumberFields);
        _updateMinterToSetPriceMinter(_projectId, _setPriceConfig);
    }

    function updateProject(
        uint256 _projectId,
        UpdateStringField[] calldata _updateStringFields,
        UpdateNumberField[] calldata _updateNumberFields,
        DALinConfig calldata _daLinConfig
    ) external {
        _onlyProjectArtist(_projectId);
        _updateProjectValues(_projectId, _updateStringFields, _updateNumberFields);
        _updateMinterToDALinMinter(_projectId, _daLinConfig);
    }

    function activateProject(uint256 _projectId) external {
        _onlyProjectArtist(_projectId);
        (,, bool active,,,) = genArt721CoreContract.projectStateData(_projectId);
        require(!active, "ProhibitionProjectUpdater: Project already active");
        genArt721CoreContract.toggleProjectIsActive(_projectId);
    }

    function _setFlatPriceMinter(uint256 _projectId, SetPriceConfig calldata _setPriceConfig) internal {
        minterFilterContract.setMinterForProject(_projectId, address(minterSetPriceContract));
        _setFlatPriceSale(_projectId, _setPriceConfig);
    }

    function _setDALinMinter(uint256 _projectId, DALinConfig calldata _daLinConfig) internal {
        minterFilterContract.setMinterForProject(_projectId, address(minterDALinContract));
        _setDALinSale(_projectId, _daLinConfig);
    }

    function _setFlatPriceSale(uint256 _projectId, SetPriceConfig calldata _setPriceConfig) internal {
        minterSetPriceContract.updatePricePerTokenInWei(_projectId, _setPriceConfig.pricePerTokenInWei);
        minterSetPriceContract.updateStartTime(_projectId, _setPriceConfig.timestampStart);
        minterSetPriceContract.updateProjectPurchaseLimit(_projectId, _setPriceConfig.txPurchaseLimit);
        minterSetPriceContract.updateMerkleRoot(_projectId, _setPriceConfig.merkleRoot);
    }

    function _setDALinSale(uint256 _projectId, DALinConfig calldata _daLinConfig) internal {
        minterDALinContract.setAuctionDetails(
            _projectId,
            _daLinConfig.auctionTimestampStart,
            _daLinConfig.auctionTimestampEnd,
            _daLinConfig.startPrice,
            _daLinConfig.basePrice
        );
    }

    function _updateMinterToDALinMinter(uint256 _projectId, DALinConfig calldata _daLinConfig) internal {
        bool projectHasMinter = minterFilterContract.projectHasMinter(_projectId);
        address minterAddress = address(minterDALinContract);

        if (!projectHasMinter || minterFilterContract.getMinterForProject(_projectId) != minterAddress) {
            _setDALinMinter(_projectId, _daLinConfig);
        } else {
            _setDALinSale(_projectId, _daLinConfig);
        }
    }

    function _updateMinterToSetPriceMinter(uint256 _projectId, SetPriceConfig calldata _setPriceConfig) internal {
        bool projectHasMinter = minterFilterContract.projectHasMinter(_projectId);
        address minterAddress = address(minterSetPriceContract);

        if (!projectHasMinter || minterFilterContract.getMinterForProject(_projectId) != minterAddress) {
            _setFlatPriceMinter(_projectId, _setPriceConfig);
        } else {
            _setFlatPriceSale(_projectId, _setPriceConfig);
        }
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}