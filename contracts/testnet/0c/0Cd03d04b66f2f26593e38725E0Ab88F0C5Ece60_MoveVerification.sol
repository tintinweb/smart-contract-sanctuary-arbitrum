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

/* 
   _____ _                   ______ _     _     
  / ____| |                 |  ____(_)   | |    
 | |    | |__   ___  ___ ___| |__   _ ___| |__  
 | |    | '_ \ / _ \/ __/ __|  __| | / __| '_ \ 
 | |____| | | |  __/\__ \__ \ |    | \__ \ | | |
  \_____|_| |_|\___||___/___/_|    |_|___/_| |_|
                             
*/

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ChessFish MoveVerification Contract
 * @author ChessFish
 * @notice https://github.com/Chess-Fish
 * @notice Forked from: https://github.com/marioevz/chess.eth (Updated from Solidity 0.7.6 to 0.8.17 & Added features and functionality)
 *
 * @notice This contract handles the logic for verifying the validity moves on the chessboard. Currently, pawns autoqueen by default.
 */

contract MoveVerification {
    uint8 constant empty_const = 0x0;
    uint8 constant pawn_const = 0x1; // 001
    uint8 constant bishop_const = 0x2; // 010
    uint8 constant knight_const = 0x3; // 011
    uint8 constant rook_const = 0x4; // 100
    uint8 constant queen_const = 0x5; // 101
    uint8 constant king_const = 0x6; // 110
    uint8 constant type_mask_const = 0x7;
    uint8 constant color_const = 0x8;

    uint8 constant piece_bit_size = 4;
    uint8 constant piece_pos_shift_bit = 2;

    uint32 constant en_passant_const = 0x000000ff;
    uint32 constant king_pos_mask = 0x0000ff00;
    uint32 constant king_pos_zero_mask = 0xffff00ff;
    uint16 constant king_pos_bit = 8;

    /**
        @dev For castling masks, mask only the last bit of an uint8, to block any under/overflows.
    */
    uint32 constant rook_king_side_move_mask = 0x00800000;
    uint16 constant rook_king_side_move_bit = 16;
    uint32 constant rook_queen_side_move_mask = 0x80000000;
    uint16 constant rook_queen_side_move_bit = 24;
    uint32 constant king_move_mask = 0x80800000;

    uint16 constant pieces_left_bit = 32;

    uint8 constant king_white_start_pos = 0x04;
    uint8 constant king_black_start_pos = 0x3c;

    uint16 constant pos_move_mask = 0xfff;

    uint16 constant request_draw_const = 0x1000;
    uint16 constant accept_draw_const = 0x2000;
    uint16 constant resign_const = 0x3000;

    uint8 constant inconclusive_outcome = 0x0;
    uint8 constant draw_outcome = 0x1;
    uint8 constant white_win_outcome = 0x2;
    uint8 constant black_win_outcome = 0x3;

    uint256 constant game_state_start = 0xcbaedabc99999999000000000000000000000000000000001111111143265234;

    uint256 constant full_long_word_mask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 constant invalid_move_constant = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /** @dev    Initial white state:
                0f: 15 (non-king) pieces left
                00: Queen-side rook at a1 position
                07: King-side rook at h1 position
                04: King at e1 position
                ff: En-passant at invalid position
    */
    uint32 constant initial_white_state = 0x000704ff;

    /** @dev    Initial black state:
                0f: 15 (non-king) pieces left
                38: Queen-side rook at a8 position
                3f: King-side rook at h8 position
                3c: King at e8 position
                ff: En-passant at invalid position
    */
    uint32 constant initial_black_state = 0x383f3cff;

    // @dev chess game from start using hex moves
    // @dev returns outcome, gameState, player0State, player1State
    function checkGameFromStart(uint16[] memory moves) public pure returns (uint8, uint256, uint32, uint32) {
        return checkGame(game_state_start, initial_white_state, initial_black_state, false, moves);
    }

    /**
        @dev Calculates the outcome of a game depending on the moves from a starting position.
             Reverts when an invalid move is found.
        @param startingGameState Game state from which start the movements
        @param startingPlayerState State of the first playing player
        @param startingOpponentState State of the other playing player
        @param startingTurnBlack Whether the starting player is the black pieces
        @param moves is the input array containing all the moves in the game
        @return outcome can be 0 for inconclusive, 1 for draw, 2 for white winning, 3 for black winning
     */
    function checkGame(
        uint256 startingGameState,
        uint32 startingPlayerState,
        uint32 startingOpponentState,
        bool startingTurnBlack,
        uint16[] memory moves
    ) public pure returns (uint8 outcome, uint256 gameState, uint32 playerState, uint32 opponentState) {
        gameState = startingGameState;

        playerState = startingPlayerState;
        opponentState = startingOpponentState;

        outcome = inconclusive_outcome;

        bool currentTurnBlack = startingTurnBlack;

        require(moves.length > 0, "inv moves");

        if (moves[moves.length - 1] == accept_draw_const) {
            // Check
            require(moves.length >= 2, "inv draw");
            require(moves[moves.length - 2] == request_draw_const, "inv draw");
            outcome = draw_outcome;
        } else if (moves[moves.length - 1] == resign_const) {
            // Assumes that signatures have been checked and moves are in correct order
            outcome = ((moves.length % 2) == 1) != currentTurnBlack ? black_win_outcome : white_win_outcome;
        } else {
            // Check entire game
            for (uint256 i = 0; i < moves.length; ) {
                (gameState, opponentState, playerState) = verifyExecuteMove(
                    gameState,
                    moves[i],
                    playerState,
                    opponentState,
                    currentTurnBlack
                );
                unchecked {
                    i++;
                }

                require(!checkForCheck(gameState, opponentState), "inv check");
                //require (outcome == 0 || i == (moves.length - 1), "Excesive moves");
                currentTurnBlack = !currentTurnBlack;
            }

            uint8 endgameOutcome = checkEndgame(gameState, playerState, opponentState);

            if (endgameOutcome == 2) {
                outcome = currentTurnBlack ? white_win_outcome : black_win_outcome;
            } else if (endgameOutcome == 1) {
                outcome = draw_outcome;
            }
        }
    }

    /**
        @dev Calculates the outcome of a single move given the current game state.
             Reverts for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param move is the move to execute: 16-bit var, high word = from pos, low word = to pos
                move can also be: resign, request draw, accept draw.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteMove(
        uint256 gameState,
        uint16 move,
        uint32 playerState,
        uint32 opponentState,
        bool currentTurnBlack
    ) public pure returns (uint256 newGameState, uint32 newPlayerState, uint32 newOpponentState) {
        // TODO: check resigns and other stuff first
        uint8 fromPos = (uint8)((move >> 6) & 0x3f);
        uint8 toPos = (uint8)(move & 0x3f);

        require(fromPos != toPos, "inv move stale");

        uint8 fromPiece = pieceAtPosition(gameState, fromPos);

        require(((fromPiece & color_const) > 0) == currentTurnBlack, "inv move color");

        uint8 fromType = fromPiece & type_mask_const;

        newPlayerState = playerState;
        newOpponentState = opponentState;

        if (fromType == pawn_const) {
            (newGameState, newPlayerState) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                (uint8)(move >> 12),
                currentTurnBlack,
                playerState,
                opponentState
            );
        } else if (fromType == knight_const) {
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
        } else if (fromType == bishop_const) {
            newGameState = verifyExecuteBishopMove(gameState, fromPos, toPos, currentTurnBlack);
        } else if (fromType == rook_const) {
            newGameState = verifyExecuteRookMove(gameState, fromPos, toPos, currentTurnBlack);
            // Reset playerState if necessary when one of the rooks move

            if (fromPos == (uint8)(playerState >> rook_king_side_move_bit)) {
                newPlayerState = playerState | rook_king_side_move_mask;
            } else if (fromPos == (uint8)(playerState >> rook_queen_side_move_bit)) {
                newPlayerState = playerState | rook_queen_side_move_mask;
            }
        } else if (fromType == queen_const) {
            newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
        } else if (fromType == king_const) {
            (newGameState, newPlayerState) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
        } else {
            revert("inv move type");
        }
        require(newGameState != invalid_move_constant, "inv move");

        // Check for en passant only if the piece moving is a pawn... smh
        if (
            pawn_const == pieceAtPosition(gameState, fromPos) ||
            pawn_const + color_const == pieceAtPosition(gameState, fromPos)
        ) {
            if (toPos == (opponentState & en_passant_const)) {
                if (currentTurnBlack) {
                    newGameState = zeroPosition(newGameState, toPos + 8);
                } else {
                    newGameState = zeroPosition(newGameState, toPos - 8);
                }
            }
        }
        newOpponentState = opponentState | en_passant_const;
    }

    /**
        @dev Calculates the outcome of a single move of a pawn given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecutePawnMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        uint8 moveExtra,
        bool currentTurnBlack,
        uint32 playerState,
        uint32 opponentState
    ) public pure returns (uint256 newGameState, uint32 newPlayerState) {
        newPlayerState = playerState;
        // require ((currentTurnBlack && (toPos < fromPos)) || (!currentTurnBlack && (fromPos < toPos)), "inv move");
        if (currentTurnBlack != (toPos < fromPos)) {
            // newGameState = invalid_move_constant;
            return (invalid_move_constant, 0x0);
        }
        uint8 diff = (uint8)(Math.max(fromPos, toPos) - Math.min(fromPos, toPos));
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (diff == 8 || diff == 16) {
            if (pieceToPosition != 0) {
                //newGameState = invalid_move_constant;
                return (invalid_move_constant, 0x0);
            }
            if (diff == 16) {
                if ((currentTurnBlack && ((fromPos >> 3) != 0x6)) || (!currentTurnBlack && ((fromPos >> 3) != 0x1))) {
                    return (invalid_move_constant, 0x0);
                }
                uint8 posToInBetween = toPos > fromPos ? fromPos + 8 : toPos + 8;
                if (pieceAtPosition(gameState, posToInBetween) != 0) {
                    return (invalid_move_constant, 0x0);
                }
                newPlayerState = (newPlayerState & (~en_passant_const)) | (uint32)(posToInBetween);
            }
        } else if (diff == 7 || diff == 9) {
            if (getVerticalMovement(fromPos, toPos) != 1) {
                return (invalid_move_constant, 0x0);
            }
            if ((uint8)(opponentState & en_passant_const) != toPos) {
                if (
                    (pieceToPosition == 0) || (currentTurnBlack == ((pieceToPosition & color_const) == color_const)) // Must be moving to occupied square // Must be different color
                ) {
                    return (invalid_move_constant, 0x0);
                }
            }
        } else return (invalid_move_constant, 0x0);

        newGameState = commitMove(gameState, fromPos, toPos);
        if ((currentTurnBlack && ((toPos >> 3) == 0x0)) || (!currentTurnBlack && ((toPos >> 3) == 0x7))) {
            // @dev Handling Promotion:
            // Currently Promotion is set to autoqueen
            /*   
            require ((moveExtra == bishop_const) || (moveExtra == knight_const) ||
                     (moveExtra == rook_const) || (moveExtra == queen_const), "inv prom");
            */
            // auto queen promote
            moveExtra = queen_const;

            newGameState = setPosition(
                zeroPosition(newGameState, toPos),
                toPos,
                currentTurnBlack ? moveExtra | color_const : moveExtra
            );
        }

        require(newPlayerState != 0, "pawn");
    }

    /**
        @dev Calculates the outcome of a single move of a knight given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteKnightMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (pieceToPosition > 0) {
            if (((pieceToPosition & color_const) == color_const) == currentTurnBlack) {
                return invalid_move_constant;
            }
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if (!((h == 2 && v == 1) || (h == 1 && v == 2))) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of a bishop given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteBishopMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (pieceToPosition > 0) {
            if (((pieceToPosition & color_const) == color_const) == currentTurnBlack) {
                return invalid_move_constant;
            }
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if ((h != v) || ((gameState & getInBetweenMask(fromPos, toPos)) != 0x00)) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of a rook given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteRookMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);
        if (pieceToPosition > 0) {
            if (((pieceToPosition & color_const) == color_const) == currentTurnBlack) {
                return invalid_move_constant;
            }
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if (((h > 0) == (v > 0)) || (gameState & getInBetweenMask(fromPos, toPos)) != 0x00) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of the queen given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteQueenMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);
        if (pieceToPosition > 0) {
            if (((pieceToPosition & color_const) == color_const) == currentTurnBlack) {
                return invalid_move_constant;
            }
        }
        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);
        if (((h != v) && (h != 0) && (v != 0)) || (gameState & getInBetweenMask(fromPos, toPos)) != 0x00) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of the king given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from. Behavior is undefined for values >= 0x40.
        @param toPos is position moving to. Behavior is undefined for values >= 0x40.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
     */
    function verifyExecuteKingMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack,
        uint32 playerState
    ) public pure returns (uint256 newGameState, uint32 newPlayerState) {
        newPlayerState = ((playerState | king_move_mask) & king_pos_zero_mask) | ((uint32)(toPos) << king_pos_bit);
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (pieceToPosition > 0) {
            if (((pieceToPosition & color_const) == color_const) == currentTurnBlack) {
                return (invalid_move_constant, newPlayerState);
            }
        }
        if (toPos >= 0x40 || fromPos >= 0x40) {
            return (invalid_move_constant, newPlayerState);
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if ((h <= 1) && (v <= 1)) {
            return (commitMove(gameState, fromPos, toPos), newPlayerState);
        } else if ((h == 2) && (v == 0)) {
            if (!pieceUnderAttack(gameState, fromPos)) {
                // TODO: must we check king's 'from' position?
                // Reasoning: castilngRookPosition resolves to an invalid toPos when the rook or the king have already moved.
                uint8 castilngRookPosition = (uint8)(playerState >> rook_queen_side_move_bit);
                if (castilngRookPosition + 2 == toPos) {
                    // Queen-side castling
                    // Spaces between king and rook original positions must be empty
                    if ((getInBetweenMask(castilngRookPosition, fromPos) & gameState) == 0) {
                        // Move King 1 space to the left and check for attacks (there must be none)
                        newGameState = commitMove(gameState, fromPos, fromPos - 1);
                        if (!pieceUnderAttack(newGameState, fromPos - 1)) {
                            return (
                                commitMove(
                                    commitMove(newGameState, fromPos - 1, toPos),
                                    castilngRookPosition,
                                    fromPos - 1
                                ),
                                newPlayerState
                            );
                        }
                    }
                } else {
                    castilngRookPosition = (uint8)(playerState >> rook_king_side_move_bit);
                    if (castilngRookPosition - 1 == toPos) {
                        // King-side castling
                        // Spaces between king and rook original positions must be empty
                        if ((getInBetweenMask(castilngRookPosition, fromPos) & gameState) == 0) {
                            // Move King 1 space to the left and check for attacks (there must be none)
                            newGameState = commitMove(gameState, fromPos, fromPos + 1);
                            if (!pieceUnderAttack(newGameState, fromPos + 1)) {
                                return (
                                    commitMove(
                                        commitMove(newGameState, fromPos + 1, toPos),
                                        castilngRookPosition,
                                        fromPos + 1
                                    ),
                                    newPlayerState
                                );
                            }
                        }
                    }
                }
            }
        }

        return (invalid_move_constant, 0x00);
    }

    /**
        @dev Checks if a move is valid for the queen in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the queen is moving.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkQueenValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by Queen's movement */

        unchecked {
            // Check left
            for (toPos = fromPos - 1; (toPos & 0x7) < (fromPos & 0x7); toPos--) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check right
            for (toPos = fromPos + 1; (toPos & 0x7) > (fromPos & 0x7); toPos++) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check up
            for (toPos = fromPos + 8; toPos < 0x40; toPos += 8) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down
            for (toPos = fromPos - 8; toPos < fromPos; toPos -= 8) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check up-right
            for (toPos = fromPos + 9; (toPos < 0x40) && ((toPos & 0x7) > (fromPos & 0x7)); toPos += 9) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check up-left
            for (toPos = fromPos + 7; (toPos < 0x40) && ((toPos & 0x7) < (fromPos & 0x7)); toPos += 7) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down-right
            for (toPos = fromPos - 7; (toPos < fromPos) && ((toPos & 0x7) > (fromPos & 0x7)); toPos -= 7) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down-left
            for (toPos = fromPos - 9; (toPos < fromPos) && ((toPos & 0x7) < (fromPos & 0x7)); toPos -= 9) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the bishop in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the bishop is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkBishopValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by Bishop's movement */

        unchecked {
            // Check up-right
            for (toPos = fromPos + 9; (toPos < 0x40) && ((toPos & 0x7) > (fromPos & 0x7)); toPos += 9) {
                newGameState = verifyExecuteBishopMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check up-left
            for (toPos = fromPos + 7; (toPos < 0x40) && ((toPos & 0x7) < (fromPos & 0x7)); toPos += 7) {
                newGameState = verifyExecuteBishopMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down-right
            for (toPos = fromPos - 7; (toPos < fromPos) && ((toPos & 0x7) > (fromPos & 0x7)); toPos -= 7) {
                newGameState = verifyExecuteBishopMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down-left
            for (toPos = fromPos - 9; (toPos < fromPos) && ((toPos & 0x7) < (fromPos & 0x7)); toPos -= 9) {
                newGameState = verifyExecuteBishopMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the rook in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the rook is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkRookValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(playerState >> king_pos_bit); /* Kings position cannot be affected by Rook's movement */

        unchecked {
            // Check left
            for (toPos = fromPos - 1; (toPos & 0x7) < (fromPos & 0x7); toPos--) {
                newGameState = verifyExecuteRookMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check right
            for (toPos = fromPos + 1; (toPos & 0x7) > (fromPos & 0x7); toPos++) {
                newGameState = verifyExecuteRookMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check up
            for (toPos = fromPos + 8; toPos < 0x40; toPos += 8) {
                newGameState = verifyExecuteRookMove(gameState, fromPos, toPos, currentTurnBlack);

                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down
            for (toPos = fromPos - 8; toPos < fromPos; toPos -= 8) {
                newGameState = verifyExecuteRookMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the knight in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the knight is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkKnightValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by knight's movement */

        unchecked {
            toPos = fromPos + 6;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos - 6;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos + 10;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos - 10;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos - 17;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos + 17;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos + 15;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos - 15;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the pawn in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the knight is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkPawnValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        uint32 opponentState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 moveExtra = queen_const; /* Since this is supposed to be endgame, movement of promoted piece is irrelevant. */
        uint8 kingPos = (uint8)(playerState >> king_pos_bit); /* Kings position cannot be affected by pawn's movement */

        unchecked {
            toPos = currentTurnBlack ? fromPos - 7 : fromPos + 7;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = currentTurnBlack ? fromPos - 8 : fromPos + 8;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = currentTurnBlack ? fromPos - 9 : fromPos + 9;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = currentTurnBlack ? fromPos - 16 : fromPos + 16;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }
        }

        return false;
    }

    function checkKingValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;

        unchecked {
            toPos = fromPos - 9;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos - 8;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos - 7;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos - 1;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos + 1;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos + 7;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos + 8;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos + 9;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }
        }

        /* TODO: Check castling */

        return false;
    }

    /**
        @dev Performs one iteration of recursive search for pieces. 
        @param gameState Game state from which start the movements
        @param playerState State of the player
        @param opponentState State of the opponent
        @return returns true if any of the pieces in the current offest has legal moves
    */
    function searchPiece(
        uint256 gameState,
        uint32 playerState,
        uint32 opponentState,
        uint8 color,
        uint16 pBitOffset,
        uint16 bitSize
    ) public pure returns (bool) {
        if (bitSize > piece_bit_size) {
            uint16 newBitSize = bitSize / 2;
            uint256 m = ~(full_long_word_mask << newBitSize);
            uint256 h = (gameState >> (pBitOffset + newBitSize)) & m;

            if (h != 0) {
                if (searchPiece(gameState, playerState, opponentState, color, pBitOffset + newBitSize, newBitSize)) {
                    return true;
                }
            }

            uint256 l = (gameState >> pBitOffset) & m;

            if (l != 0) {
                if (searchPiece(gameState, playerState, opponentState, color, pBitOffset, newBitSize)) {
                    return true;
                }
            }
        } else {
            uint8 piece = (uint8)((gameState >> pBitOffset) & 0xF);

            if ((piece > 0) && ((piece & color_const) == color)) {
                uint8 pos = uint8(pBitOffset / piece_bit_size);
                bool currentTurnBlack = color != 0;
                uint8 pieceType = piece & type_mask_const;

                if ((pieceType == king_const) && checkKingValidMoves(gameState, pos, playerState, currentTurnBlack)) {
                    return true;
                } else if (
                    (pieceType == pawn_const) &&
                    checkPawnValidMoves(gameState, pos, playerState, opponentState, currentTurnBlack)
                ) {
                    return true;
                } else if (
                    (pieceType == knight_const) && checkKnightValidMoves(gameState, pos, playerState, currentTurnBlack)
                ) {
                    return true;
                } else if (
                    (pieceType == rook_const) && checkRookValidMoves(gameState, pos, playerState, currentTurnBlack)
                ) {
                    return true;
                } else if (
                    (pieceType == bishop_const) && checkBishopValidMoves(gameState, pos, playerState, currentTurnBlack)
                ) {
                    return true;
                } else if (
                    (pieceType == queen_const) && checkQueenValidMoves(gameState, pos, playerState, currentTurnBlack)
                ) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
        @dev Checks the endgame state and determines whether the last user is checkmate'd or
             stalemate'd, or neither.
        @param gameState Game state from which start the movements
        @param playerState State of the player
        @return outcome can be 0 for inconclusive/only check, 1 stalemate, 2 checkmate
     */
    function checkEndgame(uint256 gameState, uint32 playerState, uint32 opponentState) public pure returns (uint8) {
        uint8 kingPiece = (uint8)(gameState >> ((uint8)(playerState >> king_pos_bit) << piece_pos_shift_bit)) & 0xF;

        require((kingPiece & (~color_const)) == king_const, "934");

        bool legalMoves = searchPiece(gameState, playerState, opponentState, color_const & kingPiece, 0, 256);

        // If the player is in check but also
        if (checkForCheck(gameState, playerState)) {
            return legalMoves ? 0 : 2;
        }
        return legalMoves ? 0 : 1;
    }

    /**
        @dev Gets the mask of the in-between squares.
             Basically it performs bit-shifts depending on the movement.
             Down: >> 8
             Up: << 8
             Right: << 1
             Left: >> 1
             UpRight: << 9
             DownLeft: >> 9
             DownRight: >> 7
             UpLeft: << 7
             Reverts for invalid movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @return mask of the in-between squares, can be bit-wise-and with the game state to check squares
     */
    function getInBetweenMask(uint8 fromPos, uint8 toPos) public pure returns (uint256) {
        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);
        require((h == v) || (h == 0) || (v == 0), "inv move");

        // TODO: Remove this getPositionMask usage
        uint256 startMask = getPositionMask(fromPos);
        uint256 endMask = getPositionMask(toPos);
        int8 x = (int8)(toPos & 0x7) - (int8)(fromPos & 0x7);
        int8 y = (int8)(toPos >> 3) - (int8)(fromPos >> 3);
        uint8 s = 0;

        if (((x > 0) && (y > 0)) || ((x < 0) && (y < 0))) {
            s = 9 * 4;
        } else if ((x == 0) && (y != 0)) {
            s = 8 * 4;
        } else if (((x > 0) && (y < 0)) || ((x < 0) && (y > 0))) {
            s = 7 * 4;
        } else if ((x != 0) && (y == 0)) {
            s = 1 * 4;
        }

        uint256 outMask = 0x00;

        while (endMask != startMask) {
            if (startMask < endMask) {
                startMask <<= s;
            } else {
                startMask >>= s;
            }
            if (endMask != startMask) outMask |= startMask;
        }

        return outMask;
    }

    /**
        @dev Gets the mask (0xF) of a square
        @param pos square position.
        @return mask
    */
    function getPositionMask(uint8 pos) public pure returns (uint256) {
        return (uint256)(0xF) << ((((pos >> 3) & 0x7) * 32) + ((pos & 0x7) * 4));
    }

    /**
        @dev Calculates the horizontal movement between two positions on a chessboard.
        @param fromPos The starting position from which the movement is measured.
        @param toPos The ending position to which the movement is measured.
        @return The horizontal movement between the two positions.
    */
    function getHorizontalMovement(uint8 fromPos, uint8 toPos) public pure returns (uint8) {
        return (uint8)(Math.max(fromPos & 0x7, toPos & 0x7) - Math.min(fromPos & 0x7, toPos & 0x7));
    }

    /**
        @dev Calculates the vertical movement between two positions on a chessboard.
        @param fromPos The starting position from which the movement is measured.
        @param toPos The ending position to which the movement is measured.
        @return The vertical movement between the two positions.
    */
    function getVerticalMovement(uint8 fromPos, uint8 toPos) public pure returns (uint8) {
        return (uint8)(Math.max(fromPos >> 3, toPos >> 3) - Math.min(fromPos >> 3, toPos >> 3));
    }

    /**
        @dev Checks if the king in the given game state is under attack (check condition).
        @param gameState The current game state to analyze.
        @param playerState The player's state containing information about the king position.
        @return A boolean indicating whether the king is under attack (check) or not.
    */
    function checkForCheck(uint256 gameState, uint32 playerState) public pure returns (bool) {
        uint8 kingsPosition = (uint8)(playerState >> king_pos_bit);

        require(king_const == (pieceAtPosition(gameState, kingsPosition) & 0x7), "NOT KING");

        return pieceUnderAttack(gameState, kingsPosition);
    }

    /**
    @dev Checks if a piece at the given position is under attack in the given game state.
    @param gameState The current game state to analyze.
    @param pos The position of the piece to check for attack.
    @return A boolean indicating whether the piece at the given position is under attack.
    */
    function pieceUnderAttack(uint256 gameState, uint8 pos) public pure returns (bool) {
        // When migrating from 0.7.6 to 0.8.17 tests would fail when calling this function
        // this is why this code is left unchecked
        // should find exactly where it phantom overflows / underflows
        // hint: its where things get multiplied...

        unchecked {
            uint8 currPiece = (uint8)(gameState >> (pos * piece_bit_size)) & 0xf;
            uint8 enemyPawn = pawn_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyBishop = bishop_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyKnight = knight_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyRook = rook_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyQueen = queen_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyKing = king_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);

            currPiece = 0x0;

            uint8 currPos;
            bool firstSq;
            // Check up
            firstSq = true;
            currPos = pos + 8;
            while (currPos < 0x40) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (currPiece == enemyRook || currPiece == enemyQueen || (firstSq && (currPiece == enemyKing)))
                        return true;
                    break;
                }
                currPos += 8;
                firstSq = false;
            }

            // Check down
            firstSq = true;
            currPos = pos - 8;
            while (currPos < pos) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (currPiece == enemyRook || currPiece == enemyQueen || (firstSq && (currPiece == enemyKing)))
                        return true;
                    break;
                }
                currPos -= 8;
                firstSq = false;
            }

            // Check right
            firstSq = true;
            currPos = pos + 1;
            while ((pos >> 3) == (currPos >> 3)) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (currPiece == enemyRook || currPiece == enemyQueen || (firstSq && (currPiece == enemyKing)))
                        return true;
                    break;
                }
                currPos += 1;
                firstSq = false;
            }

            // Check left
            firstSq = true;
            currPos = pos - 1;
            while ((pos >> 3) == (currPos >> 3)) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (currPiece == enemyRook || currPiece == enemyQueen || (firstSq && (currPiece == enemyKing)))
                        return true;
                    break;
                }
                currPos -= 1;
                firstSq = false;
            }

            // Check up-right
            firstSq = true;
            currPos = pos + 9;
            while ((currPos < 0x40) && ((currPos & 0x7) > (pos & 0x7))) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) && ((enemyPawn & color_const) == color_const))))
                    ) return true;
                    break;
                }
                currPos += 9;
                firstSq = false;
            }

            // Check up-left
            firstSq = true;
            currPos = pos + 7;
            while ((currPos < 0x40) && ((currPos & 0x7) < (pos & 0x7))) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) && ((enemyPawn & color_const) == color_const))))
                    ) return true;
                    break;
                }
                currPos += 7;
                firstSq = false;
            }

            // Check down-right
            firstSq = true;
            currPos = pos - 7;
            while ((currPos < 0x40) && ((currPos & 0x7) > (pos & 0x7))) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) && ((enemyPawn & color_const) == 0x0))))
                    ) return true;
                    break;
                }
                currPos -= 7;
                firstSq = false;
            }

            // Check down-left
            firstSq = true;
            currPos = pos - 9;
            while ((currPos < 0x40) && ((currPos & 0x7) < (pos & 0x7))) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) && ((enemyPawn & color_const) == 0x0))))
                    ) return true;
                    break;
                }
                currPos -= 9;
                firstSq = false;
            }

            // Check knights
            // 1 right 2 up
            currPos = pos + 17;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;
            // 1 left 2 up
            currPos = pos + 15;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;
            // 2 right 1 up
            currPos = pos + 10;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;
            // 2 left 1 up
            currPos = pos + 6;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;

            // 1 left 2 down
            currPos = pos - 17;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;

            // 2 left 1 down
            currPos = pos - 10;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;

            // 1 right 2 down
            currPos = pos - 15;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;
            // 2 right 1 down
            currPos = pos - 6;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;
        }

        return false;
    }

    /**
        @dev Checks if gameState has insufficient material
        @param gameState current game state
        @return isInsufficient returns true if insufficient material
    */
    function isStalemateViaInsufficientMaterial(uint256 gameState) public pure returns (bool) {
        uint8 whiteKingCount = 0;
        uint8 blackKingCount = 0;
        uint8 otherPiecesCount = 0;

        for (uint pos = 0; pos < 64; ) {
            uint8 piece = pieceAtPosition(gameState, uint8(pos));
            uint8 pieceType = piece & type_mask_const;
            bool isWhite = (piece & color_const) == 0;

            if (pieceType == king_const) {
                if (isWhite) {
                    whiteKingCount++;
                } else {
                    blackKingCount++;
                }
            } else if (pieceType != empty_const) {
                otherPiecesCount++;
                if (otherPiecesCount > 1 || (pieceType != knight_const && pieceType != bishop_const)) {
                    return false;
                }
            }
            unchecked {
                pos++;
            }
        }

        return whiteKingCount == 1 && blackKingCount == 1 && otherPiecesCount <= 1;
    }

    /**
        @dev Commits a move into the game state. Validity of the move is not checked.
        @param gameState current game state
        @param fromPos is the position to move a piece from.
        @param toPos is the position to move a piece to.
        @return newGameState
    */
    function commitMove(uint256 gameState, uint8 fromPos, uint8 toPos) public pure returns (uint) {
        uint8 bitpos = fromPos * piece_bit_size;
        uint8 piece = (uint8)((gameState >> bitpos) & 0xF);
        uint newGameState = gameState & ~(0xF << bitpos);

        newGameState = setPosition(newGameState, toPos, piece);

        return newGameState;
    }

    /**
        @dev Zeroes out a piece position in the current game state.
             Behavior is undefined for position values greater than 0x3f
        @param gameState current game state
        @param pos is the position to zero out: 6-bit var, 3-bit word, high word = row, low word = column.
        @return newGameState
    */
    function zeroPosition(uint256 gameState, uint8 pos) public pure returns (uint256) {
        return gameState & ~(0xF << (pos * piece_bit_size));
    }

    /**
        @dev Sets a piece position in the current game state.
             Behavior is undefined for position values greater than 0x3f
        @param gameState current game state
        @param pos is the position to set the piece: 6-bit var, 3-bit word, high word = row, low word = column.
        @param piece to set, including color
        @return newGameState
    */
    function setPosition(uint256 gameState, uint8 pos, uint8 piece) public pure returns (uint256 newGameState) {
        uint8 bitpos;

        unchecked {
            bitpos = pos * piece_bit_size;

            newGameState = (gameState & ~(0xF << bitpos)) | ((uint256)(piece) << bitpos);
        }

        return newGameState;
    }

    /**
        @dev Gets the piece at a given position in the current gameState.
             Behavior is undefined for position values greater than 0x3f
        @param gameState current game state
        @param pos is the position to get the piece: 6-bit var, 3-bit word, high word = row, low word = column.
        @return piece value including color
    */
    function pieceAtPosition(uint256 gameState, uint8 pos) public pure returns (uint8) {
        uint8 piece;

        unchecked {
            piece = (uint8)((gameState >> (pos * piece_bit_size)) & 0xF);
        }

        return piece;
    }
}