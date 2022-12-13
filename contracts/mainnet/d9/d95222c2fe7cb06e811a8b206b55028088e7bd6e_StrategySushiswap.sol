// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {Util} from "./Util.sol";
import {IStrategyHelper} from "./interfaces/IStrategyHelper.sol";

abstract contract Strategy is Util {
    error OverCap();
    error WrongStatus();
    error SlippageTooHigh();

    uint256 public constant S_LIQUIDATE = 1;
    uint256 public constant S_PAUSE = 2;
    uint256 public constant S_WITHDRAW = 3;
    uint256 public constant S_LIVE = 4;
    uint256 public cap;
    uint256 public totalShares;
    uint256 public slippage = 50;
    uint256 public status = S_LIVE;
    IStrategyHelper public strategyHelper;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event Mint(address indexed ast, uint256 amt, uint256 sha);
    event Burn(address indexed ast, uint256 amt, uint256 sha);
    event Earn(uint256 val, uint256 amt);

    constructor(address _strategyHelper) {
        strategyHelper = IStrategyHelper(_strategyHelper);
        exec[msg.sender] = true;
    }

    modifier statusAbove(uint256 sta) {
        if (status < sta) revert WrongStatus();
        _;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "cap") cap = data;
        if (what == "status") status = data;
        if (what == "slippage") slippage = data;
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        emit FileAddress(what, data);
    }

    function getSlippage(bytes memory dat) internal view returns (uint256) {
        if (dat.length > 0) {
            (uint256 slp) = abi.decode(dat, (uint256));
            if (slp > 500) revert SlippageTooHigh();
            return slp;
        }
        return slippage;
    }

    function rate(uint256 sha) public view returns (uint256) {
        if (status == S_LIQUIDATE) return 0;
        return _rate(sha);
    }

    function mint(address ast, uint256 amt, bytes calldata dat) external auth statusAbove(S_LIVE) returns (uint256) {
        uint256 sha = _mint(ast, amt, dat);
        totalShares += sha;
        if (cap != 0 && rate(totalShares) > cap) revert OverCap();
        emit Mint(ast, amt, sha);
        return sha;
    }

    function burn(address ast, uint256 sha, bytes calldata dat) external auth statusAbove(S_WITHDRAW) returns (uint256) {
        uint256 amt = _burn(ast, sha, dat);
        totalShares -= sha;
        emit Burn(ast, amt, sha);
        return amt;
    }

    function earn() public {
        uint256 bef = rate(totalShares);
        _earn();
        uint256 aft = rate(totalShares);
        emit Earn(aft, aft - min(aft, bef));
    }

    function exit(address str) public auth {
        _exit(str);
        totalShares = 0;
        status = S_PAUSE;
    }

    function move(address old) public auth {
        require(totalShares != 0, "ts!=0");
        totalShares = Strategy(old).totalShares();
        _move(old);
    }

    function _rate(uint256) internal view virtual returns (uint256) {
        // calculate vault / lp value in usd (1e18) terms
        return 0;
    }

    function _earn() internal virtual { }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal virtual returns (uint256) { }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal virtual returns (uint256) { }

    function _exit(address str) internal virtual { }

    function _move(address old) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {IPairUniV2} from "./interfaces/IPairUniV2.sol";
import {Strategy} from "./Strategy.sol";
import {IRewarderMiniChefV2} from "./interfaces/IRewarderMiniChefV2.sol";

