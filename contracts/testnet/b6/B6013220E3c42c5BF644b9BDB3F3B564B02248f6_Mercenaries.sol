// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../WrappedCharacters/WrappedCharacters.sol";

contract Mercenaries is WrappedCharacters {

    constructor (
        uint256 _mercenaryPrice,
        uint256 _traitPrice,
        string memory _initialBaseURI
    )
    WrappedCharacters("Farmland Mercenaries", "MERCENARIES") {
        mercenaryPrice = _mercenaryPrice;  // Set the minting price
        traitPrice = _traitPrice;          // Set the price to update traits
        baseURI = _initialBaseURI;         // Set the starting BaseURI
        isPaused(true);                    // Start the contract in paused model
    }

// STATE VARIABLES

    /// @dev This is the price for minting
    uint256 public mercenaryPrice;
    
    /// @dev This is the price for updating traits
    uint256 public traitPrice;

    /// @dev For tracking the mercenaries visual traits
    mapping (uint256 => uint16[]) public visualTraits;

// FUNCTIONS

    /// @dev Mint a mercenary
    /// @param amount of mint
    /// @param traits a 2 dimensional array representing the mercenaries traits e.g., [[7,2,5,1,1],[6,3,1,4,5]]
    function mint(uint256 amount, uint16[][] calldata traits)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require( amount < 11,                                                           "You can mint a maximum of 10" );
        require( amount == traits.length,                                               "Amount and traits array should match");
        require( msg.value >= mercenaryPrice * amount,                                  "Ether sent is not correct" );
        for(uint256 i = 0; i < amount; i++){                                            // Loop through the amount to mint
            uint256 tokenID = wTokenID;
            _storeStats(address(this),wTokenID);                                        // Then set the stats
            bytes32 underlyingTokenHash = hashUnderlyingToken(address(this),tokenID);
            underlyingToken[underlyingTokenHash].collectionAddress = address(this);     // Add Collection address to the mapping
            underlyingToken[underlyingTokenHash].tokenID = tokenID;                     // Add Token ID to the mapping
            wrappedCharacter[tokenID] = underlyingTokenHash;                            // Map the underlying token hash to the wrapped token id
            _updateTraits(wTokenID, traits[i]);                                          // Add Visual Traits for mercenary
            wTokenID++;                                                                 // Increment wrapped token id
        }
        _mint(_msgSender(), amount);                                                    // Mint the Mercenaries
    }

    /// @dev Replace traits
    /// @param tokenID of mercenary
    /// @param traits an array representing the mercenaries traits e.g., [7,2,5,1,1]
    function updateTraits(uint256 tokenID, uint16[] calldata traits)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(ownerOf(tokenID) == _msgSender(), "Only the owner can update traits");
        require( msg.value >= traitPrice,         "Ether sent is not correct" );
        _updateTraits(tokenID, traits);           // Replace Visual Traits for mercenary
    }

// INTERNAL FUNCTIONS

    /// @dev Replace traits
    /// @param tokenID of mercenary
    /// @param traits an array representing the mercenaries traits e.g., [7,2,5,1,1]
    function _updateTraits(uint256 tokenID, uint16[] calldata traits)
        internal
    {
        if (visualTraits[tokenID].length>0) {
            delete visualTraits[tokenID];
        }
        visualTraits[tokenID] = traits;
    }

