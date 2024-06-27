// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {BaseRouter} from "./BaseRouter.sol";
import {FulfilExec, ExtractExec} from "../common/BungeeStructs.sol";
import {BungeeEvents} from "../common/BungeeEvents.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IFeeCollector} from "../interfaces/IFeeCollector.sol";
import {InsufficientNativeAmount} from "../common/BungeeErrors.sol";

// Follows IRouter
// @todo create Router.sol that routers implement
contract RFQRouter is BaseRouter, BungeeEvents, Ownable {
    constructor(address _bungeeGateway, address _owner) Ownable(_owner) BaseRouter(_bungeeGateway) {}

    // execute the function
    function _execute(
        uint256 amount,
        address inputToken,
        bytes32 requestHash,
        uint256 expiry,
        address receiverContract,
        ExtractExec calldata exec
    ) internal override {
        // Do nothing, not needed.
    }

    // Called by Bungee on the destination chain to fulfill requests
    function _fulfil(bytes32 requestHash, FulfilExec calldata fulfillExec, address transmitter) internal override {
        // Transfer fulfilAmounts from transmitter to user
        for (uint256 i = 0; i < fulfillExec.fulfilAmounts.length; i++) {
            if (
                fulfillExec.request.basicReq.outputTokens[i] == NATIVE_TOKEN_ADDRESS &&
                fulfillExec.fulfilAmounts[i] > msg.value
            ) revert InsufficientNativeAmount();

            // Send the tokens in the exec to the receiver.
            _sendFundsToReceiver({
                token: fulfillExec.request.basicReq.outputTokens[i],
                from: transmitter,
                amount: fulfillExec.fulfilAmounts[i],
                to: fulfillExec.request.basicReq.receiver
            });
        }

        emit RequestFulfilled(requestHash, transmitter, abi.encode(fulfillExec));
    }

    /// @dev can only be called by BungeeGateways
    function _releaseFunds(address token, uint256 amount, address recipient) internal override {
        // Send the tokens in the exec to the receiver.
        _sendFundsFromContract(token, amount, recipient);
    }

    function _collectFee(
        address token,
        uint256 amount,
        address feeTaker,
        address feeCollector,
        bytes32 requestHash
    ) internal override {
        _sendFundsFromContract(token, amount, feeCollector);
        IFeeCollector(feeCollector).registerFee(feeTaker, amount, token, requestHash);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Request, FulfilExec, ExtractExec} from "../common/BungeeStructs.sol";
import {IBungeeGateway} from "../interfaces/IBungeeGateway.sol";
import {TransferFailed} from "../common/BungeeErrors.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {CallerNotBungeeGateway} from "../common/BungeeErrors.sol";
import {AffiliateFeesLib} from "../lib/AffiliateFeesLib.sol";

// Abstract Contract implemented by Routers
abstract contract BaseRouter {
    using SafeTransferLib for ERC20;

    // BungeeGateway Contract
    IBungeeGateway public immutable BUNGEE_GATEWAY;

    /// @notice address to identify the native token
    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _bungeeGateway) {
        BUNGEE_GATEWAY = IBungeeGateway(_bungeeGateway);
    }

    /// @dev can only be called by BungeeGateway
    function execute(
        uint256 amount,
        address inputToken,
        bytes32 requestHash,
        uint256 expiry,
        address receiverContract,
        address feeCollector,
        ExtractExec calldata exec
    ) external {
        // Should only be called by Bungee contract
        if (msg.sender != address(BUNGEE_GATEWAY)) revert CallerNotBungeeGateway();

        // Check if fee is supposed to be deducted
        (uint256 bridgeAmount, uint256 feeAmount, address feeTaker) = AffiliateFeesLib.getAffiliateFees(
            amount,
            exec.request.affiliateFees
        );

        _collectFee(inputToken, feeAmount, feeTaker, feeCollector, requestHash);
        _execute(bridgeAmount, inputToken, requestHash, expiry, receiverContract, exec);
    }

    /// @dev can only be called by BungeeGateway
    function fulfil(bytes32 requestHash, FulfilExec calldata fulfillExec, address transmitter) external payable {
        // Should only be called by Bungee contract
        if (msg.sender != address(BUNGEE_GATEWAY)) revert CallerNotBungeeGateway();

        _fulfil(requestHash, fulfillExec, transmitter);
    }

    function withdrawRequestOnDestination(Request calldata request, bytes calldata withdrawRequestData) external {
        // Should only be called by Bungee contract
        if (msg.sender != address(BUNGEE_GATEWAY)) revert CallerNotBungeeGateway();

        _withdrawRequestOnDestination(request, withdrawRequestData);
    }

    /// @dev can only be called by BungeeGateways
    function releaseFunds(address token, uint256 amount, address recipient) external {
        // Should only be called by Bungee contract
        if (msg.sender != address(BUNGEE_GATEWAY)) revert CallerNotBungeeGateway();
        // Send the tokens in the exec to the receiver.
        _releaseFunds(token, amount, recipient);
    }

    /// @dev internal function for fulfil that every router needs to implement
    function _fulfil(bytes32 requestHash, FulfilExec calldata fulfillExec, address transmitter) internal virtual {}

    /// @dev internal function for executing the route every router needs to implement
    function _execute(
        uint256 amount,
        address inputToken,
        bytes32 requestHash,
        uint256 expiry,
        address receiverContract,
        ExtractExec calldata exec
    ) internal virtual {}

    /// @dev can only be called by BungeeGateways
    function _releaseFunds(address token, uint256 amount, address recipient) internal virtual {}

    function _collectFee(
        address token,
        uint256 amount,
        address feeTaker,
        address feeCollector,
        bytes32 requestHash
    ) internal virtual {}

    function _withdrawRequestOnDestination(
        Request calldata request,
        bytes calldata withdrawRequestData
    ) internal virtual {}

    /**
     * @dev send funds from an address to the provided address.
     * @param token address of the token
     * @param from atomic execution.
     * @param amount hash of the command.
     * @param to address, funds will be transferred to this address.
     */
    function _sendFundsToReceiver(address token, address from, uint256 amount, address to) internal {
        /// native token case
        if (token == NATIVE_TOKEN_ADDRESS) {
            (bool success, ) = to.call{value: amount, gas: 5000}("");
            if (!success) revert TransferFailed();
            return;
        }
        /// ERC20 case
        ERC20(token).safeTransferFrom(from, to, amount);
    }

    /**
     * @dev send funds to the provided address.
     * @param token address of the token
     * @param amount hash of the command.
     * @param to address, funds will be transferred to this address.
     */
    function _sendFundsFromContract(address token, uint256 amount, address to) internal {
        /// native token case
        if (token == NATIVE_TOKEN_ADDRESS) {
            (bool success, ) = to.call{value: amount, gas: 5000}("");
            if (!success) revert TransferFailed();
            return;
        }

        /// ERC20 case
        ERC20(token).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Basic details in the request
struct BasicRequest {
    // src chain id
    uint256 originChainId;
    // dest chain id
    uint256 destinationChainId;
    // deadline of the request
    uint256 deadline;
    // nonce used for uniqueness in signature
    uint256 nonce;
    // address of the user placing the request.
    address sender;
    // address of the receiver on destination chain
    address receiver;
    // delegate address that has some rights over the request signed
    address delegate;
    // address of bungee gateway, this address will have access to pull funds from the sender.
    address bungeeGateway;
    // id of the switchboard
    uint32 switchboardId;
    // address of the input token
    address inputToken;
    // amount of the input tokens
    uint256 inputAmount;
    // array of output tokens to be received on the destination.
    address[] outputTokens;
    // array of minimum amounts to be receive on the destination for the output tokens array.
    uint256[] minOutputAmounts;
}

// The Request which user signs
struct Request {
    // basic details in the request.
    BasicRequest basicReq;
    // swap putput token that the user is okay with swapping input token to.
    address swapOutputToken;
    // minimum swap output the user is okay with swapping the input token to.
    // Transmitter can choose or not choose to swap tokens.
    uint256 minSwapOutput;
    // calldata execution parameter. Only to be used when execution is required on destination.
    // minimum dest gas limit to execute calldata on destination
    uint256 minDestGas;
    // array of addresses to check if request whitelists only certain transmitters
    address[] exclusiveTransmitters;
    // array of addresses to check if request whitelists only certain routers
    address[] exclusiveRouters;
    // any sort of metadata to be passed with the request
    bytes32 metadata;
    // fees of the affiliate if any
    bytes affiliateFees;
    // calldata to be executed on the destination
    // callata can only be executed on the receiver in the request.
    bytes destinationCalldata; //@todo rename to payload
}

// Transmitter's origin chain execution details for a request with promisedAmounts.
struct ExtractExec {
    // User signed Request
    Request request;
    // address of the router being used for the request.
    address router;
    // array of promised amounts for the corresponding output tokens on the destination
    uint256[] promisedAmounts;
    // RouterPayload (router specific data) + RouterValue (value required by the router) etc etc
    bytes routerData;
    // swapPayload 0x00 if no swap is involved.
    bytes swapPayload;
    // swapRouterAddress
    address swapRouter;
    // user signature against the request
    bytes userSignature;
    // address of the beneficiary submitted by the transmitter.
    // the beneficiary will be the one receiving locked tokens when a request is settled.
    address beneficiary;
}

// Batch of executions on the origin chain signed by MOFA.
struct SignedBatch {
    // Array of extraction executions
    ExtractExec[] extractExecs;
}

// Transmitter's destination chain execution details with fulfil amounts.
struct FulfilExec {
    // User Signed Request
    Request request;
    // address of the router
    address fulfilRouter;
    // amounts to be sent to the receiver for the corresponing output tokens.
    uint256[] fulfilAmounts;
    // extraPayload for router.
    bytes routerData;
    // total msg.value to be sent to fulfil native token output token
    uint256 msgValue;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BungeeEvents {
    /// @notice Emitted when a request is extracted
    /// @param requestHash hash of the request
    /// @param transmitter address of the transmitter
    /// @param execution encoded execution data
    event RequestExtracted(bytes32 indexed requestHash, address transmitter, bytes execution);

    /// @notice Emitted when a request is fulfilled
    /// @param requestHash hash of the request
    /// @param fulfiller address of the fulfiller
    /// @param execution encoded execution data
    event RequestFulfilled(bytes32 indexed requestHash, address fulfiller, bytes execution);

    // emitted on the source once settlement completes
    /// @param requestHash hash of the request
    event RequestSettled(bytes32 indexed requestHash);

    /// @notice Emitted on the originChain when a request is withdrawn beyond fulfillment deadline
    /// @param requestHash hash of the request
    /// @param token token being withdrawn
    /// @param amount amount being withdrawn
    /// @param to address of the recipient
    event WithdrawOnOrigin(bytes32 indexed requestHash, address token, uint256 amount, address to);

    /// @notice Emitted on the destinationChain when a request is withdrawn if transmitter fails to fulfil
    /// @param requestHash hash of the request
    /// @param token token being withdrawn
    /// @param amount amount being withdrawn
    /// @param to address of the recipient
    event WithdrawOnDestination(bytes32 indexed requestHash, address token, uint256 amount, address to);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {OnlyOwner, OnlyNominee} from "../common/BungeeErrors.sol";

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function nominee() public view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) {
            revert OnlyNominee();
        }
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IFeeCollector {
    function registerFee(address feeTaker, uint256 feeAmount, address feeToken) external;
    function registerFee(address feeTaker, uint256 feeAmount, address feeToken, bytes32 requestHash) external;
    function settleFee(bytes32 requestHash) external;
    function refundFee(bytes32 requestHash, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//

error MofaSignatureInvalid();
error InsufficientNativeAmount();

error FulfillmentChainInvalid();
error RequestAlreadyFulfilled();
error RouterNotRegistered();

error TransferFailed();
error CallerNotBungeeGateway();

error NoExecutionCacheFound();
error ExecutionCacheFailed();
error SwapOutputInsufficient();

error UnsupportedDestinationChainId();

error MinOutputNotMet();

error OnlyOwner();
error OnlyNominee();

error InvalidRequest();
error FulfillmentDeadlineNotMet();
error CallerNotDelegate();

error BungeeSiblingDoesNotExist();
error InvalidMsg();

error NotDelegate();
error RequestProcessed();
error RequestNotProcessed();

error InvalidSwitchboard();
error PromisedAmountNotMet();

error MsgReceiveFailed();

error RouterAlreadyWhitelisted();
error InvalidStake();
error RouterAlreadyRegistered();

error InvalidFulfil();

error InsufficientCapacity();

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IBungeeGateway {
    function setWhitelistedReceiver(address receiver, uint256 destinationChainId, address router) external;

    function getWhitelistedReceiver(address router, uint256 destinationChainId) external view returns (address);

    function inboundMsgFromSwitchboard(
        uint8 msgId,
        uint32 siblingChainId,
        uint32 switchboardId,
        bytes calldata payload
    ) external;

    function isBungeeRouter(address router) external view returns (bool);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {ERC20, SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {BytesLib} from "./BytesLib.sol";

/// @notice helpers for AffiliateFees struct
library AffiliateFeesLib {
    /// @notice SafeTransferLib - library for safe and optimized operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    /// @notice error when affiliate fee length is wrong
    error WrongAffiliateFeeLength();

    /// @notice event emitted when affiliate fee is deducted
    event AffiliateFeeDeducted(address feeToken, address feeTakerAddress, uint256 feeAmount);

    // Precision used for affiliate fee calculation
    uint256 internal constant PRECISION = 10000000000000000;

    /**
     * @dev calculates & transfers fee to feeTakerAddress
     * @param bridgingAmount amount to be bridged
     * @param affiliateFees packed bytes containing feeTakerAddress and feeInBps
     *                      ensure the affiliateFees is packed as follows:
     *                      address feeTakerAddress (20 bytes) + uint48 feeInBps (6 bytes) = 26 bytes
     * @return bridgingAmount after deducting affiliate fees
     */
    function getAffiliateFees(
        uint256 bridgingAmount,
        bytes memory affiliateFees
    ) internal pure returns (uint256, uint256, address) {
        address feeTakerAddress;
        uint256 feeAmount = 0;
        if (affiliateFees.length > 0) {
            uint48 feeInBps;

            if (affiliateFees.length != 26) revert WrongAffiliateFeeLength();

            feeInBps = BytesLib.toUint48(affiliateFees, 20);
            feeTakerAddress = BytesLib.toAddress(affiliateFees, 0);

            if (feeInBps > 0) {
                // calculate fee
                feeAmount = ((bridgingAmount * feeInBps) / PRECISION);
                bridgingAmount -= feeAmount;
            }
        }

        return (bridgingAmount, feeAmount, feeTakerAddress);
    }

    function getAmountAfterFee(uint256 bridgingAmount, bytes memory affiliateFees) internal pure returns (uint256) {
        address feeTakerAddress;
        uint256 feeAmount = 0;
        if (affiliateFees.length > 0) {
            uint48 feeInBps;

            if (affiliateFees.length != 26) revert WrongAffiliateFeeLength();

            feeInBps = BytesLib.toUint48(affiliateFees, 20);
            feeTakerAddress = BytesLib.toAddress(affiliateFees, 0);

            if (feeInBps > 0) {
                // calculate fee
                feeAmount = ((bridgingAmount * feeInBps) / PRECISION);
                bridgingAmount -= feeAmount;
            }
        }

        return (bridgingAmount);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.4 <0.9.0;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint48(bytes memory _bytes, uint256 _start) internal pure returns (uint48) {
        require(_bytes.length >= _start + 6, "toUint48_outOfBounds");
        uint48 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x6), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equal_nonAligned(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let endMinusWord := add(_preBytes, length)
                let mc := add(_preBytes, 0x20)
                let cc := add(_postBytes, 0x20)

                for {
                    // the next line is the loop condition:
                    // while(uint256(mc < endWord) + cb == 2)
                } eq(add(lt(mc, endMinusWord), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }

                // Only if still successful
                // For <1 word tail bytes
                if gt(success, 0) {
                    // Get the remainder of length/32
                    // length % 32 = AND(length, 32 - 1)
                    let numTailBytes := and(length, 0x1f)
                    let mcRem := mload(mc)
                    let ccRem := mload(cc)
                    for {
                        let i := 0
                        // the next line is the loop condition:
                        // while(uint256(i < numTailBytes) + cb == 2)
                    } eq(add(lt(i, numTailBytes), cb), 2) {
                        i := add(i, 1)
                    } {
                        if iszero(eq(byte(i, mcRem), byte(i, ccRem))) {
                            // unsuccess:
                            success := 0
                            cb := 0
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}