// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ArbSys} from "./vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import {ArbGasInfo} from "./vendor/@arbitrum/nitro-contracts/src/precompiles/ArbGasInfo.sol";
import {OVM_GasPriceOracle} from "./vendor/@eth-optimism/contracts/v0.8.9/contracts/L2/predeploys/OVM_GasPriceOracle.sol";

/// @dev A library that abstracts out opcodes that behave differently across chains.
/// @dev The methods below return values that are pertinent to the given chain.
/// @dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
  // ------------ Start Arbitrum Constants ------------

  /// @dev ARBSYS_ADDR is the address of the ArbSys precompile on Arbitrum.
  /// @dev reference: https://github.com/OffchainLabs/nitro/blob/v2.0.14/contracts/src/precompiles/ArbSys.sol#L10
  address private constant ARBSYS_ADDR = address(0x0000000000000000000000000000000000000064);
  ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);

  /// @dev ARBGAS_ADDR is the address of the ArbGasInfo precompile on Arbitrum.
  /// @dev reference: https://github.com/OffchainLabs/nitro/blob/v2.0.14/contracts/src/precompiles/ArbGasInfo.sol#L10
  address private constant ARBGAS_ADDR = address(0x000000000000000000000000000000000000006C);
  ArbGasInfo private constant ARBGAS = ArbGasInfo(ARBGAS_ADDR);

  uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
  uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;
  uint256 private constant ARB_SEPOLIA_TESTNET_CHAIN_ID = 421614;

  // ------------ End Arbitrum Constants ------------

  // ------------ Start Optimism Constants ------------
  /// @dev L1_FEE_DATA_PADDING includes 35 bytes for L1 data padding for Optimism
  bytes internal constant L1_FEE_DATA_PADDING =
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  /// @dev OVM_GASPRICEORACLE_ADDR is the address of the OVM_GasPriceOracle precompile on Optimism.
  /// @dev reference: https://community.optimism.io/docs/developers/build/transaction-fees/#estimating-the-l1-data-fee
  address private constant OVM_GASPRICEORACLE_ADDR = address(0x420000000000000000000000000000000000000F);
  OVM_GasPriceOracle private constant OVM_GASPRICEORACLE = OVM_GasPriceOracle(OVM_GASPRICEORACLE_ADDR);

  uint256 private constant OP_MAINNET_CHAIN_ID = 10;
  uint256 private constant OP_GOERLI_CHAIN_ID = 420;
  uint256 private constant OP_SEPOLIA_CHAIN_ID = 11155420;

  /// @dev Base is a OP stack based rollup and follows the same L1 pricing logic as Optimism.
  uint256 private constant BASE_MAINNET_CHAIN_ID = 8453;
  uint256 private constant BASE_GOERLI_CHAIN_ID = 84531;

  // ------------ End Optimism Constants ------------

  /**
   * @notice Returns the blockhash for the given blockNumber.
   * @notice If the blockNumber is more than 256 blocks in the past, returns the empty string.
   * @notice When on a known Arbitrum chain, it uses ArbSys.arbBlockHash to get the blockhash.
   * @notice Otherwise, it uses the blockhash opcode.
   * @notice Note that the blockhash opcode will return the L2 blockhash on Optimism.
   */
  function _getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      if ((_getBlockNumber() - blockNumber) > 256 || blockNumber >= _getBlockNumber()) {
        return "";
      }
      return ARBSYS.arbBlockHash(blockNumber);
    }
    return blockhash(blockNumber);
  }

  /**
   * @notice Returns the block number of the current block.
   * @notice When on a known Arbitrum chain, it uses ArbSys.arbBlockNumber to get the block number.
   * @notice Otherwise, it uses the block.number opcode.
   * @notice Note that the block.number opcode will return the L2 block number on Optimism.
   */
  function _getBlockNumber() internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      return ARBSYS.arbBlockNumber();
    }
    return block.number;
  }

  /**
   * @notice Returns the L1 fees that will be paid for the current transaction, given any calldata
   * @notice for the current transaction.
   * @notice When on a known Arbitrum chain, it uses ArbGas.getCurrentTxL1GasFees to get the fees.
   * @notice On Arbitrum, the provided calldata is not used to calculate the fees.
   * @notice On Optimism, the provided calldata is passed to the OVM_GasPriceOracle predeploy
   * @notice and getL1Fee is called to get the fees.
   */
  function _getCurrentTxL1GasFees(bytes memory txCallData) internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      return ARBGAS.getCurrentTxL1GasFees();
    } else if (_isOptimismChainId(chainid)) {
      return OVM_GASPRICEORACLE.getL1Fee(bytes.concat(txCallData, L1_FEE_DATA_PADDING));
    }
    return 0;
  }

  /**
   * @notice Returns the gas cost in wei of calldataSizeBytes of calldata being posted
   * @notice to L1.
   */
  function _getL1CalldataGasCost(uint256 calldataSizeBytes) internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      (, uint256 l1PricePerByte, , , , ) = ARBGAS.getPricesInWei();
      // see https://developer.arbitrum.io/devs-how-tos/how-to-estimate-gas#where-do-we-get-all-this-information-from
      // for the justification behind the 140 number.
      return l1PricePerByte * (calldataSizeBytes + 140);
    } else if (_isOptimismChainId(chainid)) {
      return _calculateOptimismL1DataFee(calldataSizeBytes);
    }
    return 0;
  }

  /**
   * @notice Return true if and only if the provided chain ID is an Arbitrum chain ID.
   */
  function _isArbitrumChainId(uint256 chainId) internal pure returns (bool) {
    return
      chainId == ARB_MAINNET_CHAIN_ID ||
      chainId == ARB_GOERLI_TESTNET_CHAIN_ID ||
      chainId == ARB_SEPOLIA_TESTNET_CHAIN_ID;
  }

  /**
   * @notice Return true if and only if the provided chain ID is an Optimism chain ID.
   * @notice Note that optimism chain id's are also OP stack chain id's.
   */
  function _isOptimismChainId(uint256 chainId) internal pure returns (bool) {
    return
      chainId == OP_MAINNET_CHAIN_ID ||
      chainId == OP_GOERLI_CHAIN_ID ||
      chainId == OP_SEPOLIA_CHAIN_ID ||
      chainId == BASE_MAINNET_CHAIN_ID ||
      chainId == BASE_GOERLI_CHAIN_ID;
  }

  function _calculateOptimismL1DataFee(uint256 calldataSizeBytes) internal view returns (uint256) {
    // from: https://community.optimism.io/docs/developers/build/transaction-fees/#the-l1-data-fee
    // l1_data_fee = l1_gas_price * (tx_data_gas + fixed_overhead) * dynamic_overhead
    // tx_data_gas = count_zero_bytes(tx_data) * 4 + count_non_zero_bytes(tx_data) * 16
    // note we conservatively assume all non-zero bytes.
    uint256 l1BaseFeeWei = OVM_GASPRICEORACLE.l1BaseFee();
    uint256 numZeroBytes = 0;
    uint256 numNonzeroBytes = calldataSizeBytes - numZeroBytes;
    uint256 txDataGas = numZeroBytes * 4 + numNonzeroBytes * 16;
    uint256 fixedOverhead = OVM_GASPRICEORACLE.overhead();

    // The scalar is some value like 0.684, but is represented as
    // that times 10 ^ number of scalar decimals.
    // e.g scalar = 0.684 * 10^6
    // The divisor is used to divide that and have a net result of the true scalar.
    uint256 scalar = OVM_GASPRICEORACLE.scalar();
    uint256 scalarDecimals = OVM_GASPRICEORACLE.decimals();
    uint256 divisor = 10 ** scalarDecimals;

    uint256 l1DataFee = (l1BaseFeeWei * (txDataGas + fixedOverhead) * scalar) / divisor;
    return l1DataFee;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwnerWithProposal} from "./ConfirmedOwnerWithProposal.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from "../interfaces/IOwnable.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line gas-custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line gas-custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
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

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides insight into the cost of using the chain.
/// @notice These methods have been adjusted to account for Nitro's heavy use of calldata compression.
/// Of note to end-users, we no longer make a distinction between non-zero and zero-valued calldata bytes.
/// Precompiled contract that exists in every Arbitrum chain at 0x000000000000000000000000000000000000006c.
interface ArbGasInfo {
    /// @notice Get gas prices for a provided aggregator
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWeiWithAggregator(address aggregator)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    /// @notice Get gas prices. Uses the caller's preferred aggregator, or the default if the caller doesn't have a preferred one.
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWei()
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    /// @notice Get prices in ArbGas for the supplied aggregator
    /// @return (per L2 tx, per L1 calldata byte, per storage allocation)
    function getPricesInArbGasWithAggregator(address aggregator)
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    );

    /// @notice Get prices in ArbGas. Assumes the callers preferred validator, or the default if caller doesn't have a preferred one.
    /// @return (per L2 tx, per L1 calldata byte, per storage allocation)
    function getPricesInArbGas()
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    );

    /// @notice Get the gas accounting parameters. `gasPoolMax` is always zero, as the exponential pricing model has no such notion.
    /// @return (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams()
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    );

    /// @notice Get the minimum gas price needed for a tx to succeed
    function getMinimumGasPrice() external view returns (uint256);

    /// @notice Get ArbOS's estimate of the L1 basefee in wei
    function getL1BaseFeeEstimate() external view returns (uint256);

    /// @notice Get how slowly ArbOS updates its estimate of the L1 basefee
    function getL1BaseFeeEstimateInertia() external view returns (uint64);

    /// @notice Get the L1 pricer reward rate, in wei per unit
    /// Available in ArbOS version 11
    function getL1RewardRate() external view returns (uint64);

    /// @notice Get the L1 pricer reward recipient
    /// Available in ArbOS version 11
    function getL1RewardRecipient() external view returns (address);

    /// @notice Deprecated -- Same as getL1BaseFeeEstimate()
    function getL1GasPriceEstimate() external view returns (uint256);

    /// @notice Get L1 gas fees paid by the current transaction
    function getCurrentTxL1GasFees() external view returns (uint256);

    /// @notice Get the backlogged amount of gas burnt in excess of the speed limit
    function getGasBacklog() external view returns (uint64);

    /// @notice Get how slowly ArbOS updates the L2 basefee in response to backlogged gas
    function getPricingInertia() external view returns (uint64);

    /// @notice Get the forgivable amount of backlogged gas ArbOS will ignore when raising the basefee
    function getGasBacklogTolerance() external view returns (uint64);

    /// @notice Returns the surplus of funds for L1 batch posting payments (may be negative).
    function getL1PricingSurplus() external view returns (int256);

    /// @notice Returns the base charge (in L1 gas) attributed to each data batch in the calldata pricer
    function getPerBatchGasCharge() external view returns (int64);

    /// @notice Returns the cost amortization cap in basis points
    function getAmortizedCostCapBips() external view returns (uint64);

    /// @notice Returns the available funds from L1 fees
    function getL1FeesAvailable() external view returns (uint256);

    /// @notice Returns the equilibration units parameter for L1 price adjustment algorithm
    /// Available in ArbOS version 20
    function getL1PricingEquilibrationUnits() external view returns (uint256);

    /// @notice Returns the last time the L1 calldata pricer was updated.
    /// Available in ArbOS version 20
    function getLastL1PricingUpdateTime() external view returns (uint64);

    /// @notice Returns the amount of L1 calldata payments due for rewards (per the L1 reward rate)
    /// Available in ArbOS version 20
    function getL1PricingFundsDueForRewards() external view returns (uint256);

    /// @notice Returns the amount of L1 calldata posted since the last update.
    /// Available in ArbOS version 20
    function getL1PricingUnitsSinceUpdate() external view returns (uint64);

    /// @notice Returns the L1 pricing surplus as of the last update (may be negative).
    /// Available in ArbOS version 20
    function getLastL1PricingSurplus() external view returns (int256);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
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
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

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
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* External Imports */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OVM_GasPriceOracle
 * @dev This contract exposes the current l2 gas price, a measure of how congested the network
 * currently is. This measure is used by the Sequencer to determine what fee to charge for
 * transactions. When the system is more congested, the l2 gas price will increase and fees
 * will also increase as a result.
 *
 * All public variables are set while generating the initial L2 state. The
 * constructor doesn't run in practice as the L2 state generation script uses
 * the deployed bytecode instead of running the initcode.
 */
