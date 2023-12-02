// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Strategy} from "../Strategy.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {PartnerProxy} from "../PartnerProxy.sol";
import {IVault4626} from "../interfaces/IVault4626.sol";
import {IRewarderMiniChefV2} from "../interfaces/IRewarderMiniChefV2.sol";

interface IJonesGlpAdapter {
    function usdc() external view returns (address);
    function vaultRouter() external view returns (address);
    function stableVault() external view returns (address);
    function depositStable(uint256, bool) external;
}

interface IJonesGlpVaultRouter {
    function EXIT_COOLDOWN() external view returns (uint256);
    function stableRewardTracker() external view returns (address);
    function rewardCompounder(address) external view returns (address);
    function withdrawSignal(address, uint256) external view returns (uint256, uint256, bool, bool);
    function stableWithdrawalSignal(uint256 amt, bool cpd) external returns (uint256);
    function cancelStableWithdrawalSignal(uint256 eph, bool cpd) external;
    function redeemStable(uint256 eph) external returns (uint256);
    function claimRewards() external returns (uint256, uint256, uint256);
}

interface IJonesGlpRewardTracker {
    function stakedAmount(address) external view returns (uint256);
}

contract StrategyJonesUsdc is Strategy {
    string public constant name = "JonesDAO jUSDC";
    IJonesGlpAdapter public immutable adapter;
    IERC20 public immutable asset;
    IVault4626 public immutable vault;
    IJonesGlpVaultRouter public immutable vaultRouter;
    IJonesGlpRewardTracker public immutable tracker;
    IVault4626 public immutable jusdc;
    PartnerProxy public immutable proxy;
    IRewarderMiniChefV2 public immutable farming;
    uint256 public reserveRatio = 1000; // 10%
    uint256 public redeemFee = 100; // 1%
    uint256 public signaledStablesEpoch = 0;

    event SetReserveRatio(uint256);
    event SetRedeemFee(uint256);

    constructor(address _strategyHelper, address _proxy, address _adapter, address _farming) Strategy(_strategyHelper) {
        proxy = PartnerProxy(payable(_proxy));
        adapter = IJonesGlpAdapter(_adapter);
        asset = IERC20(adapter.usdc());
        vault = IVault4626(adapter.stableVault());
        vaultRouter = IJonesGlpVaultRouter(adapter.vaultRouter());
        tracker = IJonesGlpRewardTracker(vaultRouter.stableRewardTracker());
        jusdc = IVault4626(vaultRouter.rewardCompounder(address(asset)));
        farming = IRewarderMiniChefV2(_farming);
    }

    function setReserveRatio(uint256 val) public auth {
        reserveRatio = val;
        emit SetReserveRatio(val);
    }

    function setRedeemFee(uint256 val) public auth {
        redeemFee = val;
        emit SetRedeemFee(val);
    }

    function _rate(uint256 sha) internal view override returns (uint256) {
        return _rateWithOptions(sha, true);
    }

    function _rateWithOptions(uint256 sha, bool applyRedeemFee) internal view returns (uint256) {
        if (totalShares == 0) return 0;
        (uint256 bal,) = farming.userInfo(1, address(proxy));
        uint256 tma = jusdc.previewRedeem(bal);
        if (signaledStablesEpoch > 0) {
            (, uint256 shares,,) = vaultRouter.withdrawSignal(address(proxy), signaledStablesEpoch);
            tma += shares;
        }
        uint256 ast0 = asset.balanceOf(address(this)) * 99 / 100;
        uint256 ast1 = vault.previewRedeem(tma);
        uint256 ast = (ast0 + ast1);
        if (applyRedeemFee) ast = ast * (10000 - redeemFee) / 10000;
        uint256 val = strategyHelper.value(address(asset), ast);
        return sha * val / totalShares;
    }

    // This strategy's value is a combination of the (~10%) USDC reserves + value of the jUSDC held
    // We also don't mint jUSDC right away but keep the USDC for withdrawal
    // So to calculate the amount of shares to give we mint based on the proportion of the total USD value
    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        uint256 slp = getSlippage(dat);
        uint256 tma = _rateWithOptions(totalShares, false);
        pull(IERC20(ast), msg.sender, amt);
        IERC20(ast).approve(address(strategyHelper), amt);
        uint256 bal = strategyHelper.swap(ast, address(asset), amt, slp, address(this));
        uint256 val = strategyHelper.value(address(asset), bal);
        return tma == 0 ? val : val * totalShares / tma;
    }

    // Send off some of the reserve USDC, if none is available the user will have to wait for the next `redeemStable`
    function _burn(address ast, uint256 sha, bytes calldata dat) internal override returns (uint256) {
        uint256 slp = getSlippage(dat);
        uint256 amt = _rateWithOptions(sha, true) * (10 ** asset.decimals()) / strategyHelper.price(address(asset));
        asset.approve(address(strategyHelper), amt);
        return strategyHelper.swap(address(asset), ast, amt, slp, msg.sender);
    }

    // Here we deposit & mint jUSDC or ask to withdraw some USDC by next epoch based on the target `reserveRatio`
    // This is the only place that we interract with the adapter / router / vault for jUSDC
    // We also claim pending rewards for manual compounding
    // (automatic compounding would make the withdrawal math more trucky)
    function _earn() internal override {
        {
            address reward = farming.SUSHI();
            proxy.call(address(farming), 0, abi.encodeWithSignature("harvest(uint256,address)", 1, address(this)));
            uint256 bal = IERC20(reward).balanceOf(address(this));
            uint256 val = strategyHelper.value(reward, bal);
            if (val > 0.5e18) {
                strategyHelper.swap(reward, address(asset), bal, slippage, address(this));
            }
        }

        proxy.call(address(vaultRouter), 0, abi.encodeWithSignature("claimRewards()"));
        proxy.pull(address(asset));

        uint256 bal = asset.balanceOf(address(this));
        uint256 val = strategyHelper.value(address(asset), bal);
        uint256 tot = _rate(totalShares);
        uint256 tar = tot * reserveRatio / 10000;
        if (val > tar) {
            if (signaledStablesEpoch > 0) {
                proxy.call(
                    address(vaultRouter),
                    0,
                    abi.encodeWithSelector(
                        vaultRouter.cancelStableWithdrawalSignal.selector, signaledStablesEpoch, true
                    )
                );
                signaledStablesEpoch = 0;
            }
            uint256 amt = ((val - tar) * strategyHelper.price(address(asset)) / 1e18) * (10 ** asset.decimals()) / 1e18;
            IERC20(asset).transfer(address(proxy), amt);
            proxy.approve(address(asset), address(adapter));
            proxy.call(address(adapter), 0, abi.encodeWithSelector(adapter.depositStable.selector, amt, true));
            proxy.approve(address(jusdc), address(farming));
            proxy.call(address(farming), 0, abi.encodeWithSelector(farming.deposit.selector, 1, jusdc.balanceOf(address(proxy)), address(proxy)));
        }
        if (val < tar) {
            if (signaledStablesEpoch != 0 && block.timestamp > signaledStablesEpoch) {
                proxy.call(
                    address(vaultRouter),
                    0,
                    abi.encodeWithSelector(vaultRouter.redeemStable.selector, signaledStablesEpoch)
                );
                proxy.pull(address(asset));
                signaledStablesEpoch = 0;
            } else if (signaledStablesEpoch == 0) {
                uint256 amt = ((tar - val) * strategyHelper.price(address(asset)) / 1e18) * (10 ** asset.decimals()) / 1e18;
                uint256 shaV = vault.previewWithdraw(amt);
                uint256 sha = jusdc.previewWithdraw(shaV);
                proxy.call(address(farming), 0, abi.encodeWithSelector(farming.withdraw.selector, 1, sha, address(proxy)));
                bytes memory dat = proxy.call(
                    address(vaultRouter),
                    0,
                    abi.encodeWithSelector(vaultRouter.stableWithdrawalSignal.selector, sha, true)
                );
                signaledStablesEpoch = abi.decode(dat, (uint256));
            }
        }
    }

    function _exit(address str) internal override {
        push(IERC20(address(asset)), str, asset.balanceOf(address(this)));
        proxy.setExec(str, true);
        proxy.setExec(address(this), false);
    }

    function _move(address old) internal override {
        signaledStablesEpoch = StrategyJonesUsdc(old).signaledStablesEpoch();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
        uint256 _cap = cap;
        totalShares += sha;
        if (_cap != 0 && rate(totalShares) > _cap) revert OverCap();
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

    function earn() public payable {
        uint256 _totalShares = totalShares;
        if (!keepers[msg.sender]) revert NotKeeper();
        if (_totalShares == 0) return;
        uint256 bef = rate(_totalShares);
        _earn();
        uint256 aft = rate(_totalShares);
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

import {Util} from "./Util.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract PartnerProxy is Util {
    error CallReverted();

    constructor() {
        exec[msg.sender] = true;
    }

    receive() external payable {}

    function setExec(address usr, bool can) public auth {
        exec[usr] = can;
    }

    function call(address tar, uint256 val, bytes calldata dat) public payable auth returns (bytes memory) {
        (bool suc, bytes memory res) = tar.call{value: val}(dat);
        if (!suc) revert CallReverted();
        return res;
    }

    function pull(address tkn) public auth {
        IERC20(tkn).transfer(msg.sender, IERC20(tkn).balanceOf(address(this)));
    }

    function approve(address tkn, address tar) public auth {
        IERC20(tkn).approve(tar, IERC20(tkn).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault4626 {
    function balanceOf(address) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function deposit(uint256 amount, address to) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
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