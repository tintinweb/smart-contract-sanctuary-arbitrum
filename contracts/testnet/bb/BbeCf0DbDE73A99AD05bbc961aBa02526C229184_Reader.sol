// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Constants {
    uint8 internal constant STAKING_PID_FOR_CHARGE_FEE = 1;
    uint256 internal constant BASIS_POINTS_DIVISOR = 100000;
    uint256 internal constant LIQUIDATE_THRESHOLD_DIVISOR = 10 * BASIS_POINTS_DIVISOR;
    uint256 internal constant DEFAULT_VLP_PRICE = 100000;
    uint256 internal constant FUNDING_RATE_PRECISION = BASIS_POINTS_DIVISOR ** 3; // 1e15
    uint256 internal constant MAX_DEPOSIT_WITHDRAW_FEE = 10000; // 10%
    uint256 internal constant MAX_DELTA_TIME = 24 hours;
    uint256 internal constant MAX_COOLDOWN_DURATION = 30 days;
    uint256 internal constant MAX_FEE_BASIS_POINTS = 5000; // 5%
    uint256 internal constant MAX_PRICE_MOVEMENT_PERCENT = 10000; // 10%
    uint256 internal constant MAX_BORROW_FEE_FACTOR = 500; // 0.5% per hour
    uint256 internal constant MAX_FUNDING_RATE = FUNDING_RATE_PRECISION / 10; // 10% per hour
    uint256 internal constant MAX_STAKING_UNSTAKING_FEE = 10000; // 10%
    uint256 internal constant MAX_EXPIRY_DURATION = 60; // 60 seconds
    uint256 internal constant MAX_SELF_EXECUTE_COOLDOWN = 300; // 5 minutes
    uint256 internal constant MAX_TOKENFARM_COOLDOWN_DURATION = 4 weeks;
    uint256 internal constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;
    uint256 internal constant MAX_MARKET_ORDER_GAS_FEE = 1e8 gwei;
    uint256 internal constant MAX_VESTING_DURATION = 700 days;
    uint256 internal constant MIN_LEVERAGE = 10000; // 1x
    uint256 internal constant POSITION_MARKET = 0;
    uint256 internal constant POSITION_LIMIT = 1;
    uint256 internal constant POSITION_STOP_MARKET = 2;
    uint256 internal constant POSITION_STOP_LIMIT = 3;
    uint256 internal constant POSITION_TRAILING_STOP = 4;
    uint256 internal constant PRICE_PRECISION = 10 ** 30;
    uint256 internal constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 internal constant TRAILING_STOP_TYPE_PERCENT = 1;
    uint256 internal constant VLP_DECIMALS = 18;

    function uintToBytes(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        } else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function checkSlippage(bool isLong, uint256 allowedPrice, uint256 actualMarketPrice) internal pure {
        if (isLong) {
            require(
                actualMarketPrice <= allowedPrice,
                string(
                    abi.encodePacked(
                        "long: slippage exceeded ",
                        uintToBytes(actualMarketPrice),
                        " ",
                        uintToBytes(allowedPrice)
                    )
                )
            );
        } else {
            require(
                actualMarketPrice >= allowedPrice,
                string(
                    abi.encodePacked(
                        "short: slippage exceeded ",
                        uintToBytes(actualMarketPrice),
                        " ",
                        uintToBytes(allowedPrice)
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Order, OrderType, OrderStatus, AddPositionOrder, DecreasePositionOrder, PositionTrigger} from "../structs.sol";

interface IOrderVault {
    function addTrailingStop(address _account, uint256 _posId, uint256[] memory _params) external;

    function addTriggerOrders(
        uint256 _posId,
        address _account,
        bool[] memory _isTPs,
        uint256[] memory _prices,
        uint256[] memory _amountPercents
    ) external;

    function cancelPendingOrder(address _account, uint256 _posId) external;

    function updateOrder(
        uint256 _posId,
        uint256 _positionType,
        uint256 _collateral,
        uint256 _size,
        OrderStatus _status
    ) external;

    function cancelMarketOrder(uint256 _posId) external;

    function createNewOrder(
        uint256 _posId,
        address _accout,
        bool _isLong,
        uint256 _tokenId,
        uint256 _positionType,
        uint256[] memory _params,
        address _refer
    ) external;

    function createAddPositionOrder(
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice,
        uint256 _fee
    ) external;

    function createDecreasePositionOrder(uint256 _posId, uint256 _sizeDelta, uint256 _allowedPrice) external;

    function cancelAddPositionOrder(uint256 _posId) external;

    function deleteAddPositionOrder(uint256 _posId) external;

    function deleteDecreasePositionOrder(uint256 _posId) external;

    function removeOrder(uint256 _posId) external;

    function getOrder(uint256 _posId) external view returns (Order memory);

    function getAddPositionOrder(uint256 _posId) external view returns (AddPositionOrder memory);

    function getDecreasePositionOrder(uint256 _posId) external view returns (DecreasePositionOrder memory);

    function getTriggerOrderInfo(uint256 _posId) external view returns (PositionTrigger memory);

    function executeTriggerOrders(uint256 _tokenId) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Position, Order, OrderType, PaidFees} from "../structs.sol";

interface IPositionVault {
    function newPositionOrder(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address _refer
    ) external;

    function addOrRemoveCollateral(address _account, uint256 _posId, bool isPlus, uint256 _amount) external;

    function createAddPositionOrder(
        address _account,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external;

    function createDecreasePositionOrder(
        uint256 _posId,
        address _account,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external;

    function decreasePosition(uint256 _posId, uint256 _price, uint256 _sizeDelta) external;

    function removeUserAlivePosition(address _user, uint256 _posId) external;

    function lastPosId() external view returns (uint256);

    function getPosition(uint256 _posId) external view returns (Position memory);

    function getUserPositionIds(address _account) external view returns (uint256[] memory);

    function getUserOpenOrderIds(address _account) external view returns (uint256[] memory);

    function getPaidFees(uint256 _posId) external view returns (PaidFees memory);

    function getVaultUSDBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISettingsManager {
    function decreaseOpenInterest(uint256 _tokenId, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(uint256 _tokenId, address _sender, bool _isLong, uint256 _amount) external;

    function openInterestPerAssetPerSide(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint32, uint32);

    function checkBanList(address _delegate) external view returns (bool);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function minCollateral() external view returns (uint256);

    function closeDeltaTime() external view returns (uint256);

    function expiryDuration() external view returns (uint256);

    function selfExecuteCooldown() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function liquidationPendingTime() external view returns (uint256);

    function depositFee(address token) external view returns (uint256);

    function withdrawFee(address token) external view returns (uint256);

    function feeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function defaultBorrowFeeFactor() external view returns (uint256);

    function borrowFeeFactor(uint256 tokenId) external view returns (uint256);

    function totalOpenInterest() external view returns (uint256);

    function basisFundingRateFactor() external view returns (uint256);

    function deductFeePercent(address _account) external view returns (uint256);

    function referrerTiers(address _referrer) external view returns (uint256);

    function tierFees(uint256 _tier) external view returns (uint256);

    function fundingIndex(uint256 _tokenId) external view returns (int256);

    function fundingRateFactor(uint256 _tokenId) external view returns (uint256);

    function slippageFactor(uint256 _tokenId) external view returns (uint256);

    function getFundingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        int256 _fundingIndex
    ) external view returns (int256);

    function getFundingChange(uint256 _tokenId) external view returns (int256);

    function getFundingRate(uint256 _tokenId) external view returns (int256);

    function getTradingFee(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getPnl(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _averagePrice,
        uint256 _lastPrice,
        uint256 _lastIncreasedTime,
        uint256 _accruedBorrowFee,
        int256 _fundingIndex
    ) external view returns (int256, int256, int256);

    function updateFunding(uint256 _tokenId) external;

    function getBorrowFee(
        uint256 _borrowedSize,
        uint256 _lastIncreasedTime,
        uint256 _tokenId
    ) external view returns (uint256);

    function getUndiscountedTradingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getReferFee(address _refer) external view returns (uint256);

    function getPriceWithSlippage(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _price
    ) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isDeposit(address _token) external view returns (bool);

    function isStakingEnabled(address _token) external view returns (bool);

    function isUnstakingEnabled(address _token) external view returns (bool);

    function isIncreasingPositionDisabled(uint256 _tokenId) external view returns (bool);

    function isDecreasingPositionDisabled(uint256 _tokenId) external view returns (bool);

    function isWhitelistedFromCooldown(address _addr) external view returns (bool);

    function isWithdraw(address _token) external view returns (bool);

    function lastFundingTimes(uint256 _tokenId) external view returns (uint256);

    function liquidateThreshold(uint256) external view returns (uint256);

    function tradingFee(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function maxProfitPercent() external view returns (uint256);

    function priceMovementPercent() external view returns (uint256);

    function stakingFee(address token) external view returns (uint256);

    function unstakingFee(address token) external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function marketOrderGasFee() external view returns (uint256);

    function maxTriggerPerPosition() external view returns (uint256);

    function maxFundingRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IPositionVault.sol";
import "./interfaces/IOrderVault.sol";

import "./interfaces/ISettingsManager.sol";

import {Constants} from "../access/Constants.sol";
import {OrderStatus, PositionTrigger, TriggerInfo, PaidFees} from "./structs.sol";

contract Reader is Constants {
    struct AccruedFees {
        uint256 positionFee;
        uint256 borrowFee;
        int256 fundingFee;
    }

    IOrderVault private orderVault;
    IPositionVault private positionVault;
    ISettingsManager private settingsManager;

    bool private isInitialized;

    function initialize(IPositionVault _positionVault, IOrderVault _orderVault, ISettingsManager _settingsManager) external {
        require(!isInitialized, "initialized");
        require(Address.isContract(address(_positionVault)), "vault invalid");
        require(Address.isContract(address(_orderVault)), "vaultUtils invalid");
        positionVault = _positionVault;
        orderVault = _orderVault;
        settingsManager = _settingsManager;
        isInitialized = true;
    }

    function getUserAlivePositions(
        address _user
    )
        public
        view
        returns (uint256[] memory, Position[] memory, Order[] memory, PositionTrigger[] memory, PaidFees[] memory, AccruedFees[] memory)
    {
        uint256[] memory posIds = positionVault.getUserPositionIds(_user);
        uint256 length = posIds.length;
        Position[] memory positions_ = new Position[](length);
        Order[] memory orders_ = new Order[](length);
        PositionTrigger[] memory triggers_ = new PositionTrigger[](length);
        PaidFees[] memory paidFees_ = new PaidFees[](length);
        AccruedFees[] memory accruedFees_ = new AccruedFees[](length);
        for (uint i; i < length; ++i) {
            uint256 posId = posIds[i];
            positions_[i] = positionVault.getPosition(posId);
            orders_[i] = orderVault.getOrder(posId);
            triggers_[i] = orderVault.getTriggerOrderInfo(posId);
            paidFees_[i] = positionVault.getPaidFees(posId);
            accruedFees_[i] = getAccruedFee(posId);
        }
        return (posIds, positions_, orders_, triggers_, paidFees_, accruedFees_);
    }

    function getAccruedFee(uint256 _posId) internal view returns (AccruedFees memory){
        Position memory position = positionVault.getPosition(_posId);
        AccruedFees memory accruedFees;
        accruedFees.positionFee = settingsManager.getTradingFee(position.owner, position.tokenId, position.isLong, position.size);
        accruedFees.borrowFee = settingsManager.getBorrowFee(position.size, position.lastIncreasedTime, position.tokenId);
        accruedFees.fundingFee = settingsManager.getFundingFee(position.tokenId, position.isLong, position.size, position.fundingIndex);
        return accruedFees;
    }
    function getUserOpenOrders(
        address _user
    )
        public
        view
        returns (uint256[] memory, Position[] memory, Order[] memory, PositionTrigger[] memory, PaidFees[] memory, AccruedFees[] memory)
    {
        uint256[] memory posIds = positionVault.getUserOpenOrderIds(_user);
        uint256 length = posIds.length;
        Position[] memory positions_ = new Position[](length);
        Order[] memory orders_ = new Order[](length);
        PositionTrigger[] memory triggers_ = new PositionTrigger[](length);
        PaidFees[] memory paidFees_ = new PaidFees[](length);
        AccruedFees[] memory accruedFees_ = new AccruedFees[](length);
        for (uint i; i < length; ++i) {
            uint256 posId = posIds[i];
            positions_[i] = positionVault.getPosition(posId);
            orders_[i] = orderVault.getOrder(posId);
            triggers_[i] = orderVault.getTriggerOrderInfo(posId);
            paidFees_[i] = positionVault.getPaidFees(posId);
            accruedFees_[i] = getAccruedFee(posId);
        }
        return (posIds, positions_, orders_, triggers_, paidFees_, accruedFees_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT
}

enum OrderStatus {
    NONE,
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    NONE,
    PENDING,
    OPEN,
    TRIGGERED,
    CANCELLED
}

struct Order {
    OrderStatus status;
    uint256 lmtPrice;
    uint256 size;
    uint256 collateral;
    uint256 positionType;
    uint256 stepAmount;
    uint256 stepType;
    uint256 stpPrice;
    uint256 timestamp;
}

struct AddPositionOrder {
    uint256 collateral;
    uint256 size;
    uint256 allowedPrice;
    uint256 timestamp;
    uint256 fee;
}

struct DecreasePositionOrder {
    uint256 size;
    uint256 allowedPrice;
    uint256 timestamp;
}

struct Position {
    address owner;
    address refer;
    bool isLong;
    uint256 tokenId;
    uint256 averagePrice;
    uint256 collateral;
    int256 fundingIndex;
    uint256 lastIncreasedTime;
    uint256 size;
    uint256 accruedBorrowFee;
}

struct PaidFees {
    uint256 paidPositionFee;
    uint256 paidBorrowFee;
    int256 paidFundingFee;
}

struct Temp {
    uint256 a;
    uint256 b;
    uint256 c;
    uint256 d;
    uint256 e;
}

struct TriggerInfo {
    bool isTP;
    uint256 amountPercent;
    uint256 createdAt;
    uint256 price;
    uint256 triggeredAmount;
    uint256 triggeredAt;
    TriggerStatus status;
}

struct PositionTrigger {
    TriggerInfo[] triggers;
}