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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

enum OptionsState {
    Settled,
    Active,
    Unlocked
}

enum EpochState {
    InActive,
    BootStrapped,
    Expired,
    Paused
}

enum Contracts {
    QuoteToken,
    BaseToken,
    FeeDistributor,
    FeeStrategy,
    OptionPricing,
    PriceOracle,
    VolatilityOracle,
    Gov
}

enum VaultConfig {
    IvBoost,
    ExpiryWindow,
    FundingInterval,
    BaseFundingRate,
    UseDiscount,
    ExpireDelayTolerance
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {OptionsState, EpochState} from "./AtlanticPutsPoolEnums.sol";

struct EpochData {
    uint256 settlementPrice;
    uint256 startTime;
    uint256 expiryTime;
    uint256 totalLiquidity;
    uint256 totalActiveCollateral;
    uint256 fundingRate;
    uint256 tickSize;
    MaxStrikesRange maxStrikesRange;
    EpochState state;
}

struct MaxStrikesRange {
    uint256 highest;
    uint256 lowest;
}

struct Checkpoint {
    uint256 startTime;
    uint256 unlockedCollateral;
    uint256 premiumAccrued;
    uint256 borrowFeesAccrued;
    uint256 underlyingAccrued;
    uint256 totalLiquidity;
    uint256 liquidityBalance;
    uint256 activeCollateral;
}

struct EpochRewards {
    address[] rewardTokens;
    uint256[] amounts;
}

struct OptionsPurchase {
    uint256 epoch;
    uint256 optionStrike;
    uint256 optionsAmount;
    uint256 unlockEntryTimestamp;
    uint256[] strikes;
    uint256[] checkpoints;
    uint256[] weights;
    OptionsState state;
    address user;
    address delegate;
}

struct DepositPosition {
    uint256 epoch;
    uint256 strike;
    uint256 liquidity;
    uint256 checkpoint;
    address depositor;
}

struct MaxStrike {
    uint256 maxStrike;
    uint256 activeCollateral;
    uint256[] rewardRates;
    mapping(uint256 => Checkpoint) checkpoints;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Contracts, VaultConfig, OptionsState} from "../AtlanticPutsPoolEnums.sol";

import {DepositPosition, OptionsPurchase, Checkpoint} from "../AtlanticPutsPoolStructs.sol";

interface IAtlanticPutsPool {
    function purchasePositionsCounter() external view returns (uint256);

    function currentEpoch() external view returns (uint256);

    function getOptionsPurchase(
        uint256 _tokenId
    ) external view returns (OptionsPurchase memory);

    function getEpochTickSize(uint256 _epoch) external view returns (uint256);

    function addresses(Contracts _contractType) external view returns (address);

    function getOptionsState(
        uint256 _purchaseId
    ) external view returns (OptionsState);

    function purchase(
        uint256 _strike,
        uint256 _amount,
        address _delegate,
        address _account
    ) external returns (uint256 purchaseId);

    function calculateFundingFees(
        uint256 _collateralAccess,
        uint256 _entryTimestamp
    ) external view returns (uint256 fees);

    function relockCollateral(
        uint256 purchaseId,
        uint256 relockAmount
    ) external;

    function unwind(uint256 purchaseId, uint256 unwindAmount) external;

    function calculatePurchaseFees(
        address account,
        uint256 strike,
        uint256 amount
    ) external view returns (uint256 finalFee);

    function calculatePremium(
        uint256 _strike,
        uint256 _amount
    ) external view returns (uint256 premium);

    function unlockCollateral(
        uint256 purchaseId,
        address to
    ) external returns (uint256 unlockedCollateral);

    function getDepositPosition(
        uint256 _tokenId
    ) external view returns (DepositPosition memory);

    function strikeMulAmount(
        uint256 _strike,
        uint256 _amount
    ) external view returns (uint256 result);

    function totalSupply() external view returns (uint256);

    function getEpochStrikes(
        uint256 epoch
    ) external view returns (uint256[] memory maxStrikes);

    function getEpochCheckpoints(
        uint256 _epoch,
        uint256 _maxStrike
    ) external view returns (Checkpoint[] memory _checkpoints);

    function isWithinExerciseWindow() external view returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPositionRouter {
  function executeIncreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

  function executeDecreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

  function executeDecreasePosition(bytes32 key, address payable _executionFeeReceiver) external;

  function executeIncreasePosition(bytes32 key, address payable _executionFeeReceiver) external;

  // AKA open position /  add to position
  function createIncreasePosition(
    address[] memory _path,
    address _indexToken,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _sizeDelta,
    bool _isLong,
    uint256 _acceptablePrice,
    uint256 _executionFee,
    bytes32 _referralCode,
    address _callbackTarget
  ) external payable;

  // AKA close position /  remove from position
  function createDecreasePosition(
    address[] memory _path,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver,
    uint256 _acceptablePrice,
    uint256 _minOut,
    uint256 _executionFee,
    bool _withdrawETH,
    address _callbackTarget
  ) external payable;

  function decreasePositionsIndex(address) external view returns (uint256);

  function increasePositionsIndex(address) external view returns (uint256);

  function getRequestKey(address, uint256) external view returns (bytes32);

  function minExecutionFee() external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRouter {
  function addPlugin(address _plugin) external;

  function approvePlugin(address _plugin) external;

  function pluginTransfer(
    address _token,
    address _account,
    address _receiver,
    uint256 _amount
  ) external;

  function pluginIncreasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    bool _isLong
  ) external;

  function pluginDecreasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver
  ) external returns (uint256);

  function swap(
    address[] memory _path,
    uint256 _amountIn,
    uint256 _minOut,
    address _receiver
  ) external;

