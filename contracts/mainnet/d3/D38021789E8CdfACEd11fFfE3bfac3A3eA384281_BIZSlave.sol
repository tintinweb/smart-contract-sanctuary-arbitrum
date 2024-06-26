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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageChannel is IMessageStruct {
    /*
        /// @notice LaunchPad is the function that user or DApps send omni-chain message to other chain
        ///         Once the message is sent, the Relay will validate the message and send it to the target chain
        /// @dev 1. we will call the LaunchPad.Launch function to emit the message
        /// @dev 2. the message will be sent to the destination chain
        /// @param earliestArrivalTimestamp The earliest arrival time for the message
        ///        set to 0, vizing will forward the information ASAP.
        /// @param latestArrivalTimestamp The latest arrival time for the message
        ///        set to 0, vizing will forward the information ASAP.
        /// @param relayer the specify relayer for your message
        ///        set to 0, all the relayers will be able to forward the message
        /// @param sender The sender address for the message
        ///        most likely the address of the EOA, the user of some DApps
        /// @param value native token amount, will be sent to the target contract
        /// @param destChainid The destination chain id for the message
        /// @param additionParams The addition params for the message
        ///        if not in expert mode, set to 0 (`new bytes(0)`)
        /// @param message Arbitrary information
        ///
        ///    bytes                         
        ///   message  = abi.encodePacked(
        ///         byte1           uint256         uint24        uint64        bytes
        ///     messageType, activateContract, executeGasLimit, maxFeePerGas, signature
        ///   )
        ///        
    */
    function Launch(
        uint64 earliestArrivalTimestamp,
        uint64 latestArrivalTimestamp,
        address relayer,
        address sender,
        uint256 value,
        uint64 destChainid,
        bytes calldata additionParams,
        bytes calldata message
    ) external payable;

    ///
    ///    bytes                          byte1           uint256         uint24        uint64        bytes
    ///   message  = abi.encodePacked(messageType, activateContract, executeGasLimit, maxFeePerGas, signature)
    ///
    function launchMultiChain(
        launchEnhanceParams calldata params
    ) external payable;

    /// @notice batch landing message to the chain, execute the landing message
    /// @dev trusted relayer will call this function to send omni-chain message to the Station
    /// @param params the landing message params
    /// @param proofs the  proof of the validated message
    function Landing(
        landingParams[] calldata params,
        bytes[][] calldata proofs
    ) external payable;

    /// @notice similar to the Landing function, but with gasLimit
    function LandingSpecifiedGas(
        landingParams[] calldata params,
        uint24 gasLimit,
        bytes[][] calldata proofs
    ) external payable;

    /// @dev feel free to call this function before pass message to the Station,
    ///      this method will return the protocol fee that the message need to pay, longer message will pay more
    function estimateGas(
        uint256[] calldata value,
        uint64[] calldata destChainid,
        bytes[] calldata additionParams,
        bytes[] calldata message
    ) external view returns (uint256);

    function estimateGas(
        uint256 value,
        uint64 destChainid,
        bytes calldata additionParams,
        bytes calldata message
    ) external view returns (uint256);

    function estimatePrice(
        address sender,
        uint64 destChainid
    ) external view returns (uint64);

    function gasSystemAddr() external view returns (address);

    /// @dev get the message launch nonce of the sender on the specific chain
    /// @param chainId the chain id of the sender
    /// @param sender the address of the sender
    function GetNonceLaunch(
        uint64 chainId,
        address sender
    ) external view returns (uint32);

    /// @dev get the message landing nonce of the sender on the specific chain
    /// @param chainId the chain id of the sender
    /// @param sender the address of the sender
    function GetNonceLanding(
        uint64 chainId,
        address sender
    ) external view returns (uint32);

    /// @dev get the version of the Station
    /// @return the version of the Station, like "v1.0.0"
    function Version() external view returns (string memory);

    /// @dev get the chainId of current Station
    /// @return chainId, defined in the L2SupportLib.sol
    function Chainid() external view returns (uint64);

    function minArrivalTime() external view returns (uint64);

    function maxArrivalTime() external view returns (uint64);

    function expertLandingHook(bytes1 hook) external view returns (address);

    function expertLaunchHook(bytes1 hook) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageDashboard is IMessageStruct {
    /// @dev Only owner can call this function to stop or restart the engine
    /// @param stop true is stop, false is start
    function PauseEngine(bool stop) external;

    /// @notice return the states of the engine
    /// @return 0x01 is stop, 0x02 is start
    function engineState() external view returns (uint8);

    /// @notice return the states of the engine & Landing Pad
    function padState() external view returns (uint8, uint8);

    // function mptRoot() external view returns (bytes32);

    /// @dev withdraw the protocol fee from the contract, only owner can call this function
    /// @param amount the amount of the withdraw protocol fee
    function Withdraw(uint256 amount, address to) external;

    /// @dev set the payment system address, only owner can call this function
    /// @param gasSystemAddress the address of the payment system
    function setGasSystem(address gasSystemAddress) external;

    function setExpertLaunchHooks(
        bytes1[] calldata ids,
        address[] calldata hooks
    ) external;

    function setExpertLandingHooks(
        bytes1[] calldata ids,
        address[] calldata hooks
    ) external;

    /// notice reset the permission of the contract, only owner can call this function
    function roleConfiguration(
        bytes32 role,
        address[] calldata accounts,
        bool[] calldata states
    ) external;

    function stationAdminSetRole(
        bytes32 role,
        address[] calldata accounts,
        bool[] calldata states
    ) external;

    /// @notice transfer the ownership of the contract, only owner can call this function
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IMessageSpaceStation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMessageEmitter {
    function minArrivalTime() external view returns (uint64);

    function maxArrivalTime() external view returns (uint64);

    function minGasLimit() external view returns (uint24);

    function maxGasLimit() external view returns (uint24);

    function defaultBridgeMode() external view returns (bytes1);

    function selectedRelayer() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageEvent is IMessageStruct {
    /// @notice Throws event after a  message which attempts to omni-chain is submitted to LaunchPad contract
    event SuccessfulLaunchMessage(
        uint32 indexed nonce,
        uint64 earliestArrivalTimestamp,
        uint64 latestArrivalTimestamp,
        address relayer,
        address sender,
        address srcContract,
        uint256 value,
        uint64 destChainid,
        bytes additionParams,
        bytes message
    );

    /// @notice Throws event after a  message which attempts to omni-chain is submitted to LaunchPad contract
    event SuccessfulLaunchMultiMessages(
        uint32[] indexed nonce,
        uint64 earliestArrivalTimestamp,
        uint64 latestArrivalTimestamp,
        address relayer,
        address sender,
        address srcContract,
        uint256[] value,
        uint64[] destChainid,
        bytes[] additionParams,
        bytes[] message
    );

    /// @notice Throws event after a omni-chain message is submitted from source chain to target chain
    event SuccessfulLanding(bytes32 indexed messageId, landingParams params);

    /// @notice Throws event after protocol state is changed, such as pause or resume
    event EngineStateRefreshing(bool indexed isPause);

    /// @notice Throws event after protocol fee calculation is changed
    event PaymentSystemChanging(address indexed gasSystemAddress);

    /// @notice Throws event after successful withdrawa
    event WithdrawRequest(address indexed to, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageReceiver {
    function receiveStandardMessage(
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata message
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageSimulation is IMessageStruct {
    /// @dev for sequencer to simulate the landing message, call this function before call Landing
    /// @param params the landing message params
    /// check the revert message "SimulateResult" to get the result of the simulation
    /// for example, if the result is [true, false, true], it means the first and third message is valid, the second message is invalid
    function SimulateLanding(landingParams[] calldata params) external payable;

    /// @dev call this function off-chain to estimate the gas of excute the landing message
    /// @param params the landing message params
    /// @return the result of the estimation, true is valid, false is invalid
    function EstimateExecuteGas(
        landingParams[] calldata params
    ) external returns (bool[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";
import {IMessageDashboard} from "./IMessageDashboard.sol";
import {IMessageEvent} from "../interface/IMessageEvent.sol";
import {IMessageChannel} from "../interface/IMessageChannel.sol";
import {IMessageSimulation} from "../interface/IMessageSimulation.sol";

interface IMessageSpaceStation is
    IMessageStruct,
    IMessageDashboard,
    IMessageEvent,
    IMessageChannel,
    IMessageSimulation
{}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageStruct {
    struct launchParams {
        uint64 earliestArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        address relayer;
        address sender;
        uint256 value;
        uint64 destChainid;
        bytes additionParams;
        bytes message;
    }

    struct landingParams {
        bytes32 messageId;
        uint64 earliestArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        uint64 srcChainid;
        bytes32 srcTxHash;
        uint256 srcContract;
        uint32 srcChainNonce;
        uint256 sender;
        uint256 value;
        bytes additionParams;
        bytes message;
    }

    struct launchEnhanceParams {
        uint64 earliestArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        address relayer;
        address sender;
        uint256[] value;
        uint64[] destChainid;
        bytes[] additionParams;
        bytes[] message;
    }

    struct RollupMessageStruct {
        SignedMessageBase base;
        IMessageStruct.launchParams params;
    }

    struct SignedMessageBase {
        uint64 srcChainId;
        uint24 nonceLaunch;
        bytes32 srcTxHash;
        bytes32 destTxHash;
        uint64 srcTxTimestamp;
        uint64 destTxTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVizingGasSystemChannel {
    /*
        /// @notice Estimate how many native token we should spend to exchange the amountOut in the destChainid
        /// @param destChainid The chain id of the destination chain
        /// @param amountOut The value we want to receive in the destination chain
        /// @return amountIn the native token amount on the source chain we should spend
    */
    function exactOutput(
        uint64 destChainid,
        uint256 amountOut
    ) external view returns (uint256 amountIn);

    /*
        /// @notice Estimate how many native token we could get in the destChainid if we input the amountIn
        /// @param destChainid The chain id of the destination chain
        /// @param amountIn The value we spent in the source chain
        /// @return amountOut the native token amount the destination chain will receive
    */
    function exactInput(
        uint64 destChainid,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    /*
        /// @notice Estimate the gas fee we should pay to vizing
        /// @param destChainid The chain id of the destination chain
        /// @param message The message we want to send to the destination chain
    */
    function estimateGas(
        uint256 amountOut,
        uint64 destChainid,
        bytes calldata message
    ) external view returns (uint256);

    /*
        /// @notice Estimate the gas fee & native token we should pay to vizing
        /// @param amountOut amountOut in the destination chain
        /// @param destChainid The chain id of the destination chain
        /// @param message The message we want to send to the destination chain
    */
    function batchEstimateTotalFee(
        uint256[] calldata amountOut,
        uint64[] calldata destChainid,
        bytes[] calldata message
    ) external view returns (uint256 totalFee);

    /*
        /// @notice Estimate the total fee we should pay to vizing
        /// @param value The value we spent in the source chain
        /// @param destChainid The chain id of the destination chain
        /// @param message The message we want to send to the destination chain
    */
    function estimateTotalFee(
        uint256 value,
        uint64 destChainid,
        bytes calldata message
    ) external view returns (uint256 totalFee);

    /*
        /// @notice Estimate the gas price we need to encode in message
        /// @param sender most likely the address of the DApp, which forward the message from user
        /// @param destChainid The chain id of the destination chain
    */
    function estimatePrice(
        address targetContract,
        uint64 destChainid
    ) external view returns (uint64);

    /*
        /// @notice Estimate the gas price we need to encode in message
        /// @param destChainid The chain id of the destination chain
    */
    function estimatePrice(uint64 destChainid) external view returns (uint64);

    /*
        /// @notice Calculate the fee for the native token transfer
        /// @param amount The value we spent in the source chain
    */
    function computeTradeFee(
        uint64 destChainid,
        uint256 amountOut
    ) external view returns (uint256 fee);

    /*
        /// @notice Calculate the fee for the native token transfer
        /// @param amount The value we spent in the source chain
    */
    function computeTradeFee(
        address targetContract,
        uint64 destChainid,
        uint256 amountOut
    ) external view returns (uint256 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library MessageTypeLib {
    bytes1 constant DEFAULT = 0x00;

    /* ********************* message type **********************/
    bytes1 constant STANDARD_ACTIVATE = 0x01;
    bytes1 constant ARBITRARY_ACTIVATE = 0x02;
    bytes1 constant MESSAGE_POST = 0x03;
    bytes1 constant NATIVE_TOKEN_SEND = 0x04;

    /**
     * additionParams type *********************
     */
    // Single-Send mode
    bytes1 constant SINGLE_SEND = 0x01;
    bytes1 constant ERC20_HANDLER = 0x03;
    bytes1 constant MULTI_MANY_2_ONE = 0x04;
    bytes1 constant MULTI_UNIVERSAL = 0x05;

    bytes1 constant MAX_MODE = 0xFF;

    function fetchMsgMode(
        bytes calldata message
    ) internal pure returns (bytes1) {
        if (message.length < 1) {
            return DEFAULT;
        }
        bytes1 messageSlice = bytes1(message[0:1]);
        return messageSlice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./interface/IMessageStruct.sol";
import {IMessageChannel} from "./interface/IMessageChannel.sol";
import {IMessageEmitter} from "./interface/IMessageEmitter.sol";
import {IMessageReceiver} from "./interface/IMessageReceiver.sol";
import {IVizingGasSystemChannel} from "./interface/IVizingGasSystemChannel.sol";

abstract contract MessageEmitter is IMessageEmitter {
    /// @dev bellow are the default parameters for the OmniToken,
    ///      we **Highly recommended** to use immutable variables to store these parameters
    /// @notice minArrivalTime the minimal arrival timestamp for the omni-chain message
    /// @notice maxArrivalTime the maximal arrival timestamp for the omni-chain message
    /// @notice minGasLimit the minimal gas limit for target chain execute omni-chain message
    /// @notice maxGasLimit the maximal gas limit for target chain execute omni-chain message
    /// @notice defaultBridgeMode the default mode for the omni-chain message,
    ///        in OmniToken, we use MessageTypeLib.ARBITRARY_ACTIVATE (0x02), target chain will **ACTIVATE** the message
    /// @notice selectedRelayer the specify relayer for your message
    ///        set to 0, all the relayers will be able to forward the message
    /// see https://docs.vizing.com/docs/BuildOnVizing/Contract

    function minArrivalTime() external view virtual override returns (uint64) {}

    function maxArrivalTime() external view virtual override returns (uint64) {}

    function minGasLimit() external view virtual override returns (uint24) {}

    function maxGasLimit() external view virtual override returns (uint24) {}

    function defaultBridgeMode()
        external
        view
        virtual
        override
        returns (bytes1)
    {}

    function selectedRelayer()
        external
        view
        virtual
        override
        returns (address)
    {}

    IMessageChannel public LaunchPad;

    constructor(address _LaunchPad) {
        __LaunchPadInit(_LaunchPad);
    }

    /*
        /// rewrite set LaunchPad address function
        /// @notice call this function to reset the LaunchPad contract address
        /// @param _LaunchPad The new LaunchPad contract address
    */
    function __LaunchPadInit(address _LaunchPad) internal virtual {
        LaunchPad = IMessageChannel(_LaunchPad);
    }

    /*
        /// @notice call this function to packet the message before sending it to the LandingPad contract
        /// @param mode the emitter mode, check MessageTypeLib.sol for more details
        ///        eg: 0x02 for ARBITRARY_ACTIVATE, your message will be activated on the target chain
        /// @param gasLimit the gas limit for executing the specific function on the target contract
        /// @param targetContract the target contract address on the destination chain
        /// @param message the message to be sent to the target contract
        /// @return the packed message
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _packetMessage(
        bytes1 mode,
        address targetContract,
        uint24 gasLimit,
        uint64 price,
        bytes memory message
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                mode,
                uint256(uint160(targetContract)),
                gasLimit,
                price,
                message
            );
    }

    /*
        /// @notice use this function to send the ERC20 token to the destination chain
        /// @param tokenSymbol The token symbol
        /// @param sender The sender address for the message
        /// @param receiver The receiver address for the message
        /// @param amount The amount of tokens to be sent
        /// see https://docs.vizing.com/docs/DApp/Omni-ERC20-Transfer
    */
    function _packetAdditionParams(
        bytes1 mode,
        bytes1 tokenSymbol,
        address sender,
        address receiver,
        uint256 amount
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(mode, tokenSymbol, sender, receiver, amount);
    }

    /*
        /// @notice Calculate the amount of native tokens obtained on the target chain
        /// @param value The value we send to vizing on the source chain
    */
    function _computeTradeFee(
        uint64 destChainid,
        uint256 value
    ) internal view returns (uint256 amountIn) {
        return
            IVizingGasSystemChannel(LaunchPad.gasSystemAddr()).computeTradeFee(
                destChainid,
                value
            );
    }

    /*
        /// @notice Fetch the nonce of the user with specific destination chain
        /// @param destChainid The chain id of the destination chain
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _fetchNonce(
        uint64 destChainid
    ) internal view virtual returns (uint32 nonce) {
        nonce = LaunchPad.GetNonceLaunch(destChainid, msg.sender);
    }

    /*
        /// @notice Estimate the gas price we need to encode in message
        /// @param destChainid The chain id of the destination chain
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _fetchPrice(
        uint64 destChainid
    ) internal view virtual returns (uint64) {
        return
            IVizingGasSystemChannel(LaunchPad.gasSystemAddr()).estimatePrice(
                destChainid
            );
    }

    /*
        /// @notice Estimate the gas price we need to encode in message
        /// @param targetContract The target contract address on the destination chain
        /// @param destChainid The chain id of the destination chain
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _fetchPrice(
        address targetContract,
        uint64 destChainid
    ) internal view virtual returns (uint64) {
        return
            IVizingGasSystemChannel(LaunchPad.gasSystemAddr()).estimatePrice(
                targetContract,
                destChainid
            );
    }

    /*
        /// @notice similar to uniswap Swap Router
        /// @notice Estimate how many native token we should spend to exchange the amountOut in the destChainid
        /// @param destChainid The chain id of the destination chain
        /// @param amountOut The value we want to exchange in the destination chain
        /// @return amountIn the native token amount on the source chain we should spend
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _exactOutput(
        uint64 destChainid,
        uint256 amountOut
    ) internal view returns (uint256 amountIn) {
        return
            IVizingGasSystemChannel(LaunchPad.gasSystemAddr()).exactOutput(
                destChainid,
                amountOut
            );
    }

    /*
        /// @notice similar to uniswap Swap Router
        /// @notice Estimate how many native token we could get in the destChainid if we input the amountIn
        /// @param destChainid The chain id of the destination chain
        /// @param amountIn The value we spent in the source chain
        /// @return amountOut the native token amount the destination chain will receive
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _exactInput(
        uint64 destChainid,
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        return
            IVizingGasSystemChannel(LaunchPad.gasSystemAddr()).exactInput(
                destChainid,
                amountIn
            );
    }

    /*
        /// @notice Estimate the gas price we need to encode in message
        /// @param value The native token that value target address will receive in the destination chain
        /// @param destChainid The chain id of the destination chain
        /// @param additionParams The addition params for the message
        ///        if not in expert mode, set to 0 (`new bytes(0)`)
        /// @param message The message we want to send to the destination chain
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _estimateVizingGasFee(
        uint256 value,
        uint64 destChainid,
        bytes memory additionParams,
        bytes memory message
    ) internal view returns (uint256 vizingGasFee) {
        return
            LaunchPad.estimateGas(value, destChainid, additionParams, message);
    }

    /*  
        /// @notice **Highly recommend** to call this function in your frontend program
        /// @notice Estimate the gas price we need to encode in message
        /// @param value The native token that value target address will receive in the destination chain
        /// @param destChainid The chain id of the destination chain
        /// @param additionParams The addition params for the message
        ///        if not in expert mode, set to 0 (`new bytes(0)`)
        /// @param message The message we want to send to the destination chain
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function estimateVizingGasFee(
        uint256 value,
        uint64 destChainid,
        bytes calldata additionParams,
        bytes calldata message
    ) external view returns (uint256 vizingGasFee) {
        return
            _estimateVizingGasFee(value, destChainid, additionParams, message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageChannel} from "./interface/IMessageChannel.sol";
import {IMessageReceiver} from "./interface/IMessageReceiver.sol";

abstract contract MessageReceiver is IMessageReceiver {
    error LandingPadAccessDenied();
    error NotImplement();
    IMessageChannel public LandingPad;

    modifier onlyVizingPad() {
        if (msg.sender != address(LandingPad)) revert LandingPadAccessDenied();
        _;
    }

    constructor(address _LandingPad) {
        __LandingPadInit(_LandingPad);
    }

    /*
        /// rewrite set LandingPad address function
        /// @notice call this function to reset the LaunchPad contract address
        /// @param _LaunchPad The new LaunchPad contract address
    */
    function __LandingPadInit(address _LandingPad) internal virtual {
        LandingPad = IMessageChannel(_LandingPad);
    }

    /// @notice the standard function to receive the omni-chain message
    function receiveStandardMessage(
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata message
    ) external payable virtual override onlyVizingPad {
        _receiveMessage(srcChainId, srcContract, message);
    }

    /// @dev override this function to handle the omni-chain message
    /// @param srcChainId the source chain id
    /// @param srcContract the source contract address
    /// @param message the message from the source chain
    function _receiveMessage(
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata message
    ) internal virtual {
        (srcChainId, srcContract, message);
        revert NotImplement();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageEmitter} from "./MessageEmitter.sol";
import {MessageReceiver} from "./MessageReceiver.sol";

abstract contract VizingOmni is MessageEmitter, MessageReceiver {
    constructor(
        address _vizingPad
    ) MessageEmitter(_vizingPad) MessageReceiver(_vizingPad) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SlaveBase} from "./lib/SlaveBase.sol";

contract BIZSlave is SlaveBase {
    constructor(
        address _vizingPad,
        uint64 _masterChainId,
        address signer
    ) SlaveBase( _vizingPad, _masterChainId) {
        claimSigner = signer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VizingOmni} from "@vizing/contracts/VizingOmni.sol";
import {MessageTypeLib} from "@vizing/contracts/library/MessageTypeLib.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract LikwidCore is Ownable, ReentrancyGuard, VizingOmni, Pausable {
    enum ActionType {
        createPing,
        votePing,
        crossPing
    }

    function pause() external onlyOwner {
        bool isPaused = paused();
        if (isPaused) {
            _unpause();
        } else {
            _pause();
        }
    }

    mapping(uint => mapping(address => mapping(uint => bool))) public crossNoncePing;
    mapping(uint => mapping(address => uint)) public crossNonce;

    event MessageReceived(uint64 _srcChainId, address _srcAddress, uint value, bytes _payload);
    event Crossed(uint64 _srcChainId, address _sender, address _to, uint _amount,uint nonce);

    uint64 public immutable override minArrivalTime;
    uint64 public immutable override maxArrivalTime;
    uint24 public immutable override minGasLimit;
    uint24 public immutable override maxGasLimit;
    bytes1 public immutable override defaultBridgeMode;
    address public immutable override selectedRelayer;

    uint64 public masterChainId;
    uint public messageReceived;
    address public feeAddress;

    function setFeeAddress(address addr) public virtual onlyOwner {
        feeAddress = addr;
    }
    struct Meme {
        address creator;
        string symbol;
        string name;
        string logo;
        uint totalSupply;
        uint launchFunds;
        uint launchCountdown;
        string tg;
        string x;
        uint quota;
        uint hardcap;
        uint tokenomics;
        uint votes;
    }
    uint public price = 0.00295 ether;
    uint public votePrice = 0.00025 ether;

    uint public totalSupplyMax = 10000000000 ether;
    uint public totalSupplyMin = 10000000 ether;
    uint public launchFundsMax = 50 ether;

    uint public launchFundsMin = 10 ether;
    uint public crossMax = 0.1 ether;
    function setPrice(uint price_) public onlyOwner {
        price = price_;
    }

    function setVotePrice(uint price_) public onlyOwner {
        votePrice = price_;
    }

    function setTotalSupplyMax(uint totalSupplyMax_) public onlyOwner {
        require(totalSupplyMax_ > totalSupplyMin, "max_ error");
        totalSupplyMax = totalSupplyMax_;
    }

    function setLaunchFundsMax(uint launchFundsMax_) public onlyOwner {
        require(launchFundsMax_ > launchFundsMin, "max_ error");
        launchFundsMax = launchFundsMax_;
    }

    function setCrossMax(uint amount) public onlyOwner {
        crossMax = amount;
    }

    function strEqual(string memory a, string memory b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }

    constructor(
        address _vizingPad,
        uint64 _masterChainId
    ) VizingOmni(_vizingPad) {
        minArrivalTime = 1 minutes;
        maxArrivalTime = 1 days;
        minGasLimit = 100000;
        maxGasLimit = 1000000;
        selectedRelayer =  address(0);
        masterChainId = _masterChainId;
        defaultBridgeMode = MessageTypeLib.STANDARD_ACTIVATE;
        feeAddress = owner();
    }

    //----vizing bridge common----
    function paramsEstimateGas(
        uint64 dstChainId,
        address dstContract,
        uint value,
        bytes memory params
    ) public view virtual returns (uint) {
        bytes memory message = _packetMessage(
            defaultBridgeMode,
            dstContract,
            maxGasLimit,
            _fetchPrice(dstContract, dstChainId),
            abi.encode(_msgSender(), params)
        );
        return LaunchPad.estimateGas(value, dstChainId, new bytes(0), message);
    }

    function paramsEmit2LaunchPad(
        uint bridgeFee,
        uint64 dstChainId,
        address dstContract,
        uint value,
        bytes memory params,
        address sender
    ) internal virtual {
        bytes memory message = _packetMessage(
            defaultBridgeMode,
            dstContract,
            maxGasLimit,
            _fetchPrice(dstContract, dstChainId),
            abi.encode(_msgSender(), params)
        );
        uint bridgeValue = value + bridgeFee;
        require(msg.value >= bridgeValue, "bridgeFee err.");
        LaunchPad.Launch{value: bridgeValue}(0, 0, selectedRelayer, sender, value, dstChainId, new bytes(0), message);
    }

    //----  message call function----

    function master_create(
        Meme memory meme,
        address sender) internal virtual {
        revert NotImplement();
    }

    function master_vote(
        string memory symbol,
        address inviter,
        address sender) internal virtual {
        revert NotImplement();
    }
    function master_cross(
        uint64 srcChainId,
        address sender,
        uint64 dstChainId,
        address to,
        uint amount,
        uint nonce
    ) internal virtual {
        revert NotImplement();
    }

    function slave_cross(
        uint64 srcChainId,
        address sender,
        uint64 dstChainId,
        address to,
        uint amount,
        uint nonce
    ) internal virtual {
        revert NotImplement();
    }

    function action_master(
        uint64 srcChainId,
        address sender,
        uint8 action,
        uint pongFee,
        bytes memory params
    ) internal virtual {
        if (action == uint8(ActionType.createPing)) {
            (Meme memory meme) = abi.decode(params, (Meme));
            master_create(meme,sender);
        } else if (action == uint8(ActionType.votePing)) {
            (string memory symbol,address inviter) = abi.decode(params, (string,address));
            master_vote(symbol,inviter,sender);
        } else if (action == uint8(ActionType.crossPing)) {
            (uint nonce,uint64 chainid, address to, uint token) = abi.decode(params, (uint,uint64, address, uint));
            master_cross(srcChainId, sender, chainid, to, token,nonce);
        } else revert NotImplement();
    }

    function action_slave(
        uint64 srcChainId,
        address sender,
        uint8 action,
        uint pongFee,
        bytes memory params
    ) internal virtual {
        if (action == uint8(ActionType.crossPing)) {
            (uint nonce,uint64 chainid, address to, uint token) = abi.decode(params, (uint,uint64, address, uint));
            slave_cross(srcChainId, sender, chainid, to, token,nonce);
        } else revert NotImplement();
    }

    function verifySource(uint64 srcChainId, address srcContract) internal view virtual returns (bool authorized);

    function _receiveMessage(
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata _payload
    ) internal virtual override {
        require(verifySource(srcChainId, address(uint160(srcContract))), "unauthorized.");
        (address sender, bytes memory message) = abi.decode(_payload, (address, bytes));
        messageReceived += 1;
        emit MessageReceived(srcChainId, sender, msg.value, message);

        (uint8 action, uint pongFee, bytes memory params) = abi.decode(message, (uint8, uint, bytes));
        if (srcChainId == masterChainId) action_slave(srcChainId, sender, action, pongFee, params);
        else action_master(srcChainId, sender, action, pongFee, params);
    }

    function _createPingSignature(
        Meme memory meme
    ) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.createPing), 0, abi.encode(meme));
    }

    function _votePingSignature(
        string memory symbol,
        address inviter
    ) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.votePing), 0, abi.encode(symbol,inviter));
    }

    function _crossPingSignature(
        uint nonce,
        uint64 dstChainId,
        address target,
        uint amount
    ) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.crossPing), 0, abi.encode(nonce,dstChainId, target, amount));
    }

    function transferNative(address to, uint amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawFee(address to, uint amount) public onlyOwner nonReentrant {
        transferNative(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LikwidCore} from "./LikwidCore.sol";
import {IMessageStruct} from "@vizing/contracts/interface/IMessageStruct.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract SlaveBase is LikwidCore {
    address public masterContract;
    constructor(
        address _vizingPad,
        uint64 _masterChainId
    ) LikwidCore(_vizingPad, _masterChainId) {}

    function setMasterContract(address addr) public virtual onlyOwner {
        masterContract = addr;
    }

    function verifySource(
        uint64 srcChainId,
        address srcContract
    ) internal view virtual override returns (bool authorized) {
        return masterContract == srcContract && masterChainId == srcChainId;
    }
    modifier checkUpperCase(string memory _str) {
        bytes memory bytesStr = bytes(_str);
        for (uint i = 0; i < bytesStr.length; i++) {
            uint asciiValue = uint8(bytesStr[i]);
            require((asciiValue >= 65 && asciiValue <= 90) || (asciiValue >= 48 && asciiValue <= 57), "symbol err");
        }
        _;
    }
    uint public launchCountdownMin = 7200;
    uint public launchCountdownMax = 172800;
    function setLaunchCountdown(uint launchCountdownMin_, uint launchCountdownMax_) public onlyOwner {
        launchCountdownMin = launchCountdownMin_;
        launchCountdownMax = launchCountdownMax_;
    }
    uint public hardcapMax = 8000 ether;
    function setHardcapMax(uint amount) public onlyOwner {
        hardcapMax = amount;
    }
    
    address public claimSigner;
    function setClaimSigner(address signer) external onlyOwner {
        claimSigner = signer;
    }
    //----deposit
    function createPingEstimateGas(
        uint amount,
        Meme memory meme
    ) public view virtual returns (uint pingFee) {
        pingFee = paramsEstimateGas(
            masterChainId,
            masterContract,
            amount,
            _createPingSignature(meme)
        );
    }

    bool public createPause = true;
    function setCreatePause(bool pause_) public onlyOwner {
        createPause = pause_;
    }
    uint public quotaMax = 0.05 ether;
    uint public quotaMin = 0.01 ether;
    function setQuotaMax(uint max_) public onlyOwner {
        require(max_ > quotaMin, "max_ error");
        quotaMax = max_;
    }
    function getCreateAmount(
        uint tokenomics,
        uint quota,
        uint launchFunds
    ) public view virtual returns (uint) {
        if(tokenomics == 4){
            require(quota >= quotaMin && quota <= quotaMax, "quota error");
            require(quota % quotaMin == 0, "quota must be an integer multiple");
            uint poolLocked = 0.5 ether;
            // airdrop must be fixed
            uint airdrop = 0.05 ether;
            uint creater = quota;
            uint presale = 1 ether - poolLocked - airdrop - creater;
            uint createAmount = ((launchFunds * 1 ether) / presale * creater) /1 ether;
            return createAmount;
        }
        return price;
    }
    function create(
        Meme memory meme
    ) public checkUpperCase(meme.symbol) payable virtual {
        require(!createPause,"create pause");
        
        meme.votes = 0;

        uint symbolLength = bytes(meme.symbol).length;
        require(symbolLength > 0 && symbolLength <= 10, "Symbol exceeds limit");
        uint nameLength = bytes(meme.name).length;
        require(nameLength > 0 && nameLength <= 100, "Name exceeds limit");
        uint totalSupply = meme.totalSupply;
        require(totalSupply >= totalSupplyMin && totalSupply <= totalSupplyMax, "Total supply exceeds limit");
        require(totalSupply % totalSupplyMin == 0, "totalSupply must be an integer multiple");
        uint launchFunds = meme.launchFunds;
        require(launchFunds >= launchFundsMin && launchFunds <= launchFundsMax, "Launch funds exceeds limit");
        require(launchFunds % launchFundsMin == 0, "funds must be an integer multiple");
        require(meme.hardcap > launchFunds, "hardcap too small");
        require(meme.hardcap <= hardcapMax, "hardcap too large");
        uint launchCountdown = meme.launchCountdown;
        require(
            launchCountdown >= launchCountdownMin && launchCountdown <= launchCountdownMax,
            "Countdown exceeds limit"
        );

        uint createAmount = getCreateAmount(meme.tokenomics, meme.quota, meme.launchFunds);
        uint pingFee = createPingEstimateGas(createAmount, meme);
        require(msg.value >= createAmount + pingFee, "Insufficient");

        paramsEmit2LaunchPad(
            pingFee,
            masterChainId,
            masterContract,
            price,
            _createPingSignature(meme),
            _msgSender()
        );
    }

    function votePingEstimateGas(
        uint amount,
        string memory symbol,
        address inviter
    ) public view virtual returns (uint pingFee) {
        pingFee = paramsEstimateGas(
            masterChainId,
            masterContract,
            amount,
            _votePingSignature(symbol,inviter)
        );
    }
    enum signBiz{
        vote,
        airdrop
    }

    function getClaimHash(string memory biz,string memory symbol,uint amount,address sender) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(biz,symbol,amount,sender));
    }

    bool public votePause = true;
    function setVotePause(bool pause_) public onlyOwner {
        votePause = pause_;
    }
    function vote(
        string memory symbol,
        address inviter,
        bytes calldata signature
    ) public payable virtual{
        require(!votePause,"vote pause");
        require(inviter != _msgSender(), "The inviter cannot be yourself");
        uint amount = msg.value;
        uint pingFee = votePingEstimateGas(amount, symbol,inviter);
        require(amount >= votePrice + pingFee, "Insufficient");
        bytes32 hash = getClaimHash("vote",symbol,0,_msgSender());
        require(SignatureChecker.isValidSignatureNow(claimSigner, hash, signature), "verify error");
        paramsEmit2LaunchPad(
            pingFee,
            masterChainId,
            masterContract,
            votePrice,
            _votePingSignature(symbol,inviter),
            _msgSender()
        );
    }
    
    function slave_cross(uint64 srcChainId, address sender, uint64 dstChainId, address to, uint amount,uint nonce) internal virtual override {
        require(!crossNoncePing[srcChainId][sender][nonce], "nonce repetition");
        crossNoncePing[srcChainId][sender][nonce] = true;
        require(dstChainId == block.chainid, "chain id err");
        if (amount > 0 && msg.value >= amount) transferNative(to,amount);
        emit Crossed(srcChainId, sender, to, amount, nonce);
    }

    function ethCrossToEstimateGas(uint64 dstChainId, address to, uint amount) public view virtual returns (uint pingFee) {
        require(dstChainId == masterChainId, "not master chain");
        uint nonce = crossNonce[dstChainId][to];
        pingFee = paramsEstimateGas(masterChainId, masterContract, amount, _crossPingSignature(nonce+1,dstChainId, to, amount));
    }

    function ethCrossTo(uint64 dstChainId, address to, uint amount) external payable virtual whenNotPaused{
        require(dstChainId == masterChainId, "not master chain");
        uint pingFee = ethCrossToEstimateGas(dstChainId, to, amount);
        require(msg.value >= amount + pingFee, "value err.");
        require(amount >= 0 && amount <= crossMax, "exceeding the limit value");
        uint nonce = crossNonce[block.chainid][_msgSender()];
        paramsEmit2LaunchPad(
            pingFee,
            masterChainId,
            masterContract,
            amount,
            _crossPingSignature(nonce+1,dstChainId, to, amount),
            _msgSender()
        );
        crossNonce[block.chainid][_msgSender()]++;
    }
}