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

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
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

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

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

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

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

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {SafeTransferLib, ERC20} from "lib/solmate/src/utils/SafeTransferLib.sol";
import "./interfaces/IFeePolicy.sol";
import "./libraries/Multicall.sol";
import "./libraries/EIP712.sol";
import "./libraries/QuotaLib.sol";

contract Gateway is EIP712("Gateway"), Multicall {
    using SafeTransferLib for ERC20;
    using QuotaLib for Quota;

    /// @dev Quota state
    mapping(bytes32 quotaHash => QuotaState state) internal _quotaStates;

    /// @notice Payer nonce, for bulk-canceling quotas (not for EIP712)
    mapping(address payer => uint96 payerNonce) public payerNonces;

    /// @notice Emit when a quota is validated
    /// @param controllerHash Hash of abi.encode(controller, controllerRefId)
    event QuotaValidated(
        bytes32 indexed quotaHash,
        address indexed payer,
        bytes32 indexed controllerHash,
        Quota quota,
        bytes quotaSignature
    );

    /// @notice Emit when a payer cancels a quota. Note that we do not check the quota's validity when it's cancelled.
    event QuotaCancelled(bytes32 indexed quotaHash);

    /// @notice Emit when a payer increments their nonce, i.e. bulk-canceling existing quotas
    event PayerNonceIncremented(address indexed payer, uint96 newNonce);

    /// @notice Emit when a charge is made
    event Charge(
        bytes32 indexed quotaHash,
        address recipient,
        uint160 amount,
        uint40 indexed cycleStartTime,
        uint160 cycleAmountUsed,
        uint24 chargeCount,
        bytes32 indexed receipt,
        Fee[] fees,
        bytes extraEventData
    );

    /// @notice Quota typehash, used for EIP712 signature
    bytes32 public constant _QUOTA_TYPEHASH = QuotaLib._QUOTA_TYPEHASH;

    /// @notice Get the state of a quota by its hash
    function getQuotaState(bytes32 quotaHash) external view returns (QuotaState memory state) {
        return _quotaStates[quotaHash];
    }

    /// @notice Validate the quota parameters with its signature.
    /// @param quota Quota
    /// @param quotaSignature Quota signature signed by the payer
    function validate(Quota memory quota, bytes memory quotaSignature) public {
        bytes32 quotaHash = quota.hash();
        QuotaState storage state = _quotaStates[quotaHash];

        if (!state.validated) {
            require(quota.payerNonce == payerNonces[quota.payer], "INVALID_PAYER_NONCE");
            if (msg.sender != quota.payer || quotaSignature.length != 0) {
                EIP712._verifySignature(quotaSignature, quotaHash, quota.payer);
            }
            state.validated = true;

            bytes32 controllerHash = keccak256(abi.encode(quota.controller, quota.controllerRefId));
            emit QuotaValidated(quotaHash, quota.payer, controllerHash, quota, quotaSignature);
        }
    }

    /// @notice Cancel quota. Only the payer or taker can cancel it.
    /// @param quota Quota. It can be not validated yet.
    function cancel(Quota memory quota) external {
        require(msg.sender == quota.payer, "NOT_ALLOWED");

        bytes32 quotaHash = quota.hash();
        _quotaStates[quotaHash].cancelled = true;
        emit QuotaCancelled(quotaHash);
    }

    /// @notice Increment a payer's nonce to bulk-cancel quotas which he/she approved to pay
    function incrementPayerNonce() external {
        payerNonces[msg.sender] += uint96(uint256(blockhash(block.number - 1)) >> 232); // add a quasi-random 24-bit number
        emit PayerNonceIncremented(msg.sender, payerNonces[msg.sender]);
    }

    /// @notice Pull token from payer to taker. Can only be called by the controller.
    /// @param quota Quota
    /// @param quotaSignature Quota signature signed by the payer. Can be empty if the quota is already validated.
    /// @param recipient Recipient of the charge
    /// @param amount Amount to charge
    /// @param fees Fees
    /// @param extraEventData Extra event data to emit
    /// @return receipt Receipt of the charge
    function charge(
        Quota memory quota,
        bytes memory quotaSignature,
        address recipient,
        uint160 amount,
        Fee[] calldata fees,
        bytes calldata extraEventData
    ) external returns (bytes32 receipt) {
        validate(quota, quotaSignature);

        require(msg.sender == quota.controller, "NOT_CONTROLLER");
        require(block.timestamp >= quota.startTime, "BEFORE_START_TIME");
        require(block.timestamp < quota.endTime, "REACHED_END_TIME");
        require(payerNonces[quota.payer] == quota.payerNonce, "PAYER_NONCE_INVALIDATED"); // ensure payer didn't bulk-cancel quota

        bytes32 quotaHash = quota.hash();
        QuotaState storage state = _quotaStates[quotaHash];

        require(!state.cancelled, "QUOTA_CANCELLED"); // ensure payer didn't cancel quota
        require(!quota.didMissCycle(state), "CYCLE_MISSED"); // ensure controller hasn't missed billing cycle

        // reset usage if new cycle starts
        if (state.chargeCount == 0 || block.timestamp - state.cycleStartTime >= quota.interval) {
            state.cycleStartTime = quota.latestCycleStartTime();
            state.cycleAmountUsed = 0;
        }
        require(uint256(state.cycleAmountUsed) + amount <= quota.amount, "EXCEEDED_QUOTA");

        // record usage
        state.cycleAmountUsed += amount;
        state.chargeCount++;

        // return a receipt (used for searching logs off-chain)
        receipt = keccak256(abi.encode(block.chainid, address(this), quotaHash, state.chargeCount));

        // emit event first, since there could be reentrancy later, and we want to keep the event order correct.
        emit Charge({
            quotaHash: quotaHash,
            recipient: recipient,
            amount: amount,
            cycleStartTime: state.cycleStartTime,
            cycleAmountUsed: state.cycleAmountUsed,
            chargeCount: state.chargeCount,
            receipt: receipt,
            fees: fees,
            extraEventData: extraEventData
        });

        // note that there could be reentrancy below, but it's safe since we already did all state changes.
        if (fees.length == 0) {
            // transfer token directly from payer to recipient if no fees
            ERC20(quota.token).safeTransferFrom(quota.payer, recipient, amount);
        } else {
            // transfer token from payer to this contract first.
            ERC20(quota.token).safeTransferFrom(quota.payer, address(this), amount);

            // send fees
            uint256 totalFees = 0;
            for (uint256 i = 0; i < fees.length; i++) {
                if (fees[i].amount == 0) continue;
                totalFees += fees[i].amount;
                require(totalFees <= amount, "INVALID_FEES");
                ERC20(quota.token).safeTransfer(fees[i].to, fees[i].amount);
            }

            // send remaining to recipient
            ERC20(quota.token).safeTransfer(recipient, amount - totalFees);
        }
    }

    /// @notice Get the status of a quota
    /// @dev Note that a quota can be cancelled but, if it's used for subscription, the subscription could still be
    // not ended yet if the current cycle has not ended yet. It depends on how the subscription implements.
    function getQuotaStatus(Quota calldata quota) public view returns (QuotaStatus status) {
        QuotaState memory state = _quotaStates[quota.hash()];

        // forgefmt:disable-next-item
        bool isCancelled = block.timestamp >= quota.endTime
            || quota.didMissCycle(state)
            || state.cancelled
            || payerNonces[quota.payer] > quota.payerNonce;

        if (isCancelled) return QuotaStatus.Cancelled;
        if (block.timestamp < quota.startTime) return QuotaStatus.NotStarted;
        if (quota.didChargeLatestCycle(state)) return QuotaStatus.Active;
        return state.chargeCount == 0 ? QuotaStatus.PendingFirstCharge : QuotaStatus.PendingNextCharge;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "../libraries/QuotaLib.sol";

struct Fee {
    address to;
    uint160 amount;
}

interface IFeePolicy {
    function getFees(Quota calldata quota, uint160 chargeAmount, address chargeCaller)
        external
        view
        returns (Fee[] memory fees);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @notice EIP712 helpers
 * @dev Modified fork from Uniswap (https://github.com/Uniswap/permit2/blob/main/src/EIP712.sol)
 */
abstract contract EIP712 {
    // Cache the domain separator as an immutable value, but also store the chain id that it
    // corresponds to, in order to invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    bytes32 private immutable _HASHED_NAME;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    constructor(string memory name) {
        _HASHED_NAME = keccak256(bytes(name));
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME);
    }

    /// @notice Returns the domain separator for the current chain.
    /// @dev Uses cached version if chainid and address are unchanged from construction.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == _CACHED_CHAIN_ID
            ? _CACHED_DOMAIN_SEPARATOR
            : _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME);
    }

    /// @notice Builds a domain separator using the current chainId and contract address.
    function _buildDomainSeparator(bytes32 typeHash, bytes32 nameHash) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, block.chainid, address(this)));
    }

    /// @notice Creates an EIP-712 typed data hash
    function _hashTypedData(bytes32 dataHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), dataHash));
    }

    /// @notice Verify signature for EIP-712 typed data
    function _verifySignature(bytes memory signature, bytes32 dataHash, address claimedSigner) internal view {
        SignatureVerification.verify(signature, _hashTypedData(dataHash), claimedSigner);
    }
}

