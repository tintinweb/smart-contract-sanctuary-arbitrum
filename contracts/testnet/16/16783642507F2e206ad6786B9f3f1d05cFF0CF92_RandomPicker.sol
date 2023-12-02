// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomPicker {
  function addToQueue(uint256 queueType, uint256 subQueue, uint256 owner, uint256 number) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256 subQueue,
    uint256[] calldata owner,
    uint256[] calldata number
  ) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256 owner,
    uint256[] calldata number
  ) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256[][] calldata owner,
    uint256[][] calldata number
  ) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256[][] calldata subQueue,
    uint256[] calldata owner,
    uint256[][] calldata number
  ) external;

  function removeFromQueue(
    uint256 queueType,
    uint256 subQueue,
    uint256 owner,
    uint256 number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256 subQueue,
    uint256[] calldata owner,
    uint256[] calldata number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256 owner,
    uint256[] calldata number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256[][] calldata owner,
    uint256[][] calldata number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[][] calldata subQueue,
    uint256[] calldata owner,
    uint256[][] calldata number
  ) external;

  function useRandomizer(
    uint256 queueType,
    uint256 subQueue,
    uint256 number,
    uint256 randomBase
  ) external view returns (uint[] memory result, uint newRandomBase);

  function useRandomizerBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256[] calldata number,
    uint256 randomBase
  ) external view returns (uint[][] memory result, uint newRandomBase);

  function getQueueSizes(
    uint256 queueType,
    uint256[] calldata subQueues
  ) external view returns (uint256[] memory result);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../Utils/Random.sol";
import "./IRandomPicker.sol";

