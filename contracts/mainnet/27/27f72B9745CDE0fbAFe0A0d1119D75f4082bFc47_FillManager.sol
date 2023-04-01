// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC20/utils/SafeERC20.sol";
import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "./LpWhitelist.sol";
import "../interfaces/IMessenger.sol";
import "./BeamerUtils.sol";
import "./Resolver.sol";

/// The fill manager.
///
/// This contract is responsible for keeping track of filled requests. In addition to allowing
/// agents to (eventually) prove that they filled requests, it also allows anyone to invalidate
/// a claim that a request was filled.
///
/// It is the only contract that agents need to interact with on the target chain.
contract FillManager is Ownable, LpWhitelist {
    using SafeERC20 for IERC20;

    /// Emitted when a request has been filled.
    ///
    /// .. seealso:: :sol:func:`fillRequest`
    event RequestFilled(
        bytes32 indexed requestId,
        bytes32 fillId,
        uint256 indexed sourceChainId,
        address indexed targetTokenAddress,
        address filler,
        uint256 amount
    );

    /// Emitted when a fill has been invalidated.
    ///
    /// .. seealso:: :sol:func:`invalidateFill`
    event FillInvalidated(bytes32 indexed requestId, bytes32 indexed fillId);

    // The messenger to send messages to L1
    //
    // It is used to send proofs to L1. The specific implementation of the
    // :sol:interface:`IMessenger` interface is chain-dependent.
    IMessenger public immutable messenger;

    /// The L1 :sol:contract:`Resolver` contract to be used for L1 resolution.
    address public l1Resolver;

    /// Maps request IDs to fill IDs.
    mapping(bytes32 requestID => bytes32 fillId) public fills;

    /// Constructor.
    ///
    /// @param _messenger The messenger.
    constructor(address _messenger) {
        messenger = IMessenger(_messenger);
    }

    /// Set the resolver's address
    ///
    /// Can only ever be set once. Before it is set, no fills or invalidations are possible
    ///
    /// @param _l1Resolver The L1 resolver address
    function setResolver(address _l1Resolver) public onlyOwner {
        require(l1Resolver == address(0), "Resolver already set");
        l1Resolver = _l1Resolver;
    }

    /// Fill the specified request.
    ///
    /// The caller must have approved at least ``amount`` tokens for :sol:contract:`FillManager`
    /// with the ERC20 token contract at ``targetTokenAddress``. The tokens will be immediately
    /// sent to ``targetReceiverAddress`` and a fill proof will be generated, which can later
    /// be used to trigger L1 resolution, if needed.
    ///
    /// @param sourceChainId The source chain ID.
    /// @param targetTokenAddress Address of the token contract on the target chain.
    /// @param targetReceiverAddress Recipient address on the target chain.
    /// @param amount Amount of tokens to transfer. Does not include fees.
    /// @param nonce The nonce used to create the request ID.
    /// @return The fill ID.
    function fillRequest(
        uint256 sourceChainId,
        address targetTokenAddress,
        address targetReceiverAddress,
        uint256 amount,
        uint96 nonce
    ) external onlyAllowed(msg.sender) returns (bytes32) {
        address _l1Resolver = l1Resolver;
        require(_l1Resolver != address(0), "Resolver address not set");
        bytes32 requestId = BeamerUtils.createRequestId(
            sourceChainId,
            block.chainid,
            targetTokenAddress,
            targetReceiverAddress,
            amount,
            nonce
        );

        require(fills[requestId] == bytes32(0), "Already filled");

        IERC20(targetTokenAddress).safeTransferFrom(
            msg.sender,
            targetReceiverAddress,
            amount
        );

        bytes32 fillId = generateFillId();
        fills[requestId] = fillId;

        messenger.sendMessage(
            _l1Resolver,
            abi.encodeCall(
                Resolver.resolve,
                (requestId, fillId, block.chainid, sourceChainId, msg.sender)
            )
        );

        emit RequestFilled(
            requestId,
            fillId,
            sourceChainId,
            targetTokenAddress,
            msg.sender,
            amount
        );

        return fillId;
    }

    /// Invalidate the specified fill.
    ///
    /// In cases that a claim has been made on the source chain, but without a corresponding fill
    /// actually happening on the target chain, anyone can call this function to mark the fill
    /// as invalid. This is typically followed by a challenge game on the source chain, which
    /// the dishonest claimer is guaranteed to lose as soon as the information about the invalid
    /// fill (so called "non-fill proof") is propagated to the source chain via L1 resolution.
    ///
    /// @param requestId The request ID.
    /// @param fillId The fill ID.
    /// @param sourceChainId The source chain ID.
    function invalidateFill(
        bytes32 requestId,
        bytes32 fillId,
        uint256 sourceChainId
    ) external {
        address _l1Resolver = l1Resolver;
        require(_l1Resolver != address(0), "Resolver address not set");
        require(fills[requestId] != fillId, "Fill valid");
        require(
            fillId != generateFillId(),
            "Cannot invalidate fills of current block"
        );

        messenger.sendMessage(
            _l1Resolver,
            abi.encodeCall(
                Resolver.resolve,
                (requestId, fillId, block.chainid, sourceChainId, address(0))
            )
        );
        emit FillInvalidated(requestId, fillId);
    }

    /// Generate a fill ID.
    ///
    /// The fill ID is defined as the previous block hash.
    ///
    /// @return The current fill ID
    function generateFillId() private view returns (bytes32) {
        return blockhash(block.number - 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";

/// Liquidity Provider Whitelist.
///
/// This contract describes the concept of a whitelist for allowed Lps. RequestManager and FillManager
/// inherit from this contract.
contract LpWhitelist is Ownable {
    /// Emitted when a liquidity provider has been added to the set of allowed
    /// liquidity providers.
    ///
    /// .. seealso:: :sol:func:`addAllowedLp`
    event LpAdded(address lp);

    /// Emitted when a liquidity provider has been removed from the set of allowed
    /// liquidity providers.
    ///
    /// .. seealso:: :sol:func:`removeAllowedLp`
    event LpRemoved(address lp);

    /// The mapping containing addresses allowed to provide liquidity.
    mapping(address lp => bool allowed) public allowedLps;

    /// Modifier to check whether the passed address is an allowed LP
    modifier onlyAllowed(address addressToCheck) {
        require(allowedLps[addressToCheck], "Not allowed");
        _;
    }

    /// Add a liquidity provider to the set of allowed liquidity providers.
    ///
    /// .. note:: This function can only be called by the contract owner.
    ///
    /// @param newLp The liquidity provider.
    function addAllowedLp(address newLp) public onlyOwner {
        allowedLps[newLp] = true;

        emit LpAdded(newLp);
    }

    /// Remove a liquidity provider from the set of allowed liquidity providers.
    ///
    /// .. note:: This function can only be called by the contract owner.
    ///
    /// @param oldLp The liquidity provider.
    function removeAllowedLp(address oldLp) public onlyOwner {
        delete allowedLps[oldLp];

        emit LpRemoved(oldLp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// The messenger interface.
///
/// Implementations of this interface are expected to transport
/// messages across the L1 <-> L2 boundary. For instance,
/// if an implementation is deployed on L1, the :sol:func:`sendMessage`
/// would send a message to a L2 chain, as determined by the implementation.
/// In order to do this, a messenger implementation may use a native
/// messenger contract. In such cases, :sol:func:`nativeMessenger` must
/// return the address of the native messenger contract.
interface IMessenger {
    /// Send a message across the L1 <-> L2 boundary.
    ///
    /// @param target The message recipient.
    /// @param message The message.
    function sendMessage(address target, bytes calldata message) external;

    /// Return whether the call is allowed or not.
    ///
    /// @param caller The caller.
    /// @param courier The contract that is trying to deliver the message.
    function callAllowed(
        address caller,
        address courier
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "../interfaces/IMessenger.sol";
import "./RequestManager.sol";
import "./RestrictedCalls.sol";

/// The resolver.
///
/// This contract resides on the L1 chain and is tasked with receiving the
/// fill or non-fill proofs from the target L2 chain and forwarding them to
/// the :sol:contract:`RequestManager` on the source L2 chain.
contract Resolver is Ownable, RestrictedCalls {
    struct SourceChainInfo {
        address requestManager;
        address messenger;
    }

    /// Emitted when a fill or a non-fill proof is received and sent to the request manager.
    ///
    /// .. note:: In case of a non-fill proof, the ``filler`` will be zero.
    event Resolution(
        uint256 sourceChainId,
        uint256 fillChainId,
        bytes32 requestId,
        address filler,
        bytes32 fillId
    );

    /// Maps source chain IDs to source chain infos.
    mapping(uint256 sourceChainId => SourceChainInfo) public sourceChainInfos;

    /// Resolve the specified request.
    ///
    /// This marks the request identified by ``requestId`` as filled by ``filler``.
    /// If the ``filler`` is zero, the fill will be marked invalid.
    ///
    /// Information about the fill will be sent to the source chain's :sol:contract:`RequestManager`,
    /// using the messenger responsible for the source chain.
    ///
    /// .. note::
    ///
    ///     This function is callable only by the native L1 messenger contract,
    ///     which simply delivers the message sent from the target chain by the
    ///     Beamer's L2 :sol:interface:`messenger <IMessenger>` contract.
    ///
    /// @param requestId The request ID.
    /// @param fillId The fill ID.
    /// @param fillChainId The fill (target) chain ID.
    /// @param sourceChainId The source chain ID.
    /// @param filler The address that filled the request, or zero to invalidate the fill.
    function resolve(
        bytes32 requestId,
        bytes32 fillId,
        uint256 fillChainId,
        uint256 sourceChainId,
        address filler
    ) external restricted(fillChainId) {
        SourceChainInfo memory info = sourceChainInfos[sourceChainId];
        require(
            info.requestManager != address(0),
            "No request manager available for source chain"
        );
        require(
            info.messenger != address(0),
            "No messenger available for source chain"
        );

        bytes memory message;

        if (filler == address(0)) {
            message = abi.encodeCall(
                RequestManager.invalidateFill,
                (requestId, fillId, block.chainid)
            );
        } else {
            message = abi.encodeCall(
                RequestManager.resolveRequest,
                (requestId, fillId, block.chainid, filler)
            );
        }

        IMessenger messenger = IMessenger(info.messenger);
        messenger.sendMessage(info.requestManager, message);

        emit Resolution(sourceChainId, fillChainId, requestId, filler, fillId);
    }

    /// Add a request manager.
    ///
    /// In order to be able to send messages to the :sol:contract:`RequestManager`,
    /// the resolver contract needs to know the address of the request manager on the source
    /// chain, as well as the address of the messenger contract responsible for
    /// transferring messages to the L2 chain.
    ///
    /// .. note:: This function can only be called by the contract owner.
    ///
    /// @param chainId The source L2 chain ID.
    /// @param requestManager The request manager.
    /// @param messenger The messenger contract responsible for chain ``chainId``.
    ///                  Must implement :sol:interface:`IMessenger`.
    function addRequestManager(
        uint256 chainId,
        address requestManager,
        address messenger
    ) external onlyOwner {
        sourceChainInfos[chainId] = SourceChainInfo(requestManager, messenger);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "../interfaces/IMessenger.sol";

/// A helper contract that provides a way to restrict callers of restricted functions
/// to a single address. This allows for a trusted call chain,
/// as described in :ref:`contracts' architecture <contracts-architecture>`.
contract RestrictedCalls is Ownable {
    /// Maps caller chain IDs to tuples [caller, messenger].
    ///
    /// For same-chain calls, the messenger address is 0x0.
    mapping(uint256 callerChainId => address[2]) public callers;

    function _addCaller(
        uint256 callerChainId,
        address caller,
        address messenger
    ) internal {
        require(caller != address(0), "RestrictedCalls: caller cannot be 0");
        require(
            callers[callerChainId][0] == address(0),
            "RestrictedCalls: caller already exists"
        );
        callers[callerChainId] = [caller, messenger];
    }

    /// Allow calls from an address on the same chain.
    ///
    /// @param caller The caller.
    function addCaller(address caller) external onlyOwner {
        _addCaller(block.chainid, caller, address(0));
    }

    /// Allow calls from an address on another chain.
    ///
    /// @param callerChainId The caller's chain ID.
    /// @param caller The caller.
    /// @param messenger The messenger.
    function addCaller(
        uint256 callerChainId,
        address caller,
        address messenger
    ) external onlyOwner {
        _addCaller(callerChainId, caller, messenger);
    }

    /// Mark the function as restricted.
    ///
    /// Calls to the restricted function can only come from an address that
    /// was previously added by a call to :sol:func:`addCaller`.
    ///
    /// Example usage::
    ///
    ///     restricted(block.chainid)   // expecting calls from the same chain
    ///     restricted(otherChainId)    // expecting calls from another chain
    ///
    modifier restricted(uint256 callerChainId) {
        address caller = callers[callerChainId][0];

        if (callerChainId == block.chainid) {
            require(msg.sender == caller, "RestrictedCalls: call disallowed");
        } else {
            address messenger = callers[callerChainId][1];
            require(
                messenger != address(0),
                "RestrictedCalls: messenger not set"
            );
            require(
                IMessenger(messenger).callAllowed(caller, msg.sender),
                "RestrictedCalls: call disallowed"
            );
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/[email protected]/contracts/token/ERC20/utils/SafeERC20.sol";
import "OpenZeppelin/[email protected]/contracts/utils/math/Math.sol";
import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "OpenZeppelin/[email protected]/contracts/security/Pausable.sol";

import "./BeamerUtils.sol";
import "./RestrictedCalls.sol";
import "./LpWhitelist.sol";

/// The request manager.
///
/// This contract is responsible for keeping track of transfer requests,
/// implementing the rules of the challenge game and holding deposited
/// tokens until they are withdrawn.
/// The information passed by L1 resolution will be stored with the respective requests.
///
/// It is the only contract that agents need to interact with on the source chain.
/// .. note::
///
///   The functions resolveRequest and invalidateFill can only be called by
///   the :sol:contract:`Resolver` contract, via a chain-dependent messenger contract.
contract RequestManager is Ownable, LpWhitelist, RestrictedCalls, Pausable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // Structs
    // TODO: check if we can use a smaller type for `targetChainId`, so that the
    // fields can be packed into one storage slot
    struct Request {
        address sender;
        address sourceTokenAddress;
        uint256 targetChainId;
        uint256 amount;
        uint32 validUntil;
        uint256 lpFee;
        uint256 protocolFee;
        uint32 activeClaims;
        uint96 withdrawClaimId;
        address filler;
        bytes32 fillId;
        mapping(bytes32 fillId => bool invalid) invalidFillIds;
    }

    struct Claim {
        bytes32 requestId;
        address claimer;
        uint96 claimerStake;
        mapping(address challenger => uint96 stake) challengersStakes;
        address lastChallenger;
        uint96 challengerStakeTotal;
        uint256 withdrawnAmount;
        uint256 termination;
        bytes32 fillId;
    }

    struct Token {
        uint256 transferLimit;
        uint256 ethInToken;
        uint256 collectedProtocolFees;
    }

    struct Chain {
        uint256 finalityPeriod;
        uint256 transferCost;
        uint256 targetWeightPPM;
    }

    // Events

    /// Emitted when a new request has been created.
    ///
    /// .. seealso:: :sol:func:`createRequest`
    event RequestCreated(
        bytes32 indexed requestId,
        uint256 targetChainId,
        address sourceTokenAddress,
        address targetTokenAddress,
        address indexed sourceAddress,
        address targetAddress,
        uint256 amount,
        uint96 nonce,
        uint32 validUntil,
        uint256 lpFee,
        uint256 protocolFee
    );

    /// Emitted when the token deposit for request ``requestId`` has been
    /// transferred to the ``receiver``.
    ///
    /// This can happen in two cases:
    ///
    ///  * the request expired and the request submitter called :sol:func:`withdrawExpiredRequest`
    ///  * a claim related to the request has been resolved successfully in favor of the claimer
    ///
    /// .. seealso:: :sol:func:`withdraw` :sol:func:`withdrawExpiredRequest`
    event DepositWithdrawn(bytes32 requestId, address receiver);

    /// Emitted when a claim or a counter-claim (challenge) has been made.
    ///
    /// .. seealso:: :sol:func:`claimRequest` :sol:func:`challengeClaim`
    event ClaimMade(
        bytes32 indexed requestId,
        uint96 claimId,
        address claimer,
        uint96 claimerStake,
        address lastChallenger,
        uint96 challengerStakeTotal,
        uint256 termination,
        bytes32 fillId
    );

    /// Emitted when staked native tokens tied to a claim have been withdrawn.
    ///
    /// This can only happen when the claim has been resolved and the caller
    /// of :sol:func:`withdraw` is allowed to withdraw their stake.
    ///
    /// .. seealso:: :sol:func:`withdraw`
    event ClaimStakeWithdrawn(
        uint96 claimId,
        bytes32 indexed requestId,
        address stakeRecipient
    );

    /// Emitted when fees are updated.
    ///
    /// .. seealso:: :sol:func:`updateFees`
    event FeesUpdated(uint32 minFeePPM, uint32 lpFeePPM, uint32 protocolFeePPM);

    /// Emitted when token object of a token address is updated.
    ///
    /// .. seealso:: :sol:func:`updateToken`
    event TokenUpdated(
        address indexed tokenAddress,
        uint256 transferLimit,
        uint256 ethInToken
    );

    /// Emitted when chain object of a chain id is updated.
    ///
    /// .. seealso:: :sol:func:`updateChain`
    event ChainUpdated(
        uint256 indexed chainId,
        uint256 finalityPeriod,
        uint256 transferCost,
        uint256 targetWeightPPM
    );

    /// Emitted when a request has been resolved via L1 resolution.
    ///
    /// .. seealso:: :sol:func:`resolveRequest`
    event RequestResolved(bytes32 requestId, address filler, bytes32 fillId);

    /// Emitted when an invalidated fill has been resolved.
    ///
    /// .. seealso:: :sol:func:`invalidateFill`
    event FillInvalidatedResolved(bytes32 requestId, bytes32 fillId);

    // Constants

    /// The minimum amount of source chain's native token that the claimer needs to
    /// provide when making a claim, as well in each round of the challenge game.
    uint96 public immutable claimStake;

    /// The additional time given to claim a request. This value is added to the
    /// validity period of a request.
    uint256 public immutable claimRequestExtension;

    /// The period for which the claim is valid.
    uint256 public immutable claimPeriod;

    /// The period by which the termination time of a claim is extended after each
    /// round of the challenge game. This period should allow enough time for the
    /// other parties to counter-challenge.
    ///
    /// .. note::
    ///
    ///    The claim's termination time is extended only if it is less than the
    ///    extension time.
    ///
    /// Note that in the first challenge round, i.e. the round initiated by the first
    /// challenger, the termination time is extended additionally by the finality
    /// period of the target chain. This is done to allow for L1 resolution.
    uint256 public immutable challengePeriodExtension;

    /// PPM to determine the minLpFee profit for liquidity providers.
    uint32 public minFeePPM;

    /// PPM from transfer amount to determine the LP's fee
    uint32 public lpFeePPM;

    /// PPM from transfer amount to determine the protocol's fee
    uint32 public protocolFeePPM;

    /// The minimum validity period of a request.
    uint256 public constant MIN_VALIDITY_PERIOD = 30 minutes;

    /// The maximum validity period of a request.
    uint256 public constant MAX_VALIDITY_PERIOD = 48 hours;

    /// withdrawClaimId is set to this value when an expired request gets withdrawn by the sender
    uint96 public constant CLAIM_ID_WITHDRAWN_EXPIRED = type(uint96).max;

    // Variables

    /// A counter used to generate request and claim IDs.
    /// The variable holds the most recently used nonce and must
    /// be incremented to get the next nonce
    uint96 public currentNonce;

    /// Maps target rollup chain IDs to chain information.
    mapping(uint256 chainId => Chain) public chains;

    /// Maps request IDs to requests.
    mapping(bytes32 requestId => Request) public requests;

    /// Maps claim IDs to claims.
    mapping(uint96 claimId => Claim) public claims;

    /// Maps ERC20 token address to tokens
    mapping(address tokenAddress => Token) public tokens;

    /// Compute the minimum liquidity provider fee that needs to be paid for a token transfer.
    function minLpFee(
        uint256 targetChainId,
        address tokenAddress
    ) public view returns (uint256) {
        Token storage token = tokens[tokenAddress];
        Chain storage sourceChain = chains[block.chainid];
        Chain storage targetChain = chains[targetChainId];

        // The shift by 30 decimals comes from a multiplication of two PPM divisions (1e6 each)
        // and the 18 decimals division for ether
        return
            (((1_000_000 - sourceChain.targetWeightPPM) *
                sourceChain.transferCost +
                targetChain.targetWeightPPM *
                targetChain.transferCost) *
                (minFeePPM + 1_000_000) *
                token.ethInToken) / 10 ** 30;
    }

    /// Compute the liquidity provider fee that needs to be paid for a given transfer amount.
    function lpFee(
        uint256 targetChainId,
        address tokenAddress,
        uint256 amount
    ) public view returns (uint256) {
        uint256 minFee = minLpFee(targetChainId, tokenAddress);
        return Math.max(minFee, (amount * lpFeePPM) / 1_000_000);
    }

    /// Compute the protocol fee that needs to be paid for a given transfer amount.
    function protocolFee(uint256 amount) public view returns (uint256) {
        return (amount * protocolFeePPM) / 1_000_000;
    }

    /// Compute the total fee that needs to be paid for a given transfer amount.
    /// The total fee is the sum of the liquidity provider fee and the protocol fee.
    function totalFee(
        uint256 targetChainId,
        address tokenAddress,
        uint256 amount
    ) public view returns (uint256) {
        return lpFee(targetChainId, tokenAddress, amount) + protocolFee(amount);
    }

    function transferableAmount(
        uint256 targetChainId,
        address tokenAddress,
        uint256 amount
    ) public view returns (uint256) {
        uint256 minFee = minLpFee(targetChainId, tokenAddress);
        require(amount > minFee, "Amount not high enough to cover the fees");
        // FIXME: There is a possible rounding error which leads to off by one unit
        // currently the error happens in "our" favor so that the dust stays in the wallet.
        // Can probably be fixed by rounding on the token.decimals() + 1 th digit
        uint256 transferableAmount = (amount * 1_000_000) /
            (1_000_000 + lpFeePPM + protocolFeePPM);

        if ((transferableAmount * lpFeePPM) / 1_000_000 >= minFee) {
            return transferableAmount;
        }

        return ((amount - minFee) * 1_000_000) / (1_000_000 + protocolFeePPM);
    }

    // Modifiers

    /// Check whether a given request ID is valid.
    modifier validRequestId(bytes32 requestId) {
        require(
            requests[requestId].sender != address(0),
            "requestId not valid"
        );
        _;
    }

    /// Check whether a given claim ID is valid.
    modifier validClaimId(uint96 claimId) {
        require(claims[claimId].claimer != address(0), "claimId not valid");
        _;
    }

    /// Constructor.
    ///
    /// @param _claimStake Claim stake amount.
    /// @param _claimRequestExtension Extension to claim a request after validity period ends.
    /// @param _claimPeriod Claim period, in seconds.
    /// @param _challengePeriodExtension Challenge period extension, in seconds.
    constructor(
        uint96 _claimStake,
        uint256 _claimRequestExtension,
        uint256 _claimPeriod,
        uint256 _challengePeriodExtension
    ) {
        claimStake = _claimStake;
        claimRequestExtension = _claimRequestExtension;
        claimPeriod = _claimPeriod;
        challengePeriodExtension = _challengePeriodExtension;
    }

    /// Create a new transfer request.
    ///
    /// @param targetChainId ID of the target chain.
    /// @param sourceTokenAddress Address of the token contract on the source chain.
    /// @param targetTokenAddress Address of the token contract on the target chain.
    /// @param targetAddress Recipient address on the target chain.
    /// @param amount Amount of tokens to transfer. Does not include fees.
    /// @param validityPeriod The number of seconds the request is to be considered valid.
    ///                       Once its validity period has elapsed, the request cannot be claimed
    ///                       anymore and will eventually expire, allowing the request submitter
    ///                       to withdraw the deposited tokens if there are no active claims.
    /// @return ID of the newly created request.
    function createRequest(
        uint256 targetChainId,
        address sourceTokenAddress,
        address targetTokenAddress,
        address targetAddress,
        uint256 amount,
        uint256 validityPeriod
    ) external whenNotPaused returns (bytes32) {
        require(
            chains[targetChainId].finalityPeriod != 0,
            "Target rollup not supported"
        );
        require(
            validityPeriod >= MIN_VALIDITY_PERIOD,
            "Validity period too short"
        );
        require(
            validityPeriod <= MAX_VALIDITY_PERIOD,
            "Validity period too long"
        );
        require(
            amount <= tokens[sourceTokenAddress].transferLimit,
            "Amount exceeds transfer limit"
        );

        uint256 lpFeeTokenAmount = lpFee(
            targetChainId,
            sourceTokenAddress,
            amount
        );
        uint256 protocolFeeTokenAmount = protocolFee(amount);

        require(
            IERC20(sourceTokenAddress).allowance(msg.sender, address(this)) >=
                amount + lpFeeTokenAmount + protocolFeeTokenAmount,
            "Insufficient allowance"
        );

        uint96 nonce = currentNonce + 1;
        currentNonce = nonce;

        bytes32 requestId = BeamerUtils.createRequestId(
            block.chainid,
            targetChainId,
            targetTokenAddress,
            targetAddress,
            amount,
            nonce
        );

        Request storage newRequest = requests[requestId];
        newRequest.sender = msg.sender;
        newRequest.sourceTokenAddress = sourceTokenAddress;
        newRequest.targetChainId = targetChainId;
        newRequest.amount = amount;
        newRequest.validUntil = uint32(block.timestamp + validityPeriod);
        newRequest.lpFee = lpFeeTokenAmount;
        newRequest.protocolFee = protocolFeeTokenAmount;

        emit RequestCreated(
            requestId,
            targetChainId,
            sourceTokenAddress,
            targetTokenAddress,
            msg.sender,
            targetAddress,
            amount,
            nonce,
            uint32(block.timestamp + validityPeriod),
            lpFeeTokenAmount,
            protocolFeeTokenAmount
        );

        IERC20(sourceTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount + lpFeeTokenAmount + protocolFeeTokenAmount
        );

        return requestId;
    }

    /// Withdraw funds deposited with an expired request.
    ///
    /// No claims must be active for the request.
    ///
    /// @param requestId ID of the expired request.
    function withdrawExpiredRequest(
        bytes32 requestId
    ) external validRequestId(requestId) {
        Request storage request = requests[requestId];

        require(request.withdrawClaimId == 0, "Deposit already withdrawn");
        require(
            block.timestamp >= request.validUntil,
            "Request not expired yet"
        );
        require(request.activeClaims == 0, "Active claims running");

        request.withdrawClaimId = CLAIM_ID_WITHDRAWN_EXPIRED;

        emit DepositWithdrawn(requestId, request.sender);

        IERC20 token = IERC20(request.sourceTokenAddress);
        token.safeTransfer(
            request.sender,
            request.amount + request.lpFee + request.protocolFee
        );
    }

    /// Claim that a request was filled by the caller.
    ///
    /// The request must still be valid at call time.
    /// The caller must provide the ``claimStake`` amount of source rollup's native
    /// token.
    ///
    /// @param requestId ID of the request.
    /// @param fillId The fill ID.
    /// @return The claim ID.
    function claimRequest(
        bytes32 requestId,
        bytes32 fillId
    )
        external
        payable
        validRequestId(requestId)
        onlyAllowed(msg.sender)
        returns (uint96)
    {
        return claimRequest(msg.sender, requestId, fillId);
    }

    /// Claim that a request was filled.
    ///
    /// The request must still be valid at call time.
    /// The caller must provide the ``claimStake`` amount of source rollup's native
    /// token.
    /// Only the claimer may get the stake back later.
    ///
    /// @param claimer Address of the claimer.
    /// @param requestId ID of the request.
    /// @param fillId The fill ID.
    /// @return The claim ID.
    function claimRequest(
        address claimer,
        bytes32 requestId,
        bytes32 fillId
    )
        public
        payable
        validRequestId(requestId)
        onlyAllowed(claimer)
        returns (uint96)
    {
        Request storage request = requests[requestId];

        require(
            block.timestamp < request.validUntil + claimRequestExtension,
            "Request cannot be claimed anymore"
        );
        require(request.withdrawClaimId == 0, "Deposit already withdrawn");
        require(msg.value == claimStake, "Invalid stake amount");
        require(fillId != bytes32(0), "FillId must not be 0x0");

        request.activeClaims += 1;

        uint96 nonce = currentNonce + 1;
        currentNonce = nonce;
        uint256 termination = block.timestamp + claimPeriod;

        Claim storage claim = claims[nonce];
        claim.requestId = requestId;
        claim.claimer = claimer;
        claim.claimerStake = uint96(msg.value);
        claim.termination = termination;
        claim.fillId = fillId;

        emit ClaimMade(
            requestId,
            nonce,
            claimer,
            uint96(msg.value),
            address(0),
            0,
            termination,
            fillId
        );

        return nonce;
    }

    /// Challenge an existing claim.
    ///
    /// The claim must still be valid at call time.
    /// This function implements one round of the challenge game.
    /// The original claimer is allowed to call this function only
    /// after someone else made a challenge, i.e. every second round.
    /// However, once the original claimer counter-challenges, anyone
    /// can join the game and make another challenge.
    ///
    /// The caller must provide enough native tokens as their stake.
    /// For the original claimer, the minimum stake is
    /// ``challengerStakeTotal - claimerStake + claimStake``.
    ///
    /// For challengers, the minimum stake is
    /// ``claimerStake - challengerStakeTotal + 1``.
    ///
    /// An example (time flows downwards, claimStake = 10)::
    ///
    ///   claimRequest() by Max [stakes 10]
    ///   challengeClaim() by Alice [stakes 11]
    ///   challengeClaim() by Max [stakes 11]
    ///   challengeClaim() by Bob [stakes 16]
    ///
    /// In this example, if Max didn't want to lose the challenge game to
    /// Alice and Bob, he would have to challenge with a stake of at least 16.
    ///
    /// @param claimId The claim ID.
    function challengeClaim(
        uint96 claimId
    ) external payable validClaimId(claimId) {
        Claim storage claim = claims[claimId];
        bytes32 requestId = claim.requestId;
        uint256 termination = claim.termination;
        require(block.timestamp < termination, "Claim expired");
        require(
            requests[requestId].filler == address(0),
            "Request already resolved"
        );
        require(
            !requests[requestId].invalidFillIds[claim.fillId],
            "Fill already invalidated"
        );

        uint256 periodExtension = challengePeriodExtension;
        address claimer = claim.claimer;
        uint96 claimerStake = claim.claimerStake;
        uint96 challengerStakeTotal = claim.challengerStakeTotal;

        if (claimerStake > challengerStakeTotal) {
            if (challengerStakeTotal == 0) {
                periodExtension += chains[requests[requestId].targetChainId]
                    .finalityPeriod;
            }
            require(msg.sender != claimer, "Cannot challenge own claim");
            require(
                msg.value >= claimerStake - challengerStakeTotal + 1,
                "Not enough stake provided"
            );
        } else {
            require(msg.sender == claimer, "Not eligible to outbid");
            require(
                msg.value >= challengerStakeTotal - claimerStake + claimStake,
                "Not enough stake provided"
            );
        }

        if (msg.sender == claimer) {
            claimerStake += uint96(msg.value);
            claim.claimerStake = claimerStake;
        } else {
            claim.lastChallenger = msg.sender;
            claim.challengersStakes[msg.sender] += uint96(msg.value);
            challengerStakeTotal += uint96(msg.value);
            claim.challengerStakeTotal = challengerStakeTotal;
        }

        if (block.timestamp + periodExtension > termination) {
            termination = block.timestamp + periodExtension;
            claim.termination = termination;
        }

        emit ClaimMade(
            requestId,
            claimId,
            claimer,
            claimerStake,
            claim.lastChallenger,
            challengerStakeTotal,
            termination,
            claim.fillId
        );
    }

    /// Withdraw the deposit that the request submitter left with the contract,
    /// as well as the staked native tokens associated with the claim.
    ///
    /// In case the caller of this function is a challenger that won the game,
    /// they will only get their staked native tokens plus the reward in the form
    /// of full (sole challenger) or partial (multiple challengers) amount
    /// of native tokens staked by the dishonest claimer.
    ///
    /// @param claimId The claim ID.
    /// @return The claim stakes receiver.
    function withdraw(
        uint96 claimId
    ) external validClaimId(claimId) returns (address) {
        return withdraw(msg.sender, claimId);
    }

    /// Withdraw the deposit that the request submitter left with the contract,
    /// as well as the staked native tokens associated with the claim.
    ///
    /// This function is called on behalf of a participant. Only a participant
    /// may receive the funds if he is the winner of the challenge or the claim is valid.
    ///
    /// In case the caller of this function is a challenger that won the game,
    /// they will only get their staked native tokens plus the reward in the form
    /// of full (sole challenger) or partial (multiple challengers) amount
    /// of native tokens staked by the dishonest claimer.
    ///
    /// @param claimId The claim ID.
    /// @param participant The participant.
    /// @return The claim stakes receiver.
    function withdraw(
        address participant,
        uint96 claimId
    ) public validClaimId(claimId) returns (address) {
        Claim storage claim = claims[claimId];
        address claimer = claim.claimer;
        require(
            participant == claimer || claim.challengersStakes[participant] > 0,
            "Not an active participant in this claim"
        );
        bytes32 requestId = claim.requestId;
        Request storage request = requests[requestId];

        (address stakeRecipient, uint256 ethToTransfer) = resolveClaim(
            participant,
            claimId
        );

        if (claim.challengersStakes[stakeRecipient] > 0) {
            //Re-entrancy protection
            claim.challengersStakes[stakeRecipient] = 0;
        }

        uint256 withdrawnAmount = claim.withdrawnAmount;

        // First time withdraw is called, remove it from active claims
        if (withdrawnAmount == 0) {
            request.activeClaims -= 1;
        }
        withdrawnAmount += ethToTransfer;
        claim.withdrawnAmount = withdrawnAmount;

        require(
            withdrawnAmount <= claim.claimerStake + claim.challengerStakeTotal,
            "Amount to withdraw too large"
        );

        (bool sent, ) = stakeRecipient.call{value: ethToTransfer}("");
        require(sent, "Failed to send Ether");

        emit ClaimStakeWithdrawn(claimId, requestId, stakeRecipient);

        if (request.withdrawClaimId == 0 && stakeRecipient == claimer) {
            withdrawDeposit(request, claimId);
        }

        return stakeRecipient;
    }

    function resolveClaim(
        address participant,
        uint96 claimId
    ) private view returns (address, uint256) {
        Claim storage claim = claims[claimId];
        Request storage request = requests[claim.requestId];
        uint96 withdrawClaimId = request.withdrawClaimId;
        address claimer = claim.claimer;
        uint96 claimerStake = claim.claimerStake;
        uint96 challengerStakeTotal = claim.challengerStakeTotal;
        require(
            claim.withdrawnAmount < claimerStake + challengerStakeTotal,
            "Claim already withdrawn"
        );

        bool claimValid = false;

        // The claim is resolved with the following priority:
        // 1) The l1 resolved filler is the claimer and l1 resolved fillId matches, claim is valid
        // 2) FillId is true in request's invalidFillIds, claim is invalid
        // 3) The withdrawer's claim matches exactly this claim (same claimer address, same fillId)
        // 4) Claim properties, claim terminated and claimer has the highest stake
        address filler = request.filler;
        bytes32 fillId = request.fillId;

        if (filler != address(0)) {
            // Claim resolution via 1)
            claimValid = filler == claimer && fillId == claim.fillId;
        } else if (request.invalidFillIds[fillId]) {
            // Claim resolution via 2)
            claimValid = false;
        } else if (withdrawClaimId != 0) {
            // Claim resolution via 3)
            claimValid =
                claimer == claims[withdrawClaimId].claimer &&
                claim.fillId == claims[withdrawClaimId].fillId;
        } else {
            // Claim resolution via 4)
            require(
                block.timestamp >= claim.termination,
                "Claim period not finished"
            );
            claimValid = claimerStake > challengerStakeTotal;
        }

        // Calculate withdraw scheme for claim stakes
        uint96 ethToTransfer;
        address stakeRecipient;

        if (claimValid) {
            // If claim is valid, all stakes go to the claimer
            stakeRecipient = claimer;
            ethToTransfer = claimerStake + challengerStakeTotal;
        } else if (challengerStakeTotal > 0) {
            // If claim is invalid, partial withdrawal by the participant
            stakeRecipient = participant;
            ethToTransfer = 2 * claim.challengersStakes[stakeRecipient];
            require(ethToTransfer > 0, "Challenger has nothing to withdraw");
        } else {
            // The unlikely event is possible that a false claim has no challenger
            // If it is known that the claim is false then the claimer stake goes to the platform
            stakeRecipient = owner();
            ethToTransfer = claimerStake;
        }

        // If the challenger wins and is the last challenger, he gets either
        // twice his stake plus the excess stake (if the claimer was winning), or
        // twice his stake minus the difference between the claimer and challenger stakes (if the claimer was losing)
        if (stakeRecipient == claim.lastChallenger) {
            if (claimerStake > challengerStakeTotal) {
                ethToTransfer += (claimerStake - challengerStakeTotal);
            } else {
                ethToTransfer -= (challengerStakeTotal - claimerStake);
            }
        }

        return (stakeRecipient, ethToTransfer);
    }

    function withdrawDeposit(Request storage request, uint96 claimId) private {
        Claim storage claim = claims[claimId];
        address claimer = claim.claimer;
        emit DepositWithdrawn(claim.requestId, claimer);

        request.withdrawClaimId = claimId;

        tokens[request.sourceTokenAddress].collectedProtocolFees += request
            .protocolFee;

        IERC20 token = IERC20(request.sourceTokenAddress);
        token.safeTransfer(claimer, request.amount + request.lpFee);
    }

    /// Returns whether a request's deposit was withdrawn or not
    ///
    /// This can be true in two cases:
    /// 1. The deposit was withdrawn after the request was claimed and filled.
    /// 2. The submitter withdrew the deposit after the request's expiry.
    /// .. seealso:: :sol:func:`withdraw`
    /// .. seealso:: :sol:func:`withdrawExpiredRequest`
    ///
    /// @param requestId The request ID
    /// @return Whether the deposit corresponding to the given request ID was withdrawn
    function isWithdrawn(
        bytes32 requestId
    ) public view validRequestId(requestId) returns (bool) {
        return requests[requestId].withdrawClaimId != 0;
    }

    /// Withdraw protocol fees collected by the contract.
    ///
    /// Protocol fees are paid in token transferred.
    ///
    /// .. note:: This function can only be called by the contract owner.
    ///
    /// @param tokenAddress The address of the token contract.
    /// @param recipient The address the fees should be sent to.
    function withdrawProtocolFees(
        address tokenAddress,
        address recipient
    ) external onlyOwner {
        uint256 amount = tokens[tokenAddress].collectedProtocolFees;
        require(amount > 0, "Protocol fee is zero");
        tokens[tokenAddress].collectedProtocolFees = 0;

        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(recipient, amount);
    }

    /// Update fees
    ///
    /// .. note:: This function can only be called by the contract owner.
    ///
    /// @param _minFeePPM Margin which is going to be applied to the minLpFee
    /// @param _lpFeePPM LP percentage fee applied on transfer amount denominated in parts per million
    /// @param _protocolFeePPM Protocol fee applied on transfer amount denominated in parts per million
    function updateFees(
        uint32 _minFeePPM,
        uint32 _lpFeePPM,
        uint32 _protocolFeePPM
    ) external onlyOwner {
        require(_lpFeePPM <= 999_999, "Maximum PPM of 999999 exceeded");
        require(_protocolFeePPM <= 999_999, "Maximum PPM of 999999 exceeded");

        minFeePPM = _minFeePPM;
        lpFeePPM = _lpFeePPM;
        protocolFeePPM = _protocolFeePPM;

        emit FeesUpdated(_minFeePPM, _lpFeePPM, _protocolFeePPM);
    }

    function updateToken(
        address tokenAddress,
        uint256 transferLimit,
        uint256 ethInToken
    ) external onlyOwner {
        Token storage token = tokens[tokenAddress];
        token.transferLimit = transferLimit;
        token.ethInToken = ethInToken;

        emit TokenUpdated(tokenAddress, transferLimit, ethInToken);
    }

    /// Update chain information for a given chain ID.
    ///
    /// .. note:: This function can only be called by the contract owner.
    ///
    /// @param chainId The chain ID of the chain.
    /// @param finalityPeriod The finality period of the chain in seconds.
    /// @param transferCost The transfer cost (fill, claim, withdraw) on the chain in WEI.
    /// @param targetWeightPPM The share of the target chain costs (fill) in parts per million.
    function updateChain(
        uint256 chainId,
        uint256 finalityPeriod,
        uint256 transferCost,
        uint256 targetWeightPPM
    ) external onlyOwner {
        require(finalityPeriod > 0, "Finality period must be greater than 0");
        require(targetWeightPPM <= 999_999, "Maximum PPM of 999999 exceeded");

        Chain storage chain = chains[chainId];
        chain.finalityPeriod = finalityPeriod;
        chain.transferCost = transferCost;
        chain.targetWeightPPM = targetWeightPPM;

        emit ChainUpdated(
            chainId,
            finalityPeriod,
            transferCost,
            targetWeightPPM
        );
    }

    /// Returns whether a fill is invalidated or not
    ///
    /// Calling invalidateFill() will set this boolean to true,
    /// marking that the ``fillId`` for the corresponding ``requestId`` was
    /// invalidated.
    /// Calling resolveRequest will validate it again, setting request.invalidatedFills[fillId]
    /// to false.
    /// .. seealso:: :sol:func:`invalidateFill`
    /// .. seealso:: :sol:func:`resolveRequest`
    ///
    /// @param requestId The request ID
    /// @param fillId The fill ID
    /// @return Whether the fill ID is invalid for the given request ID
    function isInvalidFill(
        bytes32 requestId,
        bytes32 fillId
    ) public view returns (bool) {
        return requests[requestId].invalidFillIds[fillId];
    }

    /// Mark the request identified by ``requestId`` as filled by ``filler``.
    ///
    /// .. note::
    ///
    ///     This function is a restricted call function. Only callable by the added caller.
    ///
    /// @param requestId The request ID.
    /// @param fillId The fill ID.
    /// @param resolutionChainId The resolution (L1) chain ID.
    /// @param filler The address that filled the request.
    function resolveRequest(
        bytes32 requestId,
        bytes32 fillId,
        uint256 resolutionChainId,
        address filler
    ) external restricted(resolutionChainId) {
        Request storage request = requests[requestId];
        request.filler = filler;
        request.fillId = fillId;

        request.invalidFillIds[fillId] = false;

        emit RequestResolved(requestId, filler, fillId);
    }

    /// Mark the fill identified by ``requestId`` and ``fillId`` as invalid.
    ///
    /// .. note::
    ///
    ///     This function is a restricted call function. Only callable by the added caller.
    ///
    /// @param requestId The request ID.
    /// @param fillId The fill ID.
    /// @param resolutionChainId The resolution (L1) chain ID.
    function invalidateFill(
        bytes32 requestId,
        bytes32 fillId,
        uint256 resolutionChainId
    ) external restricted(resolutionChainId) {
        Request storage request = requests[requestId];
        require(
            request.filler == address(0),
            "Cannot invalidate resolved fills"
        );
        require(
            request.invalidFillIds[fillId] == false,
            "Fill already invalidated"
        );

        request.invalidFillIds[fillId] = true;

        emit FillInvalidatedResolved(requestId, fillId);
    }

    /// Pauses the contract.
    ///
    /// Once the contract is paused, it cannot be used to create new
    /// requests anymore. Withdrawing deposited funds and claim stakes
    /// still works, though.
    ///
    /// .. note:: This function can only be called when the contract is not paused.
    /// .. note:: This function can only be called by the contract owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// Unpauses the contract.
    ///
    /// Once the contract is unpaused, it can be used normally.
    ///
    /// .. note:: This function can only be called when the contract is paused.
    /// .. note:: This function can only be called by the contract owner.
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library BeamerUtils {
    function createRequestId(
        uint256 sourceChainId,
        uint256 targetChainId,
        address targetTokenAddress,
        address targetReceiverAddress,
        uint256 amount,
        uint96 nonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    sourceChainId,
                    targetChainId,
                    targetTokenAddress,
                    targetReceiverAddress,
                    amount,
                    nonce
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}