contract OVM_GasPriceOracle is Ownable {
  /*************
   * Variables *
   *************/

  // Current L2 gas price
  uint256 public gasPrice;
  // Current L1 base fee
  uint256 public l1BaseFee;
  // Amortized cost of batch submission per transaction
  uint256 public overhead;
  // Value to scale the fee up by
  uint256 public scalar;
  // Number of decimals of the scalar
  uint256 public decimals;

  /***************
   * Constructor *
   ***************/

  /**
   * @param _owner Address that will initially own this contract.
   */
  constructor(address _owner) Ownable() {
    transferOwnership(_owner);
  }

  /**********
   * Events *
   **********/

  event GasPriceUpdated(uint256);
  event L1BaseFeeUpdated(uint256);
  event OverheadUpdated(uint256);
  event ScalarUpdated(uint256);
  event DecimalsUpdated(uint256);

  /********************
   * Public Functions *
   ********************/

  /**
   * Allows the owner to modify the l2 gas price.
   * @param _gasPrice New l2 gas price.
   */
  // slither-disable-next-line external-function
  function setGasPrice(uint256 _gasPrice) public onlyOwner {
    gasPrice = _gasPrice;
    emit GasPriceUpdated(_gasPrice);
  }

  /**
   * Allows the owner to modify the l1 base fee.
   * @param _baseFee New l1 base fee
   */
  // slither-disable-next-line external-function
  function setL1BaseFee(uint256 _baseFee) public onlyOwner {
    l1BaseFee = _baseFee;
    emit L1BaseFeeUpdated(_baseFee);
  }

  /**
   * Allows the owner to modify the overhead.
   * @param _overhead New overhead
   */
  // slither-disable-next-line external-function
  function setOverhead(uint256 _overhead) public onlyOwner {
    overhead = _overhead;
    emit OverheadUpdated(_overhead);
  }

  /**
   * Allows the owner to modify the scalar.
   * @param _scalar New scalar
   */
  // slither-disable-next-line external-function
  function setScalar(uint256 _scalar) public onlyOwner {
    scalar = _scalar;
    emit ScalarUpdated(_scalar);
  }

  /**
   * Allows the owner to modify the decimals.
   * @param _decimals New decimals
   */
  // slither-disable-next-line external-function
  function setDecimals(uint256 _decimals) public onlyOwner {
    decimals = _decimals;
    emit DecimalsUpdated(_decimals);
  }

  /**
   * Computes the L1 portion of the fee
   * based on the size of the RLP encoded tx
   * and the current l1BaseFee
   * @param _data Unsigned RLP encoded tx, 6 elements
   * @return L1 fee that should be paid for the tx
   */
  // slither-disable-next-line external-function
  function getL1Fee(bytes memory _data) public view returns (uint256) {
    uint256 l1GasUsed = getL1GasUsed(_data);
    uint256 l1Fee = l1GasUsed * l1BaseFee;
    uint256 divisor = 10 ** decimals;
    uint256 unscaled = l1Fee * scalar;
    uint256 scaled = unscaled / divisor;
    return scaled;
  }

  // solhint-disable max-line-length
  /**
   * Computes the amount of L1 gas used for a transaction
   * The overhead represents the per batch gas overhead of
   * posting both transaction and state roots to L1 given larger
   * batch sizes.
   * 4 gas for 0 byte
   * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L33
   * 16 gas for non zero byte
   * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L87
   * This will need to be updated if calldata gas prices change
   * Account for the transaction being unsigned
   * Padding is added to account for lack of signature on transaction
   * 1 byte for RLP V prefix
   * 1 byte for V
   * 1 byte for RLP R prefix
   * 32 bytes for R
   * 1 byte for RLP S prefix
   * 32 bytes for S
   * Total: 68 bytes of padding
   * @param _data Unsigned RLP encoded tx, 6 elements
   * @return Amount of L1 gas used for a transaction
   */
  // solhint-enable max-line-length
  function getL1GasUsed(bytes memory _data) public view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < _data.length; i++) {
      if (_data[i] == 0) {
        total += 4;
      } else {
        total += 16;
      }
    }
    uint256 unsigned = total + overhead;
    return unsigned + (68 * 16);
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
pragma solidity ^0.8.4;

