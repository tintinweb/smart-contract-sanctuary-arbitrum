// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Util} from "./Util.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IInvestor} from "./interfaces/IInvestor.sol";
import {IInvestorActor} from "./interfaces/IInvestorActor.sol";

contract Investor is Util {
    error WrongStatus();
    error InvalidPool();
    error InvalidStrategy();
    error PositionClosed();
    error StrategyIndexToHigh();
    error Undercollateralized();

    struct Position {
        address owner;
        address pool;
        uint256 strategy;
        uint256 outset;
        uint256 amount;
        uint256 shares;
        uint256 borrow;
    }

    uint256 public constant S_PAUSE = 1;
    uint256 public constant S_LIQUIDATE = 2;
    uint256 public constant S_WITHDRAW = 3;
    uint256 public constant S_LIVE = 4;
    uint256 public status;
    uint256 public nextStrategy;
    uint256 public nextPosition;
    IInvestorActor public actor;
    mapping(address => bool) public pools;
    mapping(uint256 => address) public strategies;
    mapping(uint256 => Position) public positions;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event SetStrategy(uint256 indexed idx, address old, address str);
    event Edit(uint256 indexed id, int256 amt, int256 bor, int256 sha, int256 bar);
    event Kill(uint256 indexed id, address indexed kpr, uint256 amt, uint256 fee, uint256 bor);

    constructor() {
        status = S_LIVE;
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "status") status = data;
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        if (what == "pools") pools[data] = !pools[data];
        if (what == "actor") actor = IInvestorActor(data);
        emit FileAddress(what, data);
    }

    function setStrategy(uint256 idx, address str) external auth {
        if (idx > nextStrategy) revert StrategyIndexToHigh();
        if (idx == nextStrategy) {
            strategies[idx] = str;
            nextStrategy++;
            emit SetStrategy(idx, address(0), str);
            return;
        }
        IStrategy old = IStrategy(strategies[idx]);
        old.exit(str);
        IStrategy(str).move(address(old));
        strategies[idx] = str;
        emit SetStrategy(idx, address(old), str);
    }

    // Calculates position health (<1e18 is liquidatable)
    function life(uint256 id) public view returns (uint256) {
        return actor.life(id);
    }

    // Invest in strategy, providing collateral and optionally borrowing for leverage
    function earn(address usr, address pol, uint256 str, uint256 amt, uint256 bor, bytes calldata dat)
        external
        loop
        returns (uint256)
    {
        if (status < S_LIVE) revert WrongStatus();
        if (!pools[pol]) revert InvalidPool();
        if (strategies[str] == address(0)) revert InvalidStrategy();
        uint256 id = nextPosition++;
        Position storage p = positions[id];
        p.owner = usr;
        p.pool = pol;
        p.strategy = str;
        p.outset = block.timestamp;
        pullTo(IERC20(IPool(p.pool).asset()), msg.sender, address(actor), uint256(amt));
        (int256 bas, int256 sha, int256 bar) = actor.edit(id, int256(amt), int256(bor), dat);
        p.amount = uint256(bas);
        p.shares = uint256(sha);
        p.borrow = uint256(bar);
        emit Edit(id, int256(amt), int256(bor), sha, bar);
        return id;
    }

    // Modify a position. Positive amt is tokens to invest, negative is shares to divest. Positive bor is asset to borrow, negative is borrow shares to repay.
    function edit(uint256 id, int256 amt, int256 bor, bytes calldata dat) external loop {
        Position storage p = positions[id];
        if (p.owner != msg.sender) revert Unauthorized();
        if (p.shares == 0) revert PositionClosed();
        if (amt >= 0 && status < S_LIVE) revert WrongStatus();
        if (amt < 0 && status < S_WITHDRAW) revert WrongStatus();
        if (amt > 0) pullTo(IERC20(IPool(p.pool).asset()), msg.sender, address(actor), uint256(amt));
        (int256 bas, int256 sha, int256 bar) = actor.edit(id, amt, bor, dat);
        p.amount = uint256(int256(p.amount) + bas);
        p.shares = uint256(int256(p.shares) + sha);
        p.borrow = uint256(int256(p.borrow) + bar);
        if (actor.life(id) < 1e18) revert Undercollateralized();
        emit Edit(id, amt, bor, sha, bar);
    }

    // Liquidate position with health <1e18
    function kill(uint256 id, bytes calldata dat) external loop {
        if (status < S_LIQUIDATE) revert WrongStatus();
        (uint256 sha, uint256 bor, uint256 amt, uint256 fee, uint256 bal) = actor.kill(id, dat, msg.sender);
        Position storage p = positions[id];
        p.shares = p.shares - sha;
        p.borrow = p.borrow - bor;
        emit Kill(id, msg.sender, amt, bal, fee);
    }
}

