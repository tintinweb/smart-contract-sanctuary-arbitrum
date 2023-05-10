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


contract VaultUtils is IVaultUtils, Constants {
    IPositionVault private immutable positionVault;
    IPriceManager private priceManager;
    ISettingsManager private settingsManager;

    event ClosePosition(bytes32 key, int256 realisedPnl, uint256 markPrice, uint256 feeUsd);
    event DecreasePosition(
        bytes32 key,
        address indexed account,
        address indexed indexToken,
        bool isLong,
        uint256 posId,
        int256 realisedPnl,
        uint256[7] posData
    );
    event IncreasePosition(
        bytes32 key,
        address indexed account,
        address indexed indexToken,
        bool isLong,
        uint256 posId,
        uint256[7] posData
    );
    event LiquidatePosition(bytes32 key, int256 realisedPnl, uint256 markPrice, uint256 feeUsd);
    event SetDepositFee(uint256 indexed fee);

    modifier onlyVault() {
        require(msg.sender == address(positionVault), "Only vault has access");
        _;
    }

    constructor(address _positionVault, address _priceManager, address _settingsManager) {
        require(Address.isContract(_positionVault), "vault address is invalid");
        positionVault = IPositionVault(_positionVault);
        priceManager = IPriceManager(_priceManager);
        settingsManager = ISettingsManager(_settingsManager);
    }

    function emitClosePositionEvent(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external override onlyVault {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        uint256 price = priceManager.getLastPrice(_indexToken);
        (Position memory position, , ) = positionVault.getPosition(_account, _indexToken, _isLong, _posId);
        uint256 migrateFeeUsd = settingsManager.collectMarginFees(
            _account,
            _indexToken,
            _isLong,
            position.size,
            position.size,
            position.entryFundingRate
        );
        emit ClosePosition(key, position.realisedPnl, price, migrateFeeUsd);
    }

    function emitDecreasePositionEvent(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _sizeDelta,
        uint256 _fee
    ) external override onlyVault {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        uint256 price = priceManager.getLastPrice(_indexToken);
        (Position memory position, , ) = positionVault.getPosition(_account, _indexToken, _isLong, _posId);
        uint256 _collateralDelta = (position.collateral * _sizeDelta) / position.size;
        emit DecreasePosition(
            key,
            _account,
            _indexToken,
            _isLong,
            _posId,
            position.realisedPnl,
            [
                _collateralDelta,
                _sizeDelta,
                position.reserveAmount,
                position.entryFundingRate,
                position.averagePrice,
                price,
                _fee
            ]
        );
    }

    function emitIncreasePositionEvent(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external override onlyVault {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        uint256 price = priceManager.getLastPrice(_indexToken);
        (Position memory position, , ) = positionVault.getPosition(_account, _indexToken, _isLong, _posId);
        emit IncreasePosition(
            key,
            _account,
            _indexToken,
            _isLong,
            _posId,
            [
                _collateralDelta,
                _sizeDelta,
                position.reserveAmount,
                position.entryFundingRate,
                position.averagePrice,
                price,
                _fee
            ]
        );
    }

    function emitLiquidatePositionEvent(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external override onlyVault {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        uint256 price = priceManager.getLastPrice(_indexToken);
        (Position memory position, , ) = positionVault.getPosition(_account, _indexToken, _isLong, _posId);
        uint256 migrateFeeUsd = settingsManager.collectMarginFees(
            _account,
            _indexToken,
            _isLong,
            position.size,
            position.size,
            position.entryFundingRate
        );
        emit LiquidatePosition(key, position.realisedPnl, price, migrateFeeUsd);
    }

    function validateConfirmDelay(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) external view override returns (bool) {
        (, , ConfirmInfo memory confirm) = positionVault.getPosition(_account, _indexToken, _isLong, _posId);
        bool validateFlag;
        if (confirm.confirmDelayStatus) {
            if (
                block.timestamp >= (confirm.delayStartTime + settingsManager.delayDeltaTime()) &&
                confirm.pendingDelayCollateral > 0
            ) validateFlag = true;
            else validateFlag = false;
        } else validateFlag = false;
        if (_raise) {
            require(validateFlag, "order is still in delay pending");
        }
        return validateFlag;
    }

    function validateDecreasePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) external view override returns (bool) {
        (Position memory position, , ) = positionVault.getPosition(_account, _indexToken, _isLong, _posId);
        bool validateFlag;
        (bool hasProfit, ) = priceManager.getDelta(_indexToken, position.size, position.averagePrice, _isLong);
        if (hasProfit) {
            if (
                position.lastIncreasedTime > 0 &&
                position.lastIncreasedTime < block.timestamp - settingsManager.closeDeltaTime()
            ) {
                validateFlag = true;
            } else {
                uint256 price = priceManager.getLastPrice(_indexToken);
                if (
                    (_isLong &&
                        price * BASIS_POINTS_DIVISOR >=
                        (BASIS_POINTS_DIVISOR + settingsManager.priceMovementPercent()) * position.lastPrice) ||
                    (!_isLong &&
                        price * BASIS_POINTS_DIVISOR <=
                        (BASIS_POINTS_DIVISOR - settingsManager.priceMovementPercent()) * position.lastPrice)
                ) {
                    validateFlag = true;
                }
            }
        } else {
            validateFlag = true;
        }
        if (_raise) {
            require(validateFlag, "not allowed to close the position");
        }
        return validateFlag;
    }

    function validateLiquidation(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) external view override returns (uint256, uint256) {
        (Position memory position, , ) = positionVault.getPosition(_account, _indexToken, _isLong, _posId);
        if (position.averagePrice > 0) {
            (bool hasProfit, uint256 delta) = priceManager.getDelta(
                _indexToken,
                position.size,
                position.averagePrice,
                _isLong
            );
            uint256 migrateFeeUsd = settingsManager.collectMarginFees(
                _account,
                _indexToken,
                _isLong,
                position.size,
                position.size,
                position.entryFundingRate
            );
            if (!hasProfit && position.collateral < delta) {
                if (_raise) {
                    revert("Vault: losses exceed collateral");
                }
                return (LIQUIDATE_FEE_EXCEED, migrateFeeUsd);
            }

            uint256 remainingCollateral = position.collateral;
            if (!hasProfit) {
                remainingCollateral = position.collateral - delta;
            }

            if (position.collateral * priceManager.maxLeverage(_indexToken) < position.size * MIN_LEVERAGE) {
                if (_raise) {
                    revert("Vault: maxLeverage exceeded");
                }
            }
            return _checkMaxThreshold(remainingCollateral, position.size, migrateFeeUsd, _indexToken, _raise);
        } else {
            return (LIQUIDATE_NONE_EXCEED, 0);
        }
    }

    function validatePosData(
        bool _isLong,
        address _indexToken,
        OrderType _orderType,
        uint256[] memory _params,
        bool _raise
    ) external view override returns (bool) {
        bool orderTypeFlag;
        if (_params[3] > 0) {
            if (_isLong) {
                if (_orderType == OrderType.LIMIT && _params[0] > 0) {
                    orderTypeFlag = true;
                } else if (_orderType == OrderType.STOP && _params[1] > 0) {
                    orderTypeFlag = true;
                } else if (_orderType == OrderType.STOP_LIMIT && _params[0] > 0 && _params[1] > 0) {
                    orderTypeFlag = true;
                } else if (_orderType == OrderType.MARKET) {
                    checkSlippage(_isLong, _params[0], _params[1], priceManager.getLastPrice(_indexToken));
                    orderTypeFlag = true;
                }
            } else {
                if (_orderType == OrderType.LIMIT && _params[0] > 0) {
                    orderTypeFlag = true;
                } else if (_orderType == OrderType.STOP && _params[1] > 0) {
                    orderTypeFlag = true;
                } else if (_orderType == OrderType.STOP_LIMIT && _params[0] > 0 && _params[1] > 0) {
                    orderTypeFlag = true;
                } else if (_orderType == OrderType.MARKET) {
                    checkSlippage(_isLong, _params[0], _params[1], priceManager.getLastPrice(_indexToken));
                    orderTypeFlag = true;
                }
            }
        } else orderTypeFlag = true;
        if (_raise) {
            require(orderTypeFlag, "invalid position data");
        }
        return orderTypeFlag;
    }

    function validateTrailingStopInputData(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params
    ) external view override returns (bool) {
        (Position memory position, , ) = positionVault.getPosition(_account, _indexToken, _isLong, _posId);
        uint256 price = priceManager.getLastPrice(_indexToken);
        require(_params[1] > 0 && _params[1] <= position.size, "trailing size should be smaller than position size");
        if (_isLong) {
            require(_params[4] > 0 && _params[3] > 0 && _params[3] <= price, "invalid trailing data");
        } else {
            require(_params[4] > 0 && _params[3] > 0 && _params[3] >= price, "invalid trailing data");
        }
        if (_params[2] == TRAILING_STOP_TYPE_PERCENT) {
            require(_params[4] < BASIS_POINTS_DIVISOR, "percent cant exceed 100%");
        } else {
            if (_isLong) {
                require(_params[4] < price, "step amount cant exceed price");
            }
        }
        return true;
    }

    function validateTrailingStopPrice(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) external view override returns (bool) {
        (, OrderInfo memory order, ) = positionVault.getPosition(_account, _indexToken, _isLong, _posId);
        uint256 price = priceManager.getLastPrice(_indexToken);
        uint256 stopPrice;
        if (_isLong) {
            if (order.stepType == TRAILING_STOP_TYPE_AMOUNT) {
                stopPrice = order.stpPrice + order.stepAmount;
            } else {
                stopPrice = (order.stpPrice * BASIS_POINTS_DIVISOR) / (BASIS_POINTS_DIVISOR - order.stepAmount);
            }
        } else {
            if (order.stepType == TRAILING_STOP_TYPE_AMOUNT) {
                stopPrice = order.stpPrice - order.stepAmount;
            } else {
                stopPrice = (order.stpPrice * BASIS_POINTS_DIVISOR) / (BASIS_POINTS_DIVISOR + order.stepAmount);
            }
        }
        bool flag;
        if (
            _isLong &&
            order.status == OrderStatus.PENDING &&
            order.positionType == POSITION_TRAILING_STOP &&
            stopPrice <= price
        ) {
            flag = true;
        } else if (
            !_isLong &&
            order.status == OrderStatus.PENDING &&
            order.positionType == POSITION_TRAILING_STOP &&
            stopPrice >= price
        ) {
            flag = true;
        }
        if (_raise) {
            require(flag, "price incorrect");
        }
        return flag;
    }

    function validateTrigger(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view override returns (uint8) {
        (, OrderInfo memory order, ) = positionVault.getPosition(_account, _indexToken, _isLong, _posId);
        uint256 price = priceManager.getLastPrice(_indexToken);
        uint8 statusFlag;
        if (order.status == OrderStatus.PENDING) {
            if (order.positionType == POSITION_LIMIT) {
                if (_isLong && order.lmtPrice >= price) statusFlag = ORDER_FILLED;
                else if (!_isLong && order.lmtPrice <= price) statusFlag = ORDER_FILLED;
                else statusFlag = ORDER_NOT_FILLED;
            } else if (order.positionType == POSITION_STOP_MARKET) {
                if (_isLong && order.stpPrice <= price) statusFlag = ORDER_FILLED;
                else if (!_isLong && order.stpPrice >= price) statusFlag = ORDER_FILLED;
                else statusFlag = ORDER_NOT_FILLED;
            } else if (order.positionType == POSITION_STOP_LIMIT) {
                if (_isLong && order.stpPrice <= price) statusFlag = ORDER_FILLED;
                else if (!_isLong && order.stpPrice >= price) statusFlag = ORDER_FILLED;
                else statusFlag = ORDER_NOT_FILLED;
            } else if (order.positionType == POSITION_TRAILING_STOP) {
                if (_isLong && order.stpPrice >= price) statusFlag = ORDER_FILLED;
                else if (!_isLong && order.stpPrice <= price) statusFlag = ORDER_FILLED;
                else statusFlag = ORDER_NOT_FILLED;
            }
        } else {
            statusFlag = ORDER_NOT_FILLED;
        }
        return statusFlag;
    }

    function validateSizeCollateralAmount(uint256 _size, uint256 _collateral) external pure override {
        require(_size >= _collateral, "position size should be greater than collateral");
    }

    function _checkMaxThreshold(
        uint256 _collateral,
        uint256 _size,
        uint256 _marginFees,
        address _indexToken,
        bool _raise
    ) internal view returns (uint256, uint256) {
        if (_collateral < _marginFees) {
            if (_raise) {
                revert("Vault: fees exceed collateral");
            }
            // cap the fees to the remainingCollateral
            return (LIQUIDATE_FEE_EXCEED, _collateral);
        }

        if (_collateral < _marginFees + settingsManager.liquidationFeeUsd()) {
            if (_raise) {
                revert("Vault: liquidation fees exceed collateral");
            }
            return (LIQUIDATE_FEE_EXCEED, _marginFees);
        }

        if (
            _collateral - (_marginFees + settingsManager.liquidationFeeUsd()) <
            (_size * (BASIS_POINTS_DIVISOR - settingsManager.liquidateThreshold(_indexToken))) / BASIS_POINTS_DIVISOR
        ) {
            if (_raise) {
                revert("Vault: maxThreshold exceeded");
            }
            return (LIQUIDATE_THRESHOLD_EXCEED, _marginFees + settingsManager.liquidationFeeUsd());
        }
        return (LIQUIDATE_NONE_EXCEED, _marginFees);
    }
}