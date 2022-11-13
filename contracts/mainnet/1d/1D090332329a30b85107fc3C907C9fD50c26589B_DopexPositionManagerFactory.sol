/**
 *Submitted for verification at Arbiscan on 2022-11-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

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



// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)


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



// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)


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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
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

  function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external;

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

  function getTargetUsdgAmount(address _token) external view returns (uint256);

  function inManagerMode() external view returns (bool);

  function inPrivateLiquidationMode() external view returns (bool);

  function maxGasPrice() external view returns (uint256);

  function approvedRouters(address _account, address _router) external view returns (bool);

  function isLiquidator(address _account) external view returns (bool);

  function isManager(address _account) external view returns (bool);

  function minProfitBasisPoints(address _token) external view returns (uint256);

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

  function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;

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

  function withdrawFees(address _token, address _receiver) external returns (uint256);

  function directPoolDeposit(address _token) external;

  function buyUSDG(address _token, address _receiver) external returns (uint256);

  function sellUSDG(address _token, address _receiver) external returns (uint256);

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

  function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

  function priceFeed() external view returns (address);

  function fundingRateFactor() external view returns (uint256);

  function stableFundingRateFactor() external view returns (uint256);

  function cumulativeFundingRates(address _token) external view returns (uint256);

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

  function globalShortAveragePrices(address _token) external view returns (uint256);

  function maxGlobalShortSizes(address _token) external view returns (uint256);

  function tokenDecimals(address _token) external view returns (uint256);

  function tokenWeights(address _token) external view returns (uint256);

  function guaranteedUsd(address _token) external view returns (uint256);

  function poolAmounts(address _token) external view returns (uint256);

  function bufferAmounts(address _token) external view returns (uint256);

  function reservedAmounts(address _token) external view returns (uint256);

  function usdgAmounts(address _token) external view returns (uint256);

  function maxUsdgAmounts(address _token) external view returns (uint256);

  function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

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
    address, /* _account */
    address, /* _collateralToken */
    address, /* _indexToken */
    bool, /* _isLong */
    uint256 _sizeDelta
  ) external view returns (uint256);

  function getFundingFee(
    address, /* _account */
    address _collateralToken,
    address, /* _indexToken */
    bool, /* _isLong */
    uint256 _size,
    uint256 _entryFundingRate
  ) external view returns (uint256);

  function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);

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
}




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




interface IDopexPositionManagerFactory {
    function createPositionmanager(address _user) external returns (address positionManager);
    function callback() external view returns (address);
    function minSlipageBps() external view returns (uint256);
    function userPositionManagers(address _user) external view returns (address);
}




// Structs
struct IncreaseOrderParams {
    address[] path;
    address indexToken;
    uint256 collateralDelta;
    uint256 positionSizeDelta;
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

    function increaseOrder(IncreaseOrderParams memory) external payable;

    function decreaseOrder(DecreaseOrderParams calldata) external payable;

    function release() external;

    function withdrawAllFundsToUser(
        address _collateralToken,
        address _indexToken
    ) external;

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
    event WithdrawAllFundsToUser(address, address, uint256, uint256);
    event SlippageSet(uint256 _slippage);
    event CallbackSet(address _callback);
    event FactorySet(address _factory);
}




// Libraries






// Interfaces

