// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ExplorerStatsV2.sol";

/// @dev Farmland - Quests Smart Contract
contract QuestsV2 is ExplorerStatsV2 {

// CONSTRUCTOR

    constructor(
        address[6] memory farmlandAddresses
        ) ExplorerStatsV2 (farmlandAddresses)
    {
        require(farmlandAddresses.length == 6,      "Invalid number of contract addresses");
        require(farmlandAddresses[0] != address(0), "Invalid Corn Contract address");
        require(farmlandAddresses[1] != address(0), "Invalid Character Contract address");
        require(farmlandAddresses[2] != address(0), "Invalid Land Distributor Contract address");
        require(farmlandAddresses[3] != address(0), "Invalid Items Contract address");
        require(farmlandAddresses[4] != address(0), "Invalid Item Sets address");
        require(farmlandAddresses[5] != address(0), "Invalid Land Contract address");
    }

// EVENTS

    event QuestStarted(address indexed account, uint256 quest, uint256 endblockNumber, uint256 indexed tokenID);
    event QuestCompleted(address indexed account, uint256 quest, uint256 endblockNumber, uint256 indexed tokenID);
    event QuestAborted(address indexed account, uint256 quest, uint256 endblockNumber, uint256 indexed tokenID);
    event ItemFound(address indexed account, uint256 quest, uint256 indexed tokenID, uint256 itemMinted, uint256 amountMinted, uint256 amountOfLandFound);

// FUNCTIONS
        
    /// @dev Quest for items
    /// @param questID Quest ID
    /// @param tokenID Explorers ID
    /// @param numberOfActivities number of quests in a single transaction
    /// @param landItemID Item ID useful for finnding Land
    /// @param hazardItemID Item ID useful for avoiding hazards)
    function beginQuest(uint256 questID, uint256 tokenID, uint256 numberOfActivities, uint256 landItemID, uint256 hazardItemID)
        external
        nonReentrant
        onlyInactive(tokenID)
        onlyCharacterOwner(tokenID)
        onlyWhenQuestEnabled(questID)
        whenNotPaused
    {
        // Set the quest ID
        latestQuest[tokenID] = questID;
        //Initialize activity & set variables
        uint256 activityDuration = getExplorersQuestDuration(tokenID, quests[questID].questDuration);
        Activity memory activity = Activity({
            active: true,
            numberOfActivities: numberOfActivities,
            startBlock: block.number,
            activityDuration: activityDuration,
            endBlock: block.number + (activityDuration * numberOfActivities),
            completedBlock: 0
        });
        // Write an event
        emit QuestStarted(_msgSender(), questID, activity.endBlock, tokenID);
        // If using an item
        if (landItemID > 0 || hazardItemID > 0) {
            // Add item to the explorers inventory
            addItems(tokenID, landItemID, hazardItemID);
        }
        // Setup hazards if required for quest
        setupHazards(questID, tokenID, numberOfActivities);
        // Update the mercenaries health before starting a new quest
        updateHealth(questID, tokenID, numberOfActivities);
        // Do a few checks
        require(getExplorersLevel(tokenID) >= quests[questID].minimumLevel, "Explorer needs to level up");
        require (numberOfActivities <= getExplorersMaxQuests(tokenID, quests[questID].maxNumberOfActivitiesBase), "Exceeds maximum quest duration");
        // Calculate the amount of Corn required
        uint256 cornAmount = numberOfActivities * quests[questID].questPrice;
        // Burn Corn
        cornContract.operatorBurn(_msgSender(), cornAmount, "", "");
        // Activate Explorer & update the activity details
        explorers.startActivity(tokenID, activity);
    }

    /// @dev Complete the quest
    /// @param tokenID Explorers ID
    function completeQuest(uint256 tokenID)
        external
        nonReentrant
        onlyCharacterOwner(tokenID)
        onlyQuestExpired(tokenID)
        onlyActive(tokenID)
    {
        // Get the Quest ID
        uint256 questID = latestQuest[tokenID];
        // Get the number of activities
        (,uint256 numberOfActivities,,,,) = explorers.charactersActivity(tokenID);
        // Write an event
        emit QuestCompleted(_msgSender(), latestQuest[tokenID], block.number, tokenID);
        // Call mint rewards function
        mintRewards(questID, tokenID, numberOfActivities);
        // Release explorer
        explorers.updateActivityStatus(tokenID, false);
        // Release the item
        releaseItems(tokenID);
        // Decrease the mercenaries morale 
        decreaseMorale(questID, tokenID, numberOfActivities);
        // Decrease the explorers health
        decreaseHealth(questID, tokenID, numberOfActivities);
    }

    /// @dev Abort quest without collecting items
    /// @param tokenID Explorers ID
    function abortQuest(uint256 tokenID)
        external
        nonReentrant
        onlyCharacterOwner(tokenID)
    {        
        // Get the Quest ID
        uint256 questID = latestQuest[tokenID];
        // Get the number of activities
        (,uint256 numberOfActivities,,,,) = explorers.charactersActivity(tokenID);
        // Write an event
        emit QuestAborted(_msgSender(), questID, block.number, tokenID);
        // Release explorer
        explorers.updateActivityStatus(tokenID, false);
        // Release the item
        releaseItems(tokenID);
        // Decrease the mercenaries morale 
        decreaseMorale(questID, tokenID, numberOfActivities);
        // Decrease the explorers health
        decreaseHealth(questID, tokenID, numberOfActivities);
    }

// PRIVATE HELPER FUNCTIONS

    /// @dev Remove an item from a explorers inventory at the end of a quest
    /// @param tokenID Explorers ID
    /// @param landItemID Item ID useful for finnding Land
    /// @param hazardItemID Item ID useful for avoiding hazards
    function addItems(uint256 tokenID, uint256 landItemID, uint256 hazardItemID)
        private
    {
        // Add Land item to mapping to indicate it's in use on a quest
        if (landItemID > 0) {
            require(itemsContract.balanceOf(_msgSender(),landItemID) > 0, "Item balance too low");
            landItemOnQuest[tokenID] = landItemID;
            // Set the item as in use AKA equip the item
            itemsContract.setItemInUse(_msgSender(), tokenID, landItemID, 1, true);
        }
        // Add Hazard item to mapping to indicate it's in use on a quest
        if (hazardItemID > 0) {
            require(itemsContract.balanceOf(_msgSender(),hazardItemID) > 0, "Item balance too low");
            hazardItemOnQuest[tokenID] = hazardItemID;
            // Set the item as in use AKA equip the item
            itemsContract.setItemInUse(_msgSender(), tokenID, hazardItemID, 1, true);
        }        
    }

    /// @dev Remove an item from a explorers inventory at the end of a quest
    /// @param tokenID Explorers ID
    function releaseItems(uint256 tokenID)
        private
    {
        // Store the itemID of the active item
        uint256 landItemID = landItemOnQuest[tokenID];
        uint256 hazardItemID = hazardItemOnQuest[tokenID];
        // Check if there's a land item in use
        if (landItemID > 0) {
            // Remove the internal value, resetting the item on the quest
            landItemOnQuest[tokenID] = 0;
            // Release the item
            itemsContract.setItemInUse(_msgSender(), tokenID, landItemID, 1, false);
        }
        // Check if there's a hazard item in use
        if (hazardItemID > 0) {
            // Remove the internal value, resetting the item on the quest
            hazardItemOnQuest[tokenID] = 0;
            // Release the item
            itemsContract.setItemInUse(_msgSender(), tokenID, hazardItemID, 1, false);
        }
    }

    /// @dev Setup Hazards by quest
    /// @param questID Quest ID
    /// @param tokenID Explorers ID
    /// @param numberOfActivities on the quest
    function setupHazards(uint256 questID, uint256 tokenID, uint256 numberOfActivities)
        private
    {
        // Store the difficulty cap
        uint256 hazardDifficultyCap = quests[questID].hazardDifficultyCap;
        // If hazards configured for this quest
        if (hazardDifficultyCap > 0) {
            // Loop through the number of activities to check
            for(uint256 i=0; i < numberOfActivities;) {
                // Check if hazard will be avoided for each quest
                currentHazards[tokenID].push(isHazardAvoided(questID, tokenID, hazardDifficultyCap, i));
                unchecked { ++i; }
            }
        }
    }

    /// @dev Update the Explorers health 
    /// @param questID Quest ID
    /// @param tokenID Explorers ID
    /// @param numberOfActivities on the quest
    function updateHealth(uint256 questID, uint256 tokenID, uint256 numberOfActivities)
        private
    {
        // Get the configured reduction rate for health
        uint256 healthReductionRate = quests[questID].healthReductionRate;
        if (healthReductionRate > 0) {
            // Calculate & store the current health
            uint256 health = calculateHealth(tokenID);
            explorers.setStatTo(tokenID, health, 5);
            // Check that the Explorer has enough health to complete the quest
            require (health > (numberOfActivities * healthReductionRate), "Explorer needs more health");
        }
    }

    /// @dev Decrease the mercenaries morale 
    /// @param questID Quest ID
    /// @param tokenID Explorers ID
    /// @param numberOfActivities on the quest
    function decreaseMorale(uint256 questID, uint256 tokenID, uint256 numberOfActivities)
        private
    {
        // Get the configured reduction rate for morale
        uint256 moraleReductionRate = quests[questID].moraleReductionRate;
        if (moraleReductionRate > 0) {
            // Decrease the mercenaries morale if configured
            explorers.decreaseStat(tokenID, (numberOfActivities * moraleReductionRate), 6);
        }
    }
    
    /// @dev Decrease the mercenaries health 
    /// @param questID Quest ID
    /// @param tokenID Explorers ID
    /// @param numberOfActivities on the quest
    function decreaseHealth(uint256 questID, uint256 tokenID, uint256 numberOfActivities)
        private
    {
        // Get the configured reduction rate for health
        uint256 healthReductionRate = quests[questID].healthReductionRate;
        if (healthReductionRate > 0) {
            // Decrease the mercenaries health if configured
            explorers.decreaseStat(tokenID, (numberOfActivities * healthReductionRate), 5);
        }
    }

    /// @dev Mint items found on a quest
    /// @param questID Quest ID
    /// @param tokenID Explorers ID
    /// @param numberOfActivities on the quest
    function mintRewards(uint256 questID, uint256 tokenID, uint256 numberOfActivities)
        private
    {
        // Initialise local variables
        uint256 itemToMint = 0;
        uint256 totalToMint = 1;
        uint256 amountOfLandFound = 0;
        uint256 totalHazards = currentHazards[tokenID].length;
        // Loop through the quest and mint items
        for(uint256 i=0; i < numberOfActivities;) {
            // If hazard avoided mints rewards
            if (totalHazards == 0 || currentHazards[tokenID][i]) {
                // Calculate the Land
                amountOfLandFound = getLandAmount(questID, tokenID, i);
                // Calculate the items found
                (itemToMint, totalToMint) = getRewardItem(questID, tokenID, i);
                // If there's Land to send then ensure there is enough Land left in the contract
                if (amountOfLandFound > 0 && landContract.balanceOf(address(landDistributor)) > amountOfLandFound) {
                    // Write an event for each quest
                    emit ItemFound(_msgSender(), questID, tokenID, itemToMint, totalToMint, amountOfLandFound);
                    // Send the found Land
                    landDistributor.issueLand(_msgSender(),amountOfLandFound);
                } else {
                    // Write an event for each quest
                    emit ItemFound(_msgSender(), questID, tokenID, itemToMint, totalToMint, 0);
                }
                // Mint reward items
                itemsContract.mintItem(itemToMint, totalToMint, _msgSender());
            }
            // Increase the explorers XP
            explorers.increaseStat(tokenID, quests[questID].xpEmmissionRate, 7);
            unchecked { ++i; }
        }
        if (totalHazards > 0) {
            // Reset the hazard mapping
            delete currentHazards[tokenID];
        }
    }

// VIEWS

    /// @dev Return a reward item & amount to mint
    /// @param questID Quest ID
    /// @param tokenID Explorers ID
    function getRewardItem(uint256 questID, uint256 tokenID, uint256 salt)
        private
        view
        returns (
            uint256 itemToMint,
            uint256 totalToMint
        )
    {
        // Initialise local variable
        uint256 dropRateBucket = 0;
        // Declare & set the pack item set to work from
        uint256 rewardItemSet = quests[questID].rewardItemSet;
        // Get some random numbers
        uint256[] memory randomNumbers = new uint256[](4);
        randomNumbers = getRandomNumbers(4, tokenID * salt);
        // Choose a random number up to 1000
        uint256 random = randomNumbers[0] % 1000;
        // Loop through the array of drop rates
        for (uint256 i = 0; i < 5;) {
            if (random > quests[questID].dropRate[i] &&
                // Choose drop rate & ensure an item is registered
                itemSetsContract.getItemSetByRarity(rewardItemSet, i).length > 0) {
                // Set the drop rate bucket for minting
                dropRateBucket = i;
                // Move on
                break;
            }
            unchecked { ++i; }
        }
        // Retrieve the list of items
        Item[] memory rewardItems = itemSetsContract.getItemSetByRarity(rewardItemSet, dropRateBucket);
        require(rewardItems.length > 0, "ADMIN: Not enough items registered");
        // Randomly choose item to mint
        uint256 itemIndex = randomNumbers[1] % rewardItems.length;
        // Finds the items ID
        itemToMint = rewardItems[itemIndex].itemID;
        // Retrieve Explorers Strength modifier
        uint256 strength = getExplorersStrength(tokenID);
        // Retrieve Items scarcityCap
        uint256 scarcityCap = rewardItems[itemIndex].value1;
        // Ensure that the explorers strength limits the amount of items awarded by
        // checking if the item scarcity cap is greater than the explorers strength
        if (scarcityCap > strength) {
            // Choose a random number capped @ explorers strength
            totalToMint = (randomNumbers[2] % strength);
        } else {
            // Otherwise choose a random number capped @ item scarcity cap
            totalToMint = (randomNumbers[3] % scarcityCap);
        }
        // Ensure at least 1 item is found
        if (totalToMint == 0) { totalToMint = 1;}
    }
    
    /// @dev Checks to see if a hazard has been avoided
    /// @param questID Quest ID
    /// @param tokenID Explorers ID
    /// @param hazardDifficultyCap defines the difficulty of the quest
    /// @param salt used to help with randomness
    function isHazardAvoided(uint256 questID, uint256 tokenID, uint256 hazardDifficultyCap, uint256 salt)
        private
        view
        returns (bool hazardAvoided)
    {
        uint256[] memory randomNumbers = new uint256[](1);
        // Return a random number
        randomNumbers = getRandomNumbers(1, tokenID * salt);
        // Get the item that's in use
        uint256 itemID = hazardItemOnQuest[tokenID];
        // Check if there's an item in use
        if (itemID > 0) {
            // Get the item modifier variable
            uint256 difficultyMod = getItemModifier(itemID, quests[questID].hazardItemSet);
            // Only apply the modifier if it's greater than zero
            if (difficultyMod > 0) {
                // Recalculate the hazardDifficultyCap by reducing it by the difficulty modifier as a %
                hazardDifficultyCap -= hazardDifficultyCap * difficultyMod / 100;
            }
        }
        // Get the explorers morale
        uint256 morale = getExplorersMorale(tokenID);
        // Assign hazard difficulty up the maximum difficulty cap
        uint256 hazardDifficulty = randomNumbers[0] % hazardDifficultyCap;
        // Morale has to be greater than a random number between 0-hazardDifficultyCap for the explorer to avoid the hazard
        if (morale > hazardDifficulty) {
            // Returns true if the hazard was avoided
            return true;
        }
    }

    /// @dev Return the amount of Land found
    /// @param questID Quest ID
    /// @param tokenID Explorers ID
    function getLandAmount(uint256 questID, uint256 tokenID, uint256 salt)
        private
        view
        returns (
            uint256 amountOfLandFound
        )
    {
        uint256 chanceOfFindingLand = quests[questID].chanceOfFindingLand;
        // Check to see if this quest supports Land as a reward
        if (chanceOfFindingLand != 0) {
            // Get some random numbers
            uint256[] memory randomNumbers = new uint256[](2);
            randomNumbers = getRandomNumbers(2, tokenID * salt);
            // Get the item that's in use
            uint256 itemID = landItemOnQuest[tokenID];
            // Check if there's an item in use
            uint256 itemModifier = 0;
            if (itemID > 0) {
                // Get the item modifier variable
                itemModifier = getItemModifier(itemID, quests[questID].landItemSet);
            }
            // Set the default chance of finding Land unless explorer is carrying a land item
            if (itemModifier > 0) {
                chanceOfFindingLand = itemModifier;
            }
            // Land is found if the random number is less than the chance of finding Land
            if (randomNumbers[0] % 1000 < chanceOfFindingLand) {
                // The explorer found between 1 and max 99 (capped at the explorers of morale)
                amountOfLandFound = ((randomNumbers[1] % getExplorersMorale(tokenID)) +1) * (10**18);
            }
        }
    }

    /// @dev Grab the Item Modifier (value1)
    /// @param itemID Item ID in use
    /// @param itemSet Item set to check
    function getItemModifier(uint256 itemID, uint256 itemSet)
        private
        view
        returns (uint256 value)
    {
        // Retrieve all the useful items of a specified type
        Item[] memory usefulItems = itemSetsContract.getItemSet(itemSet);
        // Loop through the items
        for(uint256 i = 0; i < usefulItems.length;){
            if (itemID == usefulItems[i].itemID) {
                // return the item modifier for this item
                return usefulItems[i].value1;
            }
            unchecked { ++i; }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILandDistributor  {
    function issueLand(address _recipient, uint256 _amount) external;
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

struct Quest { 
    string name;                                    // The name of the quest
    uint256[5] dropRate;                            // The percentage chance of getting items [common % ,uncommon %, rare %, epic %, legendary %]
    uint256 rewardItemSet;                          // The list of rewards available in this quest
    uint256 landItemSet;                            // The list of items that will help find land in this quest
    uint256 hazardItemSet;                          // The list of items that will help avoid hazards in this quest
    uint256 questPrice;                             // Price of the quest, to be burned if payment address is empty
    uint256 chanceOfFindingLand;                    // Base chance of finding Land before item boosts
    address paymentAddress;                         // Zero address is a free mint
    uint256 questDuration;                          // Duration of a single quest in blocks
    uint256 maxNumberOfActivitiesBase;              // Maximum number of activities before explorer boosts
    uint256 hazardDifficultyCap;                    // If hazard difficulty > 0, then enabled. The higher the difficultly the harder the quest
    uint256 moraleReductionRate;                    // Determines the amount that Morale reduces per quest. 0 indicates that morale doesn't reduce
    uint256 healthReductionRate;                    // Determines the amount that Health reduces per quest. 0 indicates that morale doesn't reduce
    uint256 xpEmmissionRate;                        // Determines the amount of XP emitted per quest
    uint256 minimumLevel;                           // Sets a minimum level to start this quest
    bool active;                                    // Status (Active/Inactive)
    }

struct Inventory {uint256 itemID; uint256 amount;}

/**
 * @dev Farmland - Quests Interface
 */
interface IQuestsV2 {

// SETTERS
    function addExplorer(uint256 tokenID) external;
    function releaseExplorer(uint256 index) external;
    function beginQuest(uint256 questID, uint256 tokenID, uint256 numberOfQuests, uint256 itemID) external;
    function completeQuest(uint256 tokenID) external;
    function endQuest(uint256 tokenID, bool includeItem, uint256 itemID) external;
    function abortQuest(uint256 tokenID) external;

// GETTERS
    function getQuests() external view returns (string[] memory allQuests);
    function getQuestDropRates(uint256 questID) external view returns (uint256[5] memory dropRate);
    function getItemsByExplorer(uint256 tokenID, address account) external view returns (Inventory[] memory items);
    function calculateHealth(uint256 tokenID) external  view returns (uint256 health);
    function getMaxHealth(uint256 tokenID) external  view returns (uint256 health);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC777.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../tokens/interfaces/ICornV2.sol";
import "../utils/interfaces/ILandDistributor.sol";
import "../mercenaries/interfaces/IWrappedCharacters.sol";
import "../items/interfaces/IItemSets.sol";
import "../items/interfaces/IItems.sol";
import "./interfaces/IQuestsV2.sol";

/// @dev Farmland - Quest Type Smart Contract
contract QuestTypeV2 is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

// CONSTRUCTOR

    constructor (
        address[6] memory farmlandAddresses)
        {
            require(farmlandAddresses.length == 6, "Invalid number of contract addresses");
            cornContract = ICornV2(farmlandAddresses[0]);
            landDistributor = ILandDistributor(farmlandAddresses[2]);
            itemSetsContract = IItemSets(farmlandAddresses[4]);
            landContract = IERC777(farmlandAddresses[5]);
            explorers = IWrappedCharacters(farmlandAddresses[1]);
            itemsContract = IItems(farmlandAddresses[3]);
        }

// STATE VARIABLES

    /// @dev This is the Land contract
    ICornV2 internal immutable cornContract;

    /// @dev This is the Land contract
    IERC777 internal immutable landContract;

    /// @dev This is the Land Distributor contract
    ILandDistributor internal immutable landDistributor;

    /// @dev The Farmland Item Sets contract
    IItemSets internal immutable itemSetsContract;

    /// @dev The Farmland Character Contract
    IWrappedCharacters internal immutable explorers;

    /// @dev The Farmland Items contract
    IItems internal immutable itemsContract;

    /// @dev Create a mapping to track each type of quest
    mapping(uint256 => Quest) internal quests;

    /// @dev Tracks the last Quest ID
    uint256 public lastQuestID;
 
    /// @dev Create an mapping to track a explorers latest quest
    mapping(uint256 => uint256) internal latestQuest;

    /// @dev Create an mapping to track if hazard are avoided
    mapping(uint256 => bool[]) internal currentHazards;

    /// @dev Create an mapping to track a explorers item in use ... used for finding Land 
    mapping(uint256 => uint256) public landItemOnQuest;

    /// @dev Create an mapping to track a explorers item in use ... used for avoiding hazards 
    mapping(uint256 => uint256) public hazardItemOnQuest;

// MODIFIERS

    /// @dev Check if the explorer is inactive
    /// @param tokenID of explorer
    modifier onlyInactive(uint256 tokenID) {
        // Get the explorers activity
        (bool active,,,,,) = explorers.charactersActivity(tokenID);
        require (!active, "Explorer needs to complete quest");
        _;
    }

    /// @dev Check if the explorer is active
    /// @param tokenID of explorer
    modifier onlyActive(uint256 tokenID) {
        // Get the explorers activity
        (bool active,,,,,) = explorers.charactersActivity(tokenID);
        require (active, "Explorer can only complete quest once");
        _;
    }

    /// @dev Explorer can't be on a quest
    /// @param tokenID of explorer
    modifier onlyQuestExpired(uint256 tokenID) {
        require (explorers.getBlocksUntilActivityEnds(tokenID) == 0, "Explorer still on a quest");
        _;
    }

    /// @dev Check if the explorer is owned by account calling function
    /// @param tokenID of explorer
    modifier onlyCharacterOwner (uint256 tokenID) {
        require (explorers.ownerOf(tokenID) == _msgSender(),"Only the owner of the token can perform this action");
        _;
    }

    /// @dev Check if quest enabled
    modifier onlyWhenQuestEnabled(uint256 questID) {
        require (quests[questID].active, "Quest inactive");
        _;
    }

    /// @dev Check if quest enabled
    modifier onlyWhenQuestExists(uint256 questID) {
        require (questID <= lastQuestID, "Unknown Quest");
        _;
    }

// ADMIN FUNCTIONS

    /// @dev Create a quest & set the drop rate
    /// @param questDetails the quests details based on the struct
    function createQuest(Quest calldata questDetails)
        external
        onlyOwner
    {
        require(questDetails.dropRate.length == 5, "Requires 5 drop rate values");
        // Set the quest details
        quests[lastQuestID] = questDetails;
        // Increment the quest number
        unchecked { ++lastQuestID; }
    }

    /// @dev Update a quest & set the drop rate
    /// @param questID the quests ID
    /// @param questDetails the quests details based on the struct
    function updateQuest(uint256 questID, Quest calldata questDetails)
        external
        onlyOwner
    {
        require(questDetails.dropRate.length == 5, "Requires 5 drop rate values");
        // Update the quest details
        quests[questID] = questDetails;
    }

    /// @dev Allows the owner to withdraw tokens from the contract
    function withdrawToken(address paymentAddress) 
        external 
        onlyOwner 
    {
        require(paymentAddress != address(0),"Address can't be zero address");
        // Retrieves the token balance
        uint256 amount = IERC20(paymentAddress).balanceOf(address(this));
        require(amount > 0, "There's no balance to withdraw");
        // Send to the owner
        IERC20(paymentAddress).safeTransfer(owner(), amount);
    }

// INTERNAL FUNCTIONS

    /// @dev Returns an array of Random Numbers
    /// @param n number of random numbers to generate
    /// @param salt a number that adds to randomness
    function getRandomNumbers(uint256 n, uint256 salt)
        internal
        view
        returns (uint256[] memory randomNumbers)
    {
        randomNumbers = new uint256[](n);
        for (uint256 i = 0; i < n;) {
            randomNumbers[i] = uint256(keccak256(abi.encodePacked(block.timestamp, salt, i)));
            unchecked { ++i; }
        }
    }

// VIEWS

    /// @dev Returns a list of all quests
    function getQuests()
        external
        view
        returns (string[] memory allQuests) 
    {
        // Store total number of quests into a local variable
        uint256 total = lastQuestID;
        if ( total == 0 ) {
            // if no quests added, return an empty array
            return allQuests;
        } else {
            allQuests = new string[](total);
            // Loop through the quests
            for(uint256 i = 0; i < total;){
                // Add quests to array
                allQuests[i] = quests[i].name;
                unchecked { ++i; }
            }
        }
    }

    /// @dev Returns the quest details
    /// @param questID the quests ID
    function getQuest(uint256 questID)
        external
        view
        returns (Quest memory questDetails) 
    {
        return quests[questID];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./QuestTypeV2.sol";

/// @dev Farmland - Explorer Stats Smart Contract
contract ExplorerStatsV2 is QuestTypeV2 {

// CONSTRUCTOR

    constructor (
        address[6] memory farmlandAddresses
        ) QuestTypeV2 (farmlandAddresses) {}

// VIEWS

    /// @dev Return a explorers speed modifier
    /// @dev The speed of each the quest varies based on explorers speed
    /// @param tokenID Explorers ID
    /// @param baseDuration Duration of a single quest in blocks before stat modifier
    function getExplorersQuestDuration(uint256 tokenID, uint256 baseDuration)
        public
        view
        returns (
            uint256 explorersQuestDuration
        )
    {
        // Retrieve Explorer stats
        (,,uint256 speed,,,,,,) = explorers.getStats(tokenID);
        if ( speed < 99) {
            // Calculate how many additional blocks to add to duration based on speed stat
             explorersQuestDuration = (((99 - speed) * baseDuration) / 100);
        }
        return (explorersQuestDuration + baseDuration);
    }

    /// @dev Return a explorers max number of quests
    /// @dev The number of quests a explorer can go on, is based on the explorers stamina.
    /// @dev With a stamina of 99 stamina, you can go on 19 quests per tx
    /// @dev Whereas with stamina of 20, you can go on a max 12 quests per tx
    /// @param tokenID Explorers ID
    /// @param baseMaxNumberOfQuests Maximum number of quests before explorer stat modifier
    function getExplorersMaxQuests(uint256 tokenID, uint256 baseMaxNumberOfQuests)
        public
        view
        returns (
            uint256 maxQuests
        )
    {
        // Retrieve Explorer stats
        (uint256 stamina,,,,,,,,) = explorers.getStats(tokenID);
        // Calculate how many additional quests
        maxQuests = baseMaxNumberOfQuests + (baseMaxNumberOfQuests * stamina / 100);
    }

    /// @dev Return a explorers strength
    /// @param tokenID Explorers ID
    function getExplorersStrength(uint256 tokenID)
        public
        view
        returns (
            uint256 strength
        )
    {
        // Retrieve Explorer stats
        (,strength,,,,,,,) = explorers.getStats(tokenID);
        // Boost for warriors
        if (strength > 95) {
            strength += strength / 2;
        }
    }
 
    /// @dev Return a explorers XP
    /// @param tokenID Explorers ID
    function getExplorersLevel(uint256 tokenID)
        public
        view
        returns (
            uint256 level
        )
    {
        return explorers.getLevel(tokenID);
    }

    /// @dev Return a explorers XP
    /// @param tokenID Explorers ID
    function getExplorersMorale(uint256 tokenID)
        public
        view
        returns (
            uint256 morale
        )
    {
        (,,,,,,morale,,) = explorers.getStats(tokenID);
    }

    /// @dev Return a characters current health
    /// @dev Health regenerates whilst a Character is resting (i.e., not on a activity)
    /// @dev character regains 1 stat per activity duration for that character 
    /// @dev so the speedier the character the quicker to regenerate
    /// @param tokenID Characters ID
    function calculateHealth(uint256 tokenID)
        public
        view
        returns (
            uint256 health
        )
    {
        // Get the Quest ID
        uint256 questID = latestQuest[tokenID];
        // Get the configured reduction rate for health
        uint256 healthReductionRate = quests[questID].healthReductionRate;
        // Get the character activity details
        (bool active, uint256 numberOfActivities, uint256 activityDuration, uint256 startBlock, uint256 endBlock, uint256 completedBlock) = explorers.charactersActivity(tokenID);
        // Get characters max health
        uint256 maxHealth = explorers.getMaxHealth(tokenID);
        // If there's been no activity return max health
        if (endBlock == 0) {return maxHealth;}
        // Get characters health
        (,,,,,health,,,) = explorers.getStats(tokenID);
        // If activity not ended
        if (block.number <= endBlock) {
            // Calculate blocks since activity started
            uint256 blockSinceStartOfActivity = block.number - startBlock;
            // Reduce health used = # of blocks since start of activity / # of Blocks to consume One Health stat
            health -= (blockSinceStartOfActivity / (healthReductionRate * activityDuration));
        } else {
            // If ended but still active i.e., not completed
            if (active) {
                // Reduce health by number of activities
                health -= numberOfActivities;
            } else {
                // Calculate blocks since last activity finished
                uint256 blockSinceLastActivity = block.number - completedBlock;
                // Add health + health regenerated = # of blocks since last activity / # of Blocks To Regenerate One Health stat
                health += (blockSinceLastActivity / activityDuration);
                // Ensure new energy amount doesn't exceed max health
                if (health > maxHealth) {return maxHealth;}
            }
       }
    }

    /// @dev Return the number of blocks until a characters health will regenerate
    /// @param tokenID Characters ID
    function getBlocksToMaxHealth(uint256 tokenID)
        external
        view
        returns (
            uint256 blocks
        )
    {
         // Get the character activity details
        (bool active,, uint256 activityDuration,,, uint256 completedBlock) = explorers.charactersActivity(tokenID);
        // Get characters health
        (,,,,,uint256 health,,,) = explorers.getStats(tokenID);
        // Character not on a activity
        if (!active) {
            // Calculate blocks until health is restored
            uint256 blocksToMaxHealth = completedBlock +(activityDuration * (explorers.getMaxHealth(tokenID)- health));
            if (blocksToMaxHealth > block.number) {
                return blocksToMaxHealth - block.number;
            }
        }
    }

// ADMIN FUNCTIONS

    // Start or pause the sale
    function isPaused(bool value) 
        external
        onlyOwner 
    {
        if ( !value ) {
            _unpause();
        } else {
            _pause();
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

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
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

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