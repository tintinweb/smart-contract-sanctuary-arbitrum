// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./MerkleProof.sol";

contract PlutusPrivateTGE {
    bytes32 public merkleRoot;
    address public governance;
    address public deployer;
    address public proposedGovernance;
    uint256 public accountCap;
    uint256 public raiseCap;
    bool public started = false;
    uint256 raisedAmount;

    mapping(address => uint256) public deposit;

    event TGEStart();
    event Contribute(address indexed user, uint256 amt);
    event WhitelistUpdate();
    event GovernanceWithdraw(address indexed to, uint256 amt);
    event GovernancePropose(address indexed newAddr);
    event GovernanceChange(address indexed from, address indexed to);

    constructor(
        address _deployer,
        address _governance,
        bytes32 _merkleRoot
    ) {
        deployer = _deployer;
        governance = _governance;
        merkleRoot = _merkleRoot;
        accountCap = 0.5 ether;
        started = false;
    }

    function isOnAllowList(bytes32[] calldata _merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256((abi.encodePacked((msg.sender))));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function contribute(bytes32[] calldata _merkleProof) external payable {
        require(started == true, "Soon");
        require(isOnAllowList(_merkleProof), "Sender not on allowlist");
        require(
            msg.value + raisedAmount <= raiseCap,
            "TGE total limit exceeded"
        );
        require(
            deposit[msg.sender] + msg.value <= accountCap,
            "Individual contribution limit exceeded"
        );
        deposit[msg.sender] += msg.value;
        raisedAmount += msg.value;

        emit Contribute(msg.sender, msg.value);
    }

    function details()
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            started,
            address(msg.sender).balance,
            raisedAmount,
            raiseCap,
            deposit[msg.sender],
            accountCap
        );
    }

    /** MODIFIERS */
    modifier onlyDeployerOrGovernance() {
        require(
            msg.sender == governance || msg.sender == deployer,
            "Unauthorized"
        );
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Unauthorized");
        _;
    }

    modifier onlyProposedGovernance() {
        require(msg.sender == proposedGovernance, "Unauthorized");
        _;
    }

    /** GOVERNANCE FUNCTIONS */
    function setMerkleRoot(bytes32 _merkleRoot)
        external
        onlyDeployerOrGovernance
    {
        merkleRoot = _merkleRoot;
        emit WhitelistUpdate();
    }

    function setAccountCapInWEI(uint256 _cap)
        external
        onlyDeployerOrGovernance
    {
        accountCap = _cap;
    }

    function setRaiseCapInETH(uint256 _cap) external onlyDeployerOrGovernance {
        raiseCap = _cap * 1e18;
    }

    function setStarted(bool _started) external onlyDeployerOrGovernance {
        require(raiseCap > 0, "TGE cap cannot be zero");
        started = _started;
        emit TGEStart();
    }

    function governanceWithdrawAll() external onlyGovernance {
        uint256 amt = address(this).balance;
        payable(governance).transfer(address(this).balance);
        emit GovernanceWithdraw(governance, amt);
    }

    function proposeGovernance(address _proposedGovernanceAddr)
        external
        onlyGovernance
    {
        require(_proposedGovernanceAddr != address(0));
        proposedGovernance = _proposedGovernanceAddr;
        emit GovernancePropose(_proposedGovernanceAddr);
    }

    function claimGovernance() external onlyProposedGovernance {
        address oldGovernance = governance;
        governance = proposedGovernance;
        proposedGovernance = address(0);
        emit GovernanceChange(oldGovernance, governance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

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
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}