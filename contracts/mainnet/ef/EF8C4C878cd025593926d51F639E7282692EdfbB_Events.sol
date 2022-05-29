pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Events is Ownable {
    enum EventType { EXPLORE, ADVENTURE, COMBAT, REST, SPECIAL }

    struct Event {
        uint8 eventType;
        uint256 rand;
    } 

    // EXTERNAL
    // ------------------------------------------------------

    // events + loots... so format should be [ [ eventId, rand ], [ eventId, rand ] ]
    function getEvents(uint256 _wizId, uint256 _tile) external view returns (Event[] memory) {
        // get our array of randoms
        uint[] memory randArr = new uint[](10);
        for (uint i = 0; i < 10; i++){
            randArr[i] = i;
        }
        // 0 is #of events, 1 2 3 4  are events Id, 5 6 7 8 are rands
        bool specialTile = _tile > 1;
        uint[] memory eventRands= _randomArr(randArr,_wizId, specialTile);
    
        Event[] memory toReturn = new Event[](eventRands[0]);
        for(uint e=0;e<eventRands[0];e++){
            // choose type 
            Event memory newEvent = Event(uint8(eventRands[e+1]), eventRands[e+5]);
            toReturn[e] = newEvent;
        }
        // TODO make a last pass on the events and make one SPECIAL if its a special tile
        // otherwise it will alwyas come last?
        // BUT special can never be index 0 or it will have 100% chance to trigger

        return toReturn;
    }

    // INTERNAL
    // ------------------------------------------------------

    // if _special, include the last type of events
     // Returns:  0 is #of events, 1 2 3 4 are events Id, 5 6 7 8 are rands
    function _randomArr(uint[] memory _myArray, uint256 _wizId, bool _special) internal view returns(uint[] memory){
        // uint a = _myArray.length; 
        uint b = _myArray.length;
        for(uint i = 0; i< b ; i++){
            uint div = 100;
            if(i==0) div = 4;
            // if it's a special tile, any of the events can be special, even multiple
            if(_special){
                if(i>0 && i<5) div = 5;              
            }else{
                if(i>0 && i<5) div = 4;
            }
            uint randNumber =uint(keccak256      
            (abi.encodePacked(block.timestamp, _wizId,_myArray[i]))) % div;
            // uint randForInterim=(randNumber % a) +1;
            // _myArray[randForInterim-1]= _myArray[a-1];
            _myArray[i] = randNumber;
            // a = a-1;
        }
        // uint256[] memory result;
        // result = _myArray; 
        if(_myArray[0]<1) _myArray[0]=1;      
        return _myArray;        
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