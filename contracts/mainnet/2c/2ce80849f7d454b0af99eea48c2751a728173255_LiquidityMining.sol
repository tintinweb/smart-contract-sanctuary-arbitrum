// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Util} from "./Util.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IStrategyHelper} from "./interfaces/IStrategyHelper.sol";

// Incentivize liquidity with token rewards, based on SushiSwap's MiniChef
contract LiquidityMining is Util {
    struct UserInfo {
        uint256 amount;
        uint256 lp;
        uint256 boostLp;
        uint256 boostLock;
        int256 rewardDebt;
        uint256 lock;
    }

    struct PoolInfo {
        uint256 totalAmount;
        uint128 accRewardPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    IStrategyHelper public strategyHelper;
    IERC20 public lpToken;
    IERC20 public rewardToken;
    uint256 public totalAllocPoint;
    uint256 public rewardPerDay;
    uint256 public boostMax = 1e18;
    uint256 public boostMaxDuration = 365 days;
    uint256 public lpBoostAmount = 1e18;
    uint256 public lpBoostThreshold = 0.05e18;
    uint256 public earlyWithdrawFeeMax = 0.75e18;
    bool public emergencyBypassLock = false;
    IERC20[] public token;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to, uint256 lock);
    event DepositLp(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event WithdrawLp(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event WithdrawEarly(address indexed user, uint256 indexed pid, uint256 amount, uint256 fee, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event FileInt(bytes32 what, uint256 data);
    event FileAddress(bytes32 what, address data);
    event PoolAdd(uint256 indexed pid, uint256 allocPoint, address indexed token);
    event PoolSet(uint256 indexed pid, uint256 allocPoint);
    event PoolUpdate(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accRewardPerShare);

    constructor() {
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "paused") paused = data == 1;
        if (what == "rewardPerDay") rewardPerDay = data;
        if (what == "boostMax") boostMax = data;
        if (what == "boostMaxDuration") boostMaxDuration = data;
        if (what == "lpBoostAmount") lpBoostAmount = data;
        if (what == "lpBoostThreshold") lpBoostThreshold = data;
        if (what == "earlyWithdrawFeeMax") earlyWithdrawFeeMax = data;
        if (what == "emergencyBypassLock") emergencyBypassLock = data == 1;
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        if (what == "lpToken") lpToken = IERC20(data);
        if (what == "strategyHelper") strategyHelper = IStrategyHelper(data);
        if (what == "rewardToken") rewardToken = IERC20(data);
        emit FileAddress(what, data);
    }

    function poolAdd(uint256 allocPoint, address _token) public auth {
        totalAllocPoint = totalAllocPoint + allocPoint;
        token.push(IERC20(_token));

        poolInfo.push(
            PoolInfo({
                totalAmount: 0,
                accRewardPerShare: 0,
                lastRewardTime: uint64(block.timestamp),
                allocPoint: uint64(allocPoint)
            })
        );
        emit PoolAdd(token.length - 1, allocPoint, _token);
    }

    function poolSet(uint256 _pid, uint256 _allocPoint) public auth {
        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
        poolInfo[_pid].allocPoint = uint64(_allocPoint);
        emit PoolSet(_pid, _allocPoint);
    }

    function removeUser(uint256 pid, address usr, address to) public auth {
        UserInfo storage info = userInfo[pid][usr];
        _harvest(usr, pid, to);
        poolInfo[pid].totalAmount -= getBoostedAmount(info);
        uint256 amt = info.amount;
        uint256 amtLp = info.lp;
        info.amount = 0;
        info.lp = 0;
        info.boostLp = 0;
        info.boostLock = 0;
        info.rewardDebt = 0;
        info.lock = 0;
        token[pid].transfer(to, amt);
        lpToken.transfer(to, amtLp);
        emit Withdraw(usr, pid, amt, to);
        emit WithdrawLp(usr, pid, amtLp, to);
    }

    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    function pendingRewards(uint256 pid, address user) public view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[pid];
        UserInfo storage info = userInfo[pid][user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (block.timestamp > pool.lastRewardTime && pool.totalAmount != 0) {
            uint256 timeSinceLastReward = block.timestamp - pool.lastRewardTime;
            uint256 reward = timeSinceLastReward * rewardPerDay * pool.allocPoint / totalAllocPoint / 86400;

            accRewardPerShare = accRewardPerShare + ((reward * 1e12) / pool.totalAmount);
        }
        pending = uint256(int256((getBoostedAmount(info) * accRewardPerShare) / 1e12) - info.rewardDebt);
    }

    function poolUpdateMulti(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            poolUpdate(pids[i]);
        }
    }

    function poolUpdate(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            if (pool.totalAmount > 0) {
                uint256 timeSinceLastReward = block.timestamp - pool.lastRewardTime;
                uint256 reward = timeSinceLastReward * rewardPerDay * pool.allocPoint / totalAllocPoint / 86400;
                pool.accRewardPerShare = pool.accRewardPerShare + uint128((reward * 1e12) / pool.totalAmount);
            }
            pool.lastRewardTime = uint64(block.timestamp);
            poolInfo[pid] = pool;
            emit PoolUpdate(pid, pool.lastRewardTime, pool.totalAmount, pool.accRewardPerShare);
        }
    }

    function deposit(uint256 pid, uint256 amount, address to, uint256 lock) public loop live {
        token[pid].transferFrom(msg.sender, address(this), amount);
        _deposit(msg.sender, pid, amount, to, lock);
    }

    function _deposit(address usr, uint256 pid, uint256 amount, address to, uint256 lock) internal {
        PoolInfo memory pool = poolUpdate(pid);
        UserInfo storage info = userInfo[pid][to];
        _userUpdate(pid, info, lock, 0, int256(amount));
        emit Deposit(usr, pid, amount, to, lock);
    }

    function withdraw(uint256 pid, uint256 amount, address to) public loop live {
        _withdraw(msg.sender, pid, amount, to);
        token[pid].transfer(to, amount);
    }

    function withdrawWithUnwrap(uint256 pid, uint256 amount, address to) public loop live {
        _withdraw(msg.sender, pid, amount, to);
        IPool(address(token[pid])).burn(amount, to);
    }

    function _withdraw(address usr, uint256 pid, uint256 amount, address to) internal {
        PoolInfo memory pool = poolUpdate(pid);
        UserInfo storage info = userInfo[pid][usr];
        require(block.timestamp >= info.lock, "locked");
        _userUpdate(pid, info, 0, 0, 0 - int256(amount));
        emit Withdraw(msg.sender, pid, amount, to);
    }

    function withdrawEarly(uint256 pid, address to) public loop live {
        PoolInfo memory pool = poolUpdate(pid);
        UserInfo storage info = userInfo[pid][msg.sender];
        require(info.lock > 0, "no lock");
        require(block.timestamp < info.lock, "unlocked");
        // fee is % of max lock in time to unlock multiplied by feeMax multiplied by amount
        uint256 rate = earlyWithdrawFeeMax * (info.lock - block.timestamp) / boostMaxDuration;
        uint256 amount = info.amount;
        uint256 fee = amount * rate / 1e18;
        _userUpdate(pid, info, 0, 0, 0 - int256(amount));
        token[pid].transfer(to, amount - fee);
        token[pid].transfer(address(0), fee); // donate fee to reserve
        emit Withdraw(msg.sender, pid, amount - fee, to);
        emit WithdrawEarly(msg.sender, pid, amount - fee, fee, to);
    }

    function harvest(uint256 pid, address to) public loop live {
        _harvest(msg.sender, pid, to);
    }

    function _harvest(address usr, uint256 pid, address to) internal {
        PoolInfo memory pool = poolUpdate(pid);
        UserInfo storage info = userInfo[pid][usr];
        uint256 amount = getBoostedAmount(info);
        int256 total = int256(amount * pool.accRewardPerShare / 1e12);
        uint256 owed = uint256(total - info.rewardDebt);
        info.rewardDebt = total;
        if (owed != 0) {
            rewardToken.transfer(to, owed);
        }
        emit Harvest(usr, pid, owed);
    }

    function emergencyWithdraw(uint256 pid, address to) public loop live {
        UserInfo storage info = userInfo[pid][msg.sender];
        if (!emergencyBypassLock) require(block.timestamp >= info.lock, "locked");
        uint256 amount = info.amount;
        uint256 lpAmount = info.lp;
        _userUpdate(pid, info, 0, 0 - int256(lpAmount), 0 - int256(info.amount));
        info.rewardDebt = 0;
        if (amount > 0) token[pid].transfer(to, amount);
        if (lpAmount > 0) lpToken.transfer(to, lpAmount);
        emit Withdraw(msg.sender, pid, amount, to);
    }

    function depositLp(uint256 pid, address to, uint256 amount) public loop live {
        UserInfo storage info = userInfo[pid][to];
        lpToken.transferFrom(msg.sender, address(this), amount);
        _userUpdate(pid, info, 0, int256(amount), 0);
        emit DepositLp(msg.sender, pid, amount, to);
    }

    function withdrawLp(uint256 pid, uint256 amount, address to) public loop live {
        UserInfo storage info = userInfo[pid][msg.sender];
        _userUpdate(pid, info, 0, 0 - int256(amount), 0);
        lpToken.transfer(to, amount);
        emit WithdrawLp(msg.sender, pid, amount, to);
    }

    // Allow keeper / bot to update a user. So that when the value of their LP drops below 5%
    // but they are still earning as lp boosted they can be stopped
    function ping(uint256 pid, address user) external {
        UserInfo storage info = userInfo[pid][user];
        _userUpdate(pid, info, 0, 0, 0);
    }

    function _userUpdate(uint256 pid, UserInfo storage info, uint256 lock, int256 lp, int256 amount) internal {
        int256 prev = int256(getBoostedAmount(info));
        if (amount != 0) info.amount = uint256(int256(info.amount) + amount);
        if (lock > 0) {
            require(info.lock == 0, "already locked");
            info.lock = block.timestamp + min(lock, boostMaxDuration);
            info.boostLock = boostMax * min(lock, boostMaxDuration) / boostMaxDuration;
        }
        if (info.lock > 0 && amount < 0) {
            info.lock = 0;
            info.boostLock = 0;
        }
        if (lp != 0) {
            uint256 value = strategyHelper.value(IPool(address(token[pid])).asset(), info.amount);
            info.lp = uint256(int256(info.lp) + lp);
            uint256 lpValue = strategyHelper.value(address(lpToken), info.lp);
            if (lpValue > 0 && value > 0) {
                info.boostLp = (lpValue * 1e18 / value) > lpBoostThreshold ? lpBoostAmount : 0;
            } else if (info.boostLp > 0) {
                info.boostLp = 0;
            }
        }
        int256 next = int256(getBoostedAmount(info));
        info.rewardDebt += (next - prev) * int256(uint256(poolInfo[pid].accRewardPerShare)) / 1e12;
        poolInfo[pid].totalAmount = poolInfo[pid].totalAmount - uint256(prev) + uint256(next);
    }

    function getBoostedAmount(UserInfo storage info) internal view returns (uint256) {
        return info.amount * (1e18 + info.boostLock + info.boostLp) / 1e18;
    }

    function getUser(uint256 pid, address user)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        UserInfo memory info = userInfo[pid][user];
        uint256 value = strategyHelper.value(IPool(address(token[pid])).asset(), info.amount);
        uint256 lpValue = strategyHelper.value(address(lpToken), info.lp);
        uint256 owed = pendingRewards(pid, user);
        return (info.amount, info.lp, info.lock, info.boostLp, info.boostLock, owed, value, lpValue);
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