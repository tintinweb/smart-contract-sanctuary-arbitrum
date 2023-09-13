// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
pragma solidity ^0.8.10;

interface ArbGasInfo {
    // return gas prices in wei, assuming the specified aggregator is used
    //        (
    //            per L2 tx,
    //            per L1 calldata unit, (zero byte = 4 units, nonzero byte = 16 units)
    //            per storage allocation,
    //            per ArbGas base,
    //            per ArbGas congestion,
    //            per ArbGas total
    //        )
    function getPricesInWeiWithAggregator(
        address aggregator
    ) external view returns (uint, uint, uint, uint, uint, uint);

    // return gas prices in wei, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInWei()
        external
        view
        returns (uint, uint, uint, uint, uint, uint);

    // return prices in ArbGas (per L2 tx, per L1 calldata unit, per storage allocation),
    //       assuming the specified aggregator is used
    function getPricesInArbGasWithAggregator(
        address aggregator
    ) external view returns (uint, uint, uint);

    // return gas prices in ArbGas, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInArbGas() external view returns (uint, uint, uint);

    // return gas accounting parameters (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams() external view returns (uint, uint, uint);

    // get ArbOS's estimate of the L1 gas price in wei
    function getL1GasPriceEstimate() external view returns (uint);

    // set ArbOS's estimate of the L1 gas price in wei
    // reverts unless called by chain owner or designated gas oracle (if any)
    function setL1GasPriceEstimate(uint priceInWei) external;

    // get L1 gas fees paid by the current transaction (txBaseFeeWei, calldataFeeWei)
    function getCurrentTxL1GasFees() external view returns (uint);
}

interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(
        address sender,
        address unused
    ) external pure returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(
        address destination
    ) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(
        address destination,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (uint256 size, bytes32 root, bytes32[] memory partials);

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

//@dev A library that abstracts out opcodes that behave differently across chains.
//@dev The methods below return values that are pertinent to the given chain.
//@dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
    address private constant ARBSYS_ADDR =
        address(0x0000000000000000000000000000000000000064);
    ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);
    address private constant ARBGAS_ADDR =
        address(0x000000000000000000000000000000000000006C);
    ArbGasInfo private constant ARBGAS = ArbGasInfo(ARBGAS_ADDR);
    uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
    uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;

    function getBlockhash(uint256 blockNumber) internal view returns (bytes32) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            if (
                (getBlockNumber() - blockNumber) > 256 ||
                blockNumber >= getBlockNumber()
            ) {
                return "";
            }
            return ARBSYS.arbBlockHash(blockNumber);
        }
        return blockhash(blockNumber);
    }

    function getBlockNumber() internal view returns (uint256) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            return ARBSYS.arbBlockNumber();
        }
        return block.number;
    }

    function getCurrentTxL1GasFees() internal view returns (uint256) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            return ARBGAS.getCurrentTxL1GasFees();
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import "./ChainSpecificUtil.sol";

