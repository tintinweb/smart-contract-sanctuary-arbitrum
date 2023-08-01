// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../interfaces/IERC20.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IRateModel} from "../interfaces/IRateModel.sol";

contract Helper {
    function pool(address pool) public view returns (bool paused, uint256 borrowMin, uint256 amountCap, uint256 index, uint256 shares, uint256 borrow, uint256 supply, uint256 rate, uint256 price) {
        IPool p = IPool(pool);
        paused = p.paused();
        borrowMin = p.borrowMin();
        amountCap = p.amountCap();
        index = p.getUpdatedIndex();
        shares = p.totalSupply();
        borrow = p.totalBorrow() * index / 1e18;
        supply = borrow + IERC20(p.asset()).balanceOf(pool);
        {
            IRateModel rm = IRateModel(p.rateModel());
            rate = supply == 0 ? 0 : rm.rate(borrow * 1e18 / supply);
        }
        {
            IOracle oracle = IOracle(p.oracle());
            price = uint256(oracle.latestAnswer()) * 1e18 / (10 ** oracle.decimals());
        }
    }

    function rateModel(address pool) public view returns (uint256, uint256, uint256, uint256) {
        IPool p = IPool(pool);
        IRateModel rm = IRateModel(p.rateModel());
        return (rm.kink(), rm.base(), rm.low(), rm.high());
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

interface IPool {
    function paused() external view returns (bool);
    function asset() external view returns (address);
    function oracle() external view returns (address);
    function rateModel() external view returns (address);
    function borrowMin() external view returns (uint256);
    function borrowFactor() external view returns (uint256);
    function liquidationFactor() external view returns (uint256);
    function amountCap() external view returns (uint256);
    function index() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalBorrow() external view returns (uint256);
    function getUtilization() external view returns (uint256);
    function getUpdatedIndex() external view returns (uint256);
    function mint(uint256, address) external;
    function burn(uint256, address) external;
    function borrow(uint256) external returns (uint256);
    function repay(uint256) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRateModel {
    function rate(uint256) external view returns (uint256);
    function kink() external view returns (uint256);
    function base() external view returns (uint256);
    function low() external view returns (uint256);
    function high() external view returns (uint256);
}