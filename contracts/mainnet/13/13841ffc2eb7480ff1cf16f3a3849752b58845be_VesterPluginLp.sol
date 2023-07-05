// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {IStrategyHelper} from "./interfaces/IStrategyHelper.sol";

contract VesterPluginLp {
    IStrategyHelper public strategyHelper;
    address public lpToken;
    uint256 public slippage;

    constructor(address _strategyHelper, address _lpToken, uint256 _slippage) {
        strategyHelper = IStrategyHelper(_strategyHelper);
        lpToken = _lpToken;
        slippage = _slippage;
    }

    function onClaim(address from, uint256, address token, uint256 amount) external {
        IERC20(token).approve(address(strategyHelper), amount);
        strategyHelper.swap(token, lpToken, amount, slippage, from);
    }

    function rescueToken(address token, uint256 amount) external {
        IERC20(token).transfer(msg.sender, amount);
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
    function paths(address, address) external returns (address venue, bytes memory path);
}

interface IStrategyHelperUniswapV3 {
    function swap(address ast, bytes calldata path, uint256 amt, uint256 min, address to) external;
}