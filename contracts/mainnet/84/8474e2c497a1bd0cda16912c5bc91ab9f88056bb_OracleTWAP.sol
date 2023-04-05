// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {IOracle} from "./interfaces/IOracle.sol";

contract OracleTWAP {
    IOracle public oracle;
    int256[4] public prices;
    uint256 public lastIndex;
    uint256 public lastTimestamp;
    uint256 public constant updateInterval = 30 minutes;

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
        int256 price = currentPrice();
        prices = [price, price, price, price];
        lastTimestamp = block.timestamp;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestAnswer() external view returns (int256) {
      require(block.timestamp < lastTimestamp + (updateInterval * 2), "stale price");
      int256 price = (prices[0] + prices[1] + prices[2] + prices[3]) / 4;
      return price;
    }

    function update() external {
        require(block.timestamp > lastTimestamp + updateInterval, "before next update");
        lastIndex = (lastIndex + 1) % 4;
        prices[lastIndex] = currentPrice();
        lastTimestamp = block.timestamp;
    }

    function currentPrice() public view returns (int256) {
        return oracle.latestAnswer() * 1e18 / int256(10 ** oracle.decimals());
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