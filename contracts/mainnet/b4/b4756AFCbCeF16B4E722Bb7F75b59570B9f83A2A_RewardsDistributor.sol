// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
pragma solidity ^0.8.19;

interface IMinter {
    function active_period() external view returns (uint256);

    function _token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISolidlyV3PoolMinimal {
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVoter {
    function isOperator(address addr) external view returns (bool);
    function isWhitelisted(address addr) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "../ProxyPattern/SolidlyImplementation.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {IMinter} from "../interfaces/IMinter.sol";
import {IVoter} from "../interfaces/IVoter.sol";
import {ISolidlyV3PoolMinimal} from "../interfaces/ISolidlyV3PoolMinimal.sol";
import {Status} from "./Status.sol";

error AlreadyClaimed();
error BufferPeriod();
error Paused();
error InvalidIncentiveAmount();
error InvalidIncentiveDistributionPeriod();
error PoolNotWhitelisted();
error InvalidProof();
error NotClaimsPauser();
error NotOwner();
error NotOperator();
error NotVoter();
error NotRootSetter();
error RootCandidatesInvalid();
error IncorrectCollateralAmount();
error FailedToReturnCollateral();

struct Root {
    bytes32 value;
    uint256 lastUpdatedAt;
}

struct Claim {
    uint256 amount;
    uint256 timestamp;
}

enum RewardType {
    STORED,
    EARNED
}

enum StoredRewardType {
    LP_SOLID_EMISSIONS,
    LP_TOKEN_INCENTIVE,
    POOL_FEES,
    VOTE_INCENTIVE
}

struct StoredReward {
    StoredRewardType _type;
    address pool;
    address token;
}

enum EarnedRewardType {
    LP_POOL_FEES,
    LP_SOLID_EMISSIONS,
    LP_TOKEN_INCENTIVE,
    PROTOCOL_POOL_FEES,
    VOTER_POOL_FEES,
    VOTER_VOTE_INCENTIVE
}

struct EarnedReward {
    EarnedRewardType _type;
    address pool;
    address token;
}

contract RewardsDistributor is SolidlyImplementation {
    using Status for mapping(address => uint256);
    using SafeERC20 for IERC20;

    uint256 private constant EPOCH_DURATION = 1 weeks;
    bytes32 private constant ZERO_ROOT = bytes32(0);
    address public solidlyMinter;
    address public solidlyVoter;
    address public solidlyToken;
    address public owner;
    Root public root;
    mapping(address admin => uint256 status) public isRootAdmin; //Admin function active for emergencies - multisig
    mapping(address pauser => uint256 status) public isClaimsPauser;
    mapping(address token => uint256 amount) public approvedIncentiveAmounts;
    uint256 public claimDelay;
    uint256 public activePeriod;
    uint256 public maxIncentivePeriods;

    mapping(address earner => mapping(bytes32 rewardKey => Claim claim))
        public claims;
    mapping(uint256 period => mapping(bytes32 rewardKey => uint256 rewardAmount))
        public periodRewards;

    uint80 public lastUpdateBlock;
    uint80 public nextUpdateBlock;
    uint64 public lastUpdateTime;
    uint24 public targetTime;
    bool public paused;

    uint256 public collateralAmount;
    
    mapping(address setter => uint256 status) public isRootSetterA;
    mapping(address setter => uint256 status) public isRootSetterB;

    Root public rootCandidateA;
    Root public rootCandidateB;

    event OwnerChanged(address newOwner);
    event ClaimDelayChanged(uint256 newClaimDelay);
    event TargetTimeChanged(uint80 targetTime);
    event MaxIncentivePeriodsChanged(uint256 newMaxIncentivePeriods);
    event RootChanged(address setter, bytes32 newRoot);
    event RootCandidateAChanged(address setter, bytes32 newRoot);
    event RootCandidateBChanged(address setter, bytes32 newRoot);
    event RootAdminStatusToggled(address setter, uint256 newStatus);
    event RootSetterAStatusToggled(address setter, uint256 newStatus);
    event RootSetterBStatusToggled(address setter, uint256 newStatus);
    event ClaimsPaused(address pauser);
    event ClaimsUnpaused(address unpauser);
    event ClaimsPauserStatusToggled(address pauser, uint256 newStatus);
    event CollateralDeposited(address depositor, uint256 amount);
    event CollateralWithdrawn(address depositor, uint256 amount);
    event CollateralAmountChanged(uint256 amount);
    event PoolFeesCollected(address pool, uint256 amount0, uint256 amount1);
    event ApprovedIncentiveAmountsChanged(address token, uint256 newAmount);
    event LPSolidEmissionsDeposited(
        address pool,
        uint256 amount,
        uint256 period
    );
    event LPTokenIncentiveDeposited(
        address depositor,
        address pool,
        address token,
        uint256 amount,
        uint256 periodReceived,
        uint256 distributionStart,
        uint256 distributionEnd
    );
    event VoteIncentiveDeposited(
        address depositor,
        address pool,
        address token,
        uint256 amount,
        uint256 periodReceived,
        uint256 distributionStart,
        uint256 distributionEnd
    );
    event RewardStored(
        uint256 periodReceived,
        StoredRewardType _type,
        address pool,
        address token,
        uint256 amount
    );
    event RewardClaimed(
        address earner,
        EarnedRewardType _type,
        address pool,
        address token,
        uint256 amount
    );

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier WhenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    function initialize(
        address _solidlyMinter,
        address _solidlyVoter
    ) external onlyGovernance notInitialized {
        owner = msg.sender;
        solidlyMinter = _solidlyMinter;
        solidlyVoter = _solidlyVoter;
        solidlyToken = IMinter(solidlyMinter)._token();
        activePeriod = IMinter(solidlyMinter).active_period();
        claimDelay = 1 hours;
        maxIncentivePeriods = 4;
        lastUpdateBlock = uint80(block.number);
        nextUpdateBlock = uint80(block.number) + 42300;
        lastUpdateTime = uint64(block.timestamp);
        targetTime = 84600;
    }

    struct MultiProof {
        bytes32[] path;
        bool[] flags;
    }

    struct ClaimParams {
        address[] earners;
        EarnedRewardType[] types;
        address[] pools;
        address[] tokens;
        uint256[] amounts;
        MultiProof proof;
    }

    function claimAll(ClaimParams calldata params) external WhenNotPaused {
        if (block.timestamp < root.lastUpdatedAt + claimDelay)
            revert BufferPeriod();
        uint256 numClaims = params.earners.length;

        // verify claim against merkle root
        _verifyProof(params);

        // iterate over each token to be claimed
        for (uint256 i; i < numClaims; ) {
            _claimSingle(
                params.earners[i],
                params.types[i],
                params.pools[i],
                params.tokens[i],
                params.amounts[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    function _claimSingle(
        address earner,
        EarnedRewardType _type,
        address pool,
        address token,
        uint256 amount
    ) private {
        // get already claimed amounts
        bytes32 rewardKey = getRewardKey(
            RewardType.EARNED,
            uint8(_type),
            pool,
            token
        );
        uint256 previouslyClaimed = claims[earner][rewardKey].amount;

        // calc owed amounts (delta vs already claimed)
        uint256 amountDelta = amount - previouslyClaimed;
        if (amountDelta == 0) revert AlreadyClaimed();

        // replace old claimed amount w/ new amount
        claims[earner][rewardKey] = Claim(amount, block.timestamp);

        // check if this contract has enough tokens to satisfy the claim
        // only relevant for claims on pool fees, for which this contract cannot receive the funds in advance
        if (
            (_type == EarnedRewardType.LP_POOL_FEES ||
                _type == EarnedRewardType.PROTOCOL_POOL_FEES ||
                _type == EarnedRewardType.VOTER_POOL_FEES) &&
            _balance(token) < amountDelta
        ) {
            _collectPoolFees(pool);
        }

        // send tokens and emit claimed event
        IERC20(token).safeTransfer(earner, amountDelta);
        emit RewardClaimed(earner, _type, pool, token, amount);
    }

    function _verifyProof(ClaimParams calldata params) private view {
        bytes32[] memory leaves = _generateLeaves(
            params.earners,
            params.types,
            params.pools,
            params.tokens,
            params.amounts
        );
        if (
            !MerkleProof.multiProofVerify(
                params.proof.path,
                params.proof.flags,
                root.value,
                leaves
            )
        ) revert InvalidProof();
    }

    function _generateLeaves(
        address[] calldata earners,
        EarnedRewardType[] calldata types,
        address[] calldata pools,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) private pure returns (bytes32[] memory) {
        uint256 numLeaves = earners.length;
        bytes32[] memory leaves = new bytes32[](numLeaves);
        for (uint256 i; i < numLeaves; ) {
            bytes32 leaf = keccak256(
                bytes.concat(
                    keccak256(
                        abi.encode(
                            earners[i],
                            types[i],
                            pools[i],
                            tokens[i],
                            amounts[i]
                        )
                    )
                )
            );
            leaves[i] = leaf;
            unchecked {
                ++i;
            }
        }
        return leaves;
    }

    function depositLPSolidEmissions(address pool, uint256 amount) external {
        if (msg.sender != solidlyVoter) revert NotVoter();
        StoredReward memory reward = StoredReward({
            _type: StoredRewardType.LP_SOLID_EMISSIONS,
            pool: pool,
            token: solidlyToken
        });
        uint256 _activePeriod = _syncActivePeriod();
        IERC20(solidlyToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        _storeReward(_activePeriod, reward, amount);

        emit LPSolidEmissionsDeposited(pool, amount, _activePeriod);
    }

    function depositLPTokenIncentive(
        address pool,
        address token,
        uint256 amount,
        uint256 distributionStart,
        uint256 numDistributionPeriods
    ) external {
        _validateIncentive(
            token,
            amount,
            distributionStart,
            numDistributionPeriods
        );

        StoredReward memory reward = StoredReward({
            _type: StoredRewardType.LP_TOKEN_INCENTIVE,
            pool: pool,
            token: token
        });
        uint256 periodReceived = _syncActivePeriod();
        uint256 balanceBefore = _balance(token);
        IERC20(reward.token).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        amount = _balance(token) - balanceBefore;
        _storeReward(periodReceived, reward, amount);

        emit LPTokenIncentiveDeposited(
            msg.sender,
            pool,
            token,
            amount,
            periodReceived,
            distributionStart,
            distributionStart + (EPOCH_DURATION * numDistributionPeriods)
        );
    }

    function depositVoteIncentive(
        address pool,
        address token,
        uint256 amount,
        uint256 distributionStart,
        uint256 numDistributionPeriods
    ) external {
        if (!IVoter(solidlyVoter).isWhitelisted(pool))
            revert PoolNotWhitelisted();
        _validateIncentive(
            token,
            amount,
            distributionStart,
            numDistributionPeriods
        );
        uint256 balanceBefore = _balance(token);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        StoredReward memory reward = StoredReward({
            _type: StoredRewardType.VOTE_INCENTIVE,
            pool: pool,
            token: token
        });
        uint256 periodReceived = _syncActivePeriod();
        amount = _balance(token) - balanceBefore;
        _storeReward(periodReceived, reward, amount);

        emit VoteIncentiveDeposited(
            msg.sender,
            pool,
            token,
            amount,
            periodReceived,
            distributionStart,
            distributionStart + (EPOCH_DURATION * numDistributionPeriods)
        );
    }

    function _storeReward(
        uint256 period,
        StoredReward memory reward,
        uint256 amount
    ) private {
        bytes32 rewardKey = getRewardKey(
            RewardType.STORED,
            uint8(reward._type),
            reward.pool,
            reward.token
        );
        periodRewards[period][rewardKey] += amount;
        emit RewardStored(
            period,
            reward._type,
            reward.pool,
            reward.token,
            amount
        );
    }

    function _validateIncentive(
        address token,
        uint256 amount,
        uint256 distributionStart,
        uint256 numDistributionPeriods
    ) private view {
        // distribution must start on future epoch flip and last for [1, max] periods
        if (
            numDistributionPeriods == 0 ||
            numDistributionPeriods > maxIncentivePeriods ||
            distributionStart % EPOCH_DURATION != 0 ||
            distributionStart < block.timestamp
        ) revert InvalidIncentiveDistributionPeriod();

        uint256 minAmount = approvedIncentiveAmounts[token] *
            numDistributionPeriods;
        if (minAmount == 0 || amount < minAmount)
            revert InvalidIncentiveAmount();
    }

    function collectPoolFees(
        address pool
    ) external returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _collectPoolFees(pool);
    }

    // pulls trading fees from pools and stores amounts in periodRewards
    function _collectPoolFees(
        address pool
    ) private returns (uint256 amount0, uint256 amount1) {
        (uint128 amount0As128, uint128 amount1As128) = ISolidlyV3PoolMinimal(
            pool
        ).collectProtocol(address(this), type(uint128).max, type(uint128).max);
        (amount0, amount1) = (uint256(amount0As128), uint256(amount1As128));
        uint256 _activePeriod = _syncActivePeriod();
        if (amount0 > 0) {
            StoredReward memory r0 = StoredReward({
                _type: StoredRewardType.POOL_FEES,
                pool: pool,
                token: ISolidlyV3PoolMinimal(pool).token0()
            });
            _storeReward(_activePeriod, r0, amount0);
        }
        if (amount1 > 0) {
            StoredReward memory r1 = StoredReward({
                _type: StoredRewardType.POOL_FEES,
                pool: pool,
                token: ISolidlyV3PoolMinimal(pool).token1()
            });
            _storeReward(_activePeriod, r1, amount1);
        }

        emit PoolFeesCollected(pool, amount0, amount1);
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit OwnerChanged(_owner);
    }

    function toggleRootAdminStatus(address addr) external onlyOwner {
        uint256 newStatus = isRootAdmin.toggle(addr);
        emit RootAdminStatusToggled(addr, newStatus);
    }

    function toggleRootSetterAStatus(address addr) external onlyOwner {
        uint256 newStatus = isRootSetterA.toggle(addr);
        emit RootSetterAStatusToggled(addr, newStatus);
    }

    function toggleRootSetterBStatus(address addr) external onlyOwner {
        uint256 newStatus = isRootSetterB.toggle(addr);
        emit RootSetterBStatusToggled(addr, newStatus);
    }

    function _setNextUpdateBlock() private {
        uint80 currentBlock = uint80(block.number);
        uint64 currentTime = uint64(block.timestamp);
        
        uint80 lastBlock = lastUpdateBlock;
        uint64 lastUpdate = lastUpdateTime;

        uint64 timePassed = currentTime - lastUpdate;
        uint80 blocksPassed = currentBlock - lastBlock;
        uint80 targetBlocks = blocksPassed * targetTime / timePassed;

        nextUpdateBlock = currentBlock + targetBlocks;
        lastUpdateBlock = currentBlock;
        lastUpdateTime = currentTime;
    }

    function setRoot(bytes32 _root) external {
        if (isRootAdmin[msg.sender] == 0) revert NotRootSetter();
        _setNextUpdateBlock();
        root = Root({value: _root, lastUpdatedAt: block.timestamp});
        rootCandidateA = Root({value: ZERO_ROOT, lastUpdatedAt: block.timestamp});
        rootCandidateB = Root({value: ZERO_ROOT, lastUpdatedAt: block.timestamp});
        emit RootCandidateAChanged(msg.sender, ZERO_ROOT);
        emit RootCandidateBChanged(msg.sender, ZERO_ROOT);
        emit RootChanged(msg.sender, _root);
    }

    function setRootCandidateA(bytes32 _root) external WhenNotPaused {
        if (isRootSetterA[msg.sender] == 0) revert NotRootSetter();
        rootCandidateA = Root({value: _root, lastUpdatedAt: block.timestamp});
        emit RootCandidateAChanged(msg.sender, _root);
    }

    function setRootCandidateB(bytes32 _root) external WhenNotPaused {
        if (isRootSetterB[msg.sender] == 0) revert NotRootSetter();
        rootCandidateB = Root({value: _root, lastUpdatedAt: block.timestamp});
        emit RootCandidateBChanged(msg.sender, _root);
    }

    function triggerRoot() external {
        bytes32 rootCandidateAValue = rootCandidateA.value;
        if (rootCandidateAValue != rootCandidateB.value || rootCandidateAValue == ZERO_ROOT) revert RootCandidatesInvalid();
        _setNextUpdateBlock();
        root = Root({value: rootCandidateAValue, lastUpdatedAt: block.timestamp});
        rootCandidateA = Root({value: ZERO_ROOT, lastUpdatedAt: block.timestamp});
        rootCandidateB = Root({value: ZERO_ROOT, lastUpdatedAt: block.timestamp});
        emit RootCandidateAChanged(msg.sender, ZERO_ROOT);
        emit RootCandidateBChanged(msg.sender, ZERO_ROOT);
        emit RootChanged(msg.sender, rootCandidateAValue);
    }

    function setCollateralAmount(uint256 _collateralAmount) external onlyOwner {
        collateralAmount = _collateralAmount;
        emit CollateralAmountChanged(_collateralAmount);
    }

    function setClaimDelay(uint256 newClaimDelay) external onlyOwner {
        claimDelay = newClaimDelay;
        emit ClaimDelayChanged(newClaimDelay);
    }

    function setTargetTime(uint24 _targetTime) external {
        if (isRootAdmin[msg.sender] == 0) revert NotRootSetter();
        targetTime = _targetTime;
        emit TargetTimeChanged(_targetTime);
    }

    function setUpdateInterval(uint80 _lastBlock, uint80 _nextBlock, uint64 _lastUpdate) external {
        if (isRootAdmin[msg.sender] == 0) revert NotRootSetter();
        lastUpdateBlock = _lastBlock;
        nextUpdateBlock = _nextBlock;
        lastUpdateTime = _lastUpdate;
    }

    function setMaxIncentivePeriods(
        uint256 newMaxIncentivePeriods
    ) external onlyOwner {
        maxIncentivePeriods = newMaxIncentivePeriods;
        emit MaxIncentivePeriodsChanged(newMaxIncentivePeriods);
    }

    function updateApprovedIncentiveAmounts(
        address token,
        uint256 amount
    ) external {
        if (!IVoter(solidlyVoter).isOperator(msg.sender)) revert NotOperator();
        approvedIncentiveAmounts[token] = amount;
        emit ApprovedIncentiveAmountsChanged(token, amount);
    }

    function toggleClaimsPauserStatus(address addr) external onlyOwner {
        uint256 newStatus = isClaimsPauser.toggle(addr);
        emit ClaimsPauserStatusToggled(addr, newStatus);
    }

    function pauseClaimsGovernance() external WhenNotPaused {
        if (isClaimsPauser[msg.sender] == 0) revert NotClaimsPauser();
        paused = true;
        emit ClaimsPaused(msg.sender);
    }

    function pauseClaimsPublic() external payable WhenNotPaused {
        if (msg.value != collateralAmount) revert IncorrectCollateralAmount();
        paused = true;
        emit CollateralDeposited(msg.sender, msg.value);
        emit ClaimsPaused(msg.sender);
    }

    function unpauseClaimsGovernance() external {
        if (isClaimsPauser[msg.sender] == 0) revert NotClaimsPauser();
        paused = false;
        emit ClaimsUnpaused(msg.sender);
    }

    function withdrawCollateral(address payable _to, uint256 _amount) external {
        if (isClaimsPauser[msg.sender] == 0) revert NotClaimsPauser();
        bool sent;
        assembly {
        sent := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        if(!sent) revert FailedToReturnCollateral();
        emit CollateralWithdrawn(_to, _amount);
    }

    function getRewardKey(
        RewardType _type,
        uint8 subtype,
        address pool,
        address token
    ) public pure returns (bytes32 key) {
        key = keccak256(abi.encodePacked(_type, subtype, pool, token));
    }

    function _syncActivePeriod() private returns (uint256 _activePeriod) {
        _activePeriod = activePeriod;
        if (block.timestamp >= _activePeriod + EPOCH_DURATION) {
            uint256 _minterActivePeriod = IMinter(solidlyMinter)
                .active_period();
            if (_activePeriod != _minterActivePeriod) {
                _activePeriod = _minterActivePeriod;
                activePeriod = _activePeriod;
            }
        }
    }

    /// @dev Get this contract's balance of a pool fee token
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    function _balance(address token) private view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Status
/// @notice Contains functions for managing address statuses
library Status {
    /// @notice toggles the status val of an address from 0 to 1 or 1 to 0
    /// @param self The calling contract's storage mapping containing address statuses
    /// @param addr The address that will have its status flipped
    /// @return newStatus The new status of the address (0 or 1)
    function toggle(
        mapping(address => uint256) storage self,
        address addr
    ) internal returns (uint256 newStatus) {
        unchecked {
            newStatus = 1 - self[addr];
            self[addr] = newStatus;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/**
 * @title Solidly Implementation
 * @author Solidly Labs
 * @notice Governable implementation that relies on governance slot to be set by the proxy
 */
contract SolidlyImplementation {
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev U4sed by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
            sstore(INITIALIZED_SLOT, 1)
        }
        _;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }
}