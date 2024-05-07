/**
 *Submitted for verification at Arbiscan.io on 2024-05-07
*/

// Sources flattened with hardhat v2.20.1 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/access/interfaces/IAdmin.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity 0.8.19;

interface IAdmin {
    function admin() external view returns (address);

    function setAdmin(address _admin) external;
}


// File contracts/core/interfaces/IBasePositionManager.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity 0.8.19;

interface IBasePositionManager is IAdmin {
    function maxGlobalLongSizes(address _token) external view returns (uint256);

    function maxGlobalShortSizes(address _token)
        external
        view
        returns (uint256);
}


// File contracts/core/interfaces/IVault.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity 0.8.19;

interface IVault {
    function isInitialized() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function collateralToken() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router)
        external
        view
        returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function plpManager() external view returns (address);

    function minProfitBasisPoints(address _token)
        external
        view
        returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token, bool _isLong)
        external
        view
        returns (uint256);

    function estimateUSDPOut(uint256 _amount) external view returns (uint256);

    function estimateTokenIn(uint256 _usdpAmount)
        external
        view
        returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setPlpManager(address _manager) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdpAmount(uint256 _amount) external;

    function setMaxGlobalSize(
        address _token,
        uint256 _longAmount,
        uint256 _shortAmount
    ) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor
    ) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime
    ) external;

    function setMaxUsdpAmounts(uint256 _maxUsdpAmounts) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _minProfitBps,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(address _receiver) external returns (uint256);

    function directPoolDeposit() external;

    function addLiquidity() external returns (uint256);

    function removeLiquidity(address _receiver, uint256 _usdpAmount)
        external
        returns (uint256);

    function increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function validateLiquidation(
        address _account,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function liquidatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(address _token, uint256 _tokenAmount)
        external
        view
        returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address _token, bool _isLong)
        external
        view
        returns (uint256);

    function getNextFundingRate(address _token, bool _isLong)
        external
        view
        returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserve() external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalLongSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(address _token)
        external
        view
        returns (uint256);

    function globalLongAveragePrices(address _token)
        external
        view
        returns (uint256);

    function maxGlobalShortSizes(address _token)
        external
        view
        returns (uint256);

    function maxGlobalLongSizes(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function poolAmount() external view returns (uint256);

    function reservedAmounts(address _token, bool _isLong)
        external
        view
        returns (uint256);

    function totalReservedAmount() external view returns (uint256);

    function usdpAmount() external view returns (uint256);

    function maxUsdpAmount() external view returns (uint256);

    function getRedemptionAmount(uint256 _usdpAmount)
        external
        view
        returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );
}


// File contracts/core/interfaces/IVaultPyth.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity 0.8.19;

