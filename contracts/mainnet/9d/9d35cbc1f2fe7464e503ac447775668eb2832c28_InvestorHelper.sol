// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IInvestor} from "./interfaces/IInvestor.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IRateModel} from "./interfaces/IRateModel.sol";

contract InvestorHelper {
    error TransferFailed();

    uint256 private constant ONE_YEAR = 31536000;
    IInvestor public immutable i;

    constructor(address _i) {
        i = IInvestor(_i);
    }

    function aggregate(address[] memory targets, bytes[] memory data) public returns (uint256, bytes[] memory) {
        bytes[] memory returnData = new bytes[](targets.length);
        for (uint256 j = 0; j < targets.length; j++) {
            (bool success, bytes memory ret) = targets[j].call(data[j]);
            require(success);
            returnData[j] = ret;
        }
        return (block.number, returnData);
    }

    function peekPoolInfos(address[] calldata pools)
        external
        view
        returns (
            address[] memory,
            bool[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        address[] memory asset = new address[](pools.length);
        bool[] memory paused = new bool[](pools.length);
        uint256[] memory borrowMin = new uint256[](pools.length);
        uint256[] memory borrowFactor = new uint256[](pools.length);
        uint256[] memory liquidationFactor = new uint256[](pools.length);
        uint256[] memory amountCap = new uint256[](pools.length);
        for (uint256 j = 0; j < pools.length; j++) {
            IPool pool = IPool(pools[j]);
            asset[j] = pool.asset();
            paused[j] = pool.paused();
            borrowMin[j] = pool.borrowMin();
            borrowFactor[j] = pool.borrowFactor();
            liquidationFactor[j] = pool.liquidationFactor();
            amountCap[j] = pool.amountCap();
        }
        return (asset, paused, borrowMin, borrowFactor, liquidationFactor, amountCap);
    }

    function peekPools(address[] calldata pools)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory index = new uint256[](pools.length);
        uint256[] memory share = new uint256[](pools.length);
        uint256[] memory supply = new uint256[](pools.length);
        uint256[] memory borrow = new uint256[](pools.length);
        uint256[] memory rate = new uint256[](pools.length);
        uint256[] memory price = new uint256[](pools.length);
        for (uint256 j = 0; j < pools.length; j++) {
            IPool pool = IPool(pools[j]);
            index[j] = pool.getUpdatedIndex();
            share[j] = pool.totalSupply();
            borrow[j] = pool.totalBorrow() * index[j] / 1e18;
            supply[j] = borrow[j] + IERC20(pool.asset()).balanceOf(address(pool));
            if (supply[j] > 0) rate[j] = IRateModel(pool.rateModel()).rate(borrow[j] * 1e18 / supply[j]);
            IOracle oracle = IOracle(pool.oracle());
            price[j] = uint256(oracle.latestAnswer()) * 1e18 / (10 ** oracle.decimals());
        }
        return (index, share, supply, borrow, rate, price);
    }

    function peekPosition(uint256 id)
        external
        view
        returns (
            address pol,
            uint256 str,
            uint256 sha,
            uint256 bor,
            uint256 shaval,
            uint256 borval,
            uint256 lif,
            uint256 amt,
            uint256 price
        )
    {
        (, pol, str,, amt, sha, bor) = i.positions(id);
        lif = i.life(id);
        shaval = IStrategy(i.strategies(str)).rate(sha);
        borval = bor * IPool(pol).getUpdatedIndex() / 1e18;
        IOracle o = IOracle(IPool(pol).oracle());
        price = uint256(o.latestAnswer()) * 1e18 / (10 ** o.decimals());
    }

    function lifeBatched(uint256[] calldata positionIds) external view returns (uint256[] memory) {
        uint256 posLen = positionIds.length;
        uint256[] memory lifeArr = new uint256[](posLen);
        for (uint256 j = 0; j < posLen; j++) {
            (,,,,,, uint256 borrow) = i.positions(positionIds[j]);
            if (borrow == 0) {
                lifeArr[j] = 0;
            } else {
                lifeArr[j] = i.life(positionIds[j]);
            }
        }
        return lifeArr;
    }

    function killBatched(uint256[] calldata ids, bytes[] calldata dat, address usr) external {
        for (uint256 j = 0; j < ids.length; j++) {
            (, address pol,,,,,) = i.positions(ids[j]);
            address ast = IPool(pol).asset();
            address(i).call(abi.encodeWithSelector(IInvestor.kill.selector, ids[j], dat[j]));
            uint256 bal = IERC20(ast).balanceOf(address(this));
            if (bal > 0) push(ast, usr, bal);
        }
    }

    function push(address ast, address usr, uint256 amt) internal {
        if (!IERC20(ast).transfer(usr, amt)) revert TransferFailed();
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

interface IInvestor {
    function strategies(uint256) external view returns (address);
    function positions(uint256) external view returns (address, address, uint256, uint256, uint256, uint256, uint256);
    function life(uint256) external view returns (uint256);
    function earn(address, address, uint256, uint256, uint256, bytes calldata) external returns (uint256);
    function edit(uint256, int256, int256, bytes calldata) external;
    function kill(uint256, bytes calldata) external;
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
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IStrategy {
    function name() external view returns (string memory);
    function rate(uint256) external view returns (uint256);
    function mint(address, uint256, bytes calldata) external returns (uint256);
    function burn(address, uint256, bytes calldata) external returns (uint256);
    function exit(address str) external;
    function move(address old) external;
}