contract RandomPicker is ManagerModifier, IRandomPicker {
  constructor(address _manager) ManagerModifier(_manager) {}

  mapping(uint256 => mapping(uint256 => uint32)) public queueLengths;
  mapping(uint256 => mapping(uint256 => uint16[])) public queues;

  mapping(uint256 => mapping(uint256 => mapping(uint16 => uint32[]))) public queuePositionsByOwner;
  mapping(uint256 => mapping(uint256 => mapping(uint16 => uint32))) public ownerTicketsLengths;

  function addToQueue(
    uint256 queueType,
    uint256 subQueue,
    uint256 owner,
    uint256 number
  ) external onlyManager {
    _addToQueue(queueType, subQueue, owner, number);
  }

  function addToQueueBatch(
    uint256 queueType,
    uint256 subQueue,
    uint256[] calldata owners,
    uint256[] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < owners.length; i++) {
      _addToQueue(queueType, subQueue, owners[i], numbers[i]);
    }
  }

  function addToQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueues,
    uint256 owner,
    uint256[] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < subQueues.length; i++) {
      _addToQueue(queueType, subQueues[i], owner, numbers[i]);
    }
  }

  function addToQueueBatch(
    uint256 queueType,
    uint256[][] calldata subQueues,
    uint256[] calldata owners,
    uint256[][] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < owners.length; i++) {
      for (uint j = 0; j < subQueues[i].length; j++) {
        _addToQueue(queueType, subQueues[i][j], owners[i], numbers[i][j]);
      }
    }
  }

  function addToQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueues,
    uint256[][] calldata owners,
    uint256[][] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < subQueues.length; i++) {
      for (uint j = 0; j < owners[i].length; j++) {
        _addToQueue(queueType, subQueues[i], owners[i][j], numbers[i][j]);
      }
    }
  }

  function removeFromQueue(
    uint256 queueType,
    uint256 subQueue,
    uint256 owner,
    uint256 number
  ) external onlyManager {
    uint32 queueLength = queueLengths[queueType][subQueue];
    require(queueLength >= number);
    uint16[] storage queue = queues[queueType][subQueue];
    uint32[] storage oTickets = queuePositionsByOwner[queueType][subQueue][uint16(owner)];
    mapping(uint16 => uint32) storage ownerTicketsLength = ownerTicketsLengths[queueType][subQueue];
    uint32 oTicketsLength = ownerTicketsLength[uint16(owner)];

    require(oTicketsLength >= number);

    uint32 indexToRemove;
    for (uint i = 0; i < number; i++) {
      indexToRemove = oTickets[oTicketsLength - i - 1];
      queue[indexToRemove] = queue[queueLength - i - 1];
    }

    ownerTicketsLength[uint16(owner)] -= uint32(number);
    queueLengths[queueType][subQueue] -= uint32(number);
  }

  function removeFromQueueBatch(
    uint256 queueType,
    uint256 subQueue,
    uint256[] calldata owner,
    uint256[] calldata number
  ) external onlyManager {
    for (uint i = 0; i < owner.length; i++) {
      _removeFromQueue(queueType, subQueue, owner[i], number[i]);
    }
  }

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueues,
    uint256 owner,
    uint256[] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < subQueues.length; i++) {
      _removeFromQueue(queueType, subQueues[i], owner, numbers[i]);
    }
  }

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[][] calldata subQueues,
    uint256[] calldata owners,
    uint256[][] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < owners.length; i++) {
      for (uint j = 0; j < subQueues[i].length; j++) {
        _removeFromQueue(queueType, subQueues[i][j], owners[i], numbers[i][j]);
      }
    }
  }

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueues,
    uint256[][] calldata owners,
    uint256[][] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < subQueues.length; i++) {
      for (uint j = 0; j < owners[i].length; j++) {
        _removeFromQueue(queueType, subQueues[i], owners[i][j], numbers[i][j]);
      }
    }
  }

  function useRandomizer(
    uint256 queueType,
    uint256 subQueue,
    uint256 number,
    uint256 randomBase
  ) external view returns (uint[] memory result, uint newRandomBase) {
    (result, newRandomBase) = _findRandom(queueType, subQueue, number, randomBase);
  }

  function useRandomizerBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256[] calldata number,
    uint256 randomBase
  ) external view returns (uint[][] memory result, uint newRandomBase) {
    require(subQueue.length == number.length);

    result = new uint[][](subQueue.length);
    newRandomBase = randomBase;
    for (uint i = 0; i < subQueue.length; i++) {
      (result[i], newRandomBase) = _findRandom(queueType, subQueue[i], number[i], newRandomBase);
    }
  }

  function getQueueSizes(
    uint256 queueType,
    uint256[] calldata subQueues
  ) external view returns (uint256[] memory result) {
    result = new uint256[](subQueues.length);
    for (uint i = 0; i < subQueues.length; i++) {
      result[i] = uint256(queueLengths[queueType][subQueues[i]]);
    }
  }

  function _addToQueue(
    uint256 queueType,
    uint256 subQueue,
    uint256 owner,
    uint256 number
  ) internal {
    uint32 queueLength = queueLengths[queueType][subQueue];
    uint16[] storage queue = queues[queueType][subQueue];
    uint32[] storage oTickets = queuePositionsByOwner[queueType][subQueue][uint16(owner)];
    mapping(uint16 => uint32) storage ownerTicketsLength = ownerTicketsLengths[queueType][subQueue];
    uint32 oTicketsLength = ownerTicketsLength[uint16(owner)];

    if (oTickets.length < oTicketsLength + number) {
      // Expand tickets owned by the user array, this should be rare after the initial stake
      uint newLength = oTicketsLength + number;
      assembly {
        let arrayPointer := sload(oTickets.slot)
        sstore(oTickets.slot, newLength)
      }
    }

    if (queue.length < queueLength + number) {
      uint newLength = queueLength + number;
      // Expand the queue array if needed
      assembly {
        sstore(queue.slot, newLength)
      }
    }

    for (uint i = 0; i < number; i++) {
      queue[queueLength + i] = uint16(owner);
      oTickets[oTicketsLength + i] = uint32(queueLength + i);
    }

    queueLengths[queueType][subQueue] += uint16(number);
    ownerTicketsLength[uint16(owner)] += uint16(number);
  }

  function _removeFromQueue(
    uint256 queueType,
    uint256 subQueue,
    uint256 owner,
    uint256 number
  ) internal {
    uint32 queueLength = queueLengths[queueType][subQueue];
    require(queueLength >= number);
    uint16[] storage queue = queues[queueType][subQueue];
    uint32[] storage oTickets = queuePositionsByOwner[queueType][subQueue][uint16(owner)];
    mapping(uint16 => uint32) storage ownerTicketsLength = ownerTicketsLengths[queueType][subQueue];
    uint32 oTicketsLength = ownerTicketsLength[uint16(owner)];

    require(oTicketsLength >= number);

    uint32 indexToRemove;
    for (uint i = 0; i < number; i++) {
      indexToRemove = oTickets[oTicketsLength - i - 1];
      queue[indexToRemove] = queue[queueLength - i - 1];
    }

    ownerTicketsLength[uint16(owner)] -= uint32(number);
    queueLengths[queueType][subQueue] -= uint32(number);
  }

  function _findRandom(
    uint256 queueType,
    uint256 subQueue,
    uint256 number,
    uint256 randomBase
  ) internal view returns (uint[] memory result, uint256 nextRandomBase) {
    uint32 queueLength = queueLengths[queueType][subQueue];
    uint16[] storage queue = queues[queueType][subQueue];

    require(queueLength > 0 || number == 0);

    uint randomNumber;
    result = new uint[](number);
    for (uint i = 0; i < number; i++) {
      (randomNumber, randomBase) = Random.getNextRandom(randomBase, queueLength);
      result[i] = queue[randomNumber % queueLength];
    }
    nextRandomBase = randomBase;
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
  function withdrawEth(address destination) external payable returns (uint256);

  /**
   * @notice Send a transaction to L1
   * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
   * to a contract address without any code (as enforced by the Bridge contract).
   * @param destination recipient address on L1
   * @param data (optional) calldata for L1 contract call
   * @return a unique identifier for this L2-to-L1 transaction.
   */
  function sendTxToL1(address destination, bytes calldata data) external payable returns (uint256);

  /**
   * @notice Get send Merkle tree .state
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
  event SendMerkleUpdate(uint256 indexed reserved, bytes32 indexed hash, uint256 indexed position);

  error InvalidBlockNumber(uint256 requested, uint256 current);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IArbSys.sol";

//=========================================================================================================================================
// We're trying to normalize all chances close to 100%, which is 100 000 with decimal point 10^3. Assuming this, we can get more "random"
// numbers by dividing the "random" number by this prime. To be honest most primes larger than 100% should work, but to be safe we'll
// use an order of magnitude higher (10^3) relative to the decimal point
// We're using uint256 (2^256 ~= 10^77), which means we're safe to derive 8 consecutive random numbers from each hash.
// If we, by any chance, run out of random numbers (hash being lower than the range) we can in turn
// use the remainder of the hash to regenerate a new random number.
// Example: assuming our hash function result would be 1132134687911000 (shorter number picked for explanation) and we're using
// % 100000 range for our drop chance. The first "random" number is 11000. We then divide 1000000011000 by the 100000037 prime,
// leaving us at 11321342. The second derived random number would be 11321342 % 100000 = 21342. 11321342/100000037 is in turn less than
// 100000037, so we'll instead regenerate a new hash using 11321342.
// Primes are used for additional safety, but we could just deal with the "range".
//=========================================================================================================================================
uint256 constant MIN_SAFE_NEXT_NUMBER_PRIME = 200033;
uint256 constant HIGH_RANGE_PRIME_OFFSET = 13;

library Random {
  function startRandomBase(uint256 _highSalt, uint256 _lowSalt) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            _getPreviousBlockhash(),
            block.timestamp,
            msg.sender,
            _lowSalt,
            _highSalt
          )
        )
      );
  }

  function getNextRandom(
    uint256 _randomBase,
    uint256 _range
  ) internal view returns (uint256, uint256) {
    uint256 nextNumberSeparator = MIN_SAFE_NEXT_NUMBER_PRIME > _range
      ? MIN_SAFE_NEXT_NUMBER_PRIME
      : (_range + HIGH_RANGE_PRIME_OFFSET);
    uint256 nextBaseNumber = _randomBase / nextNumberSeparator;
    if (nextBaseNumber > nextNumberSeparator) {
      return (_randomBase % _range, nextBaseNumber);
    }
    nextBaseNumber = uint256(
      keccak256(abi.encodePacked(_getPreviousBlockhash(), msg.sender, _randomBase, _range))
    );
    return (nextBaseNumber % _range, nextBaseNumber / nextNumberSeparator);
  }

  function _getPreviousBlockhash() internal view returns (bytes32) {
    // Arbitrum One, Nova, Goerli, Sepolia, Stylus or Rinkeby
    if (
      block.chainid == 42161 ||
      block.chainid == 42170 ||
      block.chainid == 421613 ||
      block.chainid == 421614 ||
      block.chainid == 23011913 ||
      block.chainid == 421611
    ) {
      return ArbSys(address(0x64)).arbBlockHash(ArbSys(address(0x64)).arbBlockNumber() - 1);
    } else {
      // WARNING: THIS IS HIGHLY INSECURE ON ETH MAINNET, it is currently used mostly for testing
      return blockhash(block.number - 1);
    }
  }
}