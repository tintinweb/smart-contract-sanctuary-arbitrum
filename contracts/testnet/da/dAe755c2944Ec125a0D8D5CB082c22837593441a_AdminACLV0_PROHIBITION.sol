// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./interfaces/IAdminACLV0_PROHIBITION.sol";
import "../../../../interfaces/v0.8.x/IGenArt721CoreContractV3_Base.sol";

import "@openzeppelin-4.7/contracts/access/Ownable.sol";
import "@openzeppelin-4.7/contracts/utils/introspection/ERC165.sol";

/**
 * @title Admin ACL contract, V0.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract has a single superAdmin that passes all ACL checks. All checks
 * for any other address will return false.
 * The superAdmin can be changed by the current superAdmin.
 * Care must be taken to ensure that the admin ACL contract is secure behind a
 * multi-sig or other secure access control mechanism.
 */
contract AdminACLV0_PROHIBITION is IAdminACLV0_PROHIBITION, ERC165 {
    string public AdminACLType = "AdminACLV0_PROHIBITION";

    /// superAdmin is the only address that passes any and all ACL checks
    address public superAdmin;

    /// contractSelectorApprovals is a mapping of:
    ///   keccak256(contracts, selectors, account) -> approved to call.
    /// It is used to determine if an account is approved to call a function on specific contracts.
    mapping(bytes32 => bool) contractSelectorApprovals;

    /// contractArtistApprovals is a mapping of:
    ///   keccak256(contracts, artist) -> approved to call.
    /// It is used to determine if an account is approved to call a functions for specific projects.
    mapping(bytes32 => bool) contractArtistApprovals;

    constructor() {
        superAdmin = msg.sender;
    }

    /**
     * @notice Allows superAdmin change the superAdmin address.
     * @param _newSuperAdmin The new superAdmin address.
     * @param _genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     * @dev this function is gated to only superAdmin address.
     */
    function changeSuperAdmin(
        address _newSuperAdmin,
        address[] calldata _genArt721CoreAddressesToUpdate
    ) external {
        require(msg.sender == superAdmin, "Only superAdmin");
        address previousSuperAdmin = superAdmin;
        superAdmin = _newSuperAdmin;
        emit SuperAdminTransferred(
            previousSuperAdmin,
            _newSuperAdmin,
            _genArt721CoreAddressesToUpdate
        );
    }

    /**
     * Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @param _contract The contract address.
     * @param _newAdminACL The new AdminACL contract address.
     * @dev This function is gated to only superAdmin address.
     * @dev This implementation requires that the new AdminACL contract
     * broadcasts support of IAdminACLV0 via ERC165 interface detection.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external {
        require(msg.sender == superAdmin, "Only superAdmin");
        // ensure new AdminACL contract supports IAdminACLV0
        require(
            ERC165(_newAdminACL).supportsInterface(
                type(IAdminACLV0).interfaceId
            ),
            "AdminACLV0: new admin ACL does not support IAdminACLV0"
        );
        Ownable(_contract).transferOwnership(_newAdminACL);
    }

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @param _contract The contract address.
     * @dev this function is gated to only superAdmin address.
     */
    function renounceOwnershipOn(address _contract) external {
        require(msg.sender == superAdmin, "Only superAdmin");
        Ownable(_contract).renounceOwnership();
    }

    /**
     * @notice Retrieve the address of the caller that is allowed to call a contract's function
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @param _caller The caller address.
     * @return isApproved The approval status.
     */
    function getContractSelectorApproval(
        address _contract,
        bytes4 _selector,
        address _caller
    ) public view returns (bool) {
        return
            contractSelectorApprovals[
                hashSelectorApprovalKey(_contract, _selector, _caller)
            ];
    }

    /**
     * @notice Retrieve whether of the caller is allowed to call a functions for a project
     * @param _contract The contract address.
     * @param _caller The caller address.
     * @return isApproved The approval status.
     */
    function getContractArtistApproval(
        address _contract,
        address _caller
    ) public view returns (bool) {
        return
            contractArtistApprovals[hashArtistApprovalKey(_contract, _caller)];
    }

    /**
     * @notice Toggles ability for caller to call specific function on a contract
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @param _caller The caller address.
     * @dev this function is gated to only allwed addressed.
     */
    function toggleContractSelectorApproval(
        address _contract,
        bytes4 _selector,
        address _caller
    ) external {
        require(
            allowed(
                msg.sender,
                address(this),
                this.toggleContractSelectorApproval.selector
            ),
            "Only allowed caller"
        );

        bytes32 approvalHash = hashSelectorApprovalKey(
            _contract,
            _selector,
            _caller
        );
        contractSelectorApprovals[approvalHash] = !contractSelectorApprovals[
            approvalHash
        ];
        emit ContractSelectorApprovalUpdated(
            _contract,
            _selector,
            _caller,
            contractSelectorApprovals[approvalHash]
        );
    }

    /**
     * @notice Toggles verification for artists to call functions relating to their projects
     * on a contract
     * @param _contract The contract address.
     * @param _caller The caller address.
     * @dev this function is gated to only allwed addressed.
     */
    function toggleContractArtistApproval(
        address _contract,
        address _caller
    ) external {
        require(
            allowed(
                msg.sender,
                address(this),
                this.toggleContractArtistApproval.selector
            ),
            "Only allowed caller"
        );

        bytes32 approvalHash = hashArtistApprovalKey(_contract, _caller);
        contractArtistApprovals[approvalHash] = !contractArtistApprovals[
            approvalHash
        ];
        emit ContractArtistApprovalUpdated(
            _contract,
            _caller,
            contractArtistApprovals[approvalHash]
        );
    }

    /**
     * @notice Checks if sender `_sender` is allowed to call function with method
     * `_selector` on `_contract`. Returns true if sender is superAdmin.
     * @param _sender The sender address.
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @return isApproved The approval status.
     * @dev this function is public insteaad of internal so that the right to toggle approvals
     * can also be delegated
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) public view returns (bool) {
        return
            superAdmin == _sender ||
            getContractSelectorApproval(_contract, _selector, _sender);
    }

    /**
     * @notice Checks if sender `_sender` is allowed to call function (or functions) for projects
     * `projectId` with method `_selector` on `_contract`. Returns true if sender is superAdmin.
     * @param _sender The sender address.
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @param _projectId The project ID.
     * @return isApproved The approval status.
     * @dev this function is public insteaad of internal so that the right to toggle approvals
     * can also be delegated
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector,
        uint256 _projectId
    ) external view returns (bool) {
        IGenArt721CoreContractV3_Base coreV3 = IGenArt721CoreContractV3_Base(
            _contract
        );
        return
            allowed(_sender, _contract, _selector) ||
            (getContractArtistApproval(_contract, _sender) &&
                coreV3.projectIdToArtistAddress(_projectId) == _sender);
    }

    /**
     * @notice Hash the contract address, selector, and caller address.
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @param _caller The caller address.
     * @return hash The hash.
     */
    function hashSelectorApprovalKey(
        address _contract,
        bytes4 _selector,
        address _caller
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_contract, _selector, _caller));
    }

    /**
     * @notice Hash the contract address and artist address.
     * @param _contract The contract address.
     * @param _caller The artist address.
     * @return hash The hash.
     */
    function hashArtistApprovalKey(
        address _contract,
        address _caller
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_contract, _caller));
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IAdminACLV0_PROHIBITION).interfaceId ||
            interfaceId == type(IAdminACLV0).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "../../../../../interfaces/v0.8.x/IAdminACLV0.sol";

