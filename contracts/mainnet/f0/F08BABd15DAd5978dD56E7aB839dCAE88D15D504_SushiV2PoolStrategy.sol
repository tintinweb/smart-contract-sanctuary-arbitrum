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

pragma solidity 0.8.24;

interface IMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    function pendingSushi(
        uint256 _pid,
        address _user
    ) external view returns (uint256 pending);

    function userInfo(
        uint256 _pid,
        address _user
    ) external view returns (uint256 amount, int256 rewardDebt);

    function SUSHI() external view returns (address);
}

pragma solidity 0.8.24;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../interfaces/IUniversalOracle.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IMiniChefV2.sol";

contract SushiV2PoolStrategy {
    IUniswapV2Pair public sushiSwapV2Pool;
    IUniversalOracle public universalOracle;
    IMiniChefV2 public miniChefV2;
    uint256 public poolId;
    address[] public tokens;
    address usdc;

    constructor(
        address _sushiSwapV2Pool,
        address _miniChefV2,
        uint256 _poolId,
        address _universalOracle,
        address _usdc
    ) {
        sushiSwapV2Pool = IUniswapV2Pair(_sushiSwapV2Pool);
        miniChefV2 = IMiniChefV2(_miniChefV2);
        universalOracle = IUniversalOracle(_universalOracle);
        poolId = _poolId;
        usdc = _usdc;
        address token0 = IUniswapV2Pair(_sushiSwapV2Pool).token0();
        address token1 = IUniswapV2Pair(_sushiSwapV2Pool).token1();
        address rewardToken = IMiniChefV2(_miniChefV2).SUSHI();
        tokens = [token0, token1, rewardToken];
    }

    function getBalance(address strategist) external view returns (uint256) {
        uint256 strategistLpBalance = sushiSwapV2Pool.balanceOf(strategist);
        (uint256 strategistLpBalanceInChef, ) = miniChefV2.userInfo(
            poolId,
            strategist
        );
        uint256 rewardsInSushi;
        if (strategistLpBalanceInChef > 0) {
            rewardsInSushi = miniChefV2.pendingSushi(poolId, strategist);
        }
        uint256 lpTotalSupply = sushiSwapV2Pool.totalSupply();
        (uint112 reserve0, uint112 reserve1, ) = sushiSwapV2Pool.getReserves();

        uint256 partInToken0 = (reserve0 *
            (strategistLpBalance + strategistLpBalanceInChef)) / lpTotalSupply;

        uint256 partInToken1 = (reserve1 *
            (strategistLpBalance + strategistLpBalanceInChef)) / lpTotalSupply;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = partInToken0;
        amounts[1] = partInToken1;
        amounts[2] = rewardsInSushi;

        uint256 usdcPrice = universalOracle.getValues(tokens, amounts, usdc);

        return usdcPrice;
    }
}