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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

// Libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';


import "./interfaces/IPlugin.sol";
import "./interfaces/IExchangeRouter.sol";
import "./interfaces/IDataStore.sol";
import "./interfaces/IReader.sol";
import "./interfaces/IMarket.sol";

import "./TokenPriceConsumer.sol";

contract GmxPlugin is Ownable, IPlugin, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    // Struct defining configuration parameters for the router.
    struct RouterConfig {
        address exchangeRouter;   // Address of the exchange router contract.
        address router;           // Address of the router contract.
        address depositVault;     // Address of the deposit vault contract.
        address withdrawVault;    // Address of the withdraw vault contract.
        address orderVault;       // Address of the order vault contract.
        address reader;           // Address of the reader contract.
    }

    // Struct defining configuration parameters for a pool.
    struct PoolConfig {
        uint256 poolId;           // Unique identifier for the pool.
        address indexToken;       // Address of the index token associated with the pool.
        address longToken;        // Address of the long token associated with the pool.
        address shortToken;       // Address of the short token associated with the pool.
        address marketToken;      // Address of the market token associated with the pool.
    }

    // Struct defining parameters related to Gmx (Governance Mining) functionality.
    struct GmxParams {
        address uiFeeReceiver;    // Address to receive UI fees.
        address callbackContract;  // Address of the callback contract for Gmx interactions.
        uint256 callbackGasLimit; // Gas limit for Gmx callback functions.
        uint256 executionFee;     // Execution fee for Gmx interactions.
        bool shouldUnwrapNativeToken; // Flag indicating whether native tokens should be unwrapped during Gmx interactions.
    }

    /* ========== CONSTANTS ========== */
    // Constant defining the decimal precision for asset values.
    uint256 public constant ASSET_DECIMALS = 36;

    // Constant defining the decimal precision for market token prices.
    uint256 public constant MARKET_TOKEN_PRICE_DECIMALS = 30;

    /* ========== STATE VARIABLES ========== */
    // Address of the master contract, controlling the overall functionality.
    address public master;

    // Address of the local vault associated with the smart contract.
    address public localVault;

    // Address of the treasury where funds are managed.
    address payable public treasury;

    // Configuration parameters for the router, specifying key contracts and components.
    RouterConfig public routerConfig;

    // Parameters related to Governance Mining (Gmx) functionality.
    GmxParams public gmxParams;

    // Array storing configuration details for different pools.
    PoolConfig[] public pools;

    // Mapping to track the existence of pools based on their unique identifiers.
    mapping(uint256 => bool) public poolExistsMap;

    // Array containing unique tokens associated with the contract.
    address[] public uniqueTokens;

    // Address of the token price consumer contract used for obtaining token prices.
    address public tokenPriceConsumer;

    /* ========== EVENTS ========== */
    event SetMaster(address master);
    event PoolAdded(uint256 poolId);
    event PoolRemoved(uint256 poolId);
    event SetTreasury(address payable treasury);

    /* ========== MODIFIERS ========== */

    // Modifier allowing only the local vault to execute the function.
    modifier onlyVault() {
        require(msg.sender == localVault, "Invalid caller");
        _;
    }

    // Modifier allowing only the master contract to execute the function.
    modifier onlyMaster() {
        require(msg.sender == master, "Invalid caller");
        _;
    }


    /* ========== CONFIGURATION ========== */

    // Constructor initializing the GMX contract with the address of the local vault.
    constructor(address _localVault) {
        // Ensure the provided local vault address is valid.
        require(_localVault != address(0), "GMX: Invalid Address");
        // Set the localVault address.
        localVault = _localVault;
    }

    // Function allowing the owner to set the address of the master contract.
    function setMaster(address _master) public onlyOwner {
        // Ensure the provided master address is valid.
        require(_master != address(0), "GMX: Invalid Address");
        // Set the master address.
        master = _master;
        // Emit an event signaling the master address update.
        emit SetMaster(_master);
    }

    // Function allowing the owner to set the treasury address.
    function setTreasury(address payable _treasury) public onlyOwner {
        // Ensure the provided treasury address is valid.
        require(_treasury != address(0), "Vault: Invalid address");
        // Set the treasury address.
        treasury = _treasury;
        // Emit an event signaling the treasury address update.
        emit SetTreasury(_treasury);
    }


    // Function allowing the owner to set the router configuration parameters.
    function setRouterConfig(
        address _exchangeRouter,
        address _router,
        address _depositVault,
        address _withdrawVault,
        address _orderVault,
        address _reader
    ) external onlyOwner {
        // Ensure all provided addresses are valid.
        require(
            _exchangeRouter != address(0) && 
            _router != address(0) && 
            _depositVault != address(0) && 
            _withdrawVault != address(0) && 
            _orderVault != address(0) && 
            _reader != address(0),
            "GMX: Invalid Address"
        );

        // Set the router configuration with the provided addresses.
        routerConfig = RouterConfig({
            exchangeRouter: _exchangeRouter,
            router: _router,
            depositVault: _depositVault,
            withdrawVault: _withdrawVault,
            orderVault: _orderVault,
            reader: _reader
        });
    }

    // Function allowing the owner to set Governance Mining (Gmx) parameters.
    function setGmxParams(
        address _uiFeeReceiver,
        address _callbackContract,
        uint256 _callbackGasLimit,
        uint256 _executionFee,
        bool _shouldUnwrapNativeToken
    ) public onlyOwner {
        // Set the Gmx parameters with the provided values.
        gmxParams = GmxParams({
            uiFeeReceiver: _uiFeeReceiver,
            callbackContract: _callbackContract,
            callbackGasLimit: _callbackGasLimit,
            executionFee: _executionFee,
            shouldUnwrapNativeToken: _shouldUnwrapNativeToken
        });
    }

    // Function allowing the owner to set the token price consumer contract address.
    function setTokenPriceConsumer(address _tokenPriceConsumer) public onlyOwner {
        // Ensure the provided token price consumer address is valid.
        require(_tokenPriceConsumer != address(0), "GMX: Invalid Address");
        
        // Set the token price consumer contract address.
        tokenPriceConsumer = _tokenPriceConsumer;
    }


    // Function allowing the owner to add a new pool with specified configuration.
    function addPool(
        uint256 _poolId,
        address _indexToken,
        address _longToken,
        address _shortToken,
        address _marketToken
    ) external onlyOwner {
        // Ensure the pool with the given poolId does not already exist.
        require(_poolId != 0, "GMX: Invalid Pool Id");
        require(!poolExistsMap[_poolId], "GMX: Pool with this poolId already exists");

        // Create a new pool configuration and add it to the array.
        PoolConfig memory newPool = PoolConfig(_poolId, _indexToken, _longToken, _shortToken, _marketToken);
        pools.push(newPool);

        // Mark the pool as existing.
        poolExistsMap[_poolId] = true;

        // Add unique tokens to the list if not already present.
        if (!isTokenAdded(_longToken)) {
            uniqueTokens.push(_longToken);
        }

        if (!isTokenAdded(_shortToken)) {
            uniqueTokens.push(_shortToken);
        }

        // Emit an event indicating the addition of a new pool.
        emit PoolAdded(_poolId);
    }

    // Function allowing the owner to remove an existing pool.
    function removePool(uint256 _poolId) external onlyOwner {
        // Ensure the pool with the given poolId exists.
        require(poolExistsMap[_poolId], "GMX: Pool with this poolId does not exist");

        // Find the index of the pool in the array.
        uint256 indexToRemove = getPoolIndexById(_poolId);

        // Swap the pool to remove with the last pool in the array.
        // This avoids leaving gaps in the array.
        uint256 lastIndex = pools.length - 1;
        if (indexToRemove != lastIndex) {
            pools[indexToRemove] = pools[lastIndex];
        }

        // Remove the last pool (which now contains the removed pool's data).
        pools.pop();

        // Mark the pool as no longer existing.
        delete poolExistsMap[_poolId];

        // Update the list of unique tokens.
        updateUniqueTokens();

        // Emit an event indicating the removal of an existing pool.
        emit PoolRemoved(_poolId);
    }


    /* ========== PUBLIC FUNCTIONS ========== */
    // Function allowing the vault to execute different actions based on the specified action type.
    function execute(ActionType _actionType, bytes calldata _payload) external payable onlyVault nonReentrant {
        // Determine the action type and execute the corresponding logic.
        if (_actionType == ActionType.Stake) {
            // Execute stake action.
            stake(_payload);
        } else if (_actionType == ActionType.Unstake) {
            // Execute unstake action.
            unstake(_payload);
        } else if (_actionType == ActionType.SwapTokens) {
            // Execute token swap action (create order).
            createOrder(_payload);
        }
    }

    /* ========== VIEW FUNCTIONS ========== */
    // Function to calculate the total liquidity (totalAsset) of the vault, considering balances in unique tokens and pools.
    function getTotalLiquidity() public view returns (uint256 totalAsset) {
        // Iterate over uniqueTokens and calculate totalAsset based on token balances.
        for (uint256 i = 0; i < uniqueTokens.length; ++i) {
            address tokenAddress = uniqueTokens[i];
            uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
            totalAsset += calculateTokenValueInUsd(tokenAddress, tokenBalance);
        }

        // Iterate over pools and calculate totalAsset based on market token balances and prices.
        for (uint256 i = 0; i < pools.length; ++i) {
            address marketTokenAddress = pools[i].marketToken;
            uint256 marketTokenBalance = IERC20(marketTokenAddress).balanceOf(address(this));
            uint256 marketTokenPrice = uint256(getMarketTokenPrice(pools[i].poolId, true));
            uint256 amount = marketTokenBalance * marketTokenPrice;

            // Use IERC20Metadata only once to get decimals.
            uint256 decimals = IERC20Metadata(marketTokenAddress).decimals() + MARKET_TOKEN_PRICE_DECIMALS;

            // Refactor decimalsDiff calculation to improve readability.
            uint256 decimalsDiff = abs(int256(decimals) - int256(ASSET_DECIMALS));
            uint256 adjustedAmount;

            // Adjust amount based on decimalsDiff.
            if (decimals >= ASSET_DECIMALS) {
                adjustedAmount = amount / 10**decimalsDiff;
            } else {
                adjustedAmount = amount * 10**decimalsDiff;
            }

            // Accumulate adjustedAmount to totalAsset.
            totalAsset += adjustedAmount;
        }
    }

    // Function to calculate the USD value of a given token amount based on its price and decimals.
    function calculateTokenValueInUsd(address _tokenAddress, uint256 _tokenAmount) public view returns (uint256) {
        uint256 tokenDecimals = IERC20Metadata(_tokenAddress).decimals();
        uint256 priceConsumerDecimals = TokenPriceConsumer(tokenPriceConsumer).decimals(_tokenAddress);

        // Get the token price from the TokenPriceConsumer.
        uint256 tokenPrice = TokenPriceConsumer(tokenPriceConsumer).getTokenPrice(_tokenAddress);

        uint256 decimalsDiff;

        // Adjust the token value based on the difference in decimals.
        if (tokenDecimals + priceConsumerDecimals >= ASSET_DECIMALS) {
            decimalsDiff = tokenDecimals + priceConsumerDecimals - ASSET_DECIMALS;
            return (_tokenAmount * tokenPrice) / (10 ** decimalsDiff);
        } else {
            decimalsDiff = ASSET_DECIMALS - tokenDecimals - priceConsumerDecimals;
            return (_tokenAmount * tokenPrice * (10 ** decimalsDiff));
        }
    }


    // Function to retrieve the total number of pools in the vault.
    function getPoolNumber() public view returns(uint256) {
        return pools.length;
    }

    // Function to retrieve the array of unique tokens stored in the vault.
    function getUniqueTokens() public view returns (address[] memory) {
        return uniqueTokens;
    }

    // Function to retrieve the length of the array of unique tokens.
    function getUniqueTokenLength() public view returns(uint256) {
        return uniqueTokens.length;
    }

    // Function to retrieve the array of pool configurations stored in the vault.
    function getPools() public view returns(PoolConfig[] memory) {
        return pools;
    }

    // Function to retrieve the length of the array of pool configurations.
    function getPoolLength() public view returns (uint256) {
        return pools.length;
    }

    // Function to check if a token is present in the uniqueTokens array.
    function isTokenAdded(address _token) public view returns(bool) {
        for(uint256 i; i < uniqueTokens.length; ++i) {
            if(uniqueTokens[i] == _token) return true;
        }
        return false;
    }

    // Internal function to check if a token exists in the longToken or shortToken of any pool configurations.
    function tokenExistsInList(address _token) internal view returns (bool) {
        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i].longToken == _token || pools[i].shortToken == _token) {
                return true;
            }
        }
        return false;
    }


    // Internal function to get the index of a pool in the array by poolId
    function getPoolIndexById(uint256 _poolId) public view returns (uint256 poolIndex) {
        for (uint256 index = 0; index < pools.length; index++) {
            if (pools[index].poolId == _poolId) {
                // Pool found, return its index
                poolIndex = index;
                return poolIndex;
            }
        }
        // If the pool is not found, revert with an error message
        revert("GMX: Pool not found");
    }

    // Updates the 'uniqueTokens' array by removing tokens that no longer exist.
    function updateUniqueTokens() internal {
        for (uint256 i = uniqueTokens.length; i > 0; i--) {
            if (!tokenExistsInList(uniqueTokens[i - 1])) {
                // Remove the token from uniqueTokens
                uniqueTokens[i - 1] = uniqueTokens[uniqueTokens.length - 1];
                uniqueTokens.pop();
            }
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    // Internal function to stake tokens into a specified pool.
    // The payload includes the pool ID, an array of two tokens (long and short), and corresponding amounts.
    // Validates the existence of the pool, array lengths, correct pool tokens, and non-zero token amounts.
    // Transfers tokens from localVault to the contract and executes buyGMToken function.
    function stake(bytes calldata _payload) internal {
        // Decode payload
        (uint8 _poolId, address[] memory _tokens, uint256[] memory _amounts) = abi.decode(_payload, (uint8, address[], uint256[]));

        // Validate pool existence
        require(poolExistsMap[_poolId], "GMX: Pool with this poolId does not exist");

        // Validate array lengths
        require(_tokens.length == 2 && _amounts.length == 2, "GMX: Array length must be 2");

        // Get pool index and pool configuration
        uint256 index = getPoolIndexById(_poolId);
        PoolConfig memory pool = pools[index];

        // Validate tokens
        require(pool.longToken == _tokens[0] && pool.shortToken == _tokens[1], "GMX: Invalid Pool tokens");

        // Validate token amounts
        require(_amounts[0] != 0 || _amounts[1] != 0, "GMX: Invalid token amount");

        // Transfer tokens from localVault to contract if amounts are positive
        if (_amounts[0] > 0) {
            IERC20(pool.longToken).safeTransferFrom(localVault, address(this), _amounts[0]);
        }

        if (_amounts[1] > 0) {
            IERC20(pool.shortToken).safeTransferFrom(localVault, address(this), _amounts[1]);
        }

        // Execute buyGMToken function
        buyGMToken(_poolId, _amounts[0], _amounts[1]);
    }


    // Internal function to unstake GM tokens from a specified pool.
    // The payload includes the pool ID and the market amount to sell.
    // Decodes the payload and performs the sell operation using sellGMToken function.
    function unstake(bytes calldata _payload) internal {
        // Decode payload
        (uint8 _poolId, uint256 marketAmount) = abi.decode(_payload, (uint8, uint256));

        // Perform sell operation
        sellGMToken(_poolId, marketAmount);
    }

    // Internal function to create a GM token order using provided order parameters.
    // The payload includes order parameters in the CreateOrderParams structure.
    // Decodes the payload and executes createGMOrder function.
    function createOrder(bytes calldata _payload) internal {
        // Decode payload
        IExchangeRouter.CreateOrderParams memory orderParams = abi.decode(_payload, (IExchangeRouter.CreateOrderParams));

        // Execute createGMOrder function
        createGMOrder(orderParams);
    }


    /* ========== GMX FUNCTIONS ========== */
    // Internal function to buy GM tokens in a specified pool.
    // Handles the approval of token transfers, prepares swap paths, and executes multicall to deposit assets and create GM tokens.
    function buyGMToken(uint8 _poolId, uint256 _longTokenAmount, uint256 _shortTokenAmount) internal {
        // Retrieve pool configuration
        PoolConfig memory pool = pools[getPoolIndexById(_poolId)];
        IExchangeRouter _exchangeRouter = IExchangeRouter(routerConfig.exchangeRouter);

        // Prepare swap paths and other variables
        address longToken = pool.longToken;
        address shortToken = pool.shortToken;
        address marketAddress = pool.marketToken;
        address[] memory longTokenSwapPath;
        address[] memory shortTokenSwapPath;
        uint256 executionFee = gmxParams.executionFee;

        // Prepare CreateDepositParams
        IExchangeRouter.CreateDepositParams memory params = IExchangeRouter.CreateDepositParams(
            address(this),                     // receiver
            gmxParams.callbackContract,        // callbackContract
            gmxParams.uiFeeReceiver,           // uiFeeReceiver
            marketAddress,
            longToken,
            shortToken,
            longTokenSwapPath,
            shortTokenSwapPath,
            0,                                 // minMarketTokens
            gmxParams.shouldUnwrapNativeToken, // shouldUnwrapNativeToken
            executionFee,
            gmxParams.callbackGasLimit         // callbackGasLimit
        );

        // Approve token transfers if amounts are greater than 0
        if (_longTokenAmount > 0) {
            IERC20(longToken).approve(routerConfig.router, _longTokenAmount);
        }

        if (_shortTokenAmount > 0) {
            IERC20(shortToken).approve(routerConfig.router, _shortTokenAmount);
        }

        // Prepare multicall arguments
        bytes[] memory multicallArgs = new bytes[](4);

        // Encode external contract calls for multicall
        multicallArgs[0] = abi.encodeWithSignature("sendWnt(address,uint256)", routerConfig.depositVault, executionFee);
        multicallArgs[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", longToken, routerConfig.depositVault, _longTokenAmount);
        multicallArgs[2] = abi.encodeWithSignature("sendTokens(address,address,uint256)", shortToken, routerConfig.depositVault, _shortTokenAmount);
        multicallArgs[3] = abi.encodeWithSignature("createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))", params);

        // Execute multicall with optional value (executionFee)
        _exchangeRouter.multicall{value: executionFee}(multicallArgs);
    }


    function sellGMToken(uint8 _poolId, uint256 marketAmount) internal {
        // Retrieve pool configuration
        PoolConfig memory pool = pools[getPoolIndexById(_poolId)];

        // Cast exchangeRouter to IExchangeRouter
        IExchangeRouter _exchangeRouter = IExchangeRouter(routerConfig.exchangeRouter);

        // Define swap paths
        address[] memory longTokenSwapPath;
        address[] memory shortTokenSwapPath;
        uint256 executionFee = gmxParams.executionFee;

        // Extract market address from the pool configuration
        address marketAddress = pool.marketToken;

        // Check if the contract has sufficient market token balance
        uint256 balance = IERC20(marketAddress).balanceOf(address(this));
        require(balance >= marketAmount && marketAmount > 0, "GMX: Insufficient market token balance");

        // Create parameters for the external contract call
        IExchangeRouter.CreateWithdrawalParams memory params = IExchangeRouter.CreateWithdrawalParams(
            localVault,                        // receiver
            gmxParams.callbackContract,        // callbackContract
            gmxParams.uiFeeReceiver,           // uiFeeReceiver
            marketAddress,
            longTokenSwapPath,
            shortTokenSwapPath,
            0,                                 // minLongTokens
            0,                                 // minShortTokens
            gmxParams.shouldUnwrapNativeToken, // shouldUnwrapNativeToken
            executionFee,
            gmxParams.callbackGasLimit         // callbackGasLimit
        );

        // Approve market token transfer
        IERC20(marketAddress).approve(routerConfig.router, marketAmount);

        // Initialize an array to store multicall arguments
        bytes[] memory multicallArgs = new bytes[](3);

        // Encode external contract calls for multicall
        multicallArgs[0] = abi.encodeWithSignature("sendWnt(address,uint256)", routerConfig.withdrawVault, executionFee);
        multicallArgs[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", marketAddress, routerConfig.withdrawVault, marketAmount);
        multicallArgs[2] = abi.encodeWithSignature("createWithdrawal((address,address,address,address,address[],address[],uint256,uint256,bool,uint256,uint256))", params);

        // Execute multicall with optional value (executionFee)
        _exchangeRouter.multicall{value: executionFee}(multicallArgs);
    }


    function createGMOrder(IExchangeRouter.CreateOrderParams memory _params) internal {
        require(_params.addresses.receiver == localVault, "Invalid receiver");
        
        // Extract values from _params to improve readability
        address initialCollateralToken = _params.addresses.initialCollateralToken;
        uint256 initialCollateralDeltaAmount = _params.numbers.initialCollateralDeltaAmount;
        uint256 executionFee = _params.numbers.executionFee;

        // Transfer initialCollateralToken from localVault to contract
        IERC20(initialCollateralToken).transferFrom(localVault, address(this), initialCollateralDeltaAmount);

        // Approve initialCollateralToken transfer
        IERC20(initialCollateralToken).approve(routerConfig.router, initialCollateralDeltaAmount);

        // Cast exchangeRouter to IExchangeRouter
        IExchangeRouter _exchangeRouter = IExchangeRouter(routerConfig.exchangeRouter);

        // Send execution fee to orderVault
        _exchangeRouter.sendWnt{value: executionFee}(routerConfig.orderVault, executionFee);

        // Transfer initialCollateralToken to orderVault
        _exchangeRouter.sendTokens(initialCollateralToken, routerConfig.orderVault, initialCollateralDeltaAmount);

        // Create the order using the external exchange router
        _exchangeRouter.createOrder(_params);
    }


   function getMarketTokenPrice(uint256 _poolId, bool _maximize) public view returns (int256) {
        require(poolExistsMap[_poolId], "GMX: Pool with this poolId does not exist");
        
        // Retrieve pool configuration
        PoolConfig memory _pool = pools[getPoolIndexById(_poolId)];

        // Cast exchangeRouter to IExchangeRouter for interacting with the external contract
        IExchangeRouter exchangeRouterInstance = IExchangeRouter(routerConfig.exchangeRouter);

        // Retrieve dataStore from the exchangeRouter
        IDataStore dataStore = exchangeRouterInstance.dataStore();

        // Define market properties for the external contract call
        IMarket.Props memory marketProps = IMarket.Props(
            _pool.marketToken,
            _pool.indexToken,
            _pool.longToken,
            _pool.shortToken
        );

        // Fetch token prices for indexToken, longToken, and shortToken
        IPrice.Props memory indexTokenPrice = getTokenPriceInfo(_pool.indexToken);
        IPrice.Props memory longTokenPrice = getTokenPriceInfo(_pool.longToken);
        IPrice.Props memory shortTokenPrice = getTokenPriceInfo(_pool.shortToken);

        // Define additional parameters for the external contract call
        bytes32 pnlFactorType = keccak256(abi.encodePacked("MAX_PNL_FACTOR_FOR_TRADERS"));
        bool maximize = _maximize;

        // Call the external contract to get the market token price
        (int256 marketTokenPrice, ) = IReader(routerConfig.reader).getMarketTokenPrice(
            dataStore,
            marketProps,
            indexTokenPrice,
            longTokenPrice,
            shortTokenPrice,
            pnlFactorType,
            maximize
        );

        // Return the calculated market token price
        return marketTokenPrice;
    }

    // Retrieves token price information, adjusting for decimals.
    function getTokenPriceInfo(address token) public view returns (IPrice.Props memory) {
        // Create an instance of TokenPriceConsumer for fetching token prices
        TokenPriceConsumer priceConsumer = TokenPriceConsumer(tokenPriceConsumer);

        uint256 tokenDecimal = IERC20Metadata(token).decimals();
        IPrice.Props memory tokenPrice = IPrice.Props(
            convertDecimals(priceConsumer.getTokenPrice(token), priceConsumer.decimals(token), MARKET_TOKEN_PRICE_DECIMALS - tokenDecimal),
            convertDecimals(priceConsumer.getTokenPrice(token), priceConsumer.decimals(token), MARKET_TOKEN_PRICE_DECIMALS - tokenDecimal)
        );
        return tokenPrice;
    }

    // Retrieves the long and short tokens allowed in a pool.
    function getAllowedTokens(uint256 _poolId) public view returns (address[] memory) {
        address[] memory emptyArray;
        if (!poolExistsMap[_poolId]) {
            return emptyArray;
        }
        address[] memory tokens = new address[](2);
        uint256 index = getPoolIndexById(_poolId);
        PoolConfig memory pool = pools[index];

        tokens[0] = pool.longToken;
        tokens[1] = pool.shortToken;
        return tokens;
    }

    // Converts an amount from one decimal precision to another.
    function convertDecimals(uint256 _amount, uint256 _from, uint256 _to) public pure returns (uint256) {
        if(_from >= _to) return _amount / 10 ** (_from - _to);
        else return _amount * 10 ** (_to - _from);
    }

    // Helper function to calculate absolute value of an int256
    function abs(int256 x) internal pure returns (uint256) {
        return x < 0 ? uint256(-x) : uint256(x);
    }

    receive() external payable {}
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdrawFee(uint256 _amount) public onlyOwner {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;
        require(amount >= _amount, "Vault: Invalid withdraw amount.");
                                                  
        require(treasury != address(0), "Vault: Invalid treasury");
        (bool success, ) = treasury.call{value: _amount}("");
        require(success, "Vault: Failed to send Ether");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IDataStore {
    function getUint(bytes32 key) external view returns (uint256);
    function setUint(bytes32 key, uint256 value) external returns (uint256);
    function removeUint(bytes32 key) external;
    function applyDeltaToUint(bytes32 key, int256 value, string calldata errorMessage) external returns (uint256);
    function applyDeltaToUint(bytes32 key, uint256 value) external returns (uint256);
    function applyBoundedDeltaToUint(bytes32 key, int256 value) external returns (uint256);
    function incrementUint(bytes32 key, uint256 value) external returns (uint256);
    function decrementUint(bytes32 key, uint256 value) external returns (uint256);

    function getInt(bytes32 key) external view returns (int256);
    function setInt(bytes32 key, int256 value) external returns (int256);
    function removeInt(bytes32 key) external;
    function applyDeltaToInt(bytes32 key, int256 value) external returns (int256);
    function incrementInt(bytes32 key, int256 value) external returns (int256);
    function decrementInt(bytes32 key, int256 value) external returns (int256);

    function getAddress(bytes32 key) external view returns (address);
    function setAddress(bytes32 key, address value) external returns (address);
    function removeAddress(bytes32 key) external;

    function getBool(bytes32 key) external view returns (bool);
    function setBool(bytes32 key, bool value) external returns (bool);
    function removeBool(bytes32 key) external;

    function getString(bytes32 key) external view returns (string memory);
    function setString(bytes32 key, string calldata value) external returns (string memory);
    function removeString(bytes32 key) external;

    function getBytes32(bytes32 key) external view returns (bytes32);
    function setBytes32(bytes32 key, bytes32 value) external returns (bytes32);
    function removeBytes32(bytes32 key) external;

    function getUintArray(bytes32 key) external view returns (uint256[] memory);
    function setUintArray(bytes32 key, uint256[] memory value) external;
    function removeUintArray(bytes32 key) external;

    function getIntArray(bytes32 key) external view returns (int256[] memory);
    function setIntArray(bytes32 key, int256[] memory value) external;
    function removeIntArray(bytes32 key) external;

    function getAddressArray(bytes32 key) external view returns (address[] memory);
    function setAddressArray(bytes32 key, address[] memory value) external;
    function removeAddressArray(bytes32 key) external;

    function getBoolArray(bytes32 key) external view returns (bool[] memory);
    function setBoolArray(bytes32 key, bool[] memory value) external;
    function removeBoolArray(bytes32 key) external;

    function getStringArray(bytes32 key) external view returns (string[] memory);
    function setStringArray(bytes32 key, string[] memory value) external;
    function removeStringArray(bytes32 key) external;

    function getBytes32Array(bytes32 key) external view returns (bytes32[] memory);
    function setBytes32Array(bytes32 key, bytes32[] memory value) external;
    function removeBytes32Array(bytes32 key) external;

    function containsBytes32(bytes32 setKey, bytes32 value) external view returns (bool);
    function getBytes32Count(bytes32 setKey) external view returns (uint256);
    function getBytes32ValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (bytes32[] memory);
    function addBytes32(bytes32 setKey, bytes32 value) external;
    function removeBytes32(bytes32 setKey, bytes32 value) external;

    function containsAddress(bytes32 setKey, address value) external view returns (bool);
    function getAddressCount(bytes32 setKey) external view returns (uint256);
    function getAddressValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (address[] memory);
    function addAddress(bytes32 setKey, address value) external;
    function removeAddress(bytes32 setKey, address value) external;

    function containsUint(bytes32 setKey, uint256 value) external view returns (bool);
    function getUintCount(bytes32 setKey) external view returns (uint256);
    function getUintValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (uint256[] memory);
    function addUint(bytes32 setKey, uint256 value) external;
    function removeUint(bytes32 setKey, uint256 value) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IDataStore.sol"; // Import the DataStore contract

interface IExchangeRouter {
    
    function dataStore() external view returns (IDataStore);
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
    
    struct CreateDepositParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minMarketTokens;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct CreateWithdrawalParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }


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

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }

    // @param receiver for order.receiver
    // @param callbackContract for order.callbackContract
    // @param market for order.market
    // @param initialCollateralToken for order.initialCollateralToken
    // @param swapPath for order.swapPath
    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd for order.sizeDeltaUsd
    // @param triggerPrice for order.triggerPrice
    // @param acceptablePrice for order.acceptablePrice
    // @param executionFee for order.executionFee
    // @param callbackGasLimit for order.callbackGasLimit
    // @param minOutputAmount for order.minOutputAmount
    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }

    // @dev Wraps the specified amount of native tokens into WNT then sends the WNT to the specified address
    function sendWnt(address receiver, uint256 amount) external payable;

    // @dev Sends the given amount of tokens to the given address
    function sendTokens(address token, address receiver, uint256 amount) external payable;

    function createDeposit(
        CreateDepositParams calldata params
    ) external payable returns (bytes32);

    function createWithdrawal(
        CreateWithdrawalParams calldata params
    ) external payable returns (bytes32);

    function createOrder(
        CreateOrderParams calldata params
    ) external payable returns (bytes32);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IMarket {
    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IMarketPoolValueInfo {
    struct Props {
        int256 poolValue;
        int256 longPnl;
        int256 shortPnl;
        int256 netPnl;

        uint256 longTokenAmount;
        uint256 shortTokenAmount;
        uint256 longTokenUsd;
        uint256 shortTokenUsd;

        uint256 totalBorrowingFees;
        uint256 borrowingFeePoolFactor;

        uint256 impactPoolAmount;
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

interface IPrice {
    struct Props {
        uint256 min;
        uint256 max;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IDataStore.sol"; // Import the DataStore contract
import "./IMarket.sol"; // Import the Market contract
import "./IPrice.sol"; // Import the Price contract
import "./IMarketPoolValueInfo.sol"; // Import the MarketPoolValueInfo contract

interface IReader {
    function getMarketTokenPrice(
        IDataStore dataStore,
        IMarket.Props memory market,
        IPrice.Props memory indexTokenPrice,
        IPrice.Props memory longTokenPrice,
        IPrice.Props memory shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) external view returns (int256, IMarketPoolValueInfo.Props memory);
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