// ADMIN FUNCTIONS

    /// @dev Allow an external contract to mint a mercenary
    /// @dev Enables giveaways to supportive community members
    /// @dev Enables external contracts with permission to mint mercenaries for promotions
    /// @param to recipient
    /// @param amount of mint
    /// @param traits a 2 dimensional array representing the mercenaries traits e.g., [[7,2,5,1,1],[6,3,1,4,5]]
    function giveAway(address to, uint256 amount, uint16[][] calldata traits)
        external
        nonReentrant
        onlyAllowed
    {
        require( amount < 11,                                                           "You can mint a maximum of 10" );
        require( amount == traits.length,                                               "Amount and traits array should match");
        for(uint256 i = 0; i < amount; i++){                                            // Loop through the amount to mint
            uint256 tokenID = wTokenID;
            _storeStats(address(this),wTokenID);                                        // Then set the stats
            bytes32 underlyingTokenHash = hashUnderlyingToken(address(this),tokenID);
            underlyingToken[underlyingTokenHash].collectionAddress = address(this);     // Add Collection address to the mapping
            underlyingToken[underlyingTokenHash].tokenID = tokenID;                     // Add Token ID to the mapping
            wrappedCharacter[tokenID] = underlyingTokenHash;                            // Map the underlying token hash to the wrapped token id
            _updateTraits(wTokenID, traits[i]);                                          // Add Visual Traits for mercenary
            wTokenID++;                                                                 // Increment wrapped token id
        }
        _mint (to, amount);                                                             // Mint the Mercenaries
    }

    /// @dev Allow change in the prices
    /// @param _mercenaryPrice new price in ETH
    /// @param _traitPrice new price in ETH
    function setPrice(uint256 _mercenaryPrice, uint256 _traitPrice) 
        external
        onlyOwner
    {
        mercenaryPrice = _mercenaryPrice;
        traitPrice = _traitPrice;
    }

    /// @dev Withdraw ETH
    function withdrawAll()
        external
        payable
        onlyOwner
    {
        payable(_msgSender()).transfer(address(this).balance);
    }

    fallback() external payable { }
    
    receive() external payable { }

// VIEWS

    /// @dev Check if mercenary is a native (true) or wrapped (false)
    /// @param wrappedTokenID token id
    function isMercenary(uint256 wrappedTokenID)
        external
        view
        returns (bool mercenary)
        {
            (address collectionAddress,) = getCharactersID(wrappedTokenID);
            if (collectionAddress == address(this)) {return true;}
        }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Permissioned is AccessControlEnumerable {

    constructor () {
            _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }

// STATE VARIABLES

    /// @dev Defines the accessible roles
    bytes32 public constant ACCESS_ROLE = keccak256("ACCESS_ROLE");

// MODIFIERS

    /// @dev Only allows admin accounts
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not the owner");
        _; // Call the actual code
    }

    /// @dev Only allows accounts with permission
    modifier onlyAllowed() {
        require(hasRole(ACCESS_ROLE, _msgSender()), "Caller does not have permission");
        _; // Call the actual code
    }

