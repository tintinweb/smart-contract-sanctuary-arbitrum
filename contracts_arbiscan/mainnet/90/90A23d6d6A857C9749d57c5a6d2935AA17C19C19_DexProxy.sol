//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FeeInfo.sol";
import "./libraries/FullMath.sol";
import "./Withdrawable.sol";

contract DexProxy is Withdrawable {
    using Address for address;
    using SafeERC20 for IERC20;
    using FullMath for uint;

    uint public constant FEE_DIVISOR = 100000;
    /**
     * @dev Promoter fee in range 0 to feeDivisor (1 means 1/feeDivisor), so range is 0.00001 (0.001%) to 1
     */
    uint public promoterFee;

    /**
     * @dev Contract owner fee (if no promocode passed) in range 0 to feeDivisor (1 means 1/feeDivisor), so range is 0.00001 (0.001%) to 1
     */
    uint public providerBaseFee;

    /**
     * @dev Contract owner discount fee in range 0 to feeDivisor (1 means 1/feeDivisor), so range is 0.00001 (0.001%) to 1
     */
    uint public providerDiscountFee;

    address public providerFeeTarget;

    mapping(address => bool) public dexes;

    mapping(uint => bool) public availableFeeValues;

    constructor(
        uint _promoterFee,
        uint _providerBaseFee,
        uint _providerDiscountFee,
        address _providerFeeTarget,
        uint[] memory _availableFeeValues,
        address[] memory _dexes
    ) {
        _setPromoterFee(_promoterFee);
        _setProviderBaseFee(_providerBaseFee);
        _setProviderDiscountFee(_providerDiscountFee);
        _setProviderFeeTarget(_providerFeeTarget);
        _setAvailableFeeValues(_availableFeeValues);
        _setDexes(_dexes);
    }

    receive() external payable {}

    function swap(
        address fromToken,
        address toToken,
        uint value,
        address targetDex,
        bytes calldata encodedParameters,
        FeeInfo calldata feeInfo
    ) external payable {
        uint tokensReceived = _swap(fromToken, toToken, value, targetDex, encodedParameters, feeInfo);

        _sendReceivedTokens(toToken, tokensReceived, feeInfo);
    }

    function swapWithPromoter(
        address fromToken,
        address toToken,
        uint value,
        address targetDex,
        bytes calldata encodedParameters,
        FeeInfo calldata feeInfo,
        address promoterAddress
    ) external payable {
        uint tokensReceived = _swap(fromToken, toToken, value, targetDex, encodedParameters, feeInfo);

        _sendReceivedTokens(toToken, tokensReceived, feeInfo, promoterAddress);
    }

    function _swap(
        address fromToken,
        address toToken,
        uint value,
        address targetDex,
        bytes calldata encodedParameters,
        FeeInfo calldata feeInfo
    ) private returns (uint) {
        require(dexes[targetDex], "Passed dex is not supported.");
        require(availableFeeValues[feeInfo.fee], "Passed fee value is not supported.");
        uint fromTokenBalanceBefore;
        uint toTokenBalanceBefore = _getBalance(toToken);

        if (fromToken == address(0)) {
            fromTokenBalanceBefore = _getBalance(fromToken);
            _swapFromNativeToken(value, targetDex, encodedParameters);
        } else {
            IERC20(fromToken).safeTransferFrom(_msgSender(), address(this), value);
            fromTokenBalanceBefore = _getBalance(fromToken);
            _swapFromErc20Token(fromToken, value, targetDex, encodedParameters);
        }

        uint fromTokenBalanceAfter = _getBalance(fromToken);
        uint tokensPaid = fromTokenBalanceBefore - fromTokenBalanceAfter;
        require(tokensPaid == value, "Value parameter is not equal to swap data amount parameter.");

        uint toTokenBalanceAfter = _getBalance(toToken);
        uint tokensReceived = toTokenBalanceAfter - toTokenBalanceBefore;
        require(tokensReceived > 0, "Swapped to zero tokens.");

        return tokensReceived;
    }

    function _swapFromNativeToken(
        uint value,
        address targetDex,
        bytes calldata encodedParameters
    ) private {
        require(msg.value == value, "Transaction value must be equal to value parameter.");
        targetDex.functionCallWithValue(encodedParameters, value);
    }

    function _swapFromErc20Token(
        address fromToken,
        uint value,
        address targetDex,
        bytes calldata encodedParameters
    ) private {
        _safeApproveToInfinityIfNeeded(IERC20(fromToken), targetDex, value);
        targetDex.functionCall(encodedParameters);
    }

    function _getBalance(address tokenAddress) private view returns (uint balance) {
        if (tokenAddress == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(tokenAddress).balanceOf(address(this));
        }
    }

    function _sendReceivedTokens(
        address toToken,
        uint tokensReceived,
        FeeInfo calldata feeInfo
    ) private {
        uint integratorAmount = tokensReceived.mulDiv(feeInfo.fee, FEE_DIVISOR);
        uint providerAmount = tokensReceived.mulDiv(providerBaseFee, FEE_DIVISOR);
        uint userAmount = tokensReceived - integratorAmount - providerAmount;

        _transferTokenOrNativeCoin(toToken, feeInfo.feeTarget, integratorAmount);
        _transferTokenOrNativeCoin(toToken, providerFeeTarget, providerAmount);
        _transferTokenOrNativeCoin(toToken, _msgSender(), userAmount);
    }

    function _sendReceivedTokens(
        address toToken,
        uint tokensReceived,
        FeeInfo calldata feeInfo,
        address promoterAddress
    ) private {
        uint integratorFeeBonus = providerBaseFee - providerDiscountFee - promoterFee;
        uint integratorFee = feeInfo.fee + integratorFeeBonus;

        uint integratorAmount = tokensReceived.mulDiv(integratorFee, FEE_DIVISOR);
        uint providerAmount = tokensReceived.mulDiv(providerDiscountFee, FEE_DIVISOR);
        uint promoterAmount = tokensReceived.mulDiv(promoterFee, FEE_DIVISOR);
        uint userAmount = tokensReceived - integratorAmount - promoterAmount - providerAmount;

        _transferTokenOrNativeCoin(toToken, feeInfo.feeTarget, integratorAmount);
        _transferTokenOrNativeCoin(toToken, providerFeeTarget, providerAmount);
        _transferTokenOrNativeCoin(toToken, promoterAddress, promoterAmount);
        _transferTokenOrNativeCoin(toToken, _msgSender(), userAmount);
    }

    function _transferTokenOrNativeCoin(
        address tokenAddress,
        address receiver,
        uint amount
    ) private {
        if (tokenAddress == address(0)) {
            payable(receiver).transfer(amount);
        } else {
            IERC20(tokenAddress).safeTransfer(receiver, amount);
        }
    }

    function _safeApproveToInfinityIfNeeded(
        IERC20 token,
        address target,
        uint requiredAmount
    ) private {
        uint allowance = token.allowance(address(this), target);

        if (allowance < requiredAmount) {
            if (allowance == 0) {
                token.safeApprove(target, type(uint).max);
            } else {
                try token.approve(target, type(uint).max) returns (bool res) {
                    require(res, "Approve failed");
                } catch {
                    token.safeApprove(target, 0);
                    token.safeApprove(target, type(uint).max);
                }
            }
        }
    }

    function setPromoterFee(uint _promoterFee) external onlyOwner {
        _setPromoterFee(_promoterFee);
    }

    function _setPromoterFee(uint _promoterFee) private {
        require(_promoterFee <= FEE_DIVISOR, "Fee can not be greater than feeDivisor.");
        promoterFee = _promoterFee;
    }

    function setProviderBaseFee(uint _providerBaseFee) external onlyOwner {
        _setProviderBaseFee(_providerBaseFee);
    }

    function _setProviderBaseFee(uint _providerBaseFee) private {
        require(_providerBaseFee <= FEE_DIVISOR, "Fee can not be greater than feeDivisor.");
        require(
            _providerBaseFee - promoterFee >= providerDiscountFee,
            "Base fee minus promoter fee must be gte than discount fee."
        );
        providerBaseFee = _providerBaseFee;
    }

    function setProviderDiscountFee(uint _providerDiscountFee) external onlyOwner {
        _setProviderDiscountFee(_providerDiscountFee);
    }

    function _setProviderDiscountFee(uint _providerDiscountFee) private {
        require(_providerDiscountFee <= FEE_DIVISOR, "Fee can not be greater than feeDivisor.");
        require(
            _providerDiscountFee + promoterFee <= providerBaseFee,
            "Discount fee plus promoter fee must be lte than base fee."
        );
        providerDiscountFee = _providerDiscountFee;
    }

    function setProviderFeeTarget(address _providerFeeTarget) external onlyOwner {
        _setProviderFeeTarget(_providerFeeTarget);
    }

    function _setProviderFeeTarget(address _providerFeeTarget) private {
        require(
            _providerFeeTarget != providerFeeTarget,
            "New providerFeeTarget value should not be equal to previous."
        );
        providerFeeTarget = _providerFeeTarget;
    }

    function setAvailableFeeValues(uint[] memory _availableFeeValues) external onlyOwner {
        _setAvailableFeeValues(_availableFeeValues);
    }

    function _setAvailableFeeValues(uint[] memory _availableFeeValues) private {
        uint _availableFeeValuesLength = _availableFeeValues.length;
        for (uint i = 0; i < _availableFeeValuesLength; i++) {
            require(_availableFeeValues[i] <= FEE_DIVISOR, "Fee can not be greater than feeDivisor.");
            availableFeeValues[_availableFeeValues[i]] = true;
        }
    }

    function removeFeeValue(uint feeValue) external onlyOwner {
        availableFeeValues[feeValue] = false;
    }

    function setDexes(address[] memory _dexes) external onlyOwner {
        _setDexes(_dexes);
    }

    function _setDexes(address[] memory _dexes) private {
        uint _dexesLength = _dexes.length;
        for (uint i = 0; i < _dexesLength; i++) {
            dexes[_dexes[i]] = true;
        }
    }

    function removeDex(address dex) external onlyOwner {
        dexes[dex] = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
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

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

struct FeeInfo {
    uint fee;
    address feeTarget;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Withdrawable is Ownable {
    function withdraw(
        address token,
        uint amount,
        address payable receiver
    ) external onlyOwner {
        if (token == address(0)) {
            receiver.transfer(amount);
        } else {
            IERC20(token).transfer(receiver, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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