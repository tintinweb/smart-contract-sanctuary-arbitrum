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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/ErrorUtils.sol";

import "./IOrderCallbackReceiver.sol";
import "./IDepositCallbackReceiver.sol";
import "./IWithdrawalCallbackReceiver.sol";
import "./IShiftCallbackReceiver.sol";
import "./IGasFeeCallbackReceiver.sol";
import "./IGlvDepositCallbackReceiver.sol";

// @title CallbackUtils
// @dev most features require a two step process to complete
// the user first sends a request transaction, then a second transaction is sent
// by a keeper to execute the request
//
// to allow for better composability with other contracts, a callback contract
// can be specified to be called after request executions or cancellations
//
// in case it is necessary to add "before" callbacks, extra care should be taken
// to ensure that important state cannot be changed during the before callback
// for example, if an order can be cancelled in the "before" callback during
// order execution, it may lead to an order being executed even though the user
// was already refunded for its cancellation
//
// the details from callback errors are not processed to avoid cases where a malicious
// callback contract returns a very large value to cause transactions to run out of gas
library CallbackUtils {
    using Address for address;
    using Deposit for Deposit.Props;
    using Withdrawal for Withdrawal.Props;
    using Shift for Shift.Props;
    using Order for Order.Props;
    using GlvDeposit for GlvDeposit.Props;

    event AfterDepositExecutionError(bytes32 key, Deposit.Props deposit);
    event AfterDepositCancellationError(bytes32 key, Deposit.Props deposit);

    event AfterWithdrawalExecutionError(bytes32 key, Withdrawal.Props withdrawal);
    event AfterWithdrawalCancellationError(bytes32 key, Withdrawal.Props withdrawal);

    event AfterShiftExecutionError(bytes32 key, Shift.Props shift);
    event AfterShiftCancellationError(bytes32 key, Shift.Props shift);

    event AfterOrderExecutionError(bytes32 key, Order.Props order);
    event AfterOrderCancellationError(bytes32 key, Order.Props order);
    event AfterOrderFrozenError(bytes32 key, Order.Props order);

    event AfterGlvDepositExecutionError(bytes32 key, GlvDeposit.Props glvDeposit);
    event AfterGlvDepositCancellationError(bytes32 key, GlvDeposit.Props glvDeposit);

    // @dev validate that the callbackGasLimit is less than the max specified value
    // this is to prevent callback gas limits which are larger than the max gas limits per block
    // as this would allow for callback contracts that can consume all gas and conditionally cause
    // executions to fail
    // @param dataStore DataStore
    // @param callbackGasLimit the callback gas limit
    function validateCallbackGasLimit(DataStore dataStore, uint256 callbackGasLimit) internal view {
        uint256 maxCallbackGasLimit = dataStore.getUint(Keys.MAX_CALLBACK_GAS_LIMIT);
        if (callbackGasLimit > maxCallbackGasLimit) {
            revert Errors.MaxCallbackGasLimitExceeded(callbackGasLimit, maxCallbackGasLimit);
        }
    }

    function validateGasLeftForCallback(uint256 callbackGasLimit) internal view {
        uint256 gasToBeForwarded = gasleft() / 64 * 63;
        if (gasToBeForwarded < callbackGasLimit) {
            revert Errors.InsufficientGasLeftForCallback(gasToBeForwarded, callbackGasLimit);
        }
    }

    function setSavedCallbackContract(DataStore dataStore, address account, address market, address callbackContract) external {
        dataStore.setAddress(Keys.savedCallbackContract(account, market), callbackContract);
    }

    function getSavedCallbackContract(DataStore dataStore, address account, address market) internal view returns (address) {
        return dataStore.getAddress(Keys.savedCallbackContract(account, market));
    }

    function refundExecutionFee(
        DataStore dataStore,
        bytes32 key,
        address callbackContract,
        uint256 refundFeeAmount,
        EventUtils.EventLogData memory eventData
    ) internal returns (bool) {
        if (!isValidCallbackContract(callbackContract)) { return false; }

        uint256 gasLimit = dataStore.getUint(Keys.REFUND_EXECUTION_FEE_GAS_LIMIT);

        try IGasFeeCallbackReceiver(callbackContract).refundExecutionFee{ gas: gasLimit, value: refundFeeAmount }(
            key,
            eventData
        ) {
            return true;
        } catch {
            return false;
        }
    }

    // @dev called after a deposit execution
    // @param key the key of the deposit
    // @param deposit the deposit that was executed
    function afterDepositExecution(
        bytes32 key,
        Deposit.Props memory deposit,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(deposit.callbackContract())) { return; }

        validateGasLeftForCallback(deposit.callbackGasLimit());

        try IDepositCallbackReceiver(deposit.callbackContract()).afterDepositExecution{ gas: deposit.callbackGasLimit() }(
            key,
            deposit,
            eventData
        ) {
        } catch {
            emit AfterDepositExecutionError(key, deposit);
        }
    }

    // @dev called after a deposit cancellation
    // @param key the key of the deposit
    // @param deposit the deposit that was cancelled
    function afterDepositCancellation(
        bytes32 key,
        Deposit.Props memory deposit,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(deposit.callbackContract())) { return; }

        validateGasLeftForCallback(deposit.callbackGasLimit());

        try IDepositCallbackReceiver(deposit.callbackContract()).afterDepositCancellation{ gas: deposit.callbackGasLimit() }(
            key,
            deposit,
            eventData
        ) {
        } catch {
            emit AfterDepositCancellationError(key, deposit);
        }
    }

    // @dev called after a withdrawal execution
    // @param key the key of the withdrawal
    // @param withdrawal the withdrawal that was executed
    function afterWithdrawalExecution(
        bytes32 key,
        Withdrawal.Props memory withdrawal,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(withdrawal.callbackContract())) { return; }

        validateGasLeftForCallback(withdrawal.callbackGasLimit());

        try IWithdrawalCallbackReceiver(withdrawal.callbackContract()).afterWithdrawalExecution{ gas: withdrawal.callbackGasLimit() }(
            key,
            withdrawal,
            eventData
        ) {
        } catch {
            emit AfterWithdrawalExecutionError(key, withdrawal);
        }
    }

    // @dev called after a withdrawal cancellation
    // @param key the key of the withdrawal
    // @param withdrawal the withdrawal that was cancelled
    function afterWithdrawalCancellation(
        bytes32 key,
        Withdrawal.Props memory withdrawal,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(withdrawal.callbackContract())) { return; }

        validateGasLeftForCallback(withdrawal.callbackGasLimit());

        try IWithdrawalCallbackReceiver(withdrawal.callbackContract()).afterWithdrawalCancellation{ gas: withdrawal.callbackGasLimit() }(
            key,
            withdrawal,
            eventData
        ) {
        } catch {
            emit AfterWithdrawalCancellationError(key, withdrawal);
        }
    }

    function afterShiftExecution(
        bytes32 key,
        Shift.Props memory shift,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(shift.callbackContract())) { return; }

        validateGasLeftForCallback(shift.callbackGasLimit());

        try IShiftCallbackReceiver(shift.callbackContract()).afterShiftExecution{ gas: shift.callbackGasLimit() }(
            key,
            shift,
            eventData
        ) {
        } catch {
            emit AfterShiftExecutionError(key, shift);
        }
    }
    function afterShiftCancellation(
        bytes32 key,
        Shift.Props memory shift,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(shift.callbackContract())) { return; }

        validateGasLeftForCallback(shift.callbackGasLimit());

        try IShiftCallbackReceiver(shift.callbackContract()).afterShiftCancellation{ gas: shift.callbackGasLimit() }(
            key,
            shift,
            eventData
        ) {
        } catch {
            emit AfterShiftCancellationError(key, shift);
        }
    }

    // @dev called after an order execution
    // note that the order.size, order.initialCollateralDeltaAmount and other
    // properties may be updated during execution, the new values may not be
    // updated in the order object for the callback
    // @param key the key of the order
    // @param order the order that was executed
    function afterOrderExecution(
        bytes32 key,
        Order.Props memory order,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(order.callbackContract())) { return; }

        validateGasLeftForCallback(order.callbackGasLimit());

        try IOrderCallbackReceiver(order.callbackContract()).afterOrderExecution{ gas: order.callbackGasLimit() }(
            key,
            order,
            eventData
        ) {
        } catch {
            emit AfterOrderExecutionError(key, order);
        }
    }

    // @dev called after an order cancellation
    // @param key the key of the order
    // @param order the order that was cancelled
    function afterOrderCancellation(
        bytes32 key,
        Order.Props memory order,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(order.callbackContract())) { return; }

        validateGasLeftForCallback(order.callbackGasLimit());

        try IOrderCallbackReceiver(order.callbackContract()).afterOrderCancellation{ gas: order.callbackGasLimit() }(
            key,
            order,
            eventData
        ) {
        } catch {
            emit AfterOrderCancellationError(key, order);
        }
    }

    // @dev called after an order has been frozen, see OrderUtils.freezeOrder in OrderHandler for more info
    // @param key the key of the order
    // @param order the order that was frozen
    function afterOrderFrozen(
        bytes32 key,
        Order.Props memory order,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(order.callbackContract())) { return; }

        validateGasLeftForCallback(order.callbackGasLimit());

        try IOrderCallbackReceiver(order.callbackContract()).afterOrderFrozen{ gas: order.callbackGasLimit() }(
            key,
            order,
            eventData
        ) {
        } catch {
            emit AfterOrderFrozenError(key, order);
        }
    }

    // @dev called after a glvDeposit execution
    // @param key the key of the glvDeposit
    // @param glvDeposit the glvDeposit that was executed
    function afterGlvDepositExecution(
        bytes32 key,
        GlvDeposit.Props memory glvDeposit,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(glvDeposit.callbackContract())) { return; }

        try IGlvDepositCallbackReceiver(glvDeposit.callbackContract()).afterGlvDepositExecution{ gas: glvDeposit.callbackGasLimit() }(
            key,
            glvDeposit,
            eventData
        ) {
        } catch {
            emit AfterGlvDepositExecutionError(key, glvDeposit);
        }
    }

    // @dev called after a glvDeposit cancellation
    // @param key the key of the glvDeposit
    // @param glvDeposit the glvDeposit that was cancelled
    function afterGlvDepositCancellation(
        bytes32 key,
        GlvDeposit.Props memory glvDeposit,
        EventUtils.EventLogData memory eventData
    ) internal {
        if (!isValidCallbackContract(glvDeposit.callbackContract())) { return; }

        try IGlvDepositCallbackReceiver(glvDeposit.callbackContract()).afterGlvDepositCancellation{ gas: glvDeposit.callbackGasLimit() }(
            key,
            glvDeposit,
            eventData
        ) {
        } catch {
            emit AfterGlvDepositCancellationError(key, glvDeposit);
        }
    }

    // @dev validates that the given address is a contract
    // @param callbackContract the contract to call
    function isValidCallbackContract(address callbackContract) internal view returns (bool) {
        if (callbackContract == address(0)) { return false; }
        if (!callbackContract.isContract()) { return false; }

        return true;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../event/EventUtils.sol";
import "../deposit/Deposit.sol";

// @title IDepositCallbackReceiver
// @dev interface for a deposit callback contract
interface IDepositCallbackReceiver {
    // @dev called after a deposit execution
    // @param key the key of the deposit
    // @param deposit the deposit that was executed
    function afterDepositExecution(bytes32 key, Deposit.Props memory deposit, EventUtils.EventLogData memory eventData) external;

    // @dev called after a deposit cancellation
    // @param key the key of the deposit
    // @param deposit the deposit that was cancelled
    function afterDepositCancellation(bytes32 key, Deposit.Props memory deposit, EventUtils.EventLogData memory eventData) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../event/EventUtils.sol";

interface IGasFeeCallbackReceiver {
    function refundExecutionFee(bytes32 key, EventUtils.EventLogData memory eventData) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../event/EventUtils.sol";
import "../glv/GlvDeposit.sol";

// @title IGlvDepositCallbackReceiver
// @dev interface for a glvDeposit callback contract
interface IGlvDepositCallbackReceiver {
    // @dev called after a glvDeposit execution
    // @param key the key of the glvDeposit
    // @param glvDeposit the glvDeposit that was executed
    function afterGlvDepositExecution(bytes32 key, GlvDeposit.Props memory glvDeposit, EventUtils.EventLogData memory eventData) external;

    // @dev called after a glvDeposit cancellation
    // @param key the key of the glvDeposit
    // @param glvDeposit the glvDeposit that was cancelled
    function afterGlvDepositCancellation(bytes32 key, GlvDeposit.Props memory glvDeposit, EventUtils.EventLogData memory eventData) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../event/EventUtils.sol";
import "../order/Order.sol";

// @title IOrderCallbackReceiver
// @dev interface for an order callback contract
interface IOrderCallbackReceiver {
    // @dev called after an order execution
    // @param key the key of the order
    // @param order the order that was executed
    function afterOrderExecution(bytes32 key, Order.Props memory order, EventUtils.EventLogData memory eventData) external;

    // @dev called after an order cancellation
    // @param key the key of the order
    // @param order the order that was cancelled
    function afterOrderCancellation(bytes32 key, Order.Props memory order, EventUtils.EventLogData memory eventData) external;

    // @dev called after an order has been frozen, see OrderUtils.freezeOrder in OrderHandler for more info
    // @param key the key of the order
    // @param order the order that was frozen
    function afterOrderFrozen(bytes32 key, Order.Props memory order, EventUtils.EventLogData memory eventData) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../event/EventUtils.sol";
import "../shift/Shift.sol";

interface IShiftCallbackReceiver {
    function afterShiftExecution(bytes32 key, Shift.Props memory shift, EventUtils.EventLogData memory eventData) external;
    function afterShiftCancellation(bytes32 key, Shift.Props memory shift, EventUtils.EventLogData memory eventData) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../event/EventUtils.sol";
import "../withdrawal/Withdrawal.sol";

// @title IWithdrawalCallbackReceiver
// @dev interface for a withdrawal callback contract
interface IWithdrawalCallbackReceiver {
    // @dev called after a withdrawal execution
    // @param key the key of the withdrawal
    // @param withdrawal the withdrawal that was executed
    function afterWithdrawalExecution(bytes32 key, Withdrawal.Props memory withdrawal, EventUtils.EventLogData memory eventData) external;

    // @dev called after a withdrawal cancellation
    // @param key the key of the withdrawal
    // @param withdrawal the withdrawal that was cancelled
    function afterWithdrawalCancellation(bytes32 key, Withdrawal.Props memory withdrawal, EventUtils.EventLogData memory eventData) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title ArbSys
// @dev Globally available variables for Arbitrum may have both an L1 and an L2
// value, the ArbSys interface is used to retrieve the L2 value
interface ArbSys {
    function arbBlockNumber() external view returns (uint256);
    function arbBlockHash(uint256 blockNumber) external view returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ArbSys.sol";

// @title Chain
// @dev Wrap the calls to retrieve chain variables to handle differences
// between chain implementations
library Chain {
    // if the ARBITRUM_CHAIN_ID changes, a new version of this library
    // and contracts depending on it would need to be deployed
    uint256 public constant ARBITRUM_CHAIN_ID = 42161;
    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;

    ArbSys public constant arbSys = ArbSys(address(100));

    // @dev return the current block's timestamp
    // @return the current block's timestamp
    function currentTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    // @dev return the current block's number
    // @return the current block's number
    function currentBlockNumber() internal view returns (uint256) {
        if (shouldUseArbSysValues()) {
            return arbSys.arbBlockNumber();
        }

        return block.number;
    }

    // @dev return the current block's hash
    // @return the current block's hash
    function getBlockHash(uint256 blockNumber) internal view returns (bytes32) {
        if (shouldUseArbSysValues()) {
            return arbSys.arbBlockHash(blockNumber);
        }

        return blockhash(blockNumber);
    }

    function shouldUseArbSysValues() internal view returns (bool) {
        return block.chainid == ARBITRUM_CHAIN_ID || block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/Calc.sol";
import "../utils/Printer.sol";

// @title DataStore
// @dev DataStore for all general state values
contract DataStore is RoleModule {
    using SafeCast for int256;

    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableValues for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.UintSet;

    // store for uint values
    mapping(bytes32 => uint256) public uintValues;
    // store for int values
    mapping(bytes32 => int256) public intValues;
    // store for address values
    mapping(bytes32 => address) public addressValues;
    // store for bool values
    mapping(bytes32 => bool) public boolValues;
    // store for string values
    mapping(bytes32 => string) public stringValues;
    // store for bytes32 values
    mapping(bytes32 => bytes32) public bytes32Values;

    // store for uint[] values
    mapping(bytes32 => uint256[]) public uintArrayValues;
    // store for int[] values
    mapping(bytes32 => int256[]) public intArrayValues;
    // store for address[] values
    mapping(bytes32 => address[]) public addressArrayValues;
    // store for bool[] values
    mapping(bytes32 => bool[]) public boolArrayValues;
    // store for string[] values
    mapping(bytes32 => string[]) public stringArrayValues;
    // store for bytes32[] values
    mapping(bytes32 => bytes32[]) public bytes32ArrayValues;

    // store for bytes32 sets
    mapping(bytes32 => EnumerableSet.Bytes32Set) internal bytes32Sets;
    // store for address sets
    mapping(bytes32 => EnumerableSet.AddressSet) internal addressSets;
    // store for uint256 sets
    mapping(bytes32 => EnumerableSet.UintSet) internal uintSets;

    constructor(RoleStore _roleStore) RoleModule(_roleStore) {}

    // @dev get the uint value for the given key
    // @param key the key of the value
    // @return the uint value for the key
    function getUint(bytes32 key) external view returns (uint256) {
        return uintValues[key];
    }

    // @dev set the uint value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the uint value for the key
    function setUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uintValues[key] = value;
        return value;
    }

    // @dev delete the uint value for the given key
    // @param key the key of the value
    function removeUint(bytes32 key) external onlyController {
        delete uintValues[key];
    }

    // @dev add the input int value to the existing uint value
    // @param key the key of the value
    // @param value the input int value
    // @return the new uint value
    function applyDeltaToUint(bytes32 key, int256 value, string memory errorMessage) external onlyController returns (uint256) {
        uint256 currValue = uintValues[key];
        if (value < 0 && (-value).toUint256() > currValue) {
            revert(errorMessage);
        }
        uint256 nextUint = Calc.sumReturnUint256(currValue, value);
        uintValues[key] = nextUint;
        return nextUint;
    }

    // @dev add the input uint value to the existing uint value
    // @param key the key of the value
    // @param value the input int value
    // @return the new uint value
    function applyDeltaToUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uint256 currValue = uintValues[key];
        uint256 nextUint = currValue + value;
        uintValues[key] = nextUint;
        return nextUint;
    }

    // @dev add the input int value to the existing uint value, prevent the uint
    // value from becoming negative
    // @param key the key of the value
    // @param value the input int value
    // @return the new uint value
    function applyBoundedDeltaToUint(bytes32 key, int256 value) external onlyController returns (uint256) {
        uint256 uintValue = uintValues[key];
        if (value < 0 && (-value).toUint256() > uintValue) {
            uintValues[key] = 0;
            return 0;
        }

        uint256 nextUint = Calc.sumReturnUint256(uintValue, value);
        uintValues[key] = nextUint;
        return nextUint;
    }

    // @dev add the input uint value to the existing uint value
    // @param key the key of the value
    // @param value the input uint value
    // @return the new uint value
    function incrementUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uint256 nextUint = uintValues[key] + value;
        uintValues[key] = nextUint;
        return nextUint;
    }

    // @dev subtract the input uint value from the existing uint value
    // @param key the key of the value
    // @param value the input uint value
    // @return the new uint value
    function decrementUint(bytes32 key, uint256 value) external onlyController returns (uint256) {
        uint256 nextUint = uintValues[key] - value;
        uintValues[key] = nextUint;
        return nextUint;
    }

    // @dev get the int value for the given key
    // @param key the key of the value
    // @return the int value for the key
    function getInt(bytes32 key) external view returns (int256) {
        return intValues[key];
    }

    // @dev set the int value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the int value for the key
    function setInt(bytes32 key, int256 value) external onlyController returns (int256) {
        intValues[key] = value;
        return value;
    }

    function removeInt(bytes32 key) external onlyController {
        delete intValues[key];
    }

    // @dev add the input int value to the existing int value
    // @param key the key of the value
    // @param value the input int value
    // @return the new int value
    function applyDeltaToInt(bytes32 key, int256 value) external onlyController returns (int256) {
        int256 nextInt = intValues[key] + value;
        intValues[key] = nextInt;
        return nextInt;
    }

    // @dev add the input int value to the existing int value
    // @param key the key of the value
    // @param value the input int value
    // @return the new int value
    function incrementInt(bytes32 key, int256 value) external onlyController returns (int256) {
        int256 nextInt = intValues[key] + value;
        intValues[key] = nextInt;
        return nextInt;
    }

    // @dev subtract the input int value from the existing int value
    // @param key the key of the value
    // @param value the input int value
    // @return the new int value
    function decrementInt(bytes32 key, int256 value) external onlyController returns (int256) {
        int256 nextInt = intValues[key] - value;
        intValues[key] = nextInt;
        return nextInt;
    }

    // @dev get the address value for the given key
    // @param key the key of the value
    // @return the address value for the key
    function getAddress(bytes32 key) external view returns (address) {
        return addressValues[key];
    }

    // @dev set the address value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the address value for the key
    function setAddress(bytes32 key, address value) external onlyController returns (address) {
        addressValues[key] = value;
        return value;
    }

    // @dev delete the address value for the given key
    // @param key the key of the value
    function removeAddress(bytes32 key) external onlyController {
        delete addressValues[key];
    }

    // @dev get the bool value for the given key
    // @param key the key of the value
    // @return the bool value for the key
    function getBool(bytes32 key) external view returns (bool) {
        return boolValues[key];
    }

    // @dev set the bool value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the bool value for the key
    function setBool(bytes32 key, bool value) external onlyController returns (bool) {
        boolValues[key] = value;
        return value;
    }

    // @dev delete the bool value for the given key
    // @param key the key of the value
    function removeBool(bytes32 key) external onlyController {
        delete boolValues[key];
    }

    // @dev get the string value for the given key
    // @param key the key of the value
    // @return the string value for the key
    function getString(bytes32 key) external view returns (string memory) {
        return stringValues[key];
    }

    // @dev set the string value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the string value for the key
    function setString(bytes32 key, string memory value) external onlyController returns (string memory) {
        stringValues[key] = value;
        return value;
    }

    // @dev delete the string value for the given key
    // @param key the key of the value
    function removeString(bytes32 key) external onlyController {
        delete stringValues[key];
    }

    // @dev get the bytes32 value for the given key
    // @param key the key of the value
    // @return the bytes32 value for the key
    function getBytes32(bytes32 key) external view returns (bytes32) {
        return bytes32Values[key];
    }

    // @dev set the bytes32 value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the bytes32 value for the key
    function setBytes32(bytes32 key, bytes32 value) external onlyController returns (bytes32) {
        bytes32Values[key] = value;
        return value;
    }

    // @dev delete the bytes32 value for the given key
    // @param key the key of the value
    function removeBytes32(bytes32 key) external onlyController {
        delete bytes32Values[key];
    }

    // @dev get the uint array for the given key
    // @param key the key of the uint array
    // @return the uint array for the key
    function getUintArray(bytes32 key) external view returns (uint256[] memory) {
        return uintArrayValues[key];
    }

    // @dev set the uint array for the given key
    // @param key the key of the uint array
    // @param value the value of the uint array
    function setUintArray(bytes32 key, uint256[] memory value) external onlyController {
        uintArrayValues[key] = value;
    }

    // @dev delete the uint array for the given key
    // @param key the key of the uint array
    // @param value the value of the uint array
    function removeUintArray(bytes32 key) external onlyController {
        delete uintArrayValues[key];
    }

    // @dev get the int array for the given key
    // @param key the key of the int array
    // @return the int array for the key
    function getIntArray(bytes32 key) external view returns (int256[] memory) {
        return intArrayValues[key];
    }

    // @dev set the int array for the given key
    // @param key the key of the int array
    // @param value the value of the int array
    function setIntArray(bytes32 key, int256[] memory value) external onlyController {
        intArrayValues[key] = value;
    }

    // @dev delete the int array for the given key
    // @param key the key of the int array
    // @param value the value of the int array
    function removeIntArray(bytes32 key) external onlyController {
        delete intArrayValues[key];
    }

    // @dev get the address array for the given key
    // @param key the key of the address array
    // @return the address array for the key
    function getAddressArray(bytes32 key) external view returns (address[] memory) {
        return addressArrayValues[key];
    }

    // @dev set the address array for the given key
    // @param key the key of the address array
    // @param value the value of the address array
    function setAddressArray(bytes32 key, address[] memory value) external onlyController {
        addressArrayValues[key] = value;
    }

    // @dev delete the address array for the given key
    // @param key the key of the address array
    // @param value the value of the address array
    function removeAddressArray(bytes32 key) external onlyController {
        delete addressArrayValues[key];
    }

    // @dev get the bool array for the given key
    // @param key the key of the bool array
    // @return the bool array for the key
    function getBoolArray(bytes32 key) external view returns (bool[] memory) {
        return boolArrayValues[key];
    }

    // @dev set the bool array for the given key
    // @param key the key of the bool array
    // @param value the value of the bool array
    function setBoolArray(bytes32 key, bool[] memory value) external onlyController {
        boolArrayValues[key] = value;
    }

    // @dev delete the bool array for the given key
    // @param key the key of the bool array
    // @param value the value of the bool array
    function removeBoolArray(bytes32 key) external onlyController {
        delete boolArrayValues[key];
    }

    // @dev get the string array for the given key
    // @param key the key of the string array
    // @return the string array for the key
    function getStringArray(bytes32 key) external view returns (string[] memory) {
        return stringArrayValues[key];
    }

    // @dev set the string array for the given key
    // @param key the key of the string array
    // @param value the value of the string array
    function setStringArray(bytes32 key, string[] memory value) external onlyController {
        stringArrayValues[key] = value;
    }

    // @dev delete the string array for the given key
    // @param key the key of the string array
    // @param value the value of the string array
    function removeStringArray(bytes32 key) external onlyController {
        delete stringArrayValues[key];
    }

    // @dev get the bytes32 array for the given key
    // @param key the key of the bytes32 array
    // @return the bytes32 array for the key
    function getBytes32Array(bytes32 key) external view returns (bytes32[] memory) {
        return bytes32ArrayValues[key];
    }

    // @dev set the bytes32 array for the given key
    // @param key the key of the bytes32 array
    // @param value the value of the bytes32 array
    function setBytes32Array(bytes32 key, bytes32[] memory value) external onlyController {
        bytes32ArrayValues[key] = value;
    }

    // @dev delete the bytes32 array for the given key
    // @param key the key of the bytes32 array
    // @param value the value of the bytes32 array
    function removeBytes32Array(bytes32 key) external onlyController {
        delete bytes32ArrayValues[key];
    }

    // @dev check whether the given value exists in the set
    // @param setKey the key of the set
    // @param value the value to check
    function containsBytes32(bytes32 setKey, bytes32 value) external view returns (bool) {
        return bytes32Sets[setKey].contains(value);
    }

    // @dev get the length of the set
    // @param setKey the key of the set
    function getBytes32Count(bytes32 setKey) external view returns (uint256) {
        return bytes32Sets[setKey].length();
    }

    // @dev get the values of the set in the given range
    // @param setKey the key of the set
    // @param the start of the range, values at the start index will be returned
    // in the result
    // @param the end of the range, values at the end index will not be returned
    // in the result
    function getBytes32ValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (bytes32[] memory) {
        return bytes32Sets[setKey].valuesAt(start, end);
    }

    // @dev add the given value to the set
    // @param setKey the key of the set
    // @param value the value to add
    function addBytes32(bytes32 setKey, bytes32 value) external onlyController {
        bytes32Sets[setKey].add(value);
    }

    // @dev remove the given value from the set
    // @param setKey the key of the set
    // @param value the value to remove
    function removeBytes32(bytes32 setKey, bytes32 value) external onlyController {
        bytes32Sets[setKey].remove(value);
    }

    // @dev check whether the given value exists in the set
    // @param setKey the key of the set
    // @param value the value to check
    function containsAddress(bytes32 setKey, address value) external view returns (bool) {
        return addressSets[setKey].contains(value);
    }

    // @dev get the length of the set
    // @param setKey the key of the set
    function getAddressCount(bytes32 setKey) external view returns (uint256) {
        return addressSets[setKey].length();
    }

    // @dev get the values of the set in the given range
    // @param setKey the key of the set
    // @param the start of the range, values at the start index will be returned
    // in the result
    // @param the end of the range, values at the end index will not be returned
    // in the result
    function getAddressValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (address[] memory) {
        return addressSets[setKey].valuesAt(start, end);
    }

    // @dev add the given value to the set
    // @param setKey the key of the set
    // @param value the value to add
    function addAddress(bytes32 setKey, address value) external onlyController {
        addressSets[setKey].add(value);
    }

    // @dev remove the given value from the set
    // @param setKey the key of the set
    // @param value the value to remove
    function removeAddress(bytes32 setKey, address value) external onlyController {
        addressSets[setKey].remove(value);
    }

    // @dev check whether the given value exists in the set
    // @param setKey the key of the set
    // @param value the value to check
    function containsUint(bytes32 setKey, uint256 value) external view returns (bool) {
        return uintSets[setKey].contains(value);
    }

    // @dev get the length of the set
    // @param setKey the key of the set
    function getUintCount(bytes32 setKey) external view returns (uint256) {
        return uintSets[setKey].length();
    }

    // @dev get the values of the set in the given range
    // @param setKey the key of the set
    // @param the start of the range, values at the start index will be returned
    // in the result
    // @param the end of the range, values at the end index will not be returned
    // in the result
    function getUintValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (uint256[] memory) {
        return uintSets[setKey].valuesAt(start, end);
    }

    // @dev add the given value to the set
    // @param setKey the key of the set
    // @param value the value to add
    function addUint(bytes32 setKey, uint256 value) external onlyController {
        uintSets[setKey].add(value);
    }

    // @dev remove the given value from the set
    // @param setKey the key of the set
    // @param value the value to remove
    function removeUint(bytes32 setKey, uint256 value) external onlyController {
        uintSets[setKey].remove(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title Keys
// @dev Keys for values in the DataStore
library Keys {
    // @dev key for the address of the wrapped native token
    bytes32 public constant WNT = keccak256(abi.encode("WNT"));
    // @dev key for the nonce value used in NonceUtils
    bytes32 public constant NONCE = keccak256(abi.encode("NONCE"));

    // @dev for sending received fees
    bytes32 public constant FEE_RECEIVER = keccak256(abi.encode("FEE_RECEIVER"));

    // @dev for holding tokens that could not be sent out
    bytes32 public constant HOLDING_ADDRESS = keccak256(abi.encode("HOLDING_ADDRESS"));

    // @dev key for the minimum gas for execution error
    bytes32 public constant MIN_HANDLE_EXECUTION_ERROR_GAS = keccak256(abi.encode("MIN_HANDLE_EXECUTION_ERROR_GAS"));

    // @dev key for the minimum gas that should be forwarded for execution error handling
    bytes32 public constant MIN_HANDLE_EXECUTION_ERROR_GAS_TO_FORWARD = keccak256(abi.encode("MIN_HANDLE_EXECUTION_ERROR_GAS_TO_FORWARD"));

    // @dev key for the min additional gas for execution
    bytes32 public constant MIN_ADDITIONAL_GAS_FOR_EXECUTION = keccak256(abi.encode("MIN_ADDITIONAL_GAS_FOR_EXECUTION"));

    // @dev for a global reentrancy guard
    bytes32 public constant REENTRANCY_GUARD_STATUS = keccak256(abi.encode("REENTRANCY_GUARD_STATUS"));

    // @dev key for deposit fees
    bytes32 public constant DEPOSIT_FEE_TYPE = keccak256(abi.encode("DEPOSIT_FEE_TYPE"));
    // @dev key for withdrawal fees
    bytes32 public constant WITHDRAWAL_FEE_TYPE = keccak256(abi.encode("WITHDRAWAL_FEE_TYPE"));
    // @dev key for swap fees
    bytes32 public constant SWAP_FEE_TYPE = keccak256(abi.encode("SWAP_FEE_TYPE"));
    // @dev key for position fees
    bytes32 public constant POSITION_FEE_TYPE = keccak256(abi.encode("POSITION_FEE_TYPE"));
    // @dev key for ui deposit fees
    bytes32 public constant UI_DEPOSIT_FEE_TYPE = keccak256(abi.encode("UI_DEPOSIT_FEE_TYPE"));
    // @dev key for ui withdrawal fees
    bytes32 public constant UI_WITHDRAWAL_FEE_TYPE = keccak256(abi.encode("UI_WITHDRAWAL_FEE_TYPE"));
    // @dev key for ui swap fees
    bytes32 public constant UI_SWAP_FEE_TYPE = keccak256(abi.encode("UI_SWAP_FEE_TYPE"));
    // @dev key for ui position fees
    bytes32 public constant UI_POSITION_FEE_TYPE = keccak256(abi.encode("UI_POSITION_FEE_TYPE"));

    // @dev key for ui fee factor
    bytes32 public constant UI_FEE_FACTOR = keccak256(abi.encode("UI_FEE_FACTOR"));
    // @dev key for max ui fee receiver factor
    bytes32 public constant MAX_UI_FEE_FACTOR = keccak256(abi.encode("MAX_UI_FEE_FACTOR"));

    // @dev key for the claimable fee amount
    bytes32 public constant CLAIMABLE_FEE_AMOUNT = keccak256(abi.encode("CLAIMABLE_FEE_AMOUNT"));
    // @dev key for the claimable ui fee amount
    bytes32 public constant CLAIMABLE_UI_FEE_AMOUNT = keccak256(abi.encode("CLAIMABLE_UI_FEE_AMOUNT"));
    // @dev key for the max number of auto cancel orders
    bytes32 public constant MAX_AUTO_CANCEL_ORDERS = keccak256(abi.encode("MAX_AUTO_CANCEL_ORDERS"));
    // @dev key for the max total callback gas limit for auto cancel orders
    bytes32 public constant MAX_TOTAL_CALLBACK_GAS_LIMIT_FOR_AUTO_CANCEL_ORDERS = keccak256(abi.encode("MAX_TOTAL_CALLBACK_GAS_LIMIT_FOR_AUTO_CANCEL_ORDERS"));

    // @dev key for the market list
    bytes32 public constant MARKET_LIST = keccak256(abi.encode("MARKET_LIST"));

    // @dev key for the fee batch list
    bytes32 public constant FEE_BATCH_LIST = keccak256(abi.encode("FEE_BATCH_LIST"));

    // @dev key for the deposit list
    bytes32 public constant DEPOSIT_LIST = keccak256(abi.encode("DEPOSIT_LIST"));
    // @dev key for the account deposit list
    bytes32 public constant ACCOUNT_DEPOSIT_LIST = keccak256(abi.encode("ACCOUNT_DEPOSIT_LIST"));

    // @dev key for the withdrawal list
    bytes32 public constant WITHDRAWAL_LIST = keccak256(abi.encode("WITHDRAWAL_LIST"));
    // @dev key for the account withdrawal list
    bytes32 public constant ACCOUNT_WITHDRAWAL_LIST = keccak256(abi.encode("ACCOUNT_WITHDRAWAL_LIST"));

    // @dev key for the shift list
    bytes32 public constant SHIFT_LIST = keccak256(abi.encode("SHIFT_LIST"));
    // @dev key for the account shift list
    bytes32 public constant ACCOUNT_SHIFT_LIST = keccak256(abi.encode("ACCOUNT_SHIFT_LIST"));

    // @dev key for the glv list
    bytes32 public constant GLV_LIST = keccak256(abi.encode("GLV_LIST"));

    // @dev key for the glv deposit list
    bytes32 public constant GLV_DEPOSIT_LIST = keccak256(abi.encode("GLV_DEPOSIT_LIST"));
    // @dev key for the account glv deposit list
    bytes32 public constant ACCOUNT_GLV_DEPOSIT_LIST = keccak256(abi.encode("ACCOUNT_GLV_DEPOSIT_LIST"));
    // @dev key for the account glv supported market list
    bytes32 public constant GLV_SUPPORTED_MARKET_LIST = keccak256(abi.encode("GLV_SUPPORTED_MARKET_LIST"));

    // @dev key for the position list
    bytes32 public constant POSITION_LIST = keccak256(abi.encode("POSITION_LIST"));
    // @dev key for the account position list
    bytes32 public constant ACCOUNT_POSITION_LIST = keccak256(abi.encode("ACCOUNT_POSITION_LIST"));

    // @dev key for the order list
    bytes32 public constant ORDER_LIST = keccak256(abi.encode("ORDER_LIST"));
    // @dev key for the account order list
    bytes32 public constant ACCOUNT_ORDER_LIST = keccak256(abi.encode("ACCOUNT_ORDER_LIST"));

    // @dev key for the subaccount list
    bytes32 public constant SUBACCOUNT_LIST = keccak256(abi.encode("SUBACCOUNT_LIST"));

    // @dev key for the auto cancel order list
    bytes32 public constant AUTO_CANCEL_ORDER_LIST = keccak256(abi.encode("AUTO_CANCEL_ORDER_LIST"));

    // @dev key for is market disabled
    bytes32 public constant IS_MARKET_DISABLED = keccak256(abi.encode("IS_MARKET_DISABLED"));

    // @dev key for the max swap path length allowed
    bytes32 public constant MAX_SWAP_PATH_LENGTH = keccak256(abi.encode("MAX_SWAP_PATH_LENGTH"));
    // @dev key used to store markets observed in a swap path, to ensure that a swap path contains unique markets
    bytes32 public constant SWAP_PATH_MARKET_FLAG = keccak256(abi.encode("SWAP_PATH_MARKET_FLAG"));
    // @dev key used to store the min market tokens for the first deposit for a market
    bytes32 public constant MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT = keccak256(abi.encode("MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT"));

    // @dev key for whether the create glv deposit feature is disabled
    bytes32 public constant CREATE_GLV_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("CREATE_GLV_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the cancel glv deposit feature is disabled
    bytes32 public constant CANCEL_GLV_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_GLV_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the execute glv deposit feature is disabled
    bytes32 public constant EXECUTE_GLV_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_GLV_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the glv shift feature is disabled
    bytes32 public constant GLV_SHIFT_FEATURE_DISABLED = keccak256(abi.encode("GLV_SHIFT_FEATURE_DISABLED"));

    // @dev key for whether the create deposit feature is disabled
    bytes32 public constant CREATE_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("CREATE_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the cancel deposit feature is disabled
    bytes32 public constant CANCEL_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the execute deposit feature is disabled
    bytes32 public constant EXECUTE_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_DEPOSIT_FEATURE_DISABLED"));

    // @dev key for whether the create withdrawal feature is disabled
    bytes32 public constant CREATE_WITHDRAWAL_FEATURE_DISABLED = keccak256(abi.encode("CREATE_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the cancel withdrawal feature is disabled
    bytes32 public constant CANCEL_WITHDRAWAL_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the execute withdrawal feature is disabled
    bytes32 public constant EXECUTE_WITHDRAWAL_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the execute atomic withdrawal feature is disabled
    bytes32 public constant EXECUTE_ATOMIC_WITHDRAWAL_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_ATOMIC_WITHDRAWAL_FEATURE_DISABLED"));

    // @dev key for whether the create shift feature is disabled
    bytes32 public constant CREATE_SHIFT_FEATURE_DISABLED = keccak256(abi.encode("CREATE_SHIFT_FEATURE_DISABLED"));
    // @dev key for whether the cancel shift feature is disabled
    bytes32 public constant CANCEL_SHIFT_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_SHIFT_FEATURE_DISABLED"));
    // @dev key for whether the execute shift feature is disabled
    bytes32 public constant EXECUTE_SHIFT_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_SHIFT_FEATURE_DISABLED"));

    // @dev key for whether the create order feature is disabled
    bytes32 public constant CREATE_ORDER_FEATURE_DISABLED = keccak256(abi.encode("CREATE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the execute order feature is disabled
    bytes32 public constant EXECUTE_ORDER_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the execute adl feature is disabled
    // for liquidations, it can be disabled by using the EXECUTE_ORDER_FEATURE_DISABLED key with the Liquidation
    // order type, ADL orders have a MarketDecrease order type, so a separate key is needed to disable it
    bytes32 public constant EXECUTE_ADL_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_ADL_FEATURE_DISABLED"));
    // @dev key for whether the update order feature is disabled
    bytes32 public constant UPDATE_ORDER_FEATURE_DISABLED = keccak256(abi.encode("UPDATE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the cancel order feature is disabled
    bytes32 public constant CANCEL_ORDER_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_ORDER_FEATURE_DISABLED"));

    // @dev key for whether the claim funding fees feature is disabled
    bytes32 public constant CLAIM_FUNDING_FEES_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_FUNDING_FEES_FEATURE_DISABLED"));
    // @dev key for whether the claim collateral feature is disabled
    bytes32 public constant CLAIM_COLLATERAL_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_COLLATERAL_FEATURE_DISABLED"));
    // @dev key for whether the claim affiliate rewards feature is disabled
    bytes32 public constant CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED"));
    // @dev key for whether the claim ui fees feature is disabled
    bytes32 public constant CLAIM_UI_FEES_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_UI_FEES_FEATURE_DISABLED"));
    // @dev key for whether the subaccount feature is disabled
    bytes32 public constant SUBACCOUNT_FEATURE_DISABLED = keccak256(abi.encode("SUBACCOUNT_FEATURE_DISABLED"));

    // @dev key for the minimum required oracle signers for an oracle observation
    bytes32 public constant MIN_ORACLE_SIGNERS = keccak256(abi.encode("MIN_ORACLE_SIGNERS"));
    // @dev key for the minimum block confirmations before blockhash can be excluded for oracle signature validation
    bytes32 public constant MIN_ORACLE_BLOCK_CONFIRMATIONS = keccak256(abi.encode("MIN_ORACLE_BLOCK_CONFIRMATIONS"));
    // @dev key for the maximum usable oracle price age in seconds
    bytes32 public constant MAX_ORACLE_PRICE_AGE = keccak256(abi.encode("MAX_ORACLE_PRICE_AGE"));
    // @dev key for the maximum oracle timestamp range
    bytes32 public constant MAX_ORACLE_TIMESTAMP_RANGE = keccak256(abi.encode("MAX_ORACLE_TIMESTAMP_RANGE"));
    // @dev key for the maximum oracle price deviation factor from the ref price
    bytes32 public constant MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR = keccak256(abi.encode("MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR"));
    // @dev key for whether an oracle provider is enabled
    bytes32 public constant IS_ORACLE_PROVIDER_ENABLED = keccak256(abi.encode("IS_ORACLE_PROVIDER_ENABLED"));
    // @dev key for whether an oracle provider can be used for atomic actions
    bytes32 public constant IS_ATOMIC_ORACLE_PROVIDER = keccak256(abi.encode("IS_ATOMIC_ORACLE_PROVIDER"));
    // @dev key for oracle timestamp adjustment
    bytes32 public constant ORACLE_TIMESTAMP_ADJUSTMENT = keccak256(abi.encode("ORACLE_TIMESTAMP_ADJUSTMENT"));
    // @dev key for oracle provider for token
    bytes32 public constant ORACLE_PROVIDER_FOR_TOKEN = keccak256(abi.encode("ORACLE_PROVIDER_FOR_TOKEN"));
    // @dev key for the chainlink payment token
    bytes32 public constant CHAINLINK_PAYMENT_TOKEN = keccak256(abi.encode("CHAINLINK_PAYMENT_TOKEN"));
    // @dev key for the sequencer grace duration
    bytes32 public constant SEQUENCER_GRACE_DURATION = keccak256(abi.encode("SEQUENCER_GRACE_DURATION"));

    // @dev key for the percentage amount of position fees to be received
    bytes32 public constant POSITION_FEE_RECEIVER_FACTOR = keccak256(abi.encode("POSITION_FEE_RECEIVER_FACTOR"));
    // @dev key for the percentage amount of swap fees to be received
    bytes32 public constant SWAP_FEE_RECEIVER_FACTOR = keccak256(abi.encode("SWAP_FEE_RECEIVER_FACTOR"));
    // @dev key for the percentage amount of borrowing fees to be received
    bytes32 public constant BORROWING_FEE_RECEIVER_FACTOR = keccak256(abi.encode("BORROWING_FEE_RECEIVER_FACTOR"));

    // @dev key for the base gas limit used when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_BASE_AMOUNT_V2_1 = keccak256(abi.encode("ESTIMATED_GAS_FEE_BASE_AMOUNT_V2_1"));
    // @dev key for the gas limit used for each oracle price when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_PER_ORACLE_PRICE = keccak256(abi.encode("ESTIMATED_GAS_FEE_PER_ORACLE_PRICE"));
    // @dev key for the multiplier used when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR = keccak256(abi.encode("ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR"));

    // @dev key for the base gas limit used when calculating execution fee
    bytes32 public constant EXECUTION_GAS_FEE_BASE_AMOUNT_V2_1 = keccak256(abi.encode("EXECUTION_GAS_FEE_BASE_AMOUNT_V2_1"));
    // @dev key for the gas limit used for each oracle price
    bytes32 public constant EXECUTION_GAS_FEE_PER_ORACLE_PRICE = keccak256(abi.encode("EXECUTION_GAS_FEE_PER_ORACLE_PRICE"));
    // @dev key for the multiplier used when calculating execution fee
    bytes32 public constant EXECUTION_GAS_FEE_MULTIPLIER_FACTOR = keccak256(abi.encode("EXECUTION_GAS_FEE_MULTIPLIER_FACTOR"));

    // @dev key for the estimated gas limit for deposits
    bytes32 public constant DEPOSIT_GAS_LIMIT = keccak256(abi.encode("DEPOSIT_GAS_LIMIT"));
    // @dev key for the estimated gas limit for withdrawals
    bytes32 public constant WITHDRAWAL_GAS_LIMIT = keccak256(abi.encode("WITHDRAWAL_GAS_LIMIT"));
    // @dev key for the estimated gas limit for each glv market
    bytes32 public constant GLV_DEPOSIT_GAS_LIMIT = keccak256(abi.encode("GLV_DEPOSIT_GAS_LIMIT"));
    // @dev key for the estimated gas limit for shifts
    bytes32 public constant GLV_PER_MARKET_GAS_LIMIT = keccak256(abi.encode("GLV_PER_MARKET_GAS_LIMIT"));
    // @dev key for the estimated gas limit for shifts
    bytes32 public constant SHIFT_GAS_LIMIT = keccak256(abi.encode("SHIFT_GAS_LIMIT"));
    // @dev key for the estimated gas limit for single swaps
    bytes32 public constant SINGLE_SWAP_GAS_LIMIT = keccak256(abi.encode("SINGLE_SWAP_GAS_LIMIT"));
    // @dev key for the estimated gas limit for increase orders
    bytes32 public constant INCREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("INCREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for decrease orders
    bytes32 public constant DECREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("DECREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for swap orders
    bytes32 public constant SWAP_ORDER_GAS_LIMIT = keccak256(abi.encode("SWAP_ORDER_GAS_LIMIT"));
    // @dev key for the amount of gas to forward for token transfers
    bytes32 public constant TOKEN_TRANSFER_GAS_LIMIT = keccak256(abi.encode("TOKEN_TRANSFER_GAS_LIMIT"));
    // @dev key for the amount of gas to forward for native token transfers
    bytes32 public constant NATIVE_TOKEN_TRANSFER_GAS_LIMIT = keccak256(abi.encode("NATIVE_TOKEN_TRANSFER_GAS_LIMIT"));
    // @dev key for the request expiration time, after which the request will be considered expired
    bytes32 public constant REQUEST_EXPIRATION_TIME = keccak256(abi.encode("REQUEST_EXPIRATION_TIME"));

    bytes32 public constant MAX_CALLBACK_GAS_LIMIT = keccak256(abi.encode("MAX_CALLBACK_GAS_LIMIT"));
    bytes32 public constant REFUND_EXECUTION_FEE_GAS_LIMIT = keccak256(abi.encode("REFUND_EXECUTION_FEE_GAS_LIMIT"));
    bytes32 public constant SAVED_CALLBACK_CONTRACT = keccak256(abi.encode("SAVED_CALLBACK_CONTRACT"));

    // @dev key for the min collateral factor
    bytes32 public constant MIN_COLLATERAL_FACTOR = keccak256(abi.encode("MIN_COLLATERAL_FACTOR"));
    // @dev key for the min collateral factor for open interest multiplier
    bytes32 public constant MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER = keccak256(abi.encode("MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER"));
    // @dev key for the min allowed collateral in USD
    bytes32 public constant MIN_COLLATERAL_USD = keccak256(abi.encode("MIN_COLLATERAL_USD"));
    // @dev key for the min allowed position size in USD
    bytes32 public constant MIN_POSITION_SIZE_USD = keccak256(abi.encode("MIN_POSITION_SIZE_USD"));

    // @dev key for the virtual id of tokens
    bytes32 public constant VIRTUAL_TOKEN_ID = keccak256(abi.encode("VIRTUAL_TOKEN_ID"));
    // @dev key for the virtual id of markets
    bytes32 public constant VIRTUAL_MARKET_ID = keccak256(abi.encode("VIRTUAL_MARKET_ID"));
    // @dev key for the virtual inventory for swaps
    bytes32 public constant VIRTUAL_INVENTORY_FOR_SWAPS = keccak256(abi.encode("VIRTUAL_INVENTORY_FOR_SWAPS"));
    // @dev key for the virtual inventory for positions
    bytes32 public constant VIRTUAL_INVENTORY_FOR_POSITIONS = keccak256(abi.encode("VIRTUAL_INVENTORY_FOR_POSITIONS"));

    // @dev key for the position impact factor
    bytes32 public constant POSITION_IMPACT_FACTOR = keccak256(abi.encode("POSITION_IMPACT_FACTOR"));
    // @dev key for the position impact exponent factor
    bytes32 public constant POSITION_IMPACT_EXPONENT_FACTOR = keccak256(abi.encode("POSITION_IMPACT_EXPONENT_FACTOR"));
    // @dev key for the max decrease position impact factor
    bytes32 public constant MAX_POSITION_IMPACT_FACTOR = keccak256(abi.encode("MAX_POSITION_IMPACT_FACTOR"));
    // @dev key for the max position impact factor for liquidations
    bytes32 public constant MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS = keccak256(abi.encode("MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS"));
    // @dev key for the position fee factor
    bytes32 public constant POSITION_FEE_FACTOR = keccak256(abi.encode("POSITION_FEE_FACTOR"));
    // @dev key for the swap impact factor
    bytes32 public constant SWAP_IMPACT_FACTOR = keccak256(abi.encode("SWAP_IMPACT_FACTOR"));
    // @dev key for the swap impact exponent factor
    bytes32 public constant SWAP_IMPACT_EXPONENT_FACTOR = keccak256(abi.encode("SWAP_IMPACT_EXPONENT_FACTOR"));
    // @dev key for the swap fee factor
    bytes32 public constant SWAP_FEE_FACTOR = keccak256(abi.encode("SWAP_FEE_FACTOR"));
    // @dev key for the atomic swap fee factor
    bytes32 public constant ATOMIC_SWAP_FEE_FACTOR = keccak256(abi.encode("ATOMIC_SWAP_FEE_FACTOR"));
    // @dev key for the oracle type
    bytes32 public constant ORACLE_TYPE = keccak256(abi.encode("ORACLE_TYPE"));
    // @dev key for open interest
    bytes32 public constant OPEN_INTEREST = keccak256(abi.encode("OPEN_INTEREST"));
    // @dev key for open interest in tokens
    bytes32 public constant OPEN_INTEREST_IN_TOKENS = keccak256(abi.encode("OPEN_INTEREST_IN_TOKENS"));
    // @dev key for collateral sum for a market
    bytes32 public constant COLLATERAL_SUM = keccak256(abi.encode("COLLATERAL_SUM"));
    // @dev key for pool amount
    bytes32 public constant POOL_AMOUNT = keccak256(abi.encode("POOL_AMOUNT"));
    // @dev key for max pool amount
    bytes32 public constant MAX_POOL_AMOUNT = keccak256(abi.encode("MAX_POOL_AMOUNT"));
    // @dev key for max pool usd for deposit
    bytes32 public constant MAX_POOL_USD_FOR_DEPOSIT = keccak256(abi.encode("MAX_POOL_USD_FOR_DEPOSIT"));
    // @dev key for max open interest
    bytes32 public constant MAX_OPEN_INTEREST = keccak256(abi.encode("MAX_OPEN_INTEREST"));
    // @dev key for position impact pool amount
    bytes32 public constant POSITION_IMPACT_POOL_AMOUNT = keccak256(abi.encode("POSITION_IMPACT_POOL_AMOUNT"));
    // @dev key for min position impact pool amount
    bytes32 public constant MIN_POSITION_IMPACT_POOL_AMOUNT = keccak256(abi.encode("MIN_POSITION_IMPACT_POOL_AMOUNT"));
    // @dev key for position impact pool distribution rate
    bytes32 public constant POSITION_IMPACT_POOL_DISTRIBUTION_RATE = keccak256(abi.encode("POSITION_IMPACT_POOL_DISTRIBUTION_RATE"));
    // @dev key for position impact pool distributed at
    bytes32 public constant POSITION_IMPACT_POOL_DISTRIBUTED_AT = keccak256(abi.encode("POSITION_IMPACT_POOL_DISTRIBUTED_AT"));
    // @dev key for swap impact pool amount
    bytes32 public constant SWAP_IMPACT_POOL_AMOUNT = keccak256(abi.encode("SWAP_IMPACT_POOL_AMOUNT"));
    // @dev key for price feed
    bytes32 public constant PRICE_FEED = keccak256(abi.encode("PRICE_FEED"));
    // @dev key for price feed multiplier
    bytes32 public constant PRICE_FEED_MULTIPLIER = keccak256(abi.encode("PRICE_FEED_MULTIPLIER"));
    // @dev key for price feed heartbeat
    bytes32 public constant PRICE_FEED_HEARTBEAT_DURATION = keccak256(abi.encode("PRICE_FEED_HEARTBEAT_DURATION"));
    // @dev key for data stream feed id
    bytes32 public constant DATA_STREAM_ID = keccak256(abi.encode("DATA_STREAM_ID"));
    // @dev key for data stream feed multipler
    bytes32 public constant DATA_STREAM_MULTIPLIER = keccak256(abi.encode("DATA_STREAM_MULTIPLIER"));
    // @dev key for stable price
    bytes32 public constant STABLE_PRICE = keccak256(abi.encode("STABLE_PRICE"));
    // @dev key for reserve factor
    bytes32 public constant RESERVE_FACTOR = keccak256(abi.encode("RESERVE_FACTOR"));
    // @dev key for open interest reserve factor
    bytes32 public constant OPEN_INTEREST_RESERVE_FACTOR = keccak256(abi.encode("OPEN_INTEREST_RESERVE_FACTOR"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR = keccak256(abi.encode("MAX_PNL_FACTOR"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR_FOR_TRADERS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_TRADERS"));
    // @dev key for max pnl factor for adl
    bytes32 public constant MAX_PNL_FACTOR_FOR_ADL = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_ADL"));
    // @dev key for min pnl factor for adl
    bytes32 public constant MIN_PNL_FACTOR_AFTER_ADL = keccak256(abi.encode("MIN_PNL_FACTOR_AFTER_ADL"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR_FOR_DEPOSITS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_DEPOSITS"));
    // @dev key for max pnl factor for withdrawals
    bytes32 public constant MAX_PNL_FACTOR_FOR_WITHDRAWALS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS"));
    // @dev key for latest ADL at
    bytes32 public constant LATEST_ADL_AT = keccak256(abi.encode("LATEST_ADL_AT"));
    // @dev key for whether ADL is enabled
    bytes32 public constant IS_ADL_ENABLED = keccak256(abi.encode("IS_ADL_ENABLED"));
    // @dev key for funding factor
    bytes32 public constant FUNDING_FACTOR = keccak256(abi.encode("FUNDING_FACTOR"));
    // @dev key for funding exponent factor
    bytes32 public constant FUNDING_EXPONENT_FACTOR = keccak256(abi.encode("FUNDING_EXPONENT_FACTOR"));
    // @dev key for saved funding factor
    bytes32 public constant SAVED_FUNDING_FACTOR_PER_SECOND = keccak256(abi.encode("SAVED_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for funding increase factor
    bytes32 public constant FUNDING_INCREASE_FACTOR_PER_SECOND = keccak256(abi.encode("FUNDING_INCREASE_FACTOR_PER_SECOND"));
    // @dev key for funding decrease factor
    bytes32 public constant FUNDING_DECREASE_FACTOR_PER_SECOND = keccak256(abi.encode("FUNDING_DECREASE_FACTOR_PER_SECOND"));
    // @dev key for min funding factor
    bytes32 public constant MIN_FUNDING_FACTOR_PER_SECOND = keccak256(abi.encode("MIN_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for max funding factor
    bytes32 public constant MAX_FUNDING_FACTOR_PER_SECOND = keccak256(abi.encode("MAX_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for max funding factor limit
    bytes32 public constant MAX_FUNDING_FACTOR_PER_SECOND_LIMIT = keccak256(abi.encode("MAX_FUNDING_FACTOR_PER_SECOND_LIMIT"));
    // @dev key for threshold for stable funding
    bytes32 public constant THRESHOLD_FOR_STABLE_FUNDING = keccak256(abi.encode("THRESHOLD_FOR_STABLE_FUNDING"));
    // @dev key for threshold for decrease funding
    bytes32 public constant THRESHOLD_FOR_DECREASE_FUNDING = keccak256(abi.encode("THRESHOLD_FOR_DECREASE_FUNDING"));
    // @dev key for funding fee amount per size
    bytes32 public constant FUNDING_FEE_AMOUNT_PER_SIZE = keccak256(abi.encode("FUNDING_FEE_AMOUNT_PER_SIZE"));
    // @dev key for claimable funding amount per size
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT_PER_SIZE = keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT_PER_SIZE"));
    // @dev key for when funding was last updated at
    bytes32 public constant FUNDING_UPDATED_AT = keccak256(abi.encode("FUNDING_UPDATED_AT"));
    // @dev key for claimable funding amount
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT = keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT"));
    // @dev key for claimable collateral amount
    bytes32 public constant CLAIMABLE_COLLATERAL_AMOUNT = keccak256(abi.encode("CLAIMABLE_COLLATERAL_AMOUNT"));
    // @dev key for claimable collateral factor
    bytes32 public constant CLAIMABLE_COLLATERAL_FACTOR = keccak256(abi.encode("CLAIMABLE_COLLATERAL_FACTOR"));
    // @dev key for claimable collateral time divisor
    bytes32 public constant CLAIMABLE_COLLATERAL_TIME_DIVISOR = keccak256(abi.encode("CLAIMABLE_COLLATERAL_TIME_DIVISOR"));
    // @dev key for claimed collateral amount
    bytes32 public constant CLAIMED_COLLATERAL_AMOUNT = keccak256(abi.encode("CLAIMED_COLLATERAL_AMOUNT"));
    // @dev key for optimal usage factor
    bytes32 public constant OPTIMAL_USAGE_FACTOR = keccak256(abi.encode("OPTIMAL_USAGE_FACTOR"));
    // @dev key for base borrowing factor
    bytes32 public constant BASE_BORROWING_FACTOR = keccak256(abi.encode("BASE_BORROWING_FACTOR"));
    // @dev key for above optimal usage borrowing factor
    bytes32 public constant ABOVE_OPTIMAL_USAGE_BORROWING_FACTOR = keccak256(abi.encode("ABOVE_OPTIMAL_USAGE_BORROWING_FACTOR"));
    // @dev key for borrowing factor
    bytes32 public constant BORROWING_FACTOR = keccak256(abi.encode("BORROWING_FACTOR"));
    // @dev key for borrowing factor
    bytes32 public constant BORROWING_EXPONENT_FACTOR = keccak256(abi.encode("BORROWING_EXPONENT_FACTOR"));
    // @dev key for skipping the borrowing factor for the smaller side
    bytes32 public constant SKIP_BORROWING_FEE_FOR_SMALLER_SIDE = keccak256(abi.encode("SKIP_BORROWING_FEE_FOR_SMALLER_SIDE"));
    // @dev key for cumulative borrowing factor
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR = keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR"));
    // @dev key for when the cumulative borrowing factor was last updated at
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR_UPDATED_AT = keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR_UPDATED_AT"));
    // @dev key for total borrowing amount
    bytes32 public constant TOTAL_BORROWING = keccak256(abi.encode("TOTAL_BORROWING"));
    // @dev key for affiliate reward
    bytes32 public constant AFFILIATE_REWARD = keccak256(abi.encode("AFFILIATE_REWARD"));
    // @dev key for max allowed subaccount action count
    bytes32 public constant MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT = keccak256(abi.encode("MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT"));
    // @dev key for subaccount action count
    bytes32 public constant SUBACCOUNT_ACTION_COUNT = keccak256(abi.encode("SUBACCOUNT_ACTION_COUNT"));
    // @dev key for subaccount auto top up amount
    bytes32 public constant SUBACCOUNT_AUTO_TOP_UP_AMOUNT = keccak256(abi.encode("SUBACCOUNT_AUTO_TOP_UP_AMOUNT"));
    // @dev key for subaccount order action
    bytes32 public constant SUBACCOUNT_ORDER_ACTION = keccak256(abi.encode("SUBACCOUNT_ORDER_ACTION"));
    // @dev key for fee distributor swap order token index
    bytes32 public constant FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX = keccak256(abi.encode("FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX"));
    // @dev key for fee distributor swap fee batch
    bytes32 public constant FEE_DISTRIBUTOR_SWAP_FEE_BATCH = keccak256(abi.encode("FEE_DISTRIBUTOR_SWAP_FEE_BATCH"));

    // @dev key for the glv pending shift
    bytes32 public constant GLV_PENDING_SHIFT = keccak256(abi.encode("GLV_PENDING_SHIFT"));
    bytes32 public constant GLV_PENDING_SHIFT_BACKREF = keccak256(abi.encode("GLV_PENDING_SHIFT_BACKREF"));
    // @dev key for the max market token balance usd for glv
    bytes32 public constant GLV_MAX_MARKET_TOKEN_BALANCE_USD = keccak256(abi.encode("GLV_MAX_MARKET_TOKEN_BALANCE_USD"));
    // @dev key for is glv market disabled
    bytes32 public constant IS_GLV_MARKET_DISABLED = keccak256(abi.encode("IS_GLV_MARKET_DISABLED"));

    // @dev constant for user initiated cancel reason
    string public constant USER_INITIATED_CANCEL = "USER_INITIATED_CANCEL";

    // @dev key for the account deposit list
    // @param account the account for the list
    function accountDepositListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_DEPOSIT_LIST, account));
    }

    // @dev key for the account withdrawal list
    // @param account the account for the list
    function accountWithdrawalListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_WITHDRAWAL_LIST, account));
    }

    // @dev key for the account shift list
    // @param account the account for the list
    function accountShiftListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_SHIFT_LIST, account));
    }

    // @dev key for the account glv deposit list
    // @param account the account for the list
    function accountGlvDepositListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_GLV_DEPOSIT_LIST, account));
    }

    // @dev key for the glv supported market list
    // @param glv the glv for the supported market list
    function glvSupportedMarketListKey(address glv) internal pure returns (bytes32) {
        return keccak256(abi.encode(GLV_SUPPORTED_MARKET_LIST, glv));
    }

    // @dev key for the account position list
    // @param account the account for the list
    function accountPositionListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_POSITION_LIST, account));
    }

    // @dev key for the account order list
    // @param account the account for the list
    function accountOrderListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_ORDER_LIST, account));
    }

    // @dev key for the subaccount list
    // @param account the account for the list
    function subaccountListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(SUBACCOUNT_LIST, account));
    }

    // @dev key for the auto cancel order list
    // @param position key the position key for the list
    function autoCancelOrderListKey(bytes32 positionKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(AUTO_CANCEL_ORDER_LIST, positionKey));
    }

    // @dev key for the claimable fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    function claimableFeeAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_FEE_AMOUNT, market, token));
    }

    // @dev key for the claimable ui fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    // @param account the account that can claim the ui fee
    function claimableUiFeeAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_UI_FEE_AMOUNT, market, token));
    }

    // @dev key for the claimable ui fee amount for account
    // @param market the market for the fee
    // @param token the token for the fee
    // @param account the account that can claim the ui fee
    function claimableUiFeeAmountKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_UI_FEE_AMOUNT, market, token, account));
    }

    // @dev key for deposit gas limit
    // @param singleToken whether a single token or pair tokens are being deposited
    // @return key for deposit gas limit
    function depositGasLimitKey(bool singleToken) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            DEPOSIT_GAS_LIMIT,
            singleToken
        ));
    }

    // @dev key for withdrawal gas limit
    // @return key for withdrawal gas limit
    function withdrawalGasLimitKey() internal pure returns (bytes32) {
        return WITHDRAWAL_GAS_LIMIT;
    }

    // @dev key for shift gas limit
    // @return key for shift gas limit
    function shiftGasLimitKey() internal pure returns (bytes32) {
        return SHIFT_GAS_LIMIT;
    }

    function glvDepositGasLimitKey() internal pure returns (bytes32) {
        return GLV_DEPOSIT_GAS_LIMIT;
    }

    function glvPerMarketGasLimitKey() internal pure returns (bytes32) {
        return GLV_PER_MARKET_GAS_LIMIT;
    }

    // @dev key for single swap gas limit
    // @return key for single swap gas limit
    function singleSwapGasLimitKey() internal pure returns (bytes32) {
        return SINGLE_SWAP_GAS_LIMIT;
    }

    // @dev key for increase order gas limit
    // @return key for increase order gas limit
    function increaseOrderGasLimitKey() internal pure returns (bytes32) {
        return INCREASE_ORDER_GAS_LIMIT;
    }

    // @dev key for decrease order gas limit
    // @return key for decrease order gas limit
    function decreaseOrderGasLimitKey() internal pure returns (bytes32) {
        return DECREASE_ORDER_GAS_LIMIT;
    }

    // @dev key for swap order gas limit
    // @return key for swap order gas limit
    function swapOrderGasLimitKey() internal pure returns (bytes32) {
        return SWAP_ORDER_GAS_LIMIT;
    }

    function swapPathMarketFlagKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_PATH_MARKET_FLAG,
            market
        ));
    }

    // @dev key for whether create glv deposit is disabled
    // @param the create deposit module
    // @return key for whether create deposit is disabled
    function createGlvDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_GLV_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether cancel glv deposit is disabled
    // @param the cancel deposit module
    // @return key for whether cancel deposit is disabled
    function cancelGlvDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_GLV_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether execute glv deposit is disabled
    // @param the execute deposit module
    // @return key for whether execute deposit is disabled
    function executeGlvDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_GLV_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether shift deposit is disabled
    // @param the execute deposit module
    // @return key for whether execute deposit is disabled
    function glvShiftFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            GLV_SHIFT_FEATURE_DISABLED,
            module
        ));
    }


    // @dev key for whether create deposit is disabled
    // @param the create deposit module
    // @return key for whether create deposit is disabled
    function createDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether cancel deposit is disabled
    // @param the cancel deposit module
    // @return key for whether cancel deposit is disabled
    function cancelDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether execute deposit is disabled
    // @param the execute deposit module
    // @return key for whether execute deposit is disabled
    function executeDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether create withdrawal is disabled
    // @param the create withdrawal module
    // @return key for whether create withdrawal is disabled
    function createWithdrawalFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_WITHDRAWAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether cancel withdrawal is disabled
    // @param the cancel withdrawal module
    // @return key for whether cancel withdrawal is disabled
    function cancelWithdrawalFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_WITHDRAWAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether execute withdrawal is disabled
    // @param the execute withdrawal module
    // @return key for whether execute withdrawal is disabled
    function executeWithdrawalFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_WITHDRAWAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether execute atomic withdrawal is disabled
    // @param the execute atomic withdrawal module
    // @return key for whether execute atomic withdrawal is disabled
    function executeAtomicWithdrawalFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_ATOMIC_WITHDRAWAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether create shift is disabled
    // @param the create shift module
    // @return key for whether create shift is disabled
    function createShiftFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_SHIFT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether cancel shift is disabled
    // @param the cancel shift module
    // @return key for whether cancel shift is disabled
    function cancelShiftFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_SHIFT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether execute shift is disabled
    // @param the execute shift module
    // @return key for whether execute shift is disabled
    function executeShiftFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_SHIFT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether create order is disabled
    // @param the create order module
    // @return key for whether create order is disabled
    function createOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether execute order is disabled
    // @param the execute order module
    // @return key for whether execute order is disabled
    function executeOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether execute adl is disabled
    // @param the execute adl module
    // @return key for whether execute adl is disabled
    function executeAdlFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_ADL_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether update order is disabled
    // @param the update order module
    // @return key for whether update order is disabled
    function updateOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            UPDATE_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether cancel order is disabled
    // @param the cancel order module
    // @return key for whether cancel order is disabled
    function cancelOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether claim funding fees is disabled
    // @param the claim funding fees module
    function claimFundingFeesFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_FUNDING_FEES_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether claim colltareral is disabled
    // @param the claim funding fees module
    function claimCollateralFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_COLLATERAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether claim affiliate rewards is disabled
    // @param the claim affiliate rewards module
    function claimAffiliateRewardsFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether claim ui fees is disabled
    // @param the claim ui fees module
    function claimUiFeesFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_UI_FEES_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether subaccounts are disabled
    // @param the subaccount module
    function subaccountFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SUBACCOUNT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for ui fee factor
    // @param account the fee receiver account
    // @return key for ui fee factor
    function uiFeeFactorKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            UI_FEE_FACTOR,
            account
        ));
    }

    // @dev key for whether an oracle provider is enabled
    // @param provider the oracle provider
    // @return key for whether an oracle provider is enabled
    function isOracleProviderEnabledKey(address provider) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            IS_ORACLE_PROVIDER_ENABLED,
            provider
        ));
    }

    // @dev key for whether an oracle provider is allowed to be used for atomic actions
    // @param provider the oracle provider
    // @return key for whether an oracle provider is allowed to be used for atomic actions
    function isAtomicOracleProviderKey(address provider) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            IS_ATOMIC_ORACLE_PROVIDER,
            provider
        ));
    }

    // @dev key for oracle timestamp adjustment
    // @param provider the oracle provider
    // @param token the token
    // @return key for oracle timestamp adjustment
    function oracleTimestampAdjustmentKey(address provider, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORACLE_TIMESTAMP_ADJUSTMENT,
            provider,
            token
        ));
    }

    // @dev key for oracle provider for token
    // @param token the token
    // @return key for oracle provider for token
    function oracleProviderForTokenKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORACLE_PROVIDER_FOR_TOKEN,
            token
        ));
    }

    // @dev key for gas to forward for token transfer
    // @param the token to check
    // @return key for gas to forward for token transfer
    function tokenTransferGasLimit(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TOKEN_TRANSFER_GAS_LIMIT,
            token
        ));
   }

   // @dev the default callback contract
   // @param account the user's account
   // @param market the address of the market
   // @param callbackContract the callback contract
   function savedCallbackContract(address account, address market) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           SAVED_CALLBACK_CONTRACT,
           account,
           market
       ));
   }

   // @dev the min collateral factor key
   // @param the market for the min collateral factor
   function minCollateralFactorKey(address market) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           MIN_COLLATERAL_FACTOR,
           market
       ));
   }

   // @dev the min collateral factor for open interest multiplier key
   // @param the market for the factor
   function minCollateralFactorForOpenInterestMultiplierKey(address market, bool isLong) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER,
           market,
           isLong
       ));
   }

   // @dev the key for the virtual token id
   // @param the token to get the virtual id for
   function virtualTokenIdKey(address token) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_TOKEN_ID,
           token
       ));
   }

   // @dev the key for the virtual market id
   // @param the market to get the virtual id for
   function virtualMarketIdKey(address market) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_MARKET_ID,
           market
       ));
   }

   // @dev the key for the virtual inventory for positions
   // @param the virtualTokenId the virtual token id
   function virtualInventoryForPositionsKey(bytes32 virtualTokenId) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_INVENTORY_FOR_POSITIONS,
           virtualTokenId
       ));
   }

   // @dev the key for the virtual inventory for swaps
   // @param the virtualMarketId the virtual market id
   // @param the token to check the inventory for
   function virtualInventoryForSwapsKey(bytes32 virtualMarketId, bool isLongToken) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_INVENTORY_FOR_SWAPS,
           virtualMarketId,
           isLongToken
       ));
   }

    // @dev key for position impact factor
    // @param market the market address to check
    // @param isPositive whether the impact is positive or negative
    // @return key for position impact factor
    function positionImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_FACTOR,
            market,
            isPositive
        ));
   }

    // @dev key for position impact exponent factor
    // @param market the market address to check
    // @return key for position impact exponent factor
    function positionImpactExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_EXPONENT_FACTOR,
            market
        ));
    }

    // @dev key for the max position impact factor
    // @param market the market address to check
    // @return key for the max position impact factor
    function maxPositionImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POSITION_IMPACT_FACTOR,
            market,
            isPositive
        ));
    }

    // @dev key for the max position impact factor for liquidations
    // @param market the market address to check
    // @return key for the max position impact factor
    function maxPositionImpactFactorForLiquidationsKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS,
            market
        ));
    }

    // @dev key for position fee factor
    // @param market the market address to check
    // @param forPositiveImpact whether the fee is for an action that has a positive price impact
    // @return key for position fee factor
    function positionFeeFactorKey(address market, bool forPositiveImpact) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_FEE_FACTOR,
            market,
            forPositiveImpact
        ));
    }

    // @dev key for swap impact factor
    // @param market the market address to check
    // @param isPositive whether the impact is positive or negative
    // @return key for swap impact factor
    function swapImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_FACTOR,
            market,
            isPositive
        ));
    }

    // @dev key for swap impact exponent factor
    // @param market the market address to check
    // @return key for swap impact exponent factor
    function swapImpactExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_EXPONENT_FACTOR,
            market
        ));
    }


    // @dev key for swap fee factor
    // @param market the market address to check
    // @return key for swap fee factor
    function swapFeeFactorKey(address market, bool forPositiveImpact) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_FEE_FACTOR,
            market,
            forPositiveImpact
        ));
    }

    // @dev key for atomic swap fee factor
    // @param market the market address to check
    // @return key for atomic swap fee factor
    function atomicSwapFeeFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ATOMIC_SWAP_FEE_FACTOR,
            market
        ));
    }

    // @dev key for oracle type
    // @param token the token to check
    // @return key for oracle type
    function oracleTypeKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORACLE_TYPE,
            token
        ));
    }

    // @dev key for open interest
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest
    function openInterestKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for open interest in tokens
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest in tokens
    function openInterestInTokensKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST_IN_TOKENS,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for collateral sum for a market
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for collateral sum
    function collateralSumKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            COLLATERAL_SUM,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for amount of tokens in a market's pool
    // @param market the market to check
    // @param token the token to check
    // @return key for amount of tokens in a market's pool
    function poolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POOL_AMOUNT,
            market,
            token
        ));
    }

    // @dev the key for the max amount of pool tokens
    // @param market the market for the pool
    // @param token the token for the pool
    function maxPoolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POOL_AMOUNT,
            market,
            token
        ));
    }

    // @dev the key for the max usd of pool tokens for deposits
    // @param market the market for the pool
    // @param token the token for the pool
    function maxPoolUsdForDepositKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POOL_USD_FOR_DEPOSIT,
            market,
            token
        ));
    }

    // @dev the key for the max open interest
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function maxOpenInterestKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_OPEN_INTEREST,
            market,
            isLong
        ));
    }

    // @dev key for amount of tokens in a market's position impact pool
    // @param market the market to check
    // @return key for amount of tokens in a market's position impact pool
    function positionImpactPoolAmountKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_POOL_AMOUNT,
            market
        ));
    }

    // @dev key for min amount of tokens in a market's position impact pool
    // @param market the market to check
    // @return key for min amount of tokens in a market's position impact pool
    function minPositionImpactPoolAmountKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_POSITION_IMPACT_POOL_AMOUNT,
            market
        ));
    }

    // @dev key for position impact pool distribution rate
    // @param market the market to check
    // @return key for position impact pool distribution rate
    function positionImpactPoolDistributionRateKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_POOL_DISTRIBUTION_RATE,
            market
        ));
    }

    // @dev key for position impact pool distributed at
    // @param market the market to check
    // @return key for position impact pool distributed at
    function positionImpactPoolDistributedAtKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_POOL_DISTRIBUTED_AT,
            market
        ));
    }

    // @dev key for amount of tokens in a market's swap impact pool
    // @param market the market to check
    // @param token the token to check
    // @return key for amount of tokens in a market's swap impact pool
    function swapImpactPoolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_POOL_AMOUNT,
            market,
            token
        ));
    }

    // @dev key for reserve factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for reserve factor
    function reserveFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            RESERVE_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for open interest reserve factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for open interest reserve factor
    function openInterestReserveFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST_RESERVE_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for max pnl factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for max pnl factor
    function maxPnlFactorKey(bytes32 pnlFactorType, address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_PNL_FACTOR,
            pnlFactorType,
            market,
            isLong
        ));
    }

    // @dev the key for min PnL factor after ADL
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function minPnlFactorAfterAdlKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_PNL_FACTOR_AFTER_ADL,
            market,
            isLong
        ));
    }

    // @dev key for latest adl time
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for latest adl time
    function latestAdlAtKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            LATEST_ADL_AT,
            market,
            isLong
        ));
    }

    // @dev key for whether adl is enabled
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for whether adl is enabled
    function isAdlEnabledKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            IS_ADL_ENABLED,
            market,
            isLong
        ));
    }

    // @dev key for funding factor
    // @param market the market to check
    // @return key for funding factor
    function fundingFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_FACTOR,
            market
        ));
    }

    // @dev the key for funding exponent
    // @param market the market for the pool
    function fundingExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_EXPONENT_FACTOR,
            market
        ));
    }

    // @dev the key for saved funding factor
    // @param market the market for the pool
    function savedFundingFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SAVED_FUNDING_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for funding increase factor
    // @param market the market for the pool
    function fundingIncreaseFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_INCREASE_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for funding decrease factor
    // @param market the market for the pool
    function fundingDecreaseFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_DECREASE_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for min funding factor
    // @param market the market for the pool
    function minFundingFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_FUNDING_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for max funding factor
    // @param market the market for the pool
    function maxFundingFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_FUNDING_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for threshold for stable funding
    // @param market the market for the pool
    function thresholdForStableFundingKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            THRESHOLD_FOR_STABLE_FUNDING,
            market
        ));
    }

    // @dev the key for threshold for decreasing funding
    // @param market the market for the pool
    function thresholdForDecreaseFundingKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            THRESHOLD_FOR_DECREASE_FUNDING,
            market
        ));
    }

    // @dev key for funding fee amount per size
    // @param market the market to check
    // @param collateralToken the collateralToken to get the key for
    // @param isLong whether to get the key for the long or short side
    // @return key for funding fee amount per size
    function fundingFeeAmountPerSizeKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_FEE_AMOUNT_PER_SIZE,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for claimabel funding amount per size
    // @param market the market to check
    // @param collateralToken the collateralToken to get the key for
    // @param isLong whether to get the key for the long or short side
    // @return key for claimable funding amount per size
    function claimableFundingAmountPerSizeKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_FUNDING_AMOUNT_PER_SIZE,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for when funding was last updated
    // @param market the market to check
    // @return key for when funding was last updated
    function fundingUpdatedAtKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_UPDATED_AT,
            market
        ));
    }

    // @dev key for claimable funding amount
    // @param market the market to check
    // @param token the token to check
    // @return key for claimable funding amount
    function claimableFundingAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_FUNDING_AMOUNT,
            market,
            token
        ));
    }

    // @dev key for claimable funding amount by account
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @return key for claimable funding amount
    function claimableFundingAmountKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_FUNDING_AMOUNT,
            market,
            token,
            account
        ));
    }

    // @dev key for claimable collateral amount
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_AMOUNT,
            market,
            token
        ));
    }

    // @dev key for claimable collateral amount for a timeKey for an account
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralAmountKey(address market, address token, uint256 timeKey, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_AMOUNT,
            market,
            token,
            timeKey,
            account
        ));
    }

    // @dev key for claimable collateral factor for a timeKey
    // @param market the market to check
    // @param token the token to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralFactorKey(address market, address token, uint256 timeKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_FACTOR,
            market,
            token,
            timeKey
        ));
    }

    // @dev key for claimable collateral factor for a timeKey for an account
    // @param market the market to check
    // @param token the token to check
    // @param timeKey the time key for the claimable amount
    // @param account the account to check
    // @return key for claimable funding amount
    function claimableCollateralFactorKey(address market, address token, uint256 timeKey, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_FACTOR,
            market,
            token,
            timeKey,
            account
        ));
    }

    // @dev key for claimable collateral factor
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimedCollateralAmountKey(address market, address token, uint256 timeKey, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMED_COLLATERAL_AMOUNT,
            market,
            token,
            timeKey,
            account
        ));
    }

    // @dev key for optimal usage factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for optimal usage factor
    function optimalUsageFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPTIMAL_USAGE_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for base borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for base borrowing factor
    function baseBorrowingFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            BASE_BORROWING_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for above optimal usage borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for above optimal usage borrowing factor
    function aboveOptimalUsageBorrowingFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ABOVE_OPTIMAL_USAGE_BORROWING_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for borrowing factor
    function borrowingFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            BORROWING_FACTOR,
            market,
            isLong
        ));
    }

    // @dev the key for borrowing exponent
    // @param market the market for the pool
    // @param isLong whether to get the key for the long or short side
    function borrowingExponentFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            BORROWING_EXPONENT_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for cumulative borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for cumulative borrowing factor
    function cumulativeBorrowingFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CUMULATIVE_BORROWING_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for cumulative borrowing factor updated at
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for cumulative borrowing factor updated at
    function cumulativeBorrowingFactorUpdatedAtKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CUMULATIVE_BORROWING_FACTOR_UPDATED_AT,
            market,
            isLong
        ));
    }

    // @dev key for total borrowing amount
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for total borrowing amount
    function totalBorrowingKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TOTAL_BORROWING,
            market,
            isLong
        ));
    }

    // @dev key for affiliate reward amount
    // @param market the market to check
    // @param token the token to get the key for
    // @param account the account to get the key for
    // @return key for affiliate reward amount
    function affiliateRewardKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            AFFILIATE_REWARD,
            market,
            token
        ));
    }

    function maxAllowedSubaccountActionCountKey(address account, address subaccount, bytes32 actionType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT,
            account,
            subaccount,
            actionType
        ));
    }

    function subaccountActionCountKey(address account, address subaccount, bytes32 actionType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SUBACCOUNT_ACTION_COUNT,
            account,
            subaccount,
            actionType
        ));
    }

    function subaccountAutoTopUpAmountKey(address account, address subaccount) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SUBACCOUNT_AUTO_TOP_UP_AMOUNT,
            account,
            subaccount
        ));
    }

    // @dev key for affiliate reward amount for an account
    // @param market the market to check
    // @param token the token to get the key for
    // @param account the account to get the key for
    // @return key for affiliate reward amount
    function affiliateRewardKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            AFFILIATE_REWARD,
            market,
            token,
            account
        ));
    }

    // @dev key for is market disabled
    // @param market the market to check
    // @return key for is market disabled
    function isMarketDisabledKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            IS_MARKET_DISABLED,
            market
        ));
    }

    // @dev key for min market tokens for first deposit
    // @param market the market to check
    // @return key for min market tokens for first deposit
    function minMarketTokensForFirstDepositKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT,
            market
        ));
    }

    // @dev key for price feed address
    // @param token the token to get the key for
    // @return key for price feed address
    function priceFeedKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED,
            token
        ));
    }

    // @dev key for data stream feed ID
    // @param token the token to get the key for
    // @return key for data stream feed ID
    function dataStreamIdKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            DATA_STREAM_ID,
            token
        ));
    }

    // @dev key for data stream feed multiplier
    // @param token the token to get the key for
    // @return key for data stream feed multiplier
    function dataStreamMultiplierKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            DATA_STREAM_MULTIPLIER,
            token
        ));
    }

    // @dev key for price feed multiplier
    // @param token the token to get the key for
    // @return key for price feed multiplier
    function priceFeedMultiplierKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED_MULTIPLIER,
            token
        ));
    }

    function priceFeedHeartbeatDurationKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED_HEARTBEAT_DURATION,
            token
        ));
    }

    // @dev key for stable price value
    // @param token the token to get the key for
    // @return key for stable price value
    function stablePriceKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            STABLE_PRICE,
            token
        ));
    }

    // @dev key for fee distributor swap token index
    // @param orderKey the swap order key
    // @return key for fee distributor swap token index
    function feeDistributorSwapTokenIndexKey(bytes32 orderKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX,
            orderKey
        ));
    }

    // @dev key for fee distributor swap fee batch key
    // @param orderKey the swap order key
    // @return key for fee distributor swap fee batch key
    function feeDistributorSwapFeeBatchKey(bytes32 orderKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FEE_DISTRIBUTOR_SWAP_FEE_BATCH,
            orderKey
        ));
    }

    // @dev key for glv pending shift
    // @param glv the glv for the pending shift
    function glvPendingShiftKey(address glv) internal pure returns (bytes32) {
        return keccak256(abi.encode(GLV_PENDING_SHIFT, glv));
    }

    function glvPendingShiftBackrefKey(bytes32 shiftKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(GLV_PENDING_SHIFT_BACKREF, shiftKey));
    }

    // @dev key for max market token balance for glv
    // @param glv the glv to check the market token balance for
    // @param market the market to check balance
    function glvMaxMarketTokenBalanceUsdKey(address glv, address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(GLV_MAX_MARKET_TOKEN_BALANCE_USD, glv, market));
    }

    // @dev key for is glv market disabled
    // @param glv the glv to check
    // @param market the market to check
    // @return key for is market disabled
    function isGlvMarketDisabledKey(address glv, address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            IS_GLV_MARKET_DISABLED,
            glv,
            market
        ));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title Deposit
