// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './RandomNumberGenerator.sol';

contract House is RandomNumberGenerator {
  address private owner;

  mapping(address => bool) adminWhitelist;

  struct UnresolvedWager {
    uint8 gameId;
    uint gameOptions;
    uint wageredAmount;
    address playerAddress;
    bool isWinner;
    uint odds;
    bool resolved;
  }
  mapping(bytes32 => UnresolvedWager) unresolvedWagers;
  uint totalOutstandingWagers;

  modifier onlyAdminWhitelist() override {
    require(adminWhitelist[msg.sender], 'OnlyAdminWhitelist');
    _;
  }

  // events
  event GameResult(
    bytes32 commitmentId,
    bool isWinner,
    uint playerNumber,
    uint randomNumber,
    string rawSecret,
    uint bet,
    uint odds,
    address playerAddress,
    string reason
  );

  constructor() {
    owner = msg.sender;
    adminWhitelist[owner] = true;
  }

  receive() external payable {}

  function addAdminWhitelist(address user) public onlyOwner {
    if (adminWhitelist[user]) revert('AddressAlreadyWhitelisted');
    adminWhitelist[user] = true;
  }

  function removeAdminWhitelist(address user) public onlyOwner {
    if (!adminWhitelist[user]) revert('AddressNotInWhitelist');
    delete adminWhitelist[user];
  }

  function liquidate(uint _amount) external onlyAdminWhitelist {
    require(address(this).balance > _amount, 'AmountHigherThanBalance');

    payable(msg.sender).transfer(_amount);
  }

  function allowLateReveals() internal pure override returns (bool) {
    return false;
  }

  function commitWager(
    uint8 _gameId,
    uint _gameOptions,
    bytes32 _rngCommitment
  ) external payable {
    require(msg.value > 0, 'NoBetError');
    require(_gameId == 1 || _gameId == 2, 'InvalidGameIdError');

    bool gameOneCondition = (_gameId == 1 &&
      _gameOptions <= 10 &&
      _gameOptions >= 1);
    bool gameTwoCondition = (_gameId == 2 &&
      (_gameOptions == 1 || _gameOptions == 0));
    require(gameOneCondition || gameTwoCondition, 'InvalidGameOptions');

    totalOutstandingWagers += _gameId == 1 ? msg.value * 10 : msg.value * 2;
    require(address(this).balance > totalOutstandingWagers, 'BetTooBigError');

    unresolvedWagers[_rngCommitment] = UnresolvedWager(
      _gameId,
      _gameOptions,
      msg.value,
      msg.sender,
      false,
      0,
      false
    );

    revealRandomNumber(_rngCommitment);
  }

  function gameLogicOne(
    uint randomNumber,
    uint playerChoice
  ) private pure returns (bool, uint, uint) {
    // 'one-through-ten' game, number range: 1 - 10
    uint odds = 10;
    return (randomNumber == playerChoice, randomNumber, odds);
  }

  function gameLogicTwo(
    uint randomNumber,
    uint playerChoice
  ) private pure returns (bool, uint, uint) {
    // 'coin-flip' game, number range: 0 - 1
    uint odds = 2;
    // default window size of random number: 1 to 10
    uint scaledRandomNumber;
    if (randomNumber >= 1 && randomNumber <= 5) scaledRandomNumber = 0;
    else if (randomNumber >= 6 && randomNumber <= 10) scaledRandomNumber = 1;

    return (scaledRandomNumber == playerChoice, scaledRandomNumber, odds);
  }

  function resolveWager(
    bytes32 _commitmentId
  ) public payable onlyWhitelistedUser {
    require(unresolvedWagers[_commitmentId].resolved, 'WagerNotResolved');

    uint amount = unresolvedWagers[_commitmentId].wageredAmount *
      unresolvedWagers[_commitmentId].odds;
    totalOutstandingWagers -= amount;

    if (!unresolvedWagers[_commitmentId].isWinner) return;
    payable(unresolvedWagers[_commitmentId].playerAddress).transfer(amount);
  }

  function __callback(
    bytes32 _commitmentId,
    bool timedOut,
    uint randomNumber,
    string memory rawSecret
  ) internal override {
    require(!unresolvedWagers[_commitmentId].resolved, 'WagerNotFound');

    unresolvedWagers[_commitmentId].resolved = true;
    uint scaledRandomNumber;
    (
      unresolvedWagers[_commitmentId].isWinner,
      scaledRandomNumber,
      unresolvedWagers[_commitmentId].odds
    ) = unresolvedWagers[_commitmentId].gameId == 1
      ? gameLogicOne(randomNumber, unresolvedWagers[_commitmentId].gameOptions)
      : gameLogicTwo(randomNumber, unresolvedWagers[_commitmentId].gameOptions);

    if (timedOut) unresolvedWagers[_commitmentId].isWinner = true;

    resolveWager(_commitmentId);

    emit GameResult(
      _commitmentId,
      unresolvedWagers[_commitmentId].isWinner,
      unresolvedWagers[_commitmentId].gameOptions,
      scaledRandomNumber,
      rawSecret,
      unresolvedWagers[_commitmentId].wageredAmount,
      unresolvedWagers[_commitmentId].odds,
      unresolvedWagers[_commitmentId].playerAddress,
      timedOut ? 'timeout' : unresolvedWagers[_commitmentId].isWinner
        ? 'player won'
        : 'player lost'
    );

    delete unresolvedWagers[_commitmentId];
  }

  function processTimedOutDecommit(bytes32 _commitmentId) internal override {
    __callback(_commitmentId, true, 0, '');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/utils/Strings.sol';

contract RandomNumberGenerator {
  address private owner;

  uint public timeoutBlocks = 0;

  struct Commitment {
    bool exists;
    bool availableState;
    uint index;
  }
  mapping(bytes32 => Commitment) public commitmentStore;
  bytes32[] public commitmentIdList;

  // admin whitelist
  mapping(address => bool) private rngWhitelist;
  uint private whitelistCount;

  // reveal number cache
  struct RevealNumberRequest {
    uint blockNumber;
    bool exists;
  }
  mapping(bytes32 => RevealNumberRequest) private revealRequestCache;
  bytes32[] revealRequestCommitIds;

  // modifiers
  modifier onlyOwner() {
    require(msg.sender == owner, 'OnlyOwner');
    _;
  }

  modifier onlyWhitelistedUser() {
    require(rngWhitelist[msg.sender], 'OnlywhitelistedUsers');
    _;
  }

  modifier onlyAdminWhitelist() virtual {
    require(true, 'OnlyAdminWhitelist');
    _;
  }

  // events
  event NewHashesAvailable(
    bytes32 commitmentId,
    uint256 newlyReceived,
    uint256 total
  );
  event DecommitRequest(bytes32 commitmentId);
  event TimedOutRevealEvent(bytes32 commitmentId);

  constructor() {
    owner = msg.sender;
  }

  function setTimeoutBlocks(uint _timeoutBlocks) public onlyAdminWhitelist {
    timeoutBlocks = _timeoutBlocks;
  }

  // enable/disable late reveals
  // overridden by child contract to modify the setting
  function allowLateReveals() internal pure virtual returns (bool) {
    return true;
  }

  // check if a decommit request is timed out
  // uses block difference as timeout counter
  function isDecommitRequestTimedOut(
    bytes32 commitmentId
  ) private view returns (bool) {
    if (allowLateReveals() || timeoutBlocks == 0) return false;
    return (block.number - revealRequestCache[commitmentId].blockNumber >
      timeoutBlocks);
  }

  // view function to returns true if any of the decommit request is timed out
  function checkDecommitTimeouts() public view returns (bool) {
    if (allowLateReveals() || timeoutBlocks == 0) return false;

    for (uint i = 0; i < revealRequestCommitIds.length; i++) {
      if (isDecommitRequestTimedOut(revealRequestCommitIds[i])) return true;
    }

    return false;
  }

  // check all decommit requests and clears it if timed out
  function processDecommitTimeouts() external {
    uint i = 0;
    while (i < revealRequestCommitIds.length) {
      if (resolveDecommitIfTimedOut(revealRequestCommitIds[i])) continue;
      i++;
    }
  }

  // clear timed out requests and resolves the commit wager
  function resolveDecommitIfTimedOut(
    bytes32 _commitmentId
  ) public returns (bool) {
    require(revealRequestCache[_commitmentId].exists, 'RevealRequestNotFound');
    if (!isDecommitRequestTimedOut(_commitmentId)) return false;

    emit TimedOutRevealEvent(_commitmentId);
    processTimedOutDecommit(_commitmentId);
    clearCommitment(_commitmentId);

    return true;
  }

  function addRngWhitelist(address user) public onlyOwner {
    if (rngWhitelist[user]) revert('AddressAlreadyWhitelisted');
    rngWhitelist[user] = true;
    whitelistCount += 1;
  }

  function removeRngWhitelist(address user) public onlyOwner {
    if (!rngWhitelist[user]) revert('AddressNotInWhitelist');
    delete rngWhitelist[user];
    whitelistCount -= 1;
  }

  // function called by node when new commitments are created
  // emits new hashes available event
  function addCommitment(bytes32 _hash) external onlyWhitelistedUser {
    require(!commitmentStore[_hash].exists, 'CommitmentAlreadyAdded');

    commitmentIdList.push(_hash);
    commitmentStore[_hash] = Commitment(
      true,
      true,
      commitmentIdList.length - 1
    );

    emit NewHashesAvailable(_hash, 1, commitmentIdList.length);
  }

  function getAvailableCommitments() public view returns (bytes32[] memory) {
    return commitmentIdList;
  }

  // internal function called by sub class to create request for revealing random number
  // emits new decommit request event
  function revealRandomNumber(bytes32 _commitmentId) internal {
    require(
      commitmentStore[_commitmentId].availableState,
      'RngCommitNotFoundError'
    );

    // cache blockNumber to calculate timeout
    revealRequestCache[_commitmentId] = RevealNumberRequest(block.number, true);
    revealRequestCommitIds.push(_commitmentId);
    commitmentStore[_commitmentId].availableState = false;

    bytes32 lastCommitmentId = commitmentIdList[commitmentIdList.length - 1];
    commitmentIdList[commitmentStore[_commitmentId].index] = lastCommitmentId;
    commitmentStore[lastCommitmentId].index = commitmentStore[_commitmentId]
      .index;
    commitmentIdList.pop();

    emit DecommitRequest(_commitmentId);
  }

  function getSelectedCommitments() public view returns (bytes32[] memory) {
    return revealRequestCommitIds;
  }

  // function called by nodes to reveal the commitment secrets and caluclate the random number
  // uses the callback to send back the random number
  function revealCommitments(
    bytes32 _commitmentId,
    uint randomNumber,
    string calldata salt
  ) external {
    require(revealRequestCache[_commitmentId].exists, 'RevealRequestNotFound');

    if (!allowLateReveals() && resolveDecommitIfTimedOut(_commitmentId)) {
      return;
    }

    string memory secret = string(
      abi.encodePacked(Strings.toString(randomNumber), ',', salt)
    );
    bytes32 commitmentHash = sha256(abi.encodePacked(secret));

    if (commitmentHash != _commitmentId) {
      revert('InvalidReveal');
    }

    // invoke the callback function to pass back the random number
    // calls child contract's function
    __callback(_commitmentId, false, randomNumber, secret);

    clearCommitment(_commitmentId);
  }

  function clearCommitment(bytes32 _commitmentId) private {
    removeCommitment(_commitmentId);
    delete revealRequestCache[_commitmentId];

    // delete entry in revealRequestCommitIds
    for (uint i = 0; i < revealRequestCommitIds.length; i++) {
      if (
        keccak256(abi.encodePacked((revealRequestCommitIds[i]))) ==
        keccak256(abi.encodePacked((_commitmentId)))
      ) {
        revealRequestCommitIds[i] = revealRequestCommitIds[
          revealRequestCommitIds.length - 1
        ];
        revealRequestCommitIds.pop();
        break;
      }
    }
  }

  // delete commitment from store
  function removeCommitment(bytes32 _commitmentId) private {
    delete commitmentStore[_commitmentId];
  }

  // called when revealing a commitment
  // overridden by the derived child contract
  function __callback(
    bytes32 _commitmentId,
    bool timedOut,
    uint randomNumber,
    string memory rawSecret
  ) internal virtual {}

  // called when a decommit request is timed out
  // overriden by the derived child contract
  function processTimedOutDecommit(bytes32 _commitmentId) internal virtual {}
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