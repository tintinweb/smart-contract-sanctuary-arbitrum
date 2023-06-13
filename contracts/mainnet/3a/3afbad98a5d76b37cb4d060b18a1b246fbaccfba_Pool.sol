// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() {
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = block.chainid);
    }

    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}

contract ERC20 {
    error InsufficientBalance();
    error InsufficientAllowance();

    string public name;
    string public symbol;
    uint8 public immutable decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed src, address indexed guy, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address dst, uint256 amt) external returns (bool) {
        return transferFrom(msg.sender, dst, amt);
    }

    function transferFrom(address src, address dst, uint256 amt) public returns (bool) {
        if (balanceOf[src] < amt) revert InsufficientBalance();
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            if (allowance[src][msg.sender] < amt) revert InsufficientAllowance();
            allowance[src][msg.sender] = allowance[src][msg.sender] - amt;
        }
        balanceOf[src] = balanceOf[src] - amt;
        balanceOf[dst] = balanceOf[dst] + amt;
        emit Transfer(src, dst, amt);
        return true;
    }

    function approve(address usr, uint256 amt) external returns (bool) {
        allowance[msg.sender][usr] = amt;
        emit Approval(msg.sender, usr, amt);
        return true;
    }

    function _mint(address usr, uint256 amt) internal {
        balanceOf[usr] = balanceOf[usr] + amt;
        totalSupply = totalSupply + amt;
        emit Transfer(address(0), usr, amt);
    }

    function _burn(address usr, uint256 amt) internal {
        if (balanceOf[usr] < amt) revert InsufficientBalance();
        balanceOf[usr] = balanceOf[usr] - amt;
        totalSupply = totalSupply - amt;
        emit Transfer(usr, address(0), amt);
    }
}

contract ERC20Permit is ERC20, Domain {
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) {}

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    function permit(address owr, address usr, uint256 val, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(owr != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(
                _getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owr, usr, val, nonces[owr]++, deadline))),
                v,
                r,
                s
            ) == owr,
            "ERC20: Invalid Signature"
        );
        allowance[owr][usr] = val;
        emit Approval(owr, usr, val);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Util} from "./Util.sol";
import {ERC20} from "./ERC20.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IRateModel} from "./interfaces/IRateModel.sol";

