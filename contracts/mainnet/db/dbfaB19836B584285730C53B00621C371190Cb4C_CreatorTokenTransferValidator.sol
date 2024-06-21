// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IEOARegistry.sol";
import "./ITransferSecurityRegistry.sol";
import "./ITransferValidator.sol";

interface ICreatorTokenTransferValidator is ITransferSecurityRegistry, ITransferValidator, IEOARegistry {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IEOARegistry is IERC165 {
    function isVerifiedEOA(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOwnable {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/TransferPolicy.sol";

interface ITransferSecurityRegistry {
    event AddedToAllowlist(AllowlistTypes indexed kind, uint256 indexed id, address indexed account);
    event CreatedAllowlist(AllowlistTypes indexed kind, uint256 indexed id, string indexed name);
    event ReassignedAllowlistOwnership(AllowlistTypes indexed kind, uint256 indexed id, address indexed newOwner);
    event RemovedFromAllowlist(AllowlistTypes indexed kind, uint256 indexed id, address indexed account);
    event SetAllowlist(AllowlistTypes indexed kind, address indexed collection, uint120 indexed id);
    event SetTransferSecurityLevel(address indexed collection, TransferSecurityLevels level);

    function createOperatorWhitelist(string calldata name) external returns (uint120);
    function createPermittedContractReceiverAllowlist(string calldata name) external returns (uint120);
    function reassignOwnershipOfOperatorWhitelist(uint120 id, address newOwner) external;
    function reassignOwnershipOfPermittedContractReceiverAllowlist(uint120 id, address newOwner) external;
    function renounceOwnershipOfOperatorWhitelist(uint120 id) external;
    function renounceOwnershipOfPermittedContractReceiverAllowlist(uint120 id) external;
    function setTransferSecurityLevelOfCollection(address collection, TransferSecurityLevels level) external;
    function setOperatorWhitelistOfCollection(address collection, uint120 id) external;
    function setPermittedContractReceiverAllowlistOfCollection(address collection, uint120 id) external;
    function addOperatorToWhitelist(uint120 id, address operator) external;
    function addPermittedContractReceiverToAllowlist(uint120 id, address receiver) external;
    function removeOperatorFromWhitelist(uint120 id, address operator) external;
    function removePermittedContractReceiverFromAllowlist(uint120 id, address receiver) external;
    function getCollectionSecurityPolicy(address collection) external view returns (CollectionSecurityPolicy memory);
    function getWhitelistedOperators(uint120 id) external view returns (address[] memory);
    function getPermittedContractReceivers(uint120 id) external view returns (address[] memory);
    function isOperatorWhitelisted(uint120 id, address operator) external view returns (bool);
    function isContractReceiverPermitted(uint120 id, address receiver) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/TransferPolicy.sol";

interface ITransferValidator {
    function applyCollectionTransferPolicy(address caller, address from, address to) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./EOARegistry.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/ICreatorTokenTransferValidator.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title  CreatorTokenTransferValidator
 * @author Limit Break, Inc.
 * @notice The CreatorTokenTransferValidator contract is designed to provide a customizable and secure transfer 
 *         validation mechanism for NFT collections. This contract allows the owner of an NFT collection to configure 
 *         the transfer security level, operator whitelist, and permitted contract receiver allowlist for each 
 *         collection.
 *
 * @dev    <h4>Features</h4>
 *         - Transfer security levels: Provides different levels of transfer security, 
 *           from open transfers to completely restricted transfers.
 *         - Operator whitelist: Allows the owner of a collection to whitelist specific operator addresses permitted
 *           to execute transfers on behalf of others.
 *         - Permitted contract receiver allowlist: Enables the owner of a collection to allow specific contract 
 *           addresses to receive NFTs when otherwise disabled by security policy.
 *
 * @dev    <h4>Benefits</h4>
 *         - Enhanced security: Allows creators to have more control over their NFT collections, ensuring the safety 
 *           and integrity of their assets.
 *         - Flexibility: Provides collection owners the ability to customize transfer rules as per their requirements.
 *         - Compliance: Facilitates compliance with regulations by enabling creators to restrict transfers based on 
 *           specific criteria.
 *
 * @dev    <h4>Intended Usage</h4>
 *         - The CreatorTokenTransferValidator contract is intended to be used by NFT collection owners to manage and 
 *           enforce transfer policies. This contract is integrated with the following varations of creator token 
 *           NFT contracts to validate transfers according to the defined security policies.
 *
 *           - ERC721-C:   Creator token implenting OpenZeppelin's ERC-721 standard.
 *           - ERC721-AC:  Creator token implenting Azuki's ERC-721A standard.
 *           - ERC721-CW:  Creator token implementing OpenZeppelin's ERC-721 standard with opt-in staking to 
 *                         wrap/upgrade a pre-existing ERC-721 collection.
 *           - ERC721-ACW: Creator token implementing Azuki's ERC721-A standard with opt-in staking to 
 *                         wrap/upgrade a pre-existing ERC-721 collection.
 *           - ERC1155-C:  Creator token implenting OpenZeppelin's ERC-1155 standard.
 *           - ERC1155-CW: Creator token implementing OpenZeppelin's ERC-1155 standard with opt-in staking to 
 *                         wrap/upgrade a pre-existing ERC-1155 collection.
 *
 *          <h4>Transfer Security Levels</h4>
 *          - Level 0 (Zero): No transfer restrictions.
 *            - Caller Constraints: None
 *            - Receiver Constraints: None
 *          - Level 1 (One): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading enabled.
 *            - Caller Constraints: OperatorWhitelistEnableOTC
 *            - Receiver Constraints: None
 *          - Level 2 (Two): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading disabled.
 *            - Caller Constraints: OperatorWhitelistDisableOTC
 *            - Receiver Constraints: None
 *          - Level 3 (Three): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading enabled. Transfers to contracts with code are not allowed.
 *            - Caller Constraints: OperatorWhitelistEnableOTC
 *            - Receiver Constraints: NoCode
 *          - Level 4 (Four): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading enabled. Transfers are allowed only to Externally Owned Accounts (EOAs).
 *            - Caller Constraints: OperatorWhitelistEnableOTC
 *            - Receiver Constraints: EOA
 *          - Level 5 (Five): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading disabled. Transfers to contracts with code are not allowed.
 *            - Caller Constraints: OperatorWhitelistDisableOTC
 *            - Receiver Constraints: NoCode
 *          - Level 6 (Six): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading disabled. Transfers are allowed only to Externally Owned Accounts (EOAs).
 *            - Caller Constraints: OperatorWhitelistDisableOTC
 *            - Receiver Constraints: EOA
 */
contract CreatorTokenTransferValidator is EOARegistry, ICreatorTokenTransferValidator {
    using EnumerableSet for EnumerableSet.AddressSet;

    error CreatorTokenTransferValidator__AddressAlreadyAllowed();
    error CreatorTokenTransferValidator__AddressNotAllowed();
    error CreatorTokenTransferValidator__AllowlistDoesNotExist();
    error CreatorTokenTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress();
    error CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist();
    error CreatorTokenTransferValidator__CallerMustBeWhitelistedOperator();
    error CreatorTokenTransferValidator__CallerMustHaveElevatedPermissionsForSpecifiedNFT();
    error CreatorTokenTransferValidator__ReceiverMustNotHaveDeployedCode();
    error CreatorTokenTransferValidator__ReceiverProofOfEOASignatureUnverified();
    
    bytes32 private constant DEFAULT_ACCESS_CONTROL_ADMIN_ROLE = 0x00;
    TransferSecurityLevels public constant DEFAULT_TRANSFER_SECURITY_LEVEL = TransferSecurityLevels.Zero;

    uint120 private lastOperatorWhitelistId;
    uint120 private lastPermittedContractReceiverAllowlistId;

    mapping (TransferSecurityLevels => TransferSecurityPolicy) public transferSecurityPolicies;
    mapping (address => CollectionSecurityPolicy) private collectionSecurityPolicies;
    mapping (uint120 => address) public operatorWhitelistOwners;
    mapping (uint120 => address) public permittedContractReceiverAllowlistOwners;
    mapping (uint120 => EnumerableSet.AddressSet) private operatorWhitelists;
    mapping (uint120 => EnumerableSet.AddressSet) private permittedContractReceiverAllowlists;

    constructor(address defaultOwner) EOARegistry() {
        transferSecurityPolicies[TransferSecurityLevels.Zero] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.None,
            receiverConstraints: ReceiverConstraints.None
        });

        transferSecurityPolicies[TransferSecurityLevels.One] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistEnableOTC,
            receiverConstraints: ReceiverConstraints.None
        });

        transferSecurityPolicies[TransferSecurityLevels.Two] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistDisableOTC,
            receiverConstraints: ReceiverConstraints.None
        });

