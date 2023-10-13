// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import {IDelegateRegistry as IDelegateRegistry} from "./IDelegateRegistry.sol";
import {RegistryHashes as Hashes} from "./libraries/RegistryHashes.sol";
import {RegistryStorage as Storage} from "./libraries/RegistryStorage.sol";
import {RegistryOps as Ops} from "./libraries/RegistryOps.sol";

/**
 * @title DelegateRegistry
 * @custom:version 2.0
 * @custom:coauthor foobar (0xfoobar)
 * @custom:coauthor mireynolds
 * @notice A standalone immutable registry storing delegated permissions from one address to another
 */
contract DelegateRegistry is IDelegateRegistry {
    /// @dev Only this mapping should be used to verify delegations; the other mapping arrays are for enumerations
    mapping(bytes32 delegationHash => bytes32[5] delegationStorage) internal delegations;

    /// @dev Vault delegation enumeration outbox, for pushing new hashes only
    mapping(address from => bytes32[] delegationHashes) internal outgoingDelegationHashes;

    /// @dev Delegate enumeration inbox, for pushing new hashes only
    mapping(address to => bytes32[] delegationHashes) internal incomingDelegationHashes;

    /**
     * ----------- WRITE -----------
     */

    /// @inheritdoc IDelegateRegistry
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        bool success;
        unchecked {
            for (uint256 i = 0; i < data.length; ++i) {
                //slither-disable-next-line calls-loop,delegatecall-loop
                (success, results[i]) = address(this).delegatecall(data[i]);
                if (!success) revert MulticallFailed();
            }
        }
    }

    /// @inheritdoc IDelegateRegistry
    function delegateAll(address to, bytes32 rights, bool enable) external payable override returns (bytes32 hash) {
        hash = Hashes.allHash(msg.sender, rights, to);
        bytes32 location = Hashes.location(hash);
        address loadedFrom = _loadFrom(location);
        if (enable) {
            if (loadedFrom == Storage.DELEGATION_EMPTY) {
                _pushDelegationHashes(msg.sender, to, hash);
                _writeDelegationAddresses(location, msg.sender, to, address(0));
                if (rights != "") _writeDelegation(location, Storage.POSITIONS_RIGHTS, rights);
            } else if (loadedFrom == Storage.DELEGATION_REVOKED) {
                _updateFrom(location, msg.sender);
            }
        } else if (loadedFrom == msg.sender) {
            _updateFrom(location, Storage.DELEGATION_REVOKED);
        }
        emit DelegateAll(msg.sender, to, rights, enable);
    }

    /// @inheritdoc IDelegateRegistry
    function delegateContract(address to, address contract_, bytes32 rights, bool enable) external payable override returns (bytes32 hash) {
        hash = Hashes.contractHash(msg.sender, rights, to, contract_);
        bytes32 location = Hashes.location(hash);
        address loadedFrom = _loadFrom(location);
        if (enable) {
            if (loadedFrom == Storage.DELEGATION_EMPTY) {
                _pushDelegationHashes(msg.sender, to, hash);
                _writeDelegationAddresses(location, msg.sender, to, contract_);
                if (rights != "") _writeDelegation(location, Storage.POSITIONS_RIGHTS, rights);
            } else if (loadedFrom == Storage.DELEGATION_REVOKED) {
                _updateFrom(location, msg.sender);
            }
        } else if (loadedFrom == msg.sender) {
            _updateFrom(location, Storage.DELEGATION_REVOKED);
        }
        emit DelegateContract(msg.sender, to, contract_, rights, enable);
    }

    /// @inheritdoc IDelegateRegistry
    function delegateERC721(address to, address contract_, uint256 tokenId, bytes32 rights, bool enable) external payable override returns (bytes32 hash) {
        hash = Hashes.erc721Hash(msg.sender, rights, to, tokenId, contract_);
        bytes32 location = Hashes.location(hash);
        address loadedFrom = _loadFrom(location);
        if (enable) {
            if (loadedFrom == Storage.DELEGATION_EMPTY) {
                _pushDelegationHashes(msg.sender, to, hash);
                _writeDelegationAddresses(location, msg.sender, to, contract_);
                _writeDelegation(location, Storage.POSITIONS_TOKEN_ID, tokenId);
                if (rights != "") _writeDelegation(location, Storage.POSITIONS_RIGHTS, rights);
            } else if (loadedFrom == Storage.DELEGATION_REVOKED) {
                _updateFrom(location, msg.sender);
            }
        } else if (loadedFrom == msg.sender) {
            _updateFrom(location, Storage.DELEGATION_REVOKED);
        }
        emit DelegateERC721(msg.sender, to, contract_, tokenId, rights, enable);
    }

    // @inheritdoc IDelegateRegistry
    function delegateERC20(address to, address contract_, bytes32 rights, uint256 amount) external payable override returns (bytes32 hash) {
        hash = Hashes.erc20Hash(msg.sender, rights, to, contract_);
        bytes32 location = Hashes.location(hash);
        address loadedFrom = _loadFrom(location);
        if (amount != 0) {
            if (loadedFrom == Storage.DELEGATION_EMPTY) {
                _pushDelegationHashes(msg.sender, to, hash);
                _writeDelegationAddresses(location, msg.sender, to, contract_);
                _writeDelegation(location, Storage.POSITIONS_AMOUNT, amount);
                if (rights != "") _writeDelegation(location, Storage.POSITIONS_RIGHTS, rights);
            } else if (loadedFrom == Storage.DELEGATION_REVOKED) {
                _updateFrom(location, msg.sender);
                _writeDelegation(location, Storage.POSITIONS_AMOUNT, amount);
            } else if (loadedFrom == msg.sender) {
                _writeDelegation(location, Storage.POSITIONS_AMOUNT, amount);
            }
        } else if (loadedFrom == msg.sender) {
            _updateFrom(location, Storage.DELEGATION_REVOKED);
            _writeDelegation(location, Storage.POSITIONS_AMOUNT, uint256(0));
        }
        emit DelegateERC20(msg.sender, to, contract_, rights, amount);
    }

    /// @inheritdoc IDelegateRegistry
    function delegateERC1155(address to, address contract_, uint256 tokenId, bytes32 rights, uint256 amount) external payable override returns (bytes32 hash) {
        hash = Hashes.erc1155Hash(msg.sender, rights, to, tokenId, contract_);
        bytes32 location = Hashes.location(hash);
        address loadedFrom = _loadFrom(location);
        if (amount != 0) {
            if (loadedFrom == Storage.DELEGATION_EMPTY) {
                _pushDelegationHashes(msg.sender, to, hash);
                _writeDelegationAddresses(location, msg.sender, to, contract_);
                _writeDelegation(location, Storage.POSITIONS_TOKEN_ID, tokenId);
                _writeDelegation(location, Storage.POSITIONS_AMOUNT, amount);
                if (rights != "") _writeDelegation(location, Storage.POSITIONS_RIGHTS, rights);
            } else if (loadedFrom == Storage.DELEGATION_REVOKED) {
                _updateFrom(location, msg.sender);
                _writeDelegation(location, Storage.POSITIONS_AMOUNT, amount);
            } else if (loadedFrom == msg.sender) {
                _writeDelegation(location, Storage.POSITIONS_AMOUNT, amount);
            }
        } else if (loadedFrom == msg.sender) {
            _updateFrom(location, Storage.DELEGATION_REVOKED);
            _writeDelegation(location, Storage.POSITIONS_AMOUNT, uint256(0));
        }
        emit DelegateERC1155(msg.sender, to, contract_, tokenId, rights, amount);
    }

    /// @dev Transfer native token out
    function sweep() external {
        assembly ("memory-safe") {
            // This hardcoded address is a CREATE2 factory counterfactual smart contract wallet that will always accept native token transfers
            let result := call(gas(), 0x000000dE1E80ea5a234FB5488fee2584251BC7e8, selfbalance(), 0, 0, 0, 0)
        }
    }

    /**
     * ----------- CHECKS -----------
     */

    /// @inheritdoc IDelegateRegistry
    function checkDelegateForAll(address to, address from, bytes32 rights) external view override returns (bool valid) {
        if (!_invalidFrom(from)) {
            valid = _validateFrom(Hashes.allLocation(from, "", to), from);
            if (!Ops.or(rights == "", valid)) valid = _validateFrom(Hashes.allLocation(from, rights, to), from);
        }
        assembly ("memory-safe") {
            // Only first 32 bytes of scratch space is accessed
            mstore(0, iszero(iszero(valid))) // Compiler cleans dirty booleans on the stack to 1, so do the same here
            return(0, 32) // Direct return, skips Solidity's redundant copying to save gas
        }
    }

    /// @inheritdoc IDelegateRegistry
    function checkDelegateForContract(address to, address from, address contract_, bytes32 rights) external view override returns (bool valid) {
        if (!_invalidFrom(from)) {
            valid = _validateFrom(Hashes.allLocation(from, "", to), from) || _validateFrom(Hashes.contractLocation(from, "", to, contract_), from);
            if (!Ops.or(rights == "", valid)) {
                valid = _validateFrom(Hashes.allLocation(from, rights, to), from) || _validateFrom(Hashes.contractLocation(from, rights, to, contract_), from);
            }
        }
        assembly ("memory-safe") {
            // Only first 32 bytes of scratch space is accessed
            mstore(0, iszero(iszero(valid))) // Compiler cleans dirty booleans on the stack to 1, so do the same here
            return(0, 32) // Direct return, skips Solidity's redundant copying to save gas
        }
    }

    /// @inheritdoc IDelegateRegistry
    function checkDelegateForERC721(address to, address from, address contract_, uint256 tokenId, bytes32 rights) external view override returns (bool valid) {
        if (!_invalidFrom(from)) {
            valid = _validateFrom(Hashes.allLocation(from, "", to), from) || _validateFrom(Hashes.contractLocation(from, "", to, contract_), from)
                || _validateFrom(Hashes.erc721Location(from, "", to, tokenId, contract_), from);
            if (!Ops.or(rights == "", valid)) {
                valid = _validateFrom(Hashes.allLocation(from, rights, to), from) || _validateFrom(Hashes.contractLocation(from, rights, to, contract_), from)
                    || _validateFrom(Hashes.erc721Location(from, rights, to, tokenId, contract_), from);
            }
        }
        assembly ("memory-safe") {
            // Only first 32 bytes of scratch space is accessed
            mstore(0, iszero(iszero(valid))) // Compiler cleans dirty booleans on the stack to 1, so do the same here
            return(0, 32) // Direct return, skips Solidity's redundant copying to save gas
        }
    }

    /// @inheritdoc IDelegateRegistry
    function checkDelegateForERC20(address to, address from, address contract_, bytes32 rights) external view override returns (uint256 amount) {
        if (!_invalidFrom(from)) {
            amount = (_validateFrom(Hashes.allLocation(from, "", to), from) || _validateFrom(Hashes.contractLocation(from, "", to, contract_), from))
                ? type(uint256).max
                : _loadDelegationUint(Hashes.erc20Location(from, "", to, contract_), Storage.POSITIONS_AMOUNT);
            if (!Ops.or(rights == "", amount == type(uint256).max)) {
                uint256 rightsBalance = (_validateFrom(Hashes.allLocation(from, rights, to), from) || _validateFrom(Hashes.contractLocation(from, rights, to, contract_), from))
                    ? type(uint256).max
                    : _loadDelegationUint(Hashes.erc20Location(from, rights, to, contract_), Storage.POSITIONS_AMOUNT);
                amount = Ops.max(rightsBalance, amount);
            }
        }
        assembly ("memory-safe") {
            mstore(0, amount) // Only first 32 bytes of scratch space being accessed
            return(0, 32) // Direct return, skips Solidity's redundant copying to save gas
        }
    }

    /// @inheritdoc IDelegateRegistry
    function checkDelegateForERC1155(address to, address from, address contract_, uint256 tokenId, bytes32 rights) external view override returns (uint256 amount) {
        if (!_invalidFrom(from)) {
            amount = (_validateFrom(Hashes.allLocation(from, "", to), from) || _validateFrom(Hashes.contractLocation(from, "", to, contract_), from))
                ? type(uint256).max
                : _loadDelegationUint(Hashes.erc1155Location(from, "", to, tokenId, contract_), Storage.POSITIONS_AMOUNT);
            if (!Ops.or(rights == "", amount == type(uint256).max)) {
                uint256 rightsBalance = (_validateFrom(Hashes.allLocation(from, rights, to), from) || _validateFrom(Hashes.contractLocation(from, rights, to, contract_), from))
                    ? type(uint256).max
                    : _loadDelegationUint(Hashes.erc1155Location(from, rights, to, tokenId, contract_), Storage.POSITIONS_AMOUNT);
                amount = Ops.max(rightsBalance, amount);
            }
        }
        assembly ("memory-safe") {
            mstore(0, amount) // Only first 32 bytes of scratch space is accessed
            return(0, 32) // Direct return, skips Solidity's redundant copying to save gas
        }
    }

    /**
     * ----------- ENUMERATIONS -----------
     */

    /// @inheritdoc IDelegateRegistry
    function getIncomingDelegations(address to) external view override returns (Delegation[] memory delegations_) {
        delegations_ = _getValidDelegationsFromHashes(incomingDelegationHashes[to]);
    }

    /// @inheritdoc IDelegateRegistry
    function getOutgoingDelegations(address from) external view returns (Delegation[] memory delegations_) {
        delegations_ = _getValidDelegationsFromHashes(outgoingDelegationHashes[from]);
    }

    /// @inheritdoc IDelegateRegistry
    function getIncomingDelegationHashes(address to) external view returns (bytes32[] memory delegationHashes) {
        delegationHashes = _getValidDelegationHashesFromHashes(incomingDelegationHashes[to]);
    }

    /// @inheritdoc IDelegateRegistry
    function getOutgoingDelegationHashes(address from) external view returns (bytes32[] memory delegationHashes) {
        delegationHashes = _getValidDelegationHashesFromHashes(outgoingDelegationHashes[from]);
    }

    /// @inheritdoc IDelegateRegistry
    function getDelegationsFromHashes(bytes32[] calldata hashes) external view returns (Delegation[] memory delegations_) {
        delegations_ = new Delegation[](hashes.length);
        unchecked {
            for (uint256 i = 0; i < hashes.length; ++i) {
                bytes32 location = Hashes.location(hashes[i]);
                address from = _loadFrom(location);
                if (_invalidFrom(from)) {
                    delegations_[i] = Delegation({type_: DelegationType.NONE, to: address(0), from: address(0), rights: "", amount: 0, contract_: address(0), tokenId: 0});
                } else {
                    (, address to, address contract_) = _loadDelegationAddresses(location);
                    delegations_[i] = Delegation({
                        type_: Hashes.decodeType(hashes[i]),
                        to: to,
                        from: from,
                        rights: _loadDelegationBytes32(location, Storage.POSITIONS_RIGHTS),
                        amount: _loadDelegationUint(location, Storage.POSITIONS_AMOUNT),
                        contract_: contract_,
                        tokenId: _loadDelegationUint(location, Storage.POSITIONS_TOKEN_ID)
                    });
                }
            }
        }
    }

    /**
     * ----------- EXTERNAL STORAGE ACCESS -----------
     */

    function readSlot(bytes32 location) external view returns (bytes32 contents) {
        assembly {
            contents := sload(location)
        }
    }

    function readSlots(bytes32[] calldata locations) external view returns (bytes32[] memory contents) {
        uint256 length = locations.length;
        contents = new bytes32[](length);
        bytes32 tempLocation;
        bytes32 tempValue;
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                tempLocation = locations[i];
                assembly {
                    tempValue := sload(tempLocation)
                }
                contents[i] = tempValue;
            }
        }
    }

    /**
     * ----------- ERC165 -----------
     */

    /// @notice Query if a contract implements an ERC-165 interface
    /// @param interfaceId The interface identifier
    /// @return valid Whether the queried interface is supported
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return Ops.or(interfaceId == type(IDelegateRegistry).interfaceId, interfaceId == 0x01ffc9a7);
    }

    /**
     * ----------- INTERNAL -----------
     */

    /// @dev Helper function to push new delegation hashes to the incoming and outgoing hashes mappings
    function _pushDelegationHashes(address from, address to, bytes32 delegationHash) internal {
        outgoingDelegationHashes[from].push(delegationHash);
        incomingDelegationHashes[to].push(delegationHash);
    }

    /// @dev Helper function that writes bytes32 data to delegation data location at array position
    function _writeDelegation(bytes32 location, uint256 position, bytes32 data) internal {
        assembly {
            sstore(add(location, position), data)
        }
    }

    /// @dev Helper function that writes uint256 data to delegation data location at array position
    function _writeDelegation(bytes32 location, uint256 position, uint256 data) internal {
        assembly {
            sstore(add(location, position), data)
        }
    }

    /// @dev Helper function that writes addresses according to the packing rule for delegation storage
    function _writeDelegationAddresses(bytes32 location, address from, address to, address contract_) internal {
        (bytes32 firstSlot, bytes32 secondSlot) = Storage.packAddresses(from, to, contract_);
        uint256 firstPacked = Storage.POSITIONS_FIRST_PACKED;
        uint256 secondPacked = Storage.POSITIONS_SECOND_PACKED;
        assembly {
            sstore(add(location, firstPacked), firstSlot)
            sstore(add(location, secondPacked), secondSlot)
        }
    }

    /// @dev Helper function that writes `from` while preserving the rest of the storage slot
    function _updateFrom(bytes32 location, address from) internal {
        uint256 firstPacked = Storage.POSITIONS_FIRST_PACKED;
        uint256 cleanAddress = Storage.CLEAN_ADDRESS;
        uint256 cleanUpper12Bytes = type(uint256).max << 160;
        assembly {
            let slot := and(sload(add(location, firstPacked)), cleanUpper12Bytes)
            sstore(add(location, firstPacked), or(slot, and(from, cleanAddress)))
        }
    }

    /// @dev Helper function that takes an array of delegation hashes and returns an array of Delegation structs with their onchain information
    function _getValidDelegationsFromHashes(bytes32[] storage hashes) internal view returns (Delegation[] memory delegations_) {
        uint256 count = 0;
        uint256 hashesLength = hashes.length;
        bytes32 hash;
        bytes32[] memory filteredHashes = new bytes32[](hashesLength);
        unchecked {
            for (uint256 i = 0; i < hashesLength; ++i) {
                hash = hashes[i];
                if (_invalidFrom(_loadFrom(Hashes.location(hash)))) continue;
                filteredHashes[count++] = hash;
            }
            delegations_ = new Delegation[](count);
            bytes32 location;
            for (uint256 i = 0; i < count; ++i) {
                hash = filteredHashes[i];
                location = Hashes.location(hash);
                (address from, address to, address contract_) = _loadDelegationAddresses(location);
                delegations_[i] = Delegation({
                    type_: Hashes.decodeType(hash),
                    to: to,
                    from: from,
                    rights: _loadDelegationBytes32(location, Storage.POSITIONS_RIGHTS),
                    amount: _loadDelegationUint(location, Storage.POSITIONS_AMOUNT),
                    contract_: contract_,
                    tokenId: _loadDelegationUint(location, Storage.POSITIONS_TOKEN_ID)
                });
            }
        }
    }

    /// @dev Helper function that takes an array of delegation hashes and returns an array of valid delegation hashes
    function _getValidDelegationHashesFromHashes(bytes32[] storage hashes) internal view returns (bytes32[] memory validHashes) {
        uint256 count = 0;
        uint256 hashesLength = hashes.length;
        bytes32 hash;
        bytes32[] memory filteredHashes = new bytes32[](hashesLength);
        unchecked {
            for (uint256 i = 0; i < hashesLength; ++i) {
                hash = hashes[i];
                if (_invalidFrom(_loadFrom(Hashes.location(hash)))) continue;
                filteredHashes[count++] = hash;
            }
            validHashes = new bytes32[](count);
            for (uint256 i = 0; i < count; ++i) {
                validHashes[i] = filteredHashes[i];
            }
        }
    }

    /// @dev Helper function that loads delegation data from a particular array position and returns as bytes32
    function _loadDelegationBytes32(bytes32 location, uint256 position) internal view returns (bytes32 data) {
        assembly {
            data := sload(add(location, position))
        }
    }

    /// @dev Helper function that loads delegation data from a particular array position and returns as uint256
    function _loadDelegationUint(bytes32 location, uint256 position) internal view returns (uint256 data) {
        assembly {
            data := sload(add(location, position))
        }
    }

    // @dev Helper function that loads the from address from storage according to the packing rule for delegation storage
    function _loadFrom(bytes32 location) internal view returns (address) {
        bytes32 data;
        uint256 firstPacked = Storage.POSITIONS_FIRST_PACKED;
        assembly {
            data := sload(add(location, firstPacked))
        }
        return Storage.unpackAddress(data);
    }

    /// @dev Helper function to establish whether a delegation is enabled
    function _validateFrom(bytes32 location, address from) internal view returns (bool) {
        return (from == _loadFrom(location));
    }

    /// @dev Helper function that loads the address for the delegation according to the packing rule for delegation storage
    function _loadDelegationAddresses(bytes32 location) internal view returns (address from, address to, address contract_) {
        bytes32 firstSlot;
        bytes32 secondSlot;
        uint256 firstPacked = Storage.POSITIONS_FIRST_PACKED;
        uint256 secondPacked = Storage.POSITIONS_SECOND_PACKED;
        assembly {
            firstSlot := sload(add(location, firstPacked))
            secondSlot := sload(add(location, secondPacked))
        }
        (from, to, contract_) = Storage.unpackAddresses(firstSlot, secondSlot);
    }

    function _invalidFrom(address from) internal pure returns (bool) {
        return Ops.or(from == Storage.DELEGATION_EMPTY, from == Storage.DELEGATION_REVOKED);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.13;

/**
 * @title IDelegateRegistry
 * @custom:version 2.0
 * @custom:author foobar (0xfoobar)
 * @notice A standalone immutable registry storing delegated permissions from one address to another
 */
interface IDelegateRegistry {
    /// @notice Delegation type, NONE is used when a delegation does not exist or is revoked
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        ERC721,
        ERC20,
        ERC1155
    }

    /// @notice Struct for returning delegations
    struct Delegation {
        DelegationType type_;
        address to;
        address from;
        bytes32 rights;
        address contract_;
        uint256 tokenId;
        uint256 amount;
    }

    /// @notice Emitted when an address delegates or revokes rights for their entire wallet
    event DelegateAll(address indexed from, address indexed to, bytes32 rights, bool enable);

    /// @notice Emitted when an address delegates or revokes rights for a contract address
    event DelegateContract(address indexed from, address indexed to, address indexed contract_, bytes32 rights, bool enable);

    /// @notice Emitted when an address delegates or revokes rights for an ERC721 tokenId
    event DelegateERC721(address indexed from, address indexed to, address indexed contract_, uint256 tokenId, bytes32 rights, bool enable);

    /// @notice Emitted when an address delegates or revokes rights for an amount of ERC20 tokens
    event DelegateERC20(address indexed from, address indexed to, address indexed contract_, bytes32 rights, uint256 amount);

    /// @notice Emitted when an address delegates or revokes rights for an amount of an ERC1155 tokenId
    event DelegateERC1155(address indexed from, address indexed to, address indexed contract_, uint256 tokenId, bytes32 rights, uint256 amount);

    /// @notice Thrown if multicall calldata is malformed
    error MulticallFailed();

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
     * @param data The encoded function data for each of the calls to make to this contract
     * @return results The results from each of the calls passed in via data
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    /**
     * @notice Allow the delegate to act on behalf of `msg.sender` for all contracts
     * @param to The address to act as delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateAll(address to, bytes32 rights, bool enable) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of `msg.sender` for a specific contract
     * @param to The address to act as delegate
     * @param contract_ The contract whose rights are being delegated
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateContract(address to, address contract_, bytes32 rights, bool enable) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of `msg.sender` for a specific ERC721 token
     * @param to The address to act as delegate
     * @param contract_ The contract whose rights are being delegated
     * @param tokenId The token id to delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC721(address to, address contract_, uint256 tokenId, bytes32 rights, bool enable) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of `msg.sender` for a specific amount of ERC20 tokens
     * @dev The actual amount is not encoded in the hash, just the existence of a amount (since it is an upper bound)
     * @param to The address to act as delegate
     * @param contract_ The address for the fungible token contract
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param amount The amount to delegate, > 0 delegates and 0 revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC20(address to, address contract_, bytes32 rights, uint256 amount) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of `msg.sender` for a specific amount of ERC1155 tokens
     * @dev The actual amount is not encoded in the hash, just the existence of a amount (since it is an upper bound)
     * @param to The address to act as delegate
     * @param contract_ The address of the contract that holds the token
     * @param tokenId The token id to delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param amount The amount of that token id to delegate, > 0 delegates and 0 revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC1155(address to, address contract_, uint256 tokenId, bytes32 rights, uint256 amount) external payable returns (bytes32 delegationHash);

    /**
     * ----------- CHECKS -----------
     */

    /**
     * @notice Check if `to` is a delegate of `from` for the entire wallet
     * @param to The potential delegate address
     * @param from The potential address who delegated rights
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on the from's behalf
     */
    function checkDelegateForAll(address to, address from, bytes32 rights) external view returns (bool);

    /**
     * @notice Check if `to` is a delegate of `from` for the specified `contract_` or the entire wallet
     * @param to The delegated address to check
     * @param contract_ The specific contract address being checked
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on from's behalf for entire wallet or that specific contract
     */
    function checkDelegateForContract(address to, address from, address contract_, bytes32 rights) external view returns (bool);

    /**
     * @notice Check if `to` is a delegate of `from` for the specific `contract` and `tokenId`, the entire `contract_`, or the entire wallet
     * @param to The delegated address to check
     * @param contract_ The specific contract address being checked
     * @param tokenId The token id for the token to delegating
     * @param from The wallet that issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on from's behalf for entire wallet, that contract, or that specific tokenId
     */
    function checkDelegateForERC721(address to, address from, address contract_, uint256 tokenId, bytes32 rights) external view returns (bool);

    /**
     * @notice Returns the amount of ERC20 tokens the delegate is granted rights to act on the behalf of
     * @param to The delegated address to check
     * @param contract_ The address of the token contract
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return balance The delegated balance, which will be 0 if the delegation does not exist
     */
    function checkDelegateForERC20(address to, address from, address contract_, bytes32 rights) external view returns (uint256);

    /**
     * @notice Returns the amount of a ERC1155 tokens the delegate is granted rights to act on the behalf of
     * @param to The delegated address to check
     * @param contract_ The address of the token contract
     * @param tokenId The token id to check the delegated amount of
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return balance The delegated balance, which will be 0 if the delegation does not exist
     */
    function checkDelegateForERC1155(address to, address from, address contract_, uint256 tokenId, bytes32 rights) external view returns (uint256);

    /**
     * ----------- ENUMERATIONS -----------
     */

    /**
     * @notice Returns all enabled delegations a given delegate has received
     * @param to The address to retrieve delegations for
     * @return delegations Array of Delegation structs
     */
    function getIncomingDelegations(address to) external view returns (Delegation[] memory delegations);

    /**
     * @notice Returns all enabled delegations an address has given out
     * @param from The address to retrieve delegations for
     * @return delegations Array of Delegation structs
     */
    function getOutgoingDelegations(address from) external view returns (Delegation[] memory delegations);

    /**
     * @notice Returns all hashes associated with enabled delegations an address has received
     * @param to The address to retrieve incoming delegation hashes for
     * @return delegationHashes Array of delegation hashes
     */
    function getIncomingDelegationHashes(address to) external view returns (bytes32[] memory delegationHashes);

    /**
     * @notice Returns all hashes associated with enabled delegations an address has given out
     * @param from The address to retrieve outgoing delegation hashes for
     * @return delegationHashes Array of delegation hashes
     */
    function getOutgoingDelegationHashes(address from) external view returns (bytes32[] memory delegationHashes);

    /**
     * @notice Returns the delegations for a given array of delegation hashes
     * @param delegationHashes is an array of hashes that correspond to delegations
     * @return delegations Array of Delegation structs, return empty structs for nonexistent or revoked delegations
     */
    function getDelegationsFromHashes(bytes32[] calldata delegationHashes) external view returns (Delegation[] memory delegations);

    /**
     * ----------- STORAGE ACCESS -----------
     */

    /**
     * @notice Allows external contracts to read arbitrary storage slots
     */
    function readSlot(bytes32 location) external view returns (bytes32);

    /**
     * @notice Allows external contracts to read an arbitrary array of storage slots
     */
    function readSlots(bytes32[] calldata locations) external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import {IDelegateRegistry} from "../IDelegateRegistry.sol";

/**
 * @title Library for calculating the hashes and storage locations used in the delegate registry
 *
 * The encoding for the 5 types of delegate registry hashes should be as follows:
 *
 * ALL:         keccak256(abi.encodePacked(rights, from, to))
 * CONTRACT:    keccak256(abi.encodePacked(rights, from, to, contract_))
 * ERC721:      keccak256(abi.encodePacked(rights, from, to, contract_, tokenId))
 * ERC20:       keccak256(abi.encodePacked(rights, from, to, contract_))
 * ERC1155:     keccak256(abi.encodePacked(rights, from, to, contract_, tokenId))
 *
 * To avoid collisions between the hashes with respect to type, the hash is shifted left by one byte
 * and the last byte is then encoded with a unique number for the delegation type
 *
 */
library RegistryHashes {
    /// @dev Used to delete everything but the last byte of a 32 byte word with and(word, EXTRACT_LAST_BYTE)
    uint256 internal constant EXTRACT_LAST_BYTE = 0xff;
    /// @dev Constants for the delegate registry delegation type enumeration
    uint256 internal constant ALL_TYPE = 1;
    uint256 internal constant CONTRACT_TYPE = 2;
    uint256 internal constant ERC721_TYPE = 3;
    uint256 internal constant ERC20_TYPE = 4;
    uint256 internal constant ERC1155_TYPE = 5;
    /// @dev Constant for the location of the delegations array in the delegate registry, defined to be zero
    uint256 internal constant DELEGATION_SLOT = 0;

    /**
     * @notice Helper function to decode last byte of a delegation hash into its delegation type enum
     * @param inputHash The bytehash to decode the type from
     * @return decodedType The delegation type
     */
    function decodeType(bytes32 inputHash) internal pure returns (IDelegateRegistry.DelegationType decodedType) {
        assembly {
            decodedType := and(inputHash, EXTRACT_LAST_BYTE)
        }
    }

    /**
     * @notice Helper function that computes the storage location of a particular delegation array
     * @dev Storage keys further down the array can be obtained by adding computedLocation with the element position
     * @dev Follows the solidity storage location encoding for a mapping(bytes32 => fixedArray) at the position of the delegationSlot
     * @param inputHash The bytehash to decode the type from
     * @return computedLocation is the storage key of the delegation array at position 0
     */
    function location(bytes32 inputHash) internal pure returns (bytes32 computedLocation) {
        assembly ("memory-safe") {
            // This block only allocates memory in the scratch space
            mstore(0, inputHash)
            mstore(32, DELEGATION_SLOT)
            computedLocation := keccak256(0, 64) // Run keccak256 over bytes in scratch space to obtain the storage key
        }
    }

    /**
     * @notice Helper function to compute delegation hash for `DelegationType.ALL`
     * @dev Equivalent to `keccak256(abi.encodePacked(rights, from, to))` then left-shift by 1 byte and write the delegation type to the cleaned last byte
     * @dev Will not revert if `from` or `to` are > uint160, any input larger than uint160 for `from` and `to` will be cleaned to its lower 20 bytes
     * @param from The address making the delegation
     * @param rights The rights specified by the delegation
     * @param to The address receiving the delegation
     * @return hash The delegation parameters encoded with ALL_TYPE
     */
    function allHash(address from, bytes32 rights, address to) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            // This block only allocates memory after the free memory pointer
            let ptr := mload(64) // Load the free memory pointer
            // Lay out the variables from last to first, agnostic to upper 96 bits of address words.
            mstore(add(ptr, 40), to)
            mstore(add(ptr, 20), from)
            mstore(ptr, rights)
            hash := or(shl(8, keccak256(ptr, 72)), ALL_TYPE) // Keccak-hashes the packed encoding, left-shifts by one byte, then writes type to the lowest-order byte
        }
    }

    /**
     * @notice Helper function to compute delegation location for `DelegationType.ALL`
     * @dev Equivalent to `location(allHash(rights, from, to))`
     * @dev Will not revert if `from` or `to` are > uint160, any input larger than uint160 for `from` and `to` will be cleaned to its lower 20 bytes
     * @param from The address making the delegation
     * @param rights The rights specified by the delegation
     * @param to The address receiving the delegation
     * @return computedLocation The storage location of the all delegation with those parameters in the delegations mapping
     */
    function allLocation(address from, bytes32 rights, address to) internal pure returns (bytes32 computedLocation) {
        assembly ("memory-safe") {
            // This block only allocates memory after the free memory pointer and in the scratch space
            let ptr := mload(64) // Load the free memory pointer
            // Lay out the variables from last to first, agnostic to upper 96 bits of address words.
            mstore(add(ptr, 40), to)
            mstore(add(ptr, 20), from)
            mstore(ptr, rights)
            mstore(0, or(shl(8, keccak256(ptr, 72)), ALL_TYPE)) // Computes `allHash`, then stores the result in scratch space
            mstore(32, DELEGATION_SLOT)
            computedLocation := keccak256(0, 64) // Runs keccak over the scratch space to obtain the storage key
        }
    }

    /**
     * @notice Helper function to compute delegation hash for `DelegationType.CONTRACT`
     * @dev Equivalent to keccak256(abi.encodePacked(rights, from, to, contract_)) left-shifted by 1 then last byte overwritten with CONTRACT_TYPE
     * @dev Will not revert if `from`, `to` or `contract_` are > uint160, these inputs will be cleaned to their lower 20 bytes
     * @param from The address making the delegation
     * @param rights The rights specified by the delegation
     * @param to The address receiving the delegation
     * @param contract_ The address of the contract specified by the delegation
     * @return hash The delegation parameters encoded with CONTRACT_TYPE
     */
    function contractHash(address from, bytes32 rights, address to, address contract_) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            // This block only allocates memory after the free memory pointer
            let ptr := mload(64) // Load the free memory pointer
            // Lay out the variables from last to first, agnostic to upper 96 bits of address words.
            mstore(add(ptr, 60), contract_)
            mstore(add(ptr, 40), to)
            mstore(add(ptr, 20), from)
            mstore(ptr, rights)
            hash := or(shl(8, keccak256(ptr, 92)), CONTRACT_TYPE) // Keccak-hashes the packed encoding, left-shifts by one byte, then writes type to the lowest-order byte
        }
    }

    /**
     * @notice Helper function to compute delegation location for `DelegationType.CONTRACT`
     * @dev Equivalent to `location(contractHash(rights, from, to, contract_))`
     * @dev Will not revert if `from`, `to` or `contract_` are > uint160, these inputs will be cleaned to their lower 20 bytes
     * @param from The address making the delegation
     * @param rights The rights specified by the delegation
     * @param to The address receiving the delegation
     * @param contract_ The address of the contract specified by the delegation
     * @return computedLocation The storage location of the contract delegation with those parameters in the delegations mapping
     */
    function contractLocation(address from, bytes32 rights, address to, address contract_) internal pure returns (bytes32 computedLocation) {
        assembly ("memory-safe") {
            // This block only allocates memory after the free memory pointer and in the scratch space
            let ptr := mload(64) // Load free memory pointer
            // Lay out the variables from last to first, agnostic to upper 96 bits of address words.
            mstore(add(ptr, 60), contract_)
            mstore(add(ptr, 40), to)
            mstore(add(ptr, 20), from)
            mstore(ptr, rights)
            mstore(0, or(shl(8, keccak256(ptr, 92)), CONTRACT_TYPE)) // Computes `contractHash`, then stores the result in scratch space
            mstore(32, DELEGATION_SLOT)
            computedLocation := keccak256(0, 64) // Runs keccak over the scratch space to obtain the storage key
        }
    }

    /**
     * @notice Helper function to compute delegation hash for `DelegationType.ERC721`
     * @dev Equivalent to `keccak256(abi.encodePacked(rights, from, to, contract_, tokenId)) left-shifted by 1 then last byte overwritten with ERC721_TYPE
     * @dev Will not revert if `from`, `to` or `contract_` are > uint160, these inputs will be cleaned to their lower 20 bytes
     * @param from The address making the delegation
     * @param rights The rights specified by the delegation
     * @param to The address receiving the delegation
     * @param tokenId The id of the token specified by the delegation
     * @param contract_ The address of the contract specified by the delegation
     * @return hash The delegation parameters encoded with ERC721_TYPE
     */
    function erc721Hash(address from, bytes32 rights, address to, uint256 tokenId, address contract_) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            // This block only allocates memory after the free memory pointer
            let ptr := mload(64) // Cache the free memory pointer.
            // Lay out the variables from last to first, agnostic to upper 96 bits of address words.
            mstore(add(ptr, 92), tokenId)
            mstore(add(ptr, 60), contract_)
            mstore(add(ptr, 40), to)
            mstore(add(ptr, 20), from)
            mstore(ptr, rights)
            hash := or(shl(8, keccak256(ptr, 124)), ERC721_TYPE) // Keccak-hashes the packed encoding, left-shifts by one byte, then writes type to the lowest-order byte
        }
    }

    /**
     * @notice Helper function to compute delegation location for `DelegationType.ERC721`
     * @dev Equivalent to `location(ERC721Hash(rights, from, to, contract_, tokenId))`
     * @dev Will not revert if `from`, `to` or `contract_` are > uint160, these inputs will be cleaned to their lower 20 bytes
     * @param from The address making the delegation
     * @param rights The rights specified by the delegation
     * @param to The address receiving the delegation
     * @param tokenId The id of the ERC721 token
     * @param contract_ The address of the ERC721 token contract
     * @return computedLocation The storage location of the ERC721 delegation with those parameters in the delegations mapping
     */
    function erc721Location(address from, bytes32 rights, address to, uint256 tokenId, address contract_) internal pure returns (bytes32 computedLocation) {
        assembly ("memory-safe") {
            // This block only allocates memory after the free memory pointer and in the scratch space
            let ptr := mload(64) // Cache the free memory pointer.
            // Lay out the variables from last to first, agnostic to upper 96 bits of address words.
            mstore(add(ptr, 92), tokenId)
            mstore(add(ptr, 60), contract_)
            mstore(add(ptr, 40), to)
            mstore(add(ptr, 20), from)
            mstore(ptr, rights)
            mstore(0, or(shl(8, keccak256(ptr, 124)), ERC721_TYPE)) // Computes erc721Hash, then stores the result in scratch space
            mstore(32, DELEGATION_SLOT)
            computedLocation := keccak256(0, 64) // Runs keccak256 over the scratch space to obtain the storage key
        }
    }

    /**
     * @notice Helper function to compute delegation hash for `DelegationType.ERC20`
     * @dev Equivalent to `keccak256(abi.encodePacked(rights, from, to, contract_))` with the last byte overwritten with ERC20_TYPE
     * @dev Will not revert if `from`, `to` or `contract_` are > uint160, these inputs will be cleaned to their lower 20 bytes
     * @param from The address making the delegation
     * @param rights The rights specified by the delegation
     * @param to The address receiving the delegation
     * @param contract_ The address of the ERC20 token contract
     * @return hash The parameters encoded with ERC20_TYPE
     */
    function erc20Hash(address from, bytes32 rights, address to, address contract_) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            // This block only allocates memory after the free memory pointer
            let ptr := mload(64) // Load free memory pointer
            // Lay out the variables from last to first, agnostic to upper 96 bits of address words.
            mstore(add(ptr, 60), contract_)
            mstore(add(ptr, 40), to)
            mstore(add(ptr, 20), from)
            mstore(ptr, rights)
            hash := or(shl(8, keccak256(ptr, 92)), ERC20_TYPE) // Keccak-hashes the packed encoding, left-shifts by one byte, then writes type to the lowest-order byte
        }
    }

    /**
     * @notice Helper function to compute delegation location for `DelegationType.ERC20`
     * @dev Equivalent to `location(ERC20Hash(rights, from, to, contract_))`
     * @dev Will not revert if `from`, `to` or `contract_` are > uint160, these inputs will be cleaned to their lower 20 bytes
     * @param from The address making the delegation
     * @param rights The rights specified by the delegation
     * @param to The address receiving the delegation
     * @param contract_ The address of the ERC20 token contract
     * @return computedLocation The storage location of the ERC20 delegation with those parameters in the delegations mapping
     */
    function erc20Location(address from, bytes32 rights, address to, address contract_) internal pure returns (bytes32 computedLocation) {
        assembly ("memory-safe") {
            // This block only allocates memory after the free memory pointer and in the scratch space
            let ptr := mload(64) // Loads the free memory pointer
            // Lay out the variables from last to first, agnostic to upper 96 bits of address words.
            mstore(add(ptr, 60), contract_)
            mstore(add(ptr, 40), to)
            mstore(add(ptr, 20), from)
            mstore(ptr, rights)
            mstore(0, or(shl(8, keccak256(ptr, 92)), ERC20_TYPE)) // Computes erc20Hash, then stores the result in scratch space
            mstore(32, DELEGATION_SLOT)
            computedLocation := keccak256(0, 64) // Runs keccak over the scratch space to obtain the storage key
        }
    }

    /**
     * @notice Helper function to compute delegation hash for `DelegationType.ERC1155`
     * @dev Equivalent to keccak256(abi.encodePacked(rights, from, to, contract_, tokenId)) left-shifted with the last byte overwritten with ERC1155_TYPE
     * @dev Will not revert if `from`, `to` or `contract_` are > uint160, these inputs will be cleaned to their lower 20 bytes
     * @param from The address making the delegation
     * @param rights The rights specified by the delegation
     * @param to The address receiving the delegation
     * @param tokenId The id of the ERC1155 token
     * @param contract_ The address of the ERC1155 token contract
     * @return hash The parameters encoded with ERC1155_TYPE
     */
    function erc1155Hash(address from, bytes32 rights, address to, uint256 tokenId, address contract_) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            // This block only allocates memory after the free memory pointer
            let ptr := mload(64) // Load the free memory pointer.
            // Lay out the variables from last to first, agnostic to upper 96 bits of address words.
            mstore(add(ptr, 92), tokenId)
            mstore(add(ptr, 60), contract_)
            mstore(add(ptr, 40), to)
            mstore(add(ptr, 20), from)
            mstore(ptr, rights)
            hash := or(shl(8, keccak256(ptr, 124)), ERC1155_TYPE) // Keccak-hashes the packed encoding, left-shifts by one byte, then writes type to the lowest-order byte
        }
    }

    /**
     * @notice Helper function to compute delegation location for `DelegationType.ERC1155`
     * @dev Equivalent to `location(ERC1155Hash(rights, from, to, contract_, tokenId))`
     * @dev Will not revert if `from`, `to` or `contract_` are > uint160, these inputs will be cleaned to their lower 20 bytes
     * @param from The address making the delegation
     * @param rights The rights specified by the delegation
     * @param to The address receiving the delegation
     * @param tokenId The id of the ERC1155 token
     * @param contract_ The address of the ERC1155 token contract
     * @return computedLocation The storage location of the ERC1155 delegation with those parameters in the delegations mapping
     */
    function erc1155Location(address from, bytes32 rights, address to, uint256 tokenId, address contract_) internal pure returns (bytes32 computedLocation) {
        assembly ("memory-safe") {
            // This block only allocates memory after the free memory pointer and in the scratch space
            let ptr := mload(64) // Cache the free memory pointer.
            // Lay out the variables from last to first, agnostic to upper 96 bits of address words.
            mstore(add(ptr, 92), tokenId)
            mstore(add(ptr, 60), contract_)
            mstore(add(ptr, 40), to)
            mstore(add(ptr, 20), from)
            mstore(ptr, rights)
            mstore(0, or(shl(8, keccak256(ptr, 124)), ERC1155_TYPE)) // Computes erc1155Hash, then stores the result in scratch space
            mstore(32, DELEGATION_SLOT)
            computedLocation := keccak256(0, 64) // Runs keccak over the scratch space to obtain the storage key
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

library RegistryStorage {
    /// @dev Standardizes `from` storage flags to prevent double-writes in the delegation in/outbox if the same delegation is revoked and rewritten
    address internal constant DELEGATION_EMPTY = address(0);
    address internal constant DELEGATION_REVOKED = address(1);

    /// @dev Standardizes storage positions of delegation data
    uint256 internal constant POSITIONS_FIRST_PACKED = 0; //  | 4 bytes empty | first 8 bytes of contract address | 20 bytes of from address |
    uint256 internal constant POSITIONS_SECOND_PACKED = 1; // |        last 12 bytes of contract address          | 20 bytes of to address   |
    uint256 internal constant POSITIONS_RIGHTS = 2;
    uint256 internal constant POSITIONS_TOKEN_ID = 3;
    uint256 internal constant POSITIONS_AMOUNT = 4;

    /// @dev Used to clean address types of dirty bits with `and(address, CLEAN_ADDRESS)`
    uint256 internal constant CLEAN_ADDRESS = 0x00ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Used to clean everything but the first 8 bytes of an address
    uint256 internal constant CLEAN_FIRST8_BYTES_ADDRESS = 0xffffffffffffffff << 96;

    /// @dev Used to clean everything but the first 8 bytes of an address in the packed position
    uint256 internal constant CLEAN_PACKED8_BYTES_ADDRESS = 0xffffffffffffffff << 160;

    /**
     * @notice Helper function that packs from, to, and contract_ address to into the two slot configuration
     * @param from The address making the delegation
     * @param to The address receiving the delegation
     * @param contract_ The contract address associated with the delegation (optional)
     * @return firstPacked The firstPacked storage configured with the parameters
     * @return secondPacked The secondPacked storage configured with the parameters
     * @dev Will not revert if `from`, `to`, and `contract_` are > uint160, any inputs with dirty bits outside the last 20 bytes will be cleaned
     */
    function packAddresses(address from, address to, address contract_) internal pure returns (bytes32 firstPacked, bytes32 secondPacked) {
        assembly {
            firstPacked := or(shl(64, and(contract_, CLEAN_FIRST8_BYTES_ADDRESS)), and(from, CLEAN_ADDRESS))
            secondPacked := or(shl(160, contract_), and(to, CLEAN_ADDRESS))
        }
    }

    /**
     * @notice Helper function that unpacks from, to, and contract_ address inside the firstPacked secondPacked storage configuration
     * @param firstPacked The firstPacked storage to be decoded
     * @param secondPacked The secondPacked storage to be decoded
     * @return from The address making the delegation
     * @return to The address receiving the delegation
     * @return contract_ The contract address associated with the delegation
     * @dev Will not revert if `from`, `to`, and `contract_` are > uint160, any inputs with dirty bits outside the last 20 bytes will be cleaned
     */
    function unpackAddresses(bytes32 firstPacked, bytes32 secondPacked) internal pure returns (address from, address to, address contract_) {
        assembly {
            from := and(firstPacked, CLEAN_ADDRESS)
            to := and(secondPacked, CLEAN_ADDRESS)
            contract_ := or(shr(64, and(firstPacked, CLEAN_PACKED8_BYTES_ADDRESS)), shr(160, secondPacked))
        }
    }

    /**
     * @notice Helper function that can unpack the from or to address from their respective packed slots in the registry
     * @param packedSlot The slot containing the from or to address
     * @return unpacked The `from` or `to` address
     * @dev Will not work if you want to obtain the contract address, use unpackAddresses
     */
    function unpackAddress(bytes32 packedSlot) internal pure returns (address unpacked) {
        assembly {
            unpacked := and(packedSlot, CLEAN_ADDRESS)
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

library RegistryOps {
    /// @dev `x > y ? x : y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // `gt(y, x)` will evaluate to 1 if `y > x`, else 0.
            //
            // If `y > x`:
            //     `x ^ ((x ^ y) * 1) = x ^ (x ^ y) = (x ^ x) ^ y = 0 ^ y = y`.
            // otherwise:
            //     `x ^ ((x ^ y) * 0) = x ^ 0 = x`.
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev `x & y`.
    function and(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := and(iszero(iszero(x)), iszero(iszero(y))) // Compiler cleans dirty booleans on the stack to 1, so do the same here
        }
    }

    /// @dev `x | y`.
    function or(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := or(iszero(iszero(x)), iszero(iszero(y))) // Compiler cleans dirty booleans on the stack to 1, so do the same here
        }
    }
}