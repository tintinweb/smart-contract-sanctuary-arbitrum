// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract StrategyPendle {
    IPRouter public router;
    IPMarket public market;
    ILpOracleHelper public lpOracleHelper;
    IERC20 public targetAsset;
    IERC20 public weth;
    string public name;
    address public asset;
    uint32 public twapPeriod = 1800;
    uint256 public totalShares = 1_000_000;
    uint256 public slippage = 500;
    bool internal entered;
    IStrategyHelper public strategyHelper;
    mapping(address => bool) public exec;
    mapping(address => bool) public keepers;

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event Mint(uint256 amount, uint256 shares);
    event Burn(uint256 amount, uint256 shares);
    event Kill(uint256 amount, uint256 shares);
    event Earn(uint256 tvl, uint256 profit);

    error PriceSlipped();
    error NoReentering();
    error Unauthorized();
    error TransferFailed();
    error NotKeeper();
    error InvalidFile();
    error TwapPeriodTooLong();

    constructor(
        address _asset,
        address _strategyHelper,
        address _weth,
        address _lpOracleHelper,
        address _router,
        address _market,
        address _targetAsset
    ) {
        exec[msg.sender] = true;
        keepers[msg.sender] = true;
        asset = _asset;
        strategyHelper = IStrategyHelper(_strategyHelper);
        weth = IERC20(_weth);
        lpOracleHelper = ILpOracleHelper(_lpOracleHelper);
        router = IPRouter(_router);
        market = IPMarket(_market);
        targetAsset = IERC20(_targetAsset);
        name = string(abi.encodePacked("Pendle ", targetAsset.symbol()));
    }

    modifier loop() {
        if (entered) revert NoReentering();
        entered = true;
        _;
        entered = false;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") {
            exec[data] = !exec[data];
        } else if (what == "keeper") {
            keepers[data] = !keepers[data];
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "slippage") {
            slippage = data;
        } else if (what == "twapPeriod") {
            if (data > uint256(int256(type(int32).max)))
                revert TwapPeriodTooLong();
            twapPeriod = uint32(data);
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function setAsset(address newAsset) external auth {
        asset = newAsset;
    }

    function mint(uint256 amount) external auth loop returns (uint256) {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        uint256 slp = slippage;
        uint256 tma = totalManagedAssets();
        uint256 lpAmt = deposit(address(asset), amount, slp);
        uint256 sha = tma == 0 ? lpAmt : (lpAmt * totalShares) / tma;

        if (
            valueLiquidity(lpAmt) <
            (strategyHelper.value(address(asset), amount) * (10000 - slp)) /
                10000
        ) revert PriceSlipped();

        totalShares += sha;
        emit Mint(amount, sha);
        return sha;
    }

    function burn(uint256 shares) external auth loop returns (uint256) {
        uint256 amt = (shares * totalManagedAssets()) / totalShares;
        uint256 val = valueLiquidity(amt);
        uint256 slp = slippage;

        uint256 netTokenOut = removePendleLiquidity(amt);
        targetAsset.approve(address(strategyHelper), netTokenOut);
        uint256 bal = strategyHelper.swap(
            address(targetAsset),
            address(asset),
            netTokenOut,
            slp,
            msg.sender
        );
        if (
            val <
            (strategyHelper.value(address(asset), bal) * (10000 - slp)) / 10000
        ) revert PriceSlipped();

        totalShares -= shares;
        emit Burn(bal, shares);
        return bal;
    }

    function kill(uint256 shares, address to) external auth loop returns (bytes memory) {
        uint256 value = rate(shares);
        market.transfer(to, value);

        totalShares -= shares;
        emit Kill(value, shares);

        address[] memory assets = new address[](1);
        assets[0] = address(market);
        return abi.encode(bytes32("pendle"), assets);
    }

    function earn() external payable {
        if (!keepers[msg.sender]) revert NotKeeper();
        uint256 before = rate(totalShares);

        address[] memory rewardTokens = market.getRewardTokens();
        uint256 len = rewardTokens.length;
        address ast = asset;
        uint256 slp = slippage;

        market.redeemRewards(address(this));

        for (uint256 i = 0; i < len; ++i) {
            uint256 bal = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (strategyHelper.value(rewardTokens[i], bal) < 0.5e18) continue;
            IERC20(rewardTokens[i]).approve(address(strategyHelper), bal);
            strategyHelper.swap(rewardTokens[i], ast, bal, slp, address(this));
        }

        uint256 astBal = IERC20(ast).balanceOf(address(this));
        uint256 value = strategyHelper.value(ast, astBal);
        if (value > 0.5e18) {
            uint256 lpAmt = deposit(ast, astBal, slp);
            if (valueLiquidity(lpAmt) < (value * (10000 - slp)) / 10000) {
                revert PriceSlipped();
            }
        }

        uint256 current = rate(totalShares);
        emit Earn(current, current - min(current, before));
    }

    function exit(address str) external auth {
        uint256 amt = totalManagedAssets();
        if (amt == 0) return;
        if (!market.transfer(str, amt)) revert TransferFailed();
    }

    function move(address old) public auth {
        require(totalShares == 1_000_000, "ts=0");
        totalShares = StrategyPendle(old).totalShares();
    }

    function rate(uint256 shares) public view returns (uint256) {
        return (shares * valueLiquidity(totalManagedAssets())) / totalShares;
    }

    function deposit(
        address ast,
        uint256 amt,
        uint256 slp
    ) private returns (uint256) {
        IERC20(ast).approve(address(strategyHelper), amt);
        uint256 bal = strategyHelper.swap(
            ast,
            address(targetAsset),
            amt,
            slp,
            address(this)
        );
        return addPendleLiquidity(bal);
    }

    function addPendleLiquidity(
        uint256 amt
    ) private returns (uint256 netLpOut) {
        address ast = address(targetAsset);
        IPMarket.ApproxParams memory approxParams = IPMarket.ApproxParams({
            guessMin: 0,
            guessMax: type(uint256).max,
            guessOffchain: 0,
            maxIteration: 256,
            eps: 1e14 // Maximum 0.01% unused
        });
        IPSwapAggregator.SwapData memory swapData = IPSwapAggregator.SwapData({
            swapType: IPSwapAggregator.SwapType.NONE,
            extRouter: address(0),
            extCalldata: "",
            needScale: false
        });
        IPRouter.TokenInput memory input = IPRouter.TokenInput({
            tokenIn: ast,
            netTokenIn: amt,
            tokenMintSy: ast,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });

        IERC20(ast).approve(address(router), amt);

        (netLpOut, ) = router.addLiquiditySingleToken(
            address(this),
            address(market),
            0,
            approxParams,
            input
        );
    }

    function removePendleLiquidity(
        uint256 amt
    ) private returns (uint256 netTokenOut) {
        address ast = address(targetAsset);
        IPSwapAggregator.SwapData memory swapData = IPSwapAggregator.SwapData({
            swapType: IPSwapAggregator.SwapType.NONE,
            extRouter: address(0),
            extCalldata: "",
            needScale: false
        });
        IPRouter.TokenOutput memory output = IPRouter.TokenOutput({
            tokenOut: ast,
            minTokenOut: 0,
            tokenRedeemSy: ast,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });

        market.approve(address(router), amt);

        (netTokenOut, ) = router.removeLiquiditySingleToken(
            address(this),
            address(market),
            amt,
            output
        );
    }

    function valueLiquidity(uint256 amt) private view returns (uint256) {
        address assetAddress = address(targetAsset);
        uint256 assetPrice = strategyHelper.price(assetAddress);
        uint256 k = strategyHelper.convert(assetAddress, address(weth), 1e18);
        uint256 lpRate = lpOracleHelper.getLpToAssetRate(market, twapPeriod);

        return (((assetPrice * lpRate) / k) * amt) / 1e18;
    }

    function totalManagedAssets() private view returns (uint256) {
        return market.balanceOf(address(this));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

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

interface IPSwapAggregator {
    enum SwapType {
        NONE,
        KYBERSWAP,
        ONE_INCH,
        ETH_WETH
    }
    struct SwapData {
        SwapType swapType;
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }
}

interface IPMarket is IERC20 {
    struct ApproxParams {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffchain;
        uint256 maxIteration;
        uint256 eps;
    }
    function redeemRewards(address user) external returns (uint256[] memory);
    function getRewardTokens() external view returns (address[] memory);
}

interface IPRouter {
    struct TokenInput {
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        address bulk;
        address pendleSwap;
        IPSwapAggregator.SwapData swapData;
    }

    struct TokenOutput {
        address tokenOut;
        uint256 minTokenOut;
        address tokenRedeemSy;
        address bulk;
        address pendleSwap;
        IPSwapAggregator.SwapData swapData;
    }

    function addLiquiditySingleToken(
        address receiver,
        address market,
        uint256 minLpOut,
        IPMarket.ApproxParams calldata guessPtReceivedFromSy,
        TokenInput calldata input
    ) external payable returns (uint256 netLpOut, uint256 netSyFee);

    function removeLiquiditySingleToken(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut, uint256 netSyFee);
}

interface ILpOracleHelper {
    function getLpToAssetRate(
        IPMarket market,
        uint32 duration
    ) external view returns (uint256 lpToAssetRate);
}

interface IStrategyHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256);
    function paths(address, address) external returns (address venue, bytes memory path);
}