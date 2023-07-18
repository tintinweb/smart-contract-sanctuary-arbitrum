// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IOwnable Interface
 * @notice IOwnable is an interface that abstracts the implementation of a
 * contract with ownership control features. It's commonly used in upgradable
 * contracts and includes the functionality to get current owner, transfer
 * ownership, and propose and accept ownership.
 */
interface IOwnable {
    error NotOwner();
    error InvalidOwner();

    event OwnershipTransferStarted(address indexed newOwner);
    event OwnershipTransferred(address indexed newOwner);

    /**
     * @notice Returns the current owner of the contract.
     * @return address The address of the current owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the address of the pending owner of the contract.
     * @return address The address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice Transfers ownership of the contract to a new address
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Proposes to transfer the contract's ownership to a new address.
     * The new owner needs to accept the ownership explicitly.
     * @param newOwner The address to transfer ownership to
     */
    function proposeOwnership(address newOwner) external;

    /**
     * @notice Transfers ownership to the pending owner.
     * @dev Can only be called by the pending owner
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from './IOwnable.sol';

// General interface for upgradable contracts
interface IUpgradable is IOwnable {
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;

    function contractId() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IUpgradable } from '../interfaces/IUpgradable.sol';
import { Ownable } from '../utils/Ownable.sol';

/**
 * @title Upgradable Contract
 * @notice This contract provides an interface for upgradable smart contracts and includes the functionality to perform upgrades.
 */
abstract contract Upgradable is Ownable, IUpgradable {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address internal immutable implementationAddress;

    /**
     * @notice Constructor sets the implementation address to the address of the contract itself
     * @dev This is used in the onlyProxy modifier to prevent certain functions from being called directly
     * on the implementation contract itself
     */
    constructor() {
        implementationAddress = address(this);
    }

    /**
     * @notice Modifier to ensure that a function can only be called by the proxy
     */
    modifier onlyProxy() {
        // Prevent setup from being called on the implementation
        if (address(this) == implementationAddress) revert NotProxy();
        _;
    }

    /**
     * @notice Returns the address of the current implementation
     * @return implementation_ Address of the current implementation
     */
    function implementation() public view returns (address implementation_) {
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @notice Upgrades the contract to a new implementation
     * @param newImplementation The address of the new implementation contract
     * @param newImplementationCodeHash The codehash of the new implementation contract
     * @param params Optional setup parameters for the new implementation contract
     * @dev This function is only callable by the owner.
     */
    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external override onlyOwner {
        if (IUpgradable(newImplementation).contractId() != IUpgradable(this).contractId())
            revert InvalidImplementation();

        if (newImplementationCodeHash != newImplementation.codehash) revert InvalidCodeHash();

        if (params.length > 0) {
            (bool success, ) = newImplementation.delegatecall(abi.encodeWithSelector(this.setup.selector, params));

            if (!success) revert SetupFailed();
        }

        emit Upgraded(newImplementation);

        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    /**
     * @notice Sets up the contract with initial data
     * @param data Initialization data for the contract
     * @dev This function is only callable by the proxy contract.
     */
    function setup(bytes calldata data) external override onlyProxy {
        _setup(data);
    }

    /**
     * @notice Internal function to set up the contract with initial data
     * @param data Initialization data for the contract
     * @dev This function should be implemented in derived contracts.
     */
    function _setup(bytes calldata data) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StringToAddress {
    error InvalidAddressString();

    function toAddress(string memory addressString) internal pure returns (address) {
        bytes memory stringBytes = bytes(addressString);
        uint160 addressNumber = 0;
        uint8 stringByte;

        if (stringBytes.length != 42 || stringBytes[0] != '0' || stringBytes[1] != 'x') revert InvalidAddressString();

        for (uint256 i = 2; i < 42; ++i) {
            stringByte = uint8(stringBytes[i]);

            if ((stringByte >= 97) && (stringByte <= 102)) stringByte -= 87;
            else if ((stringByte >= 65) && (stringByte <= 70)) stringByte -= 55;
            else if ((stringByte >= 48) && (stringByte <= 57)) stringByte -= 48;
            else revert InvalidAddressString();

            addressNumber |= uint160(uint256(stringByte) << ((41 - i) << 2));
        }
        return address(addressNumber);
    }
}

library AddressToString {
    function toString(address addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        uint256 length = addressBytes.length;
        bytes memory characters = '0123456789abcdef';
        bytes memory stringBytes = new bytes(2 + addressBytes.length * 2);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint256 i; i < length; ++i) {
            stringBytes[2 + i * 2] = characters[uint8(addressBytes[i] >> 4)];
            stringBytes[3 + i * 2] = characters[uint8(addressBytes[i] & 0x0f)];
        }
        return string(stringBytes);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from '../interfaces/IOwnable.sol';

/**
 * @title Ownable
 * @notice A contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The owner account is set through ownership transfer. This module makes
 * it possible to transfer the ownership of the contract to a new account in one
 * step, as well as to an interim pending owner. In the second flow the ownership does not
 * change until the pending owner accepts the ownership transfer.
 */
abstract contract Ownable is IOwnable {
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;
    // keccak256('ownership-transfer')
    bytes32 internal constant _OWNERSHIP_TRANSFER_SLOT =
        0x9855384122b55936fbfb8ca5120e63c6537a1ac40caf6ae33502b3c5da8c87d1;

    /**
     * @notice Modifier that throws an error if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner() != msg.sender) revert NotOwner();

        _;
    }

    /**
     * @notice Returns the current owner of the contract.
     * @return owner_ The current owner of the contract
     */
    function owner() public view returns (address owner_) {
        assembly {
            owner_ := sload(_OWNER_SLOT)
        }
    }

    /**
     * @notice Returns the pending owner of the contract.
     * @return owner_ The pending owner of the contract
     */
    function pendingOwner() public view returns (address owner_) {
        assembly {
            owner_ := sload(_OWNERSHIP_TRANSFER_SLOT)
        }
    }

    /**
     * @notice Transfers ownership of the contract to a new account `newOwner`.
     * @dev Can only be called by the current owner.
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        emit OwnershipTransferred(newOwner);

        assembly {
            sstore(_OWNER_SLOT, newOwner)
            sstore(_OWNERSHIP_TRANSFER_SLOT, 0)
        }
    }

    /**
     * @notice Propose to transfer ownership of the contract to a new account `newOwner`.
     * @dev Can only be called by the current owner. The ownership does not change
     * until the new owner accepts the ownership transfer.
     * @param newOwner The address to transfer ownership to
     */
    function proposeOwnership(address newOwner) external virtual onlyOwner {
        emit OwnershipTransferStarted(newOwner);

        assembly {
            sstore(_OWNERSHIP_TRANSFER_SLOT, newOwner)
        }
    }

    /**
     * @notice Accepts ownership of the contract.
     * @dev Can only be called by the pending owner
     */
    function acceptOwnership() external virtual {
        address newOwner = pendingOwner();
        if (newOwner != msg.sender) revert InvalidOwner();

        emit OwnershipTransferred(newOwner);

        assembly {
            sstore(_OWNERSHIP_TRANSFER_SLOT, 0)
            sstore(_OWNER_SLOT, newOwner)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IRemoteAddressValidator
 * @dev Manages and validates remote addresses, keeps track of addresses supported by the Axelar gateway contract
 */
interface IRemoteAddressValidator {
    error ZeroAddress();
    error LengthMismatch();
    error ZeroStringLength();

    event TrustedAddressAdded(string souceChain, string sourceAddress);
    event TrustedAddressRemoved(string souceChain);
    event GatewaySupportedChainAdded(string chain);
    event GatewaySupportedChainRemoved(string chain);

    /**
     * @dev Validates that the sender is a valid interchain token service address
     * @param sourceChain Source chain of the transaction
     * @param sourceAddress Source address of the transaction
     * @return bool true if the sender is validated, false otherwise
     */
    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool);

    /**
     * @dev Adds a trusted interchain token service address for the specified chain
     * @param sourceChain Chain name of the interchain token service
     * @param sourceAddress Interchain token service address to be added
     */
    function addTrustedAddress(string memory sourceChain, string memory sourceAddress) external;

    /**
     * @dev Removes a trusted interchain token service address
     * @param sourceChain Chain name of the interchain token service to be removed
     */
    function removeTrustedAddress(string calldata sourceChain) external;

    /**
     * @dev Fetches the interchain token service address for the specified chain
     * @param chainName Name of the chain
     * @return remoteAddress Interchain token service address for the specified chain
     */
    function getRemoteAddress(string calldata chainName) external view returns (string memory remoteAddress);

    /**
     * @notice Returns true if the gateway delivers token to this chain.
     * @param chainName Name of the chain
     */
    function supportedByGateway(string calldata chainName) external view returns (bool);

    /**
     * @dev Adds chains that are supported by the Axelar gateway
     * @param chainNames List of chain names to be added as supported
     */
    function addGatewaySupportedChains(string[] calldata chainNames) external;

    /**
     * @dev Removes chains that are no longer supported by the Axelar gateway
     * @param chainNames List of chain names to be removed as supported
     */
    function removeGatewaySupportedChains(string[] calldata chainNames) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import { IRemoteAddressValidator } from '../interfaces/IRemoteAddressValidator.sol';
import { AddressToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';

/**
 * @title RemoteAddressValidator
 * @dev Manages and validates remote addresses, keeps track of addresses supported by the Axelar gateway contract
 */
contract RemoteAddressValidator is IRemoteAddressValidator, Upgradable {
    using AddressToString for address;

    mapping(string => bytes32) public remoteAddressHashes;
    mapping(string => string) public remoteAddresses;
    address public immutable interchainTokenServiceAddress;
    bytes32 public immutable interchainTokenServiceAddressHash;
    mapping(string => bool) public supportedByGateway;

    bytes32 private constant CONTRACT_ID = keccak256('remote-address-validator');

    /**
     * @dev Constructs the RemoteAddressValidator contract, both array parameters must be equal in length
     * @param _interchainTokenServiceAddress Address of the interchain token service
     */
    constructor(address _interchainTokenServiceAddress) {
        if (_interchainTokenServiceAddress == address(0)) revert ZeroAddress();
        interchainTokenServiceAddress = _interchainTokenServiceAddress;
        interchainTokenServiceAddressHash = keccak256(bytes(_lowerCase(interchainTokenServiceAddress.toString())));
    }

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    function _setup(bytes calldata params) internal override {
        (string[] memory trustedChainNames, string[] memory trustedAddresses) = abi.decode(params, (string[], string[]));
        uint256 length = trustedChainNames.length;
        if (length != trustedAddresses.length) revert LengthMismatch();
        for (uint256 i; i < length; ++i) {
            addTrustedAddress(trustedChainNames[i], trustedAddresses[i]);
        }
    }

    /**
     * @dev Converts a string to lower case
     * @param s Input string to be converted
     * @return string lowercase version of the input string
     */
    function _lowerCase(string memory s) internal pure returns (string memory) {
        uint256 length = bytes(s).length;
        for (uint256 i; i < length; i++) {
            uint8 b = uint8(bytes(s)[i]);
            if ((b >= 65) && (b <= 70)) bytes(s)[i] = bytes1(b + uint8(32));
        }
        return s;
    }

    /**
     * @dev Validates that the sender is a valid interchain token service address
     * @param sourceChain Source chain of the transaction
     * @param sourceAddress Source address of the transaction
     * @return bool true if the sender is validated, false otherwise
     */
    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool) {
        string memory sourceAddressLC = _lowerCase(sourceAddress);
        bytes32 sourceAddressHash = keccak256(bytes(sourceAddressLC));
        if (sourceAddressHash == interchainTokenServiceAddressHash) {
            return true;
        }
        return sourceAddressHash == remoteAddressHashes[sourceChain];
    }

    /**
     * @dev Adds a trusted interchain token service address for the specified chain
     * @param chain Chain name of the interchain token service
     * @param addr Interchain token service address to be added
     */
    function addTrustedAddress(string memory chain, string memory addr) public onlyOwner {
        if (bytes(chain).length == 0) revert ZeroStringLength();
        if (bytes(addr).length == 0) revert ZeroStringLength();
        remoteAddressHashes[chain] = keccak256(bytes(_lowerCase(addr)));
        remoteAddresses[chain] = addr;
        emit TrustedAddressAdded(chain, addr);
    }

    /**
     * @dev Removes a trusted interchain token service address
     * @param chain Chain name of the interchain token service to be removed
     */
    function removeTrustedAddress(string calldata chain) external onlyOwner {
        if (bytes(chain).length == 0) revert ZeroStringLength();
        remoteAddressHashes[chain] = bytes32(0);
        remoteAddresses[chain] = '';
        emit TrustedAddressRemoved(chain);
    }

    /**
     * @dev Adds chains that are supported by the Axelar gateway
     * @param chainNames List of chain names to be added as supported
     */
    function addGatewaySupportedChains(string[] calldata chainNames) external onlyOwner {
        uint256 length = chainNames.length;
        for (uint256 i; i < length; ++i) {
            string calldata chainName = chainNames[i];
            supportedByGateway[chainName] = true;
            emit GatewaySupportedChainAdded(chainName);
        }
    }

    /**
     * @dev Removes chains that are no longer supported by the Axelar gateway
     * @param chainNames List of chain names to be removed as supported
     */
    function removeGatewaySupportedChains(string[] calldata chainNames) external onlyOwner {
        uint256 length = chainNames.length;
        for (uint256 i; i < length; ++i) {
            string calldata chainName = chainNames[i];
            supportedByGateway[chainName] = false;
            emit GatewaySupportedChainRemoved(chainName);
        }
    }

    /**
     * @dev Fetches the interchain token service address for the specified chain
     * @param chainName Name of the chain
     * @return remoteAddress Interchain token service address for the specified chain
     */
    function getRemoteAddress(string calldata chainName) external view returns (string memory remoteAddress) {
        remoteAddress = remoteAddresses[chainName];
        if (bytes(remoteAddress).length == 0) {
            remoteAddress = interchainTokenServiceAddress.toString();
        }
    }
}