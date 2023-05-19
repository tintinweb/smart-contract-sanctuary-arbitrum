// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./TransferDefinition.sol";
import "../lib/LibChannelCrypto.sol";

/// @title Withdraw
/// @author Connext <[email protected]>
/// @notice This contract burns the initiator's funds if a mutually signed
///         withdraw commitment can be generated

contract Withdraw is TransferDefinition {
    using LibChannelCrypto for bytes32;

    struct TransferState {
        bytes initiatorSignature;
        address initiator;
        address responder;
        bytes32 data;
        uint256 nonce; // included so that each withdraw commitment has a unique hash
        uint256 fee;
        address callTo;
        bytes callData;
    }

    struct TransferResolver {
        bytes responderSignature;
    }

    // Provide registry information
    string public constant override Name = "Withdraw";
    string public constant override StateEncoding =
        "tuple(bytes initiatorSignature, address initiator, address responder, bytes32 data, uint256 nonce, uint256 fee, address callTo, bytes callData)";
    string public constant override ResolverEncoding =
        "tuple(bytes responderSignature)";

    function EncodedCancel() external pure override returns(bytes memory) {
      TransferResolver memory resolver;
      resolver.responderSignature = new bytes(65);
      return abi.encode(resolver);
    }

    function create(bytes calldata encodedBalance, bytes calldata encodedState)
        external
        pure
        override
        returns (bool)
    {
        // Get unencoded information
        TransferState memory state = abi.decode(encodedState, (TransferState));
        Balance memory balance = abi.decode(encodedBalance, (Balance));

        require(balance.amount[1] == 0, "Withdraw: NONZERO_RECIPIENT_BALANCE");
        require(
            state.initiator != address(0) && state.responder != address(0),
            "Withdraw: EMPTY_SIGNERS"
        );
        require(state.data != bytes32(0), "Withdraw: EMPTY_DATA");
        require(state.nonce != uint256(0), "Withdraw: EMPTY_NONCE");
        require(
            state.fee <= balance.amount[0],
            "Withdraw: INSUFFICIENT_BALANCE"
        );
        require(
            state.data.checkSignature(
                state.initiatorSignature,
                state.initiator
            ),
            "Withdraw: INVALID_INITIATOR_SIG"
        );
        
        // Valid initial transfer state
        return true;
    }

    function resolve(
        bytes calldata encodedBalance,
        bytes calldata encodedState,
        bytes calldata encodedResolver
    ) external pure override returns (Balance memory) {
        TransferState memory state = abi.decode(encodedState, (TransferState));
        TransferResolver memory resolver =
            abi.decode(encodedResolver, (TransferResolver));
        Balance memory balance = abi.decode(encodedBalance, (Balance));

        // Allow for a withdrawal to be canceled if an empty signature is 
        // passed in. Should have *specific* cancellation action, not just
        // any invalid sig
        bytes memory b = new bytes(65);
        if (keccak256(resolver.responderSignature) == keccak256(b)) {
            // Withdraw should be cancelled, no state manipulation needed
        } else {
            require(
                state.data.checkSignature(
                    resolver.responderSignature,
                    state.responder
                ),
                "Withdraw: INVALID_RESPONDER_SIG"
            );
            // Reduce withdraw amount by optional fee
            // It's up to the offchain validators to ensure that the withdraw commitment takes this fee into account
            balance.amount[1] = state.fee;
            balance.amount[0] = 0;
        }

        return balance;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "../interfaces/ITransferDefinition.sol";
import "../interfaces/ITransferRegistry.sol";

/// @title TransferDefinition
/// @author Connext <[email protected]>
/// @notice This contract helps reduce boilerplate needed when creating
///         new transfer definitions by providing an implementation of
///         the required getter

abstract contract TransferDefinition is ITransferDefinition {
    function getRegistryInformation()
        external
        view
        override
        returns (RegisteredTransfer memory)
    {
        return
            RegisteredTransfer({
                name: this.Name(),
                stateEncoding: this.StateEncoding(),
                resolverEncoding: this.ResolverEncoding(),
                definition: address(this),
                encodedCancel: this.EncodedCancel()
            });
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
		
/// @author Connext <[email protected]>		
/// @notice This library contains helpers for recovering signatures from a		
///         Vector commitments. Channels do not allow for arbitrary signing of		
///         messages to prevent misuse of private keys by injected providers,		
///         and instead only sign messages with a Vector channel prefix.
library LibChannelCrypto {
    function checkSignature(
        bytes32 hash,
        bytes memory signature,
        address allegedSigner
    ) internal pure returns (bool) {
        return recoverChannelMessageSigner(hash, signature) == allegedSigner;
    }

    function recoverChannelMessageSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 digest = toChannelSignedMessage(hash);
        return ECDSA.recover(digest, signature);
    }

    function toChannelSignedMessage(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(abi.encodePacked("\x16Vector Signed Message:\n32", hash));
    }

    function checkUtilitySignature(
        bytes32 hash,
        bytes memory signature,
        address allegedSigner
    ) internal pure returns (bool) {
        return recoverChannelMessageSigner(hash, signature) == allegedSigner;
    }

    function recoverUtilityMessageSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 digest = toUtilitySignedMessage(hash);
        return ECDSA.recover(digest, signature);
    }

    function toUtilitySignedMessage(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(abi.encodePacked("\x17Utility Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./ITransferRegistry.sol";
import "./Types.sol";

interface ITransferDefinition {
    // Validates the initial state of the transfer.
    // Called by validator.ts during `create` updates.
    function create(bytes calldata encodedBalance, bytes calldata)
        external
        view
        returns (bool);

    // Performs a state transition to resolve a transfer and returns final balances.
    // Called by validator.ts during `resolve` updates.
    function resolve(
        bytes calldata encodedBalance,
        bytes calldata,
        bytes calldata
    ) external view returns (Balance memory);

    // Should also have the following properties:
    // string public constant override Name = "...";
    // string public constant override StateEncoding = "...";
    // string public constant override ResolverEncoding = "...";
    // These properties are included on the transfer specifically
    // to make it easier for implementers to add new transfers by
    // only include a `.sol` file
    function Name() external view returns (string memory);

    function StateEncoding() external view returns (string memory);

    function ResolverEncoding() external view returns (string memory);

    function EncodedCancel() external view returns (bytes memory);

    function getRegistryInformation()
        external
        view
        returns (RegisteredTransfer memory);
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

struct Balance {
    uint256[2] amount; // [alice, bob] in channel, [initiator, responder] in transfer
    address payable[2] to; // [alice, bob] in channel, [initiator, responder] in transfer
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}