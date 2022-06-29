// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../characters/interfaces/ICharacterActivity.sol";
import "../characters/CharacterStats.sol";
import "./QuestType.sol";

/// @dev Farmland - Quests Smart Contract
contract Quests is QuestType, CharacterStats {

// CONSTRUCTOR

    constructor(
        address[8] memory farmlandAddresses       // Load key contract addresses
        ) QuestType (farmlandAddresses)
          CharacterStats (farmlandAddresses)
    {
        require(farmlandAddresses.length == 8,      "Invalid number of contract addresses");
        require(farmlandAddresses[0] != address(0), "Invalid Corn Contract address");
        require(farmlandAddresses[1] != address(0), "Invalid Character Contract address");
        require(farmlandAddresses[2] != address(0), "Invalid Land Contract address");
        require(farmlandAddresses[3] != address(0), "Invalid Items Contract address");
        require(farmlandAddresses[4] != address(0), "Invalid Slot Manager address");
        require(farmlandAddresses[5] != address(0), "Invalid Character Activity address");
        require(farmlandAddresses[6] != address(0), "Invalid Character Owner address");
        require(farmlandAddresses[7] != address(0), "Invalid Item Sets address");
        characterActivity = ICharacterActivity(farmlandAddresses[5]);
    }

// STATE VARIABLES

    /// @dev This is the Land contract
    ICharacterActivity internal immutable characterActivity;
 
    /// @dev Create an mapping to track a characters latest quest
    mapping(uint256 => uint256) public latestQuest;

// MODIFIERS

    /// @dev Check if the character is inactive
    /// @param tokenID of character
    modifier onlyQuestComplete(uint256 tokenID) {
        // (bool active, uint256 NumberOfActivities, uint256 activityDuration, uint256 startBlock, uint256 endBlock ) = characterActivity.charactersActivity(tokenID); // Shortcut to characters activity
        (bool active,,,,) = characterActivity.charactersActivity(tokenID); // Shortcut to characters activity
        require (!active,                                                  "Explorer needs to complete quest");
        _; // Call the actual code
    }

    /// @dev Check if the character is active
    /// @param tokenID of character
    modifier onlyQuestActive(uint256 tokenID) {
        (bool active,,,,) = characterActivity.charactersActivity(tokenID); // Shortcut to characters activity
        require (active,                                                   "Explorer can only complete quest once");
        _; // Call the actual code
    }

    /// @dev Check if the character has enough health for the quest
    /// @param tokenID of character
    /// @param numberOfQuests how many quests
    modifier onlyIfEnoughHealth(uint256 tokenID, uint256 numberOfQuests) {
        uint256 health = characterActivity.calculateHealth(tokenID);
        characterActivity.setHealthTo(tokenID, health, _msgSender());
        require (health - numberOfQuests > 0, "Explorer needs more health");
        _; // Call the actual code
    }

    /// @dev Character can't be on a quest
    /// @param tokenID of character
    modifier onlyQuestExpired(uint256 tokenID) {
        require (characterActivity.getBlocksUntilActivityEnds(tokenID) == 0, "Explorer still on a quest");
        _; // Call the actual code
    }

// FUNCTIONS

    /// @dev Add a Character to the contract
    /// @param tokenID the id of the Character to release
    function addCharacter(uint256 tokenID)
        external
    {
        if (characterActivity.getCharactersHealth(tokenID) == 0) {
            characterActivity.setInitialHealth(tokenID, _msgSender()); // Set the characters initial health
        }
        _addCharacter(tokenID);                                        // Move character to contract
    }

    /// @dev Release a Character from the contract
    /// @param tokenID the id of the Character to release
    function releaseCharacter(uint256 tokenID)
        external
        onlyIfCharacterAvailable(tokenID)
        onlyQuestComplete(tokenID)
    {
        _releaseCharacter(tokenID);     // Release character from contract
    }

    /// @dev Quest for items
    /// @param questID Quest ID
    /// @param tokenID Characters ID
    /// @param numberOfQuests number of quests in a single transaction
    /// @param includeItem if you want to add an item to help complete the quest
    /// @param itemID of item to equip for quest
    function beginQuest(uint256 questID, uint256 tokenID, uint16 numberOfQuests, bool includeItem, uint256 itemID)
        external
        nonReentrant
        onlyIfCharacterAvailable(tokenID)
        onlyQuestComplete(tokenID)
        onlyIfEnoughHealth(tokenID, numberOfQuests)
        whenNotPaused
    {
        require ( numberOfQuests <= 
                  getCharactersMaxQuests(tokenID, quests[questID].maxNumberOfQuestsBase), "Exceeds maximum quest duration");
        latestQuest[tokenID] = questID;                                                   // Set the quest ID
        setQuestDetails(questID, tokenID, numberOfQuests);
        if ( includeItem ) {
            _addItem(tokenID, itemID, 1);                                                 // Equip an item
        }
        uint256 cornAmount = numberOfQuests * quests[questID].questPrice;                 // Calculate the amount of Corn required
        cornContract.operatorBurn(_msgSender(), cornAmount, "", "");                      // Call the ERC-777 Operator burn, requires user to authorize operator first (this will destroy a corn in your wallet).
    }

    /// @dev Complete the quest
    /// @param questID Quest ID
    /// @param tokenID Characters ID
    function completeQuest(uint256 questID, uint256 tokenID)
        external
        nonReentrant
        onlyIfCharacterAvailable(tokenID)
        onlyQuestExpired(tokenID)
        onlyQuestActive(tokenID)
    {
        require(questID == latestQuest[tokenID],                                            "Character isn't on this quest");
        (,uint256 numberOfActivities,,,) = characterActivity.charactersActivity(tokenID);   // Get the number of activities
        characterActivity.reduceHealth(tokenID, numberOfActivities, _msgSender());          // Update the characters health
        characterActivity.setActive(tokenID, false, _msgSender());                          // Set a variable to indicate that character has returned from a quest
        emit QuestCompleted(_msgSender(), latestQuest[tokenID], block.number, tokenID);     // Write an event
        bool hazardAvoided = checkHazards(questID, tokenID);                                // Checks for hazards
        if (hazardAvoided) {                                                                // Then if hazard avoided mints rewards
            mintReward(questID,  tokenID, numberOfActivities);
        }
        removeItem(tokenID);                                                                // Release the item
    }

    /// @dev Abort quest without collecting items
    /// @param tokenID Characters ID
    function abortQuest(uint256 tokenID)
        external
        nonReentrant
        onlyIfCharacterAvailable(tokenID)
    {
        (,uint256 numberOfActivities,,,) = characterActivity.charactersActivity(tokenID);   // Get the number of activities
        characterActivity.setActive(tokenID, false, _msgSender());                          // Set a variable to indicate that character is on a quest
        characterActivity.reduceHealth(tokenID, numberOfActivities, _msgSender());          // Update the characters health
        emit QuestAborted(_msgSender(), latestQuest[tokenID], block.number, tokenID);       // Write an event
        removeItem(tokenID);                                                                // Release the item
    }

// INTERNAL HELPER FUNCTIONS

    /// @dev Remove an item from a characters inventory at the end of a quest
    /// @param tokenID Characters ID
    function removeItem(uint256 tokenID)
        private
    {
        (uint256 itemID, uint256 amount) = getItemByIndex(tokenID, _msgSender(), 0);      // Check the characters inventory at index 0
        if (amount > 0) {                                                                 // If there's an item in the inventory
            _removeItem(tokenID, itemID);                                                 // Release the item
        }
    }

    /// @dev Set Quest details for quest
    /// @param questID Quest ID
    /// @param tokenID Characters ID
    /// @param numberOfQuests number of quests in a single transaction
    function setQuestDetails(uint256 questID, uint256 tokenID, uint16 numberOfQuests)
        private
    {
        uint256 questDuration = getCharactersQuestDuration(tokenID, quests[questID].questDuration); // Get the modified quest duration for this character
        uint256 endBlock = block.number + (questDuration * numberOfQuests);                         // Set block number for when quest completes
        characterActivity.setBeginActivity(tokenID, questDuration, 
                                            numberOfQuests, block.number, endBlock, _msgSender());  // Update the Quest details
        emit QuestStarted(_msgSender(), latestQuest[tokenID], endBlock, tokenID);                   // Write an event
    }

    /// @dev Checks to see if a hazard has been avoided
    /// @param questID Quest ID
    /// @param tokenID Characters ID
    function checkHazards(uint256 questID, uint256 tokenID)
        private
        returns (bool hazardAvoided)
    {
        bool hazardsEnabled = quests[questID].hazardsEnabled;
        if (!hazardsEnabled) {
            return true;                                                      // If hazards aren't enabled for this quest type, then always return hazard avoided = true 
        } else {
           uint256[] memory randomNumbers = new uint256[](1);
           randomNumbers = getRandomNumbers(1);                               // Return some random numbers
           if (getCharactersBravery(tokenID) > randomNumbers[0] % 100 ) {     // If Hazards are enabled, bravery has to be greater than a random number between 0-100 for the character to avoid the hazard
                    return true;                                              // Returns true if avoided
            }
        }
    }

    /// @dev Mint items found on a quest
    /// @param questID Quest ID
    /// @param tokenID Characters ID
    /// @param numberOfActivities on the quest
    function mintReward(uint256 questID, uint256 tokenID, uint256 numberOfActivities)
        private
    {
        uint256 itemToMint;                                                                                 // Initialise local variable
        uint256 totalToMint;                                                                                // Initialise local variable
        uint256 amountOfLandFound;                                                                          // Initialise local variable
        uint256[] memory randomNumbers = new uint256[](numberOfActivities);                                 // Initialise local variable
        randomNumbers = getRandomNumbers(numberOfActivities);                                               // Return some random numbers
        for(uint256 i=0; i < numberOfActivities; i++) {                                                     // Loop through the quest and mint items
            (itemToMint, totalToMint) = getRewardItem(questID, tokenID);                                    // Calculate the reward
            amountOfLandFound = getLandAmount(questID, tokenID);                                            // Calculate the Land
            itemsContract.mintItem(itemToMint, totalToMint, _msgSender());                                  // Mint reward items
            if (amountOfLandFound > 0 && landContract.balanceOf(address(this)) > amountOfLandFound) {       // Ensure there is enough Land left in the contract
                landContract.operatorSend(address(this),_msgSender(),amountOfLandFound,"","");              // Call the ERC-777 Operator Send to send Land to the Search Party Wallet.
                emit ItemFound(_msgSender(), questID, tokenID, itemToMint, totalToMint, amountOfLandFound); // Write an event for each quest
            }
            else {
                emit ItemFound(_msgSender(), questID, tokenID, itemToMint, totalToMint, 0); // Write an event for each quest
            }
        }
    }    

    /// @dev Return a reward item & amount to mint
    /// @param questID Quest ID
    /// @param tokenID Characters ID
    function getRewardItem(uint256 questID, uint256 tokenID)
        private
        returns (
            uint256 itemToMint,
            uint256 totalToMint
        )
    {
        uint256[] memory randomNumbers = new uint256[](3);
        uint256 questItemSet = quests[questID].itemSet;                                          // Declare & set the pack item set to work from
        randomNumbers = getRandomNumbers(3);                                                     // Return some random numbers
        uint256 random = randomNumbers[0] % 1000;                                                // Choose a random number between 0-999
        uint256 rarityBucket;                                                                    // Initialise local variable
        uint256 rewardItemType = itemsContract.getItemType('Reward');                            // Retrieve Item Types
        uint256 total = itemSetsContract.totalItemsInSet(questItemSet);                          // Initialise to store length of array
        require (total > 0,                                                                      "ADMIN: No items registered");
        for (uint256 i = 0; i < total ; i++) {                                                   // Loop through the array
            if (random > quests[questID].rarityPercentage[i] && 
                itemSetsContract.countsBySetTypeAndRarity(questItemSet,rewardItemType, i) > 0) { // Choose rarity & ensure an item is registered
                rarityBucket = i;                                                                // Set the rarity bucket
                break;                                                                           // Move on
            }
        }
        Item[] memory rewardItems = itemSetsContract.getItemSetByTypeAndRarity(
                                         questItemSet, rewardItemType, rarityBucket);            // Retrieve the list of items
        uint256 itemIndex = randomNumbers[1] % rewardItems.length;                               // Randomly choose item to mint
        itemToMint = rewardItems[itemIndex].itemID;                                              // Finds the items ID
        uint256 strength = getCharactersStrength(tokenID);                                       // Retrieve Explorers Strength modifier
        uint256 scarcity = rewardItems[itemIndex].value1;                                        // Retrieve Items scarcity
        if (scarcity > strength) {                                                               // If the item scarcity is greater than the characters strength
            totalToMint = (randomNumbers[2] % strength);                                         // Choose a random number capped @ characters strength
        } else {
            totalToMint = (randomNumbers[2] % scarcity);                                         // Choose a random number capped @ item scarcity
        }
        if (totalToMint == 0) { totalToMint = 1;}                                                // Ensure at least 1 item is found
    }

    /// @dev Return the amount of Land found
    /// @param questID Quest ID
    /// @param tokenID Characters ID
    function getLandAmount(uint256 questID, uint256 tokenID)
        private
        returns (
            uint256 amountOfLandFound
        )
    {
        uint256 chanceOfFindingLand = quests[questID].chanceOfFindingLand;                 // Set the default chance of finding Land
        Inventory[] storage inventory = ownerOfCharactersInventory[_msgSender()][tokenID]; // Shortcut to characters inventory
        if (inventory.length > 0) {                                                        // If an item is included then check the inventory
            uint256 questItemSet = quests[questID].itemSet;                                // Declare & set the item set to work from
            uint256 equipItemType = itemsContract.getItemType('Equip');                    // Retrieve Item Types
            Item[] memory usefulItems = 
                itemSetsContract.getItemsBySetAndType(questItemSet, equipItemType);        // Retrieve all the useful items
            uint256 total = usefulItems.length;                                            // Grab the number of useful items to loop through
            for(uint256 i = 0; i < total; i++){                                            // Loop through the items
                (bool inInventory,) = getItemIndexFromInventory(
                                tokenID, usefulItems[i].itemID, _msgSender());             // Determine if the item is in inventory
                if (inInventory) {                                                         // If in inventory
                    (,,,,chanceOfFindingLand,) =
                        itemSetsContract.items(usefulItems[i].itemID);                     // Set the chance of finding land with an equipped item
                    break;                                                                 // To break out of the loop early if an item is found
                }
            }
        }
        uint256[] memory randomNumbers = new uint256[](2);
        randomNumbers = getRandomNumbers(2);                                              // Return some random numbers
        if (randomNumbers[0] % 100 < chanceOfFindingLand) {                               // Land is found if the random number is less than the chance of finding Land
            amountOfLandFound = ((randomNumbers[1] % 
                                getCharactersBravery(tokenID)) +1) * (10**18);            // You found between 1 and max 99 (capped at the characters of bravery )
        }
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

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/ERC777Holder.sol";
import "../interfaces/ICornV2.sol";
import "../items/interfaces/IItemSets.sol";

struct Quest { 
    string name;                                    // The name of the quest
    uint256[5] rarityPercentage;                    // The percentage chance of getting items [common % ,uncommon %, rare %, epic %, legendary %]
    uint256 itemSet;                                // The list of items supported by the quest
    uint256 questPrice;                             // Price of the quest, to be burned if payment address is empty
    uint256 chanceOfFindingLand;                    // Base chance of finding Land before item boosts
    address paymentAddress;                         // Zero address is a free mint
    uint256 questDuration;                          // Duration of a single quest in blocks
    uint256 maxNumberOfQuestsBase;                  // Maximum number of quests before character boosts
    bool hazardsEnabled;                            // Are hazards enabled
    bool active;                                    // Status (Active/Inactive)
    }

/// @dev Farmland - Quest Type Smart Contract
contract QuestType is ERC777Holder, Ownable {
    using SafeERC20 for IERC20;

// CONSTRUCTOR

    constructor (
        address[8] memory farmlandAddresses             // Load key contract addresses
        ) {
            require(farmlandAddresses.length == 8,      "Invalid number of contract addresses");
            require(farmlandAddresses[0] != address(0), "Invalid Corn Contract address");
            require(farmlandAddresses[2] != address(0), "Invalid Land Contract address");
            require(farmlandAddresses[7] != address(0), "Invalid Item Sets Contract address");
            cornContract = ICornV2(farmlandAddresses[0]);
            landContract = IERC777(farmlandAddresses[2]);
            itemSetsContract = IItemSets(farmlandAddresses[7]);
        }

// STATE VARIABLES

    /// @dev This is the Land contract
    ICornV2 internal immutable cornContract;

    /// @dev This is the Land contract
    IERC777 internal immutable landContract;

    /// @dev The Farmland Item Sets contract
    IItemSets internal immutable itemSetsContract;

    /// @dev Create a mapping to track each type of quest
    mapping(uint256 => Quest) public quests;

    /// @dev Tracks the last Quest ID
    uint256 public lastQuestID;

    /// @dev Initialise the nonce used to pseudo random numbers
    uint256 private randomNonce;
  
// MODIFIERS

    /// @dev Check if quest enabled
    modifier onlyWhenQuestEnabled(uint256 questID) {
        require (quests[questID].active, "Quest inactive");
        _; // Call the actual code
    }

    /// @dev Check if quest enabled
    modifier onlyWhenQuestExists(uint256 questID) {
        require (questID <= lastQuestID, "Uknown Quest");
        _; // Call the actual code
    }

// EVENTS

    event QuestStarted(address indexed account, uint256 quest, uint256 endblockNumber, uint256 indexed tokenID);
    event QuestCompleted(address indexed account, uint256 quest, uint256 endblockNumber, uint256 indexed tokenID);
    event QuestAborted(address indexed account, uint256 quest, uint256 endblockNumber, uint256 indexed tokenID);
    event ItemFound(address indexed account, uint256 quest, uint256 indexed tokenID, uint256 itemMinted, uint256 amountMinted, uint256 amountOfLandFound);

// ADMIN FUNCTIONS

    /// @dev Create a quest & set the rarity percentage
    /// @param name the quest
    /// @param itemSet set the item set available for quest rewards
    /// @param questPrice set the questPrice for the quest
    /// @param paymentAddress set the contract for quest payment
    /// @param chanceOfFindingLand set the base chance of finding land for this quest
    /// @param maxNumberOfQuestsBase Maximum number of quests before character boosts
    /// @param questDuration Duration of a single quest in blocks
    /// @param hazardsEnabled set the status of the quest
    /// @param active set the status of the quest
    /// @param rarityPercentages an array of the rarity percentage for item distribution eg [400, 150, 50, 10, 0]
    function createQuest(string calldata name, uint256 itemSet, uint256 questPrice, address paymentAddress, uint256 chanceOfFindingLand, uint256 questDuration, uint256 maxNumberOfQuestsBase, bool hazardsEnabled, bool active, uint256[5] calldata rarityPercentages)
        external
        onlyOwner
    {
        require(rarityPercentages.length == 5,                       "Requires 5 rarity values");
        Quest storage quest = quests[lastQuestID];                   // Shortcut accessor for the quest
        quest.name = name;                                           // Set the name
        quest.itemSet = itemSet;                                     // Set the item set
        quest.questPrice = questPrice;                               // Set the questPrice
        quest.paymentAddress = paymentAddress;                       // Set the payment contract
        quest.chanceOfFindingLand = chanceOfFindingLand;             // Set the merkle root
        quest.questDuration = questDuration;                         // Set base quest duration
        quest.maxNumberOfQuestsBase = maxNumberOfQuestsBase;         // Set base max number of quest
        quest.hazardsEnabled = hazardsEnabled;                       // Set hazards as enabled/disabled
        quest.active = active;                                       // Set quest as active/inactive
        quest.rarityPercentage = rarityPercentages;                  // Add item rarity percentages to array
        lastQuestID++;                                               // Increment the quest number
    }

    /// @dev Update a quest & set the rarity percentage
    /// @param questID the quests ID
    /// @param name the quest
    /// @param itemSet set the item set available for quest rewards
    /// @param questPrice set the questPrice for the quest
    /// @param paymentAddress set the contract for quest payment
    /// @param chanceOfFindingLand set the base chance of finding land for this quest
    /// @param maxNumberOfQuestsBase Maximum number of quests before character boosts
    /// @param questDuration Duration of a single quest in blocks
    /// @param hazardsEnabled set the status of the quest
    /// @param active set the status of the quest
    /// @param rarityPercentages an array of the rarity percentage for item distribution eg [400, 150, 50, 10, 0]
    function updateQuest(uint256 questID, string calldata name, uint256 itemSet, uint256 questPrice, address paymentAddress, uint256 chanceOfFindingLand, uint256 questDuration, uint256 maxNumberOfQuestsBase, bool hazardsEnabled, bool active, uint256[5] calldata rarityPercentages)
        public
        onlyOwner
    {
        require(rarityPercentages.length == 5,                       "Requires 5 rarity values");
        Quest storage quest = quests[questID];                       // Shortcut accessor for the quest
        quest.name = name;                                           // Set the name
        quest.itemSet = itemSet;                                     // Set the item set
        quest.questPrice = questPrice;                               // Set the questPrice
        quest.paymentAddress = paymentAddress;                       // Set the payment contract
        quest.chanceOfFindingLand = chanceOfFindingLand;             // Set the merkle root
        quest.maxNumberOfQuestsBase = maxNumberOfQuestsBase;         // Set base max number of quest
        quest.questDuration = questDuration;                         // Set base quest duration
        quest.hazardsEnabled = hazardsEnabled;                       // Set hazards as enabled/disabled
        quest.active = active;                                       // Set quest as active/inactive
        delete quest.rarityPercentage;                               // Remove the old rarity percentages
        quest.rarityPercentage = rarityPercentages;                  // Add item rarity percentages to array
    }

    /// @dev Allows the owner to withdraw all the payments from the contract
    function withdrawAll() 
        external 
        onlyOwner 
    {
        uint256 total = lastQuestID;                                         // Store total number of quests into a local variable to save gas
        uint256 amount;                                                      // Instantiate local variable to store the amount to withdraw
        for (uint256 questID=1; questID <= total; questID++) {               // Loop through all quests
            IERC20 paymentContract = IERC20(quests[questID].paymentAddress); // Setup the payment contract
            if (address(paymentContract) != address(0)) {                    // If payment contract is registered
                amount = paymentContract.balanceOf(address(this));           // Retrieves the token balance
                if ( amount > 0 ) {                                          // If there's a balance
                    paymentContract.safeTransfer(owner(), amount);           // Send to the owner
                }
            }
        }
        uint256 landAmount = IERC777(landContract).balanceOf(address(this));
        IERC777(landContract).operatorSend(address(this), owner(), landAmount , "", "");  // Call the ERC-777 Operator Send to add Land to the contract.
    }

    /// @dev Add Land the contract
    /// @param amount amount to add
    function addLand(uint256 amount)
        external
        onlyOwner
    {
        IERC777(landContract).operatorSend(_msgSender(), address(this), amount , "", "");  // Call the ERC-777 Operator Send to add Land to the contract.
    }

// INTERNAL FUNCTIONS

    /// @dev INTERNAL: Returns an arrary of Random Numbers
    /// @param n number of random numbers to generate
    function getRandomNumbers(uint256 n)
        internal
        returns (uint256[] memory randomNumbers)
    {
        unchecked {
            randomNonce++;
        }
        randomNumbers = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            randomNumbers[i] = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randomNonce, i)));
        }
    }

