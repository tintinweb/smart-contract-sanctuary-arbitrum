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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IConnext } from '../interfaces/IConnext.sol';
import { ICrosschain } from '../interfaces/ICrosschain.sol';
import { MerkleSet } from './abstract/MerkleSet.sol';

/**
 * @title Satellite
 * @notice This contract allows a beneficiary to claim tokens to this chain from a Distributor on another chain.
 * This contract validates inclusion in the merkle root, but only as a sanity check. The distributor contract
 * is the source of truth for claim eligibility.
 *
 * @dev The beneficiary domain in the merkle leaf must be this contract's domain. The beneficiary address may be
 * an EOA or a smart contract and must match msg.sender. The Satellite contract(s) and CrosschainDistributor contracts must only
 * be deployed on chains supported by the Connext protocol.
 * 
 * Note that anyone could deploy a fake Satellite contract that does not require msg.sender to match the beneficiary or the Satellite
 * domain to match the beneficiary domain. This would allow the attacker to claim tokens from the distributor on behalf of a beneficiary onto
 * the chain / domain specified by that beneficiary's merkle leaf. This is not a security risk to the CrosschainMerkleDistributor,
 * as this is the intended behavior for a properly constructed merkle root.
 */

contract Satellite is MerkleSet {
  // ========== Events ===========

  /**
   * @notice Emitted when a claim is initiated
   * @param id The transfer id for sending claim to distributor
   * @param beneficiary The user claiming tokens
   * @param total The beneficiary's total claimable token quantity (which may not be immediately claimable due to vesting conditions)
   */
  event ClaimInitiated(bytes32 indexed id, address indexed beneficiary, uint256 total);

  // ========== Storage ===========

  /**
   * @notice The distributor hosted on on distributorDomain
   */
  ICrosschain public immutable distributor;

  /**
   * @notice The domain of the distributor
   */
  uint32 public immutable distributorDomain;

  /**
   * @notice The domain of this satellite
   */
  uint32 public immutable domain;

  /**
   * @notice Address of Connext on the satellite domain
   */
  IConnext public immutable connext;

  constructor(
    IConnext _connext,
    ICrosschain _distributor,
    uint32 _distributorDomain,
    bytes32 _merkleRoot
  ) MerkleSet(_merkleRoot) {
    distributor = _distributor;
    distributorDomain = _distributorDomain;
    connext = _connext;
    domain = uint32(_connext.domain());

    // the distributor must be deployed on a different domain than the satellite
    require(_distributorDomain != domain, 'same domain');
  }

  // ========== Public Methods ===========

  /**
   * @notice Initiates crosschain claim by msg.sender, relayer fees paid by native asset only.
   * @dev Verifies membership in distribution merkle proof and xcalls to Distributor to initiate claim
   * @param total The amount of the claim (in leaf)
   * @param proof The merkle proof of the leaf in the root
   */
  function initiateClaim(uint256 total, bytes32[] calldata proof) public payable {
    // load values into memory to reduce sloads
    uint32 _distributorDomain = distributorDomain;
    uint32 _domain = domain;

    // Verify the proof before sending cross-chain as a cost + time saving step
    _verifyMembership(keccak256(abi.encodePacked(msg.sender, total, _domain)), proof);

    // Send claim to distributor via crosschain call
    bytes32 transferId = connext.xcall{ value: msg.value }(
      _distributorDomain, // destination domain
      address(distributor), // to
      address(0), // asset
      address(0), // delegate, only required for self-execution + slippage
      0, // total
      0, // slippage
      abi.encodePacked(msg.sender, _domain, total, proof) // data
    );

    // Emit event
    emit ClaimInitiated(transferId, msg.sender, total);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import { IMerkleSet } from '../../interfaces/IMerkleSet.sol';

/**
 * @title MerkleSet
 * @notice Checks merkle proofs
 * @dev Contracts inheriting from MerkleSet may update the merkle root whenever desired.
 */
contract MerkleSet is IMerkleSet {
  bytes32 private merkleRoot;

  constructor(bytes32 _merkleRoot) {
    _setMerkleRoot(_merkleRoot);
  }

  modifier validMerkleProof(bytes32 leaf, bytes32[] memory merkleProof) {
    _verifyMembership(leaf, merkleProof);

    _;
  }

  /**
   * @notice Tests membership in the merkle set
   */
  function _testMembership(
    bytes32 leaf,
    bytes32[] memory merkleProof
  ) internal view returns (bool) {
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }

  function getMerkleRoot() public view returns (bytes32) {
    return merkleRoot;
  }

  /**
   * @dev Verifies membership in the merkle set
   */
  function _verifyMembership(bytes32 leaf, bytes32[] memory merkleProof) internal view {
    require(_testMembership(leaf, merkleProof), 'invalid proof');
  }

  /**
   * @dev Updates the merkle root
   */
  function _setMerkleRoot(bytes32 _merkleRoot) internal {
    merkleRoot = _merkleRoot;
    emit SetMerkleRoot(merkleRoot);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IConnext {

  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32);

  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData,
    uint256 _relayerFee
  ) external returns (bytes32);

  function xcallIntoLocal(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32);

  function domain() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IDistributor } from './IDistributor.sol';
import { IXReceiver } from './IXReceiver.sol';

/**
 * @notice Defines functions and events for receiving and tracking crosschain claims
 */
interface ICrosschain is IDistributor, IXReceiver {
    /**
   * @dev The beneficiary and recipient may be different addresses. The beneficiary is the address
   * eligible to receive the claim, and the recipient is where the funds are actually sent.
   */
  event CrosschainClaim(
    bytes32 indexed id,
    address indexed beneficiary,
    address indexed recipient,
    uint32 recipientDomain,
    uint256 amount
  );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev This struct tracks claim progress for a given beneficiary.
 * Because many claims are stored in a merkle root, this struct is only valid once initialized.
 * Users can no longer claim once their claimed quantity meets or exceeds their total quantity.
 * Note that admins may update the merkle root or adjust the total quantity for a specific
 * beneficiary after initialization!
 */
struct DistributionRecord {
  bool initialized; // has the claim record been initialized
  uint120 total; // total token quantity claimable
  uint120 claimed; // token quantity already claimed
}

interface IDistributor {
  event InitializeDistributor(
    IERC20 indexed token, // the ERC20 token being distributed
    uint256 total, // total distribution quantity across all beneficiaries
    string uri, // a URI for additional information about the distribution
    uint256 fractionDenominator // the denominator for vesting fractions represented as integers
  );

  // Fired once when a beneficiary's distribution record is set up
  event InitializeDistributionRecord(address indexed beneficiary, uint256 total);

  // Fired every time a claim for a beneficiary occurs
  event Claim(address indexed beneficiary, uint256 amount);

  /**
   * @dev get the current distribution status for a particular user
   * @param beneficiary the address of the beneficiary
   */
  function getDistributionRecord(
    address beneficiary
  ) external view returns (DistributionRecord memory);

  /**
   * @dev get the amount of tokens currently claimable by a beneficiary
   * @param beneficiary the address of the beneficiary
   */
  function getClaimableAmount(address beneficiary) external view returns (uint256);

  /**
   * @dev get the denominator for vesting fractions represented as integers
   */
  function getFractionDenominator() external view returns (uint256);

  /**
   * @dev get the ERC20 token being distributed
   */
  function token() external view returns (IERC20);

  /**
	* @dev get the total distribution quantity across all beneficiaries
	*/
  function total() external view returns (uint256);

	/**
	* @dev get a URI for additional information about the distribution
	*/
  function uri() external view returns (string memory);

	/**
	* @dev get a human-readable name for the distributor that describes basic functionality
	* On-chain consumers should rely on registered ERC165 interface IDs or similar for more specificity
	*/
  function NAME() external view returns (string memory);

	/**
	* @dev get a human-readable version for the distributor that describes basic functionality
	* The version should update whenever functionality significantly changes
	* On-chain consumers should rely on registered ERC165 interface IDs or similar for more specificity
	*/
  function VERSION() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IMerkleSet {
	event SetMerkleRoot(bytes32 merkleRoot);

	function getMerkleRoot() external view returns (bytes32 root);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IXReceiver {
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external returns (bytes memory);
}