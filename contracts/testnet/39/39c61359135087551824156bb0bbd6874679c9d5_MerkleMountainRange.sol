// SPDX-License-Identifier: Apache2
pragma solidity ^0.8.17;

import "./MerkleMultiProof.sol";
import "openzeppelin/utils/math/Math.sol";

/// @title A representation of a MerkleMountainRange leaf
struct MmrLeaf {
    // the leftmost index of a node
    uint256 k_index;
    // The position in the tree
    uint256 leaf_index;
    // The hash of the position in the tree
    bytes32 hash;
}

struct Iterator {
    uint256 offset;
    bytes32[] data;
}

/**
 * @title A Merkle Mountain Range proof library
 * @author Polytope Labs
 * @notice Use this library to verify the leaves of a merkle mountain range tree
 * @dev refer to research for more info. https://research.polytope.technology/merkle-mountain-range-multi-proofs
 */
library MerkleMountainRange {
    /// @notice Verify that merkle proof is accurate
    /// @notice This calls CalculateRoot(...) under the hood
    /// @param root hash of the Merkle's root node
    /// @param proof a list of nodes required for the proof to be verified
    /// @param leaves a list of mmr leaves to prove
    /// @return boolean if the calculated root matches the provides root node
    function VerifyProof(bytes32 root, bytes32[] memory proof, MmrLeaf[] memory leaves, uint256 mmrSize)
        public
        pure
        returns (bool)
    {
        return root == CalculateRoot(proof, leaves, mmrSize);
    }

    /// @notice Calculate merkle root
    /// @notice this method allows computing the root hash of a merkle tree using Merkle Mountain Range
    /// @param proof A list of the merkle nodes that are needed to re-calculate root node.
    /// @param leaves a list of mmr leaves to prove
    /// @param leafCount the size of the merkle tree
    /// @return bytes32 hash of the computed root node
    function CalculateRoot(bytes32[] memory proof, MmrLeaf[] memory leaves, uint256 leafCount)
        public
        pure
        returns (bytes32)
    {
        // special handle the only 1 leaf MMR
        if (leafCount == 1 && leaves.length == 1 && leaves[0].leaf_index == 0) {
            return leaves[0].hash;
        }

        uint256[] memory subtrees = subtreeHeights(leafCount);
        uint256 length = subtrees.length;
        Iterator memory peakRoots = Iterator(0, new bytes32[](length));
        Iterator memory proofIter = Iterator(0, proof);

        uint256 current_subtree = 0;
        for (uint256 p = 0; p < length; p++) {
            uint256 height = subtrees[p];
            current_subtree += 2 ** height;

            MmrLeaf[] memory subtreeLeaves = new MmrLeaf[](0);
            if (leaves.length > 0) {
                (subtreeLeaves, leaves) = leavesForSubtree(leaves, current_subtree);
            }

            if (subtreeLeaves.length == 0) {
                if (proofIter.data.length == proofIter.offset) {
                    break;
                } else {
                    push(peakRoots, next(proofIter));
                }
            } else if (subtreeLeaves.length == 1 && height == 0) {
                push(peakRoots, subtreeLeaves[0].hash);
            } else {
                push(peakRoots, CalculateSubtreeRoot(subtreeLeaves, proofIter, height));
            }
        }

        unchecked {
            peakRoots.offset--;
        }

        while (peakRoots.offset != 0) {
            bytes32 right = previous(peakRoots);
            bytes32 left = previous(peakRoots);
            unchecked {
                ++peakRoots.offset;
            }
            peakRoots.data[peakRoots.offset] = keccak256(abi.encodePacked(right, left));
        }

        return peakRoots.data[0];
    }

    function subtreeHeights(uint256 leavesLength) internal pure returns (uint256[] memory) {
        uint256 maxSubtrees = 64;
        uint256[] memory indices = new uint256[](maxSubtrees);
        uint256 i = 0;
        uint256 current = leavesLength;
        for (; i < maxSubtrees; i++) {
            if (current == 0) {
                break;
            }
            uint256 log = Math.log2(current);
            indices[i] = log;
            current = current - 2 ** log;
        }

        // resize array?, sigh solidity.
        uint256 excess = maxSubtrees - i;
        assembly {
            mstore(indices, sub(mload(indices), excess))
        }

        return indices;
    }

    /// @notice calculate root hash of a subtree of the merkle mountain
    /// @param peakLeaves  a list of nodes to provide proof for
    /// @param proofIter   a list of node hashes to traverse to compute the peak root hash
    /// @param height    Height of the subtree
    /// @return peakRoot a tuple containing the peak root hash, and the peak root position in the merkle
    function CalculateSubtreeRoot(MmrLeaf[] memory peakLeaves, Iterator memory proofIter, uint256 height)
        internal
        pure
        returns (bytes32)
    {
        uint256[] memory current_layer;
        Node[] memory leaves;
        (leaves, current_layer) = mmrLeafToNode(peakLeaves);

        Node[][] memory layers = new Node[][](height);
        for (uint256 i = 0; i < height; i++) {
            uint256 nodelength = 2 ** (height - i);
            if (current_layer.length == nodelength) {
                break;
            }

            uint256[] memory siblings = siblingIndices(current_layer);
            uint256[] memory diff = difference(siblings, current_layer);

            uint256 length = diff.length;
            layers[i] = new Node[](length);
            for (uint256 j = 0; j < length; j++) {
                layers[i][j] = Node(diff[j], next(proofIter));
            }

            current_layer = parentIndices(siblings);
        }

        return MerkleMultiProof.CalculateRoot(layers, leaves);
    }

    /**
     * @notice difference ensures all nodes have a sibling.
     * @dev left and right are designed to be equal length array
     * @param left a list of hashes
     * @param right a list of hashes to compare
     * @return uint256[] a new array with difference
     */
    function difference(uint256[] memory left, uint256[] memory right) internal pure returns (uint256[] memory) {
        uint256 length = left.length;
        uint256 rightLength = right.length;

        uint256[] memory diff = new uint256[](length);
        uint256 d = 0;
        for (uint256 i = 0; i < length; i++) {
            bool found = false;
            for (uint256 j = 0; j < rightLength; j++) {
                if (left[i] == right[j]) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                diff[d] = left[i];
                d++;
            }
        }

        // resize array?, sigh solidity.
        uint256 excess = length - d;
        assembly {
            mstore(diff, sub(mload(diff), excess))
        }

        return diff;
    }

    /**
     * @dev calculates the index of each sibling index of the proof nodes
     * @dev proof nodes are the nodes that will be traversed to estimate the root hash
     * @param indices a list of proof nodes indices
     * @return uint256[] a list of sibling indices
     */
    function siblingIndices(uint256[] memory indices) internal pure returns (uint256[] memory) {
        uint256 length = indices.length;
        uint256[] memory siblings = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 index = indices[i];
            if (index == 0) {
                siblings[i] = index + 1;
            } else if (index % 2 == 0) {
                siblings[i] = index + 1;
            } else {
                siblings[i] = index - 1;
            }
        }

        return siblings;
    }

    /**
     * @notice Compute Parent Indices
     * @dev Used internally to calculate the indices of the parent nodes of the provided proof nodes
     * @param indices a list of indices of proof nodes in a merkle mountain
     * @return uint256[] a list of parent indices for each index provided
     */
    function parentIndices(uint256[] memory indices) internal pure returns (uint256[] memory) {
        uint256 length = indices.length;
        uint256[] memory parents = new uint256[](length);
        uint256 k = 0;

        for (uint256 i = 0; i < length; i++) {
            uint256 index = indices[i] / 2;
            if (k > 0 && parents[k - 1] == index) {
                continue;
            }
            parents[k] = index;
            unchecked {
                ++k;
            }
        }

        // resize array?, sigh solidity.
        uint256 excess = length - k;

        assembly {
            mstore(parents, sub(mload(parents), excess))
        }

        return parents;
    }

    /**
     * @notice Convert Merkle mountain Leaf to a Merkle Node
     * @param leaves list of merkle mountain range leaf
     * @return A tuple with the list of merkle nodes and the list of nodes at 0 and 1 respectively
     */
    function mmrLeafToNode(MmrLeaf[] memory leaves) internal pure returns (Node[] memory, uint256[] memory) {
        uint256 i = 0;
        uint256 length = leaves.length;
        Node[] memory nodes = new Node[](length);
        uint256[] memory indices = new uint256[](length);
        while (i < length) {
            nodes[i] = Node(leaves[i].k_index, leaves[i].hash);
            indices[i] = leaves[i].k_index;
            ++i;
        }

        return (nodes, indices);
    }

    /**
     * @notice Get a meountain peak's leaves
     * @notice this splits the leaves into either side of the peak [left & right]
     * @param leaves a list of mountain merkle leaves, for a subtree
     * @param leafIndex the index of the leaf of the next subtree
     * @return A tuple of 2 arrays of mountain merkle leaves. Index 1 and 2 represent left and right of the peak respectively
     */
    function leavesForSubtree(MmrLeaf[] memory leaves, uint256 leafIndex)
        internal
        pure
        returns (MmrLeaf[] memory, MmrLeaf[] memory)
    {
        uint256 p = 0;
        uint256 length = leaves.length;
        for (; p < length; p++) {
            if (leafIndex <= leaves[p].leaf_index) {
                break;
            }
        }

        uint256 len = p == 0 ? 0 : p;
        MmrLeaf[] memory left = new MmrLeaf[](len);
        MmrLeaf[] memory right = new MmrLeaf[](length - len);

        uint256 i = 0;
        uint256 leftLength = left.length;
        while (i < leftLength) {
            left[i] = leaves[i];
            ++i;
        }

        uint256 j = 0;
        while (i < length) {
            right[j] = leaves[i];
            ++i;
            ++j;
        }

        return (left, right);
    }

    function push(Iterator memory iterator, bytes32 data) internal pure {
        iterator.data[iterator.offset] = data;
        unchecked {
            ++iterator.offset;
        }
    }

    function next(Iterator memory iterator) internal pure returns (bytes32) {
        bytes32 data = iterator.data[iterator.offset];
        unchecked {
            ++iterator.offset;
        }

        return data;
    }

    function previous(Iterator memory iterator) internal pure returns (bytes32) {
        bytes32 data = iterator.data[iterator.offset];
        unchecked {
            --iterator.offset;
        }

        return data;
    }
}

