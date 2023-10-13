// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/core/IVault.sol";
import "../interfaces/core/IVaultUtils.sol";

contract VaultUtils is IVaultUtils {
    IVault public immutable vault;

    constructor(address _vault) {
        vault = IVault(_vault);
    }

    /*==================== View functions *====================*/

    /**
     * @notice returns the amount of basispooints the vault will charge for a GEMLP deposit (so minting of GEMLP by depositing a whitelisted asset in the vault)
     * @param _token address of the token to check
     * @param _usdwAmount usdw amount/value of the mutation
     * @return the fee basis point the vault will charge for the mutation
     */
    function getBuyUsdwFeeBasisPoints(
        address _token,
        uint256 _usdwAmount
    ) external view override returns (uint256) {
        uint256 dynamicFee_ = getFeeBasisPoints(
            _token,
            _usdwAmount,
            vault.mintBurnFeeBasisPoints(),
            vault.taxBasisPoints(),
            true
        );
        uint256 minimumFee_ = vault.minimumBurnMintFee();
        // if the dynamic fee is lower than the minimum fee
        if (dynamicFee_ < minimumFee_) {
            // the vault will charge the minimum configured mint/burn fee
            return minimumFee_;
        } else {
            return dynamicFee_;
        }
    }

    /**
     * @notice returns the amount of basispooints the vault will charge for a GEMLP withdraw (so burning of GEMLP for a certain whitelisted asset in the vault)
     * @param _token address of the token to check
     * @param _usdwAmount usdw amount/value of the mutation
     * @return the fee basis point the vault will charge for the mutation
     */
    function getSellUsdwFeeBasisPoints(
        address _token,
        uint256 _usdwAmount
    ) external view override returns (uint256) {
        uint256 dynamicFee_ = getFeeBasisPoints(
            _token,
            _usdwAmount,
            vault.mintBurnFeeBasisPoints(),
            vault.taxBasisPoints(),
            false
        );
        uint256 minimumFee_ = vault.minimumBurnMintFee();
        // if the dynamic fee is lower than the minimum fee
        if (dynamicFee_ < minimumFee_) {
            // the vault will charge the minimum configured mint/burn fee
            return minimumFee_;
        } else {
            return dynamicFee_;
        }
    }

    /**
     * @notice this function determines how much swap fee needs to be paid for a certain swap
     * @dev the size/extent of the swap fee depends on if the swap balances the GEMLP (cheaper) or unbalances the pool (expensive)
     * @param _tokenIn address of the token being sold by the swapper
     * @param _tokenOut address of the token being bought by the swapper
     * @param _usdwAmount the amount of of USDC/GEMLP the swap is 'worth'
     */
    function getSwapFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        uint256 _usdwAmount
    ) external view override returns (uint256 effectiveSwapFee_) {
        // check if the swap is a swap between 2 stablecoins
        bool isStableSwap_ = vault.stableTokens(_tokenIn) &&
            vault.stableTokens(_tokenOut);
        uint256 baseBps_ = isStableSwap_
            ? vault.stableSwapFeeBasisPoints()
            : vault.swapFeeBasisPoints();
        uint256 taxBps_ = isStableSwap_
            ? vault.stableTaxBasisPoints()
            : vault.taxBasisPoints();
        /**
         * How large a swap fee is depends on if the swap improves the GEMLP asset balance or not.
         * If the incoming asset is relatively scarce, this means a lower swap rate
         * If the outcoing asset is abundant, this means a lower swap rate
         * Both the in and outcoming assets need to improve the balance for the swap fee to be low.
         * If both the incoming as the outgoing asset are scarce, this will mean that the swap fee will be high.
         */
        // get the swap fee for the incoming asset/change
        uint256 feesBasisPoints0_ = getFeeBasisPoints(
            _tokenIn,
            _usdwAmount,
            baseBps_,
            taxBps_,
            true
        );
        // get the swap fee for the outgoing change/asset
        uint256 feesBasisPoints1_ = getFeeBasisPoints(
            _tokenOut,
            _usdwAmount,
            baseBps_,
            taxBps_,
            false
        );
        // use the highest of the two fees as effective rate
        effectiveSwapFee_ = feesBasisPoints0_ > feesBasisPoints1_
            ? feesBasisPoints0_
            : feesBasisPoints1_;
    }

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    /**
     * @param _token the asset that is entering or leaving the GEMLP
     * @param _usdwDelta the amount of GEMLP this incoming/outgoing asset is 'worth'
     * @param _feeBasisPoints the amount of swap fee (based on the type of swap)
     * @param _taxBasisPoints the amount of tax (based on the type of swap)
     * @param _increment if the asset is coming in 'incrementing the balance'
     * @return the swapFee in basis points (including the tax)
     */
    function getFeeBasisPoints(
        address _token,
        uint256 _usdwDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) public view override returns (uint256) {
        if (!vault.hasDynamicFees()) {
            return _feeBasisPoints;
        }
        // fetch how much debt of the _token there is before the change in the GEMLP
        uint256 initialAmount_ = vault.usdwAmounts(_token);
        uint256 nextAmount_;
        // if the _token is leaving the pool (so it is NOT incrementing the pool debt/balance)
        if (!_increment) {
            // if the token is leaving the usdw debt will be reduced
            unchecked {
                nextAmount_ = _usdwDelta > initialAmount_
                    ? 0
                    : (initialAmount_ - _usdwDelta);
            }
            // IMO nextAmount cannot be 0 realistically, it is merely there to prevent underflow
        } else {
            // calculate how much the debt will be
            nextAmount_ = (initialAmount_ + _usdwDelta);
        }
        // fetch how much usdw debt the token should be in optimally balanced state
        uint256 targetAmount_ = vault.getTargetUsdwAmount(_token);
        // if the token weight is 0, then the fee is the standard fee
        if (targetAmount_ == 0) {
            return _feeBasisPoints;
        }
        /**
         * calculate how much the pool balance was before the swap/depoist/mutation is processed
         */
        uint256 initialDiff_;
        unchecked {
            initialDiff_ = initialAmount_ > targetAmount_
                ? (initialAmount_ - targetAmount_)
                : (targetAmount_ - initialAmount_);
        }
        /**
         * calculate the balance of the pool after the swap/deposit/mutation is processed
         */
        uint256 nextDiff_;
        unchecked {
            nextDiff_ = nextAmount_ > targetAmount_
                ? (nextAmount_ - targetAmount_)
                : (targetAmount_ - nextAmount_);
        }
        /**
         * with the initial and next balance, we can determine if the swap/deposit/mutation is improving the balance of the pool
         */
        // action improves relative asset balance
        if (nextDiff_ < initialDiff_) {
            // the _taxBasisPoints determines the extent of the discount of the fee, the higher the tax, the lower the fee in case of improvement of the pool
            // this effect also works in reverse, if the tax is low, the fee will be high in case of improvement of the pool
            uint256 rebateBps_ = (_taxBasisPoints * initialDiff_) /
                targetAmount_;
            // if the action improves the balance so that the rebate is so high, no swap fee is charged and no tax is charged
            // if the rebate is higher than the fee, the function returns 0
            return
                rebateBps_ > _feeBasisPoints
                    ? 0
                    : (_feeBasisPoints - rebateBps_);
        }
        /**
         * If we are here, it means that this leg of the swap isn't improving the balance of the pool.
         * Now we need to establish to what extent this leg unbalances the pool in order to determine the final fee.
         */
        uint256 averageDiff_ = (initialDiff_ + nextDiff_) / 2;
        if (averageDiff_ > targetAmount_) {
            averageDiff_ = targetAmount_;
        }
        uint256 taxBps_ = (_taxBasisPoints * averageDiff_) / targetAmount_;
        return (_feeBasisPoints + taxBps_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtils.sol";

interface IVault {
    /*==================== Events *====================*/
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
    event DirectPoolDeposit(address token, uint256 amount);
    error TokenBufferViolation(address tokenAddress);
    error PriceZero();

    event PayinGEMLP(
        // address of the token sent into the vault
        address tokenInAddress,
        // amount payed in (was in escrow)
        uint256 amountPayin
    );

    event PlayerPayout(
        // address the player receiving the tokens (do we need this? i guess it does not matter to who we send tokens for profit/loss calculations?)
        address recipient,
        // address of the token paid to the player
        address tokenOut,
        // net amount sent to the player (this is NOT the net loss, since it includes the payed in tokens, excludes wagerFee and swapFee!)
        uint256 amountPayoutTotal
    );

    event AmountOutNull();

    event WithdrawAllFees(
        address tokenCollected,
        uint256 swapFeesCollected,
        uint256 wagerFeesCollected,
        uint256 referralFeesCollected
    );

    event RebalancingWithdraw(address tokenWithdrawn, uint256 amountWithdrawn);

    event RebalancingDeposit(address tokenDeposit, uint256 amountDeposit);

    event WagerFeeChanged(uint256 newWagerFee);

    event ReferralDistributionReverted(
        uint256 registeredTooMuch,
        uint256 maxVaueAllowed
    );

    /*==================== Operational Functions *====================*/
    function setPayoutHalted(bool _setting) external;

    function isSwapEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;

    function setError(uint256 _errorCode, string calldata _error) external;

    function usdw() external view returns (address);

    function feeCollector() external returns (address);

    function hasDynamicFees() external view returns (bool);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdwAmount(
        address _token
    ) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function tokenBalances(address _token) external view returns (uint256);

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(
        address _manager,
        bool _isManager,
        bool _isGEMLPManager
    ) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setUsdwAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _minimumBurnMintFee,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _maxUsdwAmount,
        bool _isStable
    ) external;

    function setPriceFeedRouter(address _priceFeed) external;

    function withdrawAllFees(
        address _token
    ) external returns (uint256, uint256, uint256);

    function directPoolDeposit(address _token) external;

    function deposit(
        address _tokenIn,
        address _receiver,
        bool _swapLess
    ) external returns (uint256);

    function withdraw(
        address _tokenOut,
        address _receiverTokenOut
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function tokenToUsdMin(
        address _tokenToPrice,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function priceOracleRouter() external view returns (address);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function minimumBurnMintFee() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function stableTokens(address _token) external view returns (bool);

    function swapFeeReserves(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function usdwAmounts(address _token) external view returns (uint256);

    function maxUsdwAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdwAmount
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function setVaultManagerAddress(
        address _vaultManagerAddress,
        bool _setting
    ) external;

    function wagerFeeBasisPoints() external view returns (uint256);

    function setWagerFee(uint256 _wagerFee) external;

    function wagerFeeReserves(address _token) external view returns (uint256);

    function referralReserves(address _token) external view returns (uint256);

    function getReserve() external view returns (uint256);

    function getGemLpValue() external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function usdToTokenMax(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function usdToToken(
        address _token,
        uint256 _usdAmount,
        uint256 _price
    ) external view returns (uint256);

    function returnTotalOutAndIn(
        address token_
    ) external view returns (uint256 totalOutAllTime_, uint256 totalInAllTime_);

    function payout(
        address _wagerToken,
        address _escrowAddress,
        uint256 _escrowAmount,
        address _recipient,
        uint256 _totalAmount
    ) external;

    function payoutNoEscrow(
        address _wagerAsset,
        address _recipient,
        uint256 _totalAmount
    ) external;

    function payin(
        address _inputToken,
        address _escrowAddress,
        uint256 _escrowAmount
    ) external;

    function setAsideReferral(address _token, uint256 _amount) external;

    function payinWagerFee(address _tokenIn) external;

    function payinSwapFee(address _tokenIn) external;

    function payinPoolProfits(address _tokenIn) external;

    function removeAsideReferral(
        address _token,
        uint256 _amountRemoveAside
    ) external;

    function setFeeCollector(address _feeCollector) external;

    function upgradeVault(
        address _newVault,
        address _token,
        uint256 _amount,
        bool _upgrade
    ) external;

    function setCircuitBreakerAmount(address _token, uint256 _amount) external;

    function clearTokenConfig(address _token) external;

    function updateTokenBalance(address _token) external;

    function setCircuitBreakerEnabled(bool _setting) external;

    function setPoolBalance(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVaultUtils {
	function getBuyUsdwFeeBasisPoints(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getSellUsdwFeeBasisPoints(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getSwapFeeBasisPoints(
		address _tokenIn,
		address _tokenOut,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getFeeBasisPoints(
		address _token,
		uint256 _usdwDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) external view returns (uint256);
}