        transferSecurityPolicies[TransferSecurityLevels.Three] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistEnableOTC,
            receiverConstraints: ReceiverConstraints.NoCode
        });

        transferSecurityPolicies[TransferSecurityLevels.Four] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistEnableOTC,
            receiverConstraints: ReceiverConstraints.EOA
        });

        transferSecurityPolicies[TransferSecurityLevels.Five] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistDisableOTC,
            receiverConstraints: ReceiverConstraints.NoCode
        });

        transferSecurityPolicies[TransferSecurityLevels.Six] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistDisableOTC,
            receiverConstraints: ReceiverConstraints.EOA
        });

        uint120 id = ++lastOperatorWhitelistId;

        operatorWhitelistOwners[id] = defaultOwner;

        emit CreatedAllowlist(AllowlistTypes.Operators, id, "DEFAULT OPERATOR WHITELIST");
        emit ReassignedAllowlistOwnership(AllowlistTypes.Operators, id, defaultOwner);
    }

    /**
     * @notice Apply the collection transfer policy to a transfer operation of a creator token.
     *
     * @dev Throws when the receiver has deployed code but is not in the permitted contract receiver allowlist,
     *      if the ReceiverConstraints is set to NoCode.
     * @dev Throws when the receiver has never verified a signature to prove they are an EOA and the receiver
     *      is not in the permitted contract receiver allowlist, if the ReceiverConstraints is set to EOA.
     * @dev Throws when `msg.sender` is not a whitelisted operator, if CallerConstraints is OperatorWhitelistDisableOTC.
     * @dev Throws when `msg.sender` is neither a whitelisted operator nor the 'from' addresses,
     *      if CallerConstraints is OperatorWhitelistEnableOTC.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. Transfer is allowed or denied based on the applied transfer policy.
     *
     * @param caller The address initiating the transfer.
     * @param from   The address of the token owner.
     * @param to     The address of the token receiver.
     */
    function applyCollectionTransferPolicy(address caller, address from, address to) external view override {
        address collection = _msgSender();
        CollectionSecurityPolicy memory collectionSecurityPolicy = collectionSecurityPolicies[collection];
        TransferSecurityPolicy memory transferSecurityPolicy = 
            transferSecurityPolicies[collectionSecurityPolicy.transferSecurityLevel];
        
        if (transferSecurityPolicy.receiverConstraints == ReceiverConstraints.NoCode) {
            if (to.code.length > 0) {
                if (!isContractReceiverPermitted(collectionSecurityPolicy.permittedContractReceiversId, to)) {
                    revert CreatorTokenTransferValidator__ReceiverMustNotHaveDeployedCode();
                }
            }
        } else if (transferSecurityPolicy.receiverConstraints == ReceiverConstraints.EOA) {
            if (!isVerifiedEOA(to)) {
                if (!isContractReceiverPermitted(collectionSecurityPolicy.permittedContractReceiversId, to)) {
                    revert CreatorTokenTransferValidator__ReceiverProofOfEOASignatureUnverified();
                }
            }
        }

        if (transferSecurityPolicy.callerConstraints != CallerConstraints.None) {
            if(operatorWhitelists[collectionSecurityPolicy.operatorWhitelistId].length() > 0) {
                if (!isOperatorWhitelisted(collectionSecurityPolicy.operatorWhitelistId, caller)) {
                    if (transferSecurityPolicy.callerConstraints == CallerConstraints.OperatorWhitelistEnableOTC) {
                        if (caller != from) {
                            revert CreatorTokenTransferValidator__CallerMustBeWhitelistedOperator();
                        }
                    } else {
                        revert CreatorTokenTransferValidator__CallerMustBeWhitelistedOperator();
                    }
                }
            }
        }
    }

    /**
     * @notice Create a new operator whitelist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. A new operator whitelist with the specified name is created.
     *      2. The caller is set as the owner of the new operator whitelist.
     *      3. A `CreatedAllowlist` event is emitted.
     *      4. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param name The name of the new operator whitelist.
     * @return     The id of the new operator whitelist.
     */
    function createOperatorWhitelist(string calldata name) external override returns (uint120) {
        uint120 id = ++lastOperatorWhitelistId;

        operatorWhitelistOwners[id] = _msgSender();

        emit CreatedAllowlist(AllowlistTypes.Operators, id, name);
        emit ReassignedAllowlistOwnership(AllowlistTypes.Operators, id, _msgSender());

        return id;
    }

    /**
     * @notice Create a new permitted contract receiver allowlist.
     * 
     * @dev <h4>Postconditions:</h4>
     *      1. A new permitted contract receiver allowlist with the specified name is created.
     *      2. The caller is set as the owner of the new permitted contract receiver allowlist.
     *      3. A `CreatedAllowlist` event is emitted.
     *      4. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param name The name of the new permitted contract receiver allowlist.
     * @return     The id of the new permitted contract receiver allowlist.
     */
    function createPermittedContractReceiverAllowlist(string calldata name) external override returns (uint120) {
        uint120 id = ++lastPermittedContractReceiverAllowlistId;

        permittedContractReceiverAllowlistOwners[id] = _msgSender();

        emit CreatedAllowlist(AllowlistTypes.PermittedContractReceivers, id, name);
        emit ReassignedAllowlistOwnership(AllowlistTypes.PermittedContractReceivers, id, _msgSender());

        return id;
    }

    /**
     * @notice Transfer ownership of an operator whitelist to a new owner.
     *
     * @dev Throws when the new owner is the zero address.
     * @dev Throws when the caller does not own the specified operator whitelist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The operator whitelist ownership is transferred to the new owner.
     *      2. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param id       The id of the operator whitelist.
     * @param newOwner The address of the new owner.
     */
    function reassignOwnershipOfOperatorWhitelist(uint120 id, address newOwner) external override {
        if(newOwner == address(0)) {
            revert CreatorTokenTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress();
        }

        _reassignOwnershipOfOperatorWhitelist(id, newOwner);
    }

    /**
     * @notice Transfer ownership of a permitted contract receiver allowlist to a new owner.
     *
     * @dev Throws when the new owner is the zero address.
     * @dev Throws when the caller does not own the specified permitted contract receiver allowlist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The permitted contract receiver allowlist ownership is transferred to the new owner.
     *      2. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param id       The id of the permitted contract receiver allowlist.
     * @param newOwner The address of the new owner.
     */
    function reassignOwnershipOfPermittedContractReceiverAllowlist(uint120 id, address newOwner) external override {
        if(newOwner == address(0)) {
            revert CreatorTokenTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress();
        }

        _reassignOwnershipOfPermittedContractReceiverAllowlist(id, newOwner);
    }

    /**
     * @notice Renounce the ownership of an operator whitelist, rendering the whitelist immutable.
     *
     * @dev Throws when the caller does not own the specified operator whitelist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The ownership of the specified operator whitelist is renounced.
     *      2. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param id The id of the operator whitelist.
     */
    function renounceOwnershipOfOperatorWhitelist(uint120 id) external override {
        _reassignOwnershipOfOperatorWhitelist(id, address(0));
    }

    /**
     * @notice Renounce the ownership of a permitted contract receiver allowlist, rendering the allowlist immutable.
     *
     * @dev Throws when the caller does not own the specified permitted contract receiver allowlist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The ownership of the specified permitted contract receiver allowlist is renounced.
     *      2. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param id The id of the permitted contract receiver allowlist.
     */
    function renounceOwnershipOfPermittedContractReceiverAllowlist(uint120 id) external override {
        _reassignOwnershipOfPermittedContractReceiverAllowlist(id, address(0));
    }

    /**
     * @notice Set the transfer security level of a collection.
     *
     * @dev Throws when the caller is neither collection contract, nor the owner or admin of the specified collection.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The transfer security level of the specified collection is set to the new value.
     *      2. A `SetTransferSecurityLevel` event is emitted.
     *
     * @param collection The address of the collection.
     * @param level      The new transfer security level to apply.
     */
    function setTransferSecurityLevelOfCollection(
        address collection, 
        TransferSecurityLevels level) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(collection);
        collectionSecurityPolicies[collection].transferSecurityLevel = level;
        emit SetTransferSecurityLevel(collection, level);
    }

    /**
     * @notice Set the operator whitelist of a collection.
     * 
     * @dev Throws when the caller is neither collection contract, nor the owner or admin of the specified collection.
     * @dev Throws when the specified operator whitelist id does not exist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The operator whitelist of the specified collection is set to the new value.
     *      2. A `SetAllowlist` event is emitted.
     *
     * @param collection The address of the collection.
     * @param id         The id of the operator whitelist.
     */
    function setOperatorWhitelistOfCollection(address collection, uint120 id) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(collection);

        if (id > lastOperatorWhitelistId) {
            revert CreatorTokenTransferValidator__AllowlistDoesNotExist();
        }

        collectionSecurityPolicies[collection].operatorWhitelistId = id;
        emit SetAllowlist(AllowlistTypes.Operators, collection, id);
    }

    /**
     * @notice Set the permitted contract receiver allowlist of a collection.
     *
     * @dev Throws when the caller does not own the specified collection.
     * @dev Throws when the specified permitted contract receiver allowlist id does not exist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The permitted contract receiver allowlist of the specified collection is set to the new value.
     *      2. A `PermittedContractReceiverAllowlistSet` event is emitted.
     *
     * @param collection The address of the collection.
     * @param id         The id of the permitted contract receiver allowlist.
     */
    function setPermittedContractReceiverAllowlistOfCollection(address collection, uint120 id) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(collection);

        if (id > lastPermittedContractReceiverAllowlistId) {
            revert CreatorTokenTransferValidator__AllowlistDoesNotExist();
        }

        collectionSecurityPolicies[collection].permittedContractReceiversId = id;
        emit SetAllowlist(AllowlistTypes.PermittedContractReceivers, collection, id);
    }

    /**
     * @notice Add an operator to an operator whitelist.
     *
     * @dev Throws when the caller does not own the specified operator whitelist.
     * @dev Throws when the operator address is already allowed.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The operator is added to the specified operator whitelist.
     *      2. An `AddedToAllowlist` event is emitted.
     *
     * @param id       The id of the operator whitelist.
     * @param operator The address of the operator to add.
     */
    function addOperatorToWhitelist(uint120 id, address operator) external override {
        _requireCallerOwnsOperatorWhitelist(id);

        if (!operatorWhitelists[id].add(operator)) {
            revert CreatorTokenTransferValidator__AddressAlreadyAllowed();
        }

        emit AddedToAllowlist(AllowlistTypes.Operators, id, operator);
    }

    /**
     * @notice Add a contract address to a permitted contract receiver allowlist.
     *
     * @dev Throws when the caller does not own the specified permitted contract receiver allowlist.
     * @dev Throws when the contract address is already allowed.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The contract address is added to the specified permitted contract receiver allowlist.
     *      2. An `AddedToAllowlist` event is emitted.
     *
     * @param id              The id of the permitted contract receiver allowlist.
     * @param receiver The address of the contract to add.
     */
    function addPermittedContractReceiverToAllowlist(uint120 id, address receiver) external override {
        _requireCallerOwnsPermittedContractReceiverAllowlist(id);

        if (!permittedContractReceiverAllowlists[id].add(receiver)) {
            revert CreatorTokenTransferValidator__AddressAlreadyAllowed();
        }

        emit AddedToAllowlist(AllowlistTypes.PermittedContractReceivers, id, receiver);
    }

    /**
     * @notice Remove an operator from an operator whitelist.
     *
     * @dev Throws when the caller does not own the specified operator whitelist.
     * @dev Throws when the operator is not in the specified operator whitelist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The operator is removed from the specified operator whitelist.
     *      2. A `RemovedFromAllowlist` event is emitted.
     *
     * @param id       The id of the operator whitelist.
     * @param operator The address of the operator to remove.
     */
    function removeOperatorFromWhitelist(uint120 id, address operator) external override {
        _requireCallerOwnsOperatorWhitelist(id);

        if (!operatorWhitelists[id].remove(operator)) {
            revert CreatorTokenTransferValidator__AddressNotAllowed();
        }

        emit RemovedFromAllowlist(AllowlistTypes.Operators, id, operator);
    }

    /**
     * @notice Remove a contract address from a permitted contract receiver allowlist.
     * 
     * @dev Throws when the caller does not own the specified permitted contract receiver allowlist.
     * @dev Throws when the contract address is not in the specified permitted contract receiver allowlist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The contract address is removed from the specified permitted contract receiver allowlist.
     *      2. A `RemovedFromAllowlist` event is emitted.
     *
     * @param id       The id of the permitted contract receiver allowlist.
     * @param receiver The address of the contract to remove.
     */
    function removePermittedContractReceiverFromAllowlist(uint120 id, address receiver) external override {
        _requireCallerOwnsPermittedContractReceiverAllowlist(id);

        if (!permittedContractReceiverAllowlists[id].remove(receiver)) {
            revert CreatorTokenTransferValidator__AddressNotAllowed();
        }

        emit RemovedFromAllowlist(AllowlistTypes.PermittedContractReceivers, id, receiver);
    }

    /**
     * @notice Get the security policy of the specified collection.
     * @param collection The address of the collection.
     * @return           The security policy of the specified collection, which includes:
     *                   Transfer security level, operator whitelist id, permitted contract receiver allowlist id
     */
    function getCollectionSecurityPolicy(address collection) 
        external view override returns (CollectionSecurityPolicy memory) {
        return collectionSecurityPolicies[collection];
    }

    /**
     * @notice Get the whitelisted operators in an operator whitelist.
     * @param id The id of the operator whitelist.
     * @return   An array of whitelisted operator addresses.
     */
    function getWhitelistedOperators(uint120 id) external view override returns (address[] memory) {
        return operatorWhitelists[id].values();
    }

    /**
     * @notice Get the permitted contract receivers in a permitted contract receiver allowlist.
     * @param id The id of the permitted contract receiver allowlist.
     * @return   An array of contract addresses is the permitted contract receiver allowlist.
     */
    function getPermittedContractReceivers(uint120 id) external view override returns (address[] memory) {
        return permittedContractReceiverAllowlists[id].values();
    }

    /**
     * @notice Check if an operator is in a specified operator whitelist.
     * @param id       The id of the operator whitelist.
     * @param operator The address of the operator to check.
     * @return         True if the operator is in the specified operator whitelist, false otherwise.
     */
    function isOperatorWhitelisted(uint120 id, address operator) public view override returns (bool) {
        return operatorWhitelists[id].contains(operator);
    }

    /**
     * @notice Check if a contract address is in a specified permitted contract receiver allowlist.
     * @param id       The id of the permitted contract receiver allowlist.
     * @param receiver The address of the contract to check.
     * @return         True if the contract address is in the specified permitted contract receiver allowlist, 
     *                 false otherwise.
     */
    function isContractReceiverPermitted(uint120 id, address receiver) public view override returns (bool) {
        return permittedContractReceiverAllowlists[id].contains(receiver);
    }

    /// @notice ERC-165 Interface Support
    function supportsInterface(bytes4 interfaceId) public view virtual override(EOARegistry, IERC165) returns (bool) {
        return
            interfaceId == type(ITransferValidator).interfaceId ||
            interfaceId == type(ITransferSecurityRegistry).interfaceId ||
            interfaceId == type(ICreatorTokenTransferValidator).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _requireCallerIsNFTOrContractOwnerOrAdmin(address tokenAddress) internal view {
        bool callerHasPermissions = false;
        if(tokenAddress.code.length > 0) {
            callerHasPermissions = _msgSender() == tokenAddress;
            if(!callerHasPermissions) {

                try IOwnable(tokenAddress).owner() returns (address contractOwner) {
                    callerHasPermissions = _msgSender() == contractOwner;
                } catch {}

                if(!callerHasPermissions) {
                    try IAccessControl(tokenAddress).hasRole(DEFAULT_ACCESS_CONTROL_ADMIN_ROLE, _msgSender()) 
                        returns (bool callerIsContractAdmin) {
                        callerHasPermissions = callerIsContractAdmin;
                    } catch {}
                }
            }
        }

        if(!callerHasPermissions) {
            revert CreatorTokenTransferValidator__CallerMustHaveElevatedPermissionsForSpecifiedNFT();
        }
    }

    function _reassignOwnershipOfOperatorWhitelist(uint120 id, address newOwner) private {
        _requireCallerOwnsOperatorWhitelist(id);
        operatorWhitelistOwners[id] = newOwner;
        emit ReassignedAllowlistOwnership(AllowlistTypes.Operators, id, newOwner);
    }

    function _reassignOwnershipOfPermittedContractReceiverAllowlist(uint120 id, address newOwner) private {
        _requireCallerOwnsPermittedContractReceiverAllowlist(id);
        permittedContractReceiverAllowlistOwners[id] = newOwner;
        emit ReassignedAllowlistOwnership(AllowlistTypes.PermittedContractReceivers, id, newOwner);
    }

    function _requireCallerOwnsOperatorWhitelist(uint120 id) private view {
        if (_msgSender() != operatorWhitelistOwners[id]) {
            revert CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist();
        }
    }

    function _requireCallerOwnsPermittedContractReceiverAllowlist(uint120 id) private view {
        if (_msgSender() != permittedContractReceiverAllowlistOwners[id]) {
            revert CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../interfaces/IEOARegistry.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


error CallerDidNotSignTheMessage();
error SignatureAlreadyVerified();

/**
 * @title EOARegistry
 * @author Limit Break, Inc.
 * @notice A registry that may be used globally by any smart contract that limits contract interactions to verified EOA addresses only.
 * @dev Take care and carefully consider whether or not to use this. Restricting operations to EOA only accounts can break Defi composability, 
 * so if Defi composability is an objective, this is not a good option.  Be advised that in the future, EOA accounts might not be a thing
 * but this is yet to be determined.  See https://eips.ethereum.org/EIPS/eip-4337 for more information.
 */
contract EOARegistry is Context, ERC165, IEOARegistry {

    /// @dev A pre-cached signed message hash used for gas-efficient signature recovery
    bytes32 immutable private signedMessageHash;

    /// @dev The plain text message to sign for signature verification
    string constant public MESSAGE_TO_SIGN = "EOA";

    /// @dev Mapping of accounts that to signature verification status
    mapping (address => bool) private eoaSignatureVerified;

    /// @dev Emitted whenever a user verifies that they are an EOA by submitting their signature.
    event VerifiedEOASignature(address indexed account);

    constructor() {
        signedMessageHash = ECDSA.toEthSignedMessageHash(bytes(MESSAGE_TO_SIGN));
    }

    /// @notice Allows a user to verify an ECDSA signature to definitively prove they are an EOA account.
    ///
    /// Throws when the caller has already verified their signature.
    /// Throws when the caller did not sign the message.
    ///
    /// Postconditions:
    /// ---------------
    /// The verified signature mapping has been updated to `true` for the caller.
    function verifySignature(bytes calldata signature) external {
        if(eoaSignatureVerified[_msgSender()]) {
            revert SignatureAlreadyVerified();
        }

        if(_msgSender() != ECDSA.recover(signedMessageHash, signature)) {
            revert CallerDidNotSignTheMessage();
        }

        eoaSignatureVerified[_msgSender()] = true;

        emit VerifiedEOASignature(_msgSender());
    }

    /// @notice Allows a user to verify an ECDSA signature to definitively prove they are an EOA account.
    /// This version is passed the v, r, s components of the signature, and is slightly more gas efficient than
    /// calculating the v, r, s components on-chain.
    ///
    /// Throws when the caller has already verified their signature.
    /// Throws when the caller did not sign the message.
    ///
    /// Postconditions:
    /// ---------------
    /// The verified signature mapping has been updated to `true` for the caller.
    function verifySignatureVRS(uint8 v, bytes32 r, bytes32 s) external {
        if(eoaSignatureVerified[msg.sender]) {
            revert SignatureAlreadyVerified();
        }

        if(msg.sender != ECDSA.recover(signedMessageHash, v, r, s)) {
            revert CallerDidNotSignTheMessage();
        }

        eoaSignatureVerified[msg.sender] = true;

        emit VerifiedEOASignature(msg.sender);
    }

    /// @notice Returns true if the specified account has verified a signature on this registry, false otherwise.
    function isVerifiedEOA(address account) public view override returns (bool) {
        return eoaSignatureVerified[account];
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IEOARegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum AllowlistTypes {
    Operators,
    PermittedContractReceivers
}

enum ReceiverConstraints {
    None,
    NoCode,
    EOA
}

enum CallerConstraints {
    None,
    OperatorWhitelistEnableOTC,
    OperatorWhitelistDisableOTC
}

enum StakerConstraints {
    None,
    CallerIsTxOrigin,
    EOA
}

enum TransferSecurityLevels {
    Zero,
    One,
    Two,
    Three,
    Four,
    Five,
    Six
}

struct TransferSecurityPolicy {
    CallerConstraints callerConstraints;
    ReceiverConstraints receiverConstraints;
}

struct CollectionSecurityPolicy {
    TransferSecurityLevels transferSecurityLevel;
    uint120 operatorWhitelistId;
    uint120 permittedContractReceiversId;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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