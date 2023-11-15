// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVeArtProxy {
    function _tokenURI(uint _tokenId, uint _balanceOf, uint _locked_end, uint _value) external view returns (string memory output);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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
pragma solidity 0.8.13;

import {Base64} from "./libraries/Base64.sol";
import {IVeArtProxy} from "./interfaces/IVeArtProxy.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract VeArtProxyUpgradeable is IVeArtProxy, OwnableUpgradeable {


    constructor() {}

    function initialize() initializer public {
        __Ownable_init();
    }


    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
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
            // no decimals, ensure we preserve all trailing horizas
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing horizas for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if (tenPowDecimals > number) {
                // number is less tahn one
                // in this case, there may be leading horizas after the decimal place
                // that need to be added

                // offset leading horizas by two to account for leading '0.'
                params.horizasStartIndex = 2;
                params.horizasEndIndex = decimals - digits + 2;
                params.sigfigIndex = numSigfigs + params.horizasEndIndex;
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
        uint8 horizasStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 horizasEndIndex;
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
            uint256 horizasCursor = params.horizasStartIndex;
            horizasCursor < params.horizasEndIndex;
            horizasCursor++
        ) {
            buffer[horizasCursor] = bytes1(uint8(48));
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

    /*function _tokenURI(uint _tokenId, uint _balanceOf, uint _locked_end, uint _value) external pure returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        output = string(abi.encodePacked(output, "token ", toString(_tokenId), '</text><text x="10" y="40" class="base">'));
        output = string(abi.encodePacked(output, "balanceOf ", toString(_balanceOf), '</text><text x="10" y="60" class="base">'));
        output = string(abi.encodePacked(output, "locked_end ", toString(_locked_end), '</text><text x="10" y="80" class="base">'));
        output = string(abi.encodePacked(output, "value ", toString(_value), '</text></svg>'));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "lock #', toString(_tokenId), '", "description": "Horiza locks, can be used to boost gauge yields, vote on token emission, and receive bribes", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }*/

    function _tokenURI(
        uint256 _tokenId,
        uint256 _balanceOf,
        uint256 _locked_end,
        uint256 _value
    ) external view returns (string memory output) {
        output = '<svg version="1.2" baseProfile="tiny" id="coin_1_" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 1920 1920" overflow="visible" xml:space="preserve"><linearGradient id="SVGID_1_" gradientUnits="userSpaceOnUse" x1="0" y1="960" x2="1920" y2="960"><stop  offset="4.848288e-07" style="stop-color:#383538"/><stop  offset="1" style="stop-color:#000000"/></linearGradient><rect fill="url(#SVGID_1_)" width="1920" height="1920"/><g id="orange_rectangles"><rect x="108.38" y="611.47" fill="#C97800" width="183.11" height="3.62"/><rect x="290.91" y="1164.54" fill="#C97800" width="225" height="3.62"/><rect x="1391.61" y="896.73" fill="#C97800" width="183.11" height="3.62"/><rect x="1034.49" y="108.98" fill="#C97800" width="300" height="3.62"/><rect x="115.83" y="148.57" fill="#C97800" width="300" height="3.62"/><rect x="1544.86" y="1287.68" fill="#C97800" width="175" height="3.62"/><rect x="273.27" y="634.42" fill="#FFFFFF" width="120" height="3.62"/><rect x="1502.43" y="210.72" fill="#FFFFFF" width="120" height="3.62"/><rect x="1255.74" y="1263.09" fill="#FFFFFF" width="300" height="3.62"/><rect x="199.81" y="1182.49" fill="#FFFFFF" width="120" height="3.62"/></g><g id="static_blocks"><rect x="110.43" y="968.15" fill="#625B63" width="64.91" height="13.89"/><rect x="183.64" y="968.15" fill="#625B63" width="19.17" height="13.89"/><rect x="216.7" y="968.15" fill="#625B63" width="37.31" height="13.89"/><rect x="277.6" y="968.15" fill="#625B63" width="13.89" height="13.89"/><rect x="79.34" y="982.04" fill="#625B63" width="64.91" height="13.89"/><rect x="236.51" y="982.04" fill="#625B63" width="46.6" height="13.89"/><rect x="298.04" y="982.04" fill="#625B63" width="26.38" height="13.89"/><rect x="202.81" y="982.04" fill="#625B63" width="13.89" height="13.89"/><rect x="144.25" y="518.94" fill="#625B63" width="147.24" height="21.89"/><rect x="313.96" y="518.94" fill="#625B63" width="41.74" height="21.89"/><rect x="391.91" y="518.94" fill="#625B63" width="51.99" height="21.89"/><rect x="467.6" y="518.94" fill="#625B63" width="21.89" height="21.89"/><rect x="183.64" y="540.83" fill="#625B63" width="70.37" height="21.89"/><rect x="443.9" y="540.83" fill="#625B63" width="23.7" height="21.89"/><rect x="488.4" y="540.83" fill="#625B63" width="91.37" height="21.89"/><rect x="291.49" y="540.83" fill="#625B63" width="83.56" height="21.89"/><rect x="1631.07" y="161.32" fill="#625B63" width="91.37" height="21.89"/><rect x="1434.16" y="161.32" fill="#625B63" width="83.56" height="21.89"/><rect x="1373.41" y="960.15" fill="#625B63" width="147.24" height="21.89"/><rect x="1543.12" y="960.15" fill="#625B63" width="41.74" height="21.89"/><rect x="1621.07" y="960.15" fill="#625B63" width="51.99" height="21.89"/><rect x="1696.76" y="960.15" fill="#625B63" width="21.89" height="21.89"/><rect x="1412.8" y="982.04" fill="#625B63" width="70.37" height="21.89"/><rect x="1673.06" y="982.04" fill="#625B63" width="23.7" height="21.89"/><rect x="1717.56" y="982.04" fill="#625B63" width="91.37" height="21.89"/><rect x="1520.65" y="982.04" fill="#625B63" width="83.56" height="21.89"/><rect x="1286.92" y="139.43" fill="#625B63" width="147.24" height="21.89"/><rect x="1456.63" y="139.43" fill="#625B63" width="41.74" height="21.89"/><rect x="1534.58" y="139.43" fill="#625B63" width="51.99" height="21.89"/><rect x="1610.27" y="139.43" fill="#625B63" width="21.89" height="21.89"/><rect x="1326.31" y="161.32" fill="#625B63" width="70.37" height="21.89"/><rect x="1586.57" y="161.32" fill="#625B63" width="23.7" height="21.89"/><rect x="1631" y="651.5" fill="#625B63" width="64.91" height="13.89"/><rect x="1704.2" y="651.5" fill="#625B63" width="19.17" height="13.89"/><rect x="1737.26" y="651.5" fill="#625B63" width="37.31" height="13.89"/><rect x="1798.17" y="651.5" fill="#625B63" width="13.89" height="13.89"/><rect x="1599.9" y="665.39" fill="#625B63" width="64.91" height="13.89"/><rect x="1757.08" y="665.39" fill="#625B63" width="46.6" height="13.89"/><rect x="1818.6" y="665.39" fill="#625B63" width="26.38" height="13.89"/><rect x="1723.37" y="665.39" fill="#625B63" width="13.89" height="13.89"/><rect x="290.91" y="169.32" fill="#625B63" width="64.91" height="13.89"/><rect x="364.12" y="169.32" fill="#625B63" width="19.17" height="13.89"/><rect x="397.17" y="169.32" fill="#625B63" width="37.31" height="13.89"/><rect x="458.08" y="169.32" fill="#625B63" width="13.89" height="13.89"/><rect x="259.81" y="183.21" fill="#625B63" width="64.91" height="13.89"/><rect x="416.99" y="183.21" fill="#625B63" width="46.6" height="13.89"/><rect x="478.51" y="183.21" fill="#625B63" width="26.38" height="13.89"/><rect x="383.28" y="183.21" fill="#625B63" width="13.89" height="13.89"/></g><g id="Layer_1_xA0_Image_1_"><polygon fill="#B74100" points="579.55,1248.43 579.55,1277.19 632.98,1334 630.02,1241.36 "/><linearGradient id="yellow_coin_1_" gradientUnits="userSpaceOnUse" x1="492.1509" y1="731" x2="1477" y2="731"><stop  offset="4.795011e-07" style="stop-color:#EF7D00"/><stop offset="0.5" style="stop-color:#F4C400"/><stop offset="1" style="stop-color:#EF7D00"/></linearGradient><polyline id="yellow_coin" fill="url(#yellow_coin_1_)" points="535.4,1255.85 629.81,1241.81 633,1334 1382.64,1204.45 1383.55,1129.51 1444.45,1120.45 1477,326.42 1412.08,319.85 1415.02,233.81 592.68,128 596.3,237.43 492.15,228.38"/><polyline fill="#B74100" points="443.9,267.67 443.9,267.67 492.1,228.3 535.6,1255.85 487.78,1206.52 443.9,267.67"/><polygon fill="#B74100" points="539.47,173.13 540.6,232.68 595.85,237.21 592.91,129.21"/></g><linearGradient id="inside_gradient_1_" gradientUnits="userSpaceOnUse" x1="701.7358" y1="743.9245" x2="1341.2075" y2="743.9245"><stop offset="0" style="stop-color:#993A00"/><stop offset="0.5" style="stop-color:#F4A700"/><stop offset="1" style="stop-color:#993A00"/></linearGradient><polygon id="inside_gradient" fill="url(#inside_gradient_1_)" points="1274.3,397.28 793.96,362.11 794.72,462.34 701.74,458.72 716.38,1044.83 804.83,1036.38 806.34,1125.74 1259.36,1070.3 1260.49,989.92 1327.28,983.92 1341.21,488.75 1272.49,485.92"/><path id="R_shadows_3_" fill="#B74216" d="M1223.55,784l-56.91-5.66c0,0-25.66,28.75-62.87,28.91s50.42,24.38,50.42,24.38l60.3-25.13L1223.55,784"/><path id="R_shadows_1_" fill="#B74216" d="M1062.04,641.66c0,0,32.15,15.85,32.15,45.89s-29.62,50.57-42.43,59.92c-12.81,9.36,57.53-1.21,57.53-1.21l34.87-42.72l-13.28-50.11l-30.79-17.21"/><polyline id="R_shadows" fill="#B74216" points="870,520 843.17,524.23 848,941.43 875.77,949.43 "/><path id="R_shadows_2_" fill="#B74216" d="M1005.77,815.58c0,0,45.96,121.13,120,110.04c74.04-11.09-18.91-29.32-18.91-29.32l-56.26-55.02l-27.96-63.62l-18.79,3.17L1005.77,815.58z"/><polygon id="inside_shadow" fill="#CB6A00" points="1237.4,1073.25 1237.4,984.83 1303.96,979 1314.15,491.36 1248.38,488.87 1249.17,395.92 1274.3,397.28 1272.49,485.92 1341.21,488.75 1327.28,983.92 1260.49,989.92 1259.36,1070.3 "/><path fill="#11100E" d="M1223.55,784c-80.6,71.55-141.89-6.34-141.89-6.34l7.25-11.77c82.11,8.75,143.7-24.75,143.4-119.25s-92.08-114.42-92.08-114.42L870,520l5.77,429.43l130.72-9.96L1008,784.6l10.26-1.21c71.25,226.42,215.25,131.62,215.25,131.62L1223.55,784z M1008,716.98v-71.85h86.64c40.75,16,29.28,51.32,29.28,51.32C1098.26,773.74,1008,716.98,1008,716.98z"/><g id="brackets"><polyline fill="none" stroke="#FFFFFF" stroke-miterlimit="10" points="211.47,51.95 46.08,51.95 46.08,1360 211.47,1360"/><polyline fill="none" stroke="#FFFFFF" stroke-miterlimit="10" points="1708.53,51.95 1873.92,51.95 1873.92,1360 1708.53,1360"/></g><text y="1440" x="50%" fill="white" dominant-baseline="middle" text-anchor="middle" class="vr" font-size="85px"> veHoriza #';

        uint256 duration = 0;
        if (_locked_end > block.timestamp) {
            duration = _locked_end - block.timestamp;
        }

        output = string(
            abi.encodePacked(
                output,
                decimalString(_tokenId, 0, false),
                '</text> <text font-size="80px" fill="white" y="1560" x="16" dominant-baseline="middle" class="label" > Horiza Locked: </text> <text font-size="80px" y="1560" fill="white" x="1870" dominant-baseline="middle" text-anchor="end" class="amount" >',
                decimalString(_value / 1e16, 2, false),
                '</text> <text font-size="80px" fill="white" y="1680" x="16" dominant-baseline="middle" class="label"> veHoriza Power: </text> <text font-size="80px" fill="white" y="1680" x="1870" dominant-baseline="middle" text-anchor="end" class="amount">',
                decimalString(_balanceOf / 1e16, 2, false),
                '</text> <text font-size="80px"  fill="white" y="1800" x="16" dominant-baseline="middle" class="label" > Expires: </text> <text font-size="80px" fill="white" y="1800" x="1870" dominant-baseline="middle" text-anchor="end" class="amount" >',
                decimalString(duration / 8640, 1, false),
                ' days </text> <text fill="white" y="1858" x="50%" font-size="45px" dominant-baseline="middle" text-anchor="middle" class="app" > horiza.io </text></svg>'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "lock #',
                        decimalString(_tokenId, 0, false),
                        '", "description": "Horiza locks, can be used to boost gauge yields, vote on token emissions, and receive bribes", "image": "data:image/svg+xml;base64,',
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