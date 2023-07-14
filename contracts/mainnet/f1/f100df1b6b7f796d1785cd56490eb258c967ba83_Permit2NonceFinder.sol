// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";

contract Permit2NonceFinder {
    ISignatureTransfer public immutable permit2;

    /// @notice Constructs the Permit2NonceFinder contract
    /// @param _permit2 The address of the Permit2 contract
    constructor(address _permit2) {
        permit2 = ISignatureTransfer(_permit2);
    }

    /// @notice Finds the next valid nonce for a user, starting from 0.
    /// @param owner The owner of the nonces
    /// @return nonce The first valid nonce starting from 0
    function nextNonce(address owner) external view returns (uint256 nonce) {
        nonce = _nextNonce(owner, 0, 0);
    }

    /// @notice Finds the next valid nonce for a user, after from a given nonce.
    /// @dev This can be helpful if you're signing multiple nonces in a row and need the next nonce to sign but the start one is still valid.
    /// @param owner The owner of the nonces
    /// @param start The nonce to start from
    /// @return nonce The first valid nonce after the given nonce
    function nextNonceAfter(address owner, uint256 start) external view returns (uint256 nonce) {
        uint248 word = uint248(start >> 8);
        uint8 pos = uint8(start);
        if (pos == type(uint8).max) {
            // If the position is 255, we need to move to the next word
            word++;
            pos = 0;
        } else {
            // Otherwise, we just move to the next position
            pos++;
        }
        nonce = _nextNonce(owner, word, pos);
    }

    /// @notice Finds the next valid nonce for a user, starting from a given word and position.
    /// @param owner The owner of the nonces
    /// @param word Word to start looking from
    /// @param pos Position inside the word to start looking from
    function _nextNonce(address owner, uint248 word, uint8 pos) internal view returns (uint256 nonce) {
        while (true) {
            uint256 bitmap = permit2.nonceBitmap(owner, word);

            // Check if the bitmap is completely full
            if (bitmap == type(uint256).max) {
                // If so, move to the next word
                ++word;
                pos = 0;
                continue;
            }
            if (pos != 0) {
                // If the position is not 0, we need to shift the bitmap to ignore the bits before position
                bitmap = bitmap >> pos;
            }
            // Find the first zero bit in the bitmap
            while (bitmap & 1 == 1) {
                bitmap = bitmap >> 1;
                ++pos;
            }

            return _nonceFromWordAndPos(word, pos);
        }
    }

    /// @notice Constructs a nonce from a word and a position inside the word
    /// @param word The word containing the nonce
    /// @param pos The position of the nonce inside the word
    /// @return nonce The nonce constructed from the word and position
    function _nonceFromWordAndPos(uint248 word, uint8 pos) internal pure returns (uint256 nonce) {
        // The last 248 bits of the word are the nonce bits
        nonce = uint256(word) << 8;
        // The first 8 bits of the word are the position inside the word
        nonce |= pos;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IEIP712} from "./IEIP712.sol";

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer is IEIP712 {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}