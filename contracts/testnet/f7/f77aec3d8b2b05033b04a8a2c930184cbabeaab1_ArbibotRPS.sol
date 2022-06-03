// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./AttestValidMoveVerifier.sol";
import "./RevealMoveVerifier.sol";
import "./IMinimalERC721.sol";
import "./IMinimalERC20.sol";

/// @title ArbibotRPS
/// @author botdad
/// @notice On chain rock paper scissors game for Arbibot holders using zkp
contract ArbibotRPS {
  /// -----------------------------------------------------------------------
  /// Errors
  /// -----------------------------------------------------------------------
  error ErrorInvalidProof();
  error ErrorInvalidMove();
  error ErrorRoundHasMove();
  error ErrorUnauthorized();
  error ErrorNoMove2();
  error ErrorInvalidMaxRoundTime();

  /// -----------------------------------------------------------------------
  /// Events
  /// -----------------------------------------------------------------------
  event RoundStarted(uint256 indexed roundId, uint256 indexed arbibotId1, uint256 wager, uint64 maxRoundTime);
  event Move2Played(uint256 indexed roundId, uint256 indexed arbibotId2);
  event RoundEnded(uint256 indexed roundId, uint256 indexed winner);

  /// -----------------------------------------------------------------------
  /// Custom types
  /// -----------------------------------------------------------------------
  struct Round {
    uint256 arbibotId1;
    uint256 arbibotId2;
    uint256 move1Attestation;
    uint256 wager;
    // all of the following can fit together in a 256 bit word
    uint32 nonce;
    uint64 maxRoundTime;
    uint64 startedAt;
    uint64 move2PlayedAt;
    uint8 move1;
    uint8 move2;
    uint8 winner;
    bool ended;
  }

  struct StartParams {
    uint256[8] proof;
    uint256 arbibotId;
    uint256 moveAttestation;
    uint32 nonce;
    uint64 maxRoundTime;
    // Permit signature fields
    uint256 permitAmount;
    uint256 permitDeadline;
    uint8 permitV;
    bytes32 permitR;
    bytes32 permitS;
  }

  struct Move2Params {
    uint256 arbibotId;
    uint256 roundId;
    uint8 move;
    // Permit signature fields
    uint256 permitDeadline;
    uint8 permitV;
    bytes32 permitR;
    bytes32 permitS;
  }

  struct EndParams {
    uint256[8] proof;
    uint256 arbibotId;
    uint256 roundId;
    uint8 move1;
    uint256 move1Attestation;
  }

  /// -----------------------------------------------------------------------
  /// Immutable parameters
  /// -----------------------------------------------------------------------
  uint8 public immutable DEAD_MOVE = 3;
  IMinimalERC721 public immutable arbibots;
  IMinimalERC20 public immutable botgold;

  /// -----------------------------------------------------------------------
  /// Storage variables
  /// -----------------------------------------------------------------------
  uint256 public totalRounds;
  Round[] public rounds;

  constructor(address _arbibots, address _botgold) {
    arbibots = IMinimalERC721(_arbibots);
    botgold = IMinimalERC20(_botgold);
  }

  modifier onlyArbibotOwner(uint256 arbibotId) {
    if (arbibots.ownerOf(arbibotId) != msg.sender) {
      revert ErrorUnauthorized();
    }
    _;
  }

  /// -----------------------------------------------------------------------
  /// User actions
  /// -----------------------------------------------------------------------

  /// @notice Starts a new round and opens up play
  /// @dev Requires a valid AttestValidMove zk proof created off chain
  /// @param params The params necessary to start a round, encoded as `StartParams` in calldata
  function startRound(StartParams calldata params) external onlyArbibotOwner(params.arbibotId) {
    /// -------------------------------------------------------------------
    /// Validation
    /// -------------------------------------------------------------------
    if (!AttestValidMoveVerifier.verifyProof(params.proof, params.moveAttestation)) {
      revert ErrorInvalidProof();
    }

    if (params.permitAmount > 0 && params.maxRoundTime == 0) {
      revert ErrorInvalidMaxRoundTime();
    }

    /// -------------------------------------------------------------------
    /// State updates
    /// -------------------------------------------------------------------
    Round memory round = Round(
      params.arbibotId,
      0, // no arbibot2 id yet
      params.moveAttestation,
      params.permitAmount,
      params.nonce,
      params.maxRoundTime,
      uint64(block.timestamp),
      0, // move 2 not played yet
      DEAD_MOVE,
      DEAD_MOVE,
      0, // winner is tie until end
      false
    );
    rounds.push(round);
    unchecked {
      ++totalRounds;
    }

    /// -------------------------------------------------------------------
    /// Effects
    /// -------------------------------------------------------------------
    if (params.permitAmount > 0) {
      botgold.permit(
        msg.sender,
        address(this),
        params.permitAmount,
        params.permitDeadline,
        params.permitV,
        params.permitR,
        params.permitS
      );
      botgold.transferFrom(msg.sender, address(this), params.permitAmount);
    }

    emit RoundStarted(rounds.length - 1, params.arbibotId, params.permitAmount, params.maxRoundTime);
  }

  /// @notice Starts a new round and opens up play
  /// @dev Requires a valid AttestValidMove zk proof created off chain
  /// @param params The params necessary to submit a move2, encoded as `Move2Params` in calldata
  function submitMove2(Move2Params calldata params) external onlyArbibotOwner(params.arbibotId) {
    /// -------------------------------------------------------------------
    /// Validation
    /// -------------------------------------------------------------------
    Round memory round = rounds[params.roundId];

    if (round.ended || round.move2 != DEAD_MOVE) {
      revert ErrorRoundHasMove();
    }

    if (params.move > 2) {
      revert ErrorInvalidMove();
    }

    /// -------------------------------------------------------------------
    /// State updates
    /// -------------------------------------------------------------------
    round.arbibotId2 = params.arbibotId;
    round.move2 = params.move;
    round.move2PlayedAt = uint64(block.timestamp);

    rounds[params.roundId] = round;

    /// -------------------------------------------------------------------
    /// Effects
    /// -------------------------------------------------------------------
    if (round.wager > 0) {
      botgold.permit(
        msg.sender,
        address(this),
        round.wager,
        params.permitDeadline,
        params.permitV,
        params.permitR,
        params.permitS
      );
      botgold.transferFrom(msg.sender, address(this), round.wager);
    }

    emit Move2Played(params.roundId, params.arbibotId);
  }

  /// @notice Starts a new round and opens up play
  /// @dev Requires a valid RevealMove zk proof created off chain
  /// @param params The params necessary to end a round, encoded as `EndParams` in calldata
  function endRound(EndParams calldata params) external onlyArbibotOwner(params.arbibotId) {
    /// -------------------------------------------------------------------
    /// Validation
    /// -------------------------------------------------------------------
    Round memory round = rounds[params.roundId];

    if (round.arbibotId1 != params.arbibotId) {
      revert ErrorUnauthorized();
    }

    if (round.move1Attestation != params.move1Attestation) {
      revert ErrorUnauthorized();
    }

    if (round.ended || round.move1 != DEAD_MOVE) {
      revert ErrorRoundHasMove();
    }

    if (round.move2 == DEAD_MOVE) {
      revert ErrorNoMove2();
    }

    if (params.move1 == DEAD_MOVE) {
      revert ErrorInvalidMove();
    }

    if (!RevealMoveVerifier.verifyProof(params.proof, params.move1, params.move1Attestation)) {
      revert ErrorInvalidProof();
    }

    /// -------------------------------------------------------------------
    /// State updates
    /// -------------------------------------------------------------------
    round.move1 = params.move1;
    round.ended = true;

    if (round.move1 > round.move2) {
      unchecked {
        uint8 diff = round.move1 - round.move2;
        round.winner = diff == 1 ? 1 : 2;
      }
    } else if (round.move1 < round.move2) {
      unchecked {
        uint8 diff = round.move2 - round.move1;
        round.winner = diff == 1 ? 2 : 1;
      }
    } // else tie, no winner

    rounds[params.roundId] = round;

    /// -------------------------------------------------------------------
    /// Effects
    /// -------------------------------------------------------------------
    if (round.wager > 0) {
      if (round.winner == 1) {
        address owner = arbibots.ownerOf(round.arbibotId1);
        botgold.transfer(owner, round.wager * 2);
      } else if (round.winner == 2) {
        address owner = arbibots.ownerOf(round.arbibotId2);
        botgold.transfer(owner, round.wager * 2);
      } else {
        address owner1 = arbibots.ownerOf(round.arbibotId1);
        address owner2 = arbibots.ownerOf(round.arbibotId2);
        botgold.transfer(owner1, round.wager);
        botgold.transfer(owner2, round.wager);
      }
    }

    emit RoundEnded(params.roundId, round.winner);
  }

  /// @notice Claim winnings for player 2 if player 1 has not revealed the winner in time
  /// @param arbibotId token id of original arbibot player
  /// @param roundId the id of the round in a forfeit state
  function collectForfeit(uint256 arbibotId, uint256 roundId) external onlyArbibotOwner(arbibotId) {
    /// -------------------------------------------------------------------
    /// Validation
    /// -------------------------------------------------------------------
    Round memory round = rounds[roundId];

    if (round.maxRoundTime == 0) {
      revert ErrorUnauthorized();
    }

    if (round.ended) {
      revert ErrorUnauthorized();
    }

    if (round.arbibotId2 != arbibotId) {
      revert ErrorUnauthorized();
    }

    if (block.timestamp < round.move2PlayedAt + round.maxRoundTime) {
      revert ErrorUnauthorized();
    }

    /// -------------------------------------------------------------------
    /// State updates
    /// -------------------------------------------------------------------
    round.ended = true;
    rounds[roundId] = round;

    /// -------------------------------------------------------------------
    /// Effects
    /// -------------------------------------------------------------------
    // msg.sender is garunteed to be arbibots.ownerOf(arbibotId); by modifier
    botgold.transfer(msg.sender, round.wager * 2);

    emit RoundEnded(roundId, 2);
  }

  /// -------------------------------------------------------------------
  /// Views
  /// -------------------------------------------------------------------

  /// @notice Gets single round of play
  /// @param roundId id of the round
  /// @return round
  function getRound(uint256 roundId) external view returns (Round memory) {
    return rounds[roundId];
  }

  /// @notice Gets all rounds of play
  /// @return rounds all rounds
  function getRounds() external view returns (Round[] memory) {
    return rounds;
  }

  /// @notice Gets per arbibot nonce for signature generation
  /// @param arbibotId id of the arbibot
  /// @return nonce nonce to use for signature generation
  function getNonce(uint256 arbibotId) external view returns (uint256 nonce) {
    for (uint256 i = 0; i < rounds.length; i++) {
      Round memory round = rounds[i];
      if (round.arbibotId1 == arbibotId) {
        nonce++;
      }
    }
  }
}