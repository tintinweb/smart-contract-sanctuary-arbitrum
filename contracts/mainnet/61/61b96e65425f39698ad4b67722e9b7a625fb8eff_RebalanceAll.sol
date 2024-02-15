// SPDX-License-Identifier: BSUL-1.1
pragma solidity ^0.8.19;

interface NotionalProxy {
    function rebalance(uint16 currencyId) external;

    function checkRebalance() external returns (uint16[] memory currencyId);
}

contract RebalanceAll {
    event RebalancingFailed(uint16 currencyId, bytes reason);

    error CurrencyIdsLengthCannotBeZero();
    error CurrencyIdsNeedToBeSorted();
    error Unauthorized();

    // dedicated msg.sender from Gelato
    address public constant REBALANCING_BOT = 0xeBb9C73a1eDB956326c206F604160B98dB4a802f;
    uint256 public constant DELAY_AFTER_FAILURE = 10 minutes;
    NotionalProxy public immutable NOTIONAL;

    mapping(uint16 currencyId => uint32 lastFailedRebalanceTimestamp) public failedRebalanceMap;

    constructor(address notionalAddress) {
        NOTIONAL = NotionalProxy(notionalAddress);
    }

    function rebalanceAll(uint16[] calldata currencyIds) external {
        if (currencyIds.length == 0) {
            revert CurrencyIdsLengthCannotBeZero();
        }
        if (msg.sender != REBALANCING_BOT) {
            revert Unauthorized();
        }

        for (uint256 i = 0; i < currencyIds.length; i++) {
            uint16 currencyId = currencyIds[i];
            // ensure currency ids are unique and sorted
            if (i != 0 && currencyIds[i - 1] < currencyId) {
                revert CurrencyIdsNeedToBeSorted();
            }

            // Rebalance each of the currencies provided.
            try NOTIONAL.rebalance(currencyId) {} catch (bytes memory reason) {
                failedRebalanceMap[currencyId] = uint32(block.timestamp);
                emit RebalancingFailed(currencyId, reason);
            }
        }
    }

    function checkRebalance()
        external
        returns (bool canExec, bytes memory execPayload)
    {
        uint16[] memory currencyIds = NOTIONAL.checkRebalance();

        // skip any currency that failed in previous rebalance that
        // happened after block.timestamp - DELAY_AFTER_FAILURE period
        uint16 numOfCurrencyIdsToProcess = 0;
        for (uint256 i = 0; i < currencyIds.length; i++) {
            if (
                failedRebalanceMap[currencyIds[i]] + DELAY_AFTER_FAILURE <
                block.timestamp
            ) {
                currencyIds[numOfCurrencyIdsToProcess++] = currencyIds[i];
            }
        }

        if (numOfCurrencyIdsToProcess > 0) {
            uint16[] memory currencyIdsToProcess = new uint16[](
                numOfCurrencyIdsToProcess
            );
            for (uint256 i = 0; i < numOfCurrencyIdsToProcess; i++) {
                currencyIdsToProcess[i] = currencyIds[i];
            }
            canExec = true;
            execPayload = abi.encodeWithSelector(
                RebalanceAll.rebalanceAll.selector,
                currencyIdsToProcess
            );
        }
    }
}