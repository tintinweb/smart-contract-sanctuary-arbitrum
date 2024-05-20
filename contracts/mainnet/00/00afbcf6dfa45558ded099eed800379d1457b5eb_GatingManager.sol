// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {IERC1155} from "forge-std/interfaces/IERC1155.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {IKreditsDiamond} from "kr/core/IKreditsDiamond.sol";
import {IErrorsEvents as Errors} from "kr/core/IErrorsEvents.sol";

// solhint-disable code-complexity

contract GatingManager is Ownable {
    IERC1155 public kreskian;
    IERC1155 public questForKresk;
    uint8 public phase;
    uint256[] internal _qfkNFTs;

    IKreditsDiamond internal constant KREDITS =
        IKreditsDiamond(0x8E84a3B8e0b074c149b8277c753Dc6396bB95F48);
    mapping(address => bool) internal whitelisted;

    constructor(
        address _admin,
        address _kreskian,
        address _questForKresk,
        uint8 _phase
    ) Ownable(_admin) {
        kreskian = IERC1155(_kreskian);
        questForKresk = IERC1155(_questForKresk);
        phase = _phase;
    }

    function transferOwnership(
        address newOwner
    ) public override(Ownable) onlyOwner {
        Ownable.transferOwnership(newOwner);
    }

    function qfkNFTs() external view returns (uint256[] memory) {
        return _qfkNFTs;
    }

    function isWhiteListed(address _account) external view returns (bool) {
        return whitelisted[_account];
    }

    function whitelist(address _account, bool _whitelisted) external onlyOwner {
        whitelisted[_account] = _whitelisted;
    }

    function setPhase(uint8 newPhase) external onlyOwner {
        phase = newPhase;
    }

    function isEligible(address _account) external view returns (bool) {
        uint256 currentPhase = phase;
        if (currentPhase == 0) return true;

        bool hasKreskian = kreskian.balanceOf(_account, 0) != 0;

        if (currentPhase == 3) {
            return
                hasKreskian ||
                whitelisted[_account] ||
                KREDITS.getAccountInfo(_account).linked ||
                KREDITS.balanceOf(_account) > 0;
        }

        return whitelisted[_account];
    }

    function check(address _account) external view {
        uint256 currentPhase = phase;
        if (currentPhase == 0) return;

        bool hasKreskian = kreskian.balanceOf(_account, 0) != 0;
        bool validPhaseThree = hasKreskian ||
            whitelisted[_account] ||
            KREDITS.getAccountInfo(_account).linked ||
            KREDITS.balanceOf(_account) > 0;

        if (currentPhase == 3) {
            if (!validPhaseThree && !whitelisted[_account])
                revert Errors.MISSING_PHASE_3_NFT();
            return;
        }

        if (!whitelisted[_account]) revert Errors.MISSING_PHASE_3_NFT();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./IERC165.sol";

/// @title ERC-1155 Multi Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 is IERC165 {
    /// @dev
    /// - Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
    /// - The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
    /// - The `_from` argument MUST be the address of the holder whose balance is decreased.
    /// - The `_to` argument MUST be the address of the recipient whose balance is increased.
    /// - The `_id` argument MUST be the token type being transferred.
    /// - The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// - When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
    /// - When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );

    /// @dev
    /// - Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
    /// - The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
    /// - The `_from` argument MUST be the address of the holder whose balance is decreased.
    /// - The `_to` argument MUST be the address of the recipient whose balance is increased.
    /// - The `_ids` argument MUST be the list of tokens being transferred.
    /// - The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
    /// - When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
    /// - When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );

    /// @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @dev MUST emit when the URI is updated for a token ID. URIs are defined in RFC 3986.
    /// The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    event URI(string _value, uint256 indexed _id);

    /// @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// - MUST revert if `_to` is the zero address.
    /// - MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    /// - MUST revert on any other error.
    /// - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// - After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from Source address
    /// @param _to Target address
    /// @param _id ID of the token type
    /// @param _value Transfer amount
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /// @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// - MUST revert if `_to` is the zero address.
    /// - MUST revert if length of `_ids` is not the same as length of `_values`.
    /// - MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    /// - MUST revert on any other error.
    /// - MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// - Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    /// - After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from Source address
    /// @param _to Target address
    /// @param _ids IDs of each token type (order and length must match _values array)
    /// @param _values Transfer amounts per token type (order and length must match _ids array)
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /// @notice Get the balance of an account's tokens.
    /// @param _owner The address of the token holder
    /// @param _id ID of the token
    /// @return The _owner's balance of the token type requested
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /// @notice Get the balance of multiple account/token pairs
    /// @param _owners The addresses of the token holders
    /// @param _ids ID of the tokens
    /// @return The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param _owner The owner of the tokens
    /// @param _operator Address of authorized operator
    /// @return True if the operator is approved, false if not
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// solhint-disable
pragma solidity ^0.8.0;

interface IERC165_0 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC165Internal {}

interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(
        uint256 index
    ) external view returns (uint256 tokenId);
}

// src/core/interfaces/IActionFacet.sol

interface IActionFacet {
    function link(uint256 tokenId) external;

    function unlink() external;

    function lock1155(
        address[] memory nfts,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    function unlock1155(
        address[] calldata nfts,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;
}

// src/core/interfaces/IClaimerFacet.sol

interface IClaimerFacet {
    function claimAndMint(
        uint256 airdropId,
        bytes32[] calldata proof,
        uint256 amount
    ) external;

    function claim(
        uint256 airdropId,
        bytes32[] calldata proof,
        uint256 amount
    ) external;

    function burnKreditsAndMint(
        uint256 airdropId,
        bytes32[] calldata proof,
        uint256 amount
    ) external;

    function burnAndMint() external;
}

// src/core/libs/Errors.sol

interface Errors {
    error NotOwner(address sender, address owner);
    error OnlyUnlinked();
    error OnlyLinked();
    error InvalidClaimId(uint256 id);
    error AlreadyClaimed(address who, uint256 id);

    error NotStarted(uint256 id, uint256 startTime);
    error ClaimWindowEnded(uint256 id, uint256 endTime);

    error NotLinked(address who);

    error NotMintingClaim(uint256 id);
    error NotBurningClaim(uint256 id);
}

interface IDiamondCutFacet {
    struct Initializer {
        address initializer;
        bytes data;
    }

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

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

interface IExtendedDiamondCutFacet is IDiamondCutFacet {
    function executeInitializer(Initializer calldata _init) external;
}

interface IDiamondLoupeFacet {
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
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_);
}

interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165_0 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

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
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

interface IERC165_1 is IERC165Internal {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @title ERC721 base interface
 */
interface IERC721BaseInternal is IERC721Internal {
    error ERC721Base__NotOwnerOrApproved();
    error ERC721Base__SelfApproval();
    error ERC721Base__BalanceQueryZeroAddress();
    error ERC721Base__ERC721ReceiverNotImplemented();
    error ERC721Base__InvalidOwner();
    error ERC721Base__MintToZeroAddress();
    error ERC721Base__NonExistentToken();
    error ERC721Base__NotTokenOwner();
    error ERC721Base__TokenAlreadyMinted();
    error ERC721Base__TransferToZeroAddress();
}

interface IOwnershipFacet is IERC173 {}

interface IERC721MetadataInternal is IERC721BaseInternal {
    error ERC721Metadata__NonExistentToken();
}

/**
 * @title Claim Event
 * @param merkleRoot Merkle root of the claim
 * @param startDate Start date of the claim
 * @param claimWindow Claim window of the claim
 * @param minting Is the claim a minting event
 * @param burning Is the claim a burning event
 * @dev Claim event struct
 */
struct ClaimEvent {
    bytes32 merkleRoot;
    uint128 startDate;
    uint128 claimWindow;
    bool minting;
    bool burning;
}

/**
 * @title Storage layout for the registry state
 * @author Kresko
 */
struct RegistryState {
    // Airdrops
    uint256 airdropsIds;
    // Kredits to be burnt for Minting 721
    uint256 kreditsForMint;
    // Mapping kredits airdrop to merkle roots
    mapping(uint256 => ClaimEvent) claimEvents;
    // Claimed airdrops
    mapping(address => mapping(uint256 => bool)) claimed;
    // ERC721 Minted
    uint256 currentTokenIds;
    // Valid Kresko 1155 NFT
    mapping(address => bool) isValid;
    // Mapping from token ID to kredits
    mapping(uint256 => uint256) kredits;
    // Mapping from user to token ID
    mapping(address => uint256) linkedId;
    // NFT token Id to 1155 token to 1155 id to amounts locked
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) locked;
}

// Storage position
bytes32 constant REGISTRY_STORAGE_POSITION = keccak256(
    "kresko.registry.storage"
);

/* -------------------------------------------------------------------------- */
/*                                   Getter                                   */
/* -------------------------------------------------------------------------- */

function rs() pure returns (RegistryState storage state) {
    bytes32 position = REGISTRY_STORAGE_POSITION;
    assembly {
        state.slot := position
    }
}

// lib/solidstate/contracts/interfaces/IERC721.sol

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165_1 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool status);
}

// lib/solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721MetadataInternal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// src/core/interfaces/IClaimerConfigFacet.sol

interface IClaimerConfigFacet {
    function createClaim(ClaimEvent memory config) external returns (uint256);

    function updateClaim(uint256 airdropId, ClaimEvent memory config) external;

    function setKreditsForMint(uint256 amount) external;

    function mintProfile(address to, bool link) external returns (uint256);
}

// src/core/interfaces/IViewFacet.sol

interface IViewFacet {
    struct AccountInfo {
        bool linked;
        uint256 linkedId;
        uint256 points;
        uint256 walletProfileId;
        bool claimedCurrent;
        uint256[] lockedQFKs;
        bool hasKreskian;
        uint256 currentClaimId;
    }

    function getAccountInfo(
        address _account
    ) external view returns (AccountInfo memory account);

    function getBurnNftAddress() external view returns (address);

    function getClaimed(
        address user,
        uint256 airdropId
    ) external view returns (bool);

    function getIsValid(address nft) external view returns (bool);

    function getKredits(uint256 tokenId) external view returns (uint256);

    function getLinkedId(address user) external view returns (uint256);

    function getLocked(
        uint256 tokenId721,
        address nft,
        uint256 tokenId1155
    ) external view returns (uint256);

    function getConfigIds() external view returns (uint256);

    function getTokenIds() external view returns (uint256);

    function getConfig(
        uint256 airdropId
    ) external view returns (ClaimEvent memory);

    function getKreditsForMint() external view returns (uint256);
}

// src/core/libs/Events.sol

interface Events {
    event Linked(address indexed user, uint256 tokenId);
    event Unlinked(address indexed user, uint256 tokenId);
    event KreditsAdded(uint256 tokenId, uint256 amount);
    event KreditsRemoved(uint256 tokenId, uint256 amount);
    event Locked(
        address indexed user,
        uint256 tokenId721,
        address indexed token,
        uint256 amount,
        uint256 indexed tokenId
    );
    event Unlocked(
        address indexed user,
        uint256 tokenId721,
        address indexed token,
        uint256 amount,
        uint256 indexed tokenId
    );
    event Claimed(
        address indexed user,
        uint256 tokenId721,
        uint256 airdropId,
        uint256 amount
    );
    event ClaimCreated(uint256 airdropId, ClaimEvent config);
    event ClaimUpdated(uint256 airdropId, ClaimEvent config);
    event KreditsForMintSet(uint256 amount);
}

interface IERC721Base is IERC721BaseInternal, IERC721 {}

interface IERC721Facet is IERC721Base, IERC721Enumerable, IERC721Metadata {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}

interface IKreditsDiamond is
    IDiamondCutFacet,
    IDiamondLoupeFacet,
    IOwnershipFacet,
    IClaimerFacet,
    IClaimerConfigFacet,
    IActionFacet,
    IViewFacet,
    IERC721Facet,
    Errors,
    Events
{}

// SPDX-License-Identifier: MIT
// solhint-disable one-contract-per-file
pragma solidity ^0.8.0;

interface IErrorFieldProvider {
    function symbol() external view returns (string memory);
}

library Errors {
    function id(address _addr) internal view returns (IErrorsEvents.ID memory) {
        if (_addr.code.length > 0)
            return IErrorsEvents.ID(IErrorFieldProvider(_addr).symbol(), _addr);
        return IErrorsEvents.ID("", _addr); // not a token
    }

    function symbol(
        address _addr
    ) internal view returns (string memory symbol_) {
        if (_addr.code.length > 0) return IErrorFieldProvider(_addr).symbol();
    }
}

interface IErrorsEvents is IErrorFieldProvider {
    struct ID {
        string symbol;
        address addr;
    }

    event SCDPDeposit(
        address indexed depositor,
        address indexed collateralAsset,
        uint256 amount,
        uint256 feeIndex,
        uint256 timestamp
    );
    event SCDPWithdraw(
        address indexed account,
        address indexed receiver,
        address indexed collateralAsset,
        address withdrawer,
        uint256 amount,
        uint256 feeIndex,
        uint256 timestamp
    );
    event SCDPFeeClaim(
        address indexed claimer,
        address indexed receiver,
        address indexed collateralAsset,
        uint256 feeAmount,
        uint256 newIndex,
        uint256 prevIndex,
        uint256 timestamp
    );
    event SCDPRepay(
        address indexed repayer,
        address indexed repayKreskoAsset,
        uint256 repayAmount,
        address indexed receiveKreskoAsset,
        uint256 receiveAmount,
        uint256 timestamp
    );

    event SCDPLiquidationOccured(
        address indexed liquidator,
        address indexed repayKreskoAsset,
        uint256 repayAmount,
        address indexed seizeCollateral,
        uint256 seizeAmount,
        uint256 prevLiqIndex,
        uint256 newLiqIndex,
        uint256 timestamp
    );
    event SCDPCoverOccured(
        address indexed coverer,
        address indexed coverAsset,
        uint256 coverAmount,
        address indexed seizeCollateral,
        uint256 seizeAmount,
        uint256 prevLiqIndex,
        uint256 newLiqIndex,
        uint256 timestamp
    );

    // Emitted when a swap pair is disabled / enabled.
    event PairSet(
        address indexed assetIn,
        address indexed assetOut,
        bool enabled
    );
    // Emitted when a kresko asset fee is updated.
    event FeeSet(
        address indexed _asset,
        uint256 openFee,
        uint256 closeFee,
        uint256 protocolFee
    );

    // Emitted when a collateral is updated.
    event SCDPCollateralUpdated(
        address indexed _asset,
        uint256 liquidationThreshold
    );

    // Emitted when a kresko asset is updated.
    event SCDPKrAssetUpdated(
        address indexed _asset,
        uint256 openFee,
        uint256 closeFee,
        uint256 protocolFee,
        uint256 maxDebtMinter
    );

    event Swap(
        address indexed who,
        address indexed assetIn,
        address indexed assetOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );
    event SwapFee(
        address indexed feeAsset,
        address indexed assetIn,
        uint256 feeAmount,
        uint256 protocolFeeAmount,
        uint256 timestamp
    );

    event Income(address asset, uint256 amount);

    /**
     * @notice Emitted when the liquidation incentive multiplier is updated for a swappable krAsset.
     * @param symbol Asset symbol
     * @param asset The krAsset asset updated.
     * @param from Previous value.
     * @param to New value.
     */
    event SCDPLiquidationIncentiveUpdated(
        string indexed symbol,
        address indexed asset,
        uint256 from,
        uint256 to
    );

    /**
     * @notice Emitted when the minimum collateralization ratio is updated for the SCDP.
     * @param from Previous value.
     * @param to New value.
     */
    event SCDPMinCollateralRatioUpdated(uint256 from, uint256 to);

    /**
     * @notice Emitted when the liquidation threshold value is updated
     * @param from Previous value.
     * @param to New value.
     * @param mlr The new max liquidation ratio.
     */
    event SCDPLiquidationThresholdUpdated(
        uint256 from,
        uint256 to,
        uint256 mlr
    );

    /**
     * @notice Emitted when the max liquidation ratio is updated
     * @param from Previous value.
     * @param to New value.
     */
    event SCDPMaxLiquidationRatioUpdated(uint256 from, uint256 to);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /* -------------------------------------------------------------------------- */
    /*                                 Collateral                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when a collateral asset is added to the protocol.
     * @dev Can only be emitted once for a given collateral asset.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param collateralAsset The address of the collateral asset.
     * @param factor The collateral factor.
     * @param liqIncentive The liquidation incentive
     */
    event CollateralAssetAdded(
        string indexed ticker,
        string indexed symbol,
        address indexed collateralAsset,
        uint256 factor,
        address anchor,
        uint256 liqIncentive
    );

    /**
     * @notice Emitted when a collateral asset is updated.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param collateralAsset The address of the collateral asset.
     * @param factor The collateral factor.
     * @param liqIncentive The liquidation incentive
     */
    event CollateralAssetUpdated(
        string indexed ticker,
        string indexed symbol,
        address indexed collateralAsset,
        uint256 factor,
        address anchor,
        uint256 liqIncentive
    );

    /**
     * @notice Emitted when an account deposits collateral.
     * @param account The address of the account depositing collateral.
     * @param collateralAsset The address of the collateral asset.
     * @param amount The amount of the collateral asset that was deposited.
     */
    event CollateralDeposited(
        address indexed account,
        address indexed collateralAsset,
        uint256 amount
    );

    /**
     * @notice Emitted when an account withdraws collateral.
     * @param account The address of the account withdrawing collateral.
     * @param collateralAsset The address of the collateral asset.
     * @param amount The amount of the collateral asset that was withdrawn.
     */
    event CollateralWithdrawn(
        address indexed account,
        address indexed collateralAsset,
        uint256 amount
    );

    /**
     * @notice Emitted when AMM helper withdraws account collateral without MCR checks.
     * @param account The address of the account withdrawing collateral.
     * @param collateralAsset The address of the collateral asset.
     * @param amount The amount of the collateral asset that was withdrawn.
     */
    event UncheckedCollateralWithdrawn(
        address indexed account,
        address indexed collateralAsset,
        uint256 amount
    );

    /* -------------------------------------------------------------------------- */
    /*                                Kresko Assets                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when a KreskoAsset is added to the protocol.
     * @dev Can only be emitted once for a given Kresko asset.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param kreskoAsset The address of the Kresko asset.
     * @param anchor anchor token
     * @param kFactor The k-factor.
     * @param maxDebtMinter The total supply limit.
     * @param closeFee The close fee percentage.
     * @param openFee The open fee percentage.
     */
    event KreskoAssetAdded(
        string indexed ticker,
        string indexed symbol,
        address indexed kreskoAsset,
        address anchor,
        uint256 kFactor,
        uint256 maxDebtMinter,
        uint256 closeFee,
        uint256 openFee
    );

    /**
     * @notice Emitted when a Kresko asset's oracle is updated.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param kreskoAsset The address of the Kresko asset.
     * @param kFactor The k-factor.
     * @param maxDebtMinter The total supply limit.
     * @param closeFee The close fee percentage.
     * @param openFee The open fee percentage.
     */
    event KreskoAssetUpdated(
        string indexed ticker,
        string indexed symbol,
        address indexed kreskoAsset,
        address anchor,
        uint256 kFactor,
        uint256 maxDebtMinter,
        uint256 closeFee,
        uint256 openFee
    );

    /**
     * @notice Emitted when an account mints a Kresko asset.
     * @param account The address of the account minting the Kresko asset.
     * @param kreskoAsset The address of the Kresko asset.
     * @param amount The amount of the KreskoAsset that was minted.
     * @param receiver Receiver of the minted assets.
     */
    event KreskoAssetMinted(
        address indexed account,
        address indexed kreskoAsset,
        uint256 amount,
        address receiver
    );

    /**
     * @notice Emitted when an account burns a Kresko asset.
     * @param account The address of the account burning the Kresko asset.
     * @param kreskoAsset The address of the Kresko asset.
     * @param amount The amount of the KreskoAsset that was burned.
     */
    event KreskoAssetBurned(
        address indexed account,
        address indexed kreskoAsset,
        uint256 amount
    );

    /**
     * @notice Emitted when cFactor is updated for a collateral asset.
     * @param symbol Asset symbol
     * @param collateralAsset The address of the collateral asset.
     * @param from Previous value.
     * @param to New value.
     */
    event CFactorUpdated(
        string indexed symbol,
        address indexed collateralAsset,
        uint256 from,
        uint256 to
    );
    /**
     * @notice Emitted when kFactor is updated for a KreskoAsset.
     * @param symbol Asset symbol
     * @param kreskoAsset The address of the KreskoAsset.
     * @param from Previous value.
     * @param to New value.
     */
    event KFactorUpdated(
        string indexed symbol,
        address indexed kreskoAsset,
        uint256 from,
        uint256 to
    );

    /**
     * @notice Emitted when an account burns a Kresko asset.
     * @param account The address of the account burning the Kresko asset.
     * @param kreskoAsset The address of the Kresko asset.
     * @param amount The amount of the KreskoAsset that was burned.
     */
    event DebtPositionClosed(
        address indexed account,
        address indexed kreskoAsset,
        uint256 amount
    );

    /**
     * @notice Emitted when an account pays an open/close fee with a collateral asset in the Minter.
     * @dev This can be emitted multiple times for a single asset.
     * @param account Address of the account paying the fee.
     * @param paymentCollateralAsset Address of the collateral asset used to pay the fee.
     * @param feeType Fee type.
     * @param paymentAmount Amount of ollateral asset that was paid.
     * @param paymentValue USD value of the payment.
     */
    event FeePaid(
        address indexed account,
        address indexed paymentCollateralAsset,
        uint256 indexed feeType,
        uint256 paymentAmount,
        uint256 paymentValue,
        uint256 feeValue
    );

    /**
     * @notice Emitted when a liquidation occurs.
     * @param account The address of the account being liquidated.
     * @param liquidator The account performing the liquidation.
     * @param repayKreskoAsset The address of the KreskoAsset being paid back to the protocol by the liquidator.
     * @param repayAmount The amount of the repay KreskoAsset being paid back to the protocol by the liquidator.
     * @param seizedCollateralAsset The address of the collateral asset being seized from the account by the liquidator.
     * @param collateralSent The amount of the seized collateral asset being seized from the account by the liquidator.
     */
    event LiquidationOccurred(
        address indexed account,
        address indexed liquidator,
        address indexed repayKreskoAsset,
        uint256 repayAmount,
        address seizedCollateralAsset,
        uint256 collateralSent
    );

    /* -------------------------------------------------------------------------- */
    /*                                Parameters                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when the fee recipient is updated.
     * @param from The previous value.
     * @param to New value.
     */
    event FeeRecipientUpdated(address from, address to);

    /**
     * @notice Emitted when the liquidation incentive multiplier is updated.
     * @param symbol Asset symbol
     * @param asset The collateral asset being updated.
     * @param from Previous value.
     * @param to New value.
     */
    event LiquidationIncentiveUpdated(
        string indexed symbol,
        address indexed asset,
        uint256 from,
        uint256 to
    );

    /**
     * @notice Emitted when the minimum collateralization ratio is updated.
     * @param from Previous value.
     * @param to New value.
     */
    event MinCollateralRatioUpdated(uint256 from, uint256 to);

    /**
     * @notice Emitted when the minimum debt value updated.
     * @param from Previous value.
     * @param to New value.
     */
    event MinimumDebtValueUpdated(uint256 from, uint256 to);

    /**
     * @notice Emitted when the liquidation threshold value is updated
     * @param from Previous value.
     * @param to New value.
     * @param mlr The new max liquidation ratio.
     */
    event LiquidationThresholdUpdated(uint256 from, uint256 to, uint256 mlr);
    /**
     * @notice Emitted when the max liquidation ratio is updated
     * @param from Previous value.
     * @param to New value.
     */
    event MaxLiquidationRatioUpdated(uint256 from, uint256 to);

    error PERMIT_DEADLINE_EXPIRED(address, address, uint256, uint256);
    error INVALID_SIGNER(address, address);

    error ProxyCalldataFailedWithoutErrMsg();
    error ProxyCalldataFailedWithStringMessage(string message);
    error ProxyCalldataFailedWithCustomError(bytes result);

    error DIAMOND_FUNCTION_DOES_NOT_EXIST(bytes4 selector);
    error DIAMOND_INIT_DATA_PROVIDED_BUT_INIT_ADDRESS_WAS_ZERO(bytes data);
    error DIAMOND_INIT_ADDRESS_PROVIDED_BUT_INIT_DATA_WAS_EMPTY(
        address initializer
    );
    error DIAMOND_FUNCTION_ALREADY_EXISTS(
        address newFacet,
        address oldFacet,
        bytes4 func
    );
    error DIAMOND_INIT_FAILED(address initializer, bytes data);
    error DIAMOND_NOT_INITIALIZING();
    error DIAMOND_ALREADY_INITIALIZED(
        uint256 initializerVersion,
        uint256 currentVersion
    );
    error DIAMOND_CUT_ACTION_WAS_NOT_ADD_REPLACE_REMOVE();
    error DIAMOND_FACET_ADDRESS_CANNOT_BE_ZERO_WHEN_ADDING_FUNCTIONS(
        bytes4[] selectors
    );
    error DIAMOND_FACET_ADDRESS_CANNOT_BE_ZERO_WHEN_REPLACING_FUNCTIONS(
        bytes4[] selectors
    );
    error DIAMOND_FACET_ADDRESS_MUST_BE_ZERO_WHEN_REMOVING_FUNCTIONS(
        address facet,
        bytes4[] selectors
    );
    error DIAMOND_NO_FACET_SELECTORS(address facet);
    error DIAMOND_FACET_ADDRESS_CANNOT_BE_ZERO_WHEN_REMOVING_ONE_FUNCTION(
        bytes4 selector
    );
    error DIAMOND_REPLACE_FUNCTION_NEW_FACET_IS_SAME_AS_OLD(
        address facet,
        bytes4 selector
    );
    error NEW_OWNER_CANNOT_BE_ZERO_ADDRESS();
    error NOT_DIAMOND_OWNER(address who, address owner);
    error NOT_PENDING_DIAMOND_OWNER(address who, address pendingOwner);

    error APPROVE_FAILED(address, address, address, uint256);
    error ETH_TRANSFER_FAILED(address, uint256);
    error TRANSFER_FAILED(address, address, address, uint256);
    error ADDRESS_HAS_NO_CODE(address);
    error NOT_INITIALIZING();
    error TO_WAD_AMOUNT_IS_NEGATIVE(int256);
    error COMMON_ALREADY_INITIALIZED();
    error MINTER_ALREADY_INITIALIZED();
    error SCDP_ALREADY_INITIALIZED();
    error STRING_HEX_LENGTH_INSUFFICIENT();
    error SAFETY_COUNCIL_NOT_ALLOWED();
    error SAFETY_COUNCIL_SETTER_IS_NOT_ITS_OWNER(address);
    error SAFETY_COUNCIL_ALREADY_EXISTS(address given, address existing);
    error MULTISIG_NOT_ENOUGH_OWNERS(address, uint256 owners, uint256 required);
    error ACCESS_CONTROL_NOT_SELF(address who, address self);
    error MARKET_CLOSED(ID, string);
    error SCDP_ASSET_ECONOMY(
        ID,
        uint256 seizeReductionPct,
        ID,
        uint256 repayIncreasePct
    );
    error MINTER_ASSET_ECONOMY(
        ID,
        uint256 seizeReductionPct,
        ID,
        uint256 repayIncreasePct
    );
    error INVALID_TICKER(ID, string ticker);
    error ASSET_NOT_ENABLED(ID);
    error ASSET_SET_FEEDS_FAILED(ID);
    error ASSET_CANNOT_BE_USED_TO_COVER(ID);
    error ASSET_PAUSED_FOR_THIS_ACTION(ID, uint8 action);
    error ASSET_NOT_MINTER_COLLATERAL(ID);
    error ASSET_NOT_FEE_ACCUMULATING_ASSET(ID);
    error ASSET_NOT_SHARED_COLLATERAL(ID);
    error ASSET_NOT_MINTABLE_FROM_MINTER(ID);
    error ASSET_NOT_SWAPPABLE(ID);
    error ASSET_DOES_NOT_HAVE_DEPOSITS(ID);
    error ASSET_CANNOT_BE_FEE_ASSET(ID);
    error ASSET_NOT_VALID_DEPOSIT_ASSET(ID);
    error ASSET_ALREADY_ENABLED(ID);
    error ASSET_ALREADY_DISABLED(ID);
    error ASSET_DOES_NOT_EXIST(ID);
    error ASSET_ALREADY_EXISTS(ID);
    error ASSET_IS_VOID(ID);
    error INVALID_ASSET(ID);
    error CANNOT_REMOVE_COLLATERAL_THAT_HAS_USER_DEPOSITS(ID);
    error CANNOT_REMOVE_SWAPPABLE_ASSET_THAT_HAS_DEBT(ID);
    error INVALID_CONTRACT_KRASSET(ID krAsset);
    error INVALID_CONTRACT_KRASSET_ANCHOR(ID anchor, ID krAsset);
    error NOT_SWAPPABLE_KRASSET(ID);
    error IDENTICAL_ASSETS(ID);
    error WITHDRAW_NOT_SUPPORTED();
    error MINT_NOT_SUPPORTED();
    error DEPOSIT_NOT_SUPPORTED();
    error REDEEM_NOT_SUPPORTED();
    error NATIVE_TOKEN_DISABLED(ID);
    error EXCEEDS_ASSET_DEPOSIT_LIMIT(ID, uint256 deposits, uint256 limit);
    error EXCEEDS_ASSET_MINTING_LIMIT(ID, uint256 deposits, uint256 limit);
    error UINT128_OVERFLOW(ID, uint256 deposits, uint256 limit);
    error INVALID_SENDER(address, address);
    error INVALID_MIN_DEBT(uint256 invalid, uint256 valid);
    error INVALID_SCDP_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_MCR(uint256 invalid, uint256 valid);
    error MLR_CANNOT_BE_LESS_THAN_LIQ_THRESHOLD(uint256 mlt, uint256 lt);
    error INVALID_LIQ_THRESHOLD(uint256 lt, uint256 min, uint256 max);
    error INVALID_PROTOCOL_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_ASSET_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_ORACLE_DEVIATION(uint256 invalid, uint256 valid);
    error INVALID_ORACLE_TYPE(uint8 invalid);
    error INVALID_FEE_RECIPIENT(address invalid);
    error INVALID_LIQ_INCENTIVE(ID, uint256 invalid, uint256 min, uint256 max);
    error INVALID_KFACTOR(ID, uint256 invalid, uint256 valid);
    error INVALID_CFACTOR(ID, uint256 invalid, uint256 valid);
    error INVALID_MINTER_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_PRICE_PRECISION(uint256 decimals, uint256 valid);
    error INVALID_COVER_THRESHOLD(uint256 threshold, uint256 max);
    error INVALID_COVER_INCENTIVE(uint256 incentive, uint256 min, uint256 max);
    error INVALID_DECIMALS(ID, uint256 decimals);
    error INVALID_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_FEE_TYPE(uint8 invalid, uint8 valid);
    error INVALID_VAULT_PRICE(string ticker, address);
    error INVALID_API3_PRICE(string ticker, address);
    error INVALID_CL_PRICE(string ticker, address);
    error INVALID_PRICE(ID, address oracle, int256 price);
    error INVALID_KRASSET_OPERATOR(
        ID,
        address invalidOperator,
        address validOperator
    );
    error INVALID_DENOMINATOR(ID, uint256 denominator, uint256 valid);
    error INVALID_OPERATOR(ID, address who, address valid);
    error INVALID_SUPPLY_LIMIT(ID, uint256 invalid, uint256 valid);
    error NEGATIVE_PRICE(address asset, int256 price);
    error STALE_PRICE(
        string ticker,
        uint256 price,
        uint256 timeFromUpdate,
        uint256 threshold
    );
    error STALE_PUSH_PRICE(
        ID asset,
        string ticker,
        int256 price,
        uint8 oracleType,
        address feed,
        uint256 timeFromUpdate,
        uint256 threshold
    );
    error PRICE_UNSTABLE(
        uint256 primaryPrice,
        uint256 referencePrice,
        uint256 deviationPct
    );
    error ZERO_OR_STALE_VAULT_PRICE(ID, address, uint256);
    error ZERO_OR_STALE_PRICE(string ticker, uint8[2] oracles);
    error ZERO_OR_NEGATIVE_PUSH_PRICE(
        ID asset,
        string ticker,
        int256 price,
        uint8 oracleType,
        address feed
    );
    error NO_PUSH_ORACLE_SET(string ticker);
    error NOT_SUPPORTED_YET();
    error WRAP_NOT_SUPPORTED();
    error BURN_AMOUNT_OVERFLOW(ID, uint256 burnAmount, uint256 debtAmount);
    error PAUSED(address who);
    error L2_SEQUENCER_DOWN();
    error FEED_ZERO_ADDRESS(string ticker);
    error INVALID_SEQUENCER_UPTIME_FEED(address);
    error NO_MINTED_ASSETS(address who);
    error NO_COLLATERALS_DEPOSITED(address who);
    error MISSING_PHASE_3_NFT();
    error MISSING_PHASE_2_NFT();
    error MISSING_PHASE_1_NFT();
    error CANNOT_RE_ENTER();
    error ARRAY_LENGTH_MISMATCH(string ticker, uint256 arr1, uint256 arr2);
    error COLLATERAL_VALUE_GREATER_THAN_REQUIRED(
        uint256 collateralValue,
        uint256 minCollateralValue,
        uint32 ratio
    );
    error COLLATERAL_VALUE_GREATER_THAN_COVER_THRESHOLD(
        uint256 collateralValue,
        uint256 minCollateralValue,
        uint48 ratio
    );
    error ACCOUNT_COLLATERAL_VALUE_LESS_THAN_REQUIRED(
        address who,
        uint256 collateralValue,
        uint256 minCollateralValue,
        uint32 ratio
    );
    error COLLATERAL_VALUE_LESS_THAN_REQUIRED(
        uint256 collateralValue,
        uint256 minCollateralValue,
        uint32 ratio
    );
    error CANNOT_LIQUIDATE_HEALTHY_ACCOUNT(
        address who,
        uint256 collateralValue,
        uint256 minCollateralValue,
        uint32 ratio
    );
    error CANNOT_LIQUIDATE_SELF();
    error LIQUIDATION_AMOUNT_GREATER_THAN_DEBT(
        ID repayAsset,
        uint256 repayAmount,
        uint256 availableAmount
    );
    error LIQUIDATION_SEIZED_LESS_THAN_EXPECTED(ID, uint256, uint256);
    error LIQUIDATION_VALUE_IS_ZERO(ID repayAsset, ID seizeAsset);
    error ACCOUNT_HAS_NO_DEPOSITS(address who, ID);
    error WITHDRAW_AMOUNT_GREATER_THAN_DEPOSITS(
        address who,
        ID,
        uint256 requested,
        uint256 deposits
    );
    error ACCOUNT_KRASSET_NOT_FOUND(
        address account,
        ID,
        address[] accountCollaterals
    );
    error ACCOUNT_COLLATERAL_NOT_FOUND(
        address account,
        ID,
        address[] accountCollaterals
    );
    error ARRAY_INDEX_OUT_OF_BOUNDS(
        ID element,
        uint256 index,
        address[] elements
    );
    error ELEMENT_DOES_NOT_MATCH_PROVIDED_INDEX(
        ID element,
        uint256 index,
        address[] elements
    );
    error NO_FEES_TO_CLAIM(ID asset, address claimer);
    error REPAY_OVERFLOW(
        ID repayAsset,
        ID seizeAsset,
        uint256 invalid,
        uint256 valid
    );
    error INCOME_AMOUNT_IS_ZERO(ID incomeAsset);
    error NO_LIQUIDITY_TO_GIVE_INCOME_FOR(
        ID incomeAsset,
        uint256 userDeposits,
        uint256 totalDeposits
    );
    error NOT_ENOUGH_SWAP_DEPOSITS_TO_SEIZE(
        ID repayAsset,
        ID seizeAsset,
        uint256 invalid,
        uint256 valid
    );
    error SWAP_ROUTE_NOT_ENABLED(ID assetIn, ID assetOut);
    error RECEIVED_LESS_THAN_DESIRED(ID, uint256 invalid, uint256 valid);
    error SWAP_ZERO_AMOUNT_IN(ID tokenIn);
    error INVALID_WITHDRAW(
        ID withdrawAsset,
        uint256 sharesIn,
        uint256 assetsOut
    );
    error ROUNDING_ERROR(ID asset, uint256 sharesIn, uint256 assetsOut);
    error MAX_DEPOSIT_EXCEEDED(ID asset, uint256 assetsIn, uint256 maxDeposit);
    error COLLATERAL_AMOUNT_LOW(
        ID krAssetCollateral,
        uint256 amount,
        uint256 minAmount
    );
    error MINT_VALUE_LESS_THAN_MIN_DEBT_VALUE(
        ID,
        uint256 value,
        uint256 minRequiredValue
    );
    error NOT_A_CONTRACT(address who);
    error NO_ALLOWANCE(
        address spender,
        address owner,
        uint256 requested,
        uint256 allowed
    );
    error NOT_ENOUGH_BALANCE(address who, uint256 requested, uint256 available);
    error SENDER_NOT_OPERATOR(ID, address sender, address kresko);
    error ZERO_SHARES_FROM_ASSETS(ID, uint256 assets, ID);
    error ZERO_SHARES_OUT(ID, uint256 assets);
    error ZERO_SHARES_IN(ID, uint256 assets);
    error ZERO_ASSETS_FROM_SHARES(ID, uint256 shares, ID);
    error ZERO_ASSETS_OUT(ID, uint256 shares);
    error ZERO_ASSETS_IN(ID, uint256 shares);
    error ZERO_ADDRESS();
    error ZERO_DEPOSIT(ID);
    error ZERO_AMOUNT(ID);
    error ZERO_WITHDRAW(ID);
    error ZERO_MINT(ID);
    error ZERO_REPAY(ID, uint256 repayAmount, uint256 seizeAmount);
    error ZERO_BURN(ID);
    error ZERO_DEBT(ID);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    /// uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    /// `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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