// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./LizardStrategyBase4.sol";
import "../../interface/IGaugeChronos.sol";
import "../../interface/IPairChronos.sol";
import "../../interface/IRouterChronos.sol";
import "../../interface/IMaLPNFTChronos.sol";

contract LizardStrategyChronos2 is LizardStrategyBase4 {
    IPairChronos public chronosPair;
    IRouterChronos public chronosRouter;
    IGaugeChronos public chronosGauge;
    IERC20 public chronosToken;
    bool public isStable;
    IMaLPNFTChronos public maNFTs;

    function _localInitialize() internal override {
        aavePoolAddressesProvider = IPoolAddressesProvider(
            0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
        );

        chronosRouter = IRouterChronos(
            0xE708aA9E887980750C040a6A2Cb901c37Aa34f3b
        );
        chronosGauge = IGaugeChronos(
            0xdb74aE9C3d1b96326BDAb8E1da9c5e98281d576e
        );
        chronosToken = IERC20(0x15b2fb8f08E4Ac1Ce019EADAe02eE92AeDF06851);
        chronosPair = IPairChronos(0xA2F1C1B52E1b7223825552343297Dc68a29ABecC);
        isStable = false;

        baseToken = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8); //usdc
        baseDecimals = 10 ** 6;

        maximumMint = 500000 * baseDecimals;

        sideToken = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); //WETH
        sideDecimals = 10 ** 18;

        uniswapPoolFee = 500; // USDC/WETH is safe pair so 0.05% maximum fees
        maNFTs = IMaLPNFTChronos(chronosGauge.maNFTs());
    }

    function _localGiveAllowances() internal override {
        chronosPair.approve(address(chronosGauge), type(uint256).max);
        chronosPair.approve(address(chronosRouter), type(uint256).max);
        sideToken.approve(address(chronosRouter), type(uint256).max);
        baseToken.approve(address(chronosRouter), type(uint256).max);
    }

    function _localPairBalances()
        internal
        view
        override
        returns (uint256 baseBalance, uint256 sideBalance)
    {
        uint256 amount = chronosGauge.balanceOf(address(this)) +
            chronosPair.balanceOf(address(this));
        uint256 totalSupply = chronosPair.totalSupply();
        if (totalSupply == 0) return (0, 0);
        (uint256 reserve0, uint256 reserve1, ) = chronosPair.getReserves();
        if (address(baseToken) != chronosPair.token0()) {
            return (
                (reserve1 * amount) / totalSupply,
                (reserve0 * amount) / totalSupply
            );
        } else {
            return (
                (reserve0 * amount) / totalSupply,
                (reserve1 * amount) / totalSupply
            );
        }
    }

    function _localPairGetAmountOut(
        uint256 amount,
        address inToken
    ) internal view override returns (uint256) {
        return chronosPair.getAmountOut(amount, address(inToken));
    }

    function _localPairGetReserves()
        internal
        view
        override
        returns (uint256 baseReserve, uint256 sideReserve)
    {
        if (address(baseToken) != chronosPair.token0())
            (sideReserve, baseReserve, ) = chronosPair.getReserves();
        else (baseReserve, sideReserve, ) = chronosPair.getReserves();
    }

    function _localClaimRewards() internal override returns (uint256) {
        uint256 tokenCount = maNFTs.balanceOf(address(this));
        for (uint256 i = 0; i < tokenCount; i++) {
            uint _tokenId = maNFTs.tokenOfOwnerByIndex(address(this), i);
            if (maNFTs.tokenToGauge(_tokenId) == address(chronosGauge)) {
                chronosGauge.getReward(_tokenId);
            }
        }

        // sell rewards
        uint256 chronosBalance = chronosToken.balanceOf(address(this));
        if (chronosBalance > 0) {
            IRouterChronos.route[] memory routes = new IRouterChronos.route[](
                1
            );
            routes[0].from = address(chronosToken);
            routes[0].to = address(baseToken);
            routes[0].stable = false;

            uint256 amountOut = chronosRouter.getAmountsOut(
                chronosBalance,
                routes
            )[1];
            if (amountOut > 0) {
                chronosToken.approve(address(chronosRouter), chronosBalance);
                amountOut = chronosRouter.swapExactTokensForTokens(
                    chronosBalance,
                    (amountOut * 99) / 100,
                    routes,
                    address(this),
                    block.timestamp
                )[1];

                return amountOut;
            }
        }
        return 0;
    }

    function _localAddLiquidity(
        uint256 baseAmountMax,
        uint256 sideAmountMax
    ) internal override returns (uint256) {
        bool isReverse = address(baseToken) != chronosPair.token0();
        chronosRouter.addLiquidity(
            isReverse ? address(sideToken) : address(baseToken),
            isReverse ? address(baseToken) : address(sideToken),
            isStable,
            isReverse ? sideAmountMax : baseAmountMax,
            isReverse ? baseAmountMax : sideAmountMax,
            0,
            0,
            address(this),
            block.timestamp
        );
        uint256 lpAmount = chronosPair.balanceOf(address(this));

        chronosGauge.deposit(lpAmount);
        return lpAmount;
    }

    function _localRemoveLiquidity(
        uint256 amountSide
    ) internal override returns (uint256 lpForUnstake) {
        bool isReverse = address(baseToken) != chronosPair.token0();

        if (amountSide < type(uint256).max) {
            (uint256 reserve0, uint256 reserve1, ) = chronosPair.getReserves();
            lpForUnstake =
                (amountSide * chronosPair.totalSupply()) /
                (isReverse ? reserve0 : reserve1) +
                1;
        } else {
            lpForUnstake = type(uint256).max;
        }

        if (lpForUnstake > chronosPair.balanceOf(address(this))) {
            uint256 tokenCount = maNFTs.balanceOf(address(this));

            for (uint256 i = tokenCount; i > 0; i--) {
                uint _tokenId = maNFTs.tokenOfOwnerByIndex(
                    address(this),
                    i - 1
                );
                if (maNFTs.tokenToGauge(_tokenId) == address(chronosGauge)) {
                    chronosGauge.withdrawAndHarvest(_tokenId);
                    if (lpForUnstake < type(uint256).max) {
                        if (
                            lpForUnstake <= chronosPair.balanceOf(address(this))
                        ) {
                            break;
                        }
                    }
                }
            }
        }

        lpForUnstake = Math.min(
            lpForUnstake,
            chronosPair.balanceOf(address(this))
        );
        if (lpForUnstake > 0) {
            chronosRouter.removeLiquidity(
                isReverse ? address(sideToken) : address(baseToken),
                isReverse ? address(baseToken) : address(sideToken),
                isStable,
                lpForUnstake,
                0,
                0,
                address(this),
                block.timestamp
            );
        }
        return lpForUnstake;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../interface/IERC20Burnable.sol";
import "../../interface/IPoolAddressesProvider.sol";
import "../../interface/IAavePool.sol";
import "../../interface/IPriceFeed.sol";
import "../../interface/IERC20.sol";
import "../../interface/ISwapRouter.sol";
import "../../interface/IMathBalance.sol";
import "../../interface/IBlockGetter.sol";
import "../../lib/Math.sol";
import "../../lib/SafeCast.sol";
import "../../lib/SafeMath.sol";
import "../../lib/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LizardStrategyBase4 is Initializable {
    using SafeERC20 for IERC20;

    address public owner;
    address public operator;
    bool public isExit;
    bool private locked;

    IERC20Burnable public lizardSynteticToken;

    uint256 public depositWithdrawSlippageBP;
    uint256 public balanceSlippageBP;
    uint256 public allowedSlippageBP;
    uint256 public allowedStakeSlippageBP;

    IERC20 public baseToken;
    IERC20 public sideToken;

    IPriceFeed public baseOracle;
    IPriceFeed public sideOracle;

    uint256 public baseDecimals;
    uint256 public sideDecimals;

    

    ISwapRouter public uniswapRouter;
    uint24 public uniswapPoolFee;

    IPoolAddressesProvider public aavePoolAddressesProvider;
    uint256 public aaveInterestRateMode;

    uint256 public maximumMint;

    mapping(address => bool) public whitelist;

    uint256 public mintFeesNumerator;
    uint256 public mintFeesDenominator;

    uint256 public redeemFeesNumerator;
    uint256 public redeemFeesDenominator;

    IMathBalance public mathBalance;

    uint256 public neededHealthFactor;
    uint256 public liquidationThreshold;

    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event Balance();

    event RemoveLiquidity(uint256 lpAmount);
    event AddLiquidity(uint256 lpAmount);

    event SwapSideToBase(uint256 sideAmountIn, uint256 baseAmountOut);
    event SwapBaseToSide(uint256 baseAmountIn, uint256 sideAmountOut);

    event SupplyBaseToAAve(uint256 baseAmount);
    event RepaySideToAAve(uint256 sideAmount);
    event BorrowSideFromAAve(uint256 sideAmount);
    event WithdrawBaseFromAAve(uint256 baseAmount);
    event ClaimReward(uint256 baseAmount);

    function initialize(address _lizardSynteticToken) public initializer {
        _localInitialize();
        lizardSynteticToken = IERC20Burnable(_lizardSynteticToken);

        mintFeesNumerator = 1;
        mintFeesDenominator = 10000;

        redeemFeesNumerator = 1;
        redeemFeesDenominator = 10000;

        allowedSlippageBP = 100;
        depositWithdrawSlippageBP = 4; //0.04%
        balanceSlippageBP = 100; //1%
        allowedStakeSlippageBP = 500;
        isExit = false;
     

        IAaveOracle priceOracleGetter = IAaveOracle(
            aavePoolAddressesProvider.getPriceOracle()
        );

        baseOracle = IPriceFeed(
            priceOracleGetter.getSourceOfAsset(address(baseToken))
        );

        sideOracle = IPriceFeed(
            priceOracleGetter.getSourceOfAsset(address(sideToken))
        );

        uniswapRouter = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        

        aaveInterestRateMode = 2; //variable

        mathBalance = IMathBalance(0x067d60F79f5450FfEED953329911ccd22e1B1D03);

        neededHealthFactor = 1200000000000000000;
        liquidationThreshold = 860000000000000000;
        owner = msg.sender;
        operator = msg.sender;

      
        _giveAllowances();
    }

    // MODIFIERS

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    modifier onlyOperatorOrOwner() {
        require(msg.sender == owner || msg.sender == operator, "Not owner");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    //UTILS

    function applyFees(
        uint256 _amount,
        uint256 feesNumerator,
        uint256 feesDenominator
    ) internal pure returns (uint256) {
        return _amount - (_amount * feesNumerator) / feesDenominator;
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2 ** 255);
        z = int256(y);
    }

    // ONLYOWNER
    function executeAction(uint8 idAction, uint256 amount) public onlyOwner {
        _executeAction(Action(ActionType(idAction), amount));
    }

    function updateSlippagesBP(
        uint256 _allowedSlippageBP,
        uint256 _depositWithdrawSlippageBP,
        uint256 _balanceSlippageBP,
        uint256 _allowedStakeSlippageBP
    ) public onlyOwner {
        require(
            _allowedSlippageBP >= 0 && _allowedSlippageBP <= 400,
            "allowedSlippageBP not in range"
        );
        require(
            _depositWithdrawSlippageBP >= 0 && _depositWithdrawSlippageBP <= 40,
            "depositWithdrawSlippageBP not in range"
        );
        require(
            _balanceSlippageBP >= 0 && _balanceSlippageBP <= 400,
            "balanceSlippageBP not in range"
        );
        require(
            _allowedStakeSlippageBP >= 0 && _allowedStakeSlippageBP <= 1500,
            "allowedSlippageBP not in range"
        );

        allowedSlippageBP = _allowedSlippageBP;
        depositWithdrawSlippageBP = _depositWithdrawSlippageBP;
        balanceSlippageBP = _balanceSlippageBP;
        allowedStakeSlippageBP = _allowedStakeSlippageBP;
    }

    function updateHfAndLt(
        uint256 _neededHealthFactor,
        uint256 _liquidationThreshold
    ) public onlyOwner {
        require(
            _neededHealthFactor >= 1000000000000000000 &&
                _neededHealthFactor <= 2000000000000000000,
            "neededHealthFactor not in range"
        );
        require(
            _liquidationThreshold >= 800000000000000000 &&
                _liquidationThreshold <= 1000000000000000000,
            "liquidationThreshold not in range"
        );

        neededHealthFactor = _neededHealthFactor;
        liquidationThreshold = _liquidationThreshold;
    }

    function updateFees(
        uint256 _mintFeesNumerator,
        uint256 _mintFeesDenominator,
        uint256 _redeemFeesNumerator,
        uint256 _redeemFeesDenominator
    ) public onlyOwner {
        require(
            _mintFeesNumerator * 100 <= _mintFeesDenominator,
            "mint fees must be less than 1%"
        );
        require(
            _redeemFeesNumerator * 100 <= _redeemFeesDenominator,
            "redeem fees must be less than 1%"
        );

        mintFeesNumerator = _mintFeesNumerator;
        mintFeesDenominator = _mintFeesDenominator;

        redeemFeesNumerator = _redeemFeesNumerator;
        redeemFeesDenominator = _redeemFeesDenominator;
    }

    function setMaximumMint(uint256 _maximumMint) public onlyOwner {
        maximumMint = _maximumMint;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function changeOperator(address _newOperator) public onlyOwner {
        operator = _newOperator;
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        if (whitelist[_address]) {
            delete whitelist[_address];
        }
    }

    function withdrawGrowth() public onlyOwner {
        _claimRewards();
        (uint256 assetValue, uint256 lzdSupply) = pegStatus();
        assetValue = (assetValue * (10000 - depositWithdrawSlippageBP)) / 10000;
        if (assetValue > lzdSupply) {
            uint256 amountGrowth = assetValue - lzdSupply;
            uint256 navExpected = ((assetValue - amountGrowth) *
                (10000 - depositWithdrawSlippageBP)) / 10000;
            _balance(-toInt256(baseToUsd(amountGrowth)), 0);
            baseToken.transfer(
                msg.sender,
                Math.min(amountGrowth, baseToken.balanceOf(address(this)))
            );
            require(netAssetValue() >= navExpected, "nav less than expected");
        }
    }

    function claimRewards() public onlyOwner {
        uint256 rewardsAmount = _claimRewards();
        uint256 navExpected = (netAssetValue() *
            (10000 - depositWithdrawSlippageBP)) / 10000;
        if (rewardsAmount > 0) _balance(0, 0);
        require(netAssetValue() >= navExpected, "nav less than expected");
    }

    function giveAllowances() public onlyOwner {
        _giveAllowances();
    }

    function balance(uint256 balanceRatio) public onlyOperatorOrOwner {
        uint256 navExpected = (netAssetValue() * (10000 - balanceSlippageBP)) /
            10000;
        _balance(0, balanceRatio);
        require(netAssetValue() >= navExpected, "nav less than expected");
    }

    function exit() public onlyOwner nonReentrant {
        require(!isExit, "isExit==true");
        _claimRewards();
        _removeLiquidity(type(uint256).max);
        (, uint256 aaveBorrowUsd) = getBorrowAndCollateral();
        if (aaveBorrowUsd > 0) {
            uint256 sideBorrowAmount = usdToSide(aaveBorrowUsd);
            sideBorrowAmount = (sideBorrowAmount * 101) / 100 + 10;
            uint256 sideTokenBalance = sideToken.balanceOf(address(this));
            if (sideBorrowAmount > sideTokenBalance) {
                _swapBaseToSide(sideToUsd(sideBorrowAmount - sideTokenBalance));
            }
            _repaySideToAAve(type(uint256).max);
        }

        _swapSideToBase(type(uint256).max);
        _withdrawBaseFromAAve(type(uint256).max);
        isExit = true;
    }

    function stopExit() public onlyOwner nonReentrant {
        require(isExit, "isExit==false");
        isExit = false;
        uint256 navExpected = (netAssetValue() * (10000 - balanceSlippageBP)) /
            10000;
        _balance(0, 1e18);
        require(netAssetValue() >= navExpected, "nav less than expected");
    }

    //PUBLIC

    function getCurrentDebtRatio() public view returns (int256) {
        (, uint256 sideBalance) = pairBalances();
        uint256 sideUsd = sideToUsd(
            sideBalance + sideToken.balanceOf(address(this))
        );
        (, uint256 aaveBorrowUsd) = getBorrowAndCollateral();

        return int256(sideUsd == 0 ? 1e18 : ((aaveBorrowUsd * 1e18) / sideUsd));
    }

    function netAssetValue() public view returns (uint256 assetValue) {
        (
            uint256 aaveCollateralUsd,
            uint256 aaveBorrowUsd
        ) = getBorrowAndCollateral();
        (uint256 baseBalance, uint256 sideBalance) = pairBalances();
        assetValue =
            baseToken.balanceOf(address(this)) +
            baseBalance +
            usdToBase(
                aaveCollateralUsd -
                    aaveBorrowUsd +
                    sideToUsd(sideToken.balanceOf(address(this)) + sideBalance)
            );
    }

    function pegStatus()
        public
        view
        returns (uint256 assetValue, uint256 lzdSupply)
    {
        assetValue = netAssetValue();
        lzdSupply = lizardSynteticToken.totalSupply();
    }

    function deposit(uint256 _amountBase) public nonReentrant {
        require(
            tx.origin == msg.sender || whitelist[msg.sender],
            "only no smart contract or whitelist"
        );
        require(_amountBase > 0, "amount must be > 0");

        require(
            lizardSynteticToken.totalSupply() + _amountBase < maximumMint,
            "maximum lizardSyntetic minted"
        );

        uint256 navExpected = ((netAssetValue() + _amountBase) *
            (10000 - depositWithdrawSlippageBP)) / 10000;

        baseToken.safeTransferFrom(msg.sender, address(this), _amountBase);

        lizardSynteticToken.mint(
            msg.sender,
            applyFees(_amountBase, mintFeesNumerator, mintFeesDenominator)
        );

        // _balance(toInt256(baseToUsd(_amountBase)), 0);
        _balance(0, 0);

        require(netAssetValue() >= navExpected, "nav less than expected");
        emit Deposit(_amountBase);
    }

    function withdraw(uint256 _amountBase) public nonReentrant {
        require(
            tx.origin == msg.sender || whitelist[msg.sender],
            "only no smart contract or whitelist"
        );
        require(_amountBase > 0, "amount must be greater than 0");

        (uint256 assetValue, uint256 lzdSupply) = pegStatus();

        uint256 wantedBaseAmount = applyFees(
            _amountBase,
            redeemFeesNumerator,
            redeemFeesDenominator
        );

        if (assetValue < lzdSupply) //not enough  to redeem with 1/1 ratio
        {
            wantedBaseAmount = (wantedBaseAmount * (assetValue)) / lzdSupply;
        }
        require(wantedBaseAmount <= assetValue && wantedBaseAmount > 0);
        uint256 navExpected = ((netAssetValue() - _amountBase) *
            (10000 - depositWithdrawSlippageBP)) / 10000;

        _balance(-(toInt256(baseToUsd(wantedBaseAmount)) * 10001) / 10000, 0);

        uint256 realBaseAmount = Math.min(
            wantedBaseAmount,
            baseToken.balanceOf(address(this))
        );
        lizardSynteticToken.burn(
            msg.sender,
            (_amountBase * realBaseAmount) / wantedBaseAmount
        ); // burn after read totalSupply

        baseToken.safeTransfer(msg.sender, realBaseAmount);

        require(netAssetValue() >= navExpected, "nav less than expected");

        emit Withdraw(_amountBase);
    }

    function baseToUsd(uint256 amount) public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = baseOracle.latestRoundData();
        require(answeredInRound >= roundID, "Old data");
        require(timeStamp > 0, "Round not complete");
        return (amount * uint256(price)) / baseDecimals;
    }

    function usdToBase(uint256 amount) public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = baseOracle.latestRoundData();
        require(answeredInRound >= roundID, "Old data");
        require(timeStamp > 0, "Round not complete");
        return (amount * baseDecimals) / uint256(price);
    }

    function sideToUsd(uint256 amount) public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = sideOracle.latestRoundData();
        require(answeredInRound >= roundID, "Old data");
        require(timeStamp > 0, "Round not complete");
        return (amount * uint256(price)) / sideDecimals;
    }

    function usdToSide(uint256 amount) public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = sideOracle.latestRoundData();
        require(answeredInRound >= roundID, "Old data");
        require(timeStamp > 0, "Round not complete");
        return (amount * sideDecimals) / uint256(price);
    }

    function pairBalances()
        public
        view
        returns (uint256 baseBalance, uint256 sideBalance)
    {
        return _localPairBalances();
    }

    function getBorrowAndCollateral()
        public
        view
        returns (uint256 aaveCollateralUsd, uint256 aaveBorrowUsd)
    {
        IAavePool aavePool = IAavePool(aavePoolAddressesProvider.getPool());
        (aaveCollateralUsd, aaveBorrowUsd, , , , ) = aavePool
            .getUserAccountData(address(this));
    }

    function isSamePrices() public view returns (bool) {
        uint256 poolPrice = _localPairGetAmountOut(
            sideDecimals,
            address(sideToken)
        );
        uint256 oraclePrice = usdToBase(sideToUsd(sideDecimals));
        uint256 deltaPrice;
        if (poolPrice > oraclePrice) {
            deltaPrice = poolPrice - oraclePrice;
        } else {
            deltaPrice = oraclePrice - poolPrice;
        }

        return ((deltaPrice * 10000) <= allowedStakeSlippageBP * oraclePrice);
    }

    function getCurrentHealthFactor()
        public
        view
        returns (uint256 _currentHealthFactor)
    {
        IAavePool aavePool = IAavePool(aavePoolAddressesProvider.getPool());
        (, , , , , _currentHealthFactor) = aavePool.getUserAccountData(
            address(this)
        );
    }

    function k1(bool reBalance) public view returns (int256) {
        uint256 healthFactor;
        if (reBalance) {
            healthFactor = neededHealthFactor;
        } else {
            healthFactor = getCurrentHealthFactor();
            if (healthFactor == type(uint256).max) {
                healthFactor = neededHealthFactor;
            }
        }
        return int256((1e18 * healthFactor) / liquidationThreshold);
    }

    function k2() public view returns (int256) {
        (uint256 baseReserve, uint256 sideReserve) = _localPairGetReserves();
        return int256((baseToUsd(baseReserve) * 1e18) / sideToUsd(sideReserve));
    }

    function k3(uint256 balanceRatio) public view returns (int256) {
        int256 debtRatio = getCurrentDebtRatio();
        return
            debtRatio +
            int256(balanceRatio) -
            (debtRatio * int256(balanceRatio)) /
            1e18;
    }

    // INTERNAL

    function _executeAction(Action memory action) internal {
        if (action.actionType == ActionType.ADD_LIQUIDITY) {
            _addLiquidity(action.amount);
        } else if (action.actionType == ActionType.REMOVE_LIQUIDITY) {
            _removeLiquidity(action.amount);
        } else if (action.actionType == ActionType.SUPPLY_BASE_TOKEN) {
            _supplyToAAve(action.amount);
        } else if (action.actionType == ActionType.WITHDRAW_BASE_TOKEN) {
            _withdrawBaseFromAAve(usdToBase(action.amount));
        } else if (action.actionType == ActionType.BORROW_SIDE_TOKEN) {
            _borrowSideFromAAve(action.amount);
        } else if (action.actionType == ActionType.REPAY_SIDE_TOKEN) {
            _repaySideToAAve(action.amount);
        } else if (action.actionType == ActionType.SWAP_SIDE_TO_BASE) {
            _swapSideToBase(action.amount);
        } else if (action.actionType == ActionType.SWAP_BASE_TO_SIDE) {
            _swapBaseToSide(action.amount);
        }
    }

    function _balance(int256 amountUsd, uint256 balanceRatio) internal {
        if (isExit) return;

        (
            uint256 aaveCollateralUsd,
            uint256 aaveBorrowUsd
        ) = getBorrowAndCollateral();

        (, uint256 sidePoolBalance) = pairBalances();

        Action[] memory actions = IMathBalance(mathBalance).balance(
            BalanceMathInput(
                k1(balanceRatio > 0),
                k2(),
                k3(balanceRatio),
                amountUsd,
                toInt256(aaveCollateralUsd),
                toInt256(aaveBorrowUsd),
                toInt256(sideToUsd(sidePoolBalance)),
                toInt256(baseToUsd(baseToken.balanceOf(address(this)))),
                toInt256(sideToUsd(sideToken.balanceOf(address(this)))),
                toInt256(allowedSlippageBP)
            )
        );
        for (uint j; j < actions.length; j++) {
            _executeAction(actions[j]);
        }
    }

    function _giveAllowances() internal {
        // uniSwapRouter
        sideToken.approve(address(uniswapRouter), type(uint256).max);
        baseToken.approve(address(uniswapRouter), type(uint256).max);

        _localGiveAllowances();
    }

    // ADD & REMOVE LP
    function _addLiquidity(uint256 usdAmountToKeep) internal {
        if (
            baseToken.balanceOf(address(this)) == 0 ||
            sideToken.balanceOf(address(this)) == 0
        ) {
            return;
        }

        if (!isSamePrices()) return;

        uint256 baseBalance = baseToken.balanceOf(address(this));
        uint256 sideBalance = sideToken.balanceOf(address(this));
        if (usdAmountToKeep < type(uint256).max) {
            uint256 baseAmountToKeep = usdToBase(usdAmountToKeep);
            if (baseAmountToKeep > baseBalance) return;
            baseBalance = baseBalance - baseAmountToKeep;
        }

        if (baseToUsd(baseBalance) <= 100 || sideToUsd(sideBalance) <= 100) {
            return;
        }
        emit AddLiquidity(_localAddLiquidity(baseBalance, sideBalance));
        // add liquidity
    }

    function _removeLiquidity(uint256 usdAmountSide) internal {
        if (usdAmountSide == 0) return;
        if (!isSamePrices()) return;

        emit RemoveLiquidity(
            _localRemoveLiquidity(
                usdAmountSide < type(uint256).max
                    ? usdToSide(usdAmountSide)
                    : type(uint256).max
            )
        );
    }

    function _swapSideToBase(uint256 usdAmount) internal {
        if (usdAmount == 0) return;
        uint256 swapSideAmount;
        if (usdAmount == type(uint256).max) {
            swapSideAmount = sideToken.balanceOf(address(this));
        } else {
            swapSideAmount = Math.min(
                usdToSide(usdAmount),
                sideToken.balanceOf(address(this))
            );
        }

        if (swapSideAmount <= 100) {
            return;
        }

        uint256 amountOutMin = usdToBase(
            sideToUsd((swapSideAmount * (10000 - allowedSlippageBP)) / 10000)
        );

        if (amountOutMin <= 100) {
            return;
        }

        uint256 amountOut;
        {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: address(sideToken),
                    tokenOut: address(baseToken),
                    fee: uniswapPoolFee,
                    recipient: address(this),
                    amountIn: swapSideAmount,
                    amountOutMinimum: amountOutMin,
                    sqrtPriceLimitX96: 0
                });

            amountOut = uniswapRouter.exactInputSingle(params);
        }

        emit SwapSideToBase(swapSideAmount, amountOut);
    }

    function _swapBaseToSide(uint256 usdAmount) internal {
        if (usdAmount == 0) return;
        uint256 swapBaseAmount;
        if (usdAmount == type(uint256).max) {
            swapBaseAmount = baseToken.balanceOf(address(this));
        } else {
            swapBaseAmount = Math.min(
                usdToBase(usdAmount),
                baseToken.balanceOf(address(this))
            );
        }

        if (swapBaseAmount <= 100) {
            return;
        }

        uint256 amountOutMin = usdToSide(
            baseToUsd((swapBaseAmount * (10000 - allowedSlippageBP)) / 10000)
        );

        if (amountOutMin <= 100) {
            return;
        }

        uint256 amountOut;
        {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: address(baseToken),
                    tokenOut: address(sideToken),
                    fee: uniswapPoolFee,
                    recipient: address(this),
                    amountIn: swapBaseAmount,
                    amountOutMinimum: amountOutMin,
                    sqrtPriceLimitX96: 0
                });

            amountOut = uniswapRouter.exactInputSingle(params);
        }

        emit SwapBaseToSide(swapBaseAmount, amountOut);
    }

    function _supplyToAAve(uint256 usdAmount) internal {
        if (usdAmount == 0) return;
        uint256 supplyBaseAmount;
        if (usdAmount == type(uint256).max) {
            supplyBaseAmount = baseToken.balanceOf(address(this));
        } else {
            supplyBaseAmount = Math.min(
                usdToBase(usdAmount),
                baseToken.balanceOf(address(this))
            );
        }
        if (supplyBaseAmount == 0) {
            return;
        }

        IAavePool aavePool = IAavePool(aavePoolAddressesProvider.getPool());
        baseToken.approve(address(aavePool), supplyBaseAmount);
        aavePool.supply(address(baseToken), supplyBaseAmount, address(this), 0);
        emit SupplyBaseToAAve(supplyBaseAmount);
    }

    function _withdrawBaseFromAAve(uint256 baseAmount) internal {
        if (baseAmount == 0) return;
        IAavePool aavePool = IAavePool(aavePoolAddressesProvider.getPool());
        aavePool.withdraw(address(baseToken), baseAmount, address(this));
        emit WithdrawBaseFromAAve(baseAmount);
    }

    function _borrowSideFromAAve(uint256 usdAmount) internal {
        if (usdAmount == 0) return;
        uint256 borrowSideAmount = usdToSide(usdAmount);
        IAavePool aavePool = IAavePool(aavePoolAddressesProvider.getPool());
        aavePool.borrow(
            address(sideToken),
            borrowSideAmount,
            aaveInterestRateMode,
            0,
            address(this)
        );
        emit BorrowSideFromAAve(borrowSideAmount);
    }

    // repay side token to aave
    function _repaySideToAAve(uint256 usdAmount) internal {
        if (usdAmount == 0) return;

        uint256 repaySideAmount;
        if (usdAmount == type(uint256).max) {
            repaySideAmount = sideToken.balanceOf(address(this));
        } else {
            repaySideAmount = Math.min(
                usdToSide(usdAmount),
                sideToken.balanceOf(address(this))
            );
        }

        if (repaySideAmount == 0) {
            return;
        }

        IAavePool aavePool = IAavePool(aavePoolAddressesProvider.getPool());

        sideToken.approve(address(aavePool), repaySideAmount);

        aavePool.repay(
            address(sideToken),
            repaySideAmount,
            aaveInterestRateMode,
            address(this)
        );
        emit RepaySideToAAve(repaySideAmount);
    }

    function _claimRewards() internal returns (uint256) {
        uint256 amount = _localClaimRewards();
        emit ClaimReward(amount);
        return amount;
    }

    function _localClaimRewards() internal virtual returns (uint256) {
        revert("Not implemented");
    }

    function _localGiveAllowances() internal virtual {
        revert("Not implemented");
    }

    function _localRemoveLiquidity(
        uint256 usdAmountSide
    ) internal virtual returns (uint256) {
        revert("Not implemented");
    }

    function _localAddLiquidity(
        uint256 baseAmountMax,
        uint256 sideAmountMax
    ) internal virtual returns (uint256) {
        revert("Not implemented");
    }

    function _localInitialize() internal virtual {
        revert("Not implemented");
    }

    function _localPairBalances()
        internal
        view
        virtual
        returns (uint256 baseBalance, uint256 sideBalance)
    {
        revert("Not implemented");
    }

    function _localPairGetReserves()
        internal
        view
        virtual
        returns (uint256 baseReserve, uint256 sideReserve)
    {
        revert("Not implemented");
    }

    function _localPairGetAmountOut(
        uint256 amount,
        address inToken
    ) internal view virtual returns (uint256) {
        revert("Not implemented");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
interface IGaugeChronos {
  function DISTRIBUTION (  ) external view returns ( address );
  function DURATION (  ) external view returns ( uint256 );
  function TOKEN (  ) external view returns ( address );
  function _VE (  ) external view returns ( address );
  function _balances ( uint256 ) external view returns ( uint256 );
  function _depositEpoch ( uint256 ) external view returns ( uint256 );
  function _periodFinish (  ) external view returns ( uint256 );
  function _start ( uint256 ) external view returns ( uint256 );
  function _totalSupply (  ) external view returns ( uint256 );
  function balanceOfToken ( uint256 tokenId ) external view returns ( uint256 );
  function balanceOf(address _user) external view returns (uint256);
  function claimFees (  ) external returns ( uint256 claimed0, uint256 claimed1 );
  function deposit ( uint256 amount ) external returns ( uint256 _tokenId );
  function depositAll (  ) external returns ( uint256 _tokenId );
  function earned ( uint256 _tokenId ) external view returns ( uint256 );
  function external_bribe (  ) external view returns ( address );
  function fees0 (  ) external view returns ( uint256 );
  function fees1 (  ) external view returns ( uint256 );
  function gaugeRewarder (  ) external view returns ( address );
  function weightOfUser(address _user ) external view returns (uint256);
  function earned(address _user) external view returns (uint256);
  function getReward ( uint256 _tokenId ) external;
  function internal_bribe (  ) external view returns ( address );
  function isForPair (  ) external view returns ( bool );
  function lastTimeRewardApplicable (  ) external view returns ( uint256 );
  function lastUpdateTime (  ) external view returns ( uint256 );
  function maGaugeId (  ) external view returns ( uint256 );
  function maNFTs (  ) external view returns ( address );
  function maturityLevelOfTokenMaxArray ( uint256 _tokenId ) external view returns ( uint256 _matLevel );
  function maturityLevelOfTokenMaxBoost ( uint256 _tokenId ) external view returns ( uint256 _matLevel );
  function notifyRewardAmount ( address token, uint256 reward ) external;
  function owner (  ) external view returns ( address );
  function periodFinish (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function rewardForDuration (  ) external view returns ( uint256 );
  function rewardPerToken (  ) external view returns ( uint256 );
  function rewardPerTokenStored (  ) external view returns ( uint256 );
  function rewardRate (  ) external view returns ( uint256 );
  function rewardToken (  ) external view returns ( address );
  function rewards ( uint256 ) external view returns ( uint256 );
  function setDistribution ( address _distribution ) external;
  function setGaugeRewarder ( address _gaugeRewarder ) external;
  function totalSupply (  ) external view returns ( uint256 );
  function totalWeight (  ) external view returns ( uint256 _totalWeight );
  function transferOwnership ( address newOwner ) external;
  function updateReward ( uint256 _tokenId ) external;
  function userRewardPerTokenPaid ( uint256 ) external view returns ( uint256 );
  function weightOfToken ( uint256 _tokenId ) external view returns ( uint256 );
  function withdraw ( uint256 _tokenId ) external;
  function withdrawAndHarvest ( uint256 _tokenId ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./IERC20.sol";

interface IPairChronos is IERC20 {
    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
    function claimFees() external returns (uint, uint);
    function tokens() external view returns (address, address);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);

    function claimable0(address _user) external view returns (uint);
    function claimable1(address _user) external view returns (uint);

    function isStable() external view returns(bool);
    function sync() external;

    function token0() external view returns(address);
    function reserve0() external view returns(address);
    function decimals0() external view returns(address);
    function token1() external view returns(address);
    function reserve1() external view returns(address);
    function decimals1() external view returns(address);


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRouterChronos {

    struct route {
        address from;
        address to;
        bool stable;
    }

  
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1) ;
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair) ;

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB) ;

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable) ;

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, route[] memory routes) external view returns (uint[] memory amounts) ;

    function isPair(address pair) external view returns (bool) ;


    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity) ;

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity
    ) external view returns (uint amountA, uint amountB) ;


    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external  returns (uint amountA, uint amountB, uint liquidity) ;

    function addLiquidityETH(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable  returns (uint amountToken, uint amountETH, uint liquidity) ;

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external  returns (uint amountA, uint amountB) ;

    function removeLiquidityETH(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external  returns (uint amountToken, uint amountETH) ;
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) ;

    function removeLiquidityETHWithPermit(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH) ;

   

    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) ;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) ;

    function swapExactETHForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline) external payable returns (uint[] memory amounts) ;

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function UNSAFE_swapExactTokensForTokens(
        uint[] memory amounts,
        route[] calldata routes,
        address to,
        uint deadline
    ) external  returns (uint[] memory) ;





    // Experimental Extension [ETH.guru/solidly/BaseV1Router02]

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens)****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external  returns (uint amountToken, uint amountETH) ;
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH) ;
    
   
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external  ;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    )
        external
        payable
        ;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    )
        external
        
    ;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IMaLPNFTChronos {
  

  function addGauge ( address _maGaugeAddress, address _pool, address _token0, address _token1, uint _maGaugeId ) external;
  function approve ( address _approved, uint256 _tokenId ) external;
  function artProxy (  ) external view returns ( address );
  function balanceOf ( address _owner ) external view returns ( uint256 );
  function burn ( uint256 _tokenId ) external;
  function getApproved ( uint256 _tokenId ) external view returns ( address );
  function initialize ( address art_proxy ) external;
  function isApprovedForAll ( address _owner, address _operator ) external view returns ( bool );
  function isApprovedOrOwner ( address _spender, uint256 _tokenId ) external view returns ( bool );
  function killGauge ( address _gauge ) external;
  function maGauges ( address ) external view returns (
    bool active,
    bool stablePair,
    address pair,
    address token0,
    address token1,
    address maGaugeAddress,
    string memory name,
    string memory symbol,
    uint maGaugeId
  );
  function mint ( address _to ) external returns ( uint256 _tokenId );
  function ms (  ) external view returns ( address );
  function name (  ) external view returns ( string memory );
  function ownerOf ( uint256 _tokenId ) external view returns ( address );
  function ownership_change ( uint256 ) external view returns ( uint256 );
  function reset (  ) external;
  function reviveGauge ( address _gauge ) external;
  function maGaugeTokensOfOwner(address _owner, address _gauge) external view returns (uint256[] memory);
  function fromThisGauge(uint _tokenId) external view returns(bool);
  function safeTransferFrom ( address _from, address _to, uint256 _tokenId ) external;
  function safeTransferFrom ( address _from, address _to, uint256 _tokenId, bytes memory _data  ) external;
  function setApprovalForAll ( address _operator, bool _approved ) external;
  function setArtProxy ( address _proxy ) external;
  function setBoostParams ( uint256 _maxBonusEpoch, uint256 _maxBonusPercent ) external;
  function setTeam ( address _team ) external;
  function supportsInterface ( bytes4 _interfaceID ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function team (  ) external view returns ( address );
  function getWeightByEpoch() external view returns (uint[] memory weightsByEpochs);
  function totalMaLevels() external view returns (uint _totalMaLevels);
  function tokenOfOwnerByIndex ( address _owner, uint256 _tokenIndex ) external view returns ( uint256 );
  function tokenToGauge ( uint256 ) external view returns ( address );
  function tokenURI ( uint256 _tokenId ) external view returns ( string memory );
  function transferFrom ( address _from, address _to, uint256 _tokenId ) external;
  function version (  ) external view returns ( string memory );
  function voter (  ) external view returns ( address );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Burnable {
    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param oldAddress The old address of the Pool
     * @param newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param oldAddress The old address of the PoolConfigurator
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed implementationAddress
    );

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice Returns the id of the Aave market to which this contract points to.
     * @return The market id
     **/
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple Aave markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(
        bytes32 id,
        address newImplementationAddress
    ) external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     **/
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     **/
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     **/
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     **/
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     **/
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     **/
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     **/
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./IPoolAddressesProvider.sol";

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
        uint256 data;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        address priceSource;
        string label;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveAToken;
        address priceOracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool useATokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteSetUserEModeParams {
        uint256 reservesCount;
        address oracle;
        uint8 categoryId;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
        uint8 fromEModeCategory;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        uint256[] interestRateModes;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address addressesProvider;
        uint8 userEModeCategory;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
        bool isolationModeActive;
        address isolationModeCollateralAddress;
        uint256 isolationModeDebtCeiling;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct CalculateInterestRatesParams {
        uint256 unbacked;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address aToken;
    }

    struct InitReserveParams {
        address asset;
        address aTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }
}



/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IAavePool {
    /**
     * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   **/
    event MintUnbacked(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   **/
    event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

    /**
     * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   **/
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool useATokens
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
    event SwapBorrowRateMode(
        address indexed reserve,
        address indexed user,
        DataTypes.InterestRateMode interestRateMode
    );

    /**
     * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
    event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

    /**
     * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   **/
    event UserEModeSet(address indexed user, uint8 categoryId);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   **/
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @dev Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function mintUnbacked(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   **/
    function backUnbacked(
        address asset,
        uint256 amount,
        uint256 fee
    ) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   **/
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   **/
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   **/
    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    /**
     * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

    /**
     * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
    function getUserAccountData(address user)
    external
    view
    returns (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );

    /**
     * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   **/
    function dropReserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
    external;

    /**
     * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
    function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
    function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   **/
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   **/
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   **/
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

    /**
     * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
    function updateFlashloanPremiums(
        uint128 flashLoanPremiumTotal,
        uint128 flashLoanPremiumToProtocol
    ) external;

    /**
     * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
    function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

    /**
     * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
    function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

    /**
     * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
    function getUserEMode(address user) external view returns (uint256);

    /**
     * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
    function resetIsolationModeTotalDebt(address asset) external;

    /**
     * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

    /**
     * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol treasury
   */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   **/
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}


/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 **/
interface IPriceOracleGetter {
    /**
     * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   **/
    function BASE_CURRENCY() external view returns (address);

    /**
     * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   **/
    function BASE_CURRENCY_UNIT() external view returns (uint256);

    /**
     * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   **/
    function getAssetPrice(address asset) external view returns (uint256);
}


/**
 * @title IAaveOracle
 * @author Aave
 * @notice Defines the basic interface for the Aave Oracle
 */
interface IAaveOracle is IPriceOracleGetter {
    /**
     * @dev Emitted after the base currency is set
   * @param baseCurrency The base currency of used for price quotes
   * @param baseCurrencyUnit The unit of the base currency
   */
    event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

    /**
     * @dev Emitted after the price source of an asset is updated
   * @param asset The address of the asset
   * @param source The price source of the asset
   */
    event AssetSourceUpdated(address indexed asset, address indexed source);

    /**
     * @dev Emitted after the address of fallback oracle is updated
   * @param fallbackOracle The address of the fallback oracle
   */
    event FallbackOracleUpdated(address indexed fallbackOracle);

    /**
     * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Sets or replaces price sources of assets
   * @param assets The addresses of the assets
   * @param sources The addresses of the price sources
   */
    function setAssetSources(address[] calldata assets, address[] calldata sources) external;

    /**
     * @notice Sets the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
    function setFallbackOracle(address fallbackOracle) external;

    /**
     * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    /**
     * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
    function getSourceOfAsset(address asset) external view returns (address);

    /**
     * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
    function getFallbackOracle() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IPriceFeed {

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

enum ActionType {
    ADD_LIQUIDITY,
    REMOVE_LIQUIDITY,
    SUPPLY_BASE_TOKEN,
    WITHDRAW_BASE_TOKEN,
    BORROW_SIDE_TOKEN,
    REPAY_SIDE_TOKEN,
    SWAP_SIDE_TO_BASE,
    SWAP_BASE_TO_SIDE
}
struct Action {
    ActionType actionType;
    uint256 amount;
}

struct BalanceMathInput {
    int256 k1;
    int256 k2;
    int256 k3;
    int256 amount;
    int256 baseCollateral;
    int256 sideBorrow;
    int256 sidePool;
    int256 baseFree;
    int256 sideFree;
    int256 tokenAssetSlippagePercent;
}

interface IMathBalance {
function balance(BalanceMathInput calldata i
    )
        external
        view
        returns (
            Action[] memory actions
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IBlockGetter {

    function getNumber() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library Math {

  function max(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function positiveInt128(int128 value) internal pure returns (int128) {
    return value < 0 ? int128(0) : value;
  }

  function closeTo(uint a, uint b, uint target) internal pure returns (bool) {
    if (a > b) {
      if (a - b <= target) {
        return true;
      }
    } else {
      if (b - a <= target) {
        return true;
      }
    }
    return false;
  }

  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;


library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.15;

import "../interface/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint value
  ) internal {
    uint newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.15;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}