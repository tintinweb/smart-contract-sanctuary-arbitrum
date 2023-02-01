// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {IOracle} from "./interfaces/IOracle.sol";

contract OracleChainlinkETH {
    IOracle public oracle;
    IOracle public ethOracle;

    constructor(address _oracle, address _ethOracle) {
        oracle = IOracle(_oracle);
        ethOracle = IOracle(_ethOracle);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestAnswer() external view returns (int256) {
      int256 price = oracle.latestAnswer() * 1e18 / int256(10 ** oracle.decimals());
      return price * ethOracle.latestAnswer() / int256(10 ** ethOracle.decimals());
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