/**
 *Submitted for verification at Arbiscan on 2023-04-16
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: contracts/OnchainPower.sol



pragma solidity >=0.8.0 <0.9.0;



library Base64 {
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
  function buildImage(string memory _bgHue, string memory _eyesHue, string memory _pukeHue) internal pure returns(string memory) {
    return encode(bytes(abi.encodePacked(
      '<?xml version="1.0" encoding="utf-8"?><svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="1024px" height="1024px" viewBox="0 0 1024 1024" preserveAspectRatio="xMidYMid meet">',
      '<g fill="hsl(', _bgHue, ',100%,80%)"><path d="M0 512 l0 -512 512 0 512 0 0 512 0 512 -512 0 -512 0 0 -512z m513.7 403.9 c3 -1.1 8.8 -6.3 10.4 -9.2 0.6 -1 1.9 -5.1 3 -9.2 1 -4.1 3.2 -9.6 4.7 -12.2 3.5 -6 6.2 -6.5 14.6 -2.7 15.6 7.1 35.3 -0.3 43.3 -16.1 3.3 -6.5 6.3 -23.9 6.4 -37.5 0 -5.8 0.6 -20.1 1.2 -31.8 l1.2 -21.4 6.7 -2.3 c43.6 -15.2 79.2 -44.7 109.4 -90.5 22.7 -34.4 35.7 -72.7 34 -100 -1.3 -20.8 -9.2 -39.4 -22.2 -52.4 -14.8 -14.8 -33.6 -22 -57.4 -21.9 -11.5 0.1 -13.5 0.4 -24.5 3.8 -8.3 2.5 -17 6.3 -28.5 12.2 -40.9 21.3 -49.1 25.1 -64.8 30.2 -31 9.8 -43.1 11.5 -80.7 11.6 -42.6 0 -52.9 -2.1 -112 -22.7 -25.8 -9.1 -52.2 1.2 -69 26.7 -5.9 9 -10.6 21.4 -12.4 32.5 -7.1 43.8 24.5 96.3 82.4 136.7 24 16.7 49.3 29.7 78 40 l8 2.9 -0.1 3.9 c0 2.2 -0.5 8.9 -1.2 14.9 -0.7 6 -1.2 18.5 -1.2 27.7 0 25.5 2.5 35.5 11.4 44.7 7 7.4 10.2 8.5 23 8.1 l11 -0.4 0.9 4 c0.4 2.2 1.2 6.9 1.8 10.4 1.6 10.1 5.1 15.6 12.4 19.4 3.6 1.9 6.4 2.1 10.2 0.6z m-144.6 -485.5 c37.8 -6.1 67.4 -28.2 82.9 -61.8 8.5 -18.4 12.2 -36.9 12.3 -61.6 0.1 -16.2 -0.1 -18.3 -2.7 -28.5 -4.6 -17.6 -11.6 -30.5 -23 -42.4 -18.6 -19.3 -45.1 -30.4 -72.6 -30.4 -12.1 -0.1 -16.7 0.7 -32 5.5 -40.1 12.5 -66.1 38.4 -76.7 76.3 -2.7 9.5 -2.8 11 -2.7 30.5 0.1 21.2 1.1 29.4 5.6 45.9 10.3 37.7 33.8 60.5 68.8 66.5 15.9 2.7 23.7 2.7 40.1 0z m261.2 0 c12.7 -2.4 25.2 -7.3 39.1 -15.4 11.3 -6.5 18.2 -11.7 26.9 -20.3 29.7 -29.3 38.3 -66.7 25 -109.2 -9.2 -29.3 -29.6 -54.6 -56.3 -69.7 -18.8 -10.6 -44 -15.5 -64 -12.4 -13 2 -18.9 3.7 -31.3 8.8 -38.7 16 -61.8 50.7 -66.8 100.3 -1.9 19.3 -0.3 37 5.1 56 7.7 27.2 28 48 55.5 56.8 21.9 7 46.7 8.9 66.8 5.1z"/></g>',
      '<g fill="#5c2929"><path d="M494.5 784.3 c-12.2 -0.7 -28.5 -2.6 -33.5 -3.8 -15.1 -3.6 -26.4 -7 -34.5 -10.2 -34.3 -13.6 -68.3 -34.5 -92 -56.5 -24.3 -22.5 -36.5 -39.3 -45.4 -62.2 -5.1 -13.2 -6.5 -22.9 -5.8 -41.5 0.7 -20.3 4.7 -31.8 15.6 -44.8 10.4 -12.5 23.7 -18.3 41.6 -18.3 11.3 0 12.8 0.4 41.6 10.3 33.2 11.5 53 15.6 79.9 16.4 34.9 1.1 68.1 -4.7 102 -17.7 7.9 -3 19.6 -8.9 54 -26.8 22.7 -11.8 36.2 -15 58 -13.8 14.1 0.8 22.2 2.6 32 7.3 14.1 6.7 26.9 22.8 31.7 39.5 2 7.4 2.9 33.4 1.3 43.9 -2.4 17.1 -7.3 31.8 -16.7 50.4 -7.6 15.2 -7.4 14.9 -13.6 24.4 -19 29.1 -46.9 57.3 -68.8 69.6 -14.2 7.9 -19.7 10.5 -22.5 10.5 -2.8 0 -3.3 -0.5 -4.9 -4.7 -5 -13.5 -13.9 -31.5 -21.9 -44.1 -2.9 -4.7 -18.5 -23 -23.7 -27.9 -8.9 -8.4 -34.6 -22.7 -46.4 -25.8 -10.5 -2.8 -18.2 -3 -25.8 -0.7 -9.8 2.9 -13.2 5.6 -17 13.2 -2.7 5.4 -3.2 7.6 -3.1 13 0.1 7.6 5 24.3 12 40.7 2.4 5.7 4.4 10.5 4.4 10.8 0 0.4 0.8 2.5 1.9 4.8 1 2.3 3.8 9.4 6.1 15.7 2.4 6.3 4.7 12.1 5.3 12.8 0.5 0.7 1.2 4.6 1.5 8.7 l0.5 7.5 -4.4 -0.2 c-2.4 -0.1 -6.6 -0.3 -9.4 -0.5z"/><path d="M685.4 230.6 c-0.3 -0.8 -0.4 -2.6 -0.2 -4.1 l0.3 -2.6 4 4 3.9 4.1 -3.7 0 c-2.3 0 -4 -0.5 -4.3 -1.4z"/></g>',
      '<g fill="hsl(', _eyesHue, ',100%,92%)"><path d="M328.5 428.3 c-25.4 -5.6 -39.6 -13.8 -50.9 -29.2 -13.1 -17.9 -20.6 -47.5 -20.6 -81.6 0 -46.9 17.6 -77.3 55.4 -96 20 -9.9 35.4 -13 59.9 -12.2 26.7 0.8 44.2 7.6 62.5 24.3 18.8 17 28 42.8 26.9 75.4 -0.8 22.5 -2.6 34.6 -7.7 50.1 -6.7 20.5 -18.6 37.4 -34.3 49.1 -9.2 6.8 -22.9 13.7 -31.7 15.8 -16.9 4.2 -22.7 4.9 -40 4.9 -9.6 -0.1 -18.4 -0.3 -19.5 -0.6z m-21.8 -124.8 c1.9 -0.8 5.9 -1.5 8.7 -1.5 5.5 0 8.7 -1.2 6.6 -2.5 -0.7 -0.4 -1 -2.7 -0.9 -5.9 0.1 -2.8 -0.3 -6.1 -0.9 -7.3 -0.7 -1.2 -1.2 -3.2 -1.2 -4.4 0 -3.9 -2.8 -5.9 -8.1 -5.9 -3.7 0 -5.3 0.5 -6.9 2.2 -1.1 1.2 -2 2.5 -2 3 0 0.4 -1.8 2 -4 3.4 -2.2 1.5 -4 3.1 -4 3.7 0 0.6 1.1 2.5 2.5 4.3 1.4 1.8 2.5 4.6 2.5 6.3 0 2.5 2.1 6.1 3.6 6.1 0.3 0 2.1 -0.7 4.1 -1.5z"/><path d="M582.5 427.5 c-26.2 -4.2 -42.1 -11.6 -55.1 -25.9 -7.3 -8 -14.1 -20.7 -17.4 -32.6 -9.7 -35 -4.5 -86.9 11.6 -114.3 12.8 -21.8 31.7 -36.3 57.4 -44.1 12.2 -3.6 19.6 -4.6 36.2 -4.6 20.1 0 33.9 3 49.2 10.7 19.3 9.7 38.7 30.3 48.3 51 7.2 15.7 9.8 25.9 11.2 44.9 2.4 31.4 -4.4 54.2 -22.3 74.9 -8.7 10.1 -12.9 13.8 -23.6 20.9 -14.8 9.8 -27.9 15.6 -43.7 19 -8.9 2 -39.8 2 -51.8 0.1z m84.9 -128.5 c2.3 0 4.7 -0.5 5.4 -1.2 1.9 -1.9 1.4 -5.3 -1.3 -7.8 -1.4 -1.3 -2.5 -3.4 -2.5 -4.6 0 -1.3 -0.6 -2.8 -1.2 -3.3 -7.9 -6.5 -7.7 -6.4 -10.2 -4.8 -1.3 0.9 -4.5 1.7 -7.2 1.9 l-4.9 0.3 -0.3 5 c-0.2 2.7 -0.8 5.5 -1.4 6.2 -1.5 1.8 -0.2 3.2 5.5 5.7 2.9 1.3 6.3 3.6 7.6 5.1 l2.4 2.8 1.9 -2.6 c1.6 -2.2 2.8 -2.7 6.2 -2.7z"/></g>',
      '<g fill="#010101">',
      '<path d="M500.5 918.3 c-7.3 -3.8 -10.8 -9.3 -12.4 -19.4 -0.6 -3.5 -1.4 -8.1 -1.8 -10.3 l-0.8 -3.9 -11.2 0.2 c-12.9 0.2 -16 -0.9 -22.9 -8.1 -9.2 -9.5 -11.4 -18.9 -11.4 -47.7 0 -15.7 1.1 -35.1 2.3 -42.5 0.1 -0.5 -3.4 -2.3 -7.8 -3.9 -69.1 -25.1 -125.3 -69.3 -149.2 -117.2 -16.9 -33.7 -16.4 -71.2 1.2 -98 9.2 -14 20.1 -22.4 36 -28.1 3.7 -1.3 8.1 -1.8 17.5 -1.8 11.5 0 13.2 0.2 21.5 3.1 36.2 12.8 56.4 18.6 74.5 21.5 5.6 0.8 17.5 1.3 34.5 1.3 34.3 -0.1 47.4 -2 77.7 -11.6 15.7 -5.1 23.9 -8.9 64.8 -30.2 11.4 -5.9 20.2 -9.7 28.5 -12.3 11.4 -3.5 12.7 -3.7 27 -3.8 16.1 -0.1 24.8 1.3 36.5 5.9 39.6 15.5 56.4 61.2 41.5 113 -6 20.7 -15.7 41.5 -28.9 61.5 -30.2 45.8 -65.8 75.3 -109.4 90.5 l-6.7 2.3 -1.2 21.4 c-0.6 11.7 -1.2 26 -1.2 31.8 -0.1 13.6 -3.1 31 -6.4 37.5 -3.4 6.9 -11 13.7 -18.3 16.5 -4.6 1.9 -7.9 2.4 -15.4 2.4 -8.3 0.1 -10.2 -0.3 -15.3 -2.6 l-5.7 -2.7 -1.5 2.5 c-0.8 1.3 -2.2 3.5 -3 4.8 -0.8 1.3 -2.3 5.8 -3.4 10 -1.1 4.1 -2.4 8.3 -3 9.3 -1.6 2.9 -7.4 8.1 -10.4 9.2 -4.1 1.6 -12.7 1.3 -16.2 -0.6z m13.4 -13 c1.8 -1.9 3.3 -5.1 4.5 -9.7 5.4 -21.8 15.9 -29.3 30.3 -21.6 6.5 3.5 10.3 3.7 17.8 1.1 7.2 -2.6 11.6 -6.1 14.8 -12 4.4 -7.9 4.5 -9.1 7.4 -64.8 0.3 -6.2 0.4 -11.3 0.2 -11.3 -0.2 0 -9.8 1.9 -21.4 4.1 -42.8 8.4 -64.9 9.4 -98.7 4.3 -5.7 -0.8 -11.3 -1.7 -12.4 -2 -2.5 -0.6 -2.7 0.2 -4.4 16.6 -2.1 20.6 -0.6 40.6 3.7 50.3 1.9 4.2 4 6.9 7.2 9.4 4.5 3.4 4.8 3.5 11.6 2.9 3.9 -0.3 9.1 -0.8 11.6 -1.2 4.2 -0.5 4.8 -0.3 7.2 2.5 2.7 3.3 5.3 10.9 6.8 20.5 1.2 7 2 8.8 5.5 11.5 3.5 2.8 5 2.6 8.3 -0.6z m-9.3 -127.9 c-0.3 -2.6 -1 -5.2 -1.5 -5.8 -0.4 -0.6 -2.7 -6.3 -5.1 -12.6 -2.3 -6.3 -5.1 -13.4 -6.1 -15.7 -1.1 -2.3 -1.9 -4.4 -1.9 -4.8 0 -0.3 -2 -5.1 -4.4 -10.8 -2.4 -5.6 -6.1 -15.6 -8.2 -22.2 -3.3 -10.4 -3.8 -13.3 -3.9 -21.5 0 -8.7 0.3 -10.1 3.2 -16 3.9 -7.8 7 -10.1 17.9 -13.5 7.2 -2.2 8.6 -2.4 16.4 -1.5 4.7 0.5 11.2 1.7 14.5 2.5 11.7 3.1 37.4 17.4 46.4 25.8 5.2 4.9 20.8 23.2 23.7 27.9 8 12.6 16.9 30.6 21.9 44 l1.7 4.6 3.8 -1.6 c6.6 -3 21 -11.5 28.4 -16.9 19.2 -14.1 40.8 -37.7 56.3 -61.4 6.2 -9.5 6 -9.2 13.6 -24.4 9.4 -18.6 14.3 -33.3 16.8 -50.4 1.4 -10.1 0.7 -30.2 -1.5 -37.9 -4.6 -16.6 -17.5 -32.8 -31.6 -39.5 -18.2 -8.7 -42.4 -9.9 -62.9 -3.1 -4.2 1.4 -13.7 5.7 -21.1 9.6 -52.2 27.2 -59.9 30.5 -87.2 37.2 -24.9 6.1 -43.8 8 -71.7 7.3 -29.8 -0.7 -48.4 -4.4 -83 -16.4 -27 -9.3 -30.7 -10.3 -38.6 -10.3 -23.5 0 -44 16.9 -52 43 -2.2 7.5 -3.1 26.6 -1.6 37.1 2.9 19.7 15.4 43.6 33.1 63.2 23.5 25.9 54.7 48.8 88.2 64.6 21.5 10.2 32 13.9 55.8 19.6 5 1.2 21.3 3.1 33.5 3.8 2.8 0.2 5.6 0.4 6.4 0.5 1.1 0.2 1.2 -0.8 0.7 -4.4z m39.4 -2.3 c5.2 -1 13.6 -2.7 18.5 -3.6 21.5 -4.1 43.5 -10.8 43.5 -13.2 0 -2 -9 -21.8 -13.6 -29.9 -8.7 -15.6 -15.2 -24 -27.4 -35.7 -16.8 -16.2 -32.7 -24.8 -50.6 -27.7 -6.9 -1.1 -10.3 -0.5 -17.4 3 -4.3 2.2 -8.9 10.6 -8.9 16.5 -0.1 4.2 6.6 27.8 10 35.5 1.1 2.5 4.3 10.6 7 18 2.8 7.4 6.7 17.8 8.8 23 2.1 5.2 4.2 11.3 4.6 13.4 l0.6 3.9 7.7 -0.6 c4.2 -0.3 12 -1.5 17.2 -2.6z"/>',
      '<path d="M339.5 435.4 c-10 -1 -23.7 -3.9 -31 -6.7 -25.6 -9.6 -43.5 -31.8 -52 -64.4 -2.1 -8.2 -5.3 -26.6 -5.3 -31.3 -0.6 -29.7 -0.2 -34.9 3.4 -49 7.9 -30.3 28.4 -54.8 57.8 -68.5 19.6 -9.2 35.5 -13 54.1 -12.9 30.2 0.1 55.8 10.5 75.1 30.5 11.4 11.9 18.4 24.8 23 42.4 2.7 10.5 2.9 12 2.8 31.5 -0.1 17 -0.5 22.5 -2.4 32 -5.5 28 -14.8 46.8 -31.3 63.4 -20.6 20.7 -46.4 31.4 -79.7 32.9 -5.8 0.3 -12.3 0.3 -14.5 0.1z m32 -11.3 c17.3 -3.7 17 -3.6 31.2 -10.2 16.6 -7.9 33 -24.4 42.2 -42.8 8.5 -16.7 12.8 -36.8 13.7 -63.1 1 -29 -8.8 -55.1 -26.8 -71.4 -17.3 -15.8 -35.7 -23.4 -59.4 -24.3 -21 -0.9 -37.6 2.7 -57 12.2 -23.4 11.6 -39.1 27.9 -48.1 50.2 -13.7 34.1 -7.2 93.4 13.3 121.4 11.3 15.4 25.5 23.6 50.9 29.2 1.1 0.3 8.5 0.5 16.5 0.6 10.6 0 16.9 -0.5 23.5 -1.8z"/><path d="M297.6 306.4 c-1.6 -1.6 -2 -2.7 -1.7 -5.6 0.1 -0.9 -1.2 -3.6 -2.8 -5.9 -3.8 -5.2 -3.9 -8.4 -0.5 -11.2 3.5 -2.9 6.5 -5.9 8.6 -8.5 1.6 -1.9 2.8 -2.2 9.6 -2.2 8.8 0 10.9 1.2 11.5 6.6 0.2 1.7 1.2 4.2 2.1 5.6 1.5 2.3 1.6 3.2 0.5 6.1 -1 2.9 -1 3.8 0.4 5.8 3.5 4.9 0.9 7.9 -6.7 7.9 -3 0 -7 0.7 -8.9 1.5 -4.7 1.9 -10.1 1.9 -12.1 -0.1z"/><path d="M595.9 435 c-31 -2.4 -52.6 -10.8 -69.2 -26.9 -17.3 -16.7 -25.8 -39.2 -27.3 -72.1 -2.1 -45 10.6 -82.6 35.9 -106.7 20.6 -19.6 54.5 -31.6 84.2 -29.9 13.4 0.8 25.3 3.3 36.5 7.9 15.5 6.3 25.4 13 38.6 26.1 17.4 17.4 28.2 38.2 34 65.6 2.1 10.3 2.4 35.4 0.5 44.5 -4.6 21.2 -14.3 38.9 -29.8 54.2 -8.7 8.6 -15.6 13.8 -26.9 20.3 -25.1 14.6 -46.6 19.3 -76.5 17z m35.4 -10.6 c15.8 -3.4 28.9 -9.2 43.7 -19 10.7 -7.1 14.9 -10.8 23.6 -20.9 15.9 -18.4 22.5 -36.7 22.5 -62 -0.1 -32.8 -11.8 -61.5 -34 -83.5 -20.9 -20.8 -44 -30.3 -72.6 -29.9 -14.3 0.1 -21.1 1.1 -32.5 4.5 -25.7 7.8 -44.6 22.3 -57.4 44.1 -15.7 26.8 -20.8 74.7 -11.6 108.3 7.9 28.8 28.6 48.8 57.7 55.6 19.2 4.5 46.9 5.8 60.6 2.8z"/><path d="M654.3 304.9 c-1.5 -1.7 -5.2 -4.2 -8.1 -5.5 -6.6 -3 -8.3 -6.1 -5.9 -10.7 1.2 -2.1 1.5 -4.3 1.1 -6.3 -0.9 -4.5 2.2 -7.5 7 -6.7 2.3 0.4 4.2 0 5.7 -1.1 1.3 -0.9 3.9 -1.6 5.7 -1.6 3.1 0 4.5 0.8 11 6.1 0.6 0.5 1.2 1.9 1.2 3.1 0 1.2 1.1 3.4 2.5 4.8 3.5 3.6 3.8 11.5 0.6 14.1 -1.6 1.3 -3.1 1.6 -5.2 1.2 -2.5 -0.5 -3.5 -0.1 -5.9 2.6 -3.6 3.9 -6.1 3.9 -9.7 0z"/>',
      '</g><g fill="hsl(', _pukeHue, ', 60%, 40%)"><path d="M501.5 907.7 c-2.5 -2.5 -3.5 -4.5 -4 -8.3 -0.4 -2.7 -1.4 -7.6 -2.2 -10.9 -3 -11.2 -6.2 -15.3 -10.7 -13.5 -1.5 0.5 -6.7 1 -11.5 1 -8.5 0 -9 -0.1 -13.3 -3.4 -9.3 -7.1 -12.6 -22.2 -11.5 -52.1 0.6 -14.3 1.9 -27.9 3.1 -31.2 0.4 -0.9 1.6 -0.8 4.8 0.2 5.9 1.7 23.7 4.3 37.8 5.4 11.2 0.9 27.6 0.2 42.5 -1.8 8.2 -1 46.4 -8.5 51.5 -10 1.9 -0.6 3.7 -1.1 3.9 -1.1 1 0 -2.4 66.2 -3.9 73.9 -1.3 6.9 -5.4 14.4 -9.7 17.7 -5 3.8 -13.3 6.4 -20.6 6.4 -5.2 0 -7.5 -0.6 -12.2 -3.1 -3.8 -2 -6.5 -2.9 -8 -2.5 -6.4 1.6 -12.9 11.4 -16.1 24.2 -2.3 9.2 -5.4 12.4 -11.9 12.4 -4 0 -5.2 -0.5 -8 -3.3z"/></g><g fill="#b64949"><path d="M515.5 777.4 c-0.4 -2.2 -2.5 -8.2 -4.6 -13.4 -2.1 -5.2 -6 -15.6 -8.8 -23 -2.7 -7.4 -5.9 -15.5 -7 -18 -1.1 -2.5 -3.8 -10.6 -6 -18 -3.2 -10.5 -4.1 -15.1 -4 -20.5 0.1 -21.4 17.1 -28.6 45 -19.2 14.1 4.8 24.4 11.4 37.9 24.4 12.2 11.7 18.7 20.1 27.4 35.7 5 8.7 15.6 32.6 15.6 35 0 2.7 -23.2 9.9 -45.5 14.1 -4.9 0.9 -13.3 2.6 -18.5 3.7 -5.2 1.1 -14.3 2.2 -20.2 2.5 l-10.7 0.6 -0.6 -3.9z"/></g>',
      '</svg>'
    )));
  }
}

contract OnchainPower is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public cost = 0.00023 ether;

  struct ItemData { 
    string name;
    string description;
    string bgHue;
    string eyesHue;
    string pukeHue;
   }
  
  mapping (uint256 => ItemData) public itemsData;

  constructor() ERC721("Onchain Power", "POWER") {}

  function randomNum(uint256 _minNumber, uint256 _maxNumber, uint256 startAddressIndex, uint256 _salt) private view returns(uint256) {
    uint endAddressIndex = startAddressIndex + 8;
    bytes memory addressBytes = abi.encodePacked(msg.sender);
    bytes memory addressRandomnessSeed = new bytes(endAddressIndex - startAddressIndex);
    for(uint i = startAddressIndex; i < endAddressIndex; i++) {
        addressRandomnessSeed[i-startAddressIndex] = addressBytes[i];
    }
    uint256 randomNumberModule = _maxNumber - _minNumber;
    uint256 randomNumber = _minNumber + uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, addressRandomnessSeed, _salt))) % randomNumberModule;
    return randomNumber;
  }

  function mint(uint256 _mintAmount) public payable {
    require(_mintAmount > 0, "Need to mint at least 1 NFT");
    require(msg.value >= cost * _mintAmount, "Insufficient funds");
    
    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= _mintAmount; i++) {
      ItemData memory newItemData = ItemData(
      string(abi.encodePacked('Onchain Power #', uint256(supply + i).toString())), 
      "Awesome onchain NFT collection that can help you test new blockchain projects.",
      randomNum(10, 350, 4, supply + i).toString(),
      randomNum(10, 350, 8, supply + i).toString(),
      randomNum(10, 350, 12, supply + i).toString());
      itemsData[supply + i] = newItemData;
      _safeMint(msg.sender, supply + i);
    }
  }

  function buildMetadata(uint256 _tokenId) private view returns(string memory) {
      ItemData memory currentItemData = itemsData[_tokenId];
      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          currentItemData.name,
                          '", "description":"', 
                          currentItemData.description,
                          '", "image": "', 
                          'data:image/svg+xml;base64,', 
                          Base64.buildImage(currentItemData.bgHue, currentItemData.eyesHue, currentItemData.pukeHue),
                          '"}')))));
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
      return buildMetadata(_tokenId);
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os, "Failed to send Ether");
  }
}