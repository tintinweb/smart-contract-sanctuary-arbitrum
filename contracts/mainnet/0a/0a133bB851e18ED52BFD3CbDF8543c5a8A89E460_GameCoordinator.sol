// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IRentShares.sol";

contract GameCoordinator is Ownable, ReentrancyGuard {

  using EnumerableSet for EnumerableSet.AddressSet;
    
    
  EnumerableSet.AddressSet private gameContracts;

	IRentShares public rentShares;

  uint256 public activeTimeLimit;

	struct GameInfo {
		address contractAddress; // game contract
		uint256 minLevel; // min level for this game to be unlocked
		uint256 maxLevel; // max level this game can give
	}

	struct PlayerInfo {
      uint256 rewards; //pending rewards that are not rent shares
      uint256 level; //the current level for this player
      uint256 totalClaimed; //lifetime mPCKT claimed from the game
      uint256 totalPaid; //lifetime rent and taxes paid
      uint256 totalRolls; //total rolls for this player
      uint256 lastRollTime; // timestamp of the last roll on any board
    }

    mapping(uint256 => GameInfo) public gameInfo;
    mapping(address => PlayerInfo) public playerInfo;
    mapping(uint256 => uint256) public levelSummary;

    uint256 public totalPlayers;

    constructor(
        IRentShares _rentSharesAddress, // rent share contract
        uint256 _activeTimeLimit 
    ) {

      	rentShares = _rentSharesAddress;
        activeTimeLimit = _activeTimeLimit;
      /*
      	for (uint i=0; i<_gameContracts.length; i++) {
      		setGame(i,_gameContracts[i],_minLevel[i],_maxLevel[i]);
      	} */
    }

    /** 
    * @notice Modifier to only allow updates by the VRFCoordinator contract
    */
    modifier onlyGame {
        require(gameContracts.contains(address(msg.sender)), 'Game Only');
        _;
    }

    function getRewards(address _address) external view returns(uint256) {
      return playerInfo[_address].rewards;
    }

    function getLevel(address _address) external view returns(uint256) {
    	return playerInfo[_address].level;
    }

    function getTotalRolls(address _address) external view returns(uint256) {
      return playerInfo[_address].totalRolls;
    }

    function getLastRollTime(address _address) external view returns(uint256) {
      return playerInfo[_address].lastRollTime;
    }

    function addTotalPlayers(uint256 _amount) public onlyGame {
      totalPlayers = totalPlayers + _amount;
    }    

    function addRewards(address _address, uint256 _amount) public onlyGame {
      playerInfo[_address].rewards = playerInfo[_address].rewards + _amount;
    }

    event LevelSet(address indexed user, uint256 level);
    function setLevel(address _address, uint256 _level) public onlyGame {

      // dont keep stats on level 0
      if(playerInfo[_address].level > 0){
        levelSummary[playerInfo[_address].level] = levelSummary[playerInfo[_address].level] - 1;
      }

      if(_level > 0){
        levelSummary[_level] = levelSummary[_level] + 1;
      }

      playerInfo[_address].level = _level;
      emit LevelSet(_address, _level);

    }

    function addTotalClaimed(address _address, uint256 _amount) public onlyGame {
      playerInfo[_address].totalClaimed = playerInfo[_address].totalClaimed + _amount;
    }

    function addTotalPaid(address _address, uint256 _amount) public onlyGame {
      playerInfo[_address].totalPaid = playerInfo[_address].totalPaid + _amount;
    }

    function addTotalRolls(address _address) public onlyGame {
      playerInfo[_address].totalRolls = playerInfo[_address].totalRolls + 1;
    }

    function setLastRollTime(address _address, uint256 _lastRollTime) public onlyGame {
      playerInfo[_address].lastRollTime = _lastRollTime;
      // update the nft staking last update with the roll time

    }

    event GameSet(uint256 gameId, address gameContract, uint256 minLevel, uint256 maxLevel);
    function setGame(uint256 _gameId, address _gameContract, uint256 _minLevel, uint256 _maxLevel) public onlyOwner {
    	
      if(!gameContracts.contains(address(_gameContract))){
        gameContracts.add(address(_gameContract));
      }
      gameInfo[_gameId].contractAddress = _gameContract;
    	gameInfo[_gameId].minLevel = _minLevel;
    	gameInfo[_gameId].maxLevel = _maxLevel;

      emit GameSet(_gameId,_gameContract,_minLevel,_maxLevel);
    }

    event GameRemoved(uint256 _gameId);
    function removeGame(uint256 _gameId) public onlyOwner {
    	require(gameInfo[_gameId].maxLevel > 0, 'Game Not Found');
      gameContracts.remove(address(gameInfo[_gameId].contractAddress));
    	delete gameInfo[_gameId];
      emit GameRemoved(_gameId);
    }

    function canPlay(address _player, uint256 _gameId)  external view returns(bool){
    	return _canPlay(_player, _gameId);
    }
    
    function _canPlay(address _player, uint256 _gameId)  internal view returns(bool){
    	if(playerInfo[_player].level >= gameInfo[_gameId].minLevel){
    		return true;
    	}

    	return false;
    }

    function playerActive(address _player) external view returns(bool){
        return _playerActive(_player);
    }

    function _playerActive(address _player) internal view returns(bool){
        if(block.timestamp <= playerInfo[_player].lastRollTime + activeTimeLimit){
            return true;
        }
        return false;
    }


    function claimRent() public nonReentrant {
    	require(rentShares.canClaim(msg.sender,0) > 0, 'Nothing to Claim');
      require( playerInfo[msg.sender].lastRollTime + activeTimeLimit >= block.timestamp, 'Roll to Claim');
    	// claim the rent share
      // _getMod(msg.sender)
    	rentShares.claimRent(msg.sender,0);
    }

    function getRentOwed(address _address) public view returns(uint256) {
    	// _getMod(_address)
      return rentShares.canClaim(_address,0);

    }
/*
    // @dev removed the total reduction, at this moment unsure if we add it back
    function getRentMod(address _address) public view returns(uint256) {
      return _getMod(_address);
    }


    /**
     * @dev return the penalty mod for this address, reduce 10% each day down to 10% total
    function _getMod(address _address) private view returns(uint256) {
    	uint256 mod = 100;
    	uint256 cutOff = playerInfo[_address].lastRollTime + activeTimeLimit;

    	if(cutOff > block.timestamp) {
    		// we need to adjust 
    		// see how many days
    		uint256 d = (cutOff - block.timestamp) / activeTimeLimit;
    		//if over 10 days, force it to 10%
    		if(d > 10) {
    			mod = 10;
    		} else {
    			mod = mod - (d * 10);
    		}
    	}
    	return mod;
    }
*/
    function setRentShares(IRentShares _rentSharesAddress) public onlyOwner {
      rentShares = _rentSharesAddress;
    }

    function setActiveTimeLimi(uint256 _activeTimeLimit) public onlyOwner {
      activeTimeLimit = _activeTimeLimit;
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IRentShares {
    // mapping(uint256 => uint256) public totalRentSharePoints;
    function totalRentSharePoints(uint256 _nftId) external view returns(uint256);
    

    function getRentShares(address _addr, uint256 _nftId) external view returns(uint256);
    function getAllRentOwed(address _addr, uint256 _mod) external view returns (uint256);
    function getRentOwed(address _addr, uint256 _nftId) external view returns (uint256);
    function canClaim(address _addr, uint256 _mod) external view returns (uint256);
    function collectRent(uint256 _nftId, uint256 _amount) external;
    function claimRent(address _address, uint256 _mod) external;
    function addPendingRewards(address _addr, uint256 _amount) external;
    function giveShare(address _addr, uint256 _nftId) external;
    function removeShare(address _addr, uint256 _nftId) external;
    function batchGiveShares(address _addr, uint256[] calldata _nftIds) external;
    function batchRemoveShares(address _addr, uint256[] calldata _nftIds) external;
}