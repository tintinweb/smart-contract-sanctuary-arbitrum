// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.20;

/// @title Pairing
/// @notice A library implementing the alt_bn128 elliptic curve operations.
library Pairing {
  uint256 public constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

  struct G1Point {
    uint256 x;
    uint256 y;
  }

  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint256[2] x;
    uint256[2] y;
  }

  /// @notice custom errors
  error PairingAddFailed();
  error PairingMulFailed();
  error PairingOpcodeFailed();

  /// @notice The negation of p, i.e. p.plus(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
    // The prime q in the base field F_q for G1
    if (p.x == 0 && p.y == 0) {
      return G1Point(0, 0);
    } else {
      return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
    }
  }

  /// @notice r Returns the sum of two points of G1.
  function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
    uint256[4] memory input;
    input[0] = p1.x;
    input[1] = p1.y;
    input[2] = p2.x;
    input[3] = p2.y;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingAddFailed();
    }
  }

  /// @notice r Return the product of a point on G1 and a scalar, i.e.
  ///         p == p.scalarMul(1) and p.plus(p) == p.scalarMul(2) for all
  ///         points p.
  function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    uint256[3] memory input;
    input[0] = p.x;
    input[1] = p.y;
    input[2] = s;
    bool success;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingMulFailed();
    }
  }

  /// @return isValid The result of computing the pairing check
  ///         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  ///        For example,
  ///        pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
  function pairing(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2,
    G1Point memory d1,
    G2Point memory d2
  ) internal view returns (bool isValid) {
    G1Point[4] memory p1;
    p1[0] = a1;
    p1[1] = b1;
    p1[2] = c1;
    p1[3] = d1;

    G2Point[4] memory p2;
    p2[0] = a2;
    p2[1] = b2;
    p2[2] = c2;
    p2[3] = d2;

    uint256 inputSize = 24;
    uint256[] memory input = new uint256[](inputSize);

    for (uint8 i = 0; i < 4; ) {
      uint8 j = i * 6;
      input[j + 0] = p1[i].x;
      input[j + 1] = p1[i].y;
      input[j + 2] = p2[i].x[0];
      input[j + 3] = p2[i].x[1];
      input[j + 4] = p2[i].y[0];
      input[j + 5] = p2[i].y[1];

      unchecked {
        i++;
      }
    }

    uint256[1] memory out;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingOpcodeFailed();
    }

    isValid = out[0] != 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { Pairing } from "./Pairing.sol";