contract HashBet is Ownable, ReentrancyGuard, VRFV2WrapperConsumerBase {
    // Modulo is the number of equiprobable outcomes in a game:
    //  2 for coin flip
    //  6 for dice roll
    //  6*6 = 36 for double dice
    //  37 for roulette
    //  100 for hashroll
    uint constant MAX_MODULO = 100;

    // Modulos below MAX_MASK_MODULO are checked against a bit mask, allowing betting on specific outcomes.
    // For example in a dice roll (modolo = 6),
    // 000001 mask means betting on 1. 000001 converted from binary to decimal becomes 1.
    // 101000 mask means betting on 4 and 6. 101000 converted from binary to decimal becomes 40.
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits, and 40 is the highest multiple of
    // eight below 42.
    uint constant MAX_MASK_MODULO = 40;

    // EVM BLOCKHASH opcode can query no further than 256 blocks into the
    // past. Given that settleBet uses block hash of placeBet as one of
    // complementary entropy sources, we cannot process bets older than this
    // threshold. On rare occasions dice2.win croupier may fail to invoke
    // settleBet in this timespan due to technical issues or extreme Ethereum
    // congestion; such bets can be refunded via invoking refundBet.
    uint constant BET_EXPIRATION_BLOCKS = 250;

    // This is a check on bet mask overflow. Maximum mask is equivalent to number of possible binary outcomes for maximum modulo.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    // These are constants taht make O(1) population count in placeBet possible.
    uint constant POPCNT_MULT =
        0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK =
        0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

    uint256 private constant GRACE_PERIOD_TIME = 3600;

    // Sum of all historical deposits and withdrawals. Used for calculating profitability. Profit = Balance - cumulativeDeposit + cumulativeWithdrawal
    uint public cumulativeDeposit;
    uint public cumulativeWithdrawal;

    // In addition to house edge, wealth tax is added every time the bet amount exceeds a multiple of a threshold.
    // For example, if wealthTaxIncrementThreshold = 3000 ether,
    // A bet amount of 3000 ether will have a wealth tax of 1% in addition to house edge.
    // A bet amount of 6000 ether will have a wealth tax of 2% in addition to house edge.
    uint public wealthTaxIncrementThreshold = 3000 ether;
    uint public wealthTaxIncrementPercent = 1;

    // The minimum and maximum bets.
    uint public minBetAmount = 0.01 ether;
    uint public maxBetAmount = 10000 ether;

    // max bet profit. Used to cap bets against dynamic odds.
    uint public maxProfit = 300000 ether;

    // Funds that are locked in potentially winning bets. Prevents contract from committing to new bets that it cannot pay out.
    uint public lockedInBets;

    // The minimum larger comparison value.
    uint public minOverValue = 1;

    // The maximum smaller comparison value.
    uint public maxUnderValue = 98;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 constant callbackGasLimit = 1000000;

    // The default is 3, but you can set this higher.
    uint16 constant requestConfirmations = 3;

    // retrieve 1 random value in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 constant numWords = 1;

    // Address LINK
    address linkAddress;

    //Data Feed: LINK/NATIVE TOKEN
    AggregatorV2V3Interface internal dataFeed;
    //L2 sequencer feeds
    AggregatorV2V3Interface internal sequencerUptimeFeed;

    // Info of each bet.
    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollEdge),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollEdge;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Block number of placeBet tx.
        uint placeBlockNumber;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
        // Status of bet settlement.
        bool isSettled;
        // Outcome of bet.
        uint outcome;
        // Win amount.
        uint winAmount;
        // Random number used to settle bet.
        uint randomNumber;
        // Comparison method.
        bool isLarger;
        // VRF request id
        uint256 requestID;
    }

    // Each bet is deducted
    uint public defaultHouseEdgePercent = 2;

    uint256 public requestCounter;
    mapping(uint256 => uint256) s_requestIDToRequestIndex;
    // bet place time
    mapping(uint256 => uint256) betPlaceTime;
    // bet data
    mapping(uint256 => Bet) public bets;

    mapping(uint32 => uint32) public houseEdgePercents;

    // Events
    event BetPlaced(
        address indexed gambler,
        uint amount,
        uint indexed betID,
        uint8 indexed modulo,
        uint8 rollEdge,
        uint40 mask,
        bool isLarger
    );
    event BetSettled(
        address indexed gambler,
        uint amount,
        uint indexed betID,
        uint8 indexed modulo,
        uint8 rollEdge,
        uint40 mask,
        uint outcome,
        uint winAmount
    );
    event BetRefunded(address indexed gambler, uint amount);

    error OnlyCoordinatorCanFulfill(address have, address want);
    error NotAwaitingVRF();
    error AwaitingVRF(uint256 requestID);
    error RefundFailed();
    error InvalidValue(uint256 required, uint256 sent);
    error TransferFailed();
    error SequencerDown();
    error GracePeriodNotOver();

    constructor(
        address _linkAddress,
        address _vrfV2Wrapper,
        address _dataFeed,
        address _sequencerUptimeFeed
    ) VRFV2WrapperConsumerBase(_linkAddress, _vrfV2Wrapper) {
        linkAddress = _linkAddress;
        dataFeed = AggregatorV2V3Interface(_dataFeed);
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencerUptimeFeed);
        houseEdgePercents[2] = 1;
        houseEdgePercents[6] = 1;
        houseEdgePercents[36] = 1;
        houseEdgePercents[37] = 3;
        houseEdgePercents[100] = 5;
    }

    // Fallback payable function used to top up the bank roll.
    fallback() external payable {
        cumulativeDeposit += msg.value;
    }

    receive() external payable {
        cumulativeDeposit += msg.value;
    }

    // See ETH balance.
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    // Owner can withdraw funds not exceeding balance minus potential win prizes by open bets
    function withdrawFunds(uint withdrawAmount) external onlyOwner {
        require(
            withdrawAmount <= address(this).balance,
            "Withdrawal amount larger than balance."
        );
        require(
            withdrawAmount <= address(this).balance - lockedInBets,
            "Withdrawal amount larger than balance minus lockedInBets"
        );
        address payable beneficiary = payable(msg.sender);
        beneficiary.transfer(withdrawAmount);
        cumulativeWithdrawal += withdrawAmount;
    }

    function emitBetPlacedEvent(
        address gambler,
        uint amount,
        uint betID,
        uint8 modulo,
        uint8 rollEdge,
        uint40 mask,
        bool isLarger
    ) private {
        // Record bet in event logs
        emit BetPlaced(
            gambler,
            amount,
            betID,
            uint8(modulo),
            uint8(rollEdge),
            uint40(mask),
            isLarger
        );
    }

    // Place bet
    function placeBet(
        uint betAmount,
        uint betMask,
        uint modulo,
        bool isLarger
    ) external payable nonReentrant {
        address msgSender = _msgSender();

        checkVRFFee(betAmount, tx.gasprice);

        validateArguments(betAmount, betMask, modulo);

        uint rollEdge;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            // Small modulo games can specify exact bet outcomes via bit mask.
            // rollEdge is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40.
            rollEdge = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else {
            // Larger modulos games specify the right edge of half-open interval of winning bet outcomes.
            rollEdge = betMask;
        }

        // Winning amount.
        uint possibleWinAmount = getDiceWinAmount(
            betAmount,
            modulo,
            rollEdge,
            isLarger
        );

        // Check whether contract has enough funds to accept this bet.
        require(
            lockedInBets + possibleWinAmount <= address(this).balance,
            "Unable to accept bet due to insufficient funds"
        );

        uint256 requestID = _requestRandomWords();

        // Update lock funds.
        lockedInBets += possibleWinAmount;

        s_requestIDToRequestIndex[requestID] = requestCounter;
        betPlaceTime[requestCounter] = block.timestamp;
        bets[requestCounter] = Bet({
            amount: betAmount,
            modulo: uint8(modulo),
            rollEdge: uint8(rollEdge),
            mask: uint40(mask),
            placeBlockNumber: ChainSpecificUtil.getBlockNumber(),
            gambler: payable(msgSender),
            isSettled: false,
            outcome: 0,
            winAmount: possibleWinAmount,
            randomNumber: 0,
            isLarger: isLarger,
            requestID: requestID
        });

        // Record bet in event logs
        emitBetPlacedEvent(
            msgSender,
            betAmount,
            requestCounter,
            uint8(modulo),
            uint8(rollEdge),
            uint40(mask),
            isLarger
        );

        requestCounter += 1;
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(
        uint amount,
        uint modulo,
        uint rollEdge,
        bool isLarger
    ) private view returns (uint winAmount) {
        require(
            0 < rollEdge && rollEdge <= modulo,
            "Win probability out of range."
        );
        uint houseEdge = (amount *
            (getModuloHouseEdgePercent(uint32(modulo)) +
                getWealthTax(amount))) / 100;
        uint realRollEdge = rollEdge;
        if (modulo == MAX_MODULO && isLarger) {
            realRollEdge = MAX_MODULO - rollEdge - 1;
        }
        winAmount = ((amount - houseEdge) * modulo) / realRollEdge;

        // round down to multiple 1000Gweis
        winAmount = (winAmount / 1e12) * 1e12;

        uint maxWinAmount = amount + maxProfit;

        if (winAmount > maxWinAmount) {
            winAmount = maxWinAmount;
        }
    }

    // Get wealth tax
    function getWealthTax(uint amount) private view returns (uint wealthTax) {
        wealthTax =
            (amount / wealthTaxIncrementThreshold) *
            wealthTaxIncrementPercent;
    }

    // Common settlement code for settleBet.
    function settleBetCommon(
        Bet storage bet,
        uint reveal
    ) private {
        // Fetch bet parameters into local variables (to save gas).
        uint amount = bet.amount;

        // Validation check
        require(amount > 0, "Bet does not exist."); // Check that bet exists
        require(bet.isSettled == false, "Bet is settled already"); // Check that bet is not settled yet

        // Fetch bet parameters into local variables (to save gas).
        uint modulo = bet.modulo;
        uint rollEdge = bet.rollEdge;
        address payable gambler = bet.gambler;
        bool isLarger = bet.isLarger;

        // The RNG - combine "reveal" and blockhash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal));

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint outcome = uint(entropy) % modulo;

        // Win amount if gambler wins this bet
        uint possibleWinAmount = bet.winAmount;

        // Actual win amount by gambler
        uint winAmount = 0;

        // Determine dice outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2 ** outcome) & bet.mask != 0) {
                winAmount = possibleWinAmount;
            }
        } else {
            // For larger modulos, check inclusion into half-open interval.
            if (isLarger) {
                if (outcome > rollEdge) {
                    winAmount = possibleWinAmount;
                }
            } else {
                if (outcome < rollEdge) {
                    winAmount = possibleWinAmount;
                }
            }
        }

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = winAmount;
        bet.randomNumber = reveal;
        bet.outcome = outcome;

        // Send win amount to gambler.
        if (bet.winAmount > 0) {
            gambler.transfer(bet.winAmount);
        }

        emitSettledEvent(bet);
    }

    function emitSettledEvent(Bet storage bet) private {
        uint amount = bet.amount;
        uint outcome = bet.outcome;
        uint winAmount = bet.winAmount;
        // Fetch bet parameters into local variables (to save gas).
        uint modulo = bet.modulo;
        uint rollEdge = bet.rollEdge;
        address payable gambler = bet.gambler;
        // Record bet settlement in event log.
        emit BetSettled(
            gambler,
            amount,
            s_requestIDToRequestIndex[bet.requestID],
            uint8(modulo),
            uint8(rollEdge),
            bet.mask,
            outcome,
            winAmount
        );
    }

    // Return the bet in extremely unlikely scenario it was not settled by Chainlink VRF.
    // In case you ever find yourself in a situation like this, just contact hashbet support.
    // However, nothing precludes you from calling this method yourself.
    function refundBet(uint256 betID) external payable nonReentrant {
        Bet storage bet = bets[betID];
        uint amount = bet.amount;
        uint betTime = betPlaceTime[betID];

        // Validation check
        require(amount > 0, "Bet does not exist."); // Check that bet exists
        require(bet.isSettled == false, "Bet is settled already."); // Check that bet is still open
        require(
            block.timestamp >= (betTime + 1 hours),
            "Wait after placing bet before requesting refund."
        );

        uint possibleWinAmount = bet.winAmount;

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = amount;

        // Send the refund.
        bet.gambler.transfer(amount);

        // Record refund in event logs
        emit BetRefunded(bet.gambler, amount);

        delete (s_requestIDToRequestIndex[bet.requestID]);
        delete (betPlaceTime[betID]);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /**
     * @dev calculates in form of native token the fee charged by chainlink VRF
     * @return VRFfee amount of fee user has to pay
     */
    function getVRFFee(uint gasPrice) public view returns (uint256 VRFfee) {
        uint link = VRF_V2_WRAPPER.estimateRequestPrice(
            callbackGasLimit,
            gasPrice
        );
        VRFfee = (link * uint256(getLatestData())) / 1e18;
    }

    // Check the sequencer status (L2 networks) and return the latest data
    function getLatestData() public view returns (int) {
        if (sequencerUptimeFeed != AggregatorV2V3Interface(address(0))) {
            // prettier-ignore
            (
                /*uint80 roundID*/,
                int256 answer,
                uint256 startedAt,
                /*uint256 updatedAt*/,
                /*uint80 answeredInRound*/
            ) = sequencerUptimeFeed.latestRoundData();

            // Answer == 0: Sequencer is up
            // Answer == 1: Sequencer is down
            bool isSequencerUp = answer == 0;
            if (!isSequencerUp) {
                revert SequencerDown();
            }

            // Make sure the grace period has passed after the
            // sequencer is back up.
            uint256 timeSinceUp = block.timestamp - startedAt;
            if (timeSinceUp <= GRACE_PERIOD_TIME) {
                revert GracePeriodNotOver();
            }
        }

        // prettier-ignore
        (
            uint80 roundID,
            int256 price,
            , 
            ,
            uint80 answeredInRound
        ) = dataFeed.latestRoundData();
        require(answeredInRound >= roundID, "Stale price");
        require(price > 0, "Invalid price");

        return price;
    }

    // Check arguments
    function validateArguments(
        uint amount,
        uint betMask,
        uint modulo
    ) private view {
        // Validate input data.
        require(
            modulo == 2 ||
                modulo == 6 ||
                modulo == 36 ||
                modulo == 37 ||
                modulo == 100,
            "Modulo should be valid value."
        );
        require(
            amount >= minBetAmount && amount <= maxBetAmount,
            "Bet amount should be within range."
        );

        if (modulo <= MAX_MASK_MODULO) {
            require(
                betMask > 0 && betMask < MAX_BET_MASK,
                "Mask should be within range."
            );
        }

        if (modulo == MAX_MODULO) {
            require(
                betMask >= minOverValue && betMask <= maxUnderValue,
                "High modulo range, Mask should be within range."
            );
        }
    }

    /**
     * @dev function to send the request for randomness to chainlink
     */
    function _requestRandomWords() internal returns (uint256 requestID) {
        requestID = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256 requestID,
        uint256[] memory randomWords
    ) internal override {
        uint256 betID = s_requestIDToRequestIndex[requestID];
        Bet storage bet = bets[betID];
        if (bet.gambler == address(0)) revert();
        uint placeBlockNumber = bet.placeBlockNumber;
        uint betTime = betPlaceTime[betID];

        // Settle bet must be within one hour
        require(
            block.timestamp < (betTime + 1 hours),
            "settleBet has expired."
        );

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require(
            ChainSpecificUtil.getBlockNumber() > placeBlockNumber,
            "settleBet before placeBet"
        );

        // Settle bet using reveal and blockHash as entropy sources.
        settleBetCommon(
            bet,
            randomWords[0]
        );

        delete (s_requestIDToRequestIndex[requestID]);
        delete (betPlaceTime[betID]);
    }

    /**
     * @dev returns to user the excess fee sent to pay for the VRF
     * @param refund amount to send back to user
     */
    function refundExcessValue(uint256 refund) internal {
        if (refund == 0) {
            return;
        }
        (bool success, ) = payable(msg.sender).call{value: refund}("");
        if (!success) {
            revert RefundFailed();
        }
    }

    function checkVRFFee(uint betAmount, uint gasPrice) internal {
        uint256 VRFfee = getVRFFee(gasPrice);

        if (msg.value < betAmount + VRFfee) {
            revert InvalidValue(betAmount + VRFfee, msg.value);
        }
        refundExcessValue(msg.value - (VRFfee + betAmount));
    }

    function getModuloHouseEdgePercent(
        uint32 modulo
    ) internal view returns (uint32 houseEdgePercent) {
        houseEdgePercent = houseEdgePercents[modulo];
        if (houseEdgePercent == 0) {
            houseEdgePercent = uint32(defaultHouseEdgePercent);
        }
    }
}