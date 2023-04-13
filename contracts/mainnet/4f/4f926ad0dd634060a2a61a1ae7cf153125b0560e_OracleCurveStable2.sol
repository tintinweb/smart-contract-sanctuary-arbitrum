// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {IStrategyHelper} from "./interfaces/IStrategyHelper.sol";

interface ICurvePool {
    function coins(uint256 i) external view returns (address);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

contract OracleCurveStable2 {
    IStrategyHelper public strategyHelper;
    ICurvePool public pool;
    uint256 public index;
    IERC20 public tokenA;
    IERC20 public tokenB;

    constructor(address _strategyHelper, address _pool, uint256 _index) {
        strategyHelper = IStrategyHelper(_strategyHelper);
        pool = ICurvePool(_pool);
        index = _index;
        tokenA  = IERC20(pool.coins(index));
        tokenB  = IERC20(pool.coins((index + 1) % 2));
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestAnswer() external view returns (int256) {
        int128 i = int128(int256(index));
        // Price one unit of token (that we are pricing) converted to token (that it's paired with)
        uint256 amt = pool.get_dy(i, (i + 1) % 2, 10 ** tokenA.decimals());
        // Value the token it's paired with using it's oracle
        return int256(strategyHelper.value(address(tokenB), amt));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IStrategyHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256);
}