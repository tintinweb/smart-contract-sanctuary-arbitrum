// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

pragma solidity ^0.8.9;

import "./IVault.sol";

interface ILpManager {
    function plpToken() external view returns (address);

    function usdp() external view returns (address);

    function vault() external view returns (IVault);

    function getAumInUsdp(bool maximise) external view returns (uint256);

    function lastAddedAt(address _account) external returns (uint256);

    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external returns (uint256);

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external returns (uint256);

    function removeLiquidity(
        address _tokenOut,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function cooldownDuration() external view returns (uint256);

    /* Owner function */
    function setShortsTrackerAveragePriceWeight(
        uint256 _shortsTrackerAveragePriceWeight
    ) external;

    function setCooldownDuration(uint256 _cooldownDuration) external;
}

pragma solidity ^0.8.9;

interface IMintable {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

pragma solidity ^0.8.9;

interface IShortsTracker {
    function isGlobalShortDataReady() external view returns (bool);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function getNextGlobalShortData(
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        bool _isIncrease
    ) external view returns (uint256, uint256);

    function updateGlobalShortData(
        address _indexToken,
        uint256 _sizeDelta,
        uint256 _markPrice,
        bool _isIncrease
    ) external;

    function setIsGlobalShortDataReady(bool value) external;

    function setInitData(
        address[] calldata _tokens,
        uint256[] calldata _averagePrices
    ) external;
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

pragma solidity ^0.8.9;

import "../interfaces/ILpManager.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IMintable.sol";
import "../interfaces/IShortsTracker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LpManager is ILpManager, Ownable {
    using SafeMath for uint256;
    IERC20 private _plpToken;
    IERC20 private _usdp;
    IVault public vault;
    IShortsTracker public shortsTracker;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant USDG_DECIMALS = 18;
    uint256 public constant GLP_PRECISION = 10 ** 18;
    uint256 public constant MAX_COOLDOWN_DURATION = 48 hours;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public aumAddition;
    uint256 public aumDeduction;
    uint256 public shortsTrackerAveragePriceWeight;

    uint256 public cooldownDuration;
    mapping(address => uint256) public override lastAddedAt;
    mapping(address => bool) public isHandler;

    event AddLiquidity(
        address account,
        address token,
        uint256 amount,
        uint256 aumInUsdg,
        uint256 glpSupply,
        uint256 usdgAmount,
        uint256 mintAmount
    );

    event RemoveLiquidity(
        address account,
        address token,
        uint256 glpAmount,
        uint256 aumInUsdg,
        uint256 glpSupply,
        uint256 usdgAmount,
        uint256 amountOut
    );

    modifier onlyHandler() {
        require(isHandler[msg.sender], "LpManager: only handler");
        _;
    }

    constructor(
        IERC20 plpToken_,
        IERC20 usdp_,
        IVault vault_,
        address shortsTracker_,
        uint256 cooldownDuration_
    ) {
        _plpToken = plpToken_;
        _usdp = usdp_;
        vault = vault_;
        shortsTracker = IShortsTracker(shortsTracker_);
        cooldownDuration = cooldownDuration_;
    }

    function setAumAdjustment(
        uint256 _aumAddition,
        uint256 _aumDeduction
    ) external onlyOwner {
        aumAddition = _aumAddition;
        aumDeduction = _aumDeduction;
    }

    function setVault(address _vault) external onlyOwner {
        vault = IVault(_vault);
    }

    function setCooldownDuration(uint256 _cooldownDuration) external onlyOwner {
        require(
            _cooldownDuration <= MAX_COOLDOWN_DURATION,
            "LpManager: invalid _cooldownDuration"
        );
        cooldownDuration = _cooldownDuration;
    }

    function setHandler(address _handler, bool _isActive) external onlyOwner {
        isHandler[_handler] = _isActive;
    }

    function setGov(address _gov) external onlyOwner {
        _transferOwnership(_gov);
    }

    /**
     * @notice Calculates the assets under management (AUM) of a vault in terms of USDP
     * @param maximise A boolean value indicating whether to use the maximum or minimum price for each token
     * @return The calculated AUM value in USDP as a uint256
     */
    function getAumInUsdp(
        bool maximise
    ) external view override returns (uint256) {
        uint256 aum = getAum(maximise);
        return aum.mul(10 ** USDG_DECIMALS).div(PRICE_PRECISION);
    }

