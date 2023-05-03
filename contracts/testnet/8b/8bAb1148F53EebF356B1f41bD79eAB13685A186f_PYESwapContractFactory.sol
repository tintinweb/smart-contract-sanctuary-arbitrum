// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IOwnableContract } from "./interfaces/IOwnableContract.sol";

contract PYESwapContractFactory is Ownable {
    event DeployedContract(address addr);
    event CallResponse(bool success, bytes data);

    address[] public deployedAddresses;
    mapping(address => bytes) deployedBytecode;
    mapping(address => uint) deployedSalt;

    function deployContract(uint _salt, bytes memory bytecode, address expected, bytes memory _call) external payable onlyOwner {
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        if (expected != address(0)) {
            require(addr == expected, "Deployed at wrong address");
        }
        deployedAddresses.push(addr);
        deployedBytecode[addr] = bytecode;
        deployedSalt[addr] = _salt;

        if (_call.length > 0) {
            (bool success, bytes memory data) = addr.call{value: msg.value}(_call);
            emit CallResponse(success, data);
        }

        emit DeployedContract(addr);
    }

    function deployContractAndTransfer(
        uint _salt, 
        bytes memory bytecode, 
        address expected,
        bytes memory _call, 
        address _newOwner
    ) external payable onlyOwner {
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        if (expected != address(0)) {
            require(addr == expected, "Deployed at wrong address");
        }
        deployedAddresses.push(addr);
        deployedBytecode[addr] = bytecode;
        deployedSalt[addr] = _salt;

        if (_call.length > 0) {
            (bool success, bytes memory data) = addr.call{value: msg.value}(_call);
            emit CallResponse(success, data);
        }

        IOwnableContract(addr).transferOwnership(_newOwner);

        emit DeployedContract(addr);
    }

    function predictAddress(uint _salt, bytes memory bytecode) external view returns (address predicted) {
        predicted = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            _salt,
            bytecode
        )))));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IOwnableContract {

    function transferOwnership(address newOwner) external;
    
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