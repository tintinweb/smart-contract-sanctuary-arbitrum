// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC4906} from "openzeppelin/interfaces/IERC4906.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {ERC721Upgradeable, IERC165, IERC721} from "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableAccessControlUpgradeable} from "tl-sol-tools/upgradeable/access/OwnableAccessControlUpgradeable.sol";
import {EIP2981TLUpgradeable} from "tl-sol-tools/upgradeable/royalties/EIP2981TLUpgradeable.sol";
import {IBlockListRegistry} from "../../interfaces/IBlockListRegistry.sol";
import {ICreatorBase} from "../../interfaces/ICreatorBase.sol";
import {IERC7160} from "../../interfaces/IERC7160.sol";
import {IStory} from "../../interfaces/IStory.sol";
import {ITLNftDelegationRegistry} from "../../interfaces/ITLNftDelegationRegistry.sol";
import {IERC721TL} from "../IERC721TL.sol";

/// @title CollectorsChoice.sol
/// @notice Sovereign ERC-7160 Editions with a metadata lock timer (Collectors Choice) Creator Contract with Story Inscriptions
/// @dev When unpinned, the latest metadata added for a token is returned from `tokenURI` and `tokenURIs`
/// @author transientlabs.xyz
/// @custom:version 3.1.1
contract CollectorsChoice is
    ERC721Upgradeable,
    EIP2981TLUpgradeable,
    OwnableAccessControlUpgradeable,
    ICreatorBase,
    IERC721TL,
    IStory,
    IERC4906,
    IERC7160
{
    /*//////////////////////////////////////////////////////////////////////////
                                Custom Types
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Struct defining a batch mint
    struct BatchMint {
        address creator;
        uint256 fromTokenId;
        uint256 toTokenId;
    }

    /// @dev Struct for holding values used in ERC-7160
    struct MultiMetadata {
        bool pinned;
        uint256 index;
    }

    /// @dev String representation of uint256
    using Strings for uint256;

    /// @dev String representation for address
    using Strings for address;

    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    string public constant VERSION = "3.1.1";
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant APPROVED_MINT_CONTRACT = keccak256("APPROVED_MINT_CONTRACT");
    uint256 private _counter; // token ids
    bool public storyEnabled;
    bool public floatWhenUnpinned;
    ITLNftDelegationRegistry public tlNftDelegationRegistry;
    IBlockListRegistry public blocklistRegistry;
    uint256 public cutoffTime;
    mapping(uint256 => bool) private _burned; // flag to see if a token is burned or not - needed for burning batch mints
    mapping(uint256 => MultiMetadata) private _multiMetadatas;
    string[] private _tokenUris;
    BatchMint[] private _batchMints; // dynamic array for batch mints

    /*//////////////////////////////////////////////////////////////////////////
                                Custom Events
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Cutoff Time Set
    event CutoffTimeSet(address indexed sender, uint256 indexed time);

    /*//////////////////////////////////////////////////////////////////////////
                                Custom Errors
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev No token uris added yet
    error EmptyTokenURIs();

    /// @dev Mint to zero address
    error MintToZeroAddress();

    /// @dev Batch size too small
    error BatchSizeTooSmall();

    /// @dev Airdrop to too few addresses
    error AirdropTooFewAddresses();

    /// @dev Caller is not approved or owner
    error CallerNotApprovedOrOwner();

    /// @dev Token does not exist
    error TokenDoesntExist();

    /// @dev Index given for ERC-7160 is invalid
    error InvalidTokenURIIndex();

    /// @dev Not owner, admin, or mint contract
    error NotOwnerAdminOrMintContract();

    /// @dev Caller is not the owner or delegate of the owner of the specific token
    error CallerNotTokenOwnerOrDelegate();

    /// @dev Operator for token approvals blocked
    error OperatorBlocked();

    /// @dev Story not enabled for collectors
    error StoryNotEnabled();

    /// @dev Cutoff time set and can't set again
    error CutoffTimeAlreadySet();

    /// @dev Past cutoff time
    error PastCutoffTime();

    /*//////////////////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////////////////*/

    /// @param disable Boolean to disable initialization for the implementation contract
    constructor(bool disable) {
        if (disable) _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @param name The name of the 721 contract
    /// @param symbol The symbol of the 721 contract
    /// @param personalization A string to emit as a collection story. Can be ASCII art or something else that is a personalization of the contract.
    /// @param defaultRoyaltyRecipient The default address for royalty payments
    /// @param defaultRoyaltyPercentage The default royalty percentage of basis points (out of 10,000)
    /// @param initOwner The owner of the contract
    /// @param admins Array of admin addresses to add to the contract
    /// @param enableStory A bool deciding whether to add story fuctionality or not
    /// @param initBlockListRegistry Address of the blocklist registry to use
    /// @param initNftDelegationRegistry Address of the TL nft delegation registry to use
    function initialize(
        string memory name,
        string memory symbol,
        string memory personalization,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address initBlockListRegistry,
        address initNftDelegationRegistry
    ) external initializer {
        // initialize parent contracts
        __ERC721_init(name, symbol);
        __EIP2981TL_init(defaultRoyaltyRecipient, defaultRoyaltyPercentage);
        __OwnableAccessControl_init(initOwner);

        // add admins
        _setRole(ADMIN_ROLE, admins, true);

        // story
        storyEnabled = enableStory;
        emit StoryStatusUpdate(initOwner, enableStory);

        // blocklist and nft delegation registry
        blocklistRegistry = IBlockListRegistry(initBlockListRegistry);
        emit BlockListRegistryUpdate(initOwner, address(0), initBlockListRegistry);
        tlNftDelegationRegistry = ITLNftDelegationRegistry(initNftDelegationRegistry);
        emit NftDelegationRegistryUpdate(initOwner, address(0), initNftDelegationRegistry);

        // emit personalization as collection story
        if (bytes(personalization).length > 0) {
            emit CollectionStory(initOwner, initOwner.toHexString(), personalization);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                General Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICreatorBase
    function totalSupply() external view returns (uint256) {
        return _counter;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Access Control Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICreatorBase
    function setApprovedMintContracts(address[] calldata minters, bool status) external onlyRoleOrOwner(ADMIN_ROLE) {
        _setRole(APPROVED_MINT_CONTRACT, minters, status);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Mint Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721TL
    /// @dev cannot mint unless at least one token uri has been added to the array
    function mint(address recipient, string calldata /*uri*/ ) external onlyRoleOrOwner(ADMIN_ROLE) {
        if (_tokenUris.length == 0) revert EmptyTokenURIs();
        _counter++;
        _mint(recipient, _counter);
    }

    /// @inheritdoc IERC721TL
    /// @dev cannot mint unless at least one token uri has been added to the array
    function mint(address recipient, string calldata, /*uri*/ address royaltyAddress, uint256 royaltyPercent)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        if (_tokenUris.length == 0) revert EmptyTokenURIs();
        _counter++;
        _overrideTokenRoyaltyInfo(_counter, royaltyAddress, royaltyPercent);
        _mint(recipient, _counter);
    }

    /// @inheritdoc IERC721TL
    /// @dev cannot mint unless at least one token uri has been added to the array
    function batchMint(address recipient, uint128 numTokens, string calldata /*baseUri*/ )
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        if (_tokenUris.length == 0) revert EmptyTokenURIs();
        if (recipient == address(0)) revert MintToZeroAddress();
        if (numTokens < 2) revert BatchSizeTooSmall();
        uint256 start = _counter + 1;
        uint256 end = start + numTokens - 1;
        _counter += numTokens;
        _batchMints.push(BatchMint(recipient, start, end));

        _increaseBalance(recipient, numTokens); // this function adds the number of tokens to the recipient address

        for (uint256 id = start; id < end + 1; ++id) {
            emit Transfer(address(0), recipient, id);
        }
    }

    /// @inheritdoc IERC721TL
    /// @dev cannot mint unless at least one token uri has been added to the array
    function airdrop(address[] calldata addresses, string calldata /*baseUri*/ ) external onlyRoleOrOwner(ADMIN_ROLE) {
        if (_tokenUris.length == 0) revert EmptyTokenURIs();
        if (addresses.length < 2) revert AirdropTooFewAddresses();

        uint256 start = _counter + 1;
        _counter += addresses.length;
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], start + i);
        }
    }

    /// @inheritdoc IERC721TL
    /// @dev cannot mint unless at least one token uri has been added to the array
    function externalMint(address recipient, string calldata /*uri*/ ) external onlyRole(APPROVED_MINT_CONTRACT) {
        if (_tokenUris.length == 0) revert EmptyTokenURIs();
        _counter++;
        _mint(recipient, _counter);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Burn Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721TL
    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (!_isAuthorized(owner, msg.sender, tokenId)) revert CallerNotApprovedOrOwner();
        _burn(tokenId);
        _burned[tokenId] = true;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICreatorBase
    function setDefaultRoyalty(address newRecipient, uint256 newPercentage) external onlyRoleOrOwner(ADMIN_ROLE) {
        _setDefaultRoyaltyInfo(newRecipient, newPercentage);
    }

    /// @inheritdoc ICreatorBase
    function setTokenRoyalty(uint256 tokenId, address newRecipient, uint256 newPercentage)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        _overrideTokenRoyaltyInfo(tokenId, newRecipient, newPercentage);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Collectors Choice Function
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to set the cutoff time for the contract
    /// @dev Must be called by the contract owner oor admin
    /// @param time The cutoff time
    function setCutoffTime(uint256 time) external onlyRoleOrOwner(ADMIN_ROLE) {
        if (cutoffTime != 0) revert CutoffTimeAlreadySet();
        cutoffTime = time;
        emit CutoffTimeSet(msg.sender, time);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ERC-7160 Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to change the unpinned display state
    /// @dev floating means that the last item in the tokenUris array will be returned from `tokenUri`
    /// @dev if not floating, the first item in the tokenUris array is returned
    /// @param float Bool indicating whether to float or not
    function setUnpinnedFloatState(bool float) external onlyRoleOrOwner(ADMIN_ROLE) {
        floatWhenUnpinned = float;
        emit BatchMetadataUpdate(1, _counter);
    }

    /// @notice Function to add token uris
    /// @dev Must be called by contract owner, admin, or approved mint contract
    /// @param tokenUris Array of token uris to add
    function addTokenUris(string[] calldata tokenUris) external {
        if (msg.sender != owner() && !hasRole(ADMIN_ROLE, msg.sender) && !hasRole(APPROVED_MINT_CONTRACT, msg.sender)) {
            revert NotOwnerAdminOrMintContract();
        }
        if (cutoffTime != 0 && block.timestamp > cutoffTime) revert PastCutoffTime();
        if (tokenUris.length == 0) revert EmptyTokenURIs();
        for (uint256 i = 0; i < tokenUris.length; i++) {
            _tokenUris.push(tokenUris[i]);

            uint256 numTokens = _counter;
            if (numTokens > 0) {
                emit BatchMetadataUpdate(1, numTokens);
            }
        }
    }

    /// @inheritdoc IERC7160
    function tokenURIs(uint256 tokenId) external view returns (uint256 index, string[] memory uris, bool pinned) {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        MultiMetadata memory multiMetadata = _multiMetadatas[tokenId];
        // build uris
        uris = _tokenUris;
        // get if pinned
        pinned = multiMetadata.pinned;
        // set index
        if (pinned) {
            index = multiMetadata.index;
        } else {
            index = floatWhenUnpinned ? uris.length - 1 : 0;
        }
    }

    /// @inheritdoc IERC7160
    function pinTokenURI(uint256 tokenId, uint256 index) external {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        if (cutoffTime != 0 && block.timestamp > cutoffTime) revert PastCutoffTime();
        if (!_isTokenOwnerOrDelegate(tokenId)) revert CallerNotTokenOwnerOrDelegate();
        if (index >= _tokenUris.length) {
            revert InvalidTokenURIIndex();
        }

        _multiMetadatas[tokenId].index = index;
        _multiMetadatas[tokenId].pinned = true;

        emit TokenUriPinned(tokenId, index);
        emit MetadataUpdate(tokenId);
    }

    /// @inheritdoc IERC7160
    function unpinTokenURI(uint256 tokenId) external {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        if (cutoffTime != 0 && block.timestamp > cutoffTime) revert PastCutoffTime();
        if (!_isTokenOwnerOrDelegate(tokenId)) revert CallerNotTokenOwnerOrDelegate();

        _multiMetadatas[tokenId].pinned = false;

        emit TokenUriUnpinned(tokenId);
        emit MetadataUpdate(tokenId);
    }

    /// @inheritdoc IERC7160
    function hasPinnedTokenURI(uint256 tokenId) external view returns (bool) {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        return _multiMetadatas[tokenId].pinned;
    }

    /// @inheritdoc ERC721Upgradeable
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory uri) {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        MultiMetadata memory multiMetadata = _multiMetadatas[tokenId];
        if (multiMetadata.pinned) {
            uri = _tokenUris[multiMetadata.index];
        } else {
            uri = floatWhenUnpinned ? _tokenUris[_tokenUris.length - 1] : _tokenUris[0];
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Story Inscriptions
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IStory
    function addCollectionStory(string calldata, /*creatorName*/ string calldata story)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        emit CollectionStory(msg.sender, msg.sender.toHexString(), story);
    }

    /// @inheritdoc IStory
    function addCreatorStory(uint256 tokenId, string calldata, /*creatorName*/ string calldata story)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        emit CreatorStory(tokenId, msg.sender, msg.sender.toHexString(), story);
    }

    /// @inheritdoc IStory
    function addStory(uint256 tokenId, string calldata, /*collectorName*/ string calldata story) external {
        if (!storyEnabled) revert StoryNotEnabled();
        if (!_isTokenOwnerOrDelegate(tokenId)) revert CallerNotTokenOwnerOrDelegate();
        emit Story(tokenId, msg.sender, msg.sender.toHexString(), story);
    }

    /// @inheritdoc ICreatorBase
    function setStoryStatus(bool status) external onlyRoleOrOwner(ADMIN_ROLE) {
        storyEnabled = status;
        emit StoryStatusUpdate(msg.sender, status);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                BlockList
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICreatorBase
    function setBlockListRegistry(address newBlockListRegistry) external onlyRoleOrOwner(ADMIN_ROLE) {
        address oldBlockListRegistry = address(blocklistRegistry);
        blocklistRegistry = IBlockListRegistry(newBlockListRegistry);
        emit BlockListRegistryUpdate(msg.sender, oldBlockListRegistry, newBlockListRegistry);
    }

    /// @inheritdoc ERC721Upgradeable
    function approve(address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721) {
        if (_isOperatorBlocked(to)) revert OperatorBlocked();
        ERC721Upgradeable.approve(to, tokenId);
    }

    /// @inheritdoc ERC721Upgradeable
    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable, IERC721) {
        if (approved) {
            if (_isOperatorBlocked(operator)) revert OperatorBlocked();
        }
        ERC721Upgradeable.setApprovalForAll(operator, approved);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            NFT Delegation Registry
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICreatorBase
    function setNftDelegationRegistry(address newNftDelegationRegistry) external onlyRoleOrOwner(ADMIN_ROLE) {
        address oldNftDelegationRegistry = address(tlNftDelegationRegistry);
        tlNftDelegationRegistry = ITLNftDelegationRegistry(newNftDelegationRegistry);
        emit NftDelegationRegistryUpdate(msg.sender, oldNftDelegationRegistry, newNftDelegationRegistry);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ERC-165 Support
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, EIP2981TLUpgradeable, IERC165)
        returns (bool)
    {
        return (
            ERC721Upgradeable.supportsInterface(interfaceId) || EIP2981TLUpgradeable.supportsInterface(interfaceId)
                || interfaceId == 0x49064906 // ERC-4906
                || interfaceId == type(IERC7160).interfaceId || interfaceId == type(ICreatorBase).interfaceId
                || interfaceId == type(IStory).interfaceId || interfaceId == 0x0d23ecb9 // previous story contract version that is still supported
                || interfaceId == type(IERC721TL).interfaceId
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Internal Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to get batch mint info
    /// @param tokenId Token id to look up for batch mint info
    /// @return adress The token owner
    function _getBatchInfo(uint256 tokenId) internal view returns (address) {
        uint256 i = 0;
        for (i; i < _batchMints.length; i++) {
            if (tokenId >= _batchMints[i].fromTokenId && tokenId <= _batchMints[i].toTokenId) {
                break;
            }
        }
        if (i >= _batchMints.length) {
            return address(0);
        }
        return _batchMints[i].creator;
    }

    /// @notice Function to override { ERC721Upgradeable._ownerOf } to allow for batch minting
    /// @inheritdoc ERC721Upgradeable
    function _ownerOf(uint256 tokenId) internal view override(ERC721Upgradeable) returns (address) {
        if (_burned[tokenId]) {
            return address(0);
        } else {
            if (tokenId > 0 && tokenId <= _counter) {
                address owner = ERC721Upgradeable._ownerOf(tokenId);
                if (owner == address(0)) {
                    // see if can find token in a batch mint
                    owner = _getBatchInfo(tokenId);
                }
                return owner;
            } else {
                return address(0);
            }
        }
    }

    /// @notice Function to check if a token exists
    /// @param tokenId The token id to check
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /// @notice Function to get if msg.sender is the token owner or delegated owner
    function _isTokenOwnerOrDelegate(uint256 tokenId) internal view returns (bool) {
        address tokenOwner = _ownerOf(tokenId);
        if (msg.sender == tokenOwner) {
            return true;
        } else if (address(tlNftDelegationRegistry) == address(0)) {
            return false;
        } else {
            return tlNftDelegationRegistry.checkDelegateForERC721(msg.sender, tokenOwner, address(this), tokenId);
        }
    }

    // @notice Function to get if an operator is blocked for token approvals
    function _isOperatorBlocked(address operator) internal view returns (bool) {
        if (address(blocklistRegistry) == address(0)) {
            return false;
        } else {
            return blocklistRegistry.getBlockListStatus(operator);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4906.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";
import {IERC721} from "./IERC721.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165Upgradeable} from "../../utils/introspection/ERC165Upgradeable.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    /// @custom:storage-location erc7201:openzeppelin.storage.ERC721
    struct ERC721Storage {
        // Token name
        string _name;

        // Token symbol
        string _symbol;

        mapping(uint256 tokenId => address) _owners;

        mapping(address owner => uint256) _balances;

        mapping(uint256 tokenId => address) _tokenApprovals;

        mapping(address owner => mapping(address operator => bool)) _operatorApprovals;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC721")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC721StorageLocation = 0x80bb2b638cc20bc4d0a60d66940f3ab4a00c1d7b313497ca82fb0b4ab0079300;

    function _getERC721Storage() private pure returns (ERC721Storage storage $) {
        assembly {
            $.slot := ERC721StorageLocation
        }
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC721Storage storage $ = _getERC721Storage();
        $._name = name_;
        $._symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        ERC721Storage storage $ = _getERC721Storage();
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return $._balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     *
     * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
     * core ERC721 logic MUST be matched with the use of {_increaseBalance} to keep balances
     * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
     * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._owners[tokenId];
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
     * the `spender` for the specific `tokenId`.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
     * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
     *
     * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
     * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
     * remain consistent with one another.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        unchecked {
            $._balances[account] += value;
        }
    }

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                $._balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                $._balances[to] += 1;
            }
        }

        $._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
     * are aware of the ERC721 standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is like {safeTransferFrom} in the sense that it invokes
     * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned by `from`.
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
     * emitted in the context of transfers.
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        $._tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        $._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
     * Returns the owner.
     *
     * Overrides to ownership logic should be done to {_ownerOf}.
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

/// @title OwnableAccessControlUpgradeable.sol
/// @notice Single owner, flexible access control mechanics
/// @dev Can easily be extended by inheriting and applying additional roles
/// @dev By default, only the owner can grant roles but by inheriting, but you
///      may allow other roles to grant roles by using the internal helper.
/// @author transientlabs.xyz
/// @custom:version 3.0.0
abstract contract OwnableAccessControlUpgradeable is OwnableUpgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                    Types
    //////////////////////////////////////////////////////////////////////////*/

    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////////////////
                                    Storage
    //////////////////////////////////////////////////////////////////////////*/

    /// @custom:storage-location erc7201:transientlabs.storage.OwnableAccessControl
    struct OwnableAccessControlStorage {
        uint256 c; // counter to be able to revoke all priviledges
        mapping(uint256 => mapping(bytes32 => mapping(address => bool))) roleStatus;
        mapping(uint256 => mapping(bytes32 => EnumerableSet.AddressSet)) roleMembers;
    }

    // keccak256(abi.encode(uint256(keccak256("transientlabs.storage.OwnableAccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableAccessControlStorageLocation =
        0x0d0469b3d32e63681b9fc586a5627ad5e70b3d1ad20f31767e4b6c4141c7e300;

    function _getOwnableAccessControlStorage() private pure returns (OwnableAccessControlStorage storage $) {
        assembly {
            $.slot := OwnableAccessControlStorageLocation
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    Events
    //////////////////////////////////////////////////////////////////////////*/

    /// @param from Address that authorized the role change
    /// @param user The address who's role has been changed
    /// @param approved Boolean indicating the user's status in role
    /// @param role The bytes32 role created in the inheriting contract
    event RoleChange(address indexed from, address indexed user, bool indexed approved, bytes32 role);

    /// @param from Address that authorized the revoke
    event AllRolesRevoked(address indexed from);

    /*//////////////////////////////////////////////////////////////////////////
                                    Errors
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Does not have specified role
    error NotSpecifiedRole(bytes32 role);

    /// @dev Is not specified role or owner
    error NotRoleOrOwner(bytes32 role);

    /*//////////////////////////////////////////////////////////////////////////
                                    Modifiers
    //////////////////////////////////////////////////////////////////////////*/

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) {
            revert NotSpecifiedRole(role);
        }
        _;
    }

    modifier onlyRoleOrOwner(bytes32 role) {
        if (!hasRole(role, msg.sender) && owner() != msg.sender) {
            revert NotRoleOrOwner(role);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initOwner The address of the initial owner
    function __OwnableAccessControl_init(address initOwner) internal onlyInitializing {
        __Ownable_init(initOwner);
        __OwnableAccessControl_init_unchained();
    }

    function __OwnableAccessControl_init_unchained() internal onlyInitializing {}

    /*//////////////////////////////////////////////////////////////////////////
                                External Role Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to revoke all roles currently present
    /// @dev Increments the `_c` variables
    /// @dev Requires owner privileges
    function revokeAllRoles() external onlyOwner {
        OwnableAccessControlStorage storage $ = _getOwnableAccessControlStorage();
        $.c++;
        emit AllRolesRevoked(msg.sender);
    }

    /// @notice Function to renounce role
    /// @param role Bytes32 role created in inheriting contracts
    function renounceRole(bytes32 role) external {
        address[] memory members = new address[](1);
        members[0] = msg.sender;
        _setRole(role, members, false);
    }

    /// @notice Function to grant/revoke a role to an address
    /// @dev Requires owner to call this function but this may be further
    ///      extended using the internal helper function in inheriting contracts
    /// @param role Bytes32 role created in inheriting contracts
    /// @param roleMembers List of addresses that should have roles attached to them based on `status`
    /// @param status Bool whether to remove or add `roleMembers` to the `role`
    function setRole(bytes32 role, address[] memory roleMembers, bool status) external onlyOwner {
        _setRole(role, roleMembers, status);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                External View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to see if an address is the owner
    /// @param role Bytes32 role created in inheriting contracts
    /// @param potentialRoleMember Address to check for role membership
    function hasRole(bytes32 role, address potentialRoleMember) public view returns (bool) {
        OwnableAccessControlStorage storage $ = _getOwnableAccessControlStorage();
        return $.roleStatus[$.c][role][potentialRoleMember];
    }

    /// @notice Function to get role members
    /// @param role Bytes32 role created in inheriting contracts
    function getRoleMembers(bytes32 role) public view returns (address[] memory) {
        OwnableAccessControlStorage storage $ = _getOwnableAccessControlStorage();
        return $.roleMembers[$.c][role].values();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Internal Helper Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Helper function to set addresses for a role
    /// @param role Bytes32 role created in inheriting contracts
    /// @param roleMembers List of addresses that should have roles attached to them based on `status`
    /// @param status Bool whether to remove or add `roleMembers` to the `role`
    function _setRole(bytes32 role, address[] memory roleMembers, bool status) internal {
        OwnableAccessControlStorage storage $ = _getOwnableAccessControlStorage();
        for (uint256 i = 0; i < roleMembers.length; i++) {
            $.roleStatus[$.c][role][roleMembers[i]] = status;
            if (status) {
                $.roleMembers[$.c][role].add(roleMembers[i]);
            } else {
                $.roleMembers[$.c][role].remove(roleMembers[i]);
            }
            emit RoleChange(msg.sender, roleMembers[i], status, role);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165Upgradeable} from "openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IEIP2981} from "../../royalties/IEIP2981.sol";

/// @title EIP2981TLUpgradeable.sol
/// @notice Abstract contract to define a default royalty spec
///         while allowing for specific token overrides
/// @dev Follows EIP-2981 (https://eips.ethereum.org/EIPS/eip-2981)
/// @author transientlabs.xyz
/// @custom:version 3.1.0
abstract contract EIP2981TLUpgradeable is IEIP2981, ERC165Upgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                    Types
    //////////////////////////////////////////////////////////////////////////*/

    struct RoyaltySpec {
        address recipient;
        uint256 percentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    Storage
    //////////////////////////////////////////////////////////////////////////*/

    /// @custom:storage-location erc7201:transientlabs.storage.EIP2981TLStorage
    struct EIP2981TLStorage {
        address defaultRecipient;
        uint256 defaultPercentage;
        mapping(uint256 => RoyaltySpec) tokenOverrides;
    }

    // keccak256(abi.encode(uint256(keccak256("transientlabs.storage.EIP2981TLStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant EIP2981TLStorageLocation =
        0xe9db8e9b56f2e28e12956850f386d9a4c1e886a4f584b61a10a9d0cacee70700;

    function _getEIP2981TLStorage() private pure returns (EIP2981TLStorage storage $) {
        assembly {
            $.slot := EIP2981TLStorageLocation
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Constants
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant BASIS = 10_000;

    /*//////////////////////////////////////////////////////////////////////////
                                    Events
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Event to emit when the default roylaty is updated
    event DefaultRoyaltyUpdate(address indexed sender, address newRecipient, uint256 newPercentage);

    /// @dev Event to emit when a token royalty is overriden
    event TokenRoyaltyOverride(address indexed sender, uint256 indexed tokenId, address newRecipient, uint256 newPercentage);

    /*//////////////////////////////////////////////////////////////////////////
                                    Errors
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev error if the recipient is set to address(0)
    error ZeroAddressError();

    /// @dev error if the royalty percentage is greater than to 100%
    error MaxRoyaltyError();

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to initialize the contract
    /// @param defaultRecipient The default royalty payout address
    /// @param defaultPercentage The deafult royalty percentage, out of 10,000
    function __EIP2981TL_init(address defaultRecipient, uint256 defaultPercentage) internal onlyInitializing {
        __EIP2981TL_init_unchained(defaultRecipient, defaultPercentage);
    }

    /// @notice Unchained function to initialize the contract
    /// @param defaultRecipient The default royalty payout address
    /// @param defaultPercentage The deafult royalty percentage, out of 10,000
    function __EIP2981TL_init_unchained(address defaultRecipient, uint256 defaultPercentage)
        internal
        onlyInitializing
    {
        _setDefaultRoyaltyInfo(defaultRecipient, defaultPercentage);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Changing Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to set default royalty info
    /// @param newRecipient The new default royalty payout address
    /// @param newPercentage The new default royalty percentage, out of 10,000
    function _setDefaultRoyaltyInfo(address newRecipient, uint256 newPercentage) internal {
        EIP2981TLStorage storage $ = _getEIP2981TLStorage();
        if (newRecipient == address(0)) revert ZeroAddressError();
        if (newPercentage > 10_000) revert MaxRoyaltyError();
        $.defaultRecipient = newRecipient;
        $.defaultPercentage = newPercentage;
        emit DefaultRoyaltyUpdate(msg.sender, newRecipient, newPercentage);
    }

    /// @notice Function to override royalty spec on a specific token
    /// @param tokenId The token id to override royalty for
    /// @param newRecipient The new royalty payout address
    /// @param newPercentage The new royalty percentage, out of 10,000
    function _overrideTokenRoyaltyInfo(uint256 tokenId, address newRecipient, uint256 newPercentage) internal {
        EIP2981TLStorage storage $ = _getEIP2981TLStorage();
        if (newRecipient == address(0)) revert ZeroAddressError();
        if (newPercentage > 10_000) revert MaxRoyaltyError();
        $.tokenOverrides[tokenId].recipient = newRecipient;
        $.tokenOverrides[tokenId].percentage = newPercentage;
        emit TokenRoyaltyOverride(msg.sender, tokenId, newRecipient, newPercentage);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Info
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEIP2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        EIP2981TLStorage storage $ = _getEIP2981TLStorage();
        address recipient = $.defaultRecipient;
        uint256 percentage = $.defaultPercentage;
        if ($.tokenOverrides[tokenId].recipient != address(0)) {
            recipient = $.tokenOverrides[tokenId].recipient;
            percentage = $.tokenOverrides[tokenId].percentage;
        }
        return (recipient, salePrice * percentage / BASIS);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ERC-165 Override
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || ERC165Upgradeable.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            External View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Query the default royalty receiver and percentage.
    /// @return Tuple containing the default royalty recipient and percentage out of 10_000
    function getDefaultRoyaltyRecipientAndPercentage() external view returns (address, uint256) {
        EIP2981TLStorage storage $ = _getEIP2981TLStorage();
        return ($.defaultRecipient, $.defaultPercentage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title BlockList Registry
/// @notice Interface for the BlockListRegistry Contract
/// @author transientlabs.xyz
/// @custom:version 4.0.3
interface IBlockListRegistry {
    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    event BlockListStatusChange(address indexed user, address indexed operator, bool indexed status);

    event BlockListCleared(address indexed user);

    /*//////////////////////////////////////////////////////////////////////////
                          Public Read Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to get blocklist status with True meaning that the operator is blocked
    /// @param operator The operator in question to check against the blocklist
    function getBlockListStatus(address operator) external view returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                          Public Write Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to set the block list status for multiple operators
    /// @dev Must be called by the blockList owner
    /// @param operators An address array of operators to set a status for
    /// @param status The status to set for all `operators`
    function setBlockListStatus(address[] calldata operators, bool status) external;

    /// @notice Function to clear the block list status
    /// @dev Must be called by the blockList owner
    function clearBlockList() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IBlockListRegistry} from "./IBlockListRegistry.sol";
import {ITLNftDelegationRegistry} from "./ITLNftDelegationRegistry.sol";

/// @title ICreatorBase.sol
/// @notice Base interface for creator contracts
/// @dev Interface id = 0x1c8e024d
/// @author transientlabs.xyz
/// @custom:version 3.0.0
interface ICreatorBase {
    /*//////////////////////////////////////////////////////////////////////////
                                    Events
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Event for changing the story status
    event StoryStatusUpdate(address indexed sender, bool indexed status);

    /// @dev Event for changing the BlockList registry
    event BlockListRegistryUpdate(
        address indexed sender, address indexed prevBlockListRegistry, address indexed newBlockListRegistry
    );

    /// @dev Event for changing the NFT Delegation registry
    event NftDelegationRegistryUpdate(
        address indexed sender, address indexed prevNftDelegationRegistry, address indexed newNftDelegationRegistry
    );

    /*//////////////////////////////////////////////////////////////////////////
                                    Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to get total supply minted so far
    function totalSupply() external view returns (uint256);

    /// @notice Function to set approved mint contracts
    /// @dev Access to owner or admin
    /// @param minters Array of minters to grant approval to
    /// @param status Status for the minters
    function setApprovedMintContracts(address[] calldata minters, bool status) external;

    /// @notice Function to change the blocklist registry
    /// @dev Access to owner or admin
    /// @param newBlockListRegistry The new blocklist registry
    function setBlockListRegistry(address newBlockListRegistry) external;

    /// @notice Function to get the blocklist registry
    function blocklistRegistry() external view returns (IBlockListRegistry);

    /// @notice Function to change the TL NFT delegation registry
    /// @dev Access to owner or admin
    /// @param newNftDelegationRegistry The new blocklist registry
    function setNftDelegationRegistry(address newNftDelegationRegistry) external;

    /// @notice Function to get the delegation registry
    function tlNftDelegationRegistry() external view returns (ITLNftDelegationRegistry);

    /// @notice Function to set the default royalty specification
    /// @dev Requires owner or admin
    /// @param newRecipient The new royalty payout address
    /// @param newPercentage The new royalty percentage in basis (out of 10,000)
    function setDefaultRoyalty(address newRecipient, uint256 newPercentage) external;

    /// @notice Function to override a token's royalty info
    /// @dev Requires owner or admin
    /// @param tokenId The token to override royalty for
    /// @param newRecipient The new royalty payout address for the token id
    /// @param newPercentage The new royalty percentage in basis (out of 10,000) for the token id
    function setTokenRoyalty(uint256 tokenId, address newRecipient, uint256 newPercentage) external;

    /// @notice Function to enable or disable collector story inscriptions
    /// @dev Requires owner or admin
    /// @param status The status to set for collector story inscriptions
    function setStoryStatus(bool status) external;

    /// @notice Function to get the status of collector stories
    /// @return bool Status of collector stories being enabled
    function storyEnabled() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title EIP-721 Multi-Metdata Extension
/// @dev The ERC-165 identifier for this interface is 0x06e1bc5b.
interface IERC7160 {
    /// @dev This event emits when a token uri is pinned and is
    ///  useful for indexing purposes.
    event TokenUriPinned(uint256 indexed tokenId, uint256 indexed index);

    /// @dev This event emits when a token uri is unpinned and is
    ///  useful for indexing purposes.
    event TokenUriUnpinned(uint256 indexed tokenId);

    /// @notice Get all token uris associated with a particular token
    /// @dev If a token uri is pinned, the index returned SHOULD be the index in the string array
    /// @dev This call MUST revert if the token does not exist
    /// @param tokenId The identifier for the nft
    /// @return index An unisgned integer that specifies which uri is pinned for a token (or the default uri if unpinned)
    /// @return uris A string array of all uris associated with a token
    /// @return pinned A boolean showing if the token has pinned metadata or not
    function tokenURIs(uint256 tokenId) external view returns (uint256 index, string[] memory uris, bool pinned);

    /// @notice Pin a specific token uri for a particular token
    /// @dev This call MUST revert if the token does not exist
    /// @dev This call MUST emit a `TokenUriPinned` event
    /// @dev This call MAY emit a `MetadataUpdate` event from ERC-4096
    /// @param tokenId The identifier of the nft
    /// @param index The index in the string array returned from the `tokenURIs` function that should be pinned for the token
    function pinTokenURI(uint256 tokenId, uint256 index) external;

    /// @notice Unpin metadata for a particular token
    /// @dev This call MUST revert if the token does not exist
    /// @dev This call MUST emit a `TokenUriUnpinned` event
    /// @dev This call MAY emit a `MetadataUpdate` event from ERC-4096
    /// @dev It is up to the developer to define what this function does and is intentionally left open-ended
    /// @param tokenId The identifier of the nft
    function unpinTokenURI(uint256 tokenId) external;

    /// @notice Check on-chain if a token id has a pinned uri or not
    /// @dev This call MUST revert if the token does not exist
    /// @dev Useful for on-chain mechanics that don't require the tokenURIs themselves
    /// @param tokenId The identifier of the nft
    /// @return pinned A bool specifying if a token has metadata pinned or not
    function hasPinnedTokenURI(uint256 tokenId) external view returns (bool pinned);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Transient Labs Story Inscriptions Interface
/// @dev Interface id: 0x2464f17b
/// @dev Previous interface id that is still supported: 0x0d23ecb9
/// @author transientlabs.xyz
/// @custom:version 6.0.0
interface IStory {
    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Event describing a collection story getting added to a contract
    /// @dev This event stories creator stories on chain in the event log that apply to an entire collection
    /// @param creatorAddress The address of the creator of the collection
    /// @param creatorName String representation of the creator's name
    /// @param story The story written and attached to the collection
    event CollectionStory(address indexed creatorAddress, string creatorName, string story);

    /// @notice Event describing a creator story getting added to a token
    /// @dev This events stores creator stories on chain in the event log
    /// @param tokenId The token id to which the story is attached
    /// @param creatorAddress The address of the creator of the token
    /// @param creatorName String representation of the creator's name
    /// @param story The story written and attached to the token id
    event CreatorStory(uint256 indexed tokenId, address indexed creatorAddress, string creatorName, string story);

    /// @notice Event describing a collector story getting added to a token
    /// @dev This events stores collector stories on chain in the event log
    /// @param tokenId The token id to which the story is attached
    /// @param collectorAddress The address of the collector of the token
    /// @param collectorName String representation of the collectors's name
    /// @param story The story written and attached to the token id
    event Story(uint256 indexed tokenId, address indexed collectorAddress, string collectorName, string story);

    /*//////////////////////////////////////////////////////////////////////////
                                Story Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to let the creator add a story to the collection they have created
    /// @dev Depending on the implementation, this function may be restricted in various ways, such as
    ///      limiting the number of times the creator may write a story.
    /// @dev This function MUST emit the CollectionStory event each time it is called
    /// @dev This function MUST implement logic to restrict access to only the creator
    /// @param creatorName String representation of the creator's name
    /// @param story The story written and attached to the token id
    function addCollectionStory(string calldata creatorName, string calldata story) external;

    /// @notice Function to let the creator add a story to any token they have created
    /// @dev Depending on the implementation, this function may be restricted in various ways, such as
    ///      limiting the number of times the creator may write a story.
    /// @dev This function MUST emit the CreatorStory event each time it is called
    /// @dev This function MUST implement logic to restrict access to only the creator
    /// @dev This function MUST revert if a story is written to a non-existent token
    /// @param tokenId The token id to which the story is attached
    /// @param creatorName String representation of the creator's name
    /// @param story The story written and attached to the token id
    function addCreatorStory(uint256 tokenId, string calldata creatorName, string calldata story) external;

    /// @notice Function to let collectors add a story to any token they own
    /// @dev Depending on the implementation, this function may be restricted in various ways, such as
    ///      limiting the number of times a collector may write a story.
    /// @dev This function MUST emit the Story event each time it is called
    /// @dev This function MUST implement logic to restrict access to only the owner of the token
    /// @dev This function MUST revert if a story is written to a non-existent token
    /// @param tokenId The token id to which the story is attached
    /// @param collectorName String representation of the collectors's name
    /// @param story The story written and attached to the token id
    function addStory(uint256 tokenId, string calldata collectorName, string calldata story) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ITLNftDelegationRegistry.sol
/// @notice Interface for the TL NFT Delegation Registry
/// @author transientlabs.xyz
/// @custom:version 1.0.0
interface ITLNftDelegationRegistry {
    /// @notice Function to check if an address is delegated for a vault for an ERC-721 token
    /// @dev This function does not ensure the vault is the current owner of the token
    /// @dev This function SHOULD return `True` if the delegate is delegated for the vault whether it's on the token level, contract level, or wallet level (all)
    /// @param delegate The address to check for delegation status
    /// @param vault The vault address to check against
    /// @param nftContract The nft contract address to check
    /// @param tokenId The token id to check against
    /// @return bool `True` is delegated, `False` if not
    function checkDelegateForERC721(address delegate, address vault, address nftContract, uint256 tokenId)
        external
        view
        returns (bool);

    /// @notice Function to check if an address is delegated for a vault for an ERC-1155 token
    /// @dev This function does not ensure the vault has a balance of the token in question
    /// @dev This function SHOULD return `True` if the delegate is delegated for the vault whether it's on the token level, contract level, or wallet level (all)
    /// @param delegate The address to check for delegation status
    /// @param vault The vault address to check against
    /// @param nftContract The nft contract address to check
    /// @param tokenId The token id to check against
    /// @return bool `True` is delegated, `False` if not
    function checkDelegateForERC1155(address delegate, address vault, address nftContract, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/// @title IERC721TL.sol
/// @notice Interface for ERC721TL
/// @dev Interface id = 0xc74089ae
/// @author transientlabs.xyz
/// @custom:version 3.0.0
interface IERC721TL {
    /*//////////////////////////////////////////////////////////////////////////
                                    Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to mint a single token
    /// @dev Requires owner or admin
    /// @param recipient The recipient of the token - assumed as able to receive 721 tokens
    /// @param uri The token uri to mint
    function mint(address recipient, string calldata uri) external;

    /// @notice Function to mint a single token with specific token royalty
    /// @dev Requires owner or admin
    /// @param recipient The recipient of the token - assumed as able to receive 721 tokens
    /// @param uri The token uri to mint
    /// @param royaltyAddress Royalty payout address for this new token
    /// @param royaltyPercent Royalty percentage for this new token
    function mint(address recipient, string calldata uri, address royaltyAddress, uint256 royaltyPercent) external;

    /// @notice Function to batch mint tokens
    /// @dev Requires owner or admin
    /// @dev The `baseUri` folder should have the same number of json files in it as `numTokens`
    /// @dev The `baseUri` folder should have files named without any file extension
    /// @param recipient The recipient of the token - assumed as able to receive 721 tokens
    /// @param numTokens Number of tokens in the batch mint
    /// @param baseUri The base uri for the batch, expecting json to be in order, starting at file name 0, and SHOULD NOT have a trailing `/`
    function batchMint(address recipient, uint128 numTokens, string calldata baseUri) external;

    /// @notice Function to airdrop tokens to addresses
    /// @dev Requires owner or admin
    /// @dev Utilizes batch mint token uri values to save some gas but still ultimately mints individual tokens to people
    /// @dev The `baseUri` folder should have the same number of json files in it as addresses in `addresses`
    /// @dev The `baseUri` folder should have files named without any file extension
    /// @param addresses Dynamic array of addresses to mint to
    /// @param baseUri The base uri for the batch, expecting json to be in order, starting at file name 0, and SHOULD NOT have a trailing `/`
    function airdrop(address[] calldata addresses, string calldata baseUri) external;

    /// @notice Function to allow an approved mint contract to mint
    /// @dev Requires the caller to be an approved mint contract
    /// @param recipient The recipient of the token - assumed as able to receive 721 tokens
    /// @param uri The token uri to mint
    function externalMint(address recipient, string calldata uri) external;

    /// @notice Function to burn a token
    /// @dev Caller must be approved or owner of the token
    /// @param tokenId The token to burn
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

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
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

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
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
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
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///
/// @dev Interface for the NFT Royalty Standard
///
interface IEIP2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param tokenId The NFT asset queried for royalty information
    /// @param salePrice The sale price of the NFT asset specified by tokenId
    /// @return receiver Address of who should be sent the royalty payment
    /// @return royaltyAmount The royalty payment amount for salePrice
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}