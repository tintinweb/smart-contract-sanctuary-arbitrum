// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Common {
    /**
     * @param identifier  bytes32  Identifier of the distribution
     * @param token       address  Address of the token to distribute
     * @param merkleRoot  bytes32  Merkle root of the distribution
     * @param proof       bytes32  Proof of the distribution
     */
    struct Distribution {
        bytes32 identifier;
        address token;
        bytes32 merkleRoot;
        bytes32 proof;
    }

    /**
     * @param proposal          bytes32  Proposal to bribe
     * @param token             address  Token to bribe with
     * @param briber            address  Address of the briber
     * @param amount            uint256  Amount of tokens to bribe with
     * @param maxTokensPerVote  uint256  Maximum amount of tokens to use per vote
     * @param periods           uint256  Number of periods to bribe for
     * @param periodDuration    uint256  Duration of each period
     * @param proposalDeadline  uint256  Deadline for the proposal
     * @param permitDeadline    uint256  Deadline for the permit2 signature
     * @param signature         bytes    Permit2 signature
     */
    struct DepositBribeParams {
        bytes32 proposal;
        address token;
        address briber;
        uint256 amount;
        uint256 maxTokensPerVote;
        uint256 periods;
        uint256 periodDuration;
        uint256 proposalDeadline;
        uint256 permitDeadline;
        bytes signature;
    }

    /**
     * @param rwIdentifier      bytes32    Identifier for claiming reward
     * @param fromToken         address    Address of token to swap from
     * @param toToken           address    Address of token to swap to
     * @param fromAmount        uint256    Amount of fromToken to swap
     * @param toAmount          uint256    Amount of toToken to receive
     * @param deadline          uint256    Timestamp until which swap may be fulfilled
     * @param callees           address[]  Array of addresses to call (DEX addresses)
     * @param callLengths       uint256[]  Index of the beginning of each call in exchangeData
     * @param values            uint256[]  Array of encoded values for each call in exchangeData
     * @param exchangeData      bytes      Calldata to execute on callees
     * @param rwMerkleProof     bytes32[]  Merkle proof for the reward claim
     */
    struct ClaimAndSwapData {
        bytes32 rwIdentifier;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 deadline;
        address[] callees;
        uint256[] callLengths;
        uint256[] values;
        bytes exchangeData;
        bytes32[] rwMerkleProof;
    }

    /**
     * @param identifier   bytes32    Identifier for claiming reward
     * @param account      address    Address of the account to claim for
     * @param amount       uint256    Amount of tokens to claim
     * @param merkleProof  bytes32[]  Merkle proof for the reward claim
     */
    struct Claim {
        bytes32 identifier;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Errors {
    /**
     * @notice max period 0 or greater than MAX_PERIODS
     */
    error InvalidMaxPeriod();

    /**
     * @notice period duration 0 or greater than MAX_PERIOD_DURATION
     */
    error InvalidPeriodDuration();

    /**
     * @notice address provided is not a contract
     */
    error NotAContract();

    /**
     * @notice not authorized
     */
    error NotAuthorized();

    /**
     * @notice contract already initialized
     */
    error AlreadyInitialized();

    /**
     * @notice address(0)
     */
    error InvalidAddress();

    /**
     * @notice empty bytes identifier
     */
    error InvalidIdentifier();

    /**
     * @notice invalid protocol name
     */
    error InvalidProtocol();

    /**
     * @notice invalid number of choices
     */
    error InvalidChoiceCount();

    /**
     * @notice invalid input amount
     */
    error InvalidAmount();

    /**
     * @notice not team member
     */
    error NotTeamMember();

    /**
     * @notice cannot whitelist BRIBE_VAULT
     */
    error NoWhitelistBribeVault();

    /**
     * @notice token already whitelisted
     */
    error TokenWhitelisted();

    /**
     * @notice token not whitelisted
     */
    error TokenNotWhitelisted();

    /**
     * @notice voter already blacklisted
     */
    error VoterBlacklisted();

    /**
     * @notice voter not blacklisted
     */
    error VoterNotBlacklisted();

    /**
     * @notice deadline has passed
     */
    error DeadlinePassed();

    /**
     * @notice invalid period
     */
    error InvalidPeriod();

    /**
     * @notice invalid deadline
     */
    error InvalidDeadline();

    /**
     * @notice invalid max fee
     */
    error InvalidMaxFee();

    /**
     * @notice invalid fee
     */
    error InvalidFee();

    /**
     * @notice invalid fee recipient
     */
    error InvalidFeeRecipient();

    /**
     * @notice invalid distributor
     */
    error InvalidDistributor();

    /**
     * @notice invalid briber
     */
    error InvalidBriber();

    /**
     * @notice address does not have DEPOSITOR_ROLE
     */
    error NotDepositor();

    /**
     * @notice no array given
     */
    error InvalidArray();

    /**
     * @notice invalid reward identifier
     */
    error InvalidRewardIdentifier();

    /**
     * @notice bribe has already been transferred
     */
    error BribeAlreadyTransferred();

    /**
     * @notice distribution does not exist
     */
    error InvalidDistribution();

    /**
     * @notice invalid merkle root
     */
    error InvalidMerkleRoot();

    /**
     * @notice token is address(0)
     */
    error InvalidToken();

    /**
     * @notice claim does not exist
     */
    error InvalidClaim();

    /**
     * @notice reward is not yet active for claiming
     */
    error RewardInactive();

    /**
     * @notice timer duration is invalid
     */
    error InvalidTimerDuration();

    /**
     * @notice merkle proof is invalid
     */
    error InvalidProof();

    /**
     * @notice ETH transfer failed
     */
    error ETHTransferFailed();

    /**
     * @notice Invalid operator address
     */
    error InvalidOperator();

    /**
     * @notice call to TokenTransferProxy contract
     */
    error TokenTransferProxyCall();

    /**
     * @notice calling TransferFrom
     */
    error TransferFromCall();

    /**
     * @notice external call failed
     */
    error ExternalCallFailure();

    /**
     * @notice returned tokens too few
     */
    error InsufficientReturn();

    /**
     * @notice swapDeadline expired
     */
    error DeadlineBreach();

    /**
     * @notice expected tokens returned are 0
     */
    error ZeroExpectedReturns();

    /**
     * @notice arrays in SwapData.exchangeData have wrong lengths
     */
    error ExchangeDataArrayMismatch();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Errors} from "./libraries/Errors.sol";
import {Common} from "./libraries/Common.sol";

contract RewardHarvester is Ownable2Step {
    using SafeERC20 for IERC20;

    struct Reward {
        bytes32 merkleRoot;
        bytes32 hashedData;
        uint256 activeAt;
    }

    uint256 public constant FEE_BASIS = 1_000_000;
    uint256 public constant MAX_FEE = 100_000;
    uint256 public constant MINIMUM_ACTIVE_TIMER = 3 hours;

    // Maps members
    mapping(address => bool) public isMember;
    // Maps fees collected for each token
    mapping(address => uint256) public feesCollected;
    // Maps each of the identifier to its reward metadata
    mapping(address => Reward) public rewards;
    // Tracks the amount of claimed reward for the specified token and account
    mapping(address => mapping(address => uint256)) public claimed;
    // Harvest default token
    address public defaultToken;
    // Operator address
    address public operator;
    // Claimer address
    address public claimer;
    // Reward swapper address
    address public rewardSwapper;
    // Used for calculating the timestamp on which rewards can be claimed after an update
    uint256 public activeTimerDuration;

    //-----------------------//
    //        Events         //
    //-----------------------//
    event MemberJoined(address member);
    event MemberLeft(address member);
    event FeesCollected(address indexed token, uint256 amount);
    event BribeTransferred(address indexed token, uint256 totalAmount);
    event RewardClaimed(
        address indexed token,
        address indexed account,
        uint256 amount,
        uint256 postFeeAmount,
        address receiver
    );
    event RewardMetadataUpdated(
        address indexed token,
        bytes32 merkleRoot,
        bytes32 proof,
        uint256 activeAt
    );
    event DefaultTokenUpdated(address indexed token);
    event SetOperator(address indexed operator);
    event SetClaimer(address indexed claimer);
    event SetRewardSwapper(address indexed rewardSwapper);
    event SetActiveTimerDuration(uint256 duration);

    //-----------------------//
    //       Modifiers       //
    //-----------------------//
    /**
     * @notice Modifier to check caller is operator
     */
    modifier onlyOperatorOrOwner() {
        if (msg.sender != operator && msg.sender != owner())
            revert Errors.NotAuthorized();
        _;
    }

    /**
     * @notice Modifier to check caller is operator or reward swapper
     */
    modifier onlyOperatorOrRewardSwapper() {
        if (msg.sender != operator && msg.sender != rewardSwapper)
            revert Errors.NotAuthorized();
        _;
    }

    //-----------------------//
    //       Constructor     //
    //-----------------------//
    constructor(
        address _rewardSwapper,
        address _operator,
        address _defaultToken
    ) {
        _setDefaultToken(_defaultToken);
        _setOperator(_operator);
        _setRewardSwapper(_rewardSwapper);
        _setActiveTimerDuration(MINIMUM_ACTIVE_TIMER);
    }

    //-----------------------//
    //   External Functions  //
    //-----------------------//

    /**
        @notice Join the harvester to enable claiming rewards in default token
     */
    function join() external {
        isMember[msg.sender] = true;

        emit MemberJoined(msg.sender);
    }

    /**
        @notice Leave harvester
     */
    function leave() external {
        isMember[msg.sender] = false;

        emit MemberLeft(msg.sender);
    }

    /**
        @notice Claim rewards based on the specified metadata
        @dev    Can only be called by the claimer contract
        @param  _token        address    Token to claim rewards
        @param  _account      address    Account to claim rewards
        @param  _amount       uint256    Amount of rewards to claim
        @param  _merkleProof  bytes32[]  Merkle proof of the claim
        @param  _fee          uint256    Claim fee
        @param  _receiver     address    Receiver of the rewards
     */
    function claim(
        address _token,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint256 _fee,
        address _receiver
    ) external {
        if (msg.sender != claimer) revert Errors.NotAuthorized();
        if (_account == address(0)) revert Errors.InvalidClaim();
        if (_amount == 0) revert Errors.InvalidAmount();
        if (_fee > MAX_FEE) revert Errors.InvalidFee();

        // Calculate amount after any fees
        uint256 feeAmount = (_amount * _fee) / FEE_BASIS;
        uint256 postFeeAmount = _amount - feeAmount;
        feesCollected[_token] += feeAmount;

        Reward memory reward = rewards[_token];
        uint256 lifeTimeAmount = claimed[_token][_account] + _amount;

        if (reward.merkleRoot == 0) revert Errors.InvalidDistribution();
        if (reward.activeAt > block.timestamp) revert Errors.RewardInactive();

        // Verify the merkle proof
        if (
            !MerkleProof.verifyCalldata(
                _merkleProof,
                reward.merkleRoot,
                keccak256(abi.encodePacked(_account, lifeTimeAmount))
            )
        ) revert Errors.InvalidProof();

        // Update the claimed amount to the current total
        claimed[_token][_account] = lifeTimeAmount;

        IERC20(_token).safeTransfer(_receiver, postFeeAmount);

        emit RewardClaimed(_token, _account, _amount, postFeeAmount, _receiver);
    }

    /**
        @notice Deposit `defaultToken` to this contract
        @param  _amount  uint256  Amount of `defaultToken` to deposit
     */
    function depositReward(
        uint256 _amount
    ) external onlyOperatorOrRewardSwapper {
        if (_amount == 0) revert Errors.InvalidAmount();

        IERC20 token = IERC20(defaultToken);

        uint256 initialAmount = token.balanceOf(address(this));

        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit BribeTransferred(
            defaultToken,
            token.balanceOf(address(this)) - initialAmount
        );
    }

    /**
        @notice Update rewards metadata
        @param  _token       address  Token to update rewards metadata
        @param  _merkleRoot  bytes32  Merkle root of the rewards
        @param  _hashedData  bytes32  Hashed data of the rewards
     */
    function updateRewardsMetadata(
        address _token,
        bytes32 _merkleRoot,
        bytes32 _hashedData
    ) external onlyOperatorOrOwner {
        if (_token == address(0)) revert Errors.InvalidToken();
        if (_merkleRoot == 0) revert Errors.InvalidMerkleRoot();

        // Update the metadata and start the timer until the rewards will be active/claimable
        uint256 activeAt = block.timestamp + activeTimerDuration;
        Reward storage reward = rewards[_token];
        reward.merkleRoot = _merkleRoot;
        reward.hashedData = _hashedData;
        reward.activeAt = activeAt;

        emit RewardMetadataUpdated(_token, _merkleRoot, _hashedData, activeAt);
    }

    /**
        @notice Collect fees
        @param  _token  address  Token to collect fees
     */
    function collectFees(address _token) external onlyOwner {
        uint256 amount = feesCollected[_token];
        if (amount == 0) revert Errors.InvalidAmount();

        feesCollected[_token] = 0;
        IERC20(_token).safeTransfer(msg.sender, amount);

        emit FeesCollected(_token, amount);
    }

    /**
        @notice Change the operator
        @param  _operator  address  New operator address
     */
    function changeOperator(address _operator) external onlyOwner {
        _setOperator(_operator);
    }

    /**
        @notice Change the `defaultToken`
        @param  _newToken  address  New default token address
     */
    function changeDefaultToken(address _newToken) external onlyOwner {
        _setDefaultToken(_newToken);
    }

    /**
        @notice Change the RewardSwapper contract
        @param  _newSwapper  address  New reward swapper address
     */
    function changeRewardSwapper(address _newSwapper) external onlyOwner {
        _setRewardSwapper(_newSwapper);
    }

    /**
        @notice Change claimer address
        @param  _claimer  address  New claimer address
     */
    function changeClaimer(address _claimer) external onlyOwner {
        if (_claimer == address(0)) revert Errors.InvalidAddress();

        claimer = _claimer;

        emit SetClaimer(_claimer);
    }

    /**
        @notice Set the active timer duration
        @param  _duration  uint256  Timer duration
    */
    function changeActiveTimerDuration(uint256 _duration) external onlyOwner {
        _setActiveTimerDuration(_duration);
    }

    //-----------------------//
    //   Internal Functions  //
    //-----------------------//
    /**
        @dev    Internal to set the default token
        @param  _newToken  address  Token address
     */
    function _setDefaultToken(address _newToken) internal {
        if (_newToken == address(0)) revert Errors.InvalidToken();

        defaultToken = _newToken;

        emit DefaultTokenUpdated(_newToken);
    }

    /**
        @dev    Internal to set the RewardSwapper contract
        @param  _newSwapper  address  RewardSwapper address
     */
    function _setRewardSwapper(address _newSwapper) internal {
        if (_newSwapper == address(0)) revert Errors.InvalidAddress();

        rewardSwapper = _newSwapper;

        emit SetRewardSwapper(_newSwapper);
    }

    /**
        @dev    Internal to set the operator
        @param  _operator  address  Token address
     */
    function _setOperator(address _operator) internal {
        if (_operator == address(0)) revert Errors.InvalidOperator();

        operator = _operator;

        emit SetOperator(_operator);
    }

    /**
        @dev    Internal to set the active timer duration
        @param  _duration  uint256  Timer duration
     */
    function _setActiveTimerDuration(uint256 _duration) internal {
        if (_duration < MINIMUM_ACTIVE_TIMER)
            revert Errors.InvalidTimerDuration();

        activeTimerDuration = _duration;

        emit SetActiveTimerDuration(_duration);
    }
}