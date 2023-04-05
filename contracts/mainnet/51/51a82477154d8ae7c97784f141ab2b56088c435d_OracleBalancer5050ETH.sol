// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IStrategyHelper} from "./interfaces/IStrategyHelper.sol";
import {IBalancerPool} from "./interfaces/IBalancerPool.sol";
import {IBalancerVault} from "./interfaces/IBalancerVault.sol";

contract OracleBalancer5050ETH {
    IBalancerVault public vault;
    IBalancerPool public pool;
    IOracle public ethOracle;
    uint256 public tokenIndex;
    uint256 public wethIndex;

    constructor(address _vault, address _pool, address _ethOracle, address _weth) {
        vault = IBalancerVault(_vault);
        pool = IBalancerPool(_pool);
        ethOracle = IOracle(_ethOracle);
        (address[] memory poolTokens,,) = vault.getPoolTokens(IBalancerPool(pool).getPoolId());
        uint256[] memory weights = pool.getNormalizedWeights();
        require(poolTokens.length == 2, "pool has more than 2 tokens");
        require(weights[0] == 0.5e18 && weights[1] == 0.5e18, "pool weights not 50/50");
        if (poolTokens[0] == _weth) {
          tokenIndex = 1;
          wethIndex = 0;
        } else {
          tokenIndex = 0;
          wethIndex = 1;
        }
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestAnswer() external view returns (int256) {
        int256 ethPrice = ethOracle.latestAnswer() * 1e18 / int256(10 ** ethOracle.decimals());
        (, uint256[] memory balances,) = vault.getPoolTokens(IBalancerPool(pool).getPoolId());
        int256 tokenPrice = int256(balances[tokenIndex] * 1e18 / balances[wethIndex]);
        return int256(ethPrice * 1e18 / tokenPrice);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancerPool {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function getRate() external view returns (uint256);
    function getPoolId() external view returns (bytes32);
    function getNormalizedWeights() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancerVault {
    function getPoolTokens(bytes32) external view returns (address[] memory, uint256[] memory, uint256);

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request)
        external
        payable;

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request)
        external;

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        uint8 kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IStrategyHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256);
}