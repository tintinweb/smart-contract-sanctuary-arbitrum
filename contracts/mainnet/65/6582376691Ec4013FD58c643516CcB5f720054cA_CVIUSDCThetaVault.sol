// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import '@coti-cvi/contracts-cvi/contracts/ThetaVault.sol';

contract CVIUSDCThetaVault is ThetaVault {
  constructor() ThetaVault() {}
}

contract CVIUSDCThetaVault2X is ThetaVault {
  constructor() ThetaVault() {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import './interfaces/IThetaVault.sol';
import './interfaces/IRequestManager.sol';
import './external/IUniswapV2Pair.sol';
import './external/IUniswapV2Router02.sol';
import './external/IUniswapV2Factory.sol';

contract ThetaVault is Initializable, IThetaVault, IRequestManager, OwnableUpgradeable, ERC20Upgradeable, ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Request {
        uint8 requestType; // 1 => deposit, 2 => withdraw
        uint168 tokenAmount;
        uint32 targetTimestamp;
        address owner;
        bool shouldStake;
    }

    uint8 public constant DEPOSIT_REQUEST_TYPE = 1;
    uint8 public constant WITHDRAW_REQUEST_TYPE = 2;

    uint256 public constant PRECISION_DECIMALS = 1e10;
    uint16 public constant MAX_PERCENTAGE = 10000;

    uint16 public constant UNISWAP_REMOVE_MAX_FEE_PERCENTAGE = 5;

    address public fulfiller;

    IERC20Upgradeable public token;
    IPlatform public platform;
    IVolatilityToken public override volToken;
    IUniswapV2Router02 public router;

    uint256 public override nextRequestId;
    mapping(uint256 => Request) public override requests;
    mapping(address => uint256) public lastDepositTimestamp;

    uint256 public initialTokenToThetaTokenRate;

    uint256 public totalDepositRequestsAmount;
    uint256 public override totalVaultLeveragedAmount; // Obsolete

    uint16 public minPoolSkewPercentage;
    uint16 public extraLiqidityPercentage;
    uint256 public depositCap;
    uint256 public requestDelay;
    uint256 public lockupPeriod;
    uint256 public liquidationPeriod;

    uint256 public override minRequestId;
    uint256 public override maxMinRequestIncrements;
    uint256 public minDepositAmount;
    uint256 public minWithdrawAmount;

    uint256 public totalHoldingsAmount;
    uint16 public depositHoldingsPercentage;

    uint16 public minDexPercentageAllowed;

    IRewardRouter public rewardRouter;

    function initialize(uint256 _initialTokenToThetaTokenRate, IPlatform _platform, IVolatilityToken _volToken, IRewardRouter _rewardRouter, IERC20Upgradeable _token, IUniswapV2Router02 _router, string memory _lpTokenName, string memory _lpTokenSymbolName) public initializer {
        require(address(_platform) != address(0));
        require(address(_volToken) != address(0));
        require(address(_token) != address(0));
        require(address(_router) != address(0));
        require(_initialTokenToThetaTokenRate > 0);

        nextRequestId = 1;
        minRequestId = 1;
        initialTokenToThetaTokenRate = _initialTokenToThetaTokenRate;
        minPoolSkewPercentage = 300;
        extraLiqidityPercentage = 1500;
        depositCap = type(uint256).max;
        requestDelay = 0.5 hours;
        lockupPeriod = 24 hours;
        liquidationPeriod = 3 days;
        maxMinRequestIncrements = 30;
        minDepositAmount = 100000;
        minWithdrawAmount = 10 ** 16;
        depositHoldingsPercentage = 1500;
        minDexPercentageAllowed = 3000;

        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        ERC20Upgradeable.__ERC20_init(_lpTokenName, _lpTokenSymbolName);

        platform = _platform;
        token = _token;
        volToken = _volToken;
        router = _router;
        rewardRouter = _rewardRouter;

        token.safeApprove(address(platform), type(uint256).max);
        token.safeApprove(address(router), type(uint256).max);
        token.safeApprove(address(volToken), type(uint256).max);
        IERC20Upgradeable(address(volToken)).safeApprove(address(router), type(uint256).max);
        IERC20Upgradeable(address(getPair())).safeApprove(address(router), type(uint256).max);
        IERC20Upgradeable(address(volToken)).safeApprove(address(volToken), type(uint256).max);
    }

    function submitDepositRequest(uint168 _tokenAmount/* , bool _shouldStake */) external override returns (uint256 requestId) {
        require(_tokenAmount >= minDepositAmount, 'Too small');
        // require(!_shouldStake || address(rewardRouter) != address(0), 'Router not set');
        return submitRequest(DEPOSIT_REQUEST_TYPE, _tokenAmount, false);
    }

    function submitWithdrawRequest(uint168 _thetaTokenAmount) external override returns (uint256 requestId) {
        require(_thetaTokenAmount >= minWithdrawAmount, 'Too small');
        require(lastDepositTimestamp[msg.sender] + lockupPeriod <= block.timestamp, 'Deposit locked');
        return submitRequest(WITHDRAW_REQUEST_TYPE, _thetaTokenAmount, false);
    }

    struct FulfillDepositLocals {
        uint256 mintVolTokenUSDCAmount;
        uint256 addedLiquidityUSDCAmount;
        uint256 mintedVolTokenAmount;
        uint256 platformLiquidityAmount;
        uint256 holdingsAmount;
    }

    function fulfillDepositRequest(uint256 _requestId) external override returns (uint256 thetaTokensMinted) {
        uint168 amountToFulfill;
        address owner;
        uint256 volTokenPositionBalance;

        bool shouldStake = requests[_requestId].shouldStake;
        {
            bool wasLiquidated;
            (amountToFulfill, owner, wasLiquidated) = preFulfillRequest(_requestId, requests[_requestId], DEPOSIT_REQUEST_TYPE);

            if (wasLiquidated) {
                return 0;
            }

            deleteRequest(_requestId);

            // Note: reverts if pool is skewed after arbitrage, as intended
            uint256 balance;
            (balance, volTokenPositionBalance) = _rebalance(amountToFulfill);

            // Mint theta lp tokens
            if (totalSupply() > 0 && balance > 0) {
                thetaTokensMinted = (amountToFulfill * totalSupply()) / balance;
            } else {
                thetaTokensMinted = amountToFulfill * initialTokenToThetaTokenRate;
            }
        }

        require(thetaTokensMinted > 0); // 'Too few tokens'
        _mint(owner, thetaTokensMinted);

        lastDepositTimestamp[owner] = block.timestamp;

        // Avoid crashing in case an old request existed when totalDepositRequestsAmount was initialized
        if (totalDepositRequestsAmount < amountToFulfill) {
            totalDepositRequestsAmount = 0;
        } else {
            totalDepositRequestsAmount -= amountToFulfill;
        }

        FulfillDepositLocals memory locals = deposit(amountToFulfill, volTokenPositionBalance);

        if (shouldStake) {
            rewardRouter.stakeForAccount(StakedTokenName.THETA_VAULT, owner, thetaTokensMinted);
        }

        emit FulfillDeposit(_requestId, owner, amountToFulfill, locals.platformLiquidityAmount, locals.mintVolTokenUSDCAmount, locals.mintedVolTokenAmount, 
            locals.addedLiquidityUSDCAmount, thetaTokensMinted);
    }

    struct FulfillWithdrawLocals {
        uint256 withdrawnLiquidity;
        uint256 platformLPTokensToRemove;
        uint256 removedVolTokensAmount;
        uint256 dexRemovedUSDC;
        uint256 burnedVolTokensUSDCAmount;
    }

    function fulfillWithdrawRequest(uint256 _requestId) external override returns (uint256 tokenWithdrawnAmount) {
        (uint168 amountToFulfill, address owner, bool wasLiquidated) = preFulfillRequest(_requestId, requests[_requestId], WITHDRAW_REQUEST_TYPE);

        if (!wasLiquidated) {
            _rebalance(0);

            FulfillWithdrawLocals memory locals;

            locals.platformLPTokensToRemove = (amountToFulfill * IERC20Upgradeable(address(platform)).balanceOf(address(this))) / totalSupply();
            uint256 poolLPTokensAmount = (amountToFulfill * IERC20Upgradeable(address(getPair())).balanceOf(address(this))) /
                totalSupply();
            if (poolLPTokensAmount > 0) {
                (locals.removedVolTokensAmount, locals.dexRemovedUSDC) = router.removeLiquidity(address(volToken), address(token), poolLPTokensAmount, 0, 0, address(this), block.timestamp);
                locals.burnedVolTokensUSDCAmount = burnVolTokens(locals.removedVolTokensAmount);
            }

            (, locals.withdrawnLiquidity) = platform.withdrawLPTokens(locals.platformLPTokensToRemove);

            uint256 withdrawHoldings = totalHoldingsAmount * amountToFulfill / totalSupply();
            tokenWithdrawnAmount = withdrawHoldings + locals.withdrawnLiquidity + locals.dexRemovedUSDC + locals.burnedVolTokensUSDCAmount;
            totalHoldingsAmount -= withdrawHoldings;

            _burn(address(this), amountToFulfill);
            deleteRequest(_requestId);

            token.safeTransfer(owner, tokenWithdrawnAmount);

            emit FulfillWithdraw(_requestId, owner, tokenWithdrawnAmount, locals.withdrawnLiquidity, locals.removedVolTokensAmount, locals.burnedVolTokensUSDCAmount, locals.dexRemovedUSDC, amountToFulfill);
        }
    }

    function liquidateRequest(uint256 _requestId) external override nonReentrant {
        Request memory request = requests[_requestId];
        require(request.requestType != 0); // 'Request id not found'
        require(isLiquidable(_requestId), 'Not liquidable');

        _liquidateRequest(_requestId);
    }

    function rebalance() external override onlyOwner {
        _rebalance(0);
    }

    function _rebalance(uint256 _arbitrageAmount) private returns (uint256 balance, uint256 volTokenPositionBalance) {
        // Note: reverts if pool is skewed, as intended
        uint256 intrinsicDEXVolTokenBalance;
        uint256 usdcPlatformLiquidity;
        uint256 dexUSDCAmount;
        (balance, usdcPlatformLiquidity, intrinsicDEXVolTokenBalance, volTokenPositionBalance, dexUSDCAmount) = totalBalanceWithArbitrage(_arbitrageAmount);

        uint256 adjustedPositionUnits = platform.totalPositionUnitsAmount() * (MAX_PERCENTAGE + extraLiqidityPercentage) / MAX_PERCENTAGE;
        uint256 totalLeveragedTokensAmount = platform.totalLeveragedTokensAmount();

        // No need to rebalance if no position units for vault (i.e. dex not initialized yet)
        if (dexUSDCAmount > 0) {
            if (totalLeveragedTokensAmount > adjustedPositionUnits + minDepositAmount) {
                uint256 extraLiquidityAmount = totalLeveragedTokensAmount - adjustedPositionUnits;

                (, uint256 withdrawnAmount) = platform.withdraw(extraLiquidityAmount, type(uint256).max);

                deposit(withdrawnAmount, volTokenPositionBalance);
            } else if (totalLeveragedTokensAmount + minDepositAmount < adjustedPositionUnits) {
                uint256 liquidityMissing = adjustedPositionUnits - totalLeveragedTokensAmount;

                if (intrinsicDEXVolTokenBalance + dexUSDCAmount > liquidityMissing && 
                    (intrinsicDEXVolTokenBalance + dexUSDCAmount - liquidityMissing) * MAX_PERCENTAGE / balance >= minDexPercentageAllowed) {
                    uint256 poolLPTokensToRemove = liquidityMissing * IERC20Upgradeable(address(getPair())).totalSupply() / (intrinsicDEXVolTokenBalance + dexUSDCAmount);

                    (uint256 removedVolTokensAmount, uint256 dexRemovedUSDC) = router.removeLiquidity(address(volToken), address(token), poolLPTokensToRemove, 0, 0, address(this), block.timestamp);
                    uint256 totalUSDC = burnVolTokens(removedVolTokensAmount) + dexRemovedUSDC;
                    
                    platform.deposit(totalUSDC, 0);
                }
            }

            (balance,, intrinsicDEXVolTokenBalance, volTokenPositionBalance, dexUSDCAmount,) = totalBalance();
        }
    }

    function vaultPositionUnits() external view override returns (uint256) {
        (uint256 dexVolTokensAmount, ) = getReserves();
        IERC20Upgradeable poolPair = IERC20Upgradeable(address(getPair()));
        if (IERC20Upgradeable(address(volToken)).totalSupply() == 0 || poolPair.totalSupply() == 0) {
            return 0;
        }

        uint256 dexVaultVolTokensAmount = (dexVolTokensAmount * poolPair.balanceOf(address(this))) / poolPair.totalSupply();

        (uint256 totalPositionUnits, , , , ) = platform.positions(address(volToken));
        return totalPositionUnits * dexVaultVolTokensAmount / IERC20Upgradeable(address(volToken)).totalSupply();
    }

    function setRewardRouter(IRewardRouter _rewardRouter) external override onlyOwner {
        rewardRouter = _rewardRouter;
    }

    function setFulfiller(address _newFulfiller) external override onlyOwner {
        fulfiller = _newFulfiller;
    }

    function setMinAmounts(uint256 _newMinDepositAmount, uint256 _newMinWithdrawAmount) external override onlyOwner {
        minDepositAmount = _newMinDepositAmount;
        minWithdrawAmount = _newMinWithdrawAmount;
    }

    function setDepositHoldings(uint16 _newDepositHoldingsPercentage) external override onlyOwner {
        depositHoldingsPercentage = _newDepositHoldingsPercentage;
    }

    function setMinPoolSkew(uint16 _newMinPoolSkewPercentage) external override onlyOwner {
        minPoolSkewPercentage = _newMinPoolSkewPercentage;
    }

    function setLiquidityPercentages(uint16 _newExtraLiquidityPercentage, uint16 _minDexPercentageAllowed) external override onlyOwner {
        extraLiqidityPercentage = _newExtraLiquidityPercentage;
        minDexPercentageAllowed = _minDexPercentageAllowed;
    }

    function setRequestDelay(uint256 _newRequestDelay) external override onlyOwner {
        requestDelay = _newRequestDelay;
    }

    function setDepositCap(uint256 _newDepositCap) external override onlyOwner {
        depositCap = _newDepositCap;
    }

    function setPeriods(uint256 _newLockupPeriod, uint256 _newLiquidationPeriod) external override onlyOwner {
        lockupPeriod = _newLockupPeriod;
        liquidationPeriod = _newLiquidationPeriod;
    }

    function totalBalance() public view override returns (uint256 balance, uint256 usdcPlatformLiquidity, uint256 intrinsicDEXVolTokenBalance, uint256 volTokenPositionBalance, uint256 dexUSDCAmount, uint256 dexVolTokensAmount) {
        (intrinsicDEXVolTokenBalance, volTokenPositionBalance, dexUSDCAmount, dexVolTokensAmount,) = calculatePoolValue();
        (balance, usdcPlatformLiquidity) = _totalBalance(intrinsicDEXVolTokenBalance, dexUSDCAmount);
    }

    function totalBalanceWithArbitrage(uint256 _usdcArbitrageAmount) private returns (uint256 balance, uint256 usdcPlatformLiquidity, uint256 intrinsicDEXVolTokenBalance, uint256 volTokenPositionBalance, uint256 dexUSDCAmount) {
        (intrinsicDEXVolTokenBalance, volTokenPositionBalance, dexUSDCAmount) = 
            calculatePoolValueWithArbitrage(_usdcArbitrageAmount);
        (balance, usdcPlatformLiquidity) = _totalBalance(intrinsicDEXVolTokenBalance, dexUSDCAmount);
    }

    function _totalBalance(uint256 _intrinsicDEXVolTokenBalance, uint256 _dexUSDCAmount) private view returns (uint256 balance, uint256 usdcPlatformLiquidity)
    {
        IERC20Upgradeable poolPair = IERC20Upgradeable(address(getPair()));
        uint256 poolLPTokens = poolPair.balanceOf(address(this));
        uint256 vaultIntrinsicDEXVolTokenBalance = 0;
        uint256 vaultDEXUSDCAmount = 0;

        if (poolLPTokens > 0 && poolPair.totalSupply() > 0) {
            vaultIntrinsicDEXVolTokenBalance = (_intrinsicDEXVolTokenBalance * poolLPTokens) / poolPair.totalSupply();
            vaultDEXUSDCAmount = (_dexUSDCAmount * poolLPTokens) / poolPair.totalSupply();
        }

        usdcPlatformLiquidity = getUSDCPlatformLiquidity();
        balance = totalHoldingsAmount + usdcPlatformLiquidity + vaultIntrinsicDEXVolTokenBalance + vaultDEXUSDCAmount;
    }

    function deposit(uint256 _tokenAmount, uint256 _volTokenPositionBalance) private returns (FulfillDepositLocals memory locals)
    {
        (uint256 dexVolTokensAmount, uint256 dexUSDCAmount) = getReserves();

        uint256 dexVolTokenPrice;
        uint256 intrinsicVolTokenPrice;
        bool dexHasLiquidity = true;

        if (dexVolTokensAmount == 0 || dexUSDCAmount == 0) {
            dexHasLiquidity = false;
        } else {
            intrinsicVolTokenPrice =
                (_volTokenPositionBalance * 10**ERC20Upgradeable(address(volToken)).decimals()) /
                IERC20Upgradeable(address(volToken)).totalSupply();
            dexVolTokenPrice = (dexUSDCAmount * 10**ERC20Upgradeable(address(volToken)).decimals()) / dexVolTokensAmount;
        }

        if (dexHasLiquidity) {
            (locals.mintVolTokenUSDCAmount, locals.platformLiquidityAmount, locals.holdingsAmount) = calculateDepositAmounts(
                _tokenAmount,
                dexVolTokenPrice,
                intrinsicVolTokenPrice
            );

            totalHoldingsAmount += locals.holdingsAmount;

            platform.deposit(locals.platformLiquidityAmount, 0);
            (locals.addedLiquidityUSDCAmount, locals.mintedVolTokenAmount) = addDEXLiquidity(locals.mintVolTokenUSDCAmount);
        } else {
            locals.platformLiquidityAmount = _tokenAmount;
            platform.deposit(locals.platformLiquidityAmount, 0);
        }
    }

    function calculatePoolValue() private view returns (uint256 intrinsicDEXVolTokenBalance, uint256 volTokenBalance, uint256 dexUSDCAmount, uint256 dexVolTokensAmount, bool isPoolSkewed) {
        (dexVolTokensAmount, dexUSDCAmount) = getReserves();

        bool isPositive = true;
        (uint256 currPositionUnits, , , , ) = platform.positions(address(volToken));
        if (currPositionUnits != 0) {
            (volTokenBalance, isPositive,,,,) = platform.calculatePositionBalance(address(volToken));
        }
        require(isPositive); // 'Negative balance'

        // No need to check skew if pool is still empty
        if (dexVolTokensAmount > 0 && dexUSDCAmount > 0) {
            // Multiply by vol token decimals to get intrinsic worth in USDC
            intrinsicDEXVolTokenBalance =
                (dexVolTokensAmount * volTokenBalance) /
                IERC20Upgradeable(address(volToken)).totalSupply();
            uint256 delta = intrinsicDEXVolTokenBalance > dexUSDCAmount ? intrinsicDEXVolTokenBalance - dexUSDCAmount : dexUSDCAmount - intrinsicDEXVolTokenBalance;

            if (delta > (intrinsicDEXVolTokenBalance * minPoolSkewPercentage) / MAX_PERCENTAGE) {
                isPoolSkewed = true;
            }
        }
    }

    function calculatePoolValueWithArbitrage(uint256 _usdcArbitrageAmount) private returns (uint256 intrinsicDEXVolTokenBalance, uint256 volTokenBalance, uint256 dexUSDCAmount) {
        bool isPoolSkewed;
        (intrinsicDEXVolTokenBalance, volTokenBalance, dexUSDCAmount,, isPoolSkewed) = calculatePoolValue();

        if (isPoolSkewed) {
            attemptArbitrage(_usdcArbitrageAmount + totalHoldingsAmount, intrinsicDEXVolTokenBalance, dexUSDCAmount);
            (intrinsicDEXVolTokenBalance, volTokenBalance, dexUSDCAmount,, isPoolSkewed) = calculatePoolValue();
            require(!isPoolSkewed, 'Too skewed');
        }
    }

    function attemptArbitrage(uint256 _usdcAmount, uint256 _intrinsicDEXVolTokenBalance, uint256 _dexUSDCAmount) private {
        uint256 usdcAmountNeeded = _dexUSDCAmount > _intrinsicDEXVolTokenBalance ? (_dexUSDCAmount - _intrinsicDEXVolTokenBalance) / 2 : 
            (_intrinsicDEXVolTokenBalance - _dexUSDCAmount) / 2; // A good estimation to close arbitrage gap

        uint256 withdrawnLiquidity = 0;
        if (_usdcAmount < usdcAmountNeeded) {
            uint256 leftAmount = usdcAmountNeeded - _usdcAmount;

            // Get rest of amount needed from platform liquidity (will revert if not enough collateral)
            // Revert is ok here, befcause in that case, there is no way to arbitrage and resolve the skew,
            // and no requests will fulfill anyway
            (, withdrawnLiquidity) = platform.withdrawLPTokens(
                (leftAmount * IERC20Upgradeable(address(platform)).totalSupply()) / platform.totalBalance(true)
            );

            usdcAmountNeeded = withdrawnLiquidity + _usdcAmount;
        }

        uint256 updatedUSDCAmount;
        if (_dexUSDCAmount > _intrinsicDEXVolTokenBalance) {
            // Price is higher than intrinsic value, mint at lower price, then buy on dex
            uint256 mintedVolTokenAmount = mintVolTokens(usdcAmountNeeded);

            address[] memory path = new address[](2);
            path[0] = address(volToken);
            path[1] = address(token);

            // Note: No need for slippage since we checked the price in this current block
            uint256[] memory amounts = router.swapExactTokensForTokens(mintedVolTokenAmount, 0, path, address(this), block.timestamp);

            updatedUSDCAmount = amounts[1];
        } else {
            // Price is lower than intrinsic value, buy on dex, then burn at higher price

            address[] memory path = new address[](2);
            path[0] = address(token);
            path[1] = address(volToken);

            // Note: No need for slippage since we checked the price in this current block
            uint256[] memory amounts = router.swapExactTokensForTokens(usdcAmountNeeded, 0, path, address(this), block.timestamp);

            updatedUSDCAmount = burnVolTokens(amounts[1]);
        }

        // Make sure we didn't lose by doing arbitrage (for example, mint/burn fees exceeds arbitrage gain)
        require(updatedUSDCAmount > usdcAmountNeeded); // 'Arbitrage failed'

        // Deposit arbitrage gains back to vault as platform liquidity as well
        platform.deposit(updatedUSDCAmount - usdcAmountNeeded + withdrawnLiquidity, 0);
    }

    function preFulfillRequest(uint256 _requestId, Request memory _request, uint8 _expectedType) private nonReentrant returns (uint168 amountToFulfill, address owner, bool wasLiquidated) {
        require(_request.owner != address(0)); // 'Invalid request id'
        require(msg.sender == fulfiller || msg.sender == _request.owner); // 'Not allowed'
        require(_request.requestType == _expectedType); // 'Wrong request type'
        require(block.timestamp >= _request.targetTimestamp, 'Too soon');

        if (isLiquidable(_requestId)) {
            _liquidateRequest(_requestId);
            wasLiquidated = true;
        } else {
            amountToFulfill = _request.tokenAmount;
            owner = _request.owner;
        }
    }

    function submitRequest(uint8 _type, uint168 _tokenAmount, bool _shouldStake) private nonReentrant returns (uint256 requestId) {
        require(_tokenAmount > 0); // 'Token amount must be positive'

        (uint256 balance,,,,,) = totalBalance();

        if (_type == DEPOSIT_REQUEST_TYPE) {
            require(balance + _tokenAmount + totalDepositRequestsAmount <= depositCap, 'Cap reached');
        }

        requestId = nextRequestId;
        nextRequestId = nextRequestId + 1; // Overflow allowed to keep id cycling

        uint32 targetTimestamp = uint32(block.timestamp + requestDelay);

        requests[requestId] = Request(_type, _tokenAmount, targetTimestamp, msg.sender, _shouldStake);

        if (_type == DEPOSIT_REQUEST_TYPE) {
            totalDepositRequestsAmount += _tokenAmount;
        }

        collectRelevantTokens(_type, _tokenAmount);

        emit SubmitRequest(requestId, _type, _tokenAmount, targetTimestamp, msg.sender, balance, totalSupply());
    }

    function calculateDepositAmounts(uint256 _totalAmount, uint256 _dexVolTokenPrice, uint256 _intrinsicVolTokenPrice) private view returns (uint256 mintVolTokenUSDCAmount, uint256 platformLiquidityAmount, uint256 holdingsAmount) {
        holdingsAmount = _totalAmount * depositHoldingsPercentage / MAX_PERCENTAGE;
        uint256 leftAmount = _totalAmount - holdingsAmount;

        (uint256 cviValue, , ) = platform.cviOracle().getCVILatestRoundData();

        uint256 maxCVIValue = platform.maxCVIValue();
        (uint256 currentBalance,,,,,) = platform.calculatePositionBalance(address(volToken));

        mintVolTokenUSDCAmount = (cviValue * _intrinsicVolTokenPrice * MAX_PERCENTAGE * leftAmount) /
            (_intrinsicVolTokenPrice * extraLiqidityPercentage * maxCVIValue +
                (cviValue * _dexVolTokenPrice + _intrinsicVolTokenPrice * maxCVIValue) * MAX_PERCENTAGE);

        // Note: must be not-first mint (otherwise dex is empty, and this function won't be called)
        uint256 expectedMintedVolTokensAmount = (mintVolTokenUSDCAmount *
            IERC20Upgradeable(address(volToken)).totalSupply()) / currentBalance;

        (uint256 dexVolTokensAmount, uint256 dexUSDCAmount) = getReserves();
        uint256 usdcDEXAmount = (expectedMintedVolTokensAmount * dexUSDCAmount) / dexVolTokensAmount;

        platformLiquidityAmount = leftAmount - mintVolTokenUSDCAmount - usdcDEXAmount;
    }

    function addDEXLiquidity(uint256 _mintVolTokensUSDCAmount) private returns (uint256 addedLiquidityUSDCAmount, uint256 mintedVolTokenAmount) {
        mintedVolTokenAmount = mintVolTokens(_mintVolTokensUSDCAmount);

        (uint256 dexVolTokenAmount, uint256 dexUSDCAmount) = getReserves();
        uint256 _usdcDEXAmount = (mintedVolTokenAmount * dexUSDCAmount) / dexVolTokenAmount;

        uint256 addedVolTokenAmount;

        (addedVolTokenAmount, addedLiquidityUSDCAmount, ) = router.addLiquidity(address(volToken), address(token), mintedVolTokenAmount, _usdcDEXAmount, 
            mintedVolTokenAmount, _usdcDEXAmount, address(this), block.timestamp);

        require(addedLiquidityUSDCAmount == _usdcDEXAmount);
        require(addedVolTokenAmount == mintedVolTokenAmount);

        (dexVolTokenAmount, dexUSDCAmount) = getReserves();
    }

    function withdrawPlatformLiqudity(uint256 _lpTokensAmount, bool _catchRevert) private returns (uint256 withdrawnLiquidity, bool transactionSuccess) {
        transactionSuccess = true;

        if (_catchRevert) {
            (bool success, bytes memory returnData) = 
                address(platform).call(abi.encodePacked(platform.withdrawLPTokens.selector, abi.encode(_lpTokensAmount)));
            
            if (success) {
                (, withdrawnLiquidity) = abi.decode(returnData, (uint256, uint256));
            } else {
                transactionSuccess = false;
            }
        } else {
            (, withdrawnLiquidity) = platform.withdrawLPTokens(_lpTokensAmount);
        }
    }

    function burnVolTokens(uint256 _tokensToBurn) private returns (uint256 burnedVolTokensUSDCAmount) {
        uint168 __tokensToBurn = uint168(_tokensToBurn);
        require(__tokensToBurn == _tokensToBurn); // Sanity, should very rarely fail
        burnedVolTokensUSDCAmount = volToken.burnTokens(__tokensToBurn);
    }

    function mintVolTokens(uint256 _usdcAmount) private returns (uint256 mintedVolTokenAmount) {
        uint168 __usdcAmount = uint168(_usdcAmount);
        require(__usdcAmount == _usdcAmount); // Sanity, should very rarely fail
        mintedVolTokenAmount = volToken.mintTokens(__usdcAmount);
    }

    function collectRelevantTokens(uint8 _requestType, uint256 _tokenAmount) private {
        if (_requestType == WITHDRAW_REQUEST_TYPE) {
            require(balanceOf(msg.sender) >= _tokenAmount, 'Not enough tokens');
            IERC20Upgradeable(address(this)).safeTransferFrom(msg.sender, address(this), _tokenAmount);
        } else {
            token.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        }
    }

    function isLiquidable(uint256 _requestId) private view returns (bool) {
        return (requests[_requestId].targetTimestamp + liquidationPeriod < block.timestamp);
    }

    function _liquidateRequest(uint256 _requestId) private {
        Request memory request = requests[_requestId];

        if (request.requestType == DEPOSIT_REQUEST_TYPE) {
            totalDepositRequestsAmount -= request.tokenAmount;
        }

        deleteRequest(_requestId);

        if (request.requestType == WITHDRAW_REQUEST_TYPE) {
            IERC20Upgradeable(address(this)).safeTransfer(request.owner, request.tokenAmount);
        } else {
            token.safeTransfer(request.owner, request.tokenAmount);
        }

        emit LiquidateRequest(_requestId, request.requestType, request.owner, msg.sender, request.tokenAmount);
    }

    function deleteRequest(uint256 _requestId) private {
        delete requests[_requestId];

        uint256 currMinRequestId = minRequestId;
        uint256 increments = 0;
        bool didIncrement = false;

        while (currMinRequestId < nextRequestId && increments < maxMinRequestIncrements && requests[currMinRequestId].owner == address(0)) {
            increments++;
            currMinRequestId++;
            didIncrement = true;
        }

        if (didIncrement) {
            minRequestId = currMinRequestId;
        }
    }

    function getPair() private view returns (IUniswapV2Pair pair) {
        return IUniswapV2Pair(IUniswapV2Factory(router.factory()).getPair(address(volToken), address(token)));
    }

    function getReserves() public view override returns (uint256 volTokenAmount, uint256 usdcAmount) {
        (uint256 amount1, uint256 amount2, ) = getPair().getReserves();

        if (address(volToken) < address(token)) {
            volTokenAmount = amount1;
            usdcAmount = amount2;
        } else {
            volTokenAmount = amount2;
            usdcAmount = amount1;
        }
    }

    function getUSDCPlatformLiquidity() private view returns (uint256 usdcPlatformLiquidity) {
        uint256 platformLPTokensAmount = IERC20Upgradeable(address(platform)).balanceOf(address(this));

        if (platformLPTokensAmount > 0) {
            usdcPlatformLiquidity = (platformLPTokensAmount * platform.totalBalance(true)) / IERC20Upgradeable(address(platform)).totalSupply();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import '@coti-cvi/contracts-staking/contracts/interfaces/IRewardRouter.sol';

import "./IThetaVaultInfo.sol";
import "./IVolatilityToken.sol";

interface IThetaVault is IThetaVaultInfo {

    event SubmitRequest(uint256 requestId, uint8 requestType, uint256 tokenAmount, uint32 targetTimestamp, address indexed account, uint256 totalUSDCBalance, uint256 totalSupply);
    event FulfillDeposit(uint256 requestId, address indexed account, uint256 totalUSDCAmount, uint256 platformLiquidityAmount, uint256 dexVolTokenUSDCAmount, uint256 dexVolTokenAmount, uint256 dexUSDCAmount, uint256 mintedThetaTokens);
    event FulfillWithdraw(uint256 requestId, address indexed account, uint256 totalUSDCAmount, uint256 platformLiquidityAmount, uint256 dexVolTokenAmount, uint256 dexUSDCVolTokenAmount, uint256 dexUSDCAmount, uint256 burnedThetaTokens);
    event LiquidateRequest(uint256 requestId, uint8 requestType, address indexed account, address indexed liquidator, uint256 tokenAmount);

    function submitDepositRequest(uint168 tokenAmount/* , bool shouldStake */) external returns (uint256 requestId);
    function submitWithdrawRequest(uint168 thetaTokenAmount) external returns (uint256 requestId);

    function fulfillDepositRequest(uint256 requestId) external returns (uint256 thetaTokensMinted);
    function fulfillWithdrawRequest(uint256 requestId) external returns (uint256 tokenWithdrawnAmount);

    function liquidateRequest(uint256 requestId) external;

    function rebalance() external;

    function setRewardRouter(IRewardRouter rewardRouter) external;
    function setFulfiller(address newFulfiller) external;
    function setMinPoolSkew(uint16 newMinPoolSkewPercentage) external;
    function setLiquidityPercentages(uint16 newExtraLiquidityPercentage, uint16 minDexPercentageAllowed) external;
    function setRequestDelay(uint256 newRequestDelay) external;
    function setDepositCap(uint256 newDepositCap) external;
    function setPeriods(uint256 newLockupPeriod, uint256 newLiquidationPeriod) external;
    function setMinAmounts(uint256 newMinDepositAmount, uint256 newMinWithdrawAmount) external;
    function setDepositHoldings(uint16 newDepositHoldingsPercentage) external;
    
    function volToken() external view returns (IVolatilityToken);

    function totalBalance() external view returns (uint256 balance, uint256 usdcPlatformLiquidity, uint256 intrinsicDEXVolTokenBalance, uint256 volTokenPositionBalance, uint256 dexUSDCAmount, uint256 dexVolTokensAmount);
    function getReserves() external view returns (uint256 volTokenAmount, uint256 usdcAmount);
    function requests(uint256 requestId) external view returns (uint8 requestType, uint168 tokenAmount, uint32 targetTimestamp, address owner, bool shouldStake);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IRequestManager {

	function nextRequestId() external view returns (uint256);
    function minRequestId() external view returns (uint256);
    function maxMinRequestIncrements() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

import './IRewardTracker.sol';
import './IVester.sol';

enum StakedTokenName {
  THETA_VAULT,
  ES_GOVI,
  GOVI,
  LENGTH
}

interface IRewardRouter {
  event StakeToken(address indexed account, address indexed tokenName, uint256 amount);
  event UnstakeToken(address indexed account, address indexed tokenName, uint256 amount);

  function stake(StakedTokenName _token, uint256 _amount) external;

  function stakeForAccount(
    StakedTokenName _token,
    address _account,
    uint256 _amount
  ) external;

  function batchStakeForAccount(
    StakedTokenName _tokenName,
    address[] memory _accounts,
    uint256[] memory _amounts
  ) external;

  function unstake(StakedTokenName _token, uint256 _amount) external;

  function claim(StakedTokenName _token) external;

  function compound(StakedTokenName _tokenName) external;

  function compoundForAccount(address _account, StakedTokenName _tokenName) external;

  function batchCompoundForAccounts(address[] memory _accounts, StakedTokenName _tokenName) external;

  function setRewardTrackers(StakedTokenName[] calldata _tokenNames, IRewardTracker[] calldata _rewardTrackers)
    external;

  function setVesters(StakedTokenName[] calldata _tokenNames, IVester[] calldata _vesters) external;

  function setTokens(StakedTokenName[] calldata _tokenNames, address[] calldata _tokens) external;

  function rewardTrackers(StakedTokenName _token) external view returns (IRewardTracker);

  function vesters(StakedTokenName _token) external view returns (IVester);

  function tokens(StakedTokenName _token) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IThetaVaultInfo {
    function totalVaultLeveragedAmount() external view returns (uint256);
    function vaultPositionUnits() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./IPlatform.sol";
import "./IRequestFeesCalculator.sol";
import "./ICVIOracle.sol";

interface IVolatilityToken {

    struct Request {
        uint8 requestType; // 1 => mint, 2 => burn
        uint168 tokenAmount;
        uint16 timeDelayRequestFeesPercent;
        uint16 maxRequestFeesPercent;
        address owner;
        uint32 requestTimestamp;
        uint32 targetTimestamp;
        bool useKeepers;
        uint16 maxBuyingPremiumFeePercentage;
    }

    event SubmitRequest(uint256 requestId, uint8 requestType, address indexed account, uint256 tokenAmount, uint256 submitFeesAmount, uint32 requestTimestamp, uint32 targetTimestamp, bool useKeepers, uint16 maxBuyingPremiumFeePercentage);
    event FulfillRequest(uint256 requestId, uint8 requestType, address indexed account, uint256 fulfillFeesAmount, bool isAborted, bool useKeepers, bool keepersCalled, address indexed fulfiller, uint32 fulfillTimestamp);
    event LiquidateRequest(uint256 requestId, uint8 requestType, address indexed account, address indexed liquidator, uint256 findersFeeAmount, bool useKeepers, uint32 liquidateTimestamp);
    event Mint(uint256 requestId, address indexed account, uint256 tokenAmount, uint256 positionedTokenAmount, uint256 mintedTokens, uint256 openPositionFee, uint256 buyingPremiumFee);
    event Burn(uint256 requestId, address indexed account, uint256 tokenAmountBeforeFees, uint256 tokenAmount, uint256 burnedTokens, uint256 closePositionFee, uint256 closingPremiumFee);

    function rebaseCVI() external;

    function submitMintRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);
    function submitKeepersMintRequest(uint168 tokenAmount, uint32 timeDelay, uint16 maxBuyingPremiumFeePercentage) external returns (uint256 requestId);
    function submitBurnRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);
    function submitKeepersBurnRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);

    function fulfillMintRequest(uint256 requestId, uint16 maxBuyingPremiumFeePercentage, bool keepersCalled) external returns (uint256 tokensMinted, bool success);
    function fulfillBurnRequest(uint256 requestId, bool keepersCalled) external returns (uint256 tokensBurned);

    function mintTokens(uint168 tokenAmount) external returns (uint256 mintedTokens);
    function burnTokens(uint168 burnAmount) external returns (uint256 tokenAmount);

    function liquidateRequest(uint256 requestId) external returns (uint256 findersFeeAmount);

    function setMinter(address minter) external;
    function setPlatform(IPlatform newPlatform) external;
    function setFeesCalculator(IFeesCalculator newFeesCalculator) external;
    function setFeesCollector(IFeesCollector newCollector) external;
    function setRequestFeesCalculator(IRequestFeesCalculator newRequestFeesCalculator) external;
    function setCVIOracle(ICVIOracle newCVIOracle) external;
    function setDeviationParameters(uint16 newDeviationPercentagePerSingleRebaseLag, uint16 newMinDeviationPercentage, uint16 newMaxDeviationPercentage) external;
    function setVerifyTotalRequestsAmount(bool verifyTotalRequestsAmount) external;
    function setMaxTotalRequestsAmount(uint256 maxTotalRequestsAmount) external;
    function setCappedRebase(bool newCappedRebase) external;

    function setMinRequestId(uint256 newMinRequestId) external;
    function setMaxMinRequestIncrements(uint256 newMaxMinRequestIncrements) external;

    function setFulfiller(address fulfiller) external;

    function setKeepersFeeVaultAddress(address newKeepersFeeVaultAddress) external;

    function setMinKeepersAmounts(uint256 newMinKeepersMintAmount, uint256 newMinKeepersBurnAmount) external;

    function platform() external view returns (IPlatform);
    function requestFeesCalculator() external view returns (IRequestFeesCalculator);
    function leverage() external view returns (uint8);
    function initialTokenToLPTokenRate() external view returns (uint256);

    function requests(uint256 requestId) external view returns (uint8 requestType, uint168 tokenAmount, uint16 timeDelayRequestFeesPercent, uint16 maxRequestFeesPercent,
        address owner, uint32 requestTimestamp, uint32 targetTimestamp, bool useKeepers, uint16 maxBuyingPremiumFeePercentage);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

interface IRewardTracker {
  event Claim(address indexed receiver, uint256 amount);

  function stake(address _depositToken, uint256 _amount) external;

  function stakeForAccount(
    address _fundingAccount,
    address _account,
    address _depositToken,
    uint256 _amount
  ) external;

  function unstake(address _depositToken, uint256 _amount) external;

  function unstakeForAccount(
    address _account,
    address _depositToken,
    uint256 _amount,
    address _receiver
  ) external;

  function claim(address _receiver) external returns (uint256);

  function claimForAccount(address _account, address _receiver) external returns (uint256);

  function updateRewards() external;

  function depositBalances(address _account, address _depositToken) external view returns (uint256);

  function stakedAmounts(address _account) external view returns (uint256);

  function averageStakedAmounts(address _account) external view returns (uint256);

  function cumulativeRewards(address _account) external view returns (uint256);

  function claimable(address _account) external view returns (uint256);

  function tokensPerInterval() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

import './IRewardTracker.sol';

interface IVester {
  event Claim(address indexed receiver, uint256 amount);
  event Deposit(address indexed account, uint256 amount);
  event Withdraw(address indexed account, uint256 claimedAmount, uint256 balance);
  event PairTransfer(address indexed from, address indexed to, uint256 value);

  function claimForAccount(address _account, address _receiver) external returns (uint256);

  function transferStakeValues(address _sender, address _receiver) external;

  function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;

  function setTransferredCumulativeRewards(address _account, uint256 _amount) external;

  function setCumulativeRewardDeductions(address _account, uint256 _amount) external;

  function setBonusRewards(address _account, uint256 _amount) external;

  function rewardTracker() external view returns (IRewardTracker);

  function claimable(address _account) external view returns (uint256);

  function cumulativeClaimAmounts(address _account) external view returns (uint256);

  function claimedAmounts(address _account) external view returns (uint256);

  function pairAmounts(address _account) external view returns (uint256);

  function getVestedAmount(address _account) external view returns (uint256);

  function transferredAverageStakedAmounts(address _account) external view returns (uint256);

  function transferredCumulativeRewards(address _account) external view returns (uint256);

  function cumulativeRewardDeductions(address _account) external view returns (uint256);

  function bonusRewards(address _account) external view returns (uint256);

  function getMaxVestableAmount(address _account) external view returns (uint256);

  function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./ICVIOracle.sol";
import "./IFeesCalculator.sol";
import "./IRewardsCollector.sol";
import "./IFeesCollector.sol";
import "./ILiquidation.sol";

interface IPlatform {

    struct Position {
        uint168 positionUnitsAmount;
        uint8 leverage;
        uint32 openCVIValue;
        uint32 creationTimestamp;
        uint32 originalCreationTimestamp;
    }

    event Deposit(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event Withdraw(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event OpenPosition(address indexed account, uint256 tokenAmount, uint8 leverage, uint256 feeAmount, uint256 positionUnitsAmount, uint256 cviValue);
    event ClosePosition(address indexed account, uint256 tokenAmount, uint256 feeAmount, uint256 positionUnitsAmount, uint8 leverage, uint256 cviValue);
    event LiquidatePosition(address indexed positionAddress, uint256 currentPositionBalance, bool isBalancePositive, uint256 positionUnitsAmount);

    function deposit(uint256 tokenAmount, uint256 minLPTokenAmount) external returns (uint256 lpTokenAmount);
    function withdraw(uint256 tokenAmount, uint256 maxLPTokenBurnAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);
    function withdrawLPTokens(uint256 lpTokenAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);

    function increaseSharedPool(uint256 tokenAmount) external;

    function openPositionWithoutFee(uint168 tokenAmount, uint32 maxCVI, uint8 leverage) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function openPosition(uint168 tokenAmount, uint32 maxCVI, uint16 maxBuyingPremiumFeePercentage, uint8 leverage) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function closePositionWithoutFee(uint168 positionUnitsAmount, uint32 minCVI) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);
    function closePosition(uint168 positionUnitsAmount, uint32 minCVI) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);

    function liquidatePositions(address[] calldata positionOwners) external returns (uint256 finderFeeAmount);

    function setAddressSpecificParameters(address holderAddress, bool shouldLockPosition, bool noPremiumFeeAllowed, bool increaseSharedPoolAllowed, bool isLiquidityProvider) external;

    function setRevertLockedTransfers(bool revertLockedTransfers) external;

    function setSubContracts(IFeesCollector newCollector, ICVIOracle newOracle, IRewardsCollector newRewards, ILiquidation newLiquidation, address _newStakingContractAddress) external;
    function setFeesCalculator(IFeesCalculator newCalculator) external;

    function setLatestOracleRoundId(uint80 newOracleRoundId) external;
    function setMaxTimeAllowedAfterLatestRound(uint32 newMaxTimeAllowedAfterLatestRound) external;

    function setLockupPeriods(uint256 newLPLockupPeriod, uint256 newBuyersLockupPeriod) external;

    function setEmergencyParameters(bool newEmergencyWithdrawAllowed, bool newCanPurgeSnapshots) external;

    function setMaxAllowedLeverage(uint8 newMaxAllowedLeverage) external;

    function calculatePositionBalance(address positionAddress) external view returns (uint256 currentPositionBalance, bool isPositive, uint168 positionUnitsAmount, uint8 leverage, uint256 fundingFees, uint256 marginDebt);
    function calculatePositionPendingFees(address positionAddress, uint168 positionUnitsAmount) external view returns (uint256 pendingFees);

    function totalBalance(bool _withAddendum) external view returns (uint256 balance);

    function calculateLatestTurbulenceIndicatorPercent() external view returns (uint16);

    function cviOracle() external view returns (ICVIOracle);
    function feesCalculator() external view returns (IFeesCalculator);

    function PRECISION_DECIMALS() external view returns (uint256);

    function totalPositionUnitsAmount() external view returns (uint256);
    function totalLeveragedTokensAmount() external view returns (uint256);
    function totalFundingFeesAmount() external view returns (uint256);
    function latestFundingFees() external view returns (uint256);

    function positions(address positionAddress) external view returns (uint168 positionUnitsAmount, uint8 leverage, uint32 openCVIValue, uint32 creationTimestamp, uint32 originalCreationTimestamp);
    function buyersLockupPeriod() external view returns (uint256);
    function maxCVIValue() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./IVolatilityToken.sol";

interface IRequestFeesCalculator {
    function calculateTimePenaltyFee(IVolatilityToken.Request calldata request) external view returns (uint16 feePercentage);
    function calculateTimeDelayFee(uint256 timeDelay) external view returns (uint16 feePercentage);
    function calculateFindersFee(uint256 tokensLeftAmount) external view returns (uint256 findersFeeAmount);
    function calculateKeepersFee(uint256 tokensAmount) external view returns (uint256 keepersFeeAmount);

    function isLiquidable(IVolatilityToken.Request calldata request) external view returns (bool liquidable);

    function minWaitTime() external view returns (uint32);

    function setTimeWindow(uint32 minTimeWindow, uint32 maxTimeWindow) external;
    function setTimeDelayFeesParameters(uint16 minTimeDelayFeePercent, uint16 maxTimeDelayFeePercent) external;
    function setMinWaitTime(uint32 newMinWaitTime) external;
    function setTimePenaltyFeeParameters(uint16 beforeTargetTimeMaxPenaltyFeePercent, uint32 afterTargetMidTime, uint16 afterTargetMidTimePenaltyFeePercent, uint32 afterTargetMaxTime, uint16 afterTargetMaxTimePenaltyFeePercent) external;
    function setFindersFee(uint16 findersFeePercent) external;
    function setKeepersFeePercent(uint16 keepersFeePercent) external;
    function setKeepersFeeMax(uint256 keepersFeeMax) external;

    function getMaxFees() external view returns (uint16 maxFeesPercent);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ICVIOracle {
    function getCVIRoundData(uint80 roundId) external view returns (uint32 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint32 cviValue, uint80 cviRoundId, uint256 cviTimestamp);

    function setDeviationCheck(bool newDeviationCheck) external;
    function setMaxDeviation(uint16 newMaxDeviation) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./ICVIOracle.sol";
import "./IThetaVaultInfo.sol";

interface IFeesCalculator {

    struct CVIValue {
        uint256 period;
        uint32 cviValue;
    }

    struct SnapshotUpdate {
        uint256 latestSnapshot;
        uint256 singleUnitFundingFee;
        uint256 totalTime;
        uint256 totalRounds;
        uint256 cviValueTimestamp;
        uint80 newLatestRoundId;
        uint32 cviValue;
        bool updatedSnapshot;
        bool updatedLatestRoundId;
        bool updatedLatestTimestamp;
        bool updatedTurbulenceData;
    }

    function updateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint32 lastCVIValue, uint32 currCVIValue) external;

    function setOracle(ICVIOracle cviOracle) external;
    function setThetaVault(IThetaVaultInfo thetaVault) external;

    function setStateUpdator(address newUpdator) external;

    function setDepositFee(uint16 newDepositFeePercentage) external;
    function setWithdrawFee(uint16 newWithdrawFeePercentage) external;
    function setOpenPositionFee(uint16 newOpenPositionFeePercentage) external;
    function setOpenPositionLPFee(uint16 newOpenPositionLPFeePercent) external;
    function setClosePositionLPFee(uint16 newClosePositionLPFeePercent) external;
    function setClosePositionFee(uint16 newClosePositionFeePercentage) external;
    function setClosePositionMaxFee(uint16 newClosePositionMaxFeePercentage) external;
    function setClosePositionFeeDecay(uint256 newClosePositionFeeDecayPeriod) external;
    
    function setOracleHeartbeatPeriod(uint256 newOracleHeartbeatPeriod) external;
    function setBuyingPremiumFeeMax(uint16 newBuyingPremiumFeeMaxPercentage) external;
    function setBuyingPremiumThreshold(uint16 newBuyingPremiumThreshold) external;
    function setClosingPremiumFeeMax(uint16 newClosingPremiumFeeMaxPercentage) external;
    function setCollateralToBuyingPremiumMapping(uint16[] calldata newCollateralToBuyingPremiumMapping) external;
    function setFundingFeeConstantRate(uint16 newfundingFeeConstantRate) external;
    function setCollateralToExtraFundingFeeMapping(uint32[] calldata newCollateralToExtraFundingFeeMapping) external;
    function setTurbulenceStep(uint16 newTurbulenceStepPercentage) external;
    function setMaxTurbulenceFeePercentToTrim(uint16 newMaxTurbulenceFeePercentToTrim) external;
    function setTurbulenceDeviationThresholdPercent(uint16 newTurbulenceDeviationThresholdPercent) external;
    function setTurbulenceDeviationPercent(uint16 newTurbulenceDeviationPercentage) external;

    function calculateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint32 _lastCVIValue, uint32 _currCVIValue) external view returns (uint16);

    function calculateBuyingPremiumFee(uint168 tokenAmount, uint8 leverage, uint256 lastTotalLeveragedTokens, uint256 lastTotalPositionUnits, uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);
    function calculateBuyingPremiumFeeWithAddendum(uint168 tokenAmount, uint8 leverage, uint256 lastTotalLeveragedTokens, uint256 lastTotalPositionUnits, uint256 totalLeveragedTokens, uint256 totalPositionUnits, uint16 _turbulenceIndicatorPercent) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);

    function calculateClosingPremiumFee() external view returns (uint16 combinedPremiumFeePercentage);

    function calculateSingleUnitFundingFee(CVIValue[] memory cviValues, uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint256 fundingFee);
    function calculateSingleUnitPeriodFundingFee(CVIValue memory cviValue, uint256 collateralRatio) external view returns (uint256 fundingFee, uint256 fundingFeeRatePercents);
    function updateSnapshots(uint256 latestTimestamp, uint256 blockTimestampSnapshot, uint256 latestTimestampSnapshot, uint80 latestOracleRoundId, uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (SnapshotUpdate memory snapshotUpdate);

    function calculateClosePositionFeePercent(uint256 creationTimestamp, bool isNoLockPositionAddress) external view returns (uint16);
    function calculateWithdrawFeePercent(uint256 lastDepositTimestamp) external view returns (uint16);

    function calculateCollateralRatio(uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint256 collateralRatio);

    function depositFeePercent() external view returns (uint16);
    function withdrawFeePercent() external view returns (uint16);
    function openPositionFeePercent() external view returns (uint16);
    function closePositionFeePercent() external view returns (uint16);
    function openPositionLPFeePercent() external view returns (uint16);
    function closePositionLPFeePercent() external view returns (uint16);

    function openPositionFees() external view returns (uint16 openPositionFeePercentResult, uint16 buyingPremiumFeeMaxPercentResult);

    function turbulenceIndicatorPercent() external view returns (uint16);
    function oracleLeverage() external view returns (uint8);

    function getCollateralToBuyingPremiumMapping() external view returns(uint16[] memory);
    function getCollateralToExtraFundingFeeMapping() external view returns(uint32[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IRewardsCollector {
	function reward(address account, uint256 positionUnits, uint8 leverage) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeesCollector {
    function sendProfit(uint256 amount, IERC20 token) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ILiquidation {	
	function setMinLiquidationThresholdPercents(uint16[8] calldata newMinThresholdPercents) external;
	function setMinLiquidationRewardPercent(uint16 newMinRewardPercent) external;
	function setMaxLiquidationRewardPercents(uint16[8] calldata newMaxRewardPercents) external;
	function isLiquidationCandidate(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint32 openCVIValue, uint8 leverage) external view returns (bool);
	function getLiquidationReward(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint32 openCVIValue, uint8 leverage) external view returns (uint256 finderFeeAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}