  function swapTokensToETH(
    address[] memory _path,
    uint256 _amountIn,
    uint256 _minOut,
    address payable _receiver
  ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVault {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDopexFeeStrategy {
 function getFeeBps(
        uint256 feeType,
        address user,
        bool useDiscount
    ) external view returns (uint256 _feeBps);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/// @title ContractWhitelist
/// @author witherblock
/// @notice A helper contract that lets you add a list of whitelisted contracts that should be able to interact with restricited functions
abstract contract ContractWhitelist {
    /// @dev contract => whitelisted or not
    mapping(address => bool) public whitelistedContracts;

    error AddressNotContract();
    error ContractNotWhitelisted();
    error ContractAlreadyWhitelisted();

    /*==== SETTERS ====*/

    /// @dev add to the contract whitelist
    /// @param _contract the address of the contract to add to the contract whitelist
    function _addToContractWhitelist(address _contract) internal {
        if (!isContract(_contract)) revert AddressNotContract();

        whitelistedContracts[_contract] = true;

        emit AddToContractWhitelist(_contract);
    }

    /// @dev remove from  the contract whitelist
    /// @param _contract the address of the contract to remove from the contract whitelist
    function _removeFromContractWhitelist(address _contract) internal {

        whitelistedContracts[_contract] = false;

        emit RemoveFromContractWhitelist(_contract);
    }

    // modifier is eligible sender modifier
    function _isEligibleSender() internal view {
        // the below condition checks whether the caller is a contract or not
        if (msg.sender != tx.origin) {
            if (!whitelistedContracts[msg.sender]) {
                revert ContractNotWhitelisted();
            }
        }
    }

    /*==== VIEWS ====*/

    /// @dev checks for contract or eoa addresses
    /// @param addr the address to check
    /// @return bool whether the passed address is a contract address
    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /*==== EVENTS ====*/

    event AddToContractWhitelist(address indexed _contract);
    event RemoveFromContractWhitelist(address indexed _contract);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/// @title Lighter version of the Openzeppelin Pausable contract
/// @author witherblock
/// @notice Helps pause a contract to block the execution of selected functions
/// @dev Difference from the Openzeppelin version is changing the modifiers to internal fns and requires to reverts
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Internal function to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _whenNotPaused() internal view {
        if (paused()) revert ContractPaused();
    }

    /**
     * @dev Internal function to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _whenPaused() internal view {
        if (!paused()) revert ContractNotPaused();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual {
        _whenNotPaused();
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        _whenPaused();
        _paused = false;
        emit Unpaused(msg.sender);
    }

    error ContractPaused();
    error ContractNotPaused();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.7;

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

    error ReentrancyCall();

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
        if (_status == _ENTERED) revert ReentrancyCall();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// Libraries/Contracts
import {SafeERC20} from "../../libraries/SafeERC20.sol";
import {Pausable} from "../../helpers/Pausable.sol";
import {ContractWhitelist} from "../../helpers/ContractWhitelist.sol";
import {ReentrancyGuard} from "../../helpers/ReentrancyGuard.sol";
import {OwnableRoles} from "solady/src/auth/OwnableRoles.sol";

// Interfaces
import {IAtlanticPutsPool} from "../../atlantic-pools/interfaces/IAtlanticPutsPool.sol";
import {IRouter} from "../../external/gmx/interfaces-modified/IRouter.sol";
import {IVault} from "../../external/gmx/interfaces-modified/IVault.sol";
import {IPositionRouter} from "../../external/gmx/interfaces-modified/IPositionRouter.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {IDopexPositionManager, IncreaseOrderParams, DecreaseOrderParams} from "./interfaces/IDopexPositionManager.sol";
import {IInsuredLongsUtils} from "./interfaces/IInsuredLongsUtils.sol";
import {IInsuredLongsStrategy} from "./interfaces/IInsuredLongsStrategy.sol";
import {IDopexPositionManagerFactory} from "./interfaces/IDopexPositionManagerFactory.sol";
import {ICallbackForwarder} from "./interfaces/ICallbackForwarder.sol";
import {IDopexFeeStrategy} from "../../fees/interfaces/IDopexFeeStrategy.sol";

// Enums
import {OptionsState} from "../../atlantic-pools/AtlanticPutsPoolEnums.sol";

// Structs
import {OptionsPurchase} from "../../atlantic-pools/AtlanticPutsPoolStructs.sol";

contract InsuredLongsStrategy is
    ContractWhitelist,
    Pausable,
    ReentrancyGuard,
    IInsuredLongsStrategy
{
    using SafeERC20 for IERC20;

    uint256 private constant BPS_PRECISION = 100000;
    uint256 private constant STRATEGY_FEE_KEY = 3;
    uint256 public positionsCount = 1;
    uint256 public useDiscountForFees = 1;

    /**
     * @notice Time window in which whitelisted keeper can settle positions.
     */
    uint256 public keeperHandleWindow;

    uint256 public maxLeverage;

    mapping(uint256 => StrategyPosition) public strategyPositions;

    /**
     * @notice Orders after created are saved here and used in
     *         gmxPositionCallback() for reference when a order
     *         is executed.
     */
    mapping(bytes32 => uint256) public pendingOrders;

    /**
     * @notice ID of the strategy position belonging to a user.
     */
    mapping(address => uint256) public userPositionIds;

    /**
     * @notice A multiplier applied to an atlantic pool's ticksize
     *         when calculating liquidation price. This multiplier
     *         summed up with liquidation price gives a price suitable
     *         for insuring the long position.
     *
     *         same Offset bps will be applied to strike price which acts
     *         as threshold to persist unlocked collateral in the
     *         long position. If mark price of the index token
     *         crosses this trigger price (strike + offsetBps)
     *         collateral will be removed from the long position
     *         and relocked back into the atlantic pool that it
     *         was borrowed from.
     */
    mapping(address => uint256) public tickSizeMultiplierBps;

    /**
     * @notice Keepers are EOA or contracts that will have special
     *         permissions required to carry out insurance related
     *         functions available in this contract.
     *         1. Create a order to add collateral to a position.
     *         2. Create a order to exit a position.
     */
    mapping(address => uint256) public whitelistedKeepers;

    /**
     * @notice Atlantic Put pools that can be used by this strategy contract
     *         for purchasing put options, unlocking, relocking and unwinding of
     *         collateral.
     */
    mapping(bytes32 => address) public whitelistedAtlanticPools;

    mapping(uint256 => address) public pendingStrategyPositionToken;

    address public immutable positionRouter;
    address public immutable router;
    address public immutable vault;
    address public feeDistributor;
    address public gov;
    IDopexFeeStrategy public feeStrategy;

    /**
     *  @notice Index token supported by this strategy contract.
     */
    address public immutable strategyIndexToken;

    IInsuredLongsUtils public utils;
    IDopexPositionManagerFactory public positionManagerFactory;

    constructor(
        address _vault,
        address _positionRouter,
        address _router,
        address _positionManagerFactory,
        address _feeDistributor,
        address _utils,
        address _gov,
        address _indexToken,
        address _feeStrategy
    ) {
        utils = IInsuredLongsUtils(_utils);
        positionManagerFactory = IDopexPositionManagerFactory(
            _positionManagerFactory
        );
        positionRouter = _positionRouter;
        router = _router;
        vault = _vault;
        feeDistributor = _feeDistributor;
        gov = _gov;
        strategyIndexToken = _indexToken;
        feeStrategy = IDopexFeeStrategy(_feeStrategy);
    }

    /**
     * @notice                Reuse strategy for a position manager that has an active
     *                        gmx position.
     * @param _positionId     ID of the position in strategyPositions mapping
     * @param _expiry         Expiry of the insurance
     * @param _keepCollateral Whether to deposit underlying to allow unwinding
     *                        of options.
     */
    function reuseStrategy(
        uint256 _positionId,
        uint256 _expiry,
        bool _keepCollateral
    ) external {
        _isEligibleSender();
        _whenNotPaused();

        StrategyPosition memory position = strategyPositions[_positionId];

        address userPositionManager = userPositionManagers(msg.sender);

        _validate(position.atlanticsPurchaseId == 0, 28);
        _validate(msg.sender == position.user, 27);

        (uint256 positionSize, uint256 collateral) = _getPosition(_positionId);

        _validate(positionSize != 0, 5);

        _validate((positionSize * 1e4) / collateral <= maxLeverage, 30);

        address atlanticPool = _getAtlanticPoolAddress({
            _indexToken: position.indexToken,
            _quoteToken: position.collateralToken,
            _expiry: _expiry
        });

        _validate(atlanticPool != address(0), 8);

        _validteNotWithinExerciseWindow(atlanticPool);

        IDopexPositionManager(userPositionManager).lock();

        position.expiry = _expiry;
        position.keepCollateral = _keepCollateral;

        strategyPositions[_positionId] = position;

        if (position.state != ActionState.EnablePending) {
            // Collect strategy position fee
            _collectStrategyPositionFee(positionSize, position.collateralToken);
        }

        _enableStrategy(_positionId);
    }

    /**
     * @notice                 Create strategy postiion and create long position order
     * @param _collateralToken Address of the collateral token. Also to refer to
     *                         atlantic pool to buy puts from
     * @param _expiry          Timestamp of expiry for selecting a atlantic pool
     * @param _keepCollateral  Deposit underlying to keep collateral if position
     *                         is left increased before expiry
     */
    function useStrategyAndOpenLongPosition(
        IncreaseOrderParams calldata _increaseOrder,
        address _collateralToken,
        uint256 _expiry,
        bool _keepCollateral
    ) external payable nonReentrant {
        _whenNotPaused();
        _isEligibleSender();

        // Only longs are accepted
        _validate(_increaseOrder.isLong, 0);
        _validate(_increaseOrder.indexToken == strategyIndexToken, 1);
        _validate(
            _increaseOrder.path[_increaseOrder.path.length - 1] ==
                strategyIndexToken,
            1
        );

        // Collateral token and path[0] must be the same
        if (_increaseOrder.path.length > 1) {
            _validate(_collateralToken == _increaseOrder.path[0], 16);
        }

        _validate(
            (_increaseOrder.positionSizeDelta * 1e4) /
                IVault(vault).tokenToUsdMin(
                    _increaseOrder.path[0],
                    _increaseOrder.collateralDelta
                ) <=
                maxLeverage,
            30
        );

        address userPositionManager = userPositionManagers(msg.sender);
        uint256 userPositionId = userPositionIds[msg.sender];

        (uint256 size, ) = _getPosition(userPositionId);
        // Should not have open positions
        _validate(size == 0, 29);

        // If position ID and manager is already created for the user, ensure it's a settled one
        _validate(
            strategyPositions[userPositionId].atlanticsPurchaseId == 0,
            9
        );

        address atlanticPool = _getAtlanticPoolAddress({
            _indexToken: _increaseOrder.indexToken,
            _quoteToken: _collateralToken,
            _expiry: _expiry
        });

        _validate(atlanticPool != address(0), 8);

        _validteNotWithinExerciseWindow(atlanticPool);

        // If position is already created, use existing one or create new
        if (userPositionId == 0) {
            userPositionId = positionsCount;

            unchecked {
                ++positionsCount;
            }

            userPositionIds[msg.sender] = userPositionId;
        }

        _newStrategyPosition({
            _positionId: userPositionId,
            _expiry: _expiry,
            _indexToken: _increaseOrder.indexToken,
            _collateralToken: _collateralToken,
            _keepCollateral: _keepCollateral
        });

        // if a position manager is not created for the user, create one or use existing one
        if (userPositionManager == address(0)) {
            userPositionManager = positionManagerFactory.createPositionmanager(
                msg.sender
            );
        }

        _transferFrom(
            _increaseOrder.path[0],
            msg.sender,
            userPositionManager,
            _increaseOrder.collateralDelta
        );

        // Create increase order for long position
        IDopexPositionManager(userPositionManager).enableAndCreateIncreaseOrder{
            value: msg.value
        }({
            params: _increaseOrder,
            _gmxVault: vault,
            _gmxRouter: router,
            _gmxPositionRouter: positionRouter,
            _user: msg.sender
        });

        // Called after gmx position is created since position key is generated after gmx position is opened.
        pendingOrders[
            _getPositionKey(userPositionManager, true)
        ] = userPositionId;

        // Collect strategy position fee
        _collectStrategyPositionFee(
            _increaseOrder.positionSizeDelta,
            _increaseOrder.path[0]
        );

        emit OrderCreated(userPositionId, ActionState.EnablePending);
    }

    /**
     * @notice            Enable keepCollateral state of the strategy position
     *                    such allowing users to keep their long positions post
     *                    expiry of the atlantic put from which options were purch-
     *                    -ased from.
     * @param _positionId ID of the position.
     */
    function enableKeepCollateral(uint256 _positionId) external {
        _isEligibleSender();

        StrategyPosition memory position = strategyPositions[_positionId];

        _validate(position.user == msg.sender, 27);
        _validate(position.state != ActionState.Settled, 3);
        // Must be an active position with insurance
        _validate(position.atlanticsPurchaseId != 0, 19);
        _validate(!position.keepCollateral, 18);

        (, uint256 unwindCost) = _getOptionsPurchase(
            _getAtlanticPoolAddress({
                _indexToken: position.indexToken,
                _quoteToken: position.collateralToken,
                _expiry: position.expiry
            }),
            position.atlanticsPurchaseId
        );

        _transferFrom({
            _token: position.indexToken,
            _from: msg.sender,
            _to: address(this),
            _amount: unwindCost
        });

        strategyPositions[_positionId].keepCollateral = true;
    }

    /**
     * @notice            Create a order to add collateral to managed long gmx position
     * @param _positionId ID of the strategy position in strategyPositions Mapping
     */
    function createIncreaseManagedPositionOrder(
        uint256 _positionId
    ) external payable {
        StrategyPosition memory position = strategyPositions[_positionId];

        if (msg.sender != position.user) {
            _validate(whitelistedKeepers[msg.sender] == 1, 2);
        }

        _validate(position.state != ActionState.Increased, 4);
        _validate(position.atlanticsPurchaseId != 0, 19);

        address positionManager = userPositionManagers(position.user);

        IAtlanticPutsPool pool = IAtlanticPutsPool(
            _getAtlanticPoolAddress({
                _indexToken: position.indexToken,
                _quoteToken: position.collateralToken,
                _expiry: position.expiry
            })
        );

        _validate(
            pool.getOptionsState(position.atlanticsPurchaseId) !=
                OptionsState.Settled,
            19
        );

        uint256 collateralUnlocked = _getCollateralAccess(
            address(pool),
            position.atlanticsPurchaseId
        );

        // Skip unlocking if collateral already unlocked
        if (ActionState.IncreasePending != position.state) {
            _transferFrom({
                _token: position.collateralToken,
                _from: position.user,
                _to: address(this),
                _amount: pool.calculateFundingFees(
                    collateralUnlocked,
                    block.timestamp
                )
            });

            // Unlock collateral from atlantic pool
            pool.unlockCollateral(
                position.atlanticsPurchaseId,
                positionManager
            );
        } else {
            _validate(
                pool.getOptionsState(position.atlanticsPurchaseId) ==
                    OptionsState.Unlocked,
                33
            );
        }

        // Create order to add unlocked collateral
        IDopexPositionManager(positionManager).increaseOrder{value: msg.value}({
            _increaseOrderParams: IncreaseOrderParams({
                path: _get2TokenSwapPath(
                    position.collateralToken,
                    position.indexToken
                ),
                indexToken: position.indexToken,
                collateralDelta: collateralUnlocked,
                positionSizeDelta: 0,
                acceptablePrice: 0,
                isLong: true
            })
        });

        strategyPositions[_positionId].state = ActionState.IncreasePending;
        pendingOrders[_getPositionKey(positionManager, true)] = _positionId;

        emit OrderCreated(_positionId, ActionState.IncreasePending);
    }

    /**
     * @notice            Create a order to exit from strategy and long gmx position
     * @param _positionId ID of the strategy position in strategyPositions Mapping
     */
    function createExitStrategyOrder(
        uint256 _positionId,
        address withdrawAs,
        bool exitLongPosition
    ) external payable nonReentrant {
        StrategyPosition memory position = strategyPositions[_positionId];

        _updateGmxVaultCummulativeFundingRate(position.indexToken);

        _validate(position.atlanticsPurchaseId != 0, 19);

        // Keeper can only call during keeperHandleWindow before expiry
        if (msg.sender != position.user) {
            _validate(whitelistedKeepers[msg.sender] == 1, 2);
            _validate(_isKeeperHandleWindow(position.expiry), 21);
        }
        _validate(position.state != ActionState.Settled, 3);

        address positionManager = userPositionManagers(position.user);

        uint256 collateralDelta;
        address tokenOut;
        uint256 sizeDelta;
        address[] memory path;

        // Only decrease from position is it has borrowed collateral.
        (sizeDelta, ) = _getPosition(_positionId);
        if (position.state == ActionState.Increased) {
            (tokenOut, collateralDelta) = getAmountAndTokenReceviedOnExit(
                _positionId
            );

            if (
                !utils.validateDecreaseCollateralDelta({
                    _positionManager: positionManager,
                    _indexToken: position.indexToken,
                    _collateralDelta: collateralDelta
                })
            ) {
                tokenOut = position.indexToken;
            }

            // if token out == index token, close the position
            if (tokenOut == position.indexToken) {
                path = _get1TokenSwapPath(position.indexToken);
                delete collateralDelta;

                // else only remove borrowed collateral
            } else {
                path = _get2TokenSwapPath(
                    position.indexToken,
                    position.collateralToken
                );

                // if user wishes to exit position let size delta persist. (sizeDelta assigned earlier).
                if (!exitLongPosition) {
                    delete sizeDelta;
                }
            }
        } else {
            if (exitLongPosition) {
                if (withdrawAs != position.indexToken) {
                    path = _get2TokenSwapPath(position.indexToken, withdrawAs);
                } else {
                    path = _get1TokenSwapPath(position.indexToken);
                }
            } else {
                delete sizeDelta;
            }
        }

        if (collateralDelta != 0 || sizeDelta != 0) {
            // Create order to exit position
            IDopexPositionManager(positionManager).decreaseOrder{
                value: msg.value
            }(
                DecreaseOrderParams({
                    orderParams: IncreaseOrderParams({
                        path: path,
                        indexToken: position.indexToken,
                        collateralDelta: collateralDelta,
                        positionSizeDelta: sizeDelta,
                        acceptablePrice: 0,
                        isLong: true
                    }),
                    receiver: positionManager,
                    withdrawETH: false
                })
            );

            pendingStrategyPositionToken[_positionId] = path[path.length - 1];

            strategyPositions[_positionId].state = ActionState.ExitPending;

            pendingOrders[
                _getPositionKey(positionManager, false)
            ] = _positionId;
        } else {
            _exitStrategy(_positionId, position.user);
        }

        emit OrderCreated(_positionId, ActionState.ExitPending);
    }

    /**
     * @notice             Callback fn called by callback forwarder
     *                     contract (instead of gmx's position router)
     *                     after an order has been executed by gmx.
     * @param positionKey  Position key in gmx's position router.
     * @param isExecuted   Everything the order was executed order.
     */
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool
    ) external payable nonReentrant {
        _validate(whitelistedKeepers[msg.sender] == 1, 2);
        uint256 positionId = pendingOrders[positionKey];
        ActionState currentState = strategyPositions[positionId].state;

        if (currentState == ActionState.EnablePending) {
            if (isExecuted) {
                _enableStrategy(positionId);
                return;
            } else {
                _enableStrategyFail(positionId);
                return;
            }
        }
        if (currentState == ActionState.IncreasePending) {
            if (isExecuted) {
                strategyPositions[positionId].state = ActionState.Increased;
                return;
            } else {
                _increaseManagedPositionFail(positionId);
            }
            return;
        }

        if (currentState == ActionState.ExitPending) {
            _exitStrategy(positionId);
            return;
        }
    }

    /**
     * @notice            Exit strategy by abandoning the options position.
     *                    Can only be called if gmx position has no borrowed
     *                    collateral.
     * @param _positionId Id of the position in strategyPositions mapping .
     *
     */
    function emergencyStrategyExit(uint256 _positionId) public nonReentrant {
        (
            uint256 expiry,
            uint256 purchaseId,
            address indexToken,
            address collateralToken,
            address user,
            bool keepCollateral,
            ActionState state
        ) = getStrategyPosition(_positionId);

        if (msg.sender != user) {
            _validate(whitelistedKeepers[msg.sender] == 1, 2);
        }

        address atlanticPool = _getAtlanticPoolAddress({
            _indexToken: indexToken,
            _quoteToken: collateralToken,
            _expiry: expiry
        });

        // Position shouldn't be increased or have an increase order initationed
        _validate(
            state != ActionState.Increased &&
                state != ActionState.IncreasePending,
            26
        );

        delete pendingOrders[_getPositionKey(userPositionManagers(user), true)];

        if (keepCollateral) {
            (, uint256 amount) = _getOptionsPurchase(atlanticPool, purchaseId);

            _transfer({_token: indexToken, _to: user, _amount: amount});
        }

        _exitStrategy(_positionId, user);
    }

    /**
     * @notice                 Get strategy position details
     * @param _positionId      Id of the position in strategy positions
     *                         mapping
     * @return expiry
     * @return purchaseId      Options purchase id
     * @return indexToken      Address of the index token
     * @return collateralToken Address of the collateral token
     * @return user            Address of the strategy position owner
     * @return keepCollateral  Has deposited underlying to persist
     *                         borrowed collateral
     * @return state           State of the position from ActionState enum
     */
    function getStrategyPosition(
        uint256 _positionId
    )
        public
        view
        returns (uint256, uint256, address, address, address, bool, ActionState)
    {
        StrategyPosition memory position = strategyPositions[_positionId];
        return (
            position.expiry,
            position.atlanticsPurchaseId,
            position.indexToken,
            position.collateralToken,
            position.user,
            position.keepCollateral,
            position.state
        );
    }

    /**
     * @notice         Get fee charged on creating a strategy postion
     * @param _size    Size of the gmx position in 1e30 decimals
     * @param _toToken Address of the index token of the gmx position
     * @return fees    Fee amount in index token / _toToken decimals
     */
    function getPositionfee(
        uint256 _size,
        address _toToken,
        address _account
    ) public view returns (uint256 fees) {
        uint256 feeBps = feeStrategy.getFeeBps({
            feeType: STRATEGY_FEE_KEY,
            user: _account,
            useDiscount: useDiscountForFees == 1 ? true : false
        });
        uint256 usdWithFee = (_size * (10000000 + feeBps)) / 10000000;
        fees = IVault(vault).usdToTokenMin(_toToken, (usdWithFee - _size));
    }

    /**
     * @notice            Get strike amount added with offset bps of
     *                    the index token
     * @param _strike     Strike of the option
     * @param _pool Address of the index token / underlying
     *                     of the option
     */
    function getStrikeWithOffsetBps(
        uint256 _strike,
        address _pool
    ) public view returns (uint256 strikeWithOffset) {
        uint256 tickSize = IAtlanticPutsPool(_pool).getEpochTickSize(
            IAtlanticPutsPool(_pool).currentEpoch()
        );
        uint256 offset = (tickSize *
            (BPS_PRECISION + tickSizeMultiplierBps[_pool])) / BPS_PRECISION;
        strikeWithOffset = _strike + offset;
    }

    /**
     * @notice                  Fetch user's position manager.
     * @param _user             Address of the user.
     * @return _positionManager Address of the position manager.
     */
    function userPositionManagers(
        address _user
    ) public view returns (address _positionManager) {
        return
            IDopexPositionManagerFactory(positionManagerFactory)
                .userPositionManagers(_user);
    }

    function _exitStrategy(uint256 _positionId) private {
        StrategyPosition memory position = strategyPositions[_positionId];

        address pendingToken = pendingStrategyPositionToken[_positionId];

        IAtlanticPutsPool pool = IAtlanticPutsPool(
            _getAtlanticPoolAddress({
                _indexToken: position.indexToken,
                _quoteToken: position.collateralToken,
                _expiry: position.expiry
            })
        );

        (, uint256 unwindAmount) = _getOptionsPurchase(
            address(pool),
            position.atlanticsPurchaseId
        );

        uint256 receivedTokenAmount = IDopexPositionManager(
            userPositionManagers(position.user)
        ).withdrawTokens(_get1TokenSwapPath(pendingToken), address(this))[0];

        uint256 deductable;
        if (
            pool.getOptionsState(position.atlanticsPurchaseId) ==
            OptionsState.Unlocked
        ) {
            if (pendingToken == position.indexToken) {
                // if received tokens < unwind amount, use remaining token amount
                // Make exception if underlying was deposited
                if (
                    unwindAmount > receivedTokenAmount &&
                    !position.keepCollateral
                ) {
                    unwindAmount = receivedTokenAmount;
                }
                // unwind options
                pool.unwind(position.atlanticsPurchaseId, unwindAmount);

                if (!position.keepCollateral) {
                    deductable = unwindAmount;
                }
            } else {
                if (
                    pool
                        .getOptionsPurchase(position.atlanticsPurchaseId)
                        .state == OptionsState.Unlocked
                ) {
                    deductable = _getCollateralAccess(
                        address(pool),
                        position.atlanticsPurchaseId
                    );

                    if (deductable > receivedTokenAmount) {
                        deductable = receivedTokenAmount;
                    }
                    // Relock collateral
                    pool.relockCollateral(
                        position.atlanticsPurchaseId,
                        deductable
                    );
                }

                if (position.keepCollateral) {
                    _transfer({
                        _token: position.indexToken,
                        _to: position.user,
                        _amount: unwindAmount
                    });
                }
            }
        } else {
            if (position.keepCollateral) {
                _transfer(position.indexToken, position.user, unwindAmount);
            }
        }

        delete pendingStrategyPositionToken[_positionId];

        _exitStrategy(_positionId, position.user);

        _transfer({
            _token: pendingToken,
            _to: position.user,
            _amount: receivedTokenAmount - deductable
        });
    }

    /**
     * @notice            Get amount of a token received when
     *                    a position is closed before closing
     *                    the position and also considering if
     *                    options are ITM or not. if ITM then
     *                    token received will be the underlying
     *                    or indexToken, otherwise collateral token
     * @param _positionId ID of the position strategyPositions mapping
     * @return _tokenOut  Address of the token out.
     * @return _amount    Amount of _tokenOut receivable.
     */
    function getAmountAndTokenReceviedOnExit(
        uint256 _positionId
    ) public view returns (address _tokenOut, uint256 _amount) {
        StrategyPosition memory position = strategyPositions[_positionId];
        address positionManager = userPositionManagers(position.user);

        uint256 collateralAccess = _getCollateralAccess(
            _getAtlanticPoolAddress({
                _indexToken: position.indexToken,
                _quoteToken: position.collateralToken,
                _expiry: position.expiry
            }),
            position.atlanticsPurchaseId
        );

        uint256 marginFees = utils.getMarginFees({
            _positionManager: positionManager,
            _indexToken: position.indexToken,
            _convertTo: position.collateralToken
        });

        _amount = utils.getAmountReceivedOnExitPosition({
            _positionManager: userPositionManagers(position.user),
            _indexToken: position.indexToken,
            _outToken: position.collateralToken
        });

        if (_amount > collateralAccess) {
            _tokenOut = position.collateralToken;

            _amount = utils.getAmountIn({
                _amountOut: collateralAccess + marginFees,
                _slippage: IDopexPositionManager(positionManager)
                    .minSlippageBps(),
                _tokenOut: position.collateralToken,
                _tokenIn: position.indexToken
            });

            _amount = IVault(vault).tokenToUsdMin(position.indexToken, _amount);
        } else {
            _tokenOut = position.indexToken;
        }
    }

    /**
     * @notice            Delete states related strategy positions.
     * @param _positionId Id of the strategy position.
     * @param _user       Address of the user
     */
    function _exitStrategy(uint256 _positionId, address _user) private {
        delete strategyPositions[_positionId].atlanticsPurchaseId;
        delete strategyPositions[_positionId].expiry;
        delete strategyPositions[_positionId].keepCollateral;
        strategyPositions[_positionId].state = ActionState.Settled;
        strategyPositions[_positionId].user = _user;
        IDopexPositionManager(userPositionManagers(_user)).release();
    }

    /**
     * @notice                 Save/replace a new strategy position for a user.
     * @param _positionId      Id of the strategy position.
     * @param _expiry          Expiry of the AP options.
     * @param _indexToken      Address of the index token.
     * @param _collateralToken Address of the collateral token.
     * @param _keepCollateral  To deposit underlying or not.
     */
    function _newStrategyPosition(
        uint256 _positionId,
        uint256 _expiry,
        address _indexToken,
        address _collateralToken,
        bool _keepCollateral
    ) private {
        strategyPositions[_positionId].expiry = _expiry;
        strategyPositions[_positionId].indexToken = _indexToken;
        strategyPositions[_positionId].collateralToken = _collateralToken;
        strategyPositions[_positionId].user = msg.sender;
        strategyPositions[_positionId].keepCollateral = _keepCollateral;
        strategyPositions[_positionId].state = ActionState.EnablePending;
    }

    /**
     * @notice            Fallback for failure of execution of gmx position
     *                    order. User is refunded their collateral they used
     *                    to open the position.
     * @param _positionId ID of the strategy position.
     */
    function _enableStrategyFail(uint256 _positionId) private {
        StrategyPosition memory position = strategyPositions[_positionId];
        address positionManager = userPositionManagers(position.user);

        delete pendingOrders[_getPositionKey(positionManager, true)];

        strategyPositions[_positionId].state = ActionState.None;

        IDopexPositionManager(positionManager).withdrawTokens(
            _get1TokenSwapPath(position.collateralToken),
            position.user
        );

        _exitStrategy(_positionId, position.user);
    }

    /**
     * @notice            Fallback on successful exeuction of gmx position
     *                    order. In this fall back options are purchased
     *                    and underlying is collected if enabled to.
     * @param _positionId ID of the strategy position.
     */
    function _enableStrategy(uint256 _positionId) private {
        StrategyPosition memory position = strategyPositions[_positionId];

        address positionManager = userPositionManagers(position.user);

        address atlanticPool = _getAtlanticPoolAddress({
            _indexToken: position.indexToken,
            _quoteToken: position.collateralToken,
            _expiry: position.expiry
        });

        uint256 putStrike = utils.getEligiblePutStrike({
            _atlanticPool: atlanticPool,
            _offset: tickSizeMultiplierBps[atlanticPool],
            _liquidationPrice: utils.getLiquidationPrice(
                positionManager,
                position.indexToken
            ) / 1e22
        });

        uint256 optionsAmount = utils.getRequiredAmountOfOptionsForInsurance({
            _putStrike: putStrike,
            _positionManager: positionManager,
            _indexToken: position.indexToken,
            _quoteToken: position.collateralToken
        });

        IAtlanticPutsPool pool = IAtlanticPutsPool(atlanticPool);

        uint256 optionsCosts = pool.calculatePremium({
            _strike: putStrike,
            _amount: optionsAmount
        }) +
            pool.calculatePurchaseFees({
                account: position.user,
                strike: putStrike,
                amount: optionsAmount
            });

        _transferFrom(
            position.collateralToken,
            position.user,
            address(this),
            optionsCosts
        );

        strategyPositions[_positionId].atlanticsPurchaseId = pool.purchase({
            _strike: putStrike,
            _amount: optionsAmount,
            _delegate: address(this),
            _account: position.user
        });

        strategyPositions[_positionId].state = ActionState.Active;

        if (position.keepCollateral) {
            _transferFrom({
                _token: position.indexToken,
                _from: position.user,
                _to: address(this),
                _amount: optionsAmount
            });
        }

        ICallbackForwarder(positionManagerFactory.callback())
            .createIncreaseOrder(_positionId);

        emit StrategyEnabled(_positionId, putStrike, optionsAmount);
    }

    /**
     * @notice            Fallback for handling failure of adding collateral
     *                    to the gmx position. Collateral unlocked is relocked
     *                    back to the options pool.
     * @param _positionId ID of the strategy position.
     */
    function _increaseManagedPositionFail(uint256 _positionId) private {
        StrategyPosition memory position = strategyPositions[_positionId];

        uint256 receivedTokenAmount = IDopexPositionManager(
            userPositionManagers(position.user)
        ).withdrawTokens(
                _get1TokenSwapPath(position.collateralToken),
                address(this)
            )[0];

        IAtlanticPutsPool pool = IAtlanticPutsPool(
            _getAtlanticPoolAddress({
                _indexToken: position.indexToken,
                _quoteToken: position.collateralToken,
                _expiry: position.expiry
            })
        );

        uint256 collateralAccess = _getCollateralAccess(
            address(pool),
            position.atlanticsPurchaseId
        );

        if (receivedTokenAmount > collateralAccess) {
            _transfer({
                _token: position.collateralToken,
                _to: position.user,
                _amount: receivedTokenAmount - collateralAccess
            });
        }

        pool.relockCollateral(position.atlanticsPurchaseId, collateralAccess);

        strategyPositions[_positionId].state = ActionState.Active;

        ICallbackForwarder(positionManagerFactory.callback())
            .createIncreaseOrder(_positionId);
    }

    /**
     * @notice              Collect strategy fees.
     * @param _positionSize Size of the gmx position.
     * @param _tokenIn      Address of the token used
     *                      to open the gmx position with.
     */
    function _collectStrategyPositionFee(
        uint256 _positionSize,
        address _tokenIn
    ) private {
        uint256 fee = getPositionfee(_positionSize, _tokenIn, msg.sender);
        _transferFrom(_tokenIn, msg.sender, feeDistributor, fee);
        emit StrategyFeesCollected(fee);
    }

    /**
     * @notice        Check whether block.timestamp is
     *                within keeper handler window.
     * @param _expiry Expiry of the options associated with
     *                the gmx position.
     */
    function _isKeeperHandleWindow(
        uint256 _expiry
    ) private view returns (bool isInWindow) {
        return block.timestamp > _expiry - keeperHandleWindow;
    }

    /**
     * @notice             Get address of an atlantic pool.
     * @param _indexToken  Address of the index token/ base token.
     * @param _quoteToken  Address of the quote token / collateral token.
     * @param _expiry      Expiry timestamp of the pool.
     * @return poolAddress Address of the atlantic pool.
     */
    function _getAtlanticPoolAddress(
        address _indexToken,
        address _quoteToken,
        uint256 _expiry
    ) private view returns (address poolAddress) {
        return
            whitelistedAtlanticPools[
                _getPoolKey(_indexToken, _quoteToken, _expiry)
            ];
    }

    /**
     * @notice             AP addresses are stored with keys of bytes32.
     *                     hence, helper fn to generate the key.
     * @param _indexToken  Address of the index token/ base token.
     * @param _quoteToken  Address of the quote token / collateral token.
     * @param _expiry      Expiry timestamp of the pool
     */
    function _getPoolKey(
        address _indexToken,
        address _quoteToken,
        uint256 _expiry
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_indexToken, _quoteToken, _expiry));
    }

    /**
     * @notice                       Set/Add an atlantic pool usable by
     *                               this strategy contract.
     * @param _poolAddress           Address of the pool.
     * @param _indexToken            Address of the index token/ base token.
     * @param _quoteToken            Address of the quote token / collateral token.
     * @param _expiry                Expiry timestamp of the pool
     * @param _tickSizeMultiplierBps Buffer for purchasing put strike.
     */
    function setAtlanticPool(
        address _poolAddress,
        address _indexToken,
        address _quoteToken,
        uint256 _expiry,
        uint256 _tickSizeMultiplierBps
    ) external onlyGov {
        whitelistedAtlanticPools[
            _getPoolKey(_indexToken, _quoteToken, _expiry)
        ] = _poolAddress;
        tickSizeMultiplierBps[_poolAddress] = _tickSizeMultiplierBps;

        IERC20(_indexToken).approve(_poolAddress, type(uint256).max);
        IERC20(_quoteToken).approve(_poolAddress, type(uint256).max);
    }

    /**
     * @notice             Set max leverage for opening positions throuugh this
     *                     Strategy contract.
     * @param _maxLeverage Max leverage allowable.
     */
    function setMaxLeverage(uint256 _maxLeverage) external onlyGov {
        maxLeverage = _maxLeverage;
        emit MaxLeverageSet(_maxLeverage);
    }

    /**
     * @notice        Set amount of seconds before options expiry.
     *                keepers are allowed handle positions (or create
     *                orders).
     * @param _window Amount of seconds.
     */
    function setKeeperhandleWindow(uint256 _window) external onlyGov {
        keeperHandleWindow = _window;
        emit KeeperHandleWindowSet(_window);
    }

    /**
     * @notice        Set a keeper who can call:
     *                createIncreaseOrder()
     *                createExitOrder()
     *                emergencyStrategyExit()
     * @param _keeper Address of the keeper.
     * @param _setAs  True = can keep, false = cannot.
     */
    function setKeeper(address _keeper, bool _setAs) external onlyGov {
        whitelistedKeepers[_keeper] = _setAs ? 1 : 0;
        emit KeeperSet(_keeper, _setAs);
    }

    /**
     * @notice                         Set addresses of contracts used by the strategy.
     * @param _feeDistributor          Address of the fee distributor.
     * @param _utils                   Address of the utils/calculations contract.
     * @param _positionManagerFactory  Address of the position manager factory.
     * @param _gov,                    Address of the gov.
     * @param _feeStrategy             Address of dopex fee strategy contract.
     */
    function setAddresses(
        address _feeDistributor,
        address _utils,
        address _positionManagerFactory,
        address _gov,
        address _feeStrategy
    ) external onlyGov {
        feeDistributor = _feeDistributor;
        utils = IInsuredLongsUtils(_utils);
        positionManagerFactory = IDopexPositionManagerFactory(
            _positionManagerFactory
        );

        feeStrategy = IDopexFeeStrategy(_feeStrategy);
        feeDistributor = _feeDistributor;
        gov = _gov;

        emit AddressesSet(
            _feeDistributor,
            _utils,
            _positionManagerFactory,
            _gov,
            _feeStrategy
        );
    }

    /**
     * @notice Add a contract to the whitelist
     * @dev    Can only be called by the owner
     * @param _contract Address of the contract that needs to be added to the whitelist
     */
    function addToContractWhitelist(address _contract) external onlyGov {
        _addToContractWhitelist(_contract);
    }

    /**
     * @notice Add a contract to the whitelist
     * @dev    Can only be called by the owner
     * @param _contract Address of the contract that needs to be added to the whitelist
     */
    function removeFromContractWhitelist(address _contract) external onlyGov {
        _removeFromContractWhitelist(_contract);
    }

    function setUseDiscountForFees(
        bool _setAs
    ) external onlyGov returns (bool) {
        useDiscountForFees = _setAs ? 1 : 0;
        return true;
    }

    /**
     * @notice Pauses the vault for emergency cases
     * @dev     Can only be called by DEFAULT_ADMIN_ROLE
     * @return  Whether it was successfully paused
     */
    function pause() external onlyGov returns (bool) {
        _pause();
        return true;
    }

    /**
     *  @notice Unpauses the vault
     *  @dev    Can only be called by DEFAULT_ADMIN_ROLE
     *  @return success it was successfully unpaused
     */
    function unpause() external onlyGov returns (bool) {
        _unpause();
        return true;
    }

    function _updateGmxVaultCummulativeFundingRate(address _token) private {
        IVault(vault).updateCumulativeFundingRate(_token);
    }

    /**
     * @notice               Transfers all funds to msg.sender
     * @dev                  Can only be called by DEFAULT_ADMIN_ROLE
     * @param tokens         The list of erc20 tokens to withdraw
     * @param transferNative Whether should transfer the native currency
     */
    function emergencyWithdraw(
        address[] calldata tokens,
        bool transferNative
    ) external onlyGov returns (bool) {
        _whenPaused();
        if (transferNative) payable(gov).transfer(address(this).balance);

        for (uint256 i; i < tokens.length; ) {
            _transfer(
                tokens[i],
                gov,
                IERC20(tokens[i]).balanceOf(address(this))
            );
            unchecked {
                ++i;
            }
        }

        return true;
    }

    /**
     * @notice              Fetch options purchase data from AP.
     * @param _atlanticPool Address of the atlantic pool.
     * @param _purchaseId   ID of the options purchase.
     * @return strike       Strike of the options.
     * @return amount       Amount of options.
     */
    function _getOptionsPurchase(
        address _atlanticPool,
        uint256 _purchaseId
    ) private view returns (uint256 strike, uint256 amount) {
        OptionsPurchase memory position = IAtlanticPutsPool(_atlanticPool)
            .getOptionsPurchase(_purchaseId);
        strike = position.optionStrike;
        amount = position.optionsAmount;
    }

    /**
     * @notice                  Fetch Collateral access or amount of
     *                          collateral a gmx position can borrow
     *                          against the AP options.
     * @param _atlanticPool     Address of the atlantic pool the op-
     *                          tions were purchased from.
     * @param _purchaseId       ID of the options purchase.
     * @return collateralAccess Amount of collateral access.
     */
    function _getCollateralAccess(
        address _atlanticPool,
        uint256 _purchaseId
    ) private view returns (uint256 collateralAccess) {
        (uint256 strike, uint256 amount) = _getOptionsPurchase(
            _atlanticPool,
            _purchaseId
        );
        collateralAccess = IAtlanticPutsPool(_atlanticPool).strikeMulAmount(
            strike,
            amount
        );
    }

    /**
     * @notice             Fetch gmx position size and collateral.
     * @param _positionId  ID of the position in strategy positions.
     * @return _size       Size of the gmx position.
     * @return _collateral Collateral balance of the gmx position
     */
    function _getPosition(
        uint256 _positionId
    ) private view returns (uint256 _size, uint256 _collateral) {
        (_size, _collateral, , , , , , ) = IVault(vault).getPosition(
            userPositionManagers(strategyPositions[_positionId].user),
            strategyIndexToken,
            strategyIndexToken,
            true
        );
    }

    /**
     * @notice Fetch the unique key created when a position manager
     *         calls GMX position router contract to create an order
     *         the return key is directly linked to the order in the GMX
     *         position router contract.
     * @param  _positionManager Address of the position manager
     * @param  _isIncrease      Whether to create an order to increase
     *                          collateral size of a position or decrease
     *                          it.
     * @return key
     */
    function _getPositionKey(
        address _positionManager,
        bool _isIncrease
    ) private view returns (bytes32 key) {
        IPositionRouter _positionRouter = IPositionRouter(positionRouter);

        if (_isIncrease) {
            key = _positionRouter.getRequestKey(
                _positionManager,
                _positionRouter.increasePositionsIndex(_positionManager)
            );
        } else {
            key = _positionRouter.getRequestKey(
                _positionManager,
                _positionRouter.decreasePositionsIndex(_positionManager)
            );
        }
    }

    /**
     * @notice Create and return an array of 1 item.
     * @param _token Address of the token.
     * @return path
     */
    function _get1TokenSwapPath(
        address _token
    ) private pure returns (address[] memory path) {
        path = new address[](1);
        path[0] = _token;
    }

    /**
     * @notice Create and return an 2 item array of addresses used for
     *         swapping.
     * @param _token1 Token in or input token.
     * @param _token2 Token out or output token.
     * @return path
     */
    function _get2TokenSwapPath(
        address _token1,
        address _token2
    ) private pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
    }

