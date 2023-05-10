/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT,
    TRAILING_STOP
}

enum OrderStatus {
    NONE,
    PENDING,
    FILLED,
    CANCELED
}

enum PositionStatus {
    NONE,
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    OPEN,
    TRIGGERED,
    CANCELLED
}

struct ConfirmInfo {
    bool confirmDelayStatus;
    uint256 pendingDelayCollateral;
    uint256 pendingDelaySize;
    uint256 delayStartTime;
}

struct OrderInfo {
    OrderStatus status;
    uint256 lmtPrice;
    uint256 pendingSize;
    uint256 pendingCollateral;
    uint256 positionType;
    uint256 stepAmount;
    uint256 stepType;
    uint256 stpPrice;
}

struct Position {
    address owner;
    address refer;
    int256 realisedPnl;
    uint256 averagePrice;
    uint256 collateral;
    uint256 entryFundingRate;
    uint256 lastIncreasedTime;
    uint256 lastPrice;
    uint256 reserveAmount;
    uint256 size;
}

struct TriggerOrder {
    bytes32 key;
    uint256[] slPrices;
    uint256[] slAmountPercents;
    uint256[] slTriggeredAmounts;
    uint256[] tpPrices;
    uint256[] tpAmountPercents;
    uint256[] tpTriggeredAmounts;
    TriggerStatus status;
}


contract Constants {
    address public constant ZERO_ADDRESS = address(0);
    uint8 public constant ORDER_FILLED = 1;
    uint8 public constant ORDER_NOT_FILLED = 0;
    uint8 public constant STAKING_PID_FOR_CHARGE_FEE = 1;
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;
    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    uint256 public constant DEFAULT_MAX_OPEN_INTEREST = 10000000000 * PRICE_PRECISION;
    uint256 public constant DEFAULT_ALP_PRICE = 100000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_DELTA_TIME = 24 hours;
    uint256 public constant MAX_COOLDOWN_DURATION = 48 hours;
    uint256 public constant MAX_FEE_BASIS_POINTS = 5000; // 5%
    uint256 public constant MAX_FEE_REWARD_BASIS_POINTS = BASIS_POINTS_DIVISOR; // 100%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_STAKING_FEE = 10000; // 10%
    uint256 public constant MAX_TOKENFARM_COOLDOWN_DURATION = 4 weeks;
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;
    uint256 public constant MAX_VESTING_DURATION = 700 days;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%
    uint256 public constant POSITION_MARKET = 0;
    uint256 public constant POSITION_LIMIT = 1;
    uint256 public constant POSITION_STOP_MARKET = 2;
    uint256 public constant POSITION_STOP_LIMIT = 3;
    uint256 public constant POSITION_TRAILING_STOP = 4;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 public constant TRAILING_STOP_TYPE_PERCENT = 1;
    uint256 public constant ALP_DECIMALS = 18;

    function _getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isLong, _posId));
    }

    function checkSlippage(
        bool isLong,
        uint256 expectedMarketPrice,
        uint256 slippageBasisPoints,
        uint256 actualMarketPrice
    ) internal pure {
        if (isLong) {
            require(
                actualMarketPrice <=
                    (expectedMarketPrice * (BASIS_POINTS_DIVISOR + slippageBasisPoints)) / BASIS_POINTS_DIVISOR,
                "slippage exceeded"
            );
        } else {
            require(
                (expectedMarketPrice * (BASIS_POINTS_DIVISOR - slippageBasisPoints)) / BASIS_POINTS_DIVISOR <=
                    actualMarketPrice,
                "slippage exceeded"
            );
        }
    }
}



interface ITriggerOrderManager {
    function executeTriggerOrders(
        address _account,
        address _token,
        bool _isLong,
        uint256 _posId
    ) external returns (bool, uint256);

    function validateTPSLTriggers(
        address _account,
        address _token,
        bool _isLong,
        uint256 _posId
    ) external view returns (bool);
}


interface IVaultUtils {
    function emitClosePositionEvent(address _account, address _indexToken, bool _isLong, uint256 _posId) external;

    function emitDecreasePositionEvent(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _sizeDelta,
        uint256 _fee
    ) external;

