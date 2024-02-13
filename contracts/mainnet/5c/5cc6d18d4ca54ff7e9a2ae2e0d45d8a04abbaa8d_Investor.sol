// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IOracle {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}

interface IStore {
    function exec(address) external view returns (bool);
    function getUint(bytes32) external view returns (uint256);
    function getAddress(bytes32) external view returns (address);
    function setUint(bytes32, uint256) external;
    function setUintDelta(bytes32, int256) external returns (uint256);
    function setAddress(bytes32, address) external returns (address);
}

interface IBank {
    function exec(address) external view returns (bool);
    function transfer(address, address, uint256) external;
}

interface IPool {
    function exec(address) external view returns (bool);
    function asset() external view returns (address);
    function oracle() external view returns (address);
    function getUpdatedIndex() external view returns (uint256);
    function borrow(uint256) external returns (uint256);
    function repay(uint256) external returns (uint256);
}

interface IHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address, address, uint256, uint256, address) external returns (uint256);
}

interface IStrategy {
    function totalShares() external view returns (uint256);
    function rate(uint256) external view returns (uint256);
    function exit(address) external;
    function move(address) external;
}

interface IStrategyProxy {
    function exec(address) external view returns (bool);
    function mint(address, uint256) external returns (uint256);
    function burn(address, uint256) external returns (uint256);
    function kill(address, uint256, address) external returns (bytes memory);
}

