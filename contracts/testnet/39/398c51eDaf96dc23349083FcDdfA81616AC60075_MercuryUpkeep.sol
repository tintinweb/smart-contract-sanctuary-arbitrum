// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FeedLookupCompatibleInterface {
  error FeedLookup(string feedParamKey, string[] feeds, string timeParamKey, uint256 time, bytes extraData);

  /**
   * @notice any contract which wants to utilize FeedLookup feature needs to
   * implement this interface as well as the automation compatible interface.
   * @param values an array of bytes returned from Mercury endpoint.
   * @param extraData context data from feed lookup process.
   * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
   */
  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external view returns (bool upkeepNeeded, bytes memory performData);
}

// SPDX-License-Identifier: MIT
import "../../vendor/entrypoint/interfaces/IAccount.sol";
import "./SCALibrary.sol";
import "../../vendor/entrypoint/core/Helpers.sol";

/// TODO: decide on a compiler version. Must not be dynamic, and must be > 0.8.12.
pragma solidity 0.8.15;

/// @dev Smart Contract Account, a contract deployed for a single user and that allows
/// @dev them to invoke meta-transactions.
/// TODO: Consider making the Smart Contract Account upgradeable.
contract SCA is IAccount {
  uint256 public s_nonce;
  address public immutable i_owner;
  address public immutable i_entryPoint;

  error IncorrectNonce(uint256 currentNonce, uint256 nonceGiven);
  error NotAuthorized(address sender);
  error BadFormatOrOOG();
  error TransactionExpired(uint256 deadline, uint256 currentTimestamp);
  error InvalidSignature(bytes32 operationHash, address owner);

  // Assign the owner of this contract upon deployment.
  constructor(address owner, address entryPoint) {
    i_owner = owner;
    i_entryPoint = entryPoint;
  }

  /// @dev Validates the user operation via a signature check.
  /// TODO: Utilize a "validAfter" for a tx to be only valid _after_ a certain time.
  function validateUserOp(
    UserOperation calldata userOp,
    bytes32 userOpHash,
    uint256 /* missingAccountFunds - unused in favor of paymaster */
  ) external returns (uint256 validationData) {
    if (userOp.nonce != s_nonce) {
      // Revert for non-signature errors.
      revert IncorrectNonce(s_nonce, userOp.nonce);
    }

    // Verify signature on hash.
    bytes32 fullHash = SCALibrary.getUserOpFullHash(userOpHash, address(this));
    bytes memory signature = userOp.signature;
    if (SCALibrary.recoverSignature(signature, fullHash) != i_owner) {
      return _packValidationData(true, 0, 0); // signature error
    }
    s_nonce++;

    // Unpack deadline, return successful signature.
    (, , uint48 deadline, ) = abi.decode(userOp.callData[4:], (address, uint256, uint48, bytes));
    return _packValidationData(false, deadline, 0);
  }

  /// @dev Execute a transaction on behalf of the owner. This function can only
  /// @dev be called by the EntryPoint contract, and assumes that `validateUserOp` has succeeded.
  function executeTransactionFromEntryPoint(address to, uint256 value, uint48 deadline, bytes calldata data) external {
    if (msg.sender != i_entryPoint) {
      revert NotAuthorized(msg.sender);
    }
    if (deadline != 0 && block.timestamp > deadline) {
      revert TransactionExpired(deadline, block.timestamp);
    }

    // Execute transaction. Bubble up an error if found.
    (bool success, bytes memory returnData) = to.call{value: value}(data);
    if (!success) {
      if (returnData.length == 0) revert BadFormatOrOOG();
      assembly {
        revert(add(32, returnData), mload(returnData))
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library SCALibrary {
  // keccak256("EIP712Domain(uint256 chainId, address verifyingContract)");
  bytes32 internal constant DOMAIN_SEPARATOR = hex"1c7d3b72b37a35523e273aaadd7b4cd66f618bb81429ab053412d51f50ccea61";

  // keccak256("executeTransactionFromEntryPoint(address to, uint256 value, bytes calldata data)");
  bytes32 internal constant TYPEHASH = hex"4750045d47fce615521b32cee713ff8db50147e98aec5ca94926b52651ca3fa0";

  enum LinkPaymentType {
    DIRECT_FUNDING,
    SUBSCRIPTION // TODO: implement
  }

  struct DirectFundingData {
    address recipient; // recipient of the top-up
    uint256 topupThreshold; // set to zero to disable auto-topup
    uint256 topupAmount;
  }

  function getUserOpFullHash(bytes32 userOpHash, address scaAddress) internal view returns (bytes32 fullHash) {
    bytes32 hashOfEncoding = keccak256(abi.encode(SCALibrary.TYPEHASH, userOpHash));
    fullHash = keccak256(
      abi.encodePacked(
        bytes1(0x19),
        bytes1(0x01),
        SCALibrary.DOMAIN_SEPARATOR,
        block.chainid,
        scaAddress,
        hashOfEncoding
      )
    );
  }

  function recoverSignature(bytes memory signature, bytes32 fullHash) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
    }
    uint8 v = uint8(signature[64]);

    return ecrecover(fullHash, v + 27, r, s);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract SmartContractAccountFactory {
  event ContractCreated(address scaAddress);

  error DeploymentFailed();

  /// @dev Use create2 to deploy a new Smart Contract Account.
  /// @dev See EIP-1014 for more on CREATE2.
  /// TODO: Return the address of the Smart Contract Account even if it is already
  /// deployed.
  function deploySmartContractAccount(
    bytes32 abiEncodedOwnerAddress,
    bytes memory initCode
  ) external payable returns (address scaAddress) {
    assembly {
      scaAddress := create2(
        0, // value - left at zero here
        add(0x20, initCode), // initialization bytecode
        mload(initCode), // length of initialization bytecode
        abiEncodedOwnerAddress // user-defined nonce to ensure unique SCA addresses
      )
    }
    if (scaAddress == address(0)) {
      revert DeploymentFailed();
    }

    emit ContractCreated(scaAddress);
  }
}

import "../4337/SCA.sol";
import "../4337/SmartContractAccountFactory.sol";
import "../4337/SCALibrary.sol";

pragma solidity ^0.8.15;

library SmartContractAccountHelper {
  bytes constant initailizeCode = type(SCA).creationCode;

  function getFullEndTxEncoding(
    address endContract,
    uint256 value,
    uint256 deadline,
    bytes memory data
  ) public view returns (bytes memory encoding) {
    encoding = bytes.concat(
      SCA.executeTransactionFromEntryPoint.selector,
      abi.encode(endContract, value, block.timestamp + deadline, data)
    );
  }

  function getFullHashForSigning(bytes32 userOpHash, address scaAddress) public view returns (bytes32) {
    return SCALibrary.getUserOpFullHash(userOpHash, scaAddress);
  }

  function getSCAInitCodeWithConstructor(
    address owner,
    address entryPoint
  ) public pure returns (bytes memory initCode) {
    initCode = bytes.concat(initailizeCode, abi.encode(owner, entryPoint));
  }

  function getInitCode(
    address factory,
    address owner,
    address entryPoint
  ) external pure returns (bytes memory initCode) {
    bytes32 salt = bytes32(uint256(uint160(owner)) << 96);
    bytes memory initializeCodeWithConstructor = bytes.concat(initailizeCode, abi.encode(owner, entryPoint));
    initCode = bytes.concat(
      bytes20(address(factory)),
      abi.encodeWithSelector(
        SmartContractAccountFactory.deploySmartContractAccount.selector,
        salt,
        initializeCodeWithConstructor
      )
    );
  }

  /// @dev Computes the smart contract address that results from a CREATE2 operation, per EIP-1014.
  function calculateSmartContractAccountAddress(
    address owner,
    address entryPoint,
    address factory
  ) external pure returns (address) {
    bytes32 salt = bytes32(uint256(uint160(owner)) << 96);
    bytes memory initializeCodeWithConstructor = bytes.concat(initailizeCode, abi.encode(owner, entryPoint));
    bytes32 initializeCodeHash = keccak256(initializeCodeWithConstructor);
    return address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", address(factory), salt, initializeCodeHash)))));
  }

  function getAbiEncodedDirectRequestData(
    address recipient,
    uint256 topupThreshold,
    uint256 topupAmount
  ) external view returns (bytes memory) {
    SCALibrary.DirectFundingData memory data = SCALibrary.DirectFundingData({
      recipient: recipient,
      topupThreshold: topupThreshold,
      topupAmount: topupAmount
    });
    return abi.encode(data);
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
    function withdrawEth(address destination) external payable returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/**
 * returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`
 * @param aggregator - address(0) - the account validated the signature by itself.
 *              address(1) - the account failed to validate the signature.
 *              otherwise - this is an address of a signature aggregator that must be used to validate the signature.
 * @param validAfter - this UserOp is valid only after this timestamp.
 * @param validaUntil - this UserOp is valid only up to this timestamp.
 */
struct ValidationData {
  address aggregator;
  uint48 validAfter;
  uint48 validUntil;
}

//extract sigFailed, validAfter, validUntil.
// also convert zero validUntil to type(uint48).max
function _parseValidationData(uint validationData) pure returns (ValidationData memory data) {
  address aggregator = address(uint160(validationData));
  uint48 validUntil = uint48(validationData >> 160);
  if (validUntil == 0) {
    validUntil = type(uint48).max;
  }
  uint48 validAfter = uint48(validationData >> (48 + 160));
  return ValidationData(aggregator, validAfter, validUntil);
}

// intersect account and paymaster ranges.
function _intersectTimeRange(
  uint256 validationData,
  uint256 paymasterValidationData
) pure returns (ValidationData memory) {
  ValidationData memory accountValidationData = _parseValidationData(validationData);
  ValidationData memory pmValidationData = _parseValidationData(paymasterValidationData);
  address aggregator = accountValidationData.aggregator;
  if (aggregator == address(0)) {
    aggregator = pmValidationData.aggregator;
  }
  uint48 validAfter = accountValidationData.validAfter;
  uint48 validUntil = accountValidationData.validUntil;
  uint48 pmValidAfter = pmValidationData.validAfter;
  uint48 pmValidUntil = pmValidationData.validUntil;

  if (validAfter < pmValidAfter) validAfter = pmValidAfter;
  if (validUntil > pmValidUntil) validUntil = pmValidUntil;
  return ValidationData(aggregator, validAfter, validUntil);
}

/**
 * helper to pack the return value for validateUserOp
 * @param data - the ValidationData to pack
 */
function _packValidationData(ValidationData memory data) pure returns (uint256) {
  return uint160(data.aggregator) | (uint256(data.validUntil) << 160) | (uint256(data.validAfter) << (160 + 48));
}

/**
 * helper to pack the return value for validateUserOp, when not using an aggregator
 * @param sigFailed - true for signature failure, false for success
 * @param validUntil last timestamp this UserOperation is valid (or zero for infinite)
 * @param validAfter first timestamp this UserOperation is valid
 */
function _packValidationData(bool sigFailed, uint48 validUntil, uint48 validAfter) pure returns (uint256) {
  return (sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48));
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

interface IAccount {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
     * This allows making a "simulation call" without a valid signature
     * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external returns (uint256 validationData);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

    /**
     * User Operation struct
     * @param sender the sender account of this request.
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor/
     * @param callData the method call to execute on this account.
     * @param callGasLimit the gas limit passed to the callData method call.
     * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp.
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter.
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter.
     * @param paymasterAndData if set, this field holds the paymaster address and paymaster-specific data. the paymaster will pay for the transaction instead of the sender.
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        //lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata sig = userOp.signature;
        // copy directly the userOp from calldata up to (but not including) the signature.
        // this encoding depends on the ABI encoding of calldata, but is much lighter to copy
        // than referencing each field separately.
        assembly {
            let ofs := userOp
            let len := sub(sub(sig.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

pragma solidity 0.8.15;

import "../interfaces/automation/AutomationCompatibleInterface.sol";
import "../dev/automation/2_1/interfaces/FeedLookupCompatibleInterface.sol";
import {ArbSys} from "../dev/vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";

//interface IVerifierProxy {
//  /**
//   * @notice Verifies that the data encoded has been signed
//   * correctly by routing to the correct verifier.
//   * @param signedReport The encoded data to be verified.
//   * @return verifierResponse The encoded response from the verifier.
//   */
//  function verify(bytes memory signedReport) external returns (bytes memory verifierResponse);
//}

contract MercuryUpkeep is AutomationCompatibleInterface, FeedLookupCompatibleInterface {
  event MercuryPerformEvent(
    address indexed origin,
    address indexed sender,
    uint256 indexed blockNumber,
    bytes v0,
    bytes v1,
    bytes ed
  );

  ArbSys internal constant ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064);
  //  IVerifierProxy internal constant VERIFIER = IVerifierProxy(0xa4D813064dc6E2eFfaCe02a060324626d4C5667f);

  uint256 public testRange;
  uint256 public interval;
  uint256 public previousPerformBlock;
  uint256 public initialBlock;
  uint256 public counter;
  string[] public feeds;
  string public feedParamKey;
  string public timeParamKey;
  bool public immutable useL1BlockNumber;

  constructor(uint256 _testRange, uint256 _interval, bool _useL1BlockNumber) {
    testRange = _testRange;
    interval = _interval;
    previousPerformBlock = 0;
    initialBlock = 0;
    counter = 0;
    feedParamKey = "feedIDHex"; // feedIDStr is deprecated
    feeds = [
      "0x4554482d5553442d415242495452554d2d544553544e45540000000000000000",
      "0x4254432d5553442d415242495452554d2d544553544e45540000000000000000"
    ];
    timeParamKey = "blockNumber"; // timestamp not supported yet
    useL1BlockNumber = _useL1BlockNumber;
  }

  function checkCallback(bytes[] memory values, bytes memory extraData) external pure returns (bool, bytes memory) {
    // do sth about the chainlinkBlob data in values and extraData
    bytes memory performData = abi.encode(values, extraData);
    return (true, performData);
  }

  function checkUpkeep(bytes calldata data) external view returns (bool, bytes memory) {
    if (!eligible()) {
      return (false, data);
    }
    uint256 blockNumber;
    if (useL1BlockNumber) {
      blockNumber = block.number;
    } else {
      blockNumber = ARB_SYS.arbBlockNumber();
    }
    // encode ARB_SYS as extraData to verify that it is provided to checkCallback correctly.
    // in reality, this can be any data or empty
    revert FeedLookup(feedParamKey, feeds, timeParamKey, blockNumber, abi.encodePacked(address(ARB_SYS)));
  }

  function performUpkeep(bytes calldata performData) external {
    uint256 blockNumber;
    if (useL1BlockNumber) {
      blockNumber = block.number;
    } else {
      blockNumber = ARB_SYS.arbBlockNumber();
    }
    if (initialBlock == 0) {
      initialBlock = blockNumber;
    }
    (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
    previousPerformBlock = blockNumber;
    counter = counter + 1;
    //    bytes memory v0 = VERIFIER.verify(values[0]);
    //    bytes memory v1 = VERIFIER.verify(values[1]);
    emit MercuryPerformEvent(tx.origin, msg.sender, blockNumber, values[0], values[1], extraData);
  }

  function eligible() public view returns (bool) {
    if (initialBlock == 0) {
      return true;
    }

    uint256 blockNumber;
    if (useL1BlockNumber) {
      blockNumber = block.number;
    } else {
      blockNumber = ARB_SYS.arbBlockNumber();
    }
    return (blockNumber - initialBlock) < testRange && (blockNumber - previousPerformBlock) >= interval;
  }
}