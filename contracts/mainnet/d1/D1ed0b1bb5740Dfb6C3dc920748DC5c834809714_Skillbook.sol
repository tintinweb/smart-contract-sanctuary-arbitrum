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

//        _.--._  _.--._
//  ,-=.-":;:;:;\':;:;:;"-._
//  \\\:;:;:;:;:;\:;:;:;:;:;\
//   \\\:;:;:;:;:;\:;:;:;:;:;\
//    \\\:;:;:;:;:;\:;:;:;:;:;\
//     \\\:;:;:;:;:;\:;::;:;:;:\
//      \\\;:;::;:;:;\:;:;:;::;:\
//       \\\;;:;:_:--:\:_:--:_;:;\    
//        \\\_.-"      :      "-._\
//         \`_..--""--.;.--""--.._=>
//          "
//-shimrod
//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IArcane {
    function checkIfConnected(address _sender) external returns (bool);

    function renounceWizard(uint256 _wizId, address _caller) external;
}

interface ISkills{
    function ancientSkills(uint256 _wizId) external view returns(uint256);
}

contract Skillbook is Ownable {

    IArcane public ARCANE;
    ISkills public SKILLS0;
    ISkills public SKILLS1;
    ISkills public SKILLS2;
    ISkills public SKILLS3;
    ISkills public SKILLS4;


    struct Book{
        uint256 mana;
        uint256[5] skills;
    }

    mapping (uint256=> Book) public wizToBook;
     // @dev the last timestamp mana was used
    mapping (uint256 => uint256) public lastManaUse;
    uint256 public manaRefillTime = 1 days;
    uint16 private MANA_PER_HOUR = 10;
    uint16 private MAX_MANA = 240;
    

    event SkillsImproved(uint256 wizId, uint256[5] skillsAdded);
    event NewSkillbook(uint256 wizId, uint256[5] startSkills);
    event ManaUsed(uint256 wizardId, uint256 manaUsed);

    modifier isConnected() {
        require(ARCANE.checkIfConnected(msg.sender) || IArcane(msg.sender) == ARCANE, "No authority" );
        _;
    }

    // EXTERNAL
    // ------------------------------------------------------

    function createBook(uint256[5] memory _startSkills, uint256 _wizId) external isConnected{
         for(uint256 i=0;i<5;i++){
            wizToBook[_wizId].skills[i] = _startSkills[i];
        }
        wizToBook[_wizId].mana = MAX_MANA;
        lastManaUse[_wizId] = block.timestamp;

        emit NewSkillbook(_wizId,_startSkills);
    }

    // @dev returns a bool if Wizard has enough mana to perform action
    function useMana(uint8 _amount, uint256 _wizId) external isConnected returns(bool) {
        // Update regenerated mana
        wizToBook[_wizId].mana += _getManaGenerated(_wizId); 
        if(wizToBook[_wizId].mana>MAX_MANA){
            wizToBook[_wizId].mana = MAX_MANA;
        }

        // use required mana
        if(wizToBook[_wizId].mana < _amount){
            return false;
        }else{
            wizToBook[_wizId].mana -= _amount;
            lastManaUse[_wizId]=block.timestamp;
            emit ManaUsed(_wizId, _amount);
            return true;
        }
    }

    function getWizardSkills(uint256 _wizId) external view returns (uint256[5] memory){
        uint256[5] memory skills;
        if(_wizId<=732){
              for(uint256 i=0;i<5;i++){
            skills[0] = SKILLS0.ancientSkills(_wizId);
            skills[1] = SKILLS1.ancientSkills(_wizId);
            skills[2] = SKILLS2.ancientSkills(_wizId);
            skills[3] = SKILLS3.ancientSkills(_wizId);
            skills[4] = SKILLS4.ancientSkills(_wizId);

        }
        }else{
        for(uint256 i=0;i<5;i++){
            skills[i] = wizToBook[_wizId].skills[i];
        }
        }
        return skills;
    }

    function getMana(uint256 _wizId) external view returns(uint256){
        uint256 currMana = wizToBook[_wizId].mana+_getManaGenerated(_wizId);
        if(currMana>MAX_MANA) currMana = MAX_MANA;
        return currMana;
    }


    // INTERNAL
    // ------------------------------------------------------

    function _getManaGenerated(uint256 _wizId) internal view returns (uint256){
         uint256 elapsed = block.timestamp-lastManaUse[_wizId];
        uint256 manaRegenerated = 0;
        while(elapsed>=3600 && manaRegenerated<240){
            elapsed -= 3600;
            manaRegenerated+=MANA_PER_HOUR;
        }
        return manaRegenerated;
    }

    // OWNER
    // ------------------------------------------------------

    function setData(address _arcaneAddress, address _skills0, address _skills1, address _skills2, address _skills3, address _skills4) external onlyOwner {
        ARCANE = IArcane(_arcaneAddress);
        SKILLS0 = ISkills(_skills0);
        SKILLS1 = ISkills(_skills1);
        SKILLS2 = ISkills(_skills2);
        SKILLS3 = ISkills(_skills3);
        SKILLS4 = ISkills(_skills4);

    }
}