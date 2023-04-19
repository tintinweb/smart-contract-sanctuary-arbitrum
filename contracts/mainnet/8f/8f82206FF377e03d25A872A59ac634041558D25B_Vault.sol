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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @notice This contract is responsible for Vault for LP and vault for CDX-core.

pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ILPPool} from "../pool/interfaces/ILPPool.sol";
import {BokkyPooBahsDateTimeLibrary} from "../library/math/BokkyPooBahsDateTimeLibrary.sol";
import {Initializable} from "../library/common/Initializable.sol";
import {DataTypes} from "../library/common/DataTypes.sol";
import {ConfigurationParam} from "../library/common/ConfigurationParam.sol";
import {VaultFeeCalculation} from "../library/math/VaultFeeCalculation.sol";
import {ReentrancyGuard} from "../library/common/ReentrancyGuard.sol";
import {ISwap} from "../library/uniswap/interfaces/ISwap.sol";

import {IRouter} from "../library/gmx/interfaces/IRouter.sol";
import {IPositionRouter} from "../library/gmx/interfaces/IPositionRouter.sol";
import {GVault} from "../library/gmx/interfaces/GVault.sol";
import {ConvertDecimals} from "../library/math/ConvertDecimals.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract Vault is Initializable, ReentrancyGuard {
    using SafeCast for uint256;
    using SafeMath for uint256;
    /// @dev approve target for GMX position router
    IRouter public router;
    /// @dev GMX position router
    IPositionRouter public positionRouter;
    /// @dev GMX vault
    GVault public gmxvault;

    ILPPool public lPPoolAddress;
    ISwap public swap;
    address public cdxAddress;
    uint256 public totalAsset;
    uint256 public initAsset;
    address public ownerAddress;
    bool public notFreezeStatus;
    address public guardianAddress;
    bool public locked;
    address public stableC;
    uint256 public manageFee;
    uint256 public profitFee;
    uint256 public coolDown;
    uint256 public dayDeposit;
    uint256 public dayWithdrawal;

    bytes32 public referralCode;
    // bytes32 public pendingOrderKey;
    uint256 public lastOrderTimestamp;
    mapping(address => DataTypes.DecreaseHedgingPool) decreaseHedging;
    mapping(address => DataTypes.IncreaseHedgingPool) increaseHedging;
    mapping(address => DataTypes.HedgeTreatmentInfo) public hedgeTreatmentparam;

    uint256 public constant GMX_PRICE_PRECISION = 10 ** 30;
    // uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public leverage;

    /// @dev Initialise important addresses for the contract
    function initialize(address _positionRouter, address _router) external initializer {
        _initNonReentrant();
        referralCode = bytes32("CDX");
        positionRouter = IPositionRouter(_positionRouter);
        router = IRouter(_router);
        gmxvault = GVault(positionRouter.vault());
        router.approvePlugin(address(positionRouter));
        leverage = 1;
        totalAsset = 1000000;
        initAsset = 1000000;
        ownerAddress = msg.sender;
        notFreezeStatus = true;
        manageFee = 20000;
        profitFee = 100000;
        coolDown = 2;
        dayDeposit = 0;
        dayWithdrawal = 0;
        stableC = ConfigurationParam.USDT;
        guardianAddress = ConfigurationParam.GUARDIAN;
    }

    fallback() external payable {
        emit Log(msg.sender, msg.value);
    }

    function setLeverage(uint256 _leverage) external onlyOwner {
        leverage = _leverage;
    }

    function _createIncreasePosition(uint256 acceptablePrice, address _token) external onlyOwner nonReentrant {
        DataTypes.IncreaseHedgingPool memory _hedging = increaseHedging[_token];
        delete increaseHedging[_token];
        delete hedgeTreatmentparam[_token];
        require(acceptablePrice > 0, "Value cannot be zero");
        _hedging.acceptablePrice = acceptablePrice;
        TransferHelper.safeApprove(_hedging.path[0], address(router), _hedging.amountIn);
        uint256 executionFee = _getExecutionFee();
        positionRouter.createIncreasePosition{value: executionFee}(
            _hedging.path,
            _hedging.indexToken,
            _hedging.amountIn,
            0,
            _hedging.sizeDelta,
            false,
            _hedging.acceptablePrice,
            executionFee,
            referralCode,
            address(this)
        );

        lastOrderTimestamp = block.timestamp;
        emit CreateIncreasePosition(
            _hedging.path,
            _hedging.indexToken,
            _hedging.amountIn,
            _hedging.sizeDelta,
            _hedging.acceptablePrice,
            lastOrderTimestamp
        );
    }

    function _createDecreasePosition(uint256 _collateralDelta, address _token) external payable onlyOwner nonReentrant {
        DataTypes.DecreaseHedgingPool memory _hedging = decreaseHedging[_token];
        require(_collateralDelta > 0, "Value cannot be zero");
        delete decreaseHedging[_token];
        delete hedgeTreatmentparam[_token];
        uint256 executionFee = _getExecutionFee();
        positionRouter.createDecreasePosition{value: executionFee}(
            _hedging.path,
            _hedging.indexToken,
            _hedging.collateralDelta,
            _hedging.sizeDelta,
            false,
            address(this),
            _hedging.acceptablePrice,
            0,
            executionFee,
            false,
            address(this)
        );

        lastOrderTimestamp = block.timestamp;
        emit CreateDecreasePosition(
            _hedging.path,
            _hedging.indexToken,
            _hedging.sizeDelta,
            _hedging.acceptablePrice,
            _hedging.collateralDelta,
            lastOrderTimestamp
        );
    }

    /// @dev Update swap contract addresses for the contract.
    function updateSwapExactAddress(address _swapAddress) external onlyOwner {
        require(Address.isContract(_swapAddress), "BasePositionManager: the parameter is not the contract address");
        swap = ISwap(_swapAddress);
    }

    /// @dev Update StableC addresses for the contract.
    function updateStableC(address _stableC) external onlyOwner {
        require(
            _stableC == ConfigurationParam.USDC || _stableC == ConfigurationParam.USDT,
            "BasePositionManager: the parameter is error address"
        );
        stableC = _stableC;
    }

    function updateInitAsset(uint256 _initAsset) external onlyOwner {
        require(_initAsset > 0, "initAsset is zero");
        initAsset = _initAsset;
    }

    function updateManageFee(uint256 _manageFee) external onlyOwner {
        require(_manageFee > 0, "manageFee is zero");
        manageFee = _manageFee;
    }

    function updateProfitFee(uint256 _profitFee) external onlyOwner {
        require(_profitFee > 0, "profitFee is zero");
        profitFee = _profitFee;
    }

    function updateCoolDown(uint256 _coolDown) external onlyOwner {
        require(_coolDown > 0, "coolDown is zero");
        coolDown = _coolDown;
    }

    /// @dev update locked value.
    function updateLocked(bool _locked) external onlyOwner {
        locked = _locked;
    }

    /// @dev update freezeStatus value.
    function updateFreezeStatus(bool _notFreezeStatus) external onlyOwner {
        notFreezeStatus = _notFreezeStatus;
    }

    /**
     * Returns bool
     * notice To the third party platform for hedging processing.
     * @param wethInfo Hedge token address.
     * @param wbtcInfo Hedge quantity.
     * @param _releaseHeight Specified height hedge.
     */
    function hedgeTreatmentByHeight(
        DataTypes.HedgeTreatmentInfo memory wethInfo,
        DataTypes.HedgeTreatmentInfo memory wbtcInfo,
        uint256 _releaseHeight
    ) external onlyOwner synchronized {
        if (wethInfo.amount > 0) {
            DataTypes.HedgeTreatmentInfo memory ethparam = hedgeTreatmentparam[wethInfo.token];
            if (wethInfo.isSell == ethparam.isSell) {
                wethInfo.amount = wethInfo.amount + ethparam.amount;
            } else {
                if (wethInfo.amount >= ethparam.amount) {
                    wethInfo.amount = wethInfo.amount - ethparam.amount;
                } else {
                    wethInfo.amount = ethparam.amount - wethInfo.amount;
                    wethInfo.isSell = !wethInfo.isSell;
                }
            }
            bool wethResult = this.hedgeTreatment(wethInfo.isSell, wethInfo.token, wethInfo.amount);
            require(wethResult, "HedgingError: Hedging weth failed");
        }

        if (wbtcInfo.amount > 0) {
            DataTypes.HedgeTreatmentInfo memory btcparam = hedgeTreatmentparam[wbtcInfo.token];
            if (wbtcInfo.isSell == btcparam.isSell) {
                wbtcInfo.amount = wbtcInfo.amount + btcparam.amount;
            } else {
                if (wbtcInfo.amount >= btcparam.amount) {
                    wbtcInfo.amount = wbtcInfo.amount - btcparam.amount;
                } else {
                    wbtcInfo.amount = btcparam.amount - wbtcInfo.amount;
                    wbtcInfo.isSell = !wbtcInfo.isSell;
                }
            }
            bool wbtcResult = this.hedgeTreatment(wbtcInfo.isSell, wbtcInfo.token, wbtcInfo.amount);
            require(wbtcResult, "HedgingError: Hedging wbtc failed");
        }
        if (wethInfo.amount == 0 && wbtcInfo.amount == 0) {
            revert("BasePositionManager: must be greater than zero");
        }
        bool deleteHedgingAggregator = lPPoolAddress.deleteHedgingAggregator(_releaseHeight);
        require(deleteHedgingAggregator, "CustomerManager: deleteHedgingAggregator failed");
        emit HedgeTreatmentByHeight(_releaseHeight);
    }

    /**
     * Returns bool
     * notice To the third party platform for hedging processing.
     * @param _isSell Hedge type, buy or sell.
     * @param _token Hedge token address.
     * @param _amount Hedge quantity.
     */
    function hedgeTreatment(bool _isSell, address _token, uint256 _amount) external onlyOwnerOrThis returns (bool) {
        require(notFreezeStatus, "BasePositionManager: this operation cannot be performed.");
        require(_amount > 0, "BasePositionManager: must be greater than zero");
        require(Address.isContract(_token), "BasePositionManager: the parameter is not the contract address");
        IERC20 ERC20TOKEN = IERC20(_token);

        address[] memory collateralToken = new address[](1);
        collateralToken[0] = stableC;
        if (_isSell) {
            delete decreaseHedging[_token];
            uint256 price = ERC20TOKEN.balanceOf(address(this));

            if (price == 0) {
                uint256 usdcAmount = tokenToUsd(_token, _amount);
                uint256 acceptablePrice = getTokenPrice(_token);
                acceptablePrice = acceptablePrice - ((acceptablePrice * 2) / 100);
                _createIncreasePosition(collateralToken, _token, usdcAmount, acceptablePrice);
                hedgeTreatmentparam[_token] = DataTypes.HedgeTreatmentInfo({
                    isSell: _isSell,
                    token: _token,
                    amount: _amount
                });
            } else {
                if (price < _amount) {
                    uint256 surplusPrice = _amount - price;
                    _swapExactInputSingle(_token, price);
                    uint256 surplusUSDCAmount = tokenToUsd(_token, surplusPrice);
                    uint256 acceptablePrice = getTokenPrice(_token);
                    acceptablePrice = acceptablePrice - ((acceptablePrice * 2) / 100);
                    _createIncreasePosition(collateralToken, _token, surplusUSDCAmount, acceptablePrice);
                    hedgeTreatmentparam[_token] = DataTypes.HedgeTreatmentInfo({
                        isSell: _isSell,
                        token: _token,
                        amount: surplusPrice
                    });
                } else {
                    _swapExactInputSingle(_token, _amount);
                    hedgeTreatmentparam[_token] = DataTypes.HedgeTreatmentInfo({
                        isSell: _isSell,
                        token: _token,
                        amount: 0
                    });
                }
            }
        } else {
            delete increaseHedging[_token];
            uint256 usdcAmount = tokenToUsd(_token, _amount);
            DataTypes.PositionDetails memory position = this.getPosition(stableC, _token);
            uint256 size = usdToToken(
                _token,
                (position.size * ConfigurationParam.STABLEC_DECIMAL) / GMX_PRICE_PRECISION
            );
            if (size == 0) {
                _swapExactOutputSingle(usdcAmount, _amount, _token);
                hedgeTreatmentparam[_token] = DataTypes.HedgeTreatmentInfo({isSell: _isSell, token: _token, amount: 0});
            } else {
                if (size < _amount) {
                    uint256 surplusValue = (_amount - size);
                    uint256 usdcPrice = tokenToUsd(_token, surplusValue);
                    _swapExactOutputSingle(usdcPrice, surplusValue, _token);
                    uint256 usdcPriceGmx = (position.size * ConfigurationParam.STABLEC_DECIMAL) / GMX_PRICE_PRECISION;
                    uint256 acceptablePrice = getTokenPrice(_token);
                    acceptablePrice = acceptablePrice + ((acceptablePrice * 2) / 100);
                    _createDecreasePosition(collateralToken, _token, usdcPriceGmx, true, acceptablePrice);
                    hedgeTreatmentparam[_token] = DataTypes.HedgeTreatmentInfo({
                        isSell: _isSell,
                        token: _token,
                        amount: surplusValue
                    });
                } else {
                    uint256 acceptablePrice = getTokenPrice(_token);
                    acceptablePrice = acceptablePrice + ((acceptablePrice * 2) / 100);
                    _createDecreasePosition(collateralToken, _token, usdcAmount, false, acceptablePrice);
                    hedgeTreatmentparam[_token] = DataTypes.HedgeTreatmentInfo({
                        isSell: _isSell,
                        token: _token,
                        amount: _amount
                    });
                }
            }
        }
        emit EventHedgeTreatment(_isSell, _token, _amount);
        return true;
    }

    function _swapExactInputSingle(address _token, uint256 _amount) internal {
        TransferHelper.safeApprove(_token, address(swap), _amount);
        (bool result, ) = swap.swapExactInputSingle(_amount, _token, stableC, address(this));
        require(result, "UniswapManager: uniswap failed");
    }

    function getTokenPrice(address _token) public view returns (uint256) {
        uint256 price;
        if (_token == ConfigurationParam.WETH) {
            price = swap.getTokenPrice(ConfigurationParam.ETHAddress);
        } else {
            price = swap.getTokenPrice(ConfigurationParam.BTCAddress);
        }
        return price;
    }

    function getDecreaseHedging(address _token) public view returns (DataTypes.DecreaseHedgingPool memory) {
        return decreaseHedging[_token];
    }

    function getIncreaseHedging(address _token) public view returns (DataTypes.IncreaseHedgingPool memory) {
        return increaseHedging[_token];
    }

    function usdToToken(address _token, uint256 _amount) public view returns (uint256) {
        uint256 changeAmount;
        if (_token == ConfigurationParam.WETH) {
            uint256 price = swap.getTokenPrice(ConfigurationParam.ETHAddress);
            changeAmount =
                (_amount * ConfigurationParam.WETH_DECIMAL * ConfigurationParam.ORACLE_DECIMAL) /
                (price * ConfigurationParam.STABLEC_DECIMAL);
        } else {
            uint256 price = swap.getTokenPrice(ConfigurationParam.BTCAddress);
            changeAmount =
                (_amount * ConfigurationParam.WBTC_DECIMAL * ConfigurationParam.ORACLE_DECIMAL) /
                (price * ConfigurationParam.STABLEC_DECIMAL);
        }
        return changeAmount;
    }

    function tokenToUsd(address _token, uint256 _amount) public view returns (uint256) {
        uint256 usdcAmount;
        if (_token == ConfigurationParam.WETH) {
            uint256 price = swap.getTokenPrice(ConfigurationParam.ETHAddress);
            usdcAmount =
                (_amount * price * ConfigurationParam.STABLEC_DECIMAL) /
                (ConfigurationParam.WETH_DECIMAL * ConfigurationParam.ORACLE_DECIMAL);
        } else {
            uint256 price = swap.getTokenPrice(ConfigurationParam.BTCAddress);
            usdcAmount =
                (_amount * price * ConfigurationParam.STABLEC_DECIMAL) /
                (ConfigurationParam.WBTC_DECIMAL * ConfigurationParam.ORACLE_DECIMAL);
        }
        return usdcAmount;
    }

    function _swapExactOutputSingle(uint256 surplusValue, uint256 _amount, address _token) internal {
        surplusValue = surplusValue + surplusValue / 10;
        TransferHelper.safeApprove(stableC, address(swap), surplusValue);
        (bool result, ) = swap.swapExactOutputSingle(
            _amount, //etc
            surplusValue, //usdc
            stableC,
            _token,
            address(this)
        );
        require(result, "UniswapManager: uniswap failed");
    }

    function _createIncreasePosition(
        address[] memory collateralToken,
        address _token,
        uint256 amount,
        uint256 acceptablePrice
    ) internal {
        uint256 sizeDelta = (amount * GMX_PRICE_PRECISION) / ConfigurationParam.STABLEC_DECIMAL;
        uint256 amountIn = amount.div(leverage);
        increaseHedging[_token] = DataTypes.IncreaseHedgingPool({
            path: collateralToken,
            indexToken: _token,
            amountIn: amountIn,
            sizeDelta: sizeDelta,
            acceptablePrice: (acceptablePrice * GMX_PRICE_PRECISION) / ConfigurationParam.ORACLE_DECIMAL
        });
        emit EventIncreaseHedging(
            _token,
            amountIn,
            sizeDelta,
            collateralToken,
            (acceptablePrice * GMX_PRICE_PRECISION) / ConfigurationParam.ORACLE_DECIMAL
        );
    }

    function _createDecreasePosition(
        address[] memory collateralToken,
        address _token,
        uint256 collateralDelta,
        bool _isClose,
        uint256 acceptablePrice
    ) internal {
        if (_isClose) {
            DataTypes.PositionDetails memory position = this.getPosition(stableC, _token);
            decreaseHedging[_token] = DataTypes.DecreaseHedgingPool({
                path: collateralToken,
                indexToken: _token,
                sizeDelta: position.size,
                acceptablePrice: (acceptablePrice * GMX_PRICE_PRECISION) / ConfigurationParam.ORACLE_DECIMAL,
                collateralDelta: 0
            });

            emit EventDecreaseHedging(
                collateralToken,
                _token,
                collateralDelta,
                _isClose,
                (acceptablePrice * GMX_PRICE_PRECISION) / ConfigurationParam.ORACLE_DECIMAL,
                position.size
            );
        } else {
            uint256 sizeDelta = (collateralDelta * GMX_PRICE_PRECISION) / ConfigurationParam.STABLEC_DECIMAL;
            DataTypes.PositionDetails memory currentPosition = this.getPosition(stableC, _token);
            uint256 amountOut;
            if (currentPosition.size <= sizeDelta) {
                amountOut = sizeDelta.div(leverage);
            } else {
                amountOut = currentPosition.size.div(leverage) - (currentPosition.size - sizeDelta).div(leverage);
            }
            decreaseHedging[_token] = DataTypes.DecreaseHedgingPool({
                path: collateralToken,
                indexToken: _token,
                sizeDelta: sizeDelta,
                acceptablePrice: (acceptablePrice * GMX_PRICE_PRECISION) / ConfigurationParam.ORACLE_DECIMAL,
                collateralDelta: amountOut
            });

            emit EventDecreaseHedging(
                collateralToken,
                _token,
                amountOut,
                _isClose,
                (acceptablePrice * GMX_PRICE_PRECISION) / ConfigurationParam.ORACLE_DECIMAL,
                sizeDelta
            );
        }
    }

    /// @dev Update LPPool contract addresses for the contract.
    function updateLPPoolAddress(address _lPPoolAddress) external onlyOwner {
        require(Address.isContract(_lPPoolAddress), "BasePositionManager: illegal contract address");
        lPPoolAddress = ILPPool(_lPPoolAddress);
    }

    /// @dev Update CDX-core contract addresses for the contract.
    function updateCDXAddress(address _cdxAddress) external onlyOwner {
        require(Address.isContract(_cdxAddress), "BasePositionManager: illegal contract address");
        cdxAddress = _cdxAddress;
    }

    /**
     * notice Accept the bonus calculated by the robot and transfer the bonus to cdx through this contract.
     * @param _token_address Bonus token address.
     * @param _amount Bonus quantity.
     * @param _customerId Customer id.
     * @param _pid Product id.
     * @param _purchaseProductAmount Purchase amount.
     * @param _releaseHeight Specified height.
     */
    function transferToCDX(
        address _token_address,
        uint256 _amount,
        uint256 _customerId,
        uint256 _pid,
        uint256 _purchaseProductAmount,
        uint256 _releaseHeight
    ) external onlyCDXOrOwner nonReentrant {
        require(notFreezeStatus, "BasePositionManager: this operation cannot be performed.");
        require(_amount > 0, "TransferManager: transfer amount must be greater than zero");
        require(getBalanceOf(_token_address) >= _amount, "TransferManager: your credit is running low");
        DataTypes.HedgingAggregatorInfo memory hedgingAggregator = DataTypes.HedgingAggregatorInfo({
            customerId: _customerId,
            productId: _pid,
            amount: _purchaseProductAmount,
            releaseHeight: _releaseHeight
        });
        bool result = lPPoolAddress.addHedgingAggregator(hedgingAggregator);
        require(result, "LPPoolManager: deleteHedgingAggregator failed");
        TransferHelper.safeTransfer(_token_address, cdxAddress, _amount);
        emit TransferToCDX(_token_address, _amount);
    }

    /**
     * notice Updated net worth change.
     * @param optionsHoldingPrice Value of all options.
     */
    function updateAsset(uint256 optionsHoldingPrice) external onlyOwner nonReentrant synchronized returns (bool) {
        if (optionsHoldingPrice == 0 && getBalanceOf(stableC) == 0 && totalAsset == 1) {
            return true;
        }
        dayDeposit = 0;
        dayWithdrawal = 0;
        DataTypes.PositionDetails memory positionWETH = this.getPosition(stableC, ConfigurationParam.WETH);
        DataTypes.PositionDetails memory positionWBTC = this.getPosition(stableC, ConfigurationParam.WBTC);
        uint256 wethValue = tokenToUsd(ConfigurationParam.WETH, getBalanceOf(ConfigurationParam.WETH));
        uint256 wbtcValue = tokenToUsd(ConfigurationParam.WBTC, getBalanceOf(ConfigurationParam.WBTC));
        uint256 ethCollateral = (positionWETH.collateral * ConfigurationParam.STABLEC_DECIMAL) /
            ConfigurationParam.GMX_DECIMAL;
        uint256 btcCollateral = (positionWBTC.collateral * ConfigurationParam.STABLEC_DECIMAL) /
            ConfigurationParam.GMX_DECIMAL;
        int256 ethUnrealisedPnl = (positionWETH.unrealisedPnl * ConfigurationParam.STABLEC_DECIMAL.toInt256()) /
            ConfigurationParam.GENERAL_DECIMAL.toInt256();
        int256 btcUnrealisedPnl = (positionWBTC.unrealisedPnl * ConfigurationParam.STABLEC_DECIMAL.toInt256()) /
            ConfigurationParam.GENERAL_DECIMAL.toInt256();
        int256 optionsHoldingPriceToInt256 = optionsHoldingPrice.toInt256();
        uint256 latestTotalAsset = SafeCast.toUint256(
            optionsHoldingPriceToInt256 +
                getBalanceOf(stableC).toInt256() +
                ethUnrealisedPnl +
                btcUnrealisedPnl +
                ethCollateral.toInt256() +
                btcCollateral.toInt256() +
                wethValue.toInt256() +
                wbtcValue.toInt256()
        );
        uint256 manageFeeValue = (latestTotalAsset * manageFee) / (ConfigurationParam.PERCENTILE * 365);
        totalAsset = latestTotalAsset - manageFeeValue;
        bool result = lPPoolAddress.dealLPPendingInit(totalAsset);
        require(result, "LPPoolManager: failed to process initialization value");
        TransferHelper.safeTransfer(stableC, guardianAddress, manageFeeValue);
        emit UpdateAssetEvent(
            address(this),
            guardianAddress,
            manageFeeValue,
            stableC,
            DataTypes.TransferHelperStatus.TOMANAGE
        );
        return true;
    }

    /**
     * notice LP investment.
     * @param ercToken Token address.
     * @param amount Amount of investment
     */
    function applyVault(address ercToken, uint256 amount) external nonReentrant synchronized returns (bool) {
        require(notFreezeStatus, "BasePositionManager: this operation cannot be performed.");
        require(amount > 0, "BasePositionManager: credit amount cannot be zero");
        require(ercToken != address(0), "TokenManager: the ercToken address cannot be empty");
        dayDeposit = dayDeposit + amount;
        bool result = lPPoolAddress.addLPAmountInfo(amount, msg.sender);
        require(result, "LPPoolManager: add LPAmountInfo fail");
        TransferHelper.safeTransferFrom(ercToken, msg.sender, address(this), amount);
        emit ApplyVault(ercToken, amount, msg.sender);
        return result;
    }

    /**
     * notice Make an appointment to withdraw money, after the appointment cooling-off period can be withdrawn directly.
     * @param lPAddress Wallet address of the person withdrawing the money.
     * @param purchaseHeightInfo Deposit height record.
     */
    function applyWithdrawal(address lPAddress, uint256 purchaseHeightInfo) external returns (bool) {
        require(notFreezeStatus, "BasePositionManager: this operation cannot be performed.");
        bool result = lPPoolAddress.reservationWithdrawal(lPAddress, purchaseHeightInfo);
        require(result, "LPPoolManager: failure to apply for withdrawal");
        emit ApplyWithdrawal(lPAddress, purchaseHeightInfo);
        return result;
    }

    /**
     * notice LP withdrawal.
     * @param lPAddress Wallet address of the person withdrawing the money.
     * @param purchaseHeightInfo Deposit height record.
     */
    function lPwithdrawal(
        address lPAddress,
        uint256 purchaseHeightInfo
    ) external nonReentrant synchronized returns (bool) {
        //The first step is to verify the withdrawal information.
        require(notFreezeStatus, "BasePositionManager: this operation cannot be performed.");
        DataTypes.LPAmountInfo memory lPAmountInfo = lPPoolAddress.getLPAmountInfoByParams(
            lPAddress,
            purchaseHeightInfo
        );
        require(lPAmountInfo.amount > 0, "LPPollManager: the withdrawal information is abnormal");
        //The second step is to determine whether the cooling-off period has been reached.
        require(lPAmountInfo.reservationTime > 0, "LPPollManager: withdrawals are not scheduled");
        //uint256 day = uint256(BokkyPooBahsDateTimeLibrary.diffDays(lPAmountInfo.createTime, block.timestamp));
        require(
            uint256(BokkyPooBahsDateTimeLibrary.diffDays(lPAmountInfo.reservationTime, block.timestamp)) >= coolDown,
            "LPPollManager: coolDown periods are often inadequate"
        );
        uint256 withdrawalAmount;
        uint256 profitFeeValue;
        //The third step deals with profit calculation
        if (totalAsset > lPAmountInfo.initValue) {
            uint256 grossProfit = VaultFeeCalculation.profitCalculation(
                lPAmountInfo.initValue,
                totalAsset,
                lPAmountInfo.amount
            );
            //uint256 managementFee = VaultFeeCalculation.ManagementFeeCalculation(lPAmountInfo.amount, day);
            profitFeeValue = VaultFeeCalculation.ProfitFeeCalculation(grossProfit, lPAmountInfo.amount, profitFee);
            //withdrawalAmount = SafeMath.sub(SafeMath.sub(grossProfit, managementFee), profitFee);
            withdrawalAmount = SafeMath.sub(grossProfit, profitFeeValue);
            TransferHelper.safeTransfer(stableC, guardianAddress, profitFeeValue);
        } else {
            uint256 lossProfit = VaultFeeCalculation.profitCalculation(
                lPAmountInfo.initValue,
                totalAsset,
                lPAmountInfo.amount
            );
            withdrawalAmount = lossProfit;
        }
        dayWithdrawal = dayWithdrawal + withdrawalAmount + profitFeeValue;
        //Final withdrawal
        bool result = lPPoolAddress.deleteLPAmountInfoByParam(lPAddress, purchaseHeightInfo);
        require(result, "LPPollManager: failure to withdrawal");
        TransferHelper.safeTransfer(stableC, lPAmountInfo.lPAddress, withdrawalAmount);
        emit LPwithdrawal(lPAddress, purchaseHeightInfo, withdrawalAmount, profitFeeValue);
        return result;
    }

    function withdraw(
        address token,
        address recipient,
        uint256 amount
    ) external onlyGuardian nonReentrant returns (bool) {
        require(recipient != address(0), "BasePositionManager: the recipient address cannot be empty");
        require(token != address(0), "TokenManager: the token address cannot be empty");
        uint256 balance = getBalanceOf(token);
        require(balance > 0, "BasePositionManager: insufficient balance");
        require(balance >= amount, "TransferManager: excess balance");
        TransferHelper.safeTransfer(token, recipient, amount);
        emit Withdraw(address(this), recipient, token, amount);
        return true;
    }

    /**
     * @dev get position detail that includes unrealised PNL
     * @param _collatToken  [collateralToken] or [tokenIn, collateralToken] if a swap
     * @param _indexToken The address of the token you want to go long or short
     */
    function getPosition(
        address _collatToken,
        address _indexToken
    ) external view returns (DataTypes.PositionDetails memory position) {
        bool isLong = false;
        (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            ,
            ,
            ,
            uint256 lastIncreasedTime
        ) = gmxvault.getPosition(address(this), _collatToken, _indexToken, false);

        int256 unrealisedPnl = 0;
        if (averagePrice > 0) {
            // getDelta will revert if average price == 0;
            (bool hasUnrealisedProfit, uint256 absUnrealisedPnl) = gmxvault.getDelta(
                _indexToken,
                size,
                averagePrice,
                isLong,
                lastIncreasedTime
            );

            if (hasUnrealisedProfit) {
                unrealisedPnl = _convertFromGMXPrecision(absUnrealisedPnl).toInt256();
            } else {
                unrealisedPnl = -_convertFromGMXPrecision(absUnrealisedPnl).toInt256();
            }

            return
                DataTypes.PositionDetails({
                    size: size,
                    collateral: collateral,
                    averagePrice: averagePrice,
                    entryFundingRate: entryFundingRate,
                    unrealisedPnl: unrealisedPnl,
                    lastIncreasedTime: lastIncreasedTime,
                    isLong: isLong,
                    hasUnrealisedProfit: hasUnrealisedProfit
                });
        }
    }

    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external onlyGMXKeeper {
        emit GMXPositionCallback(positionKey, isExecuted, isIncrease);
    }

    function _convertFromGMXPrecision(uint256 amt) internal pure returns (uint256) {
        return ConvertDecimals.normaliseTo18(amt, GMX_PRICE_PRECISION);
    }

    receive() external payable {}

    function getBalanceOf(address token) public view returns (uint256) {
        IERC20 tokenInToken = IERC20(token);
        return tokenInToken.balanceOf(address(this));
    }

    /// @dev returns the execution fee plus the cost of the gas callback
    function _getExecutionFee() internal view returns (uint256) {
        return positionRouter.minExecutionFee();
    }

    modifier onlyCDXOrOwner() {
        require(cdxAddress == msg.sender || ownerAddress == msg.sender, "Ownable: caller is not the CDX or owner");
        _;
    }
    modifier onlyOwnerOrThis() {
        require(ownerAddress == msg.sender || msg.sender == address(this), "Ownable: caller is not the owner or this");
        _;
    }
    modifier onlyOwner() {
        require(ownerAddress == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyGuardian() {
        require(guardianAddress == msg.sender, "Ownable: caller is not the Guardian");
        _;
    }

    modifier synchronized() {
        require(!locked, "BasePositionManager: Please wait");
        locked = true;
        _;
        locked = false;
    }
    modifier onlyGMXKeeper() {
        require(msg.sender == address(positionRouter), "GMXFuturesPoolHedger: only GMX keeper can trigger callback");
        _;
    }
    event Log(address from, uint256 value);
    event ApplyVault(address ercToken, uint256 amount, address msgSender);
    event UpdateLatestAmountValue(uint256 blockTime, uint256 latestAmountValue);
    event ApplyWithdrawal(address msgSender, uint256 purchaseHeightInfo);
    event LPwithdrawal(address lPAddress, uint256 purchaseHeightInfo, uint256 withdrawalAmount, uint256 profitFeeValue);
    event TransferToCDX(address tokenAddress, uint256 amount);
    event CreateIncreasePosition(
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 sizeDelta,
        uint256 acceptablePrice,
        uint256 lastOrderTimestamp
    );
    event HedgeTreatmentByHeight(uint256 _releaseHeight);
    event EventIncreaseHedging(
        address _token,
        uint256 amountIn,
        uint256 sizeDelta,
        address[] collateralToken,
        uint256 acceptablePrice
    );
    event EventDecreaseHedging(
        address[] collateralToken,
        address _token,
        uint256 collateralDelta,
        bool _isClose,
        uint256 acceptablePrice,
        uint256 sizeDelta
    );
    event CreateDecreasePosition(
        address[] path,
        address indexToken,
        uint256 sizeDelta,
        uint256 acceptablePrice,
        uint256 collateralDelta,
        uint256 lastOrderTimestamp
    );
    event EventHedgeTreatment(bool _isSell, address _token, uint256 _amount);
    event GMXPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease);
    event UpdateAssetEvent(
        address from,
        address to,
        uint256 amount,
        address tokenAddress,
        DataTypes.TransferHelperStatus typeValue
    );
    event Withdraw(address from, address to, address cryptoAddress, uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library ConfigurationParam {
    address internal constant ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address internal constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address internal constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address internal constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address internal constant GUARDIAN = 0x366e2E5Ed08AA510c45138035d0F502A13F4718A;
    address internal constant BTCAddress = 0xd0C7101eACbB49F3deCcCc166d238410D6D46d57;
    address internal constant ETHAddress = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    uint256 internal constant PERCENTILE = 1e6;
    uint256 internal constant STABLEC_DECIMAL = 1e6;
    uint256 internal constant WETH_DECIMAL = 1e18;
    uint256 internal constant WBTC_DECIMAL = 1e8;
    uint256 internal constant ORACLE_DECIMAL = 1e8;
    uint256 internal constant GMX_DECIMAL = 1e30;
    uint256 internal constant GENERAL_DECIMAL = 1e18;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library DataTypes {
    struct LPAmountInfo {
        uint256 amount;
        uint256 initValue;
        address lPAddress;
        uint256 createTime;
        uint256 reservationTime;
        uint256 purchaseHeightInfo;
    }

    struct HedgeTreatmentInfo {
        bool isSell;
        address token;
        uint256 amount;
    }

    struct LPPendingInit {
        uint256 amount;
        address lPAddress;
        uint256 createTime;
        uint256 purchaseHeightInfo;
    }

    struct PositionDetails {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        int256 unrealisedPnl;
        uint256 lastIncreasedTime;
        bool isLong;
        bool hasUnrealisedProfit;
    }

    struct IncreaseHedgingPool {
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 sizeDelta;
        uint256 acceptablePrice;
    }

    struct DecreaseHedgingPool {
        address[] path;
        address indexToken;
        uint256 sizeDelta;
        uint256 acceptablePrice;
        uint256 collateralDelta;
    }

    struct HedgingAggregatorInfo {
        uint256 customerId;
        uint256 productId;
        uint256 amount;
        uint256 releaseHeight;
    }

    enum TransferHelperStatus {
        TOTHIS,
        TOLP,
        TOGMX,
        TOCDXCORE,
        TOMANAGE,
        GUARDIANW
    }

    struct Hedging {
        bool isSell;
        address token;
        uint256 amount;
        uint256 releaseHeight;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title Initializable
 *
 * @dev Deprecated. This contract is kept in the Upgrades Plugins for backwards compatibility purposes.
 * Users should use openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol instead.
 *
 * Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.9;

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

    // constructor() {
    //     _status = _NOT_ENTERED;
    // }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _initNonReentrant() internal virtual {
        _status = _NOT_ENTERED;
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

interface GVault {
    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);
}

//SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

interface IPositionRouter {
    function vault() external view returns (address);

    function minExecutionFee() external view returns (uint256);

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
    ) external payable returns (bytes32);

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
    ) external payable returns (bytes32);
}

//SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

interface IRouter {
    function approvePlugin(address _plugin) external;
}

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

library BokkyPooBahsDateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
}

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

// Libraries
import "./Math.sol";

/**
 * @title ConvertDecimals
 * @author Lyra
 * @dev Contract to convert amounts to and from erc20 tokens to 18 dp.
 */
library ConvertDecimals {
    /// @dev Converts amount from a given precisionFactor to 18 dp. This cuts off precision for decimals > 18.
    function normaliseTo18(uint256 amount, uint256 precisionFactor) internal pure returns (uint256) {
        return (amount * 1e18) / precisionFactor;
    }
}

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

/**
 * @title Math
 * @author Lyra
 * @dev Library to unify logic for common shared functions
 */
library Math {
    /// @dev Return the minimum value between the two inputs
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x < y) ? x : y;
    }

    /// @dev Return the maximum value between the two inputs
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? x : y;
    }

    /// @dev Compute the absolute value of `val`.
    function abs(int256 val) internal pure returns (uint256) {
        return uint256(val < 0 ? -val : val);
    }

    /// @dev Takes ceiling of a to m precision
    /// @param m represents 1eX where X is the number of trailing 0's
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }
}

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../common/ConfigurationParam.sol";

