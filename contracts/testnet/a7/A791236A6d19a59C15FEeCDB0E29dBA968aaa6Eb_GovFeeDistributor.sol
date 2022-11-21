// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

error OnlyOwner();
error AddressZero();
error AmountZero();
error ContractUnavailable();
error InsufficientBalance();

pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ITokenCheckpointLogic} from "../libraries/ITokenCheckpointLogic.sol";
import {VeCheckpointLogic} from "../libraries/VeCheckpointLogic.sol";

import {VotingEscrow} from "../VotingEscrow.sol";

import {IGovFeeDistributor} from "../interfaces/dao/IGovFeeDistributor.sol";
import {ICDSTemplate} from "../interfaces/pool/ICDSTemplate.sol";
import {IOwnership} from "../interfaces/pool/IOwnership.sol";

import {OnlyOwner, AddressZero, AmountZero, ContractUnavailable, InsufficientBalance} from "../errors/CommonErrors.sol";

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * @title InsureDAO governance fee distributor
 * @author InsureDAO
 * @notice This distributes governance fee, which is occured each insurance and saved in the vault,
 *         to veINSURE holders.
 */

contract GovFeeDistributor is ReentrancyGuard, IGovFeeDistributor {
    using SafeERC20 for IERC20;
    using SafeCast for int256;
    using SafeCast for uint256;

    uint256 constant WEEK = 7 * 86_400;
    /// @dev the minimum interval for next iToken checkpoint
    uint256 constant TOKEN_CHECKPOINT_INTERVAL = 86_400;

    /// @notice dao contract
    address public immutable votingEscrow;

    /// @notice pool contracts
    address public immutable ownership;
    address public immutable vault;
    address public immutable depositToken;

    /// @notice iToken address
    address public immutable iToken;

    /// @notice distribution start time(rounded by WEEK)
    uint256 public immutable distributionStart;
    /// @notice week boundaries where each user currently is
    mapping(address => uint256) public userTimeCursors;
    /// @notice the last veINSURE epochs each user receives their govanance fee reward
    mapping(address => uint256) public userEpochs;

    /// @notice if this true, the contract will be permanently unavailable
    bool public isKilled;

    /// @notice see VeCheckpointLogic.sol
    VeCheckpointLogic.VeCheckpoint public veCheckpointRecord;
    /// @notice see ITokenCheckpointLogic.sol
    ITokenCheckpointLogic.ITokenCheckpoint public iTokenCheckpointRecord;

    modifier onlyOwner() {
        if (msg.sender != IOwnership(ownership).owner()) revert OnlyOwner();
        _;
    }

    modifier notKilled() {
        if (isKilled) revert ContractUnavailable();
        _;
    }

    /**
     * @notice checkpoints total veINSURE and iToken supply
     *         before user claiming their iToken reward.
     */
    modifier claimPreparation() {
        // check if veINSURE to be checkpointed
        if (block.timestamp > veCheckpointRecord.latestTimeCursor)
            VeCheckpointLogic.checkpoint(votingEscrow, veCheckpointRecord);
        // check if fee token to be checkpointed
        if (
            block.timestamp >
            iTokenCheckpointRecord.lastITokenTime + TOKEN_CHECKPOINT_INTERVAL
        )
            ITokenCheckpointLogic.checkpoint(
                iToken,
                address(this),
                iTokenCheckpointRecord
            );
        _;
    }

    event ITokenReceived(uint256 _amount);
    event Claimed(address _to, uint256 _amount);
    event ITokenCheckpointed(uint256 _checkpointTime);
    event VeCheckpointed(uint256 _lastCheckpointTime);
    event Burnt(address _from, uint256 _amount);
    event Killed(uint256 _time);

    constructor(
        address _vault,
        address _votingEscrow,
        address _ownership,
        address _iToken,
        address _depositToken,
        uint256 _startTime
    ) {
        if (
            _vault == address(0) ||
            _votingEscrow == address(0) ||
            _ownership == address(0) ||
            _iToken == address(0) ||
            _depositToken == address(0)
        ) revert AddressZero();

        uint256 _distributionStart = (_startTime / WEEK) * WEEK;

        vault = _vault;
        votingEscrow = _votingEscrow;
        ownership = _ownership;
        iToken = _iToken;
        depositToken = _depositToken;
        distributionStart = _distributionStart;

        veCheckpointRecord.latestTimeCursor = _distributionStart;
        iTokenCheckpointRecord.lastITokenTime = _distributionStart;
    }

    /**
     * external functions
     */

    /// @inheritdoc IGovFeeDistributor
    function depositBalanceToReserve() external nonReentrant notKilled {
        _depositBalanceToReserve(IERC20(depositToken).balanceOf(address(this)));
    }

    /// @inheritdoc IGovFeeDistributor
    function depositBalanceToReserve(uint256 _amount)
        external
        nonReentrant
        notKilled
    {
        _depositBalanceToReserve(_amount);
    }

    /// @inheritdoc IGovFeeDistributor
    function claim()
        external
        nonReentrant
        notKilled
        claimPreparation
        returns (uint256)
    {
        return _claim(msg.sender);
    }

    /// @inheritdoc IGovFeeDistributor
    function claim(address _to)
        external
        nonReentrant
        notKilled
        claimPreparation
        returns (uint256)
    {
        if (_to == address(0)) revert AddressZero();
        return _claim(_to);
    }

    /// @inheritdoc IGovFeeDistributor
    function claimMany(address[20] calldata _receivers)
        external
        nonReentrant
        notKilled
        claimPreparation
        returns (bool)
    {
        uint256 _total = 0;

        for (uint256 i = 0; i < 20; i++) {
            address _receiver = _receivers[i];
            // no receiver specified, then end the loop immidiately
            if (_receiver == address(0)) break;

            uint256 _amount = _claim(_receiver);
            _total += _amount;
        }

        return true;
    }

    /// @inheritdoc IGovFeeDistributor
    function veSupplyCheckpoint() external {
        VeCheckpointLogic.checkpoint(votingEscrow, veCheckpointRecord);
    }

    /// @inheritdoc IGovFeeDistributor
    function iTokenCheckPoint() external {
        ITokenCheckpointLogic.checkpoint(
            iToken,
            address(this),
            iTokenCheckpointRecord
        );
    }

    /// @inheritdoc IGovFeeDistributor
    function burn() external nonReentrant notKilled returns (bool) {
        uint256 _amount = IERC20(iToken).balanceOf(msg.sender);

        if (_amount == 0) return false;

        IERC20(iToken).safeTransferFrom(msg.sender, address(this), _amount);

        // needs to wait for interval to checkpoint
        bool _checkpointable = block.timestamp >
            iTokenCheckpointRecord.lastITokenTime + TOKEN_CHECKPOINT_INTERVAL;

        if (_checkpointable)
            ITokenCheckpointLogic.checkpoint(
                iToken,
                address(this),
                iTokenCheckpointRecord
            );

        emit Burnt(msg.sender, _amount);

        return true;
    }

    /// @inheritdoc IGovFeeDistributor
    function killMe(address _to) external nonReentrant onlyOwner {
        isKilled = true;

        uint256 _iTokenBalance = IERC20(iToken).balanceOf(address(this));
        uint256 _depositTokenBalance = IERC20(depositToken).balanceOf(
            address(this)
        );
        IERC20(iToken).safeTransfer(_to, _iTokenBalance);
        IERC20(depositToken).safeTransfer(_to, _depositTokenBalance);

        emit Killed(block.timestamp);
    }

    /// @inheritdoc IGovFeeDistributor
    function lastITokenBalance() external view returns (uint256) {
        return iTokenCheckpointRecord.lastITokenBalance;
    }

    /// @inheritdoc IGovFeeDistributor
    function lastITokenTime() external view returns (uint256) {
        return iTokenCheckpointRecord.lastITokenTime;
    }

    /**
     * public functions
     */

    /// @inheritdoc IGovFeeDistributor
    function iTokenSupplyAt(uint256 _weekCursor) public view returns (uint256) {
        return iTokenCheckpointRecord.iTokenSupplyPerWeek[_weekCursor];
    }

    /// @inheritdoc IGovFeeDistributor
    function veSupplyAt(uint256 _weekCursor) public view returns (uint256) {
        return veCheckpointRecord.veSupplyPerWeek[_weekCursor];
    }

    /**
     * internal functions
     */

    function _depositBalanceToReserve(uint256 _amount) internal {
        uint256 _balance = IERC20(depositToken).balanceOf(address(this));
        if (_amount == 0) revert AmountZero();
        // needs enough amount to deposit
        if (_balance < _amount) revert InsufficientBalance();

        // allowance increased on demand
        uint256 _allowanceShortage = _amount -
            IERC20(depositToken).allowance(address(this), vault);

        if (_allowanceShortage > 0)
            IERC20(depositToken).safeIncreaseAllowance(
                vault,
                _allowanceShortage
            );

        uint256 _beforeDeposit = IERC20(iToken).balanceOf(address(this));
        uint256 _minted = ICDSTemplate(iToken).deposit(_amount);

        // check balance correctly increased
        assert(
            IERC20(iToken).balanceOf(address(this)) == _beforeDeposit + _minted
        );

        emit ITokenReceived(_minted);
    }

    /**
     * @dev claim proceeds in following steps:
     *      1. get(or initialize) user's current veINSURE and iToken distribution state
     *      2. calculate distribution amount(iterate distribution cursor and user point)
     *      3. update user's state to latest
     *      4. execute distribution(if any distribution is)
     */
    function _claim(address _to) internal returns (uint256) {
        // current veINSURE checkpoint the user is at
        uint256 _maxUserEpoch = VotingEscrow(votingEscrow).user_point_epoch(
            _to
        );
        // latest week boundary distribution completed
        uint256 _latestITokenSupplyTime = (iTokenCheckpointRecord
            .lastITokenTime / WEEK) * WEEK;

        // no lock exist
        if (_maxUserEpoch == 0) return 0;

        // if this claim is the first time, initialize epoch
        uint256 _userEpoch = _getCurrentUserEpoch(_to, _maxUserEpoch);

        // anchored to next user point
        VotingEscrow.Point memory _nextUserPoint = _getUserPoint(
            _to,
            _userEpoch
        );
        // actually calculated by this point. start from zero
        VotingEscrow.Point memory _userPoint = VotingEscrow.Point(0, 0, 0, 0);

        uint256 _weekCursor = _getUserWeekCursor(_to, _nextUserPoint.ts);

        // no reward claimable
        if (_weekCursor >= _latestITokenSupplyTime) return 0;

        uint256 _distribution = 0;

        for (uint256 i = 0; i < 50; i++) {
            // distribution should be executed until last iToken checkpoint
            if (_weekCursor > _latestITokenSupplyTime) break;

            // user ve point before than current distribution point, then move epoch and point forward
            if (
                _weekCursor >= _nextUserPoint.ts && _userEpoch <= _maxUserEpoch
            ) {
                _userEpoch++;
                _userPoint = _nextUserPoint;

                // in this case, no userchecpoint found anymore, so keep it zero
                if (_userEpoch > _maxUserEpoch)
                    _nextUserPoint = VotingEscrow.Point(0, 0, 0, 0);
                    // otherwise, keep updating user point
                else _nextUserPoint = _getUserPoint(_to, _userEpoch);
            }
            // otherwise, add iToken distribution
            else {
                // calculate veINSURE balance from user point
                int256 _dt = (_weekCursor - _userPoint.ts).toInt256();
                int256 _val = _userPoint.bias - _dt * _userPoint.slope;
                uint256 _userVeBalance = _val > 0 ? _val.toUint256() : 0;

                // even if passed user's max epoch, continue until veINSURE worth zero
                if (_userVeBalance == 0 && _userEpoch > _maxUserEpoch) break;

                // distribution determined by the share of user veINSURE balance
                if (_userVeBalance > 0) {
                    uint256 _iTokenSupply = iTokenSupplyAt(_weekCursor);
                    uint256 _veTotalSupply = veSupplyAt(_weekCursor);

                    _distribution +=
                        (_userVeBalance * _iTokenSupply) /
                        _veTotalSupply;
                }
                _weekCursor += WEEK;
            }
        }

        // update user current state
        _userEpoch = Math.min(_maxUserEpoch, _userEpoch - 1);
        userEpochs[_to] = _userEpoch;
        userTimeCursors[_to] = _weekCursor;

        // finally, if distribution exists, transfer it to the user
        if (_distribution != 0) {
            IERC20(iToken).safeTransfer(_to, _distribution);
            unchecked {
                iTokenCheckpointRecord.lastITokenBalance -= _distribution;
            }
            emit Claimed(_to, _distribution);
        }

        return _distribution;
    }

    /**
     * @dev if user epoch saved in storage, return it.
     *      otherwise, do binary search to find nearest epoch
     */
    function _getCurrentUserEpoch(address _user, uint256 _maxUserEpoch)
        internal
        view
        returns (uint256)
    {
        uint256 _weekCursor = userTimeCursors[_user];
        if (_weekCursor == 0) {
            uint256 _userEpoch = _findUserEpoch(
                _user,
                distributionStart,
                _maxUserEpoch
            );
            return _userEpoch != 0 ? _userEpoch : 1;
        }

        return userEpochs[_user];
    }

    /**
     * @dev get user point by epoch, reconstruct it to struct
     */
    function _getUserPoint(address _user, uint256 _userEpoch)
        internal
        view
        returns (VotingEscrow.Point memory)
    {
        (int256 _bias, int256 _slope, uint256 _ts, uint256 _blk) = VotingEscrow(
            votingEscrow
        ).user_point_history(_user, _userEpoch);

        return VotingEscrow.Point(_bias, _slope, _ts, _blk);
    }

    /**
     * @dev if user cursor saved in storage, return it.
     *      otherwise, initialize cursor.
     */
    function _getUserWeekCursor(address _user, uint256 _userPointTs)
        internal
        view
        returns (uint256)
    {
        uint256 _weekCursor = userTimeCursors[_user];

        if (_weekCursor != 0) return _weekCursor;

        // if first time, distribution will be active from next week boundary
        uint256 _roundedUserPointTs = ((_userPointTs + WEEK - 1) / WEEK) * WEEK;

        // if the rounded cursor before than distribution start, skip for it
        if (_roundedUserPointTs < distributionStart) return distributionStart;

        return _roundedUserPointTs;
    }

    /**
     * @dev find nearest user epoch less than given ts
     * @param _user user address
     * @param _targetTs timestamp to find user epoch
     * @param _maxUserEpoch upper limit for the exploration
     * @return user epoch found
     */
    function _findUserEpoch(
        address _user,
        uint256 _targetTs,
        uint256 _maxUserEpoch
    ) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = _maxUserEpoch;

        for (uint256 i = 0; i < 20; i++) {
            if (_min >= _max) break;

            uint256 _mid = (_min + _max + 2) / 2;

            uint256 _ts = VotingEscrow(votingEscrow).user_point_history__ts(
                _user,
                _mid
            );

            if (_ts > _targetTs) {
                unchecked {
                    _max = _mid - 1;
                }
            } else {
                unchecked {
                    _min = _mid;
                }
            }
        }

        return _min;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ICollateralManager {
    function checkStatus(address _addr) external returns (bool);
}

pragma solidity 0.8.10;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * @title InsureDAO governance fee distributor
 * @author InsureDAO
 * @notice This distributes governance fee, which is occured each insurance and saved in the vault,
 *         to veINSURE holders.
 */
interface IGovFeeDistributor {
    /**
     * @notice deposits all govanance fee this contract has,
     *         then receives iToken(Reserve pool's LP token).
     */
    function depositBalanceToReserve() external;

    /**
     * @notice overload function to specify the amount for LP token conversion.
     * @param _amount the amount deposited into reserve pool
     */
    function depositBalanceToReserve(uint256 _amount) external;

    /**
     * @notice claim all eligible amount of iToken to msg sender.
     *         this should be called by a veINSURE holder.
     * @return claimed iToken amount
     */
    function claim() external returns (uint256);

    /**
     * @notice claim all eligible amount of iToken on behalf of holder.
     *         anyone can call this function.
     * @param _to veINSURE holder address all claimed reward send
     * @return claimed iToken amount
     */
    function claim(address _to) external returns (uint256);

    /**
     * @notice execute claim for multiple addresses, this used for multi user distribution,
     *         or claim for same user who has large veINSURE hisrory.
     * @param _receivers the addresses of veINSURE holders.
     * @dev you can include same addresses as params for large veINSURE history.
     * @dev addresses should be left aligned, otherwise claim will be cancelled in the middle of process.
     * @return claim success
     */
    function claimMany(address[20] calldata _receivers) external returns (bool);

    /**
     * @notice checkpoints veINSURE total supply each week.
     *         see VeCheckpointLogic.sol for more details.
     */
    function veSupplyCheckpoint() external;

    /**
     * @notice checkpoints iToken(Reseve pool LP token) total supply each week.
     *         see ITokenCheckpointLogic.sol for more details.
     */
    function iTokenCheckPoint() external;

    /**
     * @notice burn all iToken of msg.sender.
     * @dev technically, token does not go to address(0) but goes to this contract.
     *      so burning increases this contract balance and distributed to holders again.
     * @return burn success
     */
    function burn() external returns (bool);

    /**
     * @notice deactivate the distributor contract. once killed,
     *         the contract permanently unavailable.
     */
    function killMe(address _to) external;

    /**
     * @notice get last checkpointed iToken balance.
     * @return last checkpointed iToken balance.
     */
    function lastITokenBalance() external view returns (uint256);

    /**
     * @notice get last iToken checkpointed time.
     * @return last iToken checkpointed time.
     */
    function lastITokenTime() external view returns (uint256);

    /**
     * @notice get total iToken distribution of a week.
     * @param _weekCursor week boundary distribution activated
     * @dev week cursor must be rounded for the start of a week.
     * @return total iToken distribution of a week.
     */
    function iTokenSupplyAt(uint256 _weekCursor)
        external
        view
        returns (uint256);

    /**
     * @notice get total veINSURE supply of a week.
     * @param _weekCursor week boundary iToken distribution activated
     * @dev week cursor must be rounded for the start of a week.
     * @return total veINSURE supply of a week.
     */
    function veSupplyAt(uint256 _weekCursor) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ISmartWalletChecker {
    function check(address _addr) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICDSTemplate {
    function compensate(uint256) external returns (uint256 _compensated);

    //onlyOwner
    function defund(address _to, uint256 _amount) external;

    function deposit(uint256 _amount) external returns (uint256 _mintAmount);

    function withdraw(uint256 _amount) external;
}

pragma solidity 0.8.10;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}

pragma solidity 0.8.10;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

uint256 constant WEEK = 7 * 86_400;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * @title Voting Escrow checkpoint logic
 * @author InsureDAO
 * @notice call checkpoint of voting escrow, and save week boundary to storage
 */
library ITokenCheckpointLogic {
    /**
     * @param lastITokenTime last checkpointed week boundary
     * @param lastITokenBalance the balance at last checkpointed week boundary
     * @param iTokenSupplyPerWeek iToken token distribution amount each week
     */
    struct ITokenCheckpoint {
        uint256 lastITokenTime;
        uint256 lastITokenBalance;
        uint256[1e15] iTokenSupplyPerWeek;
    }

    event ITokenCheckpointed(uint256 _checkpointTime);

    /**
     * @notice checkpoints iToken total distribution of each week boundary.
     *         this continues to reach latest week.
     */
    function checkpoint(
        address _iToken,
        address _distributor,
        ITokenCheckpoint storage record
    ) internal {
        uint256 _currentBalance = IERC20(_iToken).balanceOf(_distributor);
        // distributes incremental balance from last checkpoint
        uint256 _distribution = _currentBalance - record.lastITokenBalance;
        // saved last checkpoint
        uint256 _start = record.lastITokenTime;
        // the time from last checkpoint
        uint256 _entireDuration = block.timestamp - _start;

        uint256 _currentWeek = (_start / WEEK) * WEEK;
        uint256 _nextWeek;

        // saves last checkpoint state
        record.lastITokenBalance = _currentBalance;
        record.lastITokenTime = block.timestamp;

        for (uint256 i = 0; i < 20; i++) {
            _nextWeek = _currentWeek + WEEK;

            // reached latest week, loop end
            if (block.timestamp < _nextWeek) {
                // no duration but balance increased
                if (_entireDuration == 0 && block.timestamp == _start) {
                    record.iTokenSupplyPerWeek[_currentWeek] = _distribution;
                }
                // decide the portion of distribution
                else {
                    uint256 _currentDuration = (block.timestamp - _start);
                    record.iTokenSupplyPerWeek[_currentWeek] =
                        (_distribution * _currentDuration) /
                        _entireDuration;
                }
                break;
            }
            // unrecorded weeks remaining, loop continue
            else {
                // no duration but balance increased
                if (_entireDuration == 0 && _nextWeek == _start) {
                    record.iTokenSupplyPerWeek[_currentWeek] += _distribution;
                }
                // decide the portion of distribution
                else {
                    uint256 _currentDuration = (_nextWeek - _start);
                    record.iTokenSupplyPerWeek[_currentWeek] +=
                        (_distribution * _currentDuration) /
                        _entireDuration;
                }
            }

            // tracks to calculate duration
            _start = _nextWeek;
            _currentWeek = _nextWeek;
        }

        emit ITokenCheckpointed(record.lastITokenTime);
    }
}

pragma solidity 0.8.10;

import {VotingEscrow} from "../VotingEscrow.sol";

uint256 constant WEEK = 7 * 86_400;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * @title Voting Escrow checkpoint logic
 * @author InsureDAO
 * @notice call checkpoint of voting escrow, and save week boundary to storage
 */
library VeCheckpointLogic {
    /**
     * @param veSupplyPerWeek ve token total supply at week
     * @param latestTimeCursor last checkpointed week boundary
     */
    struct VeCheckpoint {
        uint256[1e15] veSupplyPerWeek;
        uint256 latestTimeCursor;
    }
    event VeCheckpointed(uint256 _lastCheckpointTime);

    /**
     * @notice checkpoints ve total supply of each week boundary.
     *         this continues to reach latest week.
     * @dev having own ve checkpoint helps to reduce gas cost for external call.
     */
    function checkpoint(address _votingEscrow, VeCheckpoint storage params)
        internal
    {
        // this week rounded by week
        uint256 _weekStartTs = (block.timestamp / WEEK) * WEEK;
        // makes votingEscrow latest
        VotingEscrow(_votingEscrow).checkpoint();
        // this means how far checkpoint was recorded
        uint256 _timeCursor = params.latestTimeCursor;

        // record veINSURE supply each week
        for (uint256 i = 0; i < 20; i++) {
            if (_timeCursor > _weekStartTs) break;

            // do binary search
            uint256 _epoch = _findGlobalEpoch(_votingEscrow, _timeCursor);
            (int256 _bias, int256 _slope, uint256 _ts, ) = VotingEscrow(
                _votingEscrow
            ).point_history(_epoch);

            // diference from current week boundary
            int256 _dt = _timeCursor > _ts
                ? int256(_timeCursor - _ts)
                : int256(0);

            // saving supply to storage
            int256 _supply = _bias - _dt * _slope;
            params.veSupplyPerWeek[_timeCursor] = uint256(_supply);

            unchecked {
                _timeCursor += WEEK;
            }
        }

        params.latestTimeCursor = _timeCursor;

        emit VeCheckpointed(_timeCursor);
    }

    /**
     * @dev find nearest user epoch less than given ts
     * @param _votingEscrow voting escrow address
     * @param _targetTs timestamp to find global epoch
     * @return global epoch found
     */
    function _findGlobalEpoch(address _votingEscrow, uint256 _targetTs)
        private
        view
        returns (uint256)
    {
        uint256 _max = VotingEscrow(_votingEscrow).epoch();
        uint256 _min = 0;

        // binary search
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 2) / 2;

            (, , uint256 _ts, ) = VotingEscrow(_votingEscrow).point_history(
                _mid
            );

            if (_ts > _targetTs) {
                unchecked {
                    _max = _mid - 1;
                }
            } else {
                unchecked {
                    _min = _mid;
                }
            }
        }

        return _min;
    }
}