    function emitIncreasePositionEvent(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external;

    function emitLiquidatePositionEvent(address _account, address _indexToken, bool _isLong, uint256 _posId) external;

    function validateConfirmDelay(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) external view returns (bool);

    function validateDecreasePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) external view returns (bool);

    function validateLiquidation(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) external view returns (uint256, uint256);

    function validatePosData(
        bool _isLong,
        address _indexToken,
        OrderType _orderType,
        uint256[] memory _params,
        bool _raise
    ) external view returns (bool);

    function validateSizeCollateralAmount(uint256 _size, uint256 _collateral) external view;

    function validateTrailingStopInputData(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params
    ) external view returns (bool);

    function validateTrailingStopPrice(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) external view returns (bool);

    function validateTrigger(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view returns (uint8);
}


interface IVault {
    function accountDeltaAndFeeIntoTotalUSDC(bool _hasProfit, uint256 _adjustDelta, uint256 _fee) external;

    function distributeFee(address _account, address _refer, uint256 _fee) external;

    function takeVUSDIn(address _account, address _refer, uint256 _amount, uint256 _fee) external;

    function takeVUSDOut(address _account, address _refer, uint256 _fee, uint256 _usdOut) external;

    function transferBounty(address _account, uint256 _amount) external;
}


interface ISettingsManager {
    function decreaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function updateCumulativeFundingRate(address _token, bool _isLong) external;

    function openInterestPerAsset(address _token) external view returns (uint256);

    function openInterestPerSide(bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint256);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function closeDeltaTime() external view returns (uint256);

    function collectMarginFees(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function cumulativeFundingRates(address _token, bool _isLong) external view returns (uint256);

    function delayDeltaTime() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function feeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function fundingRateFactor(address _token, bool _isLong) external view returns (uint256);

    function getFundingFee(
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isDeposit(address _token) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function isStaking(address _token) external view returns (bool);

    function lastFundingTimes(address _token, bool _isLong) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function liquidateThreshold(address) external view returns (uint256);

    function marginFeeBasisPoints(address _token, bool _isLong) external view returns (uint256);

    function marketOrderEnabled() external view returns (bool);
    function pauseForexForCloseTime() external view returns (bool);

    function positionManager() external view returns (address);

    function priceMovementPercent() external view returns (uint256);

    function referFee() external view returns (uint256);

    function referEnabled() external view returns (bool);

    function stakingFee() external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function validatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _collateral
    ) external view;
}


interface IPriceManager {
    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong
    ) external view returns (bool, uint256);

    function getLastPrice(address _token) external view returns (uint256);

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) external view returns (uint256);
    function isForex(address _token) external view returns (bool);
    function maxLeverage(address _token) external view returns (uint256);

    function usdToToken(address _token, uint256 _usdAmount) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenToUsd(address _token, uint256 _tokenAmount) external view returns (uint256);
}


interface IPositionVault {
    function addOrRemoveCollateral(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool isPlus,
        uint256 _amount
    ) external;

    function addPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) external;

    function addTrailingStop(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params
    ) external;

    function cancelPendingOrder(address _account, address _indexToken, bool _isLong, uint256 _posId) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _posId
    ) external;

    function newPositionOrder(
        address _account,
        address _indexToken,
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address _refer
    ) external;

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view returns (Position memory, OrderInfo memory, ConfirmInfo memory);

    function poolAmounts(address _token, bool _isLong) external view returns (uint256);

    function reservedAmounts(address _token, bool _isLong) external view returns (uint256);
}


interface IVUSDC {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function balanceOf(address _account) external view returns (uint256);
}


interface IMintable {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function setMinter(address _minter, bool _isActive) external;

    function isMinter(address _account) external returns (bool);
}


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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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


/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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


