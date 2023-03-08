// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/core/IVault.sol";
import "../interfaces/gmx/IVaultPriceFeedGMX.sol";
import "../interfaces/tokens/wlp/IPancakeFactory.sol";
import "../interfaces/tokens/wlp/IYieldTracker.sol";
import "../interfaces/tokens/wlp/IYieldToken.sol";
import "../interfaces/tokens/wlp/IVester.sol";

contract Reader {
    using SafeMath for uint256;

    uint256 private constant BASIS_POINTS_DIVISOR = 1e4;
    uint256 private constant POSITION_PROPS_LENGTH = 9;
    uint256 private constant PRICE_PRECISION = 1e30;
    uint256 private constant USDW_DECIMALS = 18;

    /**
     * @notice returns the maximum amount of tokenIn that can be sold in the WLP
     * @param _vault address of the vault
     * @param _tokenIn the address of the token to be sold
     * @param _tokenOut the address of the token being bought
     * @return 
     */
    function getMaxAmountIn(
        IVault _vault,
        address _tokenIn, 
        address _tokenOut) public view returns (uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 priceOut = _vault.getMaxPrice(_tokenOut);
        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = _vault.tokenDecimals(_tokenOut);
        uint256 amountIn;

        {
            uint256 poolAmount = _vault.poolAmounts(_tokenOut);
            uint256 bufferAmount = _vault.bufferAmounts(_tokenOut);
            if (bufferAmount >= poolAmount) {
                return 0;
            }
            uint256 availableAmount = poolAmount.sub(bufferAmount);
            amountIn = availableAmount.mul(priceOut).div(priceIn).mul(10 ** tokenInDecimals).div(10 ** tokenOutDecimals);
        }

        uint256 maxUsdwAmount = _vault.maxUsdwAmounts(_tokenIn);

        if (maxUsdwAmount != 0) {
            if (maxUsdwAmount < _vault.usdwAmounts(_tokenIn)) {
                return 0;
            }

            uint256 maxAmountIn = maxUsdwAmount - _vault.usdwAmounts(_tokenIn);
            maxAmountIn = (maxAmountIn * (10 ** tokenInDecimals)) / (10 ** USDW_DECIMALS);
            maxAmountIn = maxAmountIn.mul(PRICE_PRECISION).div(priceIn);

            if (amountIn > maxAmountIn) {
                return maxAmountIn;
            }
        }
        return amountIn;
    }

    /**
     * 
     * @param _vault the address of the vault
     * @param _tokenIn the address of the token being sold
     * @param _tokenOut the address of the token being bought
     * @param _amountIn the amount of tokenIn to be sold
     * @return amountOutAfterFees the amount of tokenOut after the fee is deducted from it
     * @return feeAmount amount of swap fees that will be charged by the vault 
     * @dev the swap fee is always charged in the outgoing token!
     */
    function getAmountOut(
        IVault _vault, 
        address _tokenIn, 
        address _tokenOut, 
        uint256 _amountIn) public view returns (uint256, uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);

        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = _vault.tokenDecimals(_tokenOut);

        uint256 feeBasisPoints;
        {
            uint256 usdwAmount = _amountIn.mul(priceIn).div(PRICE_PRECISION);
            usdwAmount = usdwAmount.mul(10 ** USDW_DECIMALS).div(10 ** tokenInDecimals);

            bool isStableSwap = _vault.stableTokens(_tokenIn) && _vault.stableTokens(_tokenOut);
            uint256 baseBps = isStableSwap ? _vault.stableSwapFeeBasisPoints() : _vault.swapFeeBasisPoints();
            uint256 taxBps = isStableSwap ? _vault.stableTaxBasisPoints() : _vault.taxBasisPoints();
            uint256 feesBasisPoints0 = _vault.getFeeBasisPoints(_tokenIn, usdwAmount, baseBps, taxBps, true);
            uint256 feesBasisPoints1 = _vault.getFeeBasisPoints(_tokenOut, usdwAmount, baseBps, taxBps, false);
            // use the higher of the two fee basis points
            feeBasisPoints = feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;
        }

        uint256 priceOut = _vault.getMaxPrice(_tokenOut);
        uint256 amountOut = _amountIn.mul(priceIn).div(priceOut);
        amountOut = amountOut.mul(10 ** tokenOutDecimals).div(10 ** tokenInDecimals);

        uint256 amountOutAfterFees = amountOut.mul(BASIS_POINTS_DIVISOR.sub(feeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 feeAmount = amountOut.sub(amountOutAfterFees);

        return (amountOutAfterFees, feeAmount);
    }

    /**
     * @notice returns the amount of basis points the vault will charge for a swap
     * @param _vault the address of the vault
     * @param _tokenIn the address of the token (being sold)
     * @param _tokenOut the address of the token (being bought)
     * @param _amountIn the amount of tokenIn (being sold)
     * @return feeBasisPoints the actual basisPoint fee that will be charged for this swap
     * @return feesBasisPoints0 the swap fee component of tokenIn
     * @return feesBasisPoints1 the swap fee component of tokenOut
     * @dev take note that feesBasisPoints0 and feesBasisPoints1 are only relevant for context
     */
    function getFeeBasisPoints(
        IVault _vault, 
        address _tokenIn, 
        address _tokenOut, 
        uint256 _amountIn) public view returns (uint256, uint256, uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);

        uint256 usdwAmount = _amountIn.mul(priceIn).div(PRICE_PRECISION);
        usdwAmount = usdwAmount.mul(10 ** USDW_DECIMALS).div(10 ** tokenInDecimals);

        bool isStableSwap = _vault.stableTokens(_tokenIn) && _vault.stableTokens(_tokenOut);
        uint256 baseBps = isStableSwap ? _vault.stableSwapFeeBasisPoints() : _vault.swapFeeBasisPoints();
        uint256 taxBps = isStableSwap ? _vault.stableTaxBasisPoints() : _vault.taxBasisPoints();
        uint256 feesBasisPoints0 = _vault.getFeeBasisPoints(_tokenIn, usdwAmount, baseBps, taxBps, true);
        uint256 feesBasisPoints1 = _vault.getFeeBasisPoints(_tokenOut, usdwAmount, baseBps, taxBps, false);
        // use the higher of the two fee basis points
        uint256 feeBasisPoints = feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;

        return (feeBasisPoints, feesBasisPoints0, feesBasisPoints1);
    }

    /**
     * @notice returns an array with the accumulated swap fees per vault asset
     * @param _vault address of the vault
     * @param _tokens array with the tokens you want to know the accumulated fee reserves from
     */
    function getFees(address _vault, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            amounts[i] = IVault(_vault).feeReserves(_tokens[i]);
        }
        return amounts;
    }

    /**
     * @notice returns an array with the accumulated wager fees per vault asset
     * @param _vault address of the vault
     * @param _tokens array with the tokens you want to know the accumulated fee reserves from
     */
    function getWagerFees(address _vault, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            amounts[i] = IVault(_vault).wagerFeeReserves(_tokens[i]);
        }
        return amounts;
    }

    /**
     * @notice xxx
     * @param _factory xxx
     * @param _tokens xxx
     */
    function getPairInfo(
        address _factory, 
        address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 inputLength = 2;
        uint256 propsLength = 2;
        uint256[] memory amounts = new uint256[](_tokens.length / inputLength * propsLength);
        for (uint256 i = 0; i < _tokens.length / inputLength; i++) {
            address token0 = _tokens[i * inputLength];
            address token1 = _tokens[i * inputLength + 1];
            address pair = IPancakeFactory(_factory).getPair(token0, token1);

            amounts[i * propsLength] = IERC20(token0).balanceOf(pair);
            amounts[i * propsLength + 1] = IERC20(token1).balanceOf(pair);
        }
        return amounts;
    }

    function getTokenSupply(
        IERC20 _token, 
        address[] memory _excludedAccounts) public view returns (uint256) {
        uint256 supply = _token.totalSupply();
        for (uint256 i = 0; i < _excludedAccounts.length; i++) {
            address account = _excludedAccounts[i];
            uint256 balance = _token.balanceOf(account);
            supply = supply.sub(balance);
        }
        return supply;
    }

    function getTotalBalance(
        IERC20 _token, 
        address[] memory _accounts) public view returns (uint256) {
        uint256 totalBalance = 0;
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 balance = _token.balanceOf(account);
            totalBalance = totalBalance.add(balance);
        }
        return totalBalance;
    }

    function getTokenBalances(
        address _account, 
        address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                balances[i] = _account.balance;
                continue;
            }
            balances[i] = IERC20(token).balanceOf(_account);
        }
        return balances;
    }

    function getTokenBalancesWithSupplies(
        address _account, 
        address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory balances = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                balances[i * propsLength] = _account.balance;
                balances[i * propsLength + 1] = 0;
                continue;
            }
            balances[i * propsLength] = IERC20(token).balanceOf(_account);
            balances[i * propsLength + 1] = IERC20(token).totalSupply();
        }
        return balances;
    }

    function getPrices(
        IVaultPriceFeedGMX _priceFeed, 
        address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 6;

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            amounts[i * propsLength] = _priceFeed.getPrice(token, true, true, false);
            amounts[i * propsLength + 1] = _priceFeed.getPrice(token, false, true, false);
            amounts[i * propsLength + 2] = _priceFeed.getPrimaryPrice(token, true);
            amounts[i * propsLength + 3] = _priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 4] = _priceFeed.isAdjustmentAdditive(token) ? 1 : 0;
            amounts[i * propsLength + 5] = _priceFeed.adjustmentBasisPoints(token);
        }
        return amounts;
    }

    function getVaultTokenInfo(
        address _vault, 
        address _weth, 
        uint256 _usdwAmount, 
        address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 8;

        IVault vault = IVault(_vault);
        IVaultPriceFeedGMX priceFeed = IVaultPriceFeedGMX(vault.priceFeed());

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }
            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.usdwAmounts(token);
            amounts[i * propsLength + 2] = vault.getRedemptionAmount(token, _usdwAmount);
            amounts[i * propsLength + 3] = vault.tokenWeights(token);
            amounts[i * propsLength + 4] = vault.getMinPrice(token);
            amounts[i * propsLength + 5] = vault.getMaxPrice(token);
            amounts[i * propsLength + 6] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 7] = priceFeed.getPrimaryPrice(token, true);
        }
        return amounts;
    }

    function getFullVaultTokenInfo(
        address _vault, 
        address _weth, 
        uint256 _usdwAmount, 
        address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 10;

        IVault vault = IVault(_vault);
        IVaultPriceFeedGMX priceFeed = IVaultPriceFeedGMX(vault.priceFeed());

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }
            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.usdwAmounts(token);
            amounts[i * propsLength + 2] = vault.getRedemptionAmount(token, _usdwAmount);
            amounts[i * propsLength + 3] = vault.tokenWeights(token);
            amounts[i * propsLength + 4] = vault.bufferAmounts(token);
            amounts[i * propsLength + 5] = vault.maxUsdwAmounts(token);
            amounts[i * propsLength + 6] = vault.getMinPrice(token);
            amounts[i * propsLength + 7] = vault.getMaxPrice(token);
            amounts[i * propsLength + 8] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 9] = priceFeed.getPrimaryPrice(token, true);
        }
        return amounts;
    }

    // /**
    //  * @dev take note that this function expects a token amount for _amountIn, not USD value equivalent
    //  * @param _tokenInAddress the address of the token that is going to be traded in
    //  * @param _tokenOutAddress the address of the token that is goign to be traded out
    //  * @param _amountIn the amount of tokenIn that will be swapped (will enter the pool)
    //  * @return swapFeeOut_ ai
    //  */
    // function queryAmountOfSwapFees(
    //     address _tokenInAddress,
    //     address _tokenOutAddress,
    //     uint256 _amountIn
    // ) public view returns(uint256 swapFeeOut_) {
    //     uint256 priceIn_ = getMinPrice(_tokenInAddress);
    //     uint256 priceOut_ = getMaxPrice(_tokenOutAddress);
    //     uint256 feeBasisPoints_ = _getFeeBasisPoints(_tokenInAddress, _tokenOutAddress, _amountIn);
    //     uint256 amountOut_ = (_amountIn * priceIn_) / priceOut_;
    //     amountOut_ = adjustForDecimals(amountOut_, _tokenInAddress, _tokenOutAddress);
    //     uint256 afterFeeAmount_ = (amountOut_ * (BASIS_POINTS_DIVISOR - feeBasisPoints_)) / BASIS_POINTS_DIVISOR;
    //     swapFeeOut_ = (amountOut_ - afterFeeAmount_);
    // }

    /**
    //  * 
    //  */
    // function returnTokenAmountsForPayout(
    //     address[2] memory _tokens,
    //     uint256 _escrowAmount,
    //     uint256 _totalAmount  
    // ) external view returns(uint256 amountOut_, uint256 swapFeeCharged_, uint256 wagerFeeCharged_) {
    //     uint256 afterFeeAmountWager_ = (_escrowAmount * (BASIS_POINTS_DIVISOR - wagerFee)) / BASIS_POINTS_DIVISOR;
    //     wagerFeeCharged_ = _escrowAmount - afterFeeAmountWager_;
    //     uint256 amountOutTokenOut_ = amountOfTokenForToken(
    //         _tokens[0],
    //         _tokens[1], 
    //         _totalAmount - wagerFeeCharged_
    //     );
    //     uint256 priceIn_ = getMinPrice(_tokens[0]);
    //     uint256 usdwAmount_ = ((_totalAmount - wagerFeeCharged_) * priceIn_) / PRICE_PRECISION;
    //     usdwAmount_ = adjustForDecimals(usdwAmount_, _tokens[0], usdw);
    //     uint256 feeBasisPoints_ = vaultUtils.getSwapFeeBasisPoints(_tokens[0], _tokens[1], usdwAmount_);
    //     uint256 afterFeeAmountSwap_ = ((_totalAmount - wagerFeeCharged_) * (BASIS_POINTS_DIVISOR - feeBasisPoints_)) / BASIS_POINTS_DIVISOR;
    //     swapFeeCharged_ = (_totalAmount - wagerFeeCharged_) - afterFeeAmountSwap_;
    //     amountOut_ = amountOutTokenOut_ - swapFeeCharged_;
    //     return(amountOut_, swapFeeCharged_, wagerFeeCharged_);
    // }

    // /**
    //  * @notice function that returns a swap fee matrix, allowing to access what the best route is
    //  * @dev take note that _addressTokenOut assumes that 1e30 represents $1 USD (so don't plug 1e18 value since this value represents fractions of a cent and will break for example swapping to BTC)
    //  * @param _usdValueOfSwapAsset USD value of the asset that is considered to be traded into the WLP
    //  * @return swapFeePercentages_ matrix with tthe swap fees for each possible swap route
    //  */
    // function getSwapFeePercentageMatrix(
    //     uint256 _usdValueOfSwapAsset
    // ) external view returns(uint256[] memory) {

    //     uint256[] memory swapFeePercentages_ = new uint256[](allWhitelistedTokens.length * allWhitelistedTokens.length);
    //     uint256 count_;

    //     for (uint i=0; i < allWhitelistedTokens.length; i++) {
    //         address[] memory wlpAssets_ = allWhitelistedTokens;
    //         address tokenIn_ = wlpAssets_[i];
    //         uint256 tokenAmountIn_ = usdToTokenMin(tokenIn_, _usdValueOfSwapAsset);

    //         for (uint b=0; b < wlpAssets_.length; b++) {
    //             address tokenOut_ = wlpAssets_[b];
    //             uint256 swapFeePercentage_ = _getFeeBasisPoints(
    //                 tokenIn_,
    //                 tokenOut_,
    //                 tokenAmountIn_
    //             );
    //             swapFeePercentages_[count_] = swapFeePercentage_;
    //             count_ += 1;
    //         }
    //     }
    //     return swapFeePercentages_;
    // }

    // function getVaultTokenInfoV2(address _vault, address _weth, uint256 _usdwAmount, address[] memory _tokens) public view returns (uint256[] memory) {
    //     uint256 propsLength = 14;

    //     IVault vault = IVault(_vault);
    //     IVaultPriceFeedGMX priceFeed = IVaultPriceFeedGMX(vault.priceFeed());

    //     uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
    //     for (uint256 i = 0; i < _tokens.length; i++) {
    //         address token = _tokens[i];
    //         if (token == address(0)) {
    //             token = _weth;
    //         }

    //         uint256 maxGlobalShortSize = hasMaxGlobalShortSizes ? vault.maxGlobalShortSizes(token) : 0;
    //         amounts[i * propsLength] = vault.poolAmounts(token);
    //         amounts[i * propsLength + 1] = vault.reservedAmounts(token);
    //         amounts[i * propsLength + 2] = vault.usdwAmounts(token);
    //         amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _usdwAmount);
    //         amounts[i * propsLength + 4] = vault.tokenWeights(token);
    //         amounts[i * propsLength + 5] = vault.bufferAmounts(token);
    //         amounts[i * propsLength + 6] = vault.maxUsdwAmounts(token);
    //         amounts[i * propsLength + 7] = vault.globalShortSizes(token);
    //         amounts[i * propsLength + 8] = maxGlobalShortSize;
    //         amounts[i * propsLength + 9] = vault.getMinPrice(token);
    //         amounts[i * propsLength + 10] = vault.getMaxPrice(token);
    //         amounts[i * propsLength + 11] = vault.guaranteedUsd(token);
    //         amounts[i * propsLength + 12] = priceFeed.getPrimaryPrice(token, false);
    //         amounts[i * propsLength + 13] = priceFeed.getPrimaryPrice(token, true);
    //     }

    //     return amounts;
    // }

    function getTotalStaked(address[] memory _yieldTokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_yieldTokens.length);
        for (uint256 i = 0; i < _yieldTokens.length; i++) {
            IYieldToken yieldToken = IYieldToken(_yieldTokens[i]);
            amounts[i] = yieldToken.totalStaked();
        }
        return amounts;
    }

    function getStakingInfo(address _account, address[] memory _yieldTrackers) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory amounts = new uint256[](_yieldTrackers.length * propsLength);
        for (uint256 i = 0; i < _yieldTrackers.length; i++) {
            IYieldTracker yieldTracker = IYieldTracker(_yieldTrackers[i]);
            amounts[i * propsLength] = yieldTracker.claimable(_account);
            amounts[i * propsLength + 1] = yieldTracker.getTokensPerInterval();
        }
        return amounts;
    }

    function getVestingInfo(address _account, address[] memory _vesters) public view returns (uint256[] memory) {
        uint256 propsLength = 7;
        uint256[] memory amounts = new uint256[](_vesters.length * propsLength);
        for (uint256 i = 0; i < _vesters.length; i++) {
            IVester vester = IVester(_vesters[i]);
            amounts[i * propsLength] = vester.pairAmounts(_account);
            amounts[i * propsLength + 1] = vester.getVestedAmount(_account);
            amounts[i * propsLength + 2] = IERC20(_vesters[i]).balanceOf(_account);
            amounts[i * propsLength + 3] = vester.claimedAmounts(_account);
            amounts[i * propsLength + 4] = vester.claimable(_account);
            amounts[i * propsLength + 5] = vester.getMaxVestableAmount(_account);
            amounts[i * propsLength + 6] = vester.getCombinedAverageStakedAmount(_account);
        }
        return amounts;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtils.sol";

interface IVault {
    /*==================================================== EVENTS GMX ===========================================================*/
    event BuyUSDW(
        address account, 
        address token, 
        uint256 tokenAmount, 
        uint256 usdwAmount, 
        uint256 feeBasisPoints
    );
    event SellUSDW(
        address account, 
        address token, 
        uint256 usdwAmount, 
        uint256 tokenAmount, 
        uint256 feeBasisPoints
    );
    event Swap(
        address account, 
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn, 
        uint256 indexed amountOut, 
        uint256 indexed amountOutAfterFees, 
        uint256 indexed feeBasisPoints
    );
    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event DirectPoolDeposit(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseUsdwAmount(address token, uint256 amount);
    event DecreaseUsdwAmount(address token, uint256 amount);

    /*================================================== Operational Functions GMX =================================================*/
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;
    function router() external view returns (address);
    function usdw() external view returns (address);
    function whitelistedTokenCount() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdwAmount(address _token) external view returns (uint256);
    function inManagerMode() external view returns (bool);
    function isManager(address _account) external view returns (bool);
    function tokenBalances(address _token) external view returns (uint256);
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setUsdwAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        bool _hasDynamicFees
    ) external;
    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _maxUsdwAmount,
        bool _isStable
    ) external;
    function setPriceFeed(address _priceFeed) external;
    function withdrawSwapFees(address _token) external returns (uint256);
    function directPoolDeposit(address _token) external;
    function deposit(address _tokenIn, address _receiver) external returns (uint256);
    function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function tokenToUsdMin(address _tokenToPrice, uint256 _tokenAmount) external view returns (uint256);
    function priceFeed() external view returns (address);
    function getFeeBasisPoints(
        address _token, 
        uint256 _usdwDelta, 
        uint256 _feeBasisPoints, 
        uint256 _taxBasisPoints, 
        bool _increment
    ) external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function usdwAmounts(address _token) external view returns (uint256);
    function maxUsdwAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    /*==================== Events WINR  *====================*/

    event PlayerPayout(
        address recipient,
        uint256 amountPayoutTotal
    );

    event WagerFeesCollected(
        address tokenAddress,
        uint256 usdValueFee,
        uint256 feeInTokenCharged
    );

    event PayinWLP(
        address tokenInAddress,
        uint256 amountPayin,
        uint256 usdValueProfit
    );

    event RebalancingWithdraw(
        address tokenWithdrawn,
        uint256 amountWithdrawn
    );

    event RebalancingDeposit(
        address tokenDeposit,
        uint256 amountDeposit
    );

    /*==================== Operational Functions WINR *====================*/
    function setVaultManagerAddress(address _vaultManagerAddress) external;
    function vaultManagerAddress() external view returns (address);
    function wagerFee() external view returns (uint256);
    function setWagerFee(uint256 _wagerFee) external;
    function wagerFeeReserves(address _token) external view returns(uint256);
    function withdrawWagerFees(address _token) external returns (uint256);
    function setFeeLessForPayout(bool _setting) external;
    function getReserve() external view returns (uint256);
    function getDollarValue(address _token) external view returns (uint256);
    function getWlpValue() external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToToken(address _token, uint256 _usdAmount, uint256 _price) external view returns(uint256);

    function payout(
        address[2] memory _tokens,
        address _escrowAddress,
        uint256 _escrowAmount,
        address _recipient,
        uint256 _totalAmount
    ) external;

    function payin(
        address _inputToken,
        address _escrowAddress,
        uint256 _escrowAmount
    ) external;

    function rebalanceWithdraw(
        address _tokenToRebalanceWith,
        uint256 _amountToRebalanceWith
    ) external;

    function rebalanceDeposit(
        address _tokenInDeposited,
        uint256 _amountDeposited
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVaultUtils {
    function getBuyUsdwFeeBasisPoints(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getSellUsdwFeeBasisPoints(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdwAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdwDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVaultPriceFeedGMX {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);
    function getAmmPrice(address _token) external view returns (uint256);
    function getLatestPrimaryPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVester {
    function rewardTracker() external view returns (address);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function cumulativeClaimAmounts(address _account) external view returns (uint256);
    function claimedAmounts(address _account) external view returns (uint256);
    function pairAmounts(address _account) external view returns (uint256);
    function getVestedAmount(address _account) external view returns (uint256);
    function transferredAverageStakedAmounts(address _account) external view returns (uint256);
    function transferredCumulativeRewards(address _account) external view returns (uint256);
    function cumulativeRewardDeductions(address _account) external view returns (uint256);
    function bonusRewards(address _account) external view returns (uint256);
    function transferStakeValues(address _sender, address _receiver) external;
    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;
    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;
    function setBonusRewards(address _account, uint256 _amount) external;
    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IYieldToken {
    function totalStaked() external view returns (uint256);
    function stakedBalance(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IYieldTracker {
    function claim(address _account, address _receiver) external returns (uint256);
    function updateRewards(address _account) external;
    function getTokensPerInterval() external view returns (uint256);
    function claimable(address _account) external view returns (uint256);
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}