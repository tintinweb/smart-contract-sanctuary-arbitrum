// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Util} from "./Util.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IVester} from "./interfaces/IVester.sol";
import {IPrivateInvestors} from "./interfaces/IPrivateInvestors.sol";

contract PrivateInvestorsRewarder is Util {
    mapping(address => uint256) public claimed;
    IPrivateInvestors public privateInvestors;
    IVester public vester;
    IERC20 public token;
    uint256 public totalRewards;
    uint256 public totalClaimed;
    uint256 public scheduleCliff = 0;
    uint256 public scheduleInitial = 0.05e18;
    uint256 public scheduleDuration = 365 days;

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event Donated(uint256 amount);
    event Claimed(address indexed target, uint256 amount);

    error DepositsTimeIsNotOver();

    constructor(address _privateInvestors, address _vester, address _token) {
        privateInvestors = IPrivateInvestors(_privateInvestors);
        vester = IVester(_vester);
        token = IERC20(_token);
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "paused") paused = data == 1;
        if (what == "scheduleCliff") scheduleCliff = data;
        if (what == "scheduleInitial") scheduleInitial = data;
        if (what == "scheduleDuration") scheduleDuration = data;
        if (what == "totalRewards") totalRewards = data;
        emit File(what, data);
    }

    function file(bytes32 what, address data) public auth {
        if (what == "exec") exec[data] = !exec[data];
        if (what == "privateInvestors") privateInvestors = IPrivateInvestors(data);
        if (what == "vester") vester = IVester(data);
        if (what == "token") token = IERC20(data);
        emit File(what, data);
    }

    function donate(uint256 amount) external auth {
        if (block.timestamp < privateInvestors.depositEnd()) revert DepositsTimeIsNotOver();
        pull(token, msg.sender, amount);
        totalRewards += amount;
        emit Donated(amount);
    }

    function claim() external loop live {
        (uint256 totalDepositedAmount, uint256 depositedAmount) = getPrivateInvestorInfo(msg.sender);
        uint256 claimable = totalRewards * depositedAmount / totalDepositedAmount;
        if (claimed[msg.sender] > claimable) {
            claimable = 0;
        } else {
            claimable -= claimed[msg.sender];
        }

        if (claimable > 0) {
            claimed[msg.sender] += claimable;
            totalClaimed += claimable;

            token.approve(address(vester), claimable);
            vester.vest(4, msg.sender, address(token), claimable, scheduleInitial, scheduleCliff, scheduleDuration);

            emit Claimed(msg.sender, claimable);
        }
    }

    function getInfo(address investor) external view returns (uint256, uint256, uint256, uint256) {
        (uint256 totalDepositedAmount, uint256 depositedAmount) = getPrivateInvestorInfo(investor);
        uint256 investorRewards = totalRewards * depositedAmount / totalDepositedAmount;

        return (totalRewards, investorRewards, totalClaimed, claimed[investor]);
    }

    function getPrivateInvestorInfo(address investor)
        private
        view
        returns (uint256 totalDepositedAmount, uint256 depositedAmount)
    {
        totalDepositedAmount = privateInvestors.totalDeposits();
        (depositedAmount,) = privateInvestors.users(investor);
    }

    function rescueToken(address token, uint256 amount) external auth {
        IERC20(token).transfer(msg.sender, amount);
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

interface IVester {
    function vest(
        uint256 source,
        address target,
        address token,
        uint256 amount,
        uint256 initial,
        uint256 cliff,
        uint256 time
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PrivateInvestors} from "../PrivateInvestors.sol";

interface IPrivateInvestors {
    function users(address) external view returns (uint256, bool);
    function totalDeposits() external view returns (uint256);
    function depositEnd() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Util} from "./Util.sol";
import {IERC20} from "./interfaces/IERC20.sol";

interface IVester {
    function vest(address user, address token, uint256 amount, uint256 initial, uint256 time) external;
}

interface IXRDO {
    function mint(address to, uint256 amount) external;
}

// Allows investors to deposit funds once whitelisted and claim tokens at a given price
contract PrivateInvestors is Util {
    error OverCap();
    error SoldOut();
    error NoAmount();
    error DepositOver();
    error DepositNotStarted();
    error VestingNotStarted();
    error AlreadyClaimed();
    error NotWhitelisted();

    struct User {
        uint256 amount;
        bool claimed;
    }

    IERC20 public paymentToken;
    IERC20 public rdo;
    IERC20 public xrdo;
    IVester public vester;
    IERC20 public rbcNft;
    uint256 public rbcCap;
    uint256 public rbcStart;
    uint256 public depositStart;
    uint256 public depositEnd;
    uint256 public depositCap;
    uint256 public defaultCap;
    uint256 public defaultPartnerCap;
    uint256 public price;
    uint256 public percent;
    uint256 public initial;
    uint256 public vesting;
    uint256 public totalUsers;
    uint256 public totalDeposits;
    mapping(address => User) public users;
    mapping(address => uint256) public whitelist;

    event FileInt(bytes32 what, uint256 data);
    event FileAddress(bytes32 what, address data);
    event Deposit(address indexed user, uint256 amount);
    event SetUser(address indexed user, uint256 amount);
    event Vest(address indexed user, uint256 rdoAmount, uint256 xrdoAmount);

    constructor(address _paymentToken, uint256 _depositEnd) {
        paymentToken = IERC20(_paymentToken);
        depositEnd = _depositEnd;
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) public auth {
        if (what == "paused") paused = data == 1;
        if (what == "depositStart") depositStart = data;
        if (what == "depositEnd") depositEnd = data;
        if (what == "depositCap") depositCap = data;
        if (what == "defaultCap") defaultCap = data;
        if (what == "defaultPartnerCap") defaultPartnerCap = data;
        if (what == "rbcCap") rbcCap = data;
        if (what == "rbcStart") rbcStart = data;
        if (what == "price") price = data;
        if (what == "percent") percent = data;
        if (what == "initial") initial = data;
        if (what == "vesting") vesting = data;
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) public auth {
        if (what == "exec") exec[data] = !exec[data];
        if (what == "rdo") rdo = IERC20(data);
        if (what == "xrdo") xrdo = IERC20(data);
        if (what == "vester") vester = IVester(data);
        if (what == "rbcNft") rbcNft = IERC20(data);
        emit FileAddress(what, data);
    }

    function setUser(address target, uint256 amount) public auth {
        if (block.timestamp > depositEnd) revert DepositOver();
        User storage user = users[target];
        if (user.amount == 0) totalUsers += 1;
        uint256 previousAmount = user.amount;
        user.amount = amount;
        totalDeposits = totalDeposits + amount - previousAmount;
        emit SetUser(target, amount);
    }

    function setWhitelist(address[] calldata targets, uint256 cap) external auth {
        for (uint256 i = 0; i < targets.length; i++) {
            whitelist[targets[i]] = cap;
        }
    }

    function collect(address token, uint256 amount, address to) external auth {
        IERC20(token).transfer(to, amount);
    }

    function deposit(uint256 amount) external loop live {
        uint256 cap = getCap(msg.sender);
        if (cap == 0) revert NotWhitelisted();
        if (totalDeposits + amount > depositCap) revert SoldOut();
        if (block.timestamp < depositStart) revert DepositNotStarted();
        if (block.timestamp > depositEnd) revert DepositOver();
        pull(paymentToken, msg.sender, amount);
        User storage user = users[msg.sender];
        if (user.amount == 0) totalUsers += 1;
        totalDeposits += amount;
        user.amount += amount;
        if (user.amount > cap) revert OverCap();
        emit Deposit(msg.sender, amount);
    }

    function vest(address target) external loop live {
        if (target != msg.sender && !exec[msg.sender]) revert Unauthorized();
        User storage user = users[target];
        if (block.timestamp < depositEnd) revert VestingNotStarted();
        if (user.amount == 0) revert NoAmount();
        if (user.claimed) revert AlreadyClaimed();
        user.claimed = true;
        uint256 amountScaled = user.amount * 1e18 / (10 ** paymentToken.decimals());
        uint256 amount = amountScaled * 1e18 / price;
        uint256 rdoAmount = amount * percent / 1e18;
        rdo.approve(address(vester), rdoAmount);
        vester.vest(target, address(rdo), rdoAmount, initial, vesting);
        rdo.approve(address(xrdo), amount - rdoAmount);
        IXRDO(address(xrdo)).mint(address(this), amount - rdoAmount);
        uint256 xrdoAmount = xrdo.balanceOf(address(this));
        xrdo.approve(address(vester), xrdoAmount);
        vester.vest(target, address(xrdo), xrdoAmount, initial, vesting);
        emit Vest(target, rdoAmount, xrdoAmount);
    }

    function getCap(address target) public view returns (uint256) {
        uint256 cap = whitelist[target];
        if (cap > 0) {
            if (rbcStart != 0 && block.timestamp >= rbcStart && defaultPartnerCap > cap) {
                return defaultPartnerCap;
            }
            return cap;
        }
        if (block.timestamp > rbcStart && address(rbcNft) != address(0) && rbcNft.balanceOf(target) > 0) {
            return rbcCap;
        }
        return defaultCap;
    }

    function getUser(address target) external view returns (uint256, uint256, bool) {
        User memory user = users[target];
        return (user.amount, getCap(target), user.claimed);
    }
}