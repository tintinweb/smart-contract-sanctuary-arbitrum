// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {Util} from "./Util.sol";
import {IStrategyHelper} from "./interfaces/IStrategyHelper.sol";

abstract contract Strategy is Util {
    error OverCap();
    error NotKeeper();
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
    mapping(address => bool) keepers;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event Mint(address indexed ast, uint256 amt, uint256 sha);
    event Burn(address indexed ast, uint256 amt, uint256 sha);
    event Earn(uint256 tvl, uint256 profit);

    constructor(address _strategyHelper) {
        strategyHelper = IStrategyHelper(_strategyHelper);
        exec[msg.sender] = true;
        keepers[msg.sender] = true;
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
        if (what == "keeper") keepers[data] = !keepers[data];
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
        if (totalShares == 0) return 0;
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

    function burn(address ast, uint256 sha, bytes calldata dat)
        external
        auth
        statusAbove(S_WITHDRAW)
        returns (uint256)
    {
        uint256 amt = _burn(ast, sha, dat);
        totalShares -= sha;
        emit Burn(ast, amt, sha);
        return amt;
    }

    function earn() public {
        if (!keepers[msg.sender]) revert NotKeeper();
        if (totalShares == 0) return;
        uint256 bef = rate(totalShares);
        _earn();
        uint256 aft = rate(totalShares);
        emit Earn(aft, aft - min(aft, bef));
    }

    function exit(address str) public auth {
        status = S_PAUSE;
        _exit(str);
    }

    function move(address old) public auth {
        require(totalShares == 0, "ts=0");
        totalShares = Strategy(old).totalShares();
        _move(old);
    }

    function _rate(uint256) internal view virtual returns (uint256) {
        // calculate vault / lp value in usd (1e18) terms
        return 0;
    }

    function _earn() internal virtual {}

    function _mint(address ast, uint256 amt, bytes calldata dat) internal virtual returns (uint256) {}

    function _burn(address ast, uint256 sha, bytes calldata dat) internal virtual returns (uint256) {}

    function _exit(address str) internal virtual {}

    function _move(address old) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";

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

    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 1e18;
        if (x == 0) return 0;
        require(x >> 255 == 0, "xoob");
        int256 x_int256 = int256(x);
        require(y < uint256(2 ** 254) / 1e20, "yoob");
        int256 y_int256 = int256(y);
        int256 logx_times_y = _ln(x_int256) * y_int256 / 1e18;
        require(-41e18 <= logx_times_y && logx_times_y <= 130e18, "poob");
        return uint256(_exp(logx_times_y));
    }

    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    function _ln(int256 a) private pure returns (int256) {
        if (a < 1e18) return -_ln((1e18 * 1e18) / a);
        int256 sum = 0;
        if (a >= a0 * 1e18) {
            a /= a0;
            sum += x0;
        }
        if (a >= a1 * 1e18) {
            a /= a1;
            sum += x1;
        }
        sum *= 100;
        a *= 100;
        if (a >= a2) {
            a = (a * 1e20) / a2;
            sum += x2;
        }
        if (a >= a3) {
            a = (a * 1e20) / a3;
            sum += x3;
        }
        if (a >= a4) {
            a = (a * 1e20) / a4;
            sum += x4;
        }
        if (a >= a5) {
            a = (a * 1e20) / a5;
            sum += x5;
        }
        if (a >= a6) {
            a = (a * 1e20) / a6;
            sum += x6;
        }
        if (a >= a7) {
            a = (a * 1e20) / a7;
            sum += x7;
        }
        if (a >= a8) {
            a = (a * 1e20) / a8;
            sum += x8;
        }
        if (a >= a9) {
            a = (a * 1e20) / a9;
            sum += x9;
        }
        if (a >= a10) {
            a = (a * 1e20) / a10;
            sum += x10;
        }
        if (a >= a11) {
            a = (a * 1e20) / a11;
            sum += x11;
        }
        int256 z = ((a - 1e20) * 1e20) / (a + 1e20);
        int256 z_squared = (z * z) / 1e20;
        int256 num = z;
        int256 seriesSum = num;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 3;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 5;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 7;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 9;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 11;
        seriesSum *= 2;
        return (sum + seriesSum) / 100;
    }

    function _exp(int256 x) internal pure returns (int256) {
        require(x >= -41e18 && x <= 130e18, "ie");
        if (x < 0) return ((1e18 * 1e18) / _exp(-x));
        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1;
        }
        x *= 100;
        int256 product = 1e20;
        if (x >= x2) {
            x -= x2;
            product = (product * a2) / 1e20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / 1e20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / 1e20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / 1e20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / 1e20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / 1e20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / 1e20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / 1e20;
        }
        int256 seriesSum = 1e20;
        int256 term;
        term = x;
        seriesSum += term;
        term = ((term * x) / 1e20) / 2;
        seriesSum += term;
        term = ((term * x) / 1e20) / 3;
        seriesSum += term;
        term = ((term * x) / 1e20) / 4;
        seriesSum += term;
        term = ((term * x) / 1e20) / 5;
        seriesSum += term;
        term = ((term * x) / 1e20) / 6;
        seriesSum += term;
        term = ((term * x) / 1e20) / 7;
        seriesSum += term;
        term = ((term * x) / 1e20) / 8;
        seriesSum += term;
        term = ((term * x) / 1e20) / 9;
        seriesSum += term;
        term = ((term * x) / 1e20) / 10;
        seriesSum += term;
        term = ((term * x) / 1e20) / 11;
        seriesSum += term;
        term = ((term * x) / 1e20) / 12;
        seriesSum += term;
        return (((product * seriesSum) / 1e20) * firstAN) / 100;
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

enum JoeVersion {
    V1,
    V2,
    V2_1
}

struct JoePath {
    uint256[] pairBinSteps;
    JoeVersion[] versions;
    address[] tokenPath;
}

interface IJoeLBPair {
    function getTokenX() external view returns (address);
    function getTokenY() external view returns (address);
    function getBinStep() external view returns (uint16);
    function getActiveId() external view returns (uint24);
    function totalSupply(uint256) external view returns (uint256);
    function balanceOf(address, uint256) external view returns (uint256);
    function getBin(uint24) external view returns (uint128, uint128);
    function getOracleSampleAt(uint40) external view returns (uint64, uint64, uint64);
    function getPriceFromId(uint24) external view returns (uint256);
    function approveForAll(address, bool) external;
}

interface IJoeLBRouter {
    struct LiquidityParameters {
        address tokenX;
        address tokenY;
        uint256 binStep;
        uint256 amountX;
        uint256 amountY;
        uint256 amountXMin;
        uint256 amountYMin;
        uint256 activeIdDesired;
        uint256 idSlippage;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        address to;
        address refundTo;
        uint256 deadline;
    }

    function getIdFromPrice(address pair, uint256 price) external view returns (uint24);
    function getPriceFromId(address pair, uint24 id) external view returns (uint256);

    function addLiquidity(LiquidityParameters calldata liquidityParameters)
        external
        returns (
            uint256 amountXAdded,
            uint256 amountYAdded,
            uint256 amountXLeft,
            uint256 amountYLeft,
            uint256[] memory depositIds,
            uint256[] memory liquidityMinted
        );

    function removeLiquidity(
        address tokenX,
        address tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        address[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        JoePath memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IStrategyHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256);
    function paths(address, address) external returns (address venue, bytes memory path);
}

interface IStrategyHelperUniswapV3 {
    function swap(address ast, bytes calldata path, uint256 amt, uint256 min, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Strategy} from "../Strategy.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IJoeLBPair, IJoeLBRouter} from "../interfaces/IJoe.sol";

contract StrategyJoe is Strategy {
    string public name;
    IJoeLBRouter public immutable router;
    IJoeLBPair public immutable pair;
    IERC20 public immutable tokenX;
    IERC20 public immutable tokenY;
    uint256 public immutable binStep;
    uint256 public binAmount;
    uint256[] public bins;

    constructor(address _strategyHelper, address _router, address _pair, uint256 _binAmount)
        Strategy(_strategyHelper)
    {
        router = IJoeLBRouter(_router);
        pair = IJoeLBPair(_pair);
        tokenX = IERC20(pair.getTokenX());
        tokenY = IERC20(pair.getTokenY());
        binStep = uint256(pair.getBinStep());
        binAmount = _binAmount;
        name = string(abi.encodePacked("Joe ", tokenX.symbol(), "/", tokenY.symbol()));
    }

    function _rate(uint256 sha) internal view override returns (uint256) {
        (uint256 amtX, uint256 amtY,) = _amounts();
        uint256 balX = tokenX.balanceOf(address(this));
        uint256 balY = tokenY.balanceOf(address(this));
        uint256 valX = strategyHelper.value(address(tokenX), amtX + balX);
        uint256 valY = strategyHelper.value(address(tokenY), amtY + balY);
        return sha * (valX + valY) / totalShares;
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        uint256 slp = getSlippage(dat);
        uint256 tma = rate(totalShares);
        uint256 haf = amt / 2;
        pull(IERC20(ast), msg.sender, amt);
        IERC20(ast).approve(address(strategyHelper), amt);
        uint256 amtX = strategyHelper.swap(ast, address(tokenX), haf, slp, address(this));
        uint256 amtY = strategyHelper.swap(ast, address(tokenY), amt - haf, slp, address(this));
        uint256 valX = strategyHelper.value(address(tokenX), amtX);
        uint256 valY = strategyHelper.value(address(tokenY), amtY);
        uint256 liq = valX + valY;
        return tma == 0 ? liq : liq * totalShares / tma;
    }

    function _burn(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        uint256 tot = totalShares;
        uint256 slp = getSlippage(dat);
        _burnLP(amt * 1.01e18 / tot);
        uint256 shaX;
        uint256 shaY;
        {
            uint256 balX = tokenX.balanceOf(address(this));
            uint256 balY = tokenY.balanceOf(address(this));
            (uint256 valX, uint256 valY,) = _amounts();
            shaX = amt * (balX + valX) / tot;
            shaY = amt * (balY + valY) / tot;
        }
        tokenX.approve(address(strategyHelper), shaX);
        tokenY.approve(address(strategyHelper), shaY);
        uint256 amtX = strategyHelper.swap(address(tokenX), ast, shaX, slp, msg.sender);
        uint256 amtY = strategyHelper.swap(address(tokenY), ast, shaY, slp, msg.sender);
        return amtX + amtY;
    }

    function _earn() internal override {
        _burnLP(1e18);
        _rebalance(slippage);
        _mintLP(slippage);
    }

    function _exit(address str) internal override {
        _burnLP(1e18);
        push(tokenX, str, tokenX.balanceOf(address(this)));
        push(tokenY, str, tokenY.balanceOf(address(this)));
    }

    function _move(address) internal override {
        _rebalance(slippage);
        _mintLP(slippage);
    }

    function _rebalance(uint256 slp) internal {
        uint256 amtX = tokenX.balanceOf(address(this));
        uint256 amtY = tokenY.balanceOf(address(this));
        uint256 valX = strategyHelper.value(address(tokenX), amtX);
        uint256 valY = strategyHelper.value(address(tokenY), amtY);
        uint256 haf = (valX + valY) / 2;
        if (valX < valY) {
            uint256 ned = haf - valX;
            if (ned > 0.5e18) {
                uint256 amt = ned * 1e18 / strategyHelper.price(address(tokenY));
                amt = amt * (10 ** tokenY.decimals()) / 1e18;
                tokenY.approve(address(strategyHelper), amt);
                strategyHelper.swap(address(tokenY), address(tokenX), amt, slp, address(this));
            }
        } else {
            uint256 ned = haf - valY;
            if (ned > 0.5e18) {
                uint256 amt = ned * 1e18 / strategyHelper.price(address(tokenX));
                amt = amt * (10 ** tokenX.decimals()) / 1e18;
                tokenX.approve(address(strategyHelper), amt);
                strategyHelper.swap(address(tokenX), address(tokenY), amt, slp, address(this));
            }
        }
    }

    function _mintLP(uint256 slp) internal {
        uint24 activeId = pair.getActiveId();
        uint256 amtX = tokenX.balanceOf(address(this));
        uint256 amtY = tokenY.balanceOf(address(this));
        uint256 minX = amtX * (10000 - slp) / 10000;
        uint256 minY = amtY * (10000 - slp) / 10000;
        uint256 num = binAmount;
        int256[] memory deltaIds = new int256[](num * 2);
        uint256[] memory distributionX = new uint256[](num * 2);
        uint256[] memory distributionY = new uint256[](num * 2);
        uint256 sha = 1e18 / num;
        for (uint256 i = 0; i < num; i++) {
            deltaIds[i] = int256(i + 1);
            deltaIds[num + i] = 0 - int256(i + 1);
            distributionX[i] = i > 0 ? sha : 1e18 - ((num - 1) * sha);
            distributionY[num + i] = i > 0 ? sha : 1e18 - ((num - 1) * sha);
        }
        tokenX.approve(address(router), amtX);
        tokenY.approve(address(router), amtY);
        (,,,, bins,) = router.addLiquidity(
            IJoeLBRouter.LiquidityParameters(
                address(tokenX),
                address(tokenY),
                binStep,
                amtX,
                amtY,
                minX,
                minY,
                activeId,
                0,
                deltaIds,
                distributionX,
                distributionY,
                address(this),
                address(this),
                block.timestamp
            )
        );
    }

    function _burnLP(uint256 pct) internal {
        (,, uint256[] memory amounts) = _amounts();
        uint256 len = amounts.length;
        if (len == 0) return;
        for (uint256 i = 0; i < len; i++) {
            amounts[i] = amounts[i] * pct / 1e18;
        }
        pair.approveForAll(address(router), true);
        router.removeLiquidity(
            address(tokenX), address(tokenY), uint16(binStep), 0, 0, bins, amounts, address(this), block.timestamp
        );
    }

    function _amounts() internal view returns (uint256, uint256, uint256[] memory) {
        uint256 num = bins.length;
        uint256[] memory amounts = new uint256[](num);
        uint256 amtX = 0;
        uint256 amtY = 0;
        for (uint256 i = 0; i < num; i++) {
            uint256 id = bins[i];
            uint256 amt = pair.balanceOf(address(this), id);
            amounts[i] = amt;
            (uint128 resX, uint128 resY) = pair.getBin(uint24(id));
            uint256 supply = pair.totalSupply(id);
            amtX += mulDiv(amt, uint256(resX), supply);
            amtY += mulDiv(amt, uint256(resY), supply);
        }
        return (amtX, amtY, amounts);
    }

    // Source: https://github.com/paulrberg/prb-math/blob/86c068e21f9ba229025a77b951bd3c4c4cf103da/contracts/PRBMath.sol#L394
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
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
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }
        require(denominator > prod1);
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            assembly {
                denominator := div(denominator, twos)
            }
            assembly {
                prod0 := div(prod0, twos)
            }
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;
            uint256 inv = (3 * denominator) ^ 2;
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256
            result = prod0 * inv;
            return result;
        }
    }
}