contract Pool is Util, ERC20 {
    error CapReached();
    error MintTooSmall();
    error BorrowTooSmall();
    error UtilizationTooHigh();
    error InsufficientAmountForRepay();

    IERC20 public immutable asset;
    IRateModel public rateModel;
    IOracle public oracle;
    uint256 public borrowMin;
    uint256 public borrowFactor;
    uint256 public liquidationFactor;
    uint256 public amountCap;
    uint256 public lastUpdate;
    uint256 public index = 1e18;
    uint256 public totalBorrow;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event Deposit(address indexed who, address indexed usr, uint256 amt, uint256 sha);
    event Withdraw(address indexed who, address indexed usr, uint256 amt, uint256 sha);
    event Borrow(address indexed who, uint256 amt, uint256 bor);
    event Repay(address indexed who, uint256 amt, uint256 bor);
    event Loss(address indexed who, uint256 amt, uint256 amttre, uint256 amtava);

    constructor(
        address _asset,
        address _rateModel,
        address _oracle,
        uint256 _borrowMin,
        uint256 _borrowFactor,
        uint256 _liquidationFactor,
        uint256 _amountCap
    )
        ERC20(
            string(abi.encodePacked("Rodeo Interest Bearing ", IERC20(_asset).name())),
            string(abi.encodePacked("rib", IERC20(_asset).symbol())),
            IERC20(_asset).decimals()
        )
    {
        asset = IERC20(_asset);
        rateModel = IRateModel(_rateModel);
        oracle = IOracle(_oracle);
        borrowMin = _borrowMin;
        borrowFactor = _borrowFactor;
        liquidationFactor = _liquidationFactor;
        amountCap = _amountCap;
        lastUpdate = block.timestamp;
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "paused") paused = data == 1;
        if (what == "borrowMin") borrowMin = data;
        if (what == "borrowFactor") borrowFactor = data;
        if (what == "liquidationFactor") liquidationFactor = data;
        if (what == "amountCap") amountCap = data;
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        if (what == "rateModel") rateModel = IRateModel(data);
        if (what == "oracle") oracle = IOracle(data);
        emit FileAddress(what, data);
    }

    // Supply asset for lending
    function mint(uint256 amt, address usr) external loop live {
        update();
        uint256 totalLiquidity = getTotalLiquidity();
        if (totalLiquidity + amt > amountCap) revert CapReached();
        uint256 sha = amt;
        if (totalLiquidity > 0) {
            sha = amt * totalSupply / totalLiquidity;
        }
        pull(asset, msg.sender, amt);
        _mint(usr, sha);
        emit Deposit(msg.sender, usr, amt, sha);
    }

    // Withdraw supplied asset
    function burn(uint256 sha, address usr) external loop live {
        update();
        uint256 amt = sha * getTotalLiquidity() / totalSupply;
        if (balanceOf[msg.sender] < sha) revert InsufficientBalance();
        if (asset.balanceOf(address(this)) < amt) revert UtilizationTooHigh();
        _burn(msg.sender, sha);
        push(asset, usr, amt);
        emit Withdraw(msg.sender, usr, amt, sha);
    }

    // Borrow from pool (called by Investor)
    function borrow(uint256 amt) external live auth returns (uint256) {
        update();
        if (amt < borrowMin) revert BorrowTooSmall();
        if (asset.balanceOf(address(this)) < amt) revert UtilizationTooHigh();
        uint256 bor = amt * 1e18 / index;
        totalBorrow += bor;
        push(asset, msg.sender, amt);
        emit Borrow(msg.sender, amt, bor);
        return bor;
    }

    // Repay pool (called by Investor)
    function repay(uint256 bor) external live auth returns (uint256) {
        update();
        uint256 amt = bor * index / 1e18;
        uint256 amtava = min(asset.allowance(msg.sender, address(this)), asset.balanceOf(msg.sender));
        // If the caller has less assest than debt to repay, try to burn reserves to make up the
        // gap, else, simply write off the borrow and let lenders take the hit
        if (amtava < amt) {
            uint256 totalLiquidity = getTotalLiquidity();
            uint256 amttre = balanceOf[address(0)] * totalLiquidity / totalSupply;
            uint256 usetre = min(amttre, amt - amtava);
            if (usetre > 0) {
                _burn(address(0), usetre * totalSupply / totalLiquidity);
            }
            emit Loss(msg.sender, amt, usetre, amtava);
            amt = amtava;
        }
        totalBorrow -= bor;
        pull(asset, msg.sender, amt);
        emit Repay(msg.sender, amt, bor);
        return amt;
    }

    // Levy allows an admin to collect some of the protocol reserves
    function levy(uint256 sha) external live auth {
        update();
        uint256 amt = sha * getTotalLiquidity() / totalSupply;
        _burn(address(0), sha);
        push(asset, msg.sender, amt);
        emit Withdraw(msg.sender, address(0), amt, sha);
    }

    // A minimal `burn()` to be used by users in case of emergency / frontend not working
    function emergency() external loop live {
        uint256 sha = balanceOf[msg.sender];
        uint256 amt = sha * getTotalLiquidity() / totalSupply;
        if (asset.balanceOf(address(this)) < amt) revert UtilizationTooHigh();
        _burn(msg.sender, sha);
        push(asset, msg.sender, amt);
        emit Withdraw(msg.sender, msg.sender, amt, sha);
    }

    // Accrue interest to index
    function update() public {
        uint256 time = block.timestamp - lastUpdate;
        if (time > 0) {
            uint256 utilization = getUtilization();
            index += (index * rateModel.rate(utilization) * time) / 1e18;
            lastUpdate = block.timestamp;
        }
    }

    function getUtilization() public view returns (uint256) {
        uint256 totalLiquidity = getTotalLiquidity();
        if (totalLiquidity == 0) return 0;
        return getTotalBorrow() * 1e18 / totalLiquidity;
    }

    function getTotalLiquidity() public view returns (uint256) {
        return asset.balanceOf(address(this)) + getTotalBorrow();
    }

    function getTotalBorrow() public view returns (uint256) {
        return totalBorrow * index / 1e18;
    }

    function getUpdatedIndex() public view returns (uint256) {
        uint256 time = block.timestamp - lastUpdate;
        uint256 utilization = getUtilization();
        return index + ((index * rateModel.rate(utilization) * time) / 1e18);
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

interface IOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRateModel {
    function rate(uint256) external view returns (uint256);
}