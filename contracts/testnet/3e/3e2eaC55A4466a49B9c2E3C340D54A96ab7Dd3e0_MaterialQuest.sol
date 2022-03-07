// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./QuestBase.sol";

/// @dev Farmland - Materials Quest Smart Contract
contract MaterialQuest is QuestBase {

// CONSTRUCTOR

    constructor(
        address[5] memory farmlandAddresses,                                                                    // Load key contract addresses
        uint256 price,
        uint256 duration,
        uint256 maxNumberQuests
    ) {
            require(farmlandAddresses.length == 5,                                                             "Invalid number of contract addresses");
            require(farmlandAddresses[0] != address(0),                                                        "Invalid Corn Contract address");
            require(farmlandAddresses[2] != address(0),                                                        "Invalid Land Contract address");
            cornContract = IERC777(farmlandAddresses[0]);                                                      // Define the ERC777 Corn Contract
            farmlandCharacters = IFarmlandCollectible(farmlandAddresses[1]);                                   // Define the ERC721 Character Contract
            landContract = IERC777(farmlandAddresses[2]);                                                      // Define the ERC777 Land Contract
            farmlandItems = IFarmlandItems(farmlandAddresses[3]);                                              // Define the ERC1155 Items Contract 
            characterBackpack = ICharacterBackpack(farmlandAddresses[4]);                                      // Define the Items Manager Contract 
            questPrice = price;
            questDuration = duration;
            maxNumberOfQuestsBase = maxNumberQuests;
    }


// SETTERS

    /// @dev PUBLIC: Quest for items
    /// @param tokenID Characters ID
    /// @param questLength 1-7 duration
    function beginQuest(uint256 tokenID, uint256 questLength)
        external
        nonReentrant
        onlyExplorerAvailable(tokenID)
        onlyQuestComplete(tokenID)
    {
        (,uint256 characterIndex) = getCharactersIndex(_msgSender(),tokenID);                  // Find the characters index
        uint256 stamina = ownerOfExplorers[_msgSender()][characterIndex].stamina;              // Store the characters stamina in a local variable
        require ( questLength <= maxNumberOfQuestsBase + maxNumberOfQuestsBase * (stamina/100),"Exceeds maximum quest duration");
        uint256 speed = ownerOfExplorers[_msgSender()][characterIndex].speed;                  // Store the characters speed in a local variable
        uint256 speedModifier = 0;                                                             // Initialize speed modifier in a local variable
        if ( speed < 99) { speedModifier = (((99-speed)*questDuration)/100); }                 // Calculate how many additional blocks to add to duration based on speed stat
        latestQuest[tokenID] = latestQuest[tokenID] + 1;                                       // Update quest number
        uint256 cornAmount = questLength * questPrice;                                         // Calculate the amount of Corn required
        uint256 endBlock = block.number + ((questDuration + speedModifier) * questLength);     // Calculate when the quest completes
        charactersQuest[tokenID].questLength = questLength;                                    // Set the Quest length
        charactersQuest[tokenID].endBlock = endBlock;                                          // Set block number for when quest completes
        emit QuestStarted(_msgSender(), latestQuest[tokenID], endBlock, tokenID);              // Write an event
        cornContract.operatorBurn(_msgSender(), cornAmount, "", "");                           // Call the ERC-777 Operator burn, requires user to authorize operator first (this will destroy a corn in your wallet).
    }

    /// @dev PUBLIC: Complete the quest
    /// @param tokenID Characters ID
    function completeQuest(uint256 tokenID)
        external
        nonReentrant
        onlyExplorerAvailable(tokenID)
        onlyQuestExpired(tokenID)
    {
        require (items.length > 0,                                                                           "ADMIN: No items registered");
        uint256 amountOfLandFound = 0;
        uint256 currentQuest = latestQuest[tokenID];
        (,uint256 characterIndex) = getCharactersIndex(_msgSender(),tokenID);                                // Find the characters index
        uint256 questLength = charactersQuest[tokenID].questLength;                                          // Store the questLength in a local variable
        charactersQuest[tokenID].questLength = 0;                                                            // Reset the Quest length
        charactersQuest[tokenID].endBlock = 0;                                                               // Reset end of the quest
        uint256 intelligence = ownerOfExplorers[_msgSender()][characterIndex].intelligence;                  // Store the characters intelligence in a local variable
        Item[] memory rewardItems = getItemsByType(rewardItemType);                                          // Retrieve the list of rewards items
        for(uint256 i=0; i < questLength; i++) {                                                             // Loop through the quest and mint items
            uint256 itemToMint = rewardItems[getRandomNumber() % rewardItems.length].itemID;                 // Randomly choose item to mint
            uint256 totalToMint = (getRandomNumber() % rewardItems[itemToMint].scarcity);                    // Random number capped @ item scarcity
            if (totalToMint == 0) { totalToMint = 1;}                                                        // Ensure the minimum mint is 1
            itemsReceived.push(ItemReceived(currentQuest, tokenID, itemToMint, totalToMint, _msgSender()));  // Add the items received
            farmlandItems.mintItem(itemToMint, totalToMint, _msgSender());                                   // Mint Ticket Tokens
        }
        if (getRandomNumber() % 100 < 5) {                                                                   // Land is found if the random number is less 5 .. ie. 5% chance of finding Land           
            amountOfLandFound = (getRandomNumber() % intelligence) * (10**18);                               // You found between 0 and max 98 (capped at the average of courage & intelligence)
            if (landContract.balanceOf(address(this)) > amountOfLandFound) {                                 // Ensure there is enough Land left in the contract
                landContract.operatorSend(address(this),_msgSender(),amountOfLandFound,"","");               // Call the ERC-777 Operator Send to send Land to the Search Party Wallet.
            }
        }
        emit QuestCompleted(_msgSender(), currentQuest, tokenID, amountOfLandFound );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/interfaces/IERC1820Registry.sol";

abstract contract ERC777Holder is IERC777Recipient {
    
    IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    
    constructor() {
        ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    function _tokensReceived(IERC777 token, uint256 amount, bytes memory data) internal virtual;
    function _canReceive(address token) internal virtual {}

    function tokensReceived(
        address /*operator*/,
        address /*from*/,
        address /*to*/,
        uint256 amount,
        bytes calldata userData,
        bytes calldata /*operatorData*/
    ) external virtual override {
        _canReceive(msg.sender);
        _tokensReceived(IERC777(msg.sender), amount, userData);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ItemReceived {uint256 quest; uint256 tokenID; uint256 itemID; uint256 amount; address account;}
struct Character {uint256 tokenID; uint256 addedBlockNumber; uint256 stamina; uint256 strength; uint256 speed; uint256 courage; uint256 intelligence;}
struct Quest {uint256 questLength; uint256 endBlock;}
struct Item {uint256 itemID; uint256 itemType; uint256 scarcity;}

/**
 * @dev Farmland - Quests Interface
 */
interface IFarmlandQuests {

// SETTERS
    function addExplorer(uint256 tokenID) external;
    function releaseExplorer(uint256 index) external;
    function beginQuest(uint256 tokenID, uint256 questLength) external;
    function completeQuest(uint256 tokenID) external;

// ADMIN FUNCTIONS
    function addLand(uint256 amount) external;
    function registerItem(uint256 itemID) external;
    function deregisterItem(uint256 index) external;
    function setFarmlandAddresses(address cornAddress, address landAddress) external;
    function isPaused(bool value) external;
    function withdrawToken() external;

// GETTERS
    function getRandomNumber() external returns (uint256 randomNumber);
    function getCharactersCurrentQuest(uint256 tokenID) external view returns (uint256 charactersCurrentQuest);
    function getCharactersIndex(address account, uint256 tokenID) external view returns (bool exists, uint256 charactersIndex);
    function getItemsByType(uint256 itemType) external view returns (Item[] memory itemsByType);
    function getCharactersItemsReceived(uint256 tokenID) external view returns (ItemReceived[] memory charactersItemsReceived);
    function getCharactersByAccount(address account) external view returns ( Character[] memory explorers);
    function getRemainingBlocksInQuest(uint256 tokenID) external view returns ( uint256 blocksRemaining);
    function getFarmlandAddresses() external view returns ( address, address, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFarmlandItems {
    function mintItem(uint256 itemID, uint256 amount, address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

struct CollectibleTraits {uint256 expiryDate; uint256 trait1; uint256 trait2; uint256 trait3; uint256 trait4; uint256 trait5;}

abstract contract IFarmlandCollectible is IERC721 {

    /**
     * @dev PUBLIC: Stores the key traits for Farmland Collectibles
     */
    mapping(uint256 => CollectibleTraits) public collectibleTraits;

    function setCollectibleSlot(uint256 id, uint256 slotIndex, uint256 slot) external virtual;
    function walletOfOwner(address account) external view virtual returns(uint256[] memory tokenIds);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICharacterBackpack {
    function getItemsByCharacter(uint256 characterID) external view returns (uint256[] memory items);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC777.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./utils/ERC777Holder.sol";
import "./interfaces/IFarmlandQuests.sol";
import "./interfaces/IFarmlandCollectible.sol";
import "./interfaces/IFarmlandItems.sol";
import "./interfaces/ICharacterBackpack.sol";

/// @dev Farmland - Base Quests Smart Contract
contract QuestBase is ERC777Holder, ERC721Holder, ReentrancyGuard, Ownable, Pausable {

// MODIFIERS

    /// @dev Your character can't be on a quest
    /// @param tokenID of character
    modifier onlyQuestExpired(uint256 tokenID) {
        require (getRemainingBlocksInQuest(tokenID) == 0,"Explorer still on a quest");
        _; // Call the actual code
    }  

    /// @dev Check if the character has been added as an explorer
    /// @param tokenID of character
    modifier onlyExplorerAvailable(uint256 tokenID) {
        (bool exists,) = getCharactersIndex(_msgSender(),tokenID);
        require (exists,                                 "You need to add an explorer");
        _; // Call the actual code
    }

    /// @dev Check if the character has been added as an explorer
    /// @param tokenID of character
    modifier onlyQuestComplete(uint256 tokenID) {
        (bool exists,) = getCharactersIndex(_msgSender(),tokenID);
        require (charactersQuest[tokenID].endBlock == 0, "Explorer needs to complete quest");
        _; // Call the actual code
    }

// STATE VARIABLES

    /// @dev This is the Corn contract
    IERC777 internal cornContract;
    
    /// @dev This is the Land contract
    IERC777 internal landContract;
    
    /// @dev This is the Farmland Character contract
    IFarmlandCollectible internal farmlandCharacters;

    /// @dev The Farmland Items contract
    IFarmlandItems internal farmlandItems;

    /// @dev The Farmland Items Manager contract
    ICharacterBackpack internal characterBackpack;

    /// @dev PUBLIC: Initialise the nonce used to pseudo random numbers
    uint256 private randomNonce;

    /// @dev PUBLIC: List of items that are available for minting
    Item[] public items;
    
    /// @dev PUBLIC: Create an array of items received
    ItemReceived[] public itemsReceived;

    /// @dev PUBLIC: Create a mapping between the owners & a list of Characters for Explorers
    mapping(address => Character[]) public ownerOfExplorers;

    /// @dev PUBLIC: Create a mapping between characters & their quests
    mapping(uint256 => Quest) public charactersQuest;
   
    /// @dev PUBLIC: Create an mapping to track a characters latest quest
    mapping(uint256 => uint256) public latestQuest;
    
    /// @dev PUBLIC: Duration of a single quest
    uint256 public questDuration;
    
    /// @dev PUBLIC: Maximum number of quests
    uint256 public maxNumberOfQuestsBase;

    /// @dev PUBLIC: Price in Corn for a quest
    uint256 public questPrice;

    /// @dev PUBLIC : Set reward item type
    uint256 public rewardItemType = 0;                                                               

// EVENTS

    event CharacterAdded(address sender, uint256 blockNumber, uint256 tokenID);
    event CharacterReleased(address sender, uint256 blockNumber, uint256 tokenID);
    event QuestStarted(address sender, uint256 quest, uint256 endblockNumber, uint256 tokenID);
    event QuestCompleted(address sender, uint256 quest, uint256 tokenID, uint256 landClaimed );

// SETTERS

    /// @dev PUBLIC: Add an NFT to the contract
    function addExplorer(uint256 tokenID)
        external
        whenNotPaused
        nonReentrant
    {
         
        (,uint256 stamina, uint256 strength, uint256 speed, uint256 courage, 
          uint256 intelligence) = farmlandCharacters.collectibleTraits(tokenID);                           // Retrieve Explorer stats
        // uint256[] memory equippedItems = characterBackpack.getItemsByCharacter(tokenID);                // Retrieve any items that are equipped for this character
        // uint256 totalEquippedItems = equippedItems.length; // Probably going to need multiple equipped items
        ownerOfExplorers[_msgSender()].push(Character(tokenID, block.number, stamina,
                                                      strength, speed, courage, intelligence));            // Add details to Character Struct
        emit CharacterAdded(_msgSender(),block.number,tokenID);                                            // Write an event to the chain
        farmlandCharacters.safeTransferFrom(_msgSender(),address(this),tokenID);                           // Receive the Character from the owner
    }
    
    /// @dev PUBLIC: Release an NFT from the contract
    /// @param tokenID the id of the NFT to release
    function releaseExplorer(uint256 tokenID)
        external
        nonReentrant
        onlyExplorerAvailable(tokenID)
        onlyQuestComplete(tokenID)
        {
        (,uint256 characterIndex) = getCharactersIndex(_msgSender(),tokenID);                                                       // Find the characters index
        ownerOfExplorers[_msgSender()][characterIndex] = ownerOfExplorers[_msgSender()][ownerOfExplorers[_msgSender()].length - 1]; // In the characters array swap the last item for the item being released
        ownerOfExplorers[_msgSender()].pop();                                                                                       // Delete the final item in the characters array
        emit CharacterReleased(_msgSender(), block.number, tokenID);                                                                // Write an event to the chain
        farmlandCharacters.safeTransferFrom(address(this),_msgSender(),tokenID);                                                    // Return Character to the address that is calling this function.
    }

// ADMIN FUNCTIONS

    /// @dev Add Land the contract
    /// @param amount amount to add
    function addLand(uint256 amount)
        external
        onlyOwner
    {
        IERC777(landContract).operatorSend(_msgSender(), address(this), amount , "", "");  // Call the ERC-777 Operator Send to add Land to the contract.
    }
   
    /// @dev Register items
    /// @param itemID ItemID
    /// @param itemType Item Type e.g., Raw Material etc.
    /// @param itemScarcity Determines how scarce an item is
    function registerItem(uint256 itemID, uint256 itemType, uint256 itemScarcity)
        external
        onlyOwner
        {
            items.push(Item(itemID, itemType, itemScarcity));
        }

    /// @dev Deregister items for minting as rewards
    /// @param index index of item in array
    function deregisterItem(uint256 index)
        external
        onlyOwner
    {
        items[index] = items[items.length - 1];   // In the items array swap the last item for the item being removed
        items.pop();                              // Delete the final item in the items array
    }

    function setFarmlandAddresses(
            address cornAddress,
            address landAddress,
            address characterAddress,
            address farmlandItemAddress,
            address characterBackPackAddress
        ) 
        external 
        onlyOwner
    {
        if ( cornAddress != address(0) && cornAddress != address(IERC777(cornContract)) ) { cornContract = IERC777(cornAddress);}
        if ( landAddress != address(0) && landAddress != address(IERC777(landContract)) ) { landContract = IERC777(landAddress);}
        if ( characterAddress != address(0) && characterAddress != address(IFarmlandCollectible(farmlandCharacters)) ) { farmlandCharacters = IFarmlandCollectible(characterAddress);}
        if ( farmlandItemAddress != address(0) && farmlandItemAddress != address(IFarmlandItems(farmlandItems)) ) { farmlandItems = IFarmlandItems(farmlandItemAddress);}
        if ( characterBackPackAddress != address(0) && characterBackPackAddress != address(ICharacterBackpack(characterBackpack)) ) { characterBackpack = ICharacterBackpack(characterBackPackAddress);}
    }

    /// @dev Start or pause the contract
    function isPaused(bool value) public onlyOwner {
        if ( !value ) {
            _unpause();
        } else {
            _pause();
        }
    }

// GETTERS

    /// @dev INTERNAL: Generates a random number to choose a winner
    function getRandomNumber()
        internal
        returns (uint256 randomNumber)
    {
        randomNonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randomNonce)));
    }

    /// @dev Check a array for characters index
    /// @param account address to check for character
    /// @param tokenID Characters ID
    function getCharactersIndex(address account, uint256 tokenID)
        public
        view
        returns (
            bool exists,
            uint256 charactersIndex)
    {
        uint256 total = ownerOfExplorers[account].length;            // Get the total explorers
        for(uint256 i=0; i < total; i++){                            // Loop through the items in the array
            if (tokenID == ownerOfExplorers[account][i].tokenID)     // Check if we get a match on token ID
            {
                charactersIndex = i;                                 // return the index
                exists = true;                                       // return true
            }
        }
    }

    /// @dev Retrieve List of reward Items
    /// @param itemType Item Type e.g., Raw Material etc.
    function getItemsByType(uint256 itemType)
        public
        view
        returns (Item[] memory itemsByType)                                 // Define the array of items to be returned.        
        {
        uint256 total = items.length;                                       // Store the total items in a local variable
        uint256 totalWithItemType = 0;
        if ( total == 0 ) {
            return new Item[](0);                                           // Return an empty array
        } else {
            for(uint256 i = 0; i < total; i++){                             // Loop through the draws
                if ( items[i].itemType == itemType )
                {
                        totalWithItemType++;                                // increment unclaimedTotal
                    }
            }
            uint256 index = 0;
            Item[] memory _itemsByType = new Item[](totalWithItemType);
                for(uint256 i = 0; i < total; i++){                         // Loop through the draws
                    if ( items[i].itemType == itemType )
                        {
                            _itemsByType[index] = items[i];                // Add item to array
                            index++;
                        }
                }
        return _itemsByType;
        }
    }

    /// @dev Return an array for characters items received
    /// @param tokenID Characters ID
    function getCharactersItemsReceived(uint256 tokenID, address account)
        external
        view
        returns (ItemReceived[] memory charactersItemsReceived)                    // Define the array of items to be returned.

        {
        uint256 total = itemsReceived.length;
        uint256 totalWithTokenID = 0;
        if ( total == 0 ) {
            return new ItemReceived[](0);                                           // Return an empty array
        } else {
            for(uint256 i = 0; i < total; i++){                                     // Loop through the draws
                if(itemsReceived[i].tokenID == tokenID &&                           // Where tokenID & account matc
                   itemsReceived[i].account == account)
                {
                        totalWithTokenID++;                                        // increment unclaimedTotal
                    }
            }
            uint256 index = 0;
            ItemReceived[] memory _charactersItemsReceived = new ItemReceived[](totalWithTokenID);
                for(uint256 i = 0; i < total; i++){                                 // Loop through the draws
                    if(itemsReceived[i].tokenID == tokenID &&                           // Where tokenID & account matc
                    itemsReceived[i].account == account)
                        {
                            _charactersItemsReceived[index] = itemsReceived[i];     // Add item to return array
                            index++;
                        }
                }
        return _charactersItemsReceived;
        }
    }

    /// @dev Return a list of characters by account
    /// @param account account to check
    function getCharactersByAccount(address account)
        external
        view
        returns (
            Character[] memory explorers    // Define the array of Characters to be returned.
        )
    {
        return ownerOfExplorers[account];   // Return the array of collectibles on the farm
    }

    /// @dev PUBLIC: Blocks remaining in quest, returns 0 if finished
    /// @param tokenID Characters ID
    function getRemainingBlocksInQuest(uint256 tokenID)
        public
        view
        returns (
                uint256 blocksRemaining
        )
    {
        uint256 endBlock = charactersQuest[tokenID].endBlock;
        if (endBlock > block.number) {
            return endBlock - block.number;
        }
    }

    /// @dev PUBLIC: Get key Farmland Party addresses
    function getFarmlandAddresses()
        external
        view
        returns (
                address cornAddress,
                address characterAddress,
                address landAddress,
                address farmlandItemsAddress,
                address characterBackpackAddress
        )
    {
        return (
                address(cornContract),
                address(farmlandCharacters),
                address(landContract),
                address(farmlandItems),
                address(characterBackpack)
        );
    }

  function _tokensReceived(IERC777 token, uint256 amount, bytes memory) internal view override {
    require(amount > 0,                    "You must receive a positive number of tokens");
    require(_msgSender() == address(token),"The contract can only recieve Corn or Land tokens");
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC777.sol)

pragma solidity ^0.8.0;

import "../token/ERC777/IERC777.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1820Registry.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC1820Registry.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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