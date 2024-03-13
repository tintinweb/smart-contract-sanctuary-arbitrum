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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address guy, uint wad) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOneInchSwap {  
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    struct OrderRFQ {
        uint256 info;  // lowest 64 bits is the order id, next 64 bits is the expiration timestamp
        address makerAsset; // targetToken
        address takerAsset; // foundryToken
        address maker;
        address allowedSender;  // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount; // destinationAmountIn / foundryTokenAmountIn
    }

    struct Order {
        uint256 salt;
        address makerAsset; // targetToken
        address takerAsset; // foundryToken
        address maker;
        address receiver;   
        address allowedSender;  // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount; 
        uint256 offsets;
        bytes interactions; // concat(makerAssetData, takerAssetData, getMakingAmount, getTakingAmount, predicate, permit, preIntercation, postInteraction)
    }

    // Define external functions that will be available for interaction
   
    // fillOrderRFQTo 
    function fillOrderRFQTo(
        OrderRFQ calldata order,
        bytes calldata signature,
        uint256 flagsAndAmount,
        address target // receiverAddress
    ) external payable returns (uint256 filledMakingAmount, uint256 filledTakingAmount, bytes32 orderHash);

    // fillOrderTo function
    function fillOrderTo(
        Order calldata order_,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,  // destinationAmountIn
        uint256 skipPermitAndThresholdAmount,
        address target  // receiverAddress
    ) external payable returns(uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);
    
    // uniswapV3SwapTo function
    function uniswapV3SwapTo(
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns(uint256 returnAmount);

    // unoswapTo function
    function unoswapTo(
        address payable recipient,
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns(uint256 returnAmount);

    // swap function
    function swap(
        address executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

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
pragma solidity 0.8.2;

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
pragma solidity 0.8.2;
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
 pragma solidity 0.8.2;

import "./FundManager.sol";
import "../common/tokenReceiveable.sol";
import "../common/SafeAmount.sol";
import "../common/oneInch/IOneInchSwap.sol";
import "../common/IWETH.sol";
// import "foundry-contracts/contracts/common/FerrumDeployer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 @author The ferrum network.
 @title This is a routing contract named as FiberRouter.
*/
contract FiberRouter is Ownable, TokenReceivable {
    using SafeERC20 for IERC20;
    address public pool;
    address payable public gasWallet;
    address public oneInchAggregatorRouter;
    address public WETH;

    enum OneInchFunction {
        unoswapTo,
        uniswapV3SwapTo,
        swap,
        fillOrderTo,
        fillOrderRFQTo
    }
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }
    struct Order {
        uint256 salt;
        address makerAsset; // targetToken
        address takerAsset; // foundryToken
        address maker;
        address receiver;   
        address allowedSender;  // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;  // destinationAmountIn
        uint256 offsets;
        bytes interactions; // concat(makerAssetData, takerAssetData, getMakingAmount, getTakingAmount, predicate, permit, preIntercation, postInteraction)
    }
    struct OrderRFQ {
        uint256 info;  // lowest 64 bits is the order id, next 64 bits is the expiration timestamp
        address makerAsset; // targetToken
        address takerAsset; // foundryToken
        address maker;
        address allowedSender;  // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;
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
        uint256 gasAmount
    );

    event Withdraw(
        address token,
        address receiver,
        uint256 amount,
        bytes32 salt,
        bytes signature
    );

    event WithdrawOneInch(
        address to,
        uint256 amountIn,
        uint256 amountOutOneInch,
        address foundryToken,
        address targetToken,
        bytes oneInchData,
        bytes32 salt,
        bytes multiSignature
    );

    event NonEvmSwap(
        address sourceToken,
        string targetToken,
        uint256 sourceChainId,
        string targetChainId,
        uint256 sourceAmount,
        address sourceAddress,
        string targetAddress,
        uint256 settledAmount,
        bytes32 withdrawalData
    );
    event UnoSwapHandled(
        address indexed swapRouter,
        address indexed to,
        address indexed fromToken,
        uint256 amountIn,
        uint256 amountOut
    );
    event UniswapV3SwapHandled(
        address indexed swapRouter,
        address indexed to,
        uint256 amountIn,
        uint256 amountOut
    );
    event SwapHandled(
        address indexed swapRouter,
        address indexed to,
        address indexed fromToken,
        uint256 amountIn,
        uint256 amountOut
    );

   /**
     * @dev Constructor that sets the WETH address, oneInchAggregator address, and the pool address.
     */
    constructor() {
        // bytes memory initData = IFerrumDeployer(msg.sender).initData();
    }

    /**
     @dev Sets the WETH address.
     @param _weth The WETH address
     */
    function setWETH(address _weth) external onlyOwner {
        require(
            _weth != address(0),
            "_weth address cannot be zero"
        );
        WETH = _weth;
    }

    /**
     @dev Sets the fund manager contract.
     @param _pool The fund manager
     */
    function setPool(address _pool) external onlyOwner {
        require(
            _pool != address(0),
            "Swap pool address cannot be zero"
        );
        pool = _pool;
    }

    /**
     @dev Sets the gas wallet address.
     @param _gasWallet The wallet which pays for the funds on withdrawal
     */
    function setGasWallet(address payable _gasWallet) external onlyOwner {
        require(
            _gasWallet != address(0),
            "Gas Wallet address cannot be zero"
        );
        gasWallet = _gasWallet;
    }

    /**
     @dev Sets the 1inch Aggregator Router address
     @param _newRouterAddress The new Router Address of oneInch
     */
    function setOneInchAggregatorRouter(address _newRouterAddress)
        external
        onlyOwner
    {
        require(
            _newRouterAddress != address(0),
            "Swap router address cannot be zero"
        );
        oneInchAggregatorRouter = _newRouterAddress;
    }

    /**
     * @dev Initiate an x-chain swap.
     * @param token The token to be swapped
     * @param amount The amount to be swapped
     * @param targetNetwork The target network for the swap
     * @param targetToken The target token for the swap
     * @param targetAddress The target address for the swap
     * @param withdrawalData Data related to the withdrawal
     */
    function swap(
        address token,
        uint256 amount,
        uint256 targetNetwork,
        address targetToken,
        address targetAddress,
        bytes32 withdrawalData
    ) external payable nonReentrant {
        // Validation checks
        require(token != address(0), "FR: Token address cannot be zero");
        require(targetToken != address(0), "FR: Target token address cannot be zero");
        require(targetNetwork != 0, "FR: targetNetwork is required");
        require(targetAddress != address(0), "FR: Target address cannot be zero");
        require(amount != 0, "FR: Amount must be greater than zero");
        require(withdrawalData != 0, "FR: withdraw data cannot be empty");
        require(msg.value != 0, "FR: Gas Amount must be greater than zero");

        // Proceed with the swap logic
        amount = SafeAmount.safeTransferFrom(token, _msgSender(), pool, amount);
        amount = FundManager(pool).swapToAddress(
            token,
            amount,
            targetNetwork,
            targetAddress
        );

        // Transfer the gas fee to the gasWallet
        payable(gasWallet).transfer(msg.value);

        // Emit Swap event
        emit Swap(
            token,
            targetToken,
            block.chainid,
            targetNetwork,
            amount,
            _msgSender(),
            targetAddress,
            amount,
            withdrawalData,
            msg.value
        );
    }

    /**
     *@dev Initiate an x-chain swap.
     *@param token The source token to be swaped
     *@param amount The source amount
     *@param targetNetwork The chain ID for the target network
     *@param targetToken The target token address
     *@param targetAddress Final destination on target
     *@param withdrawalData Data related to the withdrawal
     */
    function nonEvmSwap(
        address token,
        uint256 amount,
        string memory targetNetwork,
        string memory targetToken,
        string memory targetAddress,
        bytes32 withdrawalData
    ) external nonReentrant {
        // Validation checks
        require(token != address(0), "FR: Token address cannot be zero");
        require(amount != 0, "Amount must be greater than zero");
        require(
            bytes(targetNetwork).length != 0,
            "FR: Target network cannot be empty"
        );
        require(
            bytes(targetToken).length != 0,
            "FR: Target token cannot be empty"
        );
        require(
            bytes(targetAddress).length != 0,
            "FR: Target address cannot be empty"
        );
        require(
            withdrawalData != 0,
            "FR: withdraw data cannot be empty"
        );
        amount = SafeAmount.safeTransferFrom(token, _msgSender(), pool, amount);
        amount = FundManager(pool).nonEvmSwapToAddress(
            token,
            amount,
            targetNetwork,
            targetToken,
            targetAddress
        );
        emit NonEvmSwap(
            token,
            targetToken,
            block.chainid,
            targetNetwork,
            amount,
            _msgSender(),
            targetAddress,
            amount,
            withdrawalData
        );
    }

    /**
     * @dev Do a local swap and generate a cross-chain swap
     * @param amountIn The input amount
     * @param amountOut Equivalent to amountOut on oneInch
     * @param crossTargetNetwork The target network for the swap
     * @param crossTargetToken The target token for the cross-chain swap
     * @param crossTargetAddress The target address for the cross-chain swap
     * @param oneInchData The data containing information for the 1inch swap
     * @param fromToken The token to be swapped
     * @param foundryToken The foundry token used for the swap
     * @param withdrawalData Data related to the withdrawal
     */
    function swapAndCrossOneInch(
            uint256 amountIn,
            uint256 amountOut, // amountOut on oneInch
            uint256 crossTargetNetwork,
            address crossTargetToken,
            address crossTargetAddress,
            bytes memory oneInchData,
            address fromToken,
            address foundryToken,
            bytes32 withdrawalData,
            OneInchFunction funcSelector 
        ) external payable nonReentrant {
            // Validation checks
            require(
                fromToken != address(0),
                "FR: From token address cannot be zero"
            );
            require(
                foundryToken != address(0),
                "FR: Foundry token address cannot be zero"
            );
            require(
                crossTargetToken != address(0),
                "FR: Cross target token address cannot be zero"
            );
            require(amountIn != 0, "FR: Amount in must be greater than zero");
            require(amountOut != 0, "FR: Amount out must be greater than zero");
            require(
                bytes(oneInchData).length != 0,
                "FR: 1inch data cannot be empty"
            );
            require(
                withdrawalData != 0,
                "FR: withdraw data cannot be empty"
            );
            require(msg.value != 0, "FR: Gas Amount must be greater than zero");
            amountIn = SafeAmount.safeTransferFrom(
                fromToken,
                _msgSender(),
                address(this),
                amountIn
            );
            uint256 settledAmount = _swapAndCrossOneInch(
                amountIn,
                amountOut,
                crossTargetNetwork,
                crossTargetAddress,
                oneInchData,
                fromToken,
                foundryToken,
                funcSelector  // Pass the enum parameter
            );
            // Transfer the gas fee to the gasWallet
            payable(gasWallet).transfer(msg.value);
            // Emit Swap event
            emit Swap(
                fromToken,
                crossTargetToken,
                block.chainid,
                crossTargetNetwork,
                amountIn,
                _msgSender(),
                crossTargetAddress,
                settledAmount,
                withdrawalData,
                msg.value
            );
        }

    /**
     * @dev Swap and cross to oneInch in native currency
     * @param amountOut Equivalent to amountOut on oneInch
     * @param crossTargetNetwork The target network for the swap
     * @param crossTargetToken The target token for the cross-chain swap
     * @param crossTargetAddress The target address for the cross-chain swap
     * @param oneInchData The data containing information for the 1inch swap
     * @param foundryToken The foundry token used for the swap
     * @param withdrawalData Data related to the withdrawal
     * @param gasFee The gas fee being charged on withdrawal
     */
    function swapAndCrossOneInchETH(
        uint256 amountOut, // amountOut on oneInch
        uint256 crossTargetNetwork,
        address crossTargetToken,
        address crossTargetAddress,
        bytes memory oneInchData,
        address foundryToken,
        bytes32 withdrawalData,
        uint256 gasFee,
        OneInchFunction funcSelector // Add the enum parameter
    ) external payable {
        uint256 amountIn = msg.value - gasFee;
        // Validation checks
        require(amountIn != 0, "FR: Amount in must be greater than zero");
        require(gasFee != 0, "FR: Gas fee must be greater than zero");
        require(msg.value == amountIn + gasFee, "FR: msg.value must equal amountIn plus gasFee");
        require(amountOut != 0, "FR: Amount out must be greater than zero");
        require(crossTargetToken != address(0), "FR: Cross target token address cannot be zero");
        require(bytes(oneInchData).length != 0, "FR: 1inch data cannot be empty");
        require(foundryToken != address(0), "FR: Foundry token address cannot be zero");
        require(withdrawalData != 0, "FR: Withdraw data cannot be empty");
        require(msg.value != 0, "FR: Gas Amount must be greater than zero");
        // Deposit ETH (excluding gas fee) and get WETH
        IWETH(WETH).deposit{value: amountIn}();
        // Execute swap and cross-chain operation
        uint256 settledAmount = _swapAndCrossOneInch(
            amountIn,
            amountOut,
            crossTargetNetwork,
            crossTargetAddress,
            oneInchData,
            WETH,
            foundryToken,
            funcSelector // Pass the function selector
        );
        // Transfer the gas fee to the gasWallet
        payable(gasWallet).transfer(gasFee);
        // Emit Swap event
        emit Swap(
            WETH,
            crossTargetToken,
            block.chainid,
            crossTargetNetwork,
            amountIn,
            _msgSender(),
            crossTargetAddress,
            settledAmount,
            withdrawalData,
            gasFee
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
     * @param multiSignature The multisig validator signature
    */
    function withdrawSigned(
        address token,
        address payee,
        uint256 amount,
        bytes32 salt,
        uint256 expiry,
        bytes memory multiSignature
    ) public virtual nonReentrant {
        // Validation checks
        require(token != address(0), "FR: Token address cannot be zero");
        require(payee != address(0), "Payee address cannot be zero");
        require(amount != 0, "Amount must be greater than zero");
        require(salt > bytes32(0), "salt must be greater than zero bytes");
        // need to add restrictions
        amount = FundManager(pool).withdrawSigned(
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
     * @dev Initiates a signed OneInch token withdrawal, exclusive to the router.
     * @notice Ensure valid parameters and router setup.
     * @param to The address to withdraw to
     * @param amountIn The amount to be swapped in
     * @param amountOut The expected amount out in the OneInch swap
     * @param foundryToken The token used in the Foundry
     * @param targetToken The target token for the swap
     * @param oneInchData The data containing information for the 1inch swap
     * @param salt The salt value for the signature
     * @param expiry The expiration time for the signature
     * @param multiSignature The multi-signature data
     */
    function withdrawSignedAndSwapOneInch(
        address payable to,
        uint256 amountIn,
        uint256 amountOut,
        address foundryToken,
        address targetToken,
        bytes memory oneInchData,
        OneInchFunction funcSelector, // Add the enum parameter
        bytes32 salt,
        uint256 expiry,
        bytes memory multiSignature
    ) public virtual nonReentrant {
        require(foundryToken != address(0), "Bad Token Address");
        require(
            targetToken != address(0),
            "FR: Target token address cannot be zero"
        );
        require(amountIn != 0, "Amount in must be greater than zero");
        require(amountOut != 0, "Amount out minimum must be greater than zero");
        require(foundryToken != address(0), "Bad Token Address");
        FundManager(pool).withdrawSignedOneInch(
            to,
            amountIn,
            amountOut,
            foundryToken,
            targetToken,
            oneInchData,
            salt,
            expiry,
            multiSignature
        );
        amountIn = IERC20(foundryToken).balanceOf(address(this));
        // Check if allowance is non-zero
        if (IERC20(foundryToken).allowance(address(this), oneInchAggregatorRouter) != 0) {
            // We reset it to zero
            IERC20(foundryToken).safeApprove(oneInchAggregatorRouter, 0);
        }
        // Set the allowance to the swap amount
        IERC20(foundryToken).safeApprove(oneInchAggregatorRouter, amountIn);
        uint256 amountOutOneInch = swapHelperForOneInch(
            to,
            foundryToken,
            amountIn,
            amountOut,
            oneInchData,
            funcSelector
        );
        require(amountOutOneInch != 0, "FR: Bad amount out from oneInch");
        emit WithdrawOneInch(
            to,
            amountIn,
            amountOutOneInch,
            foundryToken,
            targetToken,
            oneInchData,
            salt,
            multiSignature
        );
    }

    /**
     * @dev Helper function for executing token swaps using OneInch aggregator
     * @param to The recipient address to receive the swapped tokens
     * @param srcToken The source token to be swapped (input token)
     * @param amountIn The amount of input tokens to be swapped
     * @param amountOut The expected amount of output tokens after the swap
     * @param oneInchData The data containing information for the 1inch swap
     * @return returnAmount The amount of tokens received after the swap and transaction execution
     */
    function swapHelperForOneInch(
        address payable to,
        address srcToken,
        uint256 amountIn,
        uint256 amountOut,
        bytes memory oneInchData,
        OneInchFunction funcSelector  // Add enum parameter to identify the function
    ) internal returns (uint256 returnAmount) {

        if (funcSelector == OneInchFunction.unoswapTo) {
            returnAmount = handleUnoSwap(to, srcToken, amountIn, amountOut, oneInchData);
        } else if (funcSelector == OneInchFunction.uniswapV3SwapTo) {
            returnAmount = handleUniswapV3Swap(to, amountIn, amountOut, oneInchData);
        } else if (funcSelector == OneInchFunction.swap) {
            returnAmount = handleSwap(to, srcToken, amountIn, amountOut, oneInchData);
        } else if (funcSelector == OneInchFunction.fillOrderTo) {
            returnAmount = handleFillOrderTo(to, srcToken, amountIn, oneInchData);
        } else if (funcSelector == OneInchFunction.fillOrderRFQTo) {
            returnAmount = handleFillOrderRFQTo(to, srcToken, amountIn, oneInchData);
        }
    }

    /**
     * @dev Handles the execution of a token swap operation using UnoSwap
     * @param to The recipient address to receive the swapped tokens
     * @param fromToken The token to be swapped from (input token)
     * @param amountIn The amount of input tokens to be swapped
     * @param amountOut The expected amount of output tokens after the swap
     * @param oneInchData The data containing information for the 1inch swap
     * @return returnAmount The amount of tokens received after the swap and transaction execution
     */
    function handleUnoSwap(
        address payable to,
        address fromToken,
        uint256 amountIn,
        uint256 amountOut,
        bytes memory oneInchData
    ) internal returns (uint256 returnAmount) {
        (
            address payable recipient,
            address srcToken,
            uint256 amount,
            uint256 minReturn,
            uint256[] memory poolsOneInch
        ) = abi.decode(
            oneInchData,
            (address, address, uint256, uint256, uint256[])
        );
        require(to == recipient, "FR: recipient address bad oneInch Data");
        require(fromToken == srcToken, "FR: srcToken bad oneInch Data");
        require(amountIn == amount, "FR: inputAmount bad oneInch Data");
        require(amountOut == minReturn, "FR: outAmount bad oneInch Data");
        require(oneInchData.length >= 4, "Data too short for valid call");
        returnAmount = IOneInchSwap(oneInchAggregatorRouter).unoswapTo(
            recipient,
            srcToken,
            amount,
            minReturn,
            poolsOneInch
        );
        emit UnoSwapHandled(
            oneInchAggregatorRouter,
            to,
            fromToken,
            amountIn,
            returnAmount //should return by the unoSwap
        );
    }

    /**
     * @dev Handles the execution of a token swap operation involving 1inch aggregator
     * @param to The recipient address to receive the swapped tokens
     * @param amountIn The amount of input tokens to be swapped
     * @param amountOut The expected amount of output tokens after the swap
     * @param oneInchData The data containing information for the 1inch swap
     * @return returnAmount The amount of tokens received after the swap and transaction execution
     */
    function handleUniswapV3Swap(
        address payable to,
        uint256 amountIn,
        uint256 amountOut,
        bytes memory oneInchData
    ) internal returns (uint256 returnAmount) {
        (
            address payable recipient,
            uint256 amount,
            uint256 minReturn,
            uint256[] memory poolsOneInch
        ) = abi.decode(
            oneInchData,
            (address, uint256, uint256, uint256[])
        );
        require(to == recipient, "FR: recipient address bad oneInch Data");
        require(amountIn == amount, "FR: inputAmount bad oneInch Data");
        require(amountOut == minReturn, "FR: outAmount bad oneInch Data");
        require(oneInchData.length >= 4, "Data too short for valid call");
        returnAmount = IOneInchSwap(oneInchAggregatorRouter).uniswapV3SwapTo(
            recipient,
            amount,
            minReturn,
            poolsOneInch
        );
        emit UniswapV3SwapHandled(
            oneInchAggregatorRouter,
            to,
            amountIn,
            returnAmount //should be returned by uniswapV3SwapTo
        );
    }

    /**
     * @dev Handles the execution of a token swap operation, potentially involving 1inch aggregator
     * @param to The recipient address to receive the swapped tokens
     * @param fromToken The address of the input token for the swap
     * @param amountIn The amount of input tokens to be swapped
     * @param amountOut The expected amount of output tokens after the swap
     * @param oneInchData The data containing information for the 1inch swap
     * @return returnAmount The amount of tokens received after the swap and transaction execution
     */
    function handleSwap(
        address payable to,
        address fromToken,
        uint256 amountIn,
        uint256 amountOut,
        bytes memory oneInchData
    ) internal returns (uint256 returnAmount) {
        // Decoding oneInchData to get the required parameters
        (
            address executor,
            SwapDescription memory desc,
            bytes memory permit,
            bytes memory swapData
        ) = abi.decode(
            oneInchData,
            (address, SwapDescription, bytes, bytes)
        );
        // Manually create a new SwapDescription for IOneInchSwap
        IOneInchSwap.SwapDescription memory oneInchDesc = IOneInchSwap
            .SwapDescription({
                srcToken: IERC20(desc.srcToken),
                dstToken: IERC20(desc.dstToken),
                srcReceiver: desc.srcReceiver,
                dstReceiver: desc.dstReceiver,
                amount: desc.amount,
                minReturnAmount: desc.minReturnAmount,
                flags: desc.flags
            });

        // Accessing fields of the desc instance of SwapDescription struct
        require(
            to == desc.dstReceiver,
            "FR: recipient address bad oneInch Data"
        );
        require(amountIn == desc.amount, "FR: inputAmount bad oneInch Data");
        require(
            amountOut == desc.minReturnAmount,
            "FR: outAmount bad oneInch Data"
        );
        require(fromToken == desc.srcToken, "FR: srcToken bad oneInch Data");

        // Additional safety check
        require(oneInchData.length >= 4, "Data too short for valid call");

        // Performing the swap
        ( returnAmount,) = IOneInchSwap(oneInchAggregatorRouter).swap(
            executor,
            oneInchDesc,
            permit,
            swapData
        );
        emit SwapHandled(
            oneInchAggregatorRouter,
            to,
            fromToken,
            amountIn,
            returnAmount // should be returned 
        );
    }

    /**
     * @dev Handles the execution of the `fillOrderTo` operation, involving 1inch aggregator
     * @param to The recipient address to receive the swapped tokens
     * @param fromToken The address of the input token for the swap (foundryToken or takerAsset)
     * @param amountIn The amount of input tokens to be swapped
     * @param oneInchData The data containing information for the 1inch swap
     * @return returnAmount The amount of tokens received after the swap and transaction execution
     */
    function handleFillOrderTo(
        address payable to,
        address fromToken,  // foundryToken // takerAsset
        uint256 amountIn,
        bytes memory oneInchData
    ) internal returns (uint256 returnAmount) {
        // Decoding oneInchData to get the required parameters
        (
            Order memory order_,
            bytes memory signature,
            bytes memory interaction,
            uint256 makingAmount,
            uint256 takingAmount,  // destinationAmountIn
            uint256 skipPermitAndThresholdAmount,
            address target  // receiverAddress
        ) = abi.decode(
            oneInchData,
            (Order, bytes, bytes, uint256, uint256,uint256, address)
        );

        // Manually create a new Order for IOneInchSwap
        IOneInchSwap.Order memory oneInchOrder = IOneInchSwap
            .Order({
                salt: order_.salt,
                makerAsset: order_.makerAsset,
                takerAsset: order_.takerAsset,
                maker: order_.maker,
                receiver: order_.receiver,
                allowedSender: order_.allowedSender,
                makingAmount: order_.makingAmount,
                takingAmount: order_.takingAmount,
                offsets: order_.offsets,
                interactions: order_.interactions
            });

        // Perform additional checks and validations if needed
        require(to == target, "FR: recipient address bad oneInch Data");
        require(fromToken == order_.takerAsset, "FR: takerAsset bad oneInch Data");
        require(amountIn == takingAmount, "FR: inputAmount bad oneInch Data ");
        require(oneInchData.length >= 4, "Data too short for valid call");

        // Performing the swap
        ( returnAmount, , ) = IOneInchSwap(oneInchAggregatorRouter).fillOrderTo(
            oneInchOrder,
            signature,
            interaction,
            makingAmount,
            takingAmount,
            skipPermitAndThresholdAmount,
            target
        );

        emit SwapHandled(
            oneInchAggregatorRouter,
            to,
            fromToken,
            amountIn,
            returnAmount // should be returned 
        );
    }

    /**
     * @dev Handles the execution of the `fillOrderRFQTo` operation, involving 1inch aggregator
     * @param to The recipient address to receive the swapped tokens
     * @param fromToken The address of the input token for the swap (foundryToken or takerAsset)
     * @param amountIn The amount of input tokens to be swapped
     * @param oneInchData The data containing information for the 1inch swap
     * @return returnAmount The amount of tokens received after the swap and transaction execution
     */
    function handleFillOrderRFQTo(
        address payable to,
        address fromToken,  // foundryToken // takerAsset
        uint256 amountIn,
        bytes memory oneInchData
    ) internal returns (uint256 returnAmount) {
        // Decoding oneInchData to get the required parameters
        (
            OrderRFQ memory order,
            bytes memory signature,
            uint256 flagsAndAmount,
            address target // receiverAddress
        ) = abi.decode(
            oneInchData,
            (OrderRFQ, bytes, uint256, address)
        );

        // Manually create a new OrderRFQ for IOneInchSwap
        IOneInchSwap.OrderRFQ memory oneInchOrderRFQ = IOneInchSwap.OrderRFQ({
            info: order.info,
            makerAsset: order.makerAsset,
            takerAsset: order.takerAsset,
            maker: order.maker,
            allowedSender: order.allowedSender,
            makingAmount: order.makingAmount,
            takingAmount: order.takingAmount
        });

        // Perform additional checks and validations if needed
        require(to == target, "FR: recipient address bad oneInch Data");
        require(fromToken == order.takerAsset, "FR: takerAsset bad oneInch Data");
        require(amountIn == order.takingAmount, "FR: inputAmount bad oneInch Data ");
        require(oneInchData.length >= 4, "Data too short for valid call");

        // Performing the swap
        ( returnAmount, , ) = IOneInchSwap(oneInchAggregatorRouter).fillOrderRFQTo(
            oneInchOrderRFQ,
            signature,
            flagsAndAmount,
            target
        );

        emit SwapHandled(
            oneInchAggregatorRouter,
            to,
            fromToken,
            amountIn,
            returnAmount // should be returned 
        );
    }

    /**
     * @dev Performs a token swap and cross-network transaction using the 1inch Aggregator
     * @param amountIn The amount of input tokens to be swapped
     * @param amountOut The expected amount of output tokens after the swap on 1inch
     * @param crossTargetNetwork The network identifier for the cross-network transaction
     * @param crossTargetAddress The target address on the specified network for the cross-network transaction
     * @param oneInchData The data containing information for the 1inch swap
     * @param fromToken The address of the input token for the swap
     * @param foundryToken The address of the token used as the foundry
     * @return FMAmountOut The amount of foundry tokens received after the cross-network transaction
     */
    function _swapAndCrossOneInch(
        uint256 amountIn,
        uint256 amountOut, // amountOut on oneInch
        uint256 crossTargetNetwork,
        address crossTargetAddress,
        bytes memory oneInchData,
        address fromToken,
        address foundryToken,
        OneInchFunction funcSelector  // Add enum parameter to identify the function
    ) internal returns (uint256 FMAmountOut) {

        // Check if allowance is non-zero
        if (IERC20(fromToken).allowance(address(this), oneInchAggregatorRouter) != 0) {
            // Reset the allowance to zero
            IERC20(fromToken).safeApprove(oneInchAggregatorRouter, 0);
        }
        // Set the allowance to the swap amount
        IERC20(fromToken).safeApprove(oneInchAggregatorRouter, amountIn);

        uint256 oneInchAmountOut = swapHelperForOneInch(
            payable(pool),
            fromToken,
            amountIn,
            amountOut,
            oneInchData,
            funcSelector  // Pass the enum parameter
        );
        FMAmountOut = FundManager(pool).swapToAddress(
            foundryToken,
            amountOut,
            crossTargetNetwork,
            crossTargetAddress
        );
        require(
            FMAmountOut >= oneInchAmountOut,
            "FR: Bad FM or OneInch Amount Out"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/signature/SigCheckable.sol";
// import "foundry-contracts/contracts/common/FerrumDeployer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./LiquidityManagerRole.sol";

contract FundManager is SigCheckable, LiquidityManagerRole {
    using SafeERC20 for IERC20;

    address public router;
    address public settlementManager;
    uint32 constant WEEK = 3600 * 24 * 7;
    string public constant NAME = "FUND_MANAGER";
    string public constant VERSION = "000.004";
    bytes32 constant WITHDRAW_SIGNED_METHOD =
        keccak256(
            "WithdrawSigned(address token,address payee,uint256 amount,bytes32 salt,uint256 expiry)"
        );
    bytes32 constant WITHDRAW_SIGNED_ONEINCH__METHOD =
        keccak256(
            "WithdrawSignedOneInch(address to,uint256 amountIn,uint256 amountOut,address foundryToken,address targetToken,bytes oneInchData,bytes32 salt,uint256 expiry)"
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
    event nonEvmBridgeSwap(
        address from,
        address indexed token,
        string targetNetwork,
        string targetToken,
        string targetAddrdess,
        uint256 amount
    );

    mapping(address => bool) public signers;
    mapping(address => mapping(address => uint256)) private liquidities;
    mapping(address => mapping(uint256 => address)) public allowedTargets;
    mapping(address => mapping(string => string)) public nonEvmAllowedTargets;
    mapping(address => bool) public isFoundryAsset;
    mapping(bytes32=>bool) public usedSalt;

    /**
     * @dev Modifier that allows only the designated router to execute the function.
     * It checks if the sender is equal to the `router` address.
     * @notice Ensure that `router` is set before using this modifier.
     */
    modifier onlyRouter() {
        require(msg.sender == router, "FM: Only router method");
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
    constructor() EIP712(NAME, VERSION) {
        // bytes memory initData = IFerrumDeployer(msg.sender).initData();

    }

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
     @dev sets the router
     @param _router is the FiberRouter address
     */
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "FM: router requried");
        router = _router;
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
     @dev sets the allowed target chain & token on nonEVM chain
     @param token is the address of foundry token on source network
     @param chainId target non EVM network's chain ID
     @param targetToken target non EVM network's foundry token address
     */
    function nonEvmAllowTarget(
        address token,
        string memory chainId,
        string memory targetToken
    ) external onlyAdmin {
        require(token != address(0), "Bad token");
        require(bytes(chainId).length != 0, "Chain ID cannot be empty");
        require(bytes(targetToken).length != 0, "Target token cannot be empty");

        nonEvmAllowedTargets[token][chainId] = targetToken;
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
     @dev removes the allowed target chain & token on nonEVM chain
     @param token is the address of foundry token on source network
     @param chainId target non EVM network's chain ID
     */
    function nonEvmDisallowTarget(address token, string memory chainId)
        external
        onlyAdmin
    {
        require(token != address(0), "Bad token");
        require(bytes(chainId).length != 0, "Chain ID cannot be empty");
        delete nonEvmAllowedTargets[token][chainId];
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
        require(msg.sender != address(0), "FM: bad from");
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
     * @dev Initiates a non-EVM token swap, exclusive to the router
     * @notice Ensure valid parameters and router setup
     * @param token The address of the token to be swapped
     * @param amount The amount of tokens to be swapped
     * @param targetNetwork The identifier of the target network for the swap
     * @param targetToken The identifier of the target token on the non-EVM network
     * @param targetAddress The address on the target network where the swapped tokens will be sent
     * @return The actual amount of tokens swapped
     */
    function nonEvmSwapToAddress(
        address token,
        uint256 amount,
        string memory targetNetwork,
        string memory targetToken,
        string memory targetAddress
    ) external onlyRouter returns (uint256) {
        require(msg.sender != address(0), "FM: bad from");
        require(token != address(0), "FM: bad token");
        require(amount != 0, "FM: bad amount");
        require(bytes(targetNetwork).length != 0, "FM: empty target network");
        require(bytes(targetToken).length != 0, "FM: empty target token");
        require(bytes(targetAddress).length != 0, "FM: empty target address");
        require(
            keccak256(
                abi.encodePacked(nonEvmAllowedTargets[token][targetNetwork])
            ) == keccak256(abi.encodePacked(targetToken)),
            "FM: target not allowed"
        );
        amount = TokenReceivable.sync(token);
        emit nonEvmBridgeSwap(
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
        bytes32 message =  keccak256(
                abi.encode(WITHDRAW_SIGNED_METHOD, token, payee, amount, salt, expiry)
            );
        address _signer = signerUnique(message, signature);
        
        require(signers[_signer], "FM: Invalid signer");
        require(!usedSalt[salt], "FM: salt already used");
        usedSalt[salt] = true;
        TokenReceivable.sendToken(token, payee, amount);
        emit TransferBySignature(_signer, payee, token, amount);
        return amount;
    }

    /**
     * @dev Initiates a signed OneInch token withdrawal, exclusive to the router
     * @notice Ensure valid parameters and router setup
     * @param to The address to withdraw to
     * @param amountIn The amount to be swapped in
     * @param amountOut The expected amount out in the OneInch swap
     * @param foundryToken The token used in the Foundry
     * @param targetToken The target token for the swap
     * @param oneInchData The data containing information for the 1inch swap
     * @param salt The salt value for the signature
     * @param expiry The expiration time for the signature
     * @param signature The multi-signature data
     * @return The actual amount of tokens withdrawn from Foundry
     */
    function withdrawSignedOneInch(
        address to,
        uint256 amountIn,
        uint256 amountOut,
        address foundryToken,
        address targetToken,
        bytes memory oneInchData,
        bytes32 salt,
        uint256 expiry,
        bytes memory signature
    ) external onlyRouter returns (uint256) {
        require(targetToken != address(0), "FM: bad token");
        require(foundryToken != address(0), "FM: bad token");
        require(to != address(0), "FM: bad payee");
        require(salt != 0, "FM: bad salt");
        require(amountIn != 0, "FM: bad amount");
        require(amountOut != 0, "FM: bad amount");
        require(block.timestamp < expiry, "FM: signature timed out");
        require(expiry < block.timestamp + WEEK, "FM: expiry too far");

        bytes32 message =  keccak256(
                abi.encode(
                    WITHDRAW_SIGNED_ONEINCH__METHOD,
                    to,
                    amountIn,
                    amountOut,
                    foundryToken,
                    targetToken,
                    oneInchData,
                    salt,
                    expiry
                )
            );
        address _signer = signerUnique(message, signature);
        require(signers[_signer], "FM: Invalid signer");
        require(!usedSalt[salt], "FM: salt already used");
        usedSalt[salt] = true;
        TokenReceivable.sendToken(foundryToken, router, amountIn);
        emit TransferBySignature(_signer, router, foundryToken, amountIn);
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
     * @dev Verifies details of a signed OneInch token withdrawal without execution
     * @param to Recipient address on the target network
     * @param amountIn Tokens withdrawn from Foundry
     * @param amountOut Expected tokens on the target network
     * @param foundryToken Token withdrawn from Foundry
     * @param targetToken Token on the target network
     * @param oneInchData The data containing information for the 1inch swap
     * @param salt Unique identifier to prevent replay attacks
     * @param expiry Expiration timestamp of the withdrawal signature
     * @param signature Cryptographic signature for verification
     * @return Digest and signer's address from the provided signature
     */
    function withdrawSignedOneInchVerify(
        address to,
        uint256 amountIn,
        uint256 amountOut,
        address foundryToken,
        address targetToken,
        bytes memory oneInchData,
        bytes32 salt,
        uint256 expiry,
        bytes calldata signature
    ) external view returns (bytes32, address) {
        bytes32 message =  keccak256(
                abi.encode(
                    WITHDRAW_SIGNED_ONEINCH__METHOD,
                    to,
                    amountIn,
                    amountOut,
                    foundryToken,
                    targetToken,
                    oneInchData,
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
     * @dev Cancels a signed OneInch token withdrawal
     * @notice Ensure valid parameters and router setup
     * @param to The address to withdraw to
     * @param amountIn The amount to be swapped in
     * @param amountOut The expected amount out in the OneInch swap
     * @param foundryToken The token used in the Foundry
     * @param targetToken The target token for the swap
     * @param oneInchData The data containing information for the 1inch swap
     * @param salt The salt value for the signature
     * @param expiry The expiration time for the signature
     * @param signature The multi-signature data
     */
    function cancelFailedWithdrawSignedOneInch(
        address to,
        uint256 amountIn,
        uint256 amountOut,
        address foundryToken,
        address targetToken,
        bytes memory oneInchData,
        bytes32 salt,
        uint256 expiry,
        bytes memory signature
    ) external onlySettlementManager {
        require(targetToken != address(0), "FM: bad token");
        require(foundryToken != address(0), "FM: bad token");
        require(to != address(0), "FM: bad payee");
        require(salt != 0, "FM: bad salt");
        require(amountIn != 0, "FM: bad amount");
        require(amountOut != 0, "FM: bad amount");
        require(block.timestamp < expiry, "FM: signature timed out");
        require(expiry < block.timestamp + WEEK, "FM: expiry too far");

        bytes32 message =  keccak256(
                abi.encode(
                    WITHDRAW_SIGNED_ONEINCH__METHOD,
                    to,
                    amountIn,
                    amountOut,
                    foundryToken,
                    targetToken,
                    oneInchData,
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