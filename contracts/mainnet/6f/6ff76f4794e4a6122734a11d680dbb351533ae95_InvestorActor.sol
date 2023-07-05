// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Util} from "./Util.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IInvestor} from "./interfaces/IInvestor.sol";
import {IPositionManager} from "./interfaces/IPositionManager.sol";

interface IGuard {
    function check(address usr, address str, address pol, uint256 val, uint256 bor)
        external
        view
        returns (bool ok, uint256 need, uint256 rebate);
}

interface IInvestorActorStrategyProxy {
    function mint(address str, address ast, uint256 amt, bytes calldata dat) external returns (uint256);
    function burn(address str, address ast, uint256 sha, bytes calldata dat) external returns (uint256);
}

contract InvestorActor is Util {
    error GuardNotOk(uint256 need);
    error InsufficientShares();
    error InsufficientBorrow();
    error Undercollateralized();
    error CantBorrowAndDivest();
    error OverMaxBorrowFactor();
    error NoEditingInSameBlock();
    error PositionNotLiquidatable();
    error InsufficientAmountForRepay();

    IInvestor public investor;
    IInvestorActorStrategyProxy public strategyProxy;
    IGuard public guard;
    IPositionManager public positionManager;
    uint256 public performanceFee = 0.1e4;
    uint256 public originationFee = 0;
    uint256 public liquidationFee = 0.05e4;
    uint256 public softLiquidationSize = 0.5e4;
    uint256 public softLiquidationThreshold = 0.95e18;
    mapping(uint256 => uint256) private lastEditBlock;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);

    constructor(address _investor, address _strategyProxy) {
        investor = IInvestor(_investor);
        strategyProxy = IInvestorActorStrategyProxy(_strategyProxy);
        exec[_investor] = true;
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "performanceFee") performanceFee = data;
        if (what == "originationFee") originationFee = data;
        if (what == "liquidationFee") liquidationFee = data;
        if (what == "softLiquidationSize") softLiquidationSize = data;
        if (what == "softLiquidationThreshold") softLiquidationThreshold = data;
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        if (what == "guard") guard = IGuard(data);
        if (what == "positionManager") positionManager = IPositionManager(data);
        emit FileAddress(what, data);
    }

    function life(uint256 id) public view returns (uint256) {
        (,,,,, uint256 sha, uint256 bor) = investor.positions(id);
        return _life(id, sha, bor);
    }

    function _life(uint256 id, uint256 sha, uint256 bor) internal view returns (uint256) {
        (, address pol, uint256 str,,,,) = investor.positions(id);
        IPool pool = IPool(pol);
        if (bor == 0) return 1e18;
        uint256 value = (IStrategy(investor.strategies(str)).rate(sha) * pool.liquidationFactor()) / 1e18;
        uint256 borrow = _borrowValue(pool, bor);
        return value * 1e18 / borrow;
    }

    function edit(uint256 id, int256 aamt, int256 abor, bytes calldata dat)
        public
        auth
        returns (int256 bas, int256 sha, int256 bor)
    {
        IPool pool;
        IERC20 asset;
        IStrategy strategy;
        {
            if (lastEditBlock[id] == block.number) revert NoEditingInSameBlock();
            lastEditBlock[id] = block.number;
        }

        {
            (, address pol, uint256 str,,,,) = investor.positions(id);
            pool = IPool(pol);
            asset = IERC20(pool.asset());
            strategy = IStrategy(investor.strategies(str));
        }

        (,,,,,, uint256 pbor) = investor.positions(id);
        uint256 amt = aamt > 0 ? uint256(aamt) : 0;

        if (abor > 0) {
            bor = int256(pool.borrow(uint256(abor)));
            amt = amt + uint256(abor) - _takeBorrowFee(abor);
        }

        if (aamt < 0) {
            sha = aamt;
            amt = amt + _burnShares(id, aamt, dat);
        }

        if (abor < 0) {
            bor = abor;
            uint256 cbor = uint256(0 - abor);
            if (cbor > pbor) revert InsufficientBorrow();
            uint256 rep = cbor * pool.getUpdatedIndex() / 1e18;
            // Check repay amount because if we just call repay with
            // too little funds the pool will try to use protocol reserves
            if (amt < rep) revert InsufficientAmountForRepay();
            asset.approve(address(pool), amt);
            amt = amt - pool.repay(cbor);
        }

        // Make sure whenever a user borrows, all funds go into a strategy
        // if we didn't users could withdraw borrow to their wallet
        if (abor > 0 && aamt < 0) revert CantBorrowAndDivest();
        // We could provide more capital and not borrow or provide no capital and borrow more,
        // but as long as we are not divesting shares or repaying borrow,
        // let's mint more shares with all we got
        if (abor > 0 || aamt > 0) {
            asset.transfer(address(strategyProxy), amt);
            sha = int256(strategyProxy.mint(address(strategy), address(asset), amt, dat));
            amt = 0;
        }

        // If the new position amount is below zero, collect a performance fee
        // on that portion of the outgoing assets
        {
            uint256 fee;
            uint256 rebate = _checkGuardAndGetRebate(id, sha, bor);
            (bas, fee) = _takePerformanceFee(id, aamt, amt, rebate);
            amt = amt - fee;
        }

        // Send extra funds to use (if there's any)
        // Happens when divesting or borrowing (and not minting more shares)
        {
            (address own,,,,,,) = investor.positions(id);
            push(asset, own, amt);
        }

        bas = _maybeSetBasisToInitialRate(id, bas, sha, abor);

        _checkLife(id, sha, bor);
    }

    function _borrowValue(IPool pool, uint256 bor) internal view returns (uint256) {
        IOracle oracle = IOracle(pool.oracle());
        uint256 price = (uint256(oracle.latestAnswer()) * 1e18) / (10 ** oracle.decimals());
        uint256 scaled = (bor * 1e18) / (10 ** IERC20(pool.asset()).decimals());
        return (scaled * pool.getUpdatedIndex() / 1e18) * price / 1e18;
    }

    function _takeBorrowFee(int256 abor) internal returns (uint256) {
        // leave in contract, mintProtocolReserves will happen
        return uint256(abor) * originationFee / 10000;
    }

    function _burnShares(uint256 id, int256 aamt, bytes calldata dat) internal returns (uint256) {
        (, address pol, uint256 str,,, uint256 psha,) = investor.positions(id);
        uint256 camt = uint256(0 - aamt);
        if (camt > psha) revert InsufficientShares();
        return strategyProxy.burn(investor.strategies(str), IPool(pol).asset(), camt, dat);
    }

    function _checkGuardAndGetRebate(uint256 id, int256 sha, int256 bor) internal view returns (uint256) {
        if (address(guard) == address(0)) return 0;
        IPool pool;
        IStrategy strategy;
        {
            (, address pol, uint256 str,,, uint256 psha, uint256 pbor) = investor.positions(id);
            pool = IPool(pol);
            strategy = IStrategy(investor.strategies(str));
            sha = sha + int256(psha);
            bor = bor + int256(pbor);
        }
        (bool ok, uint256 need, uint256 rebate) = guard.check(
            _positionOwner(id),
            address(strategy),
            address(pool),
            strategy.rate(uint256(sha)),
            _borrowValue(pool, uint256(bor))
        );
        if (!ok) revert GuardNotOk(need);
        return rebate;
    }

    function _takePerformanceFee(uint256 id, int256 aamt, uint256 amt, uint256 rebate)
        internal
        returns (int256, uint256)
    {
        uint256 fee;
        int256 bas = (aamt > 0 ? aamt : int256(0)) - int256(amt);
        (,,,, uint256 pamt,,) = investor.positions(id);
        int256 namt = int256(pamt) + bas;
        if (namt < 0) {
            fee = uint256(0 - namt) * performanceFee / 10000;
            fee = fee * (1e18 - rebate) / 1e18;
            // leave in contract, mintProtocolReserves will happen
        }
        // Cap bas (basis change) to position size
        if (bas < 0 - int256(pamt)) bas = 0 - int256(pamt);
        return (bas, fee);
    }

    function _maybeSetBasisToInitialRate(uint256 id, int256 bas, int256 sha, int256 abor)
        internal
        view
        returns (int256)
    {
        (, address pol, uint256 str, uint256 out,, uint256 psha,) = investor.positions(id);
        if (out != block.timestamp || psha > 0) return bas;
        IStrategy strategy = IStrategy(investor.strategies(str));
        IOracle oracle = IOracle(IPool(pol).oracle());
        uint256 tokenBasis = 10 ** IERC20(IPool(pol).asset()).decimals();
        uint256 price = (uint256(oracle.latestAnswer()) * 1e18) / (10 ** oracle.decimals());
        uint256 value = strategy.rate(uint256(sha)) * tokenBasis / 1e18;
        return int256(value * 1e18 / price) - abor;
    }

    function _checkLife(uint256 id, int256 sha, int256 bor) internal view {
        (,,,,, uint256 psha, uint256 pbor) = investor.positions(id);
        if (_life(id, uint256(int256(psha)+sha), uint256(int256(pbor)+bor)) < 1e18) {
            revert Undercollateralized();
        }
    }

    function kill(uint256 id, bytes calldata dat, address kpr)
        external
        auth
        returns (uint256 sha, uint256 bor, uint256 amt, uint256 fee, uint256 bal)
    {
        IPool pool;
        IERC20 asset;
        uint256 lif = life(id);

        {
            if (lastEditBlock[id] == block.number) revert NoEditingInSameBlock();
            lastEditBlock[id] = block.number;
        }

        {
            if (lif >= 1e18) revert PositionNotLiquidatable();
            address pol;
            (, pol,,,, sha,) = investor.positions(id);
            pool = IPool(pol);
            asset = IERC20(pool.asset());
            // Burn maximum amount of strategy shares
            if (lif > softLiquidationThreshold) {
                sha = sha * softLiquidationSize / 10000;
            }
        }

        {
            amt = strategyProxy.burn(_positionStrategy(id), address(asset), sha, dat);
        }

        // Collect liquidation fee
        // Minting protocol reserves before repay to allow it's use for bad debt
        fee = amt * liquidationFee / 10000;
        uint256 haf = fee / 2;
        if (fee > 0) {
            // Pay keeper
            push(asset, kpr, haf);
            // Pay protocol by minting reserves
            // leave in contract, mintProtocolReserves will happen
        }

        {
            (,,,,,, bor) = investor.positions(id);
            // Repay loan
            if (lif > softLiquidationThreshold) {
                bor = min(bor, (amt - fee) * 1e18 / pool.getUpdatedIndex());
            }
            asset.approve(address(pool), amt - fee);
            bal = pool.repay(bor);
            if (amt - fee - bal > 0) {
                push(asset, _positionOwner(id), amt - fee - bal);
            }
        }
    }

    function _positionStrategy(uint256 id) internal view returns (address) {
        (,, uint256 str,,,,) = investor.positions(id);
        return investor.strategies(str);
    }

    function _positionOwner(uint256 id) internal view returns (address) {
        (address own,,,,,,) = investor.positions(id);
        if (own == address(positionManager)) {
            own = positionManager.ownerOf(id);
        }
        return own;
    }

    function mintProtocolReserves(address pool) public auth {
        IERC20 asset = IERC20(IPool(pool).asset());
        uint256 amt = IERC20(pool).balanceOf(address(this));
        asset.approve(address(pool), amt);
        IPool(pool).mint(amt, address(0));
    }
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

interface IOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IInvestor {
    function nextPosition() external view returns (uint256);
    function strategies(uint256) external view returns (address);
    function positions(uint256) external view returns (address, address, uint256, uint256, uint256, uint256, uint256);
    function life(uint256) external view returns (uint256);
    function earn(address, address, uint256, uint256, uint256, bytes calldata) external returns (uint256);
    function edit(uint256, int256, int256, bytes calldata) external;
    function kill(uint256, bytes calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPositionManager {
    function mint(address to, address pol, uint256 str, uint256 amt, uint256 bor, bytes calldata dat) external;
    function edit(uint256 id, int256 amt, int256 bor, bytes calldata dat) external;
    function burn(uint256 id) external;
    function approve(address spender, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id) external;
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 id) external view returns (address);
    function investor() external view returns (address);
}