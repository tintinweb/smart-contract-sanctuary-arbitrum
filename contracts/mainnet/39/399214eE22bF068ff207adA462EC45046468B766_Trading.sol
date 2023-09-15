// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernanceStaking {
    function stake(uint256 _amount, uint256 _duration) external;
    function unstake(uint256 _amount) external;
    function claim() external;
    function distribute(address _token, uint256 _amount) external;
    function whitelistReward(address _rewardToken) external;
    function pending(address _user, address _token) external view returns (uint256);
    function userStaked(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPairsContract {

    struct Asset {
        string name;
        address chainlinkFeed;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 feeMultiplier;
        uint256 baseFundingRate;
    }

    struct OpenInterest {
        uint256 longOi;
        uint256 shortOi;
        uint256 maxOi;
    }

    function allowedAsset(uint) external view returns (bool);
    function idToAsset(uint256 _asset) external view returns (Asset memory);
    function idToOi(uint256 _asset, address _tigAsset) external view returns (OpenInterest memory);
    function setAssetBaseFundingRate(uint256 _asset, uint256 _baseFundingRate) external;
    function modifyLongOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external;
    function modifyShortOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPosition {

    struct Trade {
        uint256 margin;
        uint256 leverage;
        uint256 asset;
        bool direction;
        uint256 price;
        uint256 tpPrice;
        uint256 slPrice;
        uint256 orderType;
        address trader;
        uint256 id;
        address tigAsset;
        int accInterest;
    }

    struct MintTrade {
        address account;
        uint256 margin;
        uint256 leverage;
        uint256 asset;
        bool direction;
        uint256 price;
        uint256 tp;
        uint256 sl;
        uint256 orderType;
        address tigAsset;
    }

    function trades(uint256) external view returns (Trade memory);
    function executeLimitOrder(uint256 _id, uint256 _price, uint256 _newMargin) external;
    function modifyMargin(uint256 _id, uint256 _newMargin, uint256 _newLeverage) external;
    function addToPosition(uint256 _id, uint256 _newMargin, uint256 _newPrice) external;
    function reducePosition(uint256 _id, uint256 _newMargin) external;
    function assetOpenPositions(uint256 _asset) external view returns (uint256[] calldata);
    function assetOpenPositionsIndexes(uint256 _asset, uint256 _id) external view returns (uint256);
    function limitOrders(uint256 _asset) external view returns (uint256[] memory);
    function limitOrderIndexes(uint256 _asset, uint256 _id) external view returns (uint256);
    function assetOpenPositionsLength(uint256 _asset) external view returns (uint256);
    function limitOrdersLength(uint256 _asset) external view returns (uint256);
    function ownerOf(uint256 _id) external view returns (address);
    function mint(MintTrade memory _mintTrade) external;
    function burn(uint256 _id) external;
    function modifyTp(uint256 _id, uint256 _tpPrice) external;
    function modifySl(uint256 _id, uint256 _slPrice) external;
    function getCount() external view returns (uint);
    function updateFunding(uint256 _asset, address _tigAsset, uint256 _longOi, uint256 _shortOi, uint256 _baseFundingRate, uint256 _vaultFundingPercent) external;
    function setAccInterest(uint256 _id) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReferrals {
    function setReferred(address _referredTrader, address _referrer) external;
    function getReferred(address _trader) external view returns (address, uint);
    function addRefFees(address _trader, address _tigAsset, uint _fees) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStableVault {
    function deposit(address, uint) external;
    function withdraw(address, uint) external returns (uint256);
    function allowed(address) external view returns (bool);
    function stable() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/TradingLibrary.sol";

interface ITrading {

    struct TradeInfo {
        uint256 margin;
        address marginAsset;
        address stableVault;
        uint256 leverage;
        uint256 asset;
        bool direction;
        uint256 tpPrice;
        uint256 slPrice;
        address referrer;
    }
    struct ERC20PermitData {
        uint256 deadline;
        uint256 amount;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool usePermit;
    }
    struct Fees {
        uint256 daoFees;
        uint256 burnFees;
        uint256 refDiscount;
        uint256 botFees;
        uint256 keeperFees;
    }
    struct Delay {
        uint256 delay; // Block timestamp where delay ends
        bool actionType; // True for open, False for close
    }
    struct PendingMarketOrderData {
        uint256 id;
        uint256 timestamp;
        TradeInfo tradeInfo;
        address tigAsset;
        uint256 marginAfterFees;
        address trader;
    }
    struct PendingAddToPositionOrderData {
        uint256 id;
        uint256 tradeId;
        uint256 asset;
        uint256 timestamp;
        uint256 marginToAdd;
        address tigAsset;
        address trader;
    }

    error LimitNotSet();
    error OnlyEOA();
    error NotLiquidatable();
    error TradingPaused();
    error OldPriceData();
    error OrderNotFound();
    error TooEarlyToCancel();
    error BadDeposit();
    error BadWithdraw();
    error BadStopLoss();
    error IsLimit();
    error ValueNotEqualToMargin();
    error BadLeverage();
    error NotMargin();
    error NotAllowedInVault();
    error NotVault();
    error NotOwner();
    error NotAllowedPair();
    error WaitDelay();
    error NotProxy();
    error BelowMinPositionSize();
    error BadClosePercent();
    error NoPrice();
    error LiqThreshold();
    error CloseToMaxPnL();
    error BadSetter();
    error BadConstructor();
    error NotLimit();
    error LimitNotMet();

    function createMarketOrder(
        TradeInfo calldata _tradeInfo,
        PriceData calldata _priceData,
        ERC20PermitData calldata _permitData,
        address _trader
    ) external;

    function confirmMarketOrder(
        uint256 _orderId,
        PriceData calldata _priceData,
        bool _earnKeeperFee
    ) external;

    function initiateCloseOrder(
        uint256 _id,
        uint256 _percent,
        PriceData calldata _priceData,
        address _stableVault,
        address _outputToken,
        address _trader
    ) external;

    function addMargin(
        uint256 _id,
        address _stableVault,
        address _marginAsset,
        uint256 _addMargin,
        PriceData calldata _priceData,
        ERC20PermitData calldata _permitData,
        address _trader
    ) external;

    function removeMargin(
        uint256 _id,
        address _stableVault,
        address _outputToken,
        uint256 _removeMargin,
        PriceData calldata _priceData,
        address _trader
    ) external;

    function createAddToPositionOrder(
        uint256 _id,
        PriceData calldata _priceData,
        address _stableVault,
        address _marginAsset,
        uint256 _addMargin,
        ERC20PermitData calldata _permitData,
        address _trader
    ) external;

    function confirmAddToPositionOrder(
        uint256 _orderId,
        PriceData calldata _priceData,
        bool _earnKeeperFee
    ) external;

    function initiateLimitOrder(
        TradeInfo calldata _tradeInfo,
        uint256 _orderType, // 1 limit, 2 momentum
        uint256 _price,
        ERC20PermitData calldata _permitData,
        address _trader
    ) external;

    function cancelLimitOrder(
        uint256 _id,
        address _trader
    ) external;

    function updateTpSl(
        bool _type, // true is TP
        uint256 _id,
        uint256 _limitPrice,
        PriceData calldata _priceData,
        address _trader
    ) external;

    function executeLimitOrder(
        uint256 _id, 
        PriceData calldata _priceData
    ) external;

    function liquidatePosition(
        uint256 _id,
        PriceData calldata _priceData
    ) external;

    function limitClose(
        uint256 _id,
        bool _tp,
        PriceData calldata _priceData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/TradingLibrary.sol";

interface ITradingExtension {

    error LimitNotMet();
    error LimitNotSet();
    error IsLimit();
    error GasTooHigh();
    error BadConstructor();

    function getVerifiedPrice(
        uint256 _asset,
        PriceData calldata _priceData,
        uint8 _withSpreadIsLong
    ) external returns(uint256 _price, uint256 _spread);

    function getRef(
        address _trader
    ) external view returns(address, uint);

    function setReferral(
        address _referrer,
        address _trader
    ) external;

    function addRefFees(
        address _trader,
        address _tigAsset,
        uint _fees
    ) external;

    function validateTrade(uint256 _asset, address _tigAsset, uint256 _margin, uint256 _leverage, uint256 _orderType) external view;

    function minPos(address) external view returns(uint);

    function paused() external view returns(bool);

    function _limitClose(
        uint256 _id,
        bool _tp,
        PriceData calldata _priceData
    ) external returns(uint256 _limitPrice, address _tigAsset);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IxTIG is IERC20 {
    function vestingPeriod() external view returns (uint256);
    function earlyUnlockPenalty() external view returns (uint256);
    function epochFeesGenerated(uint256 _epoch) external view returns (uint256);
    function epochAllocation(uint256 _epoch) external view returns (uint256);
    function epochAllocationClaimed(uint256 _epoch) external view returns (uint256);
    function feesGenerated(uint256 _epoch, address _trader) external view returns (uint256);
    function tigAssetValue(address _tigAsset) external view returns (uint256);
    function createVest(uint256 _from) external;
    function claimTig() external;
    function earlyClaimTig() external;
    function claimFees() external;
    function addFees(address _trader, address _tigAsset, uint256 _fees) external;
    function addTigRewards(uint256 _epoch, uint256 _amount) external;
    function setTigAssetValue(address _tigAsset, uint256 _value) external;
    function setCanAddFees(address _address, bool _allowed) external;
    function setExtraRewards(address _address) external;
    function setVestingPeriod(uint256 _time) external;
    function setEarlyUnlockPenalty(uint256 _percent) external;
    function whitelistReward(address _rewardToken) external;
    function contractPending(address _token) external view returns (uint256);
    function extraRewardsPending(address _token) external view returns (uint256);
    function pending(address _user, address _token) external view returns (uint256);
    function pendingTig(address _user) external view returns (uint256);
    function pendingEarlyTig(address _user) external view returns (uint256);
    function upcomingXTig(address _user) external view returns (uint256);
    function stakedTigBalance() external view returns (uint256);
    function userRewardBatches(address _user) external view returns (RewardBatch[] memory);
    function unclaimedAllocation(uint256 _epoch) external view returns (uint256);
    function currentEpoch() external view returns (uint256);

    struct RewardBatch {
        uint256 amount;
        uint256 unlockTime;
    }

    event TigRewardsAdded(address indexed sender, uint256 amount);
    event TigVested(address indexed account, uint256 amount);
    event TigClaimed(address indexed user, uint256 amount);
    event EarlyTigClaimed(address indexed user, uint256 amount, uint256 penalty);
    event TokenWhitelisted(address token);
    event TokenUnwhitelisted(address token);
    event RewardClaimed(address indexed user, uint256 reward);
    event VestingPeriodUpdated(uint256 time);
    event EarlyUnlockPenaltyUpdated(uint256 percent);
    event FeePermissionUpdated(address indexed protocol, bool permission);
    event TreasuryUpdated(address indexed treasury);
    event SetExtraRewards(address indexed extraRewards);
    event FeesAdded(address indexed _trader, address indexed _tigAsset, uint256 _amount, uint256 indexed _value);
    event TigAssetValueUpdated(address indexed _tigAsset, uint256 indexed _value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./utils/MetaContext.sol";
import "./interfaces/ITrading.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPairsContract.sol";
import "./interfaces/IReferrals.sol";
import "./interfaces/IPosition.sol";
import "./interfaces/IGovernanceStaking.sol";
import "./interfaces/IStableVault.sol";
import "./interfaces/ITradingExtension.sol";
import "./interfaces/IxTIG.sol";
import "./utils/TradingLibrary.sol";

interface IStable is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function mintFor(address account, uint256 amount) external;
}

interface ExtendedIERC20 is IERC20 {
    function decimals() external view returns (uint);
}

interface ERC20Permit is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface ILPStaking {
    function distribute(address _tigAsset, uint256 _amount) external;
}

contract Trading is MetaContext, ITrading {

    using SafeERC20 for IERC20;

    uint256 private constant DIVISION_CONSTANT = 1e10; // 100%
    uint256 private constant LIQPERCENT = 9e9; // 90%

    IPairsContract private pairsContract;
    IPosition private position;
    IGovernanceStaking private staking;
    ILPStaking private lpstaking;
    ITradingExtension private tradingExtension;
    IxTIG private xtig;

    Fees public openFees = Fees(
        0,
        0,
        0,
        0,
        0
    );
    Fees public closeFees = Fees(
        0,
        0,
        0,
        0,
        0
    );

    uint256 private limitOrderPriceRange = 1e10; // 100%
    uint256 public maxWinPercent;
    uint256 public vaultFundingPercent;
    uint256 public timeDelay;
    uint256 public lpDistribution = 3e9;
    uint256 private minSlPnlDif = 1e7; // 0.1%

    mapping(address => uint256) public keeperFee; // tigAsset => fixed fee
    mapping(uint256 => Delay) private timeDelayPassed; // id => Delay
    mapping(address => bool) private allowedVault;
    mapping(address => address) public proxyApprovals;
    mapping(address => mapping(address => bool)) private tokenApprovals;
    mapping(uint256 => PendingMarketOrderData) public pendingMarketOrders;
    mapping(uint256 => PendingAddToPositionOrderData) public pendingAddToPositionOrders;
    uint256[] public pendingMarketOrdersList;
    uint256[] public pendingAddToPositionOrdersList;
    mapping(uint256 => uint256) private pendingMarketOrdersIndex;
    mapping(uint256 => uint256) private pendingAddToPositionOrdersIndex;
    uint256 private pendingOrdersCount;
    bool private allowSameBlockOrderConfirmation = true;

    // ===== EVENTS =====

    event MarketOrderCreated(
        PendingMarketOrderData orderData
    );

    event AddToPositionOrderCreated(
        PendingAddToPositionOrderData orderData
    );

    event MarketOrderCancelled(
        PendingMarketOrderData orderData
    );

    event AddToPositionOrderCancelled(
        PendingAddToPositionOrderData orderData
    );

    event PositionOpened(
        TradeInfo tradeInfo,
        uint256 orderType,
        uint256 price,
        uint256 id,
        address trader,
        uint256 marginAfterFees,
        uint256 orderId
    );

    event PositionClosed(
        uint256 id,
        uint256 closePrice,
        uint256 percent,
        uint256 payout,
        address trader,
        address executor
    );

    event PositionLiquidated(
        uint256 id,
        uint256 liqPrice,
        address trader,
        address executor
    );

    event LimitOrderExecuted(
        uint256 asset,
        bool direction,
        uint256 openPrice,
        uint256 lev,
        uint256 margin,
        uint256 id,
        address trader,
        address executor
    );

    event UpdateTPSL(
        uint256 id,
        bool isTp,
        uint256 price,
        address trader
    );

    event LimitCancelled(
        uint256 id,
        address trader
    );

    event MarginModified(
        uint256 id,
        uint256 newMargin,
        uint256 newLeverage,
        bool isMarginAdded,
        address trader
    );

    event AddToPosition(
        uint256 id,
        uint256 newMargin,
        uint256 newPrice,
        uint256 addMargin,
        address trader,
        uint256 orderId
    );

    event FeesDistributed(
        address tigAsset,
        uint256 daoFees,
        uint256 burnFees,
        uint256 refFees,
        uint256 botFees,
        address referrer
    );

    constructor(
        address _position,
        address _staking,
        address _pairsContract,
        address _lpstaking,
        address _xtig
    )
    {
        if (
            _position == address(0)
            || _staking == address(0)
            || _pairsContract == address(0)
            || _lpstaking == address(0)
            || _xtig == address(0)
        ) {
            revert BadConstructor();
        }
        position = IPosition(_position);
        staking = IGovernanceStaking(_staking);
        lpstaking = ILPStaking(_lpstaking);
        pairsContract = IPairsContract(_pairsContract);
        xtig = IxTIG(_xtig);
    }

    // ===== END-USER FUNCTIONS =====

    /**
     * @param _tradeInfo Trade info
     * @param _priceData verifiable off-chain price data
     * @param _permitData data and signature needed for token approval
     * @param _trader address the trade is initiated for
     */
    function createMarketOrder(
        TradeInfo memory _tradeInfo,
        PriceData calldata _priceData,
        ERC20PermitData calldata _permitData,
        address _trader
    )
        external
    {
        _validateProxy(_trader);
        _checkVault(_tradeInfo.stableVault, _tradeInfo.marginAsset);
        address _tigAsset = _getStable(_tradeInfo.stableVault);
        _validateTrade(_tradeInfo.asset, _tigAsset, _tradeInfo.margin, _tradeInfo.leverage, 0);
        tradingExtension.setReferral(_tradeInfo.referrer, _trader);
        _handleDeposit(_tigAsset, _tradeInfo.marginAsset, _tradeInfo.margin, _tradeInfo.stableVault, _permitData, _trader);
        bool _isTimestampValid = _priceData.timestamp == block.timestamp && allowSameBlockOrderConfirmation;
        uint256 _marginAfterFees = _tradeInfo.margin - _handleOpenFees(_tradeInfo.asset, _tradeInfo.margin*_tradeInfo.leverage/1e18, _trader, _tigAsset, false, !_isTimestampValid);
        uint256 _orderId;
        unchecked {
            _orderId = ++pendingOrdersCount;
        }
        PendingMarketOrderData memory _order = PendingMarketOrderData(
            _orderId,
            block.timestamp,
            _tradeInfo,
            _tigAsset,
            _marginAfterFees,
            _trader
        );
        pendingMarketOrders[_orderId] = _order;
        pendingMarketOrdersIndex[_orderId] = pendingMarketOrdersList.length;
        pendingMarketOrdersList.push(_orderId);
        emit MarketOrderCreated(_order);
        if (_isTimestampValid) {
            confirmMarketOrder(_orderId, _priceData, false);
        }
    }

    /**
     * @param _orderId Pending order ID
     * @param _priceData verifiable off-chain price data
     * @param _earnKeeperFee whether to earn keeper fee
     */
    function confirmMarketOrder(
        uint256 _orderId,
        PriceData calldata _priceData,
        bool _earnKeeperFee
    )
        public
    {
        if (_earnKeeperFee && msg.sender != tx.origin) revert OnlyEOA();
        PendingMarketOrderData memory _order = pendingMarketOrders[_orderId];
        if (_order.timestamp == 0) revert OrderNotFound();
        if (_priceData.timestamp < _order.timestamp + (allowSameBlockOrderConfirmation ? 0 : 1)) revert OldPriceData();
        uint256 _id = _getCount();
        _checkDelay(_id, true);
        uint8 _isLong = _order.tradeInfo.direction ? 1 : 2;
        (uint256 _price,) = _getVerifiedPrice(_order.tradeInfo.asset, _priceData, _isLong);
        _order.tradeInfo.slPrice = _checkSl(_order.tradeInfo.slPrice, _order.tradeInfo.direction, _price, false);
        address _tigAsset = _getStable(_order.tradeInfo.stableVault);
        if (_earnKeeperFee) {
            _handleTokenMint(_tigAsset, _msgSender(), keeperFee[_tigAsset]);
        }
        _removeOrderFromStorage(false, _orderId);
        IPosition.MintTrade memory _mintTrade = IPosition.MintTrade(
            _order.trader,
            _order.marginAfterFees,
            _order.tradeInfo.leverage,
            _order.tradeInfo.asset,
            _order.tradeInfo.direction,
            _price,
            _order.tradeInfo.tpPrice,
            _order.tradeInfo.slPrice,
            0,
            _tigAsset
        );
        {
            uint256 _positionSize = _order.marginAfterFees * _order.tradeInfo.leverage / 1e18;
            _handleModifyOi(_order.tradeInfo.direction, _order.tradeInfo.asset, _tigAsset, true, _positionSize);
        }
        _updateFunding(_order.tradeInfo.asset, _tigAsset);
        _handlePositionMint(_mintTrade);
        emit PositionOpened(_order.tradeInfo, 0, _price, _id, _order.trader, _order.marginAfterFees, _orderId);
    }

    /**
     * @dev initiate closing position
     * @param _id id of the position NFT
     * @param _percent percent of the position being closed in BP
     * @param _priceData verifiable off-chain price data
     * @param _stableVault StableVault address
     * @param _outputToken Token received upon closing trade
     * @param _trader address the trade is initiated for
     */
    function initiateCloseOrder(
        uint256 _id,
        uint256 _percent,
        PriceData calldata _priceData,
        address _stableVault,
        address _outputToken,
        address _trader
    )
        external
    {
        _validateProxy(_trader);
        _checkDelay(_id, false);
        _checkOwner(_id, _trader);
        _checkVault(_stableVault, _outputToken);
        IPosition.Trade memory _trade = _getTrade(_id);
        if (_trade.orderType != 0) revert IsLimit();
        (uint256 _price,) = _getVerifiedPrice(_trade.asset, _priceData, 0);
        _closePosition(_id, _percent, _price, _stableVault, _outputToken, false);
    }

    /**
     * @param _id position id
     * @param _addMargin margin amount used to add to the position
     * @param _priceData verifiable off-chain price data
     * @param _stableVault StableVault address
     * @param _marginAsset Token being used to add to the position
     * @param _permitData data and signature needed for token approval
     * @param _trader address the trade is initiated for
     */
    function createAddToPositionOrder(
        uint256 _id,
        PriceData calldata _priceData,
        address _stableVault,
        address _marginAsset,
        uint256 _addMargin,
        ERC20PermitData calldata _permitData,
        address _trader
    )
        external
    {
        _validateProxy(_trader);
        _checkOwner(_id, _trader);
        IPosition.Trade memory _trade = _getTrade(_id);
        _validateTrade(_trade.asset, _trade.tigAsset, _trade.margin + _addMargin, _trade.leverage, 0);
        _checkVault(_stableVault, _marginAsset);
        if (_trade.orderType != 0) revert IsLimit();
        bool _isTimestampValid = _priceData.timestamp == block.timestamp && allowSameBlockOrderConfirmation;
        uint256 _fee = _handleOpenFees(_trade.asset, _addMargin*_trade.leverage/1e18, _trader, _trade.tigAsset, false, !_isTimestampValid);
        _handleDeposit(
            _trade.tigAsset,
            _marginAsset,
            _addMargin,
            _stableVault,
            _permitData,
            _trader
        );
        uint256 _orderId;
        unchecked {
            _orderId = ++pendingOrdersCount;
        }
        PendingAddToPositionOrderData memory _order = PendingAddToPositionOrderData(
            _orderId,
            _trade.id,
            _trade.asset,
            block.timestamp,
            _addMargin - _fee,
            _trade.tigAsset,
            _trader
        );
        pendingAddToPositionOrders[_orderId] = _order;
        pendingAddToPositionOrdersIndex[_orderId] = pendingAddToPositionOrdersList.length;
        pendingAddToPositionOrdersList.push(_orderId);
        emit AddToPositionOrderCreated(_order);
        if (_isTimestampValid) {
            confirmAddToPositionOrder(_orderId, _priceData, false);
        }
    }

    /**
     * @param _orderId Pending order ID
     * @param _priceData verifiable off-chain price data
     * @param _earnKeeperFee boolean indicating whether to earn keeper fee
     */
    function confirmAddToPositionOrder(
        uint256 _orderId,
        PriceData calldata _priceData,
        bool _earnKeeperFee
    )
        public
    {
        if (_earnKeeperFee && msg.sender != tx.origin) revert OnlyEOA();
        PendingAddToPositionOrderData memory _order = pendingAddToPositionOrders[_orderId];
        if (_order.timestamp == 0) revert OrderNotFound();
        if (_priceData.timestamp < _order.timestamp + (allowSameBlockOrderConfirmation ? 0 : 1)) revert OldPriceData();
        uint256 _id = _order.tradeId;
        IPosition.Trade memory _trade = _getTrade(_id);
        _checkDelay(_id, true);
        uint8 _isLong = _trade.direction ? 1 : 2;
        (uint256 _price,) = _getVerifiedPrice(_trade.asset, _priceData, _isLong);
        {
            (,int256 _payout) = _getPnl(_trade.direction, _priceData.price, _trade.price, _trade.margin, _trade.leverage, _trade.accInterest);
            if (maxWinPercent != 0 && _payout >= int256(_trade.margin*(maxWinPercent-DIVISION_CONSTANT)/DIVISION_CONSTANT)) revert CloseToMaxPnL();
        }
        position.setAccInterest(_id);
        {
            uint256 _positionSize = _order.marginToAdd * _trade.leverage / 1e18;
            _handleModifyOi(_trade.direction, _trade.asset, _trade.tigAsset, true, _positionSize);
        }
        _updateFunding(_trade.asset, _trade.tigAsset);
        uint256 _newMargin = _trade.margin + _order.marginToAdd;
        uint256 _newPrice = _trade.price * _price * _newMargin /  (_trade.margin * _price + _order.marginToAdd * _trade.price);
        position.addToPosition(
            _trade.id,
            _newMargin,
            _newPrice
        );
        _removeOrderFromStorage(true, _orderId);
        if (_earnKeeperFee) {
            _handleTokenMint(_trade.tigAsset, _msgSender(), keeperFee[_trade.tigAsset]);
        }
        emit AddToPosition(_trade.id, _newMargin, _newPrice, _order.marginToAdd, _trade.trader, _orderId);
    }

    /**
     * @param _tradeInfo Trade info
     * @param _orderType type of limit order used to open the position
     * @param _price limit price
     * @param _permitData data and signature needed for token approval
     * @param _trader address the trade is initiated for
     */
    function initiateLimitOrder(
        TradeInfo calldata _tradeInfo,
        uint256 _orderType, // 1 limit, 2 stop
        uint256 _price,
        ERC20PermitData calldata _permitData,
        address _trader
    )
        external
    {
        _validateProxy(_trader);
        address _tigAsset = _getStable(_tradeInfo.stableVault);
        if (_orderType == 0) revert NotLimit();
        if (_price == 0) revert NoPrice();
        _validateTrade(_tradeInfo.asset, _tigAsset, _tradeInfo.margin, _tradeInfo.leverage, _orderType);
        _checkVault(_tradeInfo.stableVault, _tradeInfo.marginAsset);
        tradingExtension.setReferral(_tradeInfo.referrer, _trader);
        _handleDeposit(_tigAsset, _tradeInfo.marginAsset, _tradeInfo.margin, _tradeInfo.stableVault, _permitData, _trader);
        _checkSl(_tradeInfo.slPrice, _tradeInfo.direction, _price, true);
        uint256 _id = _getCount();
        _checkDelay(_id, false);
        _handlePositionMint(
            IPosition.MintTrade(
                _trader,
                _tradeInfo.margin,
                _tradeInfo.leverage,
                _tradeInfo.asset,
                _tradeInfo.direction,
                _price,
                _tradeInfo.tpPrice,
                _tradeInfo.slPrice,
                _orderType,
                _tigAsset
            )
        );
        emit PositionOpened(_tradeInfo, _orderType, _price, _id, _trader, _tradeInfo.margin, 0);
    }

    /**
     * @param _id position ID
     * @param _trader address the trade is initiated for
     */
    function cancelLimitOrder(
        uint256 _id,
        address _trader
    )
        external
    {
        _validateProxy(_trader);
        _checkOwner(_id, _trader);
        IPosition.Trade memory _trade = _getTrade(_id);
        if (_trade.orderType == 0) revert();
        _handleTokenMint(_trade.tigAsset, _trader, _trade.margin);
        _handlePositionBurn(_id);
        emit LimitCancelled(_id, _trader);
    }

    function cancelPendingOrder(
        bool _isAddToPositionOrder,
        uint256 _orderId
    )
        external
    {
        if (_isAddToPositionOrder) {
            PendingAddToPositionOrderData memory _order = pendingAddToPositionOrders[_orderId];
            if (block.timestamp < _order.timestamp + timeDelay) revert TooEarlyToCancel();
            if (_order.timestamp == 0) revert OrderNotFound();
            _validateProxy(_order.trader);
            _removeOrderFromStorage(true, _orderId);
            _handleTokenMint(_order.tigAsset, _order.trader, _order.marginToAdd);
            emit AddToPositionOrderCancelled(_order);
        } else {
            PendingMarketOrderData memory _order = pendingMarketOrders[_orderId];
            if (block.timestamp < _order.timestamp + timeDelay) revert TooEarlyToCancel();
            if (_order.timestamp == 0) revert OrderNotFound();
            _validateProxy(_order.trader);
            _removeOrderFromStorage(false, _orderId);
            _handleTokenMint(_order.tigAsset, _order.trader, _order.marginAfterFees);
            emit MarketOrderCancelled(_order);
        }
    }

    /**
     * @param _id position id
     * @param _stableVault StableVault address
     * @param _marginAsset Token being used to add to the position
     * @param _addMargin margin amount being added to the position
     * @param _priceData verifiable off-chain price data
     * @param _permitData data and signature needed for token approval
     * @param _trader address the trade is initiated for
     */
    function addMargin(
        uint256 _id,
        address _stableVault,
        address _marginAsset,
        uint256 _addMargin,
        PriceData calldata _priceData,
        ERC20PermitData calldata _permitData,
        address _trader
    )
        external
    {
        _validateProxy(_trader);
        _checkOwner(_id, _trader);
        _checkVault(_stableVault, _marginAsset);
        IPosition.Trade memory _trade = _getTrade(_id);
        _getVerifiedPrice(_trade.asset, _priceData, 0);
        (,int256 _payout) = _getPnl(_trade.direction, _priceData.price, _trade.price, _trade.margin, _trade.leverage, _trade.accInterest);
        if (maxWinPercent != 0 && _payout >= int256(_trade.margin*(maxWinPercent-DIVISION_CONSTANT)/DIVISION_CONSTANT)) revert CloseToMaxPnL();
        if (_trade.orderType != 0) revert IsLimit();
        IPairsContract.Asset memory asset = _getAsset(_trade.asset);
        _handleDeposit(_trade.tigAsset, _marginAsset, _addMargin, _stableVault, _permitData, _trader);
        uint256 _newMargin = _trade.margin + _addMargin;
        uint256 _newLeverage = _trade.margin * _trade.leverage / _newMargin;
        if (_newLeverage < asset.minLeverage) revert BadLeverage();
        position.modifyMargin(_id, _newMargin, _newLeverage);
        emit MarginModified(_id, _newMargin, _newLeverage, true, _trader);
    }

    /**
     * @param _id position id
     * @param _stableVault StableVault address
     * @param _outputToken token the trader will receive
     * @param _removeMargin margin amount being removed from the position
     * @param _priceData verifiable off-chain price data
     * @param _trader address the trade is initiated for
     */
    function removeMargin(
        uint256 _id,
        address _stableVault,
        address _outputToken,
        uint256 _removeMargin,
        PriceData calldata _priceData,
        address _trader
    )
        external
    {
        _validateProxy(_trader);
        _checkOwner(_id, _trader);
        _checkVault(_stableVault, _outputToken);
        IPosition.Trade memory _trade = _getTrade(_id);
        if (_trade.orderType != 0) revert IsLimit();
        (uint256 _assetPrice,) = _getVerifiedPrice(_trade.asset, _priceData, 0);
        (,int256 _payout) = _getPnl(_trade.direction, _assetPrice, _trade.price, _trade.margin, _trade.leverage, _trade.accInterest);
        if (maxWinPercent != 0 && _payout >= int256(_trade.margin*(maxWinPercent-DIVISION_CONSTANT)/DIVISION_CONSTANT)) revert CloseToMaxPnL();
        IPairsContract.Asset memory asset = _getAsset(_trade.asset);
        uint256 _newMargin = _trade.margin - _removeMargin;
        uint256 _newLeverage = _trade.margin * _trade.leverage / _newMargin;
        if (_newLeverage > asset.maxLeverage) revert BadLeverage();
        (,int256 _payoutAfter) = _getPnl(_trade.direction, _assetPrice, _trade.price, _newMargin, _newLeverage, _trade.accInterest);
        if (_payoutAfter <= int256(_newMargin*(DIVISION_CONSTANT-LIQPERCENT)/DIVISION_CONSTANT)) revert LiqThreshold();
        position.modifyMargin(_trade.id, _newMargin, _newLeverage);
        _handleWithdraw(_trade, _stableVault, _outputToken, _removeMargin);
        emit MarginModified(_trade.id, _newMargin, _newLeverage, false, _trader);
    }

    /**
     * @param _type true for TP, false for SL
     * @param _id position id
     * @param _limitPrice TP/SL trigger price
     * @param _priceData verifiable off-chain price data
     * @param _trader address the trade is initiated for
     */
    function updateTpSl(
        bool _type,
        uint256 _id,
        uint256 _limitPrice,
        PriceData calldata _priceData,
        address _trader
    )
        external
    {
        _validateProxy(_trader);
        _checkOwner(_id, _trader);
        _checkDelay(_id, false);
        IPosition.Trade memory _trade = _getTrade(_id);
        if (_trade.orderType != 0) revert IsLimit();
        if (_type) {
            position.modifyTp(_id, _limitPrice);
        } else {
            (uint256 _price,) = _getVerifiedPrice(_trade.asset, _priceData, 0);
            _checkSl(_limitPrice, _trade.direction, _price, true);
            position.modifySl(_id, _limitPrice);
        }
        emit UpdateTPSL(_id, _type, _limitPrice, _trader);
    }

    /**
     * @param _id position id
     * @param _priceData verifiable off-chain price data
     */
    function executeLimitOrder(
        uint256 _id,
        PriceData calldata _priceData
    )
        external
    {
        _checkDelay(_id, true);
        if (tradingExtension.paused()) revert TradingPaused();
        IPosition.Trade memory _trade = _getTrade(_id);
        _trade.margin -= _handleOpenFees(_trade.asset, _trade.margin* _trade.leverage/1e18, _trade.trader, _trade.tigAsset, true, false);
        uint8 _isLong = _trade.direction ? 1 : 2;
        (uint256 _price,) = _getVerifiedPrice(_trade.asset, _priceData, _isLong);
        if (_trade.orderType == 0) revert NotLimit();
        if (_price > _trade.price+ _trade.price*limitOrderPriceRange/DIVISION_CONSTANT || _price < _trade.price- _trade.price*limitOrderPriceRange/DIVISION_CONSTANT) revert LimitNotMet();
        if (_trade.direction && _trade.orderType == 1) {
            if (_trade.price < _price) revert LimitNotMet();
        } else if (!_trade.direction && _trade.orderType == 1) {
            if (_trade.price > _price) revert LimitNotMet();
        } else if (!_trade.direction && _trade.orderType == 2) {
            if (_trade.price < _price) revert LimitNotMet();
            _trade.price = _price;
        } else {
            if (_trade.price > _price) revert LimitNotMet();
            _trade.price = _price;
        }
        _handleModifyOi(_trade.direction, _trade.asset, _trade.tigAsset, true, _trade.margin*_trade.leverage/1e18);
        if (_trade.direction ? _trade.tpPrice <= _trade.price : _trade.tpPrice >= _trade.price) position.modifyTp(_id, 0);
        _updateFunding(_trade.asset, _trade.tigAsset);
        position.executeLimitOrder(_id, _trade.price, _trade.margin);
        emit LimitOrderExecuted(_trade.asset, _trade.direction, _trade.price, _trade.leverage, _trade.margin, _id, _trade.trader, _msgSender());
    }

    /**
     * @notice liquidate position
     * @param _id id of the position NFT
     * @param _priceData verifiable off-chain data
     */
    function liquidatePosition(
        uint256 _id,
        PriceData calldata _priceData
    )
        external
    {
        unchecked {
            IPosition.Trade memory _trade = _getTrade(_id);
            if (_trade.orderType != 0) revert IsLimit();

            (uint256 _price,) = _getVerifiedPrice(_trade.asset, _priceData, 0);
            (uint256 _positionSizeAfterPrice, int256 _payout) = _getPnl(_trade.direction, _price, _trade.price, _trade.margin, _trade.leverage, _trade.accInterest);
            uint256 _positionSize = _trade.margin*_trade.leverage/1e18;
            if (_payout > int256(_trade.margin*(DIVISION_CONSTANT-LIQPERCENT)/DIVISION_CONSTANT)) revert NotLiquidatable();
            _handleModifyOi(_trade.direction, _trade.asset, _trade.tigAsset, false, _positionSize);
            _updateFunding(_trade.asset, _trade.tigAsset);
            _handleCloseFees(_trade.asset, type(uint).max, _trade.tigAsset, _positionSizeAfterPrice, _trade.trader, true);
            _handlePositionBurn(_id);
            emit PositionLiquidated(_id, _price, _trade.trader, _msgSender());
        }
    }

    /**
     * @dev close position at a pre-set price
     * @param _id id of the position NFT
     * @param _tp true if take profit
     * @param _priceData verifiable off-chain price data
     */
    function limitClose(
        uint256 _id,
        bool _tp,
        PriceData calldata _priceData
    )
        external
    {
        _checkDelay(_id, false);
        (uint256 _limitPrice, address _tigAsset) = tradingExtension._limitClose(_id, _tp, _priceData);
        _closePosition(_id, DIVISION_CONSTANT, _limitPrice, address(0), _tigAsset, true);
    }

    /**
     * @notice Trader can approve a proxy wallet address for it to trade on its behalf. Can also provide proxy wallet with gas.
     * @param _proxy proxy wallet address
     */
    function approveProxy(address _proxy) external payable {
        require(_proxy != address(0), "ZeroAddress");
        proxyApprovals[_msgSender()] = _proxy;
        (bool sent,) = payable(_proxy).call{value: msg.value}("");
        require(sent, "F");
    }

    // ===== INTERNAL FUNCTIONS =====

    /**
     * @dev close the initiated position.
     * @param _id id of the position NFT
     * @param _percent percent of the position being closed
     * @param _price pair price
     * @param _stableVault StableVault address
     * @param _outputToken Token that trader will receive
     * @param _isBot false if closed via market order
     */
    function _closePosition(
        uint256 _id,
        uint256 _percent,
        uint256 _price,
        address _stableVault,
        address _outputToken,
        bool _isBot
    )
        internal
    {
        if (_percent > DIVISION_CONSTANT || _percent == 0) revert BadClosePercent();
        IPosition.Trade memory _trade = _getTrade(_id);
        (uint256 _positionSize, int256 _payout) = _getPnl(_trade.direction, _price, _trade.price, _trade.margin, _trade.leverage, _trade.accInterest);
        unchecked {
            _handleModifyOi(_trade.direction, _trade.asset, _trade.tigAsset, false, (_trade.margin*_trade.leverage/1e18)*_percent/DIVISION_CONSTANT);
        }
        position.setAccInterest(_id);
        _updateFunding(_trade.asset, _trade.tigAsset);
        if (_percent < DIVISION_CONSTANT) {
            if ((_trade.margin*_trade.leverage*(DIVISION_CONSTANT-_percent)/DIVISION_CONSTANT)/1e18 < tradingExtension.minPos(_trade.tigAsset)) revert BelowMinPositionSize();
            position.reducePosition(_id, _percent);
        } else {
            _handlePositionBurn(_id);
        }
        uint256 _toMint;
        if (_payout > 0) {
            unchecked {
                _toMint = _handleCloseFees(_trade.asset, uint256(_payout)*_percent/DIVISION_CONSTANT, _trade.tigAsset, _positionSize*_percent/DIVISION_CONSTANT, _trade.trader, _isBot);
                uint256 marginToClose = _trade.margin*_percent/DIVISION_CONSTANT;
                if (maxWinPercent > 0 && _toMint > marginToClose*maxWinPercent/DIVISION_CONSTANT) {
                    _toMint = marginToClose*maxWinPercent/DIVISION_CONSTANT;
                }
            }
            _handleWithdraw(_trade, _stableVault, _outputToken, _toMint);
        }
        emit PositionClosed(_id, _price, _percent, _toMint, _trade.trader, _isBot ? _msgSender() : _trade.trader);
    }

    /**
     * @dev handle stableVault deposits for different trading functions
     * @param _tigAsset tigAsset token address
     * @param _marginAsset token being deposited into stableVault
     * @param _margin amount being deposited
     * @param _stableVault StableVault address
     * @param _permitData Data for approval via permit
     * @param _trader Trader address to take tokens from
     */
    function _handleDeposit(address _tigAsset, address _marginAsset, uint256 _margin, address _stableVault, ERC20PermitData calldata _permitData, address _trader) internal {
        if (_tigAsset != _marginAsset) {
            if (_permitData.usePermit) {
                ERC20Permit(_marginAsset).permit(_trader, address(this), _permitData.amount, _permitData.deadline, _permitData.v, _permitData.r, _permitData.s);
            }
            uint256 _balBefore = _getTokenBalance(_tigAsset, address(this));
            uint256 _marginDecMultiplier = 10**(18-ExtendedIERC20(_marginAsset).decimals());
            IERC20(_marginAsset).safeTransferFrom(_trader, address(this), _margin/_marginDecMultiplier);
            _handleApproval(_marginAsset, _stableVault);
            IStableVault(_stableVault).deposit(_marginAsset, _margin/_marginDecMultiplier);
            uint256 _balAfter = _getTokenBalance(_tigAsset, address(this));
            if (_balAfter != _balBefore + _margin) revert BadDeposit();
            _handleTokenBurn(_tigAsset, address(this), _balAfter);
        } else {
            _handleTokenBurn(_tigAsset, _trader, _margin);
        }
    }

    /**
     * @dev handle stableVault withdrawals for different trading functions
     * @param _trade Position info
     * @param _stableVault StableVault address
     * @param _outputToken Output token address
     * @param _toMint Amount of tigAsset minted to be used for withdrawal
     */
    function _handleWithdraw(IPosition.Trade memory _trade, address _stableVault, address _outputToken, uint256 _toMint) internal {
        _handleTokenMint(_trade.tigAsset, address(this), _toMint);
        uint256 _amountToTransfer = _toMint;
        if (_outputToken != _trade.tigAsset) {
            uint256 _balBefore = _getTokenBalance(_outputToken, address(this));
            IStableVault(_stableVault).withdraw(_outputToken, _toMint);
            uint256 _decimals = ExtendedIERC20(_outputToken).decimals();
            uint256 _balAfter = _getTokenBalance(_outputToken, address(this));
            if (_balAfter != _balBefore + _toMint/(10**(18-_decimals))) revert BadWithdraw();
            _amountToTransfer = _balAfter - _balBefore;
        }
        IERC20(_outputToken).safeTransfer(_trade.trader, _amountToTransfer);
    }

    /**
     * @dev handle fees distribution for opening
     * @param _asset asset id
     * @param _positionSize position size
     * @param _trader trader address
     * @param _tigAsset tigAsset address
     * @param _isBot false if opened via market order
     * @param _useKeeperFee true if keeper fee should be used
     * @return _feePaid total fees paid during opening
     */
    function _handleOpenFees(
        uint256 _asset,
        uint256 _positionSize,
        address _trader,
        address _tigAsset,
        bool _isBot,
        bool _useKeeperFee
    )
        internal
        returns (uint256 _feePaid)
    {
        Fees memory _fees = openFees;
        uint256 _referrerFees;
        if (_useKeeperFee) {
            _fees.keeperFees = keeperFee[_tigAsset];
        }
        (_fees, _referrerFees) = _feesHandling(_fees, _asset, _tigAsset, _positionSize, _trader, _isBot);
        _handleApproval(_tigAsset, address(staking));
        _handleApproval(_tigAsset, address(lpstaking));
        unchecked {
            uint256 _lpDistribution = _fees.daoFees * lpDistribution / DIVISION_CONSTANT;
            lpstaking.distribute(_tigAsset, _lpDistribution);
            staking.distribute(_tigAsset, _fees.daoFees-_lpDistribution);
            _feePaid = _fees.daoFees + _fees.burnFees + _fees.botFees + _referrerFees + _fees.keeperFees;
            xtig.addFees(_trader, _tigAsset, _feePaid);
        }
    }

    /**
     * @dev handle fees distribution for closing
     * @param _asset asset id
     * @param _payout payout to trader before fees
     * @param _tigAsset margin asset
     * @param _positionSize position size
     * @param _trader trader address
     * @param _isBot false if closed via market order
     * @return payout_ payout to trader after fees
     */
    function _handleCloseFees(
        uint256 _asset,
        uint256 _payout,
        address _tigAsset,
        uint256 _positionSize,
        address _trader,
        bool _isBot
    )
        internal
        returns (uint256 payout_)
    {
        (Fees memory _fees, uint256 _referrerFees) = _feesHandling(closeFees, _asset, _tigAsset, _positionSize, _trader, _isBot);
        payout_ = _payout - (_fees.daoFees + _fees.refDiscount) - _fees.burnFees - _fees.botFees;
        unchecked {
            uint256 _lpDistribution = _fees.daoFees * lpDistribution / DIVISION_CONSTANT;
            lpstaking.distribute(_tigAsset, _lpDistribution);
            staking.distribute(_tigAsset, _fees.daoFees-_lpDistribution);
            xtig.addFees(_trader, _tigAsset,
                _fees.daoFees
                + _referrerFees
                + _fees.burnFees
                + _fees.botFees
            );
        }
    }

    /**
     * @dev Handle fee distribution from opening and closing
     * @param _fees fees struct from opening/closing
     * @param _asset asset id
     * @param _tigAsset margin asset
     * @param _positionSize position size
     * @param _trader trader address
     * @param _isBot true if called by a function that is executable by bots (limit orders, liquidations)
     * @return Updated fees struct for further processing
     * @return Fees earned by the referrer
     */
    function _feesHandling(Fees memory _fees, uint256 _asset, address _tigAsset, uint256 _positionSize, address _trader, bool _isBot) internal returns (Fees memory, uint256) {
        IPairsContract.Asset memory asset = _getAsset(_asset);
        (address _referrer, uint256 _referrerFees) = tradingExtension.getRef(_trader);
        unchecked {
            _fees.daoFees = (_positionSize*_fees.daoFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT
                - _fees.keeperFees;
            _fees.burnFees = (_positionSize*_fees.burnFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
            _fees.botFees = (_positionSize*_fees.botFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
            _fees.refDiscount = (_positionSize*_fees.refDiscount/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
            _referrerFees = (_positionSize*_referrerFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
        }
        if (_referrer != address(0)) {
            _handleTokenMint(_tigAsset, _referrer, _referrerFees);
            _fees.daoFees = _fees.daoFees-_fees.refDiscount-_referrerFees;
            tradingExtension.addRefFees(_referrer, _tigAsset, _referrerFees);
        } else {
            _referrerFees = 0;
            _fees.refDiscount = 0;
        }
        if (_isBot) {
            _handleTokenMint(_tigAsset, _msgSender(), _fees.botFees);
            _fees.daoFees = _fees.daoFees - _fees.botFees;
        } else {
            _fees.botFees = 0;
        }
        emit FeesDistributed(_tigAsset, _fees.daoFees, _fees.burnFees, _referrerFees, _fees.botFees, _referrer);
        _handleTokenMint(_tigAsset, address(this), _fees.daoFees);
        return (_fees, _referrerFees);
    }

    /**
     * @dev Checks if trade parameters are valid
     * @param _asset asset id
     * @param _tigAsset margin asset
     * @param _margin margin amount
     * @param _leverage leverage amount
     * @param _orderType order type, 0 is market, 1 is limit buy/sell, 2 is buy/sell stop
     */
    function _validateTrade(
        uint256 _asset,
        address _tigAsset,
        uint256 _margin,
        uint256 _leverage,
        uint256 _orderType
    ) internal view {
        tradingExtension.validateTrade(
            _asset,
            _tigAsset,
            _margin,
            _leverage,
            _orderType
        );
    }

    /**
     * @dev Approves a token only once
     * @param _token token address
     * @param _to spender address
     */
    function _handleApproval(address _token, address _to) internal {
        if (!tokenApprovals[_token][_to]) {
            IERC20(_token).approve(_to, type(uint256).max);
            tokenApprovals[_token][_to] = true;
        }
    }

    /**
     * @dev Changes a pair's open interest in pairs contract
     * @param _isLong true if long, false if short
     * @param _asset asset id
     * @param _tigAsset tigAsset used for margin
     * @param _onOpen true if opening, false if closing
     * @param _size position size
     */
    function _handleModifyOi(
        bool _isLong,
        uint256 _asset,
        address _tigAsset,
        bool _onOpen,
        uint256 _size
    ) internal {
        if (_isLong) {
            pairsContract.modifyLongOi(_asset, _tigAsset, _onOpen, _size);
        } else {
            pairsContract.modifyShortOi(_asset, _tigAsset, _onOpen, _size);
        }
    }

    /**
     * @dev Verify price data
     * @param _asset asset id
     * @param _priceData price data struct
     * @param _withSpreadIsLong true if long, false if short
     * @return _price price, 18 decimals
     * @return _spread spread percent, 10 decimals
     */
    function _getVerifiedPrice(
        uint256 _asset,
        PriceData calldata _priceData,
        uint8 _withSpreadIsLong
    ) internal returns (uint256, uint256) {
        return tradingExtension.getVerifiedPrice(_asset, _priceData, _withSpreadIsLong);
    }

    /**
     * @dev Calculate pnl for a position, all integer values 18 decimals
     * @param _direction position direction
     * @param _currentPrice current price
     * @param _openPrice open price
     * @param _margin margin
     * @param _leverage leverage
     * @param _accInterest accumulated interest, negative is interest paid, positive is interest received
     * @return _positionSize position size
     * @return _payout payout
     */
    function _getPnl(
        bool _direction,
        uint256 _currentPrice,
        uint256 _openPrice,
        uint256 _margin,
        uint256 _leverage,
        int256 _accInterest
    ) internal pure returns (uint256 _positionSize, int256 _payout) {
        (_positionSize, _payout) = TradingLibrary.pnl(
            _direction,
            _currentPrice,
            _openPrice,
            _margin,
            _leverage,
            _accInterest
        );
    }

    /**
     * @dev Remove an order from order list and index mapping
     * @param _isAddToPositionOrder is order from add to position or market order
     * @param _orderId order id
     */
    function _removeOrderFromStorage(bool _isAddToPositionOrder, uint256 _orderId) internal {
        if (_isAddToPositionOrder) {
            delete pendingAddToPositionOrders[_orderId];
            TradingLibrary.removeFromStorageArray(_orderId, pendingAddToPositionOrdersList, pendingAddToPositionOrdersIndex);
        } else {
            delete pendingMarketOrders[_orderId];
            TradingLibrary.removeFromStorageArray(_orderId, pendingMarketOrdersList, pendingMarketOrdersIndex);
        }
    }

    /**
     * @dev update funding rates after open interest changes
     * @param _asset asset id
     * @param _tigAsset tigAsset used for OI
     */
    function _updateFunding(uint256 _asset, address _tigAsset) internal {
        IPairsContract.OpenInterest memory _oi = pairsContract.idToOi(_asset, _tigAsset);
        IPairsContract.Asset memory _assetData = _getAsset(_asset);
        position.updateFunding(
            _asset,
            _tigAsset,
            _oi.longOi,
            _oi.shortOi,
            _assetData.baseFundingRate,
            vaultFundingPercent
        );
    }

    /**
     * @dev check that SL price is valid compared to market price
     * @param _sl SL price
     * @param _direction long/short
     * @param _price market price
     * @param _doRevert should revert if SL is invalid
     */
    function _checkSl(uint256 _sl, bool _direction, uint256 _price, bool _doRevert) internal view returns (uint256) {
        if (_direction) {
            if (_sl > _price-_price*minSlPnlDif/DIVISION_CONSTANT) {
                if (_doRevert) {
                    revert BadStopLoss();
                } else {
                    return 0;
                }
            }
        } else {
            if (_sl < _price+_price*minSlPnlDif/DIVISION_CONSTANT && _sl != 0) {
                if (_doRevert) {
                    revert BadStopLoss();
                } else {
                    return 0;
                }
            }
        }
        return _sl;
    }

    /**
     * @dev check that trader address owns the position
     * @param _id position id
     * @param _trader trader address
     */
    function _checkOwner(uint256 _id, address _trader) internal view {
        if (position.ownerOf(_id) != _trader) revert NotOwner();
    }

    /**
     * @dev Get the upcoming position nft index
     */
    function _getCount() internal view returns (uint256) {
        return position.getCount();
    }

    /**
     * @dev Mint a position
     * @param _mintTrade mint trade data
     */
    function _handlePositionMint(IPosition.MintTrade memory _mintTrade) internal {
        position.mint(_mintTrade);
    }

    /**
     * @dev Burn a position
     * @param _id position id
     */
    function _handlePositionBurn(uint256 _id) internal {
        position.burn(_id);
    }

    /**
     * @dev Mint tokens for an account
     * @param _token token address
     * @param _to account address
     * @param _amount amount to mint
     */
    function _handleTokenMint(address _token, address _to, uint256 _amount) internal {
        IStable(_token).mintFor(_to, _amount);
    }

    /**
     * @dev Burn tokens from an account
     * @param _token token address
     * @param _from account address
     * @param _amount amount to burn
     */
    function _handleTokenBurn(address _token, address _from, uint256 _amount) internal {
        IStable(_token).burnFrom(_from, _amount);
    }

    /**
     * @dev Get the token balance of an account
     * @param _token token address
     * @param _account account address
     */
    function _getTokenBalance(address _token, address _account) internal view returns (uint256) {
        return IERC20(_token).balanceOf(_account);
    }

    /**
     * @dev Get the trade data from the position contract
     * @param _id position id
     */
    function _getTrade(uint256 _id) internal view returns (IPosition.Trade memory) {
        return position.trades(_id);
    }

    /**
     * @dev Get the tigAsset address from a stableVault address, which should have the minter role for the tigAsset
     * @param _stableVault stableVault address
     */
    function _getStable(address _stableVault) internal view returns (address) {
        return IStableVault(_stableVault).stable();
    }

    /**
     * @dev Get the pair data from the pairs contract
     * @param _asset pair index
     */
    function _getAsset(uint256 _asset) internal view returns (IPairsContract.Asset memory) {
        return pairsContract.idToAsset(_asset);
    }

    /**
     * @notice Check that sufficient time has passed between opening and closing
     * @dev This is to prevent profitable opening and closing in the same tx with two different prices in the "valid signature pool".
     * @param _id position id
     * @param _type true for opening, false for closing
     */
    function _checkDelay(uint256 _id, bool _type) internal {
        unchecked {
            Delay memory _delay = timeDelayPassed[_id];
            if (_delay.actionType == _type) {
                timeDelayPassed[_id].delay = block.timestamp + timeDelay;
            } else {
                if (block.timestamp < _delay.delay) revert WaitDelay();
                timeDelayPassed[_id].delay = block.timestamp + timeDelay;
                timeDelayPassed[_id].actionType = _type;
            }
        }
    }

    /**
     * @dev Check that the stableVault input is whitelisted and the margin asset is whitelisted in the vault
     * @param _stableVault StableVault address
     * @param _token Margin asset token address
     */
    function _checkVault(address _stableVault, address _token) internal view {
        if (!allowedVault[_stableVault]) revert NotVault();
        if (_token != _getStable(_stableVault) && !IStableVault(_stableVault).allowed(_token)) revert NotAllowedInVault();
    }

    /**
     * @dev Check that the trader has approved the proxy address to trade for it
     * @param _trader Trader address
     */
    function _validateProxy(address _trader) internal view {
        if (_trader != _msgSender()) {
            address _proxy = proxyApprovals[_trader];
            if (_proxy != _msgSender()) revert NotProxy();
        }
    }

    // ===== GOVERNANCE-ONLY =====

    /**
     * @dev Sets timestamp delay between opening and closing
     * @notice payable to reduce contract size, keep value as 0
     * @param _timeDelay delay amount
     */
    function setTimeDelay(
        uint256 _timeDelay
    )
        external payable
        onlyOwner
    {
        timeDelay = _timeDelay;
    }

    /**
     * @dev Whitelists a stableVault contract address
     * @param _stableVault StableVault address
     * @param _bool true if allowed
     */
    function setAllowedVault(
        address _stableVault,
        bool _bool
    )
        external payable
        onlyOwner
    {
        allowedVault[_stableVault] = _bool;
    }

    /**
     * @dev Sets max payout % compared to margin, minimum +500% PnL
     * @param _maxWinPercent payout %
     */
    function setMaxWinPercent(
        uint256 _maxWinPercent
    )
        external payable
        onlyOwner
    {
        unchecked {
            if (_maxWinPercent != 0 && _maxWinPercent < 6*DIVISION_CONSTANT) revert BadSetter();
        }
        maxWinPercent = _maxWinPercent;
    }

    /**
     * @dev Sets executable price range for limit orders
     * @param _range price range in %
     */
    function setLimitOrderPriceRange(uint256 _range) external payable onlyOwner {
        if (_range > DIVISION_CONSTANT) revert BadSetter();
        limitOrderPriceRange = _range;
    }

    /**
     * @dev Sets the percent of fees being distributed to LPs
     * @param _percent Percent 1e10 precision
     */
    function setLPDistribution(uint256 _percent) external payable onlyOwner {
        if (_percent > DIVISION_CONSTANT) revert BadSetter();
        lpDistribution = _percent;
    }

    /**
     * @dev Sets the min pnl difference to set SL
     * @param _percent Percent 1e10 precision
     */
    function setMinSlPnlDif(uint256 _percent) external payable onlyOwner {
        if (_percent > DIVISION_CONSTANT) revert BadSetter();
        minSlPnlDif = _percent;
    }

    /**
     * @dev Sets the fees for the trading protocol
     * @param _open True if open fees are being set
     * @param _daoFees Fees distributed to the DAO
     * @param _burnFees Fees which get burned
     * @param _refDiscount Discount given to referred traders
     * @param _botFees Fees given to bots that execute limit orders
     * @param _percent Percent of earned funding fees going to StableVault
     */
    function setFees(bool _open, uint256 _daoFees, uint256 _burnFees, uint256 _refDiscount, uint256 _botFees, uint256 _percent) external payable onlyOwner {
        if (_open) {
            openFees.daoFees = _daoFees;
            openFees.burnFees = _burnFees;
            openFees.refDiscount = _refDiscount;
            openFees.botFees = _botFees;
        } else {
            closeFees.daoFees = _daoFees;
            closeFees.burnFees = _burnFees;
            closeFees.refDiscount = _refDiscount;
            closeFees.botFees = _botFees;
        }
        if (_percent > DIVISION_CONSTANT) revert BadSetter();
        vaultFundingPercent = _percent;
    }

    /**
     * @dev Sets the keeper fee for a tigAsset
     * @param _tigAsset tigAsset address
     * @param _fee fee amount
     */
    function setKeeperFee(address _tigAsset, uint256 _fee) external payable onlyOwner {
        keeperFee[_tigAsset] = _fee;
    }

    /**
     * @dev Sets the extension contract address for trading
     * @param _ext extension contract address
     */
    function setTradingExtension(
        address _ext
    ) external payable onlyOwner() {
        if (_ext == address(0)) revert BadSetter();
        tradingExtension = ITradingExtension(_ext);
    }

    /**
     * @dev Sets the LP staking contract
     * @param _lpstaking LP staking contract address
     */
    function setLPStaking(
        address _lpstaking
    ) external payable onlyOwner() {
        if (_lpstaking == address(0)) revert BadSetter();
        lpstaking = ILPStaking(_lpstaking);
    }

    /**
     * @dev Sets the pairs contract
     * @param _pairsContract pairs contract address
     */
    function setPairsContract(
        address _pairsContract
    ) external payable onlyOwner() {
        if (_pairsContract == address(0)) revert BadSetter();
        pairsContract = IPairsContract(_pairsContract);
    }

    /**
     * @dev Set if an order can be executed in the same timestamp as it was created
     * @param _allowed True if allowed
     */
    function setAllowSameBlockOrderConfirmation(
        bool _allowed
    ) external payable onlyOwner() {
        allowSameBlockOrderConfirmation = _allowed;
    }

    /**
     * @dev Get the lists of all pending orders
     */
    function getAllOrderIds() external view returns (uint256[] memory _marketOrders, uint256[] memory _addToPositionOrders) {
        return (pendingMarketOrdersList, pendingAddToPositionOrdersList);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaContext is Ownable {
    mapping(address => bool) private _isTrustedForwarder;

    function setTrustedForwarder(address _forwarder, bool _bool) external onlyOwner {
        _isTrustedForwarder[_forwarder] = _bool;
    }

    function isTrustedForwarder(address _forwarder) external view returns (bool) {
        return _isTrustedForwarder[_forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (_isTrustedForwarder[msg.sender]) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (_isTrustedForwarder[msg.sender]) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/ITrading.sol";

interface IPrice {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}

struct PriceData {
    address provider;
    bool isClosed;
    uint256 asset;
    uint256 price;
    uint256 spread;
    uint256 timestamp;
    bytes signature;
}

library TradingLibrary {

    using ECDSA for bytes32;

    uint256 constant DIVISION_CONSTANT = 1e10;
    uint256 constant CHAINLINK_PRECISION = 2e8;

    /**
    * @notice returns position profit or loss
    * @param _direction true if long
    * @param _currentPrice current price
    * @param _price opening price
    * @param _leverage position leverage
    * @param _margin collateral amount
    * @param accInterest funding fees
    * @return _positionSize position size
    * @return _payout payout trader should get
    */
    function pnl(bool _direction, uint256 _currentPrice, uint256 _price, uint256 _margin, uint256 _leverage, int256 accInterest) external pure returns (uint256 _positionSize, int256 _payout) {
        uint256 _initPositionSize = _margin * _leverage / 1e18;
        if (_direction && _currentPrice >= _price) {
            _payout = int256(_margin) + int256(_initPositionSize * (1e18 * _currentPrice / _price - 1e18)/1e18) + accInterest;
        } else if (_direction && _currentPrice < _price) {
            _payout = int256(_margin) - int256(_initPositionSize * (1e18 - 1e18 * _currentPrice / _price)/1e18) + accInterest;
        } else if (!_direction && _currentPrice <= _price) {
            _payout = int256(_margin) + int256(_initPositionSize * (1e18 - 1e18 * _currentPrice / _price)/1e18) + accInterest;
        } else {
            _payout = int256(_margin) - int256(_initPositionSize * (1e18 * _currentPrice / _price - 1e18)/1e18) + accInterest;
        }
        _positionSize = _direction ? _initPositionSize * _currentPrice / _price : _initPositionSize * _price / _currentPrice;
    }

    /**
    * @notice returns position liquidation price
    * @param _direction true if long
    * @param _tradePrice opening price
    * @param _leverage position leverage
    * @param _margin collateral amount
    * @param _accInterest funding fees
    * @param _liqPercent liquidation percent
    * @return _liqPrice liquidation price
    */
    function liqPrice(bool _direction, uint256 _tradePrice, uint256 _leverage, uint256 _margin, int256 _accInterest, uint256 _liqPercent) public pure returns (uint256 _liqPrice) {
        if (_direction) {
            _liqPrice = uint256(int256(_tradePrice) - int256(_tradePrice) * (int256(_margin) * int256(_liqPercent) / int256(DIVISION_CONSTANT) + _accInterest) * 1e18 / int256(_margin) / int256(_leverage));
        } else {
            _liqPrice = uint256(int256(_tradePrice) + int256(_tradePrice) * (int256(_margin) * int256(_liqPercent) / int256(DIVISION_CONSTANT) + _accInterest) * 1e18 / int256(_margin) / int256(_leverage));
        }
    }

    /**
    * @notice uses liqPrice() and returns position liquidation price
    * @param _positions positions contract address
    * @param _id position id
    * @param _liqPercent liquidation percent
    */
    function getLiqPrice(address _positions, uint256 _id, uint256 _liqPercent) external view returns (uint256) {
        IPosition.Trade memory _trade = IPosition(_positions).trades(_id);
        return liqPrice(_trade.direction, _trade.price, _trade.leverage, _trade.margin, _trade.accInterest, _liqPercent);
    }

    /**
    * @notice verifies that price is signed by a whitelisted node
    * @param _validSignatureTimer seconds allowed before price is old
    * @param _asset position asset
    * @param _chainlinkEnabled is chainlink verification is on
    * @param _chainlinkFeed address of chainlink price feed
    * @param _priceData PriceData object
    * @param _isNode mapping of allowed nodes
    */
    function verifyPrice(
        uint256 _validSignatureTimer,
        uint256 _asset,
        bool _chainlinkEnabled,
        address _chainlinkFeed,
        PriceData calldata _priceData,
        mapping(address => bool) storage _isNode
    )
        external view
    {
        address _provider = (
            keccak256(abi.encode(
                _priceData.provider,
                _priceData.isClosed,
                _priceData.asset,
                _priceData.price,
                _priceData.spread,
                _priceData.timestamp
            ))
        ).toEthSignedMessageHash().recover(_priceData.signature);
        require(_provider == _priceData.provider, "BadSig");
        require(_isNode[_provider], "!Node");
        require(_asset == _priceData.asset, "!Asset");
        require(!_priceData.isClosed, "Closed");
        require(block.timestamp >= _priceData.timestamp, "FutSig");
        require(block.timestamp <= _priceData.timestamp + _validSignatureTimer, "ExpSig");
        require(_priceData.price > 0, "NoPrice");
        if (_chainlinkEnabled && _chainlinkFeed != address(0)) {
            (uint80 roundId, int256 assetChainlinkPriceInt, , uint256 updatedAt, uint80 answeredInRound) = IPrice(_chainlinkFeed).latestRoundData();
            if (answeredInRound >= roundId && updatedAt > 0 && assetChainlinkPriceInt != 0) {
                uint256 assetChainlinkPrice = uint256(assetChainlinkPriceInt) * 10**(18 - IPrice(_chainlinkFeed).decimals());
                require(
                    _priceData.price < assetChainlinkPrice+assetChainlinkPrice*CHAINLINK_PRECISION/DIVISION_CONSTANT , "!chainlinkPrice"
                );
                require(
                    _priceData.price > assetChainlinkPrice-assetChainlinkPrice*CHAINLINK_PRECISION/DIVISION_CONSTANT, "!chainlinkPrice"
                );
            }
        }
    }

    /**
     * @dev Removes an element from a storage array and index mapping
     * @param _id element to remove
     * @param array storage array
     * @param indexes index mapping
     */
    function removeFromStorageArray(
        uint256 _id,
        uint256[] storage array,
        mapping(uint256 => uint256) storage indexes
    ) external {
        indexes[array[array.length-1]] = indexes[_id];
        array[indexes[_id]] = array[array.length-1];
        delete indexes[_id];
        array.pop();
    }

    //    function getAllOrdersData(
    //        mapping(uint256 => ITrading.PendingMarketOrderData) storage pendingMarketOrders,
    //        mapping(uint256 => ITrading.PendingAddToPositionOrderData) storage pendingAddToPositionOrders,
    //        uint256[] storage pendingMarketOrdersList,
    //        uint256[] storage pendingAddToPositionOrdersList
    //    ) external view returns (ITrading.PendingMarketOrderData[] memory, ITrading.PendingAddToPositionOrderData[] memory) {
    //        ITrading.PendingMarketOrderData[] memory _marketOrders = new ITrading.PendingMarketOrderData[](pendingMarketOrdersList.length);
    //        ITrading.PendingAddToPositionOrderData[] memory _addToPositionOrders = new ITrading.PendingAddToPositionOrderData[](pendingAddToPositionOrdersList.length);
    //        for (uint256 i = 0; i < pendingMarketOrdersList.length; i++) {
    //            _marketOrders[i] = pendingMarketOrders[pendingMarketOrdersList[i]];
    //        }
    //        for (uint256 i = 0; i < pendingAddToPositionOrdersList.length; i++) {
    //        _addToPositionOrders[i] = pendingAddToPositionOrders[pendingAddToPositionOrdersList[i]];
    //        }
    //        return (_marketOrders, _addToPositionOrders);
    //    }
}