/**
 * @dev Direct fork from Uniswap (https://github.com/Uniswap/permit2/blob/main/src/libraries/SignatureVerification.sol)
 */
library SignatureVerification {
    /// @notice Thrown when the passed in signature is not a valid length
    error InvalidSignatureLength();

    /// @notice Thrown when the recovered signer is equal to the zero address
    error InvalidSignature();

    /// @notice Thrown when the recovered signer does not equal the claimedSigner
    error InvalidSigner();

    /// @notice Thrown when the recovered contract signature is incorrect
    error InvalidContractSignature();

    bytes32 constant UPPER_BIT_MASK = (0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    function verify(bytes memory signature, bytes32 digest, address claimedSigner) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (claimedSigner.code.length == 0) {
            if (signature.length == 65) {
                (r, s) = abi.decode(signature, (bytes32, bytes32));
                v = uint8(signature[64]);
            } else if (signature.length == 64) {
                // EIP-2098
                bytes32 vs;
                (r, vs) = abi.decode(signature, (bytes32, bytes32));
                s = vs & UPPER_BIT_MASK;
                v = uint8(uint256(vs >> 255)) + 27;
            } else {
                revert InvalidSignatureLength();
            }
            address signer = ecrecover(digest, v, r, s);
            if (signer == address(0)) revert InvalidSignature();
            if (signer != claimedSigner) revert InvalidSigner();
        } else {
            bytes4 magicValue = IERC1271(claimedSigner).isValidSignature(digest, signature);
            if (magicValue != IERC1271.isValidSignature.selector) revert InvalidContractSignature();
        }
    }
}

