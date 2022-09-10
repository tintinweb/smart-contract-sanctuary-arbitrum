// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultUtils.sol";
import "../access/Governable.sol";
import "../tokens/interfaces/IVUSD.sol";

contract VaultUtils is IVaultUtils, Governable {
    using SafeMath for uint256;
    enum Type1  { MARKET, TP, SL, TP_SL }
    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        Type1 postionType;
        uint256 slPrice;
        uint256 tpPrice;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    IVault public vault;
    address public vusd;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;
    uint256 constant feeDivider = 10000;
    uint256 public liquidateThreshold = 9000;
    uint256 public referFee;
    bool internal referEnabled;
    event UpdateThreshold(
        uint256 oldThreshold,
        uint256 newThredhold
    );
    event ChangedReferFee(uint256 referFee);
    event ChangedReferEnabled(bool referEnabled); 
    event TakeVUSDIn(
        address _account, 
        address _refer, 
        uint256 _amount, 
        uint256 _fee
    );
    event TakeVUSDOut(
        address _account, 
        address _refer, 
        uint256 _amount, 
        uint256 _fee
    );
    constructor(address _vault, address _vusd) public {
        vault = IVault(_vault);
        vusd = _vusd;
        referFee = 2000;
        referEnabled = true;
    }

    function updateCumulativeFundingRate(address /* _indexToken */) public override returns (bool) {
        return true;
    }

    function validateIncreasePosition(address /* _account */, address /* _indexToken */, uint256 /* _sizeDelta */, bool /* _isLong */) external override view {
        // no additional validations
    }


    function getPosition(address _account, address _indexToken, bool _isLong) internal view returns (Position memory) {
        Position memory position;
        {
            (uint256 size, uint256 collateral, uint256 averagePrice, uint256 entryFundingRate, /* reserveAmount */, /* realisedPnl */, /* hasProfit */, uint256 lastIncreasedTime) = vault.getPosition(_account, _indexToken, _isLong);
            position.size = size;
            position.collateral = collateral;
            position.averagePrice = averagePrice;
            position.entryFundingRate = entryFundingRate;
            position.lastIncreasedTime = lastIncreasedTime;
        }
        return position;
    }

    function validateLiquidation(address _account, address _indexToken, bool _isLong, bool _raise) public view override returns (uint256, uint256) {
        Position memory position = getPosition(_account, _indexToken, _isLong);
        if (position.averagePrice > 0 ) {
            (bool hasProfit, uint256 delta) = vault.getDelta(_indexToken, position.size, position.averagePrice, _isLong, position.lastIncreasedTime);
            uint256 marginFees = getPositionFee(_account, _indexToken, _isLong, position.size);

            if (!hasProfit && position.collateral < delta) {
                if (_raise) { revert("Vault: losses exceed collateral"); }
                return (1, marginFees);
            }

            uint256 remainingCollateral = position.collateral;
            if (!hasProfit) {
                remainingCollateral = position.collateral.sub(delta);
            }

            if (remainingCollateral < marginFees) {
                if (_raise) { revert("Vault: fees exceed collateral"); }
                // cap the fees to the remainingCollateral
                return (1, remainingCollateral);
            }

            if (remainingCollateral < marginFees.add(vault.liquidationFeeUsd())) {
                if (_raise) { revert("Vault: liquidation fees exceed collateral"); }
                return (1, marginFees);
            }

            if ((remainingCollateral.sub(marginFees.add(vault.liquidationFeeUsd()))).mul(vault.maxLeverage()) < position.size.mul(BASIS_POINTS_DIVISOR)) {
                if (_raise) { revert("Vault: maxLeverage exceeded"); }
                return (2, marginFees.add(vault.liquidationFeeUsd()));
            }

            if (remainingCollateral.sub(marginFees.add(vault.liquidationFeeUsd())) < position.size.mul(BASIS_POINTS_DIVISOR.sub(liquidateThreshold)).div(BASIS_POINTS_DIVISOR)) {
                if (_raise) { revert("Vault: maxThreshold exceeded"); }
                return (2, marginFees.add(vault.liquidationFeeUsd()));
            }

            return (0, marginFees);
        } else {
            return (0, 0);
        }
    }

    function validateTrigger(address _account, address _indexToken, bool _isLong) public view override returns (bool) {
        Position memory position = getPosition(_account, _indexToken, _isLong);
         uint256 price = _isLong ? vault.getMaxPrice(_indexToken) : vault.getMinPrice(_indexToken);
        if (position.tpPrice > 0 && price > position.tpPrice && (position.postionType == Type1.TP || position.postionType == Type1.TP_SL)) {
            return true;
        } else if (position.slPrice > 0 && price < position.slPrice && (position.postionType == Type1.SL || position.postionType == Type1.TP_SL)) {
            return true;
        } else {
            return false;
        }
    }
 
    function getFundingFee(address /* _account */, address /* _indexToken */, bool /* _isLong */, uint256 _size, uint256 _entryFundingRate) public override view returns (uint256) {
        if (_size == 0) { return 0; }

        uint256 fundingRate = vault.cumulativeFundingRates().sub(_entryFundingRate);
        if (fundingRate == 0) { return 0; }

        return _size.mul(fundingRate).div(FUNDING_RATE_PRECISION);
    }

    function getPositionFee(address /* _account */, address /* _indexToken */, bool /* _isLong */, uint256 _sizeDelta) public override view returns (uint256) {
        if (_sizeDelta == 0) { return 0; }
        uint256 afterFeeUsd = _sizeDelta.mul(BASIS_POINTS_DIVISOR.sub(vault.marginFeeBasisPoints())).div(BASIS_POINTS_DIVISOR);
        return _sizeDelta.sub(afterFeeUsd);
    }

    function setLiquidateThreshold(uint256 _newThreshold) public onlyGov {
        emit UpdateThreshold(liquidateThreshold, _newThreshold);
        liquidateThreshold = _newThreshold;
    }

    function takeVUSDIn(address _account, address _refer, uint256 _amount, uint256 _fee) external override {
        IVUSD(vusd).burn(_account, _amount);
        if (referEnabled) {
            if (_refer == address(0)) {
                IVUSD(vusd).mint(address(vault), _amount);
            } else {
                IVUSD(vusd).mint(_refer, _fee.mul(referFee).div(feeDivider));
                IVUSD(vusd).mint(address(vault), _amount.sub(_fee.mul(referFee).div(feeDivider)));
            }
        } else {
            IVUSD(vusd).mint(address(vault), _amount);
        }
        emit TakeVUSDIn(_account, _refer, _amount, _fee);
    }

    function takeVUSDOut(address _account, address _refer, uint256 _amount, uint256 _fee) external override {
        if (referEnabled) {
            if (_refer == address(0)) {
                IVUSD(vusd).burn(address(vault), _amount.sub(_fee));
                IVUSD(vusd).mint(_account, _amount.sub(_fee));
            } else {
                IVUSD(vusd).burn(address(vault), _amount.sub(_fee.mul(feeDivider.sub(referFee)).div(feeDivider)));
                IVUSD(vusd).mint(_refer, _fee.mul(referFee).div(feeDivider));
                IVUSD(vusd).mint(_account, _amount.sub(_fee));
            }
        } else {
            IVUSD(vusd).burn(address(vault), _amount.sub(_fee));
            IVUSD(vusd).mint(_account, _amount.sub(_fee));
        }
        emit TakeVUSDOut(_account, _refer, _amount, _fee);
    }


    function setReferFee(uint256 _fee) external onlyGov {
        require(_fee <= feeDivider, "fee should be smaller than feeDivider");
        referFee = _fee;
        emit ChangedReferFee(_fee);
    }

    function setReferEnabled(bool _referEnabled) external onlyGov {
        referEnabled = _referEnabled;
        emit ChangedReferEnabled(referEnabled);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVault {
    function isInitialized() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);
    function router() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
     function getNextFundingRate() external view returns (uint256);
    function lastFundingTimes() external view returns (uint256);
    function reservedAmounts() external view returns (uint256);
    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _minProfitBps,
        bool _isStable,
        bool _isShortable
    ) external;
    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function increasePosition(address _account, address _indexToken, uint256 _amountIn, uint256 _sizeDelta, bool _isLong, uint256[] memory triggerPrices, address _refer) external;
    function decreasePosition(address _account, address _indexToken, uint256 _sizeDelta, bool _isLong) external returns (uint256);
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates() external view returns (uint256);
    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function feeRewardBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves() external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function poolAmounts() external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultUtils {
    function updateCumulativeFundingRate(address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateTrigger(address _account, address _indexToken, bool _isLong) external view returns (bool);
    function validateLiquidation(address _account, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getPositionFee(address _account, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function takeVUSDIn(address _account, address _refer, uint256 _amount, uint256 _fee) external;
    function takeVUSDOut(address _account, address _refer, uint256 _amount, uint256 _fee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVUSD {
    function balanceOf(address _account) external view returns (uint256);
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}