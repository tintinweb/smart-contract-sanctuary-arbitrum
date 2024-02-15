// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library FunctionParameters {
  /**
   * @notice Struct having the init data for a new IndexFactory creation
   * @param _indexSwapLibrary Address of the base IndexSwapLibrary
   * @param _baseIndexSwapAddress Address of the base IndexSwap
   * @param _baseRebalancingAddres Address of the base Rebalancing module
   * @param _baseOffChainRebalancingAddress Address of the base Offchain-Rebalance module
   * @param _baseRebalanceAggregatorAddress Address of the base Rebalance Aggregator module
   * @param _baseExchangeHandlerAddress Address of the base Exchange Handler
   * @param _baseAssetManagerConfigAddress Address of the baes AssetManager Config address
   * @param _baseOffChainIndexSwapAddress Address of the base Offchain-IndexSwap module
   * @param _feeModuleImplementationAddress Address of the base Fee Module implementation
   * @param _baseVelvetGnosisSafeModuleAddress Address of the base Gnosis-Safe module
   * @param _gnosisSingleton Address of the Gnosis Singleton
   * @param _gnosisFallbackLibrary Address of the Gnosis Fallback Library
   * @param _gnosisMultisendLibrary Address of the Gnosis Multisend Library
   * @param _gnosisSafeProxyFactory Address of the Gnosis Safe Proxy Factory
   * @param _priceOracle Address of the base Price Oracle to be used
   * @param _tokenRegistry Address of the Token Registry to be used
   * @param _velvetProtocolFee Fee cut that is being charged (eg: 25% of the fees)
   */
  struct IndexFactoryInitData {
    address _indexSwapLibrary;
    address _baseIndexSwapAddress;
    address _baseRebalancingAddres;
    address _baseOffChainRebalancingAddress;
    address _baseRebalanceAggregatorAddress;
    address _baseExchangeHandlerAddress;
    address _baseAssetManagerConfigAddress;
    address _baseOffChainIndexSwapAddress;
    address _feeModuleImplementationAddress;
    address _baseVelvetGnosisSafeModuleAddress;
    address _gnosisSingleton;
    address _gnosisFallbackLibrary;
    address _gnosisMultisendLibrary;
    address _gnosisSafeProxyFactory;
    address _priceOracle;
    address _tokenRegistry;
  }

  /**
   * @notice Data passed from the Factory for the init of IndexSwap module
   * @param _name Name of the Index Fund
   * @param _symbol Symbol to represent the Index Fund
   * @param _vault Address of the Vault associated with that Index Fund
   * @param _module Address of the Safe module  associated with that Index Fund
   * @param _oracle Address of the Price Oracle associated with that Index Fund
   * @param _accessController Address of the Access Controller associated with that Index Fund
   * @param _tokenRegistry Address of the Token Registry associated with that Index Fund
   * @param _exchange Address of the Exchange Handler associated with that Index Fund
   * @param _iAssetManagerConfig Address of the Asset Manager Config associated with that Index Fund
   * @param _feeModule Address of the Fee Module associated with that Index Fund
   */
  struct IndexSwapInitData {
    string _name;
    string _symbol;
    address _vault;
    address _module;
    address _oracle;
    address _accessController;
    address _tokenRegistry;
    address _exchange;
    address _iAssetManagerConfig;
    address _feeModule;
  }

  /**
   * @notice Struct used to pass data when a Token is swapped to ETH (native token) using the swap handler
   * @param _token Address of the token being swapped
   * @param _to Receiver address that is receiving the swapped result
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _swapAmount Amount of tokens to be swapped
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   */
  struct SwapTokenToETHData {
    address _token;
    address _to;
    address _swapHandler;
    uint256 _swapAmount;
    uint256 _slippage;
    uint256 _lpSlippage;
  }

  /**
   * @notice Struct used to pass data when ETH (native token) is swapped to some other Token using the swap handler
   * @param _token Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   * @param _swapAmount Amount of tokens that is to be swapped
   */
  struct SwapETHToTokenData {
    address _token;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _slippage;
    uint256 _lpSlippage;
    uint256 _swapAmount;
  }

  /**
   * @notice Struct used to pass data when ETH (native token) is swapped to some other Token using the swap handler
   * @param _token Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   */
  struct SwapETHToTokenPublicData {
    address _token;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _slippage;
    uint256 _lpSlippage;
  }

  /**
   * @notice Struct used to pass data when a Token is swapped to another token using the swap handler
   * @param _tokenIn Address of the token being swapped from
   * @param _tokenOut Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _swapAmount Amount of tokens that is to be swapped
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   * @param _isInvesting Boolean parameter indicating if the swap is being done during investment or withdrawal
   */
  struct SwapTokenToTokenData {
    address _tokenIn;
    address _tokenOut;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _swapAmount;
    uint256 _slippage;
    uint256 _lpSlippage;
    bool _isInvesting;
  }

  /**
   * @notice Struct having data for the swap of one token to another based on the input
   * @param _index Address of the IndexSwap associated with the swap tokens
   * @param _inputToken Address of the token being swapped from
   * @param _swapHandler Address of the swap handler being used
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _tokenAmount Investment amount that is being distributed into all the portfolio tokens
   * @param _totalSupply Total supply of the Index tokens
   * @param amount The swap amount (in case totalSupply != 0) value calculated from the IndexSwapLibrary
   * @param _slippage Slippage for providing the liquidity
   * @param _lpSlippage LP Slippage for providing the liquidity
   */
  struct SwapTokenToTokensData {
    address _index;
    address _inputToken;
    address _swapHandler;
    address _toUser;
    uint256 _tokenAmount;
    uint256 _totalSupply;
    uint256[] amount;
    uint256[] _slippage;
    uint256[] _lpSlippage;
  }

  /**
   * @notice Struct having the Offchain Investment data used for multiple functions
   * @param _offChainHandler Address of the off-chain handler being used
   * @param _buyAmount Array of amounts representing the distribution to all portfolio tokens; sum of this amount is the total investment amount
   * @param _buySwapData Array including the calldata which is required for the external swap handlers to swap ("buy") the portfolio tokens
   */
  struct ZeroExData {
    address _offChainHandler;
    uint256[] _buyAmount;
    bytes[] _buySwapData;
  }

  /**
   * @notice Struct having the init data for a new Index Fund creation using the Factory
   * @param _assetManagerTreasury Address of the Asset Manager Treasury to be associated with the fund
   * @param _whitelistedTokens Array of tokens which limits the use of only those addresses as portfolio tokens in the fund
   * @param maxIndexInvestmentAmount Maximum Investment amount for the fund
   * @param maxIndexInvestmentAmount Minimum Investment amount for the fund
   * @param _managementFee Management fee (streaming fee) that the asset manager will receive for managing the fund
   * @param _performanceFee Fee that the asset manager will receive for managing the fund and if the portfolio performance well
   * @param _entryFee Entry fee for investing into the fund
   * @param _exitFee Exit fee for withdrawal from the fund
   * @param _public Boolean parameter for is the fund eligible for public investment or only some whitelist users can invest
   * @param _transferable Boolean parameter for is the Index tokens from the fund transferable or not
   * @param _transferableToPublic Boolean parameter for is the Index tokens from the fund transferable to public or only to whitelisted users
   * @param _whitelistTokens Boolean parameter which specifies if the asset manager can only choose portfolio tokens from the whitelisted array or not
   * @param name Name of the fund
   * @param symbol Symbol associated with the fund
   */
  struct IndexCreationInitData {
    address _assetManagerTreasury;
    address[] _whitelistedTokens;
    uint256 maxIndexInvestmentAmount;
    uint256 minIndexInvestmentAmount;
    uint256 _managementFee;
    uint256 _performanceFee;
    uint256 _entryFee;
    uint256 _exitFee;
    bool _public;
    bool _transferable;
    bool _transferableToPublic;
    bool _whitelistTokens;
    string name;
    string symbol;
  }

  /**
   * @notice Struct having data for the Enable Rebalance (1st transaction) during ZeroEx's `Update Weight` call
   * @param _lpSlippage Array of LP Slippage values passed to the function
   * @param _newWeights Array of new weights for the rebalance
   */
  struct EnableRebalanceData {
    uint256[] _lpSlippage;
    uint96[] _newWeights;
  }

  /**
   * @notice Struct having data for the init of Asset Manager Config
   * @param _managementFee Management fee (streaming fee) that the asset manager will receive for managing the fund
   * @param _performanceFee Fee that the asset manager will receive for managing the fund and if the portfolio performance well
   * @param _entryFee Entry fee associated with the config
   * @param _exitFee Exit fee associated with the config
   * @param _minInvestmentAmount Minimum investment amount specified as per the config
   * @param _maxInvestmentAmount Maximum investment amount specified as per the config
   * @param _tokenRegistry Address of the Token Registry associated with the config
   * @param _accessController Address of the Access Controller associated with the config
   * @param _assetManagerTreasury Address of the Asset Manager Treasury account
   * @param _whitelistTokens Boolean parameter which specifies if the asset manager can only choose portfolio tokens from the whitelisted array or not
   * @param _publicPortfolio Boolean parameter for is the portfolio eligible for public investment or not
   * @param _transferable Boolean parameter for is the Index tokens from the fund transferable to public or not
   * @param _transferableToPublic Boolean parameter for is the Index tokens from the fund transferable to public or not
   * @param _whitelistTokens Boolean parameter for is the token whitelisting enabled for the fund or not
   */
  struct AssetManagerConfigInitData {
    uint256 _managementFee;
    uint256 _performanceFee;
    uint256 _entryFee;
    uint256 _exitFee;
    uint256 _minInvestmentAmount;
    uint256 _maxInvestmentAmount;
    address _tokenRegistry;
    address _accessController;
    address _assetManagerTreasury;
    address[] _whitelistedTokens;
    bool _publicPortfolio;
    bool _transferable;
    bool _transferableToPublic;
    bool _whitelistTokens;
  }

  /**
   * @notice Struct with data passed during the withdrawal from the Index Fund
   * @param _slippage Array of Slippage values passed for the withdrawal
   * @param _lpSlippage Array of LP Slippage values passed for the withdrawal
   * @param tokenAmount Amount of the Index Tokens that is to be withdrawn
   * @param _swapHandler Address of the swap handler being used for the withdrawal process
   * @param _token Address of the token being withdrawn to (must be a primary token)
   * @param isMultiAsset Boolean parameter for is the withdrawal being done in portfolio tokens (multi-token) or in the native token
   */
  struct WithdrawFund {
    uint256[] _slippage;
    uint256[] _lpSlippage;
    uint256 tokenAmount;
    address _swapHandler;
    address _token;
    bool isMultiAsset;
  }

  /**
   * @notice Struct with data passed during the investment into the Index Fund
   * @param _slippage Array of Slippage values passed for the investment
   * @param _lpSlippage Array of LP Slippage values passed for the deposit into LP protocols
   * @param _tokenAmount Amount of token being invested
   * @param _to Address that would receive the index tokens post successful investment
   * @param _swapHandler Address of the swap handler being used for the investment process
   * @param _token Address of the token being made investment in
   */
  struct InvestFund {
    uint256[] _slippage;
    uint256[] _lpSlippage;
    uint256 _tokenAmount;
    address _swapHandler;
    address _token;
  }

  /**
   * @notice Struct passed with values for the updation of tokens via the Rebalancing module
   * @param tokens Array of the new tokens that is to be updated to 
   * @param _swapHandler Address of the swap handler being used for the token update
   * @param denorms Denorms of the new tokens
   * @param _slippageSell Slippage allowed for the sale of tokens
   * @param _slippageBuy Slippage allowed for the purchase of tokens
   * @param _lpSlippageSell LP Slippage allowed for the sale of tokens
   * @param _lpSlippageBuy LP Slippage allowed for the purchase of tokens
   */
  struct UpdateTokens {
    address[] tokens;
    address _swapHandler;
    uint96[] denorms;
    uint256[] _slippageSell;
    uint256[] _slippageBuy;
    uint256[] _lpSlippageSell;
    uint256[] _lpSlippageBuy;
  }

  /**
   * @notice Struct having data for the redeem of tokens using the handlers for different protocols
   * @param _amount Amount of protocol tokens to be redeemed using the handler
   * @param _lpSlippage LP Slippage allowed for the redeem process
   * @param _to Address that would receive the redeemed tokens
   * @param _yieldAsset Address of the protocol token that is being redeemed against
   * @param isWETH Boolean parameter for is the redeem being done for WETH (native token) or not
   */
  struct RedeemData {
    uint256 _amount;
    uint256 _lpSlippage;
    address _to;
    address _yieldAsset;
    bool isWETH;
  }

  /**
   * @notice Struct having data for the setup of different roles during an Index Fund creation
   * @param _exchangeHandler Addresss of the Exchange handler for the fund
   * @param _index Address of the IndexSwap for the fund
   * @param _tokenRegistry Address of the Token Registry for the fund
   * @param _portfolioCreator Address of the account creating/deploying the portfolio
   * @param _rebalancing Address of the Rebalancing module for the fund
   * @param _offChainRebalancing Address of the Offchain-Rebalancing module for the fund
   * @param _rebalanceAggregator Address of the Rebalance Aggregator for the fund
   * @param _feeModule Address of the Fee Module for the fund
   * @param _offChainIndexSwap Address of the OffChain-IndexSwap for the fund
   */
  struct AccessSetup {
    address _exchangeHandler;
    address _index;
    address _tokenRegistry;
    address _portfolioCreator;
    address _rebalancing;
    address _offChainRebalancing;
    address _rebalanceAggregator;
    address _feeModule;
    address _offChainIndexSwap;
  }
}

