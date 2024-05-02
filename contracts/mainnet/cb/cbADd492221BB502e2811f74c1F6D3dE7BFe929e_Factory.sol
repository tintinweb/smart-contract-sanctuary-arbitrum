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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

library Constants {
    uint256 internal constant YEAR_IN_SECONDS = 365 days;
    uint256 internal constant BASE = 1e18;
    uint256 internal constant MAX_FEE_PER_ANNUM = 0.05e18; // 5% max in base
    uint256 internal constant MAX_SWAP_PROTOCOL_FEE = 0.01e18; // 1% max in base
    uint256 internal constant MAX_TOTAL_PROTOCOL_FEE = 0.05e18; // 5% max in base
    uint256 internal constant MAX_P2POOL_PROTOCOL_FEE = 0.05e18; // 5% max in base
    uint256 internal constant MIN_TIME_BETWEEN_EARLIEST_REPAY_AND_EXPIRY =
        1 days;
    uint256 internal constant MAX_PRICE_UPDATE_TIMESTAMP_DIVERGENCE = 1 days;
    uint256 internal constant SEQUENCER_GRACE_PERIOD = 1 hours;
    uint256 internal constant MIN_UNSUBSCRIBE_GRACE_PERIOD = 1 days;
    uint256 internal constant MAX_UNSUBSCRIBE_GRACE_PERIOD = 14 days;
    uint256 internal constant MIN_CONVERSION_GRACE_PERIOD = 1 days;
    uint256 internal constant MIN_REPAYMENT_GRACE_PERIOD = 1 days;
    uint256 internal constant LOAN_EXECUTION_GRACE_PERIOD = 1 days;
    uint256 internal constant MAX_CONVERSION_AND_REPAYMENT_GRACE_PERIOD =
        30 days;
    uint256 internal constant MIN_TIME_UNTIL_FIRST_DUE_DATE = 1 days;
    uint256 internal constant MIN_TIME_BETWEEN_DUE_DATES = 7 days;
    uint256 internal constant MIN_WAIT_UNTIL_EARLIEST_UNSUBSCRIBE = 60 seconds;
    uint256 internal constant MAX_ARRANGER_FEE = 0.5e18; // 50% max in base
    uint256 internal constant LOAN_TERMS_UPDATE_COOL_OFF_PERIOD = 15 minutes;
    uint256 internal constant MAX_REPAYMENT_SCHEDULE_LENGTH = 20;
    uint256 internal constant SINGLE_WRAPPER_MIN_MINT = 1000; // in wei
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Errors {
    error UnregisteredVault();
    error InvalidDelegatee();
    error InvalidSender();
    error InvalidFee();
    error InsufficientSendAmount();
    error NoOracle();
    error InvalidOracleAnswer();
    error InvalidOracleDecimals();
    error InvalidOracleVersion();
    error InvalidAddress();
    error InvalidArrayLength();
    error InvalidQuote();
    error OutdatedQuote();
    error InvalidOffChainSignature();
    error InvalidOffChainMerkleProof();
    error InvalidCollUnlock();
    error InvalidAmount();
    error UnknownOnChainQuote();
    error NeitherTokenIsGOHM();
    error NoLpTokens();
    error ZeroReserve();
    error IncorrectGaugeForLpToken();
    error InvalidGaugeIndex();
    error AlreadyStaked();
    error InvalidWithdrawAmount();
    error InvalidBorrower();
    error OutsideValidRepayWindow();
    error InvalidRepayAmount();
    error ReclaimAmountIsZero();
    error UnregisteredGateway();
    error NonWhitelistedOracle();
    error NonWhitelistedCompartment();
    error NonWhitelistedCallback();
    error NonWhitelistedToken();
    error LtvHigherThanMax();
    error InsufficientVaultFunds();
    error InvalidInterestRateFactor();
    error InconsistentUnlockTokenAddresses();
    error InvalidEarliestRepay();
    error InvalidNewMinNumOfSigners();
    error AlreadySigner();
    error InvalidArrayIndex();
    error InvalidSignerRemoveInfo();
    error InvalidSendAmount();
    error TooSmallLoanAmount();
    error DeadlinePassed();
    error WithdrawEntered();
    error DuplicateAddresses();
    error OnChainQuoteAlreadyAdded();
    error OffChainQuoteHasBeenInvalidated();
    error Uninitialized();
    error InvalidRepaymentScheduleLength();
    error FirstDueDateTooCloseOrPassed();
    error InvalidGracePeriod();
    error UnregisteredLoanProposal();
    error NotInSubscriptionPhase();
    error NotInUnsubscriptionPhase();
    error InsufficientBalance();
    error InsufficientFreeSubscriptionSpace();
    error BeforeEarliestUnsubscribe();
    error InconsistentLastLoanTermsUpdateTime();
    error InvalidActionForCurrentStatus();
    error FellShortOfTotalSubscriptionTarget();
    error InvalidRollBackRequest();
    error UnsubscriptionAmountTooLarge();
    error InvalidSubscriptionRange();
    error InvalidMaxTotalSubscriptions();
    error OutsideConversionTimeWindow();
    error OutsideRepaymentTimeWindow();
    error NoDefault();
    error LoanIsFullyRepaid();
    error RepaymentIdxTooLarge();
    error AlreadyClaimed();
    error AlreadyConverted();
    error InvalidDueDates();
    error LoanTokenDueIsZero();
    error WaitForLoanTermsCoolOffPeriod();
    error ZeroConversionAmount();
    error InvalidNewOwnerProposal();
    error CollateralMustBeCompartmentalized();
    error InvalidCompartmentForToken();
    error InvalidSignature();
    error InvalidUpdate();
    error CannotClaimOutdatedStatus();
    error DelegateReducedBalance();
    error FundingPoolAlreadyExists();
    error InvalidLender();
    error NonIncreasingTokenAddrs();
    error NonIncreasingNonFungibleTokenIds();
    error TransferToWrappedTokenFailed();
    error TransferFromWrappedTokenFailed();
    error StateAlreadySet();
    error ReclaimableCollateralAmountZero();
    error InvalidSwap();
    error InvalidUpfrontFee();
    error InvalidOracleTolerance();
    error ReserveRatiosSkewedFromOraclePrice();
    error SequencerDown();
    error GracePeriodNotOver();
    error LoanExpired();
    error NoDsEth();
    error TooShortTwapInterval();
    error TooLongTwapInterval();
    error TwapExceedsThreshold();
    error Reentrancy();
    error TokenNotStuck();
    error InconsistentExpTransferFee();
    error InconsistentExpVaultBalIncrease();
    error DepositLockActive();
    error DisallowedSubscriptionLockup();
    error IncorrectLoanAmount();
    error Disabled();
    error CannotRemintUnlessZeroSupply();
    error TokensStillMissingFromWrapper();
    error OnlyMintFromSingleTokenWrapper();
    error NonMintableTokenState();
    error NoTokensTransferred();
    error TokenAlreadyCountedInWrapper();
    error TokenNotOwnedByWrapper();
    error TokenDoesNotBelongInWrapper(address tokenAddr, uint256 tokenId);
    error InvalidMintAmount();
    error QuoteViolatesPolicy();
    error AlreadyPublished();
    error PolicyAlreadySet();
    error NoPolicyToDelete();
    error InvalidTenorBounds();
    error InvalidLtvBounds();
    error InvalidLoanPerCollBounds();
    error InvalidMinApr();
    error NoPolicy();
    error InvalidMinFee();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library Helpers {
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 vs) {
        require(sig.length == 64, "invalid signature length");
        // solhint-disable no-inline-assembly
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            vs := mload(add(sig, 64))
        }
        // implicitly return (r, vs)
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../peer-to-peer/DataTypesPeerToPeer.sol";
import {DataTypesPeerToPool} from "../peer-to-pool/DataTypesPeerToPool.sol";

interface IMysoTokenManager {
    function processP2PBorrow(
        uint128[2] memory currProtocolFeeParams,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.Loan calldata loan,
        address lenderVault
    ) external returns (uint128[2] memory applicableProtocolFeeParams);

    function processP2PCreateVault(
        uint256 numRegisteredVaults,
        address vaultCreator,
        address newLenderVaultAddr
    ) external;

    function processP2PCreateWrappedTokenForERC721s(
        address tokenCreator,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata tokensToBeWrapped,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PCreateWrappedTokenForERC20s(
        address tokenCreator,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata tokensToBeWrapped,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PoolDeposit(
        address fundingPool,
        address depositor,
        uint256 depositAmount,
        uint256 depositLockupDuration,
        uint256 transferFee
    ) external;

    function processP2PoolSubscribe(
        address fundingPool,
        address subscriber,
        address loanProposal,
        uint256 subscriptionAmount,
        uint256 subscriptionLockupDuration,
        uint256 totalSubscriptions,
        DataTypesPeerToPool.LoanTerms calldata loanTerms
    ) external;

    function processP2PoolLoanFinalization(
        address loanProposal,
        address fundingPool,
        address arranger,
        address borrower,
        uint256 grossLoanAmount,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PoolCreateLoanProposal(
        address fundingPool,
        address proposalCreator,
        address collToken,
        uint256 arrangerFee,
        uint256 numLoanProposals
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DataTypesPeerToPeer {
    struct Loan {
        // address of borrower
        address borrower;
        // address of coll token
        address collToken;
        // address of loan token
        address loanToken;
        // timestamp after which any portion of loan unpaid defaults
        uint40 expiry;
        // timestamp before which borrower cannot repay
        uint40 earliestRepay;
        // initial collateral amount of loan
        uint128 initCollAmount;
        // loan amount given
        uint128 initLoanAmount;
        // full repay amount at start of loan
        uint128 initRepayAmount;
        // amount repaid (loan token) up until current time
        // note: partial repayments are allowed
        uint128 amountRepaidSoFar;
        // amount reclaimed (coll token) up until current time
        // note: partial repayments are allowed
        uint128 amountReclaimedSoFar;
        // flag tracking if collateral has been unlocked by vault
        bool collUnlocked;
        // address of the compartment housing the collateral
        address collTokenCompartmentAddr;
    }

    struct QuoteTuple {
        // loan amount per one unit of collateral if no oracle
        // LTV in terms of the constant BASE (10 ** 18) if using oracle
        uint256 loanPerCollUnitOrLtv;
        // interest rate percentage in BASE (can be negative but greater than -BASE)
        // i.e. -100% < interestRatePct since repay amount of 0 is not allowed
        // also interestRatePctInBase is not annualized
        int256 interestRatePctInBase;
        // fee percentage,in BASE, which will be paid in upfront in collateral
        uint256 upfrontFeePctInBase;
        // length of the loan in seconds
        uint256 tenor;
    }

    struct GeneralQuoteInfo {
        // address of collateral token
        address collToken;
        // address of loan token
        address loanToken;
        // address of oracle (optional)
        address oracleAddr;
        // min loan amount (in loan token) prevent griefing attacks or
        // amounts lender feels isn't worth unlocking on default
        uint256 minLoan;
        // max loan amount (in loan token) if lender wants a cap
        uint256 maxLoan;
        // timestamp after which quote automatically invalidates
        uint256 validUntil;
        // time, in seconds, that loan cannot be exercised
        uint256 earliestRepayTenor;
        // address of compartment implementation (optional)
        address borrowerCompartmentImplementation;
        // will invalidate quote after one use
        // if false, will be a standing quote
        bool isSingleUse;
        // whitelist address (optional)
        address whitelistAddr;
        // flag indicating whether whitelistAddr refers to a single whitelisted
        // borrower or to a whitelist authority that can whitelist multiple addresses
        bool isWhitelistAddrSingleBorrower;
    }

    struct OnChainQuote {
        // general quote info
        GeneralQuoteInfo generalQuoteInfo;
        // array of quote parameters
        QuoteTuple[] quoteTuples;
        // provides more distinguishability of quotes to reduce
        // likelihood of collisions w.r.t. quote creations and invalidations
        bytes32 salt;
    }

    struct OffChainQuote {
        // general quote info
        GeneralQuoteInfo generalQuoteInfo;
        // root of the merkle tree, where the merkle tree encodes all QuoteTuples the lender accepts
        bytes32 quoteTuplesRoot;
        // provides more distinguishability of quotes to reduce
        // likelihood of collisions w.r.t. quote creations and invalidations
        bytes32 salt;
        // for invalidating multiple parallel quotes in one click
        uint256 nonce;
        // array of compact signatures from vault signers
        bytes[] compactSigs;
    }

    struct LoanRepayInstructions {
        // loan id being repaid
        uint256 targetLoanId;
        // repay amount after transfer fees in loan token
        uint128 targetRepayAmount;
        // expected transfer fees in loan token (=0 for tokens without transfer fee)
        // note: amount that borrower sends is targetRepayAmount + expectedTransferFee
        uint128 expectedTransferFee;
        // deadline to prevent stale transactions
        uint256 deadline;
        // e.g., for using collateral to payoff debt via DEX
        address callbackAddr;
        // any data needed by callback
        bytes callbackData;
    }

    struct BorrowTransferInstructions {
        // amount of collateral sent
        uint256 collSendAmount;
        // sum of (i) protocol fee and (ii) transfer fees (if any) associated with sending any collateral to vault
        uint256 expectedProtocolAndVaultTransferFee;
        // transfer fees associated with sending any collateral to compartment (if used)
        uint256 expectedCompartmentTransferFee;
        // deadline to prevent stale transactions
        uint256 deadline;
        // slippage protection if oracle price is too loose
        uint256 minLoanAmount;
        // e.g., for one-click leverage
        address callbackAddr;
        // any data needed by callback
        bytes callbackData;
        // any data needed by myso token manager
        bytes mysoTokenManagerData;
    }

    struct TransferInstructions {
        // collateral token receiver
        address collReceiver;
        // effective upfront fee in collateral tokens (vault or compartment)
        uint256 upfrontFee;
    }

    struct WrappedERC721TokenInfo {
        // address of the ERC721_TOKEN
        address tokenAddr;
        // array of ERC721_TOKEN ids
        uint256[] tokenIds;
    }

    struct WrappedERC20TokenInfo {
        // token addresse
        address tokenAddr;
        // token amounts
        uint256 tokenAmount;
    }

    struct OnChainQuoteInfo {
        // hash of on chain quote
        bytes32 quoteHash;
        // valid until timestamp
        uint256 validUntil;
    }

    enum WhitelistState {
        // not whitelisted
        NOT_WHITELISTED,
        // can be used as loan or collateral token
        ERC20_TOKEN,
        // can be be used as oracle
        ORACLE,
        // can be used as compartment
        COMPARTMENT,
        // can be used as callback contract
        CALLBACK,
        // can be used as loan or collateral token, but if collateral then must
        // be used in conjunction with a compartment (e.g., for stETH with possible
        // negative rebase that could otherwise affect other borrowers in the vault)
        ERC20_TOKEN_REQUIRING_COMPARTMENT,
        // can be used in conjunction with an ERC721 wrapper
        ERC721_TOKEN,
        // can be used as ERC721 wrapper contract
        ERC721WRAPPER,
        // can be used as ERC20 wrapper contract
        ERC20WRAPPER,
        // can be used as MYSO token manager contract
        MYSO_TOKEN_MANAGER,
        // can be used as quote policy manager contract
        QUOTE_POLICY_MANAGER
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DataTypesPeerToPool {
    struct Repayment {
        // The loan token amount due for given period; initially, expressed in relative terms (100%=BASE), once
        // finalized in absolute terms (in loanToken)
        uint128 loanTokenDue;
        // The coll token amount that can be converted for given period; initially, expressed in relative terms w.r.t.
        // loanTokenDue (e.g., convert every 1 loanToken for 8 collToken), once finalized in absolute terms (in collToken)
        uint128 collTokenDueIfConverted;
        // Timestamp when repayment is due
        uint40 dueTimestamp;
    }

    struct LoanTerms {
        // Min subscription amount (in loan token) that the borrower deems acceptable
        uint128 minTotalSubscriptions;
        // Max subscription amount (in loan token) that the borrower deems acceptable
        uint128 maxTotalSubscriptions;
        // The number of collateral tokens the borrower pledges per loan token borrowed as collateral for default case
        uint128 collPerLoanToken;
        // Borrower who can finalize given loan proposal
        address borrower;
        // Array of scheduled repayments
        Repayment[] repaymentSchedule;
    }

    struct StaticLoanProposalData {
        // Factory address from which the loan proposal is created
        address factory;
        // Funding pool address that is associated with given loan proposal and from which loan liquidity can be
        // sourced
        address fundingPool;
        // Address of collateral token to be used for given loan proposal
        address collToken;
        // Address of arranger who can manage the loan proposal contract
        address arranger;
        // Address of whitelist authority who can manage the lender whitelist (optional)
        address whitelistAuthority;
        // Unsubscribe grace period (in seconds), i.e., after acceptance by borrower lenders can unsubscribe and
        // remove liquidity for this duration before being locked-in
        uint256 unsubscribeGracePeriod;
        // Conversion grace period (in seconds), i.e., lenders can exercise their conversion right between
        // [dueTimeStamp, dueTimeStamp+conversionGracePeriod]
        uint256 conversionGracePeriod;
        // Repayment grace period (in seconds), i.e., borrowers can repay between
        // [dueTimeStamp+conversionGracePeriod, dueTimeStamp+conversionGracePeriod+repaymentGracePeriod]
        uint256 repaymentGracePeriod;
    }

    struct DynamicLoanProposalData {
        // Arranger fee charged on final loan amount, initially in relative terms (100%=BASE), and after finalization
        // in absolute terms (in loan token)
        uint256 arrangerFee;
        // The gross loan amount; initially this is zero and gets set once loan proposal gets accepted and finalized;
        // note that the borrower receives the gross loan amount minus any arranger and protocol fees
        uint256 grossLoanAmount;
        // Final collateral amount reserved for defaults; initially this is zero and gets set once loan proposal got
        // accepted and finalized
        uint256 finalCollAmountReservedForDefault;
        // Final collateral amount reserved for conversions; initially this is zero and gets set once loan proposal got
        // accepted and finalized
        uint256 finalCollAmountReservedForConversions;
        // Timestamp when the loan terms get accepted by borrower and after which they cannot be changed anymore
        uint256 loanTermsLockedTime;
        // Current repayment index, mapping to currently relevant repayment schedule element; note the
        // currentRepaymentIdx (initially 0) only ever gets incremented on repay
        uint256 currentRepaymentIdx;
        // Status of current loan proposal
        DataTypesPeerToPool.LoanStatus status;
        // Protocol fee, initially in relative terms (100%=BASE), and after finalization in absolute terms (in loan token);
        // note that the relative protocol fee is locked in at the time when the loan proposal is created
        uint256 protocolFee;
    }

    enum LoanStatus {
        WITHOUT_LOAN_TERMS,
        IN_NEGOTIATION,
        LOAN_TERMS_LOCKED,
        READY_TO_EXECUTE,
        ROLLBACK,
        LOAN_DEPLOYED,
        DEFAULTED
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Constants} from "../Constants.sol";
import {Errors} from "../Errors.sol";
import {Helpers} from "../Helpers.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IFundingPoolImpl} from "./interfaces/IFundingPoolImpl.sol";
import {ILoanProposalImpl} from "./interfaces/ILoanProposalImpl.sol";
import {IMysoTokenManager} from "../interfaces/IMysoTokenManager.sol";

contract Factory is Ownable2Step, ReentrancyGuard, IFactory {
    using ECDSA for bytes32;

    uint256 public protocolFee;
    address public immutable loanProposalImpl;
    address public immutable fundingPoolImpl;
    address public mysoTokenManager;
    address[] public loanProposals;
    address[] public fundingPools;
    mapping(address => bool) public isLoanProposal;
    mapping(address => bool) public isFundingPool;
    mapping(bytes => bool) internal _signatureIsInvalidated;
    mapping(address => bool) internal _depositTokenHasFundingPool;
    mapping(address => mapping(address => uint256))
        internal _lenderWhitelistedUntil;

    constructor(address _loanProposalImpl, address _fundingPoolImpl) {
        if (_loanProposalImpl == address(0) || _fundingPoolImpl == address(0)) {
            revert Errors.InvalidAddress();
        }
        loanProposalImpl = _loanProposalImpl;
        fundingPoolImpl = _fundingPoolImpl;
        _transferOwnership(msg.sender);
    }

    function createLoanProposal(
        address _fundingPool,
        address _collToken,
        address _whitelistAuthority,
        uint256 _arrangerFee,
        uint256 _unsubscribeGracePeriod,
        uint256 _conversionGracePeriod,
        uint256 _repaymentGracePeriod
    ) external nonReentrant {
        if (!isFundingPool[_fundingPool] || _collToken == address(0)) {
            revert Errors.InvalidAddress();
        }
        address newLoanProposal = Clones.clone(loanProposalImpl);
        loanProposals.push(newLoanProposal);
        uint256 _numLoanProposals = loanProposals.length;
        isLoanProposal[newLoanProposal] = true;
        address _mysoTokenManager = mysoTokenManager;
        if (_mysoTokenManager != address(0)) {
            IMysoTokenManager(_mysoTokenManager)
                .processP2PoolCreateLoanProposal(
                    _fundingPool,
                    msg.sender,
                    _collToken,
                    _arrangerFee,
                    _numLoanProposals
                );
        }
        ILoanProposalImpl(newLoanProposal).initialize(
            address(this),
            msg.sender,
            _fundingPool,
            _collToken,
            _whitelistAuthority,
            _arrangerFee,
            _unsubscribeGracePeriod,
            _conversionGracePeriod,
            _repaymentGracePeriod
        );

        emit LoanProposalCreated(
            newLoanProposal,
            _fundingPool,
            msg.sender,
            _collToken,
            _arrangerFee,
            _unsubscribeGracePeriod,
            _numLoanProposals
        );
    }

    function createFundingPool(address _depositToken) external {
        if (_depositTokenHasFundingPool[_depositToken]) {
            revert Errors.FundingPoolAlreadyExists();
        }
        address newFundingPool = Clones.clone(fundingPoolImpl);
        fundingPools.push(newFundingPool);
        isFundingPool[newFundingPool] = true;
        _depositTokenHasFundingPool[_depositToken] = true;
        IFundingPoolImpl(newFundingPool).initialize(
            address(this),
            _depositToken
        );

        emit FundingPoolCreated(
            newFundingPool,
            _depositToken,
            fundingPools.length
        );
    }

    function setProtocolFee(uint256 _newprotocolFee) external {
        _checkOwner();
        uint256 oldprotocolFee = protocolFee;
        if (
            _newprotocolFee > Constants.MAX_P2POOL_PROTOCOL_FEE ||
            _newprotocolFee == oldprotocolFee
        ) {
            revert Errors.InvalidFee();
        }
        protocolFee = _newprotocolFee;
        emit ProtocolFeeUpdated(oldprotocolFee, _newprotocolFee);
    }

    function claimLenderWhitelistStatus(
        address whitelistAuthority,
        uint256 whitelistedUntil,
        bytes calldata compactSig,
        bytes32 salt
    ) external {
        if (_signatureIsInvalidated[compactSig]) {
            revert Errors.InvalidSignature();
        }
        bytes32 payloadHash = keccak256(
            abi.encode(
                address(this),
                msg.sender,
                whitelistedUntil,
                block.chainid,
                salt
            )
        );
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(payloadHash);
        (bytes32 r, bytes32 vs) = Helpers.splitSignature(compactSig);
        address recoveredSigner = messageHash.recover(r, vs);
        if (
            whitelistAuthority == address(0) ||
            recoveredSigner != whitelistAuthority
        ) {
            revert Errors.InvalidSignature();
        }
        mapping(address => uint256)
            storage whitelistedUntilPerLender = _lenderWhitelistedUntil[
                whitelistAuthority
            ];
        if (
            whitelistedUntil < block.timestamp ||
            whitelistedUntil <= whitelistedUntilPerLender[msg.sender]
        ) {
            revert Errors.CannotClaimOutdatedStatus();
        }
        whitelistedUntilPerLender[msg.sender] = whitelistedUntil;
        _signatureIsInvalidated[compactSig] = true;
        emit LenderWhitelistStatusClaimed(
            whitelistAuthority,
            msg.sender,
            whitelistedUntil
        );
    }

    function updateLenderWhitelist(
        address[] calldata lenders,
        uint256 whitelistedUntil
    ) external {
        uint256 lendersLen = lenders.length;
        if (lendersLen == 0) {
            revert Errors.InvalidArrayLength();
        }
        for (uint256 i; i < lendersLen; ) {
            mapping(address => uint256)
                storage whitelistedUntilPerLender = _lenderWhitelistedUntil[
                    msg.sender
                ];
            if (
                lenders[i] == address(0) ||
                whitelistedUntil == whitelistedUntilPerLender[lenders[i]]
            ) {
                revert Errors.InvalidUpdate();
            }
            whitelistedUntilPerLender[lenders[i]] = whitelistedUntil;
            unchecked {
                ++i;
            }
        }
        emit LenderWhitelistUpdated(msg.sender, lenders, whitelistedUntil);
    }

    function setMysoTokenManager(address newTokenManager) external {
        _checkOwner();
        address oldTokenManager = mysoTokenManager;
        if (oldTokenManager == newTokenManager) {
            revert Errors.InvalidAddress();
        }
        mysoTokenManager = newTokenManager;
        emit MysoTokenManagerUpdated(oldTokenManager, newTokenManager);
    }

    function isWhitelistedLender(
        address whitelistAuthority,
        address lender
    ) external view returns (bool) {
        return
            _lenderWhitelistedUntil[whitelistAuthority][lender] >=
            block.timestamp;
    }

    function numLoanProposals() external view returns (uint256) {
        return loanProposals.length;
    }

    function transferOwnership(
        address _newOwnerProposal
    ) public override(Ownable2Step, IFactory) {
        if (
            _newOwnerProposal == address(this) ||
            _newOwnerProposal == pendingOwner() ||
            _newOwnerProposal == owner()
        ) {
            revert Errors.InvalidNewOwnerProposal();
        }
        // @dev: access control check via super.transferOwnership()
        super.transferOwnership(_newOwnerProposal);
    }

    function owner() public view override(Ownable, IFactory) returns (address) {
        return super.owner();
    }

    function pendingOwner()
        public
        view
        override(Ownable2Step, IFactory)
        returns (address)
    {
        return super.pendingOwner();
    }

    function renounceOwnership() public pure override {
        revert Errors.Disabled();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFactory {
    event LoanProposalCreated(
        address indexed loanProposalAddr,
        address indexed fundingPool,
        address indexed sender,
        address collToken,
        uint256 arrangerFee,
        uint256 unsubscribeGracePeriod,
        uint256 numLoanProposals
    );
    event FundingPoolCreated(
        address indexed newFundingPool,
        address indexed depositToken,
        uint256 numFundingPools
    );
    event ProtocolFeeUpdated(uint256 oldProtocolFee, uint256 newProtocolFee);
    event LenderWhitelistStatusClaimed(
        address indexed whitelistAuthority,
        address indexed lender,
        uint256 whitelistedUntil
    );
    event LenderWhitelistUpdated(
        address indexed whitelistAuthority,
        address[] indexed lender,
        uint256 whitelistedUntil
    );
    event MysoTokenManagerUpdated(
        address oldTokenManager,
        address newTokenManager
    );

    /**
     * @notice Creates a new loan proposal
     * @param _fundingPool The address of the funding pool from which lenders are allowed to subscribe, and -if loan proposal is successful- from where loan amount is sourced
     * @param _collToken The address of collateral token to be provided by borrower
     * @param _whitelistAuthority The address of the whitelist authority that can manage the lender whitelist (optional)
     * @param _arrangerFee The relative arranger fee (where 100% = BASE)
     * @param _unsubscribeGracePeriod The unsubscribe grace period, i.e., after a loan gets accepted by the borrower lenders can still unsubscribe for this time period before being locked-in
     * @param _conversionGracePeriod The grace period during which lenders can convert
     * @param _repaymentGracePeriod The grace period during which borrowers can repay
     */
    function createLoanProposal(
        address _fundingPool,
        address _collToken,
        address _whitelistAuthority,
        uint256 _arrangerFee,
        uint256 _unsubscribeGracePeriod,
        uint256 _conversionGracePeriod,
        uint256 _repaymentGracePeriod
    ) external;

    /**
     * @notice Creates a new funding pool
     * @param _depositToken The address of the deposit token to be accepted by the given funding pool
     */
    function createFundingPool(address _depositToken) external;

    /**
     * @notice Sets the protocol fee
     * @dev Can only be called by the loan proposal factory owner
     * @param _newProtocolFee The given protocol fee; note that this amount must be smaller than Constants.MAX_P2POOL_PROTOCOL_FEE (<5%)
     */
    function setProtocolFee(uint256 _newProtocolFee) external;

    /**
     * @notice Allows user to claim whitelisted status
     * @param whitelistAuthority Address of whitelist authorithy
     * @param whitelistedUntil Timestamp until when user is whitelisted
     * @param compactSig Compact signature from whitelist authority
     * @param salt Salt to make signature unique
     */
    function claimLenderWhitelistStatus(
        address whitelistAuthority,
        uint256 whitelistedUntil,
        bytes calldata compactSig,
        bytes32 salt
    ) external;

    /**
     * @notice Allows a whitelist authority to set the whitelistedUntil state for a given lender
     * @dev Anyone can create their own whitelist, and borrowers can decide if and which whitelist they want to use
     * @param lenders Array of lender addresses
     * @param whitelistedUntil Timestamp until which lenders shall be whitelisted under given whitelist authority
     */
    function updateLenderWhitelist(
        address[] calldata lenders,
        uint256 whitelistedUntil
    ) external;

    /**
     * @notice Sets a new MYSO token manager contract
     * @dev Can only be called by registry owner
     * @param newTokenManager Address of the new MYSO token manager contract
     */
    function setMysoTokenManager(address newTokenManager) external;

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     * @param newOwner the proposed new owner address
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Returns the address of the funding pool implementation
     * @return The address of the funding pool implementation
     */
    function fundingPoolImpl() external view returns (address);

    /**
     * @notice Returns the address of the proposal implementation
     * @return The address of the proposal implementation
     */
    function loanProposalImpl() external view returns (address);

    /**
     * @notice Returns the address of a registered loan proposal
     * @param idx The index of the given loan proposal
     * @return The address of a registered loan proposal
     */
    function loanProposals(uint256 idx) external view returns (address);

    /**
     * @notice Returns the address of a registered funding pool
     * @param idx The index of the given funding pool
     * @return The address of a registered funding pool
     */
    function fundingPools(uint256 idx) external view returns (address);

    /**
     * @notice Returns flag whether given address is a registered loan proposal contract
     * @param addr The address to check if its a registered loan proposal
     * @return Flag indicating whether address is a registered loan proposal contract
     */
    function isLoanProposal(address addr) external view returns (bool);

    /**
     * @notice Returns flag whether given address is a registered funding pool contract
     * @param addr The address to check if its a registered funding pool
     * @return Flag indicating whether address is a registered funding pool contract
     */
    function isFundingPool(address addr) external view returns (bool);

    /**
     * @notice Returns the protocol fee
     * @return The protocol fee
     */
    function protocolFee() external view returns (uint256);

    /**
     * @notice Returns the address of the owner of this contract
     * @return The address of the owner of this contract
     */
    function owner() external view returns (address);

    /**
     * @notice Returns address of the pending owner
     * @return Address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice Returns the address of the MYSO token manager
     * @return Address of the MYSO token manager contract
     */
    function mysoTokenManager() external view returns (address);

    /**
     * @notice Returns boolean flag indicating whether the lender has been whitelisted by whitelistAuthority
     * @param whitelistAuthority Addresses of the whitelist authority
     * @param lender Addresses of the lender
     * @return Boolean flag indicating whether the lender has been whitelisted by whitelistAuthority
     */
    function isWhitelistedLender(
        address whitelistAuthority,
        address lender
    ) external view returns (bool);

    /**
     * @notice Returns the number of loan proposals created
     * @return Number of loan proposals created
     */
    function numLoanProposals() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IFundingPoolImpl {
    event Deposited(
        address user,
        uint256 amount,
        uint256 depositLockupDuration
    );
    event Withdrawn(address user, uint256 amount);
    event Subscribed(
        address indexed user,
        address indexed loanProposalAddr,
        uint256 amount,
        uint256 subscriptionLockupDuration
    );
    event Unsubscribed(
        address indexed user,
        address indexed loanProposalAddr,
        uint256 amount
    );
    event LoanProposalExecuted(
        address indexed loanProposal,
        address indexed borrower,
        uint256 grossLoanAmount,
        uint256 arrangerFee,
        uint256 protocolFee
    );

    /**
     * @notice Initializes funding pool
     * @param _factory Address of the factory contract spawning the given funding pool
     * @param _depositToken Address of the deposit token for the given funding pool
     */
    function initialize(address _factory, address _depositToken) external;

    /**
     * @notice function allows users to deposit into funding pool
     * @param amount amount to deposit
     * @param transferFee this accounts for any transfer fee token may have (e.g. paxg token)
     * @param depositLockupDuration the duration for which the deposit shall be locked (optional for tokenomics)
     */
    function deposit(
        uint256 amount,
        uint256 transferFee,
        uint256 depositLockupDuration
    ) external;

    /**
     * @notice function allows users to withdraw from funding pool
     * @param amount amount to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice function allows users from funding pool to subscribe as lenders to a proposal
     * @param loanProposal address of the proposal to which user wants to subscribe
     * @param minAmount the desired minimum subscription amount
     * @param maxAmount the desired maximum subscription amount
     * @param subscriptionLockupDuration the duration for which the subscription shall be locked (optional for tokenomics)
     */
    function subscribe(
        address loanProposal,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 subscriptionLockupDuration
    ) external;

    /**
     * @notice function allows subscribed lenders to unsubscribe from a proposal
     * @dev there is a cooldown period after subscribing to mitigate possible griefing attacks
     * of subscription followed by quick unsubscription
     * @param loanProposal address of the proposal to which user wants to unsubscribe
     * @param amount amount of subscription removed
     */
    function unsubscribe(address loanProposal, uint256 amount) external;

    /**
     * @notice function allows execution of a proposal
     * @param loanProposal address of the proposal executed
     */
    function executeLoanProposal(address loanProposal) external;

    /**
     * @notice function returns factory address
     */
    function factory() external view returns (address);

    /**
     * @notice function returns address of deposit token for pool
     */
    function depositToken() external view returns (address);

    /**
     * @notice function returns balance deposited into pool
     * note: balance is tracked only through using deposit function
     * direct transfers into pool are not credited
     */
    function balanceOf(address) external view returns (uint256);

    /**
     * @notice function tracks total subscription amount for a given proposal address
     */
    function totalSubscriptions(address) external view returns (uint256);

    /**
     * @notice function tracks subscription amounts for a given proposal address and subsciber address
     */
    function subscriptionAmountOf(
        address,
        address
    ) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {DataTypesPeerToPool} from "../DataTypesPeerToPool.sol";

interface ILoanProposalImpl {
    event LoanTermsProposed(DataTypesPeerToPool.LoanTerms loanTerms);
    event LoanTermsLocked();
    event LoanTermsAndTransferCollFinalized(
        uint256 grossLoanAmount,
        uint256[2] collAmounts,
        uint256[2] fees
    );
    event Rolledback(address sender);
    event LoanDeployed();
    event ConversionExercised(
        address indexed sender,
        uint256 amount,
        uint256 repaymentIdx
    );
    event RepaymentClaimed(
        address indexed sender,
        uint256 amount,
        uint256 repaymentIdx
    );
    event Repaid(
        uint256 remainingLoanTokenDue,
        uint256 collTokenLeftUnconverted,
        uint256 repaymentIdx
    );
    event LoanDefaulted();
    event DefaultProceedsClaimed(address indexed sender);

    /**
     * @notice Initializes loan proposal
     * @param _factory Address of the factory contract from which proposal is created
     * @param _arranger Address of the arranger of the proposal
     * @param _fundingPool Address of the funding pool to be used to source liquidity, if successful
     * @param _collToken Address of collateral token to be used in loan
     * @param _whitelistAuthority Address of whitelist authority who can manage the lender whitelist (optional)
     * @param _arrangerFee Arranger fee in percent (where 100% = BASE)
     * @param _unsubscribeGracePeriod The unsubscribe grace period, i.e., after a loan gets accepted by the borrower 
     lenders can still unsubscribe for this time period before being locked-in
     * @param _conversionGracePeriod The grace period during which lenders can convert
     * @param _repaymentGracePeriod The grace period during which borrowers can repay
     */
    function initialize(
        address _factory,
        address _arranger,
        address _fundingPool,
        address _collToken,
        address _whitelistAuthority,
        uint256 _arrangerFee,
        uint256 _unsubscribeGracePeriod,
        uint256 _conversionGracePeriod,
        uint256 _repaymentGracePeriod
    ) external;

    /**
     * @notice Propose new loan terms
     * @param newLoanTerms The new loan terms
     * @dev Can only be called by the arranger
     */
    function updateLoanTerms(
        DataTypesPeerToPool.LoanTerms calldata newLoanTerms
    ) external;

    /**
     * @notice Lock loan terms
     * @param loanTermsUpdateTime The timestamp at which loan terms are locked
     * @dev Can only be called by the arranger or borrower
     */
    function lockLoanTerms(uint256 loanTermsUpdateTime) external;

    /**
     * @notice Finalize the loan terms and transfer final collateral amount
     * @param expectedTransferFee The expected transfer fee (if any) of the collateral token
     * @param mysoTokenManagerData Data to be passed to MysoTokenManager
     * @dev Can only be called by the borrower
     */
    function finalizeLoanTermsAndTransferColl(
        uint256 expectedTransferFee,
        bytes calldata mysoTokenManagerData
    ) external;

    /**
     * @notice Rolls back the loan proposal
     * @dev Can be called by borrower during the unsubscribe grace period or by anyone in case the total totalSubscriptions fell below the minTotalSubscriptions
     */
    function rollback() external;

    /**
     * @notice Checks and updates the status of the loan proposal from 'READY_TO_EXECUTE' to 'LOAN_DEPLOYED'
     * @dev Can only be called by funding pool in conjunction with executing the loan proposal and settling amounts, i.e., sending loan amount to borrower and fees
     */
    function checkAndUpdateStatus() external;

    /**
     * @notice Allows lenders to exercise their conversion right for given repayment period
     * @dev Can only be called by entitled lenders and during conversion grace period of given repayment period
     */
    function exerciseConversion() external;

    /**
     * @notice Allows borrower to repay
     * @param expectedTransferFee The expected transfer fee (if any) of the loan token
     * @dev Can only be called by borrower and during repayment grace period of given repayment period. If borrower doesn't repay in time the loan can be marked as defaulted and borrowers loses control over pledged collateral. Note that the repayment amount can be lower than the loanTokenDue if lenders convert (potentially 0 if all convert, in which case borrower still needs to call the repay function to not default). Also note that on repay any unconverted collateral token reserved for conversions for that period get transferred back to borrower.
     */
    function repay(uint256 expectedTransferFee) external;

    /**
     * @notice Allows lenders to claim any repayments for given repayment period
     * @param repaymentIdx the given repayment period index
     * @dev Can only be called by entitled lenders and if they didn't make use of their conversion right
     */
    function claimRepayment(uint256 repaymentIdx) external;

    /**
     * @notice Marks loan proposal as defaulted
     * @dev Can be called by anyone but only if borrower failed to repay during repayment grace period
     */
    function markAsDefaulted() external;

    /**
     * @notice Allows lenders to claim default proceeds
     * @dev Can only be called if borrower defaulted and loan proposal was marked as defaulted; default proceeds are whatever is left in collateral token in loan proposal contract; proceeds are splitted among all lenders taking into account any conversions lenders already made during the default period.
     */
    function claimDefaultProceeds() external;

    /**
     * @notice Returns the amount of subscriptions that converted for given repayment period
     * @param repaymentIdx The respective repayment index of given period
     * @return The total amount of subscriptions that converted for given repayment period
     */
    function totalConvertedSubscriptionsPerIdx(
        uint256 repaymentIdx
    ) external view returns (uint256);

    /**
     * @notice Returns the amount of collateral tokens that were converted during given repayment period
     * @param repaymentIdx The respective repayment index of given period
     * @return The total amount of collateral tokens that were converted during given repayment period
     */
    function collTokenConverted(
        uint256 repaymentIdx
    ) external view returns (uint256);

    /**
     * @notice Returns core dynamic data for given loan proposal
     * @return arrangerFee The arranger fee, which initially is expressed in relative terms (i.e., 100% = BASE) and once the proposal gets finalized is in absolute terms (e.g., 1000 USDC)
     * @return grossLoanAmount The final loan amount, which initially is zero and gets set once the proposal gets finalized
     * @return finalCollAmountReservedForDefault The final collateral amount reserved for default case, which initially is zero and gets set once the proposal gets finalized.
     * @return finalCollAmountReservedForConversions The final collateral amount reserved for lender conversions, which initially is zero and gets set once the proposal gets finalized
     * @return loanTermsLockedTime The timestamp when loan terms got locked in, which initially is zero and gets set once the proposal gets finalized
     * @return currentRepaymentIdx The current repayment index, which gets incremented on every repay
     * @return status The current loan proposal status.
     * @return protocolFee The protocol fee, which initially is expressed in relative terms (i.e., 100% = BASE) and once the proposal gets finalized is in absolute terms (e.g., 1000 USDC). Note that the relative protocol fee is locked in at the time when the proposal is first created
     * @dev Note that finalCollAmountReservedForDefault is a lower bound for the collateral amount that lenders can claim in case of a default. This means that in case all lenders converted and the borrower defaults then this amount will be distributed as default recovery value on a pro-rata basis to lenders. In the other case where no lenders converted then finalCollAmountReservedForDefault plus finalCollAmountReservedForConversions will be available as default recovery value for lenders, hence finalCollAmountReservedForDefault is a lower bound for a lender's default recovery value.
     */
    function dynamicData()
        external
        view
        returns (
            uint256 arrangerFee,
            uint256 grossLoanAmount,
            uint256 finalCollAmountReservedForDefault,
            uint256 finalCollAmountReservedForConversions,
            uint256 loanTermsLockedTime,
            uint256 currentRepaymentIdx,
            DataTypesPeerToPool.LoanStatus status,
            uint256 protocolFee
        );

    /**
     * @notice Returns core static data for given loan proposal
     * @return factory The address of the factory contract from which the proposal was created
     * @return fundingPool The address of the funding pool from which lenders can subscribe, and from which 
     -upon acceptance- the final loan amount gets sourced
     * @return collToken The address of the collateral token to be provided by the borrower
     * @return arranger The address of the arranger of the proposal
     * @return whitelistAuthority Addresses of the whitelist authority who can manage a lender whitelist (optional)
     * @return unsubscribeGracePeriod Unsubscribe grace period until which lenders can unsubscribe after a loan 
     proposal got accepted by the borrower
     * @return conversionGracePeriod Conversion grace period during which lenders can convert, i.e., between 
     [dueTimeStamp, dueTimeStamp+conversionGracePeriod]
     * @return repaymentGracePeriod Repayment grace period during which borrowers can repay, i.e., between 
     [dueTimeStamp+conversionGracePeriod, dueTimeStamp+conversionGracePeriod+repaymentGracePeriod]
     */
    function staticData()
        external
        view
        returns (
            address factory,
            address fundingPool,
            address collToken,
            address arranger,
            address whitelistAuthority,
            uint256 unsubscribeGracePeriod,
            uint256 conversionGracePeriod,
            uint256 repaymentGracePeriod
        );

    /**
     * @notice Returns the timestamp of when loan terms were last updated
     * @return lastLoanTermsUpdateTime The timestamp when the loan terms were last updated
     */
    function lastLoanTermsUpdateTime()
        external
        view
        returns (uint256 lastLoanTermsUpdateTime);

    /**
     * @notice Returns the current loan terms
     * @return The current loan terms
     */
    function loanTerms()
        external
        view
        returns (DataTypesPeerToPool.LoanTerms memory);

    /**
     * @notice Returns flag indicating whether lenders can currently unsubscribe from loan proposal
     * @return Flag indicating whether lenders can currently unsubscribe from loan proposal
     */
    function canUnsubscribe() external view returns (bool);

    /**
     * @notice Returns flag indicating whether lenders can currently subscribe to loan proposal
     * @return Flag indicating whether lenders can currently subscribe to loan proposal
     */
    function canSubscribe() external view returns (bool);

    /**
     * @notice Returns indicative final loan terms
     * @param _tmpLoanTerms The current (or assumed) relative loan terms
     * @param totalSubscriptions The current (or assumed) total subscription amount
     * @param loanTokenDecimals The loan token decimals
     * @return loanTerms The loan terms in absolute terms
     * @return collAmounts Array containing collateral amount reserved for default and for conversions
     * @return fees Array containing arranger fee and protocol fee
     */
    function getAbsoluteLoanTerms(
        DataTypesPeerToPool.LoanTerms memory _tmpLoanTerms,
        uint256 totalSubscriptions,
        uint256 loanTokenDecimals
    )
        external
        view
        returns (
            DataTypesPeerToPool.LoanTerms memory loanTerms,
            uint256[2] memory collAmounts,
            uint256[2] memory fees
        );
}