/// @title SnarkCommon
/// @notice a Contract which holds a struct
/// representing a Groth16 verifying key
contract SnarkCommon {
  /// @notice a struct representing a Groth16 verifying key
  struct VerifyingKey {
    Pairing.G1Point alpha1;
    Pairing.G2Point beta2;
    Pairing.G2Point gamma2;
    Pairing.G2Point delta2;
    Pairing.G1Point[] ic;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { SnarkCommon } from "../crypto/SnarkCommon.sol";
import { DomainObjs } from "../utilities/DomainObjs.sol";

/// @title IVkRegistry
/// @notice VkRegistry interface
interface IVkRegistry {
  /// @notice Get the tally verifying key
  /// @param _stateTreeDepth The state tree depth
  /// @param _intStateTreeDepth The intermediate state tree depth
  /// @param _voteOptionTreeDepth The vote option tree depth
  /// @param _mode QV or Non-QV
  /// @return The verifying key
  function getTallyVk(
    uint256 _stateTreeDepth,
    uint256 _intStateTreeDepth,
    uint256 _voteOptionTreeDepth,
    DomainObjs.Mode _mode
  ) external view returns (SnarkCommon.VerifyingKey memory);

  /// @notice Get the process verifying key
  /// @param _stateTreeDepth The state tree depth
  /// @param _messageTreeDepth The message tree depth
  /// @param _voteOptionTreeDepth The vote option tree depth
  /// @param _messageBatchSize The message batch size
  /// @param _mode QV or Non-QV
  /// @return The verifying key
  function getProcessVk(
    uint256 _stateTreeDepth,
    uint256 _messageTreeDepth,
    uint256 _voteOptionTreeDepth,
    uint256 _messageBatchSize,
    DomainObjs.Mode _mode
  ) external view returns (SnarkCommon.VerifyingKey memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DomainObjs
/// @notice An utility contract that holds
/// a number of domain objects and functions
contract DomainObjs {
  /// @notice the length of a MACI message
  uint8 public constant MESSAGE_DATA_LENGTH = 10;

  /// @notice voting modes
  enum Mode {
    QV,
    NON_QV
  }

  /// @title Message
  /// @notice this struct represents a MACI message
  /// @dev msgType: 1 for vote message, 2 for topup message (size 2)
  struct Message {
    uint256 msgType;
    uint256[MESSAGE_DATA_LENGTH] data;
  }

  /// @title PubKey
  /// @notice A MACI public key
  struct PubKey {
    uint256 x;
    uint256 y;
  }

  /// @title StateLeaf
  /// @notice A MACI state leaf
  /// @dev used to represent a user's state
  /// in the state Merkle tree
  struct StateLeaf {
    PubKey pubKey;
    uint256 voiceCreditBalance;
    uint256 timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { SnarkCommon } from "./crypto/SnarkCommon.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IVkRegistry } from "./interfaces/IVkRegistry.sol";
import { DomainObjs } from "./utilities/DomainObjs.sol";

/// @title VkRegistry
/// @notice Stores verifying keys for the circuits.
/// Each circuit has a signature which is its compile-time constants represented
/// as a uint256.
contract VkRegistry is Ownable(msg.sender), DomainObjs, SnarkCommon, IVkRegistry {
  mapping(Mode => mapping(uint256 => VerifyingKey)) internal processVks;
  mapping(Mode => mapping(uint256 => bool)) internal processVkSet;

  mapping(Mode => mapping(uint256 => VerifyingKey)) internal tallyVks;
  mapping(Mode => mapping(uint256 => bool)) internal tallyVkSet;

  event ProcessVkSet(uint256 _sig, Mode _mode);
  event TallyVkSet(uint256 _sig, Mode _mode);

  error ProcessVkAlreadySet();
  error TallyVkAlreadySet();
  error ProcessVkNotSet();
  error TallyVkNotSet();
  error SubsidyVkNotSet();
  error InvalidKeysParams();

  /// @notice Create a new instance of the VkRegistry contract
  // solhint-disable-next-line no-empty-blocks
  constructor() payable {}

  /// @notice Check if the process verifying key is set
  /// @param _sig The signature
  /// @param _mode QV or Non-QV
  /// @return isSet whether the verifying key is set
  function isProcessVkSet(uint256 _sig, Mode _mode) public view returns (bool isSet) {
    isSet = processVkSet[_mode][_sig];
  }

  /// @notice Check if the tally verifying key is set
  /// @param _sig The signature
  /// @param _mode QV or Non-QV
  /// @return isSet whether the verifying key is set
  function isTallyVkSet(uint256 _sig, Mode _mode) public view returns (bool isSet) {
    isSet = tallyVkSet[_mode][_sig];
  }

  /// @notice generate the signature for the process verifying key
  /// @param _stateTreeDepth The state tree depth
  /// @param _messageTreeDepth The message tree depth
  /// @param _voteOptionTreeDepth The vote option tree depth
  /// @param _messageBatchSize The message batch size
  function genProcessVkSig(
    uint256 _stateTreeDepth,
    uint256 _messageTreeDepth,
    uint256 _voteOptionTreeDepth,
    uint256 _messageBatchSize
  ) public pure returns (uint256 sig) {
    sig = (_messageBatchSize << 192) + (_stateTreeDepth << 128) + (_messageTreeDepth << 64) + _voteOptionTreeDepth;
  }

  /// @notice generate the signature for the tally verifying key
  /// @param _stateTreeDepth The state tree depth
  /// @param _intStateTreeDepth The intermediate state tree depth
  /// @param _voteOptionTreeDepth The vote option tree depth
  /// @return sig The signature
  function genTallyVkSig(
    uint256 _stateTreeDepth,
    uint256 _intStateTreeDepth,
    uint256 _voteOptionTreeDepth
  ) public pure returns (uint256 sig) {
    sig = (_stateTreeDepth << 128) + (_intStateTreeDepth << 64) + _voteOptionTreeDepth;
  }

  /// @notice Set the process and tally verifying keys for a certain combination
  /// of parameters and modes
  /// @param _stateTreeDepth The state tree depth
  /// @param _intStateTreeDepth The intermediate state tree depth
  /// @param _messageTreeDepth The message tree depth
  /// @param _voteOptionTreeDepth The vote option tree depth
  /// @param _messageBatchSize The message batch size
  /// @param _modes Array of QV or Non-QV modes (must have the same length as process and tally keys)
  /// @param _processVks The process verifying keys (must have the same length as modes)
  /// @param _tallyVks The tally verifying keys (must have the same length as modes)
  function setVerifyingKeysBatch(
    uint256 _stateTreeDepth,
    uint256 _intStateTreeDepth,
    uint256 _messageTreeDepth,
    uint256 _voteOptionTreeDepth,
    uint256 _messageBatchSize,
    Mode[] calldata _modes,
    VerifyingKey[] calldata _processVks,
    VerifyingKey[] calldata _tallyVks
  ) public onlyOwner {
    if (_modes.length != _processVks.length || _modes.length != _tallyVks.length) {
      revert InvalidKeysParams();
    }

    uint256 length = _modes.length;

    for (uint256 index = 0; index < length; ) {
      setVerifyingKeys(
        _stateTreeDepth,
        _intStateTreeDepth,
        _messageTreeDepth,
        _voteOptionTreeDepth,
        _messageBatchSize,
        _modes[index],
        _processVks[index],
        _tallyVks[index]
      );

      unchecked {
        index++;
      }
    }
  }

  /// @notice Set the process and tally verifying keys for a certain combination
  /// of parameters
  /// @param _stateTreeDepth The state tree depth
  /// @param _intStateTreeDepth The intermediate state tree depth
  /// @param _messageTreeDepth The message tree depth
  /// @param _voteOptionTreeDepth The vote option tree depth
  /// @param _messageBatchSize The message batch size
  /// @param _mode QV or Non-QV
  /// @param _processVk The process verifying key
  /// @param _tallyVk The tally verifying key
  function setVerifyingKeys(
    uint256 _stateTreeDepth,
    uint256 _intStateTreeDepth,
    uint256 _messageTreeDepth,
    uint256 _voteOptionTreeDepth,
    uint256 _messageBatchSize,
    Mode _mode,
    VerifyingKey calldata _processVk,
    VerifyingKey calldata _tallyVk
  ) public onlyOwner {
    uint256 processVkSig = genProcessVkSig(_stateTreeDepth, _messageTreeDepth, _voteOptionTreeDepth, _messageBatchSize);

    if (processVkSet[_mode][processVkSig]) revert ProcessVkAlreadySet();

    uint256 tallyVkSig = genTallyVkSig(_stateTreeDepth, _intStateTreeDepth, _voteOptionTreeDepth);

    if (tallyVkSet[_mode][tallyVkSig]) revert TallyVkAlreadySet();

    VerifyingKey storage processVk = processVks[_mode][processVkSig];
    processVk.alpha1 = _processVk.alpha1;
    processVk.beta2 = _processVk.beta2;
    processVk.gamma2 = _processVk.gamma2;
    processVk.delta2 = _processVk.delta2;

    uint256 processIcLength = _processVk.ic.length;
    for (uint256 i = 0; i < processIcLength; ) {
      processVk.ic.push(_processVk.ic[i]);

      unchecked {
        i++;
      }
    }

    processVkSet[_mode][processVkSig] = true;

    VerifyingKey storage tallyVk = tallyVks[_mode][tallyVkSig];
    tallyVk.alpha1 = _tallyVk.alpha1;
    tallyVk.beta2 = _tallyVk.beta2;
    tallyVk.gamma2 = _tallyVk.gamma2;
    tallyVk.delta2 = _tallyVk.delta2;

    uint256 tallyIcLength = _tallyVk.ic.length;
    for (uint256 i = 0; i < tallyIcLength; ) {
      tallyVk.ic.push(_tallyVk.ic[i]);

      unchecked {
        i++;
      }
    }

    tallyVkSet[_mode][tallyVkSig] = true;

    emit TallyVkSet(tallyVkSig, _mode);
    emit ProcessVkSet(processVkSig, _mode);
  }

  /// @notice Check if the process verifying key is set
  /// @param _stateTreeDepth The state tree depth
  /// @param _messageTreeDepth The message tree depth
  /// @param _voteOptionTreeDepth The vote option tree depth
  /// @param _messageBatchSize The message batch size
  /// @param _mode QV or Non-QV
  /// @return isSet whether the verifying key is set
  function hasProcessVk(
    uint256 _stateTreeDepth,
    uint256 _messageTreeDepth,
    uint256 _voteOptionTreeDepth,
    uint256 _messageBatchSize,
    Mode _mode
  ) public view returns (bool isSet) {
    uint256 sig = genProcessVkSig(_stateTreeDepth, _messageTreeDepth, _voteOptionTreeDepth, _messageBatchSize);
    isSet = processVkSet[_mode][sig];
  }

  /// @notice Get the process verifying key by signature
  /// @param _sig The signature
  /// @param _mode QV or Non-QV
  /// @return vk The verifying key
  function getProcessVkBySig(uint256 _sig, Mode _mode) public view returns (VerifyingKey memory vk) {
    if (!processVkSet[_mode][_sig]) revert ProcessVkNotSet();

    vk = processVks[_mode][_sig];
  }

  /// @inheritdoc IVkRegistry
  function getProcessVk(
    uint256 _stateTreeDepth,
    uint256 _messageTreeDepth,
    uint256 _voteOptionTreeDepth,
    uint256 _messageBatchSize,
    Mode _mode
  ) public view returns (VerifyingKey memory vk) {
    uint256 sig = genProcessVkSig(_stateTreeDepth, _messageTreeDepth, _voteOptionTreeDepth, _messageBatchSize);

    vk = getProcessVkBySig(sig, _mode);
  }

  /// @notice Check if the tally verifying key is set
  /// @param _stateTreeDepth The state tree depth
  /// @param _intStateTreeDepth The intermediate state tree depth
  /// @param _voteOptionTreeDepth The vote option tree depth
  /// @param _mode QV or Non-QV
  /// @return isSet whether the verifying key is set
  function hasTallyVk(
    uint256 _stateTreeDepth,
    uint256 _intStateTreeDepth,
    uint256 _voteOptionTreeDepth,
    Mode _mode
  ) public view returns (bool isSet) {
    uint256 sig = genTallyVkSig(_stateTreeDepth, _intStateTreeDepth, _voteOptionTreeDepth);

    isSet = tallyVkSet[_mode][sig];
  }

  /// @notice Get the tally verifying key by signature
  /// @param _sig The signature
  /// @param _mode QV or Non-QV
  /// @return vk The verifying key
  function getTallyVkBySig(uint256 _sig, Mode _mode) public view returns (VerifyingKey memory vk) {
    if (!tallyVkSet[_mode][_sig]) revert TallyVkNotSet();

    vk = tallyVks[_mode][_sig];
  }

  /// @inheritdoc IVkRegistry
  function getTallyVk(
    uint256 _stateTreeDepth,
    uint256 _intStateTreeDepth,
    uint256 _voteOptionTreeDepth,
    Mode _mode
  ) public view returns (VerifyingKey memory vk) {
    uint256 sig = genTallyVkSig(_stateTreeDepth, _intStateTreeDepth, _voteOptionTreeDepth);

    vk = getTallyVkBySig(sig, _mode);
  }
}