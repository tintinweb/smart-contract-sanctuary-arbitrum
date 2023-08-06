// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IEIP712} from "./IEIP712.sol";

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer is IEIP712 {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint48 newNonce,
        uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(
        address user,
        address token,
        address spender
    ) external view returns (uint160 amount, uint48 expiration, uint48 nonce);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(
        address token,
        address spender,
        uint160 amount,
        uint48 expiration
    ) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(
        address owner,
        PermitSingle memory permitSingle,
        bytes calldata signature
    ) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(
        address owner,
        PermitBatch memory permitBatch,
        bytes calldata signature
    ) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(
        address from,
        address to,
        uint160 amount,
        address token
    ) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(
        AllowanceTransferDetails[] calldata transferDetails
    ) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(
        address token,
        address spender,
        uint48 newNonce
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
    event UnorderedNonceInvalidation(
        address indexed owner,
        uint256 word,
        uint256 mask
    );

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(ERC20 token, address from, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(ERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(ERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {Order, Execution} from "./interfaces/Orders.sol";
import {OrderLib} from "./lib/OrderLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";

contract Escrow {
    using SafeTransferLib for ERC20;
    address public socketMarketPlace;
    struct EscrowOrder {
        address token;
        uint256 amount;
        address receiver;
        uint256 destinationDeadline;
        bool isOrderActive;
    }
    mapping(bytes32 => EscrowOrder) public escrows;
    event EscrowCreated(bytes32 orderId);
    event EscrowWithdrawn(bytes32 orderId);

    constructor(address _socketMarketPlace) {
        socketMarketPlace = _socketMarketPlace;
    }

    modifier onlySMP() {
        require(
            msg.sender == socketMarketPlace,
            "Only socket MarketPlace can call"
        );
        _;
    }

    function createEscrow(Order memory order) public payable onlySMP {
        // create escrow
        bytes32 orderId = OrderLib.getOrderHash(order);
        escrows[orderId] = EscrowOrder(
            order.fromToken,
            order.fromAmount,
            order.receiver,
            order.destinationDeadline,
            true
        );
        ERC20(order.fromToken).safeTransferFrom(
            socketMarketPlace,
            address(this),
            order.fromAmount
        );
        emit EscrowCreated(orderId);
    }

    function withDrawEscrow(bytes32 orderId) public {
        require(
            escrows[orderId].receiver == msg.sender,
            "Only receiver can withdraw"
        );
        require(
            escrows[orderId].destinationDeadline > block.timestamp,
            "Deadline has passed"
        );
        require(escrows[orderId].isOrderActive == true, "Order is not active");
        escrows[orderId].isOrderActive = false;
        ERC20(escrows[orderId].token).safeTransfer(
            msg.sender,
            escrows[orderId].amount
        );
        emit EscrowWithdrawn(orderId);
    }

    function fullFillEscrow(
        bytes32 orderId,
        address solver
    ) public payable onlySMP {
        require(escrows[orderId].isOrderActive == true, "Order is not active");
        escrows[orderId].isOrderActive = false;
        ERC20(escrows[orderId].token).safeTransfer(
            solver,
            escrows[orderId].amount
        );
        emit EscrowWithdrawn(orderId);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/**
 * @title ISocket
 * @notice An interface for a cross-chain communication contract
 * @dev This interface provides methods for transmitting and executing messages between chains,
 * connecting a plug to a remote chain and setting up switchboards for the message transmission
 * This interface also emits events for important operations such as message transmission, execution status,
 * and plug connection
 */
interface ISocket {
    /**
     * @notice A struct containing fees required for message transmission and execution
     * @param transmissionFees fees needed for transmission
     * @param switchboardFees fees needed by switchboard
     * @param executionFee fees needed for execution
     */
    struct Fees {
        uint128 transmissionFees;
        uint128 executionFee;
        uint128 switchboardFees;
    }

    /**
     * @title MessageDetails
     * @dev This struct defines the details of a message to be executed in a Decapacitor contract.
     */
    struct MessageDetails {
        // A unique identifier for the message.
        bytes32 msgId;
        // The fee to be paid for executing the message.
        uint256 executionFee;
        // The min amount of gas that can be used to execute the message.
        uint256 minMsgGasLimit;
        // The extra params which might provide msg value and additional info needed for message exec
        bytes32 executionParams;
        // The payload data to be executed in the message.
        bytes payload;
    }

    /**
     * @title ExecutionDetails
     * @dev This struct defines the execution details
     */
    struct ExecutionDetails {
        // packet id
        bytes32 packetId;
        // proposal count
        uint256 proposalCount;
        // gas limit needed to execute inbound
        uint256 executionGasLimit;
        // proof data required by the Decapacitor contract to verify the message's authenticity
        bytes decapacitorProof;
        // signature of executor
        bytes signature;
    }

    /**
     * @notice emits the status of message after inbound call
     * @param msgId msg id which is executed
     */
    event ExecutionSuccess(bytes32 msgId);

    /**
     * @notice emits the config set by a plug for a remoteChainSlug
     * @param plug address of plug on current chain
     * @param siblingChainSlug sibling chain slug
     * @param siblingPlug address of plug on sibling chain
     * @param inboundSwitchboard inbound switchboard (select from registered options)
     * @param outboundSwitchboard outbound switchboard (select from registered options)
     * @param capacitor capacitor selected based on outbound switchboard
     * @param decapacitor decapacitor selected based on inbound switchboard
     */
    event PlugConnected(
        address plug,
        uint32 siblingChainSlug,
        address siblingPlug,
        address inboundSwitchboard,
        address outboundSwitchboard,
        address capacitor,
        address decapacitor
    );

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param minMsgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint32 remoteChainSlug_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes calldata payload_
    ) external payable returns (bytes32 msgId);

    /**
     * @notice executes a message
     * @param executionDetails_ the packet details, proof and signature needed for message execution
     * @param messageDetails_ the message details
     */
    function execute(
        ISocket.ExecutionDetails calldata executionDetails_,
        ISocket.MessageDetails calldata messageDetails_
    ) external payable;

    /**
     * @notice seals data in capacitor for specific batchSize
     * @param batchSize_ size of batch to be sealed
     * @param capacitorAddress_ address of capacitor
     * @param signature_ signed Data needed for verification
     */
    function seal(
        uint256 batchSize_,
        address capacitorAddress_,
        bytes calldata signature_
    ) external payable;

    /**
     * @notice proposes a packet
     * @param packetId_ packet id
     * @param root_ root data
     * @param switchboard_ The address of switchboard for which this packet is proposed
     * @param signature_ signed Data needed for verification
     */
    function proposeForSwitchboard(
        bytes32 packetId_,
        bytes32 root_,
        address switchboard_,
        bytes calldata signature_
    ) external payable;

    /**
     * @notice sets the config specific to the plug
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at sibling chain to call inbound
     * @param inboundSwitchboard_ the address of switchboard to use for receiving messages
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    /**
     * @notice deploy capacitor and decapacitor for a switchboard with a specified max packet length, sibling chain slug, and capacitor type.
     * @param siblingChainSlug_ The slug of the sibling chain that the switchboard is registered with.
     * @param maxPacketLength_ The maximum length of a packet allowed by the switchboard.
     * @param capacitorType_ The type of capacitor that the switchboard uses.
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function registerSwitchboardForSibling(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_,
        address siblingSwitchboard_
    ) external returns (address capacitor, address decapacitor);

    /**
     * @notice Emits the sibling switchboard for given `siblingChainSlug_`.
     * @dev This function is expected to be only called by switchboard.
     * @dev the event emitted is tracked by transmitters to decide which switchboard a packet should be proposed on
     * @param siblingChainSlug_ The slug of the sibling chain
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function useSiblingSwitchboard(
        uint32 siblingChainSlug_,
        address siblingSwitchboard_
    ) external;

    /**
     * @notice Retrieves the packet id roots for a specified packet id.
     * @param packetId_ The packet id for which to retrieve the root.
     * @param proposalCount_ The proposal id for packetId_ for which to retrieve the root.
     * @param switchboard_ The address of switchboard for which this packet is proposed
     * @return The packet id roots for the specified packet id.
     */
    function packetIdRoots(
        bytes32 packetId_,
        uint256 proposalCount_,
        address switchboard_
    ) external view returns (bytes32);

    /**
     * @notice Retrieves the minimum fees required for a message with a specified gas limit and destination chain.
     * @param minMsgGasLimit_ The gas limit of the message.
     * @param remoteChainSlug_ The slug of the destination chain for the message.
     * @param plug_ The address of the plug through which the message is sent.
     * @return totalFees The minimum fees required for the specified message.
     */
    function getMinFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        uint32 remoteChainSlug_,
        address plug_
    ) external view returns (uint256 totalFees);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISignatureTransfer} from "lib/permit2/src/interfaces/ISignatureTransfer.sol";

struct Order {
    uint8 bridgePref;
    address fromToken;
    address toToken;
    uint256 fromChainId;
    uint256 toChainId;
    uint256 fromAmount;
    uint256 minAmountOut;
    address receiver;
    uint256 sourceDeadline;
    uint256 destinationDeadline;
    bytes payload;
}

struct Execution {
    Order order;
    address sender;
    uint256 nonce;
    uint256 deadline;
    bytes signature;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/**
 * @title IPlug
 * @notice Interface for a plug contract that executes the message received from a source chain.
 */
interface IPlug {
    /**
     * @dev this should be only executable by socket
     * @notice executes the message received from source chain
     * @notice It is expected to have original sender checks in the destination plugs using payload
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        uint32 srcChainSlug_,
        bytes calldata payload_
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISignatureTransfer} from "lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {Order, Execution} from "./../interfaces/Orders.sol";

library ExecutionLib {
    bytes private constant ORDER_TYPE =
        bytes(
            "Order(address fromToken,address toToken,uint256 fromChainId,uint256 toChainId,uint256 fromAmount,uint256 minAmountOut,address receiver,uint256 sourceDeadline,uint256 destinationDeadline,bytes payload)"
        );
    bytes32 private constant ORDER_TYPE_HASH = keccak256(ORDER_TYPE);

    string internal constant PERMIT2_EXECUTION_TYPE =
        string(abi.encodePacked("Order witness)", ORDER_TYPE));

    function hash(Execution memory execution) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPE_HASH,
                    Order(
                        execution.order.bridgePref,
                        execution.order.fromToken,
                        execution.order.toToken,
                        execution.order.fromChainId,
                        execution.order.toChainId,
                        execution.order.fromAmount,
                        execution.order.minAmountOut,
                        execution.order.receiver,
                        execution.order.sourceDeadline,
                        execution.order.destinationDeadline,
                        execution.order.payload
                    )
                )
            );
    }

    function toPermit(
        Execution memory execution
    )
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory permit)
    {
        return
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: execution.order.fromToken,
                    amount: execution.order.fromAmount
                }),
                nonce: execution.nonce,
                deadline: execution.deadline
            });
    }

    function transferDetail(
        Execution memory execution
    )
        internal
        view
        returns (ISignatureTransfer.SignatureTransferDetails memory details)
    {
        details = ISignatureTransfer.SignatureTransferDetails({
            to: address(this),
            requestedAmount: execution.order.fromAmount
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISignatureTransfer} from "lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {Order} from "./../interfaces/Orders.sol";

library OrderLib {
    function getOrderHash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.bridgePref,
                    order.fromToken,
                    order.toToken,
                    order.fromChainId,
                    order.toChainId,
                    order.fromAmount,
                    order.minAmountOut,
                    order.receiver,
                    order.sourceDeadline,
                    order.destinationDeadline,
                    order.payload
                )
            );
    }
}

// // SPDX-License-Identifier: Unlicense
// pragma solidity ^0.8.4;
// import "forge-std/Test.sol";
// import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";

// contract Permit2TransferSignHelper {
//     bytes32 private constant _HASHED_NAME = keccak256("Permit2");
//     bytes32 private constant _TYPE_HASH =
//         keccak256(
//             "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
//         );

//     string public constant _TOKEN_PERMISSIONS_TYPESTRING =
//         "TokenPermissions(address token,uint256 amount)";

//     bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH =
//         keccak256("TokenPermissions(address token,uint256 amount)");

//     bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH =
//         keccak256(
//             "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
//         );
//     Vm private constant vm =
//         Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

//     function getPermitTransferSignature(
//         ISignatureTransfer.PermitTransferFrom memory permit,
//         uint256 privateKey
//     ) public returns (bytes memory sig) {
//         bytes32 tokenPermissions = keccak256(
//             abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted)
//         );
//         console.logBytes32(tokenPermissions);
//         console.logBytes32(
//             getDomainSeparator(0x000000000022D473030F116dDEE9F6B43aC78BA3)
//         );
//         bytes32 msgHash = keccak256(
//             abi.encodePacked(
//                 "\x19\x01",
//                 getDomainSeparator(0x000000000022D473030F116dDEE9F6B43aC78BA3),
//                 keccak256(
//                     abi.encode(
//                         _PERMIT_TRANSFER_FROM_TYPEHASH,
//                         tokenPermissions,
//                         0x77cf21917FF767e2FDEd80760Ee847CAb99BE13b,
//                         permit.nonce,
//                         permit.deadline
//                     )
//                 )
//             )
//         );
//         console.logBytes32(msgHash);
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
//         return bytes.concat(r, s, bytes1(v));
//     }

//     /// @notice Returns the domain separator for the current chain.
//     /// @dev Uses cached version if chainid and address are unchanged from construction.
//     function getDomainSeparator(
//         address permit2Address
//     ) public view returns (bytes32) {
//         console.logBytes32(
//            _TYPE_HASH
            
//         );
//         console.logBytes32(
//             _HASHED_NAME
//         );


//         return
//             keccak256(
//                 abi.encode(_TYPE_HASH, _HASHED_NAME, 420, permit2Address)
//             );
//     }

//     /// @notice Creates an EIP-712 typed data hash
//     function _hashTypedData(
//         bytes32 dataHash,
//         address permit2Address
//     ) public view returns (bytes32) {
//         return
//             keccak256(
//                 abi.encodePacked(
//                     "\x19\x01",
//                     getDomainSeparator(permit2Address),
//                     dataHash
//                 )
//             );
//     }
// }

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {ISignatureTransfer} from "lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {IAllowanceTransfer} from "lib/permit2/src/interfaces/IAllowanceTransfer.sol";
import {Order, Execution} from "./interfaces/Orders.sol";
import {ExecutionLib} from "./lib/ExecutionLib.sol";
import {OrderLib} from "./lib/OrderLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ISocket} from "./interfaces/ISocket.sol";
import {IPlug} from "./interfaces/Plug.sol";
import "./Escrow.sol";

/**
*  Socket Market Place is market place where we join solvers and users
* user want to transfer there funds from chain 1 to chain 2 from token A 
    on chain 1 to token b on chain 2 A and B can be same as well
 */
contract SocketMarketPlace is IPlug {
    using ExecutionLib for Execution;
    using OrderLib for Order;
    using SafeTransferLib for ERC20;

    struct Receipt {
        bool isFullfilled;
        uint256 amount;
        address token;
        uint256 orderTime;
        address solver;
        address receiver;
    }
    error OnlySocket();

    mapping(bytes32 => Receipt) public receipts;
    address public immutable socket;

    // application ops
    bytes32 public constant FULLFILL_ORDER_REQUEST =
        keccak256("FULLFILL_ORDER_REQUEST");

    Escrow public escrow;

    ISignatureTransfer public immutable permit2 =
        ISignatureTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IAllowanceTransfer public immutable allowanceTransfer =
        IAllowanceTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    event OrderFullfilled(
        bytes32 orderId,
        uint256 amount,
        address token,
        uint256 orderTime,
        address solver,
        address receiver
    );
    event OrderCreated(
        bytes32 orderId,
        uint8 bridgePref,
        address fromToken,
        address toToken,
        uint256 fromChainId,
        uint256 toChainId,
        uint256 fromAmount,
        uint256 minAmountOut,
        address receiver,
        uint256 sourceDeadline,
        uint256 destinationDeadline,
        bytes payload
    );

    constructor(address socket_) {
        socket = socket_;
    }

    function setEscrow(address escrow_) external {
        escrow = Escrow(escrow_);
    }

    // settings
    function setSocketConfig(
        uint32 remoteChainSlug_,
        address remotePlug_,
        address switchboard_,
        address switchboard2_
    ) external {
        ISocket(socket).connect(
            remoteChainSlug_,
            remotePlug_,
            switchboard_,
            switchboard2_
        );
    }

    function inbound(
        uint32,
        bytes calldata payload_
    ) external payable override {
        if (msg.sender != socket) revert OnlySocket();
        (bytes32 operationType, address solver, bytes32 orderId) = abi.decode(
            payload_,
            (bytes32, address, bytes32)
        );

        if (operationType == FULLFILL_ORDER_REQUEST) {
            escrow.fullFillEscrow(orderId, solver);
        } else {
            revert("SocketMarketPlace: Invalid Operation");
        }
    }

    function _outbound(
        uint32 targetChain_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes memory payload_
    ) private {
        ISocket(socket).outbound{value: msg.value}(
            targetChain_,
            minMsgGasLimit_,
            executionParams_,
            transmissionParams_,
            payload_
        );
    }

    function submitOrder(Execution memory execution) public {
        permit2.permitTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: execution.order.fromToken,
                    amount: execution.order.fromAmount
                }),
                nonce: execution.nonce,
                deadline: execution.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: execution.order.fromAmount
            }),
            msg.sender,
            execution.signature
        );
        ERC20(execution.order.fromToken).approve(
            address(escrow),
            execution.order.fromAmount
        );
        escrow.createEscrow(execution.order);
        emit OrderCreated(
            execution.order.getOrderHash(),
            execution.order.bridgePref,
            execution.order.fromToken,
            execution.order.toToken,
            execution.order.fromChainId,
            execution.order.toChainId,
            execution.order.fromAmount,
            execution.order.minAmountOut,
            execution.order.receiver,
            execution.order.sourceDeadline,
            execution.order.destinationDeadline,
            execution.order.payload
        );
    }

    function fullFillOrder(
        Order calldata order,
        uint256 amount,
        uint256 minMessageGasLimit
    ) public payable {
        // find orderId
        bytes32 orderId = order.getOrderHash();
        // check if order is fullfilled
        require(
            receipts[orderId].isFullfilled == false,
            "Order is already fullfilled"
        );
        // check if order is not expired
        require(block.timestamp < order.sourceDeadline, "Order is expired");
        // check if order is not expired
        require(
            block.timestamp < order.destinationDeadline,
            "Order is expired"
        );
        // check if amount mets condition
        require(
            amount >= order.minAmountOut,
            "Amount is less than minAmountOut"
        );

        ERC20(order.toToken).safeTransferFrom(
            msg.sender,
            order.receiver,
            order.minAmountOut
        );

        receipts[orderId] = Receipt({
            isFullfilled: true,
            amount: amount,
            token: order.toToken,
            orderTime: block.timestamp,
            solver: msg.sender,
            receiver: order.receiver
        });
        // SEND TO SOCKET
        _outbound(
            uint32(order.fromChainId),
            minMessageGasLimit,
            bytes32(0),
            bytes32(0),
            abi.encode(FULLFILL_ORDER_REQUEST, msg.sender, orderId)
        );
        emit OrderFullfilled(
            orderId,
            amount,
            order.toToken,
            block.timestamp,
            msg.sender,
            order.receiver
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
// import {Order, Execution} from "./interfaces/Orders.sol";
// import {ERC20} from "solmate/src/tokens/ERC20.sol";
// import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

// contract Escrow {
//     using SafeTransferLib for ERC20;
//     address public socketMarketPlace;
//     struct EscrowOrder {
//         address token;
//         uint256 amount;
//         address receiver;
//         uint256 destinationDeadline;
//         bool isOrderActive;
//     }
//     mapping(bytes32 => EscrowOrder) public escrows;
//     event EscrowCreated(bytes32 orderId);
//     event EscrowWithdrawn(bytes32 orderId);

//     constructor(address _socketMarketPlace) {
//         socketMarketPlace = _socketMarketPlace;
//     }

//     modifier onlySMP() {
//         require(
//             msg.sender == socketMarketPlace,
//             "Only socket MarketPlace can call"
//         );
//         _;
//     }

//     function createEscrow(Order memory order) public payable onlySMP {
//         // create escrow
//         bytes32 orderId = OrderLib.getOrderHash(order);
//         escrows[orderId] = EscrowOrder(
//             order.fromToken,
//             order.fromAmount,
//             order.receiver,
//             order.destinationDeadline,
//             true
//         );
//         ERC20(order.fromToken).safeTransferFrom(
//             socketMarketPlace,
//             address(this),
//             order.fromAmount
//         );
//         emit EscrowCreated(orderId);
//     }

//     function withDrawEscrow(bytes32 orderId) public {
//         require(
//             escrows[orderId].receiver == msg.sender,
//             "Only receiver can withdraw"
//         );
//         require(
//             escrows[orderId].destinationDeadline > block.timestamp,
//             "Deadline has passed"
//         );
//         require(escrows[orderId].isOrderActive == true, "Order is not active");
//         escrows[orderId].isOrderActive = false;
//         ERC20(escrows[orderId].token).safeTransfer(
//             msg.sender,
//             escrows[orderId].amount
//         );
//         emit EscrowWithdrawn(orderId);
//     }

//     function fullFillEscrow(
//         bytes32 orderId,
//         address solver
//     ) public payable onlySMP {
//         require(escrows[orderId].isOrderActive == true, "Order is not active");
//         escrows[orderId].isOrderActive = false;
//         ERC20(escrows[orderId].token).safeTransfer(
//             solver,
//             escrows[orderId].amount
//         );
//         emit EscrowWithdrawn(orderId);
//     }
// }

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {IPlug} from "./../interfaces/Plug.sol";
import {ISocket} from "./../interfaces/ISocket.sol";
import {BasicBridgeOrderInfo} from "./../interfaces/orders.sol";

contract BaseExtractor  {

    address public immutable socket;
     constructor(address socket_) {
       socket = socket_;
    }
    error OnlySocket();

    function setSocketConfig(
        uint32 remoteChainSlug_,
        address remotePlug_,
        address switchboard_,
        address switchboard2_
    ) external {
        ISocket(socket).connect(
            remoteChainSlug_,
            remotePlug_,
            switchboard_,
            switchboard2_
        );
    }

    function _outbound(
        uint32 targetChain_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes memory payload_
    ) internal {
        ISocket(socket).outbound{value: msg.value}(
            targetChain_,
            minMsgGasLimit_,
            executionParams_,
            transmissionParams_,
            payload_
        );
    }


}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {IExtractor} from "./../interfaces/IExtractor.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BasicBridgeOrderInfo, OrdersLib} from "./../interfaces/orders.sol";
import {IPlug} from "./../interfaces/Plug.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {BaseExtractor} from "./BaseExtractor.sol";
contract RFQExtractor is BaseExtractor, IExtractor, IPlug {
    using SafeTransferLib for ERC20;
    using OrdersLib for BasicBridgeOrderInfo;
    address public SocketProtocol;
    
    bytes32 public constant FULLFILL_ORDER_REQUEST =
        keccak256("FULLFILL_ORDER_REQUEST");


    struct EscrowOrder {
        address token;
        uint256 amount;
        address receiver;
        address sender;
        uint256 destinationDeadline;
        bool isOrderActive;
    }

    struct Receipts {
        bool isFullfilled;
        uint256 amount;
        address token;
        uint256 orderTime;
        address solver;
        address receiver;
    }

    event OrderFullfilled(
        bytes32 orderId,
        uint256 amount,
        address token,
        uint256 orderTime,
        address solver,
        address receiver
    );

    mapping(bytes32 => EscrowOrder) public escrows;
    mapping(bytes32 => Receipts) public receipts;

    constructor(address _SocketProtocol, address _socket) BaseExtractor(_socket) {
        SocketProtocol = _SocketProtocol;
    }

    function inbound(
        uint32,
        bytes calldata payload_
    ) external payable override {
        if (msg.sender != socket) revert OnlySocket();
        (
            bytes32 operationType,
            address solver,
            bytes32 orderId
        ) = abi.decode(payload_, (bytes32, address, bytes32));

        if (operationType == FULLFILL_ORDER_REQUEST) {
            completeOrder(orderId, solver);
        } else {
            revert("SocketMarketPlace: Invalid Operation");
        }
    }
    
    event EscrowCreated(bytes32 orderId);
    event EscrowWithdrawn(bytes32 orderId);

    function extract(
        BasicBridgeOrderInfo calldata order,
        bytes calldata data
    ) external override returns (bytes32 subOrderHash) {
        (uint256 inputAmount, address solver) = abi.decode(
            data,
            (uint256, address)
        );
        ERC20(order.inputToken).safeTransferFrom(
            msg.sender,
            address(this),
            order.inputAmount
        );
        bytes32 escrowId =  order.getOrderHash();
        escrows[escrowId] = EscrowOrder(
            order.inputToken,
            inputAmount,
            order.receiver,
            solver,
            order.deadline,
            true
        );
        emit EscrowCreated(escrowId);

        return escrowId;
    }

    function decodeDetails(
        bytes calldata data
    ) external pure override returns (uint256 inputAmount) {
        (uint256 _inputAmount, address solver) = abi.decode(
            data,
            (uint256, address)
        );
        return _inputAmount;
    }

    function fullFill(
        BasicBridgeOrderInfo calldata order,
        bytes calldata data,
        uint256 amount
    ) external {
        (uint256 inputAmount, uint256 outputAmount, address solver) = abi
            .decode(data, (uint256, uint256, address));

        // find orderId
        bytes32 orderId = order.getOrderHash();
        // check if order is fullfilled
        require(
            receipts[orderId].isFullfilled == false,
            "Order is already fullfilled"
        );
        // check if order is not expired
        require(block.timestamp < order.deadline, "Order is expired");

        // check if amount mets condition
        require(amount >= outputAmount, "Amount is less than minAmountOut");

        ERC20(order.outputToken).safeTransferFrom(
            msg.sender,
            order.receiver,
            order.inputAmount
        );

        receipts[orderId] =  Receipts({
            isFullfilled: true,
            amount: amount,
            token: order.outputToken,
            orderTime: block.timestamp,
            solver: msg.sender,
            receiver: order.receiver
        });

        emit OrderFullfilled(
            orderId,
            amount,
            order.outputToken,
            block.timestamp,
            msg.sender,
            order.receiver
        );

        _outbound(uint32(order.fromChainId), 121000, bytes32(0), bytes32(0), abi.encode(FULLFILL_ORDER_REQUEST, msg.sender, orderId));
    }

    function completeOrder(bytes32 orderId, address solver) public {
        require(escrows[orderId].isOrderActive == true, "Order is not active");
        escrows[orderId].isOrderActive = false;
        ERC20(escrows[orderId].token).safeTransfer(
            solver,
            escrows[orderId].amount
        );
        emit EscrowWithdrawn(orderId);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;
import {BasicBridgeOrderInfo} from "./../interfaces/orders.sol";

interface IExtractor {
 function extract(
        BasicBridgeOrderInfo calldata order,
        bytes calldata data
    ) external returns (bytes32 subOrderHash);

    function decodeDetails(
        bytes calldata payload_
    ) external view returns (uint256 inputAmount);

    function fullFill(
        BasicBridgeOrderInfo calldata order,
        bytes calldata data,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/**
 * @title ISocket
 * @notice An interface for a cross-chain communication contract
 * @dev This interface provides methods for transmitting and executing messages between chains,
 * connecting a plug to a remote chain and setting up switchboards for the message transmission
 * This interface also emits events for important operations such as message transmission, execution status,
 * and plug connection
 */
interface ISocket {
    /**
     * @notice A struct containing fees required for message transmission and execution
     * @param transmissionFees fees needed for transmission
     * @param switchboardFees fees needed by switchboard
     * @param executionFee fees needed for execution
     */
    struct Fees {
        uint128 transmissionFees;
        uint128 executionFee;
        uint128 switchboardFees;
    }

    /**
     * @title MessageDetails
     * @dev This struct defines the details of a message to be executed in a Decapacitor contract.
     */
    struct MessageDetails {
        // A unique identifier for the message.
        bytes32 msgId;
        // The fee to be paid for executing the message.
        uint256 executionFee;
        // The min amount of gas that can be used to execute the message.
        uint256 minMsgGasLimit;
        // The extra params which might provide msg value and additional info needed for message exec
        bytes32 executionParams;
        // The payload data to be executed in the message.
        bytes payload;
    }

    /**
     * @title ExecutionDetails
     * @dev This struct defines the execution details
     */
    struct ExecutionDetails {
        // packet id
        bytes32 packetId;
        // proposal count
        uint256 proposalCount;
        // gas limit needed to execute inbound
        uint256 executionGasLimit;
        // proof data required by the Decapacitor contract to verify the message's authenticity
        bytes decapacitorProof;
        // signature of executor
        bytes signature;
    }

    /**
     * @notice emits the status of message after inbound call
     * @param msgId msg id which is executed
     */
    event ExecutionSuccess(bytes32 msgId);

    /**
     * @notice emits the config set by a plug for a remoteChainSlug
     * @param plug address of plug on current chain
     * @param siblingChainSlug sibling chain slug
     * @param siblingPlug address of plug on sibling chain
     * @param inboundSwitchboard inbound switchboard (select from registered options)
     * @param outboundSwitchboard outbound switchboard (select from registered options)
     * @param capacitor capacitor selected based on outbound switchboard
     * @param decapacitor decapacitor selected based on inbound switchboard
     */
    event PlugConnected(
        address plug,
        uint32 siblingChainSlug,
        address siblingPlug,
        address inboundSwitchboard,
        address outboundSwitchboard,
        address capacitor,
        address decapacitor
    );

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param minMsgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint32 remoteChainSlug_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes calldata payload_
    ) external payable returns (bytes32 msgId);

    /**
     * @notice executes a message
     * @param executionDetails_ the packet details, proof and signature needed for message execution
     * @param messageDetails_ the message details
     */
    function execute(
        ISocket.ExecutionDetails calldata executionDetails_,
        ISocket.MessageDetails calldata messageDetails_
    ) external payable;

    /**
     * @notice seals data in capacitor for specific batchSize
     * @param batchSize_ size of batch to be sealed
     * @param capacitorAddress_ address of capacitor
     * @param signature_ signed Data needed for verification
     */
    function seal(
        uint256 batchSize_,
        address capacitorAddress_,
        bytes calldata signature_
    ) external payable;

    /**
     * @notice proposes a packet
     * @param packetId_ packet id
     * @param root_ root data
     * @param switchboard_ The address of switchboard for which this packet is proposed
     * @param signature_ signed Data needed for verification
     */
    function proposeForSwitchboard(
        bytes32 packetId_,
        bytes32 root_,
        address switchboard_,
        bytes calldata signature_
    ) external payable;

    /**
     * @notice sets the config specific to the plug
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at sibling chain to call inbound
     * @param inboundSwitchboard_ the address of switchboard to use for receiving messages
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    /**
     * @notice deploy capacitor and decapacitor for a switchboard with a specified max packet length, sibling chain slug, and capacitor type.
     * @param siblingChainSlug_ The slug of the sibling chain that the switchboard is registered with.
     * @param maxPacketLength_ The maximum length of a packet allowed by the switchboard.
     * @param capacitorType_ The type of capacitor that the switchboard uses.
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function registerSwitchboardForSibling(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_,
        address siblingSwitchboard_
    ) external returns (address capacitor, address decapacitor);

    /**
     * @notice Emits the sibling switchboard for given `siblingChainSlug_`.
     * @dev This function is expected to be only called by switchboard.
     * @dev the event emitted is tracked by transmitters to decide which switchboard a packet should be proposed on
     * @param siblingChainSlug_ The slug of the sibling chain
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function useSiblingSwitchboard(
        uint32 siblingChainSlug_,
        address siblingSwitchboard_
    ) external;

    /**
     * @notice Retrieves the packet id roots for a specified packet id.
     * @param packetId_ The packet id for which to retrieve the root.
     * @param proposalCount_ The proposal id for packetId_ for which to retrieve the root.
     * @param switchboard_ The address of switchboard for which this packet is proposed
     * @return The packet id roots for the specified packet id.
     */
    function packetIdRoots(
        bytes32 packetId_,
        uint256 proposalCount_,
        address switchboard_
    ) external view returns (bytes32);

    /**
     * @notice Retrieves the minimum fees required for a message with a specified gas limit and destination chain.
     * @param minMsgGasLimit_ The gas limit of the message.
     * @param remoteChainSlug_ The slug of the destination chain for the message.
     * @param plug_ The address of the plug through which the message is sent.
     * @return totalFees The minimum fees required for the specified message.
     */
    function getMinFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        uint32 remoteChainSlug_,
        address plug_
    ) external view returns (uint256 totalFees);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISignatureTransfer} from "lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

struct SingleOutputBridgeOrder {
    BasicBridgeOrderInfo info;
    bytes payload; // payload to be executed
    uint256 fulfillProofDeadline; // order fulfillment proof to be submitted before this deadline to receive user funds. Can be o idf proof not needed.
    bytes signature;
}

struct BasicBridgeOrderInfo {
    uint256 fromChainId;
    uint256 toChainId;
    address sender;
    address receiver; // in case of payload receiver will be the contract address where the payload has to be sent.
    address inputToken; // token
    address outputToken;
    uint256 inputAmount;
    uint256 minOutputAmount;
    uint256 deadline; // till when is the order valid.
    uint256 nonce;
}

struct SubOrder {
    uint32 extractor;
    // {
    //     ...info,
    //     solverReceiver,
    //     solver,
    //     inputAmount,
    //     outputAmount,
    // }
    bytes extractorPayload;
}

struct SubmitOrder {
    SingleOutputBridgeOrder order;
    SubOrder[] subOrders;
}

struct SetttleSubOrder {
    SingleOutputBridgeOrder order;
    SubOrder suborder;
    uint256 outputAmount;
}


library OrdersLib {
    function getOrderHash(
    BasicBridgeOrderInfo calldata info
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    info.fromChainId,
                    info.toChainId,
                    info.sender,
                    info.receiver,
                    info.inputToken,
                    info.outputToken,
                    info.inputAmount,
                    info.minOutputAmount,
                    info.deadline,
                    info.nonce
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/**
 * @title IPlug
 * @notice Interface for a plug contract that executes the message received from a source chain.
 */
interface IPlug {
    /**
     * @dev this should be only executable by socket
     * @notice executes the message received from source chain
     * @notice It is expected to have original sender checks in the destination plugs using payload
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        uint32 srcChainSlug_,
        bytes calldata payload_
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {ISignatureTransfer} from "lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {IAllowanceTransfer} from "lib/permit2/src/interfaces/IAllowanceTransfer.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ISocket} from "./interfaces/ISocket.sol";
import {IPlug} from "./interfaces/Plug.sol";
import {SubmitOrder, BasicBridgeOrderInfo, SingleOutputBridgeOrder, SubOrder, OrdersLib, SetttleSubOrder} from "./interfaces/orders.sol";
import {IExtractor} from "./interfaces/IExtractor.sol";

/**
*  Socket Market Place is market place where we join solvers and users
* user want to transfer there funds from chain 1 to chain 2 from token A 
    on chain 1 to token b on chain 2 A and B can be same as well
 */
contract SocketProtocol  {
    using SafeTransferLib for ERC20;
    using OrdersLib for BasicBridgeOrderInfo;

    error OnlySocket();

    mapping(uint32 => IExtractor) public extractors;
    mapping(bytes32 => bytes32) public subOrderToOrderMap;
    mapping(bytes32 => SubmitOrder) public submittedOrders;



    // Escrow public escrow;

    ISignatureTransfer public immutable permit2 =
        ISignatureTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);


    // function setEscrow(address escrow_) external {
    //     escrow = Escrow(escrow_);
    // }

    event OrderCreated(bytes32 orderId);
    event OrderFullfilled(bytes32 orderId);

    function setExtractor(uint32 id, address extractor) external {
        extractors[id] = IExtractor(extractor);
    }



    function executeBridgeOrder(SubmitOrder calldata submitOrder) public {
        // FIXME: change to permitTransferFromWithWitness
        permit2.permitTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: submitOrder.order.info.inputToken,
                    amount: submitOrder.order.info.inputAmount
                }),
                nonce: submitOrder.order.info.nonce,
                deadline: submitOrder.order.info.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: submitOrder.order.info.inputAmount
            }),
            submitOrder.order.info.sender,
            submitOrder.order.signature
        );

        bytes32 orderHash = submitOrder.order.info.getOrderHash();

        submittedOrders[orderHash] = submitOrder;

        for (uint i = 0; i < submitOrder.subOrders.length; i++) {
            uint256 _inputSubOrderAmount = extractors[
                submitOrder.subOrders[i].extractor
            ].decodeDetails(submitOrder.subOrders[i].extractorPayload);

            ERC20(submitOrder.order.info.inputToken).approve(
                address(extractors[submitOrder.subOrders[i].extractor]),
                _inputSubOrderAmount
            );
            bytes32 subOrderHash = extractors[
                submitOrder.subOrders[i].extractor
            ].extract(submitOrder.order.info,  submitOrder.subOrders[i].extractorPayload);
            subOrderToOrderMap[subOrderHash] = orderHash;
     
        }

        emit OrderCreated(orderHash);
    }

    function fullFillBridgeOrder(SetttleSubOrder calldata settleOrder) public {
     extractors[
            settleOrder.suborder.extractor
     ].fullFill(
                settleOrder.order.info,
                settleOrder.suborder.extractorPayload,
                settleOrder.outputAmount
            );

        emit OrderFullfilled(settleOrder.order.info.getOrderHash());

    }
}