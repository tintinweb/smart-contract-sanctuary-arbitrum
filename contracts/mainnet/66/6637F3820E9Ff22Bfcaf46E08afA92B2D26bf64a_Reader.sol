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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Governable {
    address public gov;

    event GovChanged(address indexed oldGov, address indexed newGov);

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        emit GovChanged(gov, _gov);
        gov = _gov;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

pragma solidity ^0.8.9;

import "./IVaultUtils.sol";
import "../protocol/libraries/TokenConfiguration.sol";
import "../protocol/libraries/PositionInfo.sol";

interface IVault {
    /* Variables Getter */
    function priceFeed() external view returns (address);

    function vaultUtils() external view returns (address);

    function usdp() external view returns (address);

    function hasDynamicFees() external view returns (bool);

    function poolAmounts(address token) external view returns (uint256);

    function minProfitTime() external returns (uint256);

    function inManagerMode() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    /* Write Functions */
    function buyUSDP(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDP(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function swapWithoutFees(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function claimFund(
        address _collateralToken,
        address _account,
        bool _isLong,
        uint256 _amountOutUsd,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        uint256 _feeUsd
    ) external;

    function decreasePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        address _receiver,
        uint256 _amountOutUsd,
        uint256 _feeUsd
    ) external returns (uint256);

    function liquidatePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _positionSize,
        uint256 _positionMargin,
        bool _isLong
    ) external;

    function addCollateral(
        address _account,
        address[] memory _path,
        address _indexToken,
        bool _isLong,
        uint256 _feeToken
    ) external;

    function removeCollateral(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _amountInToken
    ) external;

    /* Goivernance function */
    function setWhitelistCaller(address caller, bool val) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setConfigToken(
        address _token,
        uint8 _tokenDecimals,
        uint64 _minProfitBps,
        uint128 _tokenWeight,
        uint128 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setPriceFeed(address _priceFeed) external;

    function setVaultUtils(IVaultUtils _vaultUtils) external;

    function setBorrowingRate(
        uint256 _borrowingRateInterval,
        uint256 _borrowingRateFactor,
        uint256 _stableBorrowingRateFactor
    ) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    /* End Goivernance function */

    /* View Functions */
    function getBidPrice(address _token) external view returns (uint256);

    function getAskPrice(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function isStableToken(address _token) external view returns (bool);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256 i) external view returns (address);

    function isWhitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function borrowingRateInterval() external view returns (uint256);

    function borrowingRateFactor() external view returns (uint256);

    function stableBorrowingRateFactor() external view returns (uint256);

    function lastBorrowingRateTimes(
        address _token
    ) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function cumulativeBorrowingRates(
        address _token
    ) external view returns (uint256);

    function getNextBorrowingRate(
        address _token
    ) external view returns (uint256);

    function getBorrowingFee(
        address _trader,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getSwapFee(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    // pool info
    function usdpAmount(address _token) external view returns (uint256);

    function getTargetUsdpAmount(
        address _token
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdpDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getTokenConfiguration(
        address _token
    ) external view returns (TokenConfiguration.Data memory);

    function getPositionInfo(
        address _account,
        address _indexToken,
        bool _isLong
    ) external view returns (PositionInfo.Data memory);

    function getAvailableReservedAmount(
        address _collateralToken
    ) external view returns (uint256);

    function adjustDecimalToUsd(
        address _token,
        uint256 _amount
    ) external view returns (uint256);

    function adjustDecimalToToken(
        address _token,
        uint256 _amount
    ) external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function tokenToUsdMinWithAdjustment(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function usdToTokenMinWithAdjustment(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);
}

pragma solidity ^0.8.9;

interface IVaultPriceFeed {
    function getPrice(
        address _token,
        bool _maximise
    ) external view returns (uint256);

    function getPrimaryPrice(
        address _token,
        bool _maximise
    ) external view returns (uint256);

    function setPriceFeedConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        uint256 _spreadBasisPoints,
        bool _isStrictStable
    ) external;
}

pragma solidity ^0.8.9;

interface IVaultUtils {
    function getBuyUsdgFeeBasisPoints(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function getSellUsdgFeeBasisPoints(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function getSwapFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getBorrowingFee(
        address _collateralToken,
        uint256 _size,
        uint256 _entryBorrowingRate
    ) external view returns (uint256);

    function updateCumulativeBorrowingRate(
        address _collateralToken,
        address _indexToken
    ) external returns (bool);
}

pragma solidity ^0.8.9;

library PositionInfo {
    struct Data {
        uint256 reservedAmount;
        uint128 entryBorrowingRates;
        address collateralToken;
    }

    function setEntryBorrowingRates(
        Data storage _self,
        uint256 _rate
    ) internal {
        _self.entryBorrowingRates = uint128(_rate);
    }

    function addReservedAmount(Data storage _self, uint256 _amount) internal {
        _self.reservedAmount = _self.reservedAmount + _amount;
    }

    function subReservedAmount(
        Data storage _self,
        uint256 _amount
    ) internal returns (uint256) {
        // Position already decreased on process chain -> no point in reverting
        // require(
        //    _amount <= _self.reservedAmount,
        //    "Vault: reservedAmount exceeded"
        // );
        if (_amount >= _self.reservedAmount) {
            _amount = _self.reservedAmount;
        }
        _self.reservedAmount = _self.reservedAmount - _amount;
        return _amount;
    }

    function setCollateralToken(Data storage _self, address _token) internal {
        if (_self.collateralToken == address(0)) {
            _self.collateralToken = _token;
            return;
        }
        require(_self.collateralToken == _token);
    }
}

pragma solidity ^0.8.9;

library TokenConfiguration {
    struct Data {
        // packable storage
        bool isWhitelisted;
        uint8 tokenDecimals;
        bool isStableToken;
        bool isShortableToken;
        uint64 minProfitBasisPoints;
        uint128 tokenWeight;
        // maxUsdpAmounts allows setting a max amount of USDP debt for a token
        uint128 maxUsdpAmount;
    }

    function getIsWhitelisted(Data storage _self) internal view returns (bool) {
        return _self.isWhitelisted;
    }

    function getTokenDecimals(
        Data storage _self
    ) internal view returns (uint8) {
        return _self.tokenDecimals;
    }

    function getTokenWeight(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.tokenWeight);
    }

    function getIsStableToken(Data storage _self) internal view returns (bool) {
        return _self.isStableToken;
    }

    function getIsShortableToken(
        Data storage _self
    ) internal view returns (bool) {
        return _self.isShortableToken;
    }

    function getMinProfitBasisPoints(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.minProfitBasisPoints);
    }

    function getMaxUsdpAmount(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.maxUsdpAmount);
    }
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../access/Governable.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultPriceFeed.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../token/interface/IYieldTracker.sol";
import "../token/interface/IYieldToken.sol";
import "../staking/interfaces/IVester.sol";

contract Reader is Governable {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant POSITION_PROPS_LENGTH = 9;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant USDG_DECIMALS = 18;

    bool public hasMaxGlobalShortSizes;

    function setConfig(bool _hasMaxGlobalShortSizes) public onlyGov {
        hasMaxGlobalShortSizes = _hasMaxGlobalShortSizes;
    }

    function getMaxAmountIn(
        IVault _vault,
        address _tokenIn,
        address _tokenOut
    ) public view returns (uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 priceOut = _vault.getMaxPrice(_tokenOut);

        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = _vault.tokenDecimals(_tokenOut);

        uint256 amountIn;

        {
            uint256 poolAmount = _vault.poolAmounts(_tokenOut);
            uint256 reservedAmount = _vault.reservedAmounts(_tokenOut);
            uint256 bufferAmount = _vault.bufferAmounts(_tokenOut);
            uint256 subAmount = reservedAmount > bufferAmount
                ? reservedAmount
                : bufferAmount;
            if (subAmount >= poolAmount) {
                return 0;
            }
            uint256 availableAmount = poolAmount.sub(subAmount);
            amountIn = availableAmount
                .mul(priceOut)
                .div(priceIn)
                .mul(10 ** tokenInDecimals)
                .div(10 ** tokenOutDecimals);
        }

        uint256 maxUsdgAmount = _vault.maxUsdgAmounts(_tokenIn);

        if (maxUsdgAmount != 0) {
            uint256 maxAmountIn = maxUsdgAmount.mul(10 ** tokenInDecimals).div(
                10 ** USDG_DECIMALS
            );
            maxAmountIn = maxAmountIn.mul(PRICE_PRECISION).div(priceIn);

            if (amountIn > maxAmountIn) {
                return maxAmountIn;
            }
        }

        return amountIn;
    }

    function getAmountOut(
        IVault _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) public view returns (uint256, uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);

        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = _vault.tokenDecimals(_tokenOut);

        uint256 feeBasisPoints;
        {
            uint256 usdgAmount = _amountIn.mul(priceIn).div(PRICE_PRECISION);
            usdgAmount = usdgAmount.mul(10 ** USDG_DECIMALS).div(
                10 ** tokenInDecimals
            );

            bool isStableSwap = _vault.stableTokens(_tokenIn) &&
                _vault.stableTokens(_tokenOut);
            uint256 baseBps = isStableSwap
                ? _vault.stableSwapFeeBasisPoints()
                : _vault.swapFeeBasisPoints();
            uint256 taxBps = isStableSwap
                ? _vault.stableTaxBasisPoints()
                : _vault.taxBasisPoints();
            uint256 feesBasisPoints0 = _vault.getFeeBasisPoints(
                _tokenIn,
                usdgAmount,
                baseBps,
                taxBps,
                true
            );
            uint256 feesBasisPoints1 = _vault.getFeeBasisPoints(
                _tokenOut,
                usdgAmount,
                baseBps,
                taxBps,
                false
            );
            // use the higher of the two fee basis points
            feeBasisPoints = feesBasisPoints0 > feesBasisPoints1
                ? feesBasisPoints0
                : feesBasisPoints1;
        }

        uint256 priceOut = _vault.getMaxPrice(_tokenOut);
        uint256 amountOut = _amountIn.mul(priceIn).div(priceOut);
        amountOut = amountOut.mul(10 ** tokenOutDecimals).div(
            10 ** tokenInDecimals
        );

        uint256 amountOutAfterFees = amountOut
            .mul(BASIS_POINTS_DIVISOR.sub(feeBasisPoints))
            .div(BASIS_POINTS_DIVISOR);
        uint256 feeAmount = amountOut.sub(amountOutAfterFees);

        return (amountOutAfterFees, feeAmount);
    }

    function getFeeBasisPoints(
        IVault _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) public view returns (uint256, uint256, uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);

        uint256 usdgAmount = _amountIn.mul(priceIn).div(PRICE_PRECISION);
        usdgAmount = usdgAmount.mul(10 ** USDG_DECIMALS).div(
            10 ** tokenInDecimals
        );

        bool isStableSwap = _vault.stableTokens(_tokenIn) &&
            _vault.stableTokens(_tokenOut);
        uint256 baseBps = isStableSwap
            ? _vault.stableSwapFeeBasisPoints()
            : _vault.swapFeeBasisPoints();
        uint256 taxBps = isStableSwap
            ? _vault.stableTaxBasisPoints()
            : _vault.taxBasisPoints();
        uint256 feesBasisPoints0 = _vault.getFeeBasisPoints(
            _tokenIn,
            usdgAmount,
            baseBps,
            taxBps,
            true
        );
        uint256 feesBasisPoints1 = _vault.getFeeBasisPoints(
            _tokenOut,
            usdgAmount,
            baseBps,
            taxBps,
            false
        );
        // use the higher of the two fee basis points
        uint256 feeBasisPoints = feesBasisPoints0 > feesBasisPoints1
            ? feesBasisPoints0
            : feesBasisPoints1;

        return (feeBasisPoints, feesBasisPoints0, feesBasisPoints1);
    }

    function getFees(
        address _vault,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            amounts[i] = IVault(_vault).feeReserves(_tokens[i]);
        }
        return amounts;
    }

    function getTotalStaked(
        address[] memory _yieldTokens
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_yieldTokens.length);
        for (uint256 i = 0; i < _yieldTokens.length; i++) {
            IYieldToken yieldToken = IYieldToken(_yieldTokens[i]);
            amounts[i] = yieldToken.totalStaked();
        }
        return amounts;
    }

    function getStakingInfo(
        address _account,
        address[] memory _yieldTrackers
    ) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory amounts = new uint256[](
            _yieldTrackers.length * propsLength
        );
        for (uint256 i = 0; i < _yieldTrackers.length; i++) {
            IYieldTracker yieldTracker = IYieldTracker(_yieldTrackers[i]);
            amounts[i * propsLength] = yieldTracker.claimable(_account);
            amounts[i * propsLength + 1] = yieldTracker.getTokensPerInterval();
        }
        return amounts;
    }

    function getVestingInfo(
        address _account,
        address[] memory _vesters
    ) public view returns (uint256[] memory) {
        uint256 propsLength = 7;
        uint256[] memory amounts = new uint256[](_vesters.length * propsLength);
        for (uint256 i = 0; i < _vesters.length; i++) {
            IVester vester = IVester(_vesters[i]);
            amounts[i * propsLength] = vester.pairAmounts(_account);
            amounts[i * propsLength + 1] = vester.getVestedAmount(_account);
            amounts[i * propsLength + 2] = IERC20(_vesters[i]).balanceOf(
                _account
            );
            amounts[i * propsLength + 3] = vester.claimedAmounts(_account);
            amounts[i * propsLength + 4] = vester.claimable(_account);
            amounts[i * propsLength + 5] = vester.getMaxVestableAmount(
                _account
            );
            amounts[i * propsLength + 6] = vester
                .getCombinedAverageStakedAmount(_account);
        }
        return amounts;
    }

    function getPairInfo(
        address _factory,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
        uint256 inputLength = 2;
        uint256 propsLength = 2;
        uint256[] memory amounts = new uint256[](
            (_tokens.length / inputLength) * propsLength
        );
        for (uint256 i = 0; i < _tokens.length / inputLength; i++) {
            address token0 = _tokens[i * inputLength];
            address token1 = _tokens[i * inputLength + 1];
            address pair = IUniswapV2Factory(_factory).getPair(token0, token1);

            amounts[i * propsLength] = IERC20(token0).balanceOf(pair);
            amounts[i * propsLength + 1] = IERC20(token1).balanceOf(pair);
        }
        return amounts;
    }

    function getFundingRates(
        address _vault,
        address _weth,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory fundingRates = new uint256[](
            _tokens.length * propsLength
        );
        IVault vault = IVault(_vault);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            uint256 fundingRateFactor = vault.stableTokens(token)
                ? vault.stableBorrowingRateFactor()
                : vault.borrowingRateFactor();
            uint256 reservedAmount = vault.reservedAmounts(token);
            uint256 poolAmount = vault.poolAmounts(token);

            if (poolAmount > 0) {
                fundingRates[i * propsLength] = fundingRateFactor
                    .mul(reservedAmount)
                    .div(poolAmount);
            }

            if (vault.cumulativeBorrowingRates(token) > 0) {
                uint256 nextRate = vault.getNextBorrowingRate(token);
                uint256 baseRate = vault.cumulativeBorrowingRates(token);
                fundingRates[i * propsLength + 1] = baseRate.add(nextRate);
            }
        }

        return fundingRates;
    }

    function getTokenSupply(
        IERC20 _token,
        address[] memory _excludedAccounts
    ) public view returns (uint256) {
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
        address[] memory _accounts
    ) public view returns (uint256) {
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
    //
    //    function getPrices(IVaultPriceFeed _priceFeed, address[] memory _tokens) public view returns (uint256[] memory) {
    //        uint256 propsLength = 6;
    //
    //        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
    //
    //        for (uint256 i = 0; i < _tokens.length; i++) {
    //            address token = _tokens[i];
    //            amounts[i * propsLength] = _priceFeed.getPrice(token, true, true, false);
    //            amounts[i * propsLength + 1] = _priceFeed.getPrice(token, false, true, false);
    //            amounts[i * propsLength + 2] = _priceFeed.getPrimaryPrice(token, true);
    //            amounts[i * propsLength + 3] = _priceFeed.getPrimaryPrice(token, false);
    //            amounts[i * propsLength + 4] = _priceFeed.isAdjustmentAdditive(token) ? 1 : 0;
    //            amounts[i * propsLength + 5] = _priceFeed.adjustmentBasisPoints(token);
    //        }
    //
    //        return amounts;
    //    }
    //
    //    function getVaultTokenInfo(address _vault, address _weth, uint256 _usdgAmount, address[] memory _tokens) public view returns (uint256[] memory) {
    //        uint256 propsLength = 10;
    //
    //        IVault vault = IVault(_vault);
    //        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());
    //
    //        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
    //        for (uint256 i = 0; i < _tokens.length; i++) {
    //            address token = _tokens[i];
    //            if (token == address(0)) {
    //                token = _weth;
    //            }
    //            amounts[i * propsLength] = vault.poolAmounts(token);
    //            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
    //            amounts[i * propsLength + 2] = vault.usdgAmounts(token);
    //            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _usdgAmount);
    //            amounts[i * propsLength + 4] = vault.tokenWeights(token);
    //            amounts[i * propsLength + 5] = vault.getMinPrice(token);
    //            amounts[i * propsLength + 6] = vault.getMaxPrice(token);
    //            amounts[i * propsLength + 7] = vault.guaranteedUsd(token);
    //            amounts[i * propsLength + 8] = priceFeed.getPrimaryPrice(token, false);
    //            amounts[i * propsLength + 9] = priceFeed.getPrimaryPrice(token, true);
    //        }
    //
    //        return amounts;
    //    }
    //
    //    function getFullVaultTokenInfo(address _vault, address _weth, uint256 _usdgAmount, address[] memory _tokens) public view returns (uint256[] memory) {
    //        uint256 propsLength = 12;
    //
    //        IVault vault = IVault(_vault);
    //        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());
    //
    //        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
    //        for (uint256 i = 0; i < _tokens.length; i++) {
    //            address token = _tokens[i];
    //            if (token == address(0)) {
    //                token = _weth;
    //            }
    //            amounts[i * propsLength] = vault.poolAmounts(token);
    //            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
    //            amounts[i * propsLength + 2] = vault.usdgAmounts(token);
    //            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _usdgAmount);
    //            amounts[i * propsLength + 4] = vault.tokenWeights(token);
    //            amounts[i * propsLength + 5] = vault.bufferAmounts(token);
    //            amounts[i * propsLength + 6] = vault.maxUsdgAmounts(token);
    //            amounts[i * propsLength + 7] = vault.getMinPrice(token);
    //            amounts[i * propsLength + 8] = vault.getMaxPrice(token);
    //            amounts[i * propsLength + 9] = vault.guaranteedUsd(token);
    //            amounts[i * propsLength + 10] = priceFeed.getPrimaryPrice(token, false);
    //            amounts[i * propsLength + 11] = priceFeed.getPrimaryPrice(token, true);
    //        }
    //
    //        return amounts;
    //    }
    //
    //    function getVaultTokenInfoV2(address _vault, address _weth, uint256 _usdgAmount, address[] memory _tokens) public view returns (uint256[] memory) {
    //        uint256 propsLength = 14;
    //
    //        IVault vault = IVault(_vault);
    //        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());
    //
    //        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
    //        for (uint256 i = 0; i < _tokens.length; i++) {
    //            address token = _tokens[i];
    //            if (token == address(0)) {
    //                token = _weth;
    //            }
    //
    //            uint256 maxGlobalShortSize = hasMaxGlobalShortSizes ? vault.maxGlobalShortSizes(token) : 0;
    //            amounts[i * propsLength] = vault.poolAmounts(token);
    //            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
    //            amounts[i * propsLength + 2] = vault.usdgAmounts(token);
    //            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _usdgAmount);
    //            amounts[i * propsLength + 4] = vault.tokenWeights(token);
    //            amounts[i * propsLength + 5] = vault.bufferAmounts(token);
    //            amounts[i * propsLength + 6] = vault.maxUsdgAmounts(token);
    //            amounts[i * propsLength + 7] = vault.globalShortSizes(token);
    //            amounts[i * propsLength + 8] = maxGlobalShortSize;
    //            amounts[i * propsLength + 9] = vault.getMinPrice(token);
    //            amounts[i * propsLength + 10] = vault.getMaxPrice(token);
    //            amounts[i * propsLength + 11] = vault.guaranteedUsd(token);
    //            amounts[i * propsLength + 12] = priceFeed.getPrimaryPrice(token, false);
    //            amounts[i * propsLength + 13] = priceFeed.getPrimaryPrice(token, true);
    //        }
    //
    //        return amounts;
    //    }
    //
    //    function getPositions(address _vault, address _account, address[] memory _collateralTokens, address[] memory _indexTokens, bool[] memory _isLong) public view returns(uint256[] memory) {
    //        uint256[] memory amounts = new uint256[](_collateralTokens.length * POSITION_PROPS_LENGTH);
    //
    //        for (uint256 i = 0; i < _collateralTokens.length; i++) {
    //            {
    //                (uint256 size,
    //                uint256 collateral,
    //                uint256 averagePrice,
    //                uint256 entryFundingRate,
    //                /* reserveAmount */,
    //                uint256 realisedPnl,
    //                bool hasRealisedProfit,
    //                uint256 lastIncreasedTime) = IVault(_vault).getPosition(_account, _collateralTokens[i], _indexTokens[i], _isLong[i]);
    //
    //                amounts[i * POSITION_PROPS_LENGTH] = size;
    //                amounts[i * POSITION_PROPS_LENGTH + 1] = collateral;
    //                amounts[i * POSITION_PROPS_LENGTH + 2] = averagePrice;
    //                amounts[i * POSITION_PROPS_LENGTH + 3] = entryFundingRate;
    //                amounts[i * POSITION_PROPS_LENGTH + 4] = hasRealisedProfit ? 1 : 0;
    //                amounts[i * POSITION_PROPS_LENGTH + 5] = realisedPnl;
    //                amounts[i * POSITION_PROPS_LENGTH + 6] = lastIncreasedTime;
    //            }
    //
    //            uint256 size = amounts[i * POSITION_PROPS_LENGTH];
    //            uint256 averagePrice = amounts[i * POSITION_PROPS_LENGTH + 2];
    //            uint256 lastIncreasedTime = amounts[i * POSITION_PROPS_LENGTH + 6];
    //            if (averagePrice > 0) {
    //                (bool hasProfit, uint256 delta) = IVault(_vault).getDelta(_indexTokens[i], size, averagePrice, _isLong[i], lastIncreasedTime);
    //                amounts[i * POSITION_PROPS_LENGTH + 7] = hasProfit ? 1 : 0;
    //                amounts[i * POSITION_PROPS_LENGTH + 8] = delta;
    //            }
    //        }
    //
    //        return amounts;
    //    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(
        address _account,
        address _receiver
    ) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function cumulativeClaimAmounts(
        address _account
    ) external view returns (uint256);

    function claimedAmounts(address _account) external view returns (uint256);

    function pairAmounts(address _account) external view returns (uint256);

    function getVestedAmount(address _account) external view returns (uint256);

    function transferredAverageStakedAmounts(
        address _account
    ) external view returns (uint256);

    function transferredCumulativeRewards(
        address _account
    ) external view returns (uint256);

    function cumulativeRewardDeductions(
        address _account
    ) external view returns (uint256);

    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;

    function setTransferredAverageStakedAmounts(
        address _account,
        uint256 _amount
    ) external;

    function setTransferredCumulativeRewards(
        address _account,
        uint256 _amount
    ) external;

    function setCumulativeRewardDeductions(
        address _account,
        uint256 _amount
    ) external;

    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(
        address _account
    ) external view returns (uint256);

    function getCombinedAverageStakedAmount(
        address _account
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IYieldToken {
    function totalStaked() external view returns (uint256);

    function stakedBalance(address _account) external view returns (uint256);

    function removeAdmin(address _account) external;
}

pragma solidity ^0.8.9;

interface IYieldTracker {
    function claim(
        address _account,
        address _receiver
    ) external returns (uint256);

    function updateRewards(address _account) external;

    function getTokensPerInterval() external view returns (uint256);

    function claimable(address _account) external view returns (uint256);
}