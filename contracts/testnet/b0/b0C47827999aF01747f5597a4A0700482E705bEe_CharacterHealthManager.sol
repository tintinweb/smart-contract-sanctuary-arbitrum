// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../WrappedCharacters/interfaces/IWrappedCharacters.sol";
import "../items/interfaces/IItems.sol";
import "../items/interfaces/IItemSets.sol";

contract CharacterHealthManager is ReentrancyGuard {

    constructor (
          address itemsContractAddress,
          address characterAddress,
          address itemSetsAddress
        )
        {
            require(itemsContractAddress != address(0), "Invalid Items Contract address");
            require(characterAddress != address(0),     "Invalid Character Contract address");
            require(itemSetsAddress != address(0),      "Invalid Item Sets Contract address");
            itemsContract = IItems(itemsContractAddress);
            characterContract = IWrappedCharacters(characterAddress);
            itemSetsContract = IItemSets(itemSetsAddress);
        }

// STATE VARIABLES
   
    /// @dev This is the Wrapped Character contract
    IWrappedCharacters private characterContract;

    /// @dev The Farmland Items contract
    IItems private itemsContract;

    /// @dev The Farmland Items Sets contract
    IItemSets private itemSetsContract;

// MODIFIERS

    /// @dev Character can't be active
    /// @param tokenID of character
    modifier onlyInactive(uint256 tokenID) {
        require (characterContract.getBlocksUntilActivityEnds(tokenID) == 0,"Explorer still active");
        _; // Call the actual code
    }  

    /// @dev Restore characters health with an item
    /// @param tokenID Characters ID
    /// @param itemSet item Set
    /// @param itemID item ID
    function restoreHealth(uint256 tokenID, uint256 itemSet, uint256 itemID)
        external
        nonReentrant
        onlyInactive(tokenID)
    {
        require( itemsContract.balanceOf(msg.sender,itemID) > 0,                                    "You don't have that item in your wallet");
        uint256 healthItemType = itemsContract.getItemType('Health');                               // Retrieve Item Types
        Item[] memory healthItems = itemSetsContract.getItemsBySetAndType(itemSet, healthItemType); // Retrieve all the health items
        uint256 total = healthItems.length;                                                         // Grab the number of useful items to loop through
        require( total > 0,                                                                         "No health items registered");
        for(uint256 i = 0; i < total; i++){                                                         // Loop through the items
            if (itemID == healthItems[i].itemID) {                                                  // Check for the specific health item
                // characterContract.increaseHealth(tokenID, uint16(healthItems[i].value1));           // Increase the health
                characterContract.increaseStat(tokenID, uint16(healthItems[i].value1),5);           // Increase the health
                itemsContract.burn(msg.sender, itemID, healthItems[i].value2);                      // Burn the health item(s)
                break;
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

/// @dev Defines the ItemType struct
struct ItemType {
    uint256 maxSupply;
    string name;
    string description;
    string imageUrl;
    string animationUrl;
    bool mintingActive;
    uint256 rarity;
    uint256 itemType;
    uint256 value1;
}

abstract contract IItems is IERC1155 {
    mapping(uint256 => ItemType) public items;
    function mintItem(uint256 itemID, uint256 amount, address recipient) external virtual;
    function mintItems(uint256[] memory itemIDs, uint256[] memory amounts, address recipient) external virtual;
    function burn(address account,uint256 id,uint256 value) external virtual;
    function burnBatch(address account,uint256[] memory ids,uint256[] memory values) external virtual;
    function totalSupply(uint256 id) public view virtual returns (uint256);
    function exists(uint256 id) public view virtual returns (bool);
    function getItemTypes() public view virtual returns (string[] memory allItemTypes);
    function getItemType(string memory itemTypeName) public view virtual returns (uint256 itemType);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Item {uint256 itemID; uint256 itemType; uint256 itemSet; uint256 rarity; uint256 value1; uint256 value2;}

/// @dev Farmland - Items Sets Smart Contract
abstract contract IItemSets {

    Item[] public items;
    mapping (uint256 => mapping (uint256 => uint256[5])) public countsBySetTypeAndRarity;
    mapping(uint256 => uint256[5]) public countsBySetAndRarity;
    mapping(uint256 => uint256) public totalItemsInSet;

    function getItems() external view virtual returns (Item[] memory allItems);
    function getItemsBySet(uint256 itemSet) external view virtual returns (Item[] memory itemsBySet);
    function getItemsBySetAndType(uint256 itemSet, uint256 itemType) external view virtual returns (Item[] memory itemsBySetAndType);
    function getItemSetByTypeAndRarity(uint256 itemSet, uint256 itemType, uint256 itemRarity) external view virtual returns (Item[] memory itemsByRarityAndType);
    function getItemSetByRarity(uint256 itemSet, uint256 itemRarity) external view virtual returns (Item[] memory itemSetByRarity);
    function getItemCountBySet(uint256 itemSet) external view virtual returns (uint256[5] memory itemCountBySet);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct Activity {bool active; uint16 numberOfActivities; uint256 activityDuration; uint256 startBlock; uint256 endBlock;}
struct UnderlyingToken {address collectionAddress; uint256 tokenID;}
struct Collection {address collectionAddress; bool native;}

abstract contract IWrappedCharacters is IERC721 {
    mapping(bytes32 => uint16[]) internal stats;
    mapping (uint256 => Activity) public charactersActivity;
    mapping (bytes32 => UnderlyingToken) public underlyingToken;
    mapping (uint256 => bytes32) public wrappedCharacters;
    function wrap(uint256 tokenID, address collectionAddress) external virtual;
    function unwrap(uint256 wrappedTokenID) external virtual;
    function setActive(uint256 wrappedTokenID, bool active) external virtual;
    function setBeginActivity(uint256 wrappedTokenID, uint256 activityDuration, uint16 NumberOfActivities, uint256 startBlock, uint256 endBlock) external virtual;
    function setHealthTo(uint256 wrappedTokenID, uint16 amount) external virtual;
    // function increaseHealth(uint256 wrappedTokenID, uint16 amount) external virtual;
    // function decreaseHealth(uint256 wrappedTokenID, uint16 amount) external virtual;
    function increaseStat(uint256 wrappedTokenID, uint16 amount, uint256 statIndex) external virtual;
    function decreaseStat(uint256 wrappedTokenID, uint16 amount, uint256 statIndex) external virtual;
    function calculateHealth(uint256 wrappedTokenID) external virtual view returns (uint16 health);
    function getBlocksUntilActivityEnds(uint256 wrappedTokenID) external virtual view returns (uint256 blocksRemaining);
    function getBlocksToMaxHealth(uint256 wrappedTokenID) external virtual view returns (uint256 blocks);
    function getMaxHealth(uint256 wrappedTokenID) external virtual view returns (uint16 health);
    function getStats(uint256 wrappedTokenID) external virtual view returns (uint16 stamina, uint16 strength, uint16 speed, uint16 courage, uint16 intelligence, uint16 health, uint16 experience, uint16 level);
    function hashUnderlyingToken(address collectionAddress, uint256 tokenID) external virtual pure returns (bytes32 underlyingTokenHash);
    function UnderlyingTokenExists(address collectionAddress, uint256 tokenID) external virtual view returns (bool tokenExists);
    function getCharactersID(uint256 wrappedTokenID) external virtual view returns (address collectionAddress, uint256 tokenID);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";