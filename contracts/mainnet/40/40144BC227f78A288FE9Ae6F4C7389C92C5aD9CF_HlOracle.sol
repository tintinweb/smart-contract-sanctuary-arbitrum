// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IAutomatedFunctionsConsumer {
    function s_lastResponse() external view returns (bytes memory);
    function lastUpkeepTimeStamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "../interfaces/IAutomatedFunctionsConsumer.sol";

contract HlOracle is AutomationCompatibleInterface {
    mapping(uint256 => uint256[2]) public settlePrices;
    IAutomatedFunctionsConsumer internal immutable AUTOMATED_FUNCTIONS_CONSUMER;
    uint256 public latestExpiryUpdated = 0;

    event Settled(uint256 expiry, uint256[2] settlePrices);

    modifier oracleAvailable() {
        // latestUpdateOracleTime >= 8:00 UTC
        uint256 latestUpdateOracleTime = AUTOMATED_FUNCTIONS_CONSUMER.lastUpkeepTimeStamp();
        require(latestUpdateOracleTime >= block.timestamp - block.timestamp % 86400 + 28800, "Oracle: not updated");
        _;
    }

    constructor(
        IAutomatedFunctionsConsumer automatedFunctionsConsumer_
    ) {
        AUTOMATED_FUNCTIONS_CONSUMER = automatedFunctionsConsumer_;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        oracleAvailable
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        uint256 expiry = block.timestamp - block.timestamp % 86400 + 28800;
        upkeepNeeded = settlePrices[expiry][1] == 0;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        settle();
    }

    // settle price
    function settle() public oracleAvailable {
        uint256 expiry = block.timestamp - block.timestamp % 86400 + 28800;
        require(settlePrices[expiry][1] == 0, "Oracle: already settled");

        uint256[2] memory currentPrices = getLatestPrice();
        require(currentPrices[0] < currentPrices[1], "Oracle: invalid price");

        if (latestExpiryUpdated != 0 && latestExpiryUpdated <= expiry - 86400 * 2) {
            uint256 missedDays = (expiry - latestExpiryUpdated) / 86400;
            uint256[2] memory startPrices = settlePrices[latestExpiryUpdated];

            for (uint256 i = 1; i < missedDays; i++) {
                uint256 missedExpiry = latestExpiryUpdated + i * 86400;
                if (startPrices[0] > currentPrices[0]) {
                    settlePrices[missedExpiry][0] = startPrices[0] - (startPrices[0] - currentPrices[0]) * i / missedDays;
                } else {
                    settlePrices[missedExpiry][0] = startPrices[0] + (currentPrices[0] - startPrices[0]) * i / missedDays;
                }
                if (startPrices[1] > currentPrices[1]) {
                    settlePrices[missedExpiry][1] = startPrices[1] - (startPrices[1] - currentPrices[1]) * i / missedDays;
                } else {
                    settlePrices[missedExpiry][1] = startPrices[1] + (currentPrices[1] - startPrices[1]) * i / missedDays;
                }
                emit Settled(missedExpiry, settlePrices[missedExpiry]);
            }
        }

        settlePrices[expiry] = currentPrices;
        latestExpiryUpdated = expiry;

        emit Settled(expiry, settlePrices[expiry]);
    }

    function getLatestPrice() internal view returns (uint[2] memory prices) {
        prices = abi.decode(AUTOMATED_FUNCTIONS_CONSUMER.s_lastResponse(), (uint256[2]));
    }

    function getHlPrices(uint256 term, uint256 expiry) public view returns (uint256[2] memory hlPrices) {
        // find lowest and highest prices in the term
        hlPrices = [type(uint256).max, 0];
        if (term > 0) {
            for (uint256 i = 0; i < term; i++) {
                if (settlePrices[expiry][0] > 0 && settlePrices[expiry][0] < hlPrices[0]) {
                    hlPrices[0] = settlePrices[expiry][0];
                }
                if (settlePrices[expiry][1] > hlPrices[1]) {
                    hlPrices[1] = settlePrices[expiry][1];
                }
                expiry = expiry - 86400;
            }
        }
    }
}