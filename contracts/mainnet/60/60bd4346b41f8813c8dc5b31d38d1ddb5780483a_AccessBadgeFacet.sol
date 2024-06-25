// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IResourceLocator} from '../interfaces/IResourceLocator.sol';
import {LibAccessBadge} from '../libraries/LibAccessBadge.sol';
import {LibContractOwner} from '../../lib/@lagunagames/lg-diamond-template/src/libraries/LibContractOwner.sol';

/// @title Access Badge Admin facet for Crypto Unicorns
/// @author [email protected]
contract AccessBadgeFacet {
    /// @notice Returns the 1155 pool ID for a badge
    /// @param name The name of the badge (registered on this contract)
    /// @return poolId The pool ID for the badge, on the AccessControl contract
    function getPoolByName(string memory name) external view returns (uint256 poolId) {
        poolId = LibAccessBadge.getPoolByName(name);
    }

    /// @notice Assign a name to an 1155 pool on the AccessControl contract
    /// @dev Contract owner only
    /// @param name The name of the badge
    /// @param poolId The pool ID for the badge, on the AccessControl contract
    function setPoolName(uint256 poolId, string memory name) external {
        LibContractOwner.enforceIsContractOwner();
        LibAccessBadge.setPoolName(poolId, name);
    }

    /// @notice Throw an error if the sender does not have the required badge
    /// @param badge The name of the badge
    /// @custom:throws AccessBadgeRequired
    function requireBadge(string memory badge) external view {
        LibAccessBadge.requireBadge(badge);
    }

    /// @notice Throw an error if the sender does not have the required badge
    /// @param poolId The pool ID of the badge
    /// @custom:throws AccessTokenRequired
    function requireBadgeById(uint256 poolId) external view {
        LibAccessBadge.requireBadgeById(poolId);
    }

    /// @notice Check if an address has a badge
    /// @param a The address to check
    /// @param badge The name of the badge
    /// @return true if the address has the badge
    function hasBadge(address a, string memory badge) external view returns (bool) {
        return LibAccessBadge.hasBadge(a, badge);
    }

    /// @notice Check if an address has a badge
    /// @param a The address to check
    /// @param poolId The pool ID for the badge
    /// @return true if the address has the badge
    function hasBadgeById(address a, uint256 poolId) external view returns (bool) {
        return LibAccessBadge.hasBadgeById(a, poolId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Resource Locator for Crypto Unicorns
/// @author [email protected]
interface IResourceLocator {
    /// @notice Returns the Unicorn NFT contract address
    function unicornNFTAddress() external view returns (address);

    /// @notice Returns the Land NFT contract address
    function landNFTAddress() external view returns (address);

    /// @notice Returns the Shadowcorn NFT contract address
    function shadowcornNFTAddress() external view returns (address);

    /// @notice Returns the Gem NFT contract address
    function gemNFTAddress() external view returns (address);

    /// @notice Returns the Ritual NFT contract address
    function ritualNFTAddress() external view returns (address);

    /// @notice Returns the RBW Token contract address
    function rbwTokenAddress() external view returns (address);

    /// @notice Returns the CU Token contract address
    function cuTokenAddress() external view returns (address);

    /// @notice Returns the UNIM Token contract address
    function unimTokenAddress() external view returns (address);

    /// @notice Returns the WETH Token contract address
    function wethTokenAddress() external view returns (address);

    /// @notice Returns the DarkMark Token contract address
    function darkMarkTokenAddress() external view returns (address);

    /// @notice Returns the Unicorn Items contract address
    function unicornItemsAddress() external view returns (address);

    /// @notice Returns the Shadowcorn Items contract address
    function shadowcornItemsAddress() external view returns (address);

    /// @notice Returns the Access Control Badge contract address
    function accessControlBadgeAddress() external view returns (address);

    /// @notice Returns the GameBank contract address
    function gameBankAddress() external view returns (address);

    /// @notice Returns the SatelliteBank contract address
    function satelliteBankAddress() external view returns (address);

    /// @notice Returns the PlayerProfile contract address
    function playerProfileAddress() external view returns (address);

    /// @notice Returns the Shadow Forge contract address
    function shadowForgeAddress() external view returns (address);

    /// @notice Returns the Dark Forest contract address
    function darkForestAddress() external view returns (address);

    /// @notice Returns the Game Server SSS contract address
    function gameServerSSSAddress() external view returns (address);

    /// @notice Returns the Game Server Oracle contract address
    function gameServerOracleAddress() external view returns (address);

    /// @notice Returns the VRF Oracle contract address
    function vrfOracleAddress() external view returns (address);

    /// @notice Returns the VRF Client Wallet address
    function vrfClientWalletAddress() external view returns (address);

    /// @notice Returns the Testnet Debug Registry address
    /// @dev Available on testnet deployments only
    function testnetDebugRegistryAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC1155} from '../../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';
import {LibResourceLocator} from './LibResourceLocator.sol';

/// @title LG Access Library
/// @author [email protected]
/// @notice Library for checking permission via 1155 badges
/// @custom:storage-location erc7201:games.laguna.LibAccessBadge
library LibAccessBadge {
    error PoolNameUndefined(string badge);
    error InvalidPoolId(uint256 poolId);
    error AccessBadgeRequired(address caller, string badge);
    error AccessTokenRequired(address caller, uint256 poolId);
    error ERC1155TokenRequired(address caller, address token, uint256 poolId);

    //  @dev Storage slot for LG Resource addresses
    bytes32 internal constant ACCESS_BADGE_SLOT_POSITION =
        keccak256(abi.encode(uint256(keccak256('games.laguna.LibAccessBadge')) - 1)) & ~bytes32(uint256(0xff));

    struct AccessBadgeStorageStruct {
        //  String handles for 1155 pools
        mapping(string name => uint256 poolId) namedBadges;
        //  List of all pools that have been named
        uint256[] namedPools;
    }

    /// @notice Storage slot for Access Badge state data
    function accessBadgeStorage() internal pure returns (AccessBadgeStorageStruct storage storageSlot) {
        bytes32 position = ACCESS_BADGE_SLOT_POSITION;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageSlot.slot := position
        }
    }

    function getPoolByName(string memory name) internal view returns (uint256 poolId) {
        return accessBadgeStorage().namedBadges[name];
    }

    function setPoolName(uint256 poolId, string memory name) internal {
        require(poolId > 0, 'InvalidPoolId: Must be > 0');
        accessBadgeStorage().namedBadges[name] = poolId;
        uint256 poolCount = accessBadgeStorage().namedPools.length;
        for (uint256 i = 0; i < poolCount; ++i) {
            if (accessBadgeStorage().namedPools[i] == poolId) {
                return;
            }
        }
        accessBadgeStorage().namedPools.push(poolId);
    }

    function requireBadge(string memory name) internal view {
        uint256 poolId = getPoolByName(name);
        if (poolId == 0) revert PoolNameUndefined(name);
        if (!hasBadgeById(msg.sender, poolId)) {
            revert AccessBadgeRequired(msg.sender, name);
        }
    }

    function requireBadgeById(uint256 poolId) internal view {
        if (poolId == 0) revert InvalidPoolId(poolId);
        if (!hasBadgeById(msg.sender, poolId)) {
            revert AccessTokenRequired(msg.sender, poolId);
        }
    }

    function hasBadge(address a, string memory name) internal view returns (bool) {
        return hasBadgeById(a, getPoolByName(name));
    }

    function hasBadgeById(address a, uint256 poolId) internal view returns (bool) {
        IERC1155 terminus = IERC1155(LibResourceLocator.accessControlBadge());
        return terminus.balanceOf(a, poolId) > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Library for the common LG implementation of ERC-173 Contract Ownership Standard
/// @author [email protected]
/// @custom:storage-location erc1967:eip1967.proxy.admin
library LibContractOwner {
    error CallerIsNotContractOwner();

    /// @notice This emits when ownership of a contract changes.
    /// @dev ERC-173
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when the admin account has changed.
    /// @dev ERC-1967
    event AdminChanged(address previousAdmin, address newAdmin);

    //  @dev Standard storage slot for the ERC-1967 admin address
    //  @dev bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 private constant ADMIN_SLOT_POSITION = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    struct LibOwnerStorage {
        address contractOwner;
    }

    /// @notice Storage slot for Contract Owner state data
    function ownerStorage() internal pure returns (LibOwnerStorage storage storageSlot) {
        bytes32 position = ADMIN_SLOT_POSITION;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageSlot.slot := position
        }
    }

    /// @notice Sets the contract owner
    /// @param newOwner The new owner
    /// @custom:emits OwnershipTransferred
    function setContractOwner(address newOwner) internal {
        LibOwnerStorage storage ls = ownerStorage();
        address previousOwner = ls.contractOwner;
        ls.contractOwner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
        emit AdminChanged(previousOwner, newOwner);
    }

    /// @notice Gets the contract owner wallet
    /// @return owner The contract owner
    function contractOwner() internal view returns (address owner) {
        owner = ownerStorage().contractOwner;
    }

    /// @notice Ensures that the caller is the contract owner, or throws an error.
    /// @custom:throws LibAccess: Must be contract owner
    function enforceIsContractOwner() internal view {
        if (msg.sender != ownerStorage().contractOwner) revert CallerIsNotContractOwner();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC165} from '../../lib/@lagunagames/lg-diamond-template/src/interfaces/IERC165.sol';
import {IResourceLocator} from '../interfaces/IResourceLocator.sol';

/// @title LG Resource Locator Library
/// @author [email protected]
/// @notice Library for common LG Resource Locations deployed on a chain
/// @custom:storage-location erc7201:games.laguna.LibResourceLocator
library LibResourceLocator {
    //  @dev Storage slot for LG Resource addresses
    bytes32 internal constant RESOURCE_LOCATOR_SLOT_POSITION =
        keccak256(abi.encode(uint256(keccak256('games.laguna.LibResourceLocator')) - 1)) & ~bytes32(uint256(0xff));

    struct ResourceLocatorStorageStruct {
        address unicornNFT; //  ERC-721
        address landNFT; //  ERC-721
        address shadowcornNFT; //  ERC-721
        address gemNFT; //  ERC-721
        address ritualNFT; //  ERC-721
        address RBWToken; //  ERC-20
        address CUToken; //  ERC-20
        address UNIMToken; //  ERC-20
        address WETHToken; //  ERC-20 (third party)
        address darkMarkToken; //  pseudo-ERC-20
        address unicornItems; //  ERC-1155 Terminus
        address shadowcornItems; //  ERC-1155 Terminus
        address accessControlBadge; //  ERC-1155 Terminus
        address gameBank;
        address satelliteBank;
        address playerProfile; //  PermissionProvider
        address shadowForge;
        address darkForest;
        address gameServerSSS; //  ERC-712 Signing Wallet
        address gameServerOracle; //  CU-Watcher
        address testnetDebugRegistry; // PermissionProvider
        address vrfOracle; //  SupraOracles VRF
        address vrfClientWallet; //  SupraOracles VRF payer
    }

    /// @notice Storage slot for ResourceLocator state data
    function resourceLocatorStorage() internal pure returns (ResourceLocatorStorageStruct storage storageSlot) {
        bytes32 position = RESOURCE_LOCATOR_SLOT_POSITION;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageSlot.slot := position
        }
    }

    function unicornNFT() internal view returns (address) {
        return resourceLocatorStorage().unicornNFT;
    }

    function setUnicornNFT(address a) internal {
        resourceLocatorStorage().unicornNFT = a;
    }

    function landNFT() internal view returns (address) {
        return resourceLocatorStorage().landNFT;
    }

    function setLandNFT(address a) internal {
        resourceLocatorStorage().landNFT = a;
    }

    function shadowcornNFT() internal view returns (address) {
        return resourceLocatorStorage().shadowcornNFT;
    }

    function setShadowcornNFT(address a) internal {
        resourceLocatorStorage().shadowcornNFT = a;
    }

    function gemNFT() internal view returns (address) {
        return resourceLocatorStorage().gemNFT;
    }

    function setGemNFT(address a) internal {
        resourceLocatorStorage().gemNFT = a;
    }

    function ritualNFT() internal view returns (address) {
        return resourceLocatorStorage().ritualNFT;
    }

    function setRitualNFT(address a) internal {
        resourceLocatorStorage().ritualNFT = a;
    }

    function rbwToken() internal view returns (address) {
        return resourceLocatorStorage().RBWToken;
    }

    function setRBWToken(address a) internal {
        resourceLocatorStorage().RBWToken = a;
    }

    function cuToken() internal view returns (address) {
        return resourceLocatorStorage().CUToken;
    }

    function setCUToken(address a) internal {
        resourceLocatorStorage().CUToken = a;
    }

    function unimToken() internal view returns (address) {
        return resourceLocatorStorage().UNIMToken;
    }

    function setUNIMToken(address a) internal {
        resourceLocatorStorage().UNIMToken = a;
    }

    function wethToken() internal view returns (address) {
        return resourceLocatorStorage().WETHToken;
    }

    function setWETHToken(address a) internal {
        resourceLocatorStorage().WETHToken = a;
    }

    function darkMarkToken() internal view returns (address) {
        return resourceLocatorStorage().darkMarkToken;
    }

    function setDarkMarkToken(address a) internal {
        resourceLocatorStorage().darkMarkToken = a;
    }

    function unicornItems() internal view returns (address) {
        return resourceLocatorStorage().unicornItems;
    }

    function setUnicornItems(address a) internal {
        resourceLocatorStorage().unicornItems = a;
    }

    function shadowcornItems() internal view returns (address) {
        return resourceLocatorStorage().shadowcornItems;
    }

    function setShadowcornItems(address a) internal {
        resourceLocatorStorage().shadowcornItems = a;
    }

    function accessControlBadge() internal view returns (address) {
        return resourceLocatorStorage().accessControlBadge;
    }

    function setAccessControlBadge(address a) internal {
        resourceLocatorStorage().accessControlBadge = a;
    }

    function gameBank() internal view returns (address) {
        return resourceLocatorStorage().gameBank;
    }

    function setGameBank(address a) internal {
        resourceLocatorStorage().gameBank = a;
    }

    function satelliteBank() internal view returns (address) {
        return resourceLocatorStorage().satelliteBank;
    }

    function setSatelliteBank(address a) internal {
        resourceLocatorStorage().satelliteBank = a;
    }

    function playerProfile() internal view returns (address) {
        return resourceLocatorStorage().playerProfile;
    }

    function setPlayerProfile(address a) internal {
        resourceLocatorStorage().playerProfile = a;
    }

    function shadowForge() internal view returns (address) {
        return resourceLocatorStorage().shadowForge;
    }

    function setShadowForge(address a) internal {
        resourceLocatorStorage().shadowForge = a;
    }

    function darkForest() internal view returns (address) {
        return resourceLocatorStorage().darkForest;
    }

    function setDarkForest(address a) internal {
        resourceLocatorStorage().darkForest = a;
    }

    function gameServerSSS() internal view returns (address) {
        return resourceLocatorStorage().gameServerSSS;
    }

    function setGameServerSSS(address a) internal {
        resourceLocatorStorage().gameServerSSS = a;
    }

    function gameServerOracle() internal view returns (address) {
        return resourceLocatorStorage().gameServerOracle;
    }

    function setGameServerOracle(address a) internal {
        resourceLocatorStorage().gameServerOracle = a;
    }

    function testnetDebugRegistry() internal view returns (address) {
        return resourceLocatorStorage().testnetDebugRegistry;
    }

    function setTestnetDebugRegistry(address a) internal {
        resourceLocatorStorage().testnetDebugRegistry = a;
    }

    function vrfOracle() internal view returns (address) {
        return resourceLocatorStorage().vrfOracle;
    }

    function setVRFOracle(address a) internal {
        resourceLocatorStorage().vrfOracle = a;
    }

    function vrfClientWallet() internal view returns (address) {
        return resourceLocatorStorage().vrfClientWallet;
    }

    function setVRFClientWallet(address a) internal {
        resourceLocatorStorage().vrfClientWallet = a;
    }

    /// @notice Clones the addresses from an existing diamond onto this one
    function importResourcesFromDiamond(address diamond) internal {
        require(
            IERC165(diamond).supportsInterface(type(IResourceLocator).interfaceId),
            'LibResourceLocator: target does not implement IResourceLocator'
        );
        IResourceLocator target = IResourceLocator(diamond);
        if (target.unicornNFTAddress() != address(0)) setUnicornNFT(target.unicornNFTAddress());
        if (target.landNFTAddress() != address(0)) setLandNFT(target.landNFTAddress());
        if (target.shadowcornNFTAddress() != address(0)) setShadowcornNFT(target.shadowcornNFTAddress());
        if (target.gemNFTAddress() != address(0)) setGemNFT(target.gemNFTAddress());
        if (target.ritualNFTAddress() != address(0)) setRitualNFT(target.ritualNFTAddress());
        if (target.rbwTokenAddress() != address(0)) setRBWToken(target.rbwTokenAddress());
        if (target.cuTokenAddress() != address(0)) setCUToken(target.cuTokenAddress());
        if (target.unimTokenAddress() != address(0)) setUNIMToken(target.unimTokenAddress());
        if (target.wethTokenAddress() != address(0)) setWETHToken(target.wethTokenAddress());
        if (target.darkMarkTokenAddress() != address(0)) setDarkMarkToken(target.darkMarkTokenAddress());
        if (target.unicornItemsAddress() != address(0)) setUnicornItems(target.unicornItemsAddress());
        if (target.shadowcornItemsAddress() != address(0)) setShadowcornItems(target.shadowcornItemsAddress());
        if (target.accessControlBadgeAddress() != address(0)) setAccessControlBadge(target.accessControlBadgeAddress());
        if (target.gameBankAddress() != address(0)) setGameBank(target.gameBankAddress());
        if (target.satelliteBankAddress() != address(0)) setSatelliteBank(target.satelliteBankAddress());
        if (target.playerProfileAddress() != address(0)) setPlayerProfile(target.playerProfileAddress());
        if (target.shadowForgeAddress() != address(0)) setShadowForge(target.shadowForgeAddress());
        if (target.darkForestAddress() != address(0)) setDarkForest(target.darkForestAddress());
        if (target.gameServerSSSAddress() != address(0)) setGameServerSSS(target.gameServerSSSAddress());
        if (target.gameServerOracleAddress() != address(0)) setGameServerOracle(target.gameServerOracleAddress());
        if (target.testnetDebugRegistryAddress() != address(0))
            setTestnetDebugRegistry(target.testnetDebugRegistryAddress());
        if (target.vrfOracleAddress() != address(0)) setVRFOracle(target.vrfOracleAddress());
        if (target.vrfClientWalletAddress() != address(0)) setVRFClientWallet(target.vrfClientWalletAddress());
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
pragma solidity ^0.8.19;

/// @title ERC-165 Standard Interface Detection
/// @dev https://eips.ethereum.org/EIPS/eip-165
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}