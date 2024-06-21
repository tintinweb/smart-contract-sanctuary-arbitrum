// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TickMath} from "./vendor/TickMath.sol";
import {LiquidityAmounts} from "./vendor/LiquidityAmounts.sol";

contract StrategyCamelotV3 {
    string public name;
    uint256 public totalShares = 1_000_000;
    uint256 public slippage = 500;
    bool internal entered;
    IERC20 public asset;
    IStrategyHelper public strategyHelper;
    mapping(address => bool) public exec;
    mapping(address => bool) public keepers;

    IXGrail public immutable xgrail;
    IStrategyHelperUniswapV3 public immutable strategyHelperUniswapV3;
    IUniProxy public immutable uniProxy;
    IQuoter public immutable quoter;
    IHypervisor public immutable hypervisor;
    address public targetAsset;
    INFTPool public nftPool;
    INitroPool public nitroPool;
    uint256 public tokenId;
    uint32 public twapPeriod = 43200;
    address public rewardToken1;
    address public rewardToken2;
    address public rewardToken3;

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event Mint(uint256 amount, uint256 shares);
    event Burn(uint256 amount, uint256 shares);
    event Kill(uint256 amount, uint256 shares);
    event Earn(uint256 tvl, uint256 profit);

    error NotKeeper();
    error InvalidFile();
    error NoReentering();
    error Unauthorized();
    error PriceSlipped();
    error WrongTargetAsset();
    error TwapPeriodTooLong();
    error TokenIdNeededFirst();

    constructor(
        address _asset,
        address _strategyHelper,
        address _xgrail,
        address _strategyHelperUniswapV3,
        address _uniProxy,
        address _quoter,
        address _hypervisor,
        address _nftPool,
        address _targetAsset
    ) {
        exec[msg.sender] = true;
        asset = IERC20(_asset);
        strategyHelper = IStrategyHelper(_strategyHelper);
        xgrail = IXGrail(_xgrail);
        strategyHelperUniswapV3 = IStrategyHelperUniswapV3(_strategyHelperUniswapV3);
        uniProxy = IUniProxy(_uniProxy);
        quoter = IQuoter(_quoter);
        hypervisor = IHypervisor(_hypervisor);
        nftPool = INFTPool(_nftPool);
        targetAsset = _targetAsset;
        name = string(abi.encodePacked("Camelot V3 ", hypervisor.token0().symbol(), "/", hypervisor.token1().symbol()));

        if (_targetAsset != address(hypervisor.token0()) && _targetAsset != address(hypervisor.token1())) {
            revert WrongTargetAsset();
        }
    }

    modifier loop() {
        if (entered) revert NoReentering();
        entered = true;
        _;
        entered = false;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") {
            exec[data] = !exec[data];
        } else if (what == "keeper") {
            keepers[data] = !keepers[data];
        } else if (what == "rewardToken1") {
            rewardToken1 = data;
        } else if (what == "rewardToken2") {
            rewardToken2 = data;
        } else if (what == "rewardToken3") {
            rewardToken3 = data;
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "slippage") {
            slippage = data;
        } else if (what == "twapPeriod") {
            if (data > uint256(int256(type(int32).max))) revert TwapPeriodTooLong();
            twapPeriod = uint32(twapPeriod);
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function setNitroPool(address _nitroPool) external auth {
        if (tokenId == 0) revert TokenIdNeededFirst();
        if (_nitroPool == address(0)) {
            nitroPool.withdraw(tokenId);
        } else {
            nftPool.safeTransferFrom(address(this), _nitroPool, tokenId, "");
        }
        nitroPool = INitroPool(_nitroPool);
    }

    function xgrailRedeem(uint256 amount, uint256 duration) external auth {
        xgrail.redeem(amount, duration);
    }

    function xgrailFinalizeRedeem(uint256 index) external auth {
        xgrail.finalizeRedeem(index);
    }

    function mint(uint256 amount) external auth loop returns (uint256) {
        asset.transferFrom(msg.sender, address(this), amount);
        address tgtAst = targetAsset;
        uint256 slp = slippage;
        uint256 tma = totalManagedAssets();

        asset.approve(address(strategyHelper), amount);
        strategyHelper.swap(address(asset), tgtAst, amount, slp, address(this));

        uint256 liq;
        {
            uint256 tgtAmt = IERC20(tgtAst).balanceOf(address(this));
            (uint256 amt0, uint256 amt1) = quoteAndSwap(tgtAst, tgtAmt, slp);
            address hyp = address(hypervisor);
            hypervisor.token0().approve(hyp, amt0);
            hypervisor.token1().approve(hyp, amt1);
            liq = uniProxy.deposit(amt0, amt1, address(this), hyp, [uint256(0), 0, 0, 0]);
            stake(liq);
        }

        uint256 val = valueLiquidity() * liq / totalManagedAssets();
        if (val < strategyHelper.value(address(asset), amount) * (10000 - slp) / 10000) revert PriceSlipped();
        uint256 shares = tma == 0 ? liq : liq * totalShares / tma;

        totalShares += shares;
        emit Mint(amount, shares);
        return shares;
    }

    function burn(uint256 shares) external auth loop returns (uint256) {
        uint256 tma = totalManagedAssets();
        uint256 amt = (shares * tma) / totalShares;
        uint256 val = valueLiquidity() * amt / tma;
        unstake(amt);
        (uint256 amt0, uint256 amt1) = hypervisor.withdraw(amt, address(this), address(this), [uint256(0), 0, 0, 0]);

        address strategyHelperAddress = address(strategyHelper);
        hypervisor.token0().approve(strategyHelperAddress, amt0);
        hypervisor.token1().approve(strategyHelperAddress, amt1);

        uint256 bal;
        uint256 slp = slippage;
        bal += strategyHelper.swap(address(hypervisor.token0()), address(asset), amt0, slp, msg.sender);
        bal += strategyHelper.swap(address(hypervisor.token1()), address(asset), amt1, slp, msg.sender);

        if (strategyHelper.value(address(asset), bal) < val * (10000 - slp) / 10000) revert PriceSlipped();

        totalShares -= shares;
        emit Burn(bal, shares);
        return bal;
    }

    function kill(uint256 shares, address to) external auth loop returns (bytes memory) {
        uint256 amount = shares * totalManagedAssets() / totalShares;
        unstake(amount);
        hypervisor.transfer(to, amount);

        totalShares -= shares;
        emit Kill(amount, shares);

        address[] memory assets = new address[](1);
        assets[0] = address(hypervisor);
        return abi.encode(bytes32("camelotv3"), assets);
    }

    function stake(uint256 amount) internal {
        IERC20(address(hypervisor)).approve(address(nftPool), amount);
        if (tokenId != 0 && totalManagedAssets() > 0) {
            nftPool.addToPosition(tokenId, amount);
        } else {
            // Clear the token if it's already set from a position that
            // went to 0 and got burned
            if (tokenId != 0) tokenId = 0;
            nftPool.createPosition(amount, 0);
        }
    }

    function unstake(uint256 amount) internal {
        if (address(nitroPool) != address(0)) {
            nitroPool.withdraw(tokenId);
        }
        nftPool.withdrawFromPosition(tokenId, amount);
        if (address(nitroPool) != address(0)) {
            nftPool.safeTransferFrom(address(this), address(nitroPool), tokenId, "");
        }
    }

    function earn() external payable loop {
        if (!keepers[msg.sender]) revert NotKeeper();
        uint256 before = rate(totalShares);

        if (tokenId == 0) return;
        uint256 slp = slippage;
        address tgtAsset = targetAsset;
        nftPool.harvestPosition(tokenId);
        if (address(nitroPool) != address(0)) {
            nitroPool.harvest();
        }

        if (rewardToken1 != address(0)) {
            uint256 balance = IERC20(rewardToken1).balanceOf(address(this));
            if (strategyHelper.value(rewardToken1, balance) > 1e18) {
                IERC20(rewardToken1).approve(address(strategyHelper), balance);
                strategyHelper.swap(rewardToken1, tgtAsset, balance, slp, address(this));
            }
        }

        if (rewardToken2 != address(0)) {
            uint256 balance = IERC20(rewardToken2).balanceOf(address(this));
            if (strategyHelper.value(rewardToken2, balance) > 1e18) {
                IERC20(rewardToken2).approve(address(strategyHelper), balance);
                strategyHelper.swap(rewardToken2, tgtAsset, balance, slp, address(this));
            }
        }

        if (rewardToken3 != address(0)) {
            uint256 balance = IERC20(rewardToken3).balanceOf(address(this));
            if (strategyHelper.value(rewardToken3, balance) > 1e18) {
                IERC20(rewardToken3).approve(address(strategyHelper), balance);
                strategyHelper.swap(rewardToken3, tgtAsset, balance, slp, address(this));
            }
        }

        uint256 amt = IERC20(tgtAsset).balanceOf(address(this));
        if (strategyHelper.value(tgtAsset, amt) < 1e18) return;
        (uint256 amt0, uint256 amt1) = quoteAndSwap(tgtAsset, amt, slp);
        address h = address(hypervisor);
        IHypervisor(h).token0().approve(h, amt0);
        IHypervisor(h).token1().approve(h, amt1);
        stake(uniProxy.deposit(amt0, amt1, address(this), h, [uint256(0), 0, 0, 0]));

        uint256 current = rate(totalShares);
        emit Earn(current, current - min(current, before));
    }

    function exit(address strategy) external auth {
        if (tokenId == 0) return;
        if (address(nitroPool) != address(0)) {
            nitroPool.withdraw(tokenId);
        }
        nftPool.safeTransferFrom(address(this), strategy, tokenId, "");
    }

    function move(address old) external auth {
        nftPool = StrategyCamelotV3(old).nftPool();
        nitroPool = StrategyCamelotV3(old).nitroPool();
        tokenId = StrategyCamelotV3(old).tokenId();
        if (address(nitroPool) != address(0)) {
            nftPool.safeTransferFrom(address(this), address(nitroPool), tokenId, "");
        }
    }

    function rate(uint256 shares) public view returns (uint256) {
        return shares * valueLiquidity() / totalShares;
    }

    function quoteAndSwap(address target, uint256 amt, uint256 slp) private returns (uint256 amt0, uint256 amt1) {
        address token0 = address(hypervisor.token0());
        address token1 = address(hypervisor.token1());
        if (target == token0) {
            bytes memory path = abi.encodePacked(token0, token1);
            uint256 ratioDeposit;
            {
                (uint256 amt1Min, uint256 amt1Max) = uniProxy.getDepositAmount(address(hypervisor), token0, amt);
                ratioDeposit = ((amt1Min + amt1Max) / 2) * 1e18 / amt;
            }
            uint256 ratioSwap = quoter.quoteExactInput(path, amt) * 1e18 / amt;
            // (amt - x) / (x / ratioSwap) = ratioDeposit
            // (amt * ratioSwap) - (x * ratioSwap) = ratioDeposit * x
            // x = amt * ratioSwap / (ratioSwap + ratioDeposit)
            uint256 amtSwap = amt * ratioSwap / (ratioSwap + ratioDeposit);
            uint256 before = IERC20(token1).balanceOf(address(this));
            swap(token0, token1, path, amtSwap, slp);
            uint256 amt1 = IERC20(token1).balanceOf(address(this)) - before;
            return (amt - amtSwap, amt1);
        } else {
            bytes memory path = abi.encodePacked(token1, token0);
            uint256 ratioDeposit;
            {
                (uint256 amt0Min, uint256 amt0Max) = uniProxy.getDepositAmount(address(hypervisor), token1, amt);
                ratioDeposit = ((amt0Min + amt0Max) / 2) * 1e18 / amt;
            }
            uint256 ratioSwap = quoter.quoteExactInput(path, amt) * 1e18 / amt;
            uint256 amtSwap = amt * ratioDeposit / (ratioSwap + ratioDeposit);
            uint256 before = IERC20(token0).balanceOf(address(this));
            swap(token1, token0, path, amtSwap, slp);
            uint256 amt0 = IERC20(token0).balanceOf(address(this)) - before;
            return (amt0, amt - amtSwap);
        }
    }

    function swap(address inp, address out, bytes memory path, uint256 amt, uint256 slp) private {
        uint256 min = strategyHelper.convert(inp, out, amt) * (10000 - slp) / 10000;
        IERC20(inp).transfer(address(strategyHelperUniswapV3), amt);
        strategyHelperUniswapV3.swap(inp, path, amt, min, address(this));
    }

    function valueLiquidity() private view returns (uint256) {
        uint32 period = twapPeriod;
        uint32[] memory secondsAgos = new uint32[](2);

        secondsAgos[0] = period;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives,,,) = hypervisor.pool().getTimepoints(secondsAgos);
        uint160 midX96 = TickMath.getSqrtRatioAtTick(int24((tickCumulatives[1] - tickCumulatives[0]) / int32(period)));
        (uint256 bas0, uint256 bas1) = getPosition(midX96, hypervisor.baseLower(), hypervisor.baseUpper());
        (uint256 lim0, uint256 lim1) = getPosition(midX96, hypervisor.limitLower(), hypervisor.limitUpper());
        uint256 val0 = strategyHelper.value(
            address(hypervisor.token0()), bas0 + lim0 + hypervisor.token0().balanceOf(address(hypervisor))
        );
        uint256 val1 = strategyHelper.value(
            address(hypervisor.token1()), bas1 + lim1 + hypervisor.token1().balanceOf(address(hypervisor))
        );
        uint256 bal = totalManagedAssets();
        uint256 spl = hypervisor.totalSupply();

        val0 = val0 * bal / spl;
        val1 = val1 * bal / spl;

        return val0 + val1;
    }

    function totalManagedAssets() private view returns (uint256) {
        if (tokenId == 0) return 0;
        (uint256 amount,,,,,,,) = nftPool.getStakingPosition(tokenId);
        return amount;
    }

    function getPosition(uint160 midX96, int24 minTick, int24 maxTick) private view returns (uint256, uint256) {
        bytes32 key;
        address owner = address(hypervisor);
        assembly {
            key := or(shl(24, or(shl(24, owner), and(minTick, 0xFFFFFF))), and(maxTick, 0xFFFFFF))
        }
        (uint128 liq,,,, uint128 owed0, uint128 owed1) = IAlgebraPool(address(hypervisor.pool())).positions(key);
        (uint256 amt0, uint256 amt1) = LiquidityAmounts.getAmountsForLiquidity(
            midX96, TickMath.getSqrtRatioAtTick(minTick), TickMath.getSqrtRatioAtTick(maxTick), liq
        );

        return (amt0 + uint256(owed0), amt1 + uint256(owed1));
    }

    function onERC721Received(address, address, uint256 _tokenId, bytes calldata) external returns (bytes4) {
        if (msg.sender == address(nftPool) && tokenId == 0) {
            tokenId = _tokenId;
        }
        return StrategyCamelotV3.onERC721Received.selector;
    }

    function onNFTHarvest(address, address, uint256, uint256, uint256) public pure returns (bool) {
        return true;
    }

    function onNFTAddToPosition(address, uint256, uint256) public pure returns (bool) {
        return true;
    }

    function onNFTWithdraw(address, uint256, uint256) public pure returns (bool) {
        return true;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IERC20 {
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}

interface IStrategyHelper {
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256);
}

interface IStrategyHelperUniswapV3 {
    function swap(address ast, bytes calldata path, uint256 amt, uint256 min, address to) external;
}

interface IUniProxy {
    function deposit(uint256 deposit0, uint256 deposit1, address to, address pos, uint256[4] memory minIn) external returns (uint256 shares);
    function getDepositAmount(address pos, address token, uint256 deposit) external view returns (uint256 amountStart, uint256 amountEnd);
}

interface IQuoter {
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);
}

