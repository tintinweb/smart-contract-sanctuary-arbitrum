// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MerkleRoots {
    // Construct a sparse merkle tree from a list of members and respective claim
    // amounts. This tree will be sparse in the sense that rather than padding
    // tree levels to the next power of 2, missing nodes will default to a value of
    // 0.
    function constructTree(
        bytes32[] memory members
    ) external pure returns (bytes32 root, bytes32[][] memory tree) {
        require(members.length != 0);
        // Determine tree height.
        uint256 height = 0;
        {
            uint256 n = members.length;
            while (n != 0) {
                n = n == 1 ? 0 : (n + 1) / 2;
                ++height;
            }
        }
        tree = new bytes32[][](height);
        // The first layer of the tree contains the leaf nodes, which are
        // hashes of each member and claim amount.
        bytes32[] memory nodes = tree[0] = new bytes32[](members.length);
        for (uint256 i = 0; i < members.length; ++i) {
            // Leaf hashes are inverted to prevent second preimage attacks.
            nodes[i] = ~keccak256(abi.encode(members[i]));
        }
        // Build up subsequent layers until we arrive at the root hash.
        // Each parent node is the hash of the two children below it.
        // E.g.,
        //              H0         <-- root (layer 2)
        //           /     \
        //        H1        H2
        //      /   \      /  \
        //    L1     L2  L3    L4  <--- leaves (layer 0)
        for (uint256 h = 1; h < height; ++h) {
            uint256 nHashes = (nodes.length + 1) / 2;
            bytes32[] memory hashes = new bytes32[](nHashes);
            for (uint256 i = 0; i < nodes.length; i += 2) {
                bytes32 a = nodes[i];
                // Tree is sparse. Missing nodes will have a value of 0.
                bytes32 b = i + 1 < nodes.length ? nodes[i + 1] : bytes32(0);
                // Siblings are always hashed in sorted order.
                hashes[i / 2] = keccak256(
                    a > b ? abi.encode(b, a) : abi.encode(a, b)
                );
            }
            tree[h] = nodes = hashes;
        }
        // Note the tree root is at the bottom.
        root = tree[height - 1][0];
    }

    // Given a merkle tree and a member index (leaf node index), generate a proof.
    // The proof is simply the list of sibling nodes/hashes leading up to the root.
    function createProof(
        uint256 memberIndex,
        bytes32[][] memory tree
    ) external pure returns (bytes32[] memory proof) {
        uint256 leafIndex = memberIndex;
        uint256 height = tree.length;
        proof = new bytes32[](height - 1);
        for (uint256 h = 0; h < proof.length; ++h) {
            uint256 siblingIndex = leafIndex % 2 == 0
                ? leafIndex + 1
                : leafIndex - 1;
            if (siblingIndex < tree[h].length) {
                proof[h] = tree[h][siblingIndex];
            }
            leafIndex /= 2;
        }
    }
}