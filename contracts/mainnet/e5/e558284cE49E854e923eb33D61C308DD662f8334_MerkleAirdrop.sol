pragma solidity 0.8.9;

interface IVe {

  enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
  }

  struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint ts;
    uint blk; // block
  }
  /* We cannot really do block numbers per se b/c slope is per time, not per block
  * and per block could be fairly bad b/c Ethereum changes blocktimes.
  * What we can do is to extrapolate ***At functions */

  struct LockedBalance {
    int128 amount;
    uint end;
  }

  function token() external view returns (address);

  function balanceOfNFT(uint) external view returns (uint);

  function isApprovedOrOwner(address, uint) external view returns (bool);

  function createLockFor(uint, uint, address) external returns (uint);
  
  function createLockForPartner(uint, uint, address) external returns (uint);

  function userPointEpoch(uint tokenId) external view returns (uint);

  function epoch() external view returns (uint);

  function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

  function pointHistory(uint loc) external view returns (Point memory);

  function checkpoint() external;

  function depositFor(uint tokenId, uint value) external;

  function attachToken(uint tokenId) external;

  function detachToken(uint tokenId) external;

  function voting(uint tokenId) external;

  function abstain(uint tokenId) external;
}


// File: contracts/interfaces/IBurger.sol


pragma solidity 0.8.9;

interface IBurger {
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
}

// File: contracts/libraries/MerkleProof.sol

// File: openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol

pragma solidity 0.8.9;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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
     * @dev Returns true if a `leafs` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, `proofs` for each leaf must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Then
     * 'proofFlag' designates the nodes needed for the multi proof.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    ) internal pure returns (bool) {
        return processMultiProof(leafs, proofs, proofFlag) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using the multi proof as `proofFlag`. A multi proof is
     * valid if the final hash matches the root of the tree.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leafs` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leafsLen = leafs.length;
        uint256 proofsLen = proofs.length;
        uint256 totalHashes = proofFlag.length;

        // Check proof validity.
        require(leafsLen + proofsLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

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
        //   `proofs` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leafsLen ? leafs[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlag[i] ? leafPos < leafsLen ? leafs[leafPos++] : hashes[hashPos++] : proofs[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        return hashes[totalHashes - 1];
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

/// @title MerkleClaim
/// @notice Claims BURGER for members of a merkle tree
/// @author Modified from Merkle Airdrop Starter (https://github.com/Anish-Agnihotri/merkle-airdrop-starter/blob/master/contracts/src/MerkleClaimERC20.sol)
contract MerkleAirdrop {
    /// @notice max lock period 26 weeeks
    uint256 public constant LOCK = 86400 * 7 * 26;
    uint256 public constant MAX_AMOUNT = 500_000 * 10 ** 18;

    address public owner;

    uint256 public duration;
    uint256 public startTime;
    /// ============ Immutable storage ============
    IVe public ve;
    /// @notice BURGER token to claim
    IBurger public burger;
    /// @notice ERC20-claimee inclusion root
    bytes32 public merkleRoot;

    /// @notice Mapping from boost level to veBURGER token amount
    mapping(uint => uint) public boostAmount;

    /// ============ Mutable storage ============

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => bool) public hasClaimed;

    /// ============ Modifiers =============

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    /// ============ Constructor ============

    /// @notice Initialize new MerkleClaim contract
    /// @param _ve address
    /// @param _merkleRoot of claimees
    /// @param _duration duration for airdrop
    constructor(
        address _ve, bytes32 _merkleRoot, uint256 _duration
    ) {
        owner = msg.sender;
        ve = IVe(_ve);
        burger = IBurger(IVe(_ve).token());
        merkleRoot = _merkleRoot;
        duration = _duration;

        boostAmount[1] = 25;  // 8000 wallys (200k)
        boostAmount[2] = 50;  // 5000 wallys (250k)
        boostAmount[3] = 100; // 500 wallys (50k)
    }

    /* ============ Events ============ */

    /// @notice Emitted after a successful token claim
    /// @param to recipient of claim
    /// @param amount of veTokens claimed
    /// @param tokenId veToken NFT Id
    event Claim(address indexed to, uint256 amount, uint256 tokenId);

    /// @notice Emitted after a successful withdrawal of remaining tokens
    /// @param recipient recipient of remaining tokens
    /// @param amount of remaining tokens
    event Withdrawal(address indexed recipient, uint256 amount);

    /* ============ Functions ============ */

    /// @notice set start time for airdrop
    /// @param _startTime start time (in seconds)
    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, "Invalid start time");
        startTime = _startTime;
    }

    /// @notice set duration for airdrop
    /// @param _duration duration (in days)
    function setDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0, "Invalid duration days");
        duration = _duration;
    }

    /// @notice set merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
    
    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param _to address of claimee
    /// @param _boostLevel depending on number 1-3 is how many veBURGER the receive 
    /// @param _proof merkle proof to prove address and amount are in tree
    function claim(
        address _to,
        uint256 _boostLevel,
        bytes32[] calldata _proof
    ) external {
        uint256 endTime = startTime + duration * 86400;
        // check valid timestamp
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Airdrop is not started yet or already finished");
        
        // Throw if address has already claimed tokens
        require(!hasClaimed[_to], "ALREADY_CLAIMED");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(_to, _boostLevel));
        bool isValidLeaf = MerkleProof.verify(_proof, merkleRoot, leaf);
        require(isValidLeaf, "NOT_IN_MERKLE");

        uint256 claimAmount = boostAmount[_boostLevel] * 10 ** 18;
        require(burger.balanceOf(address(this)) >= claimAmount, "All tokens were already claimed");

        // Set address to claimed
        hasClaimed[_to] = true;
        burger.approve(address(ve), claimAmount);
        // Claim veBURGERs for address
        uint256 tokenId = ve.createLockFor(claimAmount, LOCK, _to);
        // Emit claim event
        emit Claim(_to, claimAmount, tokenId);
    }

    /// @notice withdraw remaining tokens if airdrop is finished
    function withdrawBURGER(address _recipient) external onlyOwner {
        require(block.timestamp > startTime + duration * 86400, "Airdrop is not finished yet");
        uint256 remaining = burger.balanceOf(address(this));
        require(remaining > 0, "No remaining tokens");
        burger.transfer(_recipient, remaining);
        // Emit withdrawal event
        emit Withdrawal(_recipient, remaining);
    }

    function setClaimStatus(address[] memory _accounts, bool[] memory _statuses) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            hasClaimed[_accounts[i]] = _statuses[i];
        }
    }
}