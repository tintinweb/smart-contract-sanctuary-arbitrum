// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
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
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
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
                _getChainId(),
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
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.5 <0.8.0;

import "../token/ERC20/ERC20.sol";
import "./IERC20Permit.sol";
import "../cryptography/ECDSA.sol";
import "../utils/Counters.sol";
import "./EIP712.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping (address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) internal EIP712(name, "1") {
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title An interface for a contract that is capable of deploying Uniswap V3 Pools
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
interface IUniswapV3PoolDeployer {
    /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    /// Returns factory The factory address
    /// Returns token0 The first token of the pool by address sort order
    /// Returns token1 The second token of the pool by address sort order
    /// Returns fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// Returns tickSpacing The minimum number of ticks between initialized ticks
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/drafts/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

/// @title TokeHypervisor
/// @notice A Uniswap V2-like interface with fungible liquidity to Uniswap V3
/// which allows for arbitrary liquidity provision: one-sided, lop-sided, and balanced
contract TokeHypervisor is IUniswapV3MintCallback, ERC20Permit, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    IUniswapV3Pool public pool;
    IERC20 public token0;
    IERC20 public token1;
    uint24 public fee;
    int24 public tickSpacing;

    int24 public baseLower;
    int24 public baseUpper;
    int24 public limitLower;
    int24 public limitUpper;

    address public owner;
    uint256 public deposit0Max;
    uint256 public deposit1Max;
    uint256 public maxTotalSupply;
    address public whitelistedAddress;
    bool public directDeposit; /// enter uni on deposit (avoid if client uses public rpc)

    uint256 public constant PRECISION = 1e36;

    bool mintCalled;

