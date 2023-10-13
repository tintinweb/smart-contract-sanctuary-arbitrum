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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseAccess is Ownable {
    mapping(address => bool) public hasAccess;

    event GrantAccess(address indexed account, bool hasAccess);

    modifier limitAccess {
        require(hasAccess[msg.sender], "A:FBD");
        _;
    }

    function grantAccess(address _account, bool _hasAccess) onlyOwner external {
        hasAccess[_account] = _hasAccess;
        emit GrantAccess(_account, _hasAccess);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract BaseConstants {
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;

    uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals

    uint256 public constant DEFAULT_ROLP_PRICE = 100000; //1 USDC

    uint256 public constant ROLP_DECIMALS = 18;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT,
    TRAILING_STOP
}

enum OrderStatus {
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    OPEN,
    TRIGGERED,
    CANCELLED
}

enum DataType {
    POSITION,
    ORDER
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
    address collateralToken;
}

struct Position {
    address owner;
    address indexToken;
    bool isLong;
    int256 realisedPnl;
    uint256 averagePrice;
    uint256 collateral;
    int256 entryFunding;
    uint256 lastIncreasedTime;
    uint256 lastPrice;
    uint256 reserveAmount;
    uint256 size;
    uint256 posId;
    uint256 previousFee;
}

struct TriggerOrder {
    bytes32 key;
    bool isLong;
    uint256[] slPrices;
    uint256[] slAmountPercents;
    uint256[] slTriggeredAmounts;
    uint256[] tpPrices;
    uint256[] tpAmountPercents;
    uint256[] tpTriggeredAmounts;
    TriggerStatus status;
}

struct ConvertOrder {
    uint256 index;
    address indexToken;
    address sender;
    address recipient;
    uint256 amountIn;
    uint256 amountOut;
    uint256 state;
}

struct SwapPath {
    address pairAddress;
    uint256 fee;
}

struct SwapRequest {
    bytes32 orderKey;
    address tokenIn;
    address pool;
    uint256 amountIn;
}

struct PrepareTransaction {
    uint256 txType;
    uint256 startTime;

    /*
    uint256 public constant TRANSACTION_STATUS_NONE = 0;
    uint256 public constant TRANSACTION_STATUS_PENDING = 1;
    uint256 public constant TRANSACTION_STATUS_EXECUTED = 2;
    uint256 public constant TRANSACTION_STATUS_EXECUTE_REVERTED = 3;
    */
    uint256 status;
}

struct TxDetail {
    uint256[] params;
    address[] path;
}

struct VaultBond {
    address owner;
    address token; //Collateral token
    uint256 amount; //Collateral amount
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Position} from "../../constants/Structs.sol";

interface ISettingsManager {
    function decreaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function openInterestPerAsset(address _token) external view returns (uint256);

    function openInterestPerSide(bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint256);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function closeDeltaTime() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function cumulativeFundingRates(address _token, bool _isLong) external view returns (uint256);

    function delayDeltaTime() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function feeManager() external view returns (address);

    function getFeeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function getPositionFee(address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isCollateral(address _token) external view returns (bool);

    function isTradable(address _token) external view returns (bool);

    function isStable(address _token) external view returns (bool);

    function isStaking(address _token) external view returns (bool);

    function lastFundingTimes(address _token) external view returns (uint256);

    function maxPriceUpdatedDelay() external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function liquidateThreshold(address) external view returns (uint256);

    function marginFeeBasisPoints(address _token, bool _isLong) external view returns (uint256);

    function marketOrderEnabled() external view returns (bool);
    
    function pauseForexForCloseTime() external view returns (bool);

    function priceMovementPercent() external view returns (uint256);

    function referEnabled() external view returns (bool);

    function stakingFee() external view returns (uint256);

    function unstakingFee() external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function positionDefaultSlippage() external view returns (uint256);

    function setPositionDefaultSlippage(uint256 _slippage) external;

    function isActive() external view returns (bool);

    function isEnableNonStableCollateral() external view returns (bool);

    function isEnableConvertRUSD() external view returns (bool);

    function isEnableUnstaking() external view returns (bool);

    function validatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _collateral
    ) external view;

    function isApprovalCollateralToken(address _token) external view returns (bool);

    function isApprovalCollateralToken(address _token, bool _raise) external view returns (bool);

    function isEmergencyStop() external view returns (bool);

    function validateCollateralPathAndCheckSwap(address[] memory _collateralPath) external view returns (bool);

    function maxProfitPercent() external view returns (uint256);

    function basisFundingRateFactor() external view returns (uint256);

    function maxFundingRate() external view returns (uint256);

    function fundingRateFactor(address _token) external view returns (uint256);

    function fundingIndex(address _token) external view returns (int256);

    function getFundingRate(address _indexToken, address _collateralToken) external view returns (int256);

    function defaultBorrowFeeFactor() external view returns (uint256);

    function borrowFeeFactor(address token) external view returns (uint256);

    function getFundingFee(
        address _indexToken,
        bool _isLong,
        uint256 _size,
        int256 _fundingIndex
    ) external view returns (int256);

    function getBorrowFee(
        address _indexToken,
        uint256 _borrowedSize,
        uint256 _lastIncreasedTime
    ) external view returns (uint256);

    function getFeesV2(
        bytes32 _key,
        uint256 _sizeDelta,
        uint256 _loanDelta,
        bool _isApplyTradingFee,
        bool _isApplyBorrowFee,
        bool _isApplyFundingFee
    ) external view returns (uint256, int256);

    function getFees(
        uint256 _sizeDelta,
        uint256 _loanDelta,
        bool _isApplyTradingFee,
        bool _isApplyBorrowFee,
        bool _isApplyFundingFee,
        Position memory _position
    ) external view returns (uint256, int256);

    function getDiscountFee(address _account, uint256 _fee) external view returns (uint256);

    function updateFunding(address _indexToken, address _collateralToken) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IVaultPriceFeed {
    function setTokenConfig(address _token, address _priceFeed, uint256 _priceDecimals) external;

    function getLastPrice(address _token) external view returns (uint256, uint256, bool);

    function getLastPrices(address[] memory _tokens) external view returns(uint256[] memory, bool);

    function setLatestPrice(address _token, uint256 _latestPrice) external;
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IVaultPriceFeed.sol";
import "./interfaces/ISettingsManager.sol";
import "../oracle/interfaces/AggregatorV3Interface.sol";
import "../constants/BaseConstants.sol";
import "../oracle/interfaces/IFastPriceFeed.sol";
import "../access/BaseAccess.sol";

pragma solidity ^0.8.12;

contract VaultPriceFeed is IVaultPriceFeed, BaseConstants, BaseAccess {
    ISettingsManager public settingsManager;
    mapping(address => address) public fastPriceFeeds;
    mapping(address => uint256) public priceDecimals;
    mapping(address => address) public chainLinkAggregators;
    bool public isSupportFastPrice;

    event SetTokenConfig(address indexed token, address fastPriceFeed, uint256 priceDecimals);
    event SetSupportFastPrice(bool isSupportFastPrice);
    event SetTokenAggregator(address indexed token, address aggreagator);
    event SetSettingsManager(address indexed settingsManager);

    function setSupportFastPrice(bool _isSupport) external onlyOwner {
        isSupportFastPrice = _isSupport;
        emit SetSupportFastPrice( _isSupport);
    }

    function setSettingsManager(address _settingsManager) external onlyOwner {
        require(Address.isContract(_settingsManager), "Invalid settingsManager");
        settingsManager = ISettingsManager(_settingsManager);
        emit SetSettingsManager(_settingsManager);
    }

    /*
    @dev: Set token config, allow to set address(0) for fastPriceFeed
    */
    function setTokenConfig(address _token, address _fastPriceFeed, uint256 _priceDecimals) external override  onlyOwner {
        require(Address.isContract(_token), "Invalid token");
        fastPriceFeeds[_token] = _fastPriceFeed;
        priceDecimals[_token] = _priceDecimals;
        emit SetTokenConfig(_token, _fastPriceFeed, _priceDecimals);
    }

    function setTokenAggregator(address _indexToken, address _agregator) external onlyOwner {
        chainLinkAggregators[_indexToken] = _agregator;
        emit SetTokenAggregator(_indexToken, _agregator);
    }

    /*
    @dev: Return the last price including price, updatedAt, isFastPrice
    */
    function getLastPrice(address _token) external view override returns (uint256, uint256, bool) {
        (uint256 price, uint256 updatedAt, bool isFastPrice) = _getLastPrice(_token);
        return (price, updatedAt, isFastPrice ? block.timestamp - updatedAt <= _getMaxPriceUpdatedDelay() : false);
    }

    /*
    @dev: Return the lastPrices and isLastestSync result, 
        which is the union of all checks between maxPriceUpdatedDelay and updatedAt combined with isFastPrice
    */
    function getLastPrices(address[] memory _tokens) external view override returns(uint256[] memory, bool) {
        require(_tokens.length > 0, "Invalid tokens length");
        bool isLastestSync = true;
        uint256[] memory prices = new uint256[](_tokens.length);
        uint256 maxPriceUpdatedDelay = _getMaxPriceUpdatedDelay();

        for (uint256 i = 0; i < prices.length; i++) {
            (uint256 price, uint256 updatedAt, bool isFastPrice) = _getLastPrice(_tokens[i]);
            prices[i] = price;

            if (!isFastPrice) {
                isLastestSync = false;
            } else if (isLastestSync) {
                isLastestSync = block.timestamp - updatedAt <= maxPriceUpdatedDelay;
            }
        }

        return (prices, isLastestSync);
    }

    function _getLastPrice(address _token) internal view returns (uint256, uint256, bool) {
        uint256 price; 
        uint256 updatedAt;

        if (!isSupportFastPrice) {
            (price, updatedAt) = _getLastPriceByAggregator(_token);
            return (price, updatedAt, false);
        } 

        require(fastPriceFeeds[_token] != address(0), "Invalid fastPriceFeed");
        
        try IFastPriceFeed(fastPriceFeeds[_token]).latestSynchronizedPrice() 
                returns (uint256 fastPrice, uint256 fastPriceUpdatedAt) {
            if (fastPrice != 0) {
                return (fastPrice, fastPriceUpdatedAt, true);
            } else {
                (price, updatedAt) = _getLastPriceByAggregator(_token); 
                return (price, updatedAt, false);
            }
        } catch {
            (price, updatedAt) = _getLastPriceByAggregator(_token); 
            return (price, updatedAt, false);
        }
    }

    function getLastPriceByAggregator(address _token) external view returns(uint256, uint256) {
        return _getLastPriceByAggregator(_token);
    }

    function _getLastPriceByAggregator(address _token) internal view returns (uint256, uint256) {
        address aggreagatorAddress = chainLinkAggregators[_token];
        require(aggreagatorAddress != address(0), "This token has not been set up aggregator");
            (, int256 answer, , uint256 updatedAt, ) = AggregatorV3Interface(aggreagatorAddress).latestRoundData();
        uint256 aggregatorDecimals = AggregatorV3Interface(aggreagatorAddress).decimals();
        return (uint256(answer) * PRICE_PRECISION / (10**aggregatorDecimals), updatedAt);
    }

    function setLatestPrice(address _token, uint256 _latestPrice) external limitAccess {
        if (fastPriceFeeds[_token] != address(0)) {
            try IFastPriceFeed(fastPriceFeeds[_token]).setLatestAnswer(_latestPrice) {} 
            catch {}
        }
    }

    function _getMaxPriceUpdatedDelay() internal view returns (uint256) {
        require(address(settingsManager) != address(0), "SettingsManager not initialized");
        uint256 maxPriceUpdatedDelay = settingsManager.maxPriceUpdatedDelay();
        require(maxPriceUpdatedDelay > 0, "Invalid maxPriceUpdatedDelay");
        return maxPriceUpdatedDelay;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//Chain Link aggregator
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId) external view returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );

  function latestRoundData() external view returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IFastPriceFeed {
    function description() external view returns (string memory);

    function getRoundData(uint80 roundId) external view returns (uint80, uint256, uint256, uint256, uint80);

    function latestAnswer() external view returns (uint256);

    function latestRound() external view returns (uint80);

    function setLatestAnswer(uint256 _answer) external;

    function latestSynchronizedPrice() external view returns (
      uint256 answer,
      uint256 updatedAt
    );
}