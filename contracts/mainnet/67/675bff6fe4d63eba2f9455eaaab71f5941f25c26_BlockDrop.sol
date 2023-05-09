/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: mit
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


abstract contract ERC20Interface {

    function name() public view virtual  returns (string memory);

    function symbol() public view virtual returns (string memory);

    function decimals() public view virtual returns (uint8);

    function totalSupply() public view virtual returns (uint);

    function balanceOf(address tokenOwner) public view virtual returns (uint balance);

    function allowance(address tokenOwner, address spender) public view virtual returns (uint remaining);

    function transfer(address to, uint tokens) public virtual returns (bool success);

    function approve(address spender, uint tokens) public virtual returns (bool success);

    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    function burn(uint256 amount) virtual public;


    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}





contract BlockDrop is Ownable {

    bytes32 public root;
    ERC20Interface public droppedToken;
    uint public decayStartTime;
    uint public decayDurationInSeconds;

    uint public initialBalance;
    uint public remainingValue;  // The total of not withdrawn entitlements, not considering decay
    uint public spentTokens;  // The total tokens spent by the contract, burnt or withdrawn

    mapping (address => bool) public withdrawn;

    event Withdraw(address recipient, uint value, uint originalValue);
    event Burn(uint value);

    constructor(ERC20Interface _droppedToken, uint _initialBalance, bytes32 _root, uint _decayStartTime, uint _decayDurationInSeconds) public {
        // The _initialBalance should be equal to the sum of airdropped tokens
        droppedToken = _droppedToken;
        initialBalance = _initialBalance;
        remainingValue = _initialBalance;
        root = _root;
        decayStartTime = _decayStartTime;
        decayDurationInSeconds = _decayDurationInSeconds;
    }

    function claim(uint value, bytes32[] memory proof) public {
        require(verifyEntitled(msg.sender, value, proof), "The proof could not be verified.");
        require(! withdrawn[msg.sender], "You have already withdrawn your entitled token.");

        

        uint valueToSend = decayedEntitlementAtTime(value, block.timestamp, false);
        assert(valueToSend <= value);
        require(droppedToken.balanceOf(address(this)) >= valueToSend, "The MerkleDrop does not have tokens to drop yet / anymore.");
        require(valueToSend != 0, "The decayed entitled value is now zero.");

        withdrawn[msg.sender] = true;
        remainingValue -= value;
        spentTokens += valueToSend;

        require(droppedToken.transfer(msg.sender, valueToSend));
        emit Withdraw(msg.sender, valueToSend, value);
    }

    function verifyEntitled(address recipient, uint value, bytes32[] memory proof) public view returns (bool) {
        // We need to pack the 20 bytes address to the 32 bytes value
        // to match with the proof made with the python merkle-drop package
        bytes32 leaf = keccak256(abi.encodePacked(recipient, value));
        return verifyProof(leaf, proof);
    }

    function decayedEntitlementAtTime(uint value, uint time, bool roundUp) public view returns (uint) {
        if (time <= decayStartTime) {
            return value;
        } else if (time >= decayStartTime + decayDurationInSeconds) {
            return 0;
        } else {
            uint timeDecayed = time - decayStartTime;
            uint valueDecay = decay(value, timeDecayed, decayDurationInSeconds, !roundUp);
            assert(valueDecay <= value);
            return value - valueDecay;
        }
    }





    function verifyProof(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 currentHash = leaf;

        for (uint i = 0; i < proof.length; i += 1) {
            currentHash = parentHash(currentHash, proof[i]);
        }

        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encode(a, b));
        } else {
            return keccak256(abi.encode(b, a));
        }
    }

    function decay(uint value, uint timeToDecay, uint totalDecayTime, bool roundUp) internal pure returns (uint) {
        uint decay;

        if (roundUp) {
            decay = (value*timeToDecay+totalDecayTime-1)/totalDecayTime;
        } else {
            decay = value*timeToDecay/totalDecayTime;
        }
        return decay >= value ? value : decay;
    }
      function recoverERC20(address droppedToken, uint256 tokenAmount) public onlyOwner {
        ERC20Interface(droppedToken).transfer(owner(), tokenAmount);
    }
    

}