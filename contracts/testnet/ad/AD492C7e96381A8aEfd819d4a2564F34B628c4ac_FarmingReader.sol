// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFarmingPoolV1 {
    function assetToReward(
        address
    )
        external
        view
        returns (
            uint256 virtualRewards,
            uint256 claimed,
            uint256 tokensPerDay,
            uint256 lockedRate,
            uint256 startTime
        );
}

interface IFarmingPool {
    function assetToReward(
        address
    )
        external
        view
        returns (
            uint256 virtualRewards,
            uint256 claimed,
            uint256 tokensPerDay,
            uint256 lockedRate,
            uint256 startTime,
            uint256 oldRate,
            uint256 lockedPeriod,
            uint256 nextReward
        );

    function availableToClaim(
        address asset,
        address user
    ) external view returns (uint256);

    function getRewardAssets() external view returns (address[] memory);

    function totalLp() external view returns (uint256);

    function totalLocked() external view returns (uint256);

    function totalWithdraw() external view returns (uint256);
}

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract FarmingReader {
    struct Reward {
        uint256 availableToClaim;
        uint256 tokensPerDay;
        address reward;
    }

    struct FarmingPoolData {
        uint256 totalLp;
        Reward[] rewards;
    }

    struct LiquidityPoolData {
        uint256 totalSupply;
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
    }

    function batchViewData(
        address[] calldata farmingPools,
        bool[] memory oldVersions,
        IUniswapV2Pair[] calldata liquidityPools,
        address user
    )
        public
        view
        returns (FarmingPoolData[] memory, LiquidityPoolData[] memory)
    {
        require(
            farmingPools.length == oldVersions.length,
            "FarmingReader: farmingPools and oldVersions length mismatch"
        );

        uint256 farmingLength = farmingPools.length;
        uint256 liquidityLength = farmingPools.length;

        FarmingPoolData[] memory farmingPoolData = new FarmingPoolData[](
            farmingLength
        );
        LiquidityPoolData[] memory liquidityPoolData = new LiquidityPoolData[](
            liquidityLength
        );

        for (uint i; i < farmingLength; ) {
            farmingPoolData[i] = viewFarmingData(
                farmingPools[i],
                oldVersions[i],
                user
            );

            unchecked {
                ++i;
            }
        }

        for (uint i; i < liquidityLength; ) {
            liquidityPoolData[i] = viewLiquidityData(liquidityPools[i]);

            unchecked {
                ++i;
            }
        }

        return (farmingPoolData, liquidityPoolData);
    }

    function viewFarmingData(
        address farmingPool,
        bool oldVersion,
        address user
    ) public view returns (FarmingPoolData memory) {
        address[] memory rewards = IFarmingPool(farmingPool).getRewardAssets();

        uint256 length = rewards.length;
        uint256 totalLp = IFarmingPool(farmingPool).totalLp();
        Reward[] memory userRewards = new Reward[](length);

        for (uint i; i < length; ) {
            uint256 tokensPerDay;

            if (oldVersion) {
                (, , tokensPerDay, , ) = IFarmingPoolV1(farmingPool)
                    .assetToReward(rewards[i]);
            } else {
                (, , tokensPerDay, , , , , ) = IFarmingPool(farmingPool)
                    .assetToReward(rewards[i]);
                totalLp +=
                    IFarmingPool(farmingPool).totalLocked() -
                    IFarmingPool(farmingPool).totalWithdraw();
            }

            userRewards[i] = Reward({
                tokensPerDay: tokensPerDay,
                availableToClaim: IFarmingPool(farmingPool).availableToClaim(
                    rewards[i],
                    user
                ),
                reward: rewards[i]
            });

            unchecked {
                ++i;
            }
        }

        return FarmingPoolData({totalLp: totalLp, rewards: userRewards});
    }

    function viewLiquidityData(
        IUniswapV2Pair liquidityPool
    ) public view returns (LiquidityPoolData memory) {
        uint256 totalSupply = liquidityPool.totalSupply();
        address token0 = liquidityPool.token0();
        address token1 = liquidityPool.token1();
        (uint256 reserve0, uint256 reserve1, ) = liquidityPool.getReserves();

        return
            LiquidityPoolData(totalSupply, token0, token1, reserve0, reserve1);
    }
}