    event Deposit(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Withdraw(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Rebalance(
        int24 tick,
        uint256 totalAmount0,
        uint256 totalAmount1,
        uint256 feeAmount0,
        uint256 feeAmount1,
        uint256 totalSupply
    );

    /// @param _pool Uniswap V3 pool for which liquidity is managed
    /// @param _owner Owner of the Hypervisor
    constructor(
        address _pool,
        address _owner,
        string memory name,
        string memory symbol
    ) ERC20Permit(name) ERC20(name, symbol) {
        require(_pool != address(0));
        require(_owner != address(0));
        pool = IUniswapV3Pool(_pool);
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
        require(address(token0) != address(0));
        require(address(token1) != address(0));
        fee = pool.fee();
        tickSpacing = pool.tickSpacing();

        owner = _owner;

        maxTotalSupply = 0; /// no cap
        deposit0Max = uint256(-1);
        deposit1Max = uint256(-1);
    }

    /// @notice Deposit tokens
    /// @param deposit0 Amount of token0 transfered from sender to Hypervisor
    /// @param deposit1 Amount of token1 transfered from sender to Hypervisor
    /// @param to Address to which liquidity tokens are minted
    /// @param from Address from which asset tokens are transferred
    /// @return shares Quantity of liquidity tokens minted as a result of deposit
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to,
        address from,
        uint256[4] memory inMin
    ) nonReentrant external returns (uint256 shares) {
        require(deposit0 > 0 || deposit1 > 0);
        require(deposit0 <= deposit0Max && deposit1 <= deposit1Max);
        require(to != address(0) && to != address(this), "to");
        require(msg.sender == whitelistedAddress, "WHE");

        /// update fees
        zeroBurn();

        uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(currentTick());
        uint256 price = FullMath.mulDiv(uint256(sqrtPrice).mul(uint256(sqrtPrice)), PRECISION, 2**(96 * 2));

        (uint256 pool0, uint256 pool1) = getTotalAmounts();

        shares = deposit1.add(deposit0.mul(price).div(PRECISION));

        if (deposit0 > 0) {
          token0.safeTransferFrom(from, address(this), deposit0);
        }
        if (deposit1 > 0) {
          token1.safeTransferFrom(from, address(this), deposit1);
        }

        uint256 total = totalSupply();
        if (total != 0) {
          uint256 pool0PricedInToken1 = pool0.mul(price).div(PRECISION);
          shares = shares.mul(total).div(pool0PricedInToken1.add(pool1));
          if (directDeposit) {
            addLiquidity(
              baseLower,
              baseUpper,
              address(this),
              token0.balanceOf(address(this)),
              token1.balanceOf(address(this)),
              [inMin[0], inMin[1]]
            );
            addLiquidity(
              limitLower,
              limitUpper,
              address(this),
              token0.balanceOf(address(this)),
              token1.balanceOf(address(this)),
              [inMin[2],inMin[3]]
            );
          }
        }
        _mint(to, shares);
        emit Deposit(from, to, shares, deposit0, deposit1);
        /// Check total supply cap not exceeded. A value of 0 means no limit.
        require(maxTotalSupply == 0 || total <= maxTotalSupply, "max");
    }

    /// @notice Update fees of the positions
    /// @return baseLiquidity Fee of base position
    /// @return limitLiquidity Fee of limit position
    function zeroBurn() internal returns(uint128 baseLiquidity, uint128 limitLiquidity) {
      /// update fees for inclusion
      (baseLiquidity, , ) = _position(baseLower, baseUpper);
      if (baseLiquidity > 0) {
          pool.burn(baseLower, baseUpper, 0);
      }
      (limitLiquidity, , ) = _position(limitLower, limitUpper);
      if (limitLiquidity > 0) {
          pool.burn(limitLower, limitUpper, 0);
      }
    }

    /// @notice Pull liquidity tokens from liquidity and receive the tokens
    /// @param shares Number of liquidity tokens to pull from liquidity
    /// @return base0 amount of token0 received from base position
    /// @return base1 amount of token1 received from base position
    /// @return limit0 amount of token0 received from limit position
    /// @return limit1 amount of token1 received from limit position
    function pullLiquidity(
      uint256 shares,
      uint256[4] memory minAmounts
    ) external onlyOwner returns(
        uint256 base0,
        uint256 base1,
        uint256 limit0,
        uint256 limit1
      ) {
        zeroBurn();
        (base0, base1) = _burnLiquidity(
            baseLower,
            baseUpper,
            _liquidityForShares(baseLower, baseUpper, shares),
            address(this),
            false,
            minAmounts[0],
            minAmounts[1] 
        );
        (limit0, limit1) = _burnLiquidity(
            limitLower,
            limitUpper,
            _liquidityForShares(limitLower, limitUpper, shares),
            address(this),
            false,
            minAmounts[2],
            minAmounts[3] 
        );
    }

    function _baseLiquidityForShares(uint256 shares) internal view returns (uint128) {
        return _liquidityForShares(baseLower, baseUpper, shares);
    }

    function _limitLiquidityForShares(uint256 shares) internal view returns (uint128) {
        return _liquidityForShares(limitLower, limitUpper, shares);
    }

    /// @param shares Number of liquidity tokens to redeem as pool assets
    /// @param to Address to which redeemed pool assets are sent
    /// @param from Address from which liquidity tokens are sent
    /// @param minAmounts min amount0,1 returned for shares of liq 
    /// @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
    /// @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
    function withdraw(
        uint256 shares,
        address to,
        address from,
        uint256[4] memory minAmounts
    ) nonReentrant external returns (uint256 amount0, uint256 amount1) {
        require(shares > 0, "shares");
        require(to != address(0), "to");
        require(msg.sender == whitelistedAddress, "WHE");

        /// update fees
        zeroBurn();

        /// Withdraw liquidity from Uniswap pool
        (uint256 base0, uint256 base1) = _burnLiquidity(
            baseLower,
            baseUpper,
            _baseLiquidityForShares(shares),
            to,
            false,
            minAmounts[0],
            minAmounts[1]
        );
        (uint256 limit0, uint256 limit1) = _burnLiquidity(
            limitLower,
            limitUpper,
            _limitLiquidityForShares(shares),
            to,
            false,
            minAmounts[2],
            minAmounts[3]
        );

        // Push tokens proportional to unused balances
        uint256 unusedAmount0 = token0.balanceOf(address(this)).mul(shares).div(totalSupply());
        uint256 unusedAmount1 = token1.balanceOf(address(this)).mul(shares).div(totalSupply());
        if (unusedAmount0 > 0) token0.safeTransfer(to, unusedAmount0);
        if (unusedAmount1 > 0) token1.safeTransfer(to, unusedAmount1);

        amount0 = base0.add(limit0).add(unusedAmount0);
        amount1 = base1.add(limit1).add(unusedAmount1);

        _burn(from, shares);

        emit Withdraw(from, to, shares, amount0, amount1);
    }

    /// @param _baseLower The lower tick of the base position
    /// @param _baseUpper The upper tick of the base position
    /// @param _limitLower The lower tick of the limit position
    /// @param _limitUpper The upper tick of the limit position
    /// @param  inMin min spend 
    /// @param  outMin min amount0,1 returned for shares of liq 
    /// @param feeRecipient Address of recipient of 10% of earned fees since last rebalance
    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address feeRecipient,
        uint256[4] memory inMin, 
        uint256[4] memory outMin
    ) nonReentrant external onlyOwner {
        require(
            _baseLower < _baseUpper &&
                _baseLower % tickSpacing == 0 &&
                _baseUpper % tickSpacing == 0
        );
        require(
            _limitLower < _limitUpper &&
                _limitLower % tickSpacing == 0 &&
                _limitUpper % tickSpacing == 0
        );
        require(
          _limitUpper != _baseUpper ||
          _limitLower != _baseLower
        );
        require(feeRecipient != address(0));

        /// update fees
        (uint128 baseLiquidity, uint128 limitLiquidity) = zeroBurn();

        /// Withdraw all liquidity and collect all fees from Uniswap pool
        (, uint256 feesLimit0, uint256 feesLimit1) = _position(baseLower, baseUpper);
        (, uint256 feesBase0, uint256 feesBase1) = _position(limitLower, limitUpper);

        uint256 fees0 = feesBase0.add(feesLimit0);
        uint256 fees1 = feesBase1.add(feesLimit1);
        (baseLiquidity, , ) = _position(baseLower, baseUpper);
        (limitLiquidity, , ) = _position(limitLower, limitUpper);

        _burnLiquidity(baseLower, baseUpper, baseLiquidity, address(this), true, outMin[0], outMin[1]);
        _burnLiquidity(limitLower, limitUpper, limitLiquidity, address(this), true, outMin[2], outMin[3]);

        /// transfer 10% of fees for VISR buybacks
        if (fees0 > 0) token0.safeTransfer(feeRecipient, fees0.div(10));
        if (fees1 > 0) token1.safeTransfer(feeRecipient, fees1.div(10));

        emit Rebalance(
            currentTick(),
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this)),
            fees0,
            fees1,
            totalSupply()
        );

        uint256[2] memory addMins = [inMin[0],inMin[1]];
        baseLower = _baseLower;
        baseUpper = _baseUpper;
        addLiquidity(
          baseLower,
          baseUpper,
          address(this),
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this)),
          addMins 
        );

        addMins = [inMin[2],inMin[3]];
        limitLower = _limitLower;
        limitUpper = _limitUpper;
        addLiquidity(
          limitLower,
          limitUpper,
          address(this),
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this)),
          addMins
        );
    }

    /// @notice Compound pending fees
    /// @param inMin min spend 
    /// @return baseToken0Owed Pending fees of base token0
    /// @return baseToken1Owed Pending fees of base token1
    /// @return limitToken0Owed Pending fees of limit token0
    /// @return limitToken1Owed Pending fees of limit token1
    function compound(uint256[4] memory inMin) external onlyOwner returns (
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed
    ) {
        // update fees for compounding
        zeroBurn();
        (, baseToken0Owed,baseToken1Owed) = _position(baseLower, baseUpper);
        (, limitToken0Owed,limitToken1Owed) = _position(limitLower, limitUpper);
        
        // collect fees
        pool.collect(address(this), baseLower, baseLower, baseToken0Owed, baseToken1Owed);
        pool.collect(address(this), limitLower, limitUpper, limitToken0Owed, limitToken1Owed);
        
        addLiquidity(
          baseLower,
          baseUpper,
          address(this),
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this)),
          [inMin[0],inMin[1]]
        );
        addLiquidity(
          limitLower,
          limitUpper,
          address(this),
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this)),
          [inMin[2],inMin[3]]
        );
    }

    /// @notice Add tokens to base liquidity
    /// @param amount0 Amount of token0 to add
    /// @param amount1 Amount of token1 to add
    function addBaseLiquidity(uint256 amount0, uint256 amount1, uint256[2] memory inMin) external onlyOwner {
        addLiquidity(
            baseLower,
            baseUpper,
            address(this),
            amount0 == 0 && amount1 == 0 ? token0.balanceOf(address(this)) : amount0,
            amount0 == 0 && amount1 == 0 ? token1.balanceOf(address(this)) : amount1,
            inMin
        );
    }

    /// @notice Add tokens to limit liquidity
    /// @param amount0 Amount of token0 to add
    /// @param amount1 Amount of token1 to add
    function addLimitLiquidity(uint256 amount0, uint256 amount1, uint256[2] memory inMin) external onlyOwner {
        addLiquidity(
            limitLower,
            limitUpper,
            address(this),
            amount0 == 0 && amount1 == 0 ? token0.balanceOf(address(this)) : amount0,
            amount0 == 0 && amount1 == 0 ? token1.balanceOf(address(this)) : amount1,
            inMin
        );
    }

    /// @notice Add Liquidity
    function addLiquidity(
        int24 tickLower,
        int24 tickUpper,
        address payer,
        uint256 amount0,
        uint256 amount1,
        uint256[2] memory inMin
    ) internal {        
        uint128 liquidity = _liquidityForAmounts(tickLower, tickUpper, amount0, amount1);
        _mintLiquidity(tickLower, tickUpper, liquidity, payer, inMin[0], inMin[1]);
    }

    /// @notice Adds the liquidity for the given position
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param liquidity The amount of liquidity to mint
    /// @param payer Payer Data
    /// @param amount0Min Minimum amount of token0 that should be paid
    /// @param amount1Min Minimum amount of token1 that should be paid
    function _mintLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address payer,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal {
        if (liquidity > 0) {
            mintCalled = true;
            (uint256 amount0, uint256 amount1) = pool.mint(
                address(this),
                tickLower,
                tickUpper,
                liquidity,
                abi.encode(payer)
            );
            require(amount0 >= amount0Min && amount1 >= amount1Min, 'PSC');
        }
    }

    /// @notice Burn liquidity from the sender and collect tokens owed for the liquidity
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param liquidity The amount of liquidity to burn
    /// @param to The address which should receive the fees collected
    /// @param collectAll If true, collect all tokens owed in the pool, else collect the owed tokens of the burn
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function _burnLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to,
        bool collectAll,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 amount0, uint256 amount1) {
        if (liquidity > 0) {
            /// Burn liquidity
            (uint256 owed0, uint256 owed1) = pool.burn(tickLower, tickUpper, liquidity);
            require(owed0 >= amount0Min && owed1 >= amount1Min, "PSC");

            // Collect amount owed
            uint128 collect0 = collectAll ? type(uint128).max : _uint128Safe(owed0);
            uint128 collect1 = collectAll ? type(uint128).max : _uint128Safe(owed1);
            if (collect0 > 0 || collect1 > 0) {
                (amount0, amount1) = pool.collect(to, tickLower, tickUpper, collect0, collect1);
            }
        }
    }

    /// @notice Get the liquidity amount for given liquidity tokens
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param shares Shares of position
    /// @return The amount of liquidity toekn for shares
    function _liquidityForShares(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares
    ) internal view returns (uint128) {
        (uint128 position, , ) = _position(tickLower, tickUpper);
        return _uint128Safe(uint256(position).mul(shares).div(totalSupply()));
    }

    /// @notice Get the info of the given position
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return liquidity The amount of liquidity of the position
    /// @return tokensOwed0 Amount of token0 owed
    /// @return tokensOwed1 Amount of token1 owed
    function _position(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), tickLower, tickUpper));
        (liquidity, , , tokensOwed0, tokensOwed1) = pool.positions(positionKey);
    }

    /// @notice Callback function of uniswapV3Pool mint
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        require(mintCalled == true);
        mintCalled = false;

        if (amount0 > 0) token0.safeTransfer(msg.sender, amount0);
        if (amount1 > 0) token1.safeTransfer(msg.sender, amount1);
    }

    /// @return total0 Quantity of token0 in both positions and unused in the Hypervisor
    /// @return total1 Quantity of token1 in both positions and unused in the Hypervisor
    function getTotalAmounts() public view returns (uint256 total0, uint256 total1) {
        (, uint256 base0, uint256 base1) = getBasePosition();
        (, uint256 limit0, uint256 limit1) = getLimitPosition();
        total0 = token0.balanceOf(address(this)).add(base0).add(limit0);
        total1 = token1.balanceOf(address(this)).add(base1).add(limit1);
    }

    /// @return liquidity Amount of total liquidity in the base position
    /// @return amount0 Estimated amount of token0 that could be collected by
    /// burning the base position
    /// @return amount1 Estimated amount of token1 that could be collected by
    /// burning the base position
    function getBasePosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(
            baseLower,
            baseUpper
        );
        (amount0, amount1) = _amountsForLiquidity(baseLower, baseUpper, positionLiquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        liquidity = positionLiquidity;
    }

    /// @return liquidity Amount of total liquidity in the limit position
    /// @return amount0 Estimated amount of token0 that could be collected by
    /// burning the limit position
    /// @return amount1 Estimated amount of token1 that could be collected by
    /// burning the limit position
    function getLimitPosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(
            limitLower,
            limitUpper
        );
        (amount0, amount1) = _amountsForLiquidity(limitLower, limitUpper, positionLiquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        liquidity = positionLiquidity;
    }

    /// @notice Get the amounts of the given numbers of liquidity tokens
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param liquidity The amount of liquidity tokens
    /// @return Amount of token0 and token1
    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    /// @notice Get the liquidity amount of the given numbers of token0 and token1
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0
    /// @param amount0 The amount of token1
    /// @return Amount of liquidity tokens
    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amount0,
                amount1
            );
    }

    /// @return tick Uniswap pool's current price tick
    function currentTick() public view returns (int24 tick) {
        (, tick, , , , , ) = pool.slot0();
    }

    function _uint128Safe(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    /// @param _address Array of addresses to be appended
    function setWhitelist(address _address) external onlyOwner {
        whitelistedAddress = _address;
    }

    /// @notice Remove Whitelisted
    function removeWhitelisted() external onlyOwner {
        whitelistedAddress = address(0);
    }

    /// @notice Toggle Direct Deposit
    function toggleDirectDeposit() external onlyOwner {
        directDeposit = !directDeposit;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import {IUniswapV3Factory} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {TokeHypervisor} from './TokeHypervisor.sol';

/// @title TokeHypervisorFactory

contract TokeHypervisorFactory is Ownable {
    IUniswapV3Factory public uniswapV3Factory;
    mapping(address => mapping(address => mapping(uint24 => address))) public getHypervisor; // toke0, token1, fee -> hypervisor address
    address[] public allHypervisors;

    event HypervisorCreated(address token0, address token1, uint24 fee, address hypervisor, uint256);

    constructor(address _uniswapV3Factory) {
        require(_uniswapV3Factory != address(0), "uniswapV3Factory should be non-zero");
        uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
    }

    /// @notice Get the number of hypervisors created
    /// @return Number of hypervisors created
    function allHypervisorsLength() external view returns (uint256) {
        return allHypervisors.length;
    }

    /// @notice Create a Hypervisor
    /// @param tokenA Address of token0
    /// @param tokenB Address of toekn1
    /// @param fee The desired fee for the hypervisor
    /// @param name Name of the hyervisor
    /// @param symbol Symbole of the hypervisor
    /// @return hypervisor Address of hypervisor created
    function createHypervisor(
        address tokenA,
        address tokenB,
        uint24 fee,
        string memory name,
        string memory symbol
    ) external onlyOwner returns (address hypervisor) {
        require(tokenA != tokenB, 'SF: IDENTICAL_ADDRESSES'); // TODO: using PoolAddress library (uniswap-v3-periphery)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SF: ZERO_ADDRESS');
        require(getHypervisor[token0][token1][fee] == address(0), 'SF: HYPERVISOR_EXISTS');
        int24 tickSpacing = uniswapV3Factory.feeAmountTickSpacing(fee);
        require(tickSpacing != 0, 'SF: INCORRECT_FEE');
        address pool = uniswapV3Factory.getPool(token0, token1, fee);
        if (pool == address(0)) {
            pool = uniswapV3Factory.createPool(token0, token1, fee);
        }
        hypervisor = address(
            new TokeHypervisor{salt: keccak256(abi.encodePacked(token0, token1, fee, tickSpacing))}(pool, owner(), name, symbol)
        );

        getHypervisor[token0][token1][fee] = hypervisor;
        getHypervisor[token1][token0][fee] = hypervisor; // populate mapping in the reverse direction
        allHypervisors.push(hypervisor);
        emit HypervisorCreated(token0, token1, fee, hypervisor, allHypervisors.length);
    }
}

/// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

/// @title Clearing v1.2.3
/// @notice Proxy contract for hypervisor positions management
contract Clearing is ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  string constant VERSION = '1.2.3';
  address public owner;
  mapping(address => Position) public positions;

  bool public twapCheck = false;
  uint32 public twapInterval = 120;
  uint256 public depositDelta = 1010;
  uint256 public deltaScale = 1000; /// must be a power of 10
  uint256 public priceThreshold = 100;
  uint256 constant MAX_UINT = 2**256 - 1;

  struct Position {
    bool zeroDeposit;
    bool customRatio;
    bool customTwap;
    bool ratioRemoved;
    bool depositOverride; // force custom deposit constraints
    bool twapOverride; // force twap check for hypervisor instance
    uint8 version; 
    uint32 twapInterval; // override global twap
    uint256 priceThreshold; // custom price threshold
    uint256 deposit0Max;
    uint256 deposit1Max;
    uint256 maxTotalSupply;
    uint256 fauxTotal0;
    uint256 fauxTotal1;
    mapping(address=>bool) list; // whitelist certain accounts for freedeposit
  }

  event PositionAdded(address, uint8);
  event CustomDeposit(address, uint256, uint256, uint256);
  event PriceThresholdSet(uint256 _priceThreshold);
  event DepositDeltaSet(uint256 _depositDelta);
  event DeltaScaleSet(uint256 _deltaScale);
  event TwapIntervalSet(uint32 _twapInterval);
  event TwapOverrideSet(address pos, bool twapOverride, uint32 _twapInterval, uint256 _priceThreshold);
  event PriceThresholdPosSet(address pos, uint256 _priceThreshold);
  event DepositZeroToggled();
  event DepositOverrideToggled(address pos);
  event DepositZeroOverrideToggled(address pos);
  event TwapToggled();
  event ListAppended(address pos, address[] listed);
  event ListRemoved(address pos, address listed);
  event CustomRatio(address pos, uint256 fauxTotal0, uint256 fauxTotal1);
  event RatioRemoved(address pos);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyAddedPosition(address pos) {
    Position storage p = positions[pos];
    require(p.version != 0, "not added");
    _;
  }

  /// @notice Add the hypervisor position
  /// @param pos Address of the hypervisor
  /// @param version Type of hypervisor
  function addPosition(address pos, uint8 version) external onlyOwner {
    Position storage p = positions[pos];
    require(p.version == 0, 'already added');
    require(version > 0, 'version < 1');
    p.version = version;
    IHypervisor(pos).token0().safeApprove(pos, MAX_UINT);
    IHypervisor(pos).token1().safeApprove(pos, MAX_UINT);
    emit PositionAdded(pos, version);
  }

  /// @notice apply configuration constraints to shares minted 
  /// @param pos Address of the hypervisor
  /// @param shares Amount of shares minted (included for upgrades)
  /// @return cleared whether shares are cleared 
  function clearShares(
    address pos,
    uint256 shares 
  ) public view onlyAddedPosition(pos) returns (bool cleared) {
    if(positions[pos].maxTotalSupply != 0) {
      require(IHypervisor(pos).totalSupply() <= positions[pos].maxTotalSupply, "exceeds max supply");
    }
    return true;
  }

  /// @notice apply configuration constraints to deposit 
  /// @param pos Address of the hypervisor
  /// @param deposit0 Amount of token0 to deposit
  /// @param deposit1 Amount of token1 to deposit
  /// @param to Address to receive liquidity tokens
  /// @param pos Hypervisor Address
  /// @param minIn min assets to expect in position during a direct deposit 
  /// @return cleared whether deposit is cleared 
  function clearDeposit(
    uint256 deposit0,
    uint256 deposit1,
    address from,
    address to,
    address pos,
    uint256[4] memory minIn
  ) public view onlyAddedPosition(pos) returns (bool cleared) {
    require(to != address(0), "to should be non-zero");
    Position storage p = positions[pos];
    if(!positions[pos].list[from]) {
      if(!p.zeroDeposit) require(deposit0 > 0 && deposit1 > 0, "must deposit to both sides");
      if (deposit0 > 0 && !p.zeroDeposit) {
        (uint256 test1Min, uint256 test1Max) = getDepositAmount(pos, address(IHypervisor(pos).token0()), deposit0);
        require(deposit1 >= test1Min && deposit1 <= test1Max, "Improper ratio"); 
      }
      if (deposit1 > 0 && !p.zeroDeposit) {
        (uint256 test0Min, uint256 test0Max) = getDepositAmount(pos, address(IHypervisor(pos).token1()), deposit1);
        require(deposit0 >= test0Min && deposit0 <= test0Max, "Improper ratio"); 
      }
    }
    if (twapCheck || p.twapOverride) {
      /// check twap
      checkPriceChange(
        pos,
        (p.twapOverride ? p.twapInterval : twapInterval),
        (p.twapOverride ? p.priceThreshold : priceThreshold)
      );
    }

    if (p.depositOverride && !positions[pos].list[from]) {
      if (p.deposit0Max > 0) {
        require(deposit0 <= p.deposit0Max, "token0 exceeds");
      }
      if (p.deposit1Max > 0) {
        require(deposit1 <= p.deposit1Max, "token1 exceeds");
      }
    }
    return true;
  }

  /// @notice Get the amount of token to deposit for the given amount of pair token
  /// @param pos Hypervisor Address
  /// @param token Address of token to deposit
  /// @param _deposit Amount of token to deposit
  /// @return amountStart Minimum amounts of the pair token to deposit
  /// @return amountEnd Maximum amounts of the pair token to deposit
  function getDepositAmount(
    address pos,
    address token,
    uint256 _deposit
  ) public view returns (uint256 amountStart, uint256 amountEnd) {
    require(token == address(IHypervisor(pos).token0()) || token == address(IHypervisor(pos).token1()), "token mistmatch");
    require(_deposit > 0, "deposits can't be zero");
    (uint256 total0, uint256 total1) = IHypervisor(pos).getTotalAmounts();
    if (IHypervisor(pos).totalSupply() == 0 || total0 == 0 || total1 == 0) {
      amountStart = 0;
      if (token == address(IHypervisor(pos).token0())) {
        amountEnd = IHypervisor(pos).deposit1Max();
      } else {
        amountEnd = IHypervisor(pos).deposit0Max();
      }
    } else {
      (uint256 ratioStart, uint256 ratioEnd) = positions[pos].customRatio ? 
        applyRatio(pos, token, positions[pos].fauxTotal0, positions[pos].fauxTotal1) :
        applyRatio(pos, token, total0, total1);
      amountStart = FullMath.mulDiv(_deposit, 1e18, ratioStart);
      amountEnd = FullMath.mulDiv(_deposit, 1e18, ratioEnd);
    }
  }

  /// @notice Get range for deposit based on provided amounts
  /// @param pos Hypervisor Address
  /// @param token Address of token to deposit
  /// @param total0 Amount of token0 in hype 
  /// @param total1 Amount of token1 in hype 
  /// @return ratioStart Minimum amounts of the pair token to deposit
  /// @return ratioEnd Maximum amounts of the pair token to deposit
  function applyRatio(
    address pos,
    address token,
    uint256 total0,
    uint256 total1
  ) public view returns (uint256 ratioStart, uint256 ratioEnd) {
    require(token == address(IHypervisor(pos).token0()) || token == address(IHypervisor(pos).token1()), "token mistmatch");
    if (token == address(IHypervisor(pos).token0())) {
      ratioStart = FullMath.mulDiv(total0.mul(depositDelta), 1e18, total1.mul(deltaScale));
      ratioEnd = FullMath.mulDiv(total0.mul(deltaScale), 1e18, total1.mul(depositDelta));
    } else {
      ratioStart = FullMath.mulDiv(total1.mul(depositDelta), 1e18, total0.mul(deltaScale));
      ratioEnd = FullMath.mulDiv(total1.mul(deltaScale), 1e18, total0.mul(depositDelta));
    }
  }

  /// @notice Check if the price change overflows or not based on given twap and threshold in the hypervisor
  /// @param pos Hypervisor Address
  /// @param _twapInterval Time intervals
  /// @param _priceThreshold Price Threshold
  /// @return price Current price
  function checkPriceChange(
    address pos,
    uint32 _twapInterval,
    uint256 _priceThreshold
  ) public view returns (uint256 price) {
    uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(IHypervisor(pos).currentTick());
    price = FullMath.mulDiv(uint256(sqrtPrice).mul(uint256(sqrtPrice)), 1e18, 2**(96 * 2));

    uint160 sqrtPriceBefore = getSqrtTwapX96(pos, _twapInterval);
    uint256 priceBefore = FullMath.mulDiv(uint256(sqrtPriceBefore).mul(uint256(sqrtPriceBefore)), 1e18, 2**(96 * 2));
    if (price.mul(100).div(priceBefore) > _priceThreshold || priceBefore.mul(100).div(price) > _priceThreshold)
      revert("Price change Overflow");
  }

  /// @notice Get the sqrt price before the given interval
  /// @param pos Hypervisor Address
  /// @param _twapInterval Time intervals
  /// @return sqrtPriceX96 Sqrt price before interval
  function getSqrtTwapX96(address pos, uint32 _twapInterval) public view returns (uint160 sqrtPriceX96) {
    if (_twapInterval == 0) {
      /// return the current price if _twapInterval == 0
      (sqrtPriceX96, , , , , , ) = IHypervisor(pos).pool().slot0();
    } 
    else {
      uint32[] memory secondsAgos = new uint32[](2);
      secondsAgos[0] = _twapInterval; /// from (before)
      secondsAgos[1] = 0; /// to (now)

      (int56[] memory tickCumulatives, , ) = IHypervisor(pos).pool().observe(secondsAgos);

      /// tick(imprecise as it's an integer) to price
      sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
        int24((tickCumulatives[1] - tickCumulatives[0]) / _twapInterval)
      );
    }
  }

  /// @param _priceThreshold Price Threshold
  function setPriceThreshold(uint256 _priceThreshold) external onlyOwner {
    priceThreshold = _priceThreshold;
    emit PriceThresholdSet(_priceThreshold);
  }

  /// @param _depositDelta Number to calculate deposit ratio
  function setDepositDelta(uint256 _depositDelta) external onlyOwner {
    depositDelta = _depositDelta;
    emit DepositDeltaSet(_depositDelta);
  }

  /// @param _deltaScale Number to calculate deposit ratio
  function setDeltaScale(uint256 _deltaScale) external onlyOwner {
    deltaScale = _deltaScale;
    emit DeltaScaleSet(_deltaScale);
  }

  /// @param pos Hypervisor address
  /// @param deposit0Max Amount of maximum deposit amounts of token0
  /// @param deposit1Max Amount of maximum deposit amounts of token1
  /// @param maxTotalSupply Maximum total suppoy of hypervisor
  function customDeposit(
    address pos,
    uint256 deposit0Max,
    uint256 deposit1Max,
    uint256 maxTotalSupply
  ) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.deposit0Max = deposit0Max;
    p.deposit1Max = deposit1Max;
    p.maxTotalSupply = maxTotalSupply;
    emit CustomDeposit(pos, deposit0Max, deposit1Max, maxTotalSupply);
  }

  /// @param pos Hypervisor address
  /// @param customRatio whether to use custom ratio 
  /// @param fauxTotal0 override total0
  /// @param fauxTotal1 override total1 
  function customRatio(
    address pos,
    bool customRatio,
    uint256 fauxTotal0,
    uint256 fauxTotal1
  ) external onlyOwner onlyAddedPosition(pos) {
    require(!positions[pos].ratioRemoved, "custom ratio is no longer available");
    Position storage p = positions[pos];
    p.customRatio = customRatio;
    p.fauxTotal0 = fauxTotal0;
    p.fauxTotal1 = fauxTotal1;
    emit CustomRatio(pos, fauxTotal0, fauxTotal1);
  }

  // @note permantently remove ability to apply custom ratio to hype
  function removeRatio(address pos) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.ratioRemoved = true;
    emit RatioRemoved(pos);
  }

  /// @notice Toggle deposit override
  /// @param pos Hypervisor Address
  function toggleDepositOverride(address pos) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.depositOverride = !p.depositOverride;
    emit DepositOverrideToggled(pos);
  }

  /// @notice Toggle free deposit of the given hypervisor
  /// @param pos Hypervisor Address
  function toggleDepositZeroOverride(address pos) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.zeroDeposit = !p.zeroDeposit;
    emit DepositZeroOverrideToggled(pos);
  }

  /// @param _twapInterval Time intervals
  function setTwapInterval(uint32 _twapInterval) external onlyOwner {
    twapInterval = _twapInterval;
    emit TwapIntervalSet(_twapInterval);
  }

  /// @param pos Hypervisor Address
  /// @param twapOverride Twap Override
  /// @param _twapInterval Time Intervals
  /// @param _priceThreshold Price Threshold
  function setTwapOverride(address pos, bool twapOverride, uint32 _twapInterval, uint256 _priceThreshold) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.twapOverride = twapOverride;
    p.twapInterval = _twapInterval;
    p.priceThreshold = _priceThreshold;
    emit TwapOverrideSet(pos, twapOverride, _twapInterval, _priceThreshold);
  }

  /// @notice Twap Toggle
  function toggleTwap() external onlyOwner {
    twapCheck = !twapCheck;
    emit TwapToggled();
  }

  // @notice check if an address is whitelisted for hype
  function getListed(address pos, address i) public view returns(bool) {
    Position storage p = positions[pos];
    return p.list[i];
  }

  /// @notice Append whitelist to hypervisor
  /// @param pos Hypervisor Address
  /// @param listed Address array to add in whitelist
  function appendList(address pos, address[] memory listed) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    for (uint8 i; i < listed.length; i++) {
      p.list[listed[i]] = true;
    }
    emit ListAppended(pos, listed);
  }

  /// @notice Remove address from whitelist
  /// @param pos Hypervisor Address
  /// @param listed Address to remove from whitelist
  function removeListed(address pos, address listed) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.list[listed] = false;
    emit ListRemoved(pos, listed);
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "newOwner should be non-zero");
    owner = newOwner;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "only owner");
    _;
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/drafts/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/callback/IRamsesV2MintCallback.sol";
import "./interfaces/IRamsesV2Pool.sol";


