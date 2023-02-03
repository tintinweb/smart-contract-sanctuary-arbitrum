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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "base64-sol/base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IUserNFTDescriptor.sol";
import "./interfaces/IUserManager.sol";
import "./interfaces/Gameable.sol";

abstract contract BaseNFTUserDescriptor is IUserNFTDescriptor {
    function tokenURI(
        address hub,
        uint256 userId
    ) external view override returns (string memory) {
        IUserManager.UserDescription memory _userDescription = IUserManager(hub)
            .getUserDescription(userId);
        return _constructTokenURI(_userDescription);
    }

    function _constructTokenURI(
        IUserManager.UserDescription memory _userDescription
    ) private pure returns (string memory) {
        string memory _name = _generateName(_userDescription);
        string memory _description = _generateDescription();
        string memory _image = Base64.encode(
            bytes(_generateSVG(_userDescription))
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _name,
                                '", "description":"',
                                _description,
                                '", "image": "data:image/svg+xml;base64,',
                                _image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _generateDescription() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This collection contains all the heroes who participated in the Bored In Borderland Season 1.\\n\\n",
                    "Whether they are dead or alive, they are the pioneers of the game and all players who participated in Season 1 will receive benefits for future seasons.\\n\\n",
                    "Each NFT contains the name of the hero, the score represented by the amount of xBCOIN accumulated by the NFT and the current APR of the Hero."
                )
            );
    }

    function _getHeroCategory() internal pure virtual returns (string memory);

    function _generateName(
        IUserManager.UserDescription memory _userDescription
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Heroes of Borderland Season 1 - ",
                    _getHeroCategory(),
                    " - #",
                    Strings.toString(_userDescription.userId)
                )
            );
    }

    function _generateSVG(
        IUserManager.UserDescription memory _userDescription
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _generateSVGMeta(),
                    _generateStyleDefs(),
                    _generateSVGCalques(),
                    _generateSVGForm(),
                    _generateSVGDesign(),
                    _generateSVGData(_userDescription),
                    "</g></g></svg>"
                )
            );
    }

    function _generateSVGDesign() internal pure virtual returns (string memory);

    function _generateSVGMeta() internal pure virtual returns (string memory);

    function _generateStyleDefs() internal pure virtual returns (string memory);

    function _generateSVGCalques() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g id="Calque_1" data-name="Calque 1"><g id="Calque_2" data-name="Calque 2">'
                )
            );
    }

    function _generateSVGForm() internal pure virtual returns (string memory);

    function _generateSVGData(
        IUserManager.UserDescription memory _userDescription
    ) private pure returns (string memory) {
        uint256 _scoreRounded = (_userDescription.balance -
            (_userDescription.balance % 10 ** 18)) / 10 ** 18;
        uint256 _aprRounded = (_userDescription.apr -
            (_userDescription.apr % 10 ** 18) /
            10 ** 18) / 10000;
        string memory _apr = Strings.toString(_aprRounded);
        string memory _score = Strings.toString(_scoreRounded);
        return _getSVGData(_userDescription.userId, _score, _apr);
    }

    function _getSVGData(
        uint256 userID,
        string memory score,
        string memory apr
    ) internal pure virtual returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface Gameable {
    enum TierType {
        BORED,
        MUTANT,
        SOUL
    }

    struct NumberChosen {
        uint256 tokenID;
        uint256 number;
        uint256 balanceBeforeGame;
        uint256 createdAt;
    }

    struct UserGame {
        uint256 gameID;
        uint256 balanceBeforeGame;
        TierType category;
        bool isWinner;
    }

    struct Player {
        uint256 tokenID;
        string name;
        uint256 categoryPlayer;
        uint256 initialBalance;
        uint256 currentBalance;
        uint256 createdAt;
        uint256 number;
    }

    struct Game {
        uint256 id;
        uint256 winner;
        uint256 playersInGame;
        uint256 startedAt;
        uint256 endedAt;
        uint256 updatedAt;
        uint256 pool;
        TierType category;
    }

    struct Tier {
        TierType category;
        uint256 duration;
        uint256 amount;
        uint8 maxPlayer;
        uint256 createdAt;
        uint256 updatedAt;
        bool isActive;
    }

    function getGame(uint256 idGame) external returns (Game memory);

    function play(
        TierType category,
        uint256 tokenID,
        uint8 numberChosen
    ) external returns (uint256);

    function getGamesOf(uint256 tokenID) external returns (Game[] memory);

    function getGamesEndedBetweenIntervalOf(
        uint256 tokenID,
        uint256 startInterval,
        uint256 endInterval
    ) external view returns (UserGame[] memory);

    function getTier(TierType category) external view returns (Tier memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserManager {
    enum AprType {
        BORED,
        MUTANT,
        SOUL
    }
    
    event Created(
        address indexed userAdrr,
        uint256 indexed tokenId,
        AprType category,
        uint256 amount,
        uint256 createdAt
    );

    struct UserGame {
        uint256 id;
        uint256 rewardT0;
        uint256 rewardT1;
        uint256 totalReward;
        uint256 tokenBalance;
        uint256[3] gameIds;
        uint256 date;
        uint256 lastClaimTime;
    }

    struct User {
        uint256 balance;
        uint256 initialBalance;
        AprType category;
        string name;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct UserDescription {
        uint256 userId;
        uint256 balance;
        uint256 apr;
        uint256 initialBalance;
        string name;
        AprType category;
    }
    
    function getUserDescription(
        uint256 tokenId
    ) external view returns (UserDescription memory userDescription);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserNFTDescriptor {
  function tokenURI(address hub, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseNFTUserDescriptor.sol";

contract SoulNFTDescriptor is BaseNFTUserDescriptor {
    function _getHeroCategory()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return "SOUL";
    }

    function _generateSVGDesign()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<path class="cls-2" d="M260.25,513.68c.06-1.51-.82-10.08-.82-10.37l-4.1-9.05c-2.34-.68-19.55-10.75-21.34-11.68-6.91-3.58-14.46-7.8-16.89-9.47-4.35-2.81-4.6-3.07-5.37-6.52-2.43-11.13-4.48-42.35-3.45-53.48s2.68-24.57,3.19-25.33c.26-.26,7.55-4.23,16.38-8.58,28.28-14.2,38.64-20.85,50.41-32.11l8.19-7.93,1.79,1.41c2.05,1.53,3.58,1.66,7.29.64,6-1.8,9.73-7.3,16.64-25.59,4.22-11.13,5.37-15.61,5.37-20.22-.13-6.27-3.84-12.28-9.08-14.46l-2.95-1.15-.25-11.13a111.16,111.16,0,0,1-.13-11.26c.13-.12,3.2,4.35,6.91,9.85A238.16,238.16,0,0,1,325.6,290.8c3.84,7.42,6.91,13.56,7,13.56a58.34,58.34,0,0,0-1.28-6.27c-.9-3.33-2.31-10-3.33-14.59-2.94-13.94-6-19.57-17.14-32a63.24,63.24,0,0,1-7.3-9.73c-2.17-4.22-5.11-11.89-4.6-12.41.64-.76,10.1,2.31,27.51,9,20.85,8.06,28,10.49,28.65,10,.26-.13-2.43-2.3-5.88-4.48-7.81-5.12-28.15-15.22-40.3-20.09-11.13-4.47-14-6-17.4-9.85-4.1-4.48-3.59-6,3.45-8.31,12.28-4.1,25.85-5,55.66-3.71,26.61,1.15,27.76,1.15,26.1.25s-19.83-4.22-33.27-6c-12-1.66-28.66-2.05-53.48-1.28-12.79.38-14.84,0-14.84-2.94a4.46,4.46,0,0,1,1.54-3c2.3-2.17,30.19-16,42.86-21.23,11.87-5,29.13-12.61,33.09-14.74-.26-.36-.52-.74-.79-1.1a35.09,35.09,0,0,0-7.1,1.25c-16.25,4.35-37.87,11.13-49.64,15.61-9.85,3.71-11.77,4-12.8,1.66-.89-2,.9-5.24,6.4-11.77,6.65-7.68,12.67-12.28,38.38-28.66l3.88-2.48c-.57-.51-1.14-1-1.71-1.53-1.42.5-3.1,1.11-5.11,1.84-28.91,10.74-42.22,20.34-55,39.79-7.55,11.51-9.85,14.33-12.41,15.35-1.92.64-2.31.64-2.82-.13-1-1.4-.25-6.91,2.3-16.89a103.55,103.55,0,0,1,27.51-48.49c5.25-5.37,14.33-12.71,17.93-14.7l-1.48-1.44c-5.1,2-16.29,8.29-21.95,12.56-9.08,6.65-15.86,14-22.77,24.44a190,190,0,0,0-15.87,29c-5.76,12.8-5.63,13.31-5.24-14.2.25-19.45.64-25.46,1.66-32.63,1.41-9,5-21.87,9.21-33.13q5-13.82-1.53-3.84C236.81,94,233,102.85,228.36,118.71a181.36,181.36,0,0,0-6.78,34.16c-1,11-1.66,13-3.84,13s-4.22-5.75-10.1-28.4-11-39.53-15.1-48.11c-2.56-5.5-8.32-15.73-9-15.73s.39,3.2,3.59,14.71c4.09,14.2,5.37,20.73,7.67,38.77,1,8.57,2.56,19.44,3.33,24.31,1.53,9.46,1.41,15-.39,17.78-1.4,2.05-1.79,1.79-8.31-7.55a365.47,365.47,0,0,1-20.22-32.11c-12.41-21.88-16.63-28.79-21.49-35.06-2.69-3.58-5.5-7-6.27-7.8-1.41-1.28-1.41-1.28-.9.38.26.9,3.33,7.93,7,15.48s9.21,20.09,12.41,27.89,7.29,17.79,9.21,22.27,5.5,12.15,8.06,17c5,9.47,5.25,11,2.31,12.41-1.16.51-2.05.39-3.59-.38-4.47-2.3-17.52-18-42.47-50.92C125.37,120,115,107.33,110.27,102.21l-3.84-4.1,1.67,3.08c10.87,20.34,22.77,40.55,33.52,56.93,13.18,20.21,14.84,23.41,15,27.89.12,2.82-.26,3.71-1.54,5.12-2.81,3.07-8.83,2.05-19.57-3.33-6-2.94-38.26-25-53.61-36.33l-11.77-8.7c-2.82-2.18,13.56,14.71,36.33,37.1,14.2,13.95,26.23,26.36,26.87,27.38,1.41,2.56.64,5-1.66,5.89-2.56,1-7.29.25-21.24-3.2-21.62-5.38-34-9.34-68.07-22.14A66,66,0,0,0,34.15,185c-.52.64,12.28,7.55,35.82,19.19,28.27,14.07,37.74,18.42,46.06,20.6,6.27,1.53,7.68,3.07,6.27,6.14-.9,2.17-3.46,2.81-14.59,4.22-4.86.51-15.86,2.05-24.31,3.33s-21.49,3.2-28.91,4.09c-16.12,2.05-22.78,3.2-31.35,5.5-7.42,2.05-9.47,3.33-4.35,2.69,1.92-.26,6.14-.64,9.47-.77s11.77-.89,18.81-1.66c18.17-1.92,20.72-2,42-3.07,23.29-1.15,24.31-1,23.42,3.58-.77,4.35-2.31,5.25-18.68,11.26S67.54,270.2,55.9,275.83c-9.86,4.73-17,8.83-15.61,8.83s19.06-5.51,39.15-12.16c12.28-4.09,23.28-7.42,24.56-7.68l4.74-.76,2.3-.39-.64,6-.64,5.88-4.86.38c-10.24.77-16.38,6.91-16.38,16.51,0,7.93,9.34,27.89,15.87,33.9,6.14,5.63,13.3,6.15,18.93,1.16l2.3-2,3.33,4.6c4.74,6.27,19.19,20.48,26.36,25.85,7.42,5.63,16,10.87,28.66,17.91l9.85,5.5,3.32,26.61c1.67,12.16,1.8,22.65.39,40.18-1.54,20.6-2.05,22.9-4.22,24.69-1,.9-9.09,5.25-17.79,9.72s-16.5,8.83-17.27,9.6l-.25.29-12.3,10.13-3.89,5.88c-1.74,1.88-1.85,4.14-4.14,7.24Z"/>',
                    '<path class="cls-3" d="M241.29,99.07c1.21-3.95,2.54-7.92,4-11.7q5-13.82-1.53-3.84A101.55,101.55,0,0,0,236,97.32,20.11,20.11,0,0,1,241.29,99.07Z"/><path class="cls-3" d="M191.64,87.55c-2.81-5.67-7.48-13.87-8.06-13.87S184,76.8,187,87.91A29.09,29.09,0,0,1,191.64,87.55Z"/>',
                    '<path class="cls-3" d="M329.3,126c-1.42.5-3.1,1.11-5.11,1.84a195.74,195.74,0,0,0-20.36,8.71,21.1,21.1,0,0,1,1.12,8.05c5.23-3.67,12.22-8.25,22.18-14.59l3.88-2.48C330.44,127,329.87,126.46,329.3,126Z"/><path class="cls-3" d="M351.89,151.88a35.09,35.09,0,0,0-7.1,1.25c-11.85,3.17-26.54,7.63-38.2,11.56a17.69,17.69,0,0,1,7,5.61c2.2-1,4.22-1.87,6-2.58,11.87-5,29.13-12.61,33.09-14.74C352.42,152.62,352.16,152.24,351.89,151.88Z"/>',
                    '<path class="cls-3" d="M117.63,118.5a28.62,28.62,0,0,1,5.4-1.13c-5.15-6.41-10-12.12-12.76-15.16l-3.84-4.1,1.67,3.08C111.21,107,114.4,112.79,117.63,118.5Z"/><path class="cls-3" d="M283.69,117.51l.07-.08c5.25-5.37,14.33-12.71,17.93-14.7l-1.48-1.44c-5.1,2-16.29,8.29-21.95,12.56l-.45.35A34.35,34.35,0,0,1,283.69,117.51Z"/>',
                    '<path class="cls-3" d="M147.63,102.59c1.07,2.27,2.33,5,3.65,7.88q2.64-1.45,5.32-2.74a130.67,130.67,0,0,0-8.84-13.2c-2.69-3.58-5.5-7-6.27-7.8-1.41-1.28-1.41-1.28-.9.38C140.85,88,143.92,95,147.63,102.59Z"/><path class="cls-3" d="M52,277.74c-7.75,3.87-12.92,6.91-11.7,6.91.66,0,5.81-1.49,13.42-3.86C53.09,279.81,52.52,278.79,52,277.74Z"/>',
                    '<path class="cls-3" d="M349.27,243.84c-2.51-1.64-6.32-3.8-10.73-6.14a11.67,11.67,0,0,1-.54,5c12.07,4.55,16.65,6,17.15,5.58C355.41,248.19,352.72,246,349.27,243.84Z"/><path class="cls-3" d="M376.78,202.13c-1.79-.89-19.83-4.22-33.27-6-4.08-.57-8.7-1-14-1.25a20.65,20.65,0,0,1,3.11,6.48c5.28.06,11.23.23,18,.53C377.29,203,378.44,203,376.78,202.13Z"/>',
                    '<path class="cls-3" d="M82.94,152.26l-1.07-.79-11.77-8.7c-1.47-1.14,2.31,2.94,9.51,10.29A5.53,5.53,0,0,1,82.94,152.26Z"/><path class="cls-3" d="M64,195.79c-6.21-2.23-13.26-4.84-21.63-8A66,66,0,0,0,34.15,185c-.44.54,8.57,5.52,25.49,14A18.85,18.85,0,0,1,64,195.79Z"/><path class="cls-3" d="M49.72,245.52a17,17,0,0,1,1.7-2.56c-13.93,1.81-20.27,2.95-28.28,5.1-7.42,2.05-9.47,3.33-4.35,2.69,1.92-.26,6.14-.64,9.47-.77s11.77-.89,18.81-1.66l1.79-.19A7.71,7.71,0,0,1,49.72,245.52Z"/>',
                    '<path class="cls-4" d="M111.85,295.22c-1.15-5.12-1.92-7.42-3.07-8.31-1.54-1.41-4.48-1.67-7.55-.64-3.46,1-3.58,1.53-3.07,6.52.89,8.45,4.86,18.42,10.1,26,3.2,4.61,5.76,5.89,8.32,4.35a14.05,14.05,0,0,0,2.82-2.68c.89-1.54.89-1.79-.13-3.71C116.84,312,113.38,301.88,111.85,295.22Z"/>',
                    '<path class="cls-4" d="M307.09,291.38c-1.92-2.17-3.58-2.56-4.74-1.15-2.17,2.56-1.66,3.2,1.16,4.86a8.48,8.48,0,0,1,2.68,3c.9,2,1.66,2.81,2.43,1.79C310.16,297.91,309.39,293.69,307.09,291.38Z"/><path class="cls-4" d="M303.63,303.79c-3.84-1-4.09-1-4.86,3.07-1.15,5.63-4.48,14.85-6.78,18.81-2.81,5-2.43,8.32.64,8.32,1.54,0,5-3.84,6.91-7.81,2.56-5.11,6.52-17,6.52-19.44C306.06,304.69,305.81,304.43,303.63,303.79Z"/>',
                    '<path class="cls-4" d="M280.3,261c-7.16-14.59-21.87-25.59-43.63-32.37-.76-.13-1.53.38-2.3,1.54-1,1.66-1,1.79.26,3.45.89,1.28,2.81,2.18,6,3.2,9,2.81,10.75,5.63,7.29,11-5.24,8.32-7.16,15.1-7.16,25.08,0,17.53,9.34,31.47,21.88,32.75,12,1.15,21.36-9.08,22.52-24.43C285.68,274.43,284.4,269.19,280.3,261Zm-13.93,25c-3.39.71-6.85-2.13-7.74-6.35s1.13-8.21,4.52-8.93,6.86,2.13,7.74,6.34S269.76,285.3,266.37,286Z"/><path d="M263.49,270.31c-3.56.75-5.68,4.95-4.75,9.37s4.57,7.41,8.13,6.66,5.68-4.95,4.75-9.37S267.05,269.56,263.49,270.31Z"/>',
                    '<path class="cls-4" d="M202.87,228.12c-9.35,1.95-21.15,7.27-28.16,12.46A44.5,44.5,0,0,0,158,267.05c-3.63,17.64,7.27,34.9,22.84,36.33,7.78.65,16.87-3.12,21.54-9.09,2.85-3.5,5.84-10.38,6.74-15.05a74,74,0,0,0,.52-11.67c-.39-8.31-1.42-12.2-6.23-22.45-2.07-4.54-2.59-6.36-2.07-7.14,1.3-2.07,4.56-3.16,8.32-3.93,4.28-.78,5-2,5-4.24C214.54,227,210.91,226.3,202.87,228.12ZM188,269.07c-.93,4.57-4.65,7.66-8.3,6.91s-5.85-5.05-4.92-9.61,4.65-7.66,8.3-6.91S188.93,264.51,188,269.07Z"/>',
                    '<ellipse cx="181.08" cy="268.89" rx="10.36" ry="8.29" transform="translate(-118.69 392.32) rotate(-78.42)"/>'
                )
            );
    }

    function _generateSVGMeta()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 415.06 592.28">'
                )
            );
    }

    function _generateStyleDefs()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<defs>",
                    '<style>@import url("https://fonts.googleapis.com/css?family=Bowlby One:400");.cls-1{fill:#202020;}.cls-2{fill:url(#gradient41);}.cls-3,.cls-4,.cls-8{fill:#ff0007;}.cls-4{stroke:#000;stroke-miterlimit:10;stroke-width:0.75px;}.cls-5,.cls-8{font-size:36px;}.cls-5,.cls-6{fill:#fff;}.cls-5,.cls-6,.cls-9{font-family:BowlbyOne-Regular, Bowlby One;}.cls-6{font-size:15px;}.cls-7{opacity:0.5;}.cls-9{font-size:82px;fill:#3c3c3b;}</style>',
                    '<linearGradient id="gradient41" x1="196.62" y1="513.68" x2="196.62" y2="73.68" gradientUnits="userSpaceOnUse"><stop offset="0" stop-opacity="0"/><stop offset="0.18"/></linearGradient>',
                    "</defs>"
                )
            );
    }

    function _generateSVGForm()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<rect class="cls-1" width="392.04" height="576.67" rx="9.96"/>'
                )
            );
    }

    function _getSVGData(uint256 userID, string memory score, string memory apr) internal pure virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text class="cls-5" transform="translate(146.47 482.2)">N',
                    unicode"°",
                    Strings.toString(userID),
                    '</text><text class="cls-6" transform="translate(25.94 30.73)"><tspan class="cls-7">xBCOIN</tspan><tspan class="cls-8"><tspan x="0" y="32">',
                    score,
                    '</tspan></tspan></text><text class="cls-6" transform="translate(331.39 30.65)"><tspan class="cls-7">APR</tspan><tspan class="cls-8"><tspan x="-68.03" y="33">',
                    apr,
                    '%</tspan></tspan></text><text class="cls-9" transform="translate(75.72 554.96)">SOUL</text>'
                )
            );
    }
}