contract PositionVault is Constants, ReentrancyGuard, IPositionVault {
    uint256 public lastPosId;
    IPriceManager private priceManager;
    ISettingsManager private settingsManager;
    ITriggerOrderManager private triggerOrderManager;
    IVault private vault;
    IVaultUtils private vaultUtils;

    bool private isInitialized;
    mapping(address => mapping(bool => uint256)) public override poolAmounts;
    mapping(address => mapping(bool => uint256)) public override reservedAmounts;
    mapping(bytes32 => Position) public positions;
    mapping(bytes32 => ConfirmInfo) public confirms;
    mapping(bytes32 => OrderInfo) public orders;
    event AddOrRemoveCollateral(
        bytes32 indexed key,
        bool isPlus,
        uint256 amount,
        uint256 reserveAmount,
        uint256 collateral,
        uint256 size
    );
    event AddPosition(bytes32 indexed key, bool confirmDelayStatus, uint256 collateral, uint256 size);
    event AddTrailingStop(bytes32 key, uint256[] data);
    event ConfirmDelayTransaction(
        bytes32 indexed key,
        bool confirmDelayStatus,
        uint256 collateral,
        uint256 size,
        uint256 feeUsd
    );
    event DecreasePoolAmount(address indexed token, bool isLong, uint256 amount);
    event DecreaseReservedAmount(address indexed token, bool isLong, uint256 amount);
    event IncreasePoolAmount(address indexed token, bool isLong, uint256 amount);
    event IncreaseReservedAmount(address indexed token, bool isLong, uint256 amount);
    event NewOrder(
        bytes32 key,
        address indexed account,
        address indexToken,
        bool isLong,
        uint256 posId,
        uint256 positionType,
        OrderStatus orderStatus,
        uint256[] triggerData
    );
    event UpdateOrder(bytes32 key, uint256 positionType, OrderStatus orderStatus);
    event UpdatePoolAmount(address indexed token, bool isLong, uint256 amount);
    event UpdateReservedAmount(address indexed token, bool isLong, uint256 amount);
    event UpdateTrailingStop(bytes32 key, uint256 stpPrice);
    modifier onlyVault() {
        require(msg.sender == address(vault), "Only vault has access");
        _;
    }

    constructor() {}

    function addOrRemoveCollateral(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool isPlus,
        uint256 _amount
    ) external override onlyVault {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        Position storage position = positions[key];
        if (isPlus) {
            position.collateral += _amount;
            vaultUtils.validateSizeCollateralAmount(position.size, position.collateral);
            position.reserveAmount += _amount;
            vault.takeVUSDIn(_account, position.refer, _amount, 0);
            _increasePoolAmount(_indexToken, _isLong, _amount);
        } else {
            position.collateral -= _amount;
            vaultUtils.validateSizeCollateralAmount(position.size, position.collateral);
            vaultUtils.validateLiquidation(_account, _indexToken, _isLong, _posId, true);
            position.reserveAmount -= _amount;
            position.lastIncreasedTime = block.timestamp;
            vault.takeVUSDOut(_account, position.refer, 0, _amount);
            _decreasePoolAmount(_indexToken, _isLong, _amount);
        }
        emit AddOrRemoveCollateral(key, isPlus, _amount, position.reserveAmount, position.collateral, position.size);
    }

    function addPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) external override onlyVault {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        ConfirmInfo storage confirm = confirms[key];
        confirm.delayStartTime = block.timestamp;
        confirm.confirmDelayStatus = true;
        confirm.pendingDelayCollateral = _collateralDelta;
        confirm.pendingDelaySize = _sizeDelta;
        emit AddPosition(key, confirm.confirmDelayStatus, _collateralDelta, _sizeDelta);
    }

    function addTrailingStop(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params
    ) external override onlyVault {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        OrderInfo storage order = orders[key];
        vaultUtils.validateTrailingStopInputData(_account, _indexToken, _isLong, _posId, _params);
        order.pendingCollateral = _params[0];
        order.pendingSize = _params[1];
        order.status = OrderStatus.PENDING;
        order.positionType = POSITION_TRAILING_STOP;
        order.stepType = _params[2];
        order.stpPrice = _params[3];
        order.stepAmount = _params[4];
        emit AddTrailingStop(key, _params);
    }

    function cancelPendingOrder(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external override onlyVault {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        OrderInfo storage order = orders[key];
        require(order.status == OrderStatus.PENDING, "Not in Pending");
        if (order.positionType == POSITION_TRAILING_STOP) {
            order.status = OrderStatus.FILLED;
            order.positionType = POSITION_MARKET;
        } else {
            order.status = OrderStatus.CANCELED;
        }
        order.pendingCollateral = 0;
        order.pendingSize = 0;
        order.lmtPrice = 0;
        order.stpPrice = 0;
        emit UpdateOrder(key, order.positionType, order.status);
    }

    function confirmDelayTransaction(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external nonReentrant {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        Position storage position = positions[key];
        require(position.owner == msg.sender || settingsManager.isManager(msg.sender), "not allowed");
        ConfirmInfo storage confirm = confirms[key];
        vaultUtils.validateConfirmDelay(_account, _indexToken, _isLong, _posId, true);
        uint256 fee = settingsManager.collectMarginFees(
            _account,
            _indexToken,
            _isLong,
            confirm.pendingDelaySize,
            position.size,
            position.entryFundingRate
        );
        _increasePosition(
            _account,
            _indexToken,
            confirm.pendingDelayCollateral + fee,
            confirm.pendingDelaySize,
            _posId,
            _isLong,
            position.refer
        );
        confirm.confirmDelayStatus = false;
        confirm.pendingDelayCollateral = 0;
        confirm.pendingDelaySize = 0;
        emit ConfirmDelayTransaction(
            key,
            confirm.confirmDelayStatus,
            confirm.pendingDelayCollateral,
            confirm.pendingDelaySize,
            fee
        );
    }

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _posId
    ) external override onlyVault {
        _decreasePosition(_account, _indexToken, _sizeDelta, _isLong, _posId);
    }

    function initialize(
        IPriceManager _priceManager,
        ISettingsManager _settingsManager,
        ITriggerOrderManager _triggerOrderManager,
        IVault _vault,
        IVaultUtils _vaultUtils
    ) external {
        require(!isInitialized, "Not initialized");
        require(Address.isContract(address(_priceManager)), "priceManager address is invalid");
        require(Address.isContract(address(_settingsManager)), "settingsManager address is invalid");
        require(Address.isContract(address(_triggerOrderManager)), "triggerOrderManager address is invalid");
        require(Address.isContract(address(_vault)), "vault address is invalid");
        require(Address.isContract(address(_vaultUtils)), "vaultUtils address is invalid");
        priceManager = _priceManager;
        settingsManager = _settingsManager;
        triggerOrderManager = _triggerOrderManager;
        vault = _vault;
        vaultUtils = _vaultUtils;
        isInitialized = true;
    }

    function liquidatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external nonReentrant {
        settingsManager.updateCumulativeFundingRate(_indexToken, _isLong);
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        Position memory position = positions[key];
        (uint256 liquidationState, uint256 marginFees) = vaultUtils.validateLiquidation(
            _account,
            _indexToken,
            _isLong,
            _posId,
            false
        );
        require(liquidationState != LIQUIDATE_NONE_EXCEED, "not exceed or allowed");
        if (liquidationState == LIQUIDATE_THRESHOLD_EXCEED) {
            // max leverage exceeded but there is collateral remaining after deducting losses so decreasePosition instead
            _decreasePosition(_account, _indexToken, position.size, _isLong, _posId);
            return;
        }
        vault.accountDeltaAndFeeIntoTotalUSDC(true, 0, marginFees);
        uint256 bounty = (marginFees * settingsManager.bountyPercent()) / BASIS_POINTS_DIVISOR;
        vault.transferBounty(msg.sender, bounty);
        settingsManager.decreaseOpenInterest(_indexToken, _account, _isLong, position.size);
        _decreasePoolAmount(_indexToken, _isLong, marginFees);
        vaultUtils.emitLiquidatePositionEvent(_account, _indexToken, _isLong, _posId);
        delete positions[key];
        // pay the fee receive using the pool, we assume that in general the liquidated amount should be sufficient to cover
        // the liquidation fees
    }

    function newPositionOrder(
        address _account,
        address _indexToken,
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address _refer
    ) external nonReentrant onlyVault {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, lastPosId);
        OrderInfo storage order = orders[key];
        Position storage position = positions[key];
        vaultUtils.validatePosData(_isLong, _indexToken, _orderType, _params, true);
        order.pendingCollateral = _params[2];
        order.pendingSize = _params[3];
        position.owner = _account;
        position.refer = _refer;
        if (_orderType == OrderType.MARKET) {
            require(settingsManager.marketOrderEnabled(), "market order was disabled");
            order.positionType = POSITION_MARKET;
            uint256 fee = settingsManager.collectMarginFees(
                _account,
                _indexToken,
                _isLong,
                order.pendingSize,
                position.size,
                position.entryFundingRate
            );
            _increasePosition(_account, _indexToken, _params[2] + fee, order.pendingSize, lastPosId, _isLong, _refer);
            order.pendingCollateral = 0;
            order.pendingSize = 0;
            order.status = OrderStatus.FILLED;
        } else if (_orderType == OrderType.LIMIT) {
            order.status = OrderStatus.PENDING;
            order.positionType = POSITION_LIMIT;
            order.lmtPrice = _params[0];
        } else if (_orderType == OrderType.STOP) {
            order.status = OrderStatus.PENDING;
            order.positionType = POSITION_STOP_MARKET;
            order.stpPrice = _params[1];
        } else if (_orderType == OrderType.STOP_LIMIT) {
            order.status = OrderStatus.PENDING;
            order.positionType = POSITION_STOP_LIMIT;
            order.lmtPrice = _params[0];
            order.stpPrice = _params[1];
        }
        lastPosId += 1;
        emit NewOrder(key, _account, _indexToken, _isLong, lastPosId - 1, order.positionType, order.status, _params);
    }

    function triggerPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external nonReentrant {
        settingsManager.updateCumulativeFundingRate(_indexToken, _isLong);
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        Position memory position = positions[key];
        OrderInfo storage order = orders[key];
        uint8 statusFlag = vaultUtils.validateTrigger(_account, _indexToken, _isLong, _posId);
        (bool hitTrigger, uint256 triggerAmountPercent) = triggerOrderManager.executeTriggerOrders(
            _account,
            _indexToken,
            _isLong,
            _posId
        );
        require(
            (statusFlag == ORDER_FILLED || hitTrigger) &&
                (position.owner == msg.sender || settingsManager.isManager(msg.sender)),
            "trigger not ready"
        );
        if (hitTrigger) {
            _decreasePosition(
                _account,
                _indexToken,
                (position.size * (triggerAmountPercent)) / BASIS_POINTS_DIVISOR,
                _isLong,
                _posId
            );
        }
        if (statusFlag == ORDER_FILLED) {
            if (order.positionType == POSITION_LIMIT) {
                uint256 fee = settingsManager.collectMarginFees(
                    _account,
                    _indexToken,
                    _isLong,
                    order.pendingSize,
                    position.size,
                    position.entryFundingRate
                );
                _increasePosition(
                    _account,
                    _indexToken,
                    order.pendingCollateral + fee,
                    order.pendingSize,
                    _posId,
                    _isLong,
                    position.refer
                );
                order.pendingCollateral = 0;
                order.pendingSize = 0;
                order.status = OrderStatus.FILLED;
            } else if (order.positionType == POSITION_STOP_MARKET) {
                uint256 fee = settingsManager.collectMarginFees(
                    _account,
                    _indexToken,
                    _isLong,
                    order.pendingSize,
                    position.size,
                    position.entryFundingRate
                );
                _increasePosition(
                    _account,
                    _indexToken,
                    order.pendingCollateral + fee,
                    order.pendingSize,
                    _posId,
                    _isLong,
                    position.refer
                );
                order.pendingCollateral = 0;
                order.pendingSize = 0;
                order.status = OrderStatus.FILLED;
            } else if (order.positionType == POSITION_STOP_LIMIT) {
                order.positionType = POSITION_LIMIT;
            } else if (order.positionType == POSITION_TRAILING_STOP) {
                _decreasePosition(_account, _indexToken, order.pendingSize, _isLong, _posId);
                order.positionType = POSITION_MARKET;
                order.pendingCollateral = 0;
                order.pendingSize = 0;
                order.status = OrderStatus.FILLED;
            }
        }
        emit UpdateOrder(key, order.positionType, order.status);
    }

    function updateTrailingStop(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external nonReentrant {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        Position storage position = positions[key];
        OrderInfo storage order = orders[key];
        uint256 price = priceManager.getLastPrice(_indexToken);
        require(position.owner == msg.sender || settingsManager.isManager(msg.sender), "updateTStop not allowed");
        vaultUtils.validateTrailingStopPrice(_account, _indexToken, _isLong, _posId, true);
        if (_isLong) {
            order.stpPrice = order.stepType == 0
                ? price - order.stepAmount
                : (price * (BASIS_POINTS_DIVISOR - order.stepAmount)) / BASIS_POINTS_DIVISOR;
        } else {
            order.stpPrice = order.stepType == 0
                ? price + order.stepAmount
                : (price * (BASIS_POINTS_DIVISOR + order.stepAmount)) / BASIS_POINTS_DIVISOR;
        }
        emit UpdateTrailingStop(key, order.stpPrice);
    }

    function _decreasePoolAmount(address _indexToken, bool _isLong, uint256 _amount) internal {
        require(poolAmounts[_indexToken][_isLong] >= _amount, "Vault: poolAmount exceeded");
        poolAmounts[_indexToken][_isLong] -= _amount;
        emit DecreasePoolAmount(_indexToken, _isLong, poolAmounts[_indexToken][_isLong]);
    }

    function _decreasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _posId
    ) internal {
        settingsManager.updateCumulativeFundingRate(_indexToken, _isLong);
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        Position storage position = positions[key];
        address _refer = position.refer;
        require(position.size > 0, "position size is zero");
        settingsManager.decreaseOpenInterest(
            _indexToken,
            _account,
            _isLong,
            _sizeDelta
        );
        _decreaseReservedAmount(_indexToken, _isLong, _sizeDelta);
        position.reserveAmount -= (position.reserveAmount * _sizeDelta) / position.size;
        (uint256 usdOut, uint256 usdOutFee) = _reduceCollateral(_account, _indexToken, _sizeDelta, _isLong, _posId);
        if (position.size != _sizeDelta) {
            position.entryFundingRate = settingsManager.cumulativeFundingRates(_indexToken, _isLong);
            position.size -= _sizeDelta;
            vaultUtils.validateSizeCollateralAmount(position.size, position.collateral);
            vaultUtils.validateLiquidation(_account, _indexToken, _isLong, _posId, true);
            vaultUtils.emitDecreasePositionEvent(_account, _indexToken, _isLong, _posId, _sizeDelta, usdOutFee);
        } else {
            vaultUtils.emitClosePositionEvent(_account, _indexToken, _isLong, _posId);
            delete positions[key];
        }
        if (usdOutFee <= usdOut) {
            if (usdOutFee != usdOut) {
                _decreasePoolAmount(_indexToken, _isLong, usdOut - usdOutFee);
            }
            vault.takeVUSDOut(_account, _refer, usdOutFee, usdOut);
        } else if (usdOutFee != 0) {
            vault.distributeFee(_account, _refer, usdOutFee);
        }
    }

    function _decreaseReservedAmount(address _token, bool _isLong, uint256 _amount) internal {
        require(reservedAmounts[_token][_isLong] >= _amount, "Vault: reservedAmounts exceeded");
        reservedAmounts[_token][_isLong] -= _amount;
        emit DecreaseReservedAmount(_token, _isLong, reservedAmounts[_token][_isLong]);
    }

    function _increasePoolAmount(address _indexToken, bool _isLong, uint256 _amount) internal {
        poolAmounts[_indexToken][_isLong] += _amount;
        emit IncreasePoolAmount(_indexToken, _isLong, poolAmounts[_indexToken][_isLong]);
    }

    function _increasePosition(
        address _account,
        address _indexToken,
        uint256 _amountIn,
        uint256 _sizeDelta,
        uint256 _posId,
        bool _isLong,
        address _refer
    ) internal {
        settingsManager.updateCumulativeFundingRate(_indexToken, _isLong);
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        Position storage position = positions[key];
        uint256 price = priceManager.getLastPrice(_indexToken);
        if (position.size == 0) {
            position.averagePrice = price;
        }

        if (position.size > 0 && _sizeDelta > 0) {
            position.averagePrice = priceManager.getNextAveragePrice(
                _indexToken,
                position.size,
                position.averagePrice,
                _isLong,
                price,
                _sizeDelta
            );
        }
        uint256 fee = settingsManager.collectMarginFees(
            _account,
            _indexToken,
            _isLong,
            _sizeDelta,
            position.size,
            position.entryFundingRate
        );
        uint256 _amountInAfterFee = _amountIn - fee;
        position.collateral += _amountInAfterFee;
        position.reserveAmount += _amountIn;
        position.entryFundingRate = settingsManager.cumulativeFundingRates(_indexToken, _isLong);
        position.size += _sizeDelta;
        position.lastIncreasedTime = block.timestamp;
        position.lastPrice = price;
        vault.accountDeltaAndFeeIntoTotalUSDC(true, 0, fee);
        vault.takeVUSDIn(_account, _refer, _amountIn, fee);
        settingsManager.validatePosition(_account, _indexToken, _isLong, position.size, position.collateral);
        vaultUtils.validateLiquidation(_account, _indexToken, _isLong, _posId, true);
        settingsManager.increaseOpenInterest(_indexToken, _account, _isLong, _sizeDelta);
        _increaseReservedAmount(_indexToken, _isLong, _sizeDelta);
        _increasePoolAmount(_indexToken, _isLong, _amountInAfterFee);
        vaultUtils.emitIncreasePositionEvent(_account, _indexToken, _isLong, _posId, _amountIn, _sizeDelta, fee);
    }

    function _increaseReservedAmount(address _token, bool _isLong, uint256 _amount) internal {
        reservedAmounts[_token][_isLong] += _amount;
        emit IncreaseReservedAmount(_token, _isLong, reservedAmounts[_token][_isLong]);
    }

    function _reduceCollateral(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _posId
    ) internal returns (uint256, uint256) {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        Position storage position = positions[key];
        bool hasProfit;
        uint256 adjustedDelta;
        // scope variables to avoid stack too deep errors
        {
            (bool _hasProfit, uint256 delta) = priceManager.getDelta(
                _indexToken,
                position.size,
                position.averagePrice,
                _isLong
            );
            hasProfit = _hasProfit;
            // get the proportional change in pnl
            adjustedDelta = (_sizeDelta * delta) / position.size;
        }

        uint256 usdOut;
        // transfer profits
        uint256 fee = settingsManager.collectMarginFees(
            _account,
            _indexToken,
            _isLong,
            _sizeDelta,
            position.size,
            position.entryFundingRate
        );
        if (adjustedDelta > 0) {
            if (hasProfit) {
                usdOut = adjustedDelta;
                position.realisedPnl += int256(adjustedDelta);
            } else {
                position.collateral -= adjustedDelta;
                position.realisedPnl -= int256(adjustedDelta);
            }
        }

        // if the position will be closed, then transfer the remaining collateral out
        if (position.size == _sizeDelta) {
            usdOut += position.collateral;
            position.collateral = 0;
        } else {
            // reduce the position's collateral by _collateralDelta
            // transfer _collateralDelta out
            uint256 _collateralDelta = (position.collateral * _sizeDelta) / position.size;
            usdOut += _collateralDelta;
            position.collateral -= _collateralDelta;
        }
        vault.accountDeltaAndFeeIntoTotalUSDC(hasProfit, adjustedDelta, fee);
        // if the usdOut is more or equal than the fee then deduct the fee from the usdOut directly
        // else deduct the fee from the position's collateral
        if (usdOut < fee) {
            position.collateral -= fee;
        }
        vaultUtils.validateDecreasePosition(_account, _indexToken, _isLong, _posId, true);
        return (usdOut, fee);
    }

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view override returns (Position memory, OrderInfo memory, ConfirmInfo memory) {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        Position memory position = positions[key];
        OrderInfo memory order = orders[key];
        ConfirmInfo memory confirm = confirms[key];
        return (position, order, confirm);
    }
}