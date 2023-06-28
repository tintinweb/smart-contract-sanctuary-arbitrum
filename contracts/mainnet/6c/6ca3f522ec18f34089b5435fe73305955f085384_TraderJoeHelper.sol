// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IStrategyHelper} from "../interfaces/IStrategyHelper.sol";

interface ITraderJoePool {
    function getTokenX() external view returns (address);
    function getTokenY() external view returns (address);
    function getActiveId() external view returns (uint24);
    function getBin(uint24) external view returns (uint128, uint128);
    function getBinStep() external view returns (uint16);
}

contract TraderJoeHelper {
    IStrategyHelper strategyHelper;

    constructor(address _strategyHelper) {
        strategyHelper = IStrategyHelper(_strategyHelper);
    }

    function activeBinInfo(address pool) public returns (uint256) {
        ITraderJoePool p = ITraderJoePool(pool);
        uint256 value = 0;
        uint24 activeId = p.getActiveId();
        uint24 step = uint24(p.getBinStep());
        for (uint24 i = 0; i < 3; i++) {
            (uint128 reserveX, uint128 reserveY) = p.getBin(activeId - (1 * step) + (i * step));
            uint256 valueX = strategyHelper.value(p.getTokenX(), uint256(reserveX));
            uint256 valueY = strategyHelper.value(p.getTokenY(), uint256(reserveY));
            value += valueX + valueY;
        }
        return value / 5;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IStrategyHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256);
    function paths(address, address) external returns (address venue, bytes memory path);
}

interface IStrategyHelperUniswapV3 {
    function swap(address ast, bytes calldata path, uint256 amt, uint256 min, address to) external;
}