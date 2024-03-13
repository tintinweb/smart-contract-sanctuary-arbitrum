// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IAdmin {
    function admin() external view returns (address);

    function setAdmin(address _admin) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../access/interfaces/IAdmin.sol";

interface IBasePositionManager is IAdmin {
    function maxGlobalLongSizes(address _token) external view returns (uint256);

    function maxGlobalShortSizes(address _token)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token)
        external
        view
        returns (uint256);

    function isAdjustmentAdditive(address _token) external view returns (bool);

    function setAdjustment(
        address _token,
        bool _isAdditive,
        uint256 _adjustmentBps
    ) external;

    function setUseV2Pricing(bool _useV2Pricing) external;

    function setIsAmmEnabled(bool _isEnabled) external;

    function setIsSecondaryPriceEnabled(bool _isEnabled) external;

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints)
        external;

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints)
        external;

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

    function setPriceSampleSpace(uint256 _priceSampleSpace) external;

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation)
        external;

    function getPrice(
        address _token,
        bool _maximise,
        bool _includeAmmPrice,
        bool _useSwapPricing
    ) external view returns (uint256);

    function getAmmPrice(address _token) external view returns (uint256);

    function getLatestPrimaryPrice(address _token)
        external
        view
        returns (uint256);

    function getPrimaryPrice(address _token, bool _maximise)
        external
        view
        returns (uint256);

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable,
        uint256 _stalePriceThreshold
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IVault} from "./IVault.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../core/interfaces/IVaultPyth.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../core/interfaces/IBasePositionManager.sol";
import "../peripherals/interfaces/ITimelock.sol";

contract VaultReader {
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;

    function getVaultTokenInfo(
        address _vault,
        address _positionManager,
        address _weth,
        address[] memory _tokens
    )
        public
        view
        returns (
            uint256[] memory amounts,
            uint256 poolAmount,
            uint256 usdpAmount,
            uint256 maxUsdpAmount
        )
    {
        uint256 propsLength = 6;

        IVaultPyth vault = IVaultPyth(_vault);
        IBasePositionManager positionManager = IBasePositionManager(
            _positionManager
        );

        poolAmount = vault.poolAmount();
        usdpAmount = vault.usdpAmount();
        maxUsdpAmount = vault.maxUsdpAmount();

        amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            amounts[i * propsLength] = vault.reservedAmounts(token, true);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token, false);
            amounts[i * propsLength + 2] = vault.globalShortSizes(token);
            amounts[i * propsLength + 3] = vault.globalLongSizes(token);
            amounts[i * propsLength + 4] = positionManager.maxGlobalShortSizes(
                token
            );
            amounts[i * propsLength + 5] = positionManager.maxGlobalLongSizes(
                token
            );
        }
    }

    function validateLiquidationAtPrice(
        uint256 _markPrice,
        address _vault,
        address _account,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256) {
        IVaultPyth vault = IVaultPyth(_vault);

        address indexToken = _indexToken;
        uint256 markPrice = _markPrice;
        bool isLong = _isLong;
        (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate /* reserveAmount */ /* realisedPnl */ /* hasProfit */,
            ,
            ,
            ,
            uint256 lastIncreasedTime
        ) = vault.getPosition(_account, indexToken, _isLong);

        if (size == 0 || averagePrice == 0) return 0;

        (bool hasProfit, uint256 delta) = vault.getDeltaAtPrice(
            markPrice,
            indexToken,
            size,
            averagePrice,
            isLong,
            lastIncreasedTime
        );

        if (!hasProfit && collateral < delta) {
            return 1;
        }

        uint256 marginFees;

        {
            uint256 fundingRate = vault.cumulativeFundingRates(
                indexToken,
                isLong
            ) +
                vault.getNextFundingRate(indexToken, isLong) -
                entryFundingRate;

            if (fundingRate != 0) {
                marginFees = (size * fundingRate) / FUNDING_RATE_PRECISION;
            }
        }

        uint256 afterFeeUsd = (size *
            (BASIS_POINTS_DIVISOR -
                ITimelock(Ownable(address(vault)).owner())
                    .marginFeeBasisPoints())) / BASIS_POINTS_DIVISOR;
        marginFees += size - afterFeeUsd;

        {
            uint256 remainingCollateral = collateral;
            if (!hasProfit) {
                remainingCollateral = collateral - delta;
            }

            if (remainingCollateral < marginFees + vault.liquidationFeeUsd()) {
                return 1;
            }

            uint256 maxLeverage = vault.getMaxLeverage(indexToken);
            if (
                remainingCollateral * maxLeverage < size * BASIS_POINTS_DIVISOR
            ) {
                return 2;
            }
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../access/interfaces/IAdmin.sol";

interface ITimelock is IAdmin {
    function marginFeeBasisPoints() external view returns (uint256);

    function enableLeverage(address _vault) external;

    function disableLeverage(address _vault) external;

    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled)
        external;

    function signalSetGov(address _target, address _gov) external;
}