interface IERC1271 {
    /// @dev Should return whether the signature provided is valid for the provided data
    /// @param hash      Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    /// @return magicValue The bytes4 magic value 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

abstract contract Multicall {
    error CallError(uint256 index, bytes errorData);

    /// @notice Call multiple methods in a single transaction
    /// @param data Array of encoded function calls
    /// @return results Array of returned data
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            bool success;
            (success, results[i]) = address(this).delegatecall(data[i]);
            if (!success) revert CallError(i, results[i]);
        }
    }

    // ----- common utils to use in multicall -----

    /// @notice Permit any ERC20 token
    function permitERC20(
        address token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        ERC20(token).permit(owner, spender, value, deadline, v, r, s);
    }

    /// @notice Permit DAI
    function permitDAI(
        address dai, //
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        IDAIPermit(dai).permit(owner, spender, ERC20(dai).nonces(owner), deadline, true, v, r, s);
    }

    /// @notice Get value of a storage slot
    function getStorageSlot(bytes32 slot) public view returns (bytes32 value) {
        assembly ("memory-safe") {
            value := sload(slot)
        }
    }
}

interface IDAIPermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
 * `Quota` is a token allowance that a payer grants to a controller. The controller can pull token from the payer
 * address periodically according to the schedule defined in the quota.
 *
 * To protect payers, if the controller misses a charge cycle, the quota will be automatically cancelled.
 * Also, payers can revoke their approved quotas at any time.
 */
struct Quota {
    // payer info
    address payer; //           slot 0
    uint96 payerNonce;
    // token amount
    address token; //           slot 1
    uint160 amount; //          slot 2
    // charge schedule
    uint40 startTime;
    uint40 endTime;
    uint40 interval; //         slot 3
    uint40 chargeWindow;
    // controller info
    address controller;
    bytes32 controllerRefId; // slot 4
}

struct QuotaState {
    bool validated;
    bool cancelled; // by payer
    uint40 cycleStartTime;
    uint160 cycleAmountUsed;
    uint24 chargeCount;
}

enum QuotaStatus {
    NotStarted,
    PendingFirstCharge,
    Active,
    PendingNextCharge,
    Cancelled
}

library QuotaLib {
    bytes32 internal constant _QUOTA_TYPEHASH = keccak256(
        "Quota(address payer,uint96 payerNonce,address token,uint160 amount,uint40 startTime,uint40 endTime,uint40 interval,uint40 chargeWindow,address controller,bytes32 controllerRefId)"
    );

    function hash(Quota memory quota) internal pure returns (bytes32 quotaHash) {
        return keccak256(abi.encode(_QUOTA_TYPEHASH, quota));
    }

    /// @notice Calculate the start time of the quota's latest possible cycle
    /// @dev Assumed now >= quota.startTime, or else it reverts. Also, end time is not checked here.
    function latestCycleStartTime(Quota memory quota) internal view returns (uint40) {
        return quota.startTime + (((uint40(block.timestamp) - quota.startTime) / quota.interval) * quota.interval);
    }

    /// @notice Check whether the quota's latest cycle has been charged once
    function didChargeLatestCycle(Quota memory quota, QuotaState memory state) internal view returns (bool) {
        return state.chargeCount != 0 && uint256(state.cycleStartTime) + quota.interval > block.timestamp;
    }

    /// @notice Check whether the quota has missed any billing cycle
    function didMissCycle(Quota memory quota, QuotaState memory state) internal view returns (bool) {
        return state.chargeCount == 0
            ? uint256(quota.startTime) + quota.chargeWindow <= block.timestamp
            : uint256(state.cycleStartTime) + quota.interval + quota.chargeWindow <= block.timestamp;
    }

    /// @notice Calcuate the end time of the quota's current cycle, i.e. the cycle that the last charge happened in.
    function currentCycleEndTime(Quota memory quota, QuotaState memory state) internal pure returns (uint40) {
        uint256 endTime = uint256(state.cycleStartTime) + quota.interval;
        return endTime > type(uint40).max ? type(uint40).max : uint40(endTime); // truncate to uint40
    }
}