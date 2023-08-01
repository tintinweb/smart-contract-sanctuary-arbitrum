// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../interfaces/IERC20.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IRateModel} from "../interfaces/IRateModel.sol";
import {IInvestor} from "../interfaces/IInvestor.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

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

    function strategies(address investor, uint256[] calldata indexes) public view returns (address[] memory addresses, uint256[] memory statuses, uint256[] memory slippages, uint256[] memory caps, uint256[] memory tvls) {
        IInvestor i = IInvestor(investor);
        uint256 l = indexes.length;
        addresses = new address[](l);
        statuses = new uint256[](l);
        slippages = new uint256[](l);
        caps = new uint256[](l);
        tvls = new uint256[](l);
        for (uint256 j = 0; j < l; j++) {
            IStrategy s = IStrategy(i.strategies(indexes[j]));
            addresses[j] = address(s);
            statuses[j] = s.status();
            slippages[j] = s.slippage();
            caps[j] = s.cap();
            tvls[j] = s.rate(s.totalShares());
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IInvestor {
    function nextPosition() external view returns (uint256);
    function strategies(uint256) external view returns (address);
    function positions(uint256) external view returns (address, address, uint256, uint256, uint256, uint256, uint256);
    function life(uint256) external view returns (uint256);
    function earn(address, address, uint256, uint256, uint256, bytes calldata) external returns (uint256);
    function edit(uint256, int256, int256, bytes calldata) external;
    function kill(uint256, bytes calldata) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IStrategy {
    function name() external view returns (string memory);
    function cap() external view returns (uint256);
    function status() external view returns (uint256);
    function totalShares() external view returns (uint256);
    function slippage() external view returns (uint256);
    function rate(uint256) external view returns (uint256);
    function mint(address, uint256, bytes calldata) external returns (uint256);
    function burn(address, uint256, bytes calldata) external returns (uint256);
    function exit(address str) external;
    function move(address old) external;
}