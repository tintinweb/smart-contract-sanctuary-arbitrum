//SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Here Not There, Inc. <[email protected]>                      *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// if everyone reveals game is over
// if time runs out game is over
// only need a mapping if time limit based, but since we need to know when
// all are revealed, need to keep track of all the addresses in an array

//payables

contract Lupi is ReentrancyGuard {
  uint256 private constant TICKET_PRICE = 0.01 ether;

  event GameResult(
    uint32 indexed round,
    address indexed winner,
    uint256 award,
    uint32 lowestGuess
  );

  event AwardDeferred(
    uint32 indexed round,
    address indexed winner,
    uint256 amount
  );
  event AwardWithdrawn(
    uint32 indexed round,
    address indexed winner,
    address indexed payee,
    uint256 amount
  );
  event AwardForfeited(
    uint32 indexed round,
    address indexed winner,
    uint256 amount
  );

  uint256 private rollover;
  mapping(uint32 => Round) private rounds;
  address private pendingWinner = address(0); // Hold funds for this winner if call fails
  uint256 private pendingAmount = 0; // Amount held until the next game starts, otherwise forfeit into rollover
  uint32 private pendingAwardRound;
  uint32 private round;

  struct Round {
    bytes32 nonce;
    uint256 balance;
    mapping(address => CommitedGuess[]) committedGuesses;
    RevealedGuess[] revealedGuesses;
    address[] players;
    uint32 guessDeadline;
    uint32 revealDeadline;
  }

  struct CommitedGuess {
    bytes32 guessHash;
    bool revealed;
  }

  struct AllCommitedGuess {
    address player;
    CommitedGuess[] commitedGuesses;
  }

  struct RevealedGuess {
    address player;
    uint32 guess;
  }

  struct Reveal {
    bytes32 guessHash;
    bytes32 salt;
    uint32 round;
    uint32 answer;
  }

  function getSaltedHash(
    bytes32 nonce,
    uint32 answer,
    bytes32 salt
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(nonce, answer, salt));
  }

  constructor() {
    round = 0;
    newGame();
  }

  function newGame() private {
    ++round;

    // If the prior winner failed to receive payment, and failed to collect payment, it is forfeit
    // at the start of the next round
    if (pendingWinner != address(0)) {
      forfeitAward();
    }
    // When on Arbitrum Testnet run rounds faster
    rounds[round].guessDeadline =
      uint32(block.timestamp) +
      (
        block.chainid == 421611 ? 10 minutes : block.chainid == 31337
          ? 2 minutes
          : 3 days
      );
    rounds[round].revealDeadline =
      uint32(block.timestamp) +
      (
        block.chainid == 421611 ? 15 minutes : block.chainid == 31337
          ? 4 minutes
          : 4 days
      );
    rounds[round].nonce = bytes32(uint256(uint160(address(this))) << 96); // Replace with chainlink random;
  }

  function commitGuess(bytes32 guessHash) external payable nonReentrant {
    require(
      block.timestamp < rounds[round].guessDeadline,
      "Guess deadline has passed"
    );
    require(msg.value >= TICKET_PRICE, "Must send at least TICKET_PRICE");

    if (rounds[round].committedGuesses[msg.sender].length == 0) {
      rounds[round].players.push(msg.sender);
    }
    rounds[round].committedGuesses[msg.sender].push(
      CommitedGuess(guessHash, false)
    );
    rounds[round].balance += TICKET_PRICE;
    uint256 ethToReturn = msg.value - TICKET_PRICE;
    if (ethToReturn > 0) {
      payable(msg.sender).transfer(ethToReturn);
    }
  }

  function revealGuesses(Reveal[] calldata reveals) external {
    require(
      block.timestamp > rounds[round].guessDeadline,
      "revealGuesses guessDeadline hasn't passed"
    );
    require(
      block.timestamp < rounds[round].revealDeadline,
      "revealGuesses revealDeadline has passed"
    );
    require(
      rounds[round].committedGuesses[msg.sender].length > 0,
      "No guesses to reveal"
    );

    uint256 length = rounds[round].committedGuesses[msg.sender].length;
    uint256 revealsLength = reveals.length;

    for (uint256 r; r < revealsLength; ) {
      bool found = false;
      Reveal memory revealedGuess = reveals[r];
      for (uint256 i; i < length; ) {
        if (
          rounds[round].committedGuesses[msg.sender][i].guessHash ==
          revealedGuess.guessHash
        ) {
          require(
            revealedGuess.answer > 0,
            "revealGuesses answer must be positive"
          );
          require(
            revealedGuess.round == round,
            "revealGuesses must be for current round"
          );

          require(
            getSaltedHash(
              rounds[round].nonce,
              revealedGuess.answer,
              revealedGuess.salt
            ) == revealedGuess.guessHash,
            "Reveal hash does not match guessHash"
          );
          require(
            !rounds[round].committedGuesses[msg.sender][i].revealed,
            "Already revealed"
          );
          rounds[round].committedGuesses[msg.sender][i].revealed = true;
          rounds[round].revealedGuesses.push(
            RevealedGuess(msg.sender, revealedGuess.answer)
          );
          found = true;
        }
        unchecked {
          ++i;
        }
      }

      require(found, "revealGuesses no matching guessHash found");
      unchecked {
        ++r;
      }
    }
  }

  function getCurrentNonce() external view returns (bytes32) {
    return (rounds[round].nonce);
  }

  function getCurrentState()
    external
    view
    returns (
      uint256 blockTimestamp,
      uint32 currentRound,
      bytes32 nonce,
      uint256 guessDeadline,
      uint256 revealDeadline,
      uint256 balance,
      Lupi.AllCommitedGuess[] memory commitedGuesses,
      RevealedGuess[] memory revealedGuesses,
      address[] memory players
    )
  {
    Lupi.AllCommitedGuess[] memory ret = new AllCommitedGuess[](
      rounds[round].players.length
    );
    uint256 playersLength = rounds[round].players.length;
    for (uint256 i; i < playersLength; ) {
      ret[i].player = rounds[round].players[i];
      ret[i].commitedGuesses = rounds[round].committedGuesses[
        rounds[round].players[i]
      ];
      unchecked {
        ++i;
      }
    }

    return (
      block.timestamp,
      round,
      rounds[round].nonce,
      rounds[round].guessDeadline,
      rounds[round].revealDeadline,
      rounds[round].balance,
      ret,
      rounds[round].revealedGuesses,
      rounds[round].players
    );
  }

  function endGame() external nonReentrant {
    require(
      block.timestamp > rounds[round].revealDeadline,
      "Still in reveal phase"
    );
    uint32 lowestGuess = 0xffffffff;
    address winner = address(0);

    uint256 revealedGuessesLength = rounds[round].revealedGuesses.length;

    for (uint256 i; i < revealedGuessesLength; ) {
      RevealedGuess memory revealedGuessI = rounds[round].revealedGuesses[i];
      if (revealedGuessI.guess < lowestGuess) {
        bool unique = true;
        for (uint256 x; x < revealedGuessesLength; ) {
          if (i != x) {
            if (
              rounds[round].revealedGuesses[x].guess == revealedGuessI.guess
            ) {
              unique = false;
              break;
            }
          }
          unchecked {
            ++x;
          }
        }
        if (unique) {
          lowestGuess = revealedGuessI.guess;
          winner = revealedGuessI.player;
        }
      }
      unchecked {
        ++i;
      }
    }

    uint256 award = 0;
    uint32 lastRound = round;

    if (lowestGuess < 0xffffffff && winner != address(0)) {
      // Winner takes all plus rollover
      award = rollover + rounds[round].balance;
      rollover = 0;
    } else {
      // Balance rolls over to next round
      rollover += rounds[round].balance;
    }

    for (uint256 i; i < rounds[round].players.length; ++i) {
      delete rounds[round].committedGuesses[rounds[round].players[i]];
    }
    delete rounds[round].revealedGuesses;
    delete rounds[round].players;
    //slither-disable-next-line mapping-deletion
    delete rounds[round];
    newGame();
    bool success = false;
    if (award > 0 && winner != address(0)) {
      //slither-disable-next-line reentrancy-eth
      (success, ) = winner.call{gas: 21000, value: award}("");
    }
    emit GameResult(
      lastRound,
      winner,
      award,
      lowestGuess < 0xffffffff ? lowestGuess : 0
    );
    if (!success && award > 0 && winner != address(0)) {
      deferAward(lastRound, winner, award);
    }
  }

  /**
   * @dev Deposit balance for a winner when the call in endGame failed.
   * @param winner The address to which funds may be claimed from.
   */
  function deferAward(
    uint32 lastRound,
    address winner,
    uint256 amount
  ) internal {
    pendingWinner = winner;
    pendingAmount = amount;
    pendingAwardRound = lastRound;
    emit AwardDeferred(lastRound, winner, amount);
  }

  /**
   * @dev Withdraw deferred balance for a winner when the call in endGame failed.
   * @param payee The address to which funds will be sent to.
   */
  function withdrawAward(address payable payee) external nonReentrant {
    require(
      msg.sender == pendingWinner,
      "Only the winning address may withdraw"
    );
    require(payee != address(0), "Not allowed to transfer to address(0)");
    uint32 lastRound = pendingAwardRound;
    uint256 amount = pendingAmount;
    address winner = pendingWinner;

    delete pendingAmount;
    delete pendingWinner;
    delete pendingAwardRound;

    (bool success, ) = payee.call{value: amount}("");
    require(success, "withdrawAward unable to send value");
    emit AwardWithdrawn(lastRound, winner, payee, amount);
  }

  /**
   * @dev Forfeit balance for a winner when the balance wasn't retrieved prior to the
   * next round starting.
   */
  function forfeitAward() internal {
    rollover += pendingAmount;
    emit AwardForfeited(pendingAwardRound, pendingWinner, pendingAmount);
    delete pendingAwardRound;
    delete pendingWinner;
    delete pendingAmount;
  }

  function getRolloverBalance() external view returns (uint256) {
    return rollover;
  }

  function getRound() external view returns (uint32) {
    return round;
  }

  function getPendingWinner() external view returns (address) {
    return pendingWinner;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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