contract StrategySushiswap is Strategy {
    string public name;
    IRewarderMiniChefV2 public rewarder;
    IPairUniV2 public pool;
    uint256 poolId;

    constructor(address _strategyHelper, address _rewarder, uint256 _poolId) Strategy(_strategyHelper) {
        rewarder = IRewarderMiniChefV2(_rewarder);
        poolId = _poolId;
        pool = IPairUniV2(rewarder.lpToken(poolId));
        name = string(abi.encodePacked("SushiSwap ", IERC20(pool.token0()).symbol(), "/", IERC20(pool.token1()).symbol()));
    }

    function _rate(uint256 sha) internal view override returns (uint256) {
        if (sha == 0 || totalShares == 0) return 0;
        IPairUniV2 pair = pool;
        uint256 tot = pair.totalSupply();
        uint256 amt = totalManagedAssets();
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 val = strategyHelper.value(pair.token0(), reserve0) +
            strategyHelper.value(pair.token1(), reserve1);
        return sha * (val * amt / tot) / totalShares;
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        earn();
        pull(IERC20(ast), msg.sender, amt);
        IPairUniV2 pair = pool;
        IERC20 tok0 = IERC20(pair.token0());
        IERC20 tok1 = IERC20(pair.token1());
        uint256 slp = getSlippage(dat);
        uint256 tma = totalManagedAssets();
        {
            uint256 haf = amt / 2;
            IERC20(ast).approve(address(strategyHelper), amt);
            strategyHelper.swap(ast, address(tok0), haf, slp, address(this));
            strategyHelper.swap(ast, address(tok1), amt-haf, slp, address(this));
            push(tok0, address(pair), tok0.balanceOf(address(this)));
            push(tok1, address(pair), tok1.balanceOf(address(this)));
        }
        pair.mint(address(this));
        pair.skim(address(this));
        uint256 liq = IERC20(address(pair)).balanceOf(address(this));
        IERC20(address(pair)).approve(address(rewarder), liq);
        rewarder.deposit(poolId, liq, address(this));
        return tma == 0 ? liq : liq * totalShares / tma;
    }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal override returns (uint256) {
        earn();
        IPairUniV2 pair = pool;
        uint256 slp = getSlippage(dat);
        {
            uint256 tma = totalManagedAssets();
            uint256 amt = sha * tma / totalShares;
            rewarder.withdraw(poolId, amt, address(pair));
            pair.burn(address(this));
        }
        IERC20 tok0 = IERC20(pair.token0());
        IERC20 tok1 = IERC20(pair.token1());
        uint256 bal0 = tok0.balanceOf(address(this));
        uint256 bal1 = tok1.balanceOf(address(this));
        tok0.approve(address(strategyHelper), bal0);
        tok1.approve(address(strategyHelper), bal1);
        uint256 amt0 = strategyHelper.swap(address(tok0), ast, bal0, slp, msg.sender);
        uint256 amt1 = strategyHelper.swap(address(tok1), ast, bal1, slp, msg.sender);
        return amt0 + amt1;
    }

    function _earn() internal override {
        IPairUniV2 pair = pool;
        IERC20 rew = IERC20(rewarder.SUSHI());
        rewarder.harvest(poolId, address(this));
        uint256 amt = rew.balanceOf(address(this));
        uint256 haf = amt / 2;
        if (strategyHelper.value(address(rew), amt) < 0.5e18) return;
        rew.approve(address(strategyHelper), amt);
        strategyHelper.swap(address(rew), pair.token0(), haf, slippage, address(pair));
        strategyHelper.swap(address(rew), pair.token1(), amt-haf, slippage, address(pair));
        pair.mint(address(this));
        pair.skim(address(this));
        uint256 liq = IERC20(address(pair)).balanceOf(address(this));
        rewarder.deposit(poolId, liq, address(this));
    }

    function totalManagedAssets() public view returns (uint256) {
        (uint256 amt,) = rewarder.userInfo(poolId, address(this));
        return amt;
    }

    function _exit(address str) internal override {
        IERC20 lp = IERC20(address(pool));
        rewarder.withdraw(poolId, totalShares, address(pool));
        push(lp, str, lp.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from './interfaces/IERC20.sol';

contract Util {
    error Paused();
    error NoReentering();
    error Unauthorized();
    error TransferFailed();

    bool internal entered;
    bool public paused;
    mapping(address => bool) public exec;

    modifier loop() {
        if (entered) revert NoReentering();
        entered = true;
        _;
        entered = false;
    }

    modifier live() {
        if (paused) revert Paused();
        _;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    // from OZ SignedMath
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }

    function pull(IERC20 asset, address usr, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transferFrom(usr, address(this), amt)) revert TransferFailed();
    }

    function pullTo(IERC20 asset, address usr, address to, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transferFrom(usr, to, amt)) revert TransferFailed();
    }

    function push(IERC20 asset, address usr, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transfer(usr, amt)) revert TransferFailed();
    }

    function emergencyForTesting(address target, uint256 value, bytes calldata data) external auth {
        target.call{value: value}(data);
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

interface IPairUniV2 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
    function mint(address) external returns (uint256 liquidity);
    function burn(address) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256, uint256, address, bytes calldata) external;
    function skim(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRewarderMiniChefV2 {
    function SUSHI() external view returns (address);
    function lpToken(uint256) external view returns (address);
    function pendingSushi(uint256, address) external view returns (uint256);
    function userInfo(uint256, address) external view returns (uint256, int256);
    function deposit(uint256, uint256, address) external;
    function withdraw(uint256, uint256, address) external;
    function harvest(uint256, address) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IStrategyHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256);
}