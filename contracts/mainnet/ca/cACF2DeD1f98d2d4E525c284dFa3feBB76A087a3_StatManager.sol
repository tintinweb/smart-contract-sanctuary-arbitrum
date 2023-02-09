// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IWrappedCharacters.sol";
import "../items/interfaces/IItems.sol";
import "../items/interfaces/IItemSets.sol";

contract StatManager is ReentrancyGuard {

    constructor (
          address itemsAddress,
          address mercenariesAddress,
          address itemSetsAddress
        )
        {
            require(itemsAddress != address(0), "Invalid Items Contract address");
            require(mercenariesAddress != address(0), "Invalid Mercenary Contract address");
            require(itemSetsAddress != address(0), "Invalid Item Sets Contract address");
            items = IItems(itemsAddress);
            mercenaries = IWrappedCharacters(mercenariesAddress);
            itemSets = IItemSets(itemSetsAddress);
        }

// STATE VARIABLES
   
    /// @dev This is the Wrapped Character contract
    IWrappedCharacters private mercenaries;

    /// @dev The Farmland Items contract
    IItems private items;

    /// @dev The Farmland Items Sets contract
    IItemSets private itemSets;

// MODIFIERS

    /// @dev Check if the explorer is inactive
    /// @param tokenID of explorer
    modifier onlyInactive(uint256 tokenID) {
        // Get the explorers activity
        (bool active,,,,,) = mercenaries.charactersActivity(tokenID);
        require (!active, "Explorer needs to complete quest");
        _;
    }

    /// @dev Must be the owner of the character
    /// @param tokenID of character
    modifier onlyOwnerOfToken(uint256 tokenID) {
        require (mercenaries.ownerOf(tokenID) == msg.sender,"Only the owner of the token can perform this action");
        _; // Call the actual code
    }  

    /// @dev Restore characters health with an item
    /// @param tokenID Characters ID
    /// @param itemID item ID
    /// @param total number of items to use
    function restoreHealth(uint256 tokenID, uint256 itemID, uint256 total)
        external
        nonReentrant
        onlyOwnerOfToken(tokenID)
        onlyInactive(tokenID)
    {
        require(items.balanceOf(msg.sender, itemID) >= total, "You don't have that item in your wallet");
        // Return the Item Modifiers values for Health items (21)
        (uint256 amountToIncrease, uint256 amountToBurn) = getItemModifier(21, itemID);
        //Check that the amount to increase is greater than zero, otherwise it's likely the item wasn't found in the set
        require(amountToIncrease > 0,"Item not found in this set");
        // Increase the health (5 = health item)
        mercenaries.increaseStat(tokenID, amountToIncrease*total, 5);  
        // Burn the health item(s)                     
        items.burn(msg.sender, itemID, amountToBurn * total);
    }

    /// @dev Restore characters morale with an item
    /// @param tokenID Characters ID
    /// @param itemID item ID
    /// @param total number of items to use
    function restoreMorale(uint256 tokenID, uint256 itemID, uint256 total)
        external
        nonReentrant
        onlyOwnerOfToken(tokenID)
        onlyInactive(tokenID)
    {
        require(items.balanceOf(msg.sender, itemID) >= total, "You don't have that item in your wallet");
        // Return the Item Modifiers values for Morale items (20)
        (uint256 amountToIncrease, uint256 amountToBurn) = getItemModifier(20, itemID);
        //Check that the amount to increase is greater than zero, otherwise it's likely the item wasn't found in the set
        require(amountToIncrease > 0,"Item not found in this set");
        // Increase the morale (6 = morale item)
        mercenaries.increaseStat(tokenID, amountToIncrease*total, 6);
        // Burn the morale item(s)
        items.burn(msg.sender, itemID, amountToBurn * total);
    }

    /// @dev Swap characters XP for a stat increase
    /// @param tokenID Characters ID
    /// @param amount which stat to increase
    /// @param statIndex amount to increase stat
    function boostStat(uint256 tokenID, uint256[] calldata amount, uint256[] calldata statIndex)
        external
        nonReentrant
        onlyOwnerOfToken(tokenID)
        onlyInactive(tokenID)
    {
        uint256 total = amount.length;
        //Check the array amount match
        require(total == statIndex.length, "The array totals must match");
        // Ensure maximum of 5 
        require(total < 6, "The array total exceeded");
        // Loop through the array
        for (uint256 i = 0; i < total;) {
            // Boost the characters stats
            mercenaries.boostStat(tokenID, amount[i] ,statIndex[i]);
            // Increment counter
            unchecked { ++i; }
        }
    }

// VIEWS

    /// @dev Return the Item Modifiers (value1 & value2)
    /// @param itemSet Item ID in use
    /// @param itemID item ID
    function getItemModifier(uint256 itemSet, uint256 itemID)
        private
        view
        returns (uint256 value1, uint256 value2)
    {
        require(itemSets.getItemSet(itemSet).length > 0,"No items found in this set");
        // Retrieve all the useful items for hazardous quests
        Item[] memory usefulItems = itemSets.getItemSet(itemSet);
        // Loop through the items
        for(uint256 i = 0; i < usefulItems.length;){
            // Check if the items are found and return the modifiers
            if (itemID == usefulItems[i].itemID) {
                value1 = usefulItems[i].value1;
                value2 = usefulItems[i].value2;
                break;
            }
            unchecked { ++i; }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

enum WrappedStatus {NeverWrapped, Wrapped, Unwrapped}
struct Collection {bool native; uint256 range; uint256 offset;}
struct WrappedToken {address collectionAddress; uint256 wrappedTokenID; WrappedStatus status;}
struct Activity {bool active; uint256 numberOfActivities; uint256 activityDuration; uint256 startBlock; uint256 endBlock; uint256 completedBlock;}

abstract contract IWrappedCharacters is IERC721 {
    mapping(bytes32 => uint16[]) public stats;
    mapping (uint256 => Activity) public charactersActivity;
    mapping (bytes32 => WrappedToken) public wrappedToken;
    mapping (uint256 => bytes32) public wrappedTokenHashByID;
    mapping (bytes32 => uint256) public tokenIDByHash;
    mapping(uint256 => uint16) public getStatBoosted;
    function wrap(uint256 wrappedTokenID, address collectionAddress) external virtual;
    function unwrap(uint256 tokenID) external virtual;
    function updateActivityStatus(uint256 tokenID, bool active) external virtual;
    function startActivity(uint256 tokenID, Activity calldata activity) external virtual;
    function setStatTo(uint256 tokenID, uint256 amount, uint256 statIndex) external virtual;
    function increaseStat(uint256 tokenID, uint256 amount, uint256 statIndex) external virtual;
    function decreaseStat(uint256 tokenID, uint256 amount, uint256 statIndex) external virtual;
    function boostStat(uint256 tokenID, uint256 amount, uint256 statIndex)external virtual;
    function getBlocksUntilActivityEnds(uint256 tokenID) external virtual view returns (uint256 blocksRemaining);
    function getMaxHealth(uint256 tokenID) external virtual view returns (uint256 health);
    function getStats(uint256 tokenID) external virtual view returns (uint256 stamina, uint256 strength, uint256 speed, uint256 courage, uint256 intelligence, uint256 health, uint256 morale, uint256 experience, uint256 level);
    function getLevel(uint256 tokenID) external virtual view returns (uint256 level);
    function hashWrappedToken(address collectionAddress, uint256 wrappedTokenID) external virtual pure returns (bytes32 wrappedTokenHash);
    function isWrapped(address collectionAddress, uint256 wrappedTokenID) external virtual view returns (bool tokenExists);
    function getWrappedTokenDetails(uint256 tokenID) external virtual view returns (address collectionAddress, uint256 wrappedTokenID, WrappedStatus status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "./IERC1155Burnable.sol";
import "./IERC1155Supply.sol";

/// @dev Defines the ItemType struct
struct ItemType {
    uint256 itemID;
    uint256 maxSupply;
    string name;
    string description;
    string imageUrl;
    string animationUrl;
    bool mintingActive;
    bool soulbound;
    uint256 rarity;
    uint256 itemType;
    uint256 wearableType;
    uint256 value1;
}

abstract contract IItems is IERC1155, IERC1155Burnable, IERC1155Supply {
    /// @dev A mapping to track items in use by account
    /// @dev getItemsInUse[account].[itemID] = amountOfItemsInUse
    mapping (address => mapping(uint256 => uint256)) public getItemsInUse;

    /// @dev A mapping to track items in use by tokenID
    /// @dev getItemsInUseByToken[tokenID].[itemID] = amountOfItemsInUse
    mapping (uint256 => mapping(uint256 => uint256)) public getItemsInUseByToken;

    function mintItem(uint256 itemID, uint256 amount, address recipient) external virtual;
    function mintItems(uint256[] memory itemIDs, uint256[] memory amounts, address recipient) external virtual;
    function setItemInUse(address account, uint256 tokenID, uint256 itemID, uint256 amount, bool inUse) external virtual;
    function setItemsInUse(address[] calldata accounts, uint256[] calldata tokenIDs, uint256[] calldata itemIDs, uint256[] calldata amounts, bool[] calldata inUse) external virtual;
    function getItem(uint256 itemID) external view virtual returns (ItemType memory item);
    function getItems() external view virtual returns (ItemType[] memory allItems);
    function getActiveItemsByTokenID(uint256 tokenID) external view virtual returns (uint256[] memory itemsByToken);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @param itemID ItemID
/// @param itemSet Used to group items into a set
/// @param rarity Defines the item rarity ... eg., common, uncommon, rare, epic, legendary
/// @param itemValue1 Custom field ... can be used to define quest specific details (eg. item scacity cap, amount of land that can be found with certain items)
/// @param itemValue2 Another custom field ... can be used to define quest specific details (e.g., the amount of an item to burn, potions)
struct Item {uint256 itemID; uint256 itemSet; uint256 rarity; uint256 value1; uint256 value2;}

/// @dev Farmland - Items Sets Interface
interface IItemSets {
    function getItemSet(uint256 itemSet) external view returns (Item[] memory itemsBySet);
    function getItemSetByRarity(uint256 itemSet, uint256 itemRarity) external view returns (Item[] memory itemsBySetAndRarity);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155Supply {
    function totalSupply(uint256 id) external view returns (uint256);
    function exists(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155Burnable {
    function burn(address account,uint256 id,uint256 value) external;
    function burnBatch(address account,uint256[] memory ids,uint256[] memory values) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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