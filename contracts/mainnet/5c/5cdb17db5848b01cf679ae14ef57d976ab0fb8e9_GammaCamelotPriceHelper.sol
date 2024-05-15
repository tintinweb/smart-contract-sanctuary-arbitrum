// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../../../external/interfaces/strategies/arbitrum/gamma-camelot/IUniProxy.sol";
import "../../../external/interfaces/strategies/arbitrum/gamma-camelot/IClearingV2.sol";

library GammaCamelotPriceHelper {
    function getPrice(IUniProxy gammaUniProxy, address pool) external view returns (uint256 price) {
        IClearingV2 clearance = IClearingV2(gammaUniProxy.clearance());
        IClearingV2.Position memory p = clearance.positions(pool);

        price = clearance.checkPriceChange(
            pool,
            (p.twapOverride ? p.twapInterval : clearance.twapInterval()),
            (p.twapOverride ? p.priceThreshold : clearance.priceThreshold())
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniProxy {
    function deposit(uint256 deposit0, uint256 deposit1, address to, address pos, uint256[4] memory minIn)
        external
        returns (uint256 shares);

    function getDepositAmount(address pos, address token, uint256 _deposit)
        external
        view
        returns (uint256 amountStart, uint256 amountEnd);

    function clearance() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IClearingV2 {
    struct Position {
        bool customRatio;
        bool customTwap;
        bool ratioRemoved;
        bool depositOverride; // force custom deposit constraints
        bool twapOverride; // force twap check for hypervisor instance
        uint8 version;
        uint32 twapInterval; // override global twap
        uint256 priceThreshold; // custom price threshold
        uint256 deposit0Max;
        uint256 deposit1Max;
        uint256 maxTotalSupply;
        uint256 fauxTotal0;
        uint256 fauxTotal1;
        uint256 customDepositDelta;
    }

    function positions(address) external view returns (Position memory);
    function checkPriceChange(address, uint32, uint256) external view returns (uint256);
    function twapInterval() external view returns (uint32);
    function priceThreshold() external view returns (uint256);
}