// @dev Struct for deposits
library Deposit {
    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the account depositing liquidity
    // @param receiver the address to send the liquidity tokens to
    // @param callbackContract the callback contract
    // @param uiFeeReceiver the ui fee receiver
    // @param market the market to deposit to
    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

    // @param initialLongTokenAmount the amount of long tokens to deposit
    // @param initialShortTokenAmount the amount of short tokens to deposit
    // @param minMarketTokens the minimum acceptable number of liquidity tokens
    // @param updatedAtBlock the block that the deposit was last updated at
    // sending funds back to the user in case the deposit gets cancelled
    // @param executionFee the execution fee for keepers
    // @param callbackGasLimit the gas limit for the callbackContract
    struct Numbers {
        uint256 initialLongTokenAmount;
        uint256 initialShortTokenAmount;
        uint256 minMarketTokens;
        uint256 updatedAtBlock;
        uint256 updatedAtTime;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    // @param shouldUnwrapNativeToken whether to unwrap the native token when
    struct Flags {
        bool shouldUnwrapNativeToken;
    }

    function account(Props memory props) internal pure returns (address) {
        return props.addresses.account;
    }

    function setAccount(Props memory props, address value) internal pure {
        props.addresses.account = value;
    }

    function receiver(Props memory props) internal pure returns (address) {
        return props.addresses.receiver;
    }

    function setReceiver(Props memory props, address value) internal pure {
        props.addresses.receiver = value;
    }

    function callbackContract(Props memory props) internal pure returns (address) {
        return props.addresses.callbackContract;
    }

    function setCallbackContract(Props memory props, address value) internal pure {
        props.addresses.callbackContract = value;
    }

    function uiFeeReceiver(Props memory props) internal pure returns (address) {
        return props.addresses.uiFeeReceiver;
    }

    function setUiFeeReceiver(Props memory props, address value) internal pure {
        props.addresses.uiFeeReceiver = value;
    }

    function market(Props memory props) internal pure returns (address) {
        return props.addresses.market;
    }

    function setMarket(Props memory props, address value) internal pure {
        props.addresses.market = value;
    }

    function initialLongToken(Props memory props) internal pure returns (address) {
        return props.addresses.initialLongToken;
    }

    function setInitialLongToken(Props memory props, address value) internal pure {
        props.addresses.initialLongToken = value;
    }

    function initialShortToken(Props memory props) internal pure returns (address) {
        return props.addresses.initialShortToken;
    }

    function setInitialShortToken(Props memory props, address value) internal pure {
        props.addresses.initialShortToken = value;
    }

    function longTokenSwapPath(Props memory props) internal pure returns (address[] memory) {
        return props.addresses.longTokenSwapPath;
    }

    function setLongTokenSwapPath(Props memory props, address[] memory value) internal pure {
        props.addresses.longTokenSwapPath = value;
    }

    function shortTokenSwapPath(Props memory props) internal pure returns (address[] memory) {
        return props.addresses.shortTokenSwapPath;
    }

    function setShortTokenSwapPath(Props memory props, address[] memory value) internal pure {
        props.addresses.shortTokenSwapPath = value;
    }

    function initialLongTokenAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.initialLongTokenAmount;
    }

    function setInitialLongTokenAmount(Props memory props, uint256 value) internal pure {
        props.numbers.initialLongTokenAmount = value;
    }

    function initialShortTokenAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.initialShortTokenAmount;
    }

    function setInitialShortTokenAmount(Props memory props, uint256 value) internal pure {
        props.numbers.initialShortTokenAmount = value;
    }

    function minMarketTokens(Props memory props) internal pure returns (uint256) {
        return props.numbers.minMarketTokens;
    }

    function setMinMarketTokens(Props memory props, uint256 value) internal pure {
        props.numbers.minMarketTokens = value;
    }

    function updatedAtBlock(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtBlock;
    }

    function setUpdatedAtBlock(Props memory props, uint256 value) internal pure {
        props.numbers.updatedAtBlock = value;
    }

    function updatedAtTime(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtTime;
    }

    function setUpdatedAtTime(Props memory props, uint256 value) internal pure {
        props.numbers.updatedAtTime = value;
    }

    function executionFee(Props memory props) internal pure returns (uint256) {
        return props.numbers.executionFee;
    }

    function setExecutionFee(Props memory props, uint256 value) internal pure {
        props.numbers.executionFee = value;
    }

    function callbackGasLimit(Props memory props) internal pure returns (uint256) {
        return props.numbers.callbackGasLimit;
    }

    function setCallbackGasLimit(Props memory props, uint256 value) internal pure {
        props.numbers.callbackGasLimit = value;
    }

    function shouldUnwrapNativeToken(Props memory props) internal pure returns (bool) {
        return props.flags.shouldUnwrapNativeToken;
    }

    function setShouldUnwrapNativeToken(Props memory props, bool value) internal pure {
        props.flags.shouldUnwrapNativeToken = value;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Errors {
    // AdlHandler errors
    error AdlNotRequired(int256 pnlToPoolFactor, uint256 maxPnlFactorForAdl);
    error InvalidAdl(int256 nextPnlToPoolFactor, int256 pnlToPoolFactor);
    error PnlOvercorrected(int256 nextPnlToPoolFactor, uint256 minPnlFactorForAdl);

    // AdlUtils errors
    error InvalidSizeDeltaForAdl(uint256 sizeDeltaUsd, uint256 positionSizeInUsd);
    error AdlNotEnabled();

    // AutoCancelUtils errors
    error MaxAutoCancelOrdersExceeded(uint256 count, uint256 maxAutoCancelOrders);

    // Bank errors
    error SelfTransferNotSupported(address receiver);
    error InvalidNativeTokenSender(address msgSender);

    // BaseHandler errors
    error RequestNotYetCancellable(uint256 requestAge, uint256 requestExpirationAge, string requestType);

    // CallbackUtils errors
    error MaxCallbackGasLimitExceeded(uint256 callbackGasLimit, uint256 maxCallbackGasLimit);
    error InsufficientGasLeftForCallback(uint256 gasToBeForwarded, uint256 callbackGasLimit);

    // Config errors
    error InvalidBaseKey(bytes32 baseKey);
    error ConfigValueExceedsAllowedRange(bytes32 baseKey, uint256 value);
    error InvalidClaimableFactor(uint256 value);
    error PriceFeedAlreadyExistsForToken(address token);
    error DataStreamIdAlreadyExistsForToken(address token);
    error MaxFundingFactorPerSecondLimitExceeded(uint256 maxFundingFactorPerSecond, uint256 limit);

    // Timelock errors
    error ActionAlreadySignalled();
    error ActionNotSignalled();
    error SignalTimeNotYetPassed(uint256 signalTime);
    error InvalidTimelockDelay(uint256 timelockDelay);
    error MaxTimelockDelayExceeded(uint256 timelockDelay);
    error InvalidFeeReceiver(address receiver);
    error InvalidOracleSigner(address receiver);

    // GlvDepositStoreUtils errors
    error GlvDepositNotFound(bytes32 key);
    // GlvDepositUtils errors
    error EmptyGlvDepositAmounts();
    error EmptyGlvDeposit();
    // GlvUtils errors
    error EmptyGlv(address glv);
    error GlvUnsupportedMarket(address glv, address market);
    error GlvDisabledMarket(address glv, address market);
    error GlvMaxMarketTokenBalanceExceeded(address glv, address market, uint256 maxMarketTokenBalanceUsd, uint256 marketTokenBalanceUsd);
    error GlvInsufficientMarketTokenBalance(address glv, address market, uint256 marketTokenBalance, uint256 marketTokenAmount);
    error GlvHasPendingShift(address glv);
    error GlvShiftNotFound(bytes32 shiftKey);
    error GlvInvalidReceiver(address glv, address receiver);
    error GlvInvalidCallbackContract(address glvHandler, address callbackContract);
    error GlvMarketAlreadyExists(address glv, address market);
    error InvalidMarketTokenPrice(address market, int256 price);
    // GlvFactory
    error GlvAlreadyExists(address glv);

    // DepositStoreUtils errors
    error DepositNotFound(bytes32 key);

    // DepositUtils errors
    error EmptyDeposit();
    error EmptyDepositAmounts();

    // ExecuteDepositUtils errors
    error MinMarketTokens(uint256 received, uint256 expected);
    error EmptyDepositAmountsAfterSwap();
    error InvalidPoolValueForDeposit(int256 poolValue);
    error InvalidSwapOutputToken(address outputToken, address expectedOutputToken);
    error InvalidReceiverForFirstDeposit(address receiver, address expectedReceiver);
    error InvalidMinMarketTokensForFirstDeposit(uint256 minMarketTokens, uint256 expectedMinMarketTokens);

    // ExternalHandler errors
    error ExternalCallFailed(bytes data);
    error InvalidExternalCallInput(uint256 targetsLength, uint256 dataListLength);
    error InvalidExternalReceiversInput(uint256 refundTokensLength, uint256 refundReceiversLength);
    error InvalidExternalCallTarget(address target);

    // FeeBatchStoreUtils errors
    error FeeBatchNotFound(bytes32 key);

    // FeeDistributor errors
    error InvalidFeeBatchTokenIndex(uint256 tokenIndex, uint256 feeBatchTokensLength);
    error InvalidAmountInForFeeBatch(uint256 amountIn, uint256 remainingAmount);
    error InvalidSwapPathForV1(address[] path, address bridgingToken);

    // GlpMigrator errors
    error InvalidGlpAmount(uint256 totalGlpAmountToRedeem, uint256 totalGlpAmount);
    error InvalidExecutionFeeForMigration(uint256 totalExecutionFee, uint256 msgValue);

    // GlvHandler errors
    error InvalidGlvDepositInitialShortToken(address initialLongToken, address initialShortToken);
    error InvalidGlvDepositSwapPath(uint256 longTokenSwapPathLength, uint256 shortTokenSwapPathLength);
    error MinGlvTokens(uint256 received, uint256 expected);

    // OrderHandler errors
    error OrderNotUpdatable(uint256 orderType);
    error InvalidKeeperForFrozenOrder(address keeper);

    // FeatureUtils errors
    error DisabledFeature(bytes32 key);

    // FeeHandler errors
    error InvalidClaimFeesInput(uint256 marketsLength, uint256 tokensLength);

    // GasUtils errors
    error InsufficientExecutionFee(uint256 minExecutionFee, uint256 executionFee);
    error InsufficientWntAmountForExecutionFee(uint256 wntAmount, uint256 executionFee);
    error InsufficientExecutionGasForErrorHandling(uint256 startingGas, uint256 minHandleErrorGas);
    error InsufficientExecutionGas(uint256 startingGas, uint256 estimatedGasLimit, uint256 minAdditionalGasForExecution);
    error InsufficientHandleExecutionErrorGas(uint256 gas, uint256 minHandleExecutionErrorGas);
    error InsufficientGasForCancellation(uint256 gas, uint256 minHandleExecutionErrorGas);

    // MarketFactory errors
    error MarketAlreadyExists(bytes32 salt, address existingMarketAddress);

    // MarketStoreUtils errors
    error MarketNotFound(address key);

    // MarketUtils errors
    error EmptyMarket();
    error DisabledMarket(address market);
    error MaxSwapPathLengthExceeded(uint256 swapPathLengh, uint256 maxSwapPathLength);
    error InsufficientPoolAmount(uint256 poolAmount, uint256 amount);
    error InsufficientReserve(uint256 reservedUsd, uint256 maxReservedUsd);
    error InsufficientReserveForOpenInterest(uint256 reservedUsd, uint256 maxReservedUsd);
    error UnableToGetOppositeToken(address inputToken, address market);
    error UnexpectedTokenForVirtualInventory(address token, address market);
    error EmptyMarketTokenSupply();
    error InvalidSwapMarket(address market);
    error UnableToGetCachedTokenPrice(address token, address market);
    error CollateralAlreadyClaimed(uint256 adjustedClaimableAmount, uint256 claimedAmount);
    error OpenInterestCannotBeUpdatedForSwapOnlyMarket(address market);
    error MaxOpenInterestExceeded(uint256 openInterest, uint256 maxOpenInterest);
    error MaxPoolAmountExceeded(uint256 poolAmount, uint256 maxPoolAmount);
    error MaxPoolUsdForDepositExceeded(uint256 poolUsd, uint256 maxPoolUsdForDeposit);
    error UnexpectedBorrowingFactor(uint256 positionBorrowingFactor, uint256 cumulativeBorrowingFactor);
    error UnableToGetBorrowingFactorEmptyPoolUsd();
    error UnableToGetFundingFactorEmptyOpenInterest();
    error InvalidPositionMarket(address market);
    error InvalidCollateralTokenForMarket(address market, address token);
    error PnlFactorExceededForLongs(int256 pnlToPoolFactor, uint256 maxPnlFactor);
    error PnlFactorExceededForShorts(int256 pnlToPoolFactor, uint256 maxPnlFactor);
    error InvalidUiFeeFactor(uint256 uiFeeFactor, uint256 maxUiFeeFactor);
    error EmptyAddressInMarketTokenBalanceValidation(address market, address token);
    error InvalidMarketTokenBalance(address market, address token, uint256 balance, uint256 expectedMinBalance);
    error InvalidMarketTokenBalanceForCollateralAmount(address market, address token, uint256 balance, uint256 collateralAmount);
    error InvalidMarketTokenBalanceForClaimableFunding(address market, address token, uint256 balance, uint256 claimableFundingFeeAmount);
    error UnexpectedPoolValue(int256 poolValue);

    // Oracle errors
    error SequencerDown();
    error SequencerGraceDurationNotYetPassed(uint256 timeSinceUp, uint256 sequencerGraceDuration);
    error EmptyValidatedPrices();
    error InvalidOracleProvider(address provider);
    error InvalidOracleProviderForToken(address provider, address expectedProvider);
    error GmEmptySigner(uint256 signerIndex);
    error InvalidOracleSetPricesProvidersParam(uint256 tokensLength, uint256 providersLength);
    error InvalidOracleSetPricesDataParam(uint256 tokensLength, uint256 dataLength);
    error GmInvalidBlockNumber(uint256 minOracleBlockNumber, uint256 currentBlockNumber);
    error GmInvalidMinMaxBlockNumber(uint256 minOracleBlockNumber, uint256 maxOracleBlockNumber);
    error EmptyDataStreamFeedId(address token);
    error InvalidDataStreamFeedId(address token, bytes32 feedId, bytes32 expectedFeedId);
    error InvalidDataStreamBidAsk(address token, int192 bid, int192 ask);
    error InvalidDataStreamPrices(address token, int192 bid, int192 ask);
    error MaxPriceAgeExceeded(uint256 oracleTimestamp, uint256 currentTimestamp);
    error MaxOracleTimestampRangeExceeded(uint256 range, uint256 maxRange);
    error GmMinOracleSigners(uint256 oracleSigners, uint256 minOracleSigners);
    error GmMaxOracleSigners(uint256 oracleSigners, uint256 maxOracleSigners);
    error BlockNumbersNotSorted(uint256 minOracleBlockNumber, uint256 prevMinOracleBlockNumber);
    error GmMinPricesNotSorted(address token, uint256 price, uint256 prevPrice);
    error GmMaxPricesNotSorted(address token, uint256 price, uint256 prevPrice);
    error EmptyChainlinkPriceFeedMultiplier(address token);
    error EmptyDataStreamMultiplier(address token);
    error InvalidFeedPrice(address token, int256 price);
    error ChainlinkPriceFeedNotUpdated(address token, uint256 timestamp, uint256 heartbeatDuration);
    error GmMaxSignerIndex(uint256 signerIndex, uint256 maxSignerIndex);
    error InvalidGmOraclePrice(address token);
    error InvalidGmSignerMinMaxPrice(uint256 minPrice, uint256 maxPrice);
    error InvalidGmMedianMinMaxPrice(uint256 minPrice, uint256 maxPrice);
    error NonEmptyTokensWithPrices(uint256 tokensWithPricesLength);
    error InvalidMinMaxForPrice(address token, uint256 min, uint256 max);
    error EmptyChainlinkPriceFeed(address token);
    error PriceAlreadySet(address token, uint256 minPrice, uint256 maxPrice);
    error MaxRefPriceDeviationExceeded(
        address token,
        uint256 price,
        uint256 refPrice,
        uint256 maxRefPriceDeviationFactor
    );
    error InvalidBlockRangeSet(uint256 largestMinBlockNumber, uint256 smallestMaxBlockNumber);
    error EmptyChainlinkPaymentToken();
    error NonAtomicOracleProvider(address provider);

    // OracleModule errors
    error InvalidPrimaryPricesForSimulation(uint256 primaryTokensLength, uint256 primaryPricesLength);
    error EndOfOracleSimulation();

    // OracleUtils errors
    error InvalidGmSignature(address recoveredSigner, address expectedSigner);

    error EmptyPrimaryPrice(address token);

    error OracleTimestampsAreSmallerThanRequired(uint256 minOracleTimestamp, uint256 expectedTimestamp);
    error OracleTimestampsAreLargerThanRequestExpirationTime(uint256 maxOracleTimestamp, uint256 requestTimestamp, uint256 requestExpirationTime);

    // BaseOrderUtils errors
    error EmptyOrder();
    error UnsupportedOrderType(uint256 orderType);
    error InvalidOrderPrices(
        uint256 primaryPriceMin,
        uint256 primaryPriceMax,
        uint256 triggerPrice,
        uint256 orderType
    );
    error EmptySizeDeltaInTokens();
    error PriceImpactLargerThanOrderSize(int256 priceImpactUsd, uint256 sizeDeltaUsd);
    error NegativeExecutionPrice(int256 executionPrice, uint256 price, uint256 positionSizeInUsd, int256 priceImpactUsd, uint256 sizeDeltaUsd);
    error OrderNotFulfillableAtAcceptablePrice(uint256 price, uint256 acceptablePrice);

    // IncreaseOrderUtils errors
    error UnexpectedPositionState();

    // OrderUtils errors
    error OrderTypeCannotBeCreated(uint256 orderType);
    error OrderAlreadyFrozen();
    error MaxTotalCallbackGasLimitForAutoCancelOrdersExceeded(uint256 totalCallbackGasLimit, uint256 maxTotalCallbackGasLimit);
    error InvalidReceiver(address receiver);

    // OrderStoreUtils errors
    error OrderNotFound(bytes32 key);

    // SwapOrderUtils errors
    error UnexpectedMarket();

    // DecreasePositionCollateralUtils errors
    error InsufficientFundsToPayForCosts(uint256 remainingCostUsd, string step);
    error InvalidOutputToken(address tokenOut, address expectedTokenOut);

    // DecreasePositionUtils errors
    error InvalidDecreaseOrderSize(uint256 sizeDeltaUsd, uint256 positionSizeInUsd);
    error UnableToWithdrawCollateral(int256 estimatedRemainingCollateralUsd);
    error InvalidDecreasePositionSwapType(uint256 decreasePositionSwapType);
    error PositionShouldNotBeLiquidated(
        string reason,
        int256 remainingCollateralUsd,
        int256 minCollateralUsd,
        int256 minCollateralUsdForLeverage
    );

    // IncreasePositionUtils errors
    error InsufficientCollateralAmount(uint256 collateralAmount, int256 collateralDeltaAmount);
    error InsufficientCollateralUsd(int256 remainingCollateralUsd);

    // PositionStoreUtils errors
    error PositionNotFound(bytes32 key);

    // PositionUtils errors
    error LiquidatablePosition(
        string reason,
        int256 remainingCollateralUsd,
        int256 minCollateralUsd,
        int256 minCollateralUsdForLeverage
    );

    error EmptyPosition();
    error InvalidPositionSizeValues(uint256 sizeInUsd, uint256 sizeInTokens);
    error MinPositionSize(uint256 positionSizeInUsd, uint256 minPositionSizeUsd);

    // PositionPricingUtils errors
    error UsdDeltaExceedsLongOpenInterest(int256 usdDelta, uint256 longOpenInterest);
    error UsdDeltaExceedsShortOpenInterest(int256 usdDelta, uint256 shortOpenInterest);

    // ShiftStoreUtils errors
    error ShiftNotFound(bytes32 key);

    // ShiftUtils errors
    error EmptyShift();
    error EmptyShiftAmount();
    error ShiftFromAndToMarketAreEqual(address market);
    error LongTokensAreNotEqual(address fromMarketLongToken, address toMarketLongToken);
    error ShortTokensAreNotEqual(address fromMarketLongToken, address toMarketLongToken);

    // SwapPricingUtils errors
    error UsdDeltaExceedsPoolValue(int256 usdDelta, uint256 poolUsd);

    // RoleModule errors
    error Unauthorized(address msgSender, string role);

    // RoleStore errors
    error ThereMustBeAtLeastOneRoleAdmin();
    error ThereMustBeAtLeastOneTimelockMultiSig();

    // ExchangeRouter errors
    error InvalidClaimFundingFeesInput(uint256 marketsLength, uint256 tokensLength);
    error InvalidClaimCollateralInput(uint256 marketsLength, uint256 tokensLength, uint256 timeKeysLength);
    error InvalidClaimAffiliateRewardsInput(uint256 marketsLength, uint256 tokensLength);
    error InvalidClaimUiFeesInput(uint256 marketsLength, uint256 tokensLength);

    // SwapUtils errors
    error InvalidTokenIn(address tokenIn, address market);
    error InsufficientOutputAmount(uint256 outputAmount, uint256 minOutputAmount);
    error InsufficientSwapOutputAmount(uint256 outputAmount, uint256 minOutputAmount);
    error DuplicatedMarketInSwapPath(address market);
    error SwapPriceImpactExceedsAmountIn(uint256 amountAfterFees, int256 negativeImpactAmount);

    // SubaccountRouter errors
    error InvalidReceiverForSubaccountOrder(address receiver, address expectedReceiver);

    // SubaccountUtils errors
    error SubaccountNotAuthorized(address account, address subaccount);
    error MaxSubaccountActionCountExceeded(address account, address subaccount, uint256 count, uint256 maxCount);

    // TokenUtils errors
    error EmptyTokenTranferGasLimit(address token);
    error TokenTransferError(address token, address receiver, uint256 amount);
    error EmptyHoldingAddress();

    // AccountUtils errors
    error EmptyAccount();
    error EmptyReceiver();

    // Array errors
    error CompactedArrayOutOfBounds(
        uint256[] compactedValues,
        uint256 index,
        uint256 slotIndex,
        string label
    );

    error ArrayOutOfBoundsUint256(
        uint256[] values,
        uint256 index,
        string label
    );

    error ArrayOutOfBoundsBytes(
        bytes[] values,
        uint256 index,
        string label
    );

    // WithdrawalHandler errors
    error SwapsNotAllowedForAtomicWithdrawal(uint256 longTokenSwapPathLength, uint256 shortTokenSwapPathLength);

    // WithdrawalStoreUtils errors
    error WithdrawalNotFound(bytes32 key);

    // WithdrawalUtils errors
    error EmptyWithdrawal();
    error EmptyWithdrawalAmount();
    error MinLongTokens(uint256 received, uint256 expected);
    error MinShortTokens(uint256 received, uint256 expected);
    error InsufficientMarketTokens(uint256 balance, uint256 expected);
    error InsufficientWntAmount(uint256 wntAmount, uint256 executionFee);
    error InvalidPoolValueForWithdrawal(int256 poolValue);

    // Uint256Mask errors
    error MaskIndexOutOfBounds(uint256 index, string label);
    error DuplicatedIndex(uint256 index, string label);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library ErrorUtils {
    // To get the revert reason, referenced from https://ethereum.stackexchange.com/a/83577
    function getRevertMessage(bytes memory result) internal pure returns (string memory, bool) {
        // If the result length is less than 68, then the transaction either panicked or failed silently
        if (result.length < 68) {
            return ("", false);
        }

        bytes4 errorSelector = getErrorSelectorFromData(result);

        // 0x08c379a0 is the selector for Error(string)
        // referenced from https://blog.soliditylang.org/2021/04/21/custom-errors/
        if (errorSelector == bytes4(0x08c379a0)) {
            assembly {
                result := add(result, 0x04)
            }

            return (abi.decode(result, (string)), true);
        }

        // error may be a custom error, return an empty string for this case
        return ("", false);
    }

    function getErrorSelectorFromData(bytes memory data) internal pure returns (bytes4) {
        bytes4 errorSelector;

        assembly {
            errorSelector := mload(add(data, 0x20))
        }

        return errorSelector;
    }

    function revertWithParsedMessage(bytes memory result) internal pure {
        (string memory revertMessage, bool hasRevertMessage) = getRevertMessage(result);

        if (hasRevertMessage) {
            revert(revertMessage);
        } else {
            revertWithCustomError(result);
        }
    }

    function revertWithCustomError(bytes memory result) internal pure {
        // referenced from https://ethereum.stackexchange.com/a/123588
        uint256 length = result.length;
        assembly {
            revert(add(result, 0x20), length)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library EventUtils {
    struct EmitPositionDecreaseParams {
        bytes32 key;
        address account;
        address market;
        address collateralToken;
        bool isLong;
    }

    struct EventLogData {
        AddressItems addressItems;
        UintItems uintItems;
        IntItems intItems;
        BoolItems boolItems;
        Bytes32Items bytes32Items;
        BytesItems bytesItems;
        StringItems stringItems;
    }

    struct AddressItems {
        AddressKeyValue[] items;
        AddressArrayKeyValue[] arrayItems;
    }

    struct UintItems {
        UintKeyValue[] items;
        UintArrayKeyValue[] arrayItems;
    }

    struct IntItems {
        IntKeyValue[] items;
        IntArrayKeyValue[] arrayItems;
    }

    struct BoolItems {
        BoolKeyValue[] items;
        BoolArrayKeyValue[] arrayItems;
    }

    struct Bytes32Items {
        Bytes32KeyValue[] items;
        Bytes32ArrayKeyValue[] arrayItems;
    }

    struct BytesItems {
        BytesKeyValue[] items;
        BytesArrayKeyValue[] arrayItems;
    }

    struct StringItems {
        StringKeyValue[] items;
        StringArrayKeyValue[] arrayItems;
    }

    struct AddressKeyValue {
        string key;
        address value;
    }

    struct AddressArrayKeyValue {
        string key;
        address[] value;
    }

    struct UintKeyValue {
        string key;
        uint256 value;
    }

    struct UintArrayKeyValue {
        string key;
        uint256[] value;
    }

    struct IntKeyValue {
        string key;
        int256 value;
    }

    struct IntArrayKeyValue {
        string key;
        int256[] value;
    }

    struct BoolKeyValue {
        string key;
        bool value;
    }

    struct BoolArrayKeyValue {
        string key;
        bool[] value;
    }

    struct Bytes32KeyValue {
        string key;
        bytes32 value;
    }

    struct Bytes32ArrayKeyValue {
        string key;
        bytes32[] value;
    }

    struct BytesKeyValue {
        string key;
        bytes value;
    }

    struct BytesArrayKeyValue {
        string key;
        bytes[] value;
    }

    struct StringKeyValue {
        string key;
        string value;
    }

    struct StringArrayKeyValue {
        string key;
        string[] value;
    }

    function initItems(AddressItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.AddressKeyValue[](size);
    }

    function initArrayItems(AddressItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.AddressArrayKeyValue[](size);
    }

    function setItem(AddressItems memory items, uint256 index, string memory key, address value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(AddressItems memory items, uint256 index, string memory key, address[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(UintItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.UintKeyValue[](size);
    }

    function initArrayItems(UintItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.UintArrayKeyValue[](size);
    }

    function setItem(UintItems memory items, uint256 index, string memory key, uint256 value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(UintItems memory items, uint256 index, string memory key, uint256[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(IntItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.IntKeyValue[](size);
    }

    function initArrayItems(IntItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.IntArrayKeyValue[](size);
    }

    function setItem(IntItems memory items, uint256 index, string memory key, int256 value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(IntItems memory items, uint256 index, string memory key, int256[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(BoolItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.BoolKeyValue[](size);
    }

    function initArrayItems(BoolItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.BoolArrayKeyValue[](size);
    }

    function setItem(BoolItems memory items, uint256 index, string memory key, bool value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(BoolItems memory items, uint256 index, string memory key, bool[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(Bytes32Items memory items, uint256 size) internal pure {
        items.items = new EventUtils.Bytes32KeyValue[](size);
    }

    function initArrayItems(Bytes32Items memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.Bytes32ArrayKeyValue[](size);
    }

    function setItem(Bytes32Items memory items, uint256 index, string memory key, bytes32 value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(Bytes32Items memory items, uint256 index, string memory key, bytes32[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(BytesItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.BytesKeyValue[](size);
    }

    function initArrayItems(BytesItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.BytesArrayKeyValue[](size);
    }

    function setItem(BytesItems memory items, uint256 index, string memory key, bytes memory value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(BytesItems memory items, uint256 index, string memory key, bytes[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(StringItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.StringKeyValue[](size);
    }

    function initArrayItems(StringItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.StringArrayKeyValue[](size);
    }

    function setItem(StringItems memory items, uint256 index, string memory key, string memory value) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(StringItems memory items, uint256 index, string memory key, string[] memory value) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title GlvDeposit
// @dev Struct for GLV deposits
library GlvDeposit {
    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the account depositing liquidity
    // @param receiver the address to send the liquidity tokens to
    // @param callbackContract the callback contract
    // @param uiFeeReceiver the ui fee receiver
    // @param market the market to deposit to
    struct Addresses {
        address glv;
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

    // @param initialLongTokenAmount the amount of long tokens to deposit
    // @param initialShortTokenAmount the amount of short tokens to deposit
    // @param minGlvTokens the minimum acceptable number of Glv tokens
    // @param updatedAtBlock the block that the deposit was last updated at
    // sending funds back to the user in case the deposit gets cancelled
    // @param executionFee the execution fee for keepers
    // @param callbackGasLimit the gas limit for the callbackContract
    struct Numbers {
        uint256 initialLongTokenAmount;
        uint256 initialShortTokenAmount;
        uint256 minGlvTokens;
        uint256 updatedAtBlock;
        uint256 updatedAtTime;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    // @param shouldUnwrapNativeToken whether to unwrap the native token when
    struct Flags {
        bool shouldUnwrapNativeToken;
    }


    function account(Props memory props) internal pure returns (address) {
        return props.addresses.account;
    }

    function setAccount(Props memory props, address value) internal pure {
        props.addresses.account = value;
    }

    function receiver(Props memory props) internal pure returns (address) {
        return props.addresses.receiver;
    }

    function setReceiver(Props memory props, address value) internal pure {
        props.addresses.receiver = value;
    }

    function callbackContract(Props memory props) internal pure returns (address) {
        return props.addresses.callbackContract;
    }

    function setCallbackContract(Props memory props, address value) internal pure {
        props.addresses.callbackContract = value;
    }

    function uiFeeReceiver(Props memory props) internal pure returns (address) {
        return props.addresses.uiFeeReceiver;
    }

    function setUiFeeReceiver(Props memory props, address value) internal pure {
        props.addresses.uiFeeReceiver = value;
    }

    function glv(Props memory props) internal pure returns (address) {
        return props.addresses.glv;
    }

    function setGlv(Props memory props, address value) internal pure {
        props.addresses.glv = value;
    }

    function market(Props memory props) internal pure returns (address) {
        return props.addresses.market;
    }

    function setMarket(Props memory props, address value) internal pure {
        props.addresses.market = value;
    }

    function initialLongToken(Props memory props) internal pure returns (address) {
        return props.addresses.initialLongToken;
    }

    function setInitialLongToken(Props memory props, address value) internal pure {
        props.addresses.initialLongToken = value;
    }

    function initialShortToken(Props memory props) internal pure returns (address) {
        return props.addresses.initialShortToken;
    }

    function setInitialShortToken(Props memory props, address value) internal pure {
        props.addresses.initialShortToken = value;
    }

    function longTokenSwapPath(Props memory props) internal pure returns (address[] memory) {
        return props.addresses.longTokenSwapPath;
    }

    function setLongTokenSwapPath(Props memory props, address[] memory value) internal pure {
        props.addresses.longTokenSwapPath = value;
    }

    function shortTokenSwapPath(Props memory props) internal pure returns (address[] memory) {
        return props.addresses.shortTokenSwapPath;
    }

    function setShortTokenSwapPath(Props memory props, address[] memory value) internal pure {
        props.addresses.shortTokenSwapPath = value;
    }

    function initialLongTokenAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.initialLongTokenAmount;
    }

    function setInitialLongTokenAmount(Props memory props, uint256 value) internal pure {
        props.numbers.initialLongTokenAmount = value;
    }

    function initialShortTokenAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.initialShortTokenAmount;
    }

    function setInitialShortTokenAmount(Props memory props, uint256 value) internal pure {
        props.numbers.initialShortTokenAmount = value;
    }

    function minGlvTokens(Props memory props) internal pure returns (uint256) {
        return props.numbers.minGlvTokens;
    }

    function setMinGlvTokens(Props memory props, uint256 value) internal pure {
        props.numbers.minGlvTokens = value;
    }

    function updatedAtBlock(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtBlock;
    }

    function setUpdatedAtBlock(Props memory props, uint256 value) internal pure {
        props.numbers.updatedAtBlock = value;
    }

    function updatedAtTime(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtTime;
    }

    function setUpdatedAtTime(Props memory props, uint256 value) internal pure {
        props.numbers.updatedAtTime = value;
    }

    function executionFee(Props memory props) internal pure returns (uint256) {
        return props.numbers.executionFee;
    }

    function setExecutionFee(Props memory props, uint256 value) internal pure {
        props.numbers.executionFee = value;
    }

    function callbackGasLimit(Props memory props) internal pure returns (uint256) {
        return props.numbers.callbackGasLimit;
    }

    function setCallbackGasLimit(Props memory props, uint256 value) internal pure {
        props.numbers.callbackGasLimit = value;
    }

    function shouldUnwrapNativeToken(Props memory props) internal pure returns (bool) {
        return props.flags.shouldUnwrapNativeToken;
    }

    function setShouldUnwrapNativeToken(Props memory props, bool value) internal pure {
        props.flags.shouldUnwrapNativeToken = value;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../chain/Chain.sol";

// @title Order
// @dev Struct for orders
library Order {
    using Order for Props;

    enum OrderType {
        // @dev MarketSwap: swap token A to token B at the current market price
        // the order will be cancelled if the minOutputAmount cannot be fulfilled
        MarketSwap,
        // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // @dev MarketIncrease: increase position at the current market price
        // the order will be cancelled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // @dev MarketDecrease: decrease position at the current market price
        // the order will be cancelled if the position cannot be decreased at the acceptablePrice
        MarketDecrease,
        // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitDecrease,
        // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        StopLossDecrease,
        // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
        Liquidation
    }

    // to help further differentiate orders
    enum SecondaryOrderType {
        None,
        Adl
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the account of the order
    // @param receiver the receiver for any token transfers
    // this field is meant to allow the output of an order to be
    // received by an address that is different from the creator of the
    // order whether this is for swaps or whether the account is the owner
    // of a position
    // for funding fees and claimable collateral, the funds are still
    // credited to the owner of the position indicated by order.account
    // @param callbackContract the contract to call for callbacks
    // @param uiFeeReceiver the ui fee receiver
    // @param market the trading market
    // @param initialCollateralToken for increase orders, initialCollateralToken
    // is the token sent in by the user, the token will be swapped through the
    // specified swapPath, before being deposited into the position as collateral
    // for decrease orders, initialCollateralToken is the collateral token of the position
    // withdrawn collateral from the decrease of the position will be swapped
    // through the specified swapPath
    // for swaps, initialCollateralToken is the initial token sent for the swap
    // @param swapPath an array of market addresses to swap through
    struct Addresses {
        address account;
        address receiver;
        address cancellationReceiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd the requested change in position size
    // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
    // is the amount of the initialCollateralToken sent in by the user
    // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
    // collateralToken to withdraw
    // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
    // in for the swap
    // @param orderType the order type
    // @param triggerPrice the trigger price for non-market orders
    // @param acceptablePrice the acceptable execution price for increase / decrease orders
    // @param executionFee the execution fee for keepers
    // @param callbackGasLimit the gas limit for the callbackContract
    // @param minOutputAmount the minimum output amount for decrease orders and swaps
    // note that for decrease orders, multiple tokens could be received, for this reason, the
    // minOutputAmount value is treated as a USD value for validation in decrease orders
    // @param updatedAtBlock the block at which the order was last updated
    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
        uint256 updatedAtTime;
    }

    // @param isLong whether the order is for a long or short
    // @param shouldUnwrapNativeToken whether to unwrap native tokens before
    // transferring to the user
    // @param isFrozen whether the order is frozen
    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
        bool autoCancel;
    }

    // @dev the order account
    // @param props Props
    // @return the order account
    function account(Props memory props) internal pure returns (address) {
        return props.addresses.account;
    }

    // @dev set the order account
    // @param props Props
    // @param value the value to set to
    function setAccount(Props memory props, address value) internal pure {
        props.addresses.account = value;
    }

    // @dev the order receiver
    // @param props Props
    // @return the order receiver
    function receiver(Props memory props) internal pure returns (address) {
        return props.addresses.receiver;
    }

    // @dev set the order receiver
    // @param props Props
    // @param value the value to set to
    function setReceiver(Props memory props, address value) internal pure {
        props.addresses.receiver = value;
    }

    function cancellationReceiver(Props memory props) internal pure returns (address) {
        return props.addresses.cancellationReceiver;
    }

    function setCancellationReceiver(Props memory props, address value) internal pure {
        props.addresses.cancellationReceiver = value;
    }

    // @dev the order callbackContract
    // @param props Props
    // @return the order callbackContract
    function callbackContract(Props memory props) internal pure returns (address) {
        return props.addresses.callbackContract;
    }

    // @dev set the order callbackContract
    // @param props Props
    // @param value the value to set to
    function setCallbackContract(Props memory props, address value) internal pure {
        props.addresses.callbackContract = value;
    }

    // @dev the order market
    // @param props Props
    // @return the order market
    function market(Props memory props) internal pure returns (address) {
        return props.addresses.market;
    }

    // @dev set the order market
    // @param props Props
    // @param value the value to set to
    function setMarket(Props memory props, address value) internal pure {
        props.addresses.market = value;
    }

    // @dev the order initialCollateralToken
    // @param props Props
    // @return the order initialCollateralToken
    function initialCollateralToken(Props memory props) internal pure returns (address) {
        return props.addresses.initialCollateralToken;
    }

    // @dev set the order initialCollateralToken
    // @param props Props
    // @param value the value to set to
    function setInitialCollateralToken(Props memory props, address value) internal pure {
        props.addresses.initialCollateralToken = value;
    }

    // @dev the order uiFeeReceiver
    // @param props Props
    // @return the order uiFeeReceiver
    function uiFeeReceiver(Props memory props) internal pure returns (address) {
        return props.addresses.uiFeeReceiver;
    }

    // @dev set the order uiFeeReceiver
    // @param props Props
    // @param value the value to set to
    function setUiFeeReceiver(Props memory props, address value) internal pure {
        props.addresses.uiFeeReceiver = value;
    }

    // @dev the order swapPath
    // @param props Props
    // @return the order swapPath
    function swapPath(Props memory props) internal pure returns (address[] memory) {
        return props.addresses.swapPath;
    }

    // @dev set the order swapPath
    // @param props Props
    // @param value the value to set to
    function setSwapPath(Props memory props, address[] memory value) internal pure {
        props.addresses.swapPath = value;
    }

    // @dev the order type
    // @param props Props
    // @return the order type
    function orderType(Props memory props) internal pure returns (OrderType) {
        return props.numbers.orderType;
    }

    // @dev set the order type
    // @param props Props
    // @param value the value to set to
    function setOrderType(Props memory props, OrderType value) internal pure {
        props.numbers.orderType = value;
    }

    function decreasePositionSwapType(Props memory props) internal pure returns (DecreasePositionSwapType) {
        return props.numbers.decreasePositionSwapType;
    }

    function setDecreasePositionSwapType(Props memory props, DecreasePositionSwapType value) internal pure {
        props.numbers.decreasePositionSwapType = value;
    }

    // @dev the order sizeDeltaUsd
    // @param props Props
    // @return the order sizeDeltaUsd
    function sizeDeltaUsd(Props memory props) internal pure returns (uint256) {
        return props.numbers.sizeDeltaUsd;
    }

    // @dev set the order sizeDeltaUsd
    // @param props Props
    // @param value the value to set to
    function setSizeDeltaUsd(Props memory props, uint256 value) internal pure {
        props.numbers.sizeDeltaUsd = value;
    }

    // @dev the order initialCollateralDeltaAmount
    // @param props Props
    // @return the order initialCollateralDeltaAmount
    function initialCollateralDeltaAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.initialCollateralDeltaAmount;
    }

    // @dev set the order initialCollateralDeltaAmount
    // @param props Props
    // @param value the value to set to
    function setInitialCollateralDeltaAmount(Props memory props, uint256 value) internal pure {
        props.numbers.initialCollateralDeltaAmount = value;
    }

    // @dev the order triggerPrice
    // @param props Props
    // @return the order triggerPrice
    function triggerPrice(Props memory props) internal pure returns (uint256) {
        return props.numbers.triggerPrice;
    }

    // @dev set the order triggerPrice
    // @param props Props
    // @param value the value to set to
    function setTriggerPrice(Props memory props, uint256 value) internal pure {
        props.numbers.triggerPrice = value;
    }

    // @dev the order acceptablePrice
    // @param props Props
    // @return the order acceptablePrice
    function acceptablePrice(Props memory props) internal pure returns (uint256) {
        return props.numbers.acceptablePrice;
    }

    // @dev set the order acceptablePrice
    // @param props Props
    // @param value the value to set to
    function setAcceptablePrice(Props memory props, uint256 value) internal pure {
        props.numbers.acceptablePrice = value;
    }

    // @dev set the order executionFee
    // @param props Props
    // @param value the value to set to
    function setExecutionFee(Props memory props, uint256 value) internal pure {
        props.numbers.executionFee = value;
    }

    // @dev the order executionFee
    // @param props Props
    // @return the order executionFee
    function executionFee(Props memory props) internal pure returns (uint256) {
        return props.numbers.executionFee;
    }

    // @dev the order callbackGasLimit
    // @param props Props
    // @return the order callbackGasLimit
    function callbackGasLimit(Props memory props) internal pure returns (uint256) {
        return props.numbers.callbackGasLimit;
    }

    // @dev set the order callbackGasLimit
    // @param props Props
    // @param value the value to set to
    function setCallbackGasLimit(Props memory props, uint256 value) internal pure {
        props.numbers.callbackGasLimit = value;
    }

    // @dev the order minOutputAmount
    // @param props Props
    // @return the order minOutputAmount
    function minOutputAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.minOutputAmount;
    }

    // @dev set the order minOutputAmount
    // @param props Props
    // @param value the value to set to
    function setMinOutputAmount(Props memory props, uint256 value) internal pure {
        props.numbers.minOutputAmount = value;
    }

    // @dev the order updatedAtBlock
    // @param props Props
    // @return the order updatedAtBlock
    function updatedAtBlock(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtBlock;
    }

    // @dev set the order updatedAtBlock
    // @param props Props
    // @param value the value to set to
    function setUpdatedAtBlock(Props memory props, uint256 value) internal pure {
        props.numbers.updatedAtBlock = value;
    }

    // @dev the order updatedAtTime
    // @param props Props
    // @return the order updatedAtTime
    function updatedAtTime(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtTime;
    }

    // @dev set the order updatedAtTime
    // @param props Props
    // @param value the value to set to
    function setUpdatedAtTime(Props memory props, uint256 value) internal pure {
        props.numbers.updatedAtTime = value;
    }

    // @dev whether the order is for a long or short
    // @param props Props
    // @return whether the order is for a long or short
    function isLong(Props memory props) internal pure returns (bool) {
        return props.flags.isLong;
    }

    // @dev set whether the order is for a long or short
    // @param props Props
    // @param value the value to set to
    function setIsLong(Props memory props, bool value) internal pure {
        props.flags.isLong = value;
    }

    // @dev whether to unwrap the native token before transfers to the user
    // @param props Props
    // @return whether to unwrap the native token before transfers to the user
    function shouldUnwrapNativeToken(Props memory props) internal pure returns (bool) {
        return props.flags.shouldUnwrapNativeToken;
    }

    // @dev set whether the native token should be unwrapped before being
    // transferred to the receiver
    // @param props Props
    // @param value the value to set to
    function setShouldUnwrapNativeToken(Props memory props, bool value) internal pure {
        props.flags.shouldUnwrapNativeToken = value;
    }

    // @dev whether the order is frozen
    // @param props Props
    // @return whether the order is frozen
    function isFrozen(Props memory props) internal pure returns (bool) {
        return props.flags.isFrozen;
    }

    // @dev set whether the order is frozen
    // transferred to the receiver
    // @param props Props
    // @param value the value to set to
    function setIsFrozen(Props memory props, bool value) internal pure {
        props.flags.isFrozen = value;
    }

    function autoCancel(Props memory props) internal pure returns (bool) {
        return props.flags.autoCancel;
    }

    function setAutoCancel(Props memory props, bool value) internal pure {
        props.flags.autoCancel = value;
    }

    // @dev set the order.updatedAtBlock to the current block number
    // @param props Props
    function touch(Props memory props) internal view {
        props.setUpdatedAtBlock(Chain.currentBlockNumber());
        props.setUpdatedAtTime(Chain.currentTimestamp());
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title Role
 * @dev Library for role keys
 */
library Role {
    /**
     * @dev The ROLE_ADMIN role.
     * Hash: 0x56908b85b56869d7c69cd020749874f238259af9646ca930287866cdd660b7d9
     */
    bytes32 public constant ROLE_ADMIN = keccak256(abi.encode("ROLE_ADMIN"));

    /**
     * @dev The TIMELOCK_ADMIN role.
     * Hash: 0xf49b0c86b385620e25b0985905d1a112a5f1bc1d51a7a292a8cdf112b3a7c47c
     */
    bytes32 public constant TIMELOCK_ADMIN = keccak256(abi.encode("TIMELOCK_ADMIN"));

    /**
     * @dev The TIMELOCK_MULTISIG role.
     * Hash: 0xe068a8d811c3c8290a8be34607cfa3184b26ffb8dea4dde7a451adfba9fa173a
     */
    bytes32 public constant TIMELOCK_MULTISIG = keccak256(abi.encode("TIMELOCK_MULTISIG"));

    /**
     * @dev The CONFIG_KEEPER role.
     * Hash: 0x901fb3de937a1dcb6ecaf26886fda47a088e74f36232a0673eade97079dc225b
     */
    bytes32 public constant CONFIG_KEEPER = keccak256(abi.encode("CONFIG_KEEPER"));

    /**
     * @dev The LIMITED_CONFIG_KEEPER role.
     * Hash: 0xb49beded4d572a2d32002662fc5c735817329f4337b3a488aab0b5e835c01ba7
     */
    bytes32 public constant LIMITED_CONFIG_KEEPER = keccak256(abi.encode("LIMITED_CONFIG_KEEPER"));

    /**
     * @dev The CONTROLLER role.
     * Hash: 0x97adf037b2472f4a6a9825eff7d2dd45e37f2dc308df2a260d6a72af4189a65b
     */
    bytes32 public constant CONTROLLER = keccak256(abi.encode("CONTROLLER"));

    /**
     * @dev The GOV_TOKEN_CONTROLLER role.
     * Hash: 0x16a157db08319d4eaf6b157a71f5d2e18c6500cab8a25bee0b4f9c753cb13690
     */
    bytes32 public constant GOV_TOKEN_CONTROLLER = keccak256(abi.encode("GOV_TOKEN_CONTROLLER"));

    /**
     * @dev The ROUTER_PLUGIN role.
     * Hash: 0xc82e6cc76072f8edb32d42796e58e13ab6e145524eb6b36c073be82f20d410f3
     */
    bytes32 public constant ROUTER_PLUGIN = keccak256(abi.encode("ROUTER_PLUGIN"));

    /**
     * @dev The MARKET_KEEPER role.
     * Hash: 0xd66692c70b60cf1337e643d6a6473f6865d8c03f3c26b460df3d19b504fb46ae
     */
    bytes32 public constant MARKET_KEEPER = keccak256(abi.encode("MARKET_KEEPER"));

    /**
     * @dev The FEE_KEEPER role.
     * Hash: 0xe0ff4cc0c6ecffab6db3f63ea62dd53f8091919ac57669f1bb3d9828278081d8
     */
    bytes32 public constant FEE_KEEPER = keccak256(abi.encode("FEE_KEEPER"));

    /**
     * @dev The FEE_DISTRIBUTION_KEEPER role.
     * Hash: 0xc23a98a1bf683201c11eeeb8344052ad3bc603c8ddcad06093edc1e8dafa96a2
     */
    bytes32 public constant FEE_DISTRIBUTION_KEEPER = keccak256(abi.encode("FEE_DISTRIBUTION_KEEPER"));

    /**
     * @dev The ORDER_KEEPER role.
     * Hash: 0x40a07f8f0fc57fcf18b093d96362a8e661eaac7b7e6edbf66f242111f83a6794
     */
    bytes32 public constant ORDER_KEEPER = keccak256(abi.encode("ORDER_KEEPER"));

    /**
     * @dev The FROZEN_ORDER_KEEPER role.
     * Hash: 0xcb6c7bc0d25d73c91008af44527b80c56dee4db8965845d926a25659a4a8bc07
     */
    bytes32 public constant FROZEN_ORDER_KEEPER = keccak256(abi.encode("FROZEN_ORDER_KEEPER"));

    /**
     * @dev The PRICING_KEEPER role.
     * Hash: 0x2700e36dc4e6a0daa977bffd4368adbd48f8058da74152919f91f58eddb42103
     */
    bytes32 public constant PRICING_KEEPER = keccak256(abi.encode("PRICING_KEEPER"));
    /**
     * @dev The LIQUIDATION_KEEPER role.
     * Hash: 0x556c788ffc0574ec93966d808c170833d96489c9c58f5bcb3dadf711ba28720e
     */
    bytes32 public constant LIQUIDATION_KEEPER = keccak256(abi.encode("LIQUIDATION_KEEPER"));
    /**
     * @dev The ADL_KEEPER role.
     * Hash: 0xb37d64edaeaf5e634c13682dbd813f5a12fec9eb4f74433a089e7a3c3289af91
     */
    bytes32 public constant ADL_KEEPER = keccak256(abi.encode("ADL_KEEPER"));
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./RoleStore.sol";

/**
 * @title RoleModule
 * @dev Contract for role validation functions
 */
contract RoleModule {
    RoleStore public immutable roleStore;

    /**
     * @dev Constructor that initializes the role store for this contract.
     *
     * @param _roleStore The contract instance to use as the role store.
     */
    constructor(RoleStore _roleStore) {
        roleStore = _roleStore;
    }

    /**
     * @dev Only allows the contract's own address to call the function.
     */
    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert Errors.Unauthorized(msg.sender, "SELF");
        }
        _;
    }

    /**
     * @dev Only allows addresses with the TIMELOCK_MULTISIG role to call the function.
     */
    modifier onlyTimelockMultisig() {
        _validateRole(Role.TIMELOCK_MULTISIG, "TIMELOCK_MULTISIG");
        _;
    }

    /**
     * @dev Only allows addresses with the TIMELOCK_ADMIN role to call the function.
     */
    modifier onlyTimelockAdmin() {
        _validateRole(Role.TIMELOCK_ADMIN, "TIMELOCK_ADMIN");
        _;
    }

    /**
     * @dev Only allows addresses with the CONFIG_KEEPER role to call the function.
     */
    modifier onlyConfigKeeper() {
        _validateRole(Role.CONFIG_KEEPER, "CONFIG_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the CONTROLLER role to call the function.
     */
    modifier onlyController() {
        _validateRole(Role.CONTROLLER, "CONTROLLER");
        _;
    }

    /**
     * @dev Only allows addresses with the GOV_TOKEN_CONTROLLER role to call the function.
     */
    modifier onlyGovTokenController() {
        _validateRole(Role.GOV_TOKEN_CONTROLLER, "GOV_TOKEN_CONTROLLER");
        _;
    }

    /**
     * @dev Only allows addresses with the ROUTER_PLUGIN role to call the function.
     */
    modifier onlyRouterPlugin() {
        _validateRole(Role.ROUTER_PLUGIN, "ROUTER_PLUGIN");
        _;
    }

    /**
     * @dev Only allows addresses with the MARKET_KEEPER role to call the function.
     */
    modifier onlyMarketKeeper() {
        _validateRole(Role.MARKET_KEEPER, "MARKET_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the FEE_KEEPER role to call the function.
     */
    modifier onlyFeeKeeper() {
        _validateRole(Role.FEE_KEEPER, "FEE_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the FEE_DISTRIBUTION_KEEPER role to call the function.
     */
    modifier onlyFeeDistributionKeeper() {
        _validateRole(Role.FEE_DISTRIBUTION_KEEPER, "FEE_DISTRIBUTION_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the ORDER_KEEPER role to call the function.
     */
    modifier onlyOrderKeeper() {
        _validateRole(Role.ORDER_KEEPER, "ORDER_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the PRICING_KEEPER role to call the function.
     */
    modifier onlyPricingKeeper() {
        _validateRole(Role.PRICING_KEEPER, "PRICING_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the LIQUIDATION_KEEPER role to call the function.
     */
    modifier onlyLiquidationKeeper() {
        _validateRole(Role.LIQUIDATION_KEEPER, "LIQUIDATION_KEEPER");
        _;
    }

    /**
     * @dev Only allows addresses with the ADL_KEEPER role to call the function.
     */
    modifier onlyAdlKeeper() {
        _validateRole(Role.ADL_KEEPER, "ADL_KEEPER");
        _;
    }

    /**
     * @dev Validates that the caller has the specified role.
     *
     * If the caller does not have the specified role, the transaction is reverted.
     *
     * @param role The key of the role to validate.
     * @param roleName The name of the role to validate.
     */
    function _validateRole(bytes32 role, string memory roleName) internal view {
        if (!roleStore.hasRole(msg.sender, role)) {
            revert Errors.Unauthorized(msg.sender, roleName);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";
import "./Role.sol";
import "../error/Errors.sol";

/**
 * @title RoleStore
 * @dev Stores roles and their members.
 */
contract RoleStore {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set internal roles;
    mapping(bytes32 => EnumerableSet.AddressSet) internal roleMembers;
    // checking if an account has a role is a frequently used function
    // roleCache helps to save gas by offering a more efficient lookup
    // vs calling roleMembers[key].contains(account)
    mapping(address => mapping (bytes32 => bool)) roleCache;

    modifier onlyRoleAdmin() {
        if (!hasRole(msg.sender, Role.ROLE_ADMIN)) {
            revert Errors.Unauthorized(msg.sender, "ROLE_ADMIN");
        }
        _;
    }

    constructor() {
        _grantRole(msg.sender, Role.ROLE_ADMIN);
    }

    /**
     * @dev Grants the specified role to the given account.
     *
     * @param account The address of the account.
     * @param roleKey The key of the role to grant.
     */
    function grantRole(address account, bytes32 roleKey) external onlyRoleAdmin {
        _grantRole(account, roleKey);
    }

    /**
     * @dev Revokes the specified role from the given account.
     *
     * @param account The address of the account.
     * @param roleKey The key of the role to revoke.
     */
    function revokeRole(address account, bytes32 roleKey) external onlyRoleAdmin {
        _revokeRole(account, roleKey);
    }

    /**
     * @dev Returns true if the given account has the specified role.
     *
     * @param account The address of the account.
     * @param roleKey The key of the role.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(address account, bytes32 roleKey) public view returns (bool) {
        return roleCache[account][roleKey];
    }

    /**
     * @dev Returns the number of roles stored in the contract.
     *
     * @return The number of roles.
     */
    function getRoleCount() external view returns (uint256) {
        return roles.length();
    }

    /**
     * @dev Returns the keys of the roles stored in the contract.
     *
     * @param start The starting index of the range of roles to return.
     * @param end The ending index of the range of roles to return.
     * @return The keys of the roles.
     */
    function getRoles(uint256 start, uint256 end) external view returns (bytes32[] memory) {
        return roles.valuesAt(start, end);
    }

    /**
     * @dev Returns the number of members of the specified role.
     *
     * @param roleKey The key of the role.
     * @return The number of members of the role.
     */
    function getRoleMemberCount(bytes32 roleKey) external view returns (uint256) {
        return roleMembers[roleKey].length();
    }

    /**
     * @dev Returns the members of the specified role.
     *
     * @param roleKey The key of the role.
     * @param start the start index, the value for this index will be included.
     * @param end the end index, the value for this index will not be included.
     * @return The members of the role.
     */
    function getRoleMembers(bytes32 roleKey, uint256 start, uint256 end) external view returns (address[] memory) {
        return roleMembers[roleKey].valuesAt(start, end);
    }

    function _grantRole(address account, bytes32 roleKey) internal {
        roles.add(roleKey);
        roleMembers[roleKey].add(account);
        roleCache[account][roleKey] = true;
    }

    function _revokeRole(address account, bytes32 roleKey) internal {
        roleMembers[roleKey].remove(account);
        roleCache[account][roleKey] = false;

        if (roleMembers[roleKey].length() == 0) {
            if (roleKey == Role.ROLE_ADMIN) {
                revert Errors.ThereMustBeAtLeastOneRoleAdmin();
            }
            if (roleKey == Role.TIMELOCK_MULTISIG) {
                revert Errors.ThereMustBeAtLeastOneTimelockMultiSig();
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Shift {
    struct Props {
        Addresses addresses;
        Numbers numbers;
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address fromMarket;
        address toMarket;
    }

    struct Numbers {
        uint256 marketTokenAmount;
        uint256 minMarketTokens;
        uint256 updatedAtTime;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    function account(Props memory props) internal pure returns (address) {
        return props.addresses.account;
    }

    function setAccount(Props memory props, address value) internal pure {
        props.addresses.account = value;
    }

    function receiver(Props memory props) internal pure returns (address) {
        return props.addresses.receiver;
    }

    function setReceiver(Props memory props, address value) internal pure {
        props.addresses.receiver = value;
    }

    function callbackContract(Props memory props) internal pure returns (address) {
        return props.addresses.callbackContract;
    }

    function setCallbackContract(Props memory props, address value) internal pure {
        props.addresses.callbackContract = value;
    }

    function uiFeeReceiver(Props memory props) internal pure returns (address) {
        return props.addresses.uiFeeReceiver;
    }

    function setUiFeeReceiver(Props memory props, address value) internal pure {
        props.addresses.uiFeeReceiver = value;
    }

    function fromMarket(Props memory props) internal pure returns (address) {
        return props.addresses.fromMarket;
    }

    function setFromMarket(Props memory props, address value) internal pure {
        props.addresses.fromMarket = value;
    }

    function toMarket(Props memory props) internal pure returns (address) {
        return props.addresses.toMarket;
    }

    function setToMarket(Props memory props, address value) internal pure {
        props.addresses.toMarket = value;
    }

    function marketTokenAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.marketTokenAmount;
    }

    function setMarketTokenAmount(Props memory props, uint256 value) internal pure {
        props.numbers.marketTokenAmount = value;
    }

    function minMarketTokens(Props memory props) internal pure returns (uint256) {
        return props.numbers.minMarketTokens;
    }

    function setMinMarketTokens(Props memory props, uint256 value) internal pure {
        props.numbers.minMarketTokens = value;
    }

    function updatedAtTime(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtTime;
    }

    function setUpdatedAtTime(Props memory props, uint256 value) internal pure {
        props.numbers.updatedAtTime = value;
    }

    function executionFee(Props memory props) internal pure returns (uint256) {
        return props.numbers.executionFee;
    }

    function setExecutionFee(Props memory props, uint256 value) internal pure {
        props.numbers.executionFee = value;
    }

    function callbackGasLimit(Props memory props) internal pure returns (uint256) {
        return props.numbers.callbackGasLimit;
    }

    function setCallbackGasLimit(Props memory props, uint256 value) internal pure {
        props.numbers.callbackGasLimit = value;
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title Calc
 * @dev Library for math functions
 */
library Calc {
    using SignedMath for int256;
    using SafeCast for uint256;

    // this method assumes that min is less than max
    function boundMagnitude(int256 value, uint256 min, uint256 max) internal pure returns (int256) {
        uint256 magnitude = value.abs();

        if (magnitude < min) {
            magnitude = min;
        }

        if (magnitude > max) {
            magnitude = max;
        }

        int256 sign = value == 0 ? int256(1) : value / value.abs().toInt256();

        return magnitude.toInt256() * sign;
    }

    /**
     * @dev Calculates the result of dividing the first number by the second number,
     * rounded up to the nearest integer.
     *
     * @param a the dividend
     * @param b the divisor
     * @return the result of dividing the first number by the second number, rounded up to the nearest integer
     */
    function roundUpDivision(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    /**
     * Calculates the result of dividing the first number by the second number,
     * rounded up to the nearest integer.
     * The rounding is purely on the magnitude of a, if a is negative the result
     * is a larger magnitude negative
     *
     * @param a the dividend
     * @param b the divisor
     * @return the result of dividing the first number by the second number, rounded up to the nearest integer
     */
    function roundUpMagnitudeDivision(int256 a, uint256 b) internal pure returns (int256) {
        if (a < 0) {
            return (a - b.toInt256() + 1) / b.toInt256();
        }

        return (a + b.toInt256() - 1) / b.toInt256();
    }

    /**
     * Adds two numbers together and return a uint256 value, treating the second number as a signed integer.
     *
     * @param a the first number
     * @param b the second number
     * @return the result of adding the two numbers together
     */
    function sumReturnUint256(uint256 a, int256 b) internal pure returns (uint256) {
        if (b > 0) {
            return a + b.abs();
        }

        return a - b.abs();
    }

    /**
     * Adds two numbers together and return an int256 value, treating the second number as a signed integer.
     *
     * @param a the first number
     * @param b the second number
     * @return the result of adding the two numbers together
     */
    function sumReturnInt256(uint256 a, int256 b) internal pure returns (int256) {
        return a.toInt256() + b;
    }

    /**
     * @dev Calculates the absolute difference between two numbers.
     *
     * @param a the first number
     * @param b the second number
     * @return the absolute difference between the two numbers
     */
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    /**
     * Adds two numbers together, the result is bounded to prevent overflows.
     *
     * @param a the first number
     * @param b the second number
     * @return the result of adding the two numbers together
     */
    function boundedAdd(int256 a, int256 b) internal pure returns (int256) {
        // if either a or b is zero or if the signs are different there should not be any overflows
        if (a == 0 || b == 0 || (a < 0 && b > 0) || (a > 0 && b < 0)) {
            return a + b;
        }

        // if adding `b` to `a` would result in a value less than the min int256 value
        // then return the min int256 value
        if (a < 0 && b <= type(int256).min - a) {
            return type(int256).min;
        }

        // if adding `b` to `a` would result in a value more than the max int256 value
        // then return the max int256 value
        if (a > 0 && b >= type(int256).max - a) {
            return type(int256).max;
        }

        return a + b;
    }

    /**
     * Returns a - b, the result is bounded to prevent overflows.
     * Note that this will revert if b is type(int256).min because of the usage of "-b".
     *
     * @param a the first number
     * @param b the second number
     * @return the bounded result of a - b
     */
    function boundedSub(int256 a, int256 b) internal pure returns (int256) {
        // if either a or b is zero or the signs are the same there should not be any overflow
        if (a == 0 || b == 0 || (a > 0 && b > 0) || (a < 0 && b < 0)) {
            return a - b;
        }

        // if adding `-b` to `a` would result in a value greater than the max int256 value
        // then return the max int256 value
        if (a > 0 && -b >= type(int256).max - a) {
            return type(int256).max;
        }

        // if subtracting `b` from `a` would result in a value less than the min int256 value
        // then return the min int256 value
        if (a < 0 && -b <= type(int256).min - a) {
            return type(int256).min;
        }

        return a - b;
    }


    /**
     * Converts the given unsigned integer to a signed integer, using the given
     * flag to determine whether the result should be positive or negative.
     *
     * @param a the unsigned integer to convert
     * @param isPositive whether the result should be positive (if true) or negative (if false)
     * @return the signed integer representation of the given unsigned integer
     */
    function toSigned(uint256 a, bool isPositive) internal pure returns (int256) {
        if (isPositive) {
            return a.toInt256();
        } else {
            return -a.toInt256();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title EnumerableValues
 * @dev Library to extend the EnumerableSet library with functions to get
 * valuesAt for a range
 */
library EnumerableValues {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * Returns an array of bytes32 values from the given set, starting at the given
     * start index and ending before the given end index.
     *
     * @param set The set to get the values from.
     * @param start The starting index.
     * @param end The ending index.
     * @return An array of bytes32 values.
     */
    function valuesAt(EnumerableSet.Bytes32Set storage set, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        bytes32[] memory items = new bytes32[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    /**
     * Returns an array of address values from the given set, starting at the given
     * start index and ending before the given end index.
     *
     * @param set The set to get the values from.
     * @param start The starting index.
     * @param end The ending index.
     * @return An array of address values.
     */
    function valuesAt(EnumerableSet.AddressSet storage set, uint256 start, uint256 end) internal view returns (address[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        address[] memory items = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    /**
     * Returns an array of uint256 values from the given set, starting at the given
     * start index and ending before the given end index, the item at the end index will not be returned.
     *
     * @param set The set to get the values from.
     * @param start The starting index (inclusive, item at the start index will be returned).
     * @param end The ending index (exclusive, item at the end index will not be returned).
     * @return An array of uint256 values.
     */
    function valuesAt(EnumerableSet.UintSet storage set, uint256 start, uint256 end) internal view returns (uint256[] memory) {
        if (start >= set.length()) {
            return new uint256[](0);
        }

        uint256 max = set.length();
        if (end > max) { end = max; }

        uint256[] memory items = new uint256[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "hardhat/console.sol";

/**
 * @title Printer
 * @dev Library for console functions
 */
library Printer {
    using SafeCast for int256;

    function log(string memory str) external pure {
        console.log(str);
    }

    function log(string memory label, int256 value) internal pure {
        if (value < 0) {
            console.log(
                "%s -%s",
                label,
                (-value).toUint256()
            );
        } else {
            console.log(
                "%s +%s",
                label,
                value.toUint256()
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title Withdrawal
 * @dev Struct for withdrawals
 */
library Withdrawal {
    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

     // @param account The account to withdraw for.
     // @param receiver The address that will receive the withdrawn tokens.
     // @param callbackContract The contract that will be called back.
     // @param uiFeeReceiver The ui fee receiver.
     // @param market The market on which the withdrawal will be executed.
    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

     // @param marketTokenAmount The amount of market tokens that will be withdrawn.
     // @param minLongTokenAmount The minimum amount of long tokens that must be withdrawn.
     // @param minShortTokenAmount The minimum amount of short tokens that must be withdrawn.
     // @param updatedAtBlock The block at which the withdrawal was last updated.
     // @param executionFee The execution fee for the withdrawal.
     // @param callbackGasLimit The gas limit for calling the callback contract.
    struct Numbers {
        uint256 marketTokenAmount;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        uint256 updatedAtBlock;
        uint256 updatedAtTime;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    // @param shouldUnwrapNativeToken whether to unwrap the native token when
    struct Flags {
        bool shouldUnwrapNativeToken;
    }

    function account(Props memory props) internal pure returns (address) {
        return props.addresses.account;
    }

    function setAccount(Props memory props, address value) internal pure {
        props.addresses.account = value;
    }

    function receiver(Props memory props) internal pure returns (address) {
        return props.addresses.receiver;
    }

    function setReceiver(Props memory props, address value) internal pure {
        props.addresses.receiver = value;
    }

    function callbackContract(Props memory props) internal pure returns (address) {
        return props.addresses.callbackContract;
    }

    function setCallbackContract(Props memory props, address value) internal pure {
        props.addresses.callbackContract = value;
    }

    function uiFeeReceiver(Props memory props) internal pure returns (address) {
        return props.addresses.uiFeeReceiver;
    }

    function setUiFeeReceiver(Props memory props, address value) internal pure {
        props.addresses.uiFeeReceiver = value;
    }

    function market(Props memory props) internal pure returns (address) {
        return props.addresses.market;
    }

    function setMarket(Props memory props, address value) internal pure {
        props.addresses.market = value;
    }

    function longTokenSwapPath(Props memory props) internal pure returns (address[] memory) {
        return props.addresses.longTokenSwapPath;
    }

    function setLongTokenSwapPath(Props memory props, address[] memory value) internal pure {
        props.addresses.longTokenSwapPath = value;
    }

    function shortTokenSwapPath(Props memory props) internal pure returns (address[] memory) {
        return props.addresses.shortTokenSwapPath;
    }

    function setShortTokenSwapPath(Props memory props, address[] memory value) internal pure {
        props.addresses.shortTokenSwapPath = value;
    }

    function marketTokenAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.marketTokenAmount;
    }

    function setMarketTokenAmount(Props memory props, uint256 value) internal pure {
        props.numbers.marketTokenAmount = value;
    }

    function minLongTokenAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.minLongTokenAmount;
    }

    function setMinLongTokenAmount(Props memory props, uint256 value) internal pure {
        props.numbers.minLongTokenAmount = value;
    }

    function minShortTokenAmount(Props memory props) internal pure returns (uint256) {
        return props.numbers.minShortTokenAmount;
    }

    function setMinShortTokenAmount(Props memory props, uint256 value) internal pure {
        props.numbers.minShortTokenAmount = value;
    }

    function updatedAtBlock(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtBlock;
    }

    function setUpdatedAtBlock(Props memory props, uint256 value) internal pure {
        props.numbers.updatedAtBlock = value;
    }

    function updatedAtTime(Props memory props) internal pure returns (uint256) {
        return props.numbers.updatedAtTime;
    }

    function setUpdatedAtTime(Props memory props, uint256 value) internal pure {
        props.numbers.updatedAtTime = value;
    }

    function executionFee(Props memory props) internal pure returns (uint256) {
        return props.numbers.executionFee;
    }

    function setExecutionFee(Props memory props, uint256 value) internal pure {
        props.numbers.executionFee = value;
    }

    function callbackGasLimit(Props memory props) internal pure returns (uint256) {
        return props.numbers.callbackGasLimit;
    }

    function setCallbackGasLimit(Props memory props, uint256 value) internal pure {
        props.numbers.callbackGasLimit = value;
    }

    function shouldUnwrapNativeToken(Props memory props) internal pure returns (bool) {
        return props.flags.shouldUnwrapNativeToken;
    }

    function setShouldUnwrapNativeToken(Props memory props, bool value) internal pure {
        props.flags.shouldUnwrapNativeToken = value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS =
        0x000000000000000000636F6e736F6c652e6c6f67;

    function _sendLogPayloadImplementation(bytes memory payload) internal view {
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            pop(
                staticcall(
                    gas(),
                    consoleAddress,
                    add(payload, 32),
                    mload(payload),
                    0,
                    0
                )
            )
        }
    }

    function _castToPure(
      function(bytes memory) internal view fnIn
    ) internal pure returns (function(bytes memory) pure fnOut) {
        assembly {
            fnOut := fnIn
        }
    }

    function _sendLogPayload(bytes memory payload) internal pure {
        _castToPure(_sendLogPayloadImplementation)(payload);
    }

    function log() internal pure {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }
    function logInt(int256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}