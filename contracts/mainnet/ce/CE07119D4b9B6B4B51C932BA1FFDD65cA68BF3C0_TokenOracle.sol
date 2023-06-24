/**
 *Submitted for verification at Arbiscan on 2023-06-24
*/

pragma solidity ^0.8.18;

interface ILodeStar {
    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}

contract TokenOracle {
    ILodeStar lodeStar;

    struct Observation {
        uint256 timestamp;
        uint256 priceCumulative;
    }

    Observation[] public observation;

    constructor(address _contract) {
        lodeStar = ILodeStar(_contract);
    }

    function latestRoundData()
        public
        view
        virtual
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        if (observation.length > 11) {
            Observation memory observationEnd = observation[
                observation.length - 1
            ];
            Observation memory observationStart = observation[
                observation.length - 11
            ];

            answer = int256(
                (observationEnd.priceCumulative -
                    observationStart.priceCumulative) /
                    (observationEnd.timestamp - observationStart.timestamp)
            );
        } else {
            uint256 current = lodeStar.exchangeRateStored();
            answer = int256(current / 10**8);
        }

        return (1, answer, 1, 1, 1);
    }

    function latestAnswer() public view virtual returns (int256 answer) {
        if (observation.length > 11) {
            Observation memory observationEnd = observation[
                observation.length - 1
            ];
            Observation memory observationStart = observation[
                observation.length - 11
            ];

            answer = int256(
                (observationEnd.priceCumulative -
                    observationStart.priceCumulative) /
                    (observationEnd.timestamp - observationStart.timestamp)
            );
        } else {
            uint256 current = lodeStar.exchangeRateStored();
            answer = int256(current / 10**8);
        }

        return answer;
    }

    function update() external {
        if (observation.length == 0) {
            observation.push(
                Observation({timestamp: block.timestamp, priceCumulative: 0})
            );
        } else {
            Observation memory observationStart = observation[
                observation.length - 1
            ];

            require(block.timestamp > observationStart.timestamp + 60 minutes, "Too early");

            uint256 priceCumulative = observationStart.priceCumulative +
                ((lodeStar.exchangeRateStored() / 10**8) *
                    (block.timestamp - observationStart.timestamp));
            observation.push(
                Observation({
                    timestamp: block.timestamp,
                    priceCumulative: priceCumulative
                })
            );
        }
    }
}