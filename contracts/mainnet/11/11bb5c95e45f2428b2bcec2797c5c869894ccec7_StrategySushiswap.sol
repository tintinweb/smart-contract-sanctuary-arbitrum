// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IStrategyHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function mint(address) external returns (uint256 liquidity);
    function burn(address) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256, uint256, address, bytes calldata) external;
    function skim(address to) external;
}

interface ISushiswapMiniChefV2 {
    function SUSHI() external view returns (address);
    function lpToken(uint256) external view returns (address);
    function pendingSushi(uint256, address) external view returns (uint256);
    function userInfo(uint256, address) external view returns (uint256, int256);
    function deposit(uint256, uint256, address) external;
    function withdraw(uint256, uint256, address) external;
    function harvest(uint256, address) external;
}

contract StrategySushiswap {
    string public name;
    uint256 public totalShares = 1_000_000;
    uint256 public slippage = 500;
    bool internal entered;
    IERC20 public asset;
    IStrategyHelper public strategyHelper;
    ISushiswapMiniChefV2 public rewarder;
    IUniswapV2Pair public pool;
    uint256 public poolId;
    mapping(address => bool) exec;
    mapping(address => bool) keepers;

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event Mint(uint256 amount, uint256 shares);
    event Burn(uint256 amount, uint256 shares);
    event Earn(uint256 tvl, uint256 profit);

    error NotKeeper();
    error InvalidFile();
    error NoReentering();
    error Unauthorized();

    constructor(address _asset, address _strategyHelper, address _rewarder, uint256 _poolId) {
        exec[msg.sender] = true;
        asset = IERC20(_asset);
        strategyHelper = IStrategyHelper(_strategyHelper);
        rewarder = ISushiswapMiniChefV2(_rewarder);
        poolId = _poolId;
        pool = IUniswapV2Pair(rewarder.lpToken(poolId));
        name =
            string(abi.encodePacked("SushiSwap ", IERC20(pool.token0()).symbol(), "/", IERC20(pool.token1()).symbol()));
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
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "slippage") {
            slippage = data;
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function rate(uint256 sha) public view returns (uint256) {
        if (sha == 0 || totalShares == 0) return 0;
        IUniswapV2Pair pair = pool;
        uint256 tot = pair.totalSupply();
        uint256 amt = totalManagedAssets();
        uint256 reserve0;
        uint256 reserve1;
        {
            (uint112 r0, uint112 r1,) = pair.getReserves();
            reserve0 = uint256(r0) * 1e18 / (10 ** IERC20(pair.token0()).decimals());
            reserve1 = uint256(r1) * 1e18 / (10 ** IERC20(pair.token1()).decimals());
        }
        uint256 price0 = strategyHelper.price(pair.token0());
        uint256 price1 = strategyHelper.price(pair.token1());
        uint256 val = 2 * ((sqrt(reserve0 * reserve1) * sqrt(price0 * price1)) / tot);
        return sha * (val * amt / 1e18) / totalShares;
    }

    function mint(uint256 amount) public auth loop returns (uint256) { 
        asset.transferFrom(msg.sender, address(this), amount);
        IUniswapV2Pair pair = pool;
        IERC20 tok0 = IERC20(pair.token0());
        IERC20 tok1 = IERC20(pair.token1());
        uint256 slp = slippage;
        uint256 tma = totalManagedAssets();
        {
            uint256 haf = amount / 2;
            asset.approve(address(strategyHelper), amount);
            strategyHelper.swap(address(asset), address(tok0), haf, slp, address(this));
            strategyHelper.swap(address(asset), address(tok1), amount - haf, slp, address(this));
            IERC20(tok0).transfer(address(pair), tok0.balanceOf(address(this)));
            IERC20(tok1).transfer(address(pair), tok1.balanceOf(address(this)));
        }
        pair.mint(address(this));
        pair.skim(address(this));
        uint256 liq = IERC20(address(pair)).balanceOf(address(this));
        IERC20(address(pair)).approve(address(rewarder), liq);
        rewarder.deposit(poolId, liq, address(this));
        uint256 shares = tma == 0 ? liq : liq * totalShares / tma;

        totalShares += shares;
        emit Mint(amount, shares);
        return shares;
    }

    function burn(uint256 shares) public auth loop returns (uint256) {
        IUniswapV2Pair pair = pool;
        uint256 slp = slippage;
        {
            uint256 tma = totalManagedAssets();
            uint256 amt = shares * tma / totalShares;
            rewarder.withdraw(poolId, amt, address(pair));
            pair.burn(address(this));
        }
        IERC20 tok0 = IERC20(pair.token0());
        IERC20 tok1 = IERC20(pair.token1());
        uint256 bal0 = tok0.balanceOf(address(this));
        uint256 bal1 = tok1.balanceOf(address(this));
        tok0.approve(address(strategyHelper), bal0);
        tok1.approve(address(strategyHelper), bal1);
        uint256 amt0 = strategyHelper.swap(address(tok0), address(asset), bal0, slp, msg.sender);
        uint256 amt1 = strategyHelper.swap(address(tok1), address(asset), bal1, slp, msg.sender);
        uint256 amount =  amt0 + amt1;

        totalShares -= shares;
        emit Burn(amount, shares);
        return amount;
    }

    function earn() public payable loop {
        if (!keepers[msg.sender]) revert NotKeeper();
        uint256 before = rate(totalShares);

        IUniswapV2Pair pair = pool;
        IERC20 rew = IERC20(rewarder.SUSHI());
        rewarder.harvest(poolId, address(this));
        uint256 amt = rew.balanceOf(address(this));
        uint256 haf = amt / 2;
        if (strategyHelper.value(address(rew), amt) < 0.5e18) return;
        rew.approve(address(strategyHelper), amt);
        strategyHelper.swap(address(rew), pair.token0(), haf, slippage, address(this));
        strategyHelper.swap(address(rew), pair.token1(), amt - haf, slippage, address(this));
        IERC20(pair.token0()).transfer(address(pair), IERC20(pair.token0()).balanceOf(address(this)));
        IERC20(pair.token1()).transfer(address(pair), IERC20(pair.token1()).balanceOf(address(this)));
        pair.mint(address(this));
        pair.skim(address(this));
        uint256 liq = IERC20(address(pair)).balanceOf(address(this));
        IERC20(address(pair)).approve(address(rewarder), liq);
        rewarder.deposit(poolId, liq, address(this));
        uint256 current = rate(totalShares);
        emit Earn(current, current - min(current, before));
    }

    function totalManagedAssets() public view returns (uint256) {
        (uint256 amt,) = rewarder.userInfo(poolId, address(this));
        return amt;
    }

    function exit(address strategy) public auth {
        rewarder.withdraw(poolId, totalShares, strategy);
    }

    function move(address old) public auth {
        require(totalShares == 0, "ts=0");
        totalShares = StrategySushiswap(old).totalShares();
        IERC20 lp = IERC20(address(pool));
        uint256 bal = lp.balanceOf(address(this));
        totalShares = bal;
        lp.approve(address(rewarder), bal);
        rewarder.deposit(poolId, bal, address(this));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // from OZ Math
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 result = 1 << (log2(a) >> 1);
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) result += 1;
        }
        return result;
    }
}