    function _validteNotWithinExerciseWindow(
        address _atlanticPool
    ) private view {
        _validate(
            !IAtlanticPutsPool(_atlanticPool).isWithinExerciseWindow(),
            34
        );
    }

    modifier onlyGov() {
        _validate(msg.sender == gov, 32);
        _;
    }

    function _transfer(address _token, address _to, uint256 _amount) internal {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function _transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    function _validate(bool trueCondition, uint256 errorCode) private pure {
        if (!trueCondition) {
            revert InsuredLongsStrategyError(errorCode);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface ICallbackForwarder {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool
    ) external;

    function createIncreaseOrder(uint256 _positionId) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Structs
struct IncreaseOrderParams {
    address[] path;
    address indexToken;
    uint256 collateralDelta;
    uint256 positionSizeDelta;
    uint256 acceptablePrice;
    bool isLong;
}

struct DecreaseOrderParams {
    IncreaseOrderParams orderParams;
    address receiver;
    bool withdrawETH;
}

interface IDopexPositionManager {
    function enableAndCreateIncreaseOrder(
        IncreaseOrderParams calldata params,
        address _gmxVault,
        address _gmxRouter,
        address _gmxPositionRouter,
        address _user
    ) external payable;

    function increaseOrder(IncreaseOrderParams memory _increaseOrderParams) external payable;

    function decreaseOrder(DecreaseOrderParams calldata _decreaseorderParams) external payable;

    function release() external;

    function minSlippageBps() external view returns (uint256);

    function setStrategyController(address _strategy) external;

    function withdrawTokens(
        address[] calldata _tokens,
        address _receiver
    ) external returns (uint256[] memory _amounts);

    function strategyControllerTransfer(
        address _token,
        address _to,
        uint256 amount
    ) external;

    function lock() external;

    function slippage() external view returns (uint256);

    event IncreaseOrderCreated(
        address[] _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    );
    event DecreaseOrderCreated(
        address[] _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    );
    event ReferralCodeSet(bytes32 _newReferralCode);
    event Released();
    event Locked();
    event TokensWithdrawn(address[] tokens, uint256[] amounts);
    event SlippageSet(uint256 _slippage);
    event CallbackSet(address _callback);
    event FactorySet(address _factory);
    event StrategyControllerSet(address _strategy);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IDopexPositionManagerFactory {
    function createPositionmanager(address _user) external returns (address positionManager);
    function callback() external view returns (address);
    function minSlipageBps() external view returns (uint256);
    function userPositionManagers(address _user) external view returns (address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IInsuredLongsStrategy {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool
    ) external payable;

    function positionsCount() external view returns (uint256);

    function getStrategyPosition(
        uint256 _positionId
    )
        external
        view
        returns (
            uint256,
            uint256,
            address,
            address,
            address,
            bool,
            ActionState
        );

    function createExitStrategyOrder(
        uint256 _positionId,
        address _withdrawAs,
        bool _exitLongPosition
    ) external payable;

    function createIncreaseManagedPositionOrder(
        uint256 _positionId
    ) external payable;

    event StrategyEnabled(
        uint256 positionId,
        uint256 putstrike,
        uint256 optionsAmount
    );
    event OrderCreated(uint256 positionId, ActionState _newState);
    event StrategyFeesCollected(uint256 fees);
    event MaxLeverageSet(uint256 _maxLeverage);
    event KeeperHandleWindowSet(uint256 _window);
    event KeeperSet(address _keeper, bool setAs);
    event AddressesSet(
        address _feeDistributor,
        address _utils,
        address _positionManagerFactory,
        address _gov,
        address _feeStrategy
    );

    error InsuredLongsStrategyError(uint256 _errorCode);

    enum ActionState {
        None, // 0
        Settled, // 1
        Active, // 2
        IncreasePending, // 3
        Increased, // 4
        EnablePending, // 5
        ExitPending // 6
    }

    struct StrategyPosition {
        uint256 expiry;
        uint256 atlanticsPurchaseId;
        address indexToken;
        address collateralToken;
        address user;
        bool keepCollateral;
        ActionState state;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IInsuredLongsUtils {
    function getLiquidationPrice(
        address _positionManager,
        address _indexToken
    ) external view returns (uint256 liquidationPrice);

    function getLiquidationPrice(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getRequiredAmountOfOptionsForInsurance(
        address _atlanticPool,
        address _collateralToken,
        address _indexToken,
        uint256 _size,
        uint256 _collateral,
        uint256 _putStrike
    ) external view returns (uint256 optionsAmount);

    function getRequiredAmountOfOptionsForInsurance(
        uint256 _putStrike,
        address _positionManager,
        address _indexToken,
        address _quoteToken
    ) external view returns (uint256 optionsAmount);

    function getEligiblePutStrike(
        address _atlanticPool,
        uint256 _offset,
        uint256 _liquidationPrice
    ) external view returns (uint256 eligiblePutStrike);

    function getPositionKey(
        address _positionManager,
        bool isIncrease
    ) external view returns (bytes32 key);

    function getPositionLeverage(
        address _positionManager,
        address _indexToken
    ) external view returns (uint256);

    function getLiquidatablestate(
        address _positionManager,
        address _indexToken,
        address _collateralToken,
        address _atlanticPool,
        uint256 _purchaseId,
        bool _isIncreased
    ) external view returns (uint256 _usdOut, address _outToken);

    function getAtlanticUnwindCosts(
        address _atlanticPool,
        uint256 _purchaseId,
        bool
    ) external view returns (uint256);

    function get1TokenSwapPath(
        address _token
    ) external pure returns (address[] memory path);

    function get2TokenSwapPath(
        address _token1,
        address _token2
    ) external pure returns (address[] memory path);

    function getOptionsPurchase(
        address _atlanticPool,
        uint256 purchaseId
    ) external view returns (uint256, uint256);

    function getPrice(address _token) external view returns (uint256 _price);

    function getCollateralAccess(
        address atlanticPool,
        uint256 _purchaseId
    ) external view returns (uint256 _collateralAccess);

    function getFundingFee(
        address _indexToken,
        address _positionManager,
        address _convertTo
    ) external view returns (uint256 fundingFee);

    function getAmountIn(
        uint256 _amountOut,
        uint256 _slippage,
        address _tokenOut,
        address _tokenIn
    ) external view returns (uint256 _amountIn);

    function getPositionSize(
        address _positionManager,
        address _indexToken
    ) external view returns (uint256 size);

    function getPositionFee(
        uint256 _size
    ) external view returns (uint256 feeUsd);

    function getAmountReceivedOnExitPosition(
        address _positionManager,
        address _indexToken,
        address _outToken
    ) external view returns (uint256 amountOut);

    function getStrategyExitSwapPath(
        address _atlanticPool,
        uint256 _purchaseId
    ) external view returns (address[] memory path);

    function validateIncreaseExecution(
        uint256 _collateralSize,
        uint256 _size,
        address _collateralToken,
        address _indexToken
    ) external view returns (bool);

    function validateUnwind(
        address _positionManager,
        address _indexToken,
        address _atlanticPool,
        uint256 _purchaseId
    ) external view returns (bool);

    function getUsdOutForUnwindWithFee(
        address _positionManager,
        address _indexToken,
        address _atlanticPool,
        uint256 _purchaseId
    ) external view returns (uint256 _usdOut);

    function calculateCollateral(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralAmount,
        uint256 _size
    ) external view returns (uint256 collateral);

    function calculateLeverage(
        uint256 _size,
        uint256 _collateral,
        address _collateralToken
    ) external view returns (uint256 _leverage);

    function getMinUnwindablePrice(
        address _positionManager,
        address _atlanticPool,
        address _indexToken,
        uint256 _purchaseId,
        uint256 _offset
    ) external view returns (bool isLiquidatable);


   function validateDecreaseCollateralDelta(
        address _positionManager,
        address _indexToken,
        uint256 _collateralDelta
    ) external view returns (bool valid);

       function getMarginFees(
        address _positionManager,
        address _indexToken,
        address _convertTo
    ) external view returns (uint256 fees);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
/// @dev While the ownable portion follows [EIP-173](https://eips.ethereum.org/EIPS/eip-173)
/// for compatibility, the nomenclature for the 2-step ownership handover
/// may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /// @dev `bytes4(keccak256(bytes("Unauthorized()")))`.
    uint256 private constant _UNAUTHORIZED_ERROR_SELECTOR = 0x82b42900;

    /// @dev `bytes4(keccak256(bytes("NewOwnerIsZeroAddress()")))`.
    uint256 private constant _NEW_OWNER_IS_ZERO_ADDRESS_ERROR_SELECTOR = 0x7448fbae;

    /// @dev `bytes4(keccak256(bytes("NoHandoverRequest()")))`.
    uint256 private constant _NO_HANDOVER_REQUEST_ERROR_SELECTOR = 0x6f5e8818;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by: `not(_OWNER_SLOT_NOT)`.
    /// It is intentionally choosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
            sstore(ownerSlot, newOwner)
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        if (newOwner == address(0)) revert NewOwnerIsZeroAddress();
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will be automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, _NO_HANDOVER_REQUEST_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    function ownershipHandoverValidFor() public view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

/// @notice Simple single owner and multiroles authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
/// @dev While the ownable portion follows [EIP-173](https://eips.ethereum.org/EIPS/eip-173)
/// for compatibility, the nomenclature for the 2-step ownership handover and roles
/// may be unique to this codebase.
abstract contract OwnableRoles is Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `bytes4(keccak256(bytes("Unauthorized()")))`.
    uint256 private constant _UNAUTHORIZED_ERROR_SELECTOR = 0x82b42900;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The `user`'s roles is updated to `roles`.
    /// Each bit of `roles` represents whether the role is set.
    event RolesUpdated(address indexed user, uint256 indexed roles);

    /// @dev `keccak256(bytes("RolesUpdated(address,uint256)"))`.
    uint256 private constant _ROLES_UPDATED_EVENT_SIGNATURE =
        0x715ad5ce61fc9595c7b415289d59cf203f23a94fa06f04af7e489a0a76e1fe26;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The role slot of `user` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _ROLE_SLOT_SEED))
    ///     let roleSlot := keccak256(0x00, 0x20)
    /// ```
    /// This automatically ignores the upper bits of the `user` in case
    /// they are not clean, as well as keep the `keccak256` under 32-bytes.
    ///
    /// Note: This is equal to `_OWNER_SLOT_NOT` in for gas efficiency.
    uint256 private constant _ROLE_SLOT_SEED = 0x8b78c6d8;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Grants the roles directly without authorization guard.
    /// Each bit of `roles` represents the role to turn on.
    function _grantRoles(address user, uint256 roles) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, user)
            let roleSlot := keccak256(0x0c, 0x20)
            // Load the current value and `or` it with `roles`.
            roles := or(sload(roleSlot), roles)
            // Store the new value.
            sstore(roleSlot, roles)
            // Emit the {RolesUpdated} event.
            log3(0, 0, _ROLES_UPDATED_EVENT_SIGNATURE, shr(96, mload(0x0c)), roles)
        }
    }

    /// @dev Removes the roles directly without authorization guard.
    /// Each bit of `roles` represents the role to turn off.
    function _removeRoles(address user, uint256 roles) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, user)
            let roleSlot := keccak256(0x0c, 0x20)
            // Load the current value.
            let currentRoles := sload(roleSlot)
            // Use `and` to compute the intersection of `currentRoles` and `roles`,
            // `xor` it with `currentRoles` to flip the bits in the intersection.
            roles := xor(currentRoles, and(currentRoles, roles))
            // Then, store the new value.
            sstore(roleSlot, roles)
            // Emit the {RolesUpdated} event.
            log3(0, 0, _ROLES_UPDATED_EVENT_SIGNATURE, shr(96, mload(0x0c)), roles)
        }
    }

    /// @dev Throws if the sender does not have any of the `roles`.
    function _checkRoles(uint256 roles) internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, caller())
            // Load the stored value, and if the `and` intersection
            // of the value and `roles` is zero, revert.
            if iszero(and(sload(keccak256(0x0c, 0x20)), roles)) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Throws if the sender is not the owner,
    /// and does not have any of the `roles`.
    /// Checks for ownership first, then lazily checks for roles.
    function _checkOwnerOrRoles(uint256 roles) internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner.
            // Note: `_ROLE_SLOT_SEED` is equal to `_OWNER_SLOT_NOT`.
            if iszero(eq(caller(), sload(not(_ROLE_SLOT_SEED)))) {
                // Compute the role slot.
                mstore(0x0c, _ROLE_SLOT_SEED)
                mstore(0x00, caller())
                // Load the stored value, and if the `and` intersection
                // of the value and `roles` is zero, revert.
                if iszero(and(sload(keccak256(0x0c, 0x20)), roles)) {
                    mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @dev Throws if the sender does not have any of the `roles`,
    /// and is not the owner.
    /// Checks for roles first, then lazily checks for ownership.
    function _checkRolesOrOwner(uint256 roles) internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, caller())
            // Load the stored value, and if the `and` intersection
            // of the value and `roles` is zero, revert.
            if iszero(and(sload(keccak256(0x0c, 0x20)), roles)) {
                // If the caller is not the stored owner.
                // Note: `_ROLE_SLOT_SEED` is equal to `_OWNER_SLOT_NOT`.
                if iszero(eq(caller(), sload(not(_ROLE_SLOT_SEED)))) {
                    mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to grant `user` `roles`.
    /// If the `user` already has a role, then it will be an no-op for the role.
    function grantRoles(address user, uint256 roles) public payable virtual onlyOwner {
        _grantRoles(user, roles);
    }

    /// @dev Allows the owner to remove `user` `roles`.
    /// If the `user` does not have a role, then it will be an no-op for the role.
    function revokeRoles(address user, uint256 roles) public payable virtual onlyOwner {
        _removeRoles(user, roles);
    }

    /// @dev Allow the caller to remove their own roles.
    /// If the caller does not have a role, then it will be an no-op for the role.
    function renounceRoles(uint256 roles) public payable virtual {
        _removeRoles(msg.sender, roles);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `user` has any of `roles`.
    function hasAnyRole(address user, uint256 roles) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, user)
            // Load the stored value, and set the result to whether the
            // `and` intersection of the value and `roles` is not zero.
            result := iszero(iszero(and(sload(keccak256(0x0c, 0x20)), roles)))
        }
    }

    /// @dev Returns whether `user` has all of `roles`.
    function hasAllRoles(address user, uint256 roles) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, user)
            // Whether the stored value is contains all the set bits in `roles`.
            result := eq(and(sload(keccak256(0x0c, 0x20)), roles), roles)
        }
    }

    /// @dev Returns the roles of `user`.
    function rolesOf(address user) public view virtual returns (uint256 roles) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, user)
            // Load the stored value.
            roles := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Convenience function to return a `roles` bitmap from an array of `ordinals`.
    /// This is meant for frontends like Etherscan, and is therefore not fully optimized.
    /// Not recommended to be called on-chain.
    function rolesFromOrdinals(uint8[] memory ordinals) public pure returns (uint256 roles) {
        /// @solidity memory-safe-assembly
        assembly {
            for { let i := shl(5, mload(ordinals)) } i { i := sub(i, 0x20) } {
                // We don't need to mask the values of `ordinals`, as Solidity
                // cleans dirty upper bits when storing variables into memory.
                roles := or(shl(mload(add(ordinals, i)), 1), roles)
            }
        }
    }

    /// @dev Convenience function to return an array of `ordinals` from the `roles` bitmap.
    /// This is meant for frontends like Etherscan, and is therefore not fully optimized.
    /// Not recommended to be called on-chain.
    function ordinalsFromRoles(uint256 roles) public pure returns (uint8[] memory ordinals) {
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the pointer to the free memory.
            ordinals := mload(0x40)
            let ptr := add(ordinals, 0x20)
            let o := 0
            // The absence of lookup tables, De Bruijn, etc., here is intentional for
            // smaller bytecode, as this function is not meant to be called on-chain.
            for { let t := roles } 1 {} {
                mstore(ptr, o)
                // `shr` 5 is equivalent to multiplying by 0x20.
                // Push back into the ordinals array if the bit is set.
                ptr := add(ptr, shl(5, and(t, 1)))
                o := add(o, 1)
                t := shr(o, roles)
                if iszero(t) { break }
            }
            // Store the length of `ordinals`.
            mstore(ordinals, shr(5, sub(ptr, add(ordinals, 0x20))))
            // Allocate the memory.
            mstore(0x40, ptr)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by an account with `roles`.
    modifier onlyRoles(uint256 roles) virtual {
        _checkRoles(roles);
        _;
    }

    /// @dev Marks a function as only callable by the owner or by an account
    /// with `roles`. Checks for ownership first, then lazily checks for roles.
    modifier onlyOwnerOrRoles(uint256 roles) virtual {
        _checkOwnerOrRoles(roles);
        _;
    }

    /// @dev Marks a function as only callable by an account with `roles`
    /// or the owner. Checks for roles first, then lazily checks for ownership.
    modifier onlyRolesOrOwner(uint256 roles) virtual {
        _checkRolesOrOwner(roles);
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ROLE CONSTANTS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // IYKYK

    uint256 internal constant _ROLE_0 = 1 << 0;
    uint256 internal constant _ROLE_1 = 1 << 1;
    uint256 internal constant _ROLE_2 = 1 << 2;
    uint256 internal constant _ROLE_3 = 1 << 3;
    uint256 internal constant _ROLE_4 = 1 << 4;
    uint256 internal constant _ROLE_5 = 1 << 5;
    uint256 internal constant _ROLE_6 = 1 << 6;
    uint256 internal constant _ROLE_7 = 1 << 7;
    uint256 internal constant _ROLE_8 = 1 << 8;
    uint256 internal constant _ROLE_9 = 1 << 9;
    uint256 internal constant _ROLE_10 = 1 << 10;
    uint256 internal constant _ROLE_11 = 1 << 11;
    uint256 internal constant _ROLE_12 = 1 << 12;
    uint256 internal constant _ROLE_13 = 1 << 13;
    uint256 internal constant _ROLE_14 = 1 << 14;
    uint256 internal constant _ROLE_15 = 1 << 15;
    uint256 internal constant _ROLE_16 = 1 << 16;
    uint256 internal constant _ROLE_17 = 1 << 17;
    uint256 internal constant _ROLE_18 = 1 << 18;
    uint256 internal constant _ROLE_19 = 1 << 19;
    uint256 internal constant _ROLE_20 = 1 << 20;
    uint256 internal constant _ROLE_21 = 1 << 21;
    uint256 internal constant _ROLE_22 = 1 << 22;
    uint256 internal constant _ROLE_23 = 1 << 23;
    uint256 internal constant _ROLE_24 = 1 << 24;
    uint256 internal constant _ROLE_25 = 1 << 25;
    uint256 internal constant _ROLE_26 = 1 << 26;
    uint256 internal constant _ROLE_27 = 1 << 27;
    uint256 internal constant _ROLE_28 = 1 << 28;
    uint256 internal constant _ROLE_29 = 1 << 29;
    uint256 internal constant _ROLE_30 = 1 << 30;
    uint256 internal constant _ROLE_31 = 1 << 31;
    uint256 internal constant _ROLE_32 = 1 << 32;
    uint256 internal constant _ROLE_33 = 1 << 33;
    uint256 internal constant _ROLE_34 = 1 << 34;
    uint256 internal constant _ROLE_35 = 1 << 35;
    uint256 internal constant _ROLE_36 = 1 << 36;
    uint256 internal constant _ROLE_37 = 1 << 37;
    uint256 internal constant _ROLE_38 = 1 << 38;
    uint256 internal constant _ROLE_39 = 1 << 39;
    uint256 internal constant _ROLE_40 = 1 << 40;
    uint256 internal constant _ROLE_41 = 1 << 41;
    uint256 internal constant _ROLE_42 = 1 << 42;
    uint256 internal constant _ROLE_43 = 1 << 43;
    uint256 internal constant _ROLE_44 = 1 << 44;
    uint256 internal constant _ROLE_45 = 1 << 45;
    uint256 internal constant _ROLE_46 = 1 << 46;
    uint256 internal constant _ROLE_47 = 1 << 47;
    uint256 internal constant _ROLE_48 = 1 << 48;
    uint256 internal constant _ROLE_49 = 1 << 49;
    uint256 internal constant _ROLE_50 = 1 << 50;
    uint256 internal constant _ROLE_51 = 1 << 51;
    uint256 internal constant _ROLE_52 = 1 << 52;
    uint256 internal constant _ROLE_53 = 1 << 53;
    uint256 internal constant _ROLE_54 = 1 << 54;
    uint256 internal constant _ROLE_55 = 1 << 55;
    uint256 internal constant _ROLE_56 = 1 << 56;
    uint256 internal constant _ROLE_57 = 1 << 57;
    uint256 internal constant _ROLE_58 = 1 << 58;
    uint256 internal constant _ROLE_59 = 1 << 59;
    uint256 internal constant _ROLE_60 = 1 << 60;
    uint256 internal constant _ROLE_61 = 1 << 61;
    uint256 internal constant _ROLE_62 = 1 << 62;
    uint256 internal constant _ROLE_63 = 1 << 63;
    uint256 internal constant _ROLE_64 = 1 << 64;
    uint256 internal constant _ROLE_65 = 1 << 65;
    uint256 internal constant _ROLE_66 = 1 << 66;
    uint256 internal constant _ROLE_67 = 1 << 67;
    uint256 internal constant _ROLE_68 = 1 << 68;
    uint256 internal constant _ROLE_69 = 1 << 69;
    uint256 internal constant _ROLE_70 = 1 << 70;
    uint256 internal constant _ROLE_71 = 1 << 71;
    uint256 internal constant _ROLE_72 = 1 << 72;
    uint256 internal constant _ROLE_73 = 1 << 73;
    uint256 internal constant _ROLE_74 = 1 << 74;
    uint256 internal constant _ROLE_75 = 1 << 75;
    uint256 internal constant _ROLE_76 = 1 << 76;
    uint256 internal constant _ROLE_77 = 1 << 77;
    uint256 internal constant _ROLE_78 = 1 << 78;
    uint256 internal constant _ROLE_79 = 1 << 79;
    uint256 internal constant _ROLE_80 = 1 << 80;
    uint256 internal constant _ROLE_81 = 1 << 81;
    uint256 internal constant _ROLE_82 = 1 << 82;
    uint256 internal constant _ROLE_83 = 1 << 83;
    uint256 internal constant _ROLE_84 = 1 << 84;
    uint256 internal constant _ROLE_85 = 1 << 85;
    uint256 internal constant _ROLE_86 = 1 << 86;
    uint256 internal constant _ROLE_87 = 1 << 87;
    uint256 internal constant _ROLE_88 = 1 << 88;
    uint256 internal constant _ROLE_89 = 1 << 89;
    uint256 internal constant _ROLE_90 = 1 << 90;
    uint256 internal constant _ROLE_91 = 1 << 91;
    uint256 internal constant _ROLE_92 = 1 << 92;
    uint256 internal constant _ROLE_93 = 1 << 93;
    uint256 internal constant _ROLE_94 = 1 << 94;
    uint256 internal constant _ROLE_95 = 1 << 95;
    uint256 internal constant _ROLE_96 = 1 << 96;
    uint256 internal constant _ROLE_97 = 1 << 97;
    uint256 internal constant _ROLE_98 = 1 << 98;
    uint256 internal constant _ROLE_99 = 1 << 99;
    uint256 internal constant _ROLE_100 = 1 << 100;
    uint256 internal constant _ROLE_101 = 1 << 101;
    uint256 internal constant _ROLE_102 = 1 << 102;
    uint256 internal constant _ROLE_103 = 1 << 103;
    uint256 internal constant _ROLE_104 = 1 << 104;
    uint256 internal constant _ROLE_105 = 1 << 105;
    uint256 internal constant _ROLE_106 = 1 << 106;
    uint256 internal constant _ROLE_107 = 1 << 107;
    uint256 internal constant _ROLE_108 = 1 << 108;
    uint256 internal constant _ROLE_109 = 1 << 109;
    uint256 internal constant _ROLE_110 = 1 << 110;
    uint256 internal constant _ROLE_111 = 1 << 111;
    uint256 internal constant _ROLE_112 = 1 << 112;
    uint256 internal constant _ROLE_113 = 1 << 113;
    uint256 internal constant _ROLE_114 = 1 << 114;
    uint256 internal constant _ROLE_115 = 1 << 115;
    uint256 internal constant _ROLE_116 = 1 << 116;
    uint256 internal constant _ROLE_117 = 1 << 117;
    uint256 internal constant _ROLE_118 = 1 << 118;
    uint256 internal constant _ROLE_119 = 1 << 119;
    uint256 internal constant _ROLE_120 = 1 << 120;
    uint256 internal constant _ROLE_121 = 1 << 121;
    uint256 internal constant _ROLE_122 = 1 << 122;
    uint256 internal constant _ROLE_123 = 1 << 123;
    uint256 internal constant _ROLE_124 = 1 << 124;
    uint256 internal constant _ROLE_125 = 1 << 125;
    uint256 internal constant _ROLE_126 = 1 << 126;
    uint256 internal constant _ROLE_127 = 1 << 127;
    uint256 internal constant _ROLE_128 = 1 << 128;
    uint256 internal constant _ROLE_129 = 1 << 129;
    uint256 internal constant _ROLE_130 = 1 << 130;
    uint256 internal constant _ROLE_131 = 1 << 131;
    uint256 internal constant _ROLE_132 = 1 << 132;
    uint256 internal constant _ROLE_133 = 1 << 133;
    uint256 internal constant _ROLE_134 = 1 << 134;
    uint256 internal constant _ROLE_135 = 1 << 135;
    uint256 internal constant _ROLE_136 = 1 << 136;
    uint256 internal constant _ROLE_137 = 1 << 137;
    uint256 internal constant _ROLE_138 = 1 << 138;
    uint256 internal constant _ROLE_139 = 1 << 139;
    uint256 internal constant _ROLE_140 = 1 << 140;
    uint256 internal constant _ROLE_141 = 1 << 141;
    uint256 internal constant _ROLE_142 = 1 << 142;
    uint256 internal constant _ROLE_143 = 1 << 143;
    uint256 internal constant _ROLE_144 = 1 << 144;
    uint256 internal constant _ROLE_145 = 1 << 145;
    uint256 internal constant _ROLE_146 = 1 << 146;
    uint256 internal constant _ROLE_147 = 1 << 147;
    uint256 internal constant _ROLE_148 = 1 << 148;
    uint256 internal constant _ROLE_149 = 1 << 149;
    uint256 internal constant _ROLE_150 = 1 << 150;
    uint256 internal constant _ROLE_151 = 1 << 151;
    uint256 internal constant _ROLE_152 = 1 << 152;
    uint256 internal constant _ROLE_153 = 1 << 153;
    uint256 internal constant _ROLE_154 = 1 << 154;
    uint256 internal constant _ROLE_155 = 1 << 155;
    uint256 internal constant _ROLE_156 = 1 << 156;
    uint256 internal constant _ROLE_157 = 1 << 157;
    uint256 internal constant _ROLE_158 = 1 << 158;
    uint256 internal constant _ROLE_159 = 1 << 159;
    uint256 internal constant _ROLE_160 = 1 << 160;
    uint256 internal constant _ROLE_161 = 1 << 161;
    uint256 internal constant _ROLE_162 = 1 << 162;
    uint256 internal constant _ROLE_163 = 1 << 163;
    uint256 internal constant _ROLE_164 = 1 << 164;
    uint256 internal constant _ROLE_165 = 1 << 165;
    uint256 internal constant _ROLE_166 = 1 << 166;
    uint256 internal constant _ROLE_167 = 1 << 167;
    uint256 internal constant _ROLE_168 = 1 << 168;
    uint256 internal constant _ROLE_169 = 1 << 169;
    uint256 internal constant _ROLE_170 = 1 << 170;
    uint256 internal constant _ROLE_171 = 1 << 171;
    uint256 internal constant _ROLE_172 = 1 << 172;
    uint256 internal constant _ROLE_173 = 1 << 173;
    uint256 internal constant _ROLE_174 = 1 << 174;
    uint256 internal constant _ROLE_175 = 1 << 175;
    uint256 internal constant _ROLE_176 = 1 << 176;
    uint256 internal constant _ROLE_177 = 1 << 177;
    uint256 internal constant _ROLE_178 = 1 << 178;
    uint256 internal constant _ROLE_179 = 1 << 179;
    uint256 internal constant _ROLE_180 = 1 << 180;
    uint256 internal constant _ROLE_181 = 1 << 181;
    uint256 internal constant _ROLE_182 = 1 << 182;
    uint256 internal constant _ROLE_183 = 1 << 183;
    uint256 internal constant _ROLE_184 = 1 << 184;
    uint256 internal constant _ROLE_185 = 1 << 185;
    uint256 internal constant _ROLE_186 = 1 << 186;
    uint256 internal constant _ROLE_187 = 1 << 187;
    uint256 internal constant _ROLE_188 = 1 << 188;
    uint256 internal constant _ROLE_189 = 1 << 189;
    uint256 internal constant _ROLE_190 = 1 << 190;
    uint256 internal constant _ROLE_191 = 1 << 191;
    uint256 internal constant _ROLE_192 = 1 << 192;
    uint256 internal constant _ROLE_193 = 1 << 193;
    uint256 internal constant _ROLE_194 = 1 << 194;
    uint256 internal constant _ROLE_195 = 1 << 195;
    uint256 internal constant _ROLE_196 = 1 << 196;
    uint256 internal constant _ROLE_197 = 1 << 197;
    uint256 internal constant _ROLE_198 = 1 << 198;
    uint256 internal constant _ROLE_199 = 1 << 199;
    uint256 internal constant _ROLE_200 = 1 << 200;
    uint256 internal constant _ROLE_201 = 1 << 201;
    uint256 internal constant _ROLE_202 = 1 << 202;
    uint256 internal constant _ROLE_203 = 1 << 203;
    uint256 internal constant _ROLE_204 = 1 << 204;
    uint256 internal constant _ROLE_205 = 1 << 205;
    uint256 internal constant _ROLE_206 = 1 << 206;
    uint256 internal constant _ROLE_207 = 1 << 207;
    uint256 internal constant _ROLE_208 = 1 << 208;
    uint256 internal constant _ROLE_209 = 1 << 209;
    uint256 internal constant _ROLE_210 = 1 << 210;
    uint256 internal constant _ROLE_211 = 1 << 211;
    uint256 internal constant _ROLE_212 = 1 << 212;
    uint256 internal constant _ROLE_213 = 1 << 213;
    uint256 internal constant _ROLE_214 = 1 << 214;
    uint256 internal constant _ROLE_215 = 1 << 215;
    uint256 internal constant _ROLE_216 = 1 << 216;
    uint256 internal constant _ROLE_217 = 1 << 217;
    uint256 internal constant _ROLE_218 = 1 << 218;
    uint256 internal constant _ROLE_219 = 1 << 219;
    uint256 internal constant _ROLE_220 = 1 << 220;
    uint256 internal constant _ROLE_221 = 1 << 221;
    uint256 internal constant _ROLE_222 = 1 << 222;
    uint256 internal constant _ROLE_223 = 1 << 223;
    uint256 internal constant _ROLE_224 = 1 << 224;
    uint256 internal constant _ROLE_225 = 1 << 225;
    uint256 internal constant _ROLE_226 = 1 << 226;
    uint256 internal constant _ROLE_227 = 1 << 227;
    uint256 internal constant _ROLE_228 = 1 << 228;
    uint256 internal constant _ROLE_229 = 1 << 229;
    uint256 internal constant _ROLE_230 = 1 << 230;
    uint256 internal constant _ROLE_231 = 1 << 231;
    uint256 internal constant _ROLE_232 = 1 << 232;
    uint256 internal constant _ROLE_233 = 1 << 233;
    uint256 internal constant _ROLE_234 = 1 << 234;
    uint256 internal constant _ROLE_235 = 1 << 235;
    uint256 internal constant _ROLE_236 = 1 << 236;
    uint256 internal constant _ROLE_237 = 1 << 237;
    uint256 internal constant _ROLE_238 = 1 << 238;
    uint256 internal constant _ROLE_239 = 1 << 239;
    uint256 internal constant _ROLE_240 = 1 << 240;
    uint256 internal constant _ROLE_241 = 1 << 241;
    uint256 internal constant _ROLE_242 = 1 << 242;
    uint256 internal constant _ROLE_243 = 1 << 243;
    uint256 internal constant _ROLE_244 = 1 << 244;
    uint256 internal constant _ROLE_245 = 1 << 245;
    uint256 internal constant _ROLE_246 = 1 << 246;
    uint256 internal constant _ROLE_247 = 1 << 247;
    uint256 internal constant _ROLE_248 = 1 << 248;
    uint256 internal constant _ROLE_249 = 1 << 249;
    uint256 internal constant _ROLE_250 = 1 << 250;
    uint256 internal constant _ROLE_251 = 1 << 251;
    uint256 internal constant _ROLE_252 = 1 << 252;
    uint256 internal constant _ROLE_253 = 1 << 253;
    uint256 internal constant _ROLE_254 = 1 << 254;
    uint256 internal constant _ROLE_255 = 1 << 255;
}