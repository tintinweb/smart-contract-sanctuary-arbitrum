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

contract MutantNFTDescriptor is BaseNFTUserDescriptor {
    function _getHeroCategory()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return "BEAST";
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
                    '<path class="cls-2" d="M255,141.74a75.16,75.16,0,0,1,11-1.36c3.62.21,4.68.47,5,.61a.12.12,0,0,0,.17-.08l2.5-10.21s4.62-5.08,5.54-6,3.38-6.69,3.38-6.69h0l.78,1.84,1.35.06s2.08-10.05,10.66-13.86l8.57-3.81.87,4.16s-.35.87,1,.35,5.2-4.86,10.39-6.67l5.2-1.82,2.17,3.81s3.81-4.59,6.41-5.46l2.6-.87s-.87,1.56,1.29,2.86,5.55,3,5.55,3l3.95-2.33,2.54,3s1.85-1.39,5.78,1.85l3.93,3.23,3.23-1,4.27,5.43s5.09-1.27,7.86,8.55l2.77,9.81,1.9-1.41s.09-.2.06,3.49c0,4.9,4.85,8,8.66,10.86s4.62,14.32,4.28,15.47,2.08,4.62,2.08,4.62,10.62,4.28,15.7,18.6,7.86,22.64,2.31,33.95-5.66,12.3-5.66,12.3.18,20.88,6.76,26.38,13.86,10.35,13.86,10.35,5.2-1.38,7.28-6.06,7.62-8.5,4.85-20.45L433,226.27s1.74-2.77,2.43-2.77,6.76,7.1,9.53,17.15,5.89,19.75,1.73,29.45-7.71,14.1-9,15.25a9.38,9.38,0,0,1-2.49,1.73l6.13,2.51-8.83,10.66,17.67-1.74s3.11-.34-1.74,3.64-11.78,11.61-18.36,12.13-5.72,1-5.72,1l8.15,9.53a27.82,27.82,0,0,1,8,18.19l.52,11.43-3.81.87s-4-10.57-11.78-16.12l-7.79-5.54-12,2.25a26.06,26.06,0,0,1-6.93,4.68l-4.15,1.91s3.29,19.86,1.55,26.16c-1.5,5.47-1.79,6.12-1.79,6.12s-5.65-13.57-7.56-16.52l-1.91-2.94s-13.34,9.7-24.77,11.26-20.79,4.15-31.53.17-11.95-4.33-11.95-4.33,0,9.18-3.81,13.34-6.24,5.89-8.15,5.89-1.73-5.72-1.73-5.72v-9.53l-2.6,3.81s.18,11.27.52,13,2.6,11.78,3.29,13,4.33.87,6.24,8.32,6.76,11.08,13,11.78l6.24.69s2.25-1.21.35-2.25-4.16-1.91-2.26-5,5.2-6.41,7.45-4.85,3.64,2.6,1.91,4a27.21,27.21,0,0,1-2.6,1.9s-2.77.18-.35,2.26,3.12,2.42,2.78,4-.87,3.29,2.42,5.72l3.29,2.42s-1.73-2.25.52-3.64,3.12-2.59,4.68-1,3.64,4.86,3.12,6.76l-.52,1.91a8.51,8.51,0,0,0,5,0c2.6-.87,1.74,4.33,1.74,4.33s1.38,2.25-2.95,2.42a41.13,41.13,0,0,1-5.72,0l2.6,4.33s.69-1.73,5.89-1.21,8.84,2.25,8.14,5.55-1.55,4.33-3.29,3.46-2.08-3.64-2.08-3.64-2.07-2.94-3.81-1.56-1.38,1.22-1,2.43,1.74,5,1.74,5,4.15,8.49,5,16.11l.87,7.63s6.75-.52,7.1,2.25,2.25,7.79-.87,6.24-3.29-2.95-4.5-2.78-.35,4.16-2.25,5.89a6.82,6.82,0,0,1-3.3,1.91l-.52,5.37a3.38,3.38,0,0,1,2.08,2.94c.35,2.43,1.22,3.82-.34,4.51s-1.22,13.34-1.22,13.34H103.12a34.27,34.27,0,0,1,1.61-8.32l1.39-3.92s-3-2.08-3-3.47.49-40,7.16-48,7.36-9.09,7.36-9.09v-2.25s.09-1.39-2.43.17-8.74,2.42-9-1,.17-5.72,5.8-6.67,5.89-.95,9.18,1.13l3.29,2.07,3.47-2.42-2.08-.69,8.75-8.49.52-2.26s-8.15,5.38-11.09,4.42-10.77-5.69-8.92-10.31,7.62-12.47,10.85-12,5.32.7,4.86,2.78-.29,4.85-3.24,4.73-6.12.92-6.06,3.58,2.31,4.62,5.83,4.22,7.85-2.78,8.43-3.12l.58-.35s-2.66-5.25,2.54-5.89,5.31-1,5.31-1a29.29,29.29,0,0,1,2.54-4.39c.87-.92,3.81-6.18,8.09-3.64s4.21,1.16,5.25,5l1,3.87s.67,1.41,3.87-.41,19.75-10.28,20.44-13.16a18,18,0,0,1,2.66-5.55s3.93-5.37,5-8.31,2.08-6.07,5.71-6.59l3.64-.52s4-16.63,10.22-21.65l6.24-5,.75-1.09s-1.16-8.2.69-10.57,5.66-6.76,5.66-6.76l.7-1s-5.55-12.65-3.3-19.58,4-9.7,2.95-14-.64-4-.64-4l4.45,3.29,1.27-7.62s-7.68-4.85-7.68-7.28-.35-7.1-1.21-8.32-1.91-6.92-1.74-9.18-2.07-4.67-2.07-4.67a13,13,0,0,1-4.85,2.42c-2.26.35-7.45.17-14.73-2.6s-6.41-2.94-14.9-3.46-23-17.5-23-17.5S151,224.19,151,214.66s-.35-10.56-.35-10.56l-1.56,1.38s-2.94-10,2.08-16.46,21.25-20.44,31.88-20.44,17.78-.23,26.79,6,9.7,7.39,9.7,7.39,4.86-10.39,7.63-13.4l2.77-3s0-3.41,4.39-10.16C234.32,155.42,240.12,145.8,255,141.74Z"/>',
                    '<path class="cls-3" d="M352.22,397.41c-1.14-.69-3.83.48-4.52,2.6a3.66,3.66,0,0,0,.55,3.29,3,3,0,0,0,2.88,1.23C353.25,403.86,353.87,398.4,352.22,397.41Z"/><path class="cls-3" d="M389.11,211.72a1.34,1.34,0,0,0,.81.13,24.14,24.14,0,0,0-.41-9.12,32.48,32.48,0,0,1-7.68-12.47c.19-1.25,2.23-1.38,2.54-2.88.18-.84-4-19.3-13.32-18.72-4.14.26-9.49,7.26-12.69,11.76a50.9,50.9,0,0,0-2.47,4.68l4.29,2,4.54,5.22a25.09,25.09,0,0,1,7.43,2.49,8.94,8.94,0,0,1,5,5.76,10.22,10.22,0,0,0,1.64-1.65h0a3.73,3.73,0,0,1,3.25,1.91c1.11,2.4,2.19,4.81,3.22,7.24A41.5,41.5,0,0,1,389.11,211.72Z"/><path class="cls-3" d="M390.45,204.07c.09,1.25.23,2.51.41,3.76a9.81,9.81,0,0,1,1.61,1.61,18.58,18.58,0,0,0,3.76,5.63,1.08,1.08,0,0,0,.53-.27q1-4.53,1.48-9.12a20,20,0,0,1-4.83-.4C392.41,204.86,391.42,204.46,390.45,204.07Z"/>',
                    '<path class="cls-3" d="M394.08,222.05a13.35,13.35,0,0,0,2-4.56c-1-1.64-2-3.25-3.09-4.83a14.49,14.49,0,0,1-1.07-2.42,1.71,1.71,0,0,0-1.21-1.07,8.77,8.77,0,0,1-.8,3.22,6.76,6.76,0,0,1,1.61,2.28c0,.13-.09.27-.14.4a2,2,0,0,0-2-.94,3.72,3.72,0,0,0-1.48,3.9,25.36,25.36,0,0,0,5.24,4.56A1.08,1.08,0,0,0,394.08,222.05Z"/><path class="cls-3" d="M397.84,233.59a29.13,29.13,0,0,1,3.22-4.29c0-.31.09-.63.13-.94a51.78,51.78,0,0,0-3.35-8.72,2.24,2.24,0,0,0-1.48-1.35,11.36,11.36,0,0,1-2.82,4.84,19.4,19.4,0,0,1-.94,4.83,21.31,21.31,0,0,1,3.76,5.9A1,1,0,0,0,397.84,233.59Z"/><path class="cls-3" d="M406.43,250.24c-1.1-2.74-2.08-5.51-3-8.33a53.52,53.52,0,0,1-.94-5.5,14.38,14.38,0,0,0-.13-5.77c0-.79-.43-1.15-1.21-1.07a2.65,2.65,0,0,1-.27,1.61,8.43,8.43,0,0,0-2.95,3.49,1.3,1.3,0,0,1-1.07.27q.89,6.28,1.61,12.61a60.1,60.1,0,0,1,9.66,7.11,1.32,1.32,0,0,0,.81.14,2.59,2.59,0,0,0-.27-1.34A10.85,10.85,0,0,1,406.43,250.24Z"/>',
                    '<path class="cls-3" d="M525.87,287.81c2.36,2.1,9.75,13.24,9.75,14.8s-9.66-6.79-9.75-5.13a.65.65,0,0,1-.94.4,98.64,98.64,0,0,0-16.37-8.05,17.65,17.65,0,0,0-5.1-.81,92.44,92.44,0,0,0-24.16-8.32,17.3,17.3,0,0,0-5.37.27,43.23,43.23,0,0,1-6.44,1.88,74.7,74.7,0,0,0-25,7.78,2.34,2.34,0,0,1-1.08.14,2.26,2.26,0,0,0-.8-2.28,6.07,6.07,0,0,1-1.88-.54c-.32-.24-.32-.46,0-.67q9.42-4.84,19.06-9.26a32.06,32.06,0,0,1,6.17-.94,81,81,0,0,0,22.15.53c2,.16,4,.29,6,.41a1.84,1.84,0,0,1,.93.67,10.84,10.84,0,0,0,2.29-3.36,6.16,6.16,0,0,0-1.88-2.41l-.81-.27q-10.19.35-20.4.27a5,5,0,0,0-3.22-1.61,33,33,0,0,0-15,1.61c-2.84,1.2-5.7,2.31-8.59,3.35q1.26-3.06,2.55-6.17a66.9,66.9,0,0,0,1.88-14.23,34.16,34.16,0,0,1,3.22-4q4.25-9.39-6-7.79a3.31,3.31,0,0,1,0-2.28,54,54,0,0,1,13.15-2.42l3.76-2.68c-1.31-.17-2.61-.39-3.89-.67q-6.3.78-12.48,2.15a1.31,1.31,0,0,1,.27-1.08,25.66,25.66,0,0,0,4.29-3.35,15.49,15.49,0,0,1,1.88-.54l9.66-.27a1.13,1.13,0,0,0,.81-.67,6.61,6.61,0,0,1,1.88.14,17.22,17.22,0,0,0,10.73,5.36,1,1,0,0,1,.81.81,6.3,6.3,0,0,1-1.34,1.34,80.85,80.85,0,0,0-11.81,4.83,16.1,16.1,0,0,0-5.91,6.58,25.2,25.2,0,0,0-4.43,6.44,8.94,8.94,0,0,0-.27,5.64,4.25,4.25,0,0,0,3.09.4,13,13,0,0,1,3.22-1.34Q474.63,258.73,489,256a30.39,30.39,0,0,1,14.5,0,71.72,71.72,0,0,1,17.71,7.24,18.36,18.36,0,0,1,2.55,2.82,3.75,3.75,0,0,1,.27,2.42q-1.62,2-3.35,3.89-4.36,3.18-8.86,6.17a20.94,20.94,0,0,0-2.95,2.69,63.55,63.55,0,0,1,7.78,2.15S524.3,286.56,525.87,287.81Z"/>',
                    '<path class="cls-3" d="M534.17,327.26c0,.47,11.38,8.71,5.56,14.11-.94.87-9.84,8-10.85,7.35-2-1.21,3.5-8.77,3.43-13,0-2.87-4.13-3.29-5.19-3.84-2.7-1.39-5.37-.81-9.64-.77-2.57-.77-5.23-.85-7.85-1.34a44.66,44.66,0,0,0-4.43-3.89,50,50,0,0,0-9.79-11.41,10.43,10.43,0,0,1-3.63-2,31.72,31.72,0,0,0-2.68-6.17l-4-3a14.37,14.37,0,0,1-2.28-6.3,10.15,10.15,0,0,1,.67-3.36l4.56-6.17a20.23,20.23,0,0,0,1.48-2.69,28.24,28.24,0,0,1,8.32,2.69l.27.67-4.43,5a5.47,5.47,0,0,0-1.21,3,1.33,1.33,0,0,1,.81.13,14.35,14.35,0,0,0,6.71,4q4.81,1.29,9.66,2.41,3.52,2.32,7.25,4.3,4.53.8,9,1.74c3,.36,2.34,2.9,6.28,4.76,1.92.91,5.56-2.63,8.39-5.92l-4.65,9.22c-1.57,4.44-6.17-.92-8.33-2S515,312.64,515,312.64a35.89,35.89,0,0,1-7.25-5.36,45.9,45.9,0,0,0-12.34-4,15.06,15.06,0,0,1-3.9-2.82.68.68,0,0,0,0,.81,27.71,27.71,0,0,0,11.95,11.14l2.82,3.89a47.05,47.05,0,0,0,7.11,4.43,26.76,26.76,0,0,1,11.78,1.81A55.85,55.85,0,0,1,534.17,327.26Z"/>',
                    '<path class="cls-3" d="M504.67,332.1a138.6,138.6,0,0,1-10.2-12.88l-1.75-1.74a7.6,7.6,0,0,1-3-.81,28.79,28.79,0,0,1-4.83-5.5,1.31,1.31,0,0,0-1.08-.27,24.16,24.16,0,0,0,3.63,8.86,3.1,3.1,0,0,0,1.21.94,23.67,23.67,0,0,1,4,.53,20.47,20.47,0,0,1,5.91,13q-.81,5.52-1.75,11a19.57,19.57,0,0,1-3.89,7.38,2.78,2.78,0,0,1-2.42.8,27.9,27.9,0,0,1-3.48-4,8.24,8.24,0,0,0-3.23-1.21,2.28,2.28,0,0,0,.14,1.07,11.26,11.26,0,0,1,4,9.93,1.15,1.15,0,0,0,.54.27A6.09,6.09,0,0,1,491,359a3.91,3.91,0,0,1,4.16,4,4.63,4.63,0,0,0,1.61.14,21.59,21.59,0,0,1,9.12-4.3,12.32,12.32,0,0,0,2.69-8.59A71.33,71.33,0,0,0,504.67,332.1Z"/>',
                    '<path class="cls-3" d="M0,339.21l7.42-14.08a34.44,34.44,0,0,1,4.29-4.7c1.85-1.33,3.64-2.71,5.37-4.16a3,3,0,0,0-2.15-.14,54.68,54.68,0,0,0-7,2.57,8.12,8.12,0,0,0-1,.58L.11,323.83,7,315.18a3,3,0,0,1,1-.82,40.06,40.06,0,0,1,15.25-4,19.81,19.81,0,0,1,4.83.67q7.77,2.36,15.3,5.37c1.25.25,2.5.48,3.75.67a2.51,2.51,0,0,1-.8,2.28,29.18,29.18,0,0,0-13.82,15.44,1.87,1.87,0,0,0,.67,2,19,19,0,0,0,10.2,4,26,26,0,0,0,12.88,0,15.36,15.36,0,0,0,7-5.64,73.35,73.35,0,0,0,8.86-4.56l2.15-.27A11.06,11.06,0,0,0,71,329.29l-6.3-.94a27.83,27.83,0,0,1-5,.8,17.84,17.84,0,0,1-.13-4.56,28.09,28.09,0,0,1,2.68-6.71,43.26,43.26,0,0,1,7.92-7.38,3.37,3.37,0,0,1,1.34-.14,53,53,0,0,0-1.88,6.18c.34.7.65,1.42.94,2.14Q83.31,326,96,318.82a12.55,12.55,0,0,0,3.49-2.42A15,15,0,0,0,86.6,321a8.59,8.59,0,0,1-2.15.14,5.25,5.25,0,0,1,1.88-2.55,72.67,72.67,0,0,1,7-4.3,19.17,19.17,0,0,1,4.83.41q4.83-.65,9.67-1.21-5.37.17-10.74,0c-1.08-.13-2.15-.31-3.22-.54q-7.91-3-15.84-6.17a50.3,50.3,0,0,1-8.72-12.48,105.61,105.61,0,0,1-3-11.81,46.46,46.46,0,0,1-.27-9.13A38.65,38.65,0,0,1,74,264.06,55.88,55.88,0,0,1,86.33,256a46,46,0,0,1,17.18,0,17,17,0,0,1,6.19,9.32l-.52,1.13-1.64.82a29.31,29.31,0,0,0-5.37,7.92.85.85,0,0,1-1.07.13c-.23-.48-.45-1-.67-1.47l-.27,5.63a47.64,47.64,0,0,0-1.34,5.64,3.49,3.49,0,0,1-2.42,2.68,1.21,1.21,0,0,1-.81-.53,24.73,24.73,0,0,0-2-4.7q-2.76-1.59-5.64-2.95a17.78,17.78,0,0,0-3.49-.4,1.58,1.58,0,0,1,.54-1.48A19.16,19.16,0,0,0,93.45,272a2.07,2.07,0,0,0-.14-3.09Q81,262,72.24,272.78A23.69,23.69,0,0,0,68.08,281a40.64,40.64,0,0,0,8.59,18.92,23.21,23.21,0,0,0,4,2.55l8.59,3.22a53.13,53.13,0,0,1,6.17.81,13.16,13.16,0,0,0,3.76,0q-5.81-1.11-11.54-2.42l-8.19-8.18a13.37,13.37,0,0,1-2.55-5.64,1.29,1.29,0,0,1,1.07.27q9.8,12.92,26.33,12.33l3.21-.58.38-.12q7.3-5,14.37-10.42a1.53,1.53,0,0,0,.81-1.48,3.6,3.6,0,0,0,3.22-2,11.06,11.06,0,0,1,2.41-.54,9.61,9.61,0,0,1,3.36-1.74,1,1,0,0,1,.54.26,2,2,0,0,1,1.2-.94,68.87,68.87,0,0,1,34.36-5.1,5.57,5.57,0,0,1,2.15.81q11.19,6.6,22.28,13.42a6.48,6.48,0,0,1,1.34.54q7.11,1.08,14.23,2a85.41,85.41,0,0,0,17.44-5.5q4-3.26,8.06-6.31a.86.86,0,0,0,.27-.8,24.18,24.18,0,0,0-11,1.74,8.55,8.55,0,0,0-3,1.88,17.09,17.09,0,0,1-12.48-6c-.49-1-1-2-1.61-3a3.65,3.65,0,0,1,.53-3,25.25,25.25,0,0,1,10.07-6,56.23,56.23,0,0,1,12.08-.8,25,25,0,0,1,2.68-.81,2.11,2.11,0,0,0-.54-3.22q-2-.63-4-1.2a2.17,2.17,0,0,1,1.61-.68,14.86,14.86,0,0,1,11.14,3.36,2.24,2.24,0,0,1,.27,1.88,7.82,7.82,0,0,1-3.9,2.82q-6.12,1.81-12.07,4a5.84,5.84,0,0,1-1.62,1.35.72.72,0,0,0-.4.93,5.38,5.38,0,0,0,1.75.94,17.1,17.1,0,0,0,5.37-.53A104.25,104.25,0,0,0,246,272.65a13.63,13.63,0,0,1,11.28-9.13,29.59,29.59,0,0,0,16.1-4,12.21,12.21,0,0,0,4-5.77c-2.31,0-4.64-.06-7-.14q-6.89-1.89-6.31-9a13.19,13.19,0,0,1,1.61-4,78.3,78.3,0,0,1,7.38-6.17,1.75,1.75,0,0,1,.41.8q1.49-2.23,3.08-4.42c.42-.05.6.17.54.67h1.61a19.44,19.44,0,0,0,2,4.83,15.26,15.26,0,0,0,1.75-4.3,5.38,5.38,0,0,0-.67-2.41l-.27,3a1.8,1.8,0,0,1-1.75-.13,9.85,9.85,0,0,1-1.61-3.36,33.19,33.19,0,0,0,3.09-8.32q.07-8.33.54-16.64.51-4.11,1.21-8.19a7,7,0,0,1-.09-1.37,21.92,21.92,0,0,1-.65-3.81s-.34-5.77,1-8c4.12-6.5,18.7-8.63,25.67-15.48,4.94-4.85,8.42-5.09,12.3-3.81,6.38,2.1,10.78,7.6,13.08,12.39,4,8.27-1.34,12.1-1.34,12.1V195h0a51.67,51.67,0,0,1-11.73,9.46l-10.1,6a44,44,0,0,1-9-.83c0,.35,0,.7-.1.76q-.66,4.1-1.61,8.18c-.72-.06-1.44-.11-2.14-.13l1.74,1.74a13.86,13.86,0,0,1-1.61,8.59,106.74,106.74,0,0,0-8.32,13.69,24.75,24.75,0,0,0-2.15,7.25,51,51,0,0,0-2.92,7.6l.6.23a85.57,85.57,0,0,1,16.68-24.74,2.63,2.63,0,0,1,.4,1.07,1.15,1.15,0,0,1,.54-.27,6.58,6.58,0,0,0,1.61.81q2.37-.74,3.09,1.74a29.16,29.16,0,0,1-3.22,5.91,16,16,0,0,0-8.19,7.92q-2.85,6.66-6.31,13a1,1,0,0,1-1.2-.68q-4.87.85-6.18-4c-.37-2.14-.64-4.28-.8-6.44a12.84,12.84,0,0,0,3.62,12.75,16.28,16.28,0,0,0,2.68,1.07,1,1,0,0,1,.27.54q-3.17,4.38-6,9a14,14,0,0,0-4.83,4.29,31.62,31.62,0,0,0-4,11q-2.26,6.93-9.53,5.77a4.71,4.71,0,0,1-4.3-3.89,2.29,2.29,0,0,0-1.07.13,4,4,0,0,1-1.34,1.08,32,32,0,0,0-3.36,3.62q-2.32,4-4.83,7.78a67.5,67.5,0,0,1-4,8.86,12.35,12.35,0,0,1-13.28,3.89,81.16,81.16,0,0,0-18.79-2.95,50,50,0,0,0-10.87.4c-1.22-.19-2.43-.41-3.63-.67l-15.3-10.47a73.86,73.86,0,0,0-11-3.75,92.67,92.67,0,0,1-11.81-6.18q-4.35-.51-8.59-1.21c-2.95.42-5.91.82-8.86,1.21a35.83,35.83,0,0,0-5.64,2.15,31.32,31.32,0,0,0-11,3.49,54.93,54.93,0,0,1,11.46.95l3.74.29q4.09-.25,8.15-.84a22.43,22.43,0,0,1,7.78,1.48q11.86,6.6,24.16,12.35a67.91,67.91,0,0,0,16.78,5.5l.27-.27a68.19,68.19,0,0,0,16.77,0A3,3,0,0,1,214.1,321a77.07,77.07,0,0,1-12.61,5.37q-6.17,1.05-12.35,1.88a30.88,30.88,0,0,1-7.92,3.09l-2.28-.67a57.64,57.64,0,0,0-27.11-8.19,3.18,3.18,0,0,0-.54.67,30.32,30.32,0,0,1-4,.54,8.19,8.19,0,0,0-3.09,2,1.07,1.07,0,0,0-.54-.27,2.09,2.09,0,0,1-1.47.54,1,1,0,0,1-.94,1.07.91.91,0,0,1-.54-.53,78.87,78.87,0,0,1-12.08,4,1.72,1.72,0,0,1-.81-.26,14.85,14.85,0,0,0-5.5,8.58,8.57,8.57,0,0,0,6.31,7.25,21.56,21.56,0,0,0,7.65-3.22,3.08,3.08,0,0,1,2.15,1.75,19.54,19.54,0,0,0,4.83-.14,2.64,2.64,0,0,1-.27,1.61,38.62,38.62,0,0,0-11.14,8.32,3.27,3.27,0,0,0-.67,1.48c.2,1.25.38,2.5.54,3.76a1.54,1.54,0,0,1-.54,1.34,8.17,8.17,0,0,1-4.56-.54,15.26,15.26,0,0,1-9.26-10.06,19.35,19.35,0,0,1,.53-3.76,1.22,1.22,0,0,0,.67-.94,18.47,18.47,0,0,0-1.74-4.7,2.47,2.47,0,0,1,0-1.61,42.17,42.17,0,0,0,5.77-10.87l1.61-1.34a42.87,42.87,0,0,0,10.6-6.58,8.37,8.37,0,0,0,.94-1.61c.58-.29,1.16-.56,1.75-.8a1.34,1.34,0,0,0,.13-.81c1.14-.07,2.3-.12,3.49-.13a2.57,2.57,0,0,1-.67-.41,5.61,5.61,0,0,0-.4-1.47,4.25,4.25,0,0,1-3-1.08,59.73,59.73,0,0,0-23.89,2.42,62.16,62.16,0,0,1-12.92,8l.43,1.33a60.48,60.48,0,0,0,6.18-1.72c.88.05,1.1.46.67,1.21q-3.86,2.37-7.52,5.1a7.55,7.55,0,0,0-3.75,2.68,21.8,21.8,0,0,0-3.49,2.15L89,340l-2.41,1.07a33.86,33.86,0,0,0-24.57,9,58,58,0,0,0-5,8.19,41.45,41.45,0,0,0-23.36,4l-3.22,3.22c-6.2.79-11.08,4-16.27,7.5-.27.19-.71.51-.8.46a3.08,3.08,0,0,1,.17-.86,15.29,15.29,0,0,1,7.24-9,42.46,42.46,0,0,1,5.9-2.41q11.33-2.4,22.55-5.1a19.27,19.27,0,0,0,5.1-4.3,22.84,22.84,0,0,0,2.42-.8l2.55-3.09,5.5-5a28.55,28.55,0,0,0-8,6.71A95.47,95.47,0,0,1,34,353.44,35.72,35.72,0,0,0,27.82,350c-2.25-.07-4.49-.24-6.71-.53a20.6,20.6,0,0,1-2.42-1.48,2.33,2.33,0,0,1-.13-1.88q1.71-2.21,3.22-4.56a71.69,71.69,0,0,0,5.1-5.37,22.25,22.25,0,0,0,.94-4,27.77,27.77,0,0,0-1.08-3.62,1.15,1.15,0,0,1,.54-.8,17.43,17.43,0,0,0,3.49-1.08,15,15,0,0,0-6.44.81s-6.68-1.33-11.23,1.17S1.38,337.53,0,339.21Z"/>'
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
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 541.39 592.75">'
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
                    '<style>@import url("https://fonts.googleapis.com/css?family=Bowlby One:400");.cls-1{fill:#202020;}.cls-2{fill:url(#gradient41);}.cls-3,.cls-7{fill:#ff0007;}.cls-4,.cls-7{font-size:36px;}.cls-4,.cls-5{fill:#fff;}.cls-4,.cls-5,.cls-8{font-family:BowlbyOne-Regular, Bowlby One;}.cls-5{font-size:15px;}.cls-6{opacity:0.5;}.cls-8{font-size:82px;fill:#3c3c3b;}</style>',
                    '<linearGradient id="gradient41" x1="277.14" y1="513.68" x2="277.14" y2="95.73" gradientUnits="userSpaceOnUse"><stop offset="0" stop-opacity="0"/><stop offset="0.18"/></linearGradient>',
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
                    '<rect class="cls-1" x="79.46" width="392.04" height="574.65" rx="10.16"/>'
                )
            );
    }

    function _getSVGData(
        uint256 userID,
        string memory score,
        string memory apr
    ) internal pure virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text class="cls-4" transform="translate(195.65 480.18)">N',
                    unicode"°",
                    Strings.toString(userID),
                    '</text><text class="cls-5" transform="translate(105.14 30.89)"><tspan class="cls-6">xBCOIN</tspan><tspan class="cls-7"><tspan x="0" y="32">',
                    score,
                    '</tspan></tspan></text><text class="cls-5" transform="translate(410.87 30.89)"><tspan class="cls-6">APR</tspan><tspan class="cls-7"><tspan x="-70.35" y="33">',
                    apr,
                    '%</tspan></tspan></text><text class="cls-8" transform="translate(127 555.43)">BEAST</text>'
                )
            );
    }
}