pragma solidity 0.8.10;

/***
 *@title VotingEscrow
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice Votes have a weight depending on time, so that users are
 *        committed to the future of (whatever they are voting for)
 *@dev Vote weight decays linearly over time. Lock time cannot be
 *     more than `MAXTIME` (4 years).
 */

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime (4 years?)

// Interface for checking whether address belongs to a whitelisted
// type of a smart wallet.
// When new types are added - the whole contract is changed
// The check() method is modifying to be able to use caching
// for individual wallet addresses
import "./interfaces/dao/ISmartWalletChecker.sol";
import "./interfaces/dao/ICollateralManager.sol";

import "./interfaces/pool/IOwnership.sol";

//libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VotingEscrow is ReentrancyGuard {
    struct Point {
        int256 bias;
        int256 slope; // - dweight / dt
        uint256 ts; //timestamp
        uint256 blk; // block
    }
    // We cannot really do block numbers per se b/c slope is per time, not per block
    // and per block could be fairly bad b/c Ethereum changes blocktimes.
    // What we can do is to extrapolate ***At functions

    struct LockedBalance {
        int256 amount;
        uint256 end;
    }

    int256 constant DEPOSIT_FOR_TYPE = 0;
    int256 constant CREATE_LOCK_TYPE = 1;
    int256 constant INCREASE_LOCK_AMOUNT = 2;
    int256 constant INCREASE_UNLOCK_TIME = 3;

    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 indexed locktime,
        int256 _type,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event ForceUnlock(address target, uint256 value, uint256 ts);

    event Supply(uint256 prevSupply, uint256 supply);

    event commitWallet(address newSmartWalletChecker);
    event applyWallet(address newSmartWalletChecker);
    event commitCollateralManager(address newCollateralManager);
    event applyCollateralManager(address newCollateralManager);

    uint256 constant WEEK = 7 * 86400; // all future times are rounded by week
    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 constant MULTIPLIER = 10**18;

    address public token;
    uint256 public supply;

    mapping(address => LockedBalance) public locked;

    //everytime user deposit/withdraw/change_locktime, these values will be updated;
    uint256 public epoch;
    Point[100000000000000000000000000000] public point_history; // epoch -> unsigned point.
    mapping(address => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]
    mapping(address => uint256) public user_point_epoch;
    mapping(uint256 => int256) public slope_changes; // time -> signed slope change

    // Aragon's view methods for compatibility
    address public controller;
    bool public transfersEnabled;

    string public name;
    string public symbol;
    string public version;
    uint256 public constant decimals = 18;

    // Checker for whitelisted (smart contract) wallets which are allowed to deposit
    // The goal is to prevent tokenizing the escrow
    address public future_smart_wallet_checker;
    address public smart_wallet_checker;

    address public collateral_manager;
    address public future_collateral_manager;

    IOwnership public immutable ownership;

    modifier onlyOwner() {
        require(
            ownership.owner() == msg.sender,
            "Caller is not allowed to operate"
        );
        _;
    }

    modifier checkStatus() {
        if (collateral_manager != address(0)) {
            require(
                ICollateralManager(collateral_manager).checkStatus(msg.sender),
                "rejected by collateral manager"
            );
        }
        _;
    }

    /***
     *@notice Contract constructor
     *@param token_addr `InsureToken` token address
     *@param _name Token name
     *@param _symbol Token symbol
     *@param _version Contract version - required for Aragon compatibility
     */
    constructor(
        address _token_addr,
        string memory _name,
        string memory _symbol,
        string memory _version,
        address _ownership
    ) {
        ownership = IOwnership(_ownership);
        token = _token_addr;
        point_history[0].blk = block.number;
        point_history[0].ts = block.timestamp;
        controller = msg.sender;
        transfersEnabled = true;

        name = _name;
        symbol = _symbol;
        version = _version;
    }

    /***
     *@notice Check if the call is from a whitelisted smart contract, revert if not
     *@param _addr Address to be checked
     */
    function assert_not_contract(address _addr) internal {
        if (_addr != tx.origin) {
            address checker = smart_wallet_checker; //not going to be deployed at the moment of launch.
            if (checker != address(0)) {
                if (ISmartWalletChecker(checker).check(_addr)) {
                    return;
                }
            }
            revert("contract depositors not allowed");
        }
    }

    /***
     *@notice Get the most recently recorded rate of voting power decrease for `_addr`
     *@param _addr Address of the user wallet
     *@return Value of the slope
     */
    function get_last_user_slope(address _addr)
        external
        view
        returns (uint256)
    {
        uint256 uepoch = user_point_epoch[_addr];
        return uint256(user_point_history[_addr][uepoch].slope);
    }

    /***
     *@notice Get the timestamp for checkpoint `_idx` for `_addr`
     *@param _addr User wallet address
     *@param _idx User epoch number
     *@return Epoch time of the checkpoint
     */
    function user_point_history__ts(address _addr, uint256 _idx)
        external
        view
        returns (uint256)
    {
        return user_point_history[_addr][_idx].ts;
    }

    /***
     *@notice Get timestamp when `_addr`'s lock finishes
     *@param _addr User wallet
     *@return Epoch time of the lock end
     */
    function locked__end(address _addr) external view returns (uint256) {
        return locked[_addr].end;
    }

    /***
     *@notice Record global and per-user data to checkpoint
     *@param _addr User's wallet address. No user checkpoint if 0x0
     *@param _old_locked Pevious locked amount / end lock time for the user
     *@param _new_locked New locked amount / end lock time for the user
     */
    function _checkpoint(
        address _addr,
        LockedBalance memory _old_locked,
        LockedBalance memory _new_locked
    ) internal {
        Point memory _u_old;
        Point memory _u_new;
        int256 _old_dslope = 0;
        int256 _new_dslope = 0;
        uint256 _epoch = epoch;

        if (_addr != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (_old_locked.end > block.timestamp && _old_locked.amount > 0) {
                unchecked {
                    _u_old.slope = _old_locked.amount / int256(MAXTIME);
                }
                _u_old.bias =
                    _u_old.slope *
                    int256(_old_locked.end - block.timestamp);
            }
            if (_new_locked.end > block.timestamp && _new_locked.amount > 0) {
                unchecked {
                    _u_new.slope = _new_locked.amount / int256(MAXTIME);
                }
                _u_new.bias =
                    _u_new.slope *
                    int256(_new_locked.end - block.timestamp);
            }

            // Read values of scheduled changes in the slope
            // _old_locked.end can be in the past and in the future
            // _new_locked.end can ONLY by in the FUTURE unless everything expired than zeros
            _old_dslope = slope_changes[_old_locked.end];
            if (_new_locked.end != 0) {
                if (_new_locked.end == _old_locked.end) {
                    _new_dslope = _old_dslope;
                } else {
                    _new_dslope = slope_changes[_new_locked.end];
                }
            }
        }
        Point memory _last_point = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });
        if (_epoch > 0) {
            _last_point = point_history[_epoch];
        }
        uint256 _last_checkpoint = _last_point.ts;
        // _initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory _initial_last_point = _last_point;
        uint256 _block_slope = 0; // dblock/dt
        if (block.timestamp > _last_point.ts) {
            _block_slope =
                (MULTIPLIER * (block.number - _last_point.blk)) /
                (block.timestamp - _last_point.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        uint256 _t_i;
        unchecked {
            _t_i = (_last_checkpoint / WEEK) * WEEK;
        }
        for (uint256 i; i < 255; ) {
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            _t_i += WEEK;
            int256 d_slope = 0;
            if (_t_i > block.timestamp) {
                _t_i = block.timestamp;
            } else {
                d_slope = slope_changes[_t_i];
            }
            _last_point.bias =
                _last_point.bias -
                _last_point.slope *
                int256(_t_i - _last_checkpoint);
            _last_point.slope += d_slope;
            if (_last_point.bias < 0) {
                // This can happen
                _last_point.bias = 0;
            }
            if (_last_point.slope < 0) {
                // This cannot happen - just in case
                _last_point.slope = 0;
            }
            _last_checkpoint = _t_i;
            _last_point.ts = _t_i;
            _last_point.blk =
                _initial_last_point.blk +
                ((_block_slope * (_t_i - _initial_last_point.ts)) / MULTIPLIER);
            _epoch += 1;
            if (_t_i == block.timestamp) {
                _last_point.blk = block.number;
                break;
            } else {
                point_history[_epoch] = _last_point;
            }
            unchecked {
                ++i;
            }
        }
        epoch = _epoch;
        // Now point_history is filled until t=now

        if (_addr != address(0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            _last_point.slope += _u_new.slope - _u_old.slope;
            _last_point.bias += _u_new.bias - _u_old.bias;
            if (_last_point.slope < 0) {
                _last_point.slope = 0;
            }
            if (_last_point.bias < 0) {
                _last_point.bias = 0;
            }
        }
        // Record the changed point into history
        point_history[_epoch] = _last_point;

        address _addr2 = _addr; //To avoid being "Stack Too Deep"

        if (_addr2 != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [_new_locked.end]
            // and add old_user_slope to [_old_locked.end]
            if (_old_locked.end > block.timestamp) {
                // _old_dslope was <something> - _u_old.slope, so we cancel that
                _old_dslope += _u_old.slope;
                if (_new_locked.end == _old_locked.end) {
                    _old_dslope -= _u_new.slope; // It was a new deposit, not extension
                }
                slope_changes[_old_locked.end] = _old_dslope;
            }
            if (_new_locked.end > block.timestamp) {
                if (_new_locked.end > _old_locked.end) {
                    _new_dslope -= _u_new.slope; // old slope disappeared at this point
                    slope_changes[_new_locked.end] = _new_dslope;
                }
                // else we recorded it already in _old_dslope
            }

            // Now handle user history
            uint256 _user_epoch;
            unchecked {
                _user_epoch = user_point_epoch[_addr2] + 1;
            }

            user_point_epoch[_addr2] = _user_epoch;
            _u_new.ts = block.timestamp;
            _u_new.blk = block.number;
            user_point_history[_addr2][_user_epoch] = _u_new;
        }
    }

    /***
     *@notice Deposit and lock tokens for a user
     *@param _depositor Spender's wallet address
     *@param _beneficiary Beneficiary's wallet address
     *@param _value Amount to deposit
     *@param _unlock_time New time when to unlock the tokens, or 0 if unchanged
     *@param _locked_balance Previous locked amount / timestamp
     */
    function _deposit_for(
        address _depositor,
        address _beneficiary,
        uint256 _value,
        uint256 _unlock_time,
        LockedBalance memory _locked_balance,
        int256 _type
    ) internal {
        LockedBalance memory _locked = LockedBalance(
            _locked_balance.amount,
            _locked_balance.end
        );
        LockedBalance memory _old_locked = LockedBalance(
            _locked_balance.amount,
            _locked_balance.end
        );

        uint256 _supply_before = supply;
        supply = _supply_before + _value;
        //Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount = _locked.amount + int256(_value);
        if (_unlock_time != 0) {
            _locked.end = _unlock_time;
        }
        locked[_beneficiary] = _locked;

        // Possibilities
        // Both _old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)

        _checkpoint(_beneficiary, _old_locked, _locked);

        if (_value != 0) {
            require(
                IERC20(token).transferFrom(_depositor, address(this), _value)
            );
        }

        emit Deposit(_beneficiary, _value, _locked.end, _type, block.timestamp);
        emit Supply(_supply_before, _supply_before + _value);
    }

    function checkpoint() public {
        /***
         *@notice Record global data to checkpoint
         */
        LockedBalance memory _a;
        LockedBalance memory _b;
        _checkpoint(address(0), _a, _b);
    }

    /***
     *@notice Deposit `_value` tokens for `_addr` and add to the lock
     *@dev Anyone (even a smart contract) can deposit for someone else, but
     *    cannot extend their locktime and deposit for a brand new user
     *@param _addr User's wallet address
     *@param _value Amount to add to user's lock
     */
    function deposit_for(address _addr, uint256 _value) external nonReentrant {
        LockedBalance memory _locked = locked[_addr];

        require(_value > 0, "dev: need non-zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock.");

        _deposit_for(msg.sender, _addr, _value, 0, _locked, DEPOSIT_FOR_TYPE);
    }

    /***
     *@notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
     *@param _value Amount to deposit
     *@param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
     */
    function create_lock(uint256 _value, uint256 _unlock_time)
        external
        nonReentrant
    {
        assert_not_contract(msg.sender);
        _unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0, "dev: need non-zero value");
        require(_locked.amount == 0, "Withdraw old tokens first");
        require(
            _unlock_time > block.timestamp,
            "Can lock until time in future"
        );
        require(
            _unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _deposit_for(
            msg.sender,
            msg.sender,
            _value,
            _unlock_time,
            _locked,
            CREATE_LOCK_TYPE
        );
    }

    /***
     *@notice Deposit `_value` additional tokens for `msg.sender`
     *        without modifying the unlock time
     *@param _value Amount of tokens to deposit and add to the lock
     */
    function increase_amount(uint256 _value) external nonReentrant {
        assert_not_contract(msg.sender);
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0);
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock.");

        _deposit_for(
            msg.sender,
            msg.sender,
            _value,
            0,
            _locked,
            INCREASE_LOCK_AMOUNT
        );
    }

    /***
     *@notice Extend the unlock time for `msg.sender` to `_unlock_time`
     *@param _unlock_time New epoch time for unlocking
     */
    function increase_unlock_time(uint256 _unlock_time) external nonReentrant {
        assert_not_contract(msg.sender); //@shun: need to convert to solidity
        LockedBalance memory _locked = locked[msg.sender];
        unchecked {
            _unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks
        }

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(_unlock_time > _locked.end, "Can only increase lock duration");
        require(
            _unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _deposit_for(
            msg.sender,
            msg.sender,
            0,
            _unlock_time,
            _locked,
            INCREASE_UNLOCK_TIME
        );
    }

    /***
     *@notice Withdraw all tokens for `msg.sender`
     *@dev Only possible if the lock has expired
     */
    function withdraw() external checkStatus nonReentrant {
        LockedBalance memory _locked = LockedBalance(
            locked[msg.sender].amount,
            locked[msg.sender].end
        );

        require(block.timestamp >= _locked.end, "The lock didn't expire");
        uint256 _value = uint256(_locked.amount);

        LockedBalance memory _old_locked = LockedBalance(
            locked[msg.sender].amount,
            locked[msg.sender].end
        );

        _locked.end = 0;
        _locked.amount = 0;
        locked[msg.sender] = _locked;
        uint256 _supply_before = supply;
        supply = _supply_before - _value;

        // _old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, _old_locked, _locked);

        require(IERC20(token).transfer(msg.sender, _value));

        emit Withdraw(msg.sender, _value, block.timestamp);
        emit Supply(_supply_before, _supply_before - _value);
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /***
     *@notice Binary search to estimate timestamp for block number
     *@param _block Block to find
     *@param _max_epoch Don't go beyond this epoch
     *@return Approximate timestamp for block
     */
    function find_block_epoch(uint256 _block, uint256 _max_epoch)
        internal
        view
        returns (uint256)
    {
        // Binary search
        uint256 _min = 0;
        uint256 _max = _max_epoch;
        unchecked {
            for (uint256 i; i <= 128; i++) {
                // Will be always enough for 128-bit numbers
                if (_min >= _max) {
                    break;
                }
                uint256 _mid = (_min + _max + 1) / 2;
                if (point_history[_mid].blk <= _block) {
                    _min = _mid;
                } else {
                    _max = _mid - 1;
                }
            }
        }
        return _min;
    }

    /***
     *@notice Get the current voting power for `msg.sender`
     *@dev Adheres to the ERC20 `balanceOf` interface for Metamask & Snapshot compatibility
     *@param _addr User wallet address
     *@return User's present voting power
     */
    function balanceOf(address _addr) external view returns (uint256) {
        uint256 _t = block.timestamp;

        uint256 _epoch = user_point_epoch[_addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _last_point = user_point_history[_addr][_epoch];
            _last_point.bias -= _last_point.slope * int256(_t - _last_point.ts);
            if (_last_point.bias < 0) {
                _last_point.bias = 0;
            }
            return uint256(_last_point.bias);
        }
    }

    /***
     *@notice Get the current voting power for `msg.sender`
     *@dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     *@param _addr User wallet address
     *@param _t Epoch time to return voting power at
     *@return User voting power
     *@dev return the present voting power if _t is 0
     */
    function balanceOf(address _addr, uint256 _t)
        external
        view
        returns (uint256)
    {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = user_point_epoch[_addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _last_point = user_point_history[_addr][_epoch];
            _last_point.bias -= _last_point.slope * int256(_t - _last_point.ts);
            if (_last_point.bias < 0) {
                _last_point.bias = 0;
            }
            return uint256(_last_point.bias);
        }
    }

    //Struct to avoid "Stack Too Deep"
    struct Parameters {
        uint256 min;
        uint256 max;
        uint256 max_epoch;
        uint256 d_block;
        uint256 d_t;
    }

    /***
     *@notice Measure voting power of `_addr` at block height `_block`
     *@dev Adheres to MiniMe `balanceOfAt` interface https//github.com/Giveth/minime
     *@param _addr User's wallet address
     *@param _block Block to calculate the voting power at
     *@return Voting power
     */
    function balanceOfAt(address _addr, uint256 _block)
        external
        view
        returns (uint256)
    {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        require(_block <= block.number);

        Parameters memory _st;

        // Binary search
        _st.min = 0;
        _st.max = user_point_epoch[_addr];
        unchecked {
            for (uint256 i; i <= 128; i++) {
                // Will be always enough for 128-bit numbers
                if (_st.min >= _st.max) {
                    break;
                }
                uint256 _mid = (_st.min + _st.max + 1) / 2;
                if (user_point_history[_addr][_mid].blk <= _block) {
                    _st.min = _mid;
                } else {
                    _st.max = _mid - 1;
                }
            }
        }

        Point memory _upoint = user_point_history[_addr][_st.min];

        _st.max_epoch = epoch;
        uint256 _epoch = find_block_epoch(_block, _st.max_epoch);
        Point memory _point_0 = point_history[_epoch];
        _st.d_block = 0;
        _st.d_t = 0;
        if (_epoch < _st.max_epoch) {
            Point memory _point_1 = point_history[_epoch + 1];
            _st.d_block = _point_1.blk - _point_0.blk;
            _st.d_t = _point_1.ts - _point_0.ts;
        } else {
            _st.d_block = block.number - _point_0.blk;
            _st.d_t = block.timestamp - _point_0.ts;
        }
        uint256 block_time = _point_0.ts;
        if (_st.d_block != 0) {
            block_time += (_st.d_t * (_block - _point_0.blk)) / _st.d_block;
        }

        _upoint.bias -= _upoint.slope * int256(block_time - _upoint.ts);
        if (_upoint.bias >= 0) {
            return uint256(_upoint.bias);
        }
    }

    /***
     *@notice Calculate total voting power at some point in the past
     *@param point The point (bias/slope) to start search from
     *@param t Time to calculate the total voting power at
     *@return Total voting power at that time
     */
    function supply_at(Point memory point, uint256 t)
        internal
        view
        returns (uint256)
    {
        Point memory _last_point = point;
        uint256 _t_i;
        unchecked {
            _t_i = (_last_point.ts / WEEK) * WEEK;
        }
        for (uint256 i; i < 255; ) {
            _t_i += WEEK;
            int256 d_slope = 0;

            if (_t_i > t) {
                _t_i = t;
            } else {
                d_slope = slope_changes[_t_i];
            }
            _last_point.bias -=
                _last_point.slope *
                int256(_t_i - _last_point.ts);

            if (_t_i == t) {
                break;
            }
            _last_point.slope += d_slope;
            _last_point.ts = _t_i;
            unchecked {
                ++i;
            }
        }

        if (_last_point.bias < 0) {
            _last_point.bias = 0;
        }
        return uint256(_last_point.bias);
    }

    /***
     *@notice Calculate total voting power
     *@dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     *@return Total voting power
     */

    function totalSupply() external view returns (uint256) {
        uint256 _epoch = epoch;
        Point memory _last_point = point_history[_epoch];

        return supply_at(_last_point, block.timestamp);
    }

    /***
     *@notice Calculate total voting power
     *@dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     *@return Total voting power
     */
    function totalSupply(uint256 _t) external view returns (uint256) {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = epoch;
        Point memory _last_point = point_history[_epoch];

        return supply_at(_last_point, _t);
    }

    /***
     *@notice Calculate total voting power at some point in the past
     *@param _block Block to calculate the total voting power at
     *@return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256) {
        require(_block <= block.number);
        uint256 _epoch = epoch;
        uint256 _target_epoch = find_block_epoch(_block, _epoch);

        Point memory _point = point_history[_target_epoch];
        uint256 dt = 0;
        if (_target_epoch < _epoch) {
            Point memory _point_next = point_history[_target_epoch + 1];
            if (_point.blk != _point_next.blk) {
                dt =
                    ((_block - _point.blk) * (_point_next.ts - _point.ts)) /
                    (_point_next.blk - _point.blk);
            }
        } else {
            if (_point.blk != block.number) {
                dt =
                    ((_block - _point.blk) * (block.timestamp - _point.ts)) /
                    (block.number - _point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point

        return supply_at(_point, _point.ts + dt);
    }

    /***
     *@dev Dummy method required for Aragon compatibility
     */
    function changeController(address _newController) external {
        require(msg.sender == controller);
        controller = _newController;
    }

    function get_user_point_epoch(address _user)
        external
        view
        returns (uint256)
    {
        return user_point_epoch[_user];
    }

    //----------------------Investment module----------------------//

    /***
     *@notice unlock INSURE token without waiting for its end time.
     *@param _target address of being unlocked.
     *@return
     */
    function force_unlock(address _target) external returns (bool) {
        require(
            msg.sender == collateral_manager,
            "only collateral manager allowed"
        );

        //withdraw
        LockedBalance memory _locked = LockedBalance(
            locked[_target].amount,
            locked[_target].end
        );
        LockedBalance memory _old_locked = LockedBalance(
            locked[_target].amount,
            locked[_target].end
        );

        uint256 value = uint256(_locked.amount);

        //there must be locked INSURE
        require(value != 0, "There is no locked INSURE");

        _locked.end = 0;
        _locked.amount = 0;
        locked[_target] = _locked;
        uint256 _supply_before = supply;
        supply = _supply_before - value;

        _checkpoint(_target, _old_locked, _locked);

        //transfer INSURE to collateral_manager
        require(IERC20(token).transfer(collateral_manager, value));

        emit ForceUnlock(_target, value, block.timestamp);
        emit Supply(_supply_before, _supply_before - value);

        return true;
    }

    //---------------------- Admin Only ----------------------//
    /***
     *@notice Set an external contract to check for approved smart contract wallets
     *@param _addr Address of Smart contract checker
     */
    function commit_smart_wallet_checker(address _addr) external onlyOwner {
        future_smart_wallet_checker = _addr;

        emit commitWallet(_addr);
    }

    /***
     *@notice Apply setting external contract to check approved smart contract wallets
     */
    function apply_smart_wallet_checker() external onlyOwner {
        address _future_smart_wallet_checker = future_smart_wallet_checker;
        smart_wallet_checker = _future_smart_wallet_checker;

        emit commitWallet(_future_smart_wallet_checker);
    }

    /***
     *@notice Commit setting external contract to check user's collateral status
     */
    function commit_collateral_manager(address _new_collateral_manager)
        external
        onlyOwner
    {
        future_collateral_manager = _new_collateral_manager;

        emit commitCollateralManager(_new_collateral_manager);
    }

    /***
     *@notice Apply setting external contract to check user's collateral status
     */
    function apply_collateral_manager() external onlyOwner {
        address _future_collateral_manager = future_collateral_manager;
        collateral_manager = _future_collateral_manager;

        emit applyCollateralManager(_future_collateral_manager);
    }
}