// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IAdmin {
    function admin() external view returns (address);

    function setAdmin(address _admin) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IVault.sol";

interface IPlpManager {
    function plp() external view returns (address);

    function vault() external view returns (IVault);

    function collateralToken() external view returns (address);

    function cooldownDuration() external returns (uint256);

    function getAumInUsdp(bool maximise) external view returns (uint256);

    function estimatePlpOut(uint256 _amount) external view returns (uint256);

    function estimateTokenIn(uint256 _plpAmount)
        external
        view
        returns (uint256);

    function lastAddedAt(address _account) external returns (uint256);

    function addLiquidity(
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external returns (uint256);

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external returns (uint256);

    function removeLiquidity(
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function removeLiquidityForAccount(
        address _account,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function setShortsTrackerAveragePriceWeight(
        uint256 _shortsTrackerAveragePriceWeight
    ) external;

    function setCooldownDuration(uint256 _cooldownDuration) external;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITimelockTarget.sol";
import "./interfaces/ITimelock.sol";
import "./interfaces/IHandlerTarget.sol";
import "../access/interfaces/IAdmin.sol";
import "../core/interfaces/IVault.sol";
import "../core/interfaces/IPlpManager.sol";
import "../referrals/interfaces/IReferralStorage.sol";
import "../tokens/interfaces/IBaseToken.sol";
import "../tokens/interfaces/IMintable.sol";
import "../staking/interfaces/IRewardRouter.sol";

contract Timelock is ITimelock {
    using SafeERC20 for IERC20;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant MAX_BUFFER = 5 days;
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 200; // 0.02%
    uint256 public constant MAX_LEVERAGE_VALIDATION = 500000; // 50x

    uint256 public buffer;
    address public admin;

    address public tokenManager;
    address public mintReceiver;
    address public plpManager;
    address public rewardRouter;
    uint256 public maxTokenSupply;

    uint256 public override marginFeeBasisPoints;
    uint256 public maxMarginFeeBasisPoints;
    bool public shouldToggleIsLeverageEnabled;

    mapping(bytes32 => uint256) public pendingActions;

    mapping(address => bool) public isHandler;
    mapping(address => bool) public isKeeper;

    event SignalPendingAction(bytes32 action);
    event SignalApprove(
        address token,
        address spender,
        uint256 amount,
        bytes32 action
    );
    event SignalWithdrawToken(
        address target,
        address token,
        address receiver,
        uint256 amount,
        bytes32 action
    );
    event SignalMint(
        address token,
        address receiver,
        uint256 amount,
        bytes32 action
    );
    event SignalSetGov(address target, address gov, bytes32 action);
    event SignalSetHandler(
        address target,
        address handler,
        bool isActive,
        bytes32 action
    );
    event SignalSetPriceFeed(address vault, address priceFeed, bytes32 action);
    event SignalVaultSetTokenConfig(
        address vault,
        address token,
        uint256 tokenDecimals,
        uint256 minProfitBps,
        bool isStable,
        bool isShortable
    );
    event ClearAction(bytes32 action);
    event SignalTransaction(
        address target,
        uint256 ethValue,
        string signature,
        bytes data
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: forbidden");
        _;
    }

    modifier onlyHandlerAndAbove() {
        require(
            msg.sender == admin || isHandler[msg.sender],
            "Timelock: forbidden"
        );
        _;
    }

    modifier onlyKeeperAndAbove() {
        require(
            msg.sender == admin ||
                isHandler[msg.sender] ||
                isKeeper[msg.sender],
            "Timelock: forbidden"
        );
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "Timelock: forbidden");
        _;
    }

    constructor(
        address _admin,
        uint256 _buffer,
        address _tokenManager,
        address _mintReceiver,
        address _plpManager,
        address _rewardRouter,
        uint256 _maxTokenSupply,
        uint256 _marginFeeBasisPoints,
        uint256 _maxMarginFeeBasisPoints
    ) {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        admin = _admin;
        buffer = _buffer;
        tokenManager = _tokenManager;
        mintReceiver = _mintReceiver;
        plpManager = _plpManager;
        rewardRouter = _rewardRouter;
        maxTokenSupply = _maxTokenSupply;

        marginFeeBasisPoints = _marginFeeBasisPoints;
        maxMarginFeeBasisPoints = _maxMarginFeeBasisPoints;
    }

    function setAdmin(address _admin) external override onlyTokenManager {
        admin = _admin;
    }

    function setTokenManager(address _newManager) external onlyTokenManager {
        require(tokenManager != _newManager, "Timelock: already set");

        tokenManager = _newManager;
    }

    function setExternalAdmin(
        address _target,
        address _admin
    ) external onlyAdmin {
        require(_target != address(this), "Timelock: invalid _target");
        IAdmin(_target).setAdmin(_admin);
    }

    function setContractHandler(
        address _handler,
        bool _isActive
    ) external onlyAdmin {
        isHandler[_handler] = _isActive;
    }

    function initPlpManager() external onlyAdmin {
        IPlpManager _plpManager = IPlpManager(plpManager);

        IMintable plp = IMintable(_plpManager.plp());
        plp.setMinter(plpManager, true);

        IVault vault = _plpManager.vault();
        vault.setPlpManager(plpManager);
    }

    function initRewardRouter() external onlyAdmin {
        IRewardRouter _rewardRouter = IRewardRouter(rewardRouter);

        IHandlerTarget(_rewardRouter.feePlpTracker()).setHandler(
            rewardRouter,
            true
        );
        IHandlerTarget(plpManager).setHandler(rewardRouter, true);
    }

    function setKeeper(address _keeper, bool _isActive) external onlyAdmin {
        isKeeper[_keeper] = _isActive;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        require(_buffer > buffer, "Timelock: buffer cannot be decreased");
        buffer = _buffer;
    }

    function setMaxLeverage(
        address _vault,
        uint256 _maxLeverage
    ) external onlyAdmin {
        require(
            _maxLeverage > MAX_LEVERAGE_VALIDATION,
            "Timelock: invalid _maxLeverage"
        );
        IVault(_vault).setMaxLeverage(_maxLeverage);
    }

    function setFundingRate(
        address _vault,
        uint256 _fundingInterval,
        uint256 _fundingRateFactor
    ) external onlyKeeperAndAbove {
        require(
            _fundingRateFactor < MAX_FUNDING_RATE_FACTOR,
            "Timelock: invalid _fundingRateFactor"
        );
        IVault(_vault).setFundingRate(_fundingInterval, _fundingRateFactor);
    }

    function setShouldToggleIsLeverageEnabled(
        bool _shouldToggleIsLeverageEnabled
    ) external onlyHandlerAndAbove {
        shouldToggleIsLeverageEnabled = _shouldToggleIsLeverageEnabled;
    }

    function setMarginFeeBasisPoints(
        uint256 _marginFeeBasisPoints,
        uint256 _maxMarginFeeBasisPoints
    ) external onlyHandlerAndAbove {
        marginFeeBasisPoints = _marginFeeBasisPoints;
        maxMarginFeeBasisPoints = _maxMarginFeeBasisPoints;
    }

    function setSwapFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _mintBurnFeeBasisPoints
    ) external onlyKeeperAndAbove {
        IVault vault = IVault(_vault);

        vault.setFees(
            _taxBasisPoints,
            _mintBurnFeeBasisPoints,
            maxMarginFeeBasisPoints,
            vault.liquidationFeeUsd(),
            vault.minProfitTime()
        );
    }

    // assign _marginFeeBasisPoints to this.marginFeeBasisPoints
    // because enableLeverage would update Vault.marginFeeBasisPoints to this.marginFeeBasisPoints
    // and disableLeverage would reset the Vault.marginFeeBasisPoints to this.maxMarginFeeBasisPoints
    function setFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime
    ) external onlyKeeperAndAbove {
        marginFeeBasisPoints = _marginFeeBasisPoints;

        IVault(_vault).setFees(
            _taxBasisPoints,
            _mintBurnFeeBasisPoints,
            maxMarginFeeBasisPoints,
            _liquidationFeeUsd,
            _minProfitTime
        );
    }

    function enableLeverage(
        address _vault
    ) external override onlyHandlerAndAbove {
        IVault vault = IVault(_vault);

        if (shouldToggleIsLeverageEnabled) {
            vault.setIsLeverageEnabled(true);
        }

        vault.setFees(
            vault.taxBasisPoints(),
            vault.mintBurnFeeBasisPoints(),
            marginFeeBasisPoints,
            vault.liquidationFeeUsd(),
            vault.minProfitTime()
        );
    }

    function disableLeverage(
        address _vault
    ) external override onlyHandlerAndAbove {
        IVault vault = IVault(_vault);

        if (shouldToggleIsLeverageEnabled) {
            vault.setIsLeverageEnabled(false);
        }

        vault.setFees(
            vault.taxBasisPoints(),
            vault.mintBurnFeeBasisPoints(),
            maxMarginFeeBasisPoints, // marginFeeBasisPoints
            vault.liquidationFeeUsd(),
            vault.minProfitTime()
        );
    }

    function setIsLeverageEnabled(
        address _vault,
        bool _isLeverageEnabled
    ) external override onlyHandlerAndAbove {
        IVault(_vault).setIsLeverageEnabled(_isLeverageEnabled);
    }

    function setTokenConfig(
        address _vault,
        address _token,
        uint256 _minProfitBps
    ) external onlyKeeperAndAbove {
        require(_minProfitBps <= 500, "Timelock: invalid _minProfitBps");

        IVault vault = IVault(_vault);
        require(
            vault.whitelistedTokens(_token),
            "Timelock: token not yet whitelisted"
        );

        uint256 tokenDecimals = vault.tokenDecimals(_token);
        bool isStable = vault.stableTokens(_token);
        bool isShortable = vault.shortableTokens(_token);

        IVault(_vault).setTokenConfig(
            _token,
            tokenDecimals,
            _minProfitBps,
            isStable,
            isShortable
        );
    }

    function setMaxUsdpAmounts(
        address _vault,
        uint256 _maxUsdpAmounts
    ) external onlyKeeperAndAbove {
        IVault(_vault).setMaxUsdpAmounts(_maxUsdpAmounts);
    }

    function setUsdpAmount(
        address _vault,
        uint256 _usdpAmount
    ) external onlyKeeperAndAbove {
        IVault(_vault).setUsdpAmount(_usdpAmount);
    }

    function setShortsTrackerAveragePriceWeight(
        uint256 _shortsTrackerAveragePriceWeight
    ) external onlyAdmin {
        IPlpManager(plpManager).setShortsTrackerAveragePriceWeight(
            _shortsTrackerAveragePriceWeight
        );
    }

    function setPlpCooldownDuration(
        uint256 _cooldownDuration
    ) external onlyAdmin {
        require(
            _cooldownDuration < 2 hours,
            "Timelock: invalid _cooldownDuration"
        );
        IPlpManager(plpManager).setCooldownDuration(_cooldownDuration);
    }

    function setMaxGlobalSize(
        address _vault,
        address _token,
        uint256 _longAmount,
        uint256 _shortAmount
    ) external onlyAdmin {
        IVault(_vault).setMaxGlobalSize(_token, _longAmount, _shortAmount);
    }

    function setTier(
        address _referralStorage,
        uint256 _tierId,
        uint256 _totalRebate,
        uint256 _discountShare
    ) external onlyKeeperAndAbove {
        IReferralStorage(_referralStorage).setTier(
            _tierId,
            _totalRebate,
            _discountShare
        );
    }

    function setReferrerTier(
        address _referralStorage,
        address _referrer,
        uint256 _tierId
    ) external onlyKeeperAndAbove {
        IReferralStorage(_referralStorage).setReferrerTier(_referrer, _tierId);
    }

    function govSetCodeOwner(
        address _referralStorage,
        bytes32 _code,
        address _newAccount
    ) external onlyKeeperAndAbove {
        IReferralStorage(_referralStorage).govSetCodeOwner(_code, _newAccount);
    }

    function setMaxGasPrice(
        address _vault,
        uint256 _maxGasPrice
    ) external onlyAdmin {
        require(_maxGasPrice > 5000000000, "Invalid _maxGasPrice");
        IVault(_vault).setMaxGasPrice(_maxGasPrice);
    }

    function withdrawFees(
        address _vault,
        address _receiver
    ) external onlyAdmin {
        IVault(_vault).withdrawFees(_receiver);
    }

    function batchWithdrawFees(
        address _vault,
        address _receiver
    ) external onlyKeeperAndAbove returns (uint256 fee) {
        fee = IVault(_vault).withdrawFees(_receiver);
    }

    function setLiquidator(
        address _vault,
        address _liquidator,
        bool _isActive
    ) external onlyAdmin {
        IVault(_vault).setLiquidator(_liquidator, _isActive);
    }

    function setInPrivateTransferMode(
        address _token,
        bool _inPrivateTransferMode
    ) external onlyAdmin {
        IBaseToken(_token).setInPrivateTransferMode(_inPrivateTransferMode);
    }

    function transferIn(
        address _sender,
        address _token,
        uint256 _amount
    ) external onlyAdmin {
        IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
    }

    function signalApprove(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("approve", _token, _spender, _amount)
        );
        _setPendingAction(action);
        emit SignalApprove(_token, _spender, _amount, action);
    }