// SPDX-License-Identifier: Apache2
pragma solidity ^0.8.17;

import "openzeppelin/utils/math/Math.sol";

/// @title A representation of a Merkle tree node
struct Node {
    // Distance of the node to the leftmost node
    uint256 k_index;
    // A hash of the node itself
    bytes32 node;
}

/**
 * @title A Merkle Multi proof library
 * @author Polytope Labs
 * @dev Use this library to verify merkle tree leaves using merkle multi proofs
 * @dev refer to research for more info. https://research.polytope.technology/merkle-multi-proofs
 */
library MerkleMultiProof {
    /**
     * @notice Verify a Merkle Multi Proof
     * @param root hash of the root node of the merkle tree
     * @param proof A list of the merkle nodes along with their k-indices that are needed to re-calculate root node.
     * @param leaves A list of the leaves along with their k-indices to prove
     * @return boolean if the calculated root matches the provides root node
     */
    function VerifyProof(bytes32 root, Node[][] memory proof, Node[] memory leaves) internal pure returns (bool) {
        return root == CalculateRoot(proof, leaves);
    }

    /**
     * @notice Verify a Merkle Multi Proof whose internal nodes are sorted
     * @param root hash of the root node of the merkle tree
     * @param proof A list of the merkle nodes along with their k-indices that are needed to re-calculate root node.
     * @param leaves A list of the leaves along with their k-indices to prove
     * @return boolean if the calculated root matches the provides root node
     */
    function VerifyProofSorted(bytes32 root, Node[][] memory proof, Node[] memory leaves)
        internal
        pure
        returns (bool)
    {
        return root == CalculateRootSorted(proof, leaves);
    }

    /// @notice Calculate the hash of the root node
    /// @dev Use this function to calculate the hash of the root node
    /// @param proof A list of the merkle nodes along with their k-indices that are needed to re-calculate root node.
    /// @param leaves A list of the leaves along with their k-indices to prove
    /// @return Hash of root node, value is a bytes32 type
    function CalculateRoot(Node[][] memory proof, Node[] memory leaves) internal pure returns (bytes32) {
        // holds the output from hashing a previous layer
        Node[] memory next_layer = new Node[](0);

        // merge leaves
        proof[0] = mergeSort(leaves, proof[0]);

        uint256 proof_length = proof.length;
        for (uint256 height = 0; height < proof_length; height++) {
            Node[] memory current_layer = new Node[](0);

            if (next_layer.length == 0) {
                current_layer = proof[height];
            } else {
                current_layer = mergeSort(proof[height], next_layer);
            }

            next_layer = new Node[](div_ceil(current_layer.length, 2));

            uint256 p = 0;
            uint256 current_layer_length = current_layer.length;
            for (uint256 index = 0; index < current_layer_length; index += 2) {
                if (index + 1 >= current_layer_length) {
                    Node memory node = current_layer[index];
                    node.k_index = div_floor(current_layer[index].k_index, 2);
                    next_layer[p] = node;
                } else {
                    Node memory node;
                    node.k_index = div_floor(current_layer[index].k_index, 2);
                    node.node = _optimizedHash(current_layer[index].node, current_layer[index + 1].node);
                    next_layer[p] = node;
                    unchecked {
                        p++;
                    }
                }
            }
        }

        // we should have arrived at the root node
        require(next_layer.length == 1);

        return next_layer[0].node;
    }

    /// @notice Calculate the hash of the root node using a sorted node approach.
    /// @dev Use this function to calculate the hash of the root node
    /// @param proof A list of the merkle nodes that are needed to re-calculate root node.
    /// @param leaves A list of the leaves to prove
    /// @return Hash of root node, value is a bytes32 type
    function CalculateRootSorted(Node[][] memory proof, Node[] memory leaves) internal pure returns (bytes32) {
        // holds the output from hashing a previous layer
        Node[] memory next_layer = new Node[](0);

        // merge leaves
        proof[0] = mergeSort(leaves, proof[0]);

        uint256 proof_length = proof.length;
        for (uint256 height = 0; height < proof_length; height++) {
            Node[] memory current_layer = new Node[](0);

            if (next_layer.length == 0) {
                current_layer = proof[height];
            } else {
                current_layer = mergeSort(proof[height], next_layer);
            }
            uint256 current_layer_length = current_layer.length;
            uint256 p = 0;

            next_layer = new Node[](div_ceil(current_layer_length, 2));
            for (uint256 index = 0; index < current_layer_length; index += 2) {
                if (index + 1 >= current_layer_length) {
                    Node memory node = current_layer[index];
                    node.k_index = div_floor(current_layer[index].k_index, 2);
                    next_layer[p] = node;
                } else {
                    Node memory node;
                    bytes32 a = current_layer[index].node;
                    bytes32 b = current_layer[index + 1].node;
                    if (a < b) {
                        node.node = _optimizedHash(a, b);
                    } else {
                        node.node = _optimizedHash(b, a);
                    }
                    node.k_index = div_floor(current_layer[index].k_index, 2);
                    next_layer[p] = node;
                    unchecked {
                        p++;
                    }
                }
            }
        }

        // we should have arrived at the root node
        require(next_layer.length == 1);

        return next_layer[0].node;
    }

    function div_floor(uint256 x, uint256 y) internal pure returns (uint256) {
        return x / y;
    }

    function div_ceil(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 result = x / y;
        if (x % y != 0) {
            unchecked {
                result += 1;
            }
        }

        return result;
    }

    /// @notice an internal function to merge two arrays and sort them at the same time.
    /// @dev compares the k-index of each node and sort in increasing order
    /// @param arr1 leftmost index in arr
    /// @param arr2 highest index in arr
    function mergeSort(Node[] memory arr1, Node[] memory arr2) internal pure returns (Node[] memory) {
        // merge the two arrays
        uint256 i = 0;
        uint256 j = 0;
        uint256 k = 0;
        uint256 arr1_length = arr1.length;
        uint256 arr2_length = arr2.length;
        uint256 out_len = arr1_length + arr2_length;
        Node[] memory out = new Node[](out_len);

        while (i < arr1_length && j < arr2_length) {
            if (arr1[i].k_index < arr2[j].k_index) {
                out[k] = arr1[i];
                unchecked {
                    i++;
                    k++;
                }
            } else {
                out[k] = arr2[j];
                unchecked {
                    j++;
                    k++;
                }
            }
        }

        while (i < arr1_length) {
            out[k] = arr1[i];
            unchecked {
                i++;
                k++;
            }
        }

        while (j < arr2_length) {
            out[k] = arr2[j];
            unchecked {
                j++;
                k++;
            }
        }

        return out;
    }

    /// @notice compute the keccak256 hash of two nodes
    /// @param node1 hash of one of the two nodes
    /// @param node2 hash of the other of the two nodes
    function _optimizedHash(bytes32 node1, bytes32 node2) internal pure returns (bytes32 hash) {
        assembly {
            // use EVM scratch space, its memory safe
            mstore(0x0, node1)
            mstore(0x20, node2)
            hash := keccak256(0x0, 0x40)
        }
    }

    /// @notice compute the height of the tree whose total number of leaves is given, it accounts for unbalanced trees.
    /// @param leavesCount number of leaves in the tree
    /// @return height of the tree
    function TreeHeight(uint256 leavesCount) internal pure returns (uint256) {
        uint256 height = Math.log2(leavesCount, Math.Rounding.Up);
        if (!isPowerOfTwo(leavesCount)) {
            unchecked {
                height++;
            }
        }

        return height;
    }

    function isPowerOfTwo(uint256 x) internal pure returns (bool) {
        if (x == 0) {
            return false;
        }

        return (x & (x - 1)) == 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}