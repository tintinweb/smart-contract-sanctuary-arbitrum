// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";


contract PropertyValidator is Ownable {

    bytes4 public constant MAGIC_BYTES = this.validateProperty.selector;

    address public immutable ELEMENT_EX;

    mapping(address => bool) public signers;

    event AddSigner(address indexed signer);
    event RemoveSigner(address indexed signer);

    constructor(address elementEx) {
        ELEMENT_EX = elementEx;
    }

    function addSigner(address signer) external onlyOwner {
        require(signer != address(0), "invalid signer");
        require(!signers[signer], "signer is added");

        signers[signer] = true;
        emit AddSigner(signer);
    }

    function removeSigner(address signer) external onlyOwner {
        require(signers[signer], "signer is removed");

        signers[signer] = false;
        emit RemoveSigner(signer);
    }

    function validateProperty(
        address /* tokenAddress */,
        uint256 /* tokenId */,
        bytes32 orderHash,
        bytes calldata /* propertyData */,
        bytes calldata takerData
    ) external view returns(bytes4) {
        require(msg.sender == ELEMENT_EX, "validateProperty/unauthorized_caller");
        require(takerData.length == 69, "validateProperty/takerData_error");

        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
        bytes32 validateHash;

        assembly {
            // takerData -> 32bytes[r] + 32bytes[s] + 1bytes[v] + 4bytes[deadline]
            r := calldataload(takerData.offset)
            s := calldataload(add(takerData.offset, 32))
            v := and(calldataload(add(takerData.offset, 33)), 0xff)
            deadline := and(calldataload(add(takerData.offset, 37)), 0xffffffff)

            let ptr := mload(0x40)  // free memory pointer
            mstore(ptr, orderHash)
            mstore(add(ptr, 0x20), deadline)
            validateHash := keccak256(ptr, 0x40)
        }

        require(block.timestamp < deadline, "validateProperty/deadline_reached");

        address signer = ecrecover(validateHash, v, r, s);
        require(signers[signer], "validateProperty/invalid_signer");

        return MAGIC_BYTES;
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