// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CutDiamond} from '../../lib/@lagunagames/lg-diamond-template/src/diamond/CutDiamond.sol';
import {IERC20} from '../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {AccessBadgeDiamond} from '../../lib/@lagunagames/cu-common/src/implementations/AccessBadgeDiamond.sol';
import {ResourceLocatorGetterDiamond} from '../../lib/@lagunagames/cu-common/src/implementations/ResourceLocatorGetterDiamond.sol';

// import {IERC165} from '../../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract CutTerminusDiamond is CutDiamond, AccessBadgeDiamond, ResourceLocatorGetterDiamond {
    /// @notice This function sets the controller of LibTerminus
    /// @dev Only the contract owner can call this function
    function initializeTerminusDiamond() external {}

    /// @notice Create a new token pool
    /// @dev Only the controller can call this function
    /// @param capacity The maximum number of tokens that can be minted
    /// @param transferable Whether the tokens can be transferred
    /// @param burnable Whether the tokens can be burned
    /// @param poolURI The URI of the pool
    /// @return poolId The ID of the new pool
    function createPool(
        uint256 capacity,
        bool transferable,
        bool burnable,
        string calldata poolURI
    ) external returns (uint256 poolId) {}

    function setController(address newController) external {}

    function poolMintBatch(uint256 id, address[] memory toAddresses, uint256[] memory amounts) external {}

    function terminusController() external view returns (address) {}

    function paymentToken() external view returns (address) {}

    function setPaymentToken(address newPaymentToken) external {}

    function poolBasePrice() external view returns (uint256) {}

    function setPoolBasePrice(uint256 newBasePrice) external {}

    function withdrawPayments(address toAddress, uint256 amount) external {}

    function contractURI() external view returns (string memory) {}

    function setContractURI(string memory _contractURI) external {}

    function setURI(uint256 poolID, string memory poolURI) external {}

    function totalPools() external view returns (uint256) {}

    function setPoolController(uint256 poolID, address newController) external {}

    function terminusPoolController(uint256 poolID) external view returns (address) {}

    function terminusPoolCapacity(uint256 poolID) external view returns (uint256) {}

    function terminusPoolSupply(uint256 poolID) external view returns (uint256) {}

    function poolIsTransferable(uint256 poolID) external view returns (bool) {}

    function poolIsBurnable(uint256 poolID) external view returns (bool) {}

    function setPoolTransferable(uint256 poolID, bool transferable) external {}

    function setPoolBurnable(uint256 poolID, bool burnable) external {}

    function createSimplePool(uint256 _capacity) external returns (uint256) {}

    function createPoolV1(uint256 _capacity, bool _transferable, bool _burnable) external returns (uint256) {}

    function createPoolV2(
        uint256 _capacity,
        bool _transferable,
        bool _burnable,
        string memory poolURI
    ) external returns (uint256) {}

    function mint(address to, uint256 poolID, uint256 amount, bytes memory data) external {}

    function mintBatch(address to, uint256[] memory poolIDs, uint256[] memory amounts, bytes memory data) external {}

    function burn(address from, uint256 poolID, uint256 amount) external {}

    function uri(uint256 poolID) external view returns (string memory) {}

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256) {}

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory) {}

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {}

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool) {}

    function isApprovedForPool(uint256 poolID, address operator) external view returns (bool) {}

    function approveForPool(uint256 poolID, address operator) external {}

    function unapproveForPool(uint256 poolID, address operator) external {}

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external {}

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDiamondCut} from '../interfaces/IDiamondCut.sol';
import {IDiamondLoupe} from '../interfaces/IDiamondLoupe.sol';
import {IERC165} from '../interfaces/IERC165.sol';
import {LibSupportsInterface} from '../libraries/LibSupportsInterface.sol';

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract CutDiamond is IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return (interfaceID == type(IERC165).interfaceId);
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external {}

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @dev This is a convenience implementation of the above
    /// @param _diamondCut Contains the facet addresses and function selectors
    function diamondCut(IDiamondCut.FacetCut[] calldata _diamondCut) external {}

    /// @notice Removes one selector from the Diamond, using DiamondCut
    /// @param selector - The byte4 signature for a method selector to remove
    /// @custom:emits FacetCutAction
    function cutSelector(bytes4 selector) external {}

    /// @notice Removes one selector from the Diamond, using removeFunction()
    /// @param selector - The byte4 signature for a method selector to remove
    function deleteSelector(bytes4 selector) external {}

    /// @notice Removes many selectors from the Diamond, using DiamondCut
    /// @param selectors - Array of byte4 signatures for method selectors to remove
    /// @custom:emits FacetCutAction
    function cutSelectors(bytes4[] memory selectors) external {}

    /// @notice Removes many selectors from the Diamond, using removeFunctions()
    /// @param selectors - Array of byte4 signatures for method selectors to remove
    function deleteSelectors(bytes4[] memory selectors) external {}

    /// @notice Removes any selectors from the Diamond that come from a target
    /// @notice contract address, using DiamondCut.
    /// @param facet - The address of the Facet smart contract to remove
    /// @custom:emits FacetCutAction
    function cutFacet(address facet) external {}

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view returns (IDiamondLoupe.Facet[] memory facets_) {}

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {}

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_) {}

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {}

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address) {}

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external {}

    /// @notice Set the dummy "implementation" contract address
    /// @custom:emits Upgraded
    function setImplementation(address _implementation) external {}

    /// @notice Get the dummy "implementation" contract address
    /// @return The dummy "implementation" contract address
    function implementation() external view returns (address) {}

    /// @notice Set whether an interface is implemented
    /// @dev Only the contract owner can call this function
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @param implemented `true` if the contract implements `interfaceID`
    function setSupportsInterface(bytes4 interfaceID, bool implemented) external {}

    /// @notice Set a list of interfaces as implemented or not
    /// @dev Only the contract owner can call this function
    /// @param interfaceIDs The interface identifiers, as specified in ERC-165
    /// @param allImplemented `true` if the contract implements all interfaces
    function setSupportsInterfaces(bytes4[] calldata interfaceIDs, bool allImplemented) external {}

    /// @notice Returns a list of interfaces that have (ever) been supported
    /// @return The list of interfaces
    function interfaces() external view returns (LibSupportsInterface.KnownInterface[] memory) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract AccessBadgeDiamond {
    /// @notice Returns the 1155 pool ID for a badge
    /// @param name The name of the badge (registered on this contract)
    /// @return poolId The pool ID for the badge, on the AccessControl contract
    function getPoolByName(string memory name) external view returns (uint256 poolId) {}

    /// @notice Assign a name to an 1155 pool on the AccessControl contract
    /// @dev Contract owner only
    /// @param name The name of the badge
    /// @param poolId The pool ID for the badge, on the AccessControl contract
    function setPoolName(uint256 poolId, string memory name) external {}

    /// @notice Throw an error if the sender does not have the required badge
    /// @param badge The name of the badge
    /// @custom:throws AccessBadgeRequired
    function requireBadge(string memory badge) external view {}

    /// @notice Throw an error if the sender does not have the required badge
    /// @param poolId The pool ID of the badge
    /// @custom:throws AccessTokenRequired
    function requireBadgeById(uint256 poolId) external view {}

    /// @notice Check if an address has a badge
    /// @param a The address to check
    /// @param badge The name of the badge
    /// @return true if the address has the badge
    function hasBadge(address a, string memory badge) external view returns (bool) {}

    /// @notice Check if an address has a badge
    /// @param a The address to check
    /// @param poolId The pool ID for the badge
    /// @return true if the address has the badge
    function hasBadgeById(address a, uint256 poolId) external view returns (bool) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract ResourceLocatorGetterDiamond {
    /// @notice Returns the Unicorn contract address
    function unicornNFTAddress() public view returns (address) {}

    /// @notice Returns the Land contract address
    function landNFTAddress() public view returns (address) {}

    /// @notice Returns the Shadowcorn contract address
    function shadowcornNFTAddress() public view returns (address) {}

    /// @notice Returns the Gem contract address
    function gemNFTAddress() public view returns (address) {}

    /// @notice Returns the Ritual contract address
    function ritualNFTAddress() public view returns (address) {}

    /// @notice Returns the RBW Token contract address
    function rbwTokenAddress() public view returns (address) {}

    /// @notice Returns the CU Token contract address
    function cuTokenAddress() public view returns (address) {}

    /// @notice Returns the UNIM Token contract address
    function unimTokenAddress() public view returns (address) {}

    /// @notice Returns the WETH Token contract address
    function wethTokenAddress() public view returns (address) {}

    /// @notice Returns the Dark Mark Token contract address
    function darkMarkTokenAddress() public view returns (address) {}

    /// @notice Returns the Unicorn Items contract address
    function unicornItemsAddress() public view returns (address) {}

    /// @notice Returns the Shadowcorn Items contract address
    function shadowcornItemsAddress() public view returns (address) {}

    /// @notice Returns the Access Control Badge contract address
    function accessControlBadgeAddress() public view returns (address) {}

    /// @notice Returns the Game Bank contract address
    function gameBankAddress() public view returns (address) {}

    /// @notice Returns the Satellite Bank contract address
    function satelliteBankAddress() public view returns (address) {}

    /// @notice Returns the Player Profile contract address
    function playerProfileAddress() public view returns (address) {}

    /// @notice Returns the Shadow Forge contract address
    function shadowForgeAddress() public view returns (address) {}

    /// @notice Returns the Dark Forest contract address
    function darkForestAddress() public view returns (address) {}

    /// @notice Returns the Game Server SSS contract address
    function gameServerSSSAddress() public view returns (address) {}

    /// @notice Returns the Game Server Oracle contract address
    function gameServerOracleAddress() public view returns (address) {}

    /// @notice Returns the Testnet Debug Registry address
    /// @dev Available on testnet deployments only
    function testnetDebugRegistryAddress() external view returns (address) {}
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibContractOwner} from '../libraries/LibContractOwner.sol';

/// @title Library for the common LG implementation of ERC-165
/// @author [email protected]
/// @custom:storage-location erc7201:games.laguna.LibSupportsInterface
library LibSupportsInterface {
    bytes32 public constant SUPPORTS_INTERFACE_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256('games.laguna.LibSupportsInterface')) - 1)) & ~bytes32(uint256(0xff));

    struct KnownInterface {
        bytes4 selector;
        bool supported;
    }

    struct SupportsInterfaceStorage {
        mapping(bytes4 selector => bool supported) supportedInterfaces;
        bytes4[] interfaces;
    }

    /// @notice Storage slot for SupportsInterface state data
    function supportsInterfaceStorage() internal pure returns (SupportsInterfaceStorage storage storageSlot) {
        bytes32 position = SUPPORTS_INTERFACE_STORAGE_POSITION;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageSlot.slot := position
        }
    }

    /// @notice Checks if a contract implements an interface
    /// @param _interfaceId Interface ID to check
    /// @return true if the contract implements the interface
    function supportsInterface(bytes4 _interfaceId) internal view returns (bool) {
        return supportsInterfaceStorage().supportedInterfaces[_interfaceId];
    }

    /// @notice Sets whether a contract implements an interface
    /// @param _interfaceId Interface ID to set
    /// @param _implemented true if the contract implements the interface
    function setSupportsInterface(bytes4 _interfaceId, bool _implemented) internal {
        SupportsInterfaceStorage storage s = supportsInterfaceStorage();

        if (_implemented && !s.supportedInterfaces[_interfaceId]) {
            s.interfaces.push(_interfaceId);
        }

        s.supportedInterfaces[_interfaceId] = _implemented;
    }

    /// @notice Returns the list of interfaces this contract has supported, and whether they are supported currently.
    /// @return The list of interfaces
    function getKnownInterfaces() internal view returns (KnownInterface[] memory) {
        SupportsInterfaceStorage storage s = supportsInterfaceStorage();
        KnownInterface[] memory interfaces = new KnownInterface[](s.interfaces.length);
        for (uint i = 0; i < s.interfaces.length; ++i) {
            interfaces[i] = KnownInterface({
                selector: s.interfaces[i],
                supported: s.supportedInterfaces[s.interfaces[i]]
            });
        }
        return interfaces;
    }

    /// @notice Calculate the interface ID for a list of function selectors
    /// @dev Per ERC-165: "We define the interface identifier as the XOR of all function selectors in the interface"
    /// @param functionSelectors The list of function selectors in the interface
    /// @return interfaceId The ERC-165 interface ID
    function calculateInterfaceId(bytes4[] memory functionSelectors) internal pure returns (bytes4 interfaceId) {
        for (uint256 i = 0; i < functionSelectors.length; ++i) {
            interfaceId ^= functionSelectors[i];
        }
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