// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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

// SPDX-License-Identifier: Apache-2.0
 pragma solidity ^0.8.24;

interface ICCTPTokenMessenger {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce);

    function depositForBurnWithCaller(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller
    ) external returns (uint64 nonce);

    function replaceDepositForBurn(
        bytes calldata originalMessage,
        bytes calldata originalAttestation,
        bytes32 newDestinationCaller,
        bytes32 newMintRecipient
    ) external;

    function handleReceiveMessage(
        uint32 remoteDomain,
        bytes32 sender,
        bytes calldata messageBody
    ) external returns (bool);

    function addRemoteTokenMessenger(uint32 domain, bytes32 tokenMessenger) external;

    function removeRemoteTokenMessenger(uint32 domain) external;

    function addLocalMinter(address newLocalMinter) external;

    function removeLocalMinter() external;

    function localMessageTransmitter() external view returns (address);

    function messageBodyVersion() external view returns (uint32);

    function localMinter() external view returns (address);

    function remoteTokenMessengers(uint32 domain) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address guy, uint wad) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin//contracts/token/ERC20/IERC20.sol";

library SafeAmount {
    using SafeERC20 for IERC20;

    /**
     @notice transfer tokens from. Incorporate fee on transfer tokens
     @param token The token
     @param from From address
     @param to To address
     @param amount The amount
     @return result The actual amount transferred
     */
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount) internal returns (uint256 result) {
        uint256 preBalance = IERC20(token).balanceOf(to);
        IERC20(token).safeTransferFrom(from, to, amount);
        uint256 postBalance = IERC20(token).balanceOf(to);
        result = postBalance - preBalance;
        require(result <= amount, "SA: actual amount larger than transfer amount");
    }

    /**
     @notice Sends ETH
     @param to The to address
     @param value The amount
     */
	function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 @dev Make sure to define method signatures
 */
