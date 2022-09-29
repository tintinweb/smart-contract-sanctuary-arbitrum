// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Oracle is  Ownable {
    uint256 public seed;
    uint256[] public seeds;
    address public PRICE_UPDATER;
    uint256 nonce;


    mapping (address => bool) public allowed;

    constructor(uint256 _seed) {
        nonce = _seed;
        ///change to list and have randomly chosen
        for (uint i=0; i < 50; i++) {
            nonce++;
            seeds.push(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 10000000000000000000000000);
        }
        choice();
    }

    function setAllowed(address _address, bool allow) public onlyOwner{
        allowed[_address] = allow; 
    }

    //updates seed to random seed
    function choice() private {
        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 50;
        seed = seeds[num];
    }  

    function showSeed() external view returns (uint256) {
        require(allowed[msg.sender], "Contract must be alllowed to call oracle"); 
        return seed;
    }



}