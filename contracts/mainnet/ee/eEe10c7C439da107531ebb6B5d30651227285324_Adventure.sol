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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface ISkillbook {
    function useMana(uint8 _amount, uint256 _wizId) external returns(bool);
}

interface IItems {
    function mintItems(address _to, uint256[] memory _itemIds, uint256[] memory _amounts) external;
    function getWizardStats(uint256 _wizId) external returns (uint256[5] memory);
}

interface IArcane {
    function ownerOf(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function balanceOf(address owner) external view returns (uint256);
    function getWizardInfosIds(uint256 _wizId)
        external
        view
        returns (uint256[5] memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IEvents {
    function getEvents(uint256 _wizId, uint256 _tile) external returns (Event[] memory);
}

interface ILoot{
    function getLoot(uint256 _zoneId, uint256 _tile, uint256 _eventAmount, uint256 _wizId, bool passedSpecial) external returns(uint256[] memory lootIds, uint256[] memory lootAmounts);
}

interface IConsumable{
     function getBonus (uint256 _wizId, uint256 _bonusId) external returns(uint256);
}

interface ICoinReward {
    function tryReward(uint256 _wizId, uint256 _zoneId, bool _special) external;
}

struct Event {
    uint8 eventType;
    uint256 rand;
} 

 struct State {
        address quester;
        uint256 startTime;
        uint256 currX;
        uint256 currY;
        bool reward;
    }

struct RewardData{
    uint256 currZone;
    uint256 tile;
    uint256 passedEvents;
    uint256 luckPerc;
    uint256 gearPerc;
    int lvlDelta;
    uint256[5] wizStats;
}




contract Adventure is IERC721Receiver, Ownable, ReentrancyGuard {

   
    event MoveToTile(
        uint256 wizId,
        uint256 zoneId,
        uint256 targetX,
        uint256 targetY
    );

    event RevealQuest(
        uint256 wizId,
        uint256[] eventIds,
        uint256[] lootIds
    );

    event RetrieveWizard(
        uint256 wizId
    );

    IItems public ITEMS;
    IArcane public ARCANE;
    IEvents public EVENTS;
    ILoot public LOOT;
    ISkillbook public SKILLBOOK;
    IConsumable public CONSUMABLE;
    ICoinReward public COINREWARD;

    uint256 private QUEST_TIME; 
    uint256 private MAX_LVL;
    uint256 private xpPointsDivider;

    bool private pausedQuesting;

    mapping (uint256 => uint256[][]) public tileValues;
    mapping (uint256 => State) public states;
    mapping (uint256 => uint256) public currZones;
    // starting coordinate for each zone
    mapping (uint256 => uint256) public startX;
    mapping (uint256 => uint256) public startY;

    // amount of xp needed to lvl up
    mapping (uint256 => uint256) public xpPerLevel;
    // each wiz XP
    mapping (uint256 => uint256) public wizardsXp;
    mapping (uint256 => uint256) public zoneItemLevel;

    // query last event
    mapping (uint256 => uint256[]) public questEvents;
    mapping (uint256 => uint256[]) public questItemIds;

    // EXTERNAL
    // ------------------------------------------------------

    function moveToTile(uint256 _wizId, uint256 _zoneId, uint256 _targetX, uint256 _targetY) external nonReentrant {
         require(
            ARCANE.ownerOf(_wizId) == msg.sender
            || states[_wizId].quester == msg.sender,
            "You don't own this Wizard"
        );
        require(_hoursElapsed(states[_wizId].startTime)>=QUEST_TIME, "You're currently questing");
        require(!states[_wizId].reward, "Reveal your loot before questing again");
        _getTileValue(_zoneId, _targetX, _targetY);
        
        // remove mana
        uint256 manaCost = 120;
        int lvlDelta = int(getLevel(_wizId)) - int(_zoneId);
        if(lvlDelta>0){
            for(uint i=0;i<uint(lvlDelta);i++){
                manaCost -=5;
            }
        } 

        if(manaCost<70) manaCost =70;
        manaCost -= CONSUMABLE.getBonus(_wizId, 0);
        bool hasEnoughMana = SKILLBOOK.useMana(uint8(manaCost), _wizId);
        require(hasEnoughMana, "Not enough mana");
       
        State memory currState = states[_wizId];

        uint256 newX;
        uint256 newY;
        if(currZones[_wizId] !=_zoneId){
            // use starting coord
            newX = startX[_zoneId];
            newY = startY[_zoneId];
            currZones[_wizId] = _zoneId;
        } else{
            int xDelta = int(currState.currX) - int(_targetX);
            int yDelta = int(currState.currY) - int(_targetY);
            if(yDelta==0){
                require(xDelta!=0, "Cannot move to current tile");
            }
            uint256 giantLeap = CONSUMABLE.getBonus(_wizId,6);
            require(abs(xDelta) <=int(1+giantLeap) && abs(yDelta) <=int(1+giantLeap), "You cannot move that far!");
            newX = _targetX;
            newY = _targetY; 
        }

        // edit position
        State memory newPos = State(msg.sender, block.timestamp, newX, newY, true);
        states[_wizId] = newPos;
        
       
        // move Wizard if not done already
        if(ARCANE.ownerOf(_wizId)!=address(this)){
            ARCANE.safeTransferFrom(msg.sender, address(this), _wizId);
        }

        emit MoveToTile(_wizId, _zoneId, _targetX, _targetY);
    }
 
    function revealQuest(uint256 _wizId) external  {
        require(states[_wizId].quester==msg.sender, "You don't own this Wizard");
        require(states[_wizId].reward, "You are not on an adventure.");
        RewardData memory data;
        data.currZone = currZones[_wizId];
        data.tile = _getTileValue(data.currZone, states[_wizId].currX, states[_wizId].currY);
       
        // get events: [ [eventId,rand] , [eventId, rand], ... ]
        Event[] memory events = EVENTS.getEvents(_wizId, data.tile );

        data.passedEvents =1;
        // percentage of luck
        data.luckPerc= 25;
        // percentage of gear impact on success
        data.gearPerc=75;
        data.lvlDelta = int(getLevel(_wizId) - data.currZone);
        data.wizStats= ITEMS.getWizardStats(_wizId);
        // account bonuses/consumables
        for(uint i =0;i<data.wizStats.length;i++){

            data.wizStats[i]+=CONSUMABLE.getBonus(_wizId,i+1);
        }
        // if wizard is less than 2 levels compared to current zone, readjust luck weights
        if(data.lvlDelta<-2){
            data.luckPerc=15;
            data.gearPerc=85;
        }

        // Passing Events

        
        bool passedSpecial;
        // we start at 1 because first event is always passed
        for(uint i=1;i<events.length;i++){
            uint256 minToPass = 100;
            // luckroll - reduces the minimum to pass with luck, maximum dicated by data.luckPerc
            uint luckRoll =uint(keccak256      
            (abi.encodePacked(_wizId,events[i].rand,block.timestamp, data.wizStats[0]))) % data.luckPerc;
            minToPass-=luckRoll;

            // gear roll - reduces the minimum to pass thanks to gear. Maximum is 50
            // zoneItemLevel is a static value per zone which dictactes the optimal stat level for that zone
            // formula = 50 * (currStat/LvlStat) = (50 * currStat) / lvlStat
            uint256 gearRoll =  50 * (data.wizStats[_eventToStat(events[i].eventType)]) / zoneItemLevel[currZones[_wizId]];
            if(gearRoll>50) gearRoll =50;

            minToPass-=gearRoll;

            if(events[i].rand >= minToPass){
                data.passedEvents++;
                if(events[i].eventType==4){
                    passedSpecial=true;
                }
            }else{
                break;
            }

            
        }
        
       
        // erc20
        if(COINREWARD!=ICoinReward(address(0))){
            COINREWARD.tryReward(_wizId, data.currZone, passedSpecial);
        }

        // give out XP
        _giveXP(_wizId, data.passedEvents);

        // get rewards
        uint256[] memory lootIds;
        uint256[] memory lootAmounts;
        (lootIds,lootAmounts) = LOOT.getLoot(data.currZone,data.tile, events.length, _wizId, passedSpecial);
        for(uint i=0;i<lootIds.length;i++){
        }
        ITEMS.mintItems(msg.sender, lootIds,lootAmounts);

        // flag showing reward has been claimed and quest ended
        State memory currState = states[_wizId];
        currState.reward = false;
        states[_wizId] = currState;

        // save result for engine
        uint256[] memory eventIds = new uint256[](events.length);
        for(uint i = 0;i<eventIds.length;i++){
            eventIds[i]=events[i].eventType;
        }
        questEvents[_wizId] = eventIds;
        questItemIds[_wizId] = lootIds;

        emit RevealQuest(_wizId, eventIds, lootIds);

    }   

    function retrieveWizard(uint256 _wizId) external {
        require(states[_wizId].quester==msg.sender, "You don't own this Wizard");
        require(_hoursElapsed(states[_wizId].startTime)>=QUEST_TIME, "You're currently questing");
        require(!states[_wizId].reward, "Reveal your loot before retrieving");
        ARCANE.safeTransferFrom(address(this),msg.sender, _wizId);
        State memory currState = states[_wizId];
        currState.currX = currState.currY = 0;  
        states[_wizId] = currState;
        emit RetrieveWizard(_wizId);
    }

    function forceQuesterChange(uint256 _wizId) external {
        require(ARCANE.ownerOf(_wizId)==msg.sender, "Not the owner");
         State memory currState = states[_wizId];
        currState.quester = msg.sender;
        states[_wizId] = currState;
    }

    function getTilePopulation(uint256 _zoneId, uint256 _x, uint256 _y) external view returns (address[] memory){
        uint256[] memory allQuesters = getAllQuesters();
        address[] memory questing = new address[](allQuesters.length);
        uint256 counter= 0;
        for(uint i=0;i<allQuesters.length;i++){
            uint256 wizId = allQuesters[i];
            if(currZones[wizId]==_zoneId
            && states[wizId].currX == _x
            && states[wizId].currY == _y){
                questing[counter] = states[wizId].quester;
                counter++;
            }
        }
        address[] memory population = new address[](counter);
        for(uint i=0;i<counter;i++){
            population[i] = questing[i];
        }
        return population;
    }

    function getAdventureState(uint256 _wizId) external view returns (uint256 zone, uint256 posX, uint256 posY ){
        return(currZones[_wizId], states[_wizId].currX,states[_wizId].currY);
    }

    function getWizardXp(uint256 _wizId) external view returns (uint256 xp){
        return(wizardsXp[_wizId]);
    }

    function getQuesters(address _owner) external view returns(uint256[] memory){
        uint256[] memory allQuesters = getAllQuesters();
        uint256[] memory wizIds = new uint256[](allQuesters.length);
        uint256 counter=0;

        for(uint i=0;i<allQuesters.length;i++){
            uint256 wizId = allQuesters[i];
            if(states[wizId].quester==_owner){
                wizIds[counter] = wizId;
                counter++;
            }
        }
        uint256[] memory ownedQuesters = new uint256[](counter);
        for(uint i=0;i<counter;i++){
            ownedQuesters[i] = wizIds[i];
        }
        return ownedQuesters;
    }

    function getLatestQuestResult(uint256 _wizId) external view returns(uint256[] memory, uint256[] memory){
        return(questEvents[_wizId],questItemIds[_wizId]);
    }

    function getLevel(uint256 _wizId) public view returns(uint256){
        uint256 currLevel=0;
        for(uint i=0;i<MAX_LVL;i++){
            if(wizardsXp[_wizId]>=xpPerLevel[i]){
                currLevel++;
            }else{
                return currLevel;
            }
        }
        return MAX_LVL;
    }

      function getAllQuesters() public view returns(uint256[] memory){
        uint256[] memory search = new uint256[](5555);
        uint256 counter = 0;
        for(uint i=0;i<5555;i++){
             try ARCANE.ownerOf(i) returns (address) {
                if(ARCANE.ownerOf(i)==address(this)){
                    search[counter]=i;
                    counter++;
                }
            } catch {
                continue;
            }
            
        }
        uint256[] memory questers = new uint256[](counter);
        for(uint i=0;i<counter;i++){
            questers[i] = search[i];
        }
        return questers;
    }

    // INTERNAL
    // ------------------------------------------------------


    function _getTileValue(uint256 _zoneId, uint256 _x, uint256 _y) internal view returns(uint256){
        require(_x >= 0 && _y >= 0, "Move not valid");
        require(tileValues[_zoneId][_x][_y]!=0, "Tile is empty");
        return tileValues[_zoneId][_x][_y];
    }

    function _giveXP(uint256 _wizId, uint256 _eventsAmount) internal {
        if(wizardsXp[_wizId]<xpPerLevel[MAX_LVL]){
            uint256 currLevelTotal = xpPerLevel[currZones[_wizId]];
            if(currZones[_wizId]>0){
                currLevelTotal -= xpPerLevel[currZones[_wizId]-1];
            }
            uint256 earnedPoints = currLevelTotal / xpPointsDivider;
            uint256 rand =uint(keccak256(abi.encodePacked(_wizId, block.timestamp, _eventsAmount))) % 4;
            earnedPoints += rand;
            wizardsXp[_wizId]+=earnedPoints;
        }
    }

    function onERC721Received(
        address,
        address, 
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _hoursElapsed(uint256 _time) internal view returns (uint256) {
        if (block.timestamp <= _time) {
            return 0;
        }

        return (block.timestamp - _time) / (60 * 60);
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    function _eventToStat(uint256 _eventId) internal pure returns(uint256){
        if(_eventId==0){
            // EXPLORE -> Focus
            return 0;
        }else if(_eventId==1){
            // ADVENTURE -> Strength
            return 1;
        }else if(_eventId==2){
            // COMBAT -> Spell
            return 3;
        }else if(_eventId==3){
            // REST -> Endurance
            return 4;
        }else {
            // SPECIAL -> Intellect
            return 2;
        }
    }

    // OWNER
    // ------------------------------------------------------

    function setItems(address _items) external onlyOwner {
        ITEMS = IItems(_items);
    }

    function setZone(uint256 _size, uint256[] memory _gridValues, uint256 _zoneId, uint256 _startX, uint256 _startY) external onlyOwner{
        require(pausedQuesting, "Pause quests before updating zones");
        uint256 counter=0;
        uint256[20][20] memory temp;
        for(uint x = 0;x<_size;x++){
            for(uint y = 0;y<_size;y++){
                temp[x][y]= _gridValues[counter];
                counter++;
            }
        }
        tileValues[_zoneId] = temp;
        startX[_zoneId]=_startX;
        startY[_zoneId]=_startY;
    }

    function pauseQuesting(bool _flag) external onlyOwner{
        pausedQuesting= _flag;
    }

     function setAddresses(address[] memory _addresses) external onlyOwner {
        ARCANE = IArcane(_addresses[0]);
        LOOT = ILoot(_addresses[1]);
        EVENTS = IEvents(_addresses[2]);
        SKILLBOOK = ISkillbook(_addresses[3]);
        COINREWARD = ICoinReward(_addresses[4]);
        CONSUMABLE = IConsumable(_addresses[5]);
    }

    function setQuestTime(uint256 _newTime) external onlyOwner{
        QUEST_TIME=_newTime;
    }

    function setMaxLevel(uint256 _maxLevel) external onlyOwner{
        MAX_LVL=_maxLevel;
    }

    // Start: 100
    function setXpPointsDivider(uint256 _divider) external onlyOwner{
        xpPointsDivider=_divider;
    }

    function setZoneItemLevels(uint256[] memory _zoneIds, uint256[] memory _itemLevels) external onlyOwner{
        for(uint i=0;i<_zoneIds.length;i++){
            zoneItemLevel[_zoneIds[i]] = _itemLevels[i];
        }
    }

     function setXpPerLevel(uint256[] memory _lvlIds, uint256[] memory _xpPerLevels) external onlyOwner{
        for(uint i=0;i<_lvlIds.length;i++){
            xpPerLevel[_lvlIds[i]] = _xpPerLevels[i];
        }
    }

     function setWizXp(uint256[] memory _wizIds, uint256[] memory _wizXp) external onlyOwner{
        for(uint i=0;i<_wizIds.length;i++){
            wizardsXp[_wizIds[i]] = _wizXp[i];
        }
    }

   
}