abstract contract SigCheckable is EIP712 {

    function signerUnique(
        bytes32 message,
        bytes memory signature) internal view returns (address _signer) {
        bytes32 digest;
        (digest, _signer) = signer(message, signature);
    }

    /*
        @dev example message;

        bytes32 constant METHOD_SIG =
            keccak256("WithdrawSigned(address token,address payee,uint256 amount,bytes32 salt)");
        bytes32 message = keccak256(abi.encode(
          METHOD_SIG,
          token,
          payee,
          amount,
          salt
    */
    function signer(
        bytes32 message,
        bytes memory signature) internal view returns (bytes32 digest, address _signer) {
        digest = _hashTypedDataV4(message);
        _signer = ECDSA.recover(digest, signature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @notice Library for handling safe token transactions including fee per transaction tokens.
 */
abstract contract TokenReceivable is ReentrancyGuard {
  using SafeERC20 for IERC20;
  mapping(address => uint256) public inventory; // Amount of received tokens that are accounted for

  /**
   @notice Sync the inventory of a token based on amount changed
   @param token The token address
   @return amount The changed amount
   */
  function sync(address token) internal nonReentrant returns (uint256 amount) {
    uint256 inv = inventory[token];
    uint256 balance = IERC20(token).balanceOf(address(this));
    amount = balance - inv;
    inventory[token] = balance;
  }

  /**
   @notice Safely sends a token out and updates the inventory
   @param token The token address
   @param payee The payee
   @param amount The amount
   */
  function sendToken(address token, address payee, uint256 amount) internal nonReentrant {
    inventory[token] = inventory[token] - amount;
    IERC20(token).safeTransfer(payee, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/access/Ownable.sol";

contract WithAdmin is Ownable {
	address public admin;
	event AdminSet(address admin);

	function setAdmin(address _admin) external onlyOwner {
		admin = _admin;
		emit AdminSet(_admin);
	}

	modifier onlyAdmin() {
		require(msg.sender == admin || msg.sender == owner(), "WA: not admin");
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../common/signature/SigCheckable.sol";
import "../common/WithAdmin.sol";
import "../common/SafeAmount.sol";
import "../common/cctp/ICCTPTokenMessenger.sol";

contract CCTPFundManager is SigCheckable, WithAdmin {
    using SafeERC20 for IERC20;
    address public usdcToken;
    address public cctpTokenMessenger;
    address public fiberRouter;
    uint32 constant WEEK = 3600 * 24 * 7;
    string public constant NAME = "FUND_MANAGER";
    string public constant VERSION = "000.004";
    mapping(address => bool) public signers;
    mapping(bytes32 => bool) public usedSalt;
    mapping(uint256 => TargetNetwork) public targetNetworks;

    bytes32 constant WITHDRAW_SIGNED_METHOD =
        keccak256(
            "WithdrawSigned(address token,address payee,uint256 amount,bytes32 salt,uint256 expiry)"
        );
    bytes32 constant WITHDRAW_SIGNED_WITH_SWAP_METHOD =
        keccak256(
            "withdrawSignedAndSwapRouter(address to,uint256 amountIn,uint256 minAmountOut,address foundryToken,address targetToken,address router,bytes32 salt,uint256 expiry)"
        );

    struct TargetNetwork {
        uint32 targetNetworkDomain;
        address targetCCTPFundManager;
    }

    event TransferBySignature(
        address signer,
        address receiver,
        address token,
        uint256 amount
    );

    /**
     * @dev Modifier that allows only the designated fiberRouter to execute the function.
     * It checks if the sender is equal to the `fiberRouter` address.
     * @notice Ensure that `fiberRouter` is set before using this modifier.
     */
    modifier onlyRouter() {
        require(msg.sender == fiberRouter, "FM: Only fiberRouter method");
        _;
    }

    /**
     * @dev Contract constructor that initializes the EIP-712 domain with the specified NAME, VERSION.
     * @notice This constructor is called only once during the deployment of the contract.
     */
    constructor() EIP712(NAME, VERSION) {
        // bytes memory initData = IFerrumDeployer(msg.sender).initData();
    }

    /**
     @dev sets the fiberRouter
     @param _fiberRouter is the FiberRouter address
     */
    function setRouter(address _fiberRouter) external onlyOwner {
        require(_fiberRouter != address(0), "FM: fiberRouter requried");
        fiberRouter = _fiberRouter;
    }

    /**
     @dev sets the signer
     @param _signer is the address that generate signatures
     */
    function addSigner(address _signer) public onlyOwner {
        require(_signer != address(0), "Bad signer");
        signers[_signer] = true;
    }

    /**
     @dev removes the signer
     @param _signer is the address that generate signatures
     */
    function removeSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Bad signer");
        delete signers[_signer];
    }

    /**
     * @notice Initializes the Cross-Chain Transfer Protocol (CCTP) parameters.
     * @dev This function should be called by the contract owner to set the necessary parameters for CCTP.
     * @param _cctpTokenMessenger The address of the CCTP Token Messenger contract.
     * @param _usdcToken The address of the USDC token contract.
     **/
    function initCCTP(
        address _cctpTokenMessenger,
        address _usdcToken
    ) external onlyOwner {
        require(_cctpTokenMessenger != address(0), "FR: Invalid CCTP Token Messenger address");
        require(_usdcToken != address(0), "FR: Invalid USDC Token address");

        cctpTokenMessenger = _cctpTokenMessenger;
        usdcToken = _usdcToken;
    }

    /**
     * @notice Add a new target CCTP network.
     * @param _chainID The target network chain ID
     * @param _targetNetworkDomain The domain of the target network.
     * @param _targetCCTPFundManager The fund manager address for the target network.
     */
    function setTargetCCTPNetwork(uint256 _chainID, uint32 _targetNetworkDomain, address _targetCCTPFundManager) external onlyOwner {
        require(_targetNetworkDomain != 0, "FR: Invalid Target Network Domain");
        require(_chainID != 0, "FR: Invalid Target Network ChainID");
        require(_targetCCTPFundManager != address(0), "FR: Invalid Target CCTP Fund Manager address");

        targetNetworks[_chainID] = TargetNetwork(_targetNetworkDomain, _targetCCTPFundManager);
    }

    /**
     * @dev Initiates a signed token withdrawal, exclusive to the router
     * @notice Ensure valid parameters and router setup
     * @param token The token to withdraw
     * @param payee Address for where to send the tokens to
     * @param amount The amount
     * @param salt The salt for unique tx
     * @param expiry The expiration time for the signature
     * @param signature The multisig validator signature
     * @return The actual amount of tokens withdrawn
     */
    function withdrawSigned(
        address token,
        address payee,
        uint256 amount,
        bytes32 salt,
        uint256 expiry,
        bytes memory signature
    ) external onlyRouter returns (uint256) {
        require(token != address(0), "FM: bad token");
        require(payee != address(0), "FM: bad payee");
        require(salt != 0, "FM: bad salt");
        require(amount != 0, "FM: bad amount");
        require(block.timestamp < expiry, "FM: signature timed out");
        require(expiry < block.timestamp + WEEK, "FM: expiry too far");
        bytes32 message =  keccak256(
                abi.encode(WITHDRAW_SIGNED_METHOD, token, payee, amount, salt, expiry)
            );
        address _signer = signerUnique(message, signature);

        require(signers[_signer], "FM: Invalid signer");
        require(!usedSalt[salt], "FM: salt already used");
        usedSalt[salt] = true;
        // transfer the tokens to the receiver
        IERC20(token).safeTransfer(payee, amount);
        emit TransferBySignature(_signer, payee, token, amount);
        return amount;
    }

    /**
     * @dev Initiates a signed token withdrawal with swap, exclusive to the router
     * @notice Ensure valid parameters and router setup
     * @param to The address to withdraw to
     * @param amountIn The amount to be swapped in
     * @param minAmountOut The minimum amount out from the swap
     * @param foundryToken The token used in the Foundry
     * @param targetToken The target token for the swap
     * @param router The router address
     * @param salt The salt value for the signature
     * @param expiry The expiration time for the signature
     * @param signature The multi-signature data
     * @return The actual amount of tokens withdrawn from Foundry
     */
    function withdrawSignedAndSwapRouter(
        address to,
        uint256 amountIn,
        uint256 minAmountOut,
        address foundryToken,
        address targetToken,
        address router,
        bytes32 salt,
        uint256 expiry,
        bytes memory signature
    ) external onlyRouter returns (uint256) {
        require(targetToken != address(0), "FM: bad token");
        require(foundryToken != address(0), "FM: bad token");
        require(to != address(0), "FM: bad payee");
        require(salt != 0, "FM: bad salt");
        require(amountIn != 0, "FM: bad amount");
        require(minAmountOut != 0, "FM: bad amount");
        require(block.timestamp < expiry, "FM: signature timed out");
        require(expiry < block.timestamp + WEEK, "FM: expiry too far");

        bytes32 message =  keccak256(
                abi.encode(
                    WITHDRAW_SIGNED_WITH_SWAP_METHOD,
                    to,
                    amountIn,
                    minAmountOut,
                    foundryToken,
                    targetToken,
                    router,
                    salt,
                    expiry
                )
            );
        address _signer = signerUnique(message, signature);
        require(signers[_signer], "FM: Invalid signer");
        require(!usedSalt[salt], "FM: salt already used");
        usedSalt[salt] = true;
         // transfer the tokens to the receiver
        IERC20(foundryToken).safeTransfer(msg.sender, amountIn);
        emit TransferBySignature(_signer, msg.sender, foundryToken, amountIn);
        return amountIn;
    }

    /**
     * @dev Verifies details of a signed token withdrawal without executing the withdrawal
     * @param token Token address for withdrawal
     * @param payee Intended recipient address
     * @param amount Amount of tokens to be withdrawn
     * @param salt Unique identifier to prevent replay attacks
     * @param expiry Expiration timestamp of the withdrawal signature
     * @param signature Cryptographic signature for verification
     * @return Digest and signer's address from the provided signature
     */
    function withdrawSignedVerify(
        address token,
        address payee,
        uint256 amount,
        bytes32 salt,
        uint256 expiry,
        bytes calldata signature
    ) external view returns (bytes32, address) {
        bytes32 message = keccak256(
                abi.encode(WITHDRAW_SIGNED_METHOD, token, payee, amount, salt, expiry)
            );
        (bytes32 digest, address _signer) = signer(message, signature);
        return (digest, _signer);
    }

    /**
     * @dev Verifies details of a signed token swap withdrawal without execution
     * @param to Recipient address on the target network
     * @param amountIn Tokens withdrawn from Foundry
     * @param minAmountOut The minimum tokens on the target network
     * @param foundryToken Token withdrawn from Foundry
     * @param targetToken Token on the target network
     * @param router The router address
     * @param salt Unique identifier to prevent replay attacks
     * @param expiry Expiration timestamp of the withdrawal signature
     * @param signature Cryptographic signature for verification
     * @return Digest and signer's address from the provided signature
     */
    function withdrawSignedAndSwapRouterVerify(
        address to,
        uint256 amountIn,
        uint256 minAmountOut,
        address foundryToken,
        address targetToken,
        address router,
        bytes32 salt,
        uint256 expiry,
        bytes calldata signature
    ) external view returns (bytes32, address) {
        bytes32 message =  keccak256(
                abi.encode(
                    WITHDRAW_SIGNED_WITH_SWAP_METHOD,
                    to,
                    amountIn,
                    minAmountOut,
                    foundryToken,
                    targetToken,
                    router,
                    salt,
                    expiry
                )
            );
        (bytes32 digest, address _signer) = signer(message, signature);
        return (digest, _signer);
    }

    /**
     * @notice Initiates a Cross-Chain Transfer Protocol (CCTP) swap.
     * @dev This function handles the process of approving tokens and initiating a cross-chain token burn and deposit.
     * @param amountIn The amount of tokens to be swapped.
     * @param token The address of the token to be swapped (must be USDC).
     * @param targetNetwork The identifier of the target network for the swap.
     * @return depositNonce The nonce associated with the deposit for burn transaction.
     */
    function swapCCTP(uint256 amountIn, address token, uint256 targetNetwork) external onlyRouter returns (uint64 depositNonce){
        TargetNetwork memory target = targetNetworks[targetNetwork];
        require(target.targetNetworkDomain != 0, "FR: Target network not found");
        require(target.targetCCTPFundManager != address(0), "FR: Target CCTP FundManager address not found");
        require(token == usdcToken, "FR: Invalid token");

        require(IERC20(token).approve(cctpTokenMessenger, amountIn), "Approval failed");

        depositNonce = ICCTPTokenMessenger(cctpTokenMessenger).depositForBurn(
            amountIn,
            target.targetNetworkDomain,
            addressToBytes32(target.targetCCTPFundManager),
            usdcToken
        );
    }     

    /**
     * @notice Converts an Ethereum address to a bytes32 representation.
     * @dev This is useful for interacting with contracts or protocols that require addresses in bytes32 format.
     * @param addr The address to be converted.
     * @return The bytes32 representation of the given address.
     */
    function addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeDistributor is EIP712, Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    string public constant NAME = "FEE_DISTRIBUTOR";
    string public constant VERSION = "000.001";
    uint32 constant MINUTE = 60;
    address public feeWallet;
    uint256 public platformFee; // Platform fee as a fixed amount 

    mapping(address => bool) public signers;
    mapping(bytes32 => bool) public usedSalt;

    bytes32 constant DISTRIBUTE_FEES_TYPEHASH = keccak256(
        "DistributeFees(address token,address referral,uint256 referralFee,uint256 referralDiscount,uint256 sourceAmountIn,uint256 sourceAmountOut,uint256 destinationAmountIn,uint256 destinationAmountOut,bytes32 salt,uint256 expiry)"
    );

    struct FeeDistributionData {
        address referral;
        uint256 referralFee; // Referral fee as a percentage
        uint256 referralDiscount; // Referral discount as a percentage
        uint256 sourceAmountIn;
        uint256 sourceAmountOut;
        uint256 destinationAmountIn;
        uint256 destinationAmountOut;
        bytes32 salt;
        uint256 expiry;
        bytes signature;
    }

    event FeesDistributed(
        address indexed token,
        uint256 preFeeAmount,
        uint256 afterFeeAmount,
        uint256 totalPlatformFee
    );

    constructor() EIP712(NAME, VERSION) {}

    /**
     @dev sets the signer
     @param _signer is the address that generates signatures
     */
    function addSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "FD: Bad signer");
        signers[_signer] = true;
    }

    /**
     @dev removes the signer
     @param _signer is the address that generates signatures
     */
    function removeSigner(address _signer) external onlyOwner {
        delete signers[_signer];
    }

    /**
     @dev sets the fee wallet
     @param _feeWallet is the new fee wallet address
     */
    function setFeeWallet(address _feeWallet) external onlyOwner {
        require(_feeWallet != address(0), "FD: Bad fee wallet address");
        feeWallet = _feeWallet;
    }

    /**
     @dev sets the platform fee
     @param _platformFee is the new platform fee as a percentage
     */
    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee > 0, "FD: Platform fee must be greater than zero");
        platformFee = _platformFee;
    }

    function _distributeFees(
        address token,
        uint256 preFeeAmount,
        FeeDistributionData memory fdd
    ) internal returns (uint256) {
        require(_verify(token, fdd), "FD: Invalid signature");

        uint256 totalAmount = preFeeAmount;
        uint256 remainingAmount = totalAmount - platformFee;
        uint256 referralDiscountAmount = 0;
        uint256 referralFeeAmount = 0;
        uint256 feeWalletShare = platformFee;

        // If referral is provided, calculate the referral discount and referral fee
        if (fdd.referral != address(0)) {
            if (fdd.referralDiscount > 0) {
                referralDiscountAmount = (platformFee * fdd.referralDiscount) / 100;
                feeWalletShare -= referralDiscountAmount;
                remainingAmount += referralDiscountAmount;
            }

            if (fdd.referralFee > 0) {
                referralFeeAmount = (feeWalletShare * fdd.referralFee) / 100;
                feeWalletShare -= referralFeeAmount;
                IERC20(token).safeTransfer(fdd.referral, referralFeeAmount);
            }
        }

        // Ensure the total allocated fee does not exceed the platform fee
        require(feeWalletShare + referralFeeAmount + referralDiscountAmount <= platformFee, "FD: Total fee exceeds platform fee");

        // Transfer the remaining fee to the fee wallet
        IERC20(token).safeTransfer(feeWallet, feeWalletShare);

        emit FeesDistributed(token, preFeeAmount, remainingAmount, platformFee);

        return remainingAmount;
    }



    function _verify(
        address token,
        FeeDistributionData memory fdd
    ) private returns (bool) {
        require(block.timestamp < fdd.expiry, "FD: Signature timed out");
        require(fdd.expiry < block.timestamp + (20 * MINUTE), "FD: Expiry too far"); // 20 minutes probably too generous. Users should be submitting tx soon after quote on source chain
        require(!usedSalt[fdd.salt], "FM: Salt already used");
        usedSalt[fdd.salt] = true;

        bytes32 structHash = keccak256(
            abi.encode(
                DISTRIBUTE_FEES_TYPEHASH,
                token,
                fdd.referral,
                fdd.referralFee,
                fdd.referralDiscount,
                fdd.sourceAmountIn,
                fdd.sourceAmountOut,
                fdd.destinationAmountIn,
                fdd.destinationAmountOut,
                fdd.salt,
                fdd.expiry
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, fdd.signature);
        return signers[signer];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/tokenReceiveable.sol";
import "../common/SafeAmount.sol";
import "../common/IWETH.sol";
import "./FundManager.sol";
import "./CCTPFundManager.sol";
import "./FeeDistributor.sol";

/**
 @author The ferrum network.
 @title This is a routing contract named as FiberRouter.
*/
contract FiberRouter is Ownable, TokenReceivable, FeeDistributor {
    using SafeERC20 for IERC20;
    address private constant NATIVE_CURRENCY = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public weth;
    address public fundManager;
    address public cctpFundManager;
    address payable public gasWallet;
    mapping(bytes32 => bool) private routerAllowList;
    mapping(uint256 => TargetNetwork) public targetNetworks;

    struct SwapCrossData {
        uint256 targetNetwork;
        address targetToken;
        address targetAddress;
    }

    struct TargetNetwork {
        uint32 targetNetworkDomain;
        address targetFundManager;
    }

    event Swap(
        address sourceToken,
        address targetToken,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 sourceAmount,
        address sourceAddress,
        address targetAddress,
        uint256 settledAmount,
        bytes32 withdrawalData,
        uint256 gasAmount,
        uint256 depositNonce
    );

    event SwapSameNetwork(
        address sourceToken,
        address targetToken,
        uint256 sourceAmount,
        uint256 settledAmount,
        address sourceAddress,
        address targetAddress
    );
    event Withdraw(
        address token,
        address receiver,
        uint256 amount,
        bytes32 salt,
        bytes signature
    );

    event WithdrawRouter(
        address to,
        uint256 amountIn,
        uint256 amountOut,
        address foundryToken,
        address targetToken,
        address router,
        bytes routerCalldata,
        bytes32 salt,
        bytes multiSignature
    );

    event RouterAndSelectorWhitelisted(address router, bytes4 selector);
    event RouterAndSelectorRemoved(address router, bytes selector);

    /**
     * @notice Set the weth address
     * @param _weth The weth address
     */
    function setWeth(address _weth) external onlyOwner {
        require(_weth != address(0), "weth address cannot be zero");
        weth = _weth;
    }

    /**
     * @dev Sets the fund manager contract.
     * @param _fundManager The fund manager
     */
    function setFundManager(address _fundManager) external onlyOwner {
        require(_fundManager != address(0), "Swap pool address cannot be zero");
        fundManager = _fundManager;
    }

    /**
     * @dev Sets the fund manager contract.
     * @param _cctpFundManager The fund manager
     */
    function setCCTPFundManager(address _cctpFundManager) external onlyOwner {
        require(_cctpFundManager != address(0), "Swap pool address cannot be zero");
        cctpFundManager = _cctpFundManager;
    }

    /**
     * @dev Sets the gas wallet address.
     * @param _gasWallet The wallet which pays for the funds on withdrawal
     */
    function setGasWallet(address payable _gasWallet) external onlyOwner {
        require(
            _gasWallet != address(0),
            "FR: Gas Wallet address cannot be zero"
        );
        gasWallet = _gasWallet;
    }

    /**
     * @notice Whitelists the router and selector combination
     * @param router The router address
     * @param selectors The selectors for the router
     */
    function addRouterAndSelectors(address router, bytes4[] memory selectors) external onlyOwner {
        for (uint256 i = 0; i < selectors.length; i++) {
            routerAllowList[_getKey(router, abi.encodePacked(selectors[i]))] = true;
            emit RouterAndSelectorWhitelisted(router, selectors[i]);
        }
    }

    /**
     * @notice Removes the router and selector combination from the whitelist
     * @param router The router address
     * @param selector The selector for the router
     */
    function removeRouterAndSelector(address router, bytes calldata selector) external onlyOwner {
        routerAllowList[_getKey(router, selector)] = false;
        emit RouterAndSelectorRemoved(router, selector);
    }

    /**
     * @dev Perform a same network token swap on specified router/dex
     * @param amountIn The input amount
     * @param minAmountOut The minimum amount out accounting for slippage
     * @param fromToken The token to be swapped
     * @param toToken The token to receive after the swap
     * @param targetAddress The receiver address
     * @param router The router address
     * @param routerCalldata Calldata for the router
     */
    function swapOnSameNetwork(
        uint256 amountIn,
        uint256 minAmountOut,
        address fromToken,
        address toToken,
        address targetAddress,
        address router,
        bytes memory routerCalldata
    ) external nonReentrant {
        // Validation checks
        require(fromToken != address(0), "FR: From token address cannot be zero");
        require(toToken != address(0), "FR: To token address cannot be zero");
        require(amountIn != 0, "FR: Amount in must be greater than zero");
        require(minAmountOut != 0, "FR: Amount out must be greater than zero");
        require(targetAddress != address(0), "FR: Target address cannot be zero");

        amountIn = SafeAmount.safeTransferFrom(fromToken, _msgSender(), address(this), amountIn);

        // Perform the token swap
        uint256 amountOut = _swapAndCheckSlippage(
            targetAddress,
            fromToken,
            toToken,
            amountIn,
            minAmountOut,
            router,
            routerCalldata
        );

        // Emit Swap event
        emit SwapSameNetwork(
            fromToken,
            toToken,
            amountIn,
            amountOut,
            _msgSender(),
            targetAddress
        );
    }

    /**
     * @dev Performs a swap from native currency to specified token
     * @param minAmountOut The minimum amount of tokens expected after the swap
     * @param toToken The token to receive after the swap
     * @param targetAddress The receiver address for the token
     * @param router The router address
     * @param routerCalldata Calldata for the router
     */
    function swapOnSameNetworkETH(
        uint256 minAmountOut,
        address toToken,
        address targetAddress,
        address router,
        bytes memory routerCalldata
    ) external payable {
        uint256 amountIn = msg.value;
        // Validation checks
        require(toToken != address(0), "FR: To token address cannot be zero");
        require(amountIn != 0, "FR: Amount in must be greater than zero");
        require(minAmountOut != 0, "FR: Amount out must be greater than zero");
        require(targetAddress != address(0), "FR: Target address cannot be zero");
        require(bytes(routerCalldata).length != 0, "FR: Calldata cannot be empty");

        // Deposit ETH and get WETH
        IWETH(weth).deposit{value: amountIn}();

        uint256 amountOut = _swapAndCheckSlippage(
            targetAddress,
            weth,
            toToken,
            amountIn,
            minAmountOut,
            router,
            routerCalldata
        );

        // Emit Swap event
        emit SwapSameNetwork(
            NATIVE_CURRENCY,
            toToken,
            amountIn,
            amountOut,
            _msgSender(),
            targetAddress
        );
    }

    /**
     * @dev Initiates a token swap.
     * @param token The token to be swapped.
     * @param amount The amount to be swapped.
     * @param withdrawalData Data related to the withdrawal.
     * @param cctpType Boolean indicating whether it's a CCTP swap.
     */
    function swapSigned(
        address token,
        uint256 amount,
        SwapCrossData memory sd,
        bytes32 withdrawalData,
        bool cctpType,
        FeeDistributionData memory fd
    ) external payable nonReentrant {
        // Validation checks
        require(token != address(0), "FR: Token address cannot be zero");
        require(sd.targetToken != address(0), "FR: Target token address cannot be zero");
        require(sd.targetNetwork != 0, "FR: Target network is required");
        require(sd.targetAddress != address(0), "FR: Target address cannot be zero");
        require(amount != 0, "FR: Amount must be greater than zero");
        require(withdrawalData != 0, "FR: Withdraw data cannot be empty");
        require(msg.value != 0, "FR: Gas Amount must be greater than zero");

        // Transfer tokens to FiberRouter
        amount = SafeAmount.safeTransferFrom(token, _msgSender(), address(this), amount);

        // Distribute the fees
        uint256 amountOut = _distributeFees(token, amount, fd);

        // Perform the token swap based on swapCCTP flag
        uint64 depositNonce;
        if (cctpType) {
            // Proceed with the CCTP swap logic
            SafeERC20.safeTransfer(IERC20(token), cctpFundManager, amountOut);
            depositNonce = CCTPFundManager(cctpFundManager).swapCCTP(amountOut, token, sd.targetNetwork);
        } else {
            // Proceed with the normal swap logic
            SafeERC20.safeTransfer(IERC20(token), fundManager, amountOut);
            FundManager(fundManager).swapToAddress(
                token,
                amount,
                sd.targetNetwork,
                sd.targetAddress
            );
        }

        // Transfer the gas fee to the gasWallet
        SafeAmount.safeTransferETH(gasWallet, msg.value);

        emit Swap(
            token,
            sd.targetToken,
            block.chainid,
            sd.targetNetwork,
            amount,
            _msgSender(),
            sd.targetAddress,
            amountOut,
            withdrawalData,
            msg.value,
            depositNonce // Stays zero for non-CCTP swaps
        );
    }

    /**
     * @dev Do a local swap and generate a cross-chain swap
     * @param amountIn The input amount
     * @param minAmountOut The minimum amount out after the swap
     * @param fromToken The token to be swapped
     * @param foundryToken The foundry token used for the swap
     * @param router The router address
     * @param routerCalldata The calldata for the swap
     * @param withdrawalData Data related to the withdrawal
     * @param cctpType Boolean indicating whether it's a CCTP swap.
     */
    function swapSignedAndCrossRouter(
        uint256 amountIn,
        uint256 minAmountOut,
        address fromToken,
        address foundryToken,
        address router,
        bytes memory routerCalldata,
        SwapCrossData memory sd,
        bytes32 withdrawalData,
        bool cctpType,
        FeeDistributionData memory fd
    ) external payable nonReentrant {
        require(amountIn != 0, "FR: Amount in must be greater than zero");
        require(fromToken != address(0), "FR: From token address cannot be zero");
        require(foundryToken != address(0), "FR: Foundry token address cannot be zero");
        require(sd.targetToken != address(0), "FR: Cross target token address cannot be zero");
        require(minAmountOut != 0, "FR: Amount out must be greater than zero");
        require(withdrawalData != 0, "FR: withdraw data cannot be empty");
        require(msg.value != 0, "FR: Gas Amount must be greater than zero");

        uint256 _amountIn = SafeAmount.safeTransferFrom(fromToken, _msgSender(), address(this), amountIn);
        
        // Swap and receive tokens back to FiberRouter
        uint256 amountOut = _swapAndCheckSlippage(
            address(this),
            fromToken,
            foundryToken,
            _amountIn,
            minAmountOut,
            router,
            routerCalldata
        );

        amountOut = _distributeFees(foundryToken, amountOut, fd);

        uint64 depositNonce;
        if (cctpType) {
            // Transfer to CCTP FundManager and initiate CCTP swap
            SafeERC20.safeTransfer(IERC20(foundryToken), cctpFundManager, amountOut);
            depositNonce = CCTPFundManager(cctpFundManager).swapCCTP(amountOut, foundryToken, sd.targetNetwork);
        } else {
            // Transfer to FundManager and update inventory
            SafeERC20.safeTransfer(IERC20(foundryToken), fundManager, amountOut);
            FundManager(fundManager).swapToAddress(
                foundryToken,
                amountOut,
                sd.targetNetwork,
                sd.targetAddress
            );
        }

        // Transfer the gas fee to the gasWallet
        SafeAmount.safeTransferETH(gasWallet, msg.value);

        emit Swap(
            fromToken,
            sd.targetToken,
            block.chainid,
            sd.targetNetwork,
            _amountIn,
            _msgSender(),
            sd.targetAddress,
            amountOut,
            withdrawalData,
            msg.value,
            depositNonce // Stays zero for non-CCTP swaps
        );    
    }

    /**
     * @dev Do a local swap with ETH as input and generate a cross-chain swap
     * @param minAmountOut The minimum amount out after the swap
     * @param foundryToken The foundry token used for the swap
     * @param gasFee The gas fee being charged on withdrawal
     * @param router The router address
     * @param routerCalldata The calldata for the swap
     * @param withdrawalData Data related to the withdrawal
     * @param cctpType Boolean indicating whether it's a CCTP swap.
     */
    function swapSignedAndCrossRouterETH(
        uint256 minAmountOut,
        address foundryToken,
        uint256 gasFee,
        address router,
        bytes memory routerCalldata,
        SwapCrossData memory sd,
        bytes32 withdrawalData,
        bool cctpType,
        FeeDistributionData memory fd
    ) external payable {
        require(msg.value - gasFee != 0, "FR: Amount in must be greater than zero"); // amountIn = msg.value - gasFee, but using directly here 
        require(gasFee != 0, "FR: Gas fee must be greater than zero");
        require(minAmountOut != 0, "FR: Amount out must be greater than zero");
        require(sd.targetToken != address(0), "FR: Cross target token address cannot be zero");
        require(foundryToken != address(0), "FR: Foundry token address cannot be zero");
        require(withdrawalData != 0, "FR: Withdraw data cannot be empty");

        // Deposit ETH (excluding gas fee) for WETH and swap
        IWETH(weth).deposit{value: msg.value - gasFee}();

        uint256 amountOut = _swapAndCheckSlippage(
            address(this),
            weth,
            foundryToken,
            msg.value - gasFee,
            minAmountOut,
            router,
            routerCalldata
        );

        amountOut = _distributeFees(foundryToken, amountOut, fd);

        uint64 depositNonce;
        if (cctpType) {
            // Transfer to CCTP FundManager and initiate CCTP swap
            SafeERC20.safeTransfer(IERC20(foundryToken), cctpFundManager, amountOut);
            depositNonce = CCTPFundManager(cctpFundManager).swapCCTP(amountOut, foundryToken, sd.targetNetwork);
        } else {
            // Transfer and update pool inventory
            SafeERC20.safeTransfer(IERC20(foundryToken), fundManager, amountOut);
            FundManager(fundManager).swapToAddress(
                foundryToken,
                amountOut,
                sd.targetNetwork,
                sd.targetAddress
            );
        }

        // Transfer the gas fee to the gasWallet
        (bool success, ) = payable(gasWallet).call{value: gasFee}("");
        require(success, "FR: Gas fee transfer failed");

        uint256 _gasFee = gasFee; // Stack too deep workaround
        emit Swap(
            weth,
            sd.targetToken,
            block.chainid,
            sd.targetNetwork,
            msg.value - _gasFee,
            _msgSender(),
            sd.targetAddress,
            amountOut,
            withdrawalData,
            _gasFee,
            depositNonce
        );    
    }

    /**
     * @dev Initiates a signed token withdrawal, exclusive to the router.
     * @notice Ensure valid parameters and router setup.
     * @param token The token to withdraw
     * @param payee Address for where to send the tokens to
     * @param amount The amount
     * @param salt The salt for unique tx 
     * @param expiry The expiration time for the signature
     * @param cctpType Type of withdrawal: true for CCTP, false for normal
     * @param multiSignature The multisig validator signature
     */
    function withdrawSigned(
        address token,
        address payee,
        uint256 amount,
        bytes32 salt,
        uint256 expiry,
        bytes memory multiSignature,
        bool cctpType
    ) public virtual nonReentrant {
        // Validate input parameters
        require(token != address(0), "FR: Token address cannot be zero");
        require(payee != address(0), "FR: Payee address cannot be zero");
        require(amount != 0, "FR: Amount must be greater than zero");
        require(salt > bytes32(0), "FR: Salt must be greater than zero bytes");

        address _pool = cctpType ? cctpFundManager : fundManager;

        amount = FundManager(_pool).withdrawSigned(
            token,
            payee,
            amount,
            salt,
            expiry,
            multiSignature
        );

        emit Withdraw(token, payee, amount, salt, multiSignature);
    }

    /**
     * @dev Initiates a signed token withdrawal with swap through router, exclusive to the router.
     * @notice Ensure valid parameters and router setup.
     * @param to The address to withdraw to
     * @param amountIn The amount to be swapped in
     * @param minAmountOut The minimum amount out after the swap
     * @param foundryToken The token used in the Foundry
     * @param targetToken The target token for the swap
     * @param router The router address
     * @param routerCalldata The calldata for the swap
     * @param salt The salt value for the signature
     * @param expiry The expiration time for the signature
     * @param cctpType Boolean indicating if swap to CCTP
     * @param multiSignature The multi-signature data
     */
    function withdrawSignedAndSwapRouter(
        address payable to,
        uint256 amountIn,
        uint256 minAmountOut,
        address foundryToken,
        address targetToken,
        address router,
        bytes memory routerCalldata,
        bytes32 salt,
        uint256 expiry,
        bytes memory multiSignature,
        bool cctpType
    ) public virtual nonReentrant {
        require(foundryToken != address(0), "Bad Token Address");
        require(targetToken != address(0), "FR: Target token address cannot be zero");
        require(amountIn != 0, "Amount in must be greater than zero");
        require(minAmountOut != 0, "Amount out minimum must be greater than zero");
        require(foundryToken != address(0), "Bad Token Address");

        address _pool = cctpType ? cctpFundManager : fundManager;
        
        amountIn = FundManager(_pool).withdrawSignedAndSwapRouter(
            to,
            amountIn,
            minAmountOut,
            foundryToken,
            targetToken,
            router,
            salt,
            expiry,
            multiSignature
        );

        uint256 amountOut = _swapAndCheckSlippage(
            to,
            foundryToken,
            targetToken,
            amountIn,
            minAmountOut,
            router,
            routerCalldata
        );

        emit WithdrawRouter(
            to,
            amountIn,
            amountOut,
            foundryToken,
            targetToken,
            router,
            routerCalldata,
            salt,
            multiSignature
        );
    }

    /**
     * @notice Checks if the router and selector combination is whitelisted
     * @param router The router address
     * @param selector The selector for the router
     */
    function isAllowListed(address router, bytes memory selector) public view returns (bool) {
        return routerAllowList[_getKey(router, selector)];
    }

    /**
     * @notice Helper function for executing token swaps through provided router
     * @param targetAddress The recipient address to receive the swapped tokens
     * @param fromToken The address of the input token for the swap
     * @param toToken The address of the output token from the swap
     * @param amountIn The exact amount of input tokens to be swapped
     * @param minAmountOut The minimum amount of output tokens expected after the swap
     * @param router The router address
     * @param data The calldata for the swap
     */
    function _swapAndCheckSlippage(
        address targetAddress,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 minAmountOut,
        address router,
        bytes memory data
    ) internal returns (uint256) {
        require(isAllowListed(router, data), "FR: Router and selector not whitelisted");
        _approveAggregatorRouter(fromToken, router, amountIn);
        uint256 balanceBefore = _getBalance(toToken, targetAddress);
        _makeRouterCall(router, data);
        uint256 amountOut = _getBalance(toToken, targetAddress) - balanceBefore;

        require(amountOut >= minAmountOut, "FR: Slippage check failed");
        // TODO for failed slippage checks: On-chain settlement. Option are:
        // 1/ Receive USDC on dst chain
        // 2/ ask user about updated quote
        // 3/ get funds back on src chain
        return amountOut;
    }

    function _getBalance(address token, address account) private view returns (uint256) {
        return token == NATIVE_CURRENCY ? account.balance : IERC20(token).balanceOf(account);
    }

    function _approveAggregatorRouter(address token, address router, uint256 amount) private {
        if (IERC20(token).allowance(address(this), router) != 0) {
            IERC20(token).safeApprove(router, 0);
        }
        IERC20(token).safeApprove(router, amount);
    }   

    function _getKey(address router, bytes memory data) private pure returns (bytes32) {
        bytes32 key; // Takes the shape of 0x{4byteFuncSelector}00..00{20byteRouterAddress}
        assembly {
            key := or(
                and(mload(add(data, 0x20)), 0xffffffff00000000000000000000000000000000000000000000000000000000),
                router
            )
        }
        return key;
    }

    function _makeRouterCall(address router, bytes memory data) private {
        (bool success, bytes memory returnData) = router.call(data);
        if (!success) {
            if (returnData.length > 0) { // Bubble up the revert reason
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(32, returnData), returnDataSize)
                }
            } else {
                revert("FR: Call to router failed");
            }
        }
    }

    function isCctp(uint256 cdPtr) public pure returns (bool cctp) {
        assembly {
            cctp := shr(252, calldataload(cdPtr))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../common/signature/SigCheckable.sol";
import "./LiquidityManagerRole.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FundManager is SigCheckable, LiquidityManagerRole {
    using SafeERC20 for IERC20;

    address public fiberRouter;
    address public settlementManager;
    uint32 constant WEEK = 3600 * 24 * 7;
    string public constant NAME = "FUND_MANAGER";
    string public constant VERSION = "000.004";
    bytes32 constant WITHDRAW_SIGNED_METHOD =
        keccak256(
            "WithdrawSigned(address token,address payee,uint256 amount,bytes32 salt,uint256 expiry)"
        );
    bytes32 constant WITHDRAW_SIGNED_WITH_SWAP_METHOD =
        keccak256(
            "withdrawSignedAndSwapRouter(address to,uint256 amountIn,uint256 minAmountOut,address foundryToken,address targetToken,address router,bytes32 salt,uint256 expiry)"
        );

    event TransferBySignature(
        address signer,
        address receiver,
        address token,
        uint256 amount
    );
    event FailedWithdrawalCancelled(
        address indexed settlementManager,
        address indexed receiver,
        address indexed token,
        uint256 amount,
        bytes32 salt
    );
    event BridgeLiquidityAdded(address actor, address token, uint256 amount);
    event BridgeLiquidityRemoved(address actor, address token, uint256 amount);
    event BridgeSwap(
        address from,
        address indexed token,
        uint256 targetNetwork,
        address targetToken,
        address targetAddrdess,
        uint256 amount
    );

    mapping(address => bool) public signers;
    mapping(address => mapping(address => uint256)) private liquidities;
    mapping(address => mapping(uint256 => address)) public allowedTargets;
    mapping(address => bool) public isFoundryAsset;
    mapping(bytes32=>bool) public usedSalt;

    /**
     * @dev Modifier that allows only the designated fiberRouter to execute the function.
     * It checks if the sender is equal to the `fiberRouter` address.
     * @notice Ensure that `fiberRouter` is set before using this modifier.
     */
    modifier onlyRouter() {
        require(msg.sender == fiberRouter, "FM: Only fiberRouter method");
        _;
    }

    /**
     * @dev Modifier that allows only the designated settlementManager to execute the function.
     * It checks if the sender is equal to the `settlementManager` address.
     * @notice Ensure that `settlementManager` is set before using this modifier.
     */
    modifier onlySettlementManager() {
        require(msg.sender == settlementManager, "FM: Only Settlement Manager");
        _;
    }

    /**
     * @dev Contract constructor that initializes the EIP-712 domain with the specified NAME, VERSION.
     * @notice This constructor is called only once during the deployment of the contract.
     */
    constructor() EIP712(NAME, VERSION) {}

    /**
     *************** Owner only operations ***************
     */

    /**
     * @dev Sets the address of settlement manager
     * @param _settlementManager The settlement manager address
     */
    function setSettlementManager(address _settlementManager) external onlyOwner {
        require(_settlementManager != address(0), "FM: Bad settlement manager");

        settlementManager = _settlementManager;
    }

    /**
     @dev sets the fiberRouter
     @param _fiberRouter is the FiberRouter address
     */
    function setRouter(address _fiberRouter) external onlyOwner {
        require(_fiberRouter != address(0), "FM: fiberRouter required");
        fiberRouter = _fiberRouter;
    }

    /**
     @dev sets the signer
     @param _signer is the address that generate signatures
     */
    function addSigner(address _signer) public onlyOwner {
        require(_signer != address(0), "Bad signer");
        signers[_signer] = true;
    }

    /**
     @dev removes the signer
     @param _signer is the address that generate signatures
     */
    function removeSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Bad signer");
        delete signers[_signer];
    }

    /**
     @dev sets the allowed target chain & token
     @param token is the address of foundry token on source network
     @param chainId target network's chain ID
     @param targetToken target network's foundry token address
     */
    function allowTarget(
        address token,
        uint256 chainId,
        address targetToken
    ) external onlyAdmin {
        require(token != address(0), "Bad token");
        require(targetToken != address(0), "Bad targetToken");
        require(chainId != 0, "Bad chainId");
        allowedTargets[token][chainId] = targetToken;
    }

    /**
     @dev removes the allowed target chain & token
     @param token is the address of foundry token on source network
     @param chainId target network's chain ID
     */
    function disallowTarget(address token, uint256 chainId) external onlyAdmin {
        require(token != address(0), "Bad token");
        require(chainId != 0, "Bad chainId");
        delete allowedTargets[token][chainId];
    }

    /**
     @dev sets the foundry token
     @param token is the foundry token address
     */
    function addFoundryAsset(address token) external onlyAdmin {
        require(token != address(0), "Bad token");
        isFoundryAsset[token] = true;
    }

    /**
     @dev removes the foundry token
     @param token is the foundry token address
     */
    function removeFoundryAsset(address token) external onlyAdmin {
        require(token != address(0), "Bad token");
        isFoundryAsset[token] = false;
    }

    /**
     * @dev Initiates an EVM token swap, exclusive to the router
     * @notice Ensure valid parameters and router setup
     * @param token The address of the token to be swapped
     * @param amount The amount of tokens to be swapped
     * @param targetNetwork The identifier of the target network for the swap
     * @param targetAddress The address on the target network where the swapped tokens will be sent
     * @return The actual amount of tokens swapped
    */
    function swapToAddress(
        address token,
        uint256 amount,
        uint256 targetNetwork,
        address targetAddress
    ) external onlyRouter returns(uint256) {
        address targetToken = allowedTargets[token][targetNetwork];
        require(token != address(0), "FM: bad token");
        require(targetNetwork != 0, "FM: targetNetwork is requried");
        require(targetToken != address(0), "FM: bad target token");
        require(targetAddress != address(0), "FM: targetAddress is required");
        require(amount != 0, "FM: bad amount");
        amount = TokenReceivable.sync(token);
        emit BridgeSwap(
            msg.sender,
            token,
            targetNetwork,
            targetToken,
            targetAddress,
            amount
        );
        return amount;
    }
 
    /**
     * @dev Initiates a signed token withdrawal, exclusive to the router
     * @notice Ensure valid parameters and router setup
     * @param token The token to withdraw
     * @param payee Address for where to send the tokens to
     * @param amount The amount
     * @param salt The salt for unique tx
     * @param expiry The expiration time for the signature
     * @param signature The multisig validator signature
     * @return The actual amount of tokens withdrawn
     */
    function withdrawSigned(
        address token,
        address payee,
        uint256 amount,
        bytes32 salt,
        uint256 expiry,
        bytes memory signature
    ) external onlyRouter returns (uint256) {
        require(token != address(0), "FM: bad token");
        require(payee != address(0), "FM: bad payee");
        require(salt != 0, "FM: bad salt");
        require(amount != 0, "FM: bad amount");
        require(block.timestamp < expiry, "FM: signature timed out");
        require(expiry < block.timestamp + WEEK, "FM: expiry too far");
        bytes32 message =  keccak256(abi.encode(WITHDRAW_SIGNED_METHOD, token, payee, amount, salt, expiry));
        address _signer = signerUnique(message, signature);
        require(signers[_signer], "FM: Invalid signer");
        require(!usedSalt[salt], "FM: salt already used");
        usedSalt[salt] = true;
        TokenReceivable.sendToken(token, payee, amount);
        emit TransferBySignature(_signer, payee, token, amount);
        return amount;
    }

    /**
     * @dev Initiates a signed token withdrawal with swap, exclusive to the router
     * @notice Ensure valid parameters and router setup
     * @param to The address to withdraw to
     * @param amountIn The amount to be swapped in
     * @param minAmountOut The minimum amount out from the swap
     * @param foundryToken The token used in the Foundry
     * @param targetToken The target token for the swap
     * @param router The router address
     * @param salt The salt value for the signature
     * @param expiry The expiration time for the signature
     * @param signature The multi-signature data
     * @return The actual amount of tokens withdrawn from Foundry
     */
    function withdrawSignedAndSwapRouter(
        address to,
        uint256 amountIn,
        uint256 minAmountOut,
        address foundryToken,
        address targetToken,
        address router,
        bytes32 salt,
        uint256 expiry,
        bytes memory signature
    ) external onlyRouter returns (uint256) {
        require(targetToken != address(0), "FM: bad token");
        require(foundryToken != address(0), "FM: bad token");
        require(to != address(0), "FM: bad payee");
        require(salt != 0, "FM: bad salt");
        require(amountIn != 0, "FM: bad amount");
        require(minAmountOut != 0, "FM: bad amount");
        require(block.timestamp < expiry, "FM: signature timed out");
        require(expiry < block.timestamp + WEEK, "FM: expiry too far");

        bytes32 message =  keccak256(
                abi.encode(
                    WITHDRAW_SIGNED_WITH_SWAP_METHOD,
                    to,
                    amountIn,
                    minAmountOut,
                    foundryToken,
                    targetToken,
                    router,
                    salt,
                    expiry
                )
            );
        address _signer = signerUnique(message, signature);
        require(signers[_signer], "FM: Invalid signer");
        require(!usedSalt[salt], "FM: salt already used");
        usedSalt[salt] = true;
        TokenReceivable.sendToken(foundryToken, msg.sender, amountIn);
        emit TransferBySignature(_signer, msg.sender, foundryToken, amountIn);
        return amountIn;
    }

    /**
     * @dev Verifies details of a signed token withdrawal without executing the withdrawal
     * @param token Token address for withdrawal
     * @param payee Intended recipient address
     * @param amount Amount of tokens to be withdrawn
     * @param salt Unique identifier to prevent replay attacks
     * @param expiry Expiration timestamp of the withdrawal signature
     * @param signature Cryptographic signature for verification
     * @return Digest and signer's address from the provided signature
     */
    function withdrawSignedVerify(
        address token,
        address payee,
        uint256 amount,
        bytes32 salt,
        uint256 expiry,
        bytes calldata signature
    ) external view returns (bytes32, address) {
        bytes32 message = keccak256(
                abi.encode(WITHDRAW_SIGNED_METHOD, token, payee, amount, salt, expiry)
            );
        (bytes32 digest, address _signer) = signer(message, signature);
        return (digest, _signer);
    }

    function withdrawRouter(address token, uint256 amount, address recipient) external onlyRouter {
        IERC20(token).transfer(recipient, amount);
    }

    /**
     * @dev Verifies details of a signed token swap withdrawal without execution
     * @param to Recipient address on the target network
     * @param amountIn Tokens withdrawn from Foundry
     * @param minAmountOut The minimum tokens on the target network
     * @param foundryToken Token withdrawn from Foundry
     * @param targetToken Token on the target network
     * @param router The router address
     * @param salt Unique identifier to prevent replay attacks
     * @param expiry Expiration timestamp of the withdrawal signature
     * @param signature Cryptographic signature for verification
     * @return Digest and signer's address from the provided signature
     */
    function withdrawSignedAndSwapRouterVerify(
        address to,
        uint256 amountIn,
        uint256 minAmountOut,
        address foundryToken,
        address targetToken,
        address router,
        bytes32 salt,
        uint256 expiry,
        bytes calldata signature
    ) external view returns (bytes32, address) {
        bytes32 message =  keccak256(
                abi.encode(
                    WITHDRAW_SIGNED_WITH_SWAP_METHOD,
                    to,
                    amountIn,
                    minAmountOut,
                    foundryToken,
                    targetToken,
                    router,
                    salt,
                    expiry
                )
            );
        (bytes32 digest, address _signer) = signer(message, signature);
        return (digest, _signer);
    }

    /**
     * @dev Cancels a signed token withdrawal
     * @param token The token to withdraw
     * @param payee Address for where to send the tokens to
     * @param amount The amount
     * @param salt The salt for unique tx 
     * @param expiry The expiration time for the signature
     * @param signature The multisig validator signature
     */
    function cancelFailedWithdrawSigned(
        address token,
        address payee,
        uint256 amount,
        bytes32 salt,
        uint256 expiry,
        bytes memory signature
    ) external onlySettlementManager {
        require(token != address(0), "FM: bad token");
        require(payee != address(0), "FM: bad payee");
        require(salt != 0, "FM: bad salt");
        require(amount != 0, "FM: bad amount");
        require(block.timestamp < expiry, "FM: signature timed out");
        require(expiry < block.timestamp + WEEK, "FM: expiry too far");
        bytes32 message =  keccak256(
                abi.encode(WITHDRAW_SIGNED_METHOD, token, payee, amount, salt, expiry)
            );
        address _signer = signerUnique(message, signature);
        
        require(signers[_signer], "FM: Invalid signer");
        require(!usedSalt[salt], "FM: salt already used");
        usedSalt[salt] = true;

        emit FailedWithdrawalCancelled(settlementManager, payee, token, amount, salt);
    }

    /**
     * @dev Cancels a signed token swap withdrawal
     * @notice Ensure valid parameters and router setup
     * @param to The address to withdraw to
     * @param amountIn The amount to be swapped in
     * @param minAmountOut The minimum amount out from the swap
     * @param foundryToken The token used in the Foundry
     * @param targetToken The target token for the swap
     * @param router The router address
     * @param salt The salt value for the signature
     * @param expiry The expiration time for the signature
     * @param signature The multi-signature data
     */
    function cancelFailedwithdrawSignedAndSwapRouter(
        address to,
        uint256 amountIn,
        uint256 minAmountOut,
        address foundryToken,
        address targetToken,
        address router,
        bytes32 salt,
        uint256 expiry,
        bytes memory signature
    ) external onlySettlementManager {
        require(targetToken != address(0), "FM: bad token");
        require(foundryToken != address(0), "FM: bad token");
        require(to != address(0), "FM: bad payee");
        require(salt != 0, "FM: bad salt");
        require(amountIn != 0, "FM: bad amount");
        require(minAmountOut != 0, "FM: bad amount");
        require(block.timestamp < expiry, "FM: signature timed out");
        require(expiry < block.timestamp + WEEK, "FM: expiry too far");

        bytes32 message =  keccak256(
                abi.encode(
                    WITHDRAW_SIGNED_WITH_SWAP_METHOD,
                    to,
                    amountIn,
                    minAmountOut,
                    foundryToken,
                    targetToken,
                    router,
                    salt,
                    expiry
                )
            );
        address _signer = signerUnique(message, signature);
        require(signers[_signer], "FM: Invalid signer");
        require(!usedSalt[salt], "FM: salt already used");
        usedSalt[salt] = true;

        emit FailedWithdrawalCancelled(settlementManager, to, targetToken, amountIn, salt);
    }

    /**
     * @dev Adds liquidity for the specified token.
     * @param token Token address for liquidity.
     * @param amount Amount of tokens to be added.
     */
    function addLiquidity(address token, uint256 amount) external {
        require(amount != 0, "FM: Amount must be positive");
        require(token != address(0), "FM: Bad token");
        require(
            isFoundryAsset[token] == true,
            "FM: Only foundry assets can be added"
        );
        liquidities[token][msg.sender] += amount;
        amount = SafeAmount.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
        amount = TokenReceivable.sync(token);
        emit BridgeLiquidityAdded(msg.sender, token, amount);
    }

    /**
     * @dev Removes possible liquidity for the specified token.
     * @param token Token address for liquidity removal.
     * @param amount Amount of tokens to be removed.
     * @return Actual amount of tokens removed.
     */
    function removeLiquidityIfPossible(address token, uint256 amount)
        external
        returns (uint256)
    {
        require(amount != 0, "FM: Amount must be positive");
        require(token != address(0), "FM: Bad token");
        require(
            isFoundryAsset[token] == true,
            "FM: Only foundry assets can be removed"
        );
        uint256 liq = liquidities[token][msg.sender];
        require(liq >= amount, "FM: Not enough liquidity");
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 actualLiq = balance > amount ? amount : balance;

        if (actualLiq != 0) {
            liquidities[token][msg.sender] -= actualLiq;
            TokenReceivable.sendToken(token, msg.sender, actualLiq);
            emit BridgeLiquidityRemoved(msg.sender, token, amount);
        }
        return actualLiq;
    }

    /**
     * @dev Retrieves liquidity for the specified token and liquidity adder.
     * @param token Token address for liquidity.
     * @param liquidityAdder Address of the liquidity adder.
     * @return Current liquidity amount.
     */
    function liquidity(address token, address liquidityAdder)
        external
        view
        returns (uint256)
    {
        return liquidities[token][liquidityAdder];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/WithAdmin.sol";
import "../common/SafeAmount.sol";
import "../common/tokenReceiveable.sol";

abstract contract LiquidityManagerRole is WithAdmin, TokenReceivable {
    using SafeERC20 for IERC20;
    address public liquidityManager;
    address public liquidityManagerBot;
    address public withdrawalAddress;

    event LiquidityAddedByManager(address token, uint256 amount);
    event LiquidityRemovedByManager(address token, uint256 amount, address withdrawalAddress);

  /**
     * @dev Modifier that allows only the designated liquidity managers to execute the function.
     * It checks if the sender is either `liquidityManager` or `liquidityManagerBot`.
     * @notice Ensure that `liquidityManager` and `liquidityManagerBot` are set before using this modifier.
     */
    modifier onlyLiquidityManager() {
        require(
            msg.sender == liquidityManager || msg.sender == liquidityManagerBot,
            "FM: Only liquidity managers"
        );
        _;
    }

    /**
     * @dev Sets the addresses of liquidity managers
     * @param _liquidityManager The primary liquidity manager address
     * @param _liquidityManagerBot The secondary liquidity manager address
     */
    function setLiquidityManagers(address _liquidityManager, address _liquidityManagerBot) external onlyOwner {
        require(_liquidityManager != address(0), "FM: Bad liquidity manager");
        require(_liquidityManagerBot != address(0), "FM: Bad liquidity manager bot");

        liquidityManager = _liquidityManager;
        liquidityManagerBot = _liquidityManagerBot;
    }

    /**
     * @dev Sets the address for withdrawal of liquidity
     * @param _withdrawalAddress The liquidity withdraw address
     */
    function setWithdrawalAddress(address _withdrawalAddress) external onlyOwner {
        withdrawalAddress = _withdrawalAddress;
    }

    /**
     * @dev Adds specified liquidity for the given token
     * @param token Token address for liquidity addition
     * @param amount Amount of tokens to be added
     */
    function addLiquidityByManager(address token, uint256 amount) external onlyLiquidityManager {
        require(amount != 0, "FM: Amount must be positive");
        require(token != address(0), "FM: Bad token");
        // Transfer tokens from the sender to the FundManager
        SafeAmount.safeTransferFrom(token, msg.sender, address(this), amount);
        // Update the inventory using sync
        amount = TokenReceivable.sync(token);
        emit LiquidityAddedByManager(token, amount);
    }

    /**
     * @dev Removes specified liquidity for the given token
     * @param token Token address for liquidity removal
     * @param amount Amount of tokens to be removed
     * @return Actual amount of tokens removed
     */
    function removeLiquidityByManager(address token, uint256 amount) external onlyLiquidityManager returns (uint256) {
        require(amount != 0, "FM: Amount must be positive");
        require(token != address(0), "FM: Bad token");
        // Check the Token balance of FundManager
        require(IERC20(token).balanceOf(address(this)) >= amount, "FM: Insufficient balance");
        // Transfer tokens to the withdrawal address using sendToken
        TokenReceivable.sendToken(token, withdrawalAddress, amount);
        emit LiquidityRemovedByManager(token, amount, withdrawalAddress);
        return amount;
    }

}