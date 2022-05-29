pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IAltar{
    function authoriseLevelUp (uint256 _wizId, uint256 _lvl) external;
}

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

struct Event {
    uint8 eventType;
    uint256 rand;
} 



contract Adventure is IERC721Receiver, Ownable, ReentrancyGuard {

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

    event MoveToTile(
        uint256 wizId,
        uint256 zoneId,
        uint256 targetX,
        uint256 targetY
    );

    event RevealQuest(
        uint256 wizId,
        uint256 eventAmount,
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
    IAltar public ALTAR;

    uint256 private QUEST_TIME; 
    uint256 private MAX_LVL;
    uint256 private xpPointsDivider;

    bool private pausedQuesting;

    mapping (uint256 => uint256[][]) public zones;
    mapping (uint256 => State) public states;
    mapping (uint256 => uint256) public currZones;
    mapping (uint256 => uint256) public startX;
    mapping (uint256 => uint256) public startY;

    // amount of xp needed to lvl up
    mapping (uint256 => uint256) public xpPerLevel;
    // each wiz XP
    mapping (uint256 => uint256) public wizardsXp;
    mapping (uint256 => uint256) public wizardsLvl;
    mapping (uint256 => uint256) public zoneItemLevel;

    modifier wizardOwner(uint256 _wizId) {
        require(
            ARCANE.ownerOf(_wizId) == msg.sender,
            "You don't own this Wizard"
        );
        _;
    }

    // EXTERNAL
    // ------------------------------------------------------

    // maybe dont need wizardOwner(_wizId) as modifier, since calling safeTransferFrom ?
    // TODO stop people from moving in a zone that they're not in !
    function moveToTile(uint256 _wizId, uint256 _zoneId, uint256 _targetX, uint256 _targetY) external nonReentrant {
        require(_hoursElapsed(states[_wizId].startTime)>=QUEST_TIME, "You're currently questing");
        require(!states[_wizId].reward, "Reveal your loot before questing again");
        _getTileValue(_zoneId, _targetX, _targetY);
        
        // remove mana
        uint256 manaCost = 120;
        int lvlDelta = int(wizardsLvl[_wizId]) - int(_zoneId);
        if(lvlDelta>0){
            for(uint i=0;i<uint(lvlDelta);i++){
                manaCost -=5;
            }
        } 

        if(manaCost<70) manaCost =70;
        manaCost -= CONSUMABLE.getBonus(_wizId, 0);
        bool hasEnoughMana = SKILLBOOK.useMana(uint8(manaCost), _wizId);
        require(hasEnoughMana, "Not enough mana");
       
        // uint256 currZone = currZones[_wizId];
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
            require(abs(xDelta) <=1 && abs(yDelta) <=1, "You cannot move that far!");
            newX = _targetX;
            newY = _targetY; 
        }

        // edit position
        State memory newPos = State(msg.sender, block.timestamp, newX, newY, true);
        states[_wizId] = newPos;

       
        // stake Wizard if not done already
        if(ARCANE.ownerOf(_wizId)!=address(this)){
            ARCANE.safeTransferFrom(msg.sender, address(this), _wizId);
        }

        emit MoveToTile(_wizId, _zoneId, _targetX, _targetY);
    }
 
    function revealQuest(uint256 _wizId) external returns(Event[] memory _eventIds, uint256[] memory _lootIds) {
        require(states[_wizId].quester==msg.sender, "You don't own this Wizard");
        require(states[_wizId].quester!=address(0), "Nothing to loot");

        RewardData memory data;
        data.currZone = currZones[_wizId];
        data.tile = _getTileValue(data.currZone, states[_wizId].currX, states[_wizId].currY);
       
        // get events: [ [eventId,rand] , [eventId, rand]]
        Event[] memory events = EVENTS.getEvents(_wizId, data.tile );

        data.passedEvents =1;
        data.luckPerc= 25;
        data.gearPerc=75;
        data.lvlDelta = int(wizardsLvl[_wizId] - data.currZone);
        data.wizStats= ITEMS.getWizardStats(_wizId);
        // account bonuses
        for(uint i =0;i<data.wizStats.length;i++){
            data.wizStats[i]+=CONSUMABLE.getBonus(_wizId,i+1);
        }
        if(data.lvlDelta<-2){
            data.luckPerc=15;
            data.gearPerc=85;
        }
        // try passing events
        bool passedSpecial;
        for(uint i=1;i<events.length;i++){
            uint256 minToPass = 100;
            // luckroll
            uint luckRoll =uint(keccak256      
            (abi.encodePacked(_wizId,events[0].rand, data.lvlDelta, data.wizStats[0]))) % data.luckPerc;
            minToPass-=luckRoll;

            // gear roll = 50 * (currStat/LvlStat) = (50 * currStat) / lvlStat
            uint256 gearRoll = ( 50 * data.wizStats[_eventToStat(events[i].eventType)]) / zoneItemLevel[currZones[_wizId]]; 
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


        // level up
        _levelUp(_wizId, data.passedEvents);

        // get rewards
        uint256[] memory lootIds;
        uint256[] memory lootAmounts;
        (lootIds,lootAmounts) = LOOT.getLoot(data.currZone,data.tile, events.length, _wizId, passedSpecial);
        ITEMS.mintItems(msg.sender, lootIds,lootAmounts);

        // flag showing reward has been claimed and quest ended
        State memory currState = states[_wizId];
        currState.reward = false;
        states[_wizId] = currState;

        emit RevealQuest(_wizId, events.length, lootIds);

        return(events, lootIds);
    }   

    function retrieveWizard(uint256 _wizId) external {
        require(states[_wizId].quester==msg.sender, "You don't own this Wizard");
        require(_hoursElapsed(states[_wizId].startTime)>=QUEST_TIME, "You're currently questing");
        require(!states[_wizId].reward, "Reveal your loot before retrieving");
        ARCANE.safeTransferFrom(address(this),msg.sender, _wizId);

        emit RetrieveWizard(_wizId);
    }

     function levelUpFromAltar(uint256 _wizId, uint256 _newLevel) external {
        wizardsLvl[_wizId]=_newLevel;
    }

    function getAdventureState(uint256 _wizId) external view returns (uint256 zone, uint256 posX, uint256 posY ){
        return(currZones[_wizId], states[_wizId].currX,states[_wizId].currY);
    }

    function getWizardLevel(uint256 _wizId) external view returns (uint256 level){
        if(wizardsLvl[_wizId]==0) return 1;
        return(wizardsLvl[_wizId]);
    }

    function getWizardXp(uint256 _wizId) external view returns (uint256 xp){
        return(wizardsXp[_wizId]);
    }

    // INTERNAL
    // ------------------------------------------------------

    function _getTileValue(uint256 _zoneId, uint256 _x, uint256 _y) internal view returns(uint256){
        require(_x >= 0 && _y >= 0, "Move not valid");
        require(zones[_zoneId][_x][_y]!=0, "Tile is empty");
        return zones[_zoneId][_x][_y];
    }

    // unlock permission on Altar to level up if needed
    function _levelUp(uint256 _wizId, uint256 _eventsAmount) internal {
        uint256 baseMult = 1 + _eventsAmount;
        uint256 earnedPoints = xpPerLevel[currZones[_wizId]] * baseMult / xpPointsDivider;
        uint256 rand =uint(keccak256(abi.encodePacked(_wizId, block.timestamp, _eventsAmount))) % 100;
        earnedPoints += earnedPoints * rand /100;
    
        wizardsXp[_wizId]+=earnedPoints;
        uint256 newLevel = _getLevel(wizardsXp[_wizId]);
        
        if(wizardsLvl[_wizId]==0) wizardsLvl[_wizId]=1;

        if(newLevel!=wizardsLvl[_wizId]) {
            // authorise in Altar
            ALTAR.authoriseLevelUp(_wizId, newLevel);
        }
        
    }

   

    // NOT zerobased
    function _getLevel(uint256 _currPoints) internal view returns(uint256){
        uint256 currLevel=0;
        for(uint i=0;i<MAX_LVL;i++){
            if(_currPoints>=xpPerLevel[i]){
                currLevel++;
            }else{
                return currLevel+1;
            }
        }
        return MAX_LVL;
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
            // EXPLORE
            return 0;
        }else if(_eventId==1){
            // ADVENTURE
            return 1;
        }else if(_eventId==2){
            // COMBAT
            return 3;
        }else if(_eventId==3){
            // REST
            return 4;
        }else {
            // SPECIAL
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
        zones[_zoneId] = temp;
        startX[_zoneId]=_startX;
        startY[_zoneId]=_startY;
    }

    function pauseQuesting(bool _flag) external onlyOwner{
        pausedQuesting= _flag;
    }

     function setArcane(address _arcane) external onlyOwner {
        ARCANE = IArcane(_arcane);
    }

    function setLoot(address _loot) external onlyOwner{
        LOOT = ILoot(_loot);
    }

    function setAltar(address _altar) external onlyOwner{
        ALTAR = IAltar(_altar);
    }

    function setEvents(address _events) external onlyOwner{
        EVENTS = IEvents(_events);
    }

    function setSkillbook(address _skillbook) external onlyOwner{
        SKILLBOOK = ISkillbook(_skillbook);
    }

    function setConsumable(address _consumable) external onlyOwner{
        CONSUMABLE = IConsumable(_consumable);
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

   
}

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