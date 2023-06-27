// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
pragma solidity ^0.8.13;

interface IVeArtProxy {
    function _tokenURI(uint _tokenId, uint _balanceOf, uint _locked_end, uint _value) external view returns (string memory output);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {Base64} from "contracts/libraries/Base64.sol";
import {IVeArtProxy} from "contracts/interfaces/IVeArtProxy.sol";

contract VeArtProxy is IVeArtProxy, Initializable {
    function initialize() external initializer {}

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function decimalString(
        uint256 number,
        uint8 decimals,
        bool isPercent
    ) private pure returns (string memory) {
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;

        uint256 temp = number;
        uint8 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params;
        params.isPercent = isPercent;
        if ((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if (tenPowDecimals > number) {
                // number is less tahn one
                // in this case, there may be leading zeros after the decimal place
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return generateDecimalString(params);
    }

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function generateDecimalString(
        DecimalStringParams memory params
    ) private pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = "%";
        }
        if (params.isLessThanOne) {
            buffer[0] = "0";
            buffer[1] = ".";
        }

        // add leading/trailing 0's
        for (
            uint256 zerosCursor = params.zerosStartIndex;
            zerosCursor < params.zerosEndIndex;
            zerosCursor++
        ) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (
                params.decimalIndex > 0 &&
                params.sigfigIndex == params.decimalIndex
            ) {
                buffer[--params.sigfigIndex] = ".";
            }
            buffer[--params.sigfigIndex] = bytes1(
                uint8(uint256(48) + (params.sigfigs % 10))
            );
            params.sigfigs /= 10;
        }
        return string(buffer);
    }

    function _tokenURI(
        uint256 _tokenId,
        uint256 _balanceOf,
        uint256 _locked_end,
        uint256 _value
    ) external view returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" image-rendering="optimizeQuality" fill-rule="evenodd" xmlns:v="https://vecta.io/nano" viewBox="0 0 387 476"> <defs> <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%"> <stop offset="0%" style="stop-color: #14171b"/> <stop offset="20%" style="stop-color: #1b272e"/> <stop offset="56%" style="stop-color: #273945"/> <stop offset="75%" style="stop-color: #253542"/> <stop offset="100%" style="stop-color: #151719"/> </linearGradient> </defs> <defs></defs> <style>.venft{width: 96px; height: 108px; fill: #0000ff y: 51px; x: 136px;}</style> <style>.vr{font-family: Arial; font-style: normal; font-weight: 400; fill: #EADABF;}</style> <style>.label{fill: #477988; font-family: Arial; font-style: normal; font-weight: 350; font-size: 16px;}</style> <style>.amount{fill: #B0DBE5; font-family: Arial; font-style: normal; font-weight: 350; font-size: 24px;}</style> <style>.app{fill: #EADABF; font-family: Arial; font-style: normal; font-weight: 350; font-size: 14px;}</style><svg width="387" height="476" viewBox="0 0 387 476" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M0 16C0 7.16344 7.16344 0 16 0H371C379.837 0 387 7.16344 387 16V263H0V16Z" fill="url(#gg2)"/><path d="M0 263H387V460C387 468.837 379.837 476 371 476H16C7.16345 476 0 468.837 0 460V263Z" fill="#15171B"/><defs><linearGradient id="gg2" x1="0" y1="0" x2="373.573" y2="280.859" gradientUnits="userSpaceOnUse"><stop stop-color="#14171B"/><stop offset="0.382158" stop-color="#1B272E"/><stop offset="0.566492" stop-color="#273945"/><stop offset="0.711953" stop-color="#253542"/><stop offset="1" stop-color="#151719"/></linearGradient></defs></svg><text y="240" x="50%" dominant-baseline="middle" text-anchor="middle" class="vr" font-size="24px" > veRAM #';

        uint256 duration = 0;
        if (_locked_end > block.timestamp) {
            duration = _locked_end - block.timestamp;
        }

        output = string(
            abi.encodePacked(
                output,
                decimalString(_tokenId, 0, false),
                '</text> <text y="308" x="16" dominant-baseline="middle" class="label" fill="#477988" > RAM Locked </text> <text y="308" x="370" dominant-baseline="middle" text-anchor="end" class="amount" >',
                decimalString(_value / 1e16, 2, false),
                '</text> <text y="356" x="16" dominant-baseline="middle" class="label" fill="#477988" > veRAM Power </text> <text y="356" x="370" dominant-baseline="middle" text-anchor="end" class="amount">',
                decimalString(_balanceOf / 1e16, 2, false),
                '</text> <text y="404" x="16" dominant-baseline="middle" class="label" fill="#477988" > Expires: </text> <text y="404" x="370" dominant-baseline="middle" text-anchor="end" class="amount" >',
                decimalString(duration / 8640, 1, false),
                ' days </text> <text y="458" x="50%" dominant-baseline="middle" text-anchor="middle" class="app" > Ramses.Exchange </text> <g fill="none"><g opacity="0.3"><path fill-rule="evenodd" clip-rule="evenodd" d="M191.433 40.5469C192.715 39.8177 194.285 39.8177 195.567 40.5469L257.876 75.978C259.189 76.7244 260 78.1207 260 79.6339V150.366C260 151.879 259.189 153.276 257.876 154.022L195.567 189.453C194.285 190.182 192.715 190.182 191.433 189.453L129.124 154.022C127.811 153.276 127 151.879 127 150.366V79.6339C127 78.1207 127.811 76.7244 129.124 75.978L191.433 40.5469ZM194.534 42.3749L256.842 77.8059C257.499 78.1791 257.904 78.8773 257.904 79.6339V150.366C257.904 151.123 257.499 151.821 256.842 152.194L194.534 187.625C193.893 187.99 193.107 187.99 192.466 187.625L130.158 152.194C129.501 151.821 129.096 151.123 129.096 150.366V79.6339C129.096 78.8773 129.501 78.1791 130.158 77.8059L192.466 42.3749C193.107 42.0102 193.893 42.0102 194.534 42.3749Z" fill="url(#paint0_linear_250_8457)"/><path fill-rule="evenodd" clip-rule="evenodd" d="M191.435 22.5423C192.717 21.8192 194.283 21.8192 195.565 22.5423L274.36 66.9817C275.682 67.7274 276.5 69.1282 276.5 70.6468V159.353C276.5 160.872 275.682 162.273 274.36 163.018L195.565 207.458C194.283 208.181 192.717 208.181 191.435 207.458L112.64 163.018C111.318 162.273 110.5 160.872 110.5 159.353V70.6468C110.5 69.1282 111.318 67.7274 112.64 66.9817L191.435 22.5423ZM194.533 24.3748L273.327 68.8143C273.988 69.1871 274.397 69.8875 274.397 70.6468V159.353C274.397 160.113 273.988 160.813 273.327 161.186L194.533 205.625C193.892 205.987 193.108 205.987 192.467 205.625L113.673 161.186C113.012 160.813 112.603 160.113 112.603 159.353V70.6468C112.603 69.8875 113.012 69.1871 113.673 68.8142L192.467 24.3748C193.108 24.0133 193.892 24.0133 194.533 24.3748Z" fill="url(#paint1_linear_250_8457)"/><path fill-rule="evenodd" clip-rule="evenodd" d="M94 0H92V14H0V16H92V213H0V215H92V263H94V215H293V263H295V215H387V213H295V16H387V14H295V0H293V14H94V0ZM293 213V199H279V213H293ZM277 213V197H293V31H277V16H110V31H94V197H110V213H277ZM108 213V199H94V213H108ZM293 16V29H279V16H293ZM94 16V29H108V16H94Z" fill="url(#paint2_linear_250_8457)"/></g><path d="M198.361 59.7641L240.425 83.2949C242.925 84.6931 244.473 87.3332 244.473 90.1971V136.803C244.473 139.667 242.925 142.307 240.425 143.705L198.361 167.236C195.962 168.578 193.038 168.578 190.639 167.236L148.575 143.705C146.075 142.307 144.527 139.667 144.527 136.803V90.1971C144.527 87.3332 146.075 84.6931 148.575 83.2949L190.639 59.7641C193.038 58.422 195.962 58.422 198.361 59.7641Z" fill="url(#paint3_linear_250_8457)" stroke="#EADABF" stroke-width="1.0545"/><path d="M191.258 105.962L188.841 88.4825C189.613 88.44 190.409 88.4083 191.229 88.3887L193.66 105.962H191.258Z" fill="#EADABF"/><path d="M181.45 89.2922L187.619 105.962H190.153L183.852 88.9353C183.013 89.0431 182.213 89.1631 181.45 89.2922Z" fill="#EADABF"/><path d="M176.327 90.4186C175.462 90.6574 174.681 90.9005 173.984 91.1379L183.115 105.962H185.901L176.327 90.4186Z" fill="#EADABF"/><path d="M197.22 88.4654L194.8 105.962H197.201L199.6 88.6189C198.827 88.5573 198.033 88.5056 197.22 88.4654Z" fill="#EADABF"/><path d="M200.786 105.962H198.252L204.469 89.1628C205.298 89.2827 206.095 89.4125 206.86 89.5493L200.786 105.962Z" fill="#EADABF"/><path d="M202.4 105.962H205.187L214.217 91.3009C213.5 91.0828 212.707 90.8577 211.842 90.6337L202.4 105.962Z" fill="#EADABF"/><path d="M169.238 94.646L169.913 92.6762L171.452 94.646H169.238Z" fill="#EADABF"/><path d="M176.362 100.927L174.521 98.5714H167.894L167.087 100.927H176.362Z" fill="#EADABF"/><path d="M179.977 105.551L180.138 107.207H164.936L165.743 104.852H179.43L179.977 105.551Z" fill="#EADABF"/><path d="M180.751 113.488L180.521 111.133H163.592L162.786 113.488H180.751Z" fill="#EADABF"/><path d="M181.133 117.414L181.363 119.769H160.635L161.441 117.414H181.133Z" fill="#EADABF"/><path d="M181.975 126.05L181.746 123.694H159.29L158.484 126.05H181.975Z" fill="#EADABF"/><path d="M182.358 129.975L182.588 132.33H157.502L156.625 131.477L157.14 129.975H182.358Z" fill="#EADABF"/><path d="M161.539 136.256L163.961 138.611H183.2L182.971 136.256H161.539Z" fill="#EADABF"/><path d="M219.762 94.6461L219.087 92.6763L217.548 94.6461H219.762Z" fill="#EADABF"/><path d="M212.638 100.927L214.479 98.5715H221.106L221.913 100.927H212.638Z" fill="#EADABF"/><path d="M209.023 105.551L208.862 107.208H224.064L223.257 104.852H209.57L209.023 105.551Z" fill="#EADABF"/><path d="M208.249 113.488L208.479 111.133H225.408L226.214 113.488H208.249Z" fill="#EADABF"/><path d="M207.867 117.414L207.637 119.769H228.365L227.559 117.414H207.867Z" fill="#EADABF"/><path d="M207.025 126.05L207.254 123.694H229.71L230.516 126.05H207.025Z" fill="#EADABF"/><path d="M206.642 129.975L206.412 132.33H231.498L232.375 131.478L231.86 129.975H206.642Z" fill="#EADABF"/><path d="M227.461 136.256L225.039 138.611H205.8L206.029 136.256H227.461Z" fill="#EADABF"/><defs><linearGradient id="paint0_linear_250_8457" x1="-177.657" y1="-37.8352" x2="-124.857" y2="366.557" gradientUnits="userSpaceOnUse"><stop stop-color="#202B33" stop-opacity="0.75"/><stop offset="0.5" stop-color="#344E60"/><stop offset="1" stop-color="#323D45" stop-opacity="0"/></linearGradient><linearGradient id="paint1_linear_250_8457" x1="-177.657" y1="-37.8352" x2="-124.857" y2="366.557" gradientUnits="userSpaceOnUse"><stop stop-color="#202B33" stop-opacity="0.75"/><stop offset="0.5" stop-color="#344E60"/><stop offset="1" stop-color="#323D45" stop-opacity="0"/></linearGradient><linearGradient id="paint2_linear_250_8457" x1="-177.657" y1="-37.8352" x2="-124.857" y2="366.557" gradientUnits="userSpaceOnUse"><stop stop-color="#202B33" stop-opacity="0.75"/><stop offset="0.5" stop-color="#344E60"/><stop offset="1" stop-color="#323D45" stop-opacity="0"/></linearGradient><linearGradient id="paint3_linear_250_8457" x1="144" y1="112.506" x2="245.002" y2="112.757" gradientUnits="userSpaceOnUse"><stop stop-color="#14171B"/><stop offset="0.489583" stop-color="#1B272E"/><stop offset="1" stop-color="#151719"/></linearGradient></defs></g> </svg>'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "lock #',
                        decimalString(_tokenId, 0, false),
                        '", "description": "Ramses locks, can be used to boost gauge yields, vote on token emission, and receive bribes", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
    }
}