// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./TransferDefinition.sol";

/// @title HashlockTransfer
/// @author Connext <[email protected]>
/// @notice This contract allows users to claim a payment locked in
///         the application if they provide the correct preImage. The payment is
///         reverted if not unlocked by the timelock if one is provided.

contract HashlockTransfer is TransferDefinition {
    struct TransferState {
        bytes32 lockHash;
        uint256 expiry; // If 0, then no timelock is enforced
    }

    struct TransferResolver {
        bytes32 preImage;
    }

    // Provide registry information
    string public constant override Name = "HashlockTransfer";
    string public constant override StateEncoding =
        "tuple(bytes32 lockHash, uint256 expiry)";
    string public constant override ResolverEncoding =
        "tuple(bytes32 preImage)";

    function EncodedCancel() external pure override returns(bytes memory) {
      TransferResolver memory resolver;
      resolver.preImage = bytes32(0);
      return abi.encode(resolver);
    } 

    function create(bytes calldata encodedBalance, bytes calldata encodedState)
        external
        view
        override
        returns (bool)
    {
        // Decode parameters
        TransferState memory state = abi.decode(encodedState, (TransferState));
        Balance memory balance = abi.decode(encodedBalance, (Balance));

        require(
            balance.amount[0] > 0,
            "HashlockTransfer: ZER0_SENDER_BALANCE"
        );

        require(
            balance.amount[1] == 0,
            "HashlockTransfer: NONZERO_RECIPIENT_BALANCE"
        );
        require(
            state.lockHash != bytes32(0),
            "HashlockTransfer: EMPTY_LOCKHASH"
        );
        require(
            state.expiry == 0 || state.expiry > block.timestamp,
            "HashlockTransfer: EXPIRED_TIMELOCK"
        );

        // Valid transfer state
        return true;
    }

    function resolve(
        bytes calldata encodedBalance,
        bytes calldata encodedState,
        bytes calldata encodedResolver
    ) external view override returns (Balance memory) {
        TransferState memory state = abi.decode(encodedState, (TransferState));
        TransferResolver memory resolver =
            abi.decode(encodedResolver, (TransferResolver));
        Balance memory balance = abi.decode(encodedBalance, (Balance));

        // If you pass in bytes32(0), payment is canceled
        // If timelock is nonzero and has expired, payment must be canceled
        // otherwise resolve will revert
        if (resolver.preImage != bytes32(0)) {
            // Payment must not be expired
            require(state.expiry == 0 || state.expiry > block.timestamp, "HashlockTransfer: PAYMENT_EXPIRED");

            // Check hash for normal payment unlock
            bytes32 generatedHash = sha256(abi.encode(resolver.preImage));
            require(
                state.lockHash == generatedHash,
                "HashlockTransfer: INVALID_PREIMAGE"
            );

            // Update state
            balance.amount[1] = balance.amount[0];
            balance.amount[0] = 0;
        }
        // To cancel, the preImage must be empty (not simply incorrect)
        // There are no additional state mutations, and the preImage is
        // asserted by the `if` statement

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