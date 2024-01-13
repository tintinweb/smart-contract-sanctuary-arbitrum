// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../interfaces/IERC20.sol";
import {IStrategyHelper} from "../interfaces/IStrategyHelper.sol";
import {IExchangeRouter, IMarket, IReader, IPrice, IEventUtils, IDeposit, IWithdrawal} from "../interfaces/IGMXGM.sol";
import {Strategy} from "../Strategy.sol";

interface IHandler {
    function depositVault() external view returns (address);
    function withdrawalVault() external view returns (address);
}

interface IPriceFeed {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

interface IDataStore {
    function getUint(bytes32 key) external view returns (uint256);
    function getAddress(bytes32 key) external view returns (address);
    function getBytes32(bytes32 key) external view returns (bytes32);
}

contract StrategyGMXGM is Strategy {
    IExchangeRouter public exchangeRouter;
    IReader public reader;
    address public depositHandler;
    address public withdrawalHandler;
    address public depositVault;
    address public withdrawalVault;
    address public immutable dataStore;
    address public immutable market;
    address public immutable tokenLong; // Volatile
    address public immutable tokenShort; // Stable
    uint256 public indexTokenDecimals; // Optional, used to set sythetic index token decimals
    uint256 public amountPendingDeposit;
    uint256 public amountPendingWithdraw;
    uint256 public reserveRatio = 1000; // 10%
    uint256 public callbackGasLimit = 500_000;
    string public name;

    error NotGMX();
    error BadToken();
    error ActionPending();
    error ErrorSendingETH();
    error WrongReserveRatio();

    constructor(
        address _strategyHelper,
        address _exchangeRouter,
        address _reader,
        address _depositHandler,
        address _withdrawalHandler,
        address _dataStore,
        address _market
    ) Strategy(_strategyHelper) {
        exchangeRouter = IExchangeRouter(_exchangeRouter);
        reader = IReader(_reader);
        depositHandler = _depositHandler;
        withdrawalHandler = _withdrawalHandler;
        depositVault = IHandler(_depositHandler).depositVault();
        withdrawalVault = IHandler(_withdrawalHandler).withdrawalVault();
        dataStore = _dataStore;
        market = _market;

        IMarket.Props memory marketInfo = reader.getMarket(_dataStore, market);
        tokenLong = marketInfo.longToken;
        tokenShort = marketInfo.shortToken;
        name = string(
            abi.encodePacked(
                "GMX GM ", IERC20(marketInfo.longToken).symbol(), "/", IERC20(marketInfo.shortToken).symbol()
            )
        );
    }

    receive() external payable {}

    function withdrawEth() external auth {
        (bool success,) = address(msg.sender).call{value: address(this).balance}("");
        if (!success) revert ErrorSendingETH();
    }

    function withdrawAirdrop(address token) external auth {
      if (token == address(market) || token == tokenShort || token == tokenLong) revert BadToken();
      IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function setIndexTokenDecimals(uint256 data) external auth {
        indexTokenDecimals = data;
    }

    function setReserveRatio(uint256 data) external auth {
        if (data > 10000) revert WrongReserveRatio();
        reserveRatio = data;
    }

    function setReader(address data) external auth {
        reader = IReader(data);
    }

    function setExchangeRouter(address data) external auth {
        exchangeRouter = IExchangeRouter(data);
    }

    function setDepositHandler(address data) external auth {
        depositHandler = data;
        depositVault = IHandler(data).depositVault();
    }

    function setWithdrawalHandler(address data) external auth {
        withdrawalHandler = data;
        withdrawalVault = IHandler(data).withdrawalVault();
    }

    function setCallbackGasLimit(uint256 data) external auth {
        callbackGasLimit = data;
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        uint256 slp = getSlippage(dat);
        uint256 tot = totalShares;
        uint256 tma = rate(tot);

        pull(IERC20(ast), msg.sender, amt);
        IERC20(ast).approve(address(strategyHelper), amt);
        uint256 bal = strategyHelper.swap(ast, tokenShort, amt, slp, address(this));
        uint256 val = strategyHelper.value(tokenShort, bal);
        return (tma == 0 || tot == 0) ? val : val * tot / tma;
    }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal override returns (uint256) {
        uint256 slp = getSlippage(dat);
        uint256 val = _rate(sha);
        uint256 amt = (val * (10 ** IERC20(tokenShort).decimals())) / strategyHelper.price(tokenShort);
        IERC20(tokenShort).approve(address(strategyHelper), amt);
        return strategyHelper.swap(tokenShort, ast, amt, slp, msg.sender);
    }

    function _earn() internal override {
        if (amountPendingDeposit != 0 || amountPendingWithdraw != 0) {
            revert ActionPending();
        }

        uint256 slp = slippage;
        uint256 bal = IERC20(tokenLong).balanceOf(address(this));
        if (bal > 0) {
            IERC20(tokenLong).approve(address(strategyHelper), bal);
            strategyHelper.swap(tokenLong, tokenShort, bal, slp, address(this));
        }

        bal = IERC20(tokenShort).balanceOf(address(this));
        uint256 have = strategyHelper.value(tokenShort, bal);
        uint256 need = _rate(totalShares) * reserveRatio / 10000;

        if (have > need) {
            uint256 amt = (have - need) * bal / have;
            uint256 haf = amt / 2;
            IERC20(tokenShort).approve(address(strategyHelper), haf);
            uint256 out = strategyHelper.swap(tokenShort, tokenLong, haf, slp, address(this));
            uint256 min = (have - need) * 1e18 / marketTokenPrice(true);
            amountPendingDeposit = min;
            min = min * (10000 - slp) / 10000;

            IExchangeRouter.CreateDepositParams memory params = IExchangeRouter.CreateDepositParams({
                receiver: address(this),
                callbackContract: address(this),
                uiFeeReceiver: address(0),
                market: market,
                initialLongToken: tokenLong,
                initialShortToken: tokenShort,
                longTokenSwapPath: new address[](0),
                shortTokenSwapPath: new address[](0),
                minMarketTokens: min,
                shouldUnwrapNativeToken: false,
                executionFee: msg.value,
                callbackGasLimit: callbackGasLimit
            });

            IMarket.Props memory marketInfo = reader.getMarket(dataStore, market);
            bytes[] memory data = new bytes[](4);
            address router = exchangeRouter.router();
            address vault = depositVault;

            IERC20(marketInfo.longToken).approve(router, out);
            IERC20(marketInfo.shortToken).approve(router, amt - haf);

            data[0] = abi.encodeWithSelector(IExchangeRouter.sendWnt.selector, vault, params.executionFee);
            data[1] = abi.encodeWithSelector(IExchangeRouter.sendTokens.selector, marketInfo.longToken, vault, out);
            data[2] =
                abi.encodeWithSelector(IExchangeRouter.sendTokens.selector, marketInfo.shortToken, vault, amt - haf);
            data[3] = abi.encodeWithSelector(IExchangeRouter.createDeposit.selector, params);
            exchangeRouter.multicall{value: params.executionFee}(data);
        } else if (have < need) {
            uint256 amt = (need - have) * 1e18 / marketTokenPrice(true);

            IMarket.Props memory marketInfo = reader.getMarket(dataStore, market);
            (uint256 longOut, uint256 shortOut) = reader.getWithdrawalAmountOut(
                dataStore,
                marketInfo,
                IMarket.Prices({
                    indexTokenPrice: gmxPrice(marketInfo.indexToken, true),
                    longTokenPrice: gmxPrice(marketInfo.longToken, false),
                    shortTokenPrice: gmxPrice(marketInfo.shortToken, false)
                }),
                amt,
                address(0)
            );
            IExchangeRouter.CreateWithdrawalParams memory params = IExchangeRouter.CreateWithdrawalParams({
                receiver: address(this),
                callbackContract: address(this),
                uiFeeReceiver: address(0),
                market: market,
                longTokenSwapPath: new address[](0),
                shortTokenSwapPath: new address[](0),
                minLongTokenAmount: longOut * (10000 - slp) / 10000,
                minShortTokenAmount: shortOut * (10000 - slp) / 10000,
                shouldUnwrapNativeToken: false,
                executionFee: msg.value,
                callbackGasLimit: callbackGasLimit
            });

            amountPendingWithdraw = amt;
            bytes[] memory data = new bytes[](3);
            IERC20(market).approve(exchangeRouter.router(), amt);
            data[0] = abi.encodeWithSelector(IExchangeRouter.sendWnt.selector, withdrawalVault, params.executionFee);
            data[1] = abi.encodeWithSelector(IExchangeRouter.sendTokens.selector, market, withdrawalVault, amt);
            data[2] = abi.encodeWithSelector(IExchangeRouter.createWithdrawal.selector, params);
            exchangeRouter.multicall{value: params.executionFee}(data);
        }
    }

    function _exit(address str) internal override {
        if (amountPendingDeposit != 0 || amountPendingWithdraw != 0) {
            revert ActionPending();
        }
        push(IERC20(market), str, IERC20(market).balanceOf(address(this)));
        push(IERC20(tokenLong), str, IERC20(tokenLong).balanceOf(address(this)));
        push(IERC20(tokenShort), str, IERC20(tokenShort).balanceOf(address(this)));
    }

    function _move(address old) internal override {}

    function _rate(uint256 sha) internal view override returns (uint256) {
        uint256 val = strategyHelper.value(tokenLong, IERC20(tokenLong).balanceOf(address(this)));
        val += strategyHelper.value(tokenShort, IERC20(tokenShort).balanceOf(address(this)));

        uint256 bal = IERC20(market).balanceOf(address(this)) + amountPendingDeposit + amountPendingWithdraw;
        val += bal * marketTokenPrice(true) / 1e18;

        return sha * val / totalShares;
    }

    function marketTokenPrice(bool isDeposit) public view returns (uint256) {
        IReader r = reader;
        address store = dataStore;
        IMarket.Props memory marketInfo = r.getMarket(store, market);
        (int256 price,) = r.getMarketTokenPrice(
            store,
            marketInfo,
            gmxPrice(marketInfo.indexToken, true),
            gmxPrice(marketInfo.longToken, false),
            gmxPrice(marketInfo.shortToken, false),
            isDeposit ? MAX_PNL_FACTOR_FOR_DEPOSITS : MAX_PNL_FACTOR_FOR_WITHDRAWALS,
            false // maximize
        );

        // returned as 1e30, lets downscale to 1e18 used in here
        return price < 0 ? 0 : uint256(price) / 1e12;
    }

    bytes32 constant MAX_PNL_FACTOR_FOR_DEPOSITS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_DEPOSITS"));
    bytes32 constant MAX_PNL_FACTOR_FOR_WITHDRAWALS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS"));

    function gmxPrice(address token, bool isIndex) internal view returns (IPrice.Props memory) {
        uint256 decimals = isIndex ? indexTokenDecimals : 0;
        if (decimals == 0) {
            decimals = IERC20(token).decimals();
        }
        uint256 price = strategyHelper.price(token);
        price = price * (10 ** (30 - decimals)) / 1e18;
        return IPrice.Props({min: price, max: price});
    }

    function afterDepositExecution(bytes32, IDeposit.Props memory, IEventUtils.EventLogData memory) external {
        if (msg.sender != depositHandler) revert NotGMX();
        amountPendingDeposit = 0;
    }

    function afterDepositCancellation(bytes32, IDeposit.Props memory, IEventUtils.EventLogData memory) external {
        if (msg.sender != depositHandler) revert NotGMX();
        amountPendingDeposit = 0;
    }

    function afterWithdrawalExecution(bytes32, IWithdrawal.Props memory, IEventUtils.EventLogData memory) external {
        if (msg.sender != withdrawalHandler) revert NotGMX();
        amountPendingWithdraw = 0;
        uint256 bal = IERC20(tokenLong).balanceOf(address(this));
        IERC20(tokenLong).approve(address(strategyHelper), bal);
        try strategyHelper.swap(tokenLong, tokenShort, bal, slippage, address(this)) {} catch {}
    }

    function afterWithdrawalCancellation(bytes32, IWithdrawal.Props memory, IEventUtils.EventLogData memory) external {
        if (msg.sender != withdrawalHandler) revert NotGMX();
        amountPendingWithdraw = 0;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IExchangeRouter {
    struct CreateDepositParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minMarketTokens;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct CreateWithdrawalParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    function sendWnt(address receiver, uint256 amount) external payable;
    function sendTokens(address token, address receiver, uint256 amount) external payable;
    function createDeposit(CreateDepositParams calldata params) external payable returns (bytes32);
    function createWithdrawal(CreateWithdrawalParams calldata params) external payable returns (bytes32);
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
    function router() external returns (address);
}

interface IMarket {
    struct Prices {
        IPrice.Props indexTokenPrice;
        IPrice.Props longTokenPrice;
        IPrice.Props shortTokenPrice;
    }

    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }

    function mint(address account, uint256 amount) external;
}

interface IPrice {
    struct Props {
        uint256 min;
        uint256 max;
    }
}

interface IMarketPoolValueInfo {
    struct Props {
        int256 poolValue;
        int256 longPnl;
        int256 shortPnl;
        int256 netPnl;
        uint256 longTokenAmount;
        uint256 shortTokenAmount;
        uint256 longTokenUsd;
        uint256 shortTokenUsd;
        uint256 totalBorrowingFees;
        uint256 borrowingFeePoolFactor;
        uint256 impactPoolAmount;
    }
}

interface IReader {
    function getMarket(address dataStore, address key) external view returns (IMarket.Props memory);
    function getMarketTokenPrice(
        address dataStore,
        IMarket.Props memory market,
        IPrice.Props memory indexTokenPrice,
        IPrice.Props memory longTokenPrice,
        IPrice.Props memory shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) external view returns (int256, IMarketPoolValueInfo.Props memory);
    function getWithdrawalAmountOut(
        address dataStore,
        IMarket.Props memory market,
        IMarket.Prices memory prices,
        uint256 marketTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256, uint256);
}

interface IDeposit {
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

    struct Numbers {
        uint256 initialLongTokenAmount;
        uint256 initialShortTokenAmount;
        uint256 minMarketTokens;
        uint256 updatedAtBlock;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct Flags {
        bool shouldUnwrapNativeToken;
    }
}

interface IWithdrawal {
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

    struct Numbers {
        uint256 marketTokenAmount;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        uint256 updatedAtBlock;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct Flags {
        bool shouldUnwrapNativeToken;
    }
}

interface IEventUtils {
    struct EventLogData {
        AddressItems addressItems;
        UintItems uintItems;
        IntItems intItems;
        BoolItems boolItems;
        Bytes32Items bytes32Items;
        BytesItems bytesItems;
        StringItems stringItems;
    }

    struct AddressItems {
        AddressKeyValue[] items;
        AddressArrayKeyValue[] arrayItems;
    }

    struct UintItems {
        UintKeyValue[] items;
        UintArrayKeyValue[] arrayItems;
    }

    struct IntItems {
        IntKeyValue[] items;
        IntArrayKeyValue[] arrayItems;
    }

    struct BoolItems {
        BoolKeyValue[] items;
        BoolArrayKeyValue[] arrayItems;
    }

    struct Bytes32Items {
        Bytes32KeyValue[] items;
        Bytes32ArrayKeyValue[] arrayItems;
    }

    struct BytesItems {
        BytesKeyValue[] items;
        BytesArrayKeyValue[] arrayItems;
    }

    struct StringItems {
        StringKeyValue[] items;
        StringArrayKeyValue[] arrayItems;
    }

    struct AddressKeyValue {
        string key;
        address value;
    }

    struct AddressArrayKeyValue {
        string key;
        address[] value;
    }

    struct UintKeyValue {
        string key;
        uint256 value;
    }

    struct UintArrayKeyValue {
        string key;
        uint256[] value;
    }

    struct IntKeyValue {
        string key;
        int256 value;
    }

    struct IntArrayKeyValue {
        string key;
        int256[] value;
    }

    struct BoolKeyValue {
        string key;
        bool value;
    }

    struct BoolArrayKeyValue {
        string key;
        bool[] value;
    }

    struct Bytes32KeyValue {
        string key;
        bytes32 value;
    }

    struct Bytes32ArrayKeyValue {
        string key;
        bytes32[] value;
    }

    struct BytesKeyValue {
        string key;
        bytes value;
    }

    struct BytesArrayKeyValue {
        string key;
        bytes[] value;
    }

    struct StringKeyValue {
        string key;
        string value;
    }

    struct StringArrayKeyValue {
        string key;
        string[] value;
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
    uint256 public totalShares = 1_000_000;
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

    function mint(address ast, uint256 amt, bytes calldata dat) external auth loop statusAbove(S_LIVE) returns (uint256) {
        uint256 sha = _mint(ast, amt, dat);
        uint256 _cap = cap;
        totalShares += sha;
        if (_cap != 0 && rate(totalShares) > _cap) revert OverCap();
        emit Mint(ast, amt, sha);
        return sha;
    }

    function burn(address ast, uint256 sha, bytes calldata dat)
        external
        auth loop
        statusAbove(S_WITHDRAW)
        returns (uint256)
    {
        uint256 amt = _burn(ast, sha, dat);
        totalShares -= sha;
        emit Burn(ast, amt, sha);
        return amt;
    }

    function earn() public payable loop {
        uint256 _totalShares = totalShares;
        if (!keepers[msg.sender]) revert NotKeeper();
        if (_totalShares == 0) return;
        uint256 bef = rate(_totalShares);
        _earn();
        uint256 aft = rate(totalShares);
        emit Earn(aft, aft - min(aft, bef));
    }

    function exit(address str) public auth {
        status = S_PAUSE;
        _exit(str);
    }

    function move(address old) public auth {
        require(totalShares == 1_000_000, "ts=0");
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