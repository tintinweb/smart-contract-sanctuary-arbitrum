// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    function decimals() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IStrategy {
    function rate(uint256 amt) external view returns (uint256);
    function mint(uint256 amt) external returns (uint256);
    function burn(uint256 amt) external returns (uint256);
}

contract Rodeo {
    // TODO remove
    event log_named_uint(string key, uint256 val);

    error UnknownFile();
    error Unauthorized();
    error TransferFailed();
    error InsufficientBalance();
    error InsufficientAllowance();
    error InsufficientAmountForRepay();
    error InvalidStrategy();
    error BorrowTooSmall();
    error BorrowTooLarge();
    error PositionNotLiquidatable();
    error UtilizationTooHigh();
    error Undercollateralized();

    struct Position {
        address owner;
        address strategy;
        uint256 amount;
        uint256 shares;
        uint256 borrow;
    }

    // Constants
    string public constant name = "Rodeo Interest Bearing USDC";
    string public constant symbol = "ribUSDC";
    uint8 public constant decimals = 6;
    uint256 public constant factor = 1e6;
    IERC20 public immutable asset;

    // Config
    uint256 public lastGain;
    uint256 public borrowMin = 100e6;
    uint256 public borrowFactor = 900000000000000000; // 90%
    uint256 public liquidationFactor = 950000000000000000; //  95%
    uint256 public liquidationFeeMax = 1000000000; // 1000$
    uint256 public supplyRateBase = 0;
    uint256 public supplyRateKink = 800000000000000000; // 80%
    uint256 public supplyRateLow = 1030568239;
    uint256 public supplyRateHigh = 12683916793;
    uint256 public borrowRateBase = 475646879;
    uint256 public borrowRateKink = 800000000000000000; // 80%
    uint256 public borrowRateLow = 1109842719;
    uint256 public borrowRateHigh = 7927447995;
    mapping(address => bool) public exec;
    mapping(address => bool) public strategies;

    // Values
    uint256 public nextPosition;
    uint256 public totalSupply;
    uint256 public supplyIndex = 1e18;
    uint256 public totalBorrow;
    uint256 public borrowIndex = 1e18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(uint256 => Position) public positions;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event Approval(address indexed src, address indexed guy, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);
    event Earn(
        address indexed usr,
        uint256 indexed id,
        address indexed str,
        uint256 amt,
        uint256 bor
    );
    event Sell(
        address indexed usr,
        uint256 indexed id,
        uint256 sha,
        uint256 bor,
        uint256 amt
    );
    event Save(address indexed usr, uint256 indexed id, uint256 amt);
    event Kill(
        address indexed usr,
        uint256 indexed id,
        address indexed kpr,
        uint256 amt,
        uint256 bor,
        uint256 fee
    );

    constructor(address _asset) {
        asset = IERC20(_asset);
        lastGain = block.timestamp;
        exec[msg.sender] = true;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "borrowMin") {
            borrowMin = data;
        } else if (what == "borrowFactor") {
            borrowFactor = data;
        } else if (what == "liquidationFactor") {
            liquidationFactor = data;
        } else if (what == "liquidationFeeMax") {
            liquidationFeeMax = data;
        } else if (what == "supplyRateBase") {
            supplyRateBase = data;
        } else if (what == "supplyRateKink") {
            supplyRateKink = data;
        } else if (what == "supplyRateLow") {
            supplyRateLow = data;
        } else if (what == "supplyRateHigh") {
            supplyRateHigh = data;
        } else if (what == "borrowRateBase") {
            borrowRateBase = data;
        } else if (what == "borrowRateKink") {
            borrowRateKink = data;
        } else if (what == "borrowRateLow") {
            borrowRateLow = data;
        } else if (what == "borrowRateHigh") {
            borrowRateHigh = data;
        } else {
            revert UnknownFile();
        }
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") {
            exec[data] = !exec[data];
        } else if (what == "strategies") {
            strategies[data] = !strategies[data];
        } else {
            revert UnknownFile();
        }
        emit FileAddress(what, data);
    }

    function levy(address tkn, uint256 amt) external auth {
        if (tkn == address(0)) {
            msg.sender.call{value: amt}("");
        } else {
            IERC20(tkn).transfer(msg.sender, amt);
        }
    }

    function transfer(address dst, uint256 amt) external returns (bool) {
        return transferFrom(msg.sender, dst, amt);
    }

    function transferFrom(address src, address dst, uint256 amt)
        public
        returns (bool)
    {
        if (balanceOf[src] < amt) revert InsufficientBalance();
        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint256).max
        ) {
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

    // Supply asset for lending
    function mint(address usr, uint256 amt) external {
        pull(msg.sender, amt);
        gain();
        uint256 sha = amt * 1e18 / supplyIndex;
        balanceOf[usr] = balanceOf[usr] + sha;
        totalSupply = totalSupply + sha;
        emit Transfer(address(0), usr, sha);
    }

    // Withdraw supplied asset
    function burn(uint256 sha) external {
        gain();
        uint256 amt = sha * supplyIndex / 1e18;
        if (balanceOf[msg.sender] < sha) revert InsufficientBalance();
        if (asset.balanceOf(address(this)) < amt) revert UtilizationTooHigh();
        balanceOf[msg.sender] = balanceOf[msg.sender] - sha;
        totalSupply = totalSupply - sha;
        push(msg.sender, amt);
        emit Transfer(msg.sender, address(0), sha);
    }

    // Invest in strategy, providing collateral and optionally borrowing for leverage
    function earn(address str, uint256 amt, uint256 bor)
        external
        returns (uint256)
    {
        if (!strategies[str]) revert InvalidStrategy();
        if (bor != 0 && bor < borrowMin) revert BorrowTooSmall();
        if (bor > getBorrowAvailable()) revert BorrowTooLarge();
        pull(msg.sender, amt);
        gain();
        uint256 id = nextPosition++;
        Position storage p = positions[id];
        p.owner = msg.sender;
        p.strategy = str;
        p.amount = amt + bor;
        asset.approve(str, amt + bor);
        p.shares = IStrategy(str).mint(amt + bor);
        uint256 borBase = bor * 1e18 / borrowIndex;
        p.borrow = borBase;
        totalBorrow += borBase;
        if (life(id) < 1e18) revert Undercollateralized();
        emit Earn(msg.sender, id, str, amt, bor);
        return id;
    }

    // Divest from strategy, repay borrow and collect surplus
    function sell(uint256 id, uint256 sha, uint256 bor) external {
        gain();
        Position storage p = positions[id];
        if (p.owner != msg.sender) revert Unauthorized();
        if (bor == type(uint256).max) {
            bor = (p.borrow + 1) * borrowIndex / 1e18;
        }
        uint256 amt = IStrategy(p.strategy).burn(sha);
        if (bor > amt) revert InsufficientAmountForRepay();
        amt -= bor;
        p.shares -= sha;
        uint256 borBase = bor * 1e18 / borrowIndex;
        p.borrow -= borBase;
        totalBorrow -= borBase;
        push(msg.sender, amt);
        if (life(id) < 1e18) revert Undercollateralized();
        emit Sell(msg.sender, id, sha, bor, amt);
    }

    // Provide more collateral for position
    function save(uint256 id, uint256 amt) external {
        pull(msg.sender, amt);
        gain();
        Position storage p = positions[id];
        if (p.owner != msg.sender) revert Unauthorized();
        asset.approve(p.strategy, amt);
        p.amount += amt;
        p.shares += IStrategy(p.strategy).mint(amt);
        emit Save(msg.sender, id, amt);
    }

    // Liquidate position with health <1e18
    function kill(uint256 id) external {
        if (life(id) >= 1e18) revert PositionNotLiquidatable();
        Position storage p = positions[id];
        uint256 bor = p.borrow * borrowIndex / 1e18;
        uint256 amt = IStrategy(p.strategy).burn(p.shares);
        uint256 lft = amt - min(amt, bor);
        uint256 fee = min(liquidationFeeMax, lft / 2);
        totalBorrow -= p.borrow;
        p.shares = 0;
        p.borrow = 0;
        push(msg.sender, fee);
        emit Kill(p.owner, id, msg.sender, amt, bor, fee);
    }

    // Calculates position health (<1e18 is liquidatable)
    function life(uint256 id) public view returns (uint256) {
        Position memory p = positions[id];
        if (p.borrow == 0) return 1e18;
        return (IStrategy(p.strategy).rate(p.shares) * liquidationFactor / 1e18)
            * 1e18
            / (p.borrow * borrowIndex / 1e18);
    }

    // Accrue interest to indexes
    function gain() public {
        uint256 time = block.timestamp - lastGain;
        if (time > 0) {
            uint256 utilization = getUtilization();
            borrowIndex +=
                (borrowIndex * getBorrowRate(utilization) * time) / 1e18;
            supplyIndex +=
                (supplyIndex * getSupplyRate(utilization) * time) / 1e18;
        }
    }

    function pull(address usr, uint256 amt) internal {
        if (!asset.transferFrom(usr, address(this), amt)) revert TransferFailed();
    }

    function push(address usr, uint256 amt) internal {
        if (!asset.transfer(usr, amt)) revert TransferFailed();
    }

    function getSupplyRate(uint256 utilization) public view returns (uint256) {
        if (utilization <= supplyRateKink) {
            return supplyRateBase + (supplyRateLow * utilization / 1e18);
        } else {
            return supplyRateBase
                + (supplyRateLow * supplyRateKink / 1e18)
                + (supplyRateHigh * (utilization - supplyRateKink) / 1e18);
        }
    }

    function getBorrowRate(uint256 utilization) public view returns (uint256) {
        if (utilization <= borrowRateKink) {
            return borrowRateBase + (borrowRateLow * utilization / 1e18);
        } else {
            return borrowRateBase
                + (borrowRateLow * utilization / 1e18)
                + (borrowRateHigh * (utilization - borrowRateKink) / 1e18);
        }
    }

    function getUtilization() public view returns (uint256) {
        uint256 totalSupply_ = totalSupply * supplyIndex / 1e18;
        uint256 totalBorrow_ = totalBorrow * borrowIndex / 1e18;
        if (totalSupply_ == 0) {
            return 0;
        } else {
            return totalBorrow_ * 1e18 / totalSupply_;
        }
    }

    function getBorrowAvailable() public view returns (uint256) {
        uint256 totalSupply_ = totalSupply * supplyIndex / 1e18;
        uint256 totalBorrow_ = totalBorrow * borrowIndex / 1e18;
        return totalSupply_ - totalBorrow_;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}