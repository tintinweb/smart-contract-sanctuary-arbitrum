// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./interfaces/ITransferRegistry.sol";
import "./lib/LibIterableMapping.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TransferRegistry
/// @author Connext <[email protected]>
/// @notice The TransferRegistry maintains an onchain record of all
///         supported transfers (specifically holds the registry information
///         defined within the contracts). The offchain protocol uses
///         this information to get the correct encodings when generating
///         signatures. The information stored here can only be updated
///         by the owner of the contract

contract TransferRegistry is Ownable, ITransferRegistry {
    using LibIterableMapping for LibIterableMapping.IterableMapping;

    LibIterableMapping.IterableMapping transfers;

    /// @dev Should add a transfer definition to the registry
    function addTransferDefinition(RegisteredTransfer memory definition)
        external
        override
        onlyOwner
    {
        // Get index transfer will be added at
        uint256 idx = transfers.length();
        
        // Add registered transfer
        transfers.addTransferDefinition(definition);

        // Emit event
        emit TransferAdded(transfers.getTransferDefinitionByIndex(idx));
    }

    /// @dev Should remove a transfer definition from the registry
    function removeTransferDefinition(string memory name)
        external
        override
        onlyOwner
    {
        // Get transfer from library to remove for event
        RegisteredTransfer memory transfer = transfers.getTransferDefinitionByName(name);

        // Remove transfer
        transfers.removeTransferDefinition(name);

        // Emit event
        emit TransferRemoved(transfer);
    }

    /// @dev Should return all transfer defintions in registry
    function getTransferDefinitions()
        external
        view
        override
        returns (RegisteredTransfer[] memory)
    {
        return transfers.getTransferDefinitions();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental "ABIEncoderV2";

struct RegisteredTransfer {
    string name;
    address definition;
    string stateEncoding;
    string resolverEncoding;
    bytes encodedCancel;
}

interface ITransferRegistry {
    event TransferAdded(RegisteredTransfer transfer);

    event TransferRemoved(RegisteredTransfer transfer);

    // Should add a transfer definition to the registry
    // onlyOwner
    function addTransferDefinition(RegisteredTransfer memory transfer) external;

    // Should remove a transfer definition to the registry
    // onlyOwner
    function removeTransferDefinition(string memory name) external;

    // Should return all transfer defintions in registry
    function getTransferDefinitions()
        external
        view
        returns (RegisteredTransfer[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "../interfaces/ITransferRegistry.sol";

/// @title LibIterableMapping
/// @author Connext <[email protected]>
/// @notice This library provides an efficient way to store and retrieve
///         RegisteredTransfers. This contract is used to manage the transfers
///         stored by `TransferRegistry.sol`
library LibIterableMapping {
    struct TransferDefinitionWithIndex {
        RegisteredTransfer transfer;
        uint256 index;
    }

    struct IterableMapping {
        mapping(string => TransferDefinitionWithIndex) transfers;
        string[] names;
    }

    function stringEqual(string memory s, string memory t)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(s)) == keccak256(abi.encodePacked(t));
    }

    function isEmptyString(string memory s) internal pure returns (bool) {
        return stringEqual(s, "");
    }

    function nameExists(IterableMapping storage self, string memory name)
        internal
        view
        returns (bool)
    {
        return
            !isEmptyString(name) &&
            self.names.length != 0 &&
            stringEqual(self.names[self.transfers[name].index], name);
    }

    function length(IterableMapping storage self)
        internal
        view
        returns (uint256)
    {
        return self.names.length;
    }

    function getTransferDefinitionByName(
        IterableMapping storage self,
        string memory name
    ) internal view returns (RegisteredTransfer memory) {
        require(nameExists(self, name), "LibIterableMapping: NAME_NOT_FOUND");
        return self.transfers[name].transfer;
    }

    function getTransferDefinitionByIndex(
        IterableMapping storage self,
        uint256 index
    ) internal view returns (RegisteredTransfer memory) {
        require(index < self.names.length, "LibIterableMapping: INVALID_INDEX");
        return self.transfers[self.names[index]].transfer;
    }

    function getTransferDefinitions(IterableMapping storage self)
        internal
        view
        returns (RegisteredTransfer[] memory)
    {
        uint256 l = self.names.length;
        RegisteredTransfer[] memory transfers = new RegisteredTransfer[](l);
        for (uint256 i = 0; i < l; i++) {
            transfers[i] = self.transfers[self.names[i]].transfer;
        }
        return transfers;
    }

    function addTransferDefinition(
        IterableMapping storage self,
        RegisteredTransfer memory transfer
    ) internal {
        string memory name = transfer.name;
        require(!isEmptyString(name), "LibIterableMapping: EMPTY_NAME");
        require(!nameExists(self, name), "LibIterableMapping: NAME_ALREADY_ADDED");
        self.transfers[name] = TransferDefinitionWithIndex({
            transfer: transfer,
            index: self.names.length
        });
        self.names.push(name);
    }

    function removeTransferDefinition(
        IterableMapping storage self,
        string memory name
    ) internal {
        require(!isEmptyString(name), "LibIterableMapping: EMPTY_NAME");
        require(nameExists(self, name), "LibIterableMapping: NAME_NOT_FOUND");
        uint256 index = self.transfers[name].index;
        string memory lastName = self.names[self.names.length - 1];
        self.transfers[lastName].index = index;
        self.names[index] = lastName;
        delete self.transfers[name];
        self.names.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}