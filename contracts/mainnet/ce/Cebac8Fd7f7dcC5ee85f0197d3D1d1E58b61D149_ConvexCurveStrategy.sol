// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./interfaces/IBooster.sol";
import "./interfaces/ICurvePool.sol";
import "./interfaces/IBaseRewardPool.sol";
import "../interfaces/IUniversalOracle.sol";

contract ConvexCurveStrategy {
    IBooster public booster;
    ICurvePool public poolLpToken;
    IBaseRewardPool public rewardPool;
    IUniversalOracle public universalOracle;
    address public token0;
    uint256 public poolId;
    address public usdc;

    constructor(
        address _booster,
        uint256 _convexPoolId,
        address _universalOracle,
        address _usdc
    ) {
        booster = IBooster(_booster);
        poolId = _convexPoolId;
        (address lptoken, , address rewardsPool, , ) = IBooster(_booster)
            .poolInfo(_convexPoolId);
        poolLpToken = ICurvePool(lptoken);
        token0 = ICurvePool(lptoken).coins(0);
        rewardPool = IBaseRewardPool(rewardsPool);
        universalOracle = IUniversalOracle(_universalOracle);
        usdc = _usdc;
    }

    function getBalance(address strategist) external view returns (uint256) {
        uint256 lpBalanceInRewardPool = rewardPool.balanceOf(strategist);
        uint256 lpBalanceOnWallet = poolLpToken.balanceOf(strategist);

        uint256 totalRewardsTokens = rewardPool.rewardLength();
        uint256 totalRewardsInUsdc;

        for (uint256 i = 0; i < totalRewardsTokens; i++) {
            (address reward_token, uint256 reward_integral, ) = rewardPool
                .rewards(i);

            uint256 userIntegral = rewardPool.reward_integral_for(
                reward_token,
                strategist
            );
            if (userIntegral < reward_integral) {
                uint256 userClaimable = rewardPool.claimable_reward(
                    reward_token,
                    strategist
                );
                uint256 receiveable = userClaimable +
                    ((lpBalanceInRewardPool *
                        (reward_integral - userIntegral)) / 1e20);

                totalRewardsInUsdc += universalOracle.getValue(
                    reward_token,
                    receiveable,
                    usdc
                );
            }
        }

        uint256 lpInUsdc;
        if (lpBalanceOnWallet + lpBalanceInRewardPool > 0) {
            uint256 lpValueInToken0 = poolLpToken.calc_withdraw_one_coin(
                lpBalanceOnWallet + lpBalanceInRewardPool,
                0
            );

            lpInUsdc = universalOracle.getValue(token0, lpValueInToken0, usdc);
        }

        return lpInUsdc + totalRewardsInUsdc;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IBaseRewardPool {
    struct RewardType {
        address reward_token;
        uint256 reward_integral;
        uint256 reward_remaining;
    }

    function rewards(
        uint256 _rewardIndex
    )
        external
        view
        returns (
            address reward_token,
            uint256 reward_integral,
            uint256 reward_remaining
        );

    function rewardLength() external view returns (uint256);

    // mapping(address => mapping(address => uint256)) public reward_integral_for;// token -> account -> integral
    function reward_integral_for(
        address _token,
        address _account
    ) external view returns (uint256);

    // mapping(address => mapping(address => uint256)) public claimable_reward;//token -> account -> claimable
    function claimable_reward(
        address _token,
        address _account
    ) external view returns (uint256);

    function withdrawAndUnwrap(
        uint256 amount,
        bool claim
    ) external returns (bool);

    function stakingToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function getReward(
        address _account,
        bool _claimExtras
    ) external returns (bool);

    function rewardToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address gauge;
        address rewardsPool;
        bool shutdown;
        address factory;
    }

    // function poolInfo(uint256) external view returns (PoolInfo memory); // tuple(address,address,address,address,address,bool) returned

    function owner() external view returns (address);

    function feeToken() external view returns (address);

    function feeDistro() external view returns (address);

    function lockFees() external view returns (address);

    function stakerRewards() external view returns (address);

    function lockRewards() external view returns (address);

    function setVoteDelegate(address _voteDelegate) external;

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external returns (bool);

    function voteGaugeWeight(
        address[] calldata _gauge,
        uint256[] calldata _weight
    ) external returns (bool);

    function poolInfo(
        uint256 _pid
    )
        external
        view
        returns (
            address lptoken,
            address gauge,
            address rewardsPool,
            bool shutdown,
            address factory
        );

    function earmarkRewards(uint256 _pid) external returns (bool);

    function earmarkFees() external returns (bool);

    function isShutdown() external view returns (bool);

    function poolLength() external view returns (uint256);

    /// Extra functions in addition to base IBooster interface from Convex
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

interface ICurvePool {
    function decimals() external view returns (uint256);

    function price_oracle() external view returns (uint256);

    function price_oracle(uint256 k) external view returns (uint256);

    function stored_rates() external view returns (uint256[2] memory);

    function coins(uint256 i) external view returns (address);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(
        uint256 token_amount,
        int128 i
    ) external view returns (uint256);

    function remove_liquidity(
        uint256 token_amount,
        uint256[2] memory min_amounts
    ) external;

    function lp_price() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function claim_admin_fees() external;

    function withdraw_admin_fees() external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

interface IUniversalOracle {
    function getValue(
        address baseAsset,
        uint256 amount,
        address quoteAsset
    ) external view returns (uint256 value);

    function getValues(
        address[] calldata baseAssets,
        uint256[] calldata amounts,
        address quoteAsset
    ) external view returns (uint256);

    function WETH() external view returns (address);

    function isSupported(address asset) external view returns (bool);

    function getPriceInUSD(address asset) external view returns (uint256);
}