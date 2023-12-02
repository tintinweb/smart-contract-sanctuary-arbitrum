// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

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
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

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
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
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
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

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
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IAuction Interface
 *
 * @notice This interface defines the essential functions for an auction contract,
 * facilitating token burning, reward distribution, and cycle management. It provides
 * a standardized way to interact with different auction implementations.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IAuction {

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Enables users to recycle their native rewards and claim other rewards.
     */
    function recycle() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim all their pending rewards.
     */
    function claimAll() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim their pending XNF rewards.
     */
    function claimXNF() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim XNF rewards and locks them in the veXNF contract for a year.
     */
    function claimVeXNF() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim their native rewards.
     */
    function claimNative() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Updates the statistics related to the provided user address.
     */
    function updateStats(address) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to recycle native rewards and claim all other rewards.
     */
    function claimAllAndRecycle() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims all pending rewards for a specific user.
     * @dev This function aggregates all rewards and claims them in a single transaction.
     * It should be invoked by the veXNF contract before any burn action.
     */
    function claimAllForUser(address) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims the accumulated veXNF rewards for a specific user.
     * @dev This function mints and transfers the veXNF tokens to the user.
     * It should be invoked by the veXNF contract.
     */
    function claimVeXNFForUser(address) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns specified batches of vXEN or YSL tokens to earn rewards.
     */
    function burn(bool, uint256) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the current cycle number of the auction.
     * @dev A cycle represents a specific duration or round in the auction process.
     * @return The current cycle number.
     */
    function currentCycle() external returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Updates and retrieves the current cycle number of the auction.
     * @dev A cycle represents a specific duration or round in the auction process.
     * @return The current cycle number.
     */
    function calculateCycle() external returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the number of the last active cycle.
     * @dev Useful for determining the most recent cycle with recorded activity.
     * @return The number of the last active cycle.
     */
    function lastActiveCycle() external returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Registers the caller as a burner by paying in native tokens.
     */
    function participateWithNative(uint256) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the current cycle number based on the time elapsed since the contract's initialization.
     * @return The current cycle number.
     */
    function getCurrentCycle() external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the pending native token rewards for a user based on their NFT ownership and recycling activities.
     * @return The amount of pending native token rewards.
     */
    function pendingNative(address) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Determines the burn and native fee for a given number of batches, adjusting for the time within the current cycle.
     * @return The calculated burn and native fee.
     */
    function coefficientWrapper(uint256) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the reward amount for a given cycle, adjusting for halving events.
     * @return The calculated reward amount.
     */
    function calculateRewardPerCycle(uint256) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the pending native token rewards for a user for the current cycle based on their NFT ownership and recycling activities.
     * @return The amount of pending native token rewards.
     */
    function pendingNativeForCurrentCycle(address) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the pending XNF rewards for a user across various activities.
     * @return pendingXNFRewards An array containing the pending XNF rewards amounts for different activities.
     */
    function pendingXNF(address _user) external view returns (uint256, uint256, uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Registers the caller as a swap user and earns rewards.
     */
    function registerSwapUser(bytes calldata, address, uint256, address) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the pending XNF rewards for a user for the current cycle across various activities.
     * @return pendingXNFRewards An array containing the pending XNF rewards amounts for different activities.
     */
    function pendingXNFForCurrentCycle(address _user) external view returns (uint256, uint256, uint256);

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IBurnRedeemable Interface
 *
 * @notice This interface defines the methods related to redeemable tokens that can be burned.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IBurnRedeemable {

    /// -------------------------------------- EVENTS --------------------------------------- \\\

    /**
     * @notice Emitted when a user redeems tokens.
     * @dev This event emits the details about the redemption process.
     * @param user The address of the user who performed the redemption.
     * @param xenContract The address of the XEN contract involved in the redemption.
     * @param tokenContract The address of the token contract involved in the redemption.
     * @param xenAmount The amount of XEN redeemed by the user.
     * @param tokenAmount The amount of tokens redeemed by the user.
     */
    event Redeemed(
        address indexed user,
        address indexed xenContract,
        address indexed tokenContract,
        uint256 xenAmount,
        uint256 tokenAmount
    );

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Called when a token is burned by a user.
     * @dev Handles any logic related to token burning for redeemable tokens.
     * Implementations should be cautious of reentrancy attacks.
     * @param user The address of the user who burned the token.
     * @param amount The amount of the token burned.
     */
    function onTokenBurned(
        address user,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IWormholeReceiver Interface
 *
 * @notice Interface for a contract which can receive Wormhole messages.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IWormholeReceiver {

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Called by the WormholeRelayer contract to deliver a Wormhole message to this contract.
     *
     * @dev This function should be implemented to include access controls to ensure that only
     *      the Wormhole Relayer contract can invoke it.
     *
     *      Implementations should:
     *      - Maintain a mapping of received `deliveryHash`s to prevent duplicate message delivery.
     *      - Verify the authenticity of `sourceChain` and `sourceAddress` to prevent unauthorized or malicious calls.
     *
     * @param payload The arbitrary data included in the message by the sender.
     * @param additionalVaas Additional VAAs that were requested to be included in this delivery.
     *                       Guaranteed to be in the same order as specified by the sender.
     * @param sourceAddress The Wormhole-formatted address of the message sender on the originating chain.
     * @param sourceChain The Wormhole Chain ID of the originating blockchain.
     * @param deliveryHash The VAA hash of the deliveryVAA, used to prevent duplicate delivery.
     *
     * Warning: The provided VAAs are NOT verified by the Wormhole core contract prior to this call.
     *          Always invoke `parseAndVerify()` on the Wormhole core contract to validate the VAAs before trusting them.
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

import {ILayerZeroReceiver} from "@layerzerolabs/lz-evm-sdk-v1-0.7/contracts/interfaces/ILayerZeroReceiver.sol";
import {IWormholeReceiver} from "./IWormholeReceiver.sol";

/*
 * @title XNF interface
 *
 * @notice This is an interface outlining functiosn for XNF token with enhanced features such as token locking and specialized minting
 * and burning mechanisms. It's primarily used within a broader protocol to reward users who burn YSL or vXEN.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IXNF
{
    /// -------------------------------------- ERRORS --------------------------------------- \\\

    /**
     * @notice This error is thrown when minting XNF to zero address.
     */
    error ZeroAddress();

    /**
     * @notice This error is thrown when trying to claim airdroped XNF before 2 hours passed.
     */
    error TooEarlyToClaim();

    /**
     * @notice Error thrown when minting would exceed the maximum allowed supply.
     */
    error ExceedsMaxSupply();

    /**
     * @notice This error is thrown when an invalid claim proof is provided.
     */
    error InvalidClaimProof();

    /**
     * @notice Error thrown when a function is called by an account other than the Auction contract.
     */
    error OnlyAuctionAllowed();

    /**
     * @notice This error is thrown when user tries to purchase XNF from protocol owned liquidity.
     */
    error CantPurchaseFromPOL();

    /**
     * @notice This error is thrown when user tries to sell XNF directly.
     */
    error CanSellOnlyViaRecycle();

    /**
     * @notice Error thrown when the calling contract does not support the required interface.
     */
    error UnsupportedInterface();

    /**
     * @notice This error is thrown when an airdrop has already been claimed.
     */
    error AirdropAlreadyClaimed();

    /**
     * @notice Error thrown when a user tries to transfer more unlocked tokens than they have.
     */
    error InsufficientUnlockedTokens();

    /**
     * @notice Error thrown when the contract is already initialised.
     */
    error ContractInitialised(address auction);

    /// ------------------------------------- STRUCTURES ------------------------------------ \\\

    /**
     * @notice Represents token lock details for a user.
     * @param amount Total tokens locked.
     * @param timestamp When the tokens were locked.
     * @param dailyUnlockAmount Tokens unlocked daily.
     * @param usedAmount Tokens transferred from the locked amount.
     */
    struct Lock {
        uint256 amount;
        uint256 timestamp;
        uint128 dailyUnlockAmount;
        uint128 usedAmount;
    }

    /// -------------------------------------- EVENTS --------------------------------------- \\\

    /**
     * @notice Emitted when a user successfully claims their airdrop.
     * @param user Address of the user claiming the airdrop.
     * @param amount Amount of Airdrop claimed.
     */
    event Airdropped(
        address indexed user,
        uint256 amount
    );

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Allows users to claim their airdropped tokens using a Merkle proof.
     * @dev Verifies the Merkle proof against the stored Merkle root and mints the claimed amount to the user.
     * @param proof Array of bytes32 values representing the Merkle proof.
     * @param account Address of the user claiming the airdrop.
     * @param amount Amount of tokens being claimed.
     */
    function claim(
        bytes32[] calldata proof,
        address account,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Mints XNF tokens to a specified account.
     * @dev Only the Auction contract can mint tokens, and the total supply cap is checked before minting.
     * @param account Address receiving the minted tokens.
     * @param amount Number of tokens to mint.
     */
    function mint(
        address account,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Sets the liquidity pool (LP) address.
     * @dev Only the Auction contract is allowed to call this function.
     * @param _lp The address of the liquidity pool to be set.
     */
    function setLPAddress(address _lp) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns a specified amount of tokens from a user's account.
     * @dev The calling contract must support the IBurnRedeemable interface.
     * @param user Address from which tokens will be burned.
     * @param amount Number of tokens to burn.
     */
    function burn(
        address user,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Determines the number of days since a user's tokens were locked.
     * @dev If the elapsed days exceed the lock period, it returns the lock period.
     * @param _user Address of the user to check.
     * @return passedDays Number of days since the user's tokens were locked, capped at the lock period.
     */
    function daysPassed(address _user) external view returns (uint256 passedDays);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the amount of unlocked tokens for a user based on the elapsed time since locking.
     * @dev If the user's tokens have been locked for the full lock period, all tokens are considered unlocked.
     * @param _user Address of the user to check.
     * @return unlockedTokens Number of tokens that are currently unlocked for the user.
     */
    function getUnlockedTokensAmount(address _user) external view returns (uint256 unlockedTokens);

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IBurnRedeemable} from "./interfaces/IBurnRedeemable.sol";
import {IAuction} from "./interfaces/IAuction.sol";
import {IXNF} from "./interfaces/IXNF.sol";

/*
 * @title XNF Contract
 *
 * @notice XNF is an ERC20 token with enhanced features such as token locking and specialized minting
 * and burning mechanisms. It's primarily used within a broader protocol to reward users who burn YSL or vXEN.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
contract XNF is
    IXNF,
    ERC20
{

    /// ------------------------------------ VARIABLES ------------------------------------- \\\

    /**
     * @notice Address of the Auction contract, set during deployment and cannot be changed.
     */
    address public Auction;

    /**
     * @notice Address of the Recycle contract, set during deployment and cannot be changed.
     */
    address public Recycle;

    /**
     * @notice Address of the protocol owned liquidity pool contract, set after initialising the pool and cannot be changed.
     */
    address public lpAddress;

    /**
     * @notice Root of the Merkle tree used for airdrop claims.
     */
    bytes32 public merkleRoot;

    /**
     * @notice Duration (in days) for which tokens are locked. Set to 730 days (2 years).
     */
    uint256 public lockPeriod;

    /**
     * @notice Timestamp when the contract was initialised, set during deployment and cannot be changed.
     */
    uint256 public i_timestamp;

    /// ------------------------------------ MAPPINGS --------------------------------------- \\\

    /**
     * @notice Keeps track of token lock details for each user.
     */
    mapping (address => Lock) public userLocks;

    /**
     * @notice Records the total number of tokens burned by each user.
     */
    mapping (address => uint256) public userBurns;

    /**
     * @notice Mapping to track if a user has claimed their airdrop.
     */
    mapping (bytes32 => bool) public airdropClaimed;

    /// ------------------------------------ CONSTRUCTOR ------------------------------------ \\\

    /**
     * @notice Initialises the XNF token with a specified storage contract address, sets the token's name and symbol.
     */
    constructor()
        payable
        ERC20("XNF", "XNF")
    {}

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Initialises the contract with Auction contract's address and merkleRoot.
     * @dev Fails if the contract has already been initialised i.e., address of Auction is zero.
     * @param _auction Address of the Auction contract.
     * @param _merkleRoot Hashed Root of Merkle Tree for Airdrop.
     */
    function initialise(
        address _auction,
        address _recycle,
        bytes32 _merkleRoot
    ) external {
        if (Auction != address(0))
            revert ContractInitialised(Auction);
        lockPeriod = 730;
        Auction = _auction;
        Recycle = _recycle;
        merkleRoot = _merkleRoot;
        i_timestamp = block.timestamp;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Sets the liquidity pool (LP) address.
     * @dev Only the Auction contract is allowed to call this function.
     * @param _lp The address of the liquidity pool to be set.
     */
    function setLPAddress(address _lp)
        external
        override
    {
        if (msg.sender != Auction) {
            revert OnlyAuctionAllowed();
        }
        lpAddress = _lp;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows users to claim their airdropped tokens using a Merkle proof.
     * @dev Verifies the Merkle proof against the stored Merkle root and mints the claimed amount to the user.
     * @param proof Array of bytes32 values representing the Merkle proof.
     * @param account Address of the user claiming the airdrop.
     * @param amount Amount of tokens being claimed.
     */
    function claim(
        bytes32[] calldata proof,
        address account,
        uint256 amount
    )
        external
        override
    {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) {
            revert InvalidClaimProof();
        }
        if (airdropClaimed[leaf]) {
            revert AirdropAlreadyClaimed();
        }
        if (i_timestamp + 2 hours > block.timestamp ) {
            revert TooEarlyToClaim();
        }
        airdropClaimed[leaf] = true;
        _mint(account, amount);
        unchecked {
            userLocks[account] = Lock(
                amount,
                block.timestamp,
                uint128((amount * 1e18) / lockPeriod),
                0
            );
        }
        emit Airdropped(account, amount);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Mints XNF tokens to a specified account.
     * @dev Only the Auction contract can mint tokens, and the total supply cap is checked before minting.
     * @param account Address receiving the minted tokens.
     * @param amount Number of tokens to mint.
     */
    function mint(
        address account,
        uint256 amount
    )
        external
        override
    {
        if (account == address(0)) {
            revert ZeroAddress();
        }
        if (msg.sender != Auction) {
            revert OnlyAuctionAllowed();
        }
        if (totalSupply() + amount >= 22_600_000 ether) {
            revert ExceedsMaxSupply();
        }
        _mint(account, amount);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns a specified amount of tokens from a user's account.
     * @dev The calling contract must support the IBurnRedeemable interface.
     * @param user Address from which tokens will be burned.
     * @param amount Number of tokens to burn.
     */
    function burn(
        address user,
        uint256 amount
    )
        external
        override
    {
        if (!IERC165(msg.sender).supportsInterface(type(IBurnRedeemable).interfaceId)) {
            revert UnsupportedInterface();
        }
        if (msg.sender != user) {
            _spendAllowance(user, msg.sender, amount);
        }
        _burn(user, amount);
        unchecked{
            userBurns[user] += amount;
        }
        IBurnRedeemable(msg.sender).onTokenBurned(user, amount);
    }

    /// --------------------------------- PUBLIC FUNCTIONS ---------------------------------- \\\

    /**
     * @notice Determines the number of days since a user's tokens were locked.
     * @dev If the elapsed days exceed the lock period, it returns the lock period.
     * @param _user Address of the user to check.
     * @return passedDays Number of days since the user's tokens were locked, capped at the lock period.
     */
    function daysPassed(address _user)
        public
        override
        view
        returns (uint256 passedDays)
    {
        passedDays = (block.timestamp - userLocks[_user].timestamp) / 1 days;
        if (passedDays > lockPeriod) {
            passedDays = lockPeriod;
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the amount of unlocked tokens for a user based on the elapsed time since locking.
     * @dev If the user's tokens have been locked for the full lock period, all tokens are considered unlocked.
     * @param _user Address of the user to check.
     * @return unlockedTokens Number of tokens that are currently unlocked for the user.
     */
    function getUnlockedTokensAmount(address _user)
        public
        override
        view
        returns (uint256 unlockedTokens)
    {
        uint256 passedDays = daysPassed(_user);
        Lock storage lock = userLocks[_user];
        if (userLocks[_user].timestamp != 0) {
            if (passedDays >= lockPeriod) {
                unlockedTokens = lock.amount;
            } else {
                unchecked {
                    unlockedTokens = (passedDays * lock.dailyUnlockAmount) / 1e18;
                }
            }
        }
    }

    /// -------------------------------- INTERNAL FUNCTIONS --------------------------------- \\\

    /**
     * @notice Manages token transfers, ensuring that locked tokens are not transferred.
     * @dev This hook is invoked before any token transfer. It checks the locking conditions and updates lock details.
     * @param from Address sending the tokens.
     * @param amount Number of tokens being transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override
    {
        if (userLocks[from].timestamp != 0) {
            Lock storage lock = userLocks[from];
            uint256 passedDays = daysPassed(from);
            uint256 unlockedTokens = getUnlockedTokensAmount(from);
            uint256 userBalance = balanceOf(from);
            if (passedDays >= lockPeriod) {
                lock.timestamp = 0;
            }
            if (amount > userBalance - (lock.amount - unlockedTokens)) {
                revert InsufficientUnlockedTokens();
            }
            uint256 userUsedAmount = userLocks[from].usedAmount;
            unchecked {
                uint256 notLockedTokens = userBalance + userUsedAmount - userLocks[from].amount;
                if (amount > notLockedTokens) {
                    userLocks[from].usedAmount = uint128(userUsedAmount + amount - notLockedTokens);
                }
            }
        }
        if (lpAddress != address(0) && from == lpAddress && to != Recycle) {
            revert CantPurchaseFromPOL();
        }
        if (lpAddress != address(0) && to == lpAddress && from != Recycle && from != Auction) {
            revert CanSellOnlyViaRecycle();
        }
    }

    /// ------------------------------------------------------------------------------------- \\\
}