contract DopexPositionManager is IDopexPositionManager {
    using SafeERC20 for IERC20;

    uint256 private constant PRECISION = 100000;
    uint256 public minSlippageBps; // 0.35%
    // Min execution fee for orders
    uint256 public minFee;
    // Minimum slippage applied to order price
    uint256 public slippage;
    // Address of the user of this position manager
    address public user;
    // Callback address when position is executed
    address public callback;
    // Address of the strategy contract
    address public strategyController;
    // Address of the position manager factory
    address public factory;
    // initialize check
    bool public isEnabled;
    // Is position released and can be increased/decreased by user
    bool public released;

    // GMX Router
    IRouter public gmxRouter;
    //  GMX Vault
    IVault public gmxVault;
    // GMX Position Router
    IPositionRouter public gmxPositionRouter;

    // Referral code (GMX related)
    bytes32 public referralCode;

    error DopexPositionManagerError(uint256);

    /**
     * @notice Set contract vars and create long position
     * @param _gmxVault           Address of the GMX Vault contract
     * @param _gmxRouter          Address of the GMX Router contract
     * @param _gmxPositionRouter  Address of the GMX Position Router contract
     * @param _user               Address of the user of the position manager
     */
    function enableAndCreateIncreaseOrder(
        IncreaseOrderParams calldata params,
        address _gmxVault,
        address _gmxRouter,
        address _gmxPositionRouter,
        address _user
    ) external payable {
        if (isEnabled) {
            _validate(msg.sender == strategyController, 1);
        }
        strategyController = msg.sender;
        user = _user;

        gmxRouter = IRouter(_gmxRouter);
        gmxVault = IVault(_gmxVault);
        gmxPositionRouter = IPositionRouter(_gmxPositionRouter);
        minFee = gmxPositionRouter.minExecutionFee();
        slippage = IDopexPositionManagerFactory(factory).minSlipageBps();
        minSlippageBps = slippage;

        gmxRouter.approvePlugin(_gmxPositionRouter);
        // Create long position
        increaseOrder(
            IncreaseOrderParams(
                params.path,
                params.indexToken,
                params.collateralDelta,
                params.positionSizeDelta,
                params.isLong
            )
        );

        isEnabled = true;
        released = false;
    }

    /**
     * @notice Create an increase order. note that GMX position router is the approved plugin here
     *         Orders created through this function will not be executed by the strategy handler.
     *         instead GMX's position keeper will execute it.
     * @param params Parameters for creating an order for the futures position in gmx
     */
    function increaseOrder(IncreaseOrderParams memory params) public payable {
        if (msg.sender == user) {
            _validate(released, 2);
            IERC20(params.path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                params.collateralDelta
            );
        } else {
            _validate(msg.sender == strategyController, 1);
        }

        _validate(msg.value >= gmxPositionRouter.minExecutionFee(), 5);

        IERC20(params.path[0]).safeIncreaseAllowance(
            address(gmxRouter),
            params.collateralDelta
        );

        uint256 priceWithSlippage = _getPriceWithSlippage(
            params.indexToken,
            true
        );

        gmxPositionRouter.createIncreasePosition{value: msg.value}(
            params.path,
            params.indexToken,
            params.collateralDelta,
            0,
            params.positionSizeDelta,
            params.isLong,
            priceWithSlippage,
            msg.value,
            referralCode,
            callback
        );

        emit IncreaseOrderCreated(
            params.path,
            params.indexToken,
            params.collateralDelta,
            params.positionSizeDelta,
            priceWithSlippage
        );
    }

    /**
     * @notice Create an decrease order. note that GMX position router is the approved plugin here
     *         Orders created through this function will not be executed by the strategy handler
     *         instead GMX's position keeper will execute it.
     * @param params Parameters for creating an order for the futures position in gmx
     */
    function decreaseOrder(DecreaseOrderParams memory params) external payable {
        if (msg.sender == user) {
            // Position muste be released
            _validate(released, 2);
        } else {
            // Ensure only strategy controller or user can call
            _validate(msg.sender == strategyController, 1);
        }
        _validate(msg.value >= gmxPositionRouter.minExecutionFee(), 5);

        uint256 priceWithSlippage = _getPriceWithSlippage(
            params.orderParams.indexToken,
            false
        );

        gmxPositionRouter.createDecreasePosition{value: msg.value}(
            params.orderParams.path,
            params.orderParams.indexToken,
            params.orderParams.collateralDelta,
            params.orderParams.positionSizeDelta,
            params.orderParams.isLong,
            params.receiver,
            priceWithSlippage,
            0,
            msg.value,
            params.withdrawETH,
            callback
        );

        emit DecreaseOrderCreated(
            params.orderParams.path,
            params.orderParams.indexToken,
            params.orderParams.collateralDelta,
            params.orderParams.positionSizeDelta,
            priceWithSlippage
        );
    }

    function withdrawAllFundsToUser(
        address _collateralToken,
        address _indexToken
    ) external {
        _validate(msg.sender == strategyController, 1);
        IERC20 collateralToken = IERC20(_collateralToken);
        IERC20 indexToken = IERC20(_indexToken);

        uint256 balance1 = collateralToken.balanceOf(address(this));
        uint256 balance2 = indexToken.balanceOf(address(this));

        if (collateralToken.balanceOf(address(this)) > 0) {
            collateralToken.safeTransfer(user, balance1);
        }
        if (indexToken.balanceOf(address(this)) > 0) {
            indexToken.safeTransfer(user, balance2);
        }

        emit WithdrawAllFundsToUser(
            _collateralToken,
            _indexToken,
            balance1,
            balance2
        );
    }

    function strategyControllerTransfer(
        address _token,
        address _to,
        uint256 amount
    ) external {
        _validate(msg.sender == strategyController, 1);
        IERC20(_token).safeTransfer(_to, amount);
    }

    /// @notice Release contract from strategy
    function release() external {
        _validate(msg.sender == strategyController, 1);
        released = true;
        emit Released();
    }

    function lock() external {
        _validate(msg.sender == strategyController, 1);
        released = false;
        minFee = IPositionRouter(gmxPositionRouter).minExecutionFee();
        uint256 minSlippage = IDopexPositionManagerFactory(factory)
            .minSlipageBps();
        minSlippageBps = minSlippage;
        slippage = minSlippage;
        callback = IDopexPositionManagerFactory(factory).callback();
        emit Locked();
    }

    /// @notice Set min execution fee for increase/decrease orders after released
    /// @param newFee New execution fee to set
    function setMinFee(uint256 newFee) external {
        _isReleased();
        minFee = newFee;
    }

    /// @notice Set referral code
    /// @param _newReferralCode New referral code
    function setReferralCode(bytes32 _newReferralCode) external {
        _isReleased();
        referralCode = _newReferralCode;
        emit ReferralCodeSet(_newReferralCode);
    }

    /// @notice Set slippage for increase/decrease orders
    /// @param _slippageBps Slippage BPS in PRECISION
    function setSlippage(uint256 _slippageBps) external {
        _isReleased();
        // can't be more than PRECISION
        _validate(_slippageBps <= PRECISION, 6);
        // Can't be less than a min amount
        _validate(_slippageBps >= minSlippageBps, 6);
        slippage = _slippageBps;
        emit SlippageSet(_slippageBps);
    }

    /// @dev Helper function to check if position has been released and is called by user
    function _isReleased() private view {
        _validate(msg.sender == user, 1);
        _validate(released, 2);
    }

    function _getPriceWithSlippage(address _token, bool _max)
        private
        view
        returns (uint256 price)
    {
        price = _max
            ? gmxVault.getMaxPrice(_token)
            : gmxVault.getMinPrice(_token);
        uint256 precision = PRECISION;
        price =
            (price * (_max ? (precision + slippage) : (precision - slippage))) /
            precision;
    }

    /// @dev validator function to revert contracts custom error and error code
    function _validate(bool requiredCondition, uint256 errorCode) private pure {
        if (!requiredCondition) revert DopexPositionManagerError(errorCode);
    }

    function setCallback(address _callback) external {
        if (msg.sender != factory) {
            _validate(msg.sender == strategyController, 1);
        }
        callback = _callback;
        emit CallbackSet(_callback);
    }

    function setFactory(address _factory) external {
        if (factory == address(0)) {
            factory = msg.sender;
        } else {
            _validate(msg.sender == factory, 1);
        }
        factory = _factory;
        emit FactorySet(_factory);
    }
}