// VIEWS

    /// @dev Returns a list of all quests
    function getQuests()
        external
        view
        returns (string[] memory allQuests) 
    {
        uint256 total = lastQuestID;                           // Store total number of quests into a local variable
        if ( total == 0 ) {
            return allQuests;                                  // if no quests added, return an empty array
        } else {
            string[] memory _allQuests = new string[](total);
            for(uint256 i = 0; i < total; i++){               // Loop through the quests
                _allQuests[i] = quests[i].name;               // Add quests to array
            }
            return _allQuests;
        }
    }

    /// @dev Returns a quests rarity percentages
    function getQuestsRarityPercentages(uint256 questID)
        external
        view
        returns (uint256[5] memory rarityPercentage) 
    {
        rarityPercentage = quests[questID].rarityPercentage;
    }

  function _tokensReceived(IERC777 token, uint256 amount, bytes memory) internal view override {
    require(amount > 0,                    "You must receive a positive number of tokens");
    require(_msgSender() == address(token),"The contract can only recieve Corn or Land tokens");
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

import "@openzeppelin/contracts/interfaces/IERC777.sol";

enum CollectibleType {Farmer, Tractor, Equipment}
struct Farm {uint256 amount; uint256 compostedAmount; uint256 blockNumber; uint256 lastHarvestedBlockNumber; address harvesterAddress; uint256 numberOfCollectibles;}
struct Collectible {uint256 id; CollectibleType collectibleType; uint256 maxBoostLevel; uint256 addedBlockNumber; uint256 expiry; string uri;}

abstract contract ICornV2 is IERC777 {

    mapping(address => Farm) public ownerOfFarm;
    mapping(address => Collectible[]) public ownerOfCharacters;

// SETTERS
    function allocate(address farmAddress, uint256 amount) external virtual;
    function release() external virtual;
    function compost(address farmAddress, uint256 amount) external virtual;
    function harvest(address farmAddress, address targetAddress, uint256 targetBlock) external virtual;
    function directCompost(address farmAddress, uint256 targetBlock) external virtual;
    function equipCollectible(uint256 tokenID, CollectibleType collectibleType) external virtual;
    function releaseCollectible(uint256 index) external virtual;
    function isPaused(bool value) external virtual;
    function setFarmlandVariables(uint256 endMaturityBoost_, uint256 maxGrowthCycle_, uint256 maxGrowthCycleWithFarmer_, uint256 maxCompostBoost_, uint256 maxMaturityBoost_, uint256 maxMaturityCollectibleBoost_,uint256 maxFarmSizeWithoutFarmer_,uint256 maxFarmSizeWithoutTractor_, uint256 bonusCompostBoostWithFarmer_, uint256 bonusCompostBoostWithTractor_) external virtual;
    function setFarmlandAddresses(address landAddress_, address payable farmerNFTAddress_, address payable tractorNFTAddress_) external virtual;

// GETTERS
    function getHarvestAmount(address farmAddress, uint256 targetBlock) external virtual view returns (uint256 availableToHarvest);
    function getFarmCompostBoost(address farmAddress) external virtual view returns (uint256 compostBoost);
    function getFarmMaturityBoost(address farmAddress) external virtual view returns (uint256 maturityBoost);
    function getTotalBoost(address farmAddress) external virtual view returns (uint256 totalBoost);
    function getCompostBonus(address farmAddress, uint256 amount) external virtual view returns (uint256 compostBonus);
    function getNFTAddress(CollectibleType collectibleType) external virtual view returns (address payable collectibleAddress);
    function getFarmCollectibleTotals(address farmAddress) external virtual view returns (uint256 totalMaxBoost, uint256 lastAddedBlockNumber);
    function getFarmCollectibleTotalOfType(address farmAddress, CollectibleType collectibleType) external virtual view returns (uint256 ownsCollectibleTotal);
    function getCollectiblesByFarm(address farmAddress) external virtual view returns (Collectible[] memory farmCollectibles);
    function getAddressRatio(address farmAddress) external virtual view returns (uint256 myRatio);
    function getGlobalRatio() external virtual view returns (uint256 globalRatio);
    function getGlobalAverageRatio() external virtual view returns (uint256 globalAverageRatio);
    function getAddressDetails(address farmAddress) external virtual view returns (uint256 blockNumber, uint256 cropBalance, uint256 cropAvailableToHarvest, uint256 farmMaturityBoost, uint256 farmCompostBoost, uint256 farmTotalBoost);
    function getAddressTokenDetails(address farmAddress) external virtual view returns (uint256 blockNumber, bool isOperatorLand, uint256 landBalance, uint256 myRatio, bool isOperatorFarmer, bool isOperatorEquipment, bool isOperatorTractor);
    function getFarmlandVariables() external virtual view returns (uint256 totalFarms, uint256 totalAllocatedAmount, uint256 totalCompostedAmount,uint256 maximumCompostBoost, uint256 maximumMaturityBoost, uint256 maximumGrowthCycle, uint256 maximumGrowthCycleWithFarmer, uint256 maximumMaturityCollectibleBoost, uint256 endMaturityBoostBlocks, uint256 maximumFarmSizeWithoutFarmer, uint256 maximumFarmSizeWithoutTractor, uint256 bonusCompostBoostWithAFarmer, uint256 bonusCompostBoostWithATractor);
    function getFarmlandAddresses() external virtual view returns (address, address, address, address, address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

struct CollectibleTraits {uint256 expiryDate; uint256 trait1; uint256 trait2; uint256 trait3; uint256 trait4; uint256 trait5;}
struct CollectibleSlots {uint256 slot1; uint256 slot2; uint256 slot3; uint256 slot4; uint256 slot5; uint256 slot6; uint256 slot7; uint256 slot8;}

abstract contract IFarmlandCollectible is IERC721Enumerable {

     /// @dev Stores the key traits for Farmland Collectibles
    mapping(uint256 => CollectibleTraits) public collectibleTraits;
    /// @dev Stores slots for Farmland Collectibles, can be used to store various items / awards for collectibles
    mapping(uint256 => CollectibleSlots) public collectibleSlots;
    function setCollectibleSlot(uint256 id, uint256 slotIndex, uint256 slot) external virtual;
    function walletOfOwner(address account) external view virtual returns(uint256[] memory tokenIds);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICharacterOwner {
    function addCharacterContracts(address[] calldata characterContracts) external;
    function removeCharacterContract(address characterContract) external;
    function isAccountOwnerOfCharacter(address account, uint256 tokenID) external view returns (bool ownsCharacter);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Activity {bool active;uint256 NumberOfActivities;uint256 activityDuration; uint256 startBlock; uint256 endBlock;}

abstract contract ICharacterActivity {
    mapping(uint256 => Activity) public charactersActivity;
    function setActive(uint256 tokenID, bool active, address ownerOfCharacter) external virtual;
    function setBeginActivity(uint256 tokenID, uint256 activityDuration, uint256 NumberOfActivities, uint256 startBlock, uint256 endBlock, address ownerOfCharacter) external virtual;
    function setInitialHealth(uint256 tokenID, address ownerOfCharacter) external virtual;
    function setHealthTo(uint256 tokenID, uint256 amount, address ownerOfCharacter) external virtual;
    function increaseHealth(uint256 tokenID, uint256 amount, address ownerOfCharacter) external virtual;
    function reduceHealth(uint256 tokenID, uint256 amount, address ownerOfCharacter) external virtual;
    function calculateHealth(uint256 tokenID) external virtual view returns (uint256 health);
    function getBlocksToMaxHealth(uint256 tokenID) external virtual view returns (uint256 blocks);
    function getBlocksUntilActivityEnds(uint256 tokenID) external virtual view returns (uint256 blocksRemaining);
    function getCharactersHealth(uint256 tokenID) external virtual view returns (uint256 health);
    function getCharactersMaxHealth(uint256 tokenID) external virtual view returns (uint256 health);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../characters/CharacterInventory.sol";

/// @dev Farmland - Base Quests Smart Contract
contract CharacterStats is CharacterInventory {

// CONSTRUCTOR

    constructor (
        address[8] memory farmlandAddresses       // Load key contract addresses
        ) CharacterInventory (farmlandAddresses)
    {
        require(farmlandAddresses.length == 8,    "Invalid number of contract addresses");
    }

// VIEWS

    /// @dev Return a characters speed modifier
    /// @dev The speed of each the quest varies based on characters speed
    /// @param tokenID Characters ID
    /// @param baseDuration Duration of a single quest in blocks before stat modifier
    function getCharactersQuestDuration(uint256 tokenID, uint256 baseDuration)
        public
        view
        returns (
            uint256 charactersQuestDuration
        )
    {
        (,,,uint256 speed,,) = farmlandCharacters.collectibleTraits(tokenID); // Retrieve Explorer stats
        if ( speed < 99) {
             charactersQuestDuration = (((99 - speed) * baseDuration) / 100); // Calculate how many additional blocks to add to duration based on speed stat
        }
        return (charactersQuestDuration + baseDuration);
    }

    /// @dev Return a characters max number of quests
    /// @dev The number of quests a character can go on, is based on the characters stamina.
    /// @dev With a stamina of 99 stamina, you can go on 19 quests per tx
    /// @dev Whereas with stamina of 20, you can go on a max 12 quests per tx
    /// @param tokenID Characters ID
    /// @param baseMaxNumberOfQuests Maximum number of quests before character stat modifier
    function getCharactersMaxQuests(uint256 tokenID, uint256 baseMaxNumberOfQuests)
        public
        view
        returns (
            uint256 maxQuests
        )
    {
        (,uint256 stamina,,,,) = farmlandCharacters.collectibleTraits(tokenID);      // Retrieve Explorer stats
        maxQuests = baseMaxNumberOfQuests + (baseMaxNumberOfQuests * stamina / 100); // Calculate how many additional quests
    }

    /// @dev Return a characters bravery .. a combination of courage & intelligence
    /// @param tokenID Characters ID
    function getCharactersBravery(uint256 tokenID)
        public
        view
        returns (
            uint256 bravery
        )
    {
        (,,,, uint256 courage, uint256 intelligence ) = farmlandCharacters.collectibleTraits(tokenID); // Retrieve Explorer stats
        bravery = (courage + intelligence) / 2 ;
        if (tokenID < 100 || courage > 95 || intelligence > 95) // Founders, Genius or Hero
        {
            bravery += bravery / 2;
        }
    }

    /// @dev Return a characters strength
    /// @param tokenID Characters ID
    function getCharactersStrength(uint256 tokenID)
        public
        view
        returns (
            uint256 strength
        )
    {
        (,,strength,,,) = farmlandCharacters.collectibleTraits(tokenID);  // Retrieve Explorer stats
        if (tokenID < 100 || strength > 95) // Founders or Warrior
        {
            strength += strength / 2;
        }
    }
 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFarmlandCollectible.sol";
import "../characters/interfaces/ICharacterOwner.sol";

contract CharacterManager is ERC721Holder, ReentrancyGuard, Pausable, Ownable {

    constructor (
        address[8] memory farmlandAddresses       // Load key contract addresses
        )
    {
        require(farmlandAddresses.length == 8,      "Invalid number of contract addresses");
        require(farmlandAddresses[0] != address(0), "Invalid Contract address");
        require(farmlandAddresses[6] != address(0), "Invalid Contract address");
        farmlandCharacters = IFarmlandCollectible(farmlandAddresses[1]);
        characterOwner = ICharacterOwner(farmlandAddresses[6]);
    }

// STATE VARIABLES

    /// @dev The Farmland Character Owner Contract
    ICharacterOwner internal immutable characterOwner;

    /// @dev The Farmland Character Contract
    IFarmlandCollectible internal immutable farmlandCharacters;

    /// @dev A mapping to track a the owners of characters
    mapping(address => uint256[]) public ownerOfCharacter;

// EVENTS

    event CharacterAdded(address indexed account, uint256 blockNumber, uint256 tokenID);
    event CharacterReleased(address indexed account, uint256 blockNumber, uint256 tokenID);

// MODIFIERS

    /// @dev Check if the character has been added to the contract
    /// @param tokenID of character
    modifier onlyIfCharacterAvailable(uint256 tokenID) {
        (bool exists,) = getCharactersIndex(_msgSender(),tokenID);
        require (exists, "You need to add a character");
        _; // Call the actual code
    }

    /// @dev Check if the character is owned by account calling function
    /// @param tokenID of character
    modifier onlyCharacterOwner (uint256 tokenID) {
        require(characterOwner.isAccountOwnerOfCharacter(_msgSender(), tokenID),"You need to own or employ the Character");
        _;
    }

// FUNCTIONS

    /// @dev PUBLIC: Add an NFT to the contract
    /// @param tokenID the id of the NFT to release
    function _addCharacter(uint256 tokenID)
        internal
        nonReentrant
        whenNotPaused
    {
        ownerOfCharacter[_msgSender()].push(tokenID);                           // Add character id to the array for tracking
        emit CharacterAdded(_msgSender(), block.number, tokenID);               // Write an event
        farmlandCharacters.transferFrom(_msgSender(), address(this), tokenID);  // Transfer character to contract
    }

    /// @dev PUBLIC: Release an NFT from the contract
    /// @param tokenID the id of the NFT to release
    function _releaseCharacter(uint256 tokenID)
        internal
        nonReentrant
        onlyIfCharacterAvailable(tokenID)
    {
        (,uint256 characterIndex) = getCharactersIndex(_msgSender(),tokenID);                   // Find the ownerOfCharacter index
        ownerOfCharacter[_msgSender()][characterIndex] =                                        // In the ownerOfCharacter items array swap the last item for the item being removed
                    ownerOfCharacter[_msgSender()][ownerOfCharacter[_msgSender()].length - 1];
        ownerOfCharacter[_msgSender()].pop();                                                   // Delete the final item in the ownerOfCharacter items array
        emit CharacterReleased(_msgSender(), block.number, tokenID);                            // Write an event
        farmlandCharacters.transferFrom(address(this), _msgSender(), tokenID);                  // Return Item to owner
    }

    // Start or pause the sale
    function isPaused(bool value) 
        public
        onlyOwner 
    {
        if ( !value ) {
            _unpause();
        } else {
            _pause();
        }
    }

// VIEW FUNCTIONS

    /// @dev Return a list of items added to a character
    /// @param account account to check
    function getCharactersByAccount(address account)
        external
        view
        returns (
            uint256[] memory characters     // Define the array of items to be returned.
        )
    {
        return ownerOfCharacter[account];  // Return the array of collectibles on the farm
    }

    /// @dev Check a array for ownerOfCharacter index
    /// @param account address to check for character
    /// @param tokenID Characters ID
    function getCharactersIndex(address account, uint256 tokenID)
        public
        view
        returns (
            bool exists,
            uint256 charactersIndex)
    {
        uint256 total = ownerOfCharacter[account].length;    // Get the total explorers
        for(uint256 i=0; i < total; i++){                    // Loop through the items in the array
            if (tokenID == ownerOfCharacter[account][i])     // Check if we get a match on token ID
            {
                charactersIndex = i;                         // return the index
                exists = true;                               // return true
                break;
            }
        }
    }

 }

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../items/interfaces/IItems.sol";
import "./CharacterManager.sol";

struct Inventory {uint256 itemID; uint256 amount;}

abstract contract CharacterInventory is ERC1155Holder, CharacterManager {

       constructor(
        address[8] memory farmlandAddresses       // Load key contract addresses
        ) CharacterManager (farmlandAddresses)
    {
        require(farmlandAddresses.length == 8,    "Invalid number of contract addresses");
        itemsContract = IItems(farmlandAddresses[3]);    
    }

// STATE VARIABLES

    /// @dev The Farmland Items contract
    IItems internal immutable itemsContract;

    /// @dev A mapping to track a the owners of items
    mapping (address => mapping(uint256 => Inventory[])) public ownerOfCharactersInventory;
    
// EVENTS

    event ItemAdded(address indexed account, uint256 blockNumber, uint256 tokenID, uint256 itemID);
    event ItemRemoved(address indexed account, uint256 blockNumber, uint256 tokenID, uint256 itemID);

// FUNCTIONS

    /// @dev Add item to characters inventory
    /// @param tokenID of character
    /// @param itemID of item
    /// @param amount of item to add to inventory
    function _addItem(uint256 tokenID, uint256 itemID, uint256 amount)
        internal
        whenNotPaused
        onlyCharacterOwner(tokenID)
    {
        Inventory[] storage inventory = ownerOfCharactersInventory[_msgSender()][tokenID];      // Shortcut to characters inventory
        (bool inInventory,) = getItemIndexFromInventory(tokenID, itemID, _msgSender());         // Retrieve Items index if it exists
        require (!inInventory,                                                                  "Item already added to inventory");
        inventory.push(Inventory(itemID, amount));                                              // Push the items details to the array
        emit ItemAdded(_msgSender(),block.number, tokenID, itemID);                             // Write an Event
        itemsContract.safeTransferFrom(_msgSender(), address(this), itemID, amount, "");        // Transfer Inventory to contract
    }

    /// @dev Remove item from characters inventory
    /// @param tokenID of character
    /// @param itemID of item
    function _removeItem(uint256 tokenID, uint256 itemID)
        internal
        onlyCharacterOwner(tokenID)
    {
        Inventory[] storage inventory = ownerOfCharactersInventory[_msgSender()][tokenID];            // Shortcut to characters inventory
        (bool inInventory, uint256 index) = getItemIndexFromInventory(tokenID, itemID, _msgSender()); // Retrieve Items index if it exists
        require (inInventory,                                                                         "Item not in inventory");
        uint256 amount = inventory[index].amount;                                                     // Store the amount
        inventory[index] = inventory[inventory.length - 1];                                           // In the characters items array swap the last item for the item being removed
        inventory.pop();                                                                              // Delete the final item in the characters items array        
        emit ItemRemoved(_msgSender(),block.number, tokenID, itemID);                                 // Write an Event
        itemsContract.safeTransferFrom(address(this), _msgSender(), itemID, amount, "");              // Return Inventory to owner
    }

// VIEW FUNCTIONS

    /// @dev Return a list of items added to a character
    /// @param tokenID character to check
    function getItemsByCharacter(uint256 tokenID, address account)
        public
        view
        returns (
            Inventory[] memory items                          // Define the array of items to be returned.
        )
    {
        return ownerOfCharactersInventory[account][tokenID];  // Return the array of items in the characters inventory
    }

    /// @dev Return a list of items added to a character
    /// @param tokenID character to check
    function getItemByIndex(uint256 tokenID, address account, uint256 index)
        internal
        view
        returns (uint256 itemID, uint256 amount)
    {
        Inventory[] memory itemInventory = getItemsByCharacter(tokenID, account); // Retrieve any items that are equipped for this character
        if (itemInventory.length > 0) {
            itemID = itemInventory[index].itemID;
            amount = itemInventory[index].amount;
        }
    }

    /// @dev Check a characters inventory for an item & return the index
    /// @param tokenID Characters ID
    /// @param itemID Item ID
    function getItemIndexFromInventory(uint256 tokenID, uint256 itemID, address account)
        internal
        view
        returns (
            bool inInventory,
            uint256 itemsIndex)
    {

        Inventory[] memory itemInventory = 
                                  getItemsByCharacter(tokenID, account); // Retrieve any items that are equipped for this character
        uint256 totalitemInventory = itemInventory.length;               // Retrieve total equipped items
        for(uint256 i=0; i < totalitemInventory; i++){                   // Loop through the items in the array
            if (itemID == itemInventory[i].itemID)                       // Check if we get a match on itemID
            {
                itemsIndex = i;                                          // Return the index
                inInventory = true;                                      // Return true
                break;
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1820Registry.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC1820Registry.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

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