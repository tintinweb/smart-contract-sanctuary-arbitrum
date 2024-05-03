// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibZip } from "solady/src/utils/LibZip.sol";
import { LibClone } from "solady/src/utils/LibClone.sol";
import { SafeTransferLib } from "solady/src/utils/SafeTransferLib.sol";

import { Ownable } from "solady/src/auth/Ownable.sol";

interface OmniXMultisender {
    function initialize() external;
    function setPeers(uint32[] calldata remoteEids, bytes32[] calldata remoteAddresses)
        external;
    function setGasLimit(uint32[] calldata remoteEids, uint128[] calldata gasLimits)
        external;
    function setDelegate(address delegate) external;
    function setUlnConfigs(
        address lib,
        uint64 confirmations,
        uint32[] calldata eids,
        address dvn
    ) external;
}

contract OmniXMultisenderFactory is Ownable {
    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    address internal immutable implementation;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner, address _implementation) {
        _initializeOwner(_owner);
        implementation = _implementation;
    }

    /// -----------------------------------------------------------------------
    /// Owner Actions
    /// -----------------------------------------------------------------------

    function deploy(address endpoint, address omniNft, uint24 defaultGasLimit)
        external
        virtual
        onlyOwner
        returns (address instance)
    {
        instance = LibClone.clone(
            implementation,
            abi.encodePacked(endpoint, address(this), omniNft, defaultGasLimit)
        );

        OmniXMultisender(instance).initialize();
    }

    function setPeers(
        address instance,
        uint32[] calldata remoteEids,
        bytes32[] calldata remoteAddresses
    ) external virtual onlyOwner {
        OmniXMultisender(instance).setPeers(remoteEids, remoteAddresses);
    }

    function setGasLimit(
        address instance,
        uint32[] calldata remoteEids,
        uint128[] calldata gasLimits
    ) external virtual onlyOwner {
        OmniXMultisender(instance).setGasLimit(remoteEids, gasLimits);
    }

    function setDelegate(address instance, address delegate) external virtual onlyOwner {
        OmniXMultisender(instance).setDelegate(delegate);
    }

    function setUlnConfigs(
        address instance,
        address lib,
        uint64 confirmations,
        uint32[] calldata eids,
        address dvn
    ) external virtual onlyOwner {
        OmniXMultisender(instance).setUlnConfigs(lib, confirmations, eids, dvn);
    }

    function withdraw(address token, address to) external virtual onlyOwner {
        if (token == address(0)) SafeTransferLib.safeTransferAllETH(to);
        else SafeTransferLib.safeTransferAll(token, to);
    }

    /// -----------------------------------------------------------------------
    /// Fallback
    /// -----------------------------------------------------------------------

    receive() external payable virtual { }

    fallback() external virtual {
        LibZip.cdFallback();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
///
/// @dev Note:
/// This implementation does NOT auto-initialize the owner to `msg.sender`.
/// You MUST call the `_initializeOwner` in the constructor / initializer.
///
/// While the ownable portion follows
/// [EIP-173](https://eips.ethereum.org/EIPS/eip-173) for compatibility,
/// the nomenclature for the 2-step ownership handover may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /// @dev Cannot double-initialize.
    error AlreadyInitialized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by:
    /// `bytes32(~uint256(uint32(bytes4(keccak256("_OWNER_SLOT_NOT")))))`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    bytes32 internal constant _OWNER_SLOT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff74873927;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Override to return true to make `_initializeOwner` prevent double-initialization.
    function _guardInitializeOwner() internal pure virtual returns (bool guard) {}

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        if (_guardInitializeOwner()) {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
                if sload(ownerSlot) {
                    mstore(0x00, 0x0dc149f0) // `AlreadyInitialized()`.
                    revert(0x1c, 0x04)
                }
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Store the new value.
                sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Store the new value.
                sstore(_OWNER_SLOT, newOwner)
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
            }
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        if (_guardInitializeOwner()) {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
                // Store the new value.
                sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
                // Store the new value.
                sstore(ownerSlot, newOwner)
            }
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(_OWNER_SLOT))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    /// Override to return a different value if needed.
    /// Made internal to conserve bytecode. Wrap it in a public function if needed.
    function _ownershipHandoverValidFor() internal view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + _ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, 0x6f5e8818) // `NoHandoverRequest()`.
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_OWNER_SLOT)
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal proxy library.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @author Minimal proxy by 0age (https://github.com/0age)
/// @author Clones with immutable args by wighawag, zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
/// @author Minimal ERC1967 proxy by jtriley-eth (https://github.com/jtriley-eth/minimum-viable-proxy)
///
/// @dev Minimal proxy:
/// Although the sw0nt pattern saves 5 gas over the erc-1167 pattern during runtime,
/// it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
/// which saves 4 gas over the erc-1167 pattern during runtime, and has the smallest bytecode.
///
/// @dev Minimal proxy (PUSH0 variant):
/// This is a new minimal proxy that uses the PUSH0 opcode introduced during Shanghai.
/// It is optimized first for minimal runtime gas, then for minimal bytecode.
/// The PUSH0 clone functions are intentionally postfixed with a jarring "_PUSH0" as
/// many EVM chains may not support the PUSH0 opcode in the early months after Shanghai.
/// Please use with caution.
///
/// @dev Clones with immutable args (CWIA):
/// The implementation of CWIA here implements a `receive()` method that emits the
/// `ReceiveETH(uint256)` event. This skips the `DELEGATECALL` when there is no calldata,
/// enabling us to accept hard gas-capped `sends` & `transfers` for maximum backwards
/// composability. The minimal proxy implementation does not offer this feature.
///
/// @dev Minimal ERC1967 proxy:
/// An minimal ERC1967 proxy, intended to be upgraded with UUPS.
/// This is NOT the same as ERC1967Factory's transparent proxy, which includes admin logic.
///
/// @dev ERC1967I proxy:
/// An variant of the minimal ERC1967 proxy, with a special code path that activates
/// if `calldatasize() == 1`. This code path skips the delegatecall and directly returns the
/// `implementation` address. The returned implementation is guaranteed to be valid if the
/// keccak256 of the proxy's code is equal to `ERC1967I_CODE_HASH`.
library LibClone {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The keccak256 of the deployed code for the ERC1967 proxy.
    bytes32 internal constant ERC1967_CODE_HASH =
        0xaaa52c8cc8a0e3fd27ce756cc6b4e70c51423e9b597b11f32d3e49f8b1fc890d;

    /// @dev The keccak256 of the deployed code for the ERC1967I proxy.
    bytes32 internal constant ERC1967I_CODE_HASH =
        0xce700223c0d4cea4583409accfc45adac4a093b3519998a9cbbe1504dadba6f7;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the clone.
    error DeploymentFailed();

    /// @dev The salt must start with either the zero address or `by`.
    error SaltDoesNotStartWith();

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  MINIMAL PROXY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a clone of `implementation`.
    function clone(address implementation) internal returns (address instance) {
        instance = clone(0, implementation);
    }

    /// @dev Deploys a clone of `implementation`.
    /// Deposits `value` ETH during deployment.
    function clone(uint256 value, address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 3d         | RETURNDATASIZE    | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (44 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | 0                      |                       |
             * 3d      | RETURNDATASIZE | 0 0                    |                       |
             * 3d      | RETURNDATASIZE | 0 0 0                  |                       |
             * 3d      | RETURNDATASIZE | 0 0 0 0                |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            |                       |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          |                       |
             * 3d      | RETURNDATASIZE | 0 0 cds 0 0 0 0        |                       |
             * 37      | CALLDATACOPY   | 0 0 0 0                | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0 0 0     | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0 0 0 | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success 0 0            | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success 0 0        | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | rds rds success 0 0    | [0..cds): calldata    |
             * 93      | SWAP4          | 0 rds success 0 rds    | [0..cds): calldata    |
             * 80      | DUP1           | 0 0 rds success 0 rds  | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success 0 rds          | [0..rds): returndata  |
             *                                                                           |
             * 60 0x2a | PUSH1 0x2a     | 0x2a success 0 rds     | [0..rds): returndata  |
             * 57      | JUMPI          | 0 rds                  | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             */
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create(value, 0x0c, 0x35)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Deploys a deterministic clone of `implementation` with `salt`.
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = cloneDeterministic(0, implementation, salt);
    }

    /// @dev Deploys a deterministic clone of `implementation` with `salt`.
    /// Deposits `value` ETH during deployment.
    function cloneDeterministic(uint256 value, address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create2(value, 0x0c, 0x35, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the clone of `implementation`.
    function initCode(address implementation) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(add(result, 0x40), 0x5af43d3d93803e602a57fd5bf30000000000000000000000)
            mstore(add(result, 0x28), implementation)
            mstore(add(result, 0x14), 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            mstore(result, 0x35) // Store the length.
            mstore(0x40, add(result, 0x60)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            hash := keccak256(0x0c, 0x35)
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the address of the deterministic clone of `implementation`,
    /// with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          MINIMAL PROXY OPERATIONS (PUSH0 VARIANT)          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a PUSH0 clone of `implementation`.
    function clone_PUSH0(address implementation) internal returns (address instance) {
        instance = clone_PUSH0(0, implementation);
    }

    /// @dev Deploys a PUSH0 clone of `implementation`.
    /// Deposits `value` ETH during deployment.
    function clone_PUSH0(uint256 value, address implementation)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 5f         | PUSH0             | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 5f         | PUSH0             | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (45 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 5f      | PUSH0          | 0                      |                       |
             * 5f      | PUSH0          | 0 0                    |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0                |                       |
             * 5f      | PUSH0          | 0 cds 0 0              |                       |
             * 5f      | PUSH0          | 0 0 cds 0 0            |                       |
             * 37      | CALLDATACOPY   | 0 0                    | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0                | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 cds 0 0              | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0         | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0     | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success                | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success            | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 rds success          | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 0 rds success        | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success                | [0..rds): returndata  |
             *                                                                           |
             * 60 0x29 | PUSH1 0x29     | 0x29 success           | [0..rds): returndata  |
             * 57      | JUMPI          |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds                    | [0..rds): returndata  |
             * 5f      | PUSH0          | 0 rds                  | [0..rds): returndata  |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       |                        | [0..rds): returndata  |
             * 3d      | RETURNDATASIZE | rds                    | [0..rds): returndata  |
             * 5f      | PUSH0          | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             */
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            instance := create(value, 0x0e, 0x36)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Deploys a deterministic PUSH0 clone of `implementation` with `salt`.
    function cloneDeterministic_PUSH0(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = cloneDeterministic_PUSH0(0, implementation, salt);
    }

    /// @dev Deploys a deterministic PUSH0 clone of `implementation` with `salt`.
    /// Deposits `value` ETH during deployment.
    function cloneDeterministic_PUSH0(uint256 value, address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            instance := create2(value, 0x0e, 0x36, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the PUSH0 clone of `implementation`.
    function initCode_PUSH0(address implementation) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(add(result, 0x40), 0x5af43d5f5f3e6029573d5ffd5b3d5ff300000000000000000000) // 16
            mstore(add(result, 0x26), implementation) // 20
            mstore(add(result, 0x12), 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            mstore(result, 0x36) // Store the length.
            mstore(0x40, add(result, 0x60)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the PUSH0 clone of `implementation`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash_PUSH0(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            hash := keccak256(0x0e, 0x36)
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the address of the deterministic PUSH0 clone of `implementation`,
    /// with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress_PUSH0(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash_PUSH0(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           CLONES WITH IMMUTABLE ARGS OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: This implementation of CWIA differs from the original implementation.
    // If the calldata is empty, it will emit a `ReceiveETH(uint256)` event and skip the `DELEGATECALL`.

    /// @dev Deploys a clone of `implementation` with immutable arguments encoded in `data`.
    function clone(address implementation, bytes memory data) internal returns (address instance) {
        instance = clone(0, implementation, data);
    }

    /// @dev Deploys a clone of `implementation` with immutable arguments encoded in `data`.
    /// Deposits `value` ETH during deployment.
    function clone(uint256 value, address implementation, bytes memory data)
        internal
        returns (address instance)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)
            // The `creationSize` is `extraLength + 108`
            // The `runSize` is `creationSize - 10`.

            /**
             * ---------------------------------------------------------------------------------------------------+
             * CREATION (10 bytes)                                                                                |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                                                |
             * ---------------------------------------------------------------------------------------------------|
             * 61 runSize | PUSH2 runSize     | r         |                                                       |
             * 3d         | RETURNDATASIZE    | 0 r       |                                                       |
             * 81         | DUP2              | r 0 r     |                                                       |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                                                       |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                                                       |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code                            |
             * f3         | RETURN            |           | [0..runSize): runtime code                            |
             * ---------------------------------------------------------------------------------------------------|
             * RUNTIME (98 bytes + extraLength)                                                                   |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode   | Mnemonic       | Stack                    | Memory                                      |
             * ---------------------------------------------------------------------------------------------------|
             *                                                                                                    |
             * ::: if no calldata, emit event & return w/o `DELEGATECALL` ::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 60 0x2c  | PUSH1 0x2c     | 0x2c cds                 |                                             |
             * 57       | JUMPI          |                          |                                             |
             * 34       | CALLVALUE      | cv                       |                                             |
             * 3d       | RETURNDATASIZE | 0 cv                     |                                             |
             * 52       | MSTORE         |                          | [0..0x20): callvalue                        |
             * 7f sig   | PUSH32 0x9e..  | sig                      | [0..0x20): callvalue                        |
             * 59       | MSIZE          | 0x20 sig                 | [0..0x20): callvalue                        |
             * 3d       | RETURNDATASIZE | 0 0x20 sig               | [0..0x20): callvalue                        |
             * a1       | LOG1           |                          | [0..0x20): callvalue                        |
             * 00       | STOP           |                          | [0..0x20): callvalue                        |
             * 5b       | JUMPDEST       |                          |                                             |
             *                                                                                                    |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 3d       | RETURNDATASIZE | 0 cds                    |                                             |
             * 3d       | RETURNDATASIZE | 0 0 cds                  |                                             |
             * 37       | CALLDATACOPY   |                          | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: keep some values in stack :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | 0                        | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0                      | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0                    | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0 0                  | [0..cds): calldata                          |
             * 61 extra | PUSH2 extra    | e 0 0 0 0                | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: copy extra data to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 80       | DUP1           | e e 0 0 0 0              | [0..cds): calldata                          |
             * 60 0x62  | PUSH1 0x62     | 0x62 e e 0 0 0 0         | [0..cds): calldata                          |
             * 36       | CALLDATASIZE   | cds 0x62 e e 0 0 0 0     | [0..cds): calldata                          |
             * 39       | CODECOPY       | e 0 0 0 0                | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: delegate call to the implementation contract ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 01       | ADD            | cds+e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | 0 cds+e 0 0 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 73 addr  | PUSH20 addr    | addr 0 cds+e 0 0 0 0     | [0..cds): calldata, [cds..cds+e): extraData |
             * 5a       | GAS            | gas addr 0 cds+e 0 0 0 0 | [0..cds): calldata, [cds..cds+e): extraData |
             * f4       | DELEGATECALL   | success 0 0              | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: copy return data to memory ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | rds success 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | rds rds success 0 0      | [0..cds): calldata, [cds..cds+e): extraData |
             * 93       | SWAP4          | 0 rds success 0 rds      | [0..cds): calldata, [cds..cds+e): extraData |
             * 80       | DUP1           | 0 0 rds success 0 rds    | [0..cds): calldata, [cds..cds+e): extraData |
             * 3e       | RETURNDATACOPY | success 0 rds            | [0..rds): returndata                        |
             *                                                                                                    |
             * 60 0x60  | PUSH1 0x60     | 0x60 success 0 rds       | [0..rds): returndata                        |
             * 57       | JUMPI          | 0 rds                    | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: revert ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd       | REVERT         |                          | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: return ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b       | JUMPDEST       | 0 rds                    | [0..rds): returndata                        |
             * f3       | RETURN         |                          | [0..rds): returndata                        |
             * ---------------------------------------------------------------------------------------------------+
             */
            mstore(data, 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(sub(data, 0x0d), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                // Do a out-of-gas revert if `extraLength` is too big. 0xffff - 0x62 + 0x01 = 0xff9e.
                // The actual EVM limit may be smaller and may change over time.
                sub(data, add(0x59, lt(extraLength, 0xff9e))),
                or(shl(0x78, add(extraLength, 0x62)), 0xfd6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            instance := create(value, sub(data, 0x4c), add(extraLength, 0x6c))
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Deploys a deterministic clone of `implementation`
    /// with immutable arguments encoded in `data` and `salt`.
    function cloneDeterministic(address implementation, bytes memory data, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = cloneDeterministic(0, implementation, data, salt);
    }

    /// @dev Deploys a deterministic clone of `implementation`
    /// with immutable arguments encoded in `data` and `salt`.
    function cloneDeterministic(
        uint256 value,
        address implementation,
        bytes memory data,
        bytes32 salt
    ) internal returns (address instance) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            mstore(data, 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(sub(data, 0x0d), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                // Do a out-of-gas revert if `extraLength` is too big. 0xffff - 0x62 + 0x01 = 0xff9e.
                // The actual EVM limit may be smaller and may change over time.
                sub(data, add(0x59, lt(extraLength, 0xff9e))),
                or(shl(0x78, add(extraLength, 0x62)), 0xfd6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            instance := create2(value, sub(data, 0x4c), add(extraLength, 0x6c), salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`
    /// using immutable arguments encoded in `data`.
    function initCode(address implementation, bytes memory data)
        internal
        pure
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let dataLength := mload(data)

            // Do a out-of-gas revert if `dataLength` is too big. 0xffff - 0x02 - 0x62 = 0xff9b.
            // The actual EVM limit may be smaller and may change over time.
            returndatacopy(returndatasize(), returndatasize(), gt(dataLength, 0xff9b))

            let o := add(result, 0x8c)
            let end := add(o, dataLength)

            // Copy the `data` into `result`.
            for { let d := sub(add(data, 0x20), o) } 1 {} {
                mstore(o, mload(add(o, d)))
                o := add(o, 0x20)
                if iszero(lt(o, end)) { break }
            }

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            mstore(add(result, 0x6c), 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(add(result, 0x5f), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                add(result, 0x4b),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                add(result, 0x32),
                0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                add(result, 0x12),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(end, shl(0xf0, extraLength))
            mstore(add(end, 0x02), 0) // Zeroize the slot after the result.
            mstore(result, add(extraLength, 0x6c)) // Store the length.
            mstore(0x40, add(0x22, end)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`
    /// using immutable arguments encoded in `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(address implementation, bytes memory data)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // Do a out-of-gas revert if `dataLength` is too big. 0xffff - 0x02 - 0x62 = 0xff9b.
            // The actual EVM limit may be smaller and may change over time.
            returndatacopy(returndatasize(), returndatasize(), gt(dataLength, 0xff9b))

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            mstore(data, 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(sub(data, 0x0d), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            hash := keccak256(sub(data, 0x4c), add(extraLength, 0x6c))

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(
        address implementation,
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash(implementation, data);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              MINIMAL ERC1967 PROXY OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: The ERC1967 proxy here is intended to be upgraded with UUPS.
    // This is NOT the same as ERC1967Factory's transparent proxy, which includes admin logic.

    /// @dev Deploys a minimal ERC1967 proxy with `implementation`.
    function deployERC1967(address implementation) internal returns (address instance) {
        instance = deployERC1967(0, implementation);
    }

    /// @dev Deploys a minimal ERC1967 proxy with `implementation`.
    /// Deposits `value` ETH during deployment.
    function deployERC1967(uint256 value, address implementation)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * ---------------------------------------------------------------------------------+
             * CREATION (34 bytes)                                                              |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize  | r                |                                 |
             * 3d         | RETURNDATASIZE | 0 r              |                                 |
             * 81         | DUP2           | r 0 r            |                                 |
             * 60 offset  | PUSH1 offset   | o r 0 r          |                                 |
             * 3d         | RETURNDATASIZE | 0 o r 0 r        |                                 |
             * 39         | CODECOPY       | 0 r              | [0..runSize): runtime code      |
             * 73 impl    | PUSH20 impl    | impl 0 r         | [0..runSize): runtime code      |
             * 60 slotPos | PUSH1 slotPos  | slotPos impl 0 r | [0..runSize): runtime code      |
             * 51         | MLOAD          | slot impl 0 r    | [0..runSize): runtime code      |
             * 55         | SSTORE         | 0 r              | [0..runSize): runtime code      |
             * f3         | RETURN         |                  | [0..runSize): runtime code      |
             * ---------------------------------------------------------------------------------|
             * RUNTIME (61 bytes)                                                               |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             *                                                                                  |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36         | CALLDATASIZE   | cds              |                                 |
             * 3d         | RETURNDATASIZE | 0 cds            |                                 |
             * 3d         | RETURNDATASIZE | 0 0 cds          |                                 |
             * 37         | CALLDATACOPY   |                  | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | 0                |                                 |
             * 3d         | RETURNDATASIZE | 0 0              |                                 |
             * 36         | CALLDATASIZE   | cds 0 0          | [0..calldatasize): calldata     |
             * 3d         | RETURNDATASIZE | 0 cds 0 0        | [0..calldatasize): calldata     |
             * 7f slot    | PUSH32 slot    | s 0 cds 0 0      | [0..calldatasize): calldata     |
             * 54         | SLOAD          | i 0 cds 0 0      | [0..calldatasize): calldata     |
             * 5a         | GAS            | g i 0 cds 0 0    | [0..calldatasize): calldata     |
             * f4         | DELEGATECALL   | succ             | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds succ         | [0..calldatasize): calldata     |
             * 60 0x00    | PUSH1 0x00     | 0 rds succ       | [0..calldatasize): calldata     |
             * 80         | DUP1           | 0 0 rds succ     | [0..calldatasize): calldata     |
             * 3e         | RETURNDATACOPY | succ             | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: branch on delegatecall status :::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x38    | PUSH1 0x38     | dest succ        | [0..returndatasize): returndata |
             * 57         | JUMPI          |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall failed, revert :::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * fd         | REVERT         |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall succeeded, return ::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b         | JUMPDEST       |                  | [0..returndatasize): returndata |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * f3         | RETURN         |                  | [0..returndatasize): returndata |
             * ---------------------------------------------------------------------------------+
             */
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            instance := create(value, 0x21, 0x5f)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Deploys a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    function deployDeterministicERC1967(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = deployDeterministicERC1967(0, implementation, salt);
    }

    /// @dev Deploys a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967(uint256 value, address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            instance := create2(value, 0x21, 0x5f, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Creates a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967(address implementation, bytes32 salt)
        internal
        returns (bool alreadyDeployed, address instance)
    {
        return createDeterministicERC1967(0, implementation, salt);
    }

    /// @dev Creates a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967(uint256 value, address implementation, bytes32 salt)
        internal
        returns (bool alreadyDeployed, address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            // Compute and store the bytecode hash.
            mstore(add(m, 0x35), keccak256(0x21, 0x5f))
            mstore(m, shl(88, address()))
            mstore8(m, 0xff) // Write the prefix.
            mstore(add(m, 0x15), salt)
            instance := keccak256(m, 0x55)
            for {} 1 {} {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, 0x21, 0x5f, salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) { break }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the initialization code of the minimal ERC1967 proxy of `implementation`.
    function initCodeERC1967(address implementation) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(
                add(result, 0x60),
                0x3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f300
            )
            mstore(
                add(result, 0x40),
                0x55f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc
            )
            mstore(add(result, 0x20), or(shl(24, implementation), 0x600951))
            mstore(add(result, 0x09), 0x603d3d8160223d3973)
            mstore(result, 0x5f) // Store the length.
            mstore(0x40, add(result, 0x80)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the minimal ERC1967 proxy of `implementation`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHashERC1967(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            hash := keccak256(0x21, 0x5f)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the address of the deterministic ERC1967 proxy of `implementation`,
    /// with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 ERC1967I PROXY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: This proxy has a special code path that activates if `calldatasize() == 1`.
    // This code path skips the delegatecall and directly returns the `implementation` address.
    // The returned implementation is guaranteed to be valid if the keccak256 of the
    // proxy's code is equal to `ERC1967I_CODE_HASH`.

    /// @dev Deploys a minimal ERC1967I proxy with `implementation`.
    function deployERC1967I(address implementation) internal returns (address instance) {
        instance = deployERC1967I(0, implementation);
    }

    /// @dev Deploys a ERC1967I proxy with `implementation`.
    /// Deposits `value` ETH during deployment.
    function deployERC1967I(uint256 value, address implementation)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * ---------------------------------------------------------------------------------+
             * CREATION (34 bytes)                                                              |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize  | r                |                                 |
             * 3d         | RETURNDATASIZE | 0 r              |                                 |
             * 81         | DUP2           | r 0 r            |                                 |
             * 60 offset  | PUSH1 offset   | o r 0 r          |                                 |
             * 3d         | RETURNDATASIZE | 0 o r 0 r        |                                 |
             * 39         | CODECOPY       | 0 r              | [0..runSize): runtime code      |
             * 73 impl    | PUSH20 impl    | impl 0 r         | [0..runSize): runtime code      |
             * 60 slotPos | PUSH1 slotPos  | slotPos impl 0 r | [0..runSize): runtime code      |
             * 51         | MLOAD          | slot impl 0 r    | [0..runSize): runtime code      |
             * 55         | SSTORE         | 0 r              | [0..runSize): runtime code      |
             * f3         | RETURN         |                  | [0..runSize): runtime code      |
             * ---------------------------------------------------------------------------------|
             * RUNTIME (82 bytes)                                                               |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             *                                                                                  |
             * ::: check calldatasize ::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36         | CALLDATASIZE   | cds              |                                 |
             * 58         | PC             | 1 cds            |                                 |
             * 14         | EQ             | eqs              |                                 |
             * 60 0x43    | PUSH1 0x43     | dest eqs         |                                 |
             * 57         | JUMPI          |                  |                                 |
             *                                                                                  |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36         | CALLDATASIZE   | cds              |                                 |
             * 3d         | RETURNDATASIZE | 0 cds            |                                 |
             * 3d         | RETURNDATASIZE | 0 0 cds          |                                 |
             * 37         | CALLDATACOPY   |                  | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | 0                |                                 |
             * 3d         | RETURNDATASIZE | 0 0              |                                 |
             * 36         | CALLDATASIZE   | cds 0 0          | [0..calldatasize): calldata     |
             * 3d         | RETURNDATASIZE | 0 cds 0 0        | [0..calldatasize): calldata     |
             * 7f slot    | PUSH32 slot    | s 0 cds 0 0      | [0..calldatasize): calldata     |
             * 54         | SLOAD          | i 0 cds 0 0      | [0..calldatasize): calldata     |
             * 5a         | GAS            | g i 0 cds 0 0    | [0..calldatasize): calldata     |
             * f4         | DELEGATECALL   | succ             | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds succ         | [0..calldatasize): calldata     |
             * 60 0x00    | PUSH1 0x00     | 0 rds succ       | [0..calldatasize): calldata     |
             * 80         | DUP1           | 0 0 rds succ     | [0..calldatasize): calldata     |
             * 3e         | RETURNDATACOPY | succ             | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: branch on delegatecall status :::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x3E    | PUSH1 0x3E     | dest succ        | [0..returndatasize): returndata |
             * 57         | JUMPI          |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall failed, revert :::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * fd         | REVERT         |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall succeeded, return ::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b         | JUMPDEST       |                  | [0..returndatasize): returndata |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * f3         | RETURN         |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: implementation , return :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b         | JUMPDEST       |                  |                                 |
             * 60 0x20    | PUSH1 0x20     | 32               |                                 |
             * 60 0x0F    | PUSH1 0x0F     | o 32             |                                 |
             * 3d         | RETURNDATASIZE | 0 o 32           |                                 |
             * 39         | CODECOPY       |                  | [0..32): implementation slot    |
             * 3d         | RETURNDATASIZE | 0                | [0..32): implementation slot    |
             * 51         | MLOAD          | slot             | [0..32): implementation slot    |
             * 54         | SLOAD          | impl             | [0..32): implementation slot    |
             * 3d         | RETURNDATASIZE | 0 impl           | [0..32): implementation slot    |
             * 52         | MSTORE         |                  | [0..32): implementation address |
             * 59         | MSIZE          | 32               | [0..32): implementation address |
             * 3d         | RETURNDATASIZE | 0 32             | [0..32): implementation address |
             * f3         | RETURN         |                  | [0..32): implementation address |
             *                                                                                  |
             * ---------------------------------------------------------------------------------+
             */
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(0x40, 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(0x20, 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, implementation))))
            instance := create(value, 0x0c, 0x74)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Deploys a deterministic ERC1967I proxy with `implementation` and `salt`.
    function deployDeterministicERC1967I(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = deployDeterministicERC1967I(0, implementation, salt);
    }

    /// @dev Deploys a deterministic ERC1967I proxy with `implementation` and `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967I(uint256 value, address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(0x40, 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(0x20, 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, implementation))))
            instance := create2(value, 0x0c, 0x74, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Creates a deterministic ERC1967I proxy with `implementation` and `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967I(address implementation, bytes32 salt)
        internal
        returns (bool alreadyDeployed, address instance)
    {
        return createDeterministicERC1967I(0, implementation, salt);
    }

    /// @dev Creates a deterministic ERC1967I proxy with `implementation` and `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967I(uint256 value, address implementation, bytes32 salt)
        internal
        returns (bool alreadyDeployed, address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(0x40, 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(0x20, 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, implementation))))
            // Compute and store the bytecode hash.
            mstore(add(m, 0x35), keccak256(0x0c, 0x74))
            mstore(m, shl(88, address()))
            mstore8(m, 0xff) // Write the prefix.
            mstore(add(m, 0x15), salt)
            instance := keccak256(m, 0x55)
            for {} 1 {} {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, 0x0c, 0x74, salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) { break }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the initialization code of the minimal ERC1967 proxy of `implementation`.
    function initCodeERC1967I(address implementation) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(
                add(result, 0x74),
                0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3
            )
            mstore(
                add(result, 0x54),
                0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4
            )
            mstore(add(result, 0x34), 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(add(result, 0x1d), implementation)
            mstore(add(result, 0x09), 0x60523d8160223d3973)
            mstore(add(result, 0x94), 0)
            mstore(result, 0x74) // Store the length.
            mstore(0x40, add(result, 0xa0)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the minimal ERC1967 proxy of `implementation`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHashERC1967I(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(0x40, 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(0x20, 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, implementation))))
            hash := keccak256(0x0c, 0x74)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the address of the deterministic ERC1967I proxy of `implementation`,
    /// with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967I(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967I(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            CONSTANT ERC1967 BOOTSTRAP OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: This enables an ERC1967 proxy to be deployed at a deterministic address
    // independent of the implementation:
    // ```
    //     address bootstrap = LibClone.constantERC1967Bootstrap();
    //     address instance = LibClone.deployDeterministicERC1967(0, bootstrap, salt);
    //     LibClone.bootstrapConstantERC1967(bootstrap, implementation);
    // ```

    /// @dev Deploys the constant ERC1967 bootstrap if it has not been deployed.
    function constantERC1967Bootstrap() internal returns (address bootstrap) {
        bootstrap = constantERC1967BootstrapAddress();
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(extcodesize(bootstrap)) {
                mstore(0x20, 0x0894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc55)
                mstore(0x00, 0x60258060093d393df358357f36)
                if iszero(create2(0, 0x13, 0x2e, 0)) {
                    mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @dev Returns the implementation address of the ERC1967 bootstrap for this contract.
    function constantERC1967BootstrapAddress() internal view returns (address bootstrap) {
        bytes32 hash = 0xfe1a42b9c571a6a8c083c94ac67b9cfd74e2582923426aa3b762e3431d717cd1;
        bootstrap = predictDeterministicAddress(hash, bytes32(0), address(this));
    }

    /// @dev Replaces the implementation at `instance`.
    function bootstrapERC1967(address instance, address implementation) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, shr(96, shl(96, implementation)))
            if iszero(call(gas(), instance, 0, 0x00, 0x20, codesize(), 0x00)) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address when a contract with initialization code hash,
    /// `hash`, is deployed with `salt`, by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(bytes32 hash, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Requires that `salt` starts with either the zero address or `by`.
    function checkStartsWith(bytes32 salt, address by) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            // If the salt does not start with the zero address or `by`.
            if iszero(or(iszero(shr(96, salt)), eq(shr(96, shl(96, by)), shr(96, salt)))) {
                mstore(0x00, 0x0c4549ef) // `SaltDoesNotStartWith()`.
                revert(0x1c, 0x04)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for compressing and decompressing bytes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibZip.sol)
/// @author Calldata compression by clabby (https://github.com/clabby/op-kompressor)
/// @author FastLZ by ariya (https://github.com/ariya/FastLZ)
///
/// @dev Note:
/// The accompanying solady.js library includes implementations of
/// FastLZ and calldata operations for convenience.
library LibZip {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     FAST LZ OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // LZ77 implementation based on FastLZ.
    // Equivalent to level 1 compression and decompression at the following commit:
    // https://github.com/ariya/FastLZ/commit/344eb4025f9ae866ebf7a2ec48850f7113a97a42
    // Decompression is backwards compatible.

    /// @dev Returns the compressed `data`.
    function flzCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function ms8(d_, v_) -> _d {
                mstore8(d_, v_)
                _d := add(d_, 1)
            }
            function u24(p_) -> _u {
                _u := mload(p_)
                _u := or(shl(16, byte(2, _u)), or(shl(8, byte(1, _u)), byte(0, _u)))
            }
            function cmp(p_, q_, e_) -> _l {
                for { e_ := sub(e_, q_) } lt(_l, e_) { _l := add(_l, 1) } {
                    e_ := mul(iszero(byte(0, xor(mload(add(p_, _l)), mload(add(q_, _l))))), e_)
                }
            }
            function literals(runs_, src_, dest_) -> _o {
                for { _o := dest_ } iszero(lt(runs_, 0x20)) { runs_ := sub(runs_, 0x20) } {
                    mstore(ms8(_o, 31), mload(src_))
                    _o := add(_o, 0x21)
                    src_ := add(src_, 0x20)
                }
                if iszero(runs_) { leave }
                mstore(ms8(_o, sub(runs_, 1)), mload(src_))
                _o := add(1, add(_o, runs_))
            }
            function mt(l_, d_, o_) -> _o {
                for { d_ := sub(d_, 1) } iszero(lt(l_, 263)) { l_ := sub(l_, 262) } {
                    o_ := ms8(ms8(ms8(o_, add(224, shr(8, d_))), 253), and(0xff, d_))
                }
                if iszero(lt(l_, 7)) {
                    _o := ms8(ms8(ms8(o_, add(224, shr(8, d_))), sub(l_, 7)), and(0xff, d_))
                    leave
                }
                _o := ms8(ms8(o_, add(shl(5, l_), shr(8, d_))), and(0xff, d_))
            }
            function setHash(i_, v_) {
                let p_ := add(mload(0x40), shl(2, i_))
                mstore(p_, xor(mload(p_), shl(224, xor(shr(224, mload(p_)), v_))))
            }
            function getHash(i_) -> _h {
                _h := shr(224, mload(add(mload(0x40), shl(2, i_))))
            }
            function hash(v_) -> _r {
                _r := and(shr(19, mul(2654435769, v_)), 0x1fff)
            }
            function setNextHash(ip_, ipStart_) -> _ip {
                setHash(hash(u24(ip_)), sub(ip_, ipStart_))
                _ip := add(ip_, 1)
            }
            result := mload(0x40)
            codecopy(result, codesize(), 0x8000) // Zeroize the hashmap.
            let op := add(result, 0x8000)
            let a := add(data, 0x20)
            let ipStart := a
            let ipLimit := sub(add(ipStart, mload(data)), 13)
            for { let ip := add(2, a) } lt(ip, ipLimit) {} {
                let r := 0
                let d := 0
                for {} 1 {} {
                    let s := u24(ip)
                    let h := hash(s)
                    r := add(ipStart, getHash(h))
                    setHash(h, sub(ip, ipStart))
                    d := sub(ip, r)
                    if iszero(lt(ip, ipLimit)) { break }
                    ip := add(ip, 1)
                    if iszero(gt(d, 0x1fff)) { if eq(s, u24(r)) { break } }
                }
                if iszero(lt(ip, ipLimit)) { break }
                ip := sub(ip, 1)
                if gt(ip, a) { op := literals(sub(ip, a), a, op) }
                let l := cmp(add(r, 3), add(ip, 3), add(ipLimit, 9))
                op := mt(l, d, op)
                ip := setNextHash(setNextHash(add(ip, l), ipStart), ipStart)
                a := ip
            }
            // Copy the result to compact the memory, overwriting the hashmap.
            let end := sub(literals(sub(add(ipStart, mload(data)), a), a, op), 0x7fe0)
            let o := add(result, 0x20)
            mstore(result, sub(end, o)) // Store the length.
            for {} iszero(gt(o, end)) { o := add(o, 0x20) } { mstore(o, mload(add(o, 0x7fe0))) }
            mstore(end, 0) // Zeroize the slot after the string.
            mstore(0x40, add(end, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Returns the decompressed `data`.
    function flzDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let op := add(result, 0x20)
            let end := add(add(data, 0x20), mload(data))
            for { data := add(data, 0x20) } lt(data, end) {} {
                let w := mload(data)
                let c := byte(0, w)
                let t := shr(5, c)
                if iszero(t) {
                    mstore(op, mload(add(data, 1)))
                    data := add(data, add(2, c))
                    op := add(op, add(1, c))
                    continue
                }
                for {
                    let g := eq(t, 7)
                    let l := add(2, xor(t, mul(g, xor(t, add(7, byte(1, w)))))) // M
                    let s := add(add(shl(8, and(0x1f, c)), byte(add(1, g), w)), 1) // R
                    let r := sub(op, s)
                    let f := xor(s, mul(gt(s, 0x20), xor(s, 0x20)))
                    let j := 0
                } 1 {} {
                    mstore(add(op, j), mload(add(r, j)))
                    j := add(j, f)
                    if lt(j, l) { continue }
                    data := add(data, add(2, g))
                    op := add(op, l)
                    break
                }
            }
            mstore(result, sub(op, add(result, 0x20))) // Store the length.
            mstore(op, 0) // Zeroize the slot after the string.
            mstore(0x40, add(op, 0x20)) // Allocate the memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    CALLDATA OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Calldata compression and decompression using selective run length encoding:
    // - Sequences of 0x00 (up to 128 consecutive).
    // - Sequences of 0xff (up to 32 consecutive).
    //
    // A run length encoded block consists of two bytes:
    // (0) 0x00
    // (1) A control byte with the following bit layout:
    //     - [7]     `0: 0x00, 1: 0xff`.
    //     - [0..6]  `runLength - 1`.
    //
    // The first 4 bytes are bitwise negated so that the compressed calldata
    // can be dispatched into the `fallback` and `receive` functions.

    /// @dev Returns the compressed `data`.
    function cdCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function rle(v_, o_, d_) -> _o, _d {
                mstore(o_, shl(240, or(and(0xff, add(d_, 0xff)), and(0x80, v_))))
                _o := add(o_, 2)
            }
            result := mload(0x40)
            let o := add(result, 0x20)
            let z := 0 // Number of consecutive 0x00.
            let y := 0 // Number of consecutive 0xff.
            for { let end := add(data, mload(data)) } iszero(eq(data, end)) {} {
                data := add(data, 1)
                let c := byte(31, mload(data))
                if iszero(c) {
                    if y { o, y := rle(0xff, o, y) }
                    z := add(z, 1)
                    if eq(z, 0x80) { o, z := rle(0x00, o, 0x80) }
                    continue
                }
                if eq(c, 0xff) {
                    if z { o, z := rle(0x00, o, z) }
                    y := add(y, 1)
                    if eq(y, 0x20) { o, y := rle(0xff, o, 0x20) }
                    continue
                }
                if y { o, y := rle(0xff, o, y) }
                if z { o, z := rle(0x00, o, z) }
                mstore8(o, c)
                o := add(o, 1)
            }
            if y { o, y := rle(0xff, o, y) }
            if z { o, z := rle(0x00, o, z) }
            // Bitwise negate the first 4 bytes.
            mstore(add(result, 4), not(mload(add(result, 4))))
            mstore(result, sub(o, add(result, 0x20))) // Store the length.
            mstore(o, 0) // Zeroize the slot after the string.
            mstore(0x40, add(o, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Returns the decompressed `data`.
    function cdDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                result := mload(0x40)
                let o := add(result, 0x20)
                let s := add(data, 4)
                let v := mload(s)
                let end := add(data, mload(data))
                mstore(s, not(v)) // Bitwise negate the first 4 bytes.
                for {} lt(data, end) {} {
                    data := add(data, 1)
                    let c := byte(31, mload(data))
                    if iszero(c) {
                        data := add(data, 1)
                        let d := byte(31, mload(data))
                        // Fill with either 0xff or 0x00.
                        mstore(o, not(0))
                        if iszero(gt(d, 0x7f)) { codecopy(o, codesize(), add(d, 1)) }
                        o := add(o, add(and(d, 0x7f), 1))
                        continue
                    }
                    mstore8(o, c)
                    o := add(o, 1)
                }
                mstore(s, v) // Restore the first 4 bytes.
                mstore(result, sub(o, add(result, 0x20))) // Store the length.
                mstore(o, 0) // Zeroize the slot after the string.
                mstore(0x40, add(o, 0x20)) // Allocate the memory.
            }
        }
    }

    /// @dev To be called in the `fallback` function.
    /// ```
    ///     fallback() external payable { LibZip.cdFallback(); }
    ///     receive() external payable {} // Silence compiler warning to add a `receive` function.
    /// ```
    /// For efficiency, this function will directly return the results, terminating the context.
    /// If called internally, it must be called at the end of the function.
    function cdFallback() internal {
        assembly {
            if iszero(calldatasize()) { return(calldatasize(), calldatasize()) }
            let o := 0
            let f := not(3) // For negating the first 4 bytes.
            for { let i := 0 } lt(i, calldatasize()) {} {
                let c := byte(0, xor(add(i, f), calldataload(i)))
                i := add(i, 1)
                if iszero(c) {
                    let d := byte(0, xor(add(i, f), calldataload(i)))
                    i := add(i, 1)
                    // Fill with either 0xff or 0x00.
                    mstore(o, not(0))
                    if iszero(gt(d, 0x7f)) { codecopy(o, codesize(), add(d, 1)) }
                    o := add(o, add(and(d, 0x7f), 1))
                    continue
                }
                mstore8(o, c)
                o := add(o, 1)
            }
            let success := delegatecall(gas(), address(), 0x00, o, codesize(), 0x00)
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(success) { revert(0x00, returndatasize()) }
            return(0x00, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Permit2 operations from (https://github.com/Uniswap/permit2/blob/main/src/libraries/Permit2Lib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for DoS protection.
/// - For ERC20s, this implementation won't check that a token has code,
///   responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /// @dev The Permit2 operation has failed.
    error Permit2Failed();

    /// @dev The Permit2 amount must be less than `2**160 - 1`.
    error Permit2AmountOverflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /// @dev The unique EIP-712 domain domain separator for the DAI token contract.
    bytes32 internal constant DAI_DOMAIN_SEPARATOR =
        0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;

    /// @dev The address for the WETH9 contract on Ethereum mainnet.
    address internal constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @dev The canonical Permit2 address.
    /// [Github](https://github.com/Uniswap/permit2)
    /// [Etherscan](https://etherscan.io/address/0x000000000022D473030F116dDEE9F6B43aC78BA3)
    address internal constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // If the ETH transfer MUST succeed with a reasonable gas budget, use the force variants.
    //
    // The regular variants:
    // - Forwards all remaining gas to the target.
    // - Reverts if the target reverts.
    // - Reverts if the current contract has insufficient balance.
    //
    // The force variants:
    // - Forwards with an optional gas stipend
    //   (defaults to `GAS_STIPEND_NO_GRIEF`, which is sufficient for most cases).
    // - If the target reverts, or if the gas stipend is exhausted,
    //   creates a temporary contract to force send the ETH via `SELFDESTRUCT`.
    //   Future compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758.
    // - Reverts if the current contract has insufficient balance.
    //
    // The try variants:
    // - Forwards with a mandatory gas stipend.
    // - Instead of reverting, returns whether the transfer succeeded.

    /// @dev Sends `amount` (in wei) ETH to `to`.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`.
    function safeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer all the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function forceSafeTransferAllETH(address to, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function trySafeTransferAllETH(address to, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    ///
    /// The `from` account must have at least `amount` approved for the current contract to manage.
    function trySafeTransferFrom(address token, address from, address to, uint256 amount)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            success :=
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, 0x23b872dd) // `transferFrom(address,address,uint256)`.
            amount := mload(0x60) // The `amount` is already at 0x60. We'll need to return it.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, to) // Store the `to` argument.
            amount := mload(0x34) // The `amount` is already at 0x34. We'll need to return it.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// If the initial attempt to approve fails, attempts to reset the approved amount to zero,
    /// then retries the approval again (some tokens, e.g. USDT, requires this).
    /// Reverts upon failure.
    function safeApproveWithRetry(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, amount) // Store back the original `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount :=
                mul( // The arguments of `mul` are evaluated from right to left.
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// If the initial attempt fails, try to use Permit2 to transfer the token.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for the current contract to manage.
    function safeTransferFrom2(address token, address from, address to, uint256 amount) internal {
        if (!trySafeTransferFrom(token, from, to, amount)) {
            permit2TransferFrom(token, from, to, amount);
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to` via Permit2.
    /// Reverts upon failure.
    function permit2TransferFrom(address token, address from, address to, uint256 amount)
        internal
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(m, 0x74), shr(96, shl(96, token)))
            mstore(add(m, 0x54), amount)
            mstore(add(m, 0x34), to)
            mstore(add(m, 0x20), shl(96, from))
            // `transferFrom(address,address,uint160,address)`.
            mstore(m, 0x36c78516000000000000000000000000)
            let p := PERMIT2
            let exists := eq(chainid(), 1)
            if iszero(exists) { exists := iszero(iszero(extcodesize(p))) }
            if iszero(and(call(gas(), p, 0, add(m, 0x10), 0x84, codesize(), 0x00), exists)) {
                mstore(0x00, 0x7939f4248757f0fd) // `TransferFromFailed()` or `Permit2AmountOverflow()`.
                revert(add(0x18, shl(2, iszero(iszero(shr(160, amount))))), 0x04)
            }
        }
    }

    /// @dev Permit a user to spend a given amount of
    /// another user's tokens via native EIP-2612 permit if possible, falling
    /// back to Permit2 if native permit fails or is not implemented on the token.
    function permit2(
        address token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        bool success;
        /// @solidity memory-safe-assembly
        assembly {
            for {} shl(96, xor(token, WETH9)) {} {
                mstore(0x00, 0x3644e515) // `DOMAIN_SEPARATOR()`.
                if iszero(
                    and( // The arguments of `and` are evaluated from right to left.
                        lt(iszero(mload(0x00)), eq(returndatasize(), 0x20)), // Returns 1 non-zero word.
                        // Gas stipend to limit gas burn for tokens that don't refund gas when
                        // an non-existing function is called. 5K should be enough for a SLOAD.
                        staticcall(5000, token, 0x1c, 0x04, 0x00, 0x20)
                    )
                ) { break }
                // After here, we can be sure that token is a contract.
                let m := mload(0x40)
                mstore(add(m, 0x34), spender)
                mstore(add(m, 0x20), shl(96, owner))
                mstore(add(m, 0x74), deadline)
                if eq(mload(0x00), DAI_DOMAIN_SEPARATOR) {
                    mstore(0x14, owner)
                    mstore(0x00, 0x7ecebe00000000000000000000000000) // `nonces(address)`.
                    mstore(add(m, 0x94), staticcall(gas(), token, 0x10, 0x24, add(m, 0x54), 0x20))
                    mstore(m, 0x8fcbaf0c000000000000000000000000) // `IDAIPermit.permit`.
                    // `nonces` is already at `add(m, 0x54)`.
                    // `1` is already stored at `add(m, 0x94)`.
                    mstore(add(m, 0xb4), and(0xff, v))
                    mstore(add(m, 0xd4), r)
                    mstore(add(m, 0xf4), s)
                    success := call(gas(), token, 0, add(m, 0x10), 0x104, codesize(), 0x00)
                    break
                }
                mstore(m, 0xd505accf000000000000000000000000) // `IERC20Permit.permit`.
                mstore(add(m, 0x54), amount)
                mstore(add(m, 0x94), and(0xff, v))
                mstore(add(m, 0xb4), r)
                mstore(add(m, 0xd4), s)
                success := call(gas(), token, 0, add(m, 0x10), 0xe4, codesize(), 0x00)
                break
            }
        }
        if (!success) simplePermit2(token, owner, spender, amount, deadline, v, r, s);
    }

    /// @dev Simple permit on the Permit2 contract.
    function simplePermit2(
        address token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, 0x927da105) // `allowance(address,address,address)`.
            {
                let addressMask := shr(96, not(0))
                mstore(add(m, 0x20), and(addressMask, owner))
                mstore(add(m, 0x40), and(addressMask, token))
                mstore(add(m, 0x60), and(addressMask, spender))
                mstore(add(m, 0xc0), and(addressMask, spender))
            }
            let p := mul(PERMIT2, iszero(shr(160, amount)))
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x5f), // Returns 3 words: `amount`, `expiration`, `nonce`.
                    staticcall(gas(), p, add(m, 0x1c), 0x64, add(m, 0x60), 0x60)
                )
            ) {
                mstore(0x00, 0x6b836e6b8757f0fd) // `Permit2Failed()` or `Permit2AmountOverflow()`.
                revert(add(0x18, shl(2, iszero(p))), 0x04)
            }
            mstore(m, 0x2b67b570) // `Permit2.permit` (PermitSingle variant).
            // `owner` is already `add(m, 0x20)`.
            // `token` is already at `add(m, 0x40)`.
            mstore(add(m, 0x60), amount)
            mstore(add(m, 0x80), 0xffffffffffff) // `expiration = type(uint48).max`.
            // `nonce` is already at `add(m, 0xa0)`.
            // `spender` is already at `add(m, 0xc0)`.
            mstore(add(m, 0xe0), deadline)
            mstore(add(m, 0x100), 0x100) // `signature` offset.
            mstore(add(m, 0x120), 0x41) // `signature` length.
            mstore(add(m, 0x140), r)
            mstore(add(m, 0x160), s)
            mstore(add(m, 0x180), shl(248, v))
            if iszero(call(gas(), p, 0, add(m, 0x1c), 0x184, codesize(), 0x00)) {
                mstore(0x00, 0x6b836e6b) // `Permit2Failed()`.
                revert(0x1c, 0x04)
            }
        }
    }
}