contract InvestorActor is Util {
    error WaitBeforeSelling();
    error InsufficientShares();
    error InsufficientBorrow();
    error CantBorrowAndDivest();
    error OverMaxBorrowFactor();
    error PositionNotLiquidatable();
    error InsufficientAmountForRepay();

    IInvestor public investor;
    uint256 public performanceFee = 0.1e4;
    uint256 public originationFee = 0;
    uint256 public liquidationFee = 0.05e4;
    uint256 public softLiquidationSize = 0.05e4;
    uint256 public softLiquidationThreshold = 0.95e18;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);

    constructor(address _investor) {
        investor = IInvestor(_investor);
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
        emit FileAddress(what, data);
    }

    function life(uint256 id) public view returns (uint256) {
        (, address pol, uint256 str,,, uint256 sha, uint256 bor) = investor.positions(id);
        IPool pool = IPool(pol);
        IOracle oracle = IOracle(pool.oracle());
        if (bor == 0) return 1e18;
        uint256 price = (uint256(oracle.latestAnswer()) * 1e18) / (10 ** oracle.decimals());
        uint256 value = (IStrategy(investor.strategies(str)).rate(sha) * pool.liquidationFactor()) / 1e18;
        uint256 borrow = (bor * 1e18) / (10 ** IERC20(pool.asset()).decimals());
        borrow = (borrow * pool.getUpdatedIndex() / 1e18) * price / 1e18;
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
            (, address pol, uint256 str, uint256 out,,,) = investor.positions(id);
            if (out == block.timestamp && aamt < 0) revert WaitBeforeSelling();
            pool = IPool(pol);
            asset = IERC20(pool.asset());
            strategy = IStrategy(investor.strategies(str));
        }

        (,,,,,, uint256 pbor) = investor.positions(id);
        uint256 amt = aamt > 0 ? uint256(aamt) : 0;

        if (abor > 0) {
            bor = int256(pool.borrow(uint256(abor)));
            amt = amt + uint256(abor) - _takeBorrowFee(abor, address(pool));
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
        if (abor > 0 && aamt <= 0) revert CantBorrowAndDivest();
        // We could provide more capital and not borrow or provide no capital and borrow more,
        // but as long as we are not divesting shares or repaying borrow,
        // let's mint more shares with all we got
        if (abor >= 0 && aamt >= 0) {
            asset.approve(address(strategy), amt);
            sha = int256(strategy.mint(address(asset), amt, dat));
            amt = 0;
        }

        // If the new position amount is below zero, collect a performance fee
        // on that portion of the outgoing assets
        {
            uint256 fee;
            (bas, fee) = _takePerformanceFee(id, aamt, amt);
            amt = amt - fee;
        }

        // Send extra funds to use (if there's any)
        // Happens when divesting or borrowing (and not minting more shares)
        {
            (address own,,,,,,) = investor.positions(id);
            push(asset, own, amt);
        }
    }

    function _takeBorrowFee(int256 abor, address pool) internal returns (uint256) {
        uint256 borfee = uint256(abor) * originationFee / 10000;
        if (borfee > 0) {
            IERC20(IPool(pool).asset()).approve(address(pool), borfee);
            IPool(pool).mint(borfee, address(0));
        }
        return borfee;
    }

    function _burnShares(uint256 id, int256 aamt, bytes calldata dat) internal returns (uint256) {
        (, address pol, uint256 str,,, uint256 psha,) = investor.positions(id);
        uint256 camt = uint256(0 - aamt);
        if (camt > psha) revert InsufficientShares();
        return IStrategy(investor.strategies(str)).burn(IPool(pol).asset(), camt, dat);
    }

    function _takePerformanceFee(uint256 id, int256 aamt, uint256 amt) internal returns (int256, uint256) {
        uint256 fee;
        int256 bas = (aamt > 0 ? aamt : int256(0)) - int256(amt);
        (, address pol,,, uint256 pamt,,) = investor.positions(id);
        int256 namt = int256(pamt) + bas;
        if (namt < 0) {
            fee = uint256(0 - namt) * performanceFee / 10000;
            IERC20(IPool(pol).asset()).approve(pol, fee);
            IPool(pol).mint(fee, address(0));
        }
        // Cap bas (basis change) to position size
        if (bas < 0-int256(pamt)) bas = 0-int256(pamt);
        return (bas, fee);
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
            (,, uint256 str,,,,) = investor.positions(id);
            amt = IStrategy(investor.strategies(str)).burn(address(asset), sha, dat);
        }

        // Collect liquidation fee
        // Minting protocol reserves before repay to allow it's use for bad debt
        fee = amt * liquidationFee / 10000;
        uint256 haf = fee / 2;
        if (fee > 0) {
            // Pay keeper
            push(asset, kpr, haf);
            // Pay protocol by minting reserves
            asset.approve(address(pool), fee - haf);
            pool.mint(fee - haf, address(0));
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
                (address own,,,,,,) = investor.positions(id);
                push(asset, own, amt - fee - bal);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from './interfaces/IERC20.sol';

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

interface IInvestor {
    function strategies(uint256) external view returns (address);
    function positions(uint256) external view returns (address, address, uint256, uint256, uint256, uint256, uint256);
    function life(uint256) external view returns (uint256);
    function earn(address, address, uint256, uint256, uint256, bytes calldata) external returns (uint256);
    function edit(uint256, int256, int256, bytes calldata) external;
    function kill(uint256, bytes calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IInvestorActor {
    function life(uint256) external view returns (uint256);
    function edit(uint256, int256, int256, bytes calldata) external returns (int256, int256, int256);
    function kill(uint256, bytes calldata, address) external returns (uint256, uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
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
    function borrow(uint256) external returns (uint256);
    function repay(uint256) external returns (uint256);
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