interface IHypervisor is IERC20 {
    function withdraw(uint256 shares, address to, address from, uint256[4] memory minAmounts) external returns (uint256 amount0, uint256 amount1);
    function pool() external view returns (IAlgebraPool);
    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);
    function totalSupply() external view returns (uint256);
    function baseLower() external view returns (int24);
    function baseUpper() external view returns (int24);
    function limitLower() external view returns (int24);
    function limitUpper() external view returns (int24);
}

interface INFTPool {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function createPosition(uint256 amount, uint256 lockDuration) external;
    function addToPosition(uint256 tokenId, uint256 amountToAdd) external;
    function withdrawFromPosition(uint256 tokenId, uint256 amountToWithdraw) external;
    function harvestPosition(uint256 tokenId) external;
    function getStakingPosition(uint256 tokenId) external view returns (
        uint256 amount, uint256 amountWithMultiplier, uint256 startLockTime,
        uint256 lockDuration, uint256 lockMultiplier, uint256 rewardDebt,
        uint256 boostPoints, uint256 totalMultiplier
    );
}

interface INitroPool {
    function harvest() external;
    function withdraw(uint256 tokenId) external;
}

interface IAlgebraPool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getTimepoints(uint32[] calldata secondsAgos) external view returns (
        int56[] memory tickCumulatives,
        uint160[] memory secondsPerLiquidityCumulatives,
        uint112[] memory volatilityCumulatives,
        uint256[] memory volumePerAvgLiquiditys
    );
    function positions(bytes32 key) external view returns (
        uint128 liquidityAmount,
        uint32 lastLiquidityAddTimestamp,
        uint256 innerFeeGrowth0Token,
        uint256 innerFeeGrowth1Token,
        uint128 fees0,
        uint128 fees1
    );
}

interface IXGrail {
  function redeem(uint256 xGrailAmount, uint256 duration) external;
  function finalizeRedeem(uint256 redeemIndex) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio =
                absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "./FullMath.sol";
import "./FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount0)
        internal
        pure
        returns (uint128 liquidity)
    {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount1)
        internal
        pure
        returns (uint128 liquidity)
    {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity)
        internal
        pure
        returns (uint256 amount0)
    {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96
            ) / sqrtRatioAX96;
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity)
        internal
        pure
        returns (uint256 amount1)
    {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}