contract Investor {
    IStore public store;
    IHelper public helper;
    IStrategyProxy public strategyProxy;
    uint256 public slippage = 200;
    uint256 public performanceFee = 2000;
    uint256 public killCollateralPadding = 500;
    uint256 public closeCollateralPadding = 400;
    bool internal entered;
    mapping(uint256 => uint256) private lastBlock;
    mapping(address => bool) public exec;

    uint256 public constant STATUS_LIVE = 4;
    uint256 public constant STATUS_WITHDRAW = 3;
    uint256 public constant STATUS_LIQUIDATE = 2;
    uint256 public constant STATUS_PAUSED = 1;
    bytes32 constant STATUS = keccak256(abi.encode("STATUS"));
    bytes32 constant BANK = keccak256(abi.encode("BANK"));
    bytes32 constant POOL = keccak256(abi.encode("POOL"));
    bytes32 constant STRATEGIES_ADDRESS = keccak256(abi.encode("STRATEGIES_ADDRESS"));
    bytes32 constant STRATEGIES_CAP = keccak256(abi.encode("STRATEGIES_CAP"));
    bytes32 constant STRATEGIES_STATUS = keccak256(abi.encode("STRATEGIES_STATUS"));
    bytes32 constant COLLATERAL_FACTOR = keccak256(abi.encode("COLLATERAL_FACTOR"));
    bytes32 constant COLLATERAL_CAP = keccak256(abi.encode("COLLATERAL_CAP"));
    bytes32 constant POSITIONS = keccak256(abi.encode("POSITIONS"));
    bytes32 constant POSITIONS_OWNER = keccak256(abi.encode("POSITIONS_OWNER"));
    bytes32 constant POSITIONS_START = keccak256(abi.encode("POSITIONS_START"));
    bytes32 constant POSITIONS_STRATEGY = keccak256(abi.encode("POSITIONS_STRATEGY"));
    bytes32 constant POSITIONS_TOKEN = keccak256(abi.encode("POSITIONS_TOKEN"));
    bytes32 constant POSITIONS_COLLATERAL = keccak256(abi.encode("POSITIONS_COLLATERAL"));
    bytes32 constant POSITIONS_BASIS = keccak256(abi.encode("POSITIONS_BASIS"));
    bytes32 constant POSITIONS_SHARES = keccak256(abi.encode("POSITIONS_SHARES"));
    bytes32 constant POSITIONS_BORROW = keccak256(abi.encode("POSITIONS_BORROW"));

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event Open(uint256 indexed id, uint256 borrow, uint256 collateral, uint256 strategy, address token);
    event Edit(uint256 indexed id, int256 borrow, int256 collateral);
    event Kill(uint256 indexed id, uint256 borrow, uint256 value, uint256 collateral, uint256 shares, uint256 fee);
    event StrategyUpdate(uint256 indexed index, address implementation, uint256 status, uint256 cap);
    event CollateralUpdate(address indexed token, uint256 factor, uint256 cap);

    error NotOwner();
    error InvalidFile();
    error WrongStatus();
    error NoReentering();
    error Unauthorized();
    error TransferFailed();
    error StrategyClosed();
    error StrategyExists();
    error StrategyOverCap();
    error UnknownStrategy();
    error UnknownCollateral();
    error CollateralOverCap();
    error InvalidParameters();
    error Undercollateralized();
    error NoEditingInSameBlock();
    error StrategyUninitialized();
    error PositionNotLiquidatable();

    struct Strategy {
      address implementation;
      uint256 cap;
      uint256 status;
    }

    struct Position {
        address owner;
        uint256 start;
        uint256 strategy;
        address token;
        uint256 collateral;
        uint256 borrow;
        uint256 shares;
        uint256 basis;
    }

    constructor(address _store, address _helper) {
        store = IStore(_store);
        helper = IHelper(_helper);
        exec[msg.sender] = true;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    modifier loop() {
        if (entered) revert NoReentering();
        entered = true;
        _;
        entered = false;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") {
            exec[data] = !exec[data];
        } else if (what == "helper") {
            helper = IHelper(data);
            IPool pool = IPool(store.getAddress(POOL));
            address poolAsset = pool.asset();
            if (helper.price(poolAsset) == 0) revert InvalidFile();
        } else if (what == "strategyProxy") {
            strategyProxy = IStrategyProxy(data);
            if (!strategyProxy.exec(address(this))) revert InvalidFile();
        } else if (what == "bank") {
            store.setAddress(BANK, data);
            if (!IBank(data).exec(address(this))) revert InvalidFile();
        } else if (what == "pool") {
            store.setAddress(POOL, data);
            if (!IPool(data).exec(address(this))) revert InvalidFile();
            if (IPool(data).asset() == address(0)) revert InvalidFile();
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "slippage") {
            if (data > 1e18) revert InvalidFile();
            slippage = data;
        } else if (what == "performanceFee") {
            if (data > 0.5e18) revert InvalidFile();
            performanceFee = data;
        } else if (what == "killCollateralPadding") {
            if (data > 1e18) revert InvalidFile();
            killCollateralPadding = data;
        } else if (what == "closeCollateralPadding") {
            if (data > 1e18) revert InvalidFile();
            closeCollateralPadding = data;
        } else if (what == "status") {
            if (data == 0 || data > 4) revert InvalidFile();
            store.setUint(STATUS, data);
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function strategyNew(uint256 index, address implementation) external auth {
        if (store.getAddress(keccak256(abi.encode(index, STRATEGIES_ADDRESS))) != address(0)) {
            revert StrategyExists();
        }
        store.setAddress(keccak256(abi.encode(index, STRATEGIES_ADDRESS)), implementation);
        store.setUint(keccak256(abi.encode(index, STRATEGIES_STATUS)), 4);
        emit StrategyUpdate(index, implementation, 4, 0);
    }

    function strategyUgrade(uint256 index, address implementation) external auth {
        Strategy memory s = getStrategy(index);
        IStrategy(s.implementation).exit(implementation);
        IStrategy(implementation).move(s.implementation);
        store.setAddress(keccak256(abi.encode(index, STRATEGIES_ADDRESS)), implementation);
        emit StrategyUpdate(index, implementation, s.status, s.cap);
    }

    function strategySetStatus(uint256 index, uint256 status) external auth {
        Strategy memory s = getStrategy(index);
        store.setUint(keccak256(abi.encode(index, STRATEGIES_STATUS)), status);
        emit StrategyUpdate(index, s.implementation, status, s.cap);
    }

    function strategySetCap(uint256 index, uint256 cap) external auth {
        Strategy memory s = getStrategy(index);
        store.setUint(keccak256(abi.encode(index, STRATEGIES_CAP)), cap);
        emit StrategyUpdate(index, s.implementation, s.status, cap);
    }

    function collateralSetFactor(address token, uint256 factor) external auth {
        uint256 cap = store.getUint(keccak256(abi.encode(token, COLLATERAL_CAP)));
        store.setUint(keccak256(abi.encode(token, COLLATERAL_FACTOR)), factor);
        emit CollateralUpdate(token, factor, cap);
    }

    function collateralSetCap(address token, uint256 cap) external auth {
        uint256 factor = store.getUint(keccak256(abi.encode(token, COLLATERAL_FACTOR)));
        store.setUint(keccak256(abi.encode(token, COLLATERAL_CAP)), cap);
        emit CollateralUpdate(token, factor, cap);
    }

    function collect(address token) external auth {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function open(uint256 strategy, address token, uint256 collateral, uint256 borrow) external loop returns (uint256) {
        uint256 id = store.setUintDelta(POSITIONS, 1);
        lastBlock[id] = block.number;
        Strategy memory s = getStrategy(strategy);
        IStrategy si = IStrategy(s.implementation);
        if (store.getUint(STATUS) < STATUS_LIVE || s.status < STATUS_LIVE) revert WrongStatus();
        uint256 collateralCap = store.getUint(keccak256(abi.encode(token, COLLATERAL_CAP)));
        if (collateralCap == 0) revert UnknownCollateral();
        if (IERC20(token).balanceOf(store.getAddress(BANK)) + collateral > collateralCap) {
            revert CollateralOverCap();
        }

        Position memory p;
        p.owner = msg.sender;
        p.start = block.timestamp;
        p.strategy = strategy;
        p.token = token;
        p.collateral = collateral;

        {
            if (si.totalShares() == 0) revert StrategyUninitialized();
            IPool pool = IPool(store.getAddress(POOL));
            address poolAsset = pool.asset();
            pullToBank(token, msg.sender, collateral);
            p.borrow = pool.borrow(borrow);
            push(poolAsset, address(strategyProxy), borrow);
            p.shares = strategyProxy.mint(address(si), borrow);
            p.basis = si.rate(p.shares);
        }

        if (_life(p) < 1e18) revert Undercollateralized();
        if (si.rate(si.totalShares()) > s.cap) revert StrategyOverCap();
        setPosition(id, p);
        emit Open(id, borrow, collateral, strategy, token);
        return id;
    }

    function edit(uint256 id, int256 borrow, int256 collateral) external loop {
        IBank bank = IBank(store.getAddress(BANK));
        IPool pool = IPool(store.getAddress(POOL));
        int256 collateralAdjusted = collateral;
        address poolAsset = pool.asset();
        Position memory p = getPosition(id);
        Strategy memory s = getStrategy(p.strategy); 
        IStrategy si = IStrategy(s.implementation);
        if (p.owner != msg.sender) revert NotOwner();
        if (borrow < 0 && uint256(-borrow) > p.shares) revert InvalidParameters();
        if (borrow > 0 && p.shares == 0) revert InvalidParameters();
        if (collateral < 0 && uint256(-collateral) > p.collateral) revert InvalidParameters();
        if (lastBlock[id] == block.number) revert NoEditingInSameBlock();
        lastBlock[id] = block.number;
        {
            uint256 status = store.getUint(STATUS);
            if (borrow > 0 && (status < STATUS_LIVE || s.status < STATUS_LIVE)) {
                revert WrongStatus();
            }
            if (borrow <= 0 && (status < STATUS_WITHDRAW || s.status < STATUS_WITHDRAW)) {
                revert WrongStatus();
            }
        }

        // 1. Adjust collateral
        if (collateral > 0) {
            pullToBank(p.token, msg.sender, uint256(collateral));
            p.collateral = p.collateral + uint256(collateral);
            uint256 collateralCap = store.getUint(keccak256(abi.encode(p.token, COLLATERAL_CAP)));
            if (IERC20(p.token).balanceOf(store.getAddress(BANK)) > collateralCap) {
                revert CollateralOverCap();
            }
        }

        // 2. Sell strategy shares to repay loan
        if (borrow < 0) {
            p.basis = p.basis - min(p.basis, si.rate(uint256(-borrow)));
            uint256 amount = strategyProxy.burn(address(si), uint256(-borrow));
            p.shares = p.shares - uint256(-borrow);
            uint256 index = pool.getUpdatedIndex();
            uint256 repaying = amount * 1e18 / index;
            // If closing the position, make sure we repay the whole borrow
            if (p.shares == 0) {
                p.basis = 0;
                repaying = p.borrow;
                uint256 needed = p.borrow * index / 1e18;
                if (needed > amount) {
                    // If we don't have enough USDC from shares, sell some collateral
                    uint256 cAmount = helper.convert(poolAsset, p.token, needed - amount);
                    cAmount = cAmount * (10000 + closeCollateralPadding) / 10000;
                    if (cAmount > p.collateral) cAmount = p.collateral;
                    bank.transfer(p.token, address(this), cAmount);
                    IERC20(p.token).approve(address(helper), cAmount);
                    uint256 topup = helper.swap(p.token, poolAsset, cAmount, slippage, address(this));
                    amount = amount + topup;
                    p.collateral = p.collateral - cAmount;
                }
            }
            IERC20(poolAsset).approve(address(pool), amount);
            uint256 used = pool.repay(repaying);
            p.borrow = p.borrow - repaying;
            push(poolAsset, msg.sender, (amount - used) * (10000 - performanceFee) / 10000);
        }

        // 3. Borrow more from pool and mint strategy shares
        if (borrow > 0) {
            if (si.totalShares() == 0) revert StrategyUninitialized();
            if (p.shares == 0) revert StrategyClosed();
            p.borrow = p.borrow + pool.borrow(uint256(borrow));
            push(poolAsset, address(strategyProxy), uint256(borrow));
            uint256 shares = strategyProxy.mint(address(si), uint256(borrow));
            p.shares = p.shares + shares;
            p.basis = p.basis + si.rate(shares);
        }

        // 4. Withdraw collateral asked for
        if (collateral < 0) {
            uint256 amt = uint256(-collateral);
            // Allow a user to ask for all it's collateral but support some being taken away
            // as topup for the repayment of the debt
            if (amt > p.collateral) amt = p.collateral;
            collateralAdjusted = -int256(amt);
            p.collateral = p.collateral - amt;
            bank.transfer(p.token, msg.sender, amt);
        }

        if (_life(p) < 1e18) revert Undercollateralized();
        if (borrow > 0 && si.rate(si.totalShares()) > s.cap) revert StrategyOverCap();
        setPosition(id, p);
        emit Edit(id, borrow, collateralAdjusted);
    }

    function killRepayment(uint256 id) external view returns (uint256) {
        IPool pool = IPool(store.getAddress(POOL));
        Position memory p = getPosition(id);
        uint256 borrow = p.borrow * pool.getUpdatedIndex() / 1e18;
        uint256 fee = borrow * killCollateralPadding / 10000 / 2;
        return borrow + fee;
    }

    function kill(uint256 id) external loop returns (address, bytes memory) {
        IBank bank = IBank(store.getAddress(BANK));
        IPool pool = IPool(store.getAddress(POOL));
        Position memory p = getPosition(id);
        Strategy memory s = getStrategy(p.strategy); 
        address poolAsset = pool.asset();
        if (_life(p) >= 1e18) revert PositionNotLiquidatable();
        if (store.getUint(STATUS) < STATUS_LIQUIDATE || s.status < STATUS_LIQUIDATE) revert WrongStatus();
        if (lastBlock[id] == block.number) revert NoEditingInSameBlock();
        lastBlock[id] = block.number;

        // Repay borrow using liquidator funds
        uint256 borrow = p.borrow * pool.getUpdatedIndex() / 1e18;
        uint256 fee = borrow * killCollateralPadding / 10000 / 2;
        IERC20(poolAsset).transferFrom(msg.sender, address(this), borrow + fee);
        IERC20(poolAsset).approve(address(pool), borrow);
        pool.repay(p.borrow);

        uint256 amount = IStrategy(s.implementation).rate(p.shares);
        uint256 shares;
        uint256 collat;
        {
          // Transfer collateral to liquidator
          uint256 target = helper.value(poolAsset, borrow + (fee * 2));
          if (amount < target) {
            // Only use collateral if needed, some "in profit" position
            // could be liquidatable if "expired/forced to exit"
            collat = (target - amount) * 1e18 / helper.price(p.token);
            if (collat > p.collateral) collat = p.collateral;
            bank.transfer(p.token, msg.sender, collat);
          }

          // Transfer underlying to liquidator
          // scale shares to target. when just repaying borrow on an in
          // profit position, we don't want to use all shares
          shares = p.shares * target / amount;
          if (shares > p.shares) shares = p.shares;
        }
        bytes memory data = strategyProxy.kill(s.implementation, shares, msg.sender);

        // Update state
        p.collateral = p.collateral - collat;
        p.shares = p.shares - shares;
        p.borrow = 0;
        setPosition(id, p);

        emit Kill(id, borrow, amount, collat, shares, fee);
        return (p.token, data);
    }

    function life(uint256 id) external view returns (uint256) {
        Position memory p = getPosition(id);
        return _life(p);
    }

    function _life(Position memory p) internal view returns (uint256) {
        if (p.borrow == 0) return 1e18;
        IStrategy s = IStrategy(store.getAddress(keccak256(abi.encode(p.strategy, STRATEGIES_ADDRESS))));
        IPool pool = IPool(store.getAddress(POOL));
        IOracle oracle = IOracle(pool.oracle());
        uint256 factor = store.getUint(keccak256(abi.encode(p.token, COLLATERAL_FACTOR)));
        uint256 sharesValue = s.rate(p.shares);
        uint256 collateralValue = helper.value(p.token, p.collateral);
        uint256 value = (sharesValue + collateralValue) * factor / 1e18;
        uint256 price = (uint256(oracle.latestAnswer()) * 1e18) / (10 ** oracle.decimals());
        uint256 scaled = (p.borrow * 1e18) / (10 ** IERC20(pool.asset()).decimals());
        uint256 borrow = (scaled * pool.getUpdatedIndex() / 1e18) * price / 1e18;
        return value * 1e18 / borrow;
    }

    function getPosition(uint256 id) public view returns (Position memory p) {
        p.owner = store.getAddress(keccak256(abi.encode(id, POSITIONS_OWNER)));
        p.start = store.getUint(keccak256(abi.encode(id, POSITIONS_START)));
        p.strategy = store.getUint(keccak256(abi.encode(id, POSITIONS_STRATEGY)));
        p.token = store.getAddress(keccak256(abi.encode(id, POSITIONS_TOKEN)));
        p.collateral = store.getUint(keccak256(abi.encode(id, POSITIONS_COLLATERAL)));
        p.borrow = store.getUint(keccak256(abi.encode(id, POSITIONS_BORROW)));
        p.shares = store.getUint(keccak256(abi.encode(id, POSITIONS_SHARES)));
        p.basis = store.getUint(keccak256(abi.encode(id, POSITIONS_BASIS)));
    }

    function setPosition(uint256 id, Position memory p) internal {
        store.setAddress(keccak256(abi.encode(id, POSITIONS_OWNER)), p.owner);
        store.setUint(keccak256(abi.encode(id, POSITIONS_START)), p.start);
        store.setUint(keccak256(abi.encode(id, POSITIONS_STRATEGY)), p.strategy);
        store.setAddress(keccak256(abi.encode(id, POSITIONS_TOKEN)), p.token);
        store.setUint(keccak256(abi.encode(id, POSITIONS_COLLATERAL)), p.collateral);
        store.setUint(keccak256(abi.encode(id, POSITIONS_BORROW)), p.borrow);
        store.setUint(keccak256(abi.encode(id, POSITIONS_SHARES)), p.shares);
        store.setUint(keccak256(abi.encode(id, POSITIONS_BASIS)), p.basis);
    }

    function getStrategy(uint256 id) public view returns (Strategy memory s) {
        s.implementation = store.getAddress(keccak256(abi.encode(id, STRATEGIES_ADDRESS)));
        s.cap = store.getUint(keccak256(abi.encode(id, STRATEGIES_CAP)));
        s.status = store.getUint(keccak256(abi.encode(id, STRATEGIES_STATUS)));
        if (s.implementation == address(0)) revert UnknownStrategy();
    }

    function getPool() public view returns (address) {
        return store.getAddress(POOL);
    }

    function push(address asset, address user, uint256 amount) internal {
        if (amount == 0) return;
        if (!IERC20(asset).transfer(user, amount)) {
            revert TransferFailed();
        }
    }

    function pullToBank(address asset, address user, uint256 amount) internal {
        if (amount == 0) return;
        if (!IERC20(asset).transferFrom(user, store.getAddress(BANK), amount)) {
            revert TransferFailed();
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}