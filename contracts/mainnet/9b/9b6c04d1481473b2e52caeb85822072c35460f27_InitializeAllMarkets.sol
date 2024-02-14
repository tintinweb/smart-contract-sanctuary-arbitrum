// SPDX-License-Identifier: BSUL-1.1
pragma solidity =0.8.19;

interface NotionalProxy {
    function initializeMarkets(uint16 currencyId, bool isFirstInit) external;

    function getMaxCurrencyId() external view returns (uint16);

    function nTokenAddress(uint16 currencyId) external view returns (address);
}

contract InitializeAllMarkets {
    event MarketInitializationFailed(uint16 currencyId);

    error MarketsAlreadyInitialized();

    uint256 public constant QUARTER = 7776000;
    NotionalProxy public immutable NOTIONAL;
    uint256 public lastInitializedQuarter;

    constructor(address notionalAddress) {
        NOTIONAL = NotionalProxy(notionalAddress);
        lastInitializedQuarter = block.timestamp / QUARTER;
    }

    function initializeAllMarkets() external {
        uint256 currentQuarter = block.timestamp / QUARTER;
        if (block.timestamp / QUARTER <= lastInitializedQuarter) {
            revert MarketsAlreadyInitialized();
        }

        uint16 maxCurrency = NOTIONAL.getMaxCurrencyId();
        for (uint16 i = 1; i <= maxCurrency; i++) {
            try NOTIONAL.nTokenAddress(i) {
                try NOTIONAL.initializeMarkets(i, false) {} catch {
                    emit MarketInitializationFailed(i);
                }
            }  catch {}
        }
        lastInitializedQuarter = currentQuarter;
    }

    function checkInitializeAllMarkets()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = lastInitializedQuarter < block.timestamp / QUARTER;
        execPayload = "";
    }
}