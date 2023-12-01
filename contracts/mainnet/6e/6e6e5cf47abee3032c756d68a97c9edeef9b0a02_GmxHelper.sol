// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../Interfaces/IGmxHelper.sol";
import {IGmxVault} from "../Interfaces/IGmxVault.sol";
import {IGmxReader} from "../Interfaces/IGmxReader.sol";

contract GmxHelper is IGmxHelper {
    address private owner;

    IGmxVault public gmxVault;

    IGmxReader public gmxReader;

    address private GMX_VAULT_ADDRESS;

    address private WETH_TOKEN;

    event NewOwnerSet(address _newOwner, address _olderOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "gmxHelper: Forbidden");
        _;
    }

    constructor(address _vault, address _weth, address _reader) {
        gmxVault = IGmxVault(_vault);

        gmxReader = IGmxReader(_reader);

        WETH_TOKEN = _weth;

        owner = msg.sender;
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit NewOwnerSet(_newOwner, msg.sender);
    }

    function setAddresses(address _vault, address _reader) external onlyOwner {
        gmxVault = IGmxVault(_vault);
        gmxReader = IGmxReader(_reader);
    }

    /**
     * @notice Calculate leverage from collateral and size.
     * @param _collateralToken Address of the collateral token or input
     *                         token.
     * @param _indexToken      Address of the index token longing on.
     * @param _collateralDelta  Amount of collateral in collateral token decimals.
     * @param _sizeDelta        Size of the position usd in 1e30 decimals.
     * @return _positionLeverage
     */
    function getPositionLeverage(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) public view returns (uint256 _positionLeverage) {
        _positionLeverage = ((_sizeDelta * 1e30) /
            calculateCollateral(
                _collateralToken,
                _indexToken,
                _collateralDelta,
                _sizeDelta
            ));
    }

    /**
     * @notice Calculate collateral amount in 1e30 usd decimal
     *         given the input amount of token in its own decimals.
     *         considers position fee and swap fees before calculating
     *         output amount.
     * @param _collateralToken  Address of the input token or collateral token.
     * @param _indexToken       Address of the index token to long for.
     * @param _collateralAmount Amount of collateral in collateral token decimals.
     * @param _sizeDelta            Size of the position usd in 1e30 decimals.
     * @return collateral
     */
    function calculateCollateral(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralAmount,
        uint256 _sizeDelta
    ) public view returns (uint256 collateral) {
        uint256 marginFees = getPositionFee(_sizeDelta);
        if (_collateralToken != _indexToken) {
            (collateral, ) = gmxReader.getAmountOut(
                gmxVault,
                _collateralToken,
                _indexToken,
                _collateralAmount
            );
            collateral = gmxVault.tokenToUsdMin(_indexToken, collateral);
        } else {
            collateral = gmxVault.tokenToUsdMin(
                _collateralToken,
                _collateralAmount
            );
        }
        require(marginFees < collateral, "Utils: Fees exceed collateral");
        collateral -= marginFees;
    }

    /**
     * @notice Calculate collateral amount in 1e30 usd decimal
     *         given the input amount of token in its own decimals.
     *         considers position fee and swap fees before calculating
     *         output amount.
     * @param _collateralToken  Address of the input token or collateral token.
     * @param _indexToken       Address of the index token to long for.
     * @param _collateralDelta Amount of collateral in collateral token decimals.
     * @return collateral
     */
    function calculateCollateralDelta(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta
    ) public view returns (uint256 collateral) {
        if (_collateralToken != _indexToken) {
            uint256 priceIn = getMinPrice(_collateralToken);
            uint256 priceOut = getMaxPrice(_indexToken);
            collateral = adjustForDecimals(
                (_collateralDelta * priceIn) / priceOut,
                _collateralToken,
                _indexToken
            );
        } else collateral = _collateralDelta;
    }

    /**
     * @notice Check if collateral amount is sufficient
     *         to open a long position.
     * @param _collateralSize  Amount of collateral in its own decimals
     * @param _size            Total Size of the position in usd 1e30
     *                         decimals.
     * @param _collateralToken Address of the collateral token or input
     *                         token.
     * @param _indexToken      Address of the index token longing on
     */
    function validateLongIncreaseExecution(
        uint256 _collateralSize,
        uint256 _size,
        address _collateralToken,
        address _indexToken
    ) public view returns (bool) {
        if (_collateralToken != _indexToken) {
            (_collateralSize, ) = gmxReader.getAmountOut(
                gmxVault,
                _collateralToken,
                _indexToken,
                _collateralSize
            );
        }

        return
            gmxVault.tokenToUsdMin(_indexToken, _collateralSize) >
            getPositionFee(_size) + gmxVault.liquidationFeeUsd();
    }

    /**
     * @notice Check if collateral amount is sufficient
     *         to open a long position.
     * @param _collateralSize  Amount of collateral in its own decimals
     * @param _size            Total Size of the position in usd 1e30
     *                         decimals.
     * @param _collateralToken Address of the collateral token or input
     *                         token.
     */
    function validateShortIncreaseExecution(
        uint256 _collateralSize,
        uint256 _size,
        address _collateralToken
    ) public view returns (bool) {
        return
            gmxVault.tokenToUsdMin(_collateralToken, _collateralSize) >
            getPositionFee(_size) + gmxVault.liquidationFeeUsd();
    }

    /**
     * @notice Get fee charged on opening and closing a position on gmx.
     * @param  _size  Total size of the position in 30 decimal usd precision value.
     * @return feeUsd Fee in 30 decimal usd precision value.
     */
    function getPositionFee(
        uint256 _size
    ) public view returns (uint256 feeUsd) {
        address gov = gmxVault.gov();
        uint256 marginFeeBps = IGmxVault(gov).marginFeeBasisPoints();
        feeUsd = _size - ((_size * (10000 - marginFeeBps)) / 10000);
    }

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        return
            gmxVault.getPosition(
                _account,
                _collateralToken,
                _indexToken,
                _isLong
            );
    }

    function tokenDecimals(address _token) public view returns (uint256) {
        return gmxVault.tokenDecimals(_token);
    }

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) public view returns (uint256) {
        return gmxVault.adjustForDecimals(_amount, _tokenDiv, _tokenMul);
    }

    function getMinPrice(address _token) public view returns (uint256) {
        return gmxVault.getMinPrice(_token);
    }

    function getMaxPrice(address _token) public view returns (uint256) {
        return gmxVault.getMaxPrice(_token);
    }

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) public view returns (uint256) {
        return gmxVault.tokenToUsdMin(_token, _tokenAmount);
    }

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view override returns (bytes32) {
        return
            gmxVault.getPositionKey(
                _account,
                _collateralToken,
                _indexToken,
                _isLong
            );
    }

    function usdToTokenMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256) {
        return gmxVault.tokenToUsdMin(_token, _tokenAmount);
    }

    function getWethToken() external view override returns (address) {
        return WETH_TOKEN;
    }

    function getGmxDecimals() external pure returns (uint256) {
        // return IGmxVault(getGmxVault()).PRICE_PRECISION();
        return 1e30;
    }

    // function validateDecreaseCollateralDelta(
    //     address _externalPosition,
    //     address _indexToken,
    //     address _collateralToken,
    //     uint256 _collateralDelta
    // ) external view returns (bool valid) {
    //     bool isLong = _collateralToken== _indexToken;
    //     (uint256 size, uint256 collateral, , , , , , ) = vault.getPosition(
    //         _externalPosition,
    //         _collateralToken,
    //         _indexToken,
    //         isLong
    //     );

    //     (bool hasProfit, uint256 delta) = vault.getPositionDelta(
    //         _externalPosition,
    //         _collateralToken,
    //         _indexToken,
    //         isLong
    //     );

    //     uint256 feeUsd = getFundingFee(
    //         _indexToken,
    //         ,
    //         address(0)
    //     ) + getPositionFee(size);

    //     collateral -= _collateralDelta;
    //     delta += feeUsd;

    //     uint256 newLeverage = (size * 10000) / collateral;

    //     valid = true;

    //     if (vault.maxLeverage() < newLeverage) {
    //         valid = false;
    //     }

    //     if (!hasProfit && delta > collateral) {
    //         valid = false;
    //     }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IGmxVault} from "./IGmxVault.sol";