    /**
     * @notice Calculates the assets under management (AUM) of a vault
     * @param maximise A boolean value indicating whether to use the maximum or minimum price for each token
     * @return The calculated AUM value as a uint256
     */
    function getAum(bool maximise) public view returns (uint256) {
        uint256 length = vault.allWhitelistedTokensLength();
        uint256 aum = aumAddition;
        uint256 shortProfits = 0;
        IVault _vault = vault;

        for (uint256 i = 0; i < length; i++) {
            address token = vault.allWhitelistedTokens(i);
            bool isWhitelisted = vault.isWhitelistedTokens(token);

            if (!isWhitelisted) {
                continue;
            }

            uint256 price = maximise
                ? _vault.getMaxPrice(token)
                : _vault.getMinPrice(token);
            uint256 poolAmount = _vault.poolAmounts(token);
            uint256 decimals = _vault.tokenDecimals(token);

            if (_vault.stableTokens(token)) {
                aum = aum.add(poolAmount.mul(price).div(10 ** decimals));
            } else {
                // add global short profit / loss
                uint256 size = _vault.globalShortSizes(token);

                if (size > 0) {
                    (uint256 delta, bool hasProfit) = getGlobalShortDelta(
                        token,
                        price,
                        size
                    );
                    if (!hasProfit) {
                        // add losses from shorts
                        aum = aum.add(delta);
                    } else {
                        shortProfits = shortProfits.add(delta);
                    }
                }

                aum = aum.add(_vault.guaranteedUsd(token));

                uint256 reservedAmount = _vault.reservedAmounts(token);
                aum = aum.add(
                    poolAmount.sub(reservedAmount).mul(price).div(
                        10 ** decimals
                    )
                );
            }
        }

        aum = shortProfits > aum ? 0 : aum.sub(shortProfits);
        return aumDeduction > aum ? 0 : aum.sub(aumDeduction);
    }

    function getGlobalShortDelta(
        address _token,
        uint256 _price,
        uint256 _size
    ) public view returns (uint256, bool) {
        uint256 averagePrice = getGlobalShortAveragePrice(_token);
        uint256 priceDelta = averagePrice > _price
            ? averagePrice.sub(_price)
            : _price.sub(averagePrice);
        uint256 delta = _size.mul(priceDelta).div(averagePrice);
        return (delta, averagePrice > _price);
    }

    function getGlobalShortAveragePrice(
        address _token
    ) public view returns (uint256) {
        IShortsTracker _shortsTracker = shortsTracker;
        if (
            address(_shortsTracker) == address(0) ||
            !_shortsTracker.isGlobalShortDataReady()
        ) {
            return vault.globalShortAveragePrices(_token);
        }

        uint256 _shortsTrackerAveragePriceWeight = shortsTrackerAveragePriceWeight;
        if (_shortsTrackerAveragePriceWeight == 0) {
            return vault.globalShortAveragePrices(_token);
        } else if (_shortsTrackerAveragePriceWeight == BASIS_POINTS_DIVISOR) {
            return _shortsTracker.globalShortAveragePrices(_token);
        }

        uint256 vaultAveragePrice = vault.globalShortAveragePrices(_token);
        uint256 shortsTrackerAveragePrice = _shortsTracker
            .globalShortAveragePrices(_token);

        return
            vaultAveragePrice
                .mul(BASIS_POINTS_DIVISOR.sub(_shortsTrackerAveragePriceWeight))
                .add(
                    shortsTrackerAveragePrice.mul(
                        _shortsTrackerAveragePriceWeight
                    )
                )
                .div(BASIS_POINTS_DIVISOR);
    }

    /// @notice Add liquidity for caller. Caller pay `_token`, receive back PLP token
    /// @param _token the pay token. eg BUSD
    /// @param _amount the amount in pay token in wei. eg 10 * 10e18
    /// @param _minUsdp min usdp in wei, the contract will revert if _minUsdp is not met
    /// @param _minPlp min plp amount in wei, the contract will revert if _minPlp is not met
    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external override returns (uint256) {
        return
            _addLiquidity(
                msg.sender,
                msg.sender,
                _token,
                _amount,
                _minUsdp,
                _minPlp
            );
    }

    /// @notice add liquidity for an account, only whitelist handler can call
    /// @param _fundingAccount funding account
    /// @param _account credit account
    /// @param _token the pay token. eg BUSD
    /// @param _amount the amount in pay token in wei. eg 10 * 10e18
    /// @param _minUsdp min usdp in wei, the contract will revert if _minUsdp is not met
    /// @param _minPlp min plp amount in wei, the contract will revert if _minPlp is not met
    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external override onlyHandler returns (uint256) {
        return
            _addLiquidity(
                _fundingAccount,
                _account,
                _token,
                _amount,
                _minUsdp,
                _minPlp
            );
    }