import {IVRFCoordinatorV2Plus} from "./interfaces/IVRFCoordinatorV2Plus.sol";
import {IVRFMigratableConsumerV2Plus} from "./interfaces/IVRFMigratableConsumerV2Plus.sol";
import {ConfirmedOwner} from "../../shared/access/ConfirmedOwner.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinatorV2Plus.
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBaseV2Plus, and can
 * @dev initialize VRFConsumerBaseV2Plus's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumerV2Plus is VRFConsumerBaseV2Plus {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _subOwner)
 * @dev       VRFConsumerBaseV2Plus(_vrfCoordinator, _subOwner) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create a subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords, extraArgs),
 * @dev see (IVRFCoordinatorV2Plus for a description of the arguments).
 *
 * @dev Once the VRFCoordinatorV2Plus has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBaseV2Plus.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2Plus expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
    if (msg.sender != address(s_vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(s_vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  /**
   * @inheritdoc IVRFMigratableConsumerV2Plus
   */
  function setCoordinator(address _vrfCoordinator) external override onlyOwnerOrCoordinator {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);

    emit CoordinatorSet(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ConfirmedOwner} from "../../shared/access/ConfirmedOwner.sol";
import {TypeAndVersionInterface} from "../../interfaces/TypeAndVersionInterface.sol";
import {VRFConsumerBaseV2Plus} from "./VRFConsumerBaseV2Plus.sol";
import {LinkTokenInterface} from "../../shared/interfaces/LinkTokenInterface.sol";
import {AggregatorV3Interface} from "../../shared/interfaces/AggregatorV3Interface.sol";
import {VRFV2PlusClient} from "./libraries/VRFV2PlusClient.sol";
import {IVRFV2PlusWrapper} from "./interfaces/IVRFV2PlusWrapper.sol";
import {VRFV2PlusWrapperConsumerBase} from "./VRFV2PlusWrapperConsumerBase.sol";
import {ChainSpecificUtil} from "../../ChainSpecificUtil.sol";

/**
 * @notice A wrapper for VRFCoordinatorV2 that provides an interface better suited to one-off
 * @notice requests for randomness.
 */
// solhint-disable-next-line max-states-count
contract VRFV2PlusWrapper is ConfirmedOwner, TypeAndVersionInterface, VRFConsumerBaseV2Plus, IVRFV2PlusWrapper {
  event WrapperFulfillmentFailed(uint256 indexed requestId, address indexed consumer);

  // upper bound limit for premium percentages to make sure fee calculations don't overflow
  uint8 private constant PREMIUM_PERCENTAGE_MAX = 155;

  // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
  // and some arithmetic operations.
  uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
  uint16 private constant EXPECTED_MIN_LENGTH = 36;

  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
  uint256 public immutable SUBSCRIPTION_ID;
  LinkTokenInterface internal immutable i_link;
  AggregatorV3Interface internal immutable i_link_native_feed;

  event FulfillmentTxSizeSet(uint32 size);
  event ConfigSet(
    uint32 wrapperGasOverhead,
    uint32 coordinatorGasOverheadNative,
    uint32 coordinatorGasOverheadLink,
    uint16 coordinatorGasOverheadPerWord,
    uint8 coordinatorNativePremiumPercentage,
    uint8 coordinatorLinkPremiumPercentage,
    bytes32 keyHash,
    uint8 maxNumWords,
    uint32 stalenessSeconds,
    int256 fallbackWeiPerUnitLink,
    uint32 fulfillmentFlatFeeNativePPM,
    uint32 fulfillmentFlatFeeLinkDiscountPPM
  );
  event FallbackWeiPerUnitLinkUsed(uint256 requestId, int256 fallbackWeiPerUnitLink);
  event Withdrawn(address indexed to, uint256 amount);
  event NativeWithdrawn(address indexed to, uint256 amount);
  event Enabled();
  event Disabled();

  error LinkAlreadySet();
  error LinkDiscountTooHigh(uint32 flatFeeLinkDiscountPPM, uint32 flatFeeNativePPM);
  error InvalidPremiumPercentage(uint8 premiumPercentage, uint8 max);
  error FailedToTransferLink();
  error IncorrectExtraArgsLength(uint16 expectedMinimumLength, uint16 actualLength);
  error NativePaymentInOnTokenTransfer();
  error LINKPaymentInRequestRandomWordsInNative();
  error SubscriptionIdMissing();

  /* Storage Slot 1: BEGIN */
  // 20 bytes used by VRFConsumerBaseV2Plus.s_vrfCoordinator

  // s_configured tracks whether this contract has been configured. If not configured, randomness
  // requests cannot be made.
  bool public s_configured;

  // s_disabled disables the contract when true. When disabled, new VRF requests cannot be made
  // but existing ones can still be fulfilled.
  bool public s_disabled;

  // s_maxNumWords is the max number of words that can be requested in a single wrapped VRF request.
  uint8 internal s_maxNumWords;

  // 9 bytes left
  /* Storage Slot 1: END */

  /* Storage Slot 2: BEGIN */
  // s_keyHash is the key hash to use when requesting randomness. Fees are paid based on current gas
  // fees, so this should be set to the highest gas lane on the network.
  bytes32 internal s_keyHash;
  /* Storage Slot 2: END */

  /* Storage Slot 3: BEGIN */
  // lastRequestId is the request ID of the most recent VRF V2 request made by this wrapper. This
  // should only be relied on within the same transaction the request was made.
  uint256 public override lastRequestId;
  /* Storage Slot 3: END */

  /* Storage Slot 4: BEGIN */
  // s_fallbackWeiPerUnitLink is the backup LINK exchange rate used when the LINK/NATIVE feed is
  // stale.
  int256 private s_fallbackWeiPerUnitLink;
  /* Storage Slot 4: END */

  /* Storage Slot 5: BEGIN */
  // s_stalenessSeconds is the number of seconds before we consider the feed price to be stale and
  // fallback to fallbackWeiPerUnitLink.
  uint32 private s_stalenessSeconds;

  // s_wrapperGasOverhead reflects the gas overhead of the wrapper's fulfillRandomWords
  // function. The cost for this gas is passed to the user.
  uint32 private s_wrapperGasOverhead;

  // Configuration fetched from VRFCoordinatorV2

  /// @dev this is the size of a VRF v2 fulfillment's calldata abi-encoded in bytes.
  /// @dev proofSize = 13 words = 13 * 256 = 3328 bits
  /// @dev commitmentSize = 5 words = 5 * 256 = 1280 bits
  /// @dev dataSize = proofSize + commitmentSize = 4608 bits
  /// @dev selector = 32 bits
  /// @dev total data size = 4608 bits + 32 bits = 4640 bits = 580 bytes
  uint32 public s_fulfillmentTxSizeBytes = 580;

  // s_coordinatorGasOverheadNative reflects the gas overhead of the coordinator's fulfillRandomWords
  // function for native payment. The cost for this gas is billed to the subscription, and must therefor be included
  // in the pricing for wrapped requests. This includes the gas costs of proof verification and
  // payment calculation in the coordinator.
  uint32 private s_coordinatorGasOverheadNative;

  // s_coordinatorGasOverheadLink reflects the gas overhead of the coordinator's fulfillRandomWords
  // function for link payment. The cost for this gas is billed to the subscription, and must therefor be included
  // in the pricing for wrapped requests. This includes the gas costs of proof verification and
  // payment calculation in the coordinator.
  uint32 private s_coordinatorGasOverheadLink;

  uint16 private s_coordinatorGasOverheadPerWord;

  // s_fulfillmentFlatFeeLinkPPM is the flat fee in millionths of native that VRFCoordinatorV2
  // charges for native payment.
  uint32 private s_fulfillmentFlatFeeNativePPM;

  // s_fulfillmentFlatFeeLinkDiscountPPM is the flat fee discount in millionths of native that VRFCoordinatorV2
  // charges for link payment.
  uint32 private s_fulfillmentFlatFeeLinkDiscountPPM;

  // s_coordinatorNativePremiumPercentage is the coordinator's premium ratio in percentage for native payment.
  // For example, a value of 0 indicates no premium. A value of 15 indicates a 15 percent premium.
  // Wrapper has no premium. This premium is for VRFCoordinator.
  uint8 private s_coordinatorNativePremiumPercentage;

  // s_coordinatorLinkPremiumPercentage is the premium ratio in percentage for link payment. For example, a
  // value of 0 indicates no premium. A value of 15 indicates a 15 percent premium.
  // Wrapper has no premium. This premium is for VRFCoordinator.
  uint8 private s_coordinatorLinkPremiumPercentage;
  /* Storage Slot 5: END */

  struct Callback {
    address callbackAddress;
    uint32 callbackGasLimit;
    // Reducing requestGasPrice from uint256 to uint64 slots Callback struct
    // into a single word, thus saving an entire SSTORE and leading to 21K
    // gas cost saving. 18 ETH would be the max gas price we can process.
    // GasPrice is unlikely to be more than 14 ETH on most chains
    uint64 requestGasPrice;
  }
  /* Storage Slot 6: BEGIN */
  mapping(uint256 => Callback) /* requestID */ /* callback */ public s_callbacks;
  /* Storage Slot 6: END */

  constructor(
    address _link,
    address _linkNativeFeed,
    address _coordinator,
    uint256 _subId
  ) VRFConsumerBaseV2Plus(_coordinator) {
    i_link = LinkTokenInterface(_link);
    i_link_native_feed = AggregatorV3Interface(_linkNativeFeed);

    if (_subId == 0) {
      revert SubscriptionIdMissing();
    }

    // Sanity check: should revert if the subscription does not exist
    s_vrfCoordinator.getSubscription(_subId);

    // Subscription for the wrapper is created and managed by an external account.
    // Expectation is that wrapper contract address will be added as a consumer
    // to this subscription by the external account (owner of the subscription).
    // Migration of the wrapper's subscription to the new coordinator has to be
    // handled by the external account (owner of the subscription).
    SUBSCRIPTION_ID = _subId;
  }

  /**
   * @notice setFulfillmentTxSize sets the size of the fulfillment transaction in bytes.
   * @param size is the size of the fulfillment transaction in bytes.
   */
  function setFulfillmentTxSize(uint32 size) external onlyOwner {
    s_fulfillmentTxSizeBytes = size;

    emit FulfillmentTxSizeSet(size);
  }

  /**
   * @notice setConfig configures VRFV2Wrapper.
   *
   * @dev Sets wrapper-specific configuration based on the given parameters, and fetches any needed
   * @dev VRFCoordinatorV2 configuration from the coordinator.
   *
   * @param _wrapperGasOverhead reflects the gas overhead of the wrapper's fulfillRandomWords
   *        function.
   *
   * @param _coordinatorGasOverheadNative reflects the gas overhead of the coordinator's
   *        fulfillRandomWords function for native payment.
   *
   * @param _coordinatorGasOverheadLink reflects the gas overhead of the coordinator's
   *        fulfillRandomWords function for link payment.
   *
   * @param _coordinatorGasOverheadPerWord reflects the gas overhead per word of the coordinator's
   *        fulfillRandomWords function.
   *
   * @param _coordinatorNativePremiumPercentage is the coordinator's premium ratio in percentage for requests paid in native.
   *
   * @param _coordinatorLinkPremiumPercentage is the coordinator's premium ratio in percentage for requests paid in link.
   *
   * @param _keyHash to use for requesting randomness.
   * @param _maxNumWords is the max number of words that can be requested in a single wrapped VRF request
   * @param _stalenessSeconds is the number of seconds before we consider the feed price to be stale
   *        and fallback to fallbackWeiPerUnitLink.
   *
   * @param _fallbackWeiPerUnitLink is the backup LINK exchange rate used when the LINK/NATIVE feed
   *        is stale.
   *
   * @param _fulfillmentFlatFeeNativePPM is the flat fee in millionths of native that VRFCoordinatorV2Plus
   *        charges for native payment.
   *
   * @param _fulfillmentFlatFeeLinkDiscountPPM is the flat fee discount in millionths of native that VRFCoordinatorV2Plus
   *        charges for link payment.
   */
  function setConfig(
    uint32 _wrapperGasOverhead,
    uint32 _coordinatorGasOverheadNative,
    uint32 _coordinatorGasOverheadLink,
    uint16 _coordinatorGasOverheadPerWord,
    uint8 _coordinatorNativePremiumPercentage,
    uint8 _coordinatorLinkPremiumPercentage,
    bytes32 _keyHash,
    uint8 _maxNumWords,
    uint32 _stalenessSeconds,
    int256 _fallbackWeiPerUnitLink,
    uint32 _fulfillmentFlatFeeNativePPM,
    uint32 _fulfillmentFlatFeeLinkDiscountPPM
  ) external onlyOwner {
    if (_fulfillmentFlatFeeLinkDiscountPPM > _fulfillmentFlatFeeNativePPM) {
      revert LinkDiscountTooHigh(_fulfillmentFlatFeeLinkDiscountPPM, _fulfillmentFlatFeeNativePPM);
    }
    if (_coordinatorNativePremiumPercentage > PREMIUM_PERCENTAGE_MAX) {
      revert InvalidPremiumPercentage(_coordinatorNativePremiumPercentage, PREMIUM_PERCENTAGE_MAX);
    }
    if (_coordinatorLinkPremiumPercentage > PREMIUM_PERCENTAGE_MAX) {
      revert InvalidPremiumPercentage(_coordinatorLinkPremiumPercentage, PREMIUM_PERCENTAGE_MAX);
    }

    s_wrapperGasOverhead = _wrapperGasOverhead;
    s_coordinatorGasOverheadNative = _coordinatorGasOverheadNative;
    s_coordinatorGasOverheadLink = _coordinatorGasOverheadLink;
    s_coordinatorGasOverheadPerWord = _coordinatorGasOverheadPerWord;
    s_coordinatorNativePremiumPercentage = _coordinatorNativePremiumPercentage;
    s_coordinatorLinkPremiumPercentage = _coordinatorLinkPremiumPercentage;
    s_keyHash = _keyHash;
    s_maxNumWords = _maxNumWords;
    s_configured = true;

    // Get other configuration from coordinator
    s_stalenessSeconds = _stalenessSeconds;
    s_fallbackWeiPerUnitLink = _fallbackWeiPerUnitLink;
    s_fulfillmentFlatFeeNativePPM = _fulfillmentFlatFeeNativePPM;
    s_fulfillmentFlatFeeLinkDiscountPPM = _fulfillmentFlatFeeLinkDiscountPPM;

    emit ConfigSet(
      _wrapperGasOverhead,
      _coordinatorGasOverheadNative,
      _coordinatorGasOverheadLink,
      _coordinatorGasOverheadPerWord,
      _coordinatorNativePremiumPercentage,
      _coordinatorLinkPremiumPercentage,
      _keyHash,
      _maxNumWords,
      _stalenessSeconds,
      _fallbackWeiPerUnitLink,
      _fulfillmentFlatFeeNativePPM,
      s_fulfillmentFlatFeeLinkDiscountPPM
    );
  }

  /**
   * @notice getConfig returns the current VRFV2Wrapper configuration.
   *
   * @return fallbackWeiPerUnitLink is the backup LINK exchange rate used when the LINK/NATIVE feed
   *         is stale.
   *
   * @return stalenessSeconds is the number of seconds before we consider the feed price to be stale
   *         and fallback to fallbackWeiPerUnitLink.
   *
   * @return fulfillmentFlatFeeNativePPM is the flat fee in millionths of native that VRFCoordinatorV2Plus
   *         charges for native payment.
   *
   * @return fulfillmentFlatFeeLinkDiscountPPM is the flat fee discount in millionths of native that VRFCoordinatorV2Plus
   *         charges for link payment.
   *
   * @return wrapperGasOverhead reflects the gas overhead of the wrapper's fulfillRandomWords
   *         function. The cost for this gas is passed to the user.
   *
   * @return coordinatorGasOverheadNative reflects the gas overhead of the coordinator's
   *         fulfillRandomWords function for native payment.
   *
   * @return coordinatorGasOverheadLink reflects the gas overhead of the coordinator's
   *         fulfillRandomWords function for link payment.
   *
   * @return coordinatorGasOverheadPerWord reflects the gas overhead per word of the coordinator's
   *         fulfillRandomWords function.
   *
   * @return wrapperNativePremiumPercentage is the premium ratio in percentage for native payment. For example, a value of 0
   *         indicates no premium. A value of 15 indicates a 15 percent premium.
   *
   * @return wrapperLinkPremiumPercentage is the premium ratio in percentage for link payment. For example, a value of 0
   *         indicates no premium. A value of 15 indicates a 15 percent premium.
   *
   * @return keyHash is the key hash to use when requesting randomness. Fees are paid based on
   *         current gas fees, so this should be set to the highest gas lane on the network.
   *
   * @return maxNumWords is the max number of words that can be requested in a single wrapped VRF
   *         request.
   */
  function getConfig()
    external
    view
    returns (
      int256 fallbackWeiPerUnitLink,
      uint32 stalenessSeconds,
      uint32 fulfillmentFlatFeeNativePPM,
      uint32 fulfillmentFlatFeeLinkDiscountPPM,
      uint32 wrapperGasOverhead,
      uint32 coordinatorGasOverheadNative,
      uint32 coordinatorGasOverheadLink,
      uint16 coordinatorGasOverheadPerWord,
      uint8 wrapperNativePremiumPercentage,
      uint8 wrapperLinkPremiumPercentage,
      bytes32 keyHash,
      uint8 maxNumWords
    )
  {
    return (
      s_fallbackWeiPerUnitLink,
      s_stalenessSeconds,
      s_fulfillmentFlatFeeNativePPM,
      s_fulfillmentFlatFeeLinkDiscountPPM,
      s_wrapperGasOverhead,
      s_coordinatorGasOverheadNative,
      s_coordinatorGasOverheadLink,
      s_coordinatorGasOverheadPerWord,
      s_coordinatorNativePremiumPercentage,
      s_coordinatorLinkPremiumPercentage,
      s_keyHash,
      s_maxNumWords
    );
  }

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(
    uint32 _callbackGasLimit,
    uint32 _numWords
  ) external view override onlyConfiguredNotDisabled returns (uint256) {
    (int256 weiPerUnitLink, ) = _getFeedData();
    return _calculateRequestPrice(_callbackGasLimit, _numWords, tx.gasprice, weiPerUnitLink);
  }

  function calculateRequestPriceNative(
    uint32 _callbackGasLimit,
    uint32 _numWords
  ) external view override onlyConfiguredNotDisabled returns (uint256) {
    return _calculateRequestPriceNative(_callbackGasLimit, _numWords, tx.gasprice);
  }

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(
    uint32 _callbackGasLimit,
    uint32 _numWords,
    uint256 _requestGasPriceWei
  ) external view override onlyConfiguredNotDisabled returns (uint256) {
    (int256 weiPerUnitLink, ) = _getFeedData();
    return _calculateRequestPrice(_callbackGasLimit, _numWords, _requestGasPriceWei, weiPerUnitLink);
  }

  function estimateRequestPriceNative(
    uint32 _callbackGasLimit,
    uint32 _numWords,
    uint256 _requestGasPriceWei
  ) external view override onlyConfiguredNotDisabled returns (uint256) {
    return _calculateRequestPriceNative(_callbackGasLimit, _numWords, _requestGasPriceWei);
  }

  function _calculateRequestPriceNative(
    uint256 _gas,
    uint32 _numWords,
    uint256 _requestGasPrice
  ) internal view returns (uint256) {
    // costWei is the base fee denominated in wei (native)
    // (wei/gas) * gas
    uint256 wrapperCostWei = _requestGasPrice * s_wrapperGasOverhead;

    // coordinatorCostWei takes into account the L1 posting costs of the VRF fulfillment transaction, if we are on an L2.
    // (wei/gas) * gas + l1wei
    uint256 coordinatorCostWei = _requestGasPrice *
      (_gas + _getCoordinatorGasOverhead(_numWords, true)) +
      ChainSpecificUtil._getL1CalldataGasCost(s_fulfillmentTxSizeBytes);

    // coordinatorCostWithPremiumAndFlatFeeWei is the coordinator cost with the percentage premium and flat fee applied
    // coordinator cost * premium multiplier + flat fee
    uint256 coordinatorCostWithPremiumAndFlatFeeWei = ((coordinatorCostWei *
      (s_coordinatorNativePremiumPercentage + 100)) / 100) + (1e12 * uint256(s_fulfillmentFlatFeeNativePPM));

    return wrapperCostWei + coordinatorCostWithPremiumAndFlatFeeWei;
  }

  function _calculateRequestPrice(
    uint256 _gas,
    uint32 _numWords,
    uint256 _requestGasPrice,
    int256 _weiPerUnitLink
  ) internal view returns (uint256) {
    // costWei is the base fee denominated in wei (native)
    // (wei/gas) * gas
    uint256 wrapperCostWei = _requestGasPrice * s_wrapperGasOverhead;

    // coordinatorCostWei takes into account the L1 posting costs of the VRF fulfillment transaction, if we are on an L2.
    // (wei/gas) * gas + l1wei
    uint256 coordinatorCostWei = _requestGasPrice *
      (_gas + _getCoordinatorGasOverhead(_numWords, false)) +
      ChainSpecificUtil._getL1CalldataGasCost(s_fulfillmentTxSizeBytes);

    // coordinatorCostWithPremiumAndFlatFeeWei is the coordinator cost with the percentage premium and flat fee applied
    // coordinator cost * premium multiplier + flat fee
    uint256 coordinatorCostWithPremiumAndFlatFeeWei = ((coordinatorCostWei *
      (s_coordinatorLinkPremiumPercentage + 100)) / 100) +
      (1e12 * uint256(s_fulfillmentFlatFeeNativePPM - s_fulfillmentFlatFeeLinkDiscountPPM));

    // requestPrice is denominated in juels (link)
    // (1e18 juels/link) * wei / (wei/link) = juels
    return (1e18 * (wrapperCostWei + coordinatorCostWithPremiumAndFlatFeeWei)) / uint256(_weiPerUnitLink);
  }

  /**
   * @notice onTokenTransfer is called by LinkToken upon payment for a VRF request.
   *
   * @dev Reverts if payment is too low.
   *
   * @param _sender is the sender of the payment, and the address that will receive a VRF callback
   *        upon fulfillment.
   *
   * @param _amount is the amount of LINK paid in Juels.
   *
   * @param _data is the abi-encoded VRF request parameters: uint32 callbackGasLimit,
   *        uint16 requestConfirmations, and uint32 numWords.
   */
  function onTokenTransfer(address _sender, uint256 _amount, bytes calldata _data) external onlyConfiguredNotDisabled {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == address(i_link), "only callable from LINK");

    (uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords, bytes memory extraArgs) = abi.decode(
      _data,
      (uint32, uint16, uint32, bytes)
    );
    checkPaymentMode(extraArgs, true);
    uint32 eip150Overhead = _getEIP150Overhead(callbackGasLimit);
    (int256 weiPerUnitLink, bool isFeedStale) = _getFeedData();
    uint256 price = _calculateRequestPrice(callbackGasLimit, numWords, tx.gasprice, weiPerUnitLink);
    // solhint-disable-next-line gas-custom-errors
    require(_amount >= price, "fee too low");
    // solhint-disable-next-line gas-custom-errors
    require(numWords <= s_maxNumWords, "numWords too high");
    VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
      keyHash: s_keyHash,
      subId: SUBSCRIPTION_ID,
      requestConfirmations: requestConfirmations,
      callbackGasLimit: callbackGasLimit + eip150Overhead + s_wrapperGasOverhead,
      numWords: numWords,
      extraArgs: extraArgs // empty extraArgs defaults to link payment
    });
    uint256 requestId = s_vrfCoordinator.requestRandomWords(req);
    s_callbacks[requestId] = Callback({
      callbackAddress: _sender,
      callbackGasLimit: callbackGasLimit,
      requestGasPrice: uint64(tx.gasprice)
    });
    lastRequestId = requestId;

    if (isFeedStale) {
      emit FallbackWeiPerUnitLinkUsed(requestId, s_fallbackWeiPerUnitLink);
    }
  }

  function checkPaymentMode(bytes memory extraArgs, bool isLinkMode) public pure {
    // If extraArgs is empty, payment mode is LINK by default
    if (extraArgs.length == 0) {
      if (!isLinkMode) {
        revert LINKPaymentInRequestRandomWordsInNative();
      }
      return;
    }
    if (extraArgs.length < EXPECTED_MIN_LENGTH) {
      revert IncorrectExtraArgsLength(EXPECTED_MIN_LENGTH, uint16(extraArgs.length));
    }
    // ExtraArgsV1 only has struct {bool nativePayment} as of now
    // The following condition checks if nativePayment in abi.encode of
    // ExtraArgsV1 matches the appropriate function call (onTokenTransfer
    // for LINK and requestRandomWordsInNative for Native payment)
    bool nativePayment = extraArgs[35] == hex"01";
    if (nativePayment && isLinkMode) {
      revert NativePaymentInOnTokenTransfer();
    }
    if (!nativePayment && !isLinkMode) {
      revert LINKPaymentInRequestRandomWordsInNative();
    }
  }

  function requestRandomWordsInNative(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords,
    bytes calldata extraArgs
  ) external payable override onlyConfiguredNotDisabled returns (uint256 requestId) {
    checkPaymentMode(extraArgs, false);

    uint32 eip150Overhead = _getEIP150Overhead(_callbackGasLimit);
    uint256 price = _calculateRequestPriceNative(_callbackGasLimit, _numWords, tx.gasprice);
    // solhint-disable-next-line gas-custom-errors
    require(msg.value >= price, "fee too low");
    // solhint-disable-next-line gas-custom-errors
    require(_numWords <= s_maxNumWords, "numWords too high");
    VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
      keyHash: s_keyHash,
      subId: SUBSCRIPTION_ID,
      requestConfirmations: _requestConfirmations,
      callbackGasLimit: _callbackGasLimit + eip150Overhead + s_wrapperGasOverhead,
      numWords: _numWords,
      extraArgs: extraArgs
    });
    requestId = s_vrfCoordinator.requestRandomWords(req);
    s_callbacks[requestId] = Callback({
      callbackAddress: msg.sender,
      callbackGasLimit: _callbackGasLimit,
      requestGasPrice: uint64(tx.gasprice)
    });

    return requestId;
  }

  /**
   * @notice withdraw is used by the VRFV2Wrapper's owner to withdraw LINK revenue.
   *
   * @param _recipient is the address that should receive the LINK funds.
   */
  function withdraw(address _recipient) external onlyOwner {
    uint256 amount = i_link.balanceOf(address(this));
    if (!i_link.transfer(_recipient, amount)) {
      revert FailedToTransferLink();
    }

    emit Withdrawn(_recipient, amount);
  }

  /**
   * @notice withdraw is used by the VRFV2Wrapper's owner to withdraw native revenue.
   *
   * @param _recipient is the address that should receive the native funds.
   */
  function withdrawNative(address _recipient) external onlyOwner {
    uint256 amount = address(this).balance;
    (bool success, ) = payable(_recipient).call{value: amount}("");
    // solhint-disable-next-line gas-custom-errors
    require(success, "failed to withdraw native");

    emit NativeWithdrawn(_recipient, amount);
  }

  /**
   * @notice enable this contract so that new requests can be accepted.
   */
  function enable() external onlyOwner {
    s_disabled = false;

    emit Enabled();
  }

  /**
   * @notice disable this contract so that new requests will be rejected. When disabled, new requests
   * @notice will revert but existing requests can still be fulfilled.
   */
  function disable() external onlyOwner {
    s_disabled = true;

    emit Disabled();
  }

  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
    Callback memory callback = s_callbacks[_requestId];
    delete s_callbacks[_requestId];

    address callbackAddress = callback.callbackAddress;
    // solhint-disable-next-line gas-custom-errors
    require(callbackAddress != address(0), "request not found"); // This should never happen

    VRFV2PlusWrapperConsumerBase c;
    bytes memory resp = abi.encodeWithSelector(c.rawFulfillRandomWords.selector, _requestId, _randomWords);

    bool success = _callWithExactGas(callback.callbackGasLimit, callbackAddress, resp);
    if (!success) {
      emit WrapperFulfillmentFailed(_requestId, callbackAddress);
    }
  }

  function link() external view override returns (address) {
    return address(i_link);
  }

  function linkNativeFeed() external view override returns (address) {
    return address(i_link_native_feed);
  }

  function _getFeedData() private view returns (int256 weiPerUnitLink, bool isFeedStale) {
    uint32 stalenessSeconds = s_stalenessSeconds;
    uint256 timestamp;
    (, weiPerUnitLink, , timestamp, ) = i_link_native_feed.latestRoundData();
    // solhint-disable-next-line not-rely-on-time
    isFeedStale = stalenessSeconds > 0 && stalenessSeconds < block.timestamp - timestamp;
    if (isFeedStale) {
      weiPerUnitLink = s_fallbackWeiPerUnitLink;
    }
    // solhint-disable-next-line gas-custom-errors
    require(weiPerUnitLink >= 0, "Invalid LINK wei price");
    return (weiPerUnitLink, isFeedStale);
  }

  /**
   * @dev Calculates extra amount of gas required for running an assembly call() post-EIP150.
   */
  function _getEIP150Overhead(uint32 gas) private pure returns (uint32) {
    return gas / 63 + 1;
  }

  function _getCoordinatorGasOverhead(uint32 numWords, bool nativePayment) internal view returns (uint32) {
    if (nativePayment) {
      return s_coordinatorGasOverheadNative + numWords * s_coordinatorGasOverheadPerWord;
    } else {
      return s_coordinatorGasOverheadLink + numWords * s_coordinatorGasOverheadPerWord;
    }
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available.
   */
  function _callWithExactGas(uint256 gasAmount, address target, bytes memory data) private returns (bool success) {
    assembly {
      let g := gas()
      // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
      // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
      // We want to ensure that we revert if gasAmount >  63//64*gas available
      // as we do not want to provide them with less, however that check itself costs
      // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
      // to revert if gasAmount >  63//64*gas available.
      if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
        revert(0, 0)
      }
      g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  function typeAndVersion() external pure virtual override returns (string memory) {
    return "VRFV2PlusWrapper 1.0.0";
  }

  modifier onlyConfiguredNotDisabled() {
    // solhint-disable-next-line gas-custom-errors
    require(s_configured, "wrapper is not configured");
    // solhint-disable-next-line gas-custom-errors
    require(!s_disabled, "wrapper is disabled");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LinkTokenInterface} from "../../shared/interfaces/LinkTokenInterface.sol";
import {IVRFV2PlusWrapper} from "./interfaces/IVRFV2PlusWrapper.sol";

/**
 *
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2+ requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2+ subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2PlusWrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK or ether to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomWords' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2PlusWrapperConsumerBase {
  error OnlyVRFWrapperCanFulfill(address have, address want);

  LinkTokenInterface internal immutable i_linkToken;
  IVRFV2PlusWrapper public immutable i_vrfV2PlusWrapper;

  /**
   * @param _vrfV2PlusWrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _vrfV2PlusWrapper) {
    IVRFV2PlusWrapper vrfV2PlusWrapper = IVRFV2PlusWrapper(_vrfV2PlusWrapper);

    i_linkToken = LinkTokenInterface(vrfV2PlusWrapper.link());
    i_vrfV2PlusWrapper = vrfV2PlusWrapper;
  }

  /**
   * @dev Requests randomness from the VRF V2+ wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2+ request ID of the newly created randomness request.
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords,
    bytes memory extraArgs
  ) internal returns (uint256 requestId, uint256 reqPrice) {
    reqPrice = i_vrfV2PlusWrapper.calculateRequestPrice(_callbackGasLimit, _numWords);
    i_linkToken.transferAndCall(
      address(i_vrfV2PlusWrapper),
      reqPrice,
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords, extraArgs)
    );
    return (i_vrfV2PlusWrapper.lastRequestId(), reqPrice);
  }

  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function requestRandomnessPayInNative(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords,
    bytes memory extraArgs
  ) internal returns (uint256 requestId, uint256 requestPrice) {
    requestPrice = i_vrfV2PlusWrapper.calculateRequestPriceNative(_callbackGasLimit, _numWords);
    return (
      i_vrfV2PlusWrapper.requestRandomWordsInNative{value: requestPrice}(
        _callbackGasLimit,
        _requestConfirmations,
        _numWords,
        extraArgs
      ),
      requestPrice
    );
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    address vrfWrapperAddr = address(i_vrfV2PlusWrapper);
    if (msg.sender != vrfWrapperAddr) {
      revert OnlyVRFWrapperCanFulfill(msg.sender, vrfWrapperAddr);
    }
    fulfillRandomWords(_requestId, _randomWords);
  }

  /// @notice getBalance returns the native balance of the consumer contract
  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  /// @notice getLinkToken returns the link token contract
  function getLinkToken() public view returns (LinkTokenInterface) {
    return i_linkToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFV2PlusClient} from "../libraries/VRFV2PlusClient.sol";
import {IVRFSubscriptionV2Plus} from "./IVRFSubscriptionV2Plus.sol";

// Interface that enables consumers of VRFCoordinatorV2Plus to be future-proof for upgrades
// This interface is supported by subsequent versions of VRFCoordinatorV2Plus
interface IVRFCoordinatorV2Plus is IVRFSubscriptionV2Plus {
  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fields for randomness request:
   * keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * requestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * extraArgs - abi-encoded extra args
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFMigratableConsumerV2Plus interface defines the
/// @notice method required to be implemented by all V2Plus consumers.
/// @dev This interface is designed to be used in VRFConsumerBaseV2Plus.
interface IVRFMigratableConsumerV2Plus {
  event CoordinatorSet(address vrfCoordinator);

  /// @notice Sets the VRF Coordinator address
  /// @notice This method should only be callable by the coordinator or contract owner
  function setCoordinator(address vrfCoordinator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFSubscriptionV2Plus interface defines the subscription
/// @notice related methods implemented by the V2Plus coordinator.
interface IVRFSubscriptionV2Plus {
  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint256 subId, address to) external;

  /**
   * @notice Accept subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint256 subId) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner) external;

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription with LINK, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   * @dev Note to fund the subscription with Native, use fundSubscriptionWithNative. Be sure
   * @dev  to send Native with the call, for example:
   * @dev COORDINATOR.fundSubscriptionWithNative{value: amount}(subId);
   */
  function createSubscription() external returns (uint256 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return nativeBalance - native balance of the subscription in wei.
   * @return reqCount - Requests count of subscription.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint256 subId
  )
    external
    view
    returns (uint96 balance, uint96 nativeBalance, uint64 reqCount, address owner, address[] memory consumers);

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint256 subId) external view returns (bool);

  /**
   * @notice Paginate through all active VRF subscriptions.
   * @param startIndex index of the subscription to start from
   * @param maxCount maximum number of subscriptions to return, 0 to return all
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * @dev should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveSubscriptionIds(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  /**
   * @notice Fund a subscription with native.
   * @param subId - ID of the subscription
   * @notice This method expects msg.value to be greater than or equal to 0.
   */
  function fundSubscriptionWithNative(uint256 subId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRFV2PlusWrapper {
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
   * @param _numWords is the number of words to request.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit, uint32 _numWords) external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request in native with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   */
  function calculateRequestPriceNative(uint32 _callbackGasLimit, uint32 _numWords) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(
    uint32 _callbackGasLimit,
    uint32 _numWords,
    uint256 _requestGasPriceWei
  ) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request in native with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPriceNative(
    uint32 _callbackGasLimit,
    uint32 _numWords,
    uint256 _requestGasPriceWei
  ) external view returns (uint256);

  /**
   * @notice Requests randomness from the VRF V2 wrapper, paying in native token.
   *
   * @param _callbackGasLimit is the gas limit for the request.
   * @param _requestConfirmations number of request confirmations to wait before serving a request.
   * @param _numWords is the number of words to request.
   */
  function requestRandomWordsInNative(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords,
    bytes calldata extraArgs
  ) external payable returns (uint256 requestId);

  function link() external view returns (address);
  function linkNativeFeed() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// End consumer library.
library VRFV2PlusClient {
  // extraArgs will evolve to support new features
  bytes4 public constant EXTRA_ARGS_V1_TAG = bytes4(keccak256("VRF ExtraArgsV1"));
  struct ExtraArgsV1 {
    bool nativePayment;
  }

  struct RandomWordsRequest {
    bytes32 keyHash;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    bytes extraArgs;
  }

  function _argsToBytes(ExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EXTRA_ARGS_V1_TAG, extraArgs);
  }
}