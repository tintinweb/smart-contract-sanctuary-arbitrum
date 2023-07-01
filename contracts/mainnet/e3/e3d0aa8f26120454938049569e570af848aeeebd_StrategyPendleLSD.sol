// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IPSwapAggregator, IPRouter, IPMarket, ILpOracleHelper} from "../interfaces/IPendle.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Strategy} from "../Strategy.sol";

contract StrategyPendleLSD is Strategy {
    IPRouter public router;
    IPMarket public market;
    ILpOracleHelper public lpOracleHelper;
    IERC20 public lsdEth;
    IERC20 public weth;
    string public name;
    address public targetAsset;
    uint32 public twapPeriod = 1800;

    error PriceSlipped();

    constructor(
        address _strategyHelper,
        address _lpOracleHelper,
        address _router,
        address _market,
        address _lsdEth,
        address _weth,
        address _targetAsset
    ) Strategy(_strategyHelper) {
        lpOracleHelper = ILpOracleHelper(_lpOracleHelper);
        router = IPRouter(_router);
        market = IPMarket(_market);
        lsdEth = IERC20(_lsdEth);
        weth = IERC20(_weth);
        targetAsset = _targetAsset;
        name = string(abi.encodePacked("Pendle ", lsdEth.symbol()));
    }

    function setTargetAsset(address newTargetAsset) external auth {
        targetAsset = newTargetAsset;
    }

    function setTwapPeriod(uint32 newTwapPeriod) external auth {
        twapPeriod = newTwapPeriod;
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        pull(IERC20(ast), msg.sender, amt);

        uint256 slp = getSlippage(dat);
        uint256 tma = totalManagedAssets();
        uint256 lpAmt = deposit(ast, amt, slp);
        uint256 sha = tma == 0 ? lpAmt : (lpAmt * totalShares) / tma;

        if (valueLiquidity(lpAmt) < strategyHelper.value(ast, amt) * (10000 - slp) / 10000) revert PriceSlipped();

        return sha;
    }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal override returns (uint256) {
        uint256 amt = (sha * totalManagedAssets()) / totalShares;
        uint256 rate = valueLiquidity(amt);
        uint256 slp = getSlippage(dat);
        uint256 bal = withdraw(ast, amt, slp);

        if (rate < strategyHelper.value(ast, bal) * (10000 - slp) / 10000) revert PriceSlipped();

        return bal;
    }

    function _earn() internal override {
        address[] memory rewardTokens = market.getRewardTokens();
        uint256 len = rewardTokens.length;
        address trgtAst = targetAsset;
        uint256 slp = slippage;

        market.redeemRewards(address(this));

        for (uint256 i = 0; i < len; ++i) {
            uint256 bal = IERC20(rewardTokens[i]).balanceOf(address(this));

            if (strategyHelper.value(rewardTokens[i], bal) < 0.5e18) continue;

            IERC20(rewardTokens[i]).approve(address(strategyHelper), bal);

            strategyHelper.swap(rewardTokens[i], trgtAst, bal, slp, address(this));
        }

        uint256 trgtAstBal = IERC20(trgtAst).balanceOf(address(this));

        if (strategyHelper.value(trgtAst, trgtAstBal) > 0.5e18) {
            deposit(trgtAst, trgtAstBal, slp);
        }
    }

    function _exit(address str) internal override {
        push(market, str, totalManagedAssets());
    }

    // Is empty because Pendle's LPs are not staked somewhere else.
    function _move(address old) internal override {}

    function _rate(uint256 sha) internal view override returns (uint256) {
        return sha * valueLiquidity(totalManagedAssets()) / totalShares;
    }

    function deposit(address ast, uint256 amt, uint256 slp) private returns (uint256) {
        IERC20(ast).approve(address(strategyHelper), amt);
        uint256 bal = strategyHelper.swap(ast, address(lsdEth), amt, slp, address(this));
        return addPendleLiquidity(bal);
    }

    function withdraw(address ast, uint256 amt, uint256 slp) private returns (uint256) {
        uint256 bal = removePendleLiquidity(amt);
        lsdEth.approve(address(strategyHelper), bal);
        return strategyHelper.swap(address(lsdEth), ast, bal, slp, msg.sender);
    }

    function addPendleLiquidity(uint256 amt) private returns (uint256 netLpOut) {
        address ast = address(lsdEth);
        IPMarket.ApproxParams memory approxParams = IPMarket.ApproxParams({
            guessMin: 0,
            guessMax: type(uint256).max,
            guessOffchain: 0,
            maxIteration: 256,
            eps: 1e14 // Maximum 0.01% unused
        });
        IPSwapAggregator.SwapData memory swapData = IPSwapAggregator.SwapData({
            swapType: IPSwapAggregator.SwapType.NONE,
            extRouter: address(0),
            extCalldata: "",
            needScale: false
        });
        IPRouter.TokenInput memory input = IPRouter.TokenInput({
            tokenIn: ast,
            netTokenIn: amt,
            tokenMintSy: ast,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });

        IERC20(ast).approve(address(router), amt);

        (netLpOut,) = router.addLiquiditySingleToken(address(this), address(market), 0, approxParams, input);
    }

    function removePendleLiquidity(uint256 amt) private returns (uint256 netTokenOut) {
        address ast = address(lsdEth);
        IPSwapAggregator.SwapData memory swapData = IPSwapAggregator.SwapData({
            swapType: IPSwapAggregator.SwapType.NONE,
            extRouter: address(0),
            extCalldata: "",
            needScale: false
        });
        IPRouter.TokenOutput memory output = IPRouter.TokenOutput({
            tokenOut: ast,
            minTokenOut: 0,
            tokenRedeemSy: ast,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });

        market.approve(address(router), amt);

        (netTokenOut,) = router.removeLiquiditySingleToken(address(this), address(market), amt, output);
    }

    function valueLiquidity(uint256 amt) private view returns (uint256) {
        address lsdEthAddress = address(lsdEth);
        uint256 lsdEthPrice = strategyHelper.price(lsdEthAddress);
        uint256 k = strategyHelper.convert(lsdEthAddress, address(weth), 1e18);
        uint256 lpRate = lpOracleHelper.getLpToAssetRate(market, twapPeriod);

        return (lsdEthPrice * lpRate / k) * amt / 1e18;
    }

    function totalManagedAssets() private view returns (uint256) {
        return market.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./IERC20.sol";

interface IPRouter {
    struct TokenInput {
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        address bulk;
        address pendleSwap;
        IPSwapAggregator.SwapData swapData;
    }

    struct TokenOutput {
        address tokenOut;
        uint256 minTokenOut;
        address tokenRedeemSy;
        address bulk;
        address pendleSwap;
        IPSwapAggregator.SwapData swapData;
    }

    function addLiquiditySingleToken(
        address receiver,
        address market,
        uint256 minLpOut,
        IPMarket.ApproxParams calldata guessPtReceivedFromSy,
        TokenInput calldata input
    ) external payable returns (uint256 netLpOut, uint256 netSyFee);
    function removeLiquiditySingleToken(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut, uint256 netSyFee);
}

interface IPSwapAggregator {
    enum SwapType {
        NONE,
        KYBERSWAP,
        ONE_INCH,
        ETH_WETH
    }

    struct SwapData {
        SwapType swapType;
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }
}

interface IPMarket is IERC20 {
    struct ApproxParams {
        uint256 guessMin; // The minimum value for binary search.
        uint256 guessMax; // The maximum value for binary search.
        uint256 guessOffchain; // This is the first answer to be checked before performing any binary search. If the answer already satisfies, Pendle skip the search and save significant gas.
        uint256 maxIteration; // The maximum number of times binary search will be performed.
        uint256 eps; // The precision of binary search - the maximum proportion of the input that can be unused. eps is 1e18-based, so an eps of 1e14 implies that no more than 0.01% of the input might be unused.
    }

    function redeemRewards(address user) external returns (uint256[] memory);
    function getRewardTokens() external view returns (address[] memory);
}

interface ILpOracleHelper {
    function getLpToAssetRate(IPMarket market, uint32 duration) external view returns (uint256 lpToAssetRate);
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