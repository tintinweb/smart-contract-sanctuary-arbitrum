// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface JiriRngGatewayInterface {
  /**
   * @notice Request to generate new commitments.
   * @param subscriptionId - subscription ID
   * @param numCommitments - Number of commitments to be created
   * @param gatewayVersion - Gateway version to be used by the nodes
   */
  function requestCommitments(
    uint64 subscriptionId,
    uint16 numCommitments,
    string calldata gatewayVersion
  ) external;

  /**
   * @notice Request to generate new commitments (uses latest gateway version).
   * @param subscriptionId - subscription ID
   * @param numCommitments - Number of commitments to be created
   */
  function requestCommitments(
    uint64 subscriptionId,
    uint16 numCommitments
  ) external;

  /**
   * @notice Request to decommit the given commitment Id.
   * @param subscriptionId - subscription ID
   * @param commitmentId - commitment ID which needs to be decommited
   * @param gatewayVersion - Gateway version to be used by the nodes
   */
  function requestDecommit(
    uint64 subscriptionId,
    bytes32 commitmentId,
    string calldata gatewayVersion
  ) external;

  /**
   * @notice Request to decommit the given commitment Id (uses latest gateway version).
   * @param subscriptionId - subscription ID
   * @param commitmentId - commitment ID which needs to be decommited
   */
  function requestDecommit(
    uint64 subscriptionId,
    bytes32 commitmentId
  ) external;

  /**
   * Function to check if the decommit request is timed out
   * @param subscriptionId subscription Id
   * @param commitmentId commitment hash
   */
  function checkTimedOutDecommit(
    uint64 subscriptionId,
    bytes32 commitmentId
  ) external;

  /**
   * Function to check all timed out decommits
   * @param subscriptionId subscription Id
   */
  function checkAllTimedOutDecommitsForSubscription(
    uint64 subscriptionId
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract JiriRngConsumerBase {
  /**
   * @notice Callback function called by the gateway when new commiments are generated
   * @param commitments - list of new commitment IDs
   */
  function receiveNewCommitments(bytes32[] memory commitments) external virtual;

  /**
   * @notice Callback function called by the gateway when decommit request is completed
   * @param commitmentId - commitment ID
   * @param randomNumber - generated random number for the commitment
   * @param rangeMaxPrime - prime number set for the commitment
   */
  function revealRequestedCommitment(
    bytes32 commitmentId,
    uint256 randomNumber,
    uint256 rangeMaxPrime
  ) external virtual;

  /**
   * @notice Callback function called by the gateway when a decommit request is timedout
   * @param commitmentId - commitment ID of timed out decommit
   */
  function receiveTimeoutNotification(bytes32 commitmentId) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@jiritsu-dev/rng/contracts/JiriRngConsumerBase.sol";
import "@jiritsu-dev/rng/contracts/interfaces/JiriRngGatewayInterface.sol";

contract House is JiriRngConsumerBase {
  address private owner;
  uint64 subscriptionId;

  mapping(address => bool) adminAllowList;

  JiriRngGatewayInterface rngGateway;
  address rngCoordinator;

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

  mapping(bytes32 => bool) commitmentsCache;
  uint256 commitmentsCount = 0;

  event NewHashesAvailable(
    bytes32[] commitmentId,
    uint256 newlyReceived,
    uint256 total
  );

  event TimedOut(bytes32 commitmentId);

  event GameResult(
    bytes32 commitmentId,
    UnresolvedWager wager,
    uint randomNumber,
    uint scaledRandomNumber,
    uint256 prime,
    string reason
  );

  modifier onlyOwner() {
    require(owner == msg.sender, "OnlyOwner");
    _;
  }

  constructor(address _rngCoordinator, uint64 _subscriptionId) {
    owner = msg.sender;
    adminAllowList[owner] = true;

    rngCoordinator = _rngCoordinator;
    rngGateway = JiriRngGatewayInterface(rngCoordinator);

    subscriptionId = _subscriptionId;
  }

  receive() external payable {}

  function liquidate(uint _amount) external onlyOwner {
    require(address(this).balance > _amount, "AmountHigherThanBalance");

    payable(msg.sender).transfer(_amount);
  }

  function updateRngCoordinator(address _rngCoordinator) external {
    rngCoordinator = _rngCoordinator;
    rngGateway = JiriRngGatewayInterface(rngCoordinator);
  }

  function updateRngSubscriptionId(uint64 _subscriptionId) external {
    subscriptionId = _subscriptionId;
  }

  function requestNewCommitments(uint16 numCommitments) external {
    // send request to gateway contract for new commitments
    rngGateway.requestCommitments(subscriptionId, numCommitments);
  }

  function receiveNewCommitments(
    bytes32[] memory commitments
  ) external override {
    for (uint16 i = 0; i < commitments.length; i++) {
      commitmentsCache[commitments[i]] = true;
    }

    commitmentsCount += commitments.length;
    emit NewHashesAvailable(commitments, commitments.length, commitmentsCount);
  }

  function commitWager(
    uint8 _gameId,
    uint _gameOptions,
    bytes32 _rngCommitment
  ) external payable {
    require(msg.value > 0, "NoBetError");
    require(_gameId == 1 || _gameId == 2, "InvalidGameIdError");

    bool gameOneCondition = (_gameId == 1 &&
      _gameOptions <= 10 &&
      _gameOptions >= 1);
    bool gameTwoCondition = (_gameId == 2 &&
      (_gameOptions == 1 || _gameOptions == 0));
    require(gameOneCondition || gameTwoCondition, "InvalidGameOptions");

    totalOutstandingWagers += _gameId == 1 ? msg.value * 10 : msg.value * 2;
    require(address(this).balance > totalOutstandingWagers, "BetTooBigError");

    commitmentsCount -= 1;

    unresolvedWagers[_rngCommitment] = UnresolvedWager(
      _gameId,
      _gameOptions,
      msg.value,
      msg.sender,
      false,
      0,
      false
    );

    rngGateway.requestDecommit(subscriptionId, _rngCommitment);
    commitmentsCache[_rngCommitment] = false;
  }

  function gameLogicOne(
    uint randomNumber,
    uint playerChoice
  ) private pure returns (bool, uint, uint) {
    // 'one-through-ten' game, number range: 1 - 10
    uint odds = 10;
    uint scaledNumber = scaleNumberToWindow(randomNumber, 1, 10);
    return (scaledNumber == playerChoice, scaledNumber, odds);
  }

  function gameLogicTwo(
    uint randomNumber,
    uint playerChoice
  ) private pure returns (bool, uint, uint) {
    // 'coin-flip' game, number range: 0 - 1
    uint odds = 2;
    // default window size of random number: 1 to 10
    uint scaledNumber = scaleNumberToWindow(randomNumber, 0, 1);
    return (scaledNumber == playerChoice, scaledNumber, odds);
  }

  function resolveWager(bytes32 _commitmentId) private {
    require(unresolvedWagers[_commitmentId].resolved, "WagerNotResolved");

    uint amount = unresolvedWagers[_commitmentId].wageredAmount *
      unresolvedWagers[_commitmentId].odds;
    totalOutstandingWagers -= amount;

    if (!unresolvedWagers[_commitmentId].isWinner) return;
    payable(unresolvedWagers[_commitmentId].playerAddress).transfer(amount);
  }

  function resolveGameResult(
    bytes32 _commitmentId,
    uint randomNumber
  ) private returns (uint) {
    uint scaledRandomNumber;
    (
      unresolvedWagers[_commitmentId].isWinner,
      scaledRandomNumber,
      unresolvedWagers[_commitmentId].odds
    ) = unresolvedWagers[_commitmentId].gameId == 1
      ? gameLogicOne(randomNumber, unresolvedWagers[_commitmentId].gameOptions)
      : gameLogicTwo(randomNumber, unresolvedWagers[_commitmentId].gameOptions);

    return scaledRandomNumber;
  }

  function revealRequestedCommitment(
    bytes32 commitmentId,
    uint256 randomNumber,
    uint256 rangeMaxPrime
  ) external override {
    require(!unresolvedWagers[commitmentId].resolved, "WagerNotFound");

    unresolvedWagers[commitmentId].resolved = true;
    // checks game result and updates the struct
    uint scaledRandomNumber = resolveGameResult(commitmentId, randomNumber);

    // transfers bet amount if won, updates outstanding wagers
    resolveWager(commitmentId);

    emit GameResult(
      commitmentId,
      unresolvedWagers[commitmentId],
      randomNumber,
      scaledRandomNumber,
      rangeMaxPrime,
      unresolvedWagers[commitmentId].isWinner ? "player won" : "player lost"
    );

    delete unresolvedWagers[commitmentId];
  }

  // scales the number to given windown
  function scaleNumberToWindow(
    uint _number,
    uint _windowMin,
    uint _windowMax
  ) internal pure returns (uint) {
    uint _N = (_windowMax - _windowMin + 1);
    return (_number % _N) + _windowMin;
  }

  /**
   * @notice Callback function called by the gateway when a decommit request is timedout
   * @param commitmentId - commitment ID of timed out decommit
   */
  function receiveTimeoutNotification(bytes32 commitmentId) external override {
    require(!unresolvedWagers[commitmentId].resolved, "WagerNotFound");

    emit TimedOut(commitmentId);

    unresolvedWagers[commitmentId].resolved = true;
    // checks game result and updates the struct
    resolveGameResult(commitmentId, 1);
    unresolvedWagers[commitmentId].isWinner = true;

    // transfer bet amount
    resolveWager(commitmentId);

    emit GameResult(
      commitmentId,
      unresolvedWagers[commitmentId],
      0,
      0,
      0,
      "Timed out"
    );
  }

  function checkCommitTimeout(bytes32 commitmentId) external {
    rngGateway.checkTimedOutDecommit(subscriptionId, commitmentId);
  }

  function checkAllTimeouts() external {
    rngGateway.checkAllTimedOutDecommitsForSubscription(subscriptionId);
  }
}