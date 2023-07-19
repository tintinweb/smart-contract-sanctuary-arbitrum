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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Consumables is Ownable{

    mapping (address => bool) public whitelisted;

    mapping (uint256 => uint256) public manaPotions;
    mapping (uint256 => uint256) public stats_Focus;
    mapping (uint256 => uint256) public stats_Strength;
    mapping (uint256 => uint256) public stats_Intellect;
    mapping (uint256 => uint256) public stats_Spell;
    mapping (uint256 => uint256) public stats_Endurance;
    mapping (uint256 => uint256) public giantLeap;
    mapping (uint256 => uint256) public guaranteed;

    modifier isWhitelisted(){
        require(whitelisted[msg.sender], "Consumables call not whitelisted");
        _;
    }

    function getBonus (uint256 _wizId, uint256 _bonusId) external isWhitelisted returns(uint256) {
        uint256 toReturn = 0;
        if(_bonusId==0 && manaPotions[_wizId]>0){
            toReturn = manaPotions[_wizId];
            manaPotions[_wizId]=0;
        }else if(_bonusId==1 && stats_Focus[_wizId]>0){
            toReturn = stats_Focus[_wizId];
            stats_Focus[_wizId]=0;
        }else if(_bonusId==2 && stats_Strength[_wizId]>0){
            toReturn = stats_Strength[_wizId];
            stats_Strength[_wizId]=0;
        }else if(_bonusId==3 && stats_Intellect[_wizId]>0){
            toReturn = stats_Intellect[_wizId];
            stats_Intellect[_wizId]=0;
        }else if(_bonusId==4 && stats_Spell[_wizId]>0){
            toReturn = stats_Spell[_wizId];
            stats_Spell[_wizId]=0;
        }else if(_bonusId==5 && stats_Endurance[_wizId]>0){
            toReturn = stats_Endurance[_wizId];
            stats_Endurance[_wizId]=0;
        }else if(_bonusId==6 && giantLeap[_wizId]>0){
            toReturn = giantLeap[_wizId];
            giantLeap[_wizId]=0;
        }else if(_bonusId==7 && guaranteed[_wizId]>0){
            toReturn = guaranteed[_wizId];
            guaranteed[_wizId]=0;
        }
        return toReturn;
    }

    function giveBonus(uint256 _wizId, uint256 _bonusId, uint256 _amount) external isWhitelisted {
       
        if(_bonusId==0){
            manaPotions[_wizId]+=_amount;
        }else if(_bonusId==1){
            stats_Focus[_wizId]+=_amount;
        }else if(_bonusId==2){
            stats_Strength[_wizId]+=_amount;
        }else if(_bonusId==3){
            stats_Intellect[_wizId]+=_amount;
        }else if(_bonusId==4){
            stats_Spell[_wizId]+=_amount;
        }else if(_bonusId==5){
            stats_Endurance[_wizId]+=_amount;
        }else if(_bonusId==6){
            giantLeap[_wizId]+=_amount;
        }else if(_bonusId==7){
            guaranteed[_wizId]+=_amount;
        }
    }

    function setWhitelisted(address _toWhitelist) external onlyOwner{
        whitelisted[_toWhitelist]=true;
    }


    function removeWhitelisted(address _toRemove) external onlyOwner{
        whitelisted[_toRemove]=false;
    }

}