// SPDX-License-Identifier: BUSL-1.1
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {RouterInterface} from "./interfaces/RouterInterface.sol";
import {SlippageControl} from "./SlippageControl.sol";
import {DustHandler} from "./DustHandler.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {FunctionParameters} from "../FunctionParameters.sol";
import {ErrorLibrary} from "../library/ErrorLibrary.sol";
import {LPInterface} from "./interfaces/LPInterface.sol";
import {Babylonian} from "@uniswap/lib/contracts/libraries/Babylonian.sol";
import {FactoryInterface} from "./interfaces/FactoryInterface.sol";
import {FullMath} from "./libraries/FullMath.sol";
import {IPriceOracle} from "../oracle/IPriceOracle.sol";
pragma solidity 0.8.16;

abstract contract UniswapV2LPHandler is SlippageControl, DustHandler {
  event VELVET_ADDED_LIQUIDITY(uint256[] amountProvided, uint256 minAmountA, uint256 minAmountB, uint256 liquidity);
  event VELVET_REMOVE_LIQUIDITY(uint256 liquidityProvided, uint256 amountA, uint256 amountB);

  function _approveAndDeposit(
    address[] memory underlying,
    address _router,
    uint256[] memory _amount,
    address _to
  ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
    TransferHelper.safeApprove(address(underlying[0]), _router, 0);
    TransferHelper.safeApprove(address(underlying[0]), _router, _amount[0]);
    TransferHelper.safeApprove(address(underlying[1]), _router, 0);
    TransferHelper.safeApprove(address(underlying[1]), _router, _amount[1]);
    (amountA, amountB, liquidity) = RouterInterface(_router).addLiquidity(
      address(underlying[0]),
      address(underlying[1]),
      _amount[0],
      _amount[1],
      1,
      1,
      _to,
      block.timestamp
    );
  }

  function _approveAndDepositETH(
    address[] memory underlying,
    address _router,
    uint256[] memory _amount,
    address _to
  ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
    RouterInterface router = RouterInterface(_router);
    uint256 i = underlying[0] == router.WETH() ? 1 : 0;
    TransferHelper.safeApprove(address(underlying[i]), _router, 0);
    TransferHelper.safeApprove(address(underlying[i]), _router, _amount[i]);
    (amountA, amountB, liquidity) = router.addLiquidityETH{value: msg.value}(
      underlying[i],
      _amount[i],
      1,
      1,
      _to,
      block.timestamp
    );
    (amountA, amountB) = sortReturnAmounts(i, amountA, amountB);
  }

  /**
   * @notice This function adds liquidity to the BiSwap protocol
   * @param _lpAsset Address of the protocol asset to be deposited
   * @param _amount Amount that is to be deposited
   * @param _lpSlippage LP slippage value passed to the function
   * @param _to Address that would receive the cTokens in return
   * @param routerAddress Address of the protocol called
   */
  function _deposit(
    address _lpAsset,
    uint256[] memory _amount,
    uint256 _lpSlippage,
    address _to,
    address routerAddress,
    address user,
    address _oracle,
    uint priceA,
    uint priceB
  ) internal returns (uint256 _mintedAmount) {
    if (_lpAsset == address(0) || _to == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    address[] memory underlying = _getUnderlyingTokens(_lpAsset);
    uint256 amountA;
    uint256 amountB;
    uint256 liquidity;
    if (msg.value == 0) {
      (amountA, amountB, liquidity) = _approveAndDeposit(underlying, routerAddress, _amount, _to);
    } else {
      (amountA, amountB, liquidity) = _approveAndDepositETH(underlying, routerAddress, _amount, _to);
    }
    uint256 lpSlippage = _lpSlippage;
    validateLPSlippage(underlying, amountA, amountB, priceA, priceB, lpSlippage);
    _returnDust(
      underlying[0],
      user // we need to pass user from exchange
    );
    _returnDust(
      underlying[1],
      user // we need to pass user from exchange
    );
    emit VELVET_ADDED_LIQUIDITY(_amount, amountA, amountB, liquidity);
    _mintedAmount = _calculatePriceForBalance(_lpAsset, _oracle, liquidity);
  }

  function _redeemETH(
    FunctionParameters.RedeemData calldata inputData,
    address[] memory _underlying,
    LPInterface _token,
    RouterInterface _router
  ) internal returns (uint256 amountA, uint256 amountB) {
    uint256 indexi = 0;
    uint256 indexj = 1;
    if (_underlying[0] == _router.WETH()) {
      indexi = 1;
      indexj = 0;
    }
    TransferHelper.safeApprove(address(_token), address(_router), 0);
    TransferHelper.safeApprove(address(_token), address(_router), inputData._amount);
    (amountA, amountB) = _router.removeLiquidityETH(
      _underlying[indexi],
      inputData._amount,
      1,
      1,
      inputData._to,
      block.timestamp
    );
    (amountA, amountB) = sortReturnAmounts(indexi, amountA, amountB);
  }

  function sortReturnAmounts(
    uint256 _nonETHTokenPosition,
    uint256 amountATemp,
    uint256 amountBTemp
  ) internal pure returns (uint256 amountA, uint256 amountB) {
    (amountA, amountB) = _nonETHTokenPosition == 0 ? (amountATemp, amountBTemp) : (amountBTemp, amountATemp);
  }

  /**
   * @notice This function remove liquidity from the called protocol
   */
  function _redeem(
    FunctionParameters.RedeemData calldata inputData,
    address routerAddress,
    uint priceA,
    uint priceB
  ) internal {
    if (inputData._yieldAsset == address(0) || inputData._to == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    LPInterface token = LPInterface(inputData._yieldAsset);
    if (inputData._amount > token.balanceOf(address(this))) {
      revert ErrorLibrary.NotEnoughBalanceInPancakeProtocol();
    }
    address[] memory underlying = _getUnderlyingTokens(inputData._yieldAsset);
    RouterInterface router = RouterInterface(routerAddress);
    uint256 amountA;
    uint256 amountB;
    if (inputData.isWETH) {
      (amountA, amountB) = _redeemETH(inputData, underlying, token, router);
    } else {
      TransferHelper.safeApprove(address(token), address(router), 0);
      TransferHelper.safeApprove(address(token), address(router), inputData._amount);
      (amountA, amountB) = router.removeLiquidity(
        underlying[0],
        underlying[1],
        inputData._amount,
        1,
        1,
        inputData._to,
        block.timestamp
      );
    }
    validateLPSlippage(underlying, amountA, amountB, priceA, priceB, inputData._lpSlippage);
    emit VELVET_REMOVE_LIQUIDITY(inputData._amount, amountA, amountB);
  }

  function _calculatePriceForBalance(
    address _token,
    address _oracle,
    uint256 _balance
  ) internal view returns (uint256 finalLPPrice) {
    if (_token == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    uint fairLPPrice = IPriceOracle(_oracle).getPriceForOneTokenInUSD(_token);
    uint256 _tokenDecimal = IERC20Metadata(_token).decimals();
    finalLPPrice = (fairLPPrice * _balance) / (10 ** _tokenDecimal);
  }

  /**
   * @notice This function returns address of the underlying asset
   * @param _lpToken Address of the protocol token whose underlying asset is needed
   * @return underlying Address of the underlying asset
   */
  function _getUnderlyingTokens(address _lpToken) internal view virtual returns (address[] memory) {
    if (_lpToken == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    address[] memory underlying = new address[](2);
    LPInterface token = LPInterface(_lpToken);
    underlying[0] = token.token0();
    underlying[1] = token.token1();
    return underlying;
  }

  /**
   * @notice This function returns the protocol token balance of the passed address
   * @param _tokenHolder Address whose balance is to be retrieved
   * @param t Address of the protocol token
   * @return tokenBalance t token balance of the holder
   */
  function _getTokenBalance(address _tokenHolder, address t) internal view returns (uint256 tokenBalance) {
    if (_tokenHolder == address(0) || t == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    LPInterface token = LPInterface(t);
    tokenBalance = token.balanceOf(_tokenHolder);
  }

  /**
   * @notice This function returns the protocol token balance of the passed address
   * @param _amountA Amount of token A from the LP
   * @param _amountA Amount of token A from the LP
   * @param _priceA Price of token A from the oracle
   * @param _priceB Price of token B from the oracle
   * @param _lpSlippage LP slippage sent by the user
   */
  function validateLPSlippage(
    address[] memory _underlying,
    uint _amountA,
    uint _amountB,
    uint _priceA,
    uint _priceB,
    uint _lpSlippage
  ) internal view {
    uint decimalFixedAmountA = (_amountA * (10 ** 18)) / (10 ** IERC20Metadata(_underlying[0]).decimals());
    uint decimalFixedAmountB = (_amountB * (10 ** 18)) / (10 ** IERC20Metadata(_underlying[1]).decimals());
    _validateLPSlippage(decimalFixedAmountA, decimalFixedAmountB, _priceA, _priceB, _lpSlippage);
  }
}

// SPDX-License-Identifier: BUSL-1.1

// ApeSwap Official Docs: https://apeswap.gitbook.io/apeswap-finance/welcome/master
// ApeSwap GitHub: https://github.com/ApeSwapFinance/

/**
 * @title Handler for the ApeSwap's LP protocol
 * @author Velvet.Capital
 * @notice This contract is used to add and remove liquidity
 *      to/from the ApeSwap protocol.
 * @dev This contract includes functionalities:
 *      1. Add liquidity to the ApeSwap protocol
 *      2. Remove liquidity from the ApeSwap protocol
 *      3. Get underlying asset address
 *      4. Get protocol token balance
 *      5. Get underlying asset balance
 */

pragma solidity 0.8.16;

import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable-4.3.2/proxy/utils/Initializable.sol";
import {Ownable} from "@openzeppelin/contracts-4.8.2/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {LPInterface} from "../interfaces/LPInterface.sol";
import {RouterInterface} from "../interfaces/RouterInterface.sol";
import {FactoryInterface} from "../interfaces/FactoryInterface.sol";
import {IMasterChef} from "./interfaces/IMasterChef.sol";

import {Babylonian} from "@uniswap/lib/contracts/libraries/Babylonian.sol";
import {IPriceOracle} from "../../oracle/IPriceOracle.sol";
import {IHandler} from "../IHandler.sol";

import {FullMath} from "../libraries/FullMath.sol";
import {ErrorLibrary} from "./../../library/ErrorLibrary.sol";
import {SlippageControl} from "../SlippageControl.sol";
import {FunctionParameters} from "../../FunctionParameters.sol";
import {UniswapV2LPHandler} from "../AbstractLPHandler.sol";
import {Denominations} from "@chainlink/contracts/src/v0.8/Denominations.sol";

contract ApeSwapLPHandler is IHandler, SlippageControl, UniswapV2LPHandler {
  IPriceOracle internal _oracle;

  RouterInterface internal router;
  uint256 internal constant DIVISOR_INT = 10_000;

  mapping(address => uint256) pid;

  event Deposit(address indexed user, address indexed token, uint256[] amounts, address indexed to);
  event Redeem(
    address indexed user,
    address indexed token,
    uint256 amount,
    address indexed to,
    bool isWETH
  );

  /**
   * @param _priceOracle address of price oracle
   * @param _routerAddress address of apwSwapLp protocol router used for deposit and withdraw non-ETH
   */
  constructor(address _priceOracle, address _routerAddress) {
    if (_priceOracle == address(0) || _routerAddress == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    router = RouterInterface(_routerAddress);
    _oracle = IPriceOracle(_priceOracle);
  }

  /**
   * @notice This function adds liquidity to the PancakeSwap protocol
   * @param _lpAsset Address of the protocol asset to be deposited
   * @param _amount Amount that is to be deposited
   * @param _lpSlippage LP slippage value passed to the function
   * @param _to Address that would receive the cTokens in return
   */
  function deposit(
    address _lpAsset,
    uint256[] memory _amount,
    uint256 _lpSlippage,
    address _to,
    address user
  ) public payable override returns (uint256 _mintedAmount) {
    address[] memory t = getUnderlying(_lpAsset);
    uint p1 = _oracle.getPriceForOneTokenInUSD(t[0]);
    uint p2 = _oracle.getPriceForOneTokenInUSD(t[1]);
    _mintedAmount = _deposit(_lpAsset, _amount, _lpSlippage, _to, address(router), user, address(_oracle), p1, p2);
    emit Deposit(msg.sender, _lpAsset, _amount, _to);
  }

  /**
   * @notice This function remove liquidity from the PancakeSwap protocol
   */
  function redeem(FunctionParameters.RedeemData calldata inputData) public override {
    address[] memory t = getUnderlying(inputData._yieldAsset);
    uint p1 = _oracle.getPriceForOneTokenInUSD(t[0]);
    uint p2 = _oracle.getPriceForOneTokenInUSD(t[1]);
    _redeem(inputData, address(router), p1, p2);
    emit Redeem(msg.sender, inputData._yieldAsset, inputData._amount, inputData._to, inputData.isWETH);
  }

  /**
   * @notice This function returns address of the underlying asset
   * @param _lpToken Address of the protocol token whose underlying asset is needed
   * @return underlying Address of the underlying asset
   */
  function getUnderlying(address _lpToken) public view override returns (address[] memory) {
    return _getUnderlyingTokens(_lpToken);
  }

  /**
   * @notice This function returns the protocol token balance of the passed address
   * @param _tokenHolder Address whose balance is to be retrieved
   * @param t Address of the protocol token
   * @return tokenBalance t token balance of the holder
   */
  function getTokenBalance(address _tokenHolder, address t) public view override returns (uint256 tokenBalance) {
    return _getTokenBalance(_tokenHolder, t);
  }

  /**
   * @notice This function returns the USD value of the LP asset using Fair LP Price model
   * @param _tokenHolder Address whose balance is to be retrieved
   * @param t Address of the protocol token
   */
  function getTokenBalanceUSD(address _tokenHolder, address t) public view override returns (uint256) {
    if (t == address(0) || _tokenHolder == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    return _calculatePriceForBalance(t, address(_oracle),_getTokenBalance(_tokenHolder, t));
  }

  /**
   * @notice This function allows to map token addresses to their protocol's pid value
   */
  function pidMap(address[] calldata _lpTokens, uint256[] calldata _pid) external onlyOwner {
    if (_lpTokens.length != _pid.length) {
      revert ErrorLibrary.InvalidLength();
    }
    uint256 len = _lpTokens.length;
    for (uint256 i = 0; i < len; i++) {
      pid[_lpTokens[i]] = _pid[i];
    }
  }

  /**
   * @notice This function allows to remove entries from the pid map
   */
  function removePidMap(address[] calldata _lpTokens, uint256[] calldata _pid) external onlyOwner {
    if (_lpTokens.length != _pid.length) {
      revert ErrorLibrary.InvalidLength();
    }
    uint256 len = _lpTokens.length;
    for (uint256 i = 0; i < len; i++) {
      if (pid[_lpTokens[i]] != _pid[i]) revert ErrorLibrary.InvalidPID();
      delete (pid[_lpTokens[i]]);
    }
  }

  function getUnderlyingBalance(address _tokenHolder, address t) public override returns (uint256[] memory) {}

  function encodeData(address t, uint256 _amount) public returns (bytes memory) {}

  function getRouterAddress() public view returns (address) {}

  function getClaimTokenCalldata(address _token, address) public view returns (bytes memory, address) {}

  receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface IMasterChef {
  function deposit(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {ISwapHandler} from "../handler/ISwapHandler.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/token/ERC20/IERC20Upgradeable.sol";
import {ErrorLibrary} from "../library/ErrorLibrary.sol";

abstract contract DustHandler {
  address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

  // after investment if we can't deposit everything we might have underlying tokens left, no need to deposit/redeem - only swap
  function _returnDust(address _token, address _to) internal {
    if (_token == WETH) {
      (bool success, ) = payable(_to).call{value: address(this).balance}("");
      if (!success) revert ErrorLibrary.TransferFailed();
    } else {
      uint balance = IERC20Upgradeable(_token).balanceOf(address(this));
      TransferHelper.safeTransfer(_token, _to, balance);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

// lend token
// redeem token
// claim token
// get token balance
// get underlying balance

pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IHandler {
  function deposit(address, uint256[] memory, uint256, address, address) external payable returns (uint256);

  function redeem(FunctionParameters.RedeemData calldata inputData) external;

  function getTokenBalance(address, address) external view returns (uint256);

  function getUnderlyingBalance(address, address) external returns (uint256[] memory);

  function getUnderlying(address) external view returns (address[] memory);

  function getRouterAddress() external view returns (address);

  function encodeData(address t, uint256 _amount) external returns (bytes memory);

  function getClaimTokenCalldata(address _alpacaToken, address _holder) external returns (bytes memory, address);

  function getTokenBalanceUSD(address _tokenHolder, address t) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface FactoryInterface {
  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function feeTo() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface LPInterface {
  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(address from, address to, uint value) external returns (bool);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function kLast() external view returns (uint);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface RouterInterface {
  function WETH() external view returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface ISwapHandler {
  function getETH() external view returns (address);

  function getSwapAddress(uint256 _swapAmount, address _t) external view returns (address);

  function swapTokensToETH(uint256 _swapAmount, uint256 _slippage, address _t, address _to, bool isEnabled) external returns (uint256);

  function swapETHToTokens(uint256 _slippage, address _t, address _to) external payable returns (uint256);

  function swapTokenToTokens(
    uint256 _swapAmount,
    uint256 _slippage,
    address _tokenIn,
    address _tokenOut,
    address _to,
    bool isEnabled
  ) external returns (uint256 swapResult);

  function getPathForETH(address crypto) external view returns (address[] memory);

  function getPathForToken(address token) external view returns (address[] memory);

  function getSlippage(
    uint256 _amount,
    uint256 _slippage,
    address[] memory path
  ) external view returns (uint256 minAmount);
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity 0.8.16;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
import {ErrorLibrary} from "contracts/library/ErrorLibrary.sol";
library FullMath {
  function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
    uint256 mm = mulmod(x, y, type(uint).max);
    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }

  function fullDiv(uint256 l, uint256 h, uint256 d) private pure returns (uint256) {
    uint256 pow2 = d & (type(uint256).max - d + 1);
    d /= pow2;
    l /= pow2;
    l += h * (((type(uint256).max - pow2 + 1)) / pow2 + 1);
    uint256 r = 1;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    return l * r;
  }

  function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
    (uint256 l, uint256 h) = fullMul(x, y);

    uint256 mm = mulmod(x, y, d);
    if (mm > l) h -= 1;
    l -= mm;

    if (h == 0) return l / d;

    if(h >= d)
      revert ErrorLibrary.FULLDIV_OVERFLOW();
    return fullDiv(l, h, d);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {Ownable} from "@openzeppelin/contracts-4.8.2/access/Ownable.sol";

import {ErrorLibrary} from "../library/ErrorLibrary.sol";

/*
  This contract is for LP slippage to protect the users of an imbalanced pool
 */
abstract contract SlippageControl is Ownable {
  uint256 public maxSlippage;

  uint256 public constant HUNDRED_PERCENT = 10_000;

  event AddOrUpdateProtocolSlippage(uint256 _slippage);

  /**
   * @notice This function updates/adds max slippage allowed
   */
  function addOrUpdateProtocolSlippage(uint256 _slippage) public onlyOwner {
    if (_slippage >= HUNDRED_PERCENT) {
      revert ErrorLibrary.IncorrectSlippageRange();
    }
    maxSlippage = _slippage;
    emit AddOrUpdateProtocolSlippage(_slippage);
  }

  /**
   * @notice This function calculates slippage from the called protocol
   */
  function getSlippage(uint256 _amount, uint256 _lpSlippage) internal view returns (uint256 minAmount) {
    if (maxSlippage < _lpSlippage) {
      revert ErrorLibrary.InvalidLPSlippage();
    }
    minAmount = (_amount * (HUNDRED_PERCENT - _lpSlippage)) / (HUNDRED_PERCENT);
  }

  /**
   * @notice This function validates liquidity slippage from the called protocol
   * @param _amountA The amount of tokenA used by the protocol
   * @param _amountB The amount of tokenB used by the protocol
   * @param _priceA The price of tokenA
   * @param _priceB The price of tokenB
   * @param _lpSlippage The max slippage between tokenA and tokenB accepted
   */
  function _validateLPSlippage(
    uint _amountA,
    uint _amountB,
    uint _priceA,
    uint _priceB,
    uint _lpSlippage
  ) internal view {
    if (maxSlippage < _lpSlippage) {
      revert ErrorLibrary.InvalidLPSlippage();
    }
    uint decimal = 10 ** 18;
    /**
     *  amountA * priceA = amountB * priceB ( in ideal scenario )
     *  amountA/amountB - priceB/priceA = 0
     *  When the amount of either token is not fully accepted then the
     *  amountA and amountB wont be equal to 0 and that becomes our lpSlippage
     */

    uint amountDivision = (_amountA * decimal) / (_amountB); // 18 decimals 
    uint priceDivision = (_priceB * decimal) / (_priceA); // 18 decimals
    uint absoluteValue = 0;
    if (amountDivision > priceDivision) {
      absoluteValue = amountDivision - priceDivision; // 18 decimals
    } else {
      absoluteValue = priceDivision - amountDivision; // 18 decimals
    }
    uint256 percentageDifference = (absoluteValue * decimal) / priceDivision;
    if (percentageDifference * HUNDRED_PERCENT > (_lpSlippage * decimal)) {
      revert ErrorLibrary.InvalidAmount();
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

/**
 * @title ErrorLibrary
 * @author Velvet.Capital
 * @notice This is a library contract including custom defined errors
 */

library ErrorLibrary {
  error ContractPaused();
  /// @notice Thrown when caller is not rebalancer contract
  error CallerNotRebalancerContract();
  /// @notice Thrown when caller is not asset manager
  error CallerNotAssetManager();
  /// @notice Thrown when caller is not asset manager
  error CallerNotSuperAdmin();
  /// @notice Thrown when caller is not whitelist manager
  error CallerNotWhitelistManager();
  /// @notice Thrown when length of slippage array is not equal to tokens array
  error InvalidSlippageLength();
  /// @notice Thrown when length of tokens array is zero
  error InvalidLength();
  /// @notice Thrown when token is not permitted
  error TokenNotPermitted();
  /// @notice Thrown when user is not allowed to invest
  error UserNotAllowedToInvest();
  /// @notice Thrown when index token in not initialized
  error NotInitialized();
  /// @notice Thrown when investment amount is greater than or less than the set range
  error WrongInvestmentAmount(uint256 minInvestment, uint256 maxInvestment);
  /// @notice Thrown when swap amount is greater than BNB balance of the contract
  error NotEnoughBNB();
  /// @notice Thrown when the total sum of weights is not equal to 10000
  error InvalidWeights(uint256 totalWeight);
  /// @notice Thrown when balance is below set velvet min investment amount
  error BalanceCantBeBelowVelvetMinInvestAmount(uint256 minVelvetInvestment);
  /// @notice Thrown when caller is not holding underlying token amount being swapped
  error CallerNotHavingGivenTokenAmount();
  /// @notice Thrown when length of denorms array is not equal to tokens array
  error InvalidInitInput();
  /// @notice Thrown when the tokens are already initialized
  error AlreadyInitialized();
  /// @notice Thrown when the token is not whitelisted
  error TokenNotWhitelisted();
  /// @notice Thrown when denorms array length is zero
  error InvalidDenorms();
  /// @notice Thrown when token address being passed is zero
  error InvalidTokenAddress();
  /// @notice Thrown when token is not permitted
  error InvalidToken();
  /// @notice Thrown when token is not approved
  error TokenNotApproved();
  /// @notice Thrown when transfer is prohibited
  error Transferprohibited();
  /// @notice Thrown when transaction caller balance is below than token amount being invested
  error LowBalance();
  /// @notice Thrown when address is already approved
  error AddressAlreadyApproved();
  /// @notice Thrown when swap handler is not enabled inside token registry
  error SwapHandlerNotEnabled();
  /// @notice Thrown when swap amount is zero
  error ZeroBalanceAmount();
  /// @notice Thrown when caller is not index manager
  error CallerNotIndexManager();
  /// @notice Thrown when caller is not fee module contract
  error CallerNotFeeModule();
  /// @notice Thrown when lp balance is zero
  error LpBalanceZero();
  /// @notice Thrown when desired swap amount is greater than token balance of this contract
  error InvalidAmount();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInAlpacaProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountMustBeEqualToValue();
  /// @notice Thrown when the mint function returned 0 for success & 1 for failure
  error MintProcessFailed();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInApeSwap();
  /// @notice Thrown when the redeeming was success(0) or failure(1)
  error RedeemingCTokenFailed();
  /// @notice Thrown when native BNB is sent for any vault other than mooVenusBNB
  error PleaseDepositUnderlyingToken();
  /// @notice Thrown when redeem amount is greater than tokenBalance of protocol
  error NotEnoughBalanceInBeefyProtocol();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInBeefy();
  /// @notice Thrown when the deposit amount of underlying token A is more than contract balance
  error InsufficientTokenABalance();
  /// @notice Thrown when the deposit amount of underlying token B is more than contract balance
  error InsufficientTokenBBalance();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInBiSwapProtocol();
  //Not enough funds
  error InsufficientFunds(uint256 available, uint256 required);
  //Not enough eth for protocol fee
  error InsufficientFeeFunds(uint256 available, uint256 required);
  //Order success but amount 0
  error ZeroTokensSwapped();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInLiqeeProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountMustBeEqualToValuePassed();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInPancakeProtocol();
  /// @notice Thrown when Pid passed is not equal to Pid stored in Pid map
  error InvalidPID();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error InsufficientBalance();
  /// @notice Thrown when the redeem function returns 1 for fail & 0 for success
  error RedeemingFailed();
  /// @notice Thrown when the token passed in getUnderlying is not cToken
  error NotcToken();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInWombatProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountNotEqualToPassedValue();
  /// @notice Thrown when slippage value passed is greater than 100
  error SlippageCannotBeGreaterThan100();
  /// @notice Thrown when tokens are already staked
  error TokensStaked();
  /// @notice Thrown when contract is not paused
  error ContractNotPaused();
  /// @notice Thrown when offchain handler is not valid
  error OffHandlerNotValid();
  /// @notice Thrown when offchain handler is not enabled
  error OffHandlerNotEnabled();
  /// @notice Thrown when swapHandler is not enabled
  error SwaphandlerNotEnabled();
  /// @notice Thrown when account other than asset manager calls
  error OnlyAssetManagerCanCall();
  /// @notice Thrown when already redeemed
  error AlreadyRedeemed();
  /// @notice Thrown when contract is not paused
  error NotPaused();
  /// @notice Thrown when token is not index token
  error TokenNotIndexToken();
  /// @notice Thrown when swaphandler is invalid
  error SwapHandlerNotValid();
  /// @notice Thrown when token that will be bought is invalid
  error BuyTokenAddressNotValid();
  /// @notice Thrown when not redeemed
  error NotRedeemed();
  /// @notice Thrown when caller is not asset manager
  error CallerIsNotAssetManager();
  /// @notice Thrown when account other than asset manager is trying to pause
  error OnlyAssetManagerCanCallUnpause();
  /// @notice Thrown when trying to redeem token that is not staked
  error TokensNotStaked();
  /// @notice Thrown when account other than asset manager is trying to revert or unpause
  error FifteenMinutesNotExcedeed();
  /// @notice Thrown when swapping weight is zero
  error WeightNotGreaterThan0();
  /// @notice Thrown when dividing by zero
  error DivBy0Sumweight();
  /// @notice Thrown when lengths of array are not equal
  error LengthsDontMatch();
  /// @notice Thrown when contract is not paused
  error ContractIsNotPaused();
  /// @notice Thrown when set time period is not over
  error TimePeriodNotOver();
  /// @notice Thrown when trying to set any fee greater than max allowed fee
  error InvalidFee();
  /// @notice Thrown when zero address is passed for treasury
  error ZeroAddressTreasury();
  /// @notice Thrown when assetManagerFee or performaceFee is set zero
  error ZeroFee();
  /// @notice Thrown when trying to enable an already enabled handler
  error HandlerAlreadyEnabled();
  /// @notice Thrown when trying to disable an already disabled handler
  error HandlerAlreadyDisabled();
  /// @notice Thrown when zero is passed as address for oracle address
  error InvalidOracleAddress();
  /// @notice Thrown when zero is passed as address for handler address
  error InvalidHandlerAddress();
  /// @notice Thrown when token is not in price oracle
  error TokenNotInPriceOracle();
  /// @notice Thrown when address is not approved
  error AddressNotApproved();
  /// @notice Thrown when minInvest amount passed is less than minInvest amount set
  error InvalidMinInvestmentAmount();
  /// @notice Thrown when maxInvest amount passed is greater than minInvest amount set
  error InvalidMaxInvestmentAmount();
  /// @notice Thrown when zero address is being passed
  error InvalidAddress();
  /// @notice Thrown when caller is not the owner
  error CallerNotOwner();
  /// @notice Thrown when out asset address is zero
  error InvalidOutAsset();
  /// @notice Thrown when protocol is not paused
  error ProtocolNotPaused();
  /// @notice Thrown when protocol is paused
  error ProtocolIsPaused();
  /// @notice Thrown when proxy implementation is wrong
  error ImplementationNotCorrect();
  /// @notice Thrown when caller is not offChain contract
  error CallerNotOffChainContract();
  /// @notice Thrown when user has already redeemed tokens
  error TokenAlreadyRedeemed();
  /// @notice Thrown when user has not redeemed tokens
  error TokensNotRedeemed();
  /// @notice Thrown when user has entered wrong amount
  error InvalidSellAmount();
  /// @notice Thrown when trasnfer fails
  error WithdrawTransferFailed();
  /// @notice Thrown when caller is not having minter role
  error CallerNotMinter();
  /// @notice Thrown when caller is not handler contract
  error CallerNotHandlerContract();
  /// @notice Thrown when token is not enabled
  error TokenNotEnabled();
  /// @notice Thrown when index creation is paused
  error IndexCreationIsPause();
  /// @notice Thrown denorm value sent is zero
  error ZeroDenormValue();
  /// @notice Thrown when asset manager is trying to input token which already exist
  error TokenAlreadyExist();
  /// @notice Thrown when cool down period is not passed
  error CoolDownPeriodNotPassed();
  /// @notice Thrown When Buy And Sell Token Are Same
  error BuyAndSellTokenAreSame();
  /// @notice Throws arrow when token is not a reward token
  error NotRewardToken();
  /// @notice Throws arrow when MetaAggregator Swap Failed
  error SwapFailed();
  /// @notice Throws arrow when Token is Not  Primary
  error NotPrimaryToken();
  /// @notice Throws when the setup is failed in gnosis
  error ModuleNotInitialised();
  /// @notice Throws when threshold is more than owner length
  error InvalidThresholdLength();
  /// @notice Throws when no owner address is passed while fund creation
  error NoOwnerPassed();
  /// @notice Throws when length of underlying token is greater than 1
  error InvalidTokenLength();
  /// @notice Throws when already an operation is taking place and another operation is called
  error AlreadyOngoingOperation();
  /// @notice Throws when wrong function is executed for revert offchain fund
  error InvalidExecution();
  /// @notice Throws when Final value after investment is zero
  error ZeroFinalInvestmentValue();
  /// @notice Throws when token amount after swap / token amount to be minted comes out as zero
  error ZeroTokenAmount();
  /// @notice Throws eth transfer failed
  error ETHTransferFailed();
  /// @notice Thorws when the caller does not have a default admin role
  error CallerNotAdmin();
  /// @notice Throws when buyAmount is not correct in offchainIndexSwap
  error InvalidBuyValues();
  /// @notice Throws when token is not primary
  error TokenNotPrimary();
  /// @notice Throws when tokenOut during withdraw is not permitted in the asset manager config
  error _tokenOutNotPermitted();
  /// @notice Throws when token balance is too small to be included in index
  error BalanceTooSmall();
  /// @notice Throws when a public fund is tried to made transferable only to whitelisted addresses
  error PublicFundToWhitelistedNotAllowed();
  /// @notice Throws when list input by user is invalid (meta aggregator)
  error InvalidInputTokenList();
  /// @notice Generic call failed error
  error CallFailed();
  /// @notice Generic transfer failed error
  error TransferFailed();
  /// @notice Throws when handler underlying token is not ETH
  error TokenNotETH();  
   /// @notice Thrown when the token passed in getUnderlying is not vToken
  error NotVToken();
  /// @notice Throws when incorrect token amount is encountered during offchain/onchain investment
  error IncorrectInvestmentTokenAmount();
  /// @notice Throws when final invested amount after slippage is 0
  error ZeroInvestedAmountAfterSlippage();
  /// @notice Throws when the slippage trying to be set is in incorrect range
  error IncorrectSlippageRange();
  /// @notice Throws when invalid LP slippage is passed
  error InvalidLPSlippage();
  /// @notice Throws when invalid slippage for swapping is passed
  error InvalidSlippage();
  /// @notice Throws when msg.value is less than the amount passed into the handler
  error WrongNativeValuePassed();
  /// @notice Throws when there is an overflow during muldiv full math operation
  error FULLDIV_OVERFLOW();
  /// @notice Throws when the oracle price is not updated under set timeout
  error PriceOracleExpired();
  /// @notice Throws when the oracle price is returned 0
  error PriceOracleInvalid();
  /// @notice Throws when the initToken or updateTokenList function of IndexSwap is having more tokens than set by the Registry
  error TokenCountOutOfLimit(uint256 limit);
  /// @notice Throws when the array lenghts don't match for adding price feed or enabling tokens
  error IncorrectArrayLength();
  /// @notice Common Reentrancy error for IndexSwap and IndexSwapOffChain
  error ReentrancyGuardReentrantCall();
  /// @notice Throws when user calls updateFees function before proposing a new fee
  error NoNewFeeSet();
  /// @notice Throws when wrong asset is supplied to the Compound v3 Protocol
  error WrongAssetBeingSupplied();
  /// @notice Throws when wrong asset is being withdrawn from the Compound v3 Protocol
  error WrongAssetBeingWithdrawn();
  /// @notice Throws when sequencer is down
  error SequencerIsDown();
  /// @notice Throws when sequencer threshold is not crossed
  error SequencerThresholdNotCrossed();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IPriceOracle {
  function WETH() external returns(address);

  function _addFeed(address base, address quote, AggregatorV2V3Interface aggregator) external;

  function decimals(address base, address quote) external view returns (uint8);

  function latestRoundData(address base, address quote) external view returns (int256);

  function getUsdEthPrice(uint256 amountIn) external view returns (uint256 amountOut);

  function getEthUsdPrice(uint256 amountIn) external view returns (uint256 amountOut);

  function getPrice(address base, address quote) external view returns (int256);

  function getPriceForAmount(address token, uint256 amount, bool ethPath) external view returns (uint256 amountOut);

  function getPriceForTokenAmount(
    address tokenIn,
    address tokenOut,
    uint256 amount
  ) external view returns (uint256 amountOut);

  function getPriceTokenUSD18Decimals(address _base, uint256 amountIn) external view returns (uint256 amountOut);

  function getPriceForOneTokenInUSD(address _base) external view returns (uint256 amountOut);
}