import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

/// @title Hypervisor v1.3
/// @notice A Uniswap V2-like interface with fungible liquidity to RamsesV2
/// which allows for arbitrary liquidity provision: one-sided, lop-sided, and balanced
contract Hypervisor is IRamsesV2MintCallback, ERC20Permit, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    IRamsesV2Pool public pool;
    IERC20 public token0;
    IERC20 public token1;
    uint8 public fee = 7;
    int24 public tickSpacing;

    int24 public baseLower;
    int24 public baseUpper;
    int24 public limitLower;
    int24 public limitUpper;

    address public owner;
    uint256 public deposit0Max;
    uint256 public deposit1Max;
    uint256 public maxTotalSupply;
    address public whitelistedAddress;
    address public feeRecipient;
    bool public directDeposit; /// enter uni on deposit (avoid if client uses public rpc)

    uint256 public constant PRECISION = 1e36;

    bool mintCalled;

   event Deposit(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Withdraw(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Rebalance(
        int24 tick,
        uint256 totalAmount0,
        uint256 totalAmount1,
        uint256 feeAmount0,
        uint256 feeAmount1,
        uint256 totalSupply
    );

    event ZeroBurn(uint8 fee, uint256 fees0, uint256 fees1);
    event SetFee(uint8 newFee);


    /// @param _pool Ramses V2 pool for which liquidity is managed
    /// @param _owner Owner of the Hypervisor
    constructor(
        address _pool,
        address _owner,
        string memory name,
        string memory symbol
    ) ERC20Permit(name) ERC20(name, symbol) {
        require(_pool != address(0));
        require(_owner != address(0));
        pool = IRamsesV2Pool(_pool);
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
        require(address(token0) != address(0));
        require(address(token1) != address(0));
        tickSpacing = pool.tickSpacing();

        owner = _owner;

        maxTotalSupply = 0; /// no cap
        deposit0Max = uint256(-1);
        deposit1Max = uint256(-1);
    }

    /// @notice Deposit tokens
    /// @param deposit0 Amount of token0 transfered from sender to Hypervisor
    /// @param deposit1 Amount of token1 transfered from sender to Hypervisor
    /// @param to Address to which liquidity tokens are minted
    /// @param from Address from which asset tokens are transferred
    /// @param inMin min spend for directDeposit is true 
    /// @return shares Quantity of liquidity tokens minted as a result of deposit
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to,
        address from,
        uint256[4] memory inMin
    ) nonReentrant external returns (uint256 shares) {
        require(deposit0 > 0 || deposit1 > 0);
        require(deposit0 <= deposit0Max && deposit1 <= deposit1Max);
        require(to != address(0) && to != address(this), "to");
        require(msg.sender == whitelistedAddress, "WHE");

        /// update fees
        zeroBurn();

        uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(currentTick());
        uint256 price = FullMath.mulDiv(uint256(sqrtPrice).mul(uint256(sqrtPrice)), PRECISION, 2**(96 * 2));

        (uint256 pool0, uint256 pool1) = getTotalAmounts();

        shares = deposit1.add(deposit0.mul(price).div(PRECISION));

        if (deposit0 > 0) {
          token0.safeTransferFrom(from, address(this), deposit0);
        }
        if (deposit1 > 0) {
          token1.safeTransferFrom(from, address(this), deposit1);
        }

        uint256 total = totalSupply();
        if (total != 0) {
          uint256 pool0PricedInToken1 = pool0.mul(price).div(PRECISION);
          shares = shares.mul(total).div(pool0PricedInToken1.add(pool1));
          if (directDeposit) {
            uint128 liquidity = _liquidityForAmounts(
              baseLower,
              baseUpper, 
              token0.balanceOf(address(this)),
              token1.balanceOf(address(this))
            );
            _mintLiquidity(baseLower, baseUpper, liquidity, address(this), inMin[0], inMin[1]);
            liquidity = _liquidityForAmounts(
              limitLower,
              limitUpper, 
              token0.balanceOf(address(this)),
              token1.balanceOf(address(this))
            );
            _mintLiquidity(limitLower, limitUpper, liquidity, address(this), inMin[2], inMin[3]);
          }
        }
        _mint(to, shares);
        emit Deposit(from, to, shares, deposit0, deposit1);
        /// Check total supply cap not exceeded. A value of 0 means no limit.
        require(maxTotalSupply == 0 || total <= maxTotalSupply, "max");
    }

    function _zeroBurn(int24 tickLower, int24 tickUpper) internal returns(uint128 liquidity) {
      /// update fees for inclusion
      (liquidity, ,) = _position(tickLower, tickUpper);
      if(liquidity > 0) {
        pool.burn(tickLower, tickUpper, 0);
        (uint256 owed0, uint256 owed1) = pool.collect(address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max);
        emit ZeroBurn(fee, owed0, owed1);
        if (owed0.div(fee) > 0 && token0.balanceOf(address(this)) > 0) token0.safeTransfer(feeRecipient, owed0.div(fee));
        if (owed1.div(fee) > 0 && token1.balanceOf(address(this)) > 0) token1.safeTransfer(feeRecipient, owed1.div(fee));
      }      
    }

    /// @notice Update fees of the positions
    /// @return baseLiquidity Fee of base position
    /// @return limitLiquidity Fee of limit position
    function zeroBurn() internal returns(uint128 baseLiquidity, uint128 limitLiquidity) {
      baseLiquidity = _zeroBurn(baseLower, baseUpper);
      limitLiquidity = _zeroBurn(limitLower, limitUpper); 
    }

    /// @notice Pull liquidity tokens from liquidity and receive the tokens
    /// @param shares Number of liquidity tokens to pull from liquidity
    /// @param tickLower lower tick
    /// @param tickUpper upper tick
    /// @param amountMin min outs 
    /// @return amount0 amount of token0 received from base position
    /// @return amount1 amount of token1 received from base position
    function pullLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 shares,
        uint256[2] memory amountMin
    ) external onlyOwner returns (uint256 amount0, uint256 amount1) {
        _zeroBurn(tickLower, tickUpper);
        (amount0, amount1) = _burnLiquidity(
          tickLower,
          tickUpper,
          _liquidityForShares(tickLower, tickUpper, shares),
          address(this),
          false,
          amountMin[0],
          amountMin[1]
        );
    }

    /// @param shares Number of liquidity tokens to redeem as pool assets
    /// @param to Address to which redeemed pool assets are sent
    /// @param from Address from which liquidity tokens are sent
    /// @param minAmounts min amount0,1 returned for shares of liq 
    /// @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
    /// @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
    function withdraw(
        uint256 shares,
        address to,
        address from,
        uint256[4] memory minAmounts
    ) nonReentrant external returns (uint256 amount0, uint256 amount1) {
        require(shares > 0, "shares");
        require(to != address(0), "to");

        /// update fees
        zeroBurn();

        /// Withdraw liquidity from Ramses pool
        (uint256 base0, uint256 base1) = _burnLiquidity(
            baseLower,
            baseUpper,
            _liquidityForShares(baseLower, baseUpper, shares),
            to,
            false,
            minAmounts[0],
            minAmounts[1]
        );
        (uint256 limit0, uint256 limit1) = _burnLiquidity(
            limitLower,
            limitUpper,
            _liquidityForShares(limitLower, limitUpper, shares),
            to,
            false,
            minAmounts[2],
            minAmounts[3]
        );

        // Push tokens proportional to unused balances
        uint256 unusedAmount0 = token0.balanceOf(address(this)).mul(shares).div(totalSupply());
        uint256 unusedAmount1 = token1.balanceOf(address(this)).mul(shares).div(totalSupply());
        if (unusedAmount0 > 0) token0.safeTransfer(to, unusedAmount0);
        if (unusedAmount1 > 0) token1.safeTransfer(to, unusedAmount1);

        amount0 = base0.add(limit0).add(unusedAmount0);
        amount1 = base1.add(limit1).add(unusedAmount1);

        require( from == msg.sender, "own");
        _burn(from, shares);

        emit Withdraw(from, to, shares, amount0, amount1);
    }

    /// @param _baseLower The lower tick of the base position
    /// @param _baseUpper The upper tick of the base position
    /// @param _limitLower The lower tick of the limit position
    /// @param _limitUpper The upper tick of the limit position
    /// @param  inMin min spend 
    /// @param  outMin min amount0,1 returned for shares of liq 
    /// @param _feeRecipient Address of recipient of 10% of earned fees since last rebalance
    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        uint256[4] memory inMin, 
        uint256[4] memory outMin
    ) nonReentrant external onlyOwner {
        require(
            _baseLower < _baseUpper &&
                _baseLower % tickSpacing == 0 &&
                _baseUpper % tickSpacing == 0
        );
        require(
            _limitLower < _limitUpper &&
                _limitLower % tickSpacing == 0 &&
                _limitUpper % tickSpacing == 0
        );
        require(
          _limitUpper != _baseUpper ||
          _limitLower != _baseLower
        );
        require(_feeRecipient != address(0));
        feeRecipient = _feeRecipient;

        /// update fees
        zeroBurn();

        /// Withdraw all liquidity and collect all fees from Ramses pool
        (uint128 baseLiquidity, uint256 feesLimit0, uint256 feesLimit1) = _position(baseLower, baseUpper);
        (uint128 limitLiquidity, uint256 feesBase0, uint256 feesBase1) = _position(limitLower, limitUpper);

        _burnLiquidity(baseLower, baseUpper, baseLiquidity, address(this), true, outMin[0], outMin[1]);
        _burnLiquidity(limitLower, limitUpper, limitLiquidity, address(this), true, outMin[2], outMin[3]);

        emit Rebalance(
            currentTick(),
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this)),
            feesBase0.add(feesLimit0),
            feesBase1.add(feesLimit1),
            totalSupply()
        );

        baseLower = _baseLower;
        baseUpper = _baseUpper;
        baseLiquidity = _liquidityForAmounts(
          baseLower,
          baseUpper, 
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this))
        );
        _mintLiquidity(baseLower, baseUpper, baseLiquidity, address(this), inMin[0], inMin[1]);

        limitLower = _limitLower;
        limitUpper = _limitUpper;
        limitLiquidity = _liquidityForAmounts(
          limitLower,
          limitUpper, 
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this))
        );
        _mintLiquidity(limitLower, limitUpper, limitLiquidity, address(this), inMin[2], inMin[3]);
    }

    /// @notice Compound pending fees
    /// @param inMin min spend 
    /// @return baseToken0Owed Pending fees of base token0
    /// @return baseToken1Owed Pending fees of base token1
    /// @return limitToken0Owed Pending fees of limit token0
    /// @return limitToken1Owed Pending fees of limit token1
    function compound(uint256[4] memory inMin) external onlyOwner returns (
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed 
    ) {
        // update fees for compounding
        zeroBurn();

        uint128 liquidity = _liquidityForAmounts(
          baseLower,
          baseUpper, 
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this))
        );
        _mintLiquidity(baseLower, baseUpper, liquidity, address(this), inMin[0], inMin[1]);

        liquidity = _liquidityForAmounts(
          limitLower,
          limitUpper, 
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this))
        );
        _mintLiquidity(limitLower, limitUpper, liquidity, address(this), inMin[2], inMin[3]);
    }

    /// @notice Add Liquidity
    function addLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1,
        uint256[2] memory inMin
    ) public onlyOwner {        
        _zeroBurn(tickLower, tickUpper);
        uint128 liquidity = _liquidityForAmounts(tickLower, tickUpper, amount0, amount1);
        _mintLiquidity(tickLower, tickUpper, liquidity, address(this), inMin[0], inMin[1]);
    }

    /// @notice Adds the liquidity for the given position
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param liquidity The amount of liquidity to mint
    /// @param payer Payer Data
    /// @param amount0Min Minimum amount of token0 that should be paid
    /// @param amount1Min Minimum amount of token1 that should be paid
    function _mintLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address payer,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal {
        if (liquidity > 0) {
            mintCalled = true;
            (uint256 amount0, uint256 amount1) = pool.mint(
                address(this),
                tickLower,
                tickUpper,
                liquidity,
                abi.encode(payer)
            );
            require(amount0 >= amount0Min && amount1 >= amount1Min, 'PSC');
        }
    }

    /// @notice Burn liquidity from the sender and collect tokens owed for the liquidity
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param liquidity The amount of liquidity to burn
    /// @param to The address which should receive the fees collected
    /// @param collectAll If true, collect all tokens owed in the pool, else collect the owed tokens of the burn
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function _burnLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to,
        bool collectAll,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 amount0, uint256 amount1) {
        if (liquidity > 0) {
            /// Burn liquidity
            (uint256 owed0, uint256 owed1) = pool.burn(tickLower, tickUpper, liquidity);
            require(owed0 >= amount0Min && owed1 >= amount1Min, "PSC");

            // Collect amount owed
            uint128 collect0 = collectAll ? type(uint128).max : _uint128Safe(owed0);
            uint128 collect1 = collectAll ? type(uint128).max : _uint128Safe(owed1);
            if (collect0 > 0 || collect1 > 0) {
                (amount0, amount1) = pool.collect(to, tickLower, tickUpper, collect0, collect1);
            }
        }
    }

    /// @notice Get the liquidity amount for given liquidity tokens
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param shares Shares of position
    /// @return The amount of liquidity toekn for shares
    function _liquidityForShares(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares
    ) internal view returns (uint128) {
        (uint128 position, , ) = _position(tickLower, tickUpper);
        return _uint128Safe(uint256(position).mul(shares).div(totalSupply()));
    }

    /// @notice Get the info of the given position
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return liquidity The amount of liquidity of the position
    /// @return tokensOwed0 Amount of token0 owed
    /// @return tokensOwed1 Amount of token1 owed
    function _position(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), uint256(0), tickLower, tickUpper));
        (liquidity, , , tokensOwed0, tokensOwed1, ) = pool.positions(positionKey);
    }

    /// @notice Callback function of RamsesV2Pool mint
    function ramsesV2MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        require(mintCalled == true);
        mintCalled = false;

        if (amount0 > 0) token0.safeTransfer(msg.sender, amount0);
        if (amount1 > 0) token1.safeTransfer(msg.sender, amount1);
    }

    /// @return total0 Quantity of token0 in both positions and unused in the Hypervisor
    /// @return total1 Quantity of token1 in both positions and unused in the Hypervisor
    function getTotalAmounts() public view returns (uint256 total0, uint256 total1) {
        (, uint256 base0, uint256 base1) = getBasePosition();
        (, uint256 limit0, uint256 limit1) = getLimitPosition();
        total0 = token0.balanceOf(address(this)).add(base0).add(limit0);
        total1 = token1.balanceOf(address(this)).add(base1).add(limit1);
    }

    /// @return liquidity Amount of total liquidity in the base position
    /// @return amount0 Estimated amount of token0 that could be collected by
    /// burning the base position
    /// @return amount1 Estimated amount of token1 that could be collected by
    /// burning the base position
    function getBasePosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(
            baseLower,
            baseUpper
        );
        (amount0, amount1) = _amountsForLiquidity(baseLower, baseUpper, positionLiquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        liquidity = positionLiquidity;
    }

    /// @return liquidity Amount of total liquidity in the limit position
    /// @return amount0 Estimated amount of token0 that could be collected by
    /// burning the limit position
    /// @return amount1 Estimated amount of token1 that could be collected by
    /// burning the limit position
    function getLimitPosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(
            limitLower,
            limitUpper
        );
        (amount0, amount1) = _amountsForLiquidity(limitLower, limitUpper, positionLiquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        liquidity = positionLiquidity;
    }

    /// @notice Get the amounts of the given numbers of liquidity tokens
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param liquidity The amount of liquidity tokens
    /// @return Amount of token0 and token1
    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    /// @notice Get the liquidity amount of the given numbers of token0 and token1
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0
    /// @param amount0 The amount of token1
    /// @return Amount of liquidity tokens
    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amount0,
                amount1
            );
    }

    /// @return tick Ramses pool's current price tick
    function currentTick() public view returns (int24 tick) {
        (, tick, , , , , ) = pool.slot0();
    }

    function _uint128Safe(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    /// @param _address Array of addresses to be appended
    function setWhitelist(address _address) external onlyOwner {
        whitelistedAddress = _address;
    }

    /// @notice Remove Whitelisted
    function removeWhitelisted() external onlyOwner {
        whitelistedAddress = address(0);
    }

    /// @notice set fee 
    function setFee(uint8 newFee) external onlyOwner {
        fee = newFee;
        emit SetFee(fee);
    }

    /// @notice Toggle Direct Deposit
    function toggleDirectDeposit() external onlyOwner {
        directDeposit = !directDeposit;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import {IUniswapV3Factory} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {Hypervisor} from './Hypervisor.sol';

/// @title HypervisorFactory

contract HypervisorFactory is Ownable {
    IUniswapV3Factory public uniswapV3Factory;
    mapping(address => mapping(address => mapping(uint24 => address))) public getHypervisor; // toke0, token1, fee -> hypervisor address
    address[] public allHypervisors;

    event HypervisorCreated(address token0, address token1, uint24 fee, address hypervisor, uint256);

    constructor(address _uniswapV3Factory) {
        require(_uniswapV3Factory != address(0), "uniswapV3Factory should be non-zero");
        uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
    }

    /// @notice Get the number of hypervisors created
    /// @return Number of hypervisors created
    function allHypervisorsLength() external view returns (uint256) {
        return allHypervisors.length;
    }

    /// @notice Create a Hypervisor
    /// @param tokenA Address of token0
    /// @param tokenB Address of toekn1
    /// @param fee The desired fee for the hypervisor
    /// @param name Name of the hyervisor
    /// @param symbol Symbole of the hypervisor
    /// @return hypervisor Address of hypervisor created
    function createHypervisor(
        address tokenA,
        address tokenB,
        uint24 fee,
        string memory name,
        string memory symbol
    ) external onlyOwner returns (address hypervisor) {
        require(tokenA != tokenB, 'SF: IDENTICAL_ADDRESSES'); // TODO: using PoolAddress library (uniswap-v3-periphery)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SF: ZERO_ADDRESS');
        require(getHypervisor[token0][token1][fee] == address(0), 'SF: HYPERVISOR_EXISTS');
        int24 tickSpacing = uniswapV3Factory.feeAmountTickSpacing(fee);
        require(tickSpacing != 0, 'SF: INCORRECT_FEE');
        address pool = uniswapV3Factory.getPool(token0, token1, fee);
        if (pool == address(0)) {
            pool = uniswapV3Factory.createPool(token0, token1, fee);
        }
        hypervisor = address(
            new Hypervisor{salt: keccak256(abi.encodePacked(token0, token1, fee, tickSpacing))}(pool, owner(), name, symbol)
        );

        getHypervisor[token0][token1][fee] = hypervisor;
        getHypervisor[token1][token0][fee] = hypervisor; // populate mapping in the reverse direction
        allHypervisors.push(hypervisor);
        emit HypervisorCreated(token0, token1, fee, hypervisor, allHypervisors.length);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IRamsesV2PoolActions#mint
/// @notice Any contract that calls IRamsesV2PoolActions#mint must implement this interface
interface IRamsesV2MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IRamsesV2Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a RamsesV2Pool deployed by the canonical RamsesV2Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IRamsesV2PoolActions#mint call
    function ramsesV2MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0 <0.9.0;

interface IGaugeV2 {
    /// @notice Emitted when a reward notification is made.
    /// @param from The address from which the reward is notified.
    /// @param reward The address of the reward token.
    /// @param amount The amount of rewards notified.
    /// @param period The period for which the rewards are notified.
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount,
        uint256 period
    );

    /// @notice Emitted when a bribe is made.
    /// @param from The address from which the bribe is made.
    /// @param reward The address of the reward token.
    /// @param amount The amount of tokens bribed.
    /// @param period The period for which the bribe is made.
    event Bribe(
        address indexed from,
        address indexed reward,
        uint256 amount,
        uint256 period
    );

    /// @notice Emitted when rewards are claimed.
    /// @param period The period for which the rewards are claimed.
    /// @param _positionHash The identifier of the NFP for which rewards are claimed.
    /// @param receiver The address of the receiver of the claimed rewards.
    /// @param reward The address of the reward token.
    /// @param amount The amount of rewards claimed.
    event ClaimRewards(
        uint256 period,
        bytes32 _positionHash,
        address receiver,
        address reward,
        uint256 amount
    );

    /// @notice Initializes the contract with the provided gaugeFactory, voter, and pool addresses.
    /// @param _gaugeFactory The address of the gaugeFactory to set.
    /// @param _voter The address of the voter to set.
    /// @param _nfpManager The address of the NFP manager to set.
    /// @param _feeCollector The address of the fee collector to set.
    /// @param _pool The address of the pool to set.
    function initialize(
        address _gaugeFactory,
        address _voter,
        address _nfpManager,
        address _feeCollector,
        address _pool
    ) external;

    /// @notice Retrieves the value of the firstPeriod variable.
    /// @return The value of the firstPeriod variable.
    function firstPeriod() external returns (uint256);

    /// @notice Retrieves the total supply of a specific token for a given period.
    /// @param period The period for which to retrieve the total supply.
    /// @param token The address of the token for which to retrieve the total supply.
    /// @return The total supply of the specified token for the given period.
    function tokenTotalSupplyByPeriod(
        uint256 period,
        address token
    ) external view returns (uint256);

    /// @notice Retrieves the total boosted seconds for a specific period.
    /// @param period The period for which to retrieve the total boosted seconds.
    /// @return The total boosted seconds for the specified period.
    function periodTotalBoostedSeconds(
        uint256 period
    ) external view returns (uint256);

    /// @notice Retrieves the getTokenTotalSupplyByPeriod of the current period.
    /// @dev included to support voter's left() check during distribute().
    /// @param token The address of the token for which to retrieve the remaining amount.
    /// @return The amount of tokens returned by getTokenTotalSupplyByPeriod.
    function left(address token) external view returns (uint256);

    /// @notice Retrieves the reward rate for a specific reward address.
    /// @dev this method returns the base rate without boost
    /// @param token The address of the reward for which to retrieve the reward rate.
    /// @return The reward rate for the specified reward address.
    function rewardRate(address token) external view returns (uint256);

    /// @notice Retrieves the claimed amount for a specific period, position hash, and user address.
    /// @param period The period for which to retrieve the claimed amount.
    /// @param _positionHash The identifier of the NFP for which to retrieve the claimed amount.
    /// @param reward The address of the token for the claimed amount.
    /// @return The claimed amount for the specified period, token ID, and user address.
    function periodClaimedAmount(
        uint256 period,
        bytes32 _positionHash,
        address reward
    ) external view returns (uint256);

    /// @notice Retrieves the last claimed period for a specific token, token ID combination.
    /// @param token The address of the reward token for which to retrieve the last claimed period.
    /// @param _positionHash The identifier of the NFP for which to retrieve the last claimed period.
    /// @return The last claimed period for the specified token and token ID.
    function lastClaimByToken(
        address token,
        bytes32 _positionHash
    ) external view returns (uint256);

    /// @notice Retrieves the reward address at the specified index in the rewards array.
    /// @param index The index of the reward address to retrieve.
    /// @return The reward address at the specified index.
    function rewards(uint256 index) external view returns (address);

    /// @notice Checks if a given address is a valid reward.
    /// @param reward The address to check.
    /// @return A boolean indicating whether the address is a valid reward.
    function isReward(address reward) external view returns (bool);

    /// @notice Returns an array of reward token addresses.
    /// @return An array of reward token addresses.
    function getRewardTokens() external view returns (address[] memory);
    
    function getReward(
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        address[] calldata tokens,
        address receiver
    ) external;
    
    /// @notice Returns the hash used to store positions in a mapping
    /// @param owner The address of the position owner
    /// @param index The index of the position
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @return _hash The hash used to store positions in a mapping
    function positionHash(
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) external pure returns (bytes32);

    /// @notice Retrieves the liquidity and boosted liquidity for a specific NFP.
    /// @param tokenId The identifier of the NFP.
    /// @return liquidity The liquidity of the position token.
    /// @return boostedLiquidity The boosted liquidity of the position token.
    /// @return veRamTokenId The attached veRam token
    function positionInfo(
        uint256 tokenId
    ) external view returns (uint128 liquidity, uint128 boostedLiquidity,uint256 veRamTokenId);

    /// @notice Returns the amount of rewards earned for an NFP.
    /// @param token The address of the token for which to retrieve the earned rewards.
    /// @param tokenId The identifier of the specific NFP for which to retrieve the earned rewards.
    /// @return reward The amount of rewards earned for the specified NFP and tokens.
    function earned(
        address token,
        uint256 tokenId
    ) external view returns (uint256 reward);

    /// @notice Returns the amount of rewards earned during a period for an NFP.
    /// @param period The period for which to retrieve the earned rewards.
    /// @param token The address of the token for which to retrieve the earned rewards.
    /// @param tokenId The identifier of the specific NFP for which to retrieve the earned rewards.
    /// @return reward The amount of rewards earned for the specified NFP and tokens.
    function periodEarned(
        uint256 period,
        address token,
        uint256 tokenId
    ) external view returns (uint256);

    /// @notice Retrieves the earned rewards for a specific period, token, owner, index, tickLower, and tickUpper.
    /// @param period The period for which to retrieve the earned rewards.
    /// @param token The address of the token for which to retrieve the earned rewards.
    /// @param owner The address of the owner for which to retrieve the earned rewards.
    /// @param index The index for which to retrieve the earned rewards.
    /// @param tickLower The tick lower bound for which to retrieve the earned rewards.
    /// @param tickUpper The tick upper bound for which to retrieve the earned rewards.
    /// @return The earned rewards for the specified period, token, owner, index, tickLower, and tickUpper.
    function periodEarned(
        uint256 period,
        address token,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint256);

    /// @notice Retrieves the earned rewards for a specific period, token, owner, index, tickLower, and tickUpper.
    /// @dev used by getReward() and saves gas by saving states
    /// @param period The period for which to retrieve the earned rewards.
    /// @param token The address of the token for which to retrieve the earned rewards.
    /// @param owner The address of the owner for which to retrieve the earned rewards.
    /// @param index The index for which to retrieve the earned rewards.
    /// @param tickLower The tick lower bound for which to retrieve the earned rewards.
    /// @param tickUpper The tick upper bound for which to retrieve the earned rewards.
    /// @param caching Whether to cache the results or not.
    /// @return The earned rewards for the specified period, token, owner, index, tickLower, and tickUpper.
    function cachePeriodEarned(
        uint256 period,
        address token,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        bool caching
    ) external returns (uint256);

    /// @notice Notifies the contract about the amount of rewards to be distributed for a specific token.
    /// @param token The address of the token for which to notify the reward amount.
    /// @param amount The amount of rewards to be distributed.
    function notifyRewardAmount(address token, uint256 amount) external;

    /// @notice Retrieves the reward amount for a specific period, NFP, and token addresses.
    /// @param period The period for which to retrieve the reward amount.
    /// @param tokens The addresses of the tokens for which to retrieve the reward amount.
    /// @param tokenId The identifier of the specific NFP for which to retrieve the reward amount.
    /// @param receiver The address of the receiver of the reward amount.
    function getPeriodReward(
        uint256 period,
        address[] calldata tokens,
        uint256 tokenId,
        address receiver
    ) external;

    /// @notice Retrieves the rewards for a specific period, set of tokens, owner, index, tickLower, tickUpper, and receiver.
    /// @param period The period for which to retrieve the rewards.
    /// @param tokens An array of token addresses for which to retrieve the rewards.
    /// @param owner The address of the owner for which to retrieve the rewards.
    /// @param index The index for which to retrieve the rewards.
    /// @param tickLower The tick lower bound for which to retrieve the rewards.
    /// @param tickUpper The tick upper bound for which to retrieve the rewards.
    /// @param receiver The address of the receiver of the rewards.
    function getPeriodReward(
        uint256 period,
        address[] calldata tokens,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        address receiver
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRamsesV2Pool.sol";

interface IHypervisor {

  function deposit(
      uint256,
      uint256,
      address,
      address,
      uint256[4] memory minIn
  ) external returns (uint256);

  function withdraw(
    uint256,
    address,
    address,
    uint256[4] memory
  ) external returns (uint256, uint256);

  function compound() external returns (

    uint128 baseToken0Owed,
    uint128 baseToken1Owed,
    uint128 limitToken0Owed,
    uint128 limitToken1Owed
  );

  function compound(uint256[4] memory inMin) external returns (

    uint128 baseToken0Owed,
    uint128 baseToken1Owed,
    uint128 limitToken0Owed,
    uint128 limitToken1Owed
  );


  function rebalance(
    int24 _baseLower,
    int24 _baseUpper,
    int24 _limitLower,
    int24 _limitUpper,
    address _feeRecipient,
    uint256[4] memory minIn, 
    uint256[4] memory outMin
    ) external;

  function addBaseLiquidity(
    uint256 amount0, 
    uint256 amount1,
    uint256[2] memory minIn
  ) external;

  function addLimitLiquidity(
    uint256 amount0, 
    uint256 amount1,
    uint256[2] memory minIn
  ) external;   

  function pullLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint128 shares,
    uint256[2] memory amountMin
  ) external returns (
    uint256 base0,
    uint256 base1
  );

  function pullLiquidity(
    uint256 shares,
    uint256[4] memory minAmounts 
  ) external returns(
      uint256 base0,
      uint256 base1,
      uint256 limit0,
      uint256 limit1
  );

  function addLiquidity(
      int24 tickLower,
      int24 tickUpper,
      uint256 amount0,
      uint256 amount1,
      uint256[2] memory inMin
  ) external;


  function pool() external view returns (IRamsesV2Pool);

  function currentTick() external view returns (int24 tick);
  
  function tickSpacing() external view returns (int24 spacing);

  function baseLower() external view returns (int24 tick);

  function baseUpper() external view returns (int24 tick);

  function limitLower() external view returns (int24 tick);

  function limitUpper() external view returns (int24 tick);

  function token0() external view returns (IERC20);

  function token1() external view returns (IERC20);

  function deposit0Max() external view returns (uint256);

  function deposit1Max() external view returns (uint256);

  function balanceOf(address) external view returns (uint256);

  function approve(address, uint256) external returns (bool);

  function transferFrom(address, address, uint256) external returns (bool);

  function transfer(address, uint256) external returns (bool);

  function getTotalAmounts() external view returns (uint256 total0, uint256 total1);
  
  function getBasePosition() external view returns (uint256 liquidity, uint256 total0, uint256 total1);

  function totalSupply() external view returns (uint256 );

  function setWhitelist(address _address) external;
  
  function setFee(uint8 newFee) external;

  function transferReceiver(address newReceiver) external; 
  
  function removeWhitelisted() external;

  function transferOwnership(address newOwner) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./pool/IRamsesV2PoolImmutables.sol";
import "./pool/IRamsesV2PoolState.sol";
import "./pool/IRamsesV2PoolDerivedState.sol";
import "./pool/IRamsesV2PoolActions.sol";
import "./pool/IRamsesV2PoolOwnerActions.sol";
import "./pool/IRamsesV2PoolEvents.sol";

/// @title The interface for a Ramses V2 Pool
/// @notice A Ramses pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IRamsesV2Pool is
    IRamsesV2PoolImmutables,
    IRamsesV2PoolState,
    IRamsesV2PoolDerivedState,
    IRamsesV2PoolActions,
    IRamsesV2PoolOwnerActions,
    IRamsesV2PoolEvents
{
    /// @notice Initializes a pool with parameters provided
    function initialize(
        address _factory,
        address _nfpManager,
        address _veRam,
        address _voter,
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickSpacing
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6 || ^0.8.13;
pragma abicoder v2;

interface IVoter {
    function _ve() external view returns (address);

    function governor() external view returns (address);

    function emergencyCouncil() external view returns (address);

    function attachTokenToGauge(uint256 _tokenId, address account) external;

    function detachTokenFromGauge(uint256 _tokenId, address account) external;

    function emitDeposit(
        uint256 _tokenId,
        address account,
        uint256 amount
    ) external;

    function emitWithdraw(
        uint256 _tokenId,
        address account,
        uint256 amount
    ) external;

    function isWhitelisted(address token) external view returns (bool);

    function notifyRewardAmount(uint256 amount) external;

    function distribute(address _gauge) external;

    function gauges(address pool) external view returns (address);

    function feeDistributers(address gauge) external view returns (address);

    function gaugefactory() external view returns (address);

    function feeDistributorFactory() external view returns (address);

    function minter() external view returns (address);

    function factory() external view returns (address);

    function length() external view returns (uint256);

    function pools(uint256) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IRamsesV2PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position at index 0
    /// @dev The caller of this method receives a callback in the form of IRamsesV2MintCallback#ramsesV2MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IRamsesV2MintCallback#ramsesV2MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param index The index for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param veRamTokenId The veRam tokenId to attach to the position
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 veRamTokenId,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param index The index of the position to be collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position at index 0
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param index The index for which the liquidity will be burned
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param index The index for which the liquidity will be burned
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @param veRamTokenId The veRam Token Id to attach
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 veRamTokenId
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IRamsesV2SwapCallback#ramsesV2SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IRamsesV2FlashCallback#ramsesV2FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(
        uint16 observationCardinalityNext
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IRamsesV2PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerBoostedLiquidityPeriodX128s Cumulative seconds per boosted liquidity-in-range value as of each `secondsAgos` from the current block timestamp
    function observe(
        uint32[] calldata secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s,
            uint160[] memory secondsPerBoostedLiquidityPeriodX128s
        );

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken. Boosted data is only valid if it's within the same period
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsPerBoostedLiquidityInsideX128 The snapshot of seconds per boosted liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint160 secondsPerBoostedLiquidityInsideX128,
            uint32 secondsInside
        );

    /// @notice Returns the seconds per liquidity and seconds inside a tick range for a period
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsPerBoostedLiquidityInsideX128 The snapshot of seconds per boosted liquidity for the range
    function periodCumulativesInside(
        uint32 period,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            uint160 secondsPerLiquidityInsideX128,
            uint160 secondsPerBoostedLiquidityInsideX128
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IRamsesV2PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IRamsesV2PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IRamsesV2Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The contract that manages RamsesV2 NFPs, which must adhere to the INonfungiblePositionManager interface
    /// @return The contract address
    function nfpManager() external view returns (address);

    /// @notice The contract that manages veRamses NFTs, which must adhere to the IVotinEscrow interface
    /// @return The contract address
    function veRam() external view returns (address);

    /// @notice The contract that manages Ramses votes, which must adhere to the IVoter interface
    /// @return The contract address
    function voter() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IRamsesV2PoolOwnerActions {
    /// @notice Set the protocol's % share of the fees
    /// @dev Fees start at 50%, with 5% increments
    function setFeeProtocol() external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IRamsesV2PoolState {
    /// @notice reads arbitrary storage slots and returns the bytes
    /// @param slots The slots to read from
    /// @return returnData The data read from the slots
    function readStorage(
        bytes32[] calldata slots
    ) external view returns (bytes32[] memory returnData);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice Returns the last tick of a given period
    /// @param period The period in question
    /// @return previousPeriod The period before current period
    /// @dev this is because there might be periods without trades
    ///  startTick The start tick of the period
    ///  lastTick The last tick of the period, if the period is finished
    ///  endSecondsPerLiquidityPeriodX128 Seconds per liquidity at period's end
    ///  endSecondsPerBoostedLiquidityPeriodX128 Seconds per boosted liquidity at period's end
    function periods(
        uint256 period
    )
        external
        view
        returns (
            uint32 previousPeriod,
            int24 startTick,
            int24 lastTick,
            uint160 endSecondsPerLiquidityCumulativeX128,
            uint160 endSecondsPerBoostedLiquidityCumulativeX128,
            uint32 boostedInRange
        );

    /// @notice The last period where a trade or liquidity change happened
    function lastPeriod() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees()
        external
        view
        returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice The currently in range derived liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function boostedLiquidity() external view returns (uint128);

    /// @notice Get the boost information for a specific position at a period
    /// @return boostAmount the amount of boost this position has for this period,
    /// veRamAmount the amount of veRam attached to this position for this period,
    /// secondsDebtX96 used to account for changes in the deposit amount during the period
    /// boostedSecondsDebtX96 used to account for changes in the boostAmount and veRam locked during the period,
    function boostInfos(
        uint256 period,
        bytes32 key
    )
        external
        view
        returns (
            uint128 boostAmount,
            int128 veRamAmount,
            int256 secondsDebtX96,
            int256 boostedSecondsDebtX96
        );

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(
        int24 tick
    )
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint128 boostedLiquidityGross,
            int128 boostedLiquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    /// Returns attachedVeRamId the veRam tokenId attached to the position
    function positions(
        bytes32 key
    )
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1,
            uint256 attachedVeRamId
        );

    /// @notice Returns a period's total boost amount and total veRam attached
    /// @param period Period timestamp
    /// @return totalBoostAmount The total amount of boost this period has,
    /// Returns totalVeRamAmount The total amount of veRam attached to this period
    function boostInfos(
        uint256 period
    ) external view returns (uint128 totalBoostAmount, int128 totalVeRamAmount);

    /// @notice Get the period seconds debt of a specific position
    /// @param period the period number
    /// @param recipient recipient address
    /// @param index position index
    /// @param tickLower lower bound of range
    /// @param tickUpper upper bound of range
    /// @return secondsDebtX96 seconds the position was not in range for the period
    /// @return boostedSecondsDebtX96 boosted seconds the period
    function positionPeriodDebt(
        uint256 period,
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (int256 secondsDebtX96, int256 boostedSecondsDebtX96);

    /// @notice get the period seconds in range of a specific position
    /// @param period the period number
    /// @param owner owner address
    /// @param index position index
    /// @param tickLower lower bound of range
    /// @param tickUpper upper bound of range
    /// @return periodSecondsInsideX96 seconds the position was not in range for the period
    /// @return periodBoostedSecondsInsideX96 boosted seconds the period
    function positionPeriodSecondsInRange(
        uint256 period,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            uint256 periodSecondsInsideX96,
            uint256 periodBoostedSecondsInsideX96
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(
        uint256 index
    )
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized,
            uint160 secondsPerBoostedLiquidityPeriodX128
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {IUniswapV3Factory} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import {IUniswapV3MintCallback} from '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol';
import {IUniswapV3SwapCallback} from '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import {IERC20Minimal} from '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';
import {IUniswapV3PoolDeployer} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3PoolDeployer.sol';

import {TickMath} from '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import {LowGasSafeMath} from '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import {TransferHelper} from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import {LiquidityAmounts} from '@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol';

contract MockUniswapV3Pool is IUniswapV3MintCallback, IUniswapV3SwapCallback, IERC20Minimal {
    using LowGasSafeMath for uint256;

    address public immutable token0;
    address public immutable token1;

    uint24 public fee;
    int24 public tickSpacing;

    IUniswapV3Pool public currentPool;
    IUniswapV3Factory public immutable uniswapFactory;

    int24 private constant MIN_TICK = -887220;
    int24 private constant MAX_TICK = 887220;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor() {
        (address _uniswapFactory, address _token0, address _token1, uint24 _fee, int24 _tickSpacing) =
            IUniswapV3PoolDeployer(msg.sender).parameters();
        token0 = _token0;
        token1 = _token1;
        uniswapFactory = IUniswapV3Factory(_uniswapFactory);

        fee = _fee;
        tickSpacing = _tickSpacing;

        address uniswapPool = IUniswapV3Factory(_uniswapFactory).getPool(_token0, _token1, _fee);
        require(uniswapPool != address(0));
        currentPool = IUniswapV3Pool(uniswapPool);
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function deposit(
        int24 lowerTick,
        int24 upperTick,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256 rest0, uint256 rest1) {
        (uint160 sqrtRatioX96, , , , , , ) = currentPool.slot0();

        // First, deposit as much as we can
        uint128 baseLiquidity =
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(lowerTick),
                TickMath.getSqrtRatioAtTick(upperTick),
                amount0,
                amount1
            );
        (uint256 amountDeposited0, uint256 amountDeposited1) =
            currentPool.mint(msg.sender, lowerTick, upperTick, baseLiquidity, abi.encode(msg.sender));
        rest0 = amount0 - amountDeposited0;
        rest1 = amount1 - amountDeposited1;
    }

    function swap(bool zeroForOne, int256 amountSpecified) external {
        (uint160 sqrtRatio, , , , , , ) = currentPool.slot0();
        currentPool.swap(
            address(this),
            zeroForOne,
            amountSpecified,
            zeroForOne ? sqrtRatio - 1 : sqrtRatio + 1,
            abi.encode(msg.sender)
        );
    }

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        require(msg.sender == address(currentPool));

        address sender = abi.decode(data, (address));

        if (sender == address(this)) {
            if (amount0Owed > 0) {
                TransferHelper.safeTransfer(token0, msg.sender, amount0Owed);
            }
            if (amount1Owed > 0) {
                TransferHelper.safeTransfer(token1, msg.sender, amount1Owed);
            }
        } else {
            if (amount0Owed > 0) {
                TransferHelper.safeTransferFrom(token0, sender, msg.sender, amount0Owed);
            }
            if (amount1Owed > 0) {
                TransferHelper.safeTransferFrom(token1, sender, msg.sender, amount1Owed);
            }
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        require(msg.sender == address(currentPool));

        address sender = abi.decode(data, (address));

        if (amount0Delta > 0) {
            TransferHelper.safeTransferFrom(token0, sender, msg.sender, uint256(amount0Delta));
        } else if (amount1Delta > 0) {
            TransferHelper.safeTransferFrom(token1, sender, msg.sender, uint256(amount1Delta));
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        uint256 balanceBefore = _balances[msg.sender];
        require(balanceBefore >= amount, 'insufficient balance');
        _balances[msg.sender] = balanceBefore - amount;

        uint256 balanceRecipient = _balances[recipient];
        require(balanceRecipient + amount >= balanceRecipient, 'recipient balance overflow');
        _balances[recipient] = balanceRecipient + amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 allowanceBefore = allowance[sender][msg.sender];
        require(allowanceBefore >= amount, 'allowance insufficient');

        allowance[sender][msg.sender] = allowanceBefore - amount;

        uint256 balanceRecipient = _balances[recipient];
        require(balanceRecipient + amount >= balanceRecipient, 'overflow balance recipient');
        _balances[recipient] = balanceRecipient + amount;
        uint256 balanceSender = _balances[sender];
        require(balanceSender >= amount, 'underflow balance sender');
        _balances[sender] = balanceSender - amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        uint256 balanceNext = _balances[to] + amount;
        require(balanceNext >= amount, 'overflow balance');
        _balances[to] = balanceNext;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import {IUniswapV3PoolDeployer} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3PoolDeployer.sol';
import {MockUniswapV3Pool} from './MockUniswapV3Pool.sol';

contract MockUniswapV3PoolDeployer is IUniswapV3PoolDeployer {
    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
    }

    Parameters public override parameters;

    event PoolDeployed(address pool);

    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) external returns (address pool) {
        parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});
        pool = address(new MockUniswapV3Pool{salt: keccak256(abi.encodePacked(token0, token1, fee, tickSpacing))}());
        emit PoolDeployed(pool);
        delete parameters;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import {IERC20Minimal} from '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';

contract TestERC20 is IERC20Minimal {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(uint256 amountToMint) {
        mint(msg.sender, amountToMint);
    }

    function mint(address to, uint256 amount) public {
        uint256 balanceNext = balanceOf[to] + amount;
        require(balanceNext >= amount, 'overflow balance');
        balanceOf[to] = balanceNext;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        uint256 balanceBefore = balanceOf[msg.sender];
        require(balanceBefore >= amount, 'insufficient balance');
        balanceOf[msg.sender] = balanceBefore - amount;

        uint256 balanceRecipient = balanceOf[recipient];
        require(balanceRecipient + amount >= balanceRecipient, 'recipient balance overflow');
        balanceOf[recipient] = balanceRecipient + amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 allowanceBefore = allowance[sender][msg.sender];
        require(allowanceBefore >= amount, 'allowance insufficient');

        allowance[sender][msg.sender] = allowanceBefore - amount;

        uint256 balanceRecipient = balanceOf[recipient];
        require(balanceRecipient + amount >= balanceRecipient, 'overflow balance recipient');
        balanceOf[recipient] = balanceRecipient + amount;
        uint256 balanceSender = balanceOf[sender];
        require(balanceSender >= amount, 'underflow balance sender');
        balanceOf[sender] = balanceSender - amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Admin

contract Admin {

    address public admin;
		bool public ownerFixed = false;
    mapping(address => address) public rebalancers;
    mapping(address => address) public advisors;

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyAdvisor(address hypervisor) {
        require(msg.sender == advisors[hypervisor], "only advisor");
        _;
    }

    modifier onlyRebalancer(address hypervisor) {
        require(msg.sender == rebalancers[hypervisor], "only rebalancer");
        _;
    }

    constructor(address _admin) {
        admin = _admin;
    }

    /// @param _hypervisor Hypervisor Address
    /// @param _baseLower The lower tick of the base position
    /// @param _baseUpper The upper tick of the base position
    /// @param _limitLower The lower tick of the limit position
    /// @param _limitUpper The upper tick of the limit position
    /// @param _feeRecipient Address of recipient of 10% of earned fees since last rebalance
    function rebalance(
        address _hypervisor,
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        uint256[4] memory inMin, 
        uint256[4] memory outMin
    ) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).rebalance(_baseLower, _baseUpper, _limitLower, _limitUpper, _feeRecipient, inMin, outMin);
    }

    /// @notice Pull liquidity tokens from liquidity and receive the tokens
    /// @param _hypervisor Hypervisor Address
    /// @param tickLower lower tick
    /// @param tickUpper upper tick
    /// @param shares Number of liquidity tokens to pull from liquidity
    /// @return base0 amount of token0 received from base position
    /// @return base1 amount of token1 received from base position
    function pullLiquidity(
      address _hypervisor,
      int24 tickLower,
      int24 tickUpper,
      uint128 shares,
      uint256[2] memory minAmounts
    ) external onlyRebalancer(_hypervisor) returns(
        uint256 base0,
        uint256 base1
      ) {
      (base0, base1) = IHypervisor(_hypervisor).pullLiquidity(tickLower, tickUpper, shares, minAmounts);
    }

    function pullLiquidity(
      address _hypervisor,
      uint256 shares,
      uint256[4] memory minAmounts 
    ) external onlyRebalancer(_hypervisor) returns(
        uint256 base0,
        uint256 base1,
        uint256 limit0,
        uint256 limit1
      ) {
      (base0, base1, limit0, limit1) = IHypervisor(_hypervisor).pullLiquidity(shares, minAmounts);
    }

    function addLiquidity(
        address _hypervisor,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1,
        uint256[2] memory inMin
    ) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).addLiquidity(tickLower, tickUpper, amount0, amount1, inMin);
    }

    /// @notice Add tokens to base liquidity
    /// @param _hypervisor Hypervisor Address
    /// @param amount0 Amount of token0 to add
    /// @param amount1 Amount of token1 to add
    function addBaseLiquidity(address _hypervisor, uint256 amount0, uint256 amount1, uint256[2] memory inMin) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).addBaseLiquidity(amount0, amount1, inMin);
    }

    /// @notice Add tokens to limit liquidity
    /// @param _hypervisor Hypervisor Address
    /// @param amount0 Amount of token0 to add
    /// @param amount1 Amount of token1 to add
    function addLimitLiquidity(address _hypervisor, uint256 amount0, uint256 amount1, uint256[2] memory inMin) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).addLimitLiquidity(amount0, amount1, inMin);
    }

    /// @notice compound pending fees 
    /// @param _hypervisor Hypervisor Address
    function compound( address _hypervisor) external onlyAdvisor(_hypervisor) returns(
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed,
        uint256[4] memory inMin
    ) {
        IHypervisor(_hypervisor).compound();
    }

    function compound( address _hypervisor, uint256[4] memory inMin)
      external onlyAdvisor(_hypervisor) returns(
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed
    ) {
        IHypervisor(_hypervisor).compound(inMin);
    }

    /// @param _hypervisor Hypervisor Address
    function removeWhitelisted(address _hypervisor) external onlyAdmin {
        IHypervisor(_hypervisor).removeWhitelisted();
    }

    /// @param newAdmin New Admin Address
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "newAdmin should be non-zero");
        admin = newAdmin;
    }

    /// @param _hypervisor Hypervisor Address
    /// @param newOwner New Owner Address
    function transferHypervisorOwner(address _hypervisor, address newOwner) external onlyAdmin {
		require(!ownerFixed, "permanent owner in place");
        IHypervisor(_hypervisor).transferOwnership(newOwner);
    }

    /// @param _hypervisor Hypervisor Address
    /// @param newReceiver New Receiver Address
    function transferReceiver(address _hypervisor, address newReceiver) external onlyAdmin {
        require(newReceiver != address(0), "newReceiver should be non-zero");
        IHypervisor(_hypervisor).transferReceiver(newReceiver);
    }
	// @dev permanently disable hypervisor ownership transfer 
	function fixOwnership() external onlyAdmin {
		ownerFixed = false;
	}

    /// @param newAdvisor New Advisor Address
    function setAdvisor(address _hypervisor, address newAdvisor) external onlyAdmin {
        require(newAdvisor != address(0), "newAdvisor should be non-zero");
        advisors[_hypervisor] = newAdvisor;
    }

    /// @param newRebalancer New Rebalancer Address
    function setRebalancer(address _hypervisor, address newRebalancer) external onlyAdmin {
        require(newRebalancer != address(0), "newRebalancer should be non-zero");
        rebalancers[_hypervisor] = newRebalancer;
    }

    /// @notice Transfer tokens to the recipient from the contract
    /// @param token Address of token
    /// @param recipient Recipient Address
    function rescueERC20(IERC20 token, address recipient) external onlyAdmin {
        require(recipient != address(0), "recipient should be non-zero");
        require(token.transfer(recipient, token.balanceOf(address(this))));
    }

    /// @param _hypervisor Hypervisor Address
    /// @param newFee fee amount 
    function setFee(address _hypervisor, uint8 newFee) external onlyAdmin {
        IHypervisor(_hypervisor).setFee(newFee);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

contract AutoRebal {
    using SafeMath for uint256;

    address public admin;
    address public advisor;
    address public feeRecipient;
    IUniswapV3Pool public pool;
    IHypervisor public hypervisor;
    int24 public limitWidth = 1;

    modifier onlyAdvisor {
        require(msg.sender == advisor, "only advisor");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(address _admin, address _advisor, address _hypervisor) {
        require(_admin != address(0), "_admin should be non-zero");
        require(_advisor != address(0), "_advisor should be non-zero");
        require(_hypervisor != address(0), "_hypervisor should be non-zero");
        admin = _admin;
        advisor = _advisor;
        hypervisor = IHypervisor(_hypervisor);
    }

    function liquidityOptions() public view returns(bool, int24 currentTick) {

        (uint256 total0, uint256 total1) = hypervisor.getTotalAmounts();

        uint160 sqrtRatioX96;
        (sqrtRatioX96, currentTick, , , , , ) = hypervisor.pool().slot0();

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(hypervisor.baseLower()),
            TickMath.getSqrtRatioAtTick(hypervisor.baseUpper()),
            total0,
            total1 
        );
  
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(hypervisor.baseLower()),
            TickMath.getSqrtRatioAtTick(hypervisor.baseUpper()),
            liquidity
        );

        uint256 price = FullMath.mulDiv(uint256(sqrtRatioX96), (uint256(sqrtRatioX96)), 2**(96 * 2));
        return ((total0-amount0) * price > (total1-amount1), currentTick);

    }

    /// @param  outMin min amount0,1 returned for shares of liq 
    function autoRebalance(
        uint256[4] memory outMin
    ) external onlyAdvisor returns(int24 limitLower, int24 limitUpper) {
      
        (bool token0Limit, int24 currentTick) = liquidityOptions(); 

        if(!token0Limit) {
            // extra token1 in limit position = limit below
            limitUpper = (currentTick / hypervisor.tickSpacing()) * hypervisor.tickSpacing() - hypervisor.tickSpacing();
            if(limitUpper == currentTick) limitUpper = limitUpper - hypervisor.tickSpacing();

            limitLower = limitUpper - hypervisor.tickSpacing() * limitWidth; 
        }
        else {
            // extra token0 in limit position = limit above
            limitLower = (currentTick / hypervisor.tickSpacing()) * hypervisor.tickSpacing() + hypervisor.tickSpacing();
            if(limitLower == currentTick) limitLower = limitLower + hypervisor.tickSpacing();

            limitUpper = limitLower + hypervisor.tickSpacing() * limitWidth; 
        } 

        uint256[4] memory inMin;
        hypervisor.rebalance(
            hypervisor.baseLower(),
            hypervisor.baseUpper(),
            limitLower,
            limitUpper,
            feeRecipient,
            inMin,
            outMin 
        ); 
    }

    /// @notice compound pending fees 
    function compound() external onlyAdvisor returns(
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed,
        uint256[4] memory inMin
    ) {
        hypervisor.compound();
    }

    /// @param newAdmin New Admin Address
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "newAdmin should be non-zero");
        admin = newAdmin;
    }

    /// @notice Transfer tokens to recipient from the contract
    /// @param token Address of token
    /// @param recipient Recipient Address
    function rescueERC20(IERC20 token, address recipient) external onlyAdmin {
        require(recipient != address(0), "recipient should be non-zero");
        require(token.transfer(recipient, token.balanceOf(address(this))));
    }

    /// @param _recipient fee recipient 
    function setRecipient(address _recipient) external onlyAdmin {
        require(feeRecipient == address(0), "fee recipient already set");
        feeRecipient = _recipient;
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/drafts/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/callback/IRamsesV2MintCallback.sol";
import "./interfaces/IRamsesV2Pool.sol";
import "./interfaces/IGaugeV2.sol";
import "./interfaces/IVoter.sol";


import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

/// @title Hypervisor v1.3
/// @notice A Uniswap V2-like interface with fungible liquidity to RamsesV2
/// which allows for arbitrary liquidity provision: one-sided, lop-sided, and balanced
contract RamsesHypervisor is IRamsesV2MintCallback, ERC20Permit, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    IRamsesV2Pool public pool;
    IGaugeV2 public gauge;
    IERC20 public token0;
    IERC20 public token1;
    uint8 public fee = 7;
    int24 public tickSpacing;

    int24 public baseLower;
    int24 public baseUpper;
    int24 public limitLower;
    int24 public limitUpper;

    address public owner;
    address public voter;
    address public receiver;
    uint256 public deposit0Max;
    uint256 public deposit1Max;
    uint256 public maxTotalSupply;
    address public whitelistedAddress;
    address public feeRecipient;
    bool public directDeposit; /// enter uni on deposit (avoid if client uses public rpc)

    uint256 public constant PRECISION = 1e36;

    bool mintCalled;

   event Deposit(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Withdraw(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Rebalance(
        int24 tick,
        uint256 totalAmount0,
        uint256 totalAmount1,
        uint256 feeAmount0,
        uint256 feeAmount1,
        uint256 totalSupply
    );

    event ZeroBurn(uint8 fee, uint256 fees0, uint256 fees1);
    event SetFee(uint8 newFee);


    /// @param _pool Ramses V2 pool for which liquidity is managed
    /// @param _owner Owner of the Hypervisor
    /// @param _voter Voter contract address
    /// @param _receiver Rewards receiver address 
    constructor(
        address _pool,
        address _owner,
        address _voter, 
        address _receiver, 
        string memory name,
        string memory symbol
    ) ERC20Permit(name) ERC20(name, symbol) {
        require(_pool != address(0));
        require(_owner != address(0));
        require(_voter != address(0));
        require(_receiver != address(0));
        pool = IRamsesV2Pool(_pool);
        IVoter voterContract = IVoter(_voter); // Cast _voter to the IVoter interface
        gauge = IGaugeV2(voterContract.gauges(_pool)); // Fetch the gauge address using the Voter contract
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
        require(address(token0) != address(0));
        require(address(token1) != address(0));
        tickSpacing = pool.tickSpacing();

        owner = _owner;
        receiver = _receiver;
        voter = _voter;
        
        maxTotalSupply = 0; /// no cap
        deposit0Max = uint256(-1);
        deposit1Max = uint256(-1);
    }

    /// @notice Deposit tokens
    /// @param deposit0 Amount of token0 transfered from sender to Hypervisor
    /// @param deposit1 Amount of token1 transfered from sender to Hypervisor
    /// @param to Address to which liquidity tokens are minted
    /// @param from Address from which asset tokens are transferred
    /// @param inMin min spend for directDeposit is true 
    /// @return shares Quantity of liquidity tokens minted as a result of deposit
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to,
        address from,
        uint256[4] memory inMin
    ) nonReentrant external returns (uint256 shares) {
        require(deposit0 > 0 || deposit1 > 0);
        require(deposit0 <= deposit0Max && deposit1 <= deposit1Max);
        require(to != address(0) && to != address(this), "to");
        require(msg.sender == whitelistedAddress, "WHE");

        /// update fees
        zeroBurn();

        /// get rewards
        _getReward();


        uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(currentTick());
        uint256 price = FullMath.mulDiv(uint256(sqrtPrice).mul(uint256(sqrtPrice)), PRECISION, 2**(96 * 2));

        (uint256 pool0, uint256 pool1) = getTotalAmounts();

        shares = deposit1.add(deposit0.mul(price).div(PRECISION));

        if (deposit0 > 0) {
          token0.safeTransferFrom(from, address(this), deposit0);
        }
        if (deposit1 > 0) {
          token1.safeTransferFrom(from, address(this), deposit1);
        }

        uint256 total = totalSupply();
        if (total != 0) {
          uint256 pool0PricedInToken1 = pool0.mul(price).div(PRECISION);
          shares = shares.mul(total).div(pool0PricedInToken1.add(pool1));
          if (directDeposit) {
            uint128 liquidity = _liquidityForAmounts(
              baseLower,
              baseUpper, 
              token0.balanceOf(address(this)),
              token1.balanceOf(address(this))
            );
            _mintLiquidity(baseLower, baseUpper, liquidity, address(this), inMin[0], inMin[1]);
            liquidity = _liquidityForAmounts(
              limitLower,
              limitUpper, 
              token0.balanceOf(address(this)),
              token1.balanceOf(address(this))
            );
            _mintLiquidity(limitLower, limitUpper, liquidity, address(this), inMin[2], inMin[3]);
          }
        }
        _mint(to, shares);
        emit Deposit(from, to, shares, deposit0, deposit1);
        /// Check total supply cap not exceeded. A value of 0 means no limit.
        require(maxTotalSupply == 0 || total <= maxTotalSupply, "max");
    }

    function _zeroBurn(int24 tickLower, int24 tickUpper) internal returns(uint128 liquidity) {
      /// update fees for inclusion
      (liquidity, ,) = _position(tickLower, tickUpper);
      if(liquidity > 0) {
        pool.burn(tickLower, tickUpper, 0);
        (uint256 owed0, uint256 owed1) = pool.collect(address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max);
        emit ZeroBurn(fee, owed0, owed1);
        if (owed0.div(fee) > 0 && token0.balanceOf(address(this)) > 0) token0.safeTransfer(feeRecipient, owed0.div(fee));
        if (owed1.div(fee) > 0 && token1.balanceOf(address(this)) > 0) token1.safeTransfer(feeRecipient, owed1.div(fee));
      }      
    }
    

    /// @notice Update fees of the positions
    /// @return baseLiquidity Fee of base position
    /// @return limitLiquidity Fee of limit position
    function zeroBurn() internal returns(uint128 baseLiquidity, uint128 limitLiquidity) {
      baseLiquidity = _zeroBurn(baseLower, baseUpper);
      limitLiquidity = _zeroBurn(limitLower, limitUpper); 
    }

    function _getReward() internal {
        address[] memory rewardTokens = gauge.getRewardTokens();
        gauge.getReward(address(this), uint256(0), baseLower, baseUpper, rewardTokens, receiver);
        gauge.getReward(address(this), uint256(0), limitLower, limitUpper, rewardTokens, receiver);
    }



    /// @notice Pull liquidity tokens from liquidity and receive the tokens
    /// @param shares Number of liquidity tokens to pull from liquidity
    /// @param tickLower lower tick
    /// @param tickUpper upper tick
    /// @param amountMin min outs 
    /// @return amount0 amount of token0 received from base position
    /// @return amount1 amount of token1 received from base position
    function pullLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 shares,
        uint256[2] memory amountMin
    ) external onlyOwner returns (uint256 amount0, uint256 amount1) {
        _zeroBurn(tickLower, tickUpper);
        (amount0, amount1) = _burnLiquidity(
          tickLower,
          tickUpper,
          _liquidityForShares(tickLower, tickUpper, shares),
          address(this),
          false,
          amountMin[0],
          amountMin[1]
        );
    }

    /// @param shares Number of liquidity tokens to redeem as pool assets
    /// @param to Address to which redeemed pool assets are sent
    /// @param from Address from which liquidity tokens are sent
    /// @param minAmounts min amount0,1 returned for shares of liq 
    /// @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
    /// @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
    function withdraw(
        uint256 shares,
        address to,
        address from,
        uint256[4] memory minAmounts
    ) nonReentrant external returns (uint256 amount0, uint256 amount1) {
        require(shares > 0, "shares");
        require(to != address(0), "to");

        /// update fees
        zeroBurn();

        /// get rewards
        _getReward();

        /// Withdraw liquidity from Ramses pool
        (uint256 base0, uint256 base1) = _burnLiquidity(
            baseLower,
            baseUpper,
            _liquidityForShares(baseLower, baseUpper, shares),
            to,
            false,
            minAmounts[0],
            minAmounts[1]
        );
        (uint256 limit0, uint256 limit1) = _burnLiquidity(
            limitLower,
            limitUpper,
            _liquidityForShares(limitLower, limitUpper, shares),
            to,
            false,
            minAmounts[2],
            minAmounts[3]
        );

        // Push tokens proportional to unused balances
        uint256 unusedAmount0 = token0.balanceOf(address(this)).mul(shares).div(totalSupply());
        uint256 unusedAmount1 = token1.balanceOf(address(this)).mul(shares).div(totalSupply());
        if (unusedAmount0 > 0) token0.safeTransfer(to, unusedAmount0);
        if (unusedAmount1 > 0) token1.safeTransfer(to, unusedAmount1);

        amount0 = base0.add(limit0).add(unusedAmount0);
        amount1 = base1.add(limit1).add(unusedAmount1);

        require( from == msg.sender, "own");
        _burn(from, shares);

        emit Withdraw(from, to, shares, amount0, amount1);
    }

    /// @param _baseLower The lower tick of the base position
    /// @param _baseUpper The upper tick of the base position
    /// @param _limitLower The lower tick of the limit position
    /// @param _limitUpper The upper tick of the limit position
    /// @param  inMin min spend 
    /// @param  outMin min amount0,1 returned for shares of liq 
    /// @param _feeRecipient Address of recipient of 10% of earned fees since last rebalance
    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        uint256[4] memory inMin, 
        uint256[4] memory outMin
    ) nonReentrant external onlyOwner {
        require(
            _baseLower < _baseUpper &&
                _baseLower % tickSpacing == 0 &&
                _baseUpper % tickSpacing == 0
        );
        require(
            _limitLower < _limitUpper &&
                _limitLower % tickSpacing == 0 &&
                _limitUpper % tickSpacing == 0
        );
        require(
          _limitUpper != _baseUpper ||
          _limitLower != _baseLower
        );
        require(_feeRecipient != address(0));
        feeRecipient = _feeRecipient;

        /// update fees
        zeroBurn();

        /// get rewards
        _getReward();

        /// Withdraw all liquidity and collect all fees from Ramses pool
        (uint128 baseLiquidity, uint256 feesLimit0, uint256 feesLimit1) = _position(baseLower, baseUpper);
        (uint128 limitLiquidity, uint256 feesBase0, uint256 feesBase1) = _position(limitLower, limitUpper);

        _burnLiquidity(baseLower, baseUpper, baseLiquidity, address(this), true, outMin[0], outMin[1]);
        _burnLiquidity(limitLower, limitUpper, limitLiquidity, address(this), true, outMin[2], outMin[3]);

        emit Rebalance(
            currentTick(),
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this)),
            feesBase0.add(feesLimit0),
            feesBase1.add(feesLimit1),
            totalSupply()
        );

        baseLower = _baseLower;
        baseUpper = _baseUpper;
        baseLiquidity = _liquidityForAmounts(
          baseLower,
          baseUpper, 
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this))
        );
        _mintLiquidity(baseLower, baseUpper, baseLiquidity, address(this), inMin[0], inMin[1]);

        limitLower = _limitLower;
        limitUpper = _limitUpper;
        limitLiquidity = _liquidityForAmounts(
          limitLower,
          limitUpper, 
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this))
        );
        _mintLiquidity(limitLower, limitUpper, limitLiquidity, address(this), inMin[2], inMin[3]);
    }

    /// @notice Compound pending fees
    /// @param inMin min spend 
    /// @return baseToken0Owed Pending fees of base token0
    /// @return baseToken1Owed Pending fees of base token1
    /// @return limitToken0Owed Pending fees of limit token0
    /// @return limitToken1Owed Pending fees of limit token1
    function compound(uint256[4] memory inMin) external onlyOwner returns (
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed 
    ) {
        // update fees for compounding
        zeroBurn();

        /// get rewards
        _getReward();

        uint128 liquidity = _liquidityForAmounts(
          baseLower,
          baseUpper, 
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this))
        );
        _mintLiquidity(baseLower, baseUpper, liquidity, address(this), inMin[0], inMin[1]);

        liquidity = _liquidityForAmounts(
          limitLower,
          limitUpper, 
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this))
        );
        _mintLiquidity(limitLower, limitUpper, liquidity, address(this), inMin[2], inMin[3]);
    }

    /// @notice Add Liquidity
    function addLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1,
        uint256[2] memory inMin
    ) public onlyOwner {        
        _zeroBurn(tickLower, tickUpper);
        uint128 liquidity = _liquidityForAmounts(tickLower, tickUpper, amount0, amount1);
        _mintLiquidity(tickLower, tickUpper, liquidity, address(this), inMin[0], inMin[1]);
    }

    /// @notice Adds the liquidity for the given position
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param liquidity The amount of liquidity to mint
    /// @param payer Payer Data
    /// @param amount0Min Minimum amount of token0 that should be paid
    /// @param amount1Min Minimum amount of token1 that should be paid
    function _mintLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address payer,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal {
        if (liquidity > 0) {
            mintCalled = true;
            (uint256 amount0, uint256 amount1) = pool.mint(
                address(this),
                tickLower,
                tickUpper,
                liquidity,
                abi.encode(payer)
            );
            require(amount0 >= amount0Min && amount1 >= amount1Min, 'PSC');
        }
    }

    /// @notice Burn liquidity from the sender and collect tokens owed for the liquidity
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param liquidity The amount of liquidity to burn
    /// @param to The address which should receive the fees collected
    /// @param collectAll If true, collect all tokens owed in the pool, else collect the owed tokens of the burn
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function _burnLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to,
        bool collectAll,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 amount0, uint256 amount1) {
        if (liquidity > 0) {
            /// Burn liquidity
            (uint256 owed0, uint256 owed1) = pool.burn(tickLower, tickUpper, liquidity);
            require(owed0 >= amount0Min && owed1 >= amount1Min, "PSC");

            // Collect amount owed
            uint128 collect0 = collectAll ? type(uint128).max : _uint128Safe(owed0);
            uint128 collect1 = collectAll ? type(uint128).max : _uint128Safe(owed1);
            if (collect0 > 0 || collect1 > 0) {
                (amount0, amount1) = pool.collect(to, tickLower, tickUpper, collect0, collect1);
            }
        }
    }

    /// @notice Get the liquidity amount for given liquidity tokens
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param shares Shares of position
    /// @return The amount of liquidity toekn for shares
    function _liquidityForShares(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares
    ) internal view returns (uint128) {
        (uint128 position, , ) = _position(tickLower, tickUpper);
        return _uint128Safe(uint256(position).mul(shares).div(totalSupply()));
    }

    /// @notice Get the info of the given position
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return liquidity The amount of liquidity of the position
    /// @return tokensOwed0 Amount of token0 owed
    /// @return tokensOwed1 Amount of token1 owed
    function _position(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), uint256(0), tickLower, tickUpper));
        (liquidity, , , tokensOwed0, tokensOwed1, ) = pool.positions(positionKey);
    }

    /// @notice Callback function of RamsesV2Pool mint
    function ramsesV2MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        require(mintCalled == true);
        mintCalled = false;

        if (amount0 > 0) token0.safeTransfer(msg.sender, amount0);
        if (amount1 > 0) token1.safeTransfer(msg.sender, amount1);
    }

    /// @return total0 Quantity of token0 in both positions and unused in the Hypervisor
    /// @return total1 Quantity of token1 in both positions and unused in the Hypervisor
    function getTotalAmounts() public view returns (uint256 total0, uint256 total1) {
        (, uint256 base0, uint256 base1) = getBasePosition();
        (, uint256 limit0, uint256 limit1) = getLimitPosition();
        total0 = token0.balanceOf(address(this)).add(base0).add(limit0);
        total1 = token1.balanceOf(address(this)).add(base1).add(limit1);
    }

    /// @return liquidity Amount of total liquidity in the base position
    /// @return amount0 Estimated amount of token0 that could be collected by
    /// burning the base position
    /// @return amount1 Estimated amount of token1 that could be collected by
    /// burning the base position
    function getBasePosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(
            baseLower,
            baseUpper
        );
        (amount0, amount1) = _amountsForLiquidity(baseLower, baseUpper, positionLiquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        liquidity = positionLiquidity;
    }

    /// @return liquidity Amount of total liquidity in the limit position
    /// @return amount0 Estimated amount of token0 that could be collected by
    /// burning the limit position
    /// @return amount1 Estimated amount of token1 that could be collected by
    /// burning the limit position
    function getLimitPosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(
            limitLower,
            limitUpper
        );
        (amount0, amount1) = _amountsForLiquidity(limitLower, limitUpper, positionLiquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        liquidity = positionLiquidity;
    }

    /// @notice Get the amounts of the given numbers of liquidity tokens
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param liquidity The amount of liquidity tokens
    /// @return Amount of token0 and token1
    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    /// @notice Get the liquidity amount of the given numbers of token0 and token1
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0
    /// @param amount0 The amount of token1
    /// @return Amount of liquidity tokens
    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amount0,
                amount1
            );
    }

    /// @return tick Ramses pool's current price tick
    function currentTick() public view returns (int24 tick) {
        (, tick, , , , , ) = pool.slot0();
    }

    function _uint128Safe(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    /// @param _address Array of addresses to be appended
    function setWhitelist(address _address) external onlyOwner {
        whitelistedAddress = _address;
    }

    /// @notice Remove Whitelisted
    function removeWhitelisted() external onlyOwner {
        whitelistedAddress = address(0);
    }

    /// @notice set fee 
    function setFee(uint8 newFee) external onlyOwner {
        fee = newFee;
        emit SetFee(fee);
    }

    /// @notice Toggle Direct Deposit
    function toggleDirectDeposit() external onlyOwner {
        directDeposit = !directDeposit;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
    function transferReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0));
        receiver = newReceiver;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MintableToken is Ownable, ERC20 {
    constructor() public ERC20("ACCT", "ACCT") { }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol) {
        _setupDecimals(decimals);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

/**
 * @title  TestRouter
 * @dev    DO NOT USE IN PRODUCTION. This is only intended to be used for
 *         tests and lacks slippage and callback caller checks.
 */
contract TestRouter is IUniswapV3MintCallback, IUniswapV3SwapCallback {
    using SafeERC20 for IERC20;

    function mint(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256, uint256) {
        int24 tickSpacing = pool.tickSpacing();
        require(tickLower % tickSpacing == 0, "tickLower must be a multiple of tickSpacing");
        require(tickUpper % tickSpacing == 0, "tickUpper must be a multiple of tickSpacing");
        return pool.mint(msg.sender, tickLower, tickUpper, amount, abi.encode(msg.sender));
    }

    function swap(
        IUniswapV3Pool pool,
        bool zeroForOne,
        int256 amountSpecified
    ) external returns (int256, int256) {
        return
            pool.swap(
                msg.sender,
                zeroForOne,
                amountSpecified,
                zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
                abi.encode(msg.sender)
            );
    }

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        _callback(amount0Owed, amount1Owed, data);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        uint256 amount0 = amount0Delta > 0 ? uint256(amount0Delta) : 0;
        uint256 amount1 = amount1Delta > 0 ? uint256(amount1Delta) : 0;
        _callback(amount0, amount1, data);
    }

    function _callback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) internal {
        IUniswapV3Pool pool = IUniswapV3Pool(msg.sender);
        address payer = abi.decode(data, (address));

        IERC20(pool.token0()).safeTransferFrom(payer, msg.sender, amount0);
        IERC20(pool.token1()).safeTransferFrom(payer, msg.sender, amount1);
    }
}

/// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IClearing {

	function clearDeposit(
    uint256 deposit0,
    uint256 deposit1,
    address from,
    address to,
    address pos,
    uint256[4] memory minIn
  ) external view returns (bool cleared);

	function clearShares(
    address pos,
    uint256 shares
  ) external view returns (bool cleared);

  function getDepositAmount(
    address pos,
    address token,
    uint256 _deposit
  ) external view returns (uint256 amountStart, uint256 amountEnd);
}

/// @title UniProxy v1.2.3
/// @notice Proxy contract for hypervisor positions management
contract UniProxy is ReentrancyGuard {

	IClearing public clearance;
  address public owner;

  constructor(address _clearance) {
    owner = msg.sender;
		clearance = IClearing(_clearance);	
  }

  /// @notice Deposit into the given position
  /// @param deposit0 Amount of token0 to deposit
  /// @param deposit1 Amount of token1 to deposit
  /// @param to Address to receive liquidity tokens
  /// @param pos Hypervisor Address
  /// @param minIn min assets to expect in position during a direct deposit 
  /// @return shares Amount of liquidity tokens received
  function deposit(
    uint256 deposit0,
    uint256 deposit1,
    address to,
    address pos,
    uint256[4] memory minIn
  ) nonReentrant external returns (uint256 shares) {
    require(to != address(0), "to should be non-zero");
		require(clearance.clearDeposit(deposit0, deposit1, msg.sender, to, pos, minIn), "deposit not cleared");

		/// transfer assets from msg.sender and mint lp tokens to provided address 
		shares = IHypervisor(pos).deposit(deposit0, deposit1, to, msg.sender, minIn);
		require(clearance.clearShares(pos, shares), "shares not cleared");
  }

  /// @notice Get the amount of token to deposit for the given amount of pair token
  /// @param pos Hypervisor Address
  /// @param token Address of token to deposit
  /// @param _deposit Amount of token to deposit
  /// @return amountStart Minimum amounts of the pair token to deposit
  /// @return amountEnd Maximum amounts of the pair token to deposit
  function getDepositAmount(
    address pos,
    address token,
    uint256 _deposit
  ) public view returns (uint256 amountStart, uint256 amountEnd) {
		return clearance.getDepositAmount(pos, token, _deposit);
	}

	function transferClearance(address newClearance) external onlyOwner {
    require(newClearance != address(0), "newClearance should be non-zero");
		clearance = IClearing(newClearance);
	}

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "newOwner should be non-zero");
    owner = newOwner;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "only owner");
    _;
  }
}