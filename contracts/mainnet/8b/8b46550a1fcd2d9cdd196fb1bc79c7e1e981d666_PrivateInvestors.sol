// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Util} from "./Util.sol";
import {IERC20} from "./interfaces/IERC20.sol";

interface IVesting {
    function vest(address user, address token, uint256 amount, uint256 initial, uint256 time) external;
}

interface IXRDO {
    function mint(uint256 amount, address to) external;
}

// Allows investors to deposit funds once whitelisted and claim tokens at a given price
contract PrivateInvestors is Util {
    error SoldOut();
    error DepositOver();
    error VestingNotStarted();
    error AlreadyClaimed();

    struct Tranche {
        uint256 cap;
        uint256 price;
        uint256 percent;
        uint256 initial;
        uint256 vesting;
    }
    struct User {
        uint256 amount;
        uint256 tranche;
        uint256 price;
        uint256 percent;
        uint256 initial;
        uint256 vesting;
        bool claimed;
    }

    Tranche[4] public tranches;
    IERC20 public paymentToken;
    IERC20 public rdo;
    IERC20 public xrdo;
    IVesting public vester;
    uint256 public depositEnd;
    uint256 public totalUsers;
    uint256 public totalDeposits;
    mapping(address => User) public users;

    event FileInt(bytes32 what, uint256 data);
    event FileAddress(bytes32 what, address data);
    event Deposit(address indexed user, uint256 amount, uint256 tranche);
    event SetUser(address indexed user, uint256 amount, uint256 price, uint256 percent, uint256 initial, uint256 vesting);
    event Vest(address indexed user, uint256 rdoAmount, uint256 xrdoAmount, uint256 initial, uint256 vesting);

    constructor(address _paymentToken, uint256 _depositEnd) {
        tranches[0] = Tranche(250000e6, 0.07e18, 0.5e18, 0.1e18, 6 * 30 days);
        tranches[1] = Tranche(1000000e6, 0.0725e18, 0.5e18, 0.1e18, 6 * 30 days);
        tranches[2] = Tranche(3000000e6, 0.075e18, 0.5e18, 0.1e18, 6 * 30 days);
        tranches[3] = Tranche(10000000e6, 0.08e18, 0.5e18, 0.1e18, 6 * 30 days);
        paymentToken = IERC20(_paymentToken);
        depositEnd = _depositEnd;
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) public auth {
        if (what == "paused") paused = data == 1;
        if (what == "depositEnd") depositEnd = data;
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) public auth {
        if (what == "exec") exec[data] = !exec[data];
        if (what == "rdo") rdo = IERC20(data);
        if (what == "xrdo") xrdo = IERC20(data);
        if (what == "vesting") vester = IVesting(data);
        emit FileAddress(what, data);
    }

    function setTranche(uint256 index, uint256 cap, uint256 price, uint256 percent, uint256 initial, uint256 vesting) public auth {
        tranches[index] = Tranche(cap, price, percent, initial, vesting);
    }

    function setUser(address target, uint256 amount, uint256 price, uint256 percent, uint256 initial, uint256 vesting) public auth {
        if (block.timestamp > depositEnd) revert DepositOver();
        User storage user = users[target];
        if (user.amount == 0) totalUsers += 1;
        uint256 previousAmount = user.amount;
        user.amount = amount;
        user.price = price;
        user.percent = percent;
        user.initial = initial;
        user.vesting = vesting;
        totalDeposits = totalDeposits + amount - previousAmount;
        emit SetUser(target, amount, price, percent, initial, vesting);
    }

    function collect(address token, uint256 amount, address to) public auth {
        IERC20(token).transfer(to, amount);
    }

    function deposit(uint256 amount) public loop live {
        uint256 tranche = type(uint256).max;
        uint256 totalCap;
        for (uint256 i = 0; i < 4; i++) {
            totalCap += tranches[i].cap;
            if (totalDeposits < totalCap) {
                tranche = i;
                break;
            }
        }
        if (tranche == type(uint256).max) revert SoldOut();
        if (block.timestamp > depositEnd) revert DepositOver();
        pull(paymentToken, msg.sender, amount);
        User storage user = users[msg.sender];
        if (user.amount == 0) totalUsers += 1;
        user.amount += amount;
        user.tranche = tranche;
        totalDeposits += amount;
        emit Deposit(msg.sender, amount, tranche);
    }

    function vest(address target) public loop live {
        if (target != msg.sender && !exec[msg.sender]) revert Unauthorized();
        User storage user = users[target];
        if (block.timestamp < depositEnd) revert VestingNotStarted();
        if (user.claimed) revert AlreadyClaimed();
        user.claimed = true;
        uint256 price = user.price;
        if (price == 0) price = tranches[user.tranche].price;
        uint256 amountScaled = user.amount * 1e18 / (10 ** paymentToken.decimals());
        uint256 amount = amountScaled * 1e18 / user.price;
        uint256 rdoAmount = amount * user.percent / 1e18;
        vester.vest(target, address(rdo), rdoAmount, user.initial, user.vesting);
        rdo.approve(address(xrdo), amount - rdoAmount);
        IXRDO(address(xrdo)).mint(amount - rdoAmount, address(this));
        uint256 xrdoAmount = xrdo.balanceOf(address(this));
        xrdo.approve(address(vester), xrdoAmount);
        vester.vest(target, address(xrdo), xrdoAmount, user.initial, user.vesting);
        emit Vest(target, rdoAmount, xrdoAmount, user.initial, user.vesting);
    }

    function getUser(address target) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        User memory user = users[target];
        Tranche memory tranche = tranches[user.tranche];
        if (user.price == 0) user.price = tranche.price;
        if (user.percent == 0) user.percent = tranche.percent;
        if (user.initial == 0) user.initial = tranche.initial;
        if (user.vesting == 0) user.vesting = tranche.vesting;
        return (user.amount, user.tranche, user.price, user.percent, user.initial, user.vesting, user.claimed);
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