    /// @notice Remove liquidity for caller
    /// Transfer back the tokenOut
    /// @param _tokenOut the receive token
    /// @param _plpAmount plp amount to remove
    /// @param _minOut minimum amount acceptable. otherwise will revert
    /// @param _receiver the addres of receiver
    function removeLiquidity(
        address _tokenOut,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external override returns (uint256) {
        return
            _removeLiquidity(
                msg.sender,
                _tokenOut,
                _plpAmount,
                _minOut,
                _receiver
            );
    }

    /// @notice Remove liquidity for account
    /// Transfer back the tokenOut
    /// @param _account the affected account
    /// @param _tokenOut the receive token
    /// @param _plpAmount plp amount to remove
    /// @param _minOut minimum amount acceptable. otherwise will revert
    /// @param _receiver the addres of receiver
    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external override onlyHandler returns (uint256) {
        return
            _removeLiquidity(
                _account,
                _tokenOut,
                _plpAmount,
                _minOut,
                _receiver
            );
    }

    function setShortsTrackerAveragePriceWeight(
        uint256 _shortsTrackerAveragePriceWeight
    ) external override {
        // TODO imp. this
        revert("LpManager: setShortsTrackerAveragePriceWeight not implemented");
    }

    /**
     * @notice Calculates the total asset value of a vault in terms of USDP
     * @param maximise A boolean value indicating whether to use the maximum or minimum price for each token
     * @return The calculated total asset value in USDP as a uint256
     */
    function getTotalAssetValueInUsdp(
        bool maximise
    ) public view returns (uint256) {
        uint256 aum = getAum(maximise);
        return aum.mul(10 ** USDG_DECIMALS).div(PRICE_PRECISION);
    }

    function _addLiquidity(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minGlp
    ) private returns (uint256) {
        require(_amount > 0, "LpManager: invalid _amount");

        // calculate aum before buyUSDG
        uint256 aumInUsdp = getTotalAssetValueInUsdp(true);
        uint256 plpSupply = _plpToken.totalSupply();

        IERC20(_token).transferFrom(_fundingAccount, address(vault), _amount);
        uint256 usdpAmount = vault.buyUSDP(_token, address(this));
        require(usdpAmount >= _minUsdp, "LpManager: insufficient _usdp output");
        uint256 mintAmount = aumInUsdp == 0
            ? usdpAmount
            : usdpAmount.mul(plpSupply).div(aumInUsdp);
        require(mintAmount >= _minGlp, "LpManager: insufficient PLP output");

        IMintable(address(_plpToken)).mint(_account, mintAmount);

        lastAddedAt[_account] = block.timestamp;
        emit AddLiquidity(
            _account,
            _token,
            _amount,
            aumInUsdp,
            plpSupply,
            usdpAmount,
            mintAmount
        );
        return mintAmount;
    }

    function _removeLiquidity(
        address _account,
        address _tokenOut,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) private returns (uint256) {
        require(_plpAmount > 0, "LpManager: invalid _glpAmount");
        require(
            lastAddedAt[_account].add(cooldownDuration) <= block.timestamp,
            "LpManager: cooldown duration not yet passed"
        );

        // calculate aum before sellUSDG
        uint256 aumInUsdp = getTotalAssetValueInUsdp(false);
        uint256 plpSupply = _plpToken.totalSupply();

        uint256 usdpAmount = _plpAmount.mul(aumInUsdp).div(plpSupply);
        uint256 usdpBalance = _usdp.balanceOf(address(this));
        if (usdpAmount > usdpBalance) {
            IMintable(address(_usdp)).mint(
                address(this),
                usdpAmount.sub(usdpBalance)
            );
        }

        IMintable(address(_plpToken)).burn(_account, _plpAmount);

        _usdp.transfer(address(vault), usdpAmount);
        uint256 amountOut = vault.sellUSDP(_tokenOut, _receiver);
        require(amountOut >= _minOut, "LpManager: insufficient output");

        emit RemoveLiquidity(
            _account,
            _tokenOut,
            _plpAmount,
            aumInUsdp,
            plpSupply,
            usdpAmount,
            amountOut
        );

        return amountOut;
    }

    function plpToken() external view override returns (address) {
        return address(_plpToken);
    }

    function usdp() external view override returns (address) {
        return address(_usdp);
    }
}