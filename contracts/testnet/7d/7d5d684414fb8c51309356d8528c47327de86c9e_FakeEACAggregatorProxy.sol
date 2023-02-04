/**
 *Submitted for verification at Arbiscan on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * return answer is the answer for the given round
   * return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
contract FakeEACAggregatorProxy{

  function latestRoundData()
    public
    pure
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {


    (
      roundId ,
      answer,
      startedAt,
      updatedAt,
      answeredInRound
    ) = (18446744073709885213, 161337133700, 1675336316, 1675336316, 18446744073709885213);

    return (roundId, answer, startedAt, updatedAt, answeredInRound);
  }

    function decimals()
    external
    pure
    returns (uint8)
  {
    return 8;
  }
}