interface IGmxHelper {
    function tokenDecimals(address) external returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
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

    function usdToTokenMin(address, uint256) external returns (uint256);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external returns (bytes32);

    function tokenToUsdMin(address, uint256) external returns (uint256);

    function getMaxPrice(address) external returns (uint256);

    function getMinPrice(address) external returns (uint256);

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function getWethToken() external view returns (address);

    function getGmxDecimals() external view returns (uint256);

    function calculateCollateralDelta(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta
    ) external returns (uint256 collateral);

    function validateLongIncreaseExecution(
        uint256 collateralSize,
        uint256 positionSize,
        address collateralToken,
        address indexToken
    ) external view returns (bool);

    function validateShortIncreaseExecution(
        uint256 collateralSize,
        uint256 positionSize,
        address indexToken
    ) external view returns (bool);

    function gmxVault() external view returns (IGmxVault);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGmxVault {
    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    function updateCumulativeFundingRate(address _indexToken) external;

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function positions(bytes32) external view returns (Position memory);

    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function usdg() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdgAmount(
        address _token
    ) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(
        address _token
    ) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

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
        address _collateralToken,
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

    function getPositionFee(
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getFundingFee(
        address /* _account */,
        address _collateralToken,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function getPositionLeverage(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {IGmxVault} from "./IGmxVault.sol";

interface IGmxReader {
    function getMaxAmountIn(
        IGmxVault _vault,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256);

    function getAmountOut(
        IGmxVault _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256, uint256);
}