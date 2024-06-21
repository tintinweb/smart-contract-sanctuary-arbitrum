// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev See DapiProxy.sol for comments about usage
interface IProxy {
    function read() external view returns (int224 value, uint32 timestamp);

    function api3ServerV1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@api3/contracts/api3-server-v1/proxies/interfaces/IProxy.sol";

contract Api3AggregatorAdaptor {  

   // Updating the proxy address is a security-critical action which is why
   // we have made it immutable.
   address public immutable proxy;

   constructor(address _proxy) {
       proxy = _proxy;
   }

   function latestAnswer() external view returns (int256 value) {
       (value, ) = readDataFeed();
   }

   function latestTimestamp() external view returns (uint256 timestamp) {
       ( , timestamp) = readDataFeed();
   }
   
   function decimals() external pure returns (uint8) {
       return 8;
   }

   function readDataFeed()
       internal
       view
       returns (int224 value, uint256 timestamp)
   {
       (value, timestamp) = IProxy(proxy).read();
       value = value / 1e10;
       // If you have any assumptions about `value` and `timestamp`, make sure
       // to validate them right after reading from the proxy. For example,
       // if the value you are reading is the spot price of an asset, you may
       // want to reject non-positive values...
       // require(value > 0, "Value not positive");
       // ...and if the data feed is being updated with a one day-heartbeat
       // interval, you may want to check for that.
       require(
           timestamp + 1 days > block.timestamp,
           "Timestamp older than one day"
       );
       // Try to be strict about validations, but be wary of:
       // (1) Overly strict validation that may invalidate valid values
       // (2) Mutable validation parameters that are controlled by a trusted
       // party (eliminates the trust-minimization guarantees of first-party
       // oracles)
       // (3) Validation parameters that need to be tuned according to
       // external conditions (if these are forgotten to be handled, it will
       // result in (1), look up the Venus Protocol exploit related to LUNA)

       // After validation, you can implement your contract logic here.
   }       

   function getTokenType() external pure returns (uint256) {
       return 1;
   }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (int224 value, uint256 timestamp) = readDataFeed();
        roundId = uint80(timestamp);
        return (
            roundId,
            int256(value),
            timestamp,
            timestamp,
            roundId
        );
    }
}