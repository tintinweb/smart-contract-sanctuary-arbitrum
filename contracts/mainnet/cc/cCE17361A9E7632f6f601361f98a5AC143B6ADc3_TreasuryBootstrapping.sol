// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

error GovernanceInitializationAlreadyPopulated();
error GovernanceInitializationBadBlockNumber();
error OnlyDAO();
error CoraTokenUnpauseNotReady();
error ProtocolPaused();
error DaoInvalidDelaysConfiguration();
error OnlyDelayAdmin();
error DaoInvalidProposal();
error TokenBadInitialTotalSupply();

//SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import { IDeployer } from "../interfaces/IDeployer.sol";

import "./GovernanceErrors.sol";

/**
 * @title GovernanceInitiationData
 * @author Cora Dev Team
 * @notice This contract is used to initiate the Cora governance.
 * @dev This contract will hold information that can be passed to the other contracts of the governance system.
 * This contract will be deployed first and then populated. So other contracts can consume this information.
 */
contract GovernanceInitiationData {
  struct SetupData {
    address tokenAddress;
    address timelockAddress;
    address governorAddress;
  }

  SetupData internal data;
  bool populated = false;
  uint256 deployedBlockNumber;

  constructor() {
    deployedBlockNumber = block.number;
  }

  function populate(SetupData calldata _data) external virtual {
    if (populated) {
      revert GovernanceInitializationAlreadyPopulated();
    }

    if (block.number != deployedBlockNumber) {
      revert GovernanceInitializationBadBlockNumber();
    }
    data = _data;
    populated = true;
  }

  function tokenAddress() public view returns (address) {
    return data.tokenAddress;
  }

  function timelockAddress() public view returns (address) {
    return data.timelockAddress;
  }

  function governorAddress() public view returns (address) {
    return data.governorAddress;
  }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IDeployer {
  event Deployed(address indexed sender, address indexed addr);

  function deploy(bytes memory _initCode, bytes32 _salt)
    external
    returns (address payable createdContract);
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import { IERC20Metadata as IERC20 } from
  "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../governance/GovernanceInitiationData.sol";
import "../governance/GovernanceErrors.sol";

error InvalidContributionAmount();
error NotWhitelistedContributor();
error ExistingContributor();
error InvalidStartTimestamp();
error ContributionSizeReached();
error NotFinishedYet();
error InvalidProof();
error NotStartedYet();
error NotApprovedYet();
error InvalidDeployedState();
error AlreadyApproved();
error InvalidAmount();
error AmountPerUnitNotSet();

contract TreasuryBootstrapping {
  GovernanceInitiationData public initiationData;

  IERC20 public immutable coraToken;
  IERC20 public stablecoinToken;

  uint256 public constant SUPPLY_FOR_BOOTSTRAPPING = 10_000_000 ether; // 10M
  uint256 public constant SUPPLY_PERCENTAGE = 0.1 ether; // 10%

  // Computed values to be set once proposal is approved
  uint256 public startTimeStamp;
  uint256 public amountPerUnit;
  uint256 public totalContributions;

  enum State {
    Deployed,
    Approved,
    Started,
    Settled,
    Cancelled
  }

  State private state;

  // Parameters to start the bootstrapping
  uint256 public fdv;
  uint256 public targetAmount;
  uint256 public duration;
  uint256 public privatePeriod;
  address public beneficiary;
  uint256 public minContributionSize;
  uint256 public maxContributionSize;
  bytes32 public merkleRoot;

  mapping(address contributor => bool contributed) public hasContributed;

  mapping(address contributor => uint256 amount) public contributionsPerAddress;

  constructor(GovernanceInitiationData _initiationData) {
    coraToken = IERC20(_initiationData.tokenAddress());

    // explicitly assert this condition to give transparency to the DAO
    uint256 totalSupplyComputed = coraToken.totalSupply() * SUPPLY_PERCENTAGE / 1 ether;

    assert(totalSupplyComputed == SUPPLY_FOR_BOOTSTRAPPING);

    initiationData = _initiationData;

    state = State.Deployed;
  }

  // EXTERNAL FUNCTIONS
  function approveAndSchedule(
    uint256 _fdv,
    uint256 _targetAmount,
    uint256 _duration,
    uint256 _privatePeriod,
    address _beneficiary,
    uint256 _minContributionSize,
    uint256 _maxContributionSize,
    uint256 _startTimeAfterApproval,
    address _stablecoinToken,
    bytes32 _merkleRoot
  ) external whenDeployed onlyDao {
    fdv = _fdv;
    targetAmount = _targetAmount;
    duration = _duration;
    privatePeriod = _privatePeriod;
    beneficiary = _beneficiary;
    minContributionSize = _minContributionSize;
    maxContributionSize = _maxContributionSize;
    merkleRoot = _merkleRoot;
    stablecoinToken = IERC20(_stablecoinToken);

    startTimeStamp = block.timestamp + _startTimeAfterApproval;
    amountPerUnit = _targetAmount * 1 ether / SUPPLY_FOR_BOOTSTRAPPING;
    state = State.Approved;
  }

  function cancel() external whenDeployed onlyDao {
    if (state == State.Approved) {
      revert AlreadyApproved();
    }
    uint256 remainingTokens = coraToken.balanceOf(address(this));
    state = State.Cancelled;
    coraToken.transfer(initiationData.timelockAddress(), remainingTokens);
  }

  // bootstrap when started
  function bootstrap(uint256 _amount, uint256 _index, bytes32[] calldata _merkleProof)
    external
    whenApproved
    whenStarted
    onlyValidAmounts(_amount)
  {
    // @dev Verify if contributor is whitelisted
    if (_isInPrivatePeriod()) {
      _verifyIfWhitelisted(_index, msg.sender, _merkleProof);
    }

    // @dev Verify hasn't reach its limits
    uint256 contributionsBySender = contributionsPerAddress[msg.sender];

    if (contributionsBySender + _amount > maxContributionSize) {
      revert ContributionSizeReached();
    }

    if (!hasContributed[msg.sender]) {
      hasContributed[msg.sender] = true;
    }

    uint256 amountTokensToReceive = calculateAmount(_amount);
    totalContributions += _amount;
    contributionsPerAddress[msg.sender] += _amount;
    stablecoinToken.transferFrom(msg.sender, address(this), _amount);
    coraToken.transfer(msg.sender, amountTokensToReceive);
  }

  /**
    @notice Settles the treasury bootstrapping event by transferring the remaining cora tokens to the DAO and the stablecoins to the beneficiary.
   */
  function settle() external whenApproved whenFinished {
    state = State.Settled;
    uint256 amountOfStables = stablecoinToken.balanceOf(address(this));
    uint256 remainingTokens = coraToken.balanceOf(address(this));
    coraToken.transfer(initiationData.timelockAddress(), remainingTokens);
    stablecoinToken.transfer(beneficiary, amountOfStables);
  }

  // INTERNAL FUNCTIONS
  function _isInPrivatePeriod() internal view returns (bool) {
    return block.timestamp < startTimeStamp + privatePeriod;
  }

  function _verifyIfWhitelisted(uint256 _index, address _account, bytes32[] memory _merkleProof)
    internal
    view
  {
    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(_index, _account));
    if (!MerkleProof.verify(_merkleProof, merkleRoot, node)) {
      revert InvalidProof();
    }
  }

  // MODIFIERS
  modifier whenFinished() {
    if (block.timestamp < getEndDate()) {
      revert NotFinishedYet();
    }
    _;
  }

  modifier onlyValidAmounts(uint256 _amount) {
    // @dev only multiples of amountPerUnit
    if (_amount % amountPerUnit != 0) {
      revert InvalidContributionAmount();
    }
    _;
  }

  modifier whenStarted() {
    if (block.timestamp < startTimeStamp) {
      revert NotStartedYet();
    }
    _;
  }

  modifier whenApproved() {
    if (state != State.Approved) {
      revert NotApprovedYet();
    }
    _;
  }

  modifier whenDeployed() {
    if (state != State.Deployed) {
      revert InvalidDeployedState();
    }
    _;
  }

  modifier onlyDao() {
    if (msg.sender != initiationData.timelockAddress()) {
      revert OnlyDAO();
    }
    _;
  }

  // GETTERS
  function calculateAmount(uint256 _LUSDAmount) public view returns (uint256) {
    if (_LUSDAmount == 0) {
      revert InvalidAmount();
    }
    if (amountPerUnit == 0) {
      revert AmountPerUnitNotSet();
    }
    return _LUSDAmount / amountPerUnit * 1 ether;
  }

  function getEndDate() public view returns (uint256) {
    return startTimeStamp + duration;
  }

  function getEndOfPrivatePeriod() public view returns (uint256) {
    return startTimeStamp + privatePeriod;
  }

  function getRemainingTokens() public view returns (uint256) {
    return coraToken.balanceOf(address(this));
  }

  function getStablesBalance() public view returns (uint256) {
    return stablecoinToken.balanceOf(address(this));
  }

  function getStatus() public view returns (State) {
    if (state == State.Approved && block.timestamp > startTimeStamp) {
      return State.Started;
    }
    return state;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
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