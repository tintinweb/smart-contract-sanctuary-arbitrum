// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Util} from "./Util.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";

contract Investor is Util {
    error InsufficientShares();
    error InsufficientBorrow();
    error InsufficientAmountForRepay();
    error InvalidPool();
    error InvalidStrategy();
    error PositionNotLiquidatable();
    error Undercollateralized();
    error OverMaxBorrowFactor();

    struct Position {
        address owner;
        address pool;
        address strategy;
        uint256 amount;
        uint256 shares;
        uint256 borrow;
    }

    uint256 public liquidationFee = 500;
    uint256 public performanceFee = 1000;
    uint256 public originationFee = 0;
    uint256 public nextPosition;
    mapping(address => bool) public pools;
    mapping(address => bool) public strategies;
    mapping(uint256 => Position) public positions;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event Earn(
        address indexed usr,
        uint256 indexed id,
        address pol,
        address indexed str,
        uint256 amt,
        uint256 bor,
        uint256 borfee
    );
    event Sell(
        address indexed usr,
        uint256 indexed id,
        uint256 sha,
        uint256 bor,
        uint256 amt,
        uint256 bal,
        uint256 fee
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

    constructor() {
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "paused") paused = data == 1;
        if (what == "liquidationFee") liquidationFee = data;
        if (what == "performanceFee") performanceFee = data;
        if (what == "originationFee") originationFee = data;
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        if (what == "pools") pools[data] = !pools[data];
        if (what == "strategies") strategies[data] = !strategies[data];
        emit FileAddress(what, data);
    }

    // Invest in strategy, providing collateral and optionally borrowing for leverage
    function earn(address usr, address pol, address str, uint256 amt, uint256 bor, bytes calldata dat)
        external
        live
        returns (uint256)
    {
        if (!pools[pol]) revert InvalidPool();
        if (!strategies[str]) revert InvalidStrategy();
        IPool pool = IPool(pol);
        IERC20 asset = IERC20(pool.asset());
        if (bor * 1e18 / (bor + amt) > pool.borrowFactor()) revert OverMaxBorrowFactor();
        pull(asset, msg.sender, amt);
        asset.approve(str, amt + bor);
        uint256 borfee;
        uint256 id = nextPosition++;
        Position storage p = positions[id];
        if (bor > 0) {
            p.borrow = pool.borrow(bor);
            borfee = bor * originationFee / 10000;
            if (borfee > 0) {
                asset.approve(pol, borfee);
                pool.mint(borfee, address(0));
            }
        }
        p.owner = msg.sender;
        p.pool = pol;
        p.strategy = str;
        p.amount = amt;
        p.shares = IStrategy(str).mint(address(asset), amt + bor - borfee, dat);
        if (life(id) < 1e18) revert Undercollateralized();
        emit Earn(usr, id, pol, str, amt, bor, borfee);
        return id;
    }

    // Divest from strategy, repay borrow and collect surplus
    function sell(uint256 id, uint256 sha, uint256 bor, bytes calldata dat) external live {
        Position storage p = positions[id];
        if (p.owner != msg.sender) revert Unauthorized();
        if (sha > p.shares) revert InsufficientShares();
        if (bor > p.borrow) revert InsufficientBorrow();
        IPool pool = IPool(p.pool);
        IERC20 asset = IERC20(pool.asset());

        uint256 amt = IStrategy(p.strategy).burn(address(asset), sha, dat);
        uint256 rep = bor * pool.getUpdatedIndex() / 1e18;
        if (amt < rep) revert InsufficientAmountForRepay();
        asset.approve(address(pool), amt);
        uint256 bal = pool.repay(bor);

        // profit case
        //   p.amount=400 bal=400 amt=1000
        //   amtdif = min(400, 1000-400) = 400
        //   fee = (1000 - 400 - 400) * 1000 / 10000 = 20
        // loss case
        //   p.amount=900 bal=100 amt=800
        //   amtdif = min(900, 800-100) = 700
        //   fee = (800 - 100 - 700) * 1000 / 10000 = 0
        uint256 amtdif = min(p.amount, amt - bal);
        uint256 fee = (amt - bal - amtdif) * performanceFee / 10000;

        p.amount -= amtdif;
        p.shares -= sha;
        p.borrow -= bor;
        push(asset, msg.sender, amt-bal-fee);
        if (fee > 0) {
            asset.approve(address(pool), fee);
            pool.mint(fee, address(0));
        }
        if (life(id) < 1e18) revert Undercollateralized();
        emit Sell(msg.sender, id, sha, bor, amt, bal, fee);
    }

    // Provide more collateral for position
    function save(uint256 id, uint256 amt, bytes calldata dat) external {
        Position storage p = positions[id];
        if (p.owner != msg.sender) revert Unauthorized();
        IPool pool = IPool(p.pool);
        IERC20 asset = IERC20(pool.asset());
        pull(asset, msg.sender, amt);
        asset.approve(p.strategy, amt);
        p.amount += amt;
        p.shares += IStrategy(p.strategy).mint(address(asset), amt, dat);
        emit Save(msg.sender, id, amt);
    }

    // Liquidate position with health <1e18
    function kill(uint256 id, bytes calldata dat) external {
        if (life(id) >= 1e18) revert PositionNotLiquidatable();
        Position storage p = positions[id];
        IPool pool = IPool(p.pool);
        IERC20 asset = IERC20(pool.asset());
        uint256 amt = IStrategy(p.strategy).burn(address(asset), p.shares, dat);
        uint256 fee = amt * liquidationFee / 10000;
        uint256 haf = fee / 2;
        asset.approve(address(pool), amt - fee);
        uint256 bal = pool.repay(p.borrow);
        p.shares = 0;
        p.borrow = 0;
        if (fee > 0) {
            // Pay keeper
            push(asset, msg.sender, haf);
            // Pay protocol by minting reserves
            asset.approve(address(pool), fee - haf);
            pool.mint(fee - haf, address(0));
        }
        if (amt - fee - bal > 0) {
            push(asset, p.owner, amt - fee - bal);
        }
        emit Kill(p.owner, id, msg.sender, amt, bal, fee);
    }

    function emergency(uint256 id, bytes calldata dat) external {
        Position storage p = positions[id];
        if (p.owner != msg.sender) revert Unauthorized();
        IPool pool = IPool(p.pool);
        IERC20 asset = IERC20(pool.asset());
        uint256 sha = p.shares;
        uint256 bor = p.borrow;
        uint256 amt = IStrategy(p.strategy).burn(address(asset), sha, dat);
        asset.approve(address(pool), amt);
        uint256 bal = pool.repay(bor);
        p.amount = 0;
        p.shares = 0;
        p.borrow = 0;
        push(asset, msg.sender, amt-bal);
        emit Sell(msg.sender, id, sha, bor, amt, bal, 0);
    }

    // Calculates position health (<1e18 is liquidatable)
    function life(uint256 id) public view returns (uint256) {
        Position memory p = positions[id];
        IPool pool = IPool(p.pool);
        IOracle oracle = IOracle(pool.oracle());
        if (p.borrow == 0) return 1e18;
        uint256 price = uint256(oracle.latestAnswer()) * 1e18 / (10 ** oracle.decimals());
        uint256 value = IStrategy(p.strategy).rate(p.shares) * pool.liquidationFactor() / 1e18;
        uint256 borrow = p.borrow * 1e18 / (10 ** IERC20(pool.asset()).decimals());
        borrow = (borrow * pool.getUpdatedIndex() / 1e18) * price / 1e18;
        return value * 1e18 / borrow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC20} from './interfaces/IERC20.sol';

contract Util {
    error Paused();
    error Unauthorized();
    error TransferFailed();

    bool public paused;
    mapping(address => bool) public exec;

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

    function pull(IERC20 asset, address usr, uint256 amt) internal {
        if (!asset.transferFrom(usr, address(this), amt)) revert TransferFailed();
    }

    function push(IERC20 asset, address usr, uint256 amt) internal {
        if (!asset.transfer(usr, amt)) revert TransferFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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
pragma solidity 0.8.15;

interface IOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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
    function borrow(uint256) external returns (uint256);
    function repay(uint256) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

interface IStrategy {
    function name() external view returns (string memory);
    function rate(uint256) external view returns (uint256);
    function mint(address, uint256, bytes calldata) external returns (uint256);
    function burn(address, uint256, bytes calldata) external returns (uint256);
}