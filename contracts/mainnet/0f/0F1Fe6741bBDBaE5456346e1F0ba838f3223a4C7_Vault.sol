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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/**
 * @dev Interface of the Plugin standard.
 */
interface IPlugin {
    enum ActionType {
        // Action types
        Stake,
        Unstake,
        SwapTokens,
        ClaimRewards
    }

    function execute(ActionType _actionType, bytes calldata _payload) external payable;
    
    function getTotalLiquidity() external view returns (uint256);

    function getPoolNumber() external view returns(uint256);

    function getAllowedTokens(uint256 _poolId) external view returns (address[] memory tokens);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenPriceConsumer is Ownable {
    mapping(address => AggregatorV3Interface) private tokenPriceFeeds;

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses) {
        require(tokenAddresses.length == priceFeedAddresses.length, "Arrays length mismatch");

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            tokenPriceFeeds[tokenAddresses[i]] = AggregatorV3Interface(priceFeedAddresses[i]);
        }
    }

    function addPriceFeed(address tokenAddress, address priceFeedAddress) public onlyOwner {
        require(priceFeedAddress != address(0), "Invalid address");
        require(address(tokenPriceFeeds[tokenAddress]) == address(0), "PriceFeed already exist");
        tokenPriceFeeds[tokenAddress] = AggregatorV3Interface(priceFeedAddress);
    }

    function removePriceFeed(address tokenAddress) public onlyOwner {
        require(address(tokenPriceFeeds[tokenAddress]) != address(0), "PriceFeed already exist");
        tokenPriceFeeds[tokenAddress] = AggregatorV3Interface(address(0));
    }

    function getTokenPrice(address tokenAddress) public view returns (uint256) {
        AggregatorV3Interface priceFeed = tokenPriceFeeds[tokenAddress];
        require(address(priceFeed) != address(0), "Price feed not found");

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // Token price might need additional scaling based on decimals
        return uint256(answer);
    }

    function decimals(address tokenAddress) public view returns (uint8) {
        AggregatorV3Interface priceFeed = tokenPriceFeeds[tokenAddress];
        require(address(priceFeed) != address(0), "Price feed not found");
        return priceFeed.decimals();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

// Libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import "./interfaces/IPlugin.sol";
import "./TokenPriceConsumer.sol";

contract Vault is Ownable, ERC20, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    // Enum representing the status of the protocol.
    enum Status {
        Normal,   // Indicates normal operational status.
        Pending  // Indicates pending or transitional status.
    }

    // Struct defining the properties of a Plugin.
    struct Plugin {
        address pluginAddress;  // Address of the plugin contract.
        uint256 pluginId;       // Unique identifier for the plugin.
    }

    // Struct containing withdrawal information.
    struct WithdrawalInfo {
        address userAddress;     // Address of the user initiating the withdrawal.
        address tokenAddress;    // Address of the token being withdrawn.
        uint256 lpAmount;        // Amount of LP (Liquidity Provider) tokens to be withdrawn.
    }

    // Constant representing the number of decimals for the MOZAIC token.
    uint256 public constant MOZAIC_DECIMALS = 6;

    // Constant representing the number of decimals for the ASSET.
    uint256 public constant ASSET_DECIMALS = 36;

    /* ========== STATE VARIABLES ========== */
    // Stores the address of the master contract.
    address public master;

    // Stores the address of the treasury, which is payable for receiving funds.
    address payable public treasury;

    // Stores the address of the token price consumer contract.
    address public tokenPriceConsumer;

    // Maps plugin IDs to their respective index.
    mapping(uint256 => uint256) public pluginIdToIndex;

    // An array to store instances of the Plugin struct.
    Plugin[] public plugins;

    // An array to store withdrawal requests information.
    WithdrawalInfo[] public withdrawalRequests;

    // An array to store pending withdrawal requests information.
    WithdrawalInfo[] public pendingWithdrawalRequests;

    // Represents the current status of the protocol.
    Status public protocolStatus;

    // Maps token addresses to boolean values indicating whether the token is accepted.
    mapping(address => bool) public acceptedTokenMap;

    // An array of accepted token addresses.
    address[] public acceptedTokens;

    // Maps token addresses to boolean values indicating whether deposits are allowed for the token.
    mapping(address => bool) public depositAllowedTokenMap;

    // An array of token addresses for which deposits are allowed.
    address[] public depositAllowedTokens;

    // Maps token addresses to boolean values indicating whether withdrawals are allowed for the token.
    mapping(address => bool) public withdrawalTokenMap;

    // An array of token addresses for which withdrawals are allowed.
    address[] public withdrawalTokens;

    // Stores the ID of the currently selected plugin.
    uint256 public selectedPluginId;

    // Stores the ID of the currently selected pool.
    uint256 public selectedPoolId;

    uint256 public lpRate = 1e18;
    uint256 public protocolFeePercentage;
    uint256 public protocolFeeInVault;

    uint256 public depositMinExecFee;
    uint256 public withdrawMinExecFee;

    uint256 public constant BP_DENOMINATOR = 1e4;
    uint256 public constant MAX_FEE = 1e3;

    /* ========== EVENTS ========== */
    event AddPlugin(uint256 _pluginId, address _pluginAddress);
    event RemovePlugin(uint256 _pluginId);
    event Execute(uint8 _pluginId, IPlugin.ActionType _actionType, bytes _payload);
    event MasterUpdated(address _oldMaster, address _newMaster);
    event TokenPriceConsumerUpdated(address _oldTokenPriceConsumer, address _newTokenPriceConsumer);
    event SetTreasury(address payable treasury);
    event UpdatedProtocolStatus(Status _newStatus);
    event SetProtocolFeePercentage(uint256 _protocolFeePercentage);
    event SetExecutionFee(uint256 _depositMinExecFee, uint256 _withdrawMinExecFee);

    event AddAcceptedToken(address _token);
    event RemoveAcceptedToken(address _token);
    event AddDepositAllowedToken(address _token);
    event RemoveDepositAllowedToken(address _token);
    event AddWithdrawalToken(address _token);
    event RemoveWithdrawalToken(address _token);

    event AddDepositRequest(address _token, uint256 _amount);
    event AddWithdrawRequest(WithdrawalInfo _info);
    event SettleWithdrawRequest();
    event SelectPluginAndPool(uint256 _pluginId, uint256 _poolId);
    event ApproveTokens(uint8 _pluginId, address[] _tokens, uint256[] _amounts);

    event WithdrawProtocolFee(address _token, uint256 _amount);

    /* ========== MODIFIERS ========== */
    // Modifier allowing only the master contract to execute the function.
    modifier onlyMaster() {
        require(msg.sender == master, "Vault: caller must be master");
        _;
    }

    // Modifier allowing only the master contract or the vault itself to execute the function.
    modifier onlyMasterOrSelf() {
        require(msg.sender == master || msg.sender == address(this), "Vault: caller must be master or self");
        _;
    }

    /* ========== CONFIGURATION ========== */
    // Constructor for the Arbitrum LPToken contract, inheriting from ERC20.
    constructor() ERC20("Arbitrum LPToken", "mozLP") {
    }

    // Allows the owner to set a new master address for the Vault.
    function setMaster(address _newMaster) external onlyOwner {
        // Ensure that the new master address is valid.
        require(_newMaster != address(0), "Vault: Invalid Address");

        // Store the current master address before updating.
        address _oldMaster = master;

        // Update the master address to the new value.
        master = _newMaster;

        // Emit an event to log the master address update.
        emit MasterUpdated(_oldMaster, _newMaster);
    }

    // Allows the owner to set the address of the token price consumer contract.
    function setTokenPriceConsumer(address _tokenPriceConsumer) public onlyOwner {
        // Ensure that the new token price consumer address is valid.
        require(_tokenPriceConsumer != address(0), "Vault: Invalid Address");

        // Store the current token price consumer address before updating.
        address _oldTokenPriceConsumer = tokenPriceConsumer;

        // Update the token price consumer address to the new value.
        tokenPriceConsumer = _tokenPriceConsumer;

        // Emit an event to log the token price consumer address update.
        emit TokenPriceConsumerUpdated(_oldTokenPriceConsumer, _tokenPriceConsumer);
    }

    // Allows the owner to set the address of the treasury.
    function setTreasury(address payable _treasury) public onlyOwner {
        // Ensure that the new treasury address is valid.
        require(_treasury != address(0), "Vault: Invalid address");

        // Update the treasury address to the new value.
        treasury = _treasury;

        // Emit an event to log the treasury address update.
        emit SetTreasury(_treasury);
    }

    // Allows the master contract to select a plugin and pool.
    function selectPluginAndPool(uint256 _pluginId, uint256 _poolId) onlyMaster public {
        // Ensure that both the pluginId and poolId are valid and not zero.
        require(_pluginId != 0 && _poolId != 0, "Vault: Invalid pluginId or poolId");

        // Set the selectedPluginId and selectedPoolId to the provided values.
        selectedPluginId = _pluginId;
        selectedPoolId = _poolId;
        emit SelectPluginAndPool(_pluginId, _poolId);
    }

    function setExecutionFee(uint256 _depositMinExecFee, uint256 _withdrawMinExecFee) onlyMaster public {
        depositMinExecFee = _depositMinExecFee;
        withdrawMinExecFee = _withdrawMinExecFee;
        emit SetExecutionFee(_depositMinExecFee, _withdrawMinExecFee);
    }

    // Allows the owner to add a new accepted token.
    function addAcceptedToken(address _token) external onlyOwner {
        // Check if the token does not already exist in the accepted tokens mapping.
        if (acceptedTokenMap[_token] == false) {
            // Set the token as accepted, add it to the acceptedTokens array, and emit an event.
            acceptedTokenMap[_token] = true;
            acceptedTokens.push(_token);
            emit AddAcceptedToken(_token);
        } else {
            // Revert if the token already exists in the accepted tokens.
            revert("Vault: Token already exists.");
        }
    }

    // Allows the owner to remove an accepted token.
    function removeAcceptedToken(address _token) external onlyOwner {
        // Check if the token exists in the accepted tokens mapping.
        if (acceptedTokenMap[_token] == true) {
            // Set the token as not accepted, remove it from the acceptedTokens array, and emit an event.
            acceptedTokenMap[_token] = false;
            for (uint256 i = 0; i < acceptedTokens.length; ++i) {
                if (acceptedTokens[i] == _token) {
                    acceptedTokens[i] = acceptedTokens[acceptedTokens.length - 1];
                    acceptedTokens.pop();
                    emit RemoveAcceptedToken(_token);
                    return;
                }
            }
        }
        // Revert if the token does not exist in the accepted tokens.
        revert("Vault: Non-accepted token.");
    }

    // Allows the owner to add a new deposit allowed token.
    function addDepositAllowedToken(address _token) external onlyOwner {
        // Check if the token does not already exist in the deposit allowed tokens mapping.
        if (depositAllowedTokenMap[_token] == false) {
            // Set the token as allowed for deposit, add it to the depositAllowedTokens array, and emit an event.
            depositAllowedTokenMap[_token] = true;
            depositAllowedTokens.push(_token);
            emit AddDepositAllowedToken(_token);
        } else {
            // Revert if the token already exists in the deposit allowed tokens.
            revert("Vault: Token already exists.");
        }
    }

    // Allows the owner to remove a deposit allowed token.
    function removeDepositAllowedToken(address _token) external onlyOwner {
        // Check if the token exists in the deposit allowed tokens mapping.
        if (depositAllowedTokenMap[_token] == true) {
            // Set the token as not allowed for deposit, remove it from the depositAllowedTokens array, and emit an event.
            depositAllowedTokenMap[_token] = false;
            for (uint256 i = 0; i < depositAllowedTokens.length; ++i) {
                if (depositAllowedTokens[i] == _token) {
                    depositAllowedTokens[i] = depositAllowedTokens[depositAllowedTokens.length - 1];
                    depositAllowedTokens.pop();
                    emit RemoveDepositAllowedToken(_token);
                    return;
                }
            }
        }
        // Revert if the token does not exist in the deposit allowed tokens.
        revert("Vault: Non-deposit allowed token.");
    }

    // Allows the owner to add a new withdrawal token.
    function addWithdrawalToken(address _token) external onlyOwner {
        // Check if the token does not already exist in the withdrawal tokens mapping.
        if (withdrawalTokenMap[_token] == false) {
            // Set the token as withdrawal allowed, add it to the withdrawalTokens array, and emit an event.
            withdrawalTokenMap[_token] = true;
            withdrawalTokens.push(_token);
            emit AddWithdrawalToken(_token);
        } else {
            // Revert if the token already exists in the withdrawal tokens.
            revert("Vault: Token already exists.");
        }
    }

    // Allows the owner to remove a withdrawal token.
    function removeWithdrawalToken(address _token) external onlyOwner {
        // Check if the token exists in the withdrawal tokens mapping.
        if (withdrawalTokenMap[_token] == true) {
            // Set the token as not withdrawal allowed, remove it from the withdrawalTokens array, and emit an event.
            withdrawalTokenMap[_token] = false;
            for (uint256 i = 0; i < withdrawalTokens.length; ++i) {
                if (withdrawalTokens[i] == _token) {
                    withdrawalTokens[i] = withdrawalTokens[withdrawalTokens.length - 1];
                    withdrawalTokens.pop();
                    emit RemoveWithdrawalToken(_token);
                    return;
                }
            }
        }
        // Revert if the token does not exist in the withdrawal tokens.
        revert("Vault: Non-accepted token.");
    }


    // Allows the owner to add a new plugin to the vault.
    function addPlugin(uint256 _pluginId, address _pluginAddress) external onlyOwner {
        // Ensure that the pluginId is not zero and does not already exist.
        require(_pluginId != 0, "Vault: PluginId cannot be zero");
        require(pluginIdToIndex[_pluginId] == 0, "Plugin with this ID already exists");

        // Create a new Plugin instance and add it to the plugins array.
        plugins.push(Plugin(_pluginAddress, _pluginId));
        
        // Update the mapping with the index of the added plugin.
        pluginIdToIndex[_pluginId] = plugins.length;

        // Emit an event to log the addition of a new plugin.
        emit AddPlugin(_pluginId, _pluginAddress);
    }

    // Allows the owner to remove a plugin from the vault.
    function removePlugin(uint256 _pluginId) external onlyOwner {
        // Ensure that the pluginId exists.
        require(pluginIdToIndex[_pluginId] != 0, "Plugin with this ID does not exist");

        // Get the index of the plugin in the array.
        uint256 pluginIndex = pluginIdToIndex[_pluginId] - 1;
        
        // Delete the mapping entry for the removed plugin.
        delete pluginIdToIndex[_pluginId];

        if (pluginIndex != plugins.length - 1) {
            // If the removed plugin is not the last one, replace it with the last plugin in the array.
            Plugin memory lastPlugin = plugins[plugins.length - 1];
            plugins[pluginIndex] = lastPlugin;
            pluginIdToIndex[lastPlugin.pluginId] = pluginIndex + 1;
        }

        // Remove the last element from the array.
        plugins.pop();

        // Emit an event to log the removal of a plugin.
        emit RemovePlugin(_pluginId);
    }

    function setProtocolFeePercentage(uint256 _protocolFeePercentage) external onlyOwner {
        require(_protocolFeePercentage <= MAX_FEE, "Vault: protocol fee exceeds the max fee");
        protocolFeePercentage = _protocolFeePercentage;
        emit SetProtocolFeePercentage(_protocolFeePercentage);
    }


    /* ========== USER FUNCTIONS ========== */
    
    // Allows users to initiate a deposit request by converting tokens to LP tokens and staking them into the selected pool.
    function addDepositRequest(address _token, uint256 _tokenAmount) external payable nonReentrant {
        require(msg.value >= depositMinExecFee, "Vault: Insufficient execution fee");

        // Ensure the deposited token is allowed for deposit in the vault.
        require(isDepositAllowedToken(_token), "Vault: Invalid token");
        
        // Ensure a valid and positive token amount is provided.
        require(_tokenAmount > 0, "Vault: Invalid token amount");

        // Calculate the USD value of the deposited tokens.
        uint256 amountUsd = calculateTokenValueInUsd(_token, _tokenAmount);

        // Convert the USD value to the corresponding LP token amount.
        uint256 lpAmountToMint = convertAssetToLP(amountUsd);

        // Ensure that there is a sufficient LP amount to mint.
        require(lpAmountToMint > 0, "Vault: Insufficient amount");

        // Transfer the deposited tokens from the user to the vault.
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _tokenAmount);

        // Mint the calculated LP tokens and send them to the user.
        _mint(msg.sender, lpAmountToMint);

        // Emit an event to log the deposit request.
        emit AddDepositRequest(_token, _tokenAmount);

        // Stake the minted LP tokens to the selected pool.
        stakeToSelectedPool(_token, _tokenAmount);
    }


    // Internal function to stake a specified token amount to the selected pool using the configured plugin.
    function stakeToSelectedPool(address _token, uint256 _tokenAmount) internal {
        // Retrieve the list of allowed tokens for the selected plugin and pool.
        address[] memory allowedTokens = getTokensByPluginAndPoolId(selectedPluginId, selectedPoolId);

        // Iterate through the allowed tokens to find the matching token.
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                // Create an array to represent token amounts, with the target token's amount set accordingly.
                uint256[] memory _amounts = new uint256[](allowedTokens.length);
                _amounts[i] = _tokenAmount;

                // Encode the payload for the 'Stake' action using the selected plugin and pool.
                bytes memory payload = abi.encode(uint8(selectedPoolId), allowedTokens, _amounts);

                // Execute the 'Stake' action on the selected plugin with the encoded payload.
                this.execute(uint8(selectedPluginId), IPlugin.ActionType.Stake, payload);
            }
        }
    }


    // Allows users to initiate a withdrawal request by providing the amount of LP tokens they want to withdraw.
    function addWithdrawRequest(address _token, uint256 _amountLP) external payable nonReentrant {
        require(msg.value >= withdrawMinExecFee, "Vault: Insufficient execution fee");

        // Ensure the provided token is valid for withdrawal.
        require(isWithdrawalToken(_token), "Vault: Invalid token");

        // Ensure a valid and positive LP token amount is provided.
        require(_amountLP > 0, "Vault: Invalid LP token amount");

        // Determine the appropriate withdrawal list based on the protocol status.
        WithdrawalInfo[] storage withdrawalList = (protocolStatus == Status.Pending ? pendingWithdrawalRequests : withdrawalRequests);

        // Transfer the specified amount of LP tokens from the user to the contract.
        this.transferFrom(msg.sender, address(this), _amountLP);

        // Create a new withdrawal request with user address, token address, and LP token amount.
        WithdrawalInfo memory newWithdrawal = WithdrawalInfo({
            userAddress: msg.sender,
            tokenAddress: _token,
            lpAmount: _amountLP
        });

        // Add the withdrawal request to the corresponding list (pending or confirmed).
        withdrawalList.push(newWithdrawal);

        // Emit an event to log the withdrawal request.
        emit AddWithdrawRequest(newWithdrawal);
    }
    
    // Allows the master contract to activate the 'Pending' status for the vault
    function activatePendingStatus() public onlyMaster nonReentrant {
        // Ensure that the current protocol status is 'Normal'.
        require(protocolStatus == Status.Normal, "Vault: Invalid status operation");

        // Ensure there are no pending withdrawal requests and there are confirmed withdrawal requests.
        require(pendingWithdrawalRequests.length == 0 && withdrawalRequests.length != 0, "Pending withdrawal request must be empty");

        // Set the protocol status to 'Pending'.
        protocolStatus = Status.Pending;

        // Emit an event to log the updated protocol status.
        emit UpdatedProtocolStatus(Status.Pending);
    }


    // Allows the master contract to settle pending withdrawal requests, converting LP tokens to token amounts and transferring them to users.
    function settleWithdrawRequest() external onlyMaster nonReentrant {
        // Ensure that the protocol status is 'Pending'.
        require(protocolStatus == Status.Pending, "Vault: Status must be 'Pending' status");

        // Iterate through each withdrawal request.
        for (uint256 i = 0; i < withdrawalRequests.length; ++i) {
            address user = withdrawalRequests[i].userAddress;
            uint256 lpAmount = withdrawalRequests[i].lpAmount;

            // Convert LP tokens to USD value.
            uint256 usdAmountToWithdraw = convertLPToAsset(lpAmount);

            // Calculate the equivalent token amount.
            uint256 withdrawalAmount = calculateTokenAmountFromUsd(withdrawalRequests[i].tokenAddress, usdAmountToWithdraw);

            uint256 tokenBalance = IERC20(withdrawalRequests[i].tokenAddress).balanceOf(address(this));

            // Transfer withdrawal amount to the user.
            if (tokenBalance < withdrawalAmount) {
                uint256 burnAmount = (lpAmount * tokenBalance) / withdrawalAmount;
                uint256 refundAmount = lpAmount - burnAmount;

                // Refund remaining LP tokens to the user and burn the required amount.
                this.transfer(user, refundAmount);
                _burn(address(this), burnAmount);

                // Transfer remaining token balance to the user.
                IERC20(withdrawalRequests[i].tokenAddress).transfer(user, tokenBalance);
            } else {
                // Transfer the full withdrawal amount to the user and burn the corresponding LP tokens.
                IERC20(withdrawalRequests[i].tokenAddress).transfer(user, withdrawalAmount);
                _burn(address(this), lpAmount);
            }

            // Clear the processed withdrawal request.
            delete withdrawalRequests[i];
        }

        // Clear the entire withdrawal requests array.
        while (withdrawalRequests.length > 0) {
            withdrawalRequests.pop();
        }

        // Emit an event to log the settlement of withdrawal requests.
        emit SettleWithdrawRequest();

        // Process any pending withdrawal requests.
        processPendingRequests();
    }

    // Internal function to process pending withdrawal requests by moving them to the confirmed withdrawal requests array.
    function processPendingRequests() internal {
        // Ensure that the protocol status is 'Pending'.
        require(protocolStatus == Status.Pending, "Vault: Status must be 'Pending' status");

        // Ensure that there are no active withdrawal requests.
        require(withdrawalRequests.length == 0, "Vault: Withdrawal request must be empty");

        // Move pending withdrawal requests to the confirmed withdrawal requests array.
        for (uint256 i = 0; i < pendingWithdrawalRequests.length; i++) {
            withdrawalRequests.push(pendingWithdrawalRequests[i]);
        }

        // Clear the pending withdrawal requests array.
        while (pendingWithdrawalRequests.length > 0) {
            pendingWithdrawalRequests.pop();
        }

        // Reset the protocol status to 'Normal'.
        protocolStatus = Status.Normal;

        // Emit an event to log the updated protocol status.
        emit UpdatedProtocolStatus(Status.Normal);
    }
    
    /* ========== MASTER FUNCTIONS ========== */
    
    // Allows the master contract or the vault itself to execute actions on a specified plugin.
    function execute(uint8 _pluginId, IPlugin.ActionType _actionType, bytes memory _payload) public onlyMasterOrSelf nonReentrant {
        // Ensure that the specified plugin exists.
        require(pluginIdToIndex[_pluginId] != 0, "Plugin with this ID does not exist");

        // Retrieve the plugin address based on the provided plugin ID.
        address plugin = plugins[pluginIdToIndex[_pluginId] - 1].pluginAddress;

        // If the action type is 'Stake', approve tokens for staking according to the payload.
        if (_actionType == IPlugin.ActionType.Stake) {
            (, address[] memory _tokens, uint256[] memory _amounts) = abi.decode(_payload, (uint8, address[], uint256[]));
            require(_tokens.length == _amounts.length, "Vault: Lists must have the same length");

            // Iterate through the tokens and approve them for staking.
            for (uint256 i; i < _tokens.length; ++i) {
                if (_amounts[i] > 0) {
                    IERC20(_tokens[i]).approve(plugin, _amounts[i]);
                }
            }
        }

        // Execute the specified action on the plugin with the provided payload.
        IPlugin(plugin).execute(_actionType, _payload);

        // Emit an event to log the execution of the plugin action.
        emit Execute(_pluginId, _actionType, _payload);
    }

    // Allows the master contract to approve tokens for a specified plugin based on the provided payload.
    function approveTokens(uint8 _pluginId, bytes memory _payload) external onlyMaster nonReentrant {
        // Ensure that the specified plugin exists.
        require(pluginIdToIndex[_pluginId] != 0, "Plugin with this ID does not exist");

        // Retrieve the plugin address based on the provided plugin ID.
        address plugin = plugins[pluginIdToIndex[_pluginId] - 1].pluginAddress;

        // Decode the payload to obtain the list of tokens and corresponding amounts to approve.
        (address[] memory _tokens, uint256[] memory _amounts) = abi.decode(_payload, (address[], uint256[]));
        require(_tokens.length == _amounts.length, "Vault: Lists must have the same length");

        // Iterate through the tokens and approve them for the plugin.
        for (uint256 i; i < _tokens.length; ++i) {
            IERC20(_tokens[i]).approve(plugin, _amounts[i]);
        }
        emit ApproveTokens(_pluginId, _tokens, _amounts);
    }

    function updateLiquidityProviderRate() external onlyMaster nonReentrant {
        uint256 previousRate = lpRate;
        
        // Calculate current rate
        uint256 currentRate = getCurrentLiquidityProviderRate();
        
        // Check if the current rate is higher than the previous rate
        if (currentRate > previousRate) {
            // Calculate the change in rate and update total profit
            uint256 deltaRate = currentRate - previousRate;
            uint256 totalProfit = convertDecimals(deltaRate * totalSupply(), 18 + MOZAIC_DECIMALS, ASSET_DECIMALS);
            
            // Calculate protocol fee        
            uint256 protocolFee = totalProfit.mul(protocolFeePercentage).div(BP_DENOMINATOR);
            
            protocolFeeInVault += protocolFee;
            // Update the LP rates
            lpRate = getCurrentLiquidityProviderRate();
        } else {
            // Update the LP rates
            lpRate = currentRate;
        }
    }

    // Withdraws protocol fees stored in the vault for a specific token.
    function withdrawProtocolFee(address _token) external onlyMaster nonReentrant {
        require(isAcceptedToken(_token), "Vault: Invalid token");

        // Calculate the token amount from the protocol fee in the vault
        uint256 tokenAmount = calculateTokenAmountFromUsd(_token, protocolFeeInVault);

        // Get the token balance of this contract
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));

        // Determine the transfer amount, ensuring it doesn't exceed the token balance
        uint256 transferAmount = tokenBalance >= tokenAmount ? tokenAmount : tokenBalance;

        // Update the protocol fee in the vault after the withdrawal
        protocolFeeInVault = protocolFeeInVault.sub(protocolFeeInVault.mul(transferAmount).div(tokenAmount));

        // Safely transfer the tokens to the treasury address
        IERC20(_token).safeTransfer(treasury, transferAmount);

        // Emit an event to log the withdrawal
        emit WithdrawProtocolFee(_token, transferAmount);
    }

    function transferExecutionFee(uint256 _pluginId, uint256 _amount) external onlyMaster nonReentrant {
        Plugin memory plugin = getPlugin(_pluginId);
        require(_amount <= address(this).balance, "Vault: Insufficient balance");
        (bool success, ) = plugin.pluginAddress.call{value: _amount}("");
        require(success, "Vault: Failed to send Ether");
    } 

    /* ========== VIEW FUNCTIONS ========== */

    // Retrieve the array of plugins registered in the vault.
    function getPlugins() public view returns (Plugin[] memory) {
        return plugins;
    }

    // Retrieve the total count of registered plugins in the vault.
    function getPluginsCount() public view returns (uint256) {
        return plugins.length;
    }

    // Retrieve details about a specific plugin based on its unique identifier.
    function getPlugin(uint256 _pluginId) public view returns (Plugin memory) {
        // Ensure that the specified plugin exists.
        require(pluginIdToIndex[_pluginId] != 0, "Plugin with this ID does not exist");

        // Retrieve and return details about the specified plugin.
        Plugin memory plugin = plugins[pluginIdToIndex[_pluginId] - 1];
        return plugin;
    }

    // Retrieves the current liquidity provider rate.
    function getCurrentLiquidityProviderRate() public view returns(uint256) {
        uint256 _totalAssets = totalAssetInUsd() > protocolFeeInVault ? totalAssetInUsd() - protocolFeeInVault: 0;
        
        // Variable to store the current rate
        uint256 currentRate;

         // Check if total supply or total assets is zero
        if (totalSupply() == 0 || _totalAssets == 0) {
            currentRate = 1e18;
        } else {
            // Convert total assets to the desired decimals
            uint256 adjustedAssets = convertDecimals(_totalAssets, ASSET_DECIMALS, MOZAIC_DECIMALS);

            // Calculate the current rate
            currentRate = adjustedAssets * 1e18 / totalSupply();
        }
        return currentRate;
    }

    // Calculate the total value of assets held by the vault, including liquidity from registered plugins
    // and the USD value of accepted tokens held in the vault.
    function totalAssetInUsd() public view returns (uint256 _totalAsset) {
        // Iterate through registered plugins to calculate their total liquidity.
        for (uint8 i; i < plugins.length; ++i) {
            _totalAsset += IPlugin(plugins[i].pluginAddress).getTotalLiquidity();
        }

        // Iterate through accepted tokens to calculate their total USD value.
        for (uint256 i; i < acceptedTokens.length; ++i) {
            // Calculate the USD value of the token based on its balance in the vault.
            _totalAsset += calculateTokenValueInUsd(acceptedTokens[i], IERC20(acceptedTokens[i]).balanceOf(address(this)));
        }

        // Return the total calculated asset value.
        return _totalAsset;
    }


    // Retrieve an array containing details of all confirmed withdrawal requests.
    function getWithdrawalRequests() public view returns (WithdrawalInfo[] memory) {
        return withdrawalRequests;
    }

    // Retrieve the total count of confirmed withdrawal requests in the vault.
    function withdrawalRequestsLength() public view returns (uint256) {
        return withdrawalRequests.length;
    }

    // Retrieve an array containing details of all pending withdrawal requests.
    function getPendingRequests() public view returns (WithdrawalInfo[] memory) {
        return pendingWithdrawalRequests;
    }

    // Retrieve the total count of pending withdrawal requests in the vault.
    function pendingRequestsLength() public view returns (uint256) {
        return pendingWithdrawalRequests.length;
    }

    // Check if a given token is accepted by the vault.
    function isAcceptedToken(address _token) public view returns (bool) {
        return acceptedTokenMap[_token];
    }

    // Check if a given token is allowed for deposit in the vault.
    function isDepositAllowedToken(address _token) public view returns (bool) {
        return depositAllowedTokenMap[_token];
    }

    // Check if a given token is allowed for withdrawal from the vault.
    function isWithdrawalToken(address _token) public view returns (bool) {
        return withdrawalTokenMap[_token];
    }

    function getAcceptedTokens() public view returns (address[] memory) {
        return acceptedTokens;
    }

    function getDepositAllowedTokens() public view returns (address[] memory) {
        return depositAllowedTokens;
    }

    function getWithdrawalTokens() public view returns (address[] memory) {
        return withdrawalTokens;
    }

    // Retrieve the list of tokens allowed for a specific pool associated with a plugin.
    // Returns an array of token addresses based on the provided plugin and pool IDs.
    function getTokensByPluginAndPoolId(uint256 _pluginId, uint256 _poolId) public view returns (address[] memory) {
        // Initialize an array to store the allowed tokens for the specified pool.
        address[] memory poolAllowedTokens;

        // If the specified plugin does not exist, return an empty array.
        if (pluginIdToIndex[_pluginId] == 0) {
            return poolAllowedTokens;
        }

        // Retrieve the plugin information based on the provided plugin ID.
        Plugin memory plugin = plugins[pluginIdToIndex[_pluginId] - 1];

        // Retrieve the allowed tokens for the specified pool from the associated plugin.
        poolAllowedTokens = IPlugin(plugin.pluginAddress).getAllowedTokens(_poolId);

        // Return the array of allowed tokens for the specified pool.
        return poolAllowedTokens;
    }

    
    /* ========== HELPER FUNCTIONS ========== */

    // Calculate the USD value of a given token amount based on its price and decimals.
    function calculateTokenValueInUsd(address _tokenAddress, uint256 _tokenAmount) public view returns (uint256) {
        // Retrieve the token and price consumer decimals.
        uint256 tokenDecimals = IERC20Metadata(_tokenAddress).decimals();
        uint256 priceConsumerDecimals = TokenPriceConsumer(tokenPriceConsumer).decimals(_tokenAddress);

        // Calculate the difference in decimals between the token and the desired ASSET_DECIMALS.
        uint256 decimalsDiff;

        // Retrieve the token price from the price consumer.
        uint256 tokenPrice = TokenPriceConsumer(tokenPriceConsumer).getTokenPrice(_tokenAddress);

        // Adjust the token amount based on the difference in decimals.
        if (tokenDecimals + priceConsumerDecimals >= ASSET_DECIMALS) {
            decimalsDiff = tokenDecimals + priceConsumerDecimals - ASSET_DECIMALS;
            return (_tokenAmount * tokenPrice) / (10 ** decimalsDiff);
        } else {
            decimalsDiff = ASSET_DECIMALS - tokenDecimals - priceConsumerDecimals;
            return (_tokenAmount * tokenPrice * (10 ** decimalsDiff));
        }
    }

    // Calculate the token amount corresponding to a given USD value based on token price and decimals.
    function calculateTokenAmountFromUsd(address _tokenAddress, uint256 _tokenValueUsd) public view returns (uint256) {
        // Retrieve the token and price consumer decimals.
        uint256 tokenDecimals = IERC20Metadata(_tokenAddress).decimals();
        uint256 priceConsumerDecimals = TokenPriceConsumer(tokenPriceConsumer).decimals(_tokenAddress);

        // Convert the USD value to the desired ASSET_DECIMALS.
        uint256 normalizedValue = convertDecimals(_tokenValueUsd, ASSET_DECIMALS, tokenDecimals + priceConsumerDecimals);

        // Calculate the token amount based on the normalized value and token price.
        uint256 tokenAmount = normalizedValue / TokenPriceConsumer(tokenPriceConsumer).getTokenPrice(_tokenAddress);

        // Return the calculated token amount.
        return tokenAmount;
    }

    /* ========== CONVERT FUNCTIONS ========== */

    // Convert an amount from one decimal precision to another.
    function convertDecimals(uint256 _amount, uint256 _from, uint256 _to) public pure returns (uint256) {
        // If the source decimal precision is greater than or equal to the target, perform division.
        if (_from >= _to) {
            return _amount / 10 ** (_from - _to);
        } else {
            // If the target decimal precision is greater than the source, perform multiplication.
            return _amount * 10 ** (_to - _from);
        }
    }

    // Convert an asset amount to LP tokens based on the current total asset and total LP token supply.
    function convertAssetToLP(uint256 _amount) public view returns (uint256) {
        // If the total asset is zero, perform direct decimal conversion.
        uint256 _totalAssetInUsd = totalAssetInUsd() > protocolFeeInVault ?  totalAssetInUsd() - protocolFeeInVault : 0;
        if (_totalAssetInUsd == 0) {
            return convertDecimals(_amount, ASSET_DECIMALS, MOZAIC_DECIMALS);
        }
        
        // Perform conversion based on the proportion of the provided amount to the total asset.
        return (_amount * totalSupply()) / _totalAssetInUsd;
    }

    // Convert LP tokens to an equivalent asset amount based on the current total asset and total LP token supply.
    function convertLPToAsset(uint256 _amount) public view returns (uint256) {
        // If the total LP token supply is zero, perform direct decimal conversion.
        if (totalSupply() == 0) {
            return convertDecimals(_amount, MOZAIC_DECIMALS, ASSET_DECIMALS);
        }
        uint256 _totalAssetInUsd = totalAssetInUsd() > protocolFeeInVault ?  totalAssetInUsd() - protocolFeeInVault : 0;
        // Perform conversion based on the proportion of the provided amount to the total LP token supply.
        return (_amount * _totalAssetInUsd) / totalSupply();
    }

    // Retrieve the decimal precision of the token (MOZAIC_DECIMALS).
    function decimals() public view virtual override returns (uint8) {
        return uint8(MOZAIC_DECIMALS);
    }

    /* ========== TREASURY FUNCTIONS ========== */
    receive() external payable {}
    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}