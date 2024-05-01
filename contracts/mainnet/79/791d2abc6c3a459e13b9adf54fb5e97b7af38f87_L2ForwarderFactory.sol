// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {L2ForwarderPredictor} from "./L2ForwarderPredictor.sol";
import {IL2ForwarderFactory} from "./interfaces/IL2ForwarderFactory.sol";
import {IL2Forwarder} from "./interfaces/IL2Forwarder.sol";

contract L2ForwarderFactory is L2ForwarderPredictor, IL2ForwarderFactory {
    /// @inheritdoc IL2ForwarderFactory
    address public immutable aliasedL1Teleporter;

    constructor(address _impl, address _aliasedL1Teleporter) L2ForwarderPredictor(address(this), _impl) {
        aliasedL1Teleporter = _aliasedL1Teleporter;
    }

    /// @inheritdoc IL2ForwarderFactory
    function callForwarder(IL2Forwarder.L2ForwarderParams memory params) external payable {
        if (msg.sender != aliasedL1Teleporter) revert OnlyL1Teleporter();

        IL2Forwarder l2Forwarder = _tryCreateL2Forwarder(params.owner, params.routerOrInbox, params.to);

        l2Forwarder.bridgeToL3{value: msg.value}(params);

        emit CalledL2Forwarder(address(l2Forwarder), params);
    }

    /// @inheritdoc IL2ForwarderFactory
    function createL2Forwarder(address owner, address routerOrInbox, address to) public returns (IL2Forwarder) {
        IL2Forwarder l2Forwarder =
            IL2Forwarder(payable(Clones.cloneDeterministic(l2ForwarderImplementation, _salt(owner, routerOrInbox, to))));

        l2Forwarder.initialize(owner);

        emit CreatedL2Forwarder(address(l2Forwarder), owner, routerOrInbox, to);

        return l2Forwarder;
    }

    /// @dev Create an L2Forwarder if it doesn't exist, otherwise return the existing one.
    function _tryCreateL2Forwarder(address owner, address routerOrInbox, address to) internal returns (IL2Forwarder) {
        address calculatedAddress = l2ForwarderAddress(owner, routerOrInbox, to);

        if (calculatedAddress.code.length > 0) {
            // contract already exists
            return IL2Forwarder(payable(calculatedAddress));
        }

        // contract doesn't exist, create it
        return createL2Forwarder(owner, routerOrInbox, to);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IL2ForwarderPredictor} from "./interfaces/IL2ForwarderPredictor.sol";

abstract contract L2ForwarderPredictor is IL2ForwarderPredictor {
    /// @inheritdoc IL2ForwarderPredictor
    address public immutable l2ForwarderFactory;
    /// @inheritdoc IL2ForwarderPredictor
    address public immutable l2ForwarderImplementation;

    constructor(address _factory, address _implementation) {
        l2ForwarderFactory = _factory;
        l2ForwarderImplementation = _implementation;
    }

    /// @inheritdoc IL2ForwarderPredictor
    function l2ForwarderAddress(address owner, address routerOrInbox, address to) public view returns (address) {
        return Clones.predictDeterministicAddress(
            l2ForwarderImplementation, _salt(owner, routerOrInbox, to), l2ForwarderFactory
        );
    }

    /// @notice Creates the salt for an L2Forwarder from its owner, routerOrInbox, and to address
    function _salt(address owner, address routerOrInbox, address to) internal pure returns (bytes32) {
        return keccak256(abi.encode(owner, routerOrInbox, to));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {IL2ForwarderPredictor} from "./IL2ForwarderPredictor.sol";
import {IL2Forwarder} from "./IL2Forwarder.sol";

/// @title  IL2ForwarderFactory
/// @notice Creates L2Forwarders and calls them to bridge tokens to L3.
///         L2Forwarders are created via CREATE2 / clones.
interface IL2ForwarderFactory is IL2ForwarderPredictor {
    /// @notice Emitted when a new L2Forwarder is created
    event CreatedL2Forwarder(address indexed l2Forwarder, address indexed owner, address routerOrInbox, address to);

    /// @notice Emitted when an L2Forwarder is called to bridge tokens to L3
    event CalledL2Forwarder(address indexed l2Forwarder, IL2Forwarder.L2ForwarderParams params);

    /// @notice Thrown when any address other than the aliased L1Teleporter calls callForwarder
    error OnlyL1Teleporter();

    /// @notice Calls an L2Forwarder to bridge tokens to L3. Will create the L2Forwarder first if it doesn't exist.
    /// @dev    Only callable by the aliased L1Teleporter.
    /// @param  params Parameters for the L2Forwarder
    function callForwarder(IL2Forwarder.L2ForwarderParams memory params) external payable;

    /// @notice Creates an L2Forwarder for the given parameters.
    /// @param  owner           Owner of the L2Forwarder
    /// @param  routerOrInbox   Address of the L1GatewayRouter or Inbox
    /// @param  to              Address to bridge tokens to
    /// @dev    This method is external to allow fund rescue when `callForwarder` reverts.
    function createL2Forwarder(address owner, address routerOrInbox, address to) external returns (IL2Forwarder);

    /// @notice Aliased address of the L1Teleporter contract
    function aliasedL1Teleporter() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {IL2ForwarderPredictor} from "./IL2ForwarderPredictor.sol";

/// @title  IL2Forwarder
/// @notice L2 contract that receives ERC20 tokens to forward to L3.
///         May receive either token and ETH, token and the L3 feeToken, or just feeToken if token == feeToken.
///         In case funds cannot be bridged to L3, the owner can call rescue to get their funds back.
interface IL2Forwarder {
    /// @notice Parameters for an L2Forwarder
    /// @param  owner               Address of the L2Forwarder owner. Setting this incorrectly could result in loss of funds.
    /// @param  l2Token             Address of the L2 token to bridge to L3
    /// @param  l3FeeTokenL2Addr    Address of the L3's fee token, or 0x00 for ETH
    /// @param  routerOrInbox       Address of the L2 -> L3 GatewayRouter or Inbox if depositing only custom fee token
    /// @param  to                  Address of the recipient on L3
    /// @param  gasLimit            Gas limit for the L2 -> L3 retryable
    /// @param  gasPriceBid         Gas price for the L2 -> L3 retryable
    /// @param  maxSubmissionCost   Max submission fee for the L2 -> L3 retryable. Is ignored for Standard and OnlyCustomFee teleportation types.
    struct L2ForwarderParams {
        address owner;
        address l2Token;
        address l3FeeTokenL2Addr;
        address routerOrInbox;
        address to;
        uint256 gasLimit;
        uint256 gasPriceBid;
        uint256 maxSubmissionCost;
    }

    /// @notice Emitted after a successful call to rescue
    /// @param  targets Addresses that were called
    /// @param  values  Values that were sent
    /// @param  datas   Calldata that was sent
    event Rescued(address[] targets, uint256[] values, bytes[] datas);

    /// @notice Emitted after a successful call to bridgeToL3
    event BridgedToL3(uint256 tokenAmount, uint256 feeAmount);

    /// @notice Thrown when initialize is called more than once
    error AlreadyInitialized();
    /// @notice Thrown when a non-owner calls rescue
    error OnlyOwner();
    /// @notice Thrown when the length of targets, values, and datas are not equal in a call to rescue
    error LengthMismatch();
    /// @notice Thrown when an external call in rescue fails
    error CallFailed(address to, uint256 value, bytes data, bytes returnData);
    /// @notice Thrown when bridgeToL3 is called by an address other than the L2ForwarderFactory
    error OnlyL2ForwarderFactory();
    /// @notice Thrown when the L2Forwarder has no balance of the token to bridge
    error ZeroTokenBalance(address token);

    /// @notice Initialize the L2Forwarder with the owner
    function initialize(address _owner) external;

    /// @notice Send tokens + (fee tokens or ETH) through the bridge to a recipient on L3.
    /// @param  params Parameters of the bridge transaction.
    /// @dev    Can only be called by the L2ForwarderFactory.
    function bridgeToL3(L2ForwarderParams calldata params) external payable;

    /// @notice Allows the owner of this L2Forwarder to make arbitrary calls.
    ///         If bridgeToL3 cannot succeed, the owner can call this to rescue their tokens and ETH.
    /// @param  targets Addresses to call
    /// @param  values  Values to send
    /// @param  datas   Calldata to send
    function rescue(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas) external payable;

    /// @notice The owner of this L2Forwarder. Authorized to call rescue.
    function owner() external view returns (address);

    /// @notice The address of the L2ForwarderFactory
    function l2ForwarderFactory() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {IL2Forwarder} from "./IL2Forwarder.sol";

/// @title  IL2ForwarderPredictor
/// @notice Predicts the address of an L2Forwarder based on its parameters
interface IL2ForwarderPredictor {
    /// @notice Address of the L2ForwarderFactory
    function l2ForwarderFactory() external view returns (address);
    /// @notice Address of the L2Forwarder implementation
    function l2ForwarderImplementation() external view returns (address);
    /// @notice Predicts the address of an L2Forwarder based on its owner, routerOrInbox, and to
    function l2ForwarderAddress(address owner, address routerOrInbox, address to) external view returns (address);
}