interface IAdminACLV0_PROHIBITION is IAdminACLV0 {
    /**
     * @notice Emitted when function caller is updated.
     * @param contractAddress Contract that the selector caller is being set for.
     * @param selector Selector of the function we're giving the privilege to call.
     * @param caller Caller address that is allowed to call the function.
     * @param approved Boolean value indicating if the caller is approved or not.
     */
    event ContractSelectorApprovalUpdated(
        address indexed contractAddress,
        bytes4 indexed selector,
        address indexed caller,
        bool approved
    );

    /**
     * @notice Emitted when verified artist is updated.
     * @param contractAddress Contract that the selector caller is being set for.
     * @param caller Address of the artist.
     * @param approved Boolean value indicating if the caller is approved or not.
     */
    event ContractArtistApprovalUpdated(
        address indexed contractAddress,
        address indexed caller,
        bool approved
    );

    /**
     * @notice Retrieve whether of the caller is allowed to call a contract's function
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @param _caller The caller address.
     * @return isApproved The approval status.
     */
    function getContractSelectorApproval(
        address _contract,
        bytes4 _selector,
        address _caller
    ) external view returns (bool);

    /**
     * @notice Retrieve whether of the caller is allowed to call a functions for a project
     * @param _contract The contract address.
     * @param _caller The caller address.
     * @return isApproved The approval status.
     */
    function getContractArtistApproval(
        address _contract,
        address _caller
    ) external view returns (bool);

    /**
     * @notice Allowed caller can to set a contract function caller.
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @param _caller The caller address.
     * @dev this function is gated to only superAdmin address or allowed caller.
     */
    function toggleContractSelectorApproval(
        address _contract,
        bytes4 _selector,
        address _caller
    ) external;

    /**
     * @notice Toggles verification for artists to call functions relating to their projects on a contract
     * @param _contract The contract address.
     * @param _caller The caller address.
     * @dev this function is gated to only allwed addressed.
     */
    function toggleContractArtistApproval(
        address _contract,
        address _caller
    ) external;

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
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector,
        uint256 _projectId
    ) external returns (bool);

    /**
     * @notice Hash the contract address, selector, and caller address.
     * @param _contract The contract address.
     * @param _selector The function selector.
     * @param _caller The caller address.
     * @return hash The hash.
     */
    function hashSelectorApprovalKey(
        address _contract,
        bytes4 _selector,
        address _caller
    ) external pure returns (bytes32);

    /**
     * @notice Hash the contract address and artist address.
     * @param _contract The contract address.
     * @param _caller The artist address.
     * @return hash The hash.
     */
    function hashArtistApprovalKey(
        address _contract,
        address _caller
    ) external pure returns (bytes32);
}

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