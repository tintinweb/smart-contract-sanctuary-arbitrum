// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ArbSys} from "./vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";

//@dev A library that abstracts out opcodes that behave differently across chains.
//@dev The methods below return values that are pertinent to the given chain.
//@dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
  address private constant ARBSYS_ADDR = address(0x0000000000000000000000000000000000000064);
  ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);
  uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
  uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;

  function getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
    uint256 chainid = block.chainid;
    if (chainid == ARB_MAINNET_CHAIN_ID || chainid == ARB_GOERLI_TESTNET_CHAIN_ID) {
      if ((getBlockNumber() - blockNumber) > 256 || blockNumber >= getBlockNumber()) {
        return "";
      }
      return ARBSYS.arbBlockHash(blockNumber);
    }
    return blockhash(blockNumber);
  }

  function getBlockNumber() internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (chainid == ARB_MAINNET_CHAIN_ID || chainid == ARB_GOERLI_TESTNET_CHAIN_ID) {
      return ARBSYS.arbBlockNumber();
    }
    return block.number;
  }
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
pragma solidity 0.8.6;

import "../ChainSpecificUtil.sol";

/**
 * @title BatchBlockhashStore
 * @notice The BatchBlockhashStore contract acts as a proxy to write many blockhashes to the
 *   provided BlockhashStore contract efficiently in a single transaction. This results
 *   in plenty of gas savings and higher throughput of blockhash storage, which is desirable
 *   in times of high network congestion.
 */
contract BatchBlockhashStore {
  BlockhashStore public immutable BHS;

  constructor(address blockhashStoreAddr) {
    BHS = BlockhashStore(blockhashStoreAddr);
  }

  /**
   * @notice stores blockhashes of the given block numbers in the configured blockhash store, assuming
   *   they are availble though the blockhash() instruction.
   * @param blockNumbers the block numbers to store the blockhashes of. Must be available via the
   *   blockhash() instruction, otherwise this function call will revert.
   */
  function store(uint256[] memory blockNumbers) public {
    for (uint256 i = 0; i < blockNumbers.length; i++) {
      // skip the block if it's not storeable, the caller will have to check
      // after the transaction is mined to see if the blockhash was truly stored.
      if (!storeableBlock(blockNumbers[i])) {
        continue;
      }
      BHS.store(blockNumbers[i]);
    }
  }

  /**
   * @notice stores blockhashes after verifying blockheader of child/subsequent block
   * @param blockNumbers the block numbers whose blockhashes should be stored, in decreasing order
   * @param headers the rlp-encoded block headers of blockNumbers[i] + 1.
   */
  function storeVerifyHeader(uint256[] memory blockNumbers, bytes[] memory headers) public {
    require(blockNumbers.length == headers.length, "input array arg lengths mismatch");
    for (uint256 i = 0; i < blockNumbers.length; i++) {
      BHS.storeVerifyHeader(blockNumbers[i], headers[i]);
    }
  }

  /**
   * @notice retrieves blockhashes of all the given block numbers from the blockhash store, if available.
   * @param blockNumbers array of block numbers to fetch blockhashes for
   * @return blockhashes array of block hashes corresponding to each block number provided in the `blockNumbers`
   *   param. If the blockhash is not found, 0x0 is returned instead of the real blockhash, indicating
   *   that it is not in the blockhash store.
   */
  function getBlockhashes(uint256[] memory blockNumbers) external view returns (bytes32[] memory) {
    bytes32[] memory blockHashes = new bytes32[](blockNumbers.length);
    for (uint256 i = 0; i < blockNumbers.length; i++) {
      try BHS.getBlockhash(blockNumbers[i]) returns (bytes32 bh) {
        blockHashes[i] = bh;
      } catch Error(
        string memory /* reason */
      ) {
        blockHashes[i] = 0x0;
      }
    }
    return blockHashes;
  }

  /**
   * @notice returns true if and only if the given block number's blockhash can be retrieved
   *   using the blockhash() instruction.
   * @param blockNumber the block number to check if it's storeable with blockhash()
   */
  function storeableBlock(uint256 blockNumber) private view returns (bool) {
    // handle edge case on simulated chains which possibly have < 256 blocks total.
    return ChainSpecificUtil.getBlockNumber() <= 256 ? true : blockNumber >= (ChainSpecificUtil.getBlockNumber() - 256);
  }
}

interface BlockhashStore {
  function storeVerifyHeader(uint256 n, bytes memory header) external;

  function store(uint256 n) external;

  function getBlockhash(uint256 n) external view returns (bytes32);
}