interface IVaultPyth is IVault {
    function getDeltaAtPrice(
        uint256 _markPrice,
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getMaxLeverage(
        address token
    ) external view returns (uint256 _maxLeverage);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// File contracts/peripherals/Reader.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity 0.8.19;


contract Reader {
    uint256 public constant POSITION_PROPS_LENGTH = 9;
    uint256 public constant GLOBAL_SIZE_PRECISION = 1e30;

    function getFees(address _vault) public view returns (uint256) {
        return IVault(_vault).feeReserve();
    }

    function getFundingRates(
        address _vault,
        address _positionRouter,
        address _weth,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
        uint256 propsLength = 4;
        uint256[] memory fundingRates = new uint256[](
            _tokens.length * propsLength
        );
        IVault vault = IVault(_vault);
        IBasePositionManager positionRouter = IBasePositionManager(_positionRouter);

        uint256 poolAmount = vault.poolAmount();
        uint256 fundingRateFactor = vault.fundingRateFactor();

        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            uint256 reservedAmountLong = vault.reservedAmounts(token, true);
            uint256 reservedAmountShort = vault.reservedAmounts(token, false);

            if (poolAmount > 0) {
                address collateralToken = vault.collateralToken();
                uint256 collateralDecimals = vault.tokenDecimals(collateralToken);
                
                if (positionRouter.maxGlobalLongSizes(token) == 0) {
                    fundingRates[i * propsLength] = 0;
                } else {
                    fundingRates[i * propsLength] =
                        (fundingRateFactor * reservedAmountLong) *
                        GLOBAL_SIZE_PRECISION / (positionRouter.maxGlobalLongSizes(token) * 10 ** collateralDecimals);
                }
                
                if (positionRouter.maxGlobalShortSizes(token) == 0) {
                    fundingRates[i * propsLength + 1] = 0;
                } else {
                    fundingRates[i * propsLength + 1] =
                        (fundingRateFactor * reservedAmountShort) *
                        GLOBAL_SIZE_PRECISION / (positionRouter.maxGlobalShortSizes(token) * 10 ** collateralDecimals);
                }
            }

            if (vault.cumulativeFundingRates(token, true) > 0) {
                uint256 nextRate = vault.getNextFundingRate(token, true);
                uint256 baseRate = vault.cumulativeFundingRates(token, true);
                fundingRates[i * propsLength + 2] = baseRate + nextRate;
            }

            if (vault.cumulativeFundingRates(token, false) > 0) {
                uint256 nextRate = vault.getNextFundingRate(token, false);
                uint256 baseRate = vault.cumulativeFundingRates(token, false);
                fundingRates[i * propsLength + 3] = baseRate + nextRate;
            }
        }

        return fundingRates;
    }

    function getTokenSupply(
        IERC20 _token,
        address[] memory _excludedAccounts
    ) public view returns (uint256) {
        uint256 supply = _token.totalSupply();
        for (uint256 i; i < _excludedAccounts.length; i++) {
            address account = _excludedAccounts[i];
            uint256 balance = _token.balanceOf(account);
            supply -= balance;
        }
        return supply;
    }

    function getTotalBalance(
        IERC20 _token,
        address[] memory _accounts
    ) public view returns (uint256) {
        uint256 totalBalance = 0;
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 balance = _token.balanceOf(account);
            totalBalance += balance;
        }
        return totalBalance;
    }

    function getTokenBalances(
        address _account,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
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
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
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

    function getPositions(
        address _vault,
        address _account,
        address[] memory _indexTokens,
        uint256[] memory _offchainPrices,
        bool[] memory _isLong
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](
            _indexTokens.length * POSITION_PROPS_LENGTH
        );

        for (uint256 i; i < _indexTokens.length; i++) {
            {
                (
                    uint256 _size,
                    uint256 collateral,
                    uint256 _averagePrice,
                    uint256 entryFundingRate,
                    ,
                    /* reserveAmount */
                    uint256 realisedPnl,
                    bool hasRealisedProfit,
                    uint256 _lastIncreasedTime
                ) = IVault(_vault).getPosition(
                        _account,
                        _indexTokens[i],
                        _isLong[i]
                    );

                amounts[i * POSITION_PROPS_LENGTH] = _size;
                amounts[i * POSITION_PROPS_LENGTH + 1] = collateral;
                amounts[i * POSITION_PROPS_LENGTH + 2] = _averagePrice;
                amounts[i * POSITION_PROPS_LENGTH + 3] = entryFundingRate;
                amounts[i * POSITION_PROPS_LENGTH + 4] = hasRealisedProfit
                    ? 1
                    : 0;
                amounts[i * POSITION_PROPS_LENGTH + 5] = realisedPnl;
                amounts[i * POSITION_PROPS_LENGTH + 6] = _lastIncreasedTime;
            }

            uint256 size = amounts[i * POSITION_PROPS_LENGTH];
            uint256 averagePrice = amounts[i * POSITION_PROPS_LENGTH + 2];
            uint256 lastIncreasedTime = amounts[i * POSITION_PROPS_LENGTH + 6];
            if (averagePrice > 0) {
                (bool hasProfit, uint256 delta) = IVaultPyth(_vault)
                    .getDeltaAtPrice(
                        _offchainPrices[i],
                        _indexTokens[i],
                        size,
                        averagePrice,
                        _isLong[i],
                        lastIncreasedTime
                    );
                amounts[i * POSITION_PROPS_LENGTH + 7] = hasProfit ? 1 : 0;
                amounts[i * POSITION_PROPS_LENGTH + 8] = delta;
            }
        }

        return amounts;
    }
}