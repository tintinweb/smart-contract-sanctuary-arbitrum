// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./../../utils/UpgradeableBase.sol";
import "./../../interfaces/IXToken.sol";
import "./../../interfaces/IMultiLogicProxy.sol";
import "./../../interfaces/ILogicContract.sol";
import "./../../interfaces/IStrategyStatistics.sol";
import "./../../interfaces/IStrategyContract.sol";
import "./LendBorrowLendStrategyHelper.sol";

contract LendBorrowLendStrategy is UpgradeableBase, IStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for uint256;

    address internal constant ZERO_ADDRESS = address(0);
    uint256 internal constant DECIMALS = 18;
    uint256 internal constant BASE = 10**DECIMALS;

    address public logic;
    address public blid;
    address public strategyXToken;
    address public strategyToken;
    address public comptroller;
    address public rewardsToken;

    // Strategy Parameter
    uint8 public circlesCount;
    uint8 public avoidLiquidationFactor;

    uint256 private minStorageAvailable;
    uint256 public borrowRateMin;
    uint256 public borrowRateMax;

    address public multiLogicProxy;
    address public strategyStatistics;

    // RewardsTokenPrice kill switch
    uint256 public rewardsTokenPriceDeviationLimit; // percentage, decimal = 18
    RewardsTokenPriceInfo private rewardsTokenPriceInfo;

    uint256 minimumBLIDPerRewardToken;
    uint256 minRewardsSwapLimit;

    // Swap Information
    SwapInfo internal swapRewardsToBLIDInfo;
    SwapInfo internal swapRewardsToStrategyTokenInfo;
    SwapInfo internal swapStrategyTokenToBLIDInfo;
    SwapInfo internal swapStrategyTokenToSupplyTokenInfo;
    SwapInfo internal swapSupplyTokenToBLIDInfo;

    address public supplyXToken;
    address public supplyToken;

    event SetBLID(address blid);
    event SetCirclesCount(uint8 circlesCount);
    event SetAvoidLiquidationFactor(uint8 avoidLiquidationFactor);
    event SetMinRewardsSwapLimit(uint256 _minRewardsSwapLimit);
    event SetStrategyXToken(address strategyXToken);
    event SetSupplyXToken(address supplyXToken);
    event SetMinStorageAvailable(uint256 minStorageAvailable);
    event SetRebalanceParameter(uint256 borrowRateMin, uint256 borrowRateMax);
    event SetRewardsTokenPriceDeviationLimit(uint256 deviationLimit);
    event SetRewardsTokenPriceInfo(uint256 latestAnser, uint256 timestamp);
    event BuildCircle(address token, uint256 amount, uint256 circlesCount);
    event DestroyCircle(
        address token,
        uint256 circlesCount,
        uint256 destroyAmountLimit
    );
    event DestroyAll(address token, uint256 destroyAmount, uint256 blidAmount);
    event ClaimRewards(uint256 amount);
    event UseToken(address token, uint256 amount);
    event ReleaseToken(address token, uint256 amount);

    function __Strategy_init(address _comptroller, address _logic)
        public
        initializer
    {
        UpgradeableBase.initialize();
        comptroller = _comptroller;
        rewardsToken = ILendingLogic(_logic).rewardToken();
        logic = _logic;

        rewardsTokenPriceDeviationLimit = (1 ether) / uint256(86400); // limit is 100% within 1 day, 50% within 1 day = (1 ether) * 50 / (100 * 86400)
    }

    receive() external payable {}

    modifier onlyMultiLogicProxy() {
        _;
    }

    modifier onlyStrategyPaused() {
        require(_checkStrategyPaused(), "C2");
        _;
    }

    /*** Public Initialize Function ***/

    /**
     * @notice Set blid in contract
     * @param _blid Address of BLID
     */
    function setBLID(address _blid) external onlyOwner {
        if (_blid != ZERO_ADDRESS) {
            blid = _blid;
            emit SetBLID(_blid);
        }
    }

    /**
     * @notice Set MultiLogicProxy, you can call the function once
     * @param _multiLogicProxy Address of Multilogic Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        if (_multiLogicProxy != ZERO_ADDRESS) {
            multiLogicProxy = _multiLogicProxy;
        }
    }

    /**
     * @notice Set StrategyStatistics
     * @param _strategyStatistics Address of StrategyStatistics
     */
    function setStrategyStatistics(address _strategyStatistics)
        external
        onlyOwner
    {
        if (_strategyStatistics != ZERO_ADDRESS) {
            strategyStatistics = _strategyStatistics;

            // Save RewardsTokenPriceInfo
            rewardsTokenPriceInfo.latestAnswer = IStrategyStatistics(
                _strategyStatistics
            ).getRewardsTokenPrice(comptroller, rewardsToken);
            rewardsTokenPriceInfo.timestamp = block.timestamp;
        }
    }

    /**
     * @notice Set circlesCount
     * @param _circlesCount Count number
     */
    function setCirclesCount(uint8 _circlesCount) external onlyOwner {
        circlesCount = _circlesCount;

        emit SetCirclesCount(_circlesCount);
    }

    /**
     * @notice Set min Rewards swap limit
     * @param _minRewardsSwapLimit minimum swap amount for rewards token
     */
    function setMinRewardsSwapLimit(uint256 _minRewardsSwapLimit)
        external
        onlyOwner
    {
        minRewardsSwapLimit = _minRewardsSwapLimit;

        emit SetMinRewardsSwapLimit(_minRewardsSwapLimit);
    }

    /**
     * @notice Set minimumBLIDPerRewardToken
     * @param _minimumBLIDPerRewardToken minimum BLID for RewardsToken
     */
    function setMinBLIDPerRewardsToken(uint256 _minimumBLIDPerRewardToken)
        external
        onlyOwner
    {
        minimumBLIDPerRewardToken = _minimumBLIDPerRewardToken;
    }

    /**
     * @notice Set Rewards -> StrategyToken swap information
     * @param swapInfo : addresses of swapRouter and path
     * @param swapPurpose : index of swap purpose
     * 0 : swapRewardsToBLIDInfo
     * 1 : swapRewardsToStrategyTokenInfo
     * 2 : swapStrategyTokenToBLIDInfo
     * 3 : swapStrategyTokenToSupplyTokenInfo
     * 4 : swapSupplyTokenToBLIDInfo
     */
    function setSwapInfo(SwapInfo memory swapInfo, uint8 swapPurpose)
        external
        onlyOwner
    {
        LendBorrowLendStrategyHelper.checkSwapInfo(
            swapInfo,
            swapPurpose,
            supplyToken,
            strategyToken,
            rewardsToken,
            blid
        );

        if (swapPurpose == 0) {
            swapRewardsToBLIDInfo.swapRouters = swapInfo.swapRouters;
            swapRewardsToBLIDInfo.paths = swapInfo.paths;
        } else if (swapPurpose == 1) {
            swapRewardsToStrategyTokenInfo.swapRouters = swapInfo.swapRouters;
            swapRewardsToStrategyTokenInfo.paths = swapInfo.paths;
        } else if (swapPurpose == 2) {
            swapStrategyTokenToBLIDInfo.swapRouters = swapInfo.swapRouters;
            swapStrategyTokenToBLIDInfo.paths = swapInfo.paths;
        } else if (swapPurpose == 3) {
            swapStrategyTokenToSupplyTokenInfo.swapRouters = swapInfo
                .swapRouters;
            swapStrategyTokenToSupplyTokenInfo.paths = swapInfo.paths;
        } else {
            swapSupplyTokenToBLIDInfo.swapRouters = swapInfo.swapRouters;
            swapSupplyTokenToBLIDInfo.paths = swapInfo.paths;
        }
    }

    /**
     * @notice Set avoidLiquidationFactor
     * @param _avoidLiquidationFactor factor value (0-99)
     */
    function setAvoidLiquidationFactor(uint8 _avoidLiquidationFactor)
        external
        onlyOwner
    {
        require(_avoidLiquidationFactor < 100, "C4");

        avoidLiquidationFactor = _avoidLiquidationFactor;
        emit SetAvoidLiquidationFactor(_avoidLiquidationFactor);
    }

    /**
     * @notice Set MinStorageAvailable
     * @param amount amount of min storage available for token using : decimals = token decimals
     */
    function setMinStorageAvailable(uint256 amount) external onlyOwner {
        minStorageAvailable = amount;

        emit SetMinStorageAvailable(amount);
    }

    /**
     * @notice Set RebalanceParameter
     * @param _borrowRateMin borrowRate min : decimals = 18
     * @param _borrowRateMax borrowRate max : deciamls = 18
     */
    function setRebalanceParameter(
        uint256 _borrowRateMin,
        uint256 _borrowRateMax
    ) external onlyOwner {
        require(_borrowRateMin < BASE && _borrowRateMax < BASE, "C4");

        borrowRateMin = _borrowRateMin;
        borrowRateMax = _borrowRateMax;

        emit SetRebalanceParameter(_borrowRateMin, _borrowRateMin);
    }

    /**
     * @notice Set RewardsTokenPriceDeviationLimit
     * @param _rewardsTokenPriceDeviationLimit price Diviation per seccond limit
     */
    function setRewardsTokenPriceDeviationLimit(
        uint256 _rewardsTokenPriceDeviationLimit
    ) external onlyOwner {
        rewardsTokenPriceDeviationLimit = _rewardsTokenPriceDeviationLimit;

        emit SetRewardsTokenPriceDeviationLimit(
            _rewardsTokenPriceDeviationLimit
        );
    }

    /**
     * @notice Force update rewardsTokenPrice
     * @param latestAnswer new latestAnswer
     */
    function setRewardsTokenPrice(uint256 latestAnswer) external onlyOwner {
        rewardsTokenPriceInfo.latestAnswer = latestAnswer;
        rewardsTokenPriceInfo.timestamp = block.timestamp;

        emit SetRewardsTokenPriceInfo(latestAnswer, block.timestamp);
    }

    /*** Public Automation Check view function ***/

    /**
     * @notice Check wheather storageAvailable is bigger enough
     * @return canUseToken true : useToken is possible
     */
    function checkUseToken() public view override returns (bool canUseToken) {
        if (
            IMultiLogicProxy(multiLogicProxy).getTokenAvailable(
                supplyToken,
                logic
            ) < minStorageAvailable
        ) {
            canUseToken = false;
        } else {
            canUseToken = true;
        }
    }

    /**
     * @notice Check whether borrow rate is ok
     * @return canRebalance true : rebalance is possible, borrow rate is abnormal
     */
    function checkRebalance() public view override returns (bool canRebalance) {
        // Get lending status, borrowRate
        (bool isLending, uint256 borrowRate) = LendBorrowLendStrategyHelper
            .getBorrowRate(
                strategyStatistics,
                logic,
                supplyXToken,
                strategyXToken
            );

        // If no lending, can't rebalance
        if (!isLending) return false;

        // Determine rebalance with borrowRate
        if (borrowRate > borrowRateMax || borrowRate < borrowRateMin) {
            canRebalance = true;
        } else {
            canRebalance = false;
        }
    }

    /**
     * @notice Set StrategyXToken
     * Add XToken for circle in Contract and approve token
     * @param _xToken Address of XToken
     */
    function setStrategyXToken(address _xToken)
        external
        onlyOwner
        onlyStrategyPaused
    {
        if (_xToken != ZERO_ADDRESS && strategyXToken != _xToken) {
            strategyXToken = _xToken;
            strategyToken = _registerToken(_xToken, logic);

            emit SetStrategyXToken(_xToken);
        }
    }

    /**
     * @notice Set SupplyXToken
     * Add XToken for supply in Contract and approve token
     * @param _xToken Address of XToken
     */
    function setSupplyXToken(address _xToken)
        external
        onlyOwner
        onlyStrategyPaused
    {
        if (_xToken != ZERO_ADDRESS && supplyXToken != _xToken) {
            supplyXToken = _xToken;
            supplyToken = _registerToken(_xToken, logic);

            emit SetSupplyXToken(_xToken);
        }
    }

    /*** Public Strategy Function ***/

    function useToken() external override {
        address _logic = logic;
        address _supplyXToken = supplyXToken;
        address _strategyXToken = strategyXToken;
        address _supplyToken = supplyToken;

        // Check if storageAvailable is bigger enough
        uint256 availableAmount = IMultiLogicProxy(multiLogicProxy)
            .getTokenAvailable(_supplyToken, _logic);
        if (availableAmount < minStorageAvailable) return;

        // Take token from storage
        ILogic(_logic).takeTokenFromStorage(availableAmount, _supplyToken);

        // If strategy is empty, entermarket again
        if (
            ILendingLogic(_logic).checkEnteredMarket(_supplyXToken) == false ||
            ILendingLogic(_logic).checkEnteredMarket(_strategyXToken) == false
        ) {
            address[] memory tokens = new address[](2);
            tokens[0] = _supplyXToken;
            tokens[1] = _strategyXToken;
            ILendingLogic(_logic).enterMarkets(tokens);
        }

        // Mint
        ILendingLogic(_logic).mint(_supplyXToken, availableAmount);

        emit UseToken(_supplyToken, availableAmount);
    }

    function rebalance() external override {
        address _logic = logic;
        address _strategyXToken = strategyXToken;
        address _supplyXToken = supplyXToken;
        uint8 _circlesCount = circlesCount;

        // Get CollateralFactor
        (
            uint256 collateralFactorStrategy,
            uint256 collateralFactorStrategyApplied
        ) = _getCollateralFactor(_strategyXToken);

        // Get XToken information
        uint256 supplyBorrowLimitUSD;
        uint256 strategyPriceUSD;

        if (_supplyXToken != _strategyXToken) {
            XTokenInfo memory tokenInfo = IStrategyStatistics(
                strategyStatistics
            ).getStrategyXTokenInfo(_supplyXToken, _logic);

            supplyBorrowLimitUSD = tokenInfo.borrowLimitUSD;
        }

        // Call accrueInterest
        ILendingLogic(_logic).accrueInterest(_strategyXToken);
        ILendingLogic(_logic).accrueInterest(_supplyXToken);

        int256 amount;
        (amount, strategyPriceUSD) = LendBorrowLendStrategyHelper
            .getRebalanceAmount(
                RebalanceParam({
                    strategyStatistics: strategyStatistics,
                    logic: _logic,
                    supplyXToken: _supplyXToken,
                    strategyXToken: _strategyXToken,
                    borrowRateMin: borrowRateMin,
                    borrowRateMax: borrowRateMax,
                    circlesCount: _circlesCount,
                    supplyBorrowLimitUSD: supplyBorrowLimitUSD,
                    collateralFactorStrategy: collateralFactorStrategy,
                    collateralFactorStrategyApplied: collateralFactorStrategyApplied
                })
            );

        // Build
        if (amount > 0) {
            createCircles(_strategyXToken, uint256(amount), _circlesCount);

            emit BuildCircle(_strategyXToken, uint256(amount), _circlesCount);
        }

        // Destroy
        if (amount < 0) {
            destructCircles(
                _strategyXToken,
                _circlesCount,
                supplyBorrowLimitUSD,
                collateralFactorStrategyApplied,
                strategyPriceUSD,
                uint256(0 - amount)
            );
            emit DestroyCircle(
                _strategyXToken,
                _circlesCount,
                uint256(0 - amount)
            );
        }
    }

    /**
     * @notice Destroy circle strategy
     * destroy circle and return all tokens to storage
     */
    function destroyAll() external override onlyOwnerAndAdmin {
        address _logic = logic;
        address _rewardsToken = rewardsToken;
        address _supplyXToken = supplyXToken;
        address _strategyXToken = strategyXToken;
        address _supplyToken = supplyToken;
        address _strategyStatistics = strategyStatistics;
        uint256 amountBLID = 0;

        // Destruct circle
        {
            // Get Supply XToken information
            uint256 supplyBorrowLimitUSD;
            uint256 strategyPriceUSD;

            if (_supplyXToken != _strategyXToken) {
                XTokenInfo memory tokenInfo = IStrategyStatistics(
                    strategyStatistics
                ).getStrategyXTokenInfo(_supplyXToken, _logic);

                supplyBorrowLimitUSD = tokenInfo.borrowLimitUSD;

                tokenInfo = IStrategyStatistics(_strategyStatistics)
                    .getStrategyXTokenInfo(_strategyXToken, _logic);

                strategyPriceUSD = tokenInfo.priceUSD;
            }

            // Get Collateral Factor
            (, uint256 collateralFactorStrategyApplied) = _getCollateralFactor(
                _strategyXToken
            );

            destructCircles(
                _strategyXToken,
                circlesCount,
                supplyBorrowLimitUSD,
                collateralFactorStrategyApplied,
                strategyPriceUSD,
                0
            );
        }

        // Claim Rewards token
        ILendingLogic(_logic).claim();

        // Get Rewards amount
        uint256 amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken)
            .balanceOf(_logic);

        // RewardsToken Price/Amount Kill Switch
        bool rewardsTokenKill = _rewardsPriceKillSwitch(
            _strategyStatistics,
            _rewardsToken,
            amountRewardsToken
        );

        // swap rewardsToken to StrategyToken
        if (rewardsTokenKill == false && amountRewardsToken > 0) {
            _multiSwap(
                _logic,
                amountRewardsToken,
                swapRewardsToStrategyTokenInfo
            );
        }

        // Process With Supply != Strategy
        if (_supplyXToken != _strategyXToken) {
            (uint256 totalSupply, , uint256 borrowAmount) = IStrategyStatistics(
                _strategyStatistics
            ).getStrategyXTokenInfoCompact(_strategyXToken, _logic);

            // StrategyXToken : if totalSupply > 0, redeem it
            if (totalSupply > 0) {
                ILendingLogic(_logic).redeem(
                    _strategyXToken,
                    IERC20MetadataUpgradeable(_strategyXToken).balanceOf(_logic)
                );
            }

            // StrategyXToken : If borrowAmount > 0, repay it
            if (borrowAmount > 0) {
                ILendingLogic(_logic).repayBorrow(
                    _strategyXToken,
                    borrowAmount
                );
            }

            // SupplyXToken : Redeem everything
            ILendingLogic(_logic).redeem(
                _supplyXToken,
                IERC20MetadataUpgradeable(_supplyXToken).balanceOf(_logic)
            );

            // Swap StrategyToken -> SupplyToken
            _multiSwap(
                _logic,
                IERC20MetadataUpgradeable(strategyToken).balanceOf(_logic),
                swapStrategyTokenToSupplyTokenInfo
            );
        }

        // Get strategy amount, current balance of underlying
        uint256 amountStrategy = IMultiLogicProxy(multiLogicProxy)
            .getTokenTaken(_supplyToken, _logic);
        uint256 balanceToken = _supplyToken == ZERO_ADDRESS
            ? address(_logic).balance
            : IERC20MetadataUpgradeable(_supplyToken).balanceOf(_logic);

        // If we have extra, swap SupplyToken to BLID
        if (balanceToken > amountStrategy) {
            _multiSwap(
                _logic,
                balanceToken - amountStrategy,
                swapSupplyTokenToBLIDInfo
            );

            // Add BLID earn to storage
            amountBLID = _addEarnToStorage();
        } else {
            amountStrategy = balanceToken;
        }

        // Return all tokens to strategy
        ILogic(_logic).returnTokenToStorage(amountStrategy, _supplyToken);

        emit DestroyAll(_supplyXToken, amountStrategy, amountBLID);
    }

    /**
     * @notice claim distribution rewards USDT both borrow and lend swap banana token to BLID
     */
    function claimRewards() public override onlyOwnerAndAdmin {
        address _logic = logic;
        address _strategyXToken = strategyXToken;
        address _strategyToken = strategyToken;
        address _rewardsToken = rewardsToken;
        address _strategyStatistics = strategyStatistics;
        uint256 amountRewardsToken;

        // Call accrueInterest
        ILendingLogic(_logic).accrueInterest(_strategyXToken);

        // Claim Rewards token
        ILendingLogic(_logic).claim();

        // Get Rewards amount
        amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken).balanceOf(
                _logic
            );

        // RewardsToken Price/Amount Kill Switch
        bool rewardsTokenKill = _rewardsPriceKillSwitch(
            _strategyStatistics,
            _rewardsToken,
            amountRewardsToken
        );

        // Get remained amount
        (, int256 diffStrategy) = LendBorrowLendStrategyHelper
            .getDiffAmountForClaim(
                _strategyStatistics,
                _logic,
                multiLogicProxy,
                supplyXToken,
                _strategyXToken,
                supplyToken,
                _strategyToken
            );

        // If we need to replay, swap DF->Strategy and repay it
        if (diffStrategy > 0 && !rewardsTokenKill) {
            // Swap Rewards -> StrategyToken
            _multiSwap(
                _logic,
                amountRewardsToken,
                swapRewardsToStrategyTokenInfo
            );

            // Repay StrategyToken
            uint256 balanceStrategyToken = IERC20MetadataUpgradeable(
                _strategyToken
            ).balanceOf(_logic);
            if (balanceStrategyToken > uint256(diffStrategy))
                balanceStrategyToken = uint256(diffStrategy);

            // RepayBorrow
            ILendingLogic(_logic).repayBorrow(
                _strategyXToken,
                balanceStrategyToken
            );
        }

        // If we need to redeem, redeem
        if (diffStrategy < 0) {
            ILendingLogic(_logic).redeemUnderlying(
                _strategyXToken,
                uint256(0 - diffStrategy)
            );
        }

        // swap Rewards to BLID
        amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken).balanceOf(
                _logic
            );
        if (amountRewardsToken > 0 && rewardsTokenKill == false) {
            _multiSwap(_logic, amountRewardsToken, swapRewardsToBLIDInfo);
            require(
                (amountRewardsToken * minimumBLIDPerRewardToken) / BASE <=
                    IERC20MetadataUpgradeable(blid).balanceOf(_logic),
                "C5"
            );
        }

        // If we have Strategy Token, swap StrategyToken to BLID
        uint256 balanceStrategyToken = _strategyToken == ZERO_ADDRESS
            ? address(_logic).balance
            : IERC20MetadataUpgradeable(_strategyToken).balanceOf(_logic);
        if (balanceStrategyToken > 0) {
            _multiSwap(
                _logic,
                balanceStrategyToken,
                swapStrategyTokenToBLIDInfo
            );
        }

        // Add BLID earn to storage
        uint256 amountBLID = _addEarnToStorage();

        emit ClaimRewards(amountBLID);
    }

    /**
     * @notice Frees up tokens for the user, but Storage doesn't transfer token for the user,
     * only Storage can this function, after calling this function Storage transfer
     * from Logic to user token.
     * @param amount Amount of token
     * @param token Address of token
     */
    function releaseToken(uint256 amount, address token)
        external
        override
        onlyMultiLogicProxy
    {
        address _supplyXToken = supplyXToken;
        address _strategyXToken = strategyXToken;
        address _logic = logic;
        require(token == supplyToken, "C9");

        // Call accrueInterest
        ILendingLogic(_logic).accrueInterest(_strategyXToken);
        ILendingLogic(_logic).accrueInterest(_supplyXToken);

        // Destruct Circle
        {
            // Get Supply XToken information
            uint256 supplyBorrowLimitUSD;
            uint256 supplyPriceUSD;

            if (_supplyXToken != _strategyXToken) {
                XTokenInfo memory tokenInfo = IStrategyStatistics(
                    strategyStatistics
                ).getStrategyXTokenInfo(_supplyXToken, _logic);

                supplyBorrowLimitUSD = tokenInfo.borrowLimitUSD;
                supplyPriceUSD = tokenInfo.priceUSD;
            }

            // Get destroyAmount
            uint256 destroyAmount;
            uint256 strategyPriceUSD;
            uint256 collateralFactorStrategyApplied;

            {
                // Get CollateralFactor
                uint256 collateralFactorSupply;
                uint256 collateralFactorStrategy;
                (
                    collateralFactorStrategy,
                    collateralFactorStrategyApplied
                ) = _getCollateralFactor(_strategyXToken);

                (collateralFactorSupply, ) = _getCollateralFactor(
                    _supplyXToken
                );

                // Get destroy amount
                (destroyAmount, strategyPriceUSD) = LendBorrowLendStrategyHelper
                    .getDestroyAmountForRelease(
                        strategyStatistics,
                        _logic,
                        amount,
                        _supplyXToken,
                        _strategyXToken,
                        supplyBorrowLimitUSD,
                        supplyPriceUSD,
                        collateralFactorSupply,
                        collateralFactorStrategy
                    );
            }

            // destruct circle
            destructCircles(
                _strategyXToken,
                circlesCount,
                supplyBorrowLimitUSD,
                collateralFactorStrategyApplied,
                strategyPriceUSD,
                destroyAmount
            );
        }

        // Check if redeem is possible
        (int256 diffSupply, ) = LendBorrowLendStrategyHelper
            .getDiffAmountForClaim(
                strategyStatistics,
                _logic,
                multiLogicProxy,
                _supplyXToken,
                _strategyXToken,
                token,
                strategyToken
            );

        if (
            diffSupply >=
            IMultiLogicProxy(multiLogicProxy)
                .getTokenTaken(token, _logic)
                .toInt256() -
                (amount).toInt256()
        ) {
            ILendingLogic(_logic).claim();

            uint256 amountRewardsToken = IERC20MetadataUpgradeable(rewardsToken)
                .balanceOf(_logic);

            bool rewardsTokenKill = _rewardsPriceKillSwitch(
                strategyStatistics,
                rewardsToken,
                amountRewardsToken
            );
            require(!rewardsTokenKill, "C10");

            _multiSwap(
                _logic,
                amountRewardsToken,
                swapRewardsToStrategyTokenInfo
            );

            (, , uint256 borrowAmount) = IStrategyStatistics(strategyStatistics)
                .getStrategyXTokenInfoCompact(_strategyXToken, _logic);

            if (borrowAmount > 0) {
                ILendingLogic(_logic).repayBorrow(
                    _strategyXToken,
                    borrowAmount
                );
            }
        }

        // Redeem for release token
        uint256 balance;
        if (token == ZERO_ADDRESS) {
            balance = address(_logic).balance;
        } else {
            balance = IERC20MetadataUpgradeable(token).balanceOf(_logic);
        }

        if (balance < amount) {
            ILendingLogic(_logic).redeemUnderlying(
                _supplyXToken,
                amount - balance
            );
        }

        // Send ETH
        if (token == ZERO_ADDRESS) {
            ILogic(_logic).returnETHToMultiLogicProxy(amount);
        }

        emit ReleaseToken(token, amount);
    }

    /*** Private Function ***/

    /**
     * @notice creates circle (borrow-lend) of the base token
     * token (of amount) should be mint before start build
     * @param xToken xToken address
     * @param amount amount to build (borrowAmount)
     * @param iterateCount the number circles to
     */
    function createCircles(
        address xToken,
        uint256 amount,
        uint8 iterateCount
    ) private {
        address _logic = logic;
        uint256 _amount = amount;

        // Get collateralFactor, the maximum proportion of borrow/lend
        // apply avoidLiquidationFactor
        (, uint256 collateralFactorApplied) = _getCollateralFactor(xToken);
        require(collateralFactorApplied > 0, "C1");

        if (_amount > 0) {
            for (uint256 i = 0; i < iterateCount; ) {
                ILendingLogic(_logic).borrow(xToken, _amount);
                ILendingLogic(_logic).mint(xToken, _amount);
                _amount = (_amount * collateralFactorApplied) / BASE;

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice unblock all the money
     * @param xToken xToken address
     * @param iterateCount the number circles to : maximum iterates to do, the real number might be less then iterateCount
     * @param supplyBorrowLimitUSD Borrow limit in USD for supply token (deciamls = 18)
     * @param collateralFactorApplied Collateral factor with AvoidLiquidationFactor for strategyToken (decimals = 18)
     * @param priceUSD USD price of strategyToken (decimals = 18 + (18 - token.decimals))
     * @param destroyAmountLimit if > 0, stop destroy if total repay is destroyAmountLimit
     */
    function destructCircles(
        address xToken,
        uint8 iterateCount,
        uint256 supplyBorrowLimitUSD,
        uint256 collateralFactorApplied,
        uint256 priceUSD,
        uint256 destroyAmountLimit
    ) private {
        iterateCount = iterateCount + 3; // additional iteration to repay all borrowed

        address _logic = logic;
        uint256 _destroyAmountLimit = destroyAmountLimit;
        bool matched = supplyXToken == strategyXToken;

        // Check collateralFactor with avoidLiquidationFactor
        require(collateralFactorApplied > 0, "C1");

        for (uint256 i = 0; i < iterateCount; ) {
            uint256 borrowBalance; // balance of borrowed amount
            uint256 supplyBalance; // Total supply

            // Get BorrowBalance, Total Supply
            {
                uint256 xTokenBalance; // balance of xToken

                // get infromation of account
                xTokenBalance = IERC20Upgradeable(xToken).balanceOf(_logic);
                borrowBalance = IXToken(xToken).borrowBalanceCurrent(_logic);

                // calculates of supplied balance, divided by 10^18 to safe digits correctly
                {
                    //conversion rate from iToken to token
                    uint256 exchangeRateMantissa = IXToken(xToken)
                        .exchangeRateStored();
                    supplyBalance =
                        (xTokenBalance * exchangeRateMantissa) /
                        BASE;
                }

                // if nothing to repay
                if (borrowBalance == 0 || xTokenBalance == 1) {
                    // redeem and exit
                    if (xTokenBalance > 0) {
                        ILendingLogic(_logic).redeem(xToken, xTokenBalance);
                    }
                    return;
                }

                // if already redeemed
                if (supplyBalance == 0) {
                    return;
                }
            }

            // calculates how much percents could be borrowed and not to be liquidated, then multiply fo supply balance to calculate the amount
            uint256 withdrawBalance;
            if (matched) {
                withdrawBalance =
                    (supplyBalance * collateralFactorApplied) /
                    BASE -
                    borrowBalance;
            } else {
                withdrawBalance =
                    ((supplyBorrowLimitUSD +
                        (((supplyBalance * collateralFactorApplied) / BASE) *
                            priceUSD) /
                        BASE -
                        (borrowBalance * priceUSD) /
                        BASE) * BASE) /
                    priceUSD;

                // Withdraw balance can't be bigger than supply
                if (withdrawBalance > supplyBalance) {
                    withdrawBalance = supplyBalance;
                }
            }

            // If we have destroylimit, redeem only limit
            if (
                destroyAmountLimit > 0 && withdrawBalance > _destroyAmountLimit
            ) {
                withdrawBalance = _destroyAmountLimit;
            }

            // if redeem tokens
            ILendingLogic(_logic).redeemUnderlying(xToken, withdrawBalance);
            uint256 repayAmount = strategyToken == ZERO_ADDRESS
                ? address(_logic).balance
                : IERC20Upgradeable(strategyToken).balanceOf(_logic);

            // if there is something to repay
            if (repayAmount > 0) {
                // if borrow balance more then we have on account
                if (borrowBalance <= repayAmount) {
                    repayAmount = borrowBalance;
                }
                ILendingLogic(_logic).repayBorrow(xToken, repayAmount);
            }

            // Stop destroy if destroyAmountLimit < sumRepay
            if (destroyAmountLimit > 0) {
                if (_destroyAmountLimit <= repayAmount) break;
                _destroyAmountLimit = _destroyAmountLimit - repayAmount;
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice check if strategy distroy circles
     * @return paused true : strategy is empty, false : strategy has some lending token
     */
    function _checkStrategyPaused() private view returns (bool paused) {
        address _strategyXToken = strategyXToken;
        if (_strategyXToken == ZERO_ADDRESS) return true;

        (uint256 totalSupply, , uint256 borrowAmount) = IStrategyStatistics(
            strategyStatistics
        ).getStrategyXTokenInfoCompact(_strategyXToken, logic);

        if (totalSupply > 0 || borrowAmount > 0) {
            paused = false;
        } else {
            paused = true;
        }
    }

    /**
     * @notice Send all BLID to storage
     * @return amountBLID BLID amount
     */
    function _addEarnToStorage() private returns (uint256 amountBLID) {
        address _logic = logic;
        amountBLID = IERC20Upgradeable(blid).balanceOf(_logic);
        if (amountBLID > 0) {
            ILogic(_logic).addEarnToStorage(amountBLID);
        }
    }

    /**
     * @notice Process RewardsTokenPrice kill switch
     * @param _strategyStatistics : stratgyStatistics
     * @param _rewardsToken : rewardsToken
     * @param _amountRewardsToken : rewardsToken balance
     * @return killSwitch true : DF price should be protected, false : DF price is ok
     */
    function _rewardsPriceKillSwitch(
        address _strategyStatistics,
        address _rewardsToken,
        uint256 _amountRewardsToken
    ) private returns (bool killSwitch) {
        uint256 latestAnswer;
        (latestAnswer, killSwitch) = LendBorrowLendStrategyHelper
            .checkRewardsPriceKillSwitch(
                _strategyStatistics,
                comptroller,
                _rewardsToken,
                _amountRewardsToken,
                rewardsTokenPriceInfo,
                rewardsTokenPriceDeviationLimit,
                minRewardsSwapLimit
            );

        // Keep current status
        rewardsTokenPriceInfo.latestAnswer = latestAnswer;
        rewardsTokenPriceInfo.timestamp = block.timestamp;
    }

    /**
     * @notice Swap tokens base on SwapInfo
     */
    function _multiSwap(
        address _logic,
        uint256 amount,
        SwapInfo memory swapInfo
    ) private {
        for (uint256 i = 0; i < swapInfo.swapRouters.length; ) {
            if (i > 0) {
                amount = swapInfo.paths[i][0] == ZERO_ADDRESS
                    ? address(_logic).balance
                    : IERC20MetadataUpgradeable(swapInfo.paths[i][0]).balanceOf(
                            _logic
                        );
            }

            ILogic(_logic).swap(
                swapInfo.swapRouters[i],
                amount,
                1,
                swapInfo.paths[i],
                true,
                block.timestamp + 300
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get underlying
     * call Logic.addXTokens
     */
    function _registerToken(address xToken, address _logic)
        private
        returns (address underlying)
    {
        underlying = ILendingLogic(_logic).getUnderlying(xToken);

        // Add token/iToken to Logic
        ILendingLogic(_logic).addXTokens(underlying, xToken);
    }

    /*** Virtual Internal Functions ***/

    /**
     * @notice get CollateralFactor from market
     * Apply avoidLiquidationFactor
     * @param xToken : address of xToken
     * @return collateralFactor decimal = 18
     * @return collateralFactorApplied decimal = 18
     */
    function _getCollateralFactor(address xToken)
        private
        view
        returns (uint256 collateralFactor, uint256 collateralFactorApplied)
    {
        // get collateralFactor from market
        collateralFactor = ILendingLogic(logic).getCollateralFactor(xToken);

        // Apply avoidLiquidationFactor to collateralFactor
        collateralFactorApplied =
            collateralFactor -
            avoidLiquidationFactor *
            10**16;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./OwnableUpgradeableVersionable.sol";
import "./OwnableUpgradeableAdminable.sol";

abstract contract UpgradeableBase is
    Initializable,
    OwnableUpgradeableVersionable,
    OwnableUpgradeableAdminable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    function initialize() public onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IXToken {
    function mint(uint256 mintAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemTokenAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function underlying() external view returns (address);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function interestRateModel() external view returns (address);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function getCash() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function accrueInterest() external returns (uint256);
}

interface IXTokenETH {
    function mint() external payable;

    function borrow(uint256 borrowAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMultiLogicProxy {
    function releaseToken(uint256 amount, address token) external;

    function takeToken(uint256 amount, address token) external;

    function addEarn(uint256 amount, address blidToken) external;

    function returnToken(uint256 amount, address token) external;

    function setLogicTokenAvailable(
        uint256 amount,
        address token,
        uint256 deposit_withdraw
    ) external;

    function getTokenAvailable(address _token, address _logicAddress)
        external
        view
        returns (uint256);

    function getTokenTaken(address _token, address _logicAddress)
        external
        view
        returns (uint256);

    function getUsedTokensStorage() external view returns (address[] memory);

    function multiStrategyLength() external view returns (uint256);

    function multiStrategyName(uint256) external view returns (string memory);

    function strategyInfo(string memory)
        external
        view
        returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ILogicContract {
    function addXTokens(
        address token,
        address xToken,
        uint8 leadingTokenType
    ) external;

    function approveTokenForSwap(address token) external;

    function claim(address[] calldata xTokens, uint8 leadingTokenType) external;

    function mint(address xToken, uint256 mintAmount)
        external
        returns (uint256);

    function borrow(
        address xToken,
        uint256 borrowAmount,
        uint8 leadingTokenType
    ) external returns (uint256);

    function repayBorrow(address xToken, uint256 repayAmount) external;

    function redeemUnderlying(address xToken, uint256 redeemAmount)
        external
        returns (uint256);

    function swapExactTokensForTokens(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOut,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function addLiquidityETH(
        address swap,
        address token,
        uint256 amountTokenDesired,
        uint256 amountETHDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address swap,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH);

    function addEarnToStorage(uint256 amount) external;

    function enterMarkets(address[] calldata xTokens, uint8 leadingTokenType)
        external
        returns (uint256[] memory);

    function returnTokenToStorage(uint256 amount, address token) external;

    function takeTokenFromStorage(uint256 amount, address token) external;

    function returnETHToMultiLogicProxy(uint256 amount) external;

    function deposit(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdraw(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function returnToken(uint256 amount, address token) external; // for StorageV2 only
}

/************* New Architecture *************/
interface ISwapLogic {
    function swap(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swap(
        address swapRouter,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface ILogic is ISwapLogic {
    function addEarnToStorage(uint256 amount) external;

    function returnTokenToStorage(uint256 amount, address token) external;

    function takeTokenFromStorage(uint256 amount, address token) external;

    function returnETHToMultiLogicProxy(uint256 amount) external;

    function multiLogicProxy() external view returns (address);

    function approveTokenForSwap(address _swap, address token) external;
}

interface ILendingLogic is ILogic {
    function isXTokenUsed(address xToken) external view returns (bool);

    function addXTokens(address token, address xToken) external;

    function comptroller() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function checkEnteredMarket(address xToken) external view returns (bool);

    function getUnderlyingPrice(address xToken) external view returns (uint256);

    function getUnderlying(address xToken) external view returns (address);

    function getXToken(address token) external view returns (address);

    function getCollateralFactor(address xToken)
        external
        view
        returns (uint256);

    function rewardToken() external view returns (address);

    function enterMarkets(address[] calldata xTokens)
        external
        returns (uint256[] memory);

    function claim() external;

    function mint(address xToken, uint256 mintAmount)
        external
        returns (uint256);

    function borrow(address xToken, uint256 borrowAmount)
        external
        returns (uint256);

    function repayBorrow(address xToken, uint256 repayAmount)
        external
        returns (uint256);

    function redeemUnderlying(address xToken, uint256 redeemAmount)
        external
        returns (uint256);

    function redeem(address xToken, uint256 redeemTokenAmount)
        external
        returns (uint256);

    function accrueInterest(address xToken) external;
}

interface IFarmingLogic is ILogic {
    function addLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function farmingDeposit(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function farmingWithdraw(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
struct XTokenInfo {
    string symbol;
    address xToken;
    uint256 totalSupply;
    uint256 totalSupplyUSD;
    uint256 lendingAmount;
    uint256 lendingAmountUSD;
    uint256 borrowAmount;
    uint256 borrowAmountUSD;
    uint256 borrowLimit;
    uint256 borrowLimitUSD;
    uint256 underlyingBalance;
    uint256 priceUSD;
}

struct XTokenAnalytics {
    string symbol;
    address platformAddress;
    string underlyingSymbol;
    address underlyingAddress;
    uint256 underlyingDecimals;
    uint256 underlyingPrice;
    uint256 totalSupply;
    uint256 totalSupplyUSD;
    uint256 totalBorrows;
    uint256 totalBorrowsUSD;
    uint256 liquidity;
    uint256 collateralFactor;
    uint256 borrowApy;
    uint256 borrowRewardsApy;
    uint256 supplyApy;
    uint256 supplyRewardsApy;
}

struct StrategyStatistics {
    XTokenInfo[] xTokensStatistics;
    WalletInfo[] walletStatistics;
    uint256 lendingEarnedUSD;
    uint256 totalSupplyUSD;
    uint256 totalBorrowUSD;
    uint256 totalBorrowLimitUSD;
    uint256 borrowRate;
    uint256 storageAvailableUSD;
    int256 totalAmountUSD;
}

struct FarmingPairInfo {
    uint256 index;
    address lpToken;
    uint256 farmingAmount;
    uint256 rewardsAmount;
    uint256 rewardsAmountUSD;
}

struct WalletInfo {
    string symbol;
    address token;
    uint256 balance;
    uint256 balanceUSD;
}

struct PriceInfo {
    address token;
    uint256 priceUSD;
}

interface IStrategyStatistics {
    function getXTokenInfo(address _asset, address comptroller)
        external
        view
        returns (XTokenAnalytics memory);

    function getXTokensInfo(address comptroller)
        external
        view
        returns (XTokenAnalytics[] memory);

    function getStrategyStatistics(address logic)
        external
        view
        returns (StrategyStatistics memory statistics);

    function getStrategyXTokenInfo(address xToken, address logic)
        external
        view
        returns (XTokenInfo memory tokenInfo);

    function getStrategyXTokenInfoCompact(address xToken, address logic)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 borrowLimit,
            uint256 borrowAmount
        );

    function getRewardsTokenPrice(address comptroller, address rewardsToken)
        external
        view
        returns (uint256 priceUSD);

    function getEnteredMarkets(address comptroller, address logic)
        external
        view
        returns (address[] memory markets);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IStrategyVenus {
    function farmingPair() external view returns (address);

    function lendToken() external;

    function build(uint256 usdAmount) external;

    function destroy(uint256 percentage) external;

    function claimRewards(uint8 mode) external;
}

interface IStrategy {
    function releaseToken(uint256 amount, address token) external; // onlyMultiLogicProxy

    function logic() external view returns (address);

    function useToken() external; // Automation

    function rebalance() external; // Automation

    function checkUseToken() external view returns (bool); // Automation

    function checkRebalance() external view returns (bool); // Automation

    function destroyAll() external; // onlyOwnerAdmin

    function claimRewards() external; // onlyOwnerAdmin
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./../../interfaces/IStrategyStatistics.sol";
import "./../../interfaces/IMultiLogicProxy.sol";

struct RebalanceParam {
    address strategyStatistics;
    address logic;
    address supplyXToken;
    address strategyXToken;
    uint256 borrowRateMin;
    uint256 borrowRateMax;
    uint256 circlesCount;
    uint256 supplyBorrowLimitUSD;
    uint256 collateralFactorStrategy;
    uint256 collateralFactorStrategyApplied;
}

struct RewardsTokenPriceInfo {
    uint256 latestAnswer;
    uint256 timestamp;
}

struct SwapInfo {
    address[] swapRouters;
    address[][] paths;
}

library LendBorrowLendStrategyHelper {
    using SafeCastUpgradeable for uint256;

    uint256 internal constant BASE = 10**DECIMALS;
    uint256 internal constant DECIMALS = 18;

    /**
     * @notice Get BorrowRate of strategy
     * @param strategyStatistics Address of Statistics
     * @param logic Address of strategy's logic
     * @param supplyXToken XToken address for supplying
     * @param strategyXToken XToken address for circle
     * @return isLending true : there is supply, false : there is no supply
     * @return borrowRate borrowAmountUSD / borrowLimitUSD (decimals = 18)
     */
    function getBorrowRate(
        address strategyStatistics,
        address logic,
        address supplyXToken,
        address strategyXToken
    ) public view returns (bool isLending, uint256 borrowRate) {
        uint256 totalSupply;
        uint256 borrowLimit;
        uint256 borrowAmount;

        if (supplyXToken == strategyXToken) {
            (totalSupply, borrowLimit, borrowAmount) = IStrategyStatistics(
                strategyStatistics
            ).getStrategyXTokenInfoCompact(strategyXToken, logic);
        } else {
            XTokenInfo memory supplyInfo = IStrategyStatistics(
                strategyStatistics
            ).getStrategyXTokenInfo(supplyXToken, logic);
            XTokenInfo memory strategyInfo = IStrategyStatistics(
                strategyStatistics
            ).getStrategyXTokenInfo(strategyXToken, logic);

            totalSupply =
                supplyInfo.totalSupplyUSD +
                strategyInfo.totalSupplyUSD;
            borrowLimit =
                supplyInfo.borrowLimitUSD +
                strategyInfo.borrowLimitUSD;
            borrowAmount = strategyInfo.borrowAmountUSD;
        }

        // If no lending, can't rebalance
        isLending = totalSupply > 0 ? true : false;
        borrowRate = borrowLimit == 0 ? 0 : (borrowAmount * BASE) / borrowLimit;
    }

    /**
     * @notice Get BorrowRate of strategy
     * @return amount amount > 0 : build Amount, amount < 0 : destroy Amount
     */
    function getRebalanceAmount(RebalanceParam memory param)
        public
        view
        returns (int256 amount, uint256 priceUSD)
    {
        uint256 borrowRate;
        uint256 targetBorrowRate = param.borrowRateMin +
            (param.borrowRateMax - param.borrowRateMin) /
            2;
        uint256 totalSupply;
        uint256 borrowLimit;
        uint256 borrowAmount;
        uint256 P = 0; // Borrow Limit of supplyXToken

        if (param.supplyXToken == param.strategyXToken) {
            (totalSupply, borrowLimit, borrowAmount) = IStrategyStatistics(
                param.strategyStatistics
            ).getStrategyXTokenInfoCompact(param.strategyXToken, param.logic);

            borrowRate = borrowLimit == 0
                ? 0
                : (borrowAmount * BASE) / borrowLimit;
        } else {
            XTokenInfo memory strategyInfo = IStrategyStatistics(
                param.strategyStatistics
            ).getStrategyXTokenInfo(param.strategyXToken, param.logic);

            borrowRate = (param.supplyBorrowLimitUSD +
                strategyInfo.borrowLimitUSD) == 0
                ? 0
                : (strategyInfo.borrowAmountUSD * BASE) /
                    (param.supplyBorrowLimitUSD + strategyInfo.borrowLimitUSD);

            totalSupply = strategyInfo.totalSupplyUSD;
            borrowAmount = strategyInfo.borrowAmountUSD;
            P = param.supplyBorrowLimitUSD;
            priceUSD = strategyInfo.priceUSD;
        }

        // Build
        if (borrowRate < param.borrowRateMin) {
            uint256 Y = 0;
            {
                uint256 accLTV = BASE;
                for (uint256 i = 0; i < param.circlesCount; ) {
                    Y = Y + accLTV;
                    accLTV =
                        (accLTV * param.collateralFactorStrategyApplied) /
                        BASE;
                    unchecked {
                        ++i;
                    }
                }
            }
            uint256 buildAmount = ((((((totalSupply * targetBorrowRate) /
                BASE) * param.collateralFactorStrategy) / BASE) +
                (targetBorrowRate * P) /
                BASE -
                borrowAmount) * BASE) /
                ((Y *
                    (BASE -
                        (targetBorrowRate * param.collateralFactorStrategy) /
                        BASE)) / BASE);
            amount = (buildAmount).toInt256();
        }

        // Destroy
        if (borrowRate > param.borrowRateMax) {
            uint256 destroyAmount = ((borrowAmount -
                (P * targetBorrowRate) /
                BASE -
                (((totalSupply * targetBorrowRate) / BASE) *
                    param.collateralFactorStrategy) /
                BASE) * BASE) /
                (BASE -
                    (targetBorrowRate * param.collateralFactorStrategy) /
                    BASE);

            amount = 0 - (destroyAmount).toInt256();
        }

        // Calculate token amount base on USD price
        if (param.supplyXToken != param.strategyXToken) {
            amount = (amount * (BASE).toInt256()) / (priceUSD).toInt256();
        }
    }

    function getDestroyAmountForRelease(
        address strategyStatistics,
        address logic,
        uint256 releaseAmount,
        address supplyXToken,
        address strategyXToken,
        uint256 supplyBorrowLimitUSD,
        uint256 supplyPriceUSD,
        uint256 collateralFactorSupply,
        uint256 collateralFactorStrategy
    ) public view returns (uint256 destroyAmount, uint256 strategyPriceUSD) {
        if (supplyXToken == strategyXToken) {
            (uint256 totalSupply, , uint256 borrowAmount) = IStrategyStatistics(
                strategyStatistics
            ).getStrategyXTokenInfoCompact(strategyXToken, logic);

            destroyAmount =
                (borrowAmount * releaseAmount) /
                (totalSupply - borrowAmount);
        } else {
            XTokenInfo memory strategyInfo = IStrategyStatistics(
                strategyStatistics
            ).getStrategyXTokenInfo(strategyXToken, logic);

            strategyPriceUSD = strategyInfo.priceUSD;

            // Convert releaseAmount to USD
            releaseAmount = (releaseAmount * supplyPriceUSD) / BASE;

            // Calculate destroyAmount in USD
            destroyAmount = (((releaseAmount * collateralFactorSupply) / BASE) *
                strategyInfo.borrowAmountUSD);
            destroyAmount =
                destroyAmount /
                (supplyBorrowLimitUSD +
                    (strategyInfo.totalSupplyUSD * collateralFactorStrategy) /
                    BASE -
                    (strategyInfo.borrowAmountUSD * collateralFactorStrategy) /
                    BASE);

            // Convert destroyAmount to Token
            destroyAmount = (destroyAmount * BASE) / strategyPriceUSD;
        }
    }

    function getDiffAmountForClaim(
        address strategyStatistics,
        address logic,
        address multiLogicProxy,
        address supplyXToken,
        address strategyXToken,
        address supplyToken,
        address strategyToken
    ) public view returns (int256 diffSupply, int256 diffStrategy) {
        if (supplyXToken == strategyXToken) {
            (uint256 totalSupply, , uint256 borrowAmount) = IStrategyStatistics(
                strategyStatistics
            ).getStrategyXTokenInfoCompact(strategyXToken, logic);

            diffSupply =
                (
                    IMultiLogicProxy(multiLogicProxy).getTokenTaken(
                        strategyToken,
                        logic
                    )
                ).toInt256() -
                (totalSupply).toInt256() +
                (borrowAmount).toInt256();
            diffStrategy = diffSupply;
        } else {
            XTokenInfo memory supplyInfo = IStrategyStatistics(
                strategyStatistics
            ).getStrategyXTokenInfo(supplyXToken, logic);

            XTokenInfo memory strategyInfo = IStrategyStatistics(
                strategyStatistics
            ).getStrategyXTokenInfo(strategyXToken, logic);

            uint256 lendingAmountUSD = (IMultiLogicProxy(multiLogicProxy)
                .getTokenTaken(supplyToken, logic) * supplyInfo.priceUSD) /
                BASE;

            int256 diff = (lendingAmountUSD).toInt256() -
                (supplyInfo.totalSupplyUSD).toInt256() -
                (strategyInfo.totalSupplyUSD).toInt256() +
                (strategyInfo.borrowAmountUSD).toInt256();
            diffSupply =
                (diff * (BASE).toInt256()) /
                (supplyInfo.priceUSD).toInt256();
            diffStrategy =
                (diff * (BASE).toInt256()) /
                (strategyInfo.priceUSD).toInt256();
        }
    }

    function checkSwapInfo(
        SwapInfo memory swapInfo,
        uint8 swapPurpose,
        address supplyToken,
        address strategyToken,
        address rewardsToken,
        address blid
    ) public pure {
        require(swapInfo.swapRouters.length == swapInfo.paths.length, "C6");
        require(swapPurpose < 5, "C3");
        if (swapPurpose == 0 || swapPurpose == 1) {
            require(swapInfo.paths[0][0] == rewardsToken, "C7");
        } else if (swapPurpose == 2 || swapPurpose == 3) {
            require(swapInfo.paths[0][0] == strategyToken, "C7");
        } else {
            require(swapInfo.paths[0][0] == supplyToken, "C7");
        }
        if (swapPurpose == 1) {
            require(
                swapInfo.paths[swapInfo.paths.length - 1][
                    swapInfo.paths[swapInfo.paths.length - 1].length - 1
                ] == strategyToken,
                "C8"
            );
        } else if (swapPurpose == 3) {
            require(
                swapInfo.paths[swapInfo.paths.length - 1][
                    swapInfo.paths[swapInfo.paths.length - 1].length - 1
                ] == supplyToken,
                "C8"
            );
        } else {
            require(
                swapInfo.paths[swapInfo.paths.length - 1][
                    swapInfo.paths[swapInfo.paths.length - 1].length - 1
                ] == blid,
                "C8"
            );
        }
    }

    function checkRewardsPriceKillSwitch(
        address strategyStatistics,
        address comptroller,
        address rewardsToken,
        uint256 amountRewardsToken,
        RewardsTokenPriceInfo memory rewardsTokenPriceInfo,
        uint256 rewardsTokenPriceDeviationLimit,
        uint256 minRewardsSwapLimit
    ) public view returns (uint256 latestAnswer, bool killSwitch) {
        killSwitch = false;

        // Get latest Answer
        latestAnswer = IStrategyStatistics(strategyStatistics)
            .getRewardsTokenPrice(comptroller, rewardsToken);

        // Calculate Delta
        int256 delta = (rewardsTokenPriceInfo.latestAnswer).toInt256() -
            (latestAnswer).toInt256();
        if (delta < 0) delta = 0 - delta;

        // Check deviation
        if (
            block.timestamp == rewardsTokenPriceInfo.timestamp ||
            rewardsTokenPriceInfo.latestAnswer == 0
        ) {
            delta = 0;
        } else {
            delta =
                (delta * (1 ether)) /
                ((rewardsTokenPriceInfo.latestAnswer).toInt256() *
                    ((block.timestamp).toInt256() -
                        (rewardsTokenPriceInfo.timestamp).toInt256()));
        }
        if (uint256(delta) > rewardsTokenPriceDeviationLimit) {
            killSwitch = true;
        }

        // If rewards balance is below limit, activate kill switch
        if (amountRewardsToken <= minRewardsSwapLimit) killSwitch = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableVersionable is OwnableUpgradeable {
    string private _version;
    string private _purpose;

    event UpgradeVersion(string version, string purpose);

    function getVersion() external view returns (string memory) {
        return _version;
    }

    function getPurpose() external view returns (string memory) {
        return _purpose;
    }

    /**
     * @notice Set version and purpose
     * @param version Version string, ex : 1.2.0
     * @param purpose Purpose string
     */
    function upgradeVersion(string memory version, string memory purpose)
        external
        onlyOwner
    {
        require(bytes(version).length != 0, "OV1");

        _version = version;
        _purpose = purpose;

        emit UpgradeVersion(version, purpose);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableAdminable is OwnableUpgradeable {
    address private _admin;

    event SetAdmin(address admin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "OA1");
        _;
    }

    modifier onlyOwnerAndAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "OA2");
        _;
    }

    /**
     * @notice Set admin
     * @param newAdmin Addres of new admin
     */
    function setAdmin(address newAdmin) external onlyOwner {
        _admin = newAdmin;
        emit SetAdmin(newAdmin);
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}