/**
1 => Forbidden.
2 => Position hasn't been released by the strategy controller.
3 => Cannot provide 0 as amount
4 => Cannot re-initialize
5 => Insufficient exeuction fees
6 => Invalid Slippage
7 => Already initialized
 */



// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)


/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}




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



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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



// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)


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







contract DopexPositionManagerFactory is ContractWhitelist, Ownable {
    address public immutable DopexPositionManagerImplementation;
    address public callback;
    uint256 public minSlipageBps = 350;

    mapping(address => address) public userPositionManagers;

    event CallbackSet(address _callback);
    event CallbackSetPositionManager(
        address _positionManager,
        address _callback
    );
    event MinSlippageBpsSet(uint256 _slippageBps);

    error CallbackNotSet();

    constructor() {
        DopexPositionManagerImplementation = address(
            new DopexPositionManager()
        );
    }

    function createPositionmanager(address _user)
        external
        returns (address positionManager)
    {
        _isEligibleSender();

        if (callback == address(0)) {
            revert CallbackNotSet();
        }

        // Position manager instance
        DopexPositionManager userPositionManager = DopexPositionManager(
            Clones.clone(DopexPositionManagerImplementation)
        );
        userPositionManager.setFactory(address(this));
        userPositionManager.setCallback(callback);
        userPositionManagers[_user] = address(userPositionManager);
        positionManager = address(userPositionManager);
    }

    function setCallback(address _callback) external onlyOwner {
        callback = _callback;
        emit CallbackSet(_callback);
    }

    function setPositionManagerCallback(
        address _positionManager,
        address _callback
    ) external onlyOwner {
        DopexPositionManager(_positionManager).setCallback(_callback);
        emit CallbackSetPositionManager(_positionManager, _callback);
    }

    function setMinSlippageBps(uint256 _slippageBps) external onlyOwner {
       minSlipageBps = _slippageBps;
       emit MinSlippageBpsSet(_slippageBps);
    }

    /**
     * @notice Add a contract to the whitelist
     * @dev    Can only be called by the owner
     * @param _contract Address of the contract that needs to be added to the whitelist
     */
    function addToContractWhitelist(address _contract) external onlyOwner {
        _addToContractWhitelist(_contract);
    }

    /**
     * @notice Add a contract to the whitelist
     * @dev    Can only be called by the owner
     * @param _contract Address of the contract that needs to be added to the whitelist
     */
    function removeFromContractWhitelist(address _contract) external onlyOwner {
        _removeFromContractWhitelist(_contract);
    }
}