library VaultFeeCalculation {
    /// @dev The vault charges 2% management fee, which is 100*2%*(5/365) = 0.027
    function ManagementFeeCalculation(
        uint256 principal,
        uint256 day,
        uint256 manageFee
    ) internal pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(SafeMath.mul(principal, manageFee), day), 365e6);
    }

    /// @dev Thue vault charges 10% of profit, which is (120-100)*10% = 2
    function ProfitFeeCalculation(
        uint256 grossProfit,
        uint256 principal,
        uint256 profitFee
    ) internal pure returns (uint256) {
        uint256 netProfit = SafeMath.sub(grossProfit, principal);
        return SafeMath.div(SafeMath.mul(netProfit, profitFee), ConfigurationParam.PERCENTILE);
    }

    /// @dev Profit calculation
    function profitCalculation(
        uint256 initAmountValue,
        uint256 latestAmountValue,
        uint256 principal
    ) internal pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(latestAmountValue, principal), initAmountValue);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ISwap {
    function swapExactInputSingle(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address recipient
    ) external returns (bool, uint256);

    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum,
        address tokenIn,
        address tokenOut,
        address recipient
    ) external returns (bool, uint256);

    function getTokenPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;
import "../../library/common/DataTypes.sol";

interface ILPPool {
    function reservationWithdrawal(address lPAddress, uint256 purchaseHeightInfo) external returns (bool);

    function addLPAmountInfo(uint256 _amount, address _lPAddress) external returns (bool);

    function dealLPPendingInit(uint256 coefficient) external returns (bool);

    function deleteLPAmountInfoByParam(address lPAddress, uint256 purchaseHeightInfo) external returns (bool);

    function addHedgingAggregator(DataTypes.HedgingAggregatorInfo memory hedgingAggregator) external returns (bool);

    function deleteHedgingAggregator(uint256 _releaseHeight) external returns (bool);

    function getLPAmountInfo(address lPAddress) external view returns (DataTypes.LPAmountInfo[] memory);

    function getLPAmountInfoByParams(
        address lPAddress,
        uint256 purchaseHeightInfo
    ) external view returns (DataTypes.LPAmountInfo memory);

    function getProductHedgingAggregatorPool() external view returns (DataTypes.HedgingAggregatorInfo[] memory);
}