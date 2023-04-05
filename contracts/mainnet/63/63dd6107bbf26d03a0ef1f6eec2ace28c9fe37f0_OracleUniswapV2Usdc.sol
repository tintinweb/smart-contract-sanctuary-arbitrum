// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IPairUniV2} from "./interfaces/IPairUniV2.sol";

// WARNING: This oracle is not manipulation resistant, use with OracleTWAP in front
contract OracleUniswapV2Usdc {
    IPairUniV2 public pair;
    address public usdc;
    address public token0;
    address public token1;

    constructor(address _pair, address _usdc) {
        pair = IPairUniV2(_pair);
        usdc = _usdc;
        token0 = pair.token0();
        token1 = pair.token1();
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestAnswer() external view returns (int256) {
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        if (token0 == usdc) {
            return int256((reserve0 * 1e18 / 1e6) * 1e18 / reserve1);
        } else {
            return int256((reserve1 * 1e18 / 1e6) * 1e18 / reserve0);
        }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPairUniV2 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function mint(address) external returns (uint256 liquidity);
    function burn(address) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256, uint256, address, bytes calldata) external;
    function skim(address to) external;
}