    function approve(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("approve", _token, _spender, _amount)
        );
        _validateAction(action);
        _clearAction(action);
        IERC20(_token).approve(_spender, _amount);
    }

    function signalWithdrawToken(
        address _target,
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked(
                "withdrawToken",
                _target,
                _token,
                _receiver,
                _amount
            )
        );
        _setPendingAction(action);
        emit SignalWithdrawToken(_target, _token, _receiver, _amount, action);
    }

    function withdrawToken(
        address _target,
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked(
                "withdrawToken",
                _target,
                _token,
                _receiver,
                _amount
            )
        );
        _validateAction(action);
        _clearAction(action);
        IBaseToken(_target).withdrawToken(_token, _receiver, _amount);
    }

    function signalMint(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("mint", _token, _receiver, _amount)
        );
        _setPendingAction(action);
        emit SignalMint(_token, _receiver, _amount, action);
    }

    function processMint(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("mint", _token, _receiver, _amount)
        );
        _validateAction(action);
        _clearAction(action);

        _mint(_token, _receiver, _amount);
    }

    function signalSetGov(
        address _target,
        address _gov
    ) external override onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("transferOwnership", _target, _gov)
        );
        _setPendingAction(action);
        emit SignalSetGov(_target, _gov, action);
    }

    function transferOwnership(
        address _target,
        address _gov
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("transferOwnership", _target, _gov)
        );
        _validateAction(action);
        _clearAction(action);
        ITimelockTarget(_target).transferOwnership(_gov);
    }

    function signalSetHandler(
        address _target,
        address _handler,
        bool _isActive
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("setHandler", _target, _handler, _isActive)
        );
        _setPendingAction(action);
        emit SignalSetHandler(_target, _handler, _isActive, action);
    }

    function setHandler(
        address _target,
        address _handler,
        bool _isActive
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("setHandler", _target, _handler, _isActive)
        );
        _validateAction(action);
        _clearAction(action);
        IHandlerTarget(_target).setHandler(_handler, _isActive);
    }

    function signalSetPriceFeed(
        address _vault,
        address _priceFeed
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("setPriceFeed", _vault, _priceFeed)
        );
        _setPendingAction(action);
        emit SignalSetPriceFeed(_vault, _priceFeed, action);
    }

    function setPriceFeed(
        address _vault,
        address _priceFeed
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked("setPriceFeed", _vault, _priceFeed)
        );
        _validateAction(action);
        _clearAction(action);
        IVault(_vault).setPriceFeed(_priceFeed);
    }

    function signalVaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _minProfitBps,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked(
                "vaultSetTokenConfig",
                _vault,
                _token,
                _tokenDecimals,
                _minProfitBps,
                _isStable,
                _isShortable
            )
        );

        _setPendingAction(action);

        emit SignalVaultSetTokenConfig(
            _vault,
            _token,
            _tokenDecimals,
            _minProfitBps,
            _isStable,
            _isShortable
        );
    }

    function vaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _minProfitBps,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked(
                "vaultSetTokenConfig",
                _vault,
                _token,
                _tokenDecimals,
                _minProfitBps,
                _isStable,
                _isShortable
            )
        );

        _validateAction(action);
        _clearAction(action);

        IVault(_vault).setTokenConfig(
            _token,
            _tokenDecimals,
            _minProfitBps,
            _isStable,
            _isShortable
        );
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _mint(address _token, address _receiver, uint256 _amount) private {
        IMintable mintable = IMintable(_token);

        mintable.setMinter(address(this), true);

        mintable.mint(_receiver, _amount);
        require(
            IERC20(_token).totalSupply() <= maxTokenSupply,
            "Timelock: maxTokenSupply exceeded"
        );

        mintable.setMinter(address(this), false);
    }

    function _setPendingAction(bytes32 _action) private {
        require(
            pendingActions[_action] == 0,
            "Timelock: action already signalled"
        );
        pendingActions[_action] = block.timestamp + buffer;
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "Timelock: action not signalled");
        require(
            pendingActions[_action] < block.timestamp,
            "Timelock: action time not yet passed"
        );
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "Timelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }

    function signalTransaction(
        address target,
        uint256 ethValue,
        string memory signature,
        bytes memory data
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked(
                "execTransaction",
                target,
                ethValue,
                signature,
                data
            )
        );

        _setPendingAction(action);

        emit SignalTransaction(target, ethValue, signature, data);
    }

    function executeTransaction(
        address target,
        uint256 ethValue,
        string memory signature,
        bytes memory data
    ) public payable onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked(
                "execTransaction",
                target,
                ethValue,
                signature,
                data
            )
        );

        _validateAction(action);
        _clearAction(action);

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // Execute the call
        (bool success, ) = target.call{value: ethValue}(callData);

        require(success, "ExecuteTransaction failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IHandlerTarget {
    function isHandler(address _account) external returns (bool);

    function setHandler(address _handler, bool _isActive) external;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ITimelockTarget {
    function transferOwnership(address _gov) external;

    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IReferralStorage {
    function codeOwners(bytes32 _code) external view returns (address);

    function traderReferralCodes(address _account)
        external
        view
        returns (bytes32);

    function referrerDiscountShares(address _account)
        external
        view
        returns (uint256);

    function referrerTiers(address _account) external view returns (uint256);

    function getTraderReferralInfo(address _account)
        external
        view
        returns (bytes32, address);

    function setTraderReferralCode(address _account, bytes32 _code) external;

    function setTier(
        uint256 _tierId,
        uint256 _totalRebate,
        uint256 _discountShare
    ) external;

    function setReferrerTier(address _referrer, uint256 _tierId) external;

    function govSetCodeOwner(bytes32 _code, address _newAccount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IRewardRouter {
    function feePlpTracker() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IBaseToken {
    function removeAdmin(address _account) external;

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external;

    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}