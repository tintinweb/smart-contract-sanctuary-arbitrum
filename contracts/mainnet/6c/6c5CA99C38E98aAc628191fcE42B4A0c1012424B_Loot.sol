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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IRandom { 
    function getRandoms(string memory seed, uint256 _size) external view returns (uint256[] memory);
}

contract Loot is Ownable{

    IRandom private RANDOM;
    // list of all itemIds that can be looted
    mapping (uint256 => uint256[]) compoIds;
    mapping (uint256 => uint256[]) compoDroprates;
    // a unique item ID per zone that can be looted with the special event
    mapping (uint256 => uint256)  specialItems;
    // specialItems droprates
    mapping (uint256 => uint256) specialDroprates;

    function getLoot(uint256 _zoneId, uint256 _tile, uint256 _eventAmount, uint256 _wizId, bool passedSpecial) external view returns(uint256[] memory, uint256[] memory ){
            
            uint256[] memory randoms = RANDOM.getRandoms(string(abi.encodePacked(_wizId, _tile)), 9); 

            // compoIds include all items for each zone, with their corresponding craftbook id
            uint256[6] memory filler;
            uint256 counter=1;
            for(uint i=0;i<filler.length;i++){
                filler[i]=10000;
            }

            // random[0] dictates how many loots you'll get
            // we add 10 for each successful events (min: 1, max: 4)
            for(uint i=0;i<_eventAmount;i++){
                randoms[0] +=10;
            }
            if(randoms[0]>99) randoms[0] = 99;

            // minimum - guaranteed first item
            filler[0] = compoIds[_zoneId][_getCompo(_zoneId, randoms[2])];

            // second item
            if(randoms[1]>50){
                filler[1] = compoIds[_zoneId][_getCompo(_zoneId, randoms[3])];
                counter++;
            }

            // third and potentially fourth item
            if(randoms[0] >= 50){
                filler[2] = compoIds[_zoneId][_getCompo(_zoneId, randoms[5])];
                counter++;
                if(randoms[4]>50){
                    filler[3] = compoIds[_zoneId][_getCompo(_zoneId, randoms[6])];
                    counter++;

                }
            }

            // fourth 
            if(randoms[0]>=75){
                filler[4] = compoIds[_zoneId][_getCompo(_zoneId, randoms[7])];
                counter++;

            }
            // additional roll for special
            if(_tile>1 && passedSpecial){
                
                if(randoms[8]<=specialDroprates[_tile]){
                    filler[5] = specialItems[_tile];
                    counter++;
                }
            }

            uint256[] memory lootIds = new uint256[](counter);
            uint256[] memory lootAmounts= new uint256[](counter);
            uint256 counter2 =0;
            for(uint i=0;i<filler.length;i++){
                if(filler[i]!=10000){
                    lootIds[counter2]=filler[i];
                    lootAmounts[counter2] = 1;
                    counter2++;
                }
            }
            return(lootIds, lootAmounts);
    }

    function _getCompo(uint256 _zoneId, uint256 _rand) internal view returns(uint256){
         uint256 totalWeight = 0;
        for (uint256 i = 0; i < compoDroprates[_zoneId].length; i++) {
            totalWeight += compoDroprates[_zoneId][i];
        }
        
        uint256 randomWeight = _rand * totalWeight / 100;
        for (uint256 i = 0; i < compoDroprates[_zoneId].length; i++) {
            if (randomWeight < compoDroprates[_zoneId][i]) {
                return i;
            }
            randomWeight -= compoDroprates[_zoneId][i];
        }
        
        revert("Weighted selection failed");
    }

    function setRandom (address _random) external onlyOwner {
        RANDOM = IRandom(_random);
    }

    function setCompoIds(uint256 _zoneId , uint256[] memory _itemIds, uint256[] memory _dropRates) external onlyOwner{
        compoIds[_zoneId]=_itemIds;
        compoDroprates[_zoneId] = _dropRates;
    }

    function setSpecialDrops(uint256[] memory _tileIds, uint256[] memory _itemIds, uint256[] memory _dropRates ) external onlyOwner{
        for(uint i=0;i<_tileIds.length;i++){
            specialItems[_tileIds[i]] = _itemIds[i];
            specialDroprates[_tileIds[i]] = _dropRates[i];
        }
    }

}