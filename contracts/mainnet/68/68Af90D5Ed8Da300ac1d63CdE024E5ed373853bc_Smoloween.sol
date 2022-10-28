// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC1155Like {
    function mint(address to, uint256 id) external;
}

interface IRandomizerLike {
    function isRandomReady(uint256 _requestId) external view returns(bool);
    function requestRandomNumber() external returns(uint256);
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);
}

abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract Smoloween is ERC721TokenReceiver {

    // --------
    //  EVENTS
    // --------

    event Staked(address owner, uint256 gameId, uint256 requestId);
    event Unstaked(address owner, uint256  smolId, uint256 gameId);
    event SentToCopy(address sender, uint256 gameId, uint256 sidekickId, uint256 targetId, uint256 trait, uint256 day);
    event SentToAttack(address sender, uint256 gameId, uint256 targetId, uint256 day);
    event Converted(uint256 smol, uint256 day);
    event CopyResolved(uint256 gameId, uint256 sidekickId, uint256 targetId, uint256 trait, bool success);
    event AttackResolved(uint256 targetId, bool success, uint256 attackers, uint256 defenders);
    event WitchAttack(uint256 gameId, bool success, uint256 day);
    event Midnight(uint256 newDay, uint256 enstropy);
    event RandomnessRequested(uint256 day, uint256 requestId);

    // ------------------
    // STATE VARIABLES
    // ------------------

    bool public ended;
    bool public paused;

    address public sbtContract; // 0x6325439389E0797Ab35752B4F43a14C004f22A9c
    address public randomizer;  // 0x8e79c8607a28fe1EC3527991C89F1d9E36D1bAd9
    address public gameMaster;

    uint256 public currentDay;
    uint256 public maxPlayers;
    uint256 public stakedSmols;
    uint256 public lastMidnightTimestamp;

    uint256 public sidekickCount;

    // Not proud of this, but Arbitrum is cheap enough that we can get away with it.
    uint16[] public smols;
    uint16[] public ghouls;
    uint16[] public battlesToResolve;
    uint24[] public copiesToResolve;

    mapping (address => uint256) public players; // Address of the player to the gameId

    mapping (uint256 => uint256) public dayRequests;  // Requests ids for randomness for the game master.
    mapping (uint256 => uint256) public rdnRequests;  // Each player requests a random seed for the duration of the game.

    mapping (uint256 => Sidekick)  public sidekicks;
    mapping (uint256 => Character) public characters;

    mapping (uint256 => mapping(uint256 => Battle)) public battles; // smol -> day -> battle.
 
    struct Sidekick {
        uint16 owner;
        uint16 target;
        uint8 day;
        uint8 trait;
    }

    struct Character {
        address owner;
        uint16  index;
        uint8   lastDay;
        bool    isGhoul;
        uint8[5] costume; // mask - shirt - hat - trinket - backdrop 
    }

    struct Battle {
        uint16 attackers;
        uint16 defenders;
        uint16 dispatched;
    }

    uint256 constant ONE_PERCENT = type(uint256).max / 100;

    // ------------------
    //  MODIFIERS
    // ------------------

    modifier onlyGameMaster() {
        require(msg.sender == gameMaster, "Only game master");
        _;
    }

    modifier onlyWhenNotPaused() {
        require(!paused, "Game is paused");
        _;
    }

    modifier onlyWhenPaused() {
        require(paused, "Game is not paused");
        _;
    }

    // ------------------
    // TEST FUNCTION - REMOVE
    // ------------------

    function setCurrentDay(uint256 _day) external  {
        currentDay = _day;
    }

    // ------------------
    // INITIALIZE
    // ------------------

    function initialize(uint256 maxPlayers_, address smol_, address randomizer_) external {
        require(gameMaster == address(0), "Already initialized");
        gameMaster = msg.sender;
        sbtContract  = smol_;
        randomizer    = randomizer_;

        maxPlayers = maxPlayers_;

        sidekickCount = 5;
    }

    // ------------------
    // STAKING FUNCTIONS
    // ------------------

    /// @dev Create a character to partake in the game. Must own a special soulbound NFT.
    function joinGame() external returns (uint256 gameId) {
        gameId = ++stakedSmols;

        require(players[msg.sender] == 0, "already playing");
        require(currentDay == 0,          "game has already started");
        require(gameId <= maxPlayers,     "max players reached");

        IERC1155Like(sbtContract).mint(msg.sender, 1); // Id 1 is for all players.

        // Request random number for day 0
        uint256 requestId = IRandomizerLike(randomizer).requestRandomNumber();
        
        // Save request id and character information;
        players[msg.sender] = gameId;
        rdnRequests[gameId] = requestId;
        characters[gameId]  = Character(msg.sender, uint16(smols.length), 0, false, [0,0,0,0,0]);

        smols.push(uint16(gameId));

        emit Staked(msg.sender, gameId, requestId);
    }

    // -----------------------
    //   PLAYERS FUNCTIONS
    // -----------------------

    /// @dev Used for ghouls to attack a given smol
    function attack(uint256 ghoulId, uint256 target) external onlyWhenNotPaused {
        Character memory char = characters[ghoulId];

        require(currentDay > 0,                         "game hasn't started yet");
        require(char.owner == msg.sender,               "not the owner");
        require(char.isGhoul,                           "not a ghoul");
        require(char.lastDay < currentDay,              "already done action for the day");
        require(!characters[target].isGhoul,            "target is already a ghoul");
        require(characters[target].owner != address(0), "target doesn't exist");

        // Since attacks are per target, we only need to have one in the array.
        if (battles[target][currentDay].attackers == 0) {
            battlesToResolve.push(uint16(target));
        }

        battles[target][currentDay].attackers++;
        characters[ghoulId].lastDay = uint8(currentDay);

        emit SentToAttack(msg.sender, ghoulId, target, currentDay);
    }

    /// @dev Used for smols to send sidekicks to copy traits from other smols
    function sendToCopy(uint256 gameId, uint256[] calldata sidekickIds, uint256[] calldata targets, uint256[] calldata traits) external onlyWhenNotPaused {
        require(currentDay > 0,                                                          "game hasn't started yet");
        require(msg.sender == characters[gameId].owner,                                  "not the owner");
        require(sidekickIds.length == targets.length && targets.length == traits.length, "Mismatched arrays");

        for (uint256 i = 0; i < sidekickIds.length; i++) {
            uint256 sidekickId = sidekickIds[i];

            Sidekick memory sk = sidekicks[sidekickId];

            require(!characters[gameId].isGhoul,                        "ghouls can't send sidekicks");
            require(canControlSidekick(gameId, sidekickId, currentDay), "not your sidekick");
            require(sk.day < currentDay,                                "sidekick already on a mission");

            copiesToResolve.push(uint24(sidekickId));

            uint256 target = targets[i];
            uint256 trait  = traits[i];

            // Send smol on a mission
            battles[target][currentDay].defenders++;
            battles[gameId][currentDay].dispatched++;

            // Update the sidekick struct
            sidekicks[sidekickId] = Sidekick(uint16(gameId), uint16(target), uint8(currentDay), uint8(trait));

            emit SentToCopy(msg.sender, gameId, sidekickId, target, trait, currentDay);
        }
    }

    // -----------------------
    //   GAME MASTER FUNCTIONS
    // -----------------------

    /// @dev Used to perform all of the actions on the midnight event. We might need too much processing for one transaction tho, so auxiliary functions are provided to perform actions individually.
    /// @param smolsToAttack the amount of smols that the Witch will attack
    /// @param additionalSidekicks How many sidekicks, if any, remaning smols will earn.
    function midnight(uint256 smolsToAttack, uint256 additionalSidekicks) external onlyGameMaster onlyWhenPaused {
        require(msg.sender == gameMaster);

        // Copy traits
        resolveTraitCopies(copiesToResolve.length);

        // Resolve ghoul attacks
        resolveGhoulsAttacks();

        // Witch attack smols
        convertSmols(smolsToAttack);

        // Require that we do not have any pending resolutions for the round
        require(battlesToResolve.length == 0, "pending attacks");
        require(copiesToResolve.length == 0,  "pending copies");

        // Clean up for the next day
        currentDay++;
        paused = false;
        lastMidnightTimestamp = block.timestamp;

        sidekickCount += additionalSidekicks;

        emit Midnight(currentDay, _random(dayRequests[currentDay - 1]));
    }

    /// @dev Used to resolve all of ghoul the attacks that happened during the day
    function resolveGhoulsAttacks() public onlyWhenPaused {
        uint256 day    = currentDay;
        uint256 length = battlesToResolve.length;

        for (uint256 i = length; i > 0; i--) {

            Battle memory battle = battles[day][battlesToResolve[i - 1]];

            uint256 armySize = amountOfSidekicks(); 

            bool success;
            if (battle.attackers > battle.defenders + (armySize - battle.dispatched)) {
                _convert(battlesToResolve[i - 1]);
                success = true;
            }
            
            emit AttackResolved(battlesToResolve[i - 1], success, battle.attackers, battle.defenders + (armySize - battle.dispatched));

            battlesToResolve.pop();
        }
    }

    /// @dev Used to resolve all trait copying for the day
    function resolveTraitCopies(uint256 amount) public onlyWhenPaused {
        uint256 today  = currentDay;
        uint256 length =  copiesToResolve.length;

        // Go over all copies to resolve
        for (uint256 i = length; i > length - amount; i--) {

            uint256 sidekickId = copiesToResolve[i - 1];
            Sidekick memory sk = sidekicks[sidekickId];

            if (sk.day == today) { 

                bool success = _canCopy(sidekickId, today);   
                if (success) {
                    characters[i].costume[sk.trait] = uint8(getCostumeTrait(sk.target, sk.trait));
                } 
                emit CopyResolved(sidekickId / 100, sidekickId, sk.target, sk.trait, success);
                copiesToResolve.pop();

                continue;
            }
        }

    }


    /// @dev Used to convert smols to ghouls by the Witch
    function convertSmols(uint256 quantity) public onlyGameMaster onlyWhenPaused {
        require(quantity <= smols.length, "not enough smols");

        uint256 rdn = _random(dayRequests[currentDay]);
        
        for (uint256 i = 0; i < quantity; i++) {
            // Since the array is being shuffled each time, we need to calculate the index to be checked at every iteration.
            uint256 index  = uint256(keccak256(abi.encode(rdn, i))) % smols.length;
            uint256 smolId = smols[index];

            bool canAttack = _canConvert(smolId, currentDay);
            
            if (canAttack) _convert(smolId);

            emit WitchAttack(smolId, canAttack, currentDay);
        }

    }

    /// @dev Used to request the random number for the midnight operation. This pause the games until the gamemaster complete all actions that should take place during midnight
    function requestRandomnessForDay() public onlyGameMaster {
        uint256 requestId = IRandomizerLike(randomizer).requestRandomNumber();

        dayRequests[currentDay] = requestId;

        paused = true;

        emit RandomnessRequested(currentDay, requestId);
    }

    function setRandomizer(address newRandomizer) external onlyGameMaster {
        randomizer = newRandomizer;
    } 

    // ------------------
    //  VIEW FUNCTIONS
    // ------------------

    /// @dev Used to check if a sidekick can be controlled by a smol
    function canControlSidekick(uint256 gameId, uint256 siekickId, uint256 day) public view returns (bool can) {
        uint256 start = gameId * 100 + 1;
        uint256 end   = start + amountOfSidekicks() - 1;

        can = siekickId >= start && siekickId <= end;
    }

    function getCostumeTrait(uint256 gameId, uint256 trait) public view returns (uint256 traitEquipped) {
        traitEquipped = characters[gameId].costume[trait];

        // If the data structure is empty, then we get the original costume for that Smol
        if (traitEquipped == 0) {
            uint8[5] memory costume_ = _getCostumeFromSeed(_random(rdnRequests[gameId]));
            traitEquipped = costume_[trait];
        }
    }

    function getSmolCostume(uint256 gameId) public view returns (uint8[5] memory costume) {
        uint8[5] storage savedCostume = characters[gameId].costume;
        uint8[5] memory  initialCostume = _getCostumeFromSeed(_random(rdnRequests[gameId]));
        
        for (uint256 i = 0; i < 5; i++) {
            costume[i] = savedCostume[i] == 0 ? initialCostume[i] : savedCostume[i];
        }
    }

    function getSidekickCostume(uint256 sidekickId) public view returns (uint8[5] memory) {
        uint256 gameId = sidekickId / 100;
        uint256 seed = uint256(keccak256(abi.encodePacked(_random(rdnRequests[gameId]), sidekickId))); 

        return _getCostumeFromSeed(seed);
    }

    function getWitchCostume(uint256 day) public view returns (uint8[5] memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(_random(dayRequests[day - 1]), "WITCH")));

        return _getCostumeFromSeed(seed);
    }

    function smolsRemaining() public view returns (uint256) {
        return smols.length;
    }

    function amountOfGhouls() public view returns (uint256) {
        return ghouls.length;
    }

    function amountOfSidekicks() public view returns (uint256) {
        return currentDay == 0 ? 0 : sidekickCount;
    }

    function copiesToResolveLength() public view returns (uint256) {
        return copiesToResolve.length;
    }

    function getSidekicks(uint256 gameId) public view returns (uint24[] memory ids) {
        uint256 start = gameId * 100 + 1;
        uint256 count = amountOfSidekicks();

        ids = new uint24[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = uint24(start + i);
        }

    }

    // ------------------
    //  INTERNAL HELPERS
    // ------------------   

    /// @dev Used check if a sidekick can copy a trait from a smol
    function _canCopy(uint256 sidekickId, uint256 day) internal view returns (bool) {
        uint256 copySeed = uint256(keccak256(abi.encode(_random(dayRequests[day]), sidekickId, "TRAIT COPY")));

        return copySeed <= 50 * ONE_PERCENT;
    }

    /// @dev Used check if the witch can convert a smol
    function _canConvert(uint256 gameId, uint256 day) internal view returns (bool) {
        uint8[5] memory smolCostume  = getSmolCostume(gameId);
        uint8[5] memory witchCostume = getWitchCostume(day);
        uint256 inCommon;

        for (uint256 index = 0; index < 5; index++) {
            inCommon += smolCostume[index] == witchCostume[index] ? 1 : 0;
        }

        uint256 seed = _randomize(_random(dayRequests[day]), "WITCH CONVERSION");

        return seed > inCommon * 20 * ONE_PERCENT;
    }

    /// @dev Converts a smol to a ghoul
    function _convert(uint256 gameId) internal {
        Character memory char = characters[gameId];

        require(!char.isGhoul,               "already a ghoul");
        require(gameId == smols[char.index], "wrong index");  // Shouldn't happen, but just in case

        characters[smols[smols.length - 1]].index = char.index;

        smols[char.index] = smols[smols.length - 1];
        smols.pop();

        // Update the ghouls array
        ghouls.push(uint16(gameId));

        characters[gameId].isGhoul = true;
        characters[gameId].index   = uint8(ghouls.length - 1);

        IERC1155Like(sbtContract).mint(char.owner, 2); // Id 2 is for ghouls.

        emit Converted(gameId, currentDay);
    } 

    function _random(uint256 request) internal view returns (uint256 rdn) {
        rdn = IRandomizerLike(randomizer).revealRandomNumber(request);
    }

    function _getCostumeFromSeed(uint256 costumeSeed) internal pure returns (uint8[5] memory costume) {
        costume[0] = _getTrait(_randomize(costumeSeed, "MASK"));
        costume[1] = _getTrait(_randomize(costumeSeed, "SHIRT"));
        costume[2] = _getTrait(_randomize(costumeSeed, "HAT"));
        costume[3] = _getTrait(_randomize(costumeSeed, "TRINKET"));
        costume[4] = _getTrait(_randomize(costumeSeed, "BACKDROP"));
    }


    function _getTrait(uint256 seed) internal pure returns (uint8 trait) {
        if (seed <= ONE_PERCENT * 45) return (uint8(seed) % 3) + 1;
        if (seed <= ONE_PERCENT * 79) return (uint8(seed) % 3) + 4;
        if (seed <= ONE_PERCENT * 95) return (uint8(seed) % 2) + 7;
        if (seed <= ONE_PERCENT * 99) return 9;
        return 10;
    }

    function _randomize(uint256 seed, bytes32 salt) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, salt)));
    }

}