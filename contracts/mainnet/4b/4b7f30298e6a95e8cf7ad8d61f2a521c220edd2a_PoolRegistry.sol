/**
 *Submitted for verification at Arbiscan on 2023-02-08
*/

pragma solidity =0.7.6;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
pragma solidity=0.7.6;

library Utils {
    struct PoolInfo {
        address pool;
        uint32 poolType;
        uint64 poolId;
    }


    function getAmount(uint _calldataPointer) internal pure returns (uint112 amount, uint calldataPointer) {
        calldataPointer = _calldataPointer;
        uint8 firstByte = uint8(msg.data[calldataPointer++]);
        uint8 decimals;
        uint8 amountBytes;
        //using temp uint variable saves pointless and opcodes
        uint amount_ = 0;
        uint8 t = 0xF0;
        if(firstByte&t == t) {
            amountBytes = firstByte&0x0F;
            decimals = 0;
        }
        else {
            decimals = firstByte&0x1F;
            amountBytes = (firstByte&0xE0)>>5;
        }
        for(uint i = 0; i < amountBytes+1; i++) {
            amount_ <<= 8;
            amount_ += uint8(msg.data[calldataPointer++]);
        }
        amount = uint112(amount_*10**uint(decimals));
    }

    function getPoolIdWithTokenId(uint _calldataPointer) internal pure returns (uint poolId, bool token0First, uint calldataPointer) {
        calldataPointer = _calldataPointer;
        uint8 lastByte = uint8(msg.data[calldataPointer++]);
        poolId = lastByte&0x3F;
        token0First = (lastByte&0x40) == 0 ? true : false;
        //next byte flag
        if(lastByte&0x80 != 0) {
            lastByte = uint8(msg.data[calldataPointer++]);
            poolId += uint(lastByte&0x7F)<<6;
            for(uint i = 1; lastByte&0x80 != 0; i++) {
                lastByte = uint8(msg.data[calldataPointer++]);
                poolId += uint(lastByte&0x7F)<<(6+7*i);
            }
        }
    }

    function getPoolIdWithoutTokenId(uint _calldataPointer) internal pure returns (uint poolId, uint calldataPointer) {
        calldataPointer = _calldataPointer;
        uint lastByte = 0;
        do {
            poolId <<= 7;
            lastByte = uint8(msg.data[calldataPointer++]);
            poolId += uint(lastByte&0x7F);
        } while(lastByte&0x80 != 0);
    }

    function getPoolIdCount(uint calldataPointer) internal pure returns (uint count) {
        while(calldataPointer < msg.data.length) {
                while(uint8(msg.data[calldataPointer++])&0x80 != 0) {}
            count++;
        }
    }
}
pragma solidity =0.7.6;

contract PoolRegistry is Ownable {
    Utils.PoolInfo[] public allPools;
    mapping(address => bool) public canAddPools;

    function addAuthorizedPoolAdder(address authorized) external onlyOwner {
        canAddPools[authorized] = true;
    }

    function addPool(address pool, uint32 poolType) external returns (uint64 poolId) {
        require(canAddPools[msg.sender] == true, "not authorized");
        poolId = uint64(allPools.length);
        allPools.push(Utils.PoolInfo(pool, poolType, poolId));
        return poolId;
    }

    function allPoolsLength() external view returns (uint) {
        return allPools.length;
    }
}