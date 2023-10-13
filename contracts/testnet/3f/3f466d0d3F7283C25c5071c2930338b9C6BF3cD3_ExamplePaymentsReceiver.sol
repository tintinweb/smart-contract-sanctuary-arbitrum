// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";
import { InitializableStorage } from "./InitializableStorage.sol";

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
        bool isTopLevelCall = !InitializableStorage.layout()._initializing;
        require(
            (isTopLevelCall && InitializableStorage.layout()._initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && InitializableStorage.layout()._initialized == 1),
            "Initializable: contract is already initialized"
        );
        InitializableStorage.layout()._initialized = 1;
        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = false;
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
        require(!InitializableStorage.layout()._initializing && InitializableStorage.layout()._initialized < version, "Initializable: contract is already initialized");
        InitializableStorage.layout()._initialized = version;
        InitializableStorage.layout()._initializing = true;
        _;
        InitializableStorage.layout()._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(InitializableStorage.layout()._initializing, "Initializable: contract is not initializing");
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
        require(!InitializableStorage.layout()._initializing, "Initializable: contract is initializing");
        if (InitializableStorage.layout()._initialized < type(uint8).max) {
            InitializableStorage.layout()._initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return InitializableStorage.layout()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return InitializableStorage.layout()._initializing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { Initializable } from "./Initializable.sol";

library InitializableStorage {

  struct Layout {
    /*
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 _initialized;

    /*
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool _initializing;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.Initializable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { PausableUpgradeable } from "./PausableUpgradeable.sol";

library PausableStorage {

  struct Layout {

    bool _paused;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.Pausable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import { PausableStorage } from "./PausableStorage.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    using PausableStorage for PausableStorage.Layout;
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage.layout()._paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return PausableStorage.layout()._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout()._paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage.layout()._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Info related to a specific organization. Think of organizations as systems/games. i.e. Bridgeworld, The Beacon, etc.
 * @param guildIdCur The next available guild id within this organization for newly created guilds
 * @param creationRule Describes who can create a guild within this organization
 * @param maxGuildsPerUser The number of guilds a user can join within the organization.
 * @param timeoutAfterLeavingGuild The timeout a user has before joining a new guild after being kicked or leaving another guild
 * @param tokenAddress The address of the 1155 token that represents guilds created within this organization
 * @param maxUsersPerGuildRule Indicates how the max number of users per guild is decided
 * @param maxUsersPerGuildConstant If maxUsersPerGuildRule is set to CONSTANT, this is the max
 * @param customGuildManagerAddress A contract address that handles custom guild creation requirements (i.e owning specific NFTs).
 *  This is used for guild creation if @param creationRule == CUSTOM_RULE
 */
struct GuildOrganizationInfo {
    uint32 guildIdCur;
    GuildCreationRule creationRule;
    uint8 maxGuildsPerUser;
    uint32 timeoutAfterLeavingGuild;
    // Slot 4 (202/256)
    address tokenAddress;
    MaxUsersPerGuildRule maxUsersPerGuildRule;
    uint32 maxUsersPerGuildConstant;
    bool requireTreasureTagForGuilds;
    // Slot 5 (160/256) - customGuildManagerAddress
    address customGuildManagerAddress;
}

/**
 * @dev Contains information about a user at the organization user.
 * @param guildsIdsAMemberOf A list of guild ids they are currently a member/admin/owner of. Excludes invitations
 * @param timeUserLeftGuild The time this user last left or was kicked from a guild. Useful for guild joining timeouts
 */
struct GuildOrganizationUserInfo {
    // Slot 1
    uint32[] guildIdsAMemberOf;
    // Slot 2 (64/256)
    uint64 timeUserLeftGuild;
}

/**
 * @dev Information about a guild within a given organization.
 * @param name The name of this guild
 * @param description A description of this guild
 * @param symbolImageData A symbol that represents this guild
 * @param isSymbolOnChain Indicates if symbolImageData is on chain or is a URL
 * @param currentOwner The current owner of this guild
 * @param usersInGuild Keeps track of the number of users in the guild. This includes MEMBER, ADMIN, and OWNER
 * @param guildStatus Current guild status (active or terminated)
 */
struct GuildInfo {
    // Slot 1
    string name;
    // Slot 2
    string description;
    // Slot 3
    string symbolImageData;
    // Slot 4 (168/256)
    bool isSymbolOnChain;
    address currentOwner;
    uint32 usersInGuild;
    // Slot 5
    mapping(address => GuildUserInfo) addressToGuildUserInfo;
    // Slot 6 (8/256)
    GuildStatus guildStatus;
}

/**
 * @dev Provides information regarding a user in a specific guild
 * @param userStatus Indicates the status of this user (i.e member, admin, invited)
 * @param timeUserJoined The time this user joined this guild
 * @param memberLevel The member level of this user
 */
struct GuildUserInfo {
    // Slot 1 (8+64+8/256)
    GuildUserStatus userStatus;
    uint64 timeUserJoined;
    uint8 memberLevel;
}

enum GuildUserStatus {
    NOT_ASSOCIATED,
    INVITED,
    MEMBER,
    ADMIN,
    OWNER
}

enum GuildCreationRule {
    ANYONE,
    ADMIN_ONLY,
    CUSTOM_RULE
}

enum MaxUsersPerGuildRule {
    CONSTANT,
    CUSTOM_RULE
}

enum GuildStatus {
    ACTIVE,
    TERMINATED
}

interface IGuildManager {
    /**
     * @dev Sets all necessary state and permissions for the contract
     * @param _guildTokenImplementationAddress The token implementation address for guild token contracts to proxy to
     */
    function GuildManager_init(address _guildTokenImplementationAddress) external;

    /**
     * @dev Creates a new guild within the given organization. Must pass the guild creation requirements.
     * @param _organizationId The organization to create the guild within
     */
    function createGuild(bytes32 _organizationId) external;

    /**
     * @dev Terminates a provided guild
     * @param _organizationId The organization of the guild
     * @param _guildId The guild to terminate
     * @param _reason The reason of termination for the guild
     */
    function terminateGuild(bytes32 _organizationId, uint32 _guildId, string calldata _reason) external;

    /**
     * @dev Grants a given user guild terminator priviliges under a certain guild
     * @param _account The user to give terminator
     * @param _organizationId The org they belong to
     * @param _guildId The guild they belong to
     */
    function grantGuildTerminator(address _account, bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Grants a given user guild admin priviliges under a certain guild
     * @param _account The user to give admin
     * @param _organizationId The org they belong to
     * @param _guildId The guild they belong to
     */
    function grantGuildAdmin(address _account, bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Updates the guild info for the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to update
     * @param _name The new name of the guild
     * @param _description The new description of the guild
     */
    function updateGuildInfo(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _name,
        string calldata _description
    ) external;

    /**
     * @dev Updates the guild symbol for the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to update
     * @param _symbolImageData The new symbol for the guild
     * @param _isSymbolOnChain Indicates if symbolImageData is on chain or is a URL
     */
    function updateGuildSymbol(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _symbolImageData,
        bool _isSymbolOnChain
    ) external;

    /**
     * @dev Adjusts a given users member level
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild the user is in
     * @param _user The user to adjust
     * @param _memberLevel The memberLevel to adjust to
     */
    function adjustMemberLevel(bytes32 _organizationId, uint32 _guildId, address _user, uint8 _memberLevel) external;

    /**
     * @dev Invites users to the given guild. Can only be done by admins or the guild owner.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to invite users to
     * @param _users The users to invite
     */
    function inviteUsers(bytes32 _organizationId, uint32 _guildId, address[] calldata _users) external;

    /**
     * @dev Accepts an invitation to the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to accept the invitation to
     */
    function acceptInvitation(bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Changes the admin status of the given users within the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to change the admin status of users within
     * @param _users The users to change the admin status of
     * @param _isAdmins Indicates if the users should be admins or not
     */
    function changeGuildAdmins(
        bytes32 _organizationId,
        uint32 _guildId,
        address[] calldata _users,
        bool[] calldata _isAdmins
    ) external;

    /**
     * @dev Changes the owner of the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to change the owner of
     * @param _newOwner The new owner of the guild
     */
    function changeGuildOwner(bytes32 _organizationId, uint32 _guildId, address _newOwner) external;

    /**
     * @dev Leaves the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to leave
     */
    function leaveGuild(bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Kicks or cancels any invites of the given users from the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to kick users from
     * @param _users The users to kick
     */
    function kickOrRemoveInvitations(bytes32 _organizationId, uint32 _guildId, address[] calldata _users) external;

    /**
     * @dev Returns the current status of a guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to get the status of
     */
    function getGuildStatus(bytes32 _organizationId, uint32 _guildId) external view returns (GuildStatus);

    /**
     * @dev Returns whether or not the given user can create a guild within the given organization.
     * @param _organizationId The organization to check
     * @param _user The user to check
     * @return Whether or not the user can create a guild within the given organization
     */
    function userCanCreateGuild(bytes32 _organizationId, address _user) external view returns (bool);

    /**
     * @dev Returns the membership status of the given user within the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to get the membership status of the user within
     * @param _user The user to get the membership status of
     * @return The membership status of the user within the guild
     */
    function getGuildMemberStatus(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user
    ) external view returns (GuildUserStatus);

    /**
     * @dev Returns the guild user info struct of the given user within the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to get the info struct of the user within
     * @param _user The user to get the info struct of
     * @return The info struct of the user within the guild
     */
    function getGuildMemberInfo(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user
    ) external view returns (GuildUserInfo memory);

    /**
     * @dev Initializes the Guild feature for the given organization.
     *  This can only be done by admins on the GuildManager contract.
     * @param _organizationId The id of the organization to initialize
     * @param _maxGuildsPerUser The maximum number of guilds a user can join within the organization.
     * @param _timeoutAfterLeavingGuild The number of seconds a user has to wait before being able to rejoin a guild
     * @param _guildCreationRule The rule for creating new guilds
     * @param _maxUsersPerGuildRule Indicates how the max number of users per guild is decided
     * @param _maxUsersPerGuildConstant If maxUsersPerGuildRule is set to CONSTANT, this is the max
     * @param _customGuildManagerAddress A contract address that handles custom guild creation requirements (i.e owning specific NFTs).
     * @param _requireTreasureTagForGuilds Whether this org requires a treasure tag for guilds
     *  This is used for guild creation if @param _guildCreationRule == CUSTOM_RULE
     */
    function initializeForOrganization(
        bytes32 _organizationId,
        uint8 _maxGuildsPerUser,
        uint32 _timeoutAfterLeavingGuild,
        GuildCreationRule _guildCreationRule,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant,
        address _customGuildManagerAddress,
        bool _requireTreasureTagForGuilds
    ) external;

    /**
     * @dev Sets the max number of guilds a user can join within the organization.
     * @param _organizationId The id of the organization to set the max guilds per user for.
     * @param _maxGuildsPerUser The maximum number of guilds a user can join within the organization.
     */
    function setMaxGuildsPerUser(bytes32 _organizationId, uint8 _maxGuildsPerUser) external;

    /**
     * @dev Sets the cooldown period a user has to wait before joining a new guild within the organization.
     * @param _organizationId The id of the organization to set the guild joining timeout for.
     * @param _timeoutAfterLeavingGuild The cooldown period a user has to wait before joining a new guild within the organization.
     */
    function setTimeoutAfterLeavingGuild(bytes32 _organizationId, uint32 _timeoutAfterLeavingGuild) external;

    /**
     * @dev Sets the rule for creating new guilds within the organization.
     * @param _organizationId The id of the organization to set the guild creation rule for.
     * @param _guildCreationRule The rule that outlines how a user can create a new guild within the organization.
     */
    function setGuildCreationRule(bytes32 _organizationId, GuildCreationRule _guildCreationRule) external;

    /**
     * @dev Sets the max number of users per guild within the organization.
     * @param _organizationId The id of the organization to set the max number of users per guild for
     * @param _maxUsersPerGuildRule Indicates how the max number of users per guild is decided within the organization.
     * @param _maxUsersPerGuildConstant If maxUsersPerGuildRule is set to CONSTANT, this is the max.
     */
    function setMaxUsersPerGuild(
        bytes32 _organizationId,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant
    ) external;

    /**
     * @dev Sets whether an org requires treasure tags for guilds
     * @param _organizationId The id of the organization to adjust
     * @param _requireTreasureTagForGuilds Whether treasure tags are required
     */
    function setRequireTreasureTagForGuilds(bytes32 _organizationId, bool _requireTreasureTagForGuilds) external;

    /**
     * @dev Sets the contract address that handles custom guild creation requirements (i.e owning specific NFTs).
     * @param _organizationId The id of the organization to set the custom guild manager address for
     * @param _customGuildManagerAddress The contract address that handles custom guild creation requirements (i.e owning specific NFTs).
     *  This is used for guild creation if the saved `guildCreationRule` == CUSTOM_RULE
     */
    function setCustomGuildManagerAddress(bytes32 _organizationId, address _customGuildManagerAddress) external;

    /**
     * @dev Sets the treasure tag nft address
     * @param _treasureTagNFTAddress The address of the treasure tag nft contract
     */
    function setTreasureTagNFTAddress(address _treasureTagNFTAddress) external;

    /**
     * @dev Retrieves the stored info for a given organization. Used to wrap the tuple from
     *  calling the mapping directly from external contracts
     * @param _organizationId The organization to return guild management info for
     * @return The stored guild settings for a given organization
     */
    function getGuildOrganizationInfo(bytes32 _organizationId) external view returns (GuildOrganizationInfo memory);

    /**
     * @dev Retrieves the token address for guilds within the given organization
     * @param _organizationId The organization to return the guild token address for
     * @return The token address for guilds within the given organization
     */
    function guildTokenAddress(bytes32 _organizationId) external view returns (address);

    /**
     * @dev Retrieves the token implementation address for guild token contracts to proxy to
     * @return The beacon token implementation address
     */
    function guildTokenImplementation() external view returns (address);

    /**
     * @dev Determines if the given guild is valid for the given organization
     * @param _organizationId The organization to verify against
     * @param _guildId The guild to verify
     * @return If the given guild is valid within the given organization
     */
    function isValidGuild(bytes32 _organizationId, uint32 _guildId) external view returns (bool);

    /**
     * @dev Get a given guild's name
     * @param _organizationId The organization to find the given guild within
     * @param _guildId The guild to retrieve the name from
     * @return The name of the given guild within the given organization
     */
    function guildName(bytes32 _organizationId, uint32 _guildId) external view returns (string memory);

    /**
     * @dev Get a given guild's description
     * @param _organizationId The organization to find the given guild within
     * @param _guildId The guild to retrieve the description from
     * @return The description of the given guild within the given organization
     */
    function guildDescription(bytes32 _organizationId, uint32 _guildId) external view returns (string memory);

    /**
     * @dev Get a given guild's symbol info
     * @param _organizationId The organization to find the given guild within
     * @param _guildId The guild to retrieve the symbol info from
     * @return symbolImageData_ The symbol data of the given guild within the given organization
     * @return isSymbolOnChain_ Whether or not the returned data is a URL or on-chain
     */
    function guildSymbolInfo(
        bytes32 _organizationId,
        uint32 _guildId
    ) external view returns (string memory symbolImageData_, bool isSymbolOnChain_);

    /**
     * @dev Retrieves the current owner for a given guild within a organization.
     * @param _organizationId The organization to find the guild within
     * @param _guildId The guild to return the owner of
     * @return The current owner of the given guild within the given organization
     */
    function guildOwner(bytes32 _organizationId, uint32 _guildId) external view returns (address);

    /**
     * @dev Retrieves the current owner for a given guild within a organization.
     * @param _organizationId The organization to find the guild within
     * @param _guildId The guild to return the maxMembers of
     * @return The current maxMembers of the given guild within the given organization
     */
    function maxUsersForGuild(bytes32 _organizationId, uint32 _guildId) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @dev Used to track ERC20 payment feeds and decimals for conversions. Note that `decimals` equaling 0 means that the erc20
 *      information is not initialized/supported.
 * @param priceFeeds A mapping of any price feed that supports the pair of ERC20 tokens used for conversions.
 *      There are currently no price feeds for this, however if one were to exist, it would be supportable
 *      Ex. LINK / MAGIC would give an answer of "How much MAGIC equals 1 LINK?" -> 3.67 MAGIC (See https://coincodex.com/convert/chainlink/magic-token/)
 *      Ex. MAGIC / LINK would give an answer of "How much LINK equals 1 MAGIC?" -> 0.272600 LINK (See https://coincodex.com/convert/magic-token/chainlink/)
 * @param usdAggregator The price feed for the ERC20 token priced in USD
 *      Ex. LINK / USD would give an answer of "How much USD equals 1 LINK?" -> 7.26 USD (See https://coincodex.com/convert/chainlink/usd/)
 * @param pricedInGasTokenAggregator The price feed for ERC20 priced in gas tokens
 *      Ex. LINK / ETH would give an answer of "How much ETH equals 1 LINK?" -> 0.004 ETH (See https://coincodex.com/convert/chainlink/ethereum/)
 * @param gasTokenPricedInERC20Aggregator The price feed for the gas token priced in the ERC20.
 *      There are currently no price feeds for this, however if one were to exist, it would be supportable
 *      Ex. ETH / LINK would give an answer of "How much LINK equals 1 ETH" -> 249.13 LINK (See https://coincodex.com/convert/ethereum/chainlink/)
 * @param decimals The number of decimals of this ERC20.
 *      Needed to ensure proper funds transferring when decimals in the pair differ
 */
struct ERC20Info {
    // Slot 1: 256 bits
    mapping(address => AggregatorV3Interface) priceFeeds;
    // Slot 2: 160 bits
    AggregatorV3Interface usdAggregator;
    // Slot 3: 160 bits
    AggregatorV3Interface pricedInGasTokenAggregator;
    // Slot 4: 168 bits
    AggregatorV3Interface gasTokenPricedInERC20Aggregator;
    uint8 decimals;
}

/**
 * @dev Used to determine how to calculate the payment amount when taking a payment.
 *      STATIC: The payment amount is the input token without conversion.
 *      PRICED_IN_ERC20: The payment amount is priced in an ERC20 relative to the payment token.
 *      PRICED_IN_USD: The payment amount is priced in USD relative to the payment token.
 *      PRICED_IN_GAS_TOKEN: The payment amount is priced in the gas token relative to the payment token.
 */
enum PriceType {
    STATIC,
    PRICED_IN_ERC20,
    PRICED_IN_USD,
    PRICED_IN_GAS_TOKEN
}

interface IPayments {
    /**
     * @dev Emitted when a payment is made
     * @param payor The address of the sender of the payment
     * @param token The address of the token that was paid. If address(0), then it was gas token
     * @param amount The amount of the token that was paid
     * @param paymentsReceiver The address of the contract that received the payment. Supports IPaymentsReceiver
     */
    event PaymentSent(address payor, address token, uint256 amount, address paymentsReceiver);

    /**
     * @dev Make a payment in ERC20 to the recipient
     * @param _recipient The address of the recipient of the payment
     * @param _paymentERC20 The address of the ERC20 to take
     * @param _price The amount of the ERC20 to take
     */
    function makeStaticERC20Payment(address _recipient, address _paymentERC20, uint256 _price) external;

    /**
     * @dev Make a payment in gas token to the recipient.
     *      All this does is verify that the price matches the tx value
     * @param _recipient The address of the recipient of the payment
     * @param _price The amount of the gas token to take
     */
    function makeStaticGasTokenPayment(address _recipient, uint256 _price) external payable;

    /**
     * @dev Make a payment in ERC20 to the recipient priced in another token (Gas Token/USD/other ERC20)
     * @param _recipient The address of the payor to take the payment from
     * @param _paymentERC20 The address of the ERC20 to take
     * @param _paymentAmountInPricedToken The desired payment amount, priced in another token, depending on what `priceType` is
     * @param _priceType The type of currency that the payment amount is priced in
     * @param _pricedERC20 The address of the ERC20 that the payment amount is priced in. Only used if `_priceType` is PRICED_IN_ERC20
     */
    function makeERC20PaymentByPriceType(
        address _recipient,
        address _paymentERC20,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external;

    /**
     * @dev Take payment in gas tokens (ETH, MATIC, etc.) priced in another token (USD/ERC20)
     * @param _recipient The address to send the payment to
     * @param _paymentAmountInPricedToken The desired payment amount, priced in another token, depending on what `_priceType` is
     * @param _priceType The type of currency that the payment amount is priced in
     * @param _pricedERC20 The address of the ERC20 that the payment amount is priced in. Only used if `_priceType` is PRICED_IN_ERC20
     */
    function makeGasTokenPaymentByPriceType(
        address _recipient,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external payable;

    /**
     * @dev Admin-only function that initializes the ERC20 info for a given ERC20.
     *      Currently there are no price feeds for ERC20s, so those parameters are a placeholder
     * @param _paymentERC20 The ERC20 address
     * @param _decimals The number of decimals of this coin.
     * @param _pricedInGasTokenAggregator The aggregator for the gas coin (ETH, MATIC, etc.)
     * @param _usdAggregator The aggregator for USD
     * @param _pricedERC20s The ERC20s that have supported price feeds for the given ERC20
     * @param _priceFeeds The price feeds for the priced ERC20s
     */
    function initializeERC20(
        address _paymentERC20,
        uint8 _decimals,
        address _pricedInGasTokenAggregator,
        address _usdAggregator,
        address[] calldata _pricedERC20s,
        address[] calldata _priceFeeds
    ) external;

    /**
     * @dev Admin-only function that sets the price feed for a given ERC20.
     *      Currently there are no price feeds for ERC20s, so this is a placeholder
     * @param _paymentERC20 The ERC20 to set the price feed for
     * @param _pricedERC20 The ERC20 that is associated to the given price feed and `_paymentERC20`
     * @param _priceFeed The address of the price feed
     */
    function setERC20PriceFeedForERC20(address _paymentERC20, address _pricedERC20, address _priceFeed) external;

    /**
     * @dev Admin-only function that sets the price feed for the gas token for the given ERC20.
     * @param _pricedERC20 The ERC20 that is associated to the given price feed and `_paymentERC20`
     * @param _priceFeed The address of the price feed
     */
    function setERC20PriceFeedForGasToken(address _pricedERC20, address _priceFeed) external;

    /**
     * @param _paymentToken The token to convert from. If address(0), then the input is in gas tokens
     * @param _priceType The type of currency that the payment amount is priced in
     * @param _pricedERC20 The address of the ERC20 that the payment amount is priced in. Only used if `_priceType` is PRICED_IN_ERC20
     * @return supported_ Whether or not a price feed exists for the given payment token and price type
     */
    function isValidPriceType(
        address _paymentToken,
        PriceType _priceType,
        address _pricedERC20
    ) external view returns (bool supported_);

    /**
     * @dev Calculates the price of the input token relative to the output token
     * @param _paymentToken The token to convert from. If address(0), then the input is in gas tokens
     * @param _paymentAmountInPricedToken The desired payment amount, priced in either the `_pricedERC20`, gas token, or USD depending on `_priceType`
     *      used to calculate the output amount
     * @param _priceType The type of conversion to perform
     * @param _pricedERC20 The token to convert to. If address(0), then the output is in gas tokens or USD, depending on `_priceType`
     */
    function calculatePaymentAmountByPriceType(
        address _paymentToken,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external view returns (uint256 paymentAmount_);

    /**
     * @return magicAddress_ The address of the $MAGIC contract
     */
    function getMagicAddress() external view returns (address magicAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PriceType } from "src/interfaces/IPayments.sol";

interface IPaymentsReceiver {
    /**
     * @dev Emitted when a payment is made
     * @param payor The address of the sender of the payment
     * @param paymentERC20 The address of the token that was paid. If address(0), then it was gas token
     * @param paymentAmount The amount of the token that was paid
     * @param paymentAmountInPricedToken The payment amount of the given priced token. Used to have dynamic payments based on the value relative to another token
     * @param priceType The type of payment that was made. This can be static payment or priced in another currency
     * @param pricedERC20 The address of the ERC20 token that was used to price the payment. Only used if `_priceType` is PRICED_IN_ERC20
     */
    event PaymentReceived(
        address payor,
        address paymentERC20,
        uint256 paymentAmount,
        uint256 paymentAmountInPricedToken,
        PriceType priceType,
        address pricedERC20
    );

    /**
     * @dev Accepts a payment in ERC20 tokens
     * @param _payor The address of the payor for this payment
     * @param _paymentERC20 The address of the ERC20 token that was paid
     * @param _paymentAmount The amount of the ERC20 token that was paid
     * @param _paymentAmountInPricedToken The amount of the ERC20 token that was paid in the given priced token
     *      For example, if the payment is the amount of MAGIC that equals $10 USD,
     *      then this value would be 10 * 10**8 (the number of decimals for USD)
     * @param _priceType The type of payment that was made. This can be static payment or priced in another currency
     * @param _pricedERC20 The address of the ERC20 token that was used to price the payment. Only used if `_priceType` is `PriceType.PRICED_IN_ERC20`
     */
    function acceptERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external;

    /**
     * @dev Accepts a payment in gas tokens
     * @param _payor The address of the payor for this payment
     * @param _paymentAmount The amount of the gas token that was paid
     * @param _paymentAmountInPricedToken The amount of the gas token that was paid in the given priced token
     *      For example, if the payment is the amount of ETH that equals $10 USD,
     *      then this value would be 10 * 10**8 (the number of decimals for USD)
     * @param _priceType The type of payment that was made. This can be static payment or priced in another currency
     * @param _pricedERC20 The address of the ERC20 token that was used to price the payment. Only used if `_priceType` is `PriceType.PRICED_IN_ERC20`
     */
    function acceptGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BBase64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in BBase64
library LibBBase64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) return "";

        // load the _table into memory
        string memory _table = TABLE;

        // multiply by 4/3 rounded up
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory _result = new string(_encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(_result, _encodedLen)

            // prepare the lookup _table
            let tablePtr := add(_table, 1)

            // input ptr
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))

            // _result ptr, jump over length
            let resultPtr := add(_result, 32)

            // run over the input, 3 bytes at a time
            for { } lt(dataPtr, endPtr) { } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(_data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return _result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { MetaTxFacetStorage } from "src/metatx/MetaTxFacetStorage.sol";

/// @title Library for handling meta transactions with the EIP2771 standard
/// @notice The logic for getting msgSender and msgData are were copied from OpenZeppelin's
///  ERC2771ContextUpgradeable contract
library LibMeta {
    struct Layout {
        address trustedForwarder;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.metatx");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    // =============================================================
    //                      State Helpers
    // =============================================================

    function isTrustedForwarder(address _forwarder) internal view returns (bool isTrustedForwarder_) {
        isTrustedForwarder_ = layout().trustedForwarder == _forwarder;
    }

    // =============================================================
    //                      Meta Tx Helpers
    // =============================================================

    /**
     * @dev The only valid forwarding contract is the one that is going to run the executing function
     */
    function _msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender_ := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender_ = msg.sender;
        }
    }

    /**
     * @dev The only valid forwarding contract is the one that is going to run the executing function
     */
    function _msgData() internal view returns (bytes calldata data_) {
        if (msg.sender == address(this)) {
            data_ = msg.data[:msg.data.length - 20];
        } else {
            data_ = msg.data;
        }
    }

    function getMetaDelegateAddress() internal view returns (address delegateAddress_) {
        return address(MetaTxFacetStorage.layout().systemDelegateApprover);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PausableStorage } from "@openzeppelin/contracts-diamond/security/PausableStorage.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-diamond/utils/StringsUpgradeable.sol";
import { LibMeta } from "./LibMeta.sol";

library LibUtilities {
    event Paused(address account);
    event Unpaused(address account);

    error ArrayLengthMismatch(uint256 len1, uint256 len2);

    error IsPaused();
    error NotPaused();

    // =============================================================
    //                      Array Helpers
    // =============================================================

    function requireArrayLengthMatch(uint256 _length1, uint256 _length2) internal pure {
        if (_length1 != _length2) {
            revert ArrayLengthMismatch(_length1, _length2);
        }
    }

    function asSingletonArray(uint256 _item) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = _item;
    }

    function asSingletonArray(string memory _item) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = _item;
    }

    // =============================================================
    //                     Misc Functions
    // =============================================================

    function compareStrings(string memory _a, string memory _b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
    }

    function setPause(bool _paused) internal {
        PausableStorage.layout()._paused = _paused;
        if (_paused) {
            emit Paused(LibMeta._msgSender());
        } else {
            emit Unpaused(LibMeta._msgSender());
        }
    }

    function paused() internal view returns (bool) {
        return PausableStorage.layout()._paused;
    }

    function requirePaused() internal view {
        if (!paused()) {
            revert NotPaused();
        }
    }

    function requireNotPaused() internal view {
        if (paused()) {
            revert IsPaused();
        }
    }

    function toString(uint256 _value) internal pure returns (string memory) {
        return StringsUpgradeable.toString(_value);
    }

    /**
     * @notice This function takes the first 4 MSB of the given bytes32 and converts them to _a bytes4
     * @dev This function is useful for grabbing function selectors from calldata
     * @param _inBytes The bytes to convert to bytes4
     */
    function convertBytesToBytes4(bytes memory _inBytes) internal pure returns (bytes4 outBytes4_) {
        if (_inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4_ := mload(add(_inBytes, 32))
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibBBase64 } from "src/libraries/LibBBase64.sol";
import { IGuildManager } from "src/interfaces/IGuildManager.sol";

/**
 * @notice The contract that handles validating meta transaction delegate approvals
 * @dev References to 'System' are synonymous with 'Organization'
 */
interface ISystemDelegateApprover {
    function isDelegateApprovedForSystem(
        address _account,
        bytes32 _systemId,
        address _delegate
    ) external view returns (bool);
    function setDelegateApprovalForSystem(bytes32 _systemId, address _delegate, bool _approved) external;
    function setDelegateApprovalForSystemBySignature(
        bytes32 _systemId,
        address _delegate,
        bool _approved,
        address _signer,
        uint256 _nonce,
        bytes calldata _signature
    ) external;
}

/**
 * @notice The struct used for signing and validating meta transactions
 * @dev from+nonce is packed to a single storage slot to save calldata gas on rollups
 * @param from The address that is being called on behalf of
 * @param nonce The nonce of the transaction. Used to prevent replay attacks
 * @param organizationId The id of the invoking organization
 * @param data The calldata of the function to be called
 */
struct ForwardRequest {
    address from;
    uint96 nonce;
    bytes32 organizationId;
    bytes data;
}

/**
 * @dev The typehash of the ForwardRequest struct used when signing the meta transaction
 *  This must match the ForwardRequest struct, and must not have extra whitespace or it will invalidate the signature
 */
bytes32 constant FORWARD_REQ_TYPEHASH =
    keccak256("ForwardRequest(address from,uint96 nonce,bytes32 organizationId,bytes data)");

library MetaTxFacetStorage {
    /**
     * @dev Emitted when an invalid delegate approver is provided or not allowed.
     */
    error InvalidDelegateApprover();

    /**
     * @dev Emitted when the `execute` function is called recursively, which is not allowed.
     */
    error CannotCallExecuteFromExecute();

    /**
     * @dev Emitted when the session organization ID is not consumed or processed as expected.
     */
    error SessionOrganizationIdNotConsumed();

    /**
     * @dev Emitted when there is a mismatch between the session organization ID and the function organization ID.
     * @param sessionOrganizationId The session organization ID
     * @param functionOrganizationId The function organization ID
     */
    error SessionOrganizationIdMismatch(bytes32 sessionOrganizationId, bytes32 functionOrganizationId);

    /**
     * @dev Emitted when a nonce has already been used for a specific sender address.
     * @param sender The address of the sender
     * @param nonce The nonce that has already been used
     */
    error NonceAlreadyUsedForSender(address sender, uint256 nonce);

    /**
     * @dev Emitted when the signer is not authorized to sign on behalf of the sender address.
     * @param signer The address of the signer
     * @param sender The address of the sender
     */
    error UnauthorizedSignerForSender(address signer, address sender);

    struct Layout {
        /**
         * @notice The delegate approver that tracks which wallet can run txs on behalf of the real sending account
         * @dev References to 'System' are synonymous with 'Organization'
         */
        ISystemDelegateApprover systemDelegateApprover;
        /**
         * @notice Tracks which nonces have been used by the from address. Prevents replay attacks.
         * @dev Key1: from address, Key2: nonce, Value: used or not
         */
        mapping(address => mapping(uint256 => bool)) nonces;
        /**
         * @dev The organization id of the session. Set before invoking a meta transaction and requires the function to clear it
         *  to ensure the session organization matches the function organizationId
         */
        bytes32 sessionOrganizationId;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.facet.metatx");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC165Upgradeable } from "@openzeppelin/contracts-diamond/utils/introspection/IERC165Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/IERC20Upgradeable.sol";

import { FacetInitializable } from "src/utils/FacetInitializable.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";

import { IPayments, PriceType } from "src/interfaces/IPayments.sol";
import { IPaymentsReceiver } from "src/interfaces/IPaymentsReceiver.sol";
import { PaymentsReceiverStorage } from "src/payments/PaymentsReceiverStorage.sol";

/**
 * @title Payments Receiver contract.
 * @dev This facet exposes functionality to easily allow developers to accept payments in ERC20 tokens or gas
 *      tokens (ETH, MATIC, etc.). Developers can also accept payment in a token amount priced in USD, other ERC20, or gas tokens.
 */
contract PaymentsReceiver is FacetInitializable, IPaymentsReceiver, IERC165Upgradeable {
    /**
     * @dev Initialize the facet. Must be called before any other functions.
     */
    function PaymentsReceiver_init(address _spellcasterPayments)
        public
        facetInitializer(keccak256("PaymentsReceiver"))
    {
        PaymentsReceiverStorage.layout().spellcasterPayments = IPayments(_spellcasterPayments);
    }

    /**
     * @inheritdoc IPaymentsReceiver
     */
    function acceptERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external override onlySpellcasterPayments {
        emit PaymentReceived(
            _payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken, _priceType, _pricedERC20
        );

        if (
            _priceType == PriceType.STATIC || (_priceType == PriceType.PRICED_IN_ERC20 && _pricedERC20 == _paymentERC20)
        ) {
            if (_paymentAmount != _paymentAmountInPricedToken) {
                revert PaymentsReceiverStorage.IncorrectPaymentAmount(_paymentAmount, _paymentAmountInPricedToken);
            }
            if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptStaticMagicPayment(_payor, _paymentAmount);
            } else {
                _acceptStaticERC20Payment(_payor, _paymentERC20, _paymentAmount);
            }
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            if (_pricedERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptERC20PaymentPricedInMagic(_payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken);
            } else if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptMagicPaymentPricedInERC20(_payor, _paymentAmount, _pricedERC20, _paymentAmountInPricedToken);
            } else {
                _acceptERC20PaymentPricedInERC20(
                    _payor, _paymentERC20, _paymentAmount, _pricedERC20, _paymentAmountInPricedToken
                );
            }
        } else if (_priceType == PriceType.PRICED_IN_USD) {
            if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptMagicPaymentPricedInUSD(_payor, _paymentAmount, _paymentAmountInPricedToken);
            } else {
                _acceptERC20PaymentPricedInUSD(_payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken);
            }
        } else if (_priceType == PriceType.PRICED_IN_GAS_TOKEN) {
            if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptMagicPaymentPricedInGasToken(_payor, _paymentAmount, _paymentAmountInPricedToken);
            } else {
                _acceptERC20PaymentPricedInGasToken(_payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken);
            }
        } else {
            revert PaymentsReceiverStorage.PaymentTypeNotAccepted("ERC20");
        }
    }

    /**
     * @inheritdoc IPaymentsReceiver
     */
    function acceptGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external payable override onlySpellcasterPayments {
        emit PaymentReceived(_payor, address(0), _paymentAmount, _paymentAmountInPricedToken, _priceType, _pricedERC20);

        if (msg.value != _paymentAmount) {
            revert PaymentsReceiverStorage.IncorrectPaymentAmount(msg.value, _paymentAmountInPricedToken);
        }
        if (_priceType == PriceType.STATIC) {
            if (msg.value != _paymentAmountInPricedToken || _paymentAmount != _paymentAmountInPricedToken) {
                revert PaymentsReceiverStorage.IncorrectPaymentAmount(msg.value, _paymentAmountInPricedToken);
            }
            _acceptStaticGasTokenPayment(_payor, msg.value);
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            if (_pricedERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptGasTokenPaymentPricedInMagic(_payor, _paymentAmount, _paymentAmountInPricedToken);
            } else {
                _acceptGasTokenPaymentPricedInERC20(_payor, _paymentAmount, _pricedERC20, _paymentAmountInPricedToken);
            }
        } else if (_priceType == PriceType.PRICED_IN_USD) {
            _acceptGasTokenPaymentPricedInUSD(_payor, _paymentAmount, _paymentAmountInPricedToken);
        } else {
            revert PaymentsReceiverStorage.PaymentTypeNotAccepted("Gas Token");
        }
    }

    function _acceptStaticMagicPayment(address _payor, uint256 _paymentAmount) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("MAGIC ", string(abi.encode(_payor, _paymentAmount)))
        );
    }

    function _acceptMagicPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("MAGIC / USD ", string(abi.encode(_payor, _paymentAmount, _priceInUSD)))
        );
    }

    function _acceptMagicPaymentPricedInGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInGasToken
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("MAGIC / GAS TOKEN ", string(abi.encode(_payor, _paymentAmount, _priceInGasToken)))
        );
    }

    function _acceptMagicPaymentPricedInERC20(
        address _payor,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("MAGIC / ERC20 ", string(abi.encode(_payor, _paymentAmount, _pricedERC20, _priceInERC20)))
        );
    }

    function _acceptGasTokenPaymentPricedInMagic(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInMagic
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN / MAGIC ", string(abi.encode(_payor, _paymentAmount, _priceInMagic)))
        );
    }

    function _acceptStaticERC20Payment(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("ERC20 ", string(abi.encode(_payor, _paymentERC20, _paymentAmount)))
        );
    }

    function _acceptERC20PaymentPricedInERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat(
                "ERC20 / ERC20 ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _pricedERC20, _priceInERC20))
            )
        );
    }

    function _acceptERC20PaymentPricedInUSD(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("ERC20 / USD ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _priceInUSD)))
        );
    }

    function _acceptERC20PaymentPricedInMagic(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInMagic
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("ERC20 / MAGIC ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _priceInMagic)))
        );
    }

    function _acceptERC20PaymentPricedInGasToken(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInGasToken
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat(
                "ERC20 / GAS TOKEN ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _priceInGasToken))
            )
        );
    }

    function _acceptStaticGasTokenPayment(address _payor, uint256 _paymentAmount) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN ", string(abi.encode(_payor, _paymentAmount)))
        );
    }

    function _acceptGasTokenPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN / USD ", string(abi.encode(_payor, _paymentAmount, _priceInUSD)))
        );
    }

    function _acceptGasTokenPaymentPricedInERC20(
        address _payor,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN / ERC20 ", string(abi.encode(_payor, _paymentAmount, _pricedERC20, _priceInERC20)))
        );
    }

    /**
     * @dev Enables external contracts to query if this contract implements the IPaymentsReceiver interface.
     *      Needed for compliant implementation of Spellcaster Payments.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IPaymentsReceiver).interfaceId || _interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev Modifier to make a function callable only by the Spellcaster Payments contract.
     */
    modifier onlySpellcasterPayments() {
        if (LibMeta._msgSender() != address(PaymentsReceiverStorage.layout().spellcasterPayments)) {
            revert PaymentsReceiverStorage.SenderNotSpellcasterPayments(LibMeta._msgSender());
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IPayments, ERC20Info, PriceType } from "src/interfaces/IPayments.sol";

/**
 * @title PaymentsReceiverStorage library
 * @notice This library contains the storage layout and events/errors for the PaymentsReceiver contract.
 */
library PaymentsReceiverStorage {
    struct Layout {
        IPayments spellcasterPayments;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.payments.receiver");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    /**
     * @dev Emitted when an incorrect payment amount is provided.
     * @param amount The provided payment amount
     * @param price The expected payment amount (price)
     */
    error IncorrectPaymentAmount(uint256 amount, uint256 price);

    /**
     * @dev Emitted when the sender is not a valid spellcaster payment address.
     * @param sender The address of the sender attempting the action
     */
    error SenderNotSpellcasterPayments(address sender);

    /**
     * @dev Emitted when a non-accepted payment type is provided.
     * @param paymentType The provided payment type
     */
    error PaymentTypeNotAccepted(string paymentType);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUpgradeable } from "@openzeppelin/contracts-diamond/utils/AddressUpgradeable.sol";
import { InitializableStorage } from "@openzeppelin/contracts-diamond/proxy/utils/InitializableStorage.sol";
import { FacetInitializableStorage } from "./FacetInitializableStorage.sol";
import { LibUtilities } from "../libraries/LibUtilities.sol";

/**
 * @title Initializable using DiamondStorage pattern and supporting facet-specific initializers
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract FacetInitializable {
    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     * Name changed to prevent collision with OZ contracts
     */
    modifier facetInitializer(bytes32 _facetId) {
        // Allow infinite constructor initializations to support multiple inheritance.
        // Otherwise, this contract/facet must not have been previously initialized.
        if (
            InitializableStorage.layout()._initializing
                ? !_isConstructor()
                : FacetInitializableStorage.getState().initialized[_facetId]
        ) {
            revert FacetInitializableStorage.AlreadyInitialized(_facetId);
        }
        bool _isTopLevelCall = !InitializableStorage.layout()._initializing;
        // Always set facet initialized regardless of if top level call or not.
        // This is so that we can run through facetReinitializable() if needed, and lower level functions can protect themselves
        FacetInitializableStorage.getState().initialized[_facetId] = true;

        if (_isTopLevelCall) {
            InitializableStorage.layout()._initializing = true;
        }

        _;

        if (_isTopLevelCall) {
            InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to trick internal functions that use onlyInitializing / onlyFacetInitializing into thinking
     *  that the contract is being initialized.
     *  This should only be called via a diamond initialization script and makes a lot of assumptions.
     *  Handle with care.
     */
    modifier facetReinitializable() {
        InitializableStorage.layout()._initializing = true;
        _;
        InitializableStorage.layout()._initializing = false;
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyFacetInitializing() {
        require(InitializableStorage.layout()._initializing, "FacetInit: not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Storage to track facets in a diamond that have been initialized.
 * Needed to prevent accidental re-initializations
 * Name changed to prevent collision with OZ contracts
 * OZ's Initializable storage handles all of the _initializing state, which isn't facet-specific
 */
library FacetInitializableStorage {
    error AlreadyInitialized(bytes32 facetId);

    struct Layout {
        /*
         * @dev Indicates that the contract/facet has been initialized.
         * bytes32 is the contract/facetId (keccak of the contract name)
         * bool is whether or not the contract/facet has been initialized
         */
        mapping(bytes32 => bool) initialized;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("spellcaster.storage.utils.FacetInitializable");

    function getState() internal pure returns (Layout storage l_) {
        bytes32 _position = STORAGE_SLOT;
        assembly {
            l_.slot := _position
        }
    }

    function isInitialized(bytes32 _facetId) internal view returns (bool isInitialized_) {
        isInitialized_ = getState().initialized[_facetId];
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PaymentsReceiver, PaymentsReceiverStorage } from "@spellcaster/payments/PaymentsReceiver.sol";

contract ExamplePaymentsReceiver is PaymentsReceiver {
    event PaymentReceived(
        uint256 indexed payType, address indexed payor, uint256 amount, address payToken, address pricedToken
    );

    function magic() internal view returns (address magic_) {
        magic_ = PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress();
    }

    function _acceptStaticMagicPayment(address _payor, uint256 _paymentAmount) internal virtual override {
        emit PaymentReceived(0, _payor, _paymentAmount, magic(), address(0));
    }

    function _acceptMagicPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmount,
        uint256
    ) internal virtual override {
        emit PaymentReceived(1, _payor, _paymentAmount, magic(), address(0));
    }

    function _acceptMagicPaymentPricedInGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256
    ) internal virtual override {
        emit PaymentReceived(2, _payor, _paymentAmount, magic(), address(0));
    }

    function _acceptMagicPaymentPricedInERC20(
        address _payor,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256
    ) internal virtual override {
        emit PaymentReceived(3, _payor, _paymentAmount, magic(), _pricedERC20);
    }

    function _acceptGasTokenPaymentPricedInMagic(
        address _payor,
        uint256 _paymentAmount,
        uint256
    ) internal virtual override {
        emit PaymentReceived(4, _payor, _paymentAmount, address(0), magic());
    }

    function _acceptStaticERC20Payment(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount
    ) internal virtual override {
        emit PaymentReceived(5, _payor, _paymentAmount, _paymentERC20, address(0));
    }

    function _acceptERC20PaymentPricedInERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256
    ) internal virtual override {
        emit PaymentReceived(6, _payor, _paymentAmount, _paymentERC20, _pricedERC20);
    }

    function _acceptERC20PaymentPricedInUSD(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256
    ) internal virtual override {
        emit PaymentReceived(7, _payor, _paymentAmount, _paymentERC20, address(0));
    }

    function _acceptERC20PaymentPricedInMagic(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256
    ) internal virtual override {
        emit PaymentReceived(8, _payor, _paymentAmount, _paymentERC20, magic());
    }

    function _acceptERC20PaymentPricedInGasToken(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256
    ) internal virtual override {
        emit PaymentReceived(9, _payor, _paymentAmount, _paymentERC20, address(0));
    }

    function _acceptStaticGasTokenPayment(address _payor, uint256 _paymentAmount) internal virtual override {
        emit PaymentReceived(10, _payor, _paymentAmount, address(0), address(0));
    }

    function _acceptGasTokenPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmount,
        uint256
    ) internal virtual override {
        emit PaymentReceived(11, _payor, _paymentAmount, address(0), address(0));
    }

    function _acceptGasTokenPaymentPricedInERC20(
        address _payor,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256
    ) internal virtual override {
        emit PaymentReceived(12, _payor, _paymentAmount, address(0), _pricedERC20);
    }
}