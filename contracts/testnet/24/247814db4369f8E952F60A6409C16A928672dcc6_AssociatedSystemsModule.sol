//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for address related errors.
 */
library AddressError {
    /**
     * @dev Thrown when a zero address was passed as a function parameter (0x0000000000000000000000000000000000000000).
     */
    error ZeroAddress();

    /**
     * @dev Thrown when an address representing a contract is expected, but no code is found at the address.
     * @param contr The address that was expected to be a contract.
     */
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for initialization related errors.
 */
library InitError {
    /**
     * @dev Thrown when attempting to initialize a contract that is already initialized.
     */
    error AlreadyInitialized();

    /**
     * @dev Thrown when attempting to interact with a contract that has not been initialized yet.
     */
    error NotInitialized();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC20 token implementation.
 */
interface IERC20 {
    /**
     * @notice Emitted when tokens have been transferred.
     * @param from The address that originally owned the tokens.
     * @param to The address that received the tokens.
     * @param amount The number of tokens that were transferred.
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice Emitted when a user has provided allowance to another user for transferring tokens on its behalf.
     * @param owner The address that is providing the allowance.
     * @param spender The address that received the allowance.
     * @param amount The number of tokens that were added to `spender`'s allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient allowance to transfer tokens from another contract.
     * @param required The necessary allowance.
     * @param existing The current allowance.
     */
    error InsufficientAllowance(uint required, uint existing);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient tokens.
     * @param required The necessary balance.
     * @param existing The current balance.
     */
    error InsufficientBalance(uint required, uint existing);

    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Network Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the number of decimals used by the token. The default is 18.
     * @return The number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the total number of tokens in circulation (minted - burnt).
     * @return The total number of tokens.
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Returns the balance of a user.
     * @param owner The address whose balance is being retrieved.
     * @return The number of tokens owned by the user.
     */
    function balanceOf(address owner) external view returns (uint);

    /**
     * @notice Returns how many tokens a user has allowed another user to transfer on its behalf.
     * @param owner The user who has given the allowance.
     * @param spender The user who was given the allowance.
     * @return The amount of tokens `spender` can transfer on `owner`'s behalf.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @notice Transfer tokens from one address to another.
     * @param to The address that will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean which is true if the operation succeeded.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @notice Allows users to provide allowance to other users so that they can transfer tokens on their behalf.
     * @param spender The address that is receiving the allowance.
     * @param amount The amount of tokens that are being added to the allowance.
     * @return A boolean which is true if the operation succeeded.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice Allows a user who has been given allowance to transfer tokens on another user's behalf.
     * @param from The address that owns the tokens that are being transferred.
     * @param to The address that will receive the tokens.
     * @param amount The number of tokens to transfer.
     * @return A boolean which is true if the operation succeeded.
     */
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC721 non-fungible token (NFT) contract.
 */
interface IERC721 {
    /**
     * @notice Thrown when an address attempts to provide allowance to itself.
     * @param addr The address attempting to provide allowance.
     */
    error CannotSelfApprove(address addr);

    /**
     * @notice Thrown when attempting to transfer a token to an address that does not satisfy IERC721Receiver requirements.
     * @param addr The address that cannot receive the tokens.
     */
    error InvalidTransferRecipient(address addr);

    /**
     * @notice Thrown when attempting to specify an owner which is not valid (ex. the 0x00000... address)
     */
    error InvalidOwner(address addr);

    /**
     * @notice Thrown when attempting to operate on a token id that does not exist.
     * @param id The token id that does not exist.
     */
    error TokenDoesNotExist(uint256 id);

    /**
     * @notice Thrown when attempting to mint a token that already exists.
     * @param id The token id that already exists.
     */
    error TokenAlreadyMinted(uint256 id);

    /**
     * @notice Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @notice Returns the number of tokens in ``owner``'s account.
     *
     * Requirements:
     *
     * - `holder` must be a valid address
     */
    function balanceOf(address holder) external view returns (uint256 balance);

    /**
     * @notice Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @notice Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @notice Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./IERC721.sol";

/**
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @notice Thrown calling *ByIndex function with an index greater than the number of tokens existing
     * @param requestedIndex The index requested by the caller
     * @param length The length of the list that is being iterated, making the max index queryable length - 1
     */
    error IndexOverrun(uint requestedIndex, uint length);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     *
     * Requirements:
     * - `owner` must be a valid address
     * - `index` must be less than the balance of the tokens for the owner
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     *
     * Requirements:
     * - `index` must be less than the total supply of the tokens
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Contract to be used as the implementation of a Universal Upgradeable Proxy Standard (UUPS) proxy.
 *
 * Important: A UUPS proxy requires its upgradeability functions to be in the implementation as opposed to the proxy. This means that if the proxy is upgraded to an implementation that does not support this interface, it will no longer be upgradeable.
 */
interface IUUPSImplementation {
    /**
     * @notice Thrown when an incoming implementation will not be able to receive future upgrades.
     */
    error ImplementationIsSterile(address implementation);

    /**
     * @notice Thrown intentionally when testing future upgradeability of an implementation.
     */
    error UpgradeSimulationFailed();

    /**
     * @notice Emitted when the implementation of the proxy has been upgraded.
     * @param self The address of the proxy whose implementation was upgraded.
     * @param implementation The address of the proxy's new implementation.
     */
    event Upgraded(address indexed self, address implementation);

    /**
     * @notice Allows the proxy to be upgraded to a new implementation.
     * @param newImplementation The address of the proxy's new implementation.
     * @dev Will revert if `newImplementation` is not upgradeable.
     * @dev The implementation of this function needs to be protected by some sort of access control such as `onlyOwner`.
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @notice Function used to determine if a new implementation will be able to receive future upgrades in `upgradeTo`.
     * @param newImplementation The address of the new implementation being tested for future upgradeability.
     * @dev This function will always revert, but will revert with different error messages. The function `upgradeTo` uses this error to determine the future upgradeability of the implementation in question.
     */
    function simulateUpgradeTo(address newImplementation) external;

    /**
     * @notice Retrieves the current implementation of the proxy.
     * @return The address of the current implementation.
     */
    function getImplementation() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    bytes32 private constant _SLOT_OWNABLE_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Ownable"));

    struct Data {
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_OWNABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

abstract contract AbstractProxy {
    fallback() external payable {
        _forward();
    }

    receive() external payable {
        _forward();
    }

    function _forward() internal {
        address implementation = _getImplementation();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _getImplementation() internal view virtual returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

contract ProxyStorage {
    bytes32 private constant _SLOT_PROXY_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Proxy"));

    struct ProxyStore {
        address implementation;
        bool simulatingUpgrade;
    }

    function _proxyStore() internal pure returns (ProxyStore storage store) {
        bytes32 s = _SLOT_PROXY_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./AbstractProxy.sol";
import "./ProxyStorage.sol";
import "../errors/AddressError.sol";
import "../utils/AddressUtil.sol";

contract UUPSProxy is AbstractProxy, ProxyStorage {
    constructor(address firstImplementation) {
        if (firstImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(firstImplementation)) {
            revert AddressError.NotAContract(firstImplementation);
        }

        _proxyStore().implementation = firstImplementation;
    }

    function _getImplementation() internal view virtual override returns (address) {
        return _proxyStore().implementation;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {UUPSProxy} from "./UUPSProxy.sol";
import {OwnableStorage} from "../ownership/OwnableStorage.sol";

contract UUPSProxyWithOwner is UUPSProxy {
    // solhint-disable-next-line no-empty-blocks
    constructor(address firstImplementation, address initialOwner) UUPSProxy(firstImplementation) {
        OwnableStorage.load().owner = initialOwner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library AddressUtil {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for connecting a system with other associated systems.

 * Associated systems become available to all system modules for communication and interaction, but as opposed to inter-modular communications, interactions with associated systems will require the use of `CALL`.
 *
 * Associated systems can be managed or unmanaged.
 * - Managed systems are connected via a proxy, which means that their implementation can be updated, and the system controls the execution context of the associated system. Example, an snxUSD token connected to the system, and controlled by the system.
 * - Unmanaged systems are just addresses tracked by the system, for which it has no control whatsoever. Example, Uniswap v3, Curve, etc.
 *
 * Furthermore, associated systems are typed in the AssociatedSystem utility library (See AssociatedSystem.sol):
 * - KIND_ERC20: A managed associated system specifically wrapping an ERC20 implementation.
 * - KIND_ERC721: A managed associated system specifically wrapping an ERC721 implementation.
 * - KIND_UNMANAGED: Any unmanaged associated system.
 */
interface IAssociatedSystemsModule {
    /**
     * @notice Emitted when an associated system is set.
     * @param kind The type of associated system (managed ERC20, managed ERC721, unmanaged, etc - See the AssociatedSystem util).
     * @param id The bytes32 identifier of the associated system.
     * @param proxy The main external contract address of the associated system.
     * @param impl The address of the implementation of the associated system (if not behind a proxy, will equal `proxy`).
     */
    event AssociatedSystemSet(
        bytes32 indexed kind,
        bytes32 indexed id,
        address proxy,
        address impl
    );

    /**
     * @notice Emitted when the function you are calling requires an associated system, but it
     * has not been registered
     */
    error MissingAssociatedSystem(bytes32 id);

    /**
     * @notice Creates or initializes a managed associated ERC20 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system, it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param decimals The token decimals that will be used to initialize the proxy.
     * @param impl The ERC20 implementation of the proxy.
     */
    function initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) external;

    /**
     * @notice Creates or initializes a managed associated ERC721 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system, it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param uri The token uri that will be used to initialize the proxy.
     * @param impl The ERC721 implementation of the proxy.
     */
    function initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) external;

    /**
     * @notice Registers an unmanaged external contract in the system.
     * @param id The bytes32 identifier to use to reference the associated system.
     * @param endpoint The address of the associated system.
     *
     * Note: The system will not be able to control or upgrade the associated system, only communicate with it.
     */
    function registerUnmanagedSystem(bytes32 id, address endpoint) external;

    /**
     * @notice Retrieves an associated system.
     * @param id The bytes32 identifier used to reference the associated system.
     * @return addr The external contract address of the associated system.
     * @return kind The type of associated system (managed ERC20, managed ERC721, unmanaged, etc - See the AssociatedSystem util).
     */
    function getAssociatedSystem(bytes32 id) external view returns (address addr, bytes32 kind);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC721Enumerable.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 */
interface INftModule is IERC721Enumerable {
    /**
     * @notice Returns whether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and uri.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param tokenId The ID of the newly minted token
     */
    function mint(address to, uint tokenId) external;

    /**
     * @notice Allows the owner to mint tokens. Verifies that the receiver can receive the token
     * @param to The address to receive the newly minted token.
     * @param tokenId The ID of the newly minted token
     * @param data any data which should be sent to the receiver
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param tokenId The token to burn
     */
    function burn(uint tokenId) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param tokenId The token which should be allowed to spender
     * @param spender The address that is given allowance.
     */
    function setAllowance(uint tokenId, address spender) external;

    /**
     * @notice Allows the owner to update the base token URI.
     * @param uri The new base token uri
     */
    function setBaseTokenURI(string memory uri) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for giving a system owner based access control.
 */
// solhint-disable-next-line no-empty-blocks
interface IOwnerModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

/**
 * @title Module wrapping an ERC20 token implementation.
 */
interface ITokenModule is IERC20 {
    /**
     * @notice Returns wether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and decimals.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint amount) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param from The address whose tokens will be burnt.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint amount) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param from The address that is providing allowance.
     * @param spender The address that is given allowance.
     * @param amount The amount of allowance being given.
     */
    function setAllowance(address from, address spender, uint amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/errors/InitError.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/proxy/UUPSProxyWithOwner.sol";
import "../interfaces/IAssociatedSystemsModule.sol";

import "@synthetixio/core-contracts/contracts/interfaces/IUUPSImplementation.sol";
import "../interfaces/IOwnerModule.sol";
import "../interfaces/ITokenModule.sol";
import "../interfaces/INftModule.sol";

import "../storage/AssociatedSystem.sol";

/**
 * @title Module for connecting a system with other associated systems.
 * @dev See IAssociatedSystemsModule.
 */
contract AssociatedSystemsModule is IAssociatedSystemsModule {
    using AssociatedSystem for AssociatedSystem.Data;

    modifier onlyIfAssociated(bytes32 id) {
        if (address(AssociatedSystem.load(id).proxy) == address(0)) {
            revert MissingAssociatedSystem(id);
        }

        _;
    }

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) external override {
        OwnableStorage.onlyOwner();
        _initOrUpgradeToken(id, name, symbol, decimals, impl);
    }

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) external override {
        OwnableStorage.onlyOwner();
        _initOrUpgradeNft(id, name, symbol, uri, impl);
    }

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function registerUnmanagedSystem(bytes32 id, address endpoint) external override {
        OwnableStorage.onlyOwner();
        // empty string require kind will make sure the system is either unregistered or already unmanaged
        AssociatedSystem.load(id).expectKind("");

        _setAssociatedSystem(id, AssociatedSystem.KIND_UNMANAGED, endpoint, endpoint);
    }

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function getAssociatedSystem(
        bytes32 id
    ) external view override returns (address addr, bytes32 kind) {
        addr = AssociatedSystem.load(id).proxy;
        kind = AssociatedSystem.load(id).kind;
    }

    function _setAssociatedSystem(bytes32 id, bytes32 kind, address proxy, address impl) internal {
        AssociatedSystem.load(id).set(proxy, impl, kind);
        emit AssociatedSystemSet(kind, id, proxy, impl);
    }

    function _upgradeToken(
        bytes32 id,
        address impl
    ) internal returns (AssociatedSystem.Data storage store) {
        store = AssociatedSystem.load(id);
        store.expectKind(AssociatedSystem.KIND_ERC20);

        store.impl = impl;

        address proxy = store.proxy;

        // tell the associated proxy to upgrade to the new implementation
        IUUPSImplementation(proxy).upgradeTo(impl);

        emit AssociatedSystemSet(AssociatedSystem.KIND_ERC20, id, proxy, impl);
    }

    function _upgradeNft(
        bytes32 id,
        address impl
    ) internal returns (AssociatedSystem.Data storage store) {
        store = AssociatedSystem.load(id);
        store.expectKind(AssociatedSystem.KIND_ERC721);

        store.impl = impl;

        address proxy = store.proxy;

        // tell the associated proxy to upgrade to the new implementation
        IUUPSImplementation(proxy).upgradeTo(impl);

        emit AssociatedSystemSet(AssociatedSystem.KIND_ERC721, id, proxy, impl);
    }

    function _initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) internal {
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);

        if (store.proxy != address(0)) {
            _upgradeToken(id, impl);
        } else {
            // create a new proxy and own it
            address proxy = address(new UUPSProxyWithOwner(impl, address(this)));

            ITokenModule(proxy).initialize(name, symbol, decimals);

            _setAssociatedSystem(id, AssociatedSystem.KIND_ERC20, proxy, impl);
        }
    }

    function _initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) internal {
        OwnableStorage.onlyOwner();
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);

        if (store.proxy != address(0)) {
            _upgradeNft(id, impl);
        } else {
            // create a new proxy and own it
            address proxy = address(new UUPSProxyWithOwner(impl, address(this)));

            INftModule(proxy).initialize(name, symbol, uri);

            _setAssociatedSystem(id, AssociatedSystem.KIND_ERC721, proxy, impl);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/ITokenModule.sol";
import "../interfaces/INftModule.sol";

library AssociatedSystem {
    struct Data {
        address proxy;
        address impl;
        bytes32 kind;
    }

    error MismatchAssociatedSystemKind(bytes32 expected, bytes32 actual);

    bytes32 public constant KIND_ERC20 = "erc20";
    bytes32 public constant KIND_ERC721 = "erc721";
    bytes32 public constant KIND_UNMANAGED = "unmanaged";

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.core-modules.AssociatedSystem", id));
        assembly {
            store.slot := s
        }
    }

    function getAddress(Data storage self) internal view returns (address) {
        return self.proxy;
    }

    function asToken(Data storage self) internal view returns (ITokenModule) {
        expectKind(self, KIND_ERC20);
        return ITokenModule(self.proxy);
    }

    function asNft(Data storage self) internal view returns (INftModule) {
        expectKind(self, KIND_ERC721);
        return INftModule(self.proxy);
    }

    function set(Data storage self, address proxy, address impl, bytes32 kind) internal {
        self.proxy = proxy;
        self.impl = impl;
        self.kind = kind;
    }

    function expectKind(Data storage self, bytes32 kind) internal view {
        bytes32 actualKind = self.kind;

        if (actualKind != kind && actualKind != KIND_UNMANAGED) {
            revert MismatchAssociatedSystemKind(kind, actualKind);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {AssociatedSystemsModule as BaseAssociatedSystemsModule} from "@synthetixio/core-modules/contracts/modules/AssociatedSystemsModule.sol";

/**
 * @title Module for connecting to other systems.
 * See core-modules/../AssociatedSystemsModule
 */
// solhint-disable-next-line no-empty-blocks
contract AssociatedSystemsModule is BaseAssociatedSystemsModule {

}