// FUNCTIONS

  /// @dev Add an account to the access role. Restricted to admins.
  function addAllowed(address account)
    public virtual onlyOwner
  {
    grantRole(ACCESS_ROLE, account);
  }

  /// @dev Add an account to the admin role. Restricted to admins.
  function addOwner(address account)
    public virtual onlyOwner
  {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  /// @dev Remove an account from the access role. Restricted to admins.
  function removeAllowed(address account)
    public virtual onlyOwner
  {
    revokeRole(ACCESS_ROLE, account);
  }

  ///@dev Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.
  function transferOwnership(address newOwner) 
      public virtual onlyOwner
  {
      require(newOwner != address(0), "Permissioned: new owner is the zero address");
      addOwner(newOwner);
      renounceOwner();
  }

  /// @dev Remove oneself from the owner role.
  function renounceOwner()
    public virtual
  {
    renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

// VIEWS

  /// @dev Return `true` if the account belongs to the admin role.
  function isOwner(address account)
    public virtual view returns (bool)
  {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  /// @dev Return `true` if the account belongs to the access role.
  function isAllowed(address account)
    public virtual view returns (bool)
  {
    return hasRole(ACCESS_ROLE, account);
  }

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./WrappedCharacterActivity.sol";

contract WrappedCharacters is WrappedCharacterActivity {
    using Strings for string;

// CONSTRUCTOR

    constructor (string memory name, string memory symbol)
    WrappedCharacterActivity(name, symbol) {}

// STATE VARIABLES

    // @dev Track the wrapped token id
    uint256 internal wTokenID;

// FUNCTIONS

    /// @dev Wraps an NFT & mints a wrappedCharacter
    /// @param tokenID ID of the token
    /// @param collectionAddress address of the NFT collection
    function wrap(uint256 tokenID, address collectionAddress)
        external
        isWrappable(collectionAddress)
    {
        _wrap(collectionAddress, tokenID, wTokenID);    // Wrap the character
        (uint256 stamina,,,,,,,) = getStats(wTokenID);  // Get characters stamina
        if (stamina == 0) {                             // Has this token been wrapped before
           _storeStats(collectionAddress,tokenID);      // Then set the stats
        }
        _mint(_msgSender(),1);                          // Mint a wrapped character
        wTokenID++;                                     // Increment wrapped token id
    }

    /// @dev Unwraps an NFT & burns the wrappedCharacter
    /// @param wrappedTokenID ID of the token
    function unwrap(uint256 wrappedTokenID) 
        external
        onlyWrapped(wrappedTokenID)
    {
        _unwrap(wrappedTokenID);
        _burn(wrappedTokenID, true); // Approval check is set to true to ensure only the owner is allowed to burn tokens
    }
// VIEWS

    /// @dev Passes through the original token URI
    /// @dev Unless it's a mercenary
    /// @param wrappedTokenID ID of the token
    function tokenURI(uint256 wrappedTokenID)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory uri)
    {
        (address collectionAddress,uint256 tokenID) = getCharactersID(wrappedTokenID);
        if (collectionAddress == address(this)) {
            string memory _uri = super.tokenURI(wrappedTokenID);
            return string(abi.encodePacked(_uri,".json"));
        } else {
        return IERC721Metadata(collectionAddress).tokenURI(tokenID);
        }
    }

    function _baseURI() 
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return baseURI;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../characters/interfaces/IFarmlandCollectible.sol";
import "./WrappedCharacterManager.sol";

contract WrappedCharacterStats is WrappedCharacterManager {

// CONSTRUCTOR

    constructor (string memory name, string memory symbol)
    WrappedCharacterManager(name, symbol) {}

// STATE VARIABLES
   
    /// @dev Store the mapping for underlying characters to their stats
    mapping(bytes32 => uint16[]) internal stats;
    
    /// @dev Initialise the nonce used to generate pseudo random numbers
    uint256 private randomNonce;
    
// EVENTS

    event StatIncreased(address indexed account, uint256 wrappedTokenID, uint16 amount, uint256 statIndex);
    event StatDecreased(address indexed account, uint256 wrappedTokenID, uint16 amount, uint256 statIndex);

// EXTERNAL FUNCTIONS

    /// @dev Increases a stat
    /// @param wrappedTokenID ID of the token
    /// @param amount to increase
    /// @param statIndex index of stat
    function increaseStat(uint256 wrappedTokenID, uint16 amount, uint256 statIndex)
        public
        onlyAllowed
        onlyWrapped(wrappedTokenID)
    {
        bytes32 underlyingTokenHash = wrappedCharacter[wrappedTokenID];      // Get the underlying token hash
        uint16 currentStat = stats[underlyingTokenHash][statIndex];          // Get current stat
        uint16 maxStat = 99;                                                 // Set standard max stat
        if (statIndex == 5) {
            maxStat = getMaxHealth(wrappedTokenID);                          // Health has a different calculation for max stat
        }
        if (statIndex > 5) {
            maxStat = uint16(10000);                                         // Experience & Levels have a higher max stat
        }
        require(currentStat != maxStat,                                      "Stat already at maximum");
        if (currentStat + amount < maxStat + 1) {                            // Check to see if we'll go above the max stat value
            stats[underlyingTokenHash][statIndex] += amount;                 // Increase stat
        } else {
            stats[underlyingTokenHash][statIndex] = maxStat;                 // Set to max for the stat
        }
        emit StatIncreased(_msgSender(), wrappedTokenID, amount, statIndex); // Write an event to the chain
    }

    /// @dev Decreases a stat
    /// @param wrappedTokenID ID of the token
    /// @param amount to increase
    /// @param statIndex index of stat
    function decreaseStat(uint256 wrappedTokenID, uint16 amount, uint256 statIndex)
        public
        onlyAllowed
        onlyWrapped(wrappedTokenID)
    {
        bytes32 underlyingTokenHash = wrappedCharacter[wrappedTokenID];      // Get the underlying token hash
        uint16 currentStat = stats[underlyingTokenHash][statIndex];          // Get current stat
        require(currentStat > 1,                                             "Stat already at minimum");
        if (currentStat > amount) {                                          // Check to see if we'll go below the minimum stat of 1
            stats[underlyingTokenHash][statIndex] -= amount;                 // Decrease stat
        } else {
            stats[underlyingTokenHash][statIndex] = 1;                       // Set to minimum of 1
        }
        emit StatDecreased(_msgSender(), wrappedTokenID, amount, statIndex); // Write an event to the chain
    }

    /// @dev Set characters health to an arbitrary amount
    /// @param wrappedTokenID Characters ID
    /// @param amount to add
    function setHealthTo(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
        (,,,,,uint16 health,,) = getStats(wrappedTokenID);
        if (amount > health) {
            increaseStat(wrappedTokenID, amount - health, 5);
        } else {
            decreaseStat(wrappedTokenID, health - amount, 5);
        }
    }

    // /// @dev Increase a characters stamina
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to add
    // function increaseStamina(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _increaseStat(wrappedTokenID, amount, 0);
    // }

    // /// @dev Decrease a characters stamina
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to decrease by
    // function decreaseStamina(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _decreaseStat(wrappedTokenID, amount, 0);
    // }

    // /// @dev Increase a characters strength
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to add
    // function increaseStrength(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _increaseStat(wrappedTokenID, amount, 1);
    // }

    // /// @dev Decrease a characters strength
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to decrease by
    // function decreaseStrength(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _decreaseStat(wrappedTokenID, amount, 1);
    // }

    // /// @dev Increase a characters speed
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to add
    // function increaseSpeed(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _increaseStat(wrappedTokenID, amount, 2);
    // }

    // /// @dev Decrease a characters speed
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to decrease by
    // function decreaseSpeed(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _decreaseStat(wrappedTokenID, amount, 2);
    // }

    // /// @dev Increase a characters courage
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to add
    // function increaseCourage(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _increaseStat(wrappedTokenID, amount, 3);
    // }

    // /// @dev Decrease a characters courage
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to decrease by
    // function decreaseCourage(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _decreaseStat(wrappedTokenID, amount, 3);
    // }

    // /// @dev Increase a characters intelligence
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to add
    // function increaseIntelligence(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _increaseStat(wrappedTokenID, amount, 4);
    // }

    // /// @dev Decrease a characters intelligence
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to decrease by
    // function decreaseIntelligence(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _decreaseStat(wrappedTokenID, amount, 4);
    // }

    // /// @dev Increase a characters health
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to add
    // function increaseHealth(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _increaseStat(wrappedTokenID, amount, 5);
    // }

    // /// @dev Decrease a characters health but can't go below one
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to decrease by
    // function decreaseHealth(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _decreaseStat(wrappedTokenID, amount, 5);
    // }

    // /// @dev Increase a characters experience
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to add to the characters experience
    // function increaseExperience(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _increaseStat(wrappedTokenID, amount, 6);
    // }

    // /// @dev Decrease a characters experience
    // /// @param wrappedTokenID Characters ID
    // /// @param amount to decrease the characters experience
    // function decreaseExperience(uint256 wrappedTokenID, uint16 amount) external onlyAllowed {
    //     _decreaseStat(wrappedTokenID, amount, 6);
    // }

    // /// @dev Increase a characters level by 1
    // /// @param wrappedTokenID Characters ID
    // function increaseLevel(uint256 wrappedTokenID) external onlyAllowed {
    //     _increaseStat(wrappedTokenID, 1, 7);
    // }

    // /// @dev Increase a characters level by 1
    // /// @param wrappedTokenID Characters ID
    // function decreaseLevel(uint256 wrappedTokenID) external onlyAllowed {
    //     _decreaseStat(wrappedTokenID, 1, 7);
    // }

// INTERNAL FUNCTIONS

    /// @dev Import or generate character stats
    /// @param collectionAddress the address of the collection
    /// @param tokenID the id of the NFT to release
    function _storeStats(address collectionAddress, uint256 tokenID)
        internal
    {
        uint256 stamina; uint256 strength; uint256 speed; uint256 courage; uint256 intelligence; uint256 health;
        // Calculate the  underlying token hash
        bytes32 underlyingTokenHash = hashUnderlyingToken(collectionAddress,tokenID);
        // Ensure the stats haven't previously been generated
        require(stats[underlyingTokenHash].length == 0, "Traits can be created once");
        // If collection is native
        if (characterCollections[collectionAddress].native) {
            // Get Native Character stats
            (, stamina, strength, speed, courage, intelligence) = IFarmlandCollectible(collectionAddress).collectibleTraits(tokenID);
        } else  {
            // Otherwise generate some random stats
            uint16 range = characterCollections[collectionAddress].range;
            uint16 offset = characterCollections[collectionAddress].offset;
            uint256[] memory randomNumbers = new uint256[](5); // Define array to store random numbers
            randomNumbers = _getRandomNumbers(5);              // Return some random numbers
            // TODO: Test if this needs to be cast up to uint256
            stamina = (randomNumbers[0] % range) + offset;
            strength = (randomNumbers[1] % range) + offset;
            speed = (randomNumbers[2] % range) + offset;
            courage = (randomNumbers[3] % range) + offset;
            intelligence = (randomNumbers[4] % range) + offset;
        }
        // Calculate health
        health = (strength + stamina) / 2;
        if (strength > 95 || stamina > 95) // Give bonus for a Tank or Warrior
        {
            health += health / 2;
        }
        // Assign the stats (experience & level start at 0)
        stats[underlyingTokenHash] = [
            uint16(stamina),       // 0
            uint16(strength),      // 1
            uint16(speed),         // 2
            uint16(courage),       // 3
            uint16(intelligence),  // 4
            uint16(health),        // 5
            uint16(0),             // 6 - experience
            uint16(0)];            // 7 - level
    }

    /// @dev Returns an array of Random Numbers
    /// @param n number of random numbers to generate
    function _getRandomNumbers(uint256 n)
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

// VIEW FUNCTIONS

    /// @dev Returns the wrapped characters extended stats
    /// @param wrappedTokenID ID of the token
    function getStats(uint256 wrappedTokenID)
        public
        view
        returns (
            uint16 stamina, uint16 strength, uint16 speed, uint16 courage, uint16 intelligence, uint16 health, uint16 experience, uint16 level
        )
    {
        bytes32 underlyingTokenHash = wrappedCharacter[wrappedTokenID]; // Get the underlying token hash
        uint256 total = stats[underlyingTokenHash].length;
        if (total == 0) {return (0,0,0,0,0,0,0,0);}
        if (total > 0){stamina = stats[underlyingTokenHash][0];}
        if (total > 1){strength = stats[underlyingTokenHash][1];}
        if (total > 2){speed = stats[underlyingTokenHash][2];}
        if (total > 3){courage = stats[underlyingTokenHash][3];}
        if (total > 4){intelligence = stats[underlyingTokenHash][4];}
        if (total > 5){health = stats[underlyingTokenHash][5];}
        if (total > 6){experience = stats[underlyingTokenHash][6];}
        if (total > 7){level = stats[underlyingTokenHash][7];}
    }  

    /// @dev Returns a characters default max health
    /// @param wrappedTokenID Characters ID
    function getMaxHealth(uint256 wrappedTokenID)
        public
        view
        returns (
            uint16 health
        )
    {
        (uint16 stamina, uint16 strength,,,,,,) = getStats(wrappedTokenID); // Get Stats
        health = (strength + stamina) / 2;                                  // Calculate the characters health
        if (strength > 95 || stamina > 95)                                  // Tank or Warrior
        {
            health += health / 2;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./CollectionManager.sol";

struct UnderlyingToken {address collectionAddress; uint256 tokenID;}

contract WrappedCharacterManager is ERC721A, ERC721Holder, ReentrancyGuard, Pausable, CollectionManager {

// CONSTRUCTOR

    constructor (string memory name, string memory symbol)
    ERC721A(name, symbol) {}

// STATE VARIABLES
   
    /// @dev A permanent mapping to track the the underlying collection & token to a hash of the collection address & tokenID
    /// @dev Hash of (collection & tokenID) >> UnderlyingToken(collection, tokenID)
    mapping (bytes32 => UnderlyingToken) public underlyingToken;

    /// @dev A mapping to track the wrapped token to the underlying collection & token
    /// @dev The mapping is temporary as the wrapped character can be unwrapped (burned) & wrapped under another token id
    /// @dev wrappedTokenID >> hash of the UnderlyingToken
    mapping (uint256 => bytes32) public wrappedCharacter;
    
    /// @dev This stores the base URI used to generate the token ID
    string public baseURI;

// MODIFIERS

    /// @dev Only if a character is wrapped
    /// @param wrappedTokenID of character
    modifier onlyWrapped(uint256 wrappedTokenID) {
        require (_exists(wrappedTokenID),"Character does not exist");
        _; // Call the actual code
    }  

// EVENTS

    event Wrapped(address indexed account, address indexed collection, uint256 blockNumber, uint256 tokenID, uint256 wrappedTokenID, bytes32 underlyingTokenHash);
    event Unwrapped(address indexed account, address indexed collection, uint256 blockNumber, uint256 tokenID, uint256 wrappedTokenID, bytes32 underlyingTokenHash);

// FUNCTIONS

    /// @dev PUBLIC: Add an NFT to the contract
    /// @param collectionAddress the address of the collection
    /// @param tokenID the id of the NFT to release
    /// @param wrappedTokenID Characters ID
    function _wrap(address collectionAddress, uint256 tokenID, uint256 wrappedTokenID)
        internal
        nonReentrant
        whenNotPaused
        isWrappable(collectionAddress)
    {
        bytes32 underlyingTokenHash = hashUnderlyingToken(collectionAddress,tokenID);
        if (!UnderlyingTokenExists(collectionAddress, tokenID)) {                              // If this character has been wrapped previously then
            underlyingToken[underlyingTokenHash].collectionAddress = collectionAddress;        // Add Collection address to the mapping
            underlyingToken[underlyingTokenHash].tokenID = tokenID;                            // Add Token ID to the mapping
        }
        wrappedCharacter[wrappedTokenID] = underlyingTokenHash;                                // Map the underlying token hash to the wrapped token id
        emit Wrapped(_msgSender(), collectionAddress, block.number, tokenID, 
                     wrappedTokenID, underlyingTokenHash);                                     // Write an event
        IERC721(collectionAddress).safeTransferFrom(_msgSender(),address(this),tokenID);       // Transfer character to contract
    }

    /// @dev PUBLIC: Release an NFT from the contract
    /// @dev Relies on the Owner check being completed when the wrapped token is burned
    /// @param wrappedTokenID the id of the NFT to release
    function _unwrap(uint256 wrappedTokenID)
        internal
        nonReentrant
    {
        (address collectionAddress, uint256 tokenID) = getCharactersID(wrappedTokenID);         // Get the underlying token details
        bool characterExists = UnderlyingTokenExists(collectionAddress, tokenID);               // Check token UnderlyingTokenExists
        require(characterExists,                                                                "There is no token to unwrap");
        delete wrappedCharacter[wrappedTokenID];                                                // Delete mapping to underlying token hash
        emit Unwrapped(_msgSender(), collectionAddress, block.number, tokenID, 
                       wrappedTokenID, hashUnderlyingToken(collectionAddress, tokenID));        // Write an event
        IERC721(collectionAddress).transferFrom(address(this), _msgSender(), tokenID);          // Return Item to owner
    }
 // ADMIN FUNCTION

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

    // If the metadata needs to be moved
    function setBaseURI(string memory uri)
        external
        onlyOwner
    {
        baseURI = uri;
    }

// VIEW FUNCTIONS

    /// @dev Check mapping for wrapped character underlying token details
    /// @param wrappedTokenID Characters ID
    function getCharactersID(uint256 wrappedTokenID)
        public
        view
        returns (
            address collectionAddress,
            uint256 tokenID
            )
    {
        return (underlyingToken[wrappedCharacter[wrappedTokenID]].collectionAddress,  // Return collectionAddress
                underlyingToken[wrappedCharacter[wrappedTokenID]].tokenID);           // Return token ID
    }

    /// @dev Check if a token has been wrapped before
    /// @param collectionAddress the address of the collection
    /// @param tokenID the id of the NFT to release
    function UnderlyingTokenExists(address collectionAddress, uint256 tokenID)
        public
        view
        returns (
            bool tokenExists
            )
    {
        if (underlyingToken[hashUnderlyingToken(collectionAddress,tokenID)].collectionAddress != address(0)) {
            return (true);
        }
    }

    /// @dev Check mapping for wrapped character underlying token details
    /// @param collectionAddress the address of the collection
    /// @param tokenID the id of the NFT to release
    function hashUnderlyingToken(address collectionAddress, uint256 tokenID)
       public
       pure
       returns (
           bytes32 underlyingTokenHash
            )
    {
        underlyingTokenHash = keccak256(abi.encode(collectionAddress,tokenID));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721A, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WrappedCharacterStats.sol";

struct Activity {
    bool active;
    uint16 numberOfActivities;
    uint256 activityDuration;
    uint256 startBlock;
    uint256 endBlock;
    uint256 completedBlock;
}

/// @dev Farmland - Characters Activity Smart Contract
contract WrappedCharacterActivity is WrappedCharacterStats {

// CONSTRUCTOR

    constructor (string memory name, string memory symbol)
    WrappedCharacterStats(name, symbol) {}

// STATE VARIABLES

    /// @dev A mapping to track a characters activity
    mapping(uint256 => Activity) public charactersActivity;
       
// EVENTS

    event SetActive(address indexed account, uint256 wrappedTokenID, bool active);
    event BeginActivitySet(address indexed account, uint256 wrappedTokenID, uint256 activityDuration, uint16 numberOfActivities, uint256 startBlock, uint256 endBlock); 

// EXTERNAL FUNCTIONS

    /// @dev Update characters activity status
    /// @param wrappedTokenID Characters ID
    /// @param active the amount
    function setActive(uint256 wrappedTokenID, bool active)
        external
        onlyAllowed
        onlyWrapped(wrappedTokenID)
    {
        emit SetActive(_msgSender(), wrappedTokenID, active);                   // Write an event to the chain
        charactersActivity[wrappedTokenID].active = active;                     // Set active
        if (!active) {
            charactersActivity[wrappedTokenID].completedBlock = block.number;   // Set block at which the activity completes
        }
    }

    /// @dev Update characters Activity duration
    /// @param wrappedTokenID Characters ID
    /// @param activityDuration the duration of the activity
    /// @param numberOfActivities the of the activities
    /// @param startBlock the duration of the activity
    /// @param endBlock the duration of the activity
    function setBeginActivity(uint256 wrappedTokenID, uint256 activityDuration, uint16 numberOfActivities, uint256 startBlock, uint256 endBlock)
        external 
        onlyAllowed
        onlyWrapped(wrappedTokenID)
    {
        require(endBlock > startBlock,                                                  "End block should be higher than start");
        emit BeginActivitySet(_msgSender(), wrappedTokenID, activityDuration, 
                                    numberOfActivities, startBlock, endBlock);          // Write an event to the chain
        charactersActivity[wrappedTokenID].active = true;                               // Set active
        charactersActivity[wrappedTokenID].activityDuration = activityDuration;         // Set activity duration
        charactersActivity[wrappedTokenID].startBlock = startBlock;                     // Set start block
        charactersActivity[wrappedTokenID].endBlock = endBlock;                         // Set end block
        charactersActivity[wrappedTokenID].numberOfActivities = numberOfActivities;     // Set number of activies
    }

//VIEWS
   
    /// @dev Return a characters current health
    /// @dev Health regenerates whilst a Character is resting (i.e., not on a activity)
    /// @dev character regains 1 stat per activity duration for that character 
    /// @dev so the speedier the character the quicker to regenerate
    /// @param wrappedTokenID Characters ID
    function calculateHealth(uint256 wrappedTokenID)
        public
        view
        returns (
            uint16 health
        )
    {
        Activity storage activity = charactersActivity[wrappedTokenID];                  // Shortcut to characters activity
        uint16 maxHealth = getMaxHealth(wrappedTokenID);                                 // Get characters max health
        if (activity.endBlock == 0) {return maxHealth;}                                  // If there's been no activity return max health
        (,,,,,health,,) = getStats(wrappedTokenID);                                      // Get characters health
        if (block.number <= activity.endBlock) {                                         // If activity not ended
            uint256 blockSinceStartOfActivity = block.number - activity.startBlock;      // Calculate blocks since activity started
            // TODO: Calculate if this can be cast down safely
            health -= uint16(blockSinceStartOfActivity / activity.activityDuration);     // Reduce health used = # of blocks since start of activity / # of Blocks to consume One Health stat
        } else {
            if (activity.active) {                                                       // If ended but still active i.e., not completed then
                health -= activity.numberOfActivities;                                   // Reduce health by number of activities
            } else {
                uint256 blockSinceLastActivity = block.number - activity.completedBlock; // Calculate blocks since last activity finished
                // TODO: Calculate if this can be cast down safely
                health += uint16(blockSinceLastActivity / activity.activityDuration);    // Add health + health regenerated = # of blocks since last activity / # of Blocks To Regenerate One Health stat
                if (health > maxHealth) {return maxHealth;}                              // Ensure new energy amount doesn't exceed max health
            }
       }
    }

    /// @dev Return the number of blocks until a characters health will regenerate
    /// @param wrappedTokenID Characters ID
    function getBlocksToMaxHealth(uint256 wrappedTokenID)
        external
        view
        returns (
            uint256 blocks
        )
    {
        Activity storage activity = charactersActivity[wrappedTokenID];   // Shortcut to characters activity
        //TODO: Check if health needs to be cast down
        (,,,,,uint256 health,,) = getStats(wrappedTokenID);               // Get characters health
        if (!activity.active) {                                           // Character not on a activity
            uint256 blocksToMaxHealth = activity.completedBlock +         // Calculate blocks until health is restored
                                        (activity.activityDuration *
                                        (getMaxHealth(wrappedTokenID)- health));
            if (blocksToMaxHealth > block.number) {
                return blocksToMaxHealth - block.number;
            }
        }
    }

    /// @dev PUBLIC: Blocks remaining in activity, returns 0 if finished
    /// @param wrappedTokenID Characters ID
    function getBlocksUntilActivityEnds(uint256 wrappedTokenID)
        external
        view
        returns (
                uint256 blocksRemaining
        )
    {
        Activity storage activity = charactersActivity[wrappedTokenID];  // Shortcut to characters activity
        if (activity.endBlock > block.number) {
            return activity.endBlock - block.number;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Permissioned.sol";

struct Collection {bool native; uint16 range; uint16 offset;}

contract CollectionManager is Permissioned {

// CONSTRUCTOR

    constructor () Permissioned() {}

// STATE VARIABLES

    /// @dev Create an array to track the Character collections
    mapping(address => Collection) public characterCollections;

// MODIFIERS

    /// @dev Check if the collection is wrappable
    /// @param collectionAddress address of collection
    modifier isWrappable (address collectionAddress) {
        require(isCollectionEnabled(collectionAddress) && collectionAddress != address(this),"You can't wrap this token");
        _;
    }

// FUNCTIONS

    /// @dev Enables a NFT collection to be wrapped
    /// @param collectionAddress address of the NFT collection
    /// @param native is this a native Farmland NFT collection
    /// @param range the max range for non native stats i.e, when added to the offset the range gives the maximum stat
    /// @param offset the offset for not native stats i.e., the floor for stats
    function enableCollection(address collectionAddress, bool native, uint16 range, uint16 offset)
        external
        onlyOwner
    {
        characterCollections[collectionAddress].native = native;  // Add native to the collection mapping
        characterCollections[collectionAddress].range = range;    // Add range to the collection mapping
        characterCollections[collectionAddress].offset = offset;  // Add offset to the collection mapping
    }

    /// @dev Disables a NFT collection from being wrapped
    /// @param collectionAddress address of the NFT collection
    function disableCollection(address collectionAddress)
        external
        onlyOwner
    {
        delete characterCollections[collectionAddress];  // Delete the mapping
    }

// VIEWS

    /// @dev Is a NFT collection enabled for wrapping
    /// @param collectionAddress address of the NFT collection
    function isCollectionEnabled(address collectionAddress)
        public
        view
        returns (
            bool enabled
        )
    {
        if (characterCollections[collectionAddress].range > 0) {
            return true;
        }
    }

}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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

    // ==============================
    //        IERC721Metadata
    // ==============================

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
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;
    
    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID. 
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count. 
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly { // Cast aux without masking.
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Casts the address to uint256 without masking.
     */
    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev Casts the boolean to uint256 without branching.
     */
    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
            isApprovedForAll(from, _msgSenderERC721A()) ||
            getApproved(tokenId) == _msgSenderERC721A());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
                isApprovedForAll(from, _msgSenderERC721A()) ||
                getApproved(tokenId) == _msgSenderERC721A());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(from) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_BURNED | 
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), 
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length, 
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for { 
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            
            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
 * ```
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
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
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
            set._indexes[value] = set._values.length;
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
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}