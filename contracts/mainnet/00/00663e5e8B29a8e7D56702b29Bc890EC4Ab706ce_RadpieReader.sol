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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

  function latestAnswer() external view returns (int256);    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterRadpie {
    function poolLength() external view returns (uint256);

    function setPoolManagerStatus(address _address, bool _bool) external;

    function add(
        uint256 _allocPoint,
        address _stakingTokenToken,
        address _receiptToken,
        address _rewarder
    ) external;

    function set(
        address _stakingToken,
        uint256 _allocPoint,
        address _helper,
        address _rewarder,
        bool _helperNeedsHarvest
    ) external;

    function createRewarder(
        address _stakingTokenToken,
        address mainRewardToken
    ) external returns (address);

    // View function to see pending GMPs on frontend.
    function getPoolInfo(
        address token
    )
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function pendingTokens(
        address _stakingToken,
        address _user,
        address token
    )
        external
        view
        returns (
            uint256 _pendingGMP,
            address _bonusTokenAddress,
            string memory _bonusTokenSymbol,
            uint256 _pendingBonusToken
        );

    function allPendingTokens(
        address _stakingToken,
        address _user
    )
        external
        view
        returns (
            uint256 pendingRadpie,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );

    function massUpdatePools() external;

    function updatePool(address _stakingToken) external;

    function deposit(address _stakingToken, uint256 _amount) external;

    function depositFor(
        address _stakingToken,
        address _for,
        uint256 _amount
    ) external;

    function withdraw(address _stakingToken, uint256 _amount) external;

    function beforeReceiptTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function afterReceiptTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;


    function multiclaimFor(
        address[] calldata _stakingTokens,
        address[][] calldata _rewardTokens,
        address user_address
    ) external;

    function multiclaimOnBehalf(
        address[] memory _stakingTokens,
        address[][] calldata _rewardTokens,
        address user_address
    ) external;

    function emergencyWithdraw(address _stakingToken, address sender) external;

    function updateEmissionRate(uint256 _gmpPerSec) external;

    function stakingInfo(
        address _stakingToken,
        address _user
    ) external view returns (uint256 depositAmount, uint256 availableAmount);

    function totalTokenStaked(
        address _stakingToken
    ) external view returns (uint256);

    function registeredToken(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRadpieReceiptToken {

    function assetPerShare() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRewardDistributor {
    // External View Functions
    function getTotalDlpLocked() external view returns (uint256);

    function claimableDlpRewards()
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory amounts);

    function claimableAndPendingRDNT(
        address[] calldata tokens
    )
        external
        view
        returns (uint256 claimable, uint256[] memory pendings, uint256 vesting, uint256 vested);

    function rdntRewardEligibility()
        external
        view
        returns (
            bool isEligibleForRDNT,
            uint256 lockedDLPUSD,
            uint256 totalCollateralUSD,
            uint256 requiredDLPUSD,
            uint256 requiredDLPUSDWithTolerance
        );

    function sendRewards(address asset, address rewardToken, uint256 amount) external;

    function enqueueRDNT(
        address[] memory _poolTokenList,
        uint256 _lastSeenClaimableRDNT,
        uint256 _updatedClamable
    ) external;

    function getCalculatedStreamingFeePercentage(address _receiptToken) external view returns(uint256);

    function calculateStreamingFeeInflation(
        address _receiptToken,
        uint256 _feePercentage
    )
    external
    view
    returns (uint256);

    function updatelastStreamingLastFeeTimestamp(
        address _receiptToken,
        uint256 _updatedLastStreamingTime
    ) external;

    function streamingFeePercentage(address _receiptToken) external view returns (uint256);

    function enqueueEntitledRDNT(address _receipt, uint256 _amount) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

interface IAaveIncentivesController {
	event RewardsAccrued(address indexed user, uint256 amount);

	event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

	event RewardsClaimed(address indexed user, address indexed to, address indexed claimer, uint256 amount);

	event ClaimerSet(address indexed user, address indexed claimer);

	/*
	 * @dev Returns the configuration of the distribution for a certain asset
	 * @param asset The address of the reference asset of the distribution
	 * @return The asset index, the emission per second and the last updated timestamp
	 **/
	function getAssetData(address asset) external view returns (uint256, uint256, uint256);

	/**
	 * @dev Whitelists an address to claim the rewards on behalf of another address
	 * @param user The address of the user
	 * @param claimer The address of the claimer
	 */
	function setClaimer(address user, address claimer) external;

	/**
	 * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
	 * @param user The address of the user
	 * @return The claimer address
	 */
	function getClaimer(address user) external view returns (address);

	/**
	 * @dev Configure assets for a certain rewards emission
	 * @param assets The assets to incentivize
	 * @param emissionsPerSecond The emission for each asset
	 */
	function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 **/
	function handleActionBefore(address user) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 * @param userBalance The balance of the user of the asset in the lending pool
	 * @param totalSupply The total supply of the asset in the lending pool
	 **/
	function handleActionAfter(address user, uint256 userBalance, uint256 totalSupply) external;

	/**
	 * @dev Returns the total of rewards of an user, already accrued + not yet accrued
	 * @param user The address of the user
	 * @return The rewards
	 **/
	function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

	/**
	 * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
	 * @param amount Amount of rewards to claim
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);

	/**
	 * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
	 * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
	 * @param amount Amount of rewards to claim
	 * @param user Address to check and claim rewards
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewardsOnBehalf(
		address[] calldata assets,
		uint256 amount,
		address user,
		address to
	) external returns (uint256);

	/**
	 * @dev returns the unclaimed rewards of the user
	 * @param user the address of the user
	 * @return the unclaimed user rewards
	 */
	function getUserUnclaimedRewards(address user) external view returns (uint256);

	/**
	 * @dev returns the unclaimed rewards of the user
	 * @param user the address of the user
	 * @param asset The asset to incentivize
	 * @return the user index for the asset
	 */
	function getUserAssetData(address user, address asset) external view returns (uint256);

	/**
	 * @dev for backward compatibility with previous implementation of the Incentives controller
	 */
	function REWARD_TOKEN() external view returns (address);

	/**
	 * @dev for backward compatibility with previous implementation of the Incentives controller
	 */
	function PRECISION() external view returns (uint8);

	/**
	 * @dev Gets the distribution end timestamp of the emissions
	 */
	function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

interface IChefIncentivesController {
    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     **/
    function handleActionBefore(address user) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleActionAfter(address user, uint256 userBalance, uint256 totalSupply) external;

    /**
     * @dev Called by the locking contracts after locking or unlocking happens
     * @param user The address of the user
     **/
    function beforeLockUpdate(address user) external;

    /**
     * @notice Hook for lock update.
     * @dev Called by the locking contracts after locking or unlocking happens
     */
    function afterLockUpdate(address _user) external;

    function addPool(address _token, uint256 _allocPoint) external;

    function claim(address _user, address[] calldata _tokens) external;

    function setClaimReceiver(address _user, address _receiver) external;

    function getRegisteredTokens() external view returns (address[] memory);

    function disqualifyUser(address _user, address _hunter) external returns (uint256 bounty);

    function bountyForUser(address _user) external view returns (uint256 bounty);

    function allPendingRewards(address _user) external view returns (uint256 pending);

    function claimAll(address _user) external;

    function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

    function setEligibilityExempt(address _address, bool _value) external;

    function pendingRewards(
        address _user,
        address[] memory _tokens
    ) external view returns (uint256[] memory);

    function rewardsPerSecond() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function userBaseClaimable(address _user) external view returns (uint256);

    function poolInfo(address _pool) external view returns(uint256 totalSupply, uint256 allocPoint, uint256 lastRewardTime, uint256 accRewardPerShar, address onwardIncentives);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
pragma abicoder v2;

import "./LockedBalance.sol";

interface IFeeDistribution {
	struct RewardData {
		address token;
		uint256 amount;
	}

	function addReward(address rewardsToken) external;

	function lockedBalances(
		address user
	) external view returns (uint256, uint256, uint256, uint256, LockedBalance[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableAToken} from "./IInitializableAToken.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

interface IIncentivizedERC20 {
	function getAssetPrice() external view returns (uint256);

	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {ILendingPool} from "./ILendingPool.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

/**
 * @title IInitializableAToken
 * @notice Interface for the initialize function on AToken
 * @author Aave
 **/
interface IInitializableAToken {
	/**
	 * @dev Emitted when an aToken is initialized
	 * @param underlyingAsset The address of the underlying asset
	 * @param pool The address of the associated lending pool
	 * @param treasury The address of the treasury
	 * @param incentivesController The address of the incentives controller for this aToken
	 * @param aTokenDecimals the decimals of the underlying
	 * @param aTokenName the name of the aToken
	 * @param aTokenSymbol the symbol of the aToken
	 * @param params A set of encoded parameters for additional initialization
	 **/
	event Initialized(
		address indexed underlyingAsset,
		address indexed pool,
		address treasury,
		address incentivesController,
		uint8 aTokenDecimals,
		string aTokenName,
		string aTokenSymbol,
		bytes params
	);

	/**
	 * @dev Initializes the aToken
	 * @param pool The address of the lending pool where this aToken will be used
	 * @param treasury The address of the Aave treasury, receiving the fees on this aToken
	 * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 * @param incentivesController The smart contract managing potential incentives distribution
	 * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
	 * @param aTokenName The name of the aToken
	 * @param aTokenSymbol The symbol of the aToken
	 */
	function initialize(
		ILendingPool pool,
		address treasury,
		address underlyingAsset,
		IAaveIncentivesController incentivesController,
		uint8 aTokenDecimals,
		string calldata aTokenName,
		string calldata aTokenSymbol,
		bytes calldata params
	) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../../libraries/radiant/DataTypes.sol";

interface ILendingPool {
	/**
	 * @dev Emitted on deposit()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address initiating the deposit
	 * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
	 * @param amount The amount deposited
	 * @param referral The referral code used
	 **/
	event Deposit(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint16 indexed referral
	);

	/**
	 * @dev Emitted on withdraw()
	 * @param reserve The address of the underlyng asset being withdrawn
	 * @param user The address initiating the withdrawal, owner of aTokens
	 * @param to Address that will receive the underlying
	 * @param amount The amount to be withdrawn
	 **/
	event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

	/**
	 * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
	 * @param reserve The address of the underlying asset being borrowed
	 * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
	 * initiator of the transaction on flashLoan()
	 * @param onBehalfOf The address that will be getting the debt
	 * @param amount The amount borrowed out
	 * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
	 * @param borrowRate The numeric rate at which the user has borrowed
	 * @param referral The referral code used
	 **/
	event Borrow(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 borrowRateMode,
		uint256 borrowRate,
		uint16 indexed referral
	);

	/**
	 * @dev Emitted on repay()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The beneficiary of the repayment, getting his debt reduced
	 * @param repayer The address of the user initiating the repay(), providing the funds
	 * @param amount The amount repaid
	 **/
	event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

	/**
	 * @dev Emitted on swapBorrowRateMode()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user swapping his rate mode
	 * @param rateMode The rate mode that the user wants to swap to
	 **/
	event Swap(address indexed reserve, address indexed user, uint256 rateMode);

	/**
	 * @dev Emitted on setUserUseReserveAsCollateral()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user enabling the usage as collateral
	 **/
	event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on setUserUseReserveAsCollateral()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user enabling the usage as collateral
	 **/
	event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on rebalanceStableBorrowRate()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user for which the rebalance has been executed
	 **/
	event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on flashLoan()
	 * @param target The address of the flash loan receiver contract
	 * @param initiator The address initiating the flash loan
	 * @param asset The address of the asset being flash borrowed
	 * @param amount The amount flash borrowed
	 * @param premium The fee flash borrowed
	 * @param referralCode The referral code used
	 **/
	event FlashLoan(
		address indexed target,
		address indexed initiator,
		address indexed asset,
		uint256 amount,
		uint256 premium,
		uint16 referralCode
	);

	/**
	 * @dev Emitted when the pause is triggered.
	 */
	event Paused();

	/**
	 * @dev Emitted when the pause is lifted.
	 */
	event Unpaused();

	/**
	 * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
	 * LendingPoolCollateral manager using a DELEGATECALL
	 * This allows to have the events in the generated ABI for LendingPool.
	 * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
	 * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
	 * @param user The address of the borrower getting liquidated
	 * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
	 * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
	 * @param liquidator The address of the liquidator
	 * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
	 * to receive the underlying collateral asset directly
	 **/
	event LiquidationCall(
		address indexed collateralAsset,
		address indexed debtAsset,
		address indexed user,
		uint256 debtToCover,
		uint256 liquidatedCollateralAmount,
		address liquidator,
		bool receiveAToken
	);

	/**
	 * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
	 * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
	 * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
	 * gets added to the LendingPool ABI
	 * @param reserve The address of the underlying asset of the reserve
	 * @param liquidityRate The new liquidity rate
	 * @param stableBorrowRate The new stable borrow rate
	 * @param variableBorrowRate The new variable borrow rate
	 * @param liquidityIndex The new liquidity index
	 * @param variableBorrowIndex The new variable borrow index
	 **/
	event ReserveDataUpdated(
		address indexed reserve,
		uint256 liquidityRate,
		uint256 stableBorrowRate,
		uint256 variableBorrowRate,
		uint256 liquidityIndex,
		uint256 variableBorrowIndex
	);

	/**
	 * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
	 * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
	 * @param asset The address of the underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

	function depositWithAutoDLP(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

	/**
	 * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
	 * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
	 * @param asset The address of the underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
	 * @param to Address that will receive the underlying, same as msg.sender if the user
	 *   wants to receive it on his own wallet, or a different address if the beneficiary is a
	 *   different wallet
	 * @return The final amount withdrawn
	 **/
	function withdraw(address asset, uint256 amount, address to) external returns (uint256);

	/**
	 * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
	 * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
	 * corresponding debt token (StableDebtToken or VariableDebtToken)
	 * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
	 *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
	 * @param asset The address of the underlying asset to borrow
	 * @param amount The amount to be borrowed
	 * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
	 * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
	 * if he has been given credit delegation allowance
	 **/
	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	/**
	 * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
	 * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
	 * @param asset The address of the borrowed underlying asset previously borrowed
	 * @param amount The amount to repay
	 * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
	 * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
	 * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
	 * user calling the function if he wants to reduce/remove his own debt, or the address of any other
	 * other borrower whose debt should be removed
	 * @return The final amount repaid
	 **/
	function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

	/**
	 * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
	 * @param asset The address of the underlying asset borrowed
	 * @param rateMode The rate mode that the user wants to swap to
	 **/
	function swapBorrowRateMode(address asset, uint256 rateMode) external;

	/**
	 * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
	 * - Users can be rebalanced if the following conditions are satisfied:
	 *     1. Usage ratio is above 95%
	 *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
	 *        borrowed at a stable rate and depositors are not earning enough
	 * @param asset The address of the underlying asset borrowed
	 * @param user The address of the user to be rebalanced
	 **/
	function rebalanceStableBorrowRate(address asset, address user) external;

	/**
	 * @dev Allows depositors to enable/disable a specific deposited asset as collateral
	 * @param asset The address of the underlying asset deposited
	 * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
	 **/
	function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

	/**
	 * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
	 * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
	 *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
	 * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
	 * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
	 * @param user The address of the borrower getting liquidated
	 * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
	 * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
	 * to receive the underlying collateral asset directly
	 **/
	function liquidationCall(
		address collateralAsset,
		address debtAsset,
		address user,
		uint256 debtToCover,
		bool receiveAToken
	) external;

	/**
	 * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
	 * as long as the amount taken plus a fee is returned.
	 * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
	 * For further details please visit https://developers.aave.com
	 * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
	 * @param assets The addresses of the assets being flash-borrowed
	 * @param amounts The amounts amounts being flash-borrowed
	 * @param modes Types of the debt to open if the flash loan is not returned:
	 *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
	 *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
	 *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
	 * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
	 * @param params Variadic packed params to pass to the receiver as extra information
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	// function flashLoan(
	// 	address receiverAddress,
	// 	address[] calldata assets,
	// 	uint256[] calldata amounts,
	// 	uint256[] calldata modes,
	// 	address onBehalfOf,
	// 	bytes calldata params,
	// 	uint16 referralCode
	// ) external;

	/**
	 * @dev Returns the user account data across all the reserves
	 * @param user The address of the user
	 * @return totalCollateralETH the total collateral in ETH of the user
	 * @return totalDebtETH the total debt in ETH of the user
	 * @return availableBorrowsETH the borrowing power left of the user
	 * @return currentLiquidationThreshold the liquidation threshold of the user
	 * @return ltv the loan to value of the user
	 * @return healthFactor the current health factor of the user
	 **/
	function getUserAccountData(
		address user
	)
		external
		view
		returns (
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	function initReserve(
		address reserve,
		address aTokenAddress,
		address stableDebtAddress,
		address variableDebtAddress,
		address interestRateStrategyAddress
	) external;

	function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

	function setConfiguration(address reserve, uint256 configuration) external;

	/**
	 * @dev Returns the configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The configuration of the reserve
	 **/
	function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

	/**
	 * @dev Returns the configuration of the user across all the reserves
	 * @param user The user address
	 * @return The configuration of the user
	 **/
	function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

	/**
	 * @dev Returns the normalized income normalized income of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The reserve's normalized income
	 */
	function getReserveNormalizedIncome(address asset) external view returns (uint256);

	/**
	 * @dev Returns the normalized variable debt per unit of asset
	 * @param asset The address of the underlying asset of the reserve
	 * @return The reserve normalized variable debt
	 */
	function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

	/**
	 * @dev Returns the state and configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The state of the reserve
	 **/
	function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

	function finalizeTransfer(
		address asset,
		address from,
		address to,
		uint256 amount,
		uint256 balanceFromAfter,
		uint256 balanceToBefore
	) external;

	function getReservesList() external view returns (address[] memory);

	function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

	function setPause(bool val) external;

	function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
	event MarketIdSet(string newMarketId);
	event LendingPoolUpdated(address indexed newAddress);
	event ConfigurationAdminUpdated(address indexed newAddress);
	event EmergencyAdminUpdated(address indexed newAddress);
	event LendingPoolConfiguratorUpdated(address indexed newAddress);
	event LendingPoolCollateralManagerUpdated(address indexed newAddress);
	event PriceOracleUpdated(address indexed newAddress);
	event LendingRateOracleUpdated(address indexed newAddress);
	event ProxyCreated(bytes32 id, address indexed newAddress);
	event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

	function getMarketId() external view returns (string memory);

	function setMarketId(string calldata marketId) external;

	function setAddress(bytes32 id, address newAddress) external;

	function setAddressAsProxy(bytes32 id, address impl) external;

	function getAddress(bytes32 id) external view returns (address);

	function getLendingPool() external view returns (address);

	function setLendingPoolImpl(address pool) external;

	function getLendingPoolConfigurator() external view returns (address);

	function setLendingPoolConfiguratorImpl(address configurator) external;

	function getLendingPoolCollateralManager() external view returns (address);

	function setLendingPoolCollateralManager(address manager) external;

	function getPoolAdmin() external view returns (address);

	function setPoolAdmin(address admin) external;

	function getEmergencyAdmin() external view returns (address);

	function setEmergencyAdmin(address admin) external;

	function getPriceOracle() external view returns (address);

	function setPriceOracle(address priceOracle) external;

	function getLendingRateOracle() external view returns (address);

	function setLendingRateOracle(address lendingRateOracle) external;

	function getLiquidationFeeTo() external view returns (address);

	function setLiquidationFeeTo(address liquidationFeeTo) external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
    function mint(address _receiver, uint256 _amount) external returns (bool);

    function burn(uint256 _amount) external returns (bool);

    function setMinter(address _minter) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./LockedBalance.sol";
import "./IFeeDistribution.sol";
import "./IMintableToken.sol";

interface IMultiFeeDistribution is IFeeDistribution {
    function exit(bool claimRewards) external;

    function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external;

    function rdntToken() external view returns (IMintableToken);

    function getPriceProvider() external view returns (address);

    function lockInfo(address user) external view returns (LockedBalance[] memory);

    function autocompoundEnabled(address user) external view returns (bool);

    function defaultLockIndex(address _user) external view returns (uint256);

    function autoRelockDisabled(address user) external view returns (bool);

    function totalBalance(address user) external view returns (uint256);

    function zapVestingToLp(address _address) external returns (uint256);

    function withdrawExpiredLocksFor(address _address) external returns (uint256);

    function withdraw(uint256 amount) external;

    function claimableRewards(
        address account
    ) external view returns (IFeeDistribution.RewardData[] memory rewards);

    function setDefaultRelockTypeIndex(uint256 _index) external;

    function daoTreasury() external view returns (address);

    function stakingToken() external view returns (address);

    function claimFromConverter(address) external;

    function mint(address user, uint256 amount, bool withPenalty) external;

    function getReward(address[] memory _rewardTokens) external;

    function getAllRewards() external;

    function setRelock(bool _status) external;

    function rewards(address _user, address _rewardToken) external view returns (uint256);

    function earnedBalances(
        address user
    ) external view returns (uint256 total, uint256 unlocked, EarnedBalance[] memory earningsData);
}

interface IMFDPlus is IMultiFeeDistribution {
    function getLastClaimTime(address _user) external returns (uint256);

    function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

    function claimCompound(address _user, bool _execute) external returns (uint256 bountyAmt);

    function setAutocompound(bool _newVal) external;

    function getAutocompoundEnabled(address _user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPriceProvider {

	function getTokenPrice() external view returns (uint256);

	function getTokenPriceUsd() external view returns (uint256);

	function getLpTokenPrice() external view returns (uint256);

	function getLpTokenPriceUsd() external view returns (uint256);

	function decimals() external view returns (uint256);

	function update() external;

	function baseTokenPriceInUsdProxyAggregator() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IScaledBalanceToken {
	/**
	 * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
	 * updated stored balance divided by the reserve's liquidity index at the moment of the update
	 * @param user The user whose balance is calculated
	 * @return The scaled balance of the user
	 **/
	function scaledBalanceOf(address user) external view returns (uint256);

	/**
	 * @dev Returns the scaled balance of the user and the scaled total supply.
	 * @param user The address of the user
	 * @return The scaled balance of the user
	 * @return The scaled balance and the scaled total supply
	 **/
	function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

	/**
	 * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
	 * @return The scaled total supply
	 **/
	function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
pragma abicoder v2;

struct LockedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 multiplier;
	uint256 duration;
}

struct EarnedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 penalty;
}

struct Reward {
	uint256 periodFinish;
	uint256 rewardPerSecond;
	uint256 lastUpdateTime;
	uint256 rewardPerTokenStored;
	// tracks already-added balances to handle accrued interest in aToken rewards
	// for the stakingToken this value is unused and will always be 0
	uint256 balance;
}

struct Balances {
	uint256 total; // sum of earnings and lockings; no use when LP and RDNT is different
	uint256 unlocked; // RDNT token
	uint256 locked; // LP token or RDNT token
	uint256 lockedWithMultiplier; // Multiplied locked amount
	uint256 earned; // RDNT token
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBaseRewardPoolV3 {
    function allEarned(address _account) external view returns (uint256[] memory pendingBonusRewards);
    function rewardTokenInfos()
        external
        view
        returns
        (
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IMasterRadpie } from "../IMasterRadpie.sol";

interface IMasterRadpieReader is IMasterRadpie {

    struct RadpiePoolInfo {
        address stakingToken; // Address of staking token contract to be staked.
        address receiptToken; // Address of receipt token contract represent a staking position
        uint256 allocPoint; // How many allocation points assigned to this pool. Penpies to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that Penpies distribution occurs.
        uint256 accPenpiePerShare; // Accumulated Penpies per share, times 1e12. See below.
        uint256 totalStaked;
        address rewarder;
        bool    isActive;         
    }

    function tokenToPoolInfo(address) external view returns (RadpiePoolInfo memory);

    function legacyRewarders(address) external view returns (address);

    function legacyRewarderClaimed(address, address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRadpieStakingReader {

    struct RadiantStakingPool {
        address asset; // asset on Radiant
        address rToken;
        address vdToken;
        address rewarder;
        address helper;
        address receiptToken;
        uint256 maxCap;             // max receipt token amount
        uint256 lastActionHandled; // timestamp of ActionHandled trigged on Radiant ChefIncentive
        bool isNative;
        bool isActive;
    }

    function lastSeenClaimableTime() external view returns(uint256);

    function pools(address) external view returns (
        address asset,
        address rToken,
        address vdToken,
        address rewarder,
        address receiptToken,
        uint256 maxCap,
        uint256 lastActionHandled,
        bool isNative,
        bool isActive        
    );

    function assetPerShare(address _asset) external view returns (uint256);

    function rdntRewardEligibility() external view returns(bool isEligibleForRDNT, uint256 lockedDLPUSD, uint256 totalCollateralUSD, 
        uint256 requiredDLPUSD, uint256 requiredDLPUSDWithTolerance);

    function claimableAndPendingRDNT(address[] calldata _tokens) external view
        returns (uint256 claimmable, uint256[] memory pendings, uint256 vesting, uint256 vested);

    function rdntVestManager() external view returns(address);

    function systemHealthFactor() external view returns(uint256);

    function minHealthFactor() external view returns(uint256);

    function totalEarnedRDNT() external view returns(uint256);

    function assetLoopHelper() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRDNTRewardManagerReader {

    function nextVestingTime() external view returns(uint256);

    function entitledRDNTByReceipt(address _account, address _receipt) external view returns (uint256);

    function esRDNT() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct VestingSchedule {
    uint256 amount;
    uint256 endTime;
}    

interface IRDNTVestManagerReader {

    function nextVestingTime() external view returns(uint256);

    function getAllVestingInfo(
        address _user
    ) external view returns (VestingSchedule[] memory , uint256 totalRDNTRewards, uint256 totalVested, uint256 totalVesting);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

library DataTypes {
	// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
	struct ReserveData {
		//stores the reserve configuration
		ReserveConfigurationMap configuration;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable borrow index. Expressed in ray
		uint128 variableBorrowIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable borrow rate. Expressed in ray
		uint128 currentVariableBorrowRate;
		//the current stable borrow rate. Expressed in ray
		uint128 currentStableBorrowRate;
		uint40 lastUpdateTimestamp;
		//tokens addresses
		address aTokenAddress;
		address stableDebtTokenAddress;
		address variableDebtTokenAddress;
		//address of the interest rate strategy
		address interestRateStrategyAddress;
		//the id of the reserve. Represents the position in the list of the active reserves
		uint8 id;
	}

	struct ReserveConfigurationMap {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: Reserve is active
		//bit 57: reserve is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60-63: reserved
		//bit 64-79: reserve factor
		uint256 data;
	}

	struct UserConfigurationMap {
		uint256 data;
	}

	enum InterestRateMode {
		NONE,
		STABLE,
		VARIABLE
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
	//common errors
	string public constant CALLER_NOT_POOL_ADMIN = "33"; // 'The caller must be the pool admin'
	string public constant BORROW_ALLOWANCE_NOT_ENOUGH = "59"; // User borrows on behalf, but allowance are too small

	//contract specific errors
	string public constant VL_INVALID_AMOUNT = "1"; // 'Amount must be greater than 0'
	string public constant VL_NO_ACTIVE_RESERVE = "2"; // 'Action requires an active reserve'
	string public constant VL_RESERVE_FROZEN = "3"; // 'Action cannot be performed because the reserve is frozen'
	string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "4"; // 'The current liquidity is not enough'
	string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "5"; // 'User cannot withdraw more than the available balance'
	string public constant VL_TRANSFER_NOT_ALLOWED = "6"; // 'Transfer cannot be allowed.'
	string public constant VL_BORROWING_NOT_ENABLED = "7"; // 'Borrowing is not enabled'
	string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = "8"; // 'Invalid interest rate mode selected'
	string public constant VL_COLLATERAL_BALANCE_IS_0 = "9"; // 'The collateral balance is 0'
	string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "10"; // 'Health factor is lesser than the liquidation threshold'
	string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "11"; // 'There is not enough collateral to cover a new borrow'
	string public constant VL_STABLE_BORROWING_NOT_ENABLED = "12"; // stable borrowing not enabled
	string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = "13"; // collateral is (mostly) the same currency that is being borrowed
	string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "14"; // 'The requested amount is greater than the max loan size in stable rate mode
	string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "15"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
	string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "16"; // 'To repay on behalf of an user an explicit amount to repay is needed'
	string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = "17"; // 'User does not have a stable rate loan in progress on this reserve'
	string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = "18"; // 'User does not have a variable rate loan in progress on this reserve'
	string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = "19"; // 'The underlying balance needs to be greater than 0'
	string public constant VL_DEPOSIT_ALREADY_IN_USE = "20"; // 'User deposit is already being used as collateral'
	string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = "21"; // 'User does not have any stable rate loan for this reserve'
	string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "22"; // 'Interest rate rebalance conditions were not met'
	string public constant LP_LIQUIDATION_CALL_FAILED = "23"; // 'Liquidation call failed'
	string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "24"; // 'There is not enough liquidity available to borrow'
	string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = "25"; // 'The requested amount is too small for a FlashLoan.'
	string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = "26"; // 'The actual balance of the protocol is inconsistent'
	string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = "27"; // 'The caller of the function is not the lending pool configurator'
	string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = "28";
	string public constant CT_CALLER_MUST_BE_LENDING_POOL = "29"; // 'The caller of this function must be a lending pool'
	string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = "30"; // 'User cannot give allowance to himself'
	string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = "31"; // 'Transferred amount needs to be greater than zero'
	string public constant RL_RESERVE_ALREADY_INITIALIZED = "32"; // 'Reserve has already been initialized'
	string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "34"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = "35"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = "36"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = "37"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "38"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "39"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = "40"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_CONFIGURATION = "75"; // 'Invalid risk parameters for the reserve'
	string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "76"; // 'The caller must be the emergency admin'
	string public constant LPAPR_PROVIDER_NOT_REGISTERED = "41"; // 'Provider is not registered'
	string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "42"; // 'Health factor is not below the threshold'
	string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = "43"; // 'The collateral chosen cannot be liquidated'
	string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "44"; // 'User did not borrow the specified currency'
	string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = "45"; // "There isn't enough liquidity available to liquidate"
	string public constant LPCM_NO_ERRORS = "46"; // 'No errors'
	string public constant LP_INVALID_FLASHLOAN_MODE = "47"; //Invalid flashloan mode selected
	string public constant MATH_MULTIPLICATION_OVERFLOW = "48";
	string public constant MATH_ADDITION_OVERFLOW = "49";
	string public constant MATH_DIVISION_BY_ZERO = "50";
	string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "51"; //  Liquidity index overflows uint128
	string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "52"; //  Variable borrow index overflows uint128
	string public constant RL_LIQUIDITY_RATE_OVERFLOW = "53"; //  Liquidity rate overflows uint128
	string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "54"; //  Variable borrow rate overflows uint128
	string public constant RL_STABLE_BORROW_RATE_OVERFLOW = "55"; //  Stable borrow rate overflows uint128
	string public constant CT_INVALID_MINT_AMOUNT = "56"; //invalid amount to mint
	string public constant LP_FAILED_REPAY_WITH_COLLATERAL = "57";
	string public constant CT_INVALID_BURN_AMOUNT = "58"; //invalid amount to burn
	string public constant LP_FAILED_COLLATERAL_SWAP = "60";
	string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = "61";
	string public constant LP_REENTRANCY_NOT_ALLOWED = "62";
	string public constant LP_CALLER_MUST_BE_AN_ATOKEN = "63";
	string public constant LP_IS_PAUSED = "64"; // 'Pool is paused'
	string public constant LP_NO_MORE_RESERVES_ALLOWED = "65";
	string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = "66";
	string public constant RC_INVALID_LTV = "67";
	string public constant RC_INVALID_LIQ_THRESHOLD = "68";
	string public constant RC_INVALID_LIQ_BONUS = "69";
	string public constant RC_INVALID_DECIMALS = "70";
	string public constant RC_INVALID_RESERVE_FACTOR = "71";
	string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "72";
	string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = "73";
	string public constant LP_INCONSISTENT_PARAMS_LENGTH = "74";
	string public constant UL_INVALID_INDEX = "77";
	string public constant LP_NOT_CONTRACT = "78";
	string public constant SDT_STABLE_DEBT_OVERFLOW = "79";
	string public constant SDT_BURN_EXCEEDS_BALANCE = "80";

	enum CollateralManagerErrors {
		NO_ERROR,
		NO_COLLATERAL_AVAILABLE,
		COLLATERAL_CANNOT_BE_LIQUIDATED,
		CURRRENCY_NOT_BORROWED,
		HEALTH_FACTOR_ABOVE_THRESHOLD,
		NOT_ENOUGH_LIQUIDITY,
		NO_ACTIVE_RESERVE,
		HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
		INVALID_EQUAL_ASSETS_TO_SWAP,
		FROZEN_RESERVE
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {Errors} from "./Errors.sol";
import {DataTypes} from "./DataTypes.sol";

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
	uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
	uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
	uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
	uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
	uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
	uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
	uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
	uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
	uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore

	/// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
	uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
	uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
	uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
	uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
	uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
	uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
	uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
	uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;

	uint256 constant MAX_VALID_LTV = 65535;
	uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
	uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
	uint256 constant MAX_VALID_DECIMALS = 255;
	uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;

	/**
	 * @dev Sets the Loan to Value of the reserve
	 * @param self The reserve configuration
	 * @param ltv the new ltv
	 **/
	function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
		require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

		self.data = (self.data & LTV_MASK) | ltv;
	}

	/**
	 * @dev Gets the Loan to Value of the reserve
	 * @param self The reserve configuration
	 * @return The loan to value
	 **/
	function getLtv(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
		return self.data & ~LTV_MASK;
	}

	/**
	 * @dev Sets the liquidation threshold of the reserve
	 * @param self The reserve configuration
	 * @param threshold The new liquidation threshold
	 **/
	function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold) internal pure {
		require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

		self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the liquidation threshold of the reserve
	 * @param self The reserve configuration
	 * @return The liquidation threshold
	 **/
	function getLiquidationThreshold(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
		return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
	}

	/**
	 * @dev Sets the liquidation bonus of the reserve
	 * @param self The reserve configuration
	 * @param bonus The new liquidation bonus
	 **/
	function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus) internal pure {
		require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

		self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the liquidation bonus of the reserve
	 * @param self The reserve configuration
	 * @return The liquidation bonus
	 **/
	function getLiquidationBonus(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
		return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
	}

	/**
	 * @dev Sets the decimals of the underlying asset of the reserve
	 * @param self The reserve configuration
	 * @param decimals The decimals
	 **/
	function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals) internal pure {
		require(decimals <= MAX_VALID_DECIMALS, Errors.RC_INVALID_DECIMALS);

		self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the decimals of the underlying asset of the reserve
	 * @param self The reserve configuration
	 * @return The decimals of the asset
	 **/
	function getDecimals(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
		return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
	}

	/**
	 * @dev Sets the active state of the reserve
	 * @param self The reserve configuration
	 * @param active The active state
	 **/
	function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
		self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the active state of the reserve
	 * @param self The reserve configuration
	 * @return The active state
	 **/
	function getActive(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
		return (self.data & ~ACTIVE_MASK) != 0;
	}

	/**
	 * @dev Sets the frozen state of the reserve
	 * @param self The reserve configuration
	 * @param frozen The frozen state
	 **/
	function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
		self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the frozen state of the reserve
	 * @param self The reserve configuration
	 * @return The frozen state
	 **/
	function getFrozen(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
		return (self.data & ~FROZEN_MASK) != 0;
	}

	/**
	 * @dev Enables or disables borrowing on the reserve
	 * @param self The reserve configuration
	 * @param enabled True if the borrowing needs to be enabled, false otherwise
	 **/
	function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
		self.data = (self.data & BORROWING_MASK) | (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the borrowing state of the reserve
	 * @param self The reserve configuration
	 * @return The borrowing state
	 **/
	function getBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
		return (self.data & ~BORROWING_MASK) != 0;
	}

	/**
	 * @dev Enables or disables stable rate borrowing on the reserve
	 * @param self The reserve configuration
	 * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
	 **/
	function setStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
		self.data =
			(self.data & STABLE_BORROWING_MASK) |
			(uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the stable rate borrowing state of the reserve
	 * @param self The reserve configuration
	 * @return The stable rate borrowing state
	 **/
	function getStableRateBorrowingEnabled(
		DataTypes.ReserveConfigurationMap storage self
	) internal view returns (bool) {
		return (self.data & ~STABLE_BORROWING_MASK) != 0;
	}

	/**
	 * @dev Sets the reserve factor of the reserve
	 * @param self The reserve configuration
	 * @param reserveFactor The reserve factor
	 **/
	function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor) internal pure {
		require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.RC_INVALID_RESERVE_FACTOR);

		self.data = (self.data & RESERVE_FACTOR_MASK) | (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the reserve factor of the reserve
	 * @param self The reserve configuration
	 * @return The reserve factor
	 **/
	function getReserveFactor(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
		return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
	}

	/**
	 * @dev Gets the configuration flags of the reserve
	 * @param self The reserve configuration
	 * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
	 **/
	function getFlags(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool, bool, bool, bool) {
		uint256 dataLocal = self.data;

		return (
			(dataLocal & ~ACTIVE_MASK) != 0,
			(dataLocal & ~FROZEN_MASK) != 0,
			(dataLocal & ~BORROWING_MASK) != 0,
			(dataLocal & ~STABLE_BORROWING_MASK) != 0
		);
	}

	/**
	 * @dev Gets the configuration paramters of the reserve
	 * @param self The reserve configuration
	 * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
	 **/
	function getParams(
		DataTypes.ReserveConfigurationMap storage self
	) internal view returns (uint256, uint256, uint256, uint256, uint256) {
		uint256 dataLocal = self.data;

		return (
			dataLocal & ~LTV_MASK,
			(dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
			(dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
			(dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
			(dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
		);
	}

	/**
	 * @dev Gets the configuration paramters of the reserve from a memory object
	 * @param self The reserve configuration
	 * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
	 **/
	function getParamsMemory(
		DataTypes.ReserveConfigurationMap memory self
	) internal pure returns (uint256, uint256, uint256, uint256, uint256) {
		return (
			self.data & ~LTV_MASK,
			(self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
			(self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
			(self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
			(self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
		);
	}

	/**
	 * @dev Gets the configuration flags of the reserve from a memory object
	 * @param self The reserve configuration
	 * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
	 **/
	function getFlagsMemory(
		DataTypes.ReserveConfigurationMap memory self
	) internal pure returns (bool, bool, bool, bool) {
		return (
			(self.data & ~ACTIVE_MASK) != 0,
			(self.data & ~FROZEN_MASK) != 0,
			(self.data & ~BORROWING_MASK) != 0,
			(self.data & ~STABLE_BORROWING_MASK) != 0
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IMasterRadpieReader } from "./interfaces/radpieReader/IMasterRadpieReader.sol";
import { IRadpieStakingReader } from "./interfaces/radpieReader/IRadpieStakingReader.sol";
import { IRDNTRewardManagerReader } from "./interfaces/radpieReader/IRDNTRewardManagerReader.sol";
import { IRDNTVestManagerReader } from "./interfaces/radpieReader/IRDNTVestManagerReader.sol";
import { IBaseRewardPoolV3 } from "./interfaces/radpieReader/IBaseRewardPoolV3.sol";
import { ILendingPool } from "./interfaces/radiant/ILendingPool.sol";
import { IChefIncentivesController } from "./interfaces/radiant/IChefIncentivesController.sol";
import { IMultiFeeDistribution } from "./interfaces/radiant/IMultiFeeDistribution.sol";
import { IPriceProvider } from "./interfaces/radiant/IPriceProvider.sol";
import { IRadpieReceiptToken } from "./interfaces/IRadpieReceiptToken.sol";
import { IRewardDistributor } from "./interfaces/IRewardDistributor.sol";

import { IIncentivizedERC20 } from "./interfaces/radiant/IIncentivizedERC20.sol";
import { ReaderDatatype } from "./ReaderDatatype.sol";
import { DataTypes } from "./libraries/radiant/DataTypes.sol";
import { ReserveConfiguration } from "./libraries/radiant/ReserveConfiguration.sol";
import { AggregatorV3Interface } from "./interfaces/chainlink/AggregatorV3Interface.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title RadpieRader
/// @author Magpie Team

contract RadpieReader is Initializable, OwnableUpgradeable, ReaderDatatype {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    address public radpieOFT;
    address public vlRDP;
    address public mDLP;
    address public RDNT;
    address public WETH;
    address public RDNT_LP;
    IMasterRadpieReader public masterRadpie;
    IRadpieStakingReader public radpieStaking;
    IRewardDistributor public rewardDistributor;
    IRDNTRewardManagerReader public rdntRewardManager;
    IRDNTVestManagerReader public rdntVestManager;
    IMultiFeeDistribution public radiantMFD;
    ILendingPool public lendingPool;
    IChefIncentivesController public chefIncentives;

    AggregatorV3Interface public RDNTOracle;
    uint256 constant DENOMINATOR = 10000;
    uint256[] public RDNTrevShare; // 0 LPers // 1 mDLP // 2 vlRDP

    /* ============ Events ============ */

    /* ============ Errors ============ */

    /* ============ Constructor ============ */

    function __RadpieReader_init() public initializer {
        __Ownable_init();
    }

    /* ============ External Getters ============ */

    function getRadpieInfo(address account) external view returns (RadpieInfo memory) {
        RadpieInfo memory info;
        uint256 poolCount = masterRadpie.poolLength();
        RadpiePool[] memory pools = new RadpiePool[](poolCount);

        info.systemRDNTInfo = getRadpieRDNTInfo(account);
        info.esRDNTInfo = getRadpieEsRDNTInfo(account);
        for (uint256 i = 0; i < poolCount; ++i) {
            pools[i] = getRadpiePoolInfo(i, account, info);
        }

        info.pools = pools;
        info.masterRadpie = address(masterRadpie);
        info.radpieStaking = address(radpieStaking);
        info.radpieOFT = radpieOFT;
        info.rdntRewardManager = address(rdntRewardManager);
        info.rdntVestManager = address(rdntVestManager);
        info.vlRDP = vlRDP;
        info.mDLP = mDLP;
        info.RDNT = RDNT;
        info.WETH = WETH;
        info.RDNT_LP = RDNT_LP;
        info.systemHealthFactor = radpieStaking.systemHealthFactor();
        info.minHealthFactor = radpieStaking.minHealthFactor();

        _updateBasedOnRevShare(info);

        return info;
    }

    function getRadpiePoolInfo(
        uint256 poolId,
        address account,
        RadpieInfo memory systemInfo
    ) public view returns (RadpiePool memory) {
        RadpiePool memory radpiePool;
        radpiePool.poolId = poolId;

        address registeredToken = masterRadpie.registeredToken(poolId);

        IMasterRadpieReader.RadpiePoolInfo memory radpiePoolInfo = masterRadpie.tokenToPoolInfo(
            registeredToken
        );

        (
            radpiePool.asset,
            radpiePool.rToken,
            radpiePool.vdToken,
            radpiePool.rewarder,
            ,
            radpiePool.maxCap,
            ,
            radpiePool.isNative,
            radpiePool.isActive
        ) = radpieStaking.pools(registeredToken);
        radpiePool.helper = radpieStaking.assetLoopHelper();

        radpiePool.stakingToken = radpiePoolInfo.stakingToken;
        radpiePool.receiptToken = radpiePoolInfo.receiptToken;
        (, , radpiePool.sizeOfPool, ) = masterRadpie.getPoolInfo(radpiePool.stakingToken);
        radpiePool.stakedTokenInfo = getERC20TokenInfo(radpiePool.stakingToken);

        uint256 price;
        uint256 assetPerShare = 10 ** 18;

        if (radpiePool.stakingToken == vlRDP) {
            radpiePool.poolType = "vlRDP_POOL";
            radpiePool.tvl =
                (radpiePool.sizeOfPool * price) /
                (10 ** radpiePool.stakedTokenInfo.decimals);
            radpiePool.leveragedTVL = radpiePool.tvl;
            radpiePool.asset = radpiePoolInfo.stakingToken;
            radpiePool.radpieLendingInfo = getRadpieLendingInfo(radpiePool, 0, 0, RDNTrevShare[2]);
        } else if (radpiePool.stakingToken == mDLP) {
            radpiePool.poolType = "mDLP_POOL";
            price = this.getDlpPrice();
            radpiePool.assetPrice = price;
            radpiePool.tvl =
                (radpiePool.sizeOfPool * price) /
                (10 ** radpiePool.stakedTokenInfo.decimals);
            radpiePool.leveragedTVL = radpiePool.tvl;
            radpiePool.asset = radpiePoolInfo.stakingToken;
            radpiePool.radpieLendingInfo = getRadpieLendingInfo(radpiePool, 0, 0, RDNTrevShare[1]);
        } else {
            // default is Radiant pools
            radpiePool.poolType = "RADIANT_POOL";
            price = IIncentivizedERC20(radpiePool.rToken).getAssetPrice();
            radpiePool.assetPrice = price;
            uint256 rTokenBal = IERC20(radpiePool.rToken).balanceOf(address(radpieStaking));
            uint256 debtBal = IERC20(radpiePool.vdToken).balanceOf(address(radpieStaking));
            assetPerShare = IRadpieReceiptToken(radpiePoolInfo.receiptToken).assetPerShare();
            radpiePool.tvl =
                (radpiePool.sizeOfPool * price * assetPerShare) /
                (10 ** (radpiePool.stakedTokenInfo.decimals + 18));
            radpiePool.debt = (debtBal * price) / (10 ** radpiePool.stakedTokenInfo.decimals);

            radpiePool.leveragedTVL =
                (rTokenBal * price * assetPerShare) /
                (10 ** (radpiePool.stakedTokenInfo.decimals + 18));
            radpiePool.radpieLendingInfo = getRadpieLendingInfo(
                radpiePool,
                rTokenBal,
                debtBal,
                RDNTrevShare[0]
            );
            systemInfo.systemRDNTInfo.totalRDNTpersec += radpiePool.radpieLendingInfo.RDNTpersec;
        }

        uint256 totalReceiptToken = IERC20(radpiePool.receiptToken).totalSupply();
        if (radpiePool.maxCap > totalReceiptToken)
            radpiePool.quotaLeft = ((radpiePool.maxCap - totalReceiptToken)) * assetPerShare / (10 ** 18);

        if (account != address(0)) {
            radpiePool.accountInfo = getRadpieAccountInfo(
                radpiePool,
                account,
                price,
                assetPerShare
            );
            radpiePool.rewardInfo = getRadpieRewardInfo(
                radpiePool.stakingToken,
                radpiePool.receiptToken,
                account
            );
            radpiePool.legacyRewardInfo = getRadpieLegacyRewardInfo(
                radpiePool.stakingToken,
                account
            );
        }

        return radpiePool;
    }

    function getERC20TokenInfo(address token) public view returns (ERC20TokenInfo memory) {
        ERC20TokenInfo memory tokenInfo;
        tokenInfo.tokenAddress = token;
        if (token == address(1)) {
            tokenInfo.symbol = "ETH";
            tokenInfo.decimals = 18;
            return tokenInfo;
        }
        ERC20 tokenContract = ERC20(token);
        tokenInfo.symbol = tokenContract.symbol();
        tokenInfo.decimals = tokenContract.decimals();
        return tokenInfo;
    }

    function getRadpieAccountInfo(
        RadpiePool memory pool,
        address account,
        uint256 assetPrice,
        uint256 assetPerShare
    ) public view returns (RadpieAccountInfo memory) {
        RadpieAccountInfo memory accountInfo;
        if (pool.isNative == true) {
            accountInfo.balance = account.balance;
        }
        else {
            accountInfo.balance = ERC20(pool.stakingToken).balanceOf(account);
        }
        (accountInfo.stakedAmount, accountInfo.availableAmount) = masterRadpie.stakingInfo(
            pool.stakingToken,
            account
        );

        if (pool.stakingToken == mDLP) {
            accountInfo.stakingAllowance = ERC20(pool.stakingToken).allowance(
                account,
                address(masterRadpie)
            );
            accountInfo.mDLPAllowance = ERC20(RDNT_LP).allowance(account, mDLP);
            accountInfo.rdntDlpBalance = ERC20(RDNT_LP).balanceOf(account);
            accountInfo.rdntBalance = ERC20(RDNT).balanceOf(account);
        } else if (pool.stakingToken == vlRDP) {
            accountInfo.stakingAllowance = ERC20(pool.stakingToken).allowance(
                account,
                address(vlRDP)
            );
        } else {
            if (pool.isNative) {
                 accountInfo.stakingAllowance = type(uint256).max;
            }
            else {
                accountInfo.stakingAllowance = ERC20(pool.stakingToken).allowance(
                    account,
                    address(pool.helper)
                );
            }
        }

        accountInfo.tvl =
            (assetPrice * accountInfo.stakedAmount * assetPerShare) /
            (10 ** (pool.stakedTokenInfo.decimals + 18));

        return accountInfo;
    }

    function getRadpieRewardInfo(
        address stakingToken,
        address receipt,
        address account
    ) public view returns (RadpieRewardInfo memory) {
        RadpieRewardInfo memory rewardInfo;
        (
            rewardInfo.pendingRDP,
            rewardInfo.bonusTokenAddresses,
            rewardInfo.bonusTokenSymbols,
            rewardInfo.pendingBonusRewards
        ) = masterRadpie.allPendingTokens(stakingToken, account);
        rewardInfo.entitledRDNT = rdntRewardManager.entitledRDNTByReceipt(account, receipt);
        return rewardInfo;
    }

    function getRadpieLendingInfo(
        RadpiePool memory pool,
        uint256 rTokenBal,
        uint256 vdTokenBal,
        uint256 _RDNTrevShare
    ) public view returns (RadpieLendingInfo memory) {
        RadpieLendingInfo memory lendingInfo;

        if (rTokenBal == 0 && vdTokenBal == 0) return lendingInfo;

        DataTypes.ReserveData memory baseData = lendingPool.getReserveData(pool.asset);

        lendingInfo.depositRate = (DENOMINATOR * baseData.currentLiquidityRate) / (10 ** 27);
        lendingInfo.borrowRate = (DENOMINATOR * baseData.currentVariableBorrowRate) / (10 ** 27);

        uint256 decimal = IERC20Metadata(pool.asset).decimals();
        lendingInfo.depositAPR =
            (rTokenBal * lendingInfo.depositRate * pool.assetPrice) /
            (pool.tvl * 10 ** decimal);
        lendingInfo.borrowAPR =
            (vdTokenBal * lendingInfo.borrowRate * pool.assetPrice) /
            (pool.tvl * 10 ** decimal);

        (, uint256 reserveLiquidationThreshold, , , ) = baseData.configuration.getParamsMemory();

        if (vdTokenBal != 0)
            lendingInfo.healthFactor = (reserveLiquidationThreshold * rTokenBal) / vdTokenBal;

        (lendingInfo.RDNTpersec, lendingInfo.RDNTAPR) = this.getRDNTAPR(pool);
        (lendingInfo.RDNTDepositRate, lendingInfo.RDNTDBorrowRate) = this.getRDNTRate(pool);
        lendingInfo.RDNTAPR = (_RDNTrevShare * lendingInfo.RDNTAPR) / DENOMINATOR;
        lendingInfo.RDNTDepositRate = (_RDNTrevShare * lendingInfo.RDNTDepositRate) / DENOMINATOR;
        lendingInfo.RDNTDBorrowRate = (_RDNTrevShare * lendingInfo.RDNTDBorrowRate) / DENOMINATOR;

        return lendingInfo;
    }

    function getRadpieRDNTInfo(address account) public view returns (RadpieRDNTInfo memory) {
        RadpieRDNTInfo memory radpieRDNTInfo;
        (
            ,
            radpieRDNTInfo.lockedDLPUSD,
            radpieRDNTInfo.totalCollateralUSD,
            radpieRDNTInfo.requiredDLPUSD,

        ) = rewardDistributor.rdntRewardEligibility();
        radpieRDNTInfo.lastHarvestTime = radpieStaking.lastSeenClaimableTime();
        radpieRDNTInfo.nextStartVestTime = rdntRewardManager.nextVestingTime();
        radpieRDNTInfo.totalEarnedRDNT = radpieStaking.totalEarnedRDNT();

        address[] memory tokens = new address[](0);
        (radpieRDNTInfo.systemVestable, , , ) = rewardDistributor.claimableAndPendingRDNT(tokens);

        (
            radpieRDNTInfo.systemVesting,
            radpieRDNTInfo.systemVested,
            radpieRDNTInfo.vestingInfos
        ) = radiantMFD.earnedBalances(address(radpieStaking));

        if (account != address(0)) {
            (
                radpieRDNTInfo.userVestingSchedules,
                ,
                radpieRDNTInfo.userVestedRDNT,
                radpieRDNTInfo.userVestingRDNT
            ) = rdntVestManager.getAllVestingInfo(account);
        }

        return radpieRDNTInfo;
    }

     function getRadpieEsRDNTInfo(address account) public view returns (RadpieEsRDNTInfo memory) {
        RadpieEsRDNTInfo memory radpieEsRDNTInfo;
        radpieEsRDNTInfo.tokenAddress = rdntRewardManager.esRDNT();
        radpieEsRDNTInfo.balance = ERC20(radpieEsRDNTInfo.tokenAddress).balanceOf(account);
        radpieEsRDNTInfo.vestAllowance = ERC20(radpieEsRDNTInfo.tokenAddress).allowance(account, address(rdntRewardManager));
        return radpieEsRDNTInfo;
    }

    

    function getRadpieLegacyRewardInfo(
        address stakingToken,
        address account
    ) public view returns (RadpieLegacyRewardInfo memory) {
        RadpieLegacyRewardInfo memory rewardInfo;
        address rewarderAddress = masterRadpie.legacyRewarders(stakingToken);
        if (rewarderAddress != address(0) && !masterRadpie.legacyRewarderClaimed(stakingToken, account)) {
            IBaseRewardPoolV3 rewarder = IBaseRewardPoolV3(rewarderAddress);
            (rewardInfo.bonusTokenAddresses, rewardInfo.bonusTokenSymbols) = rewarder.rewardTokenInfos();
            (rewardInfo.pendingBonusRewards) = rewarder.allEarned(account);
        }
        return rewardInfo;
    }

    function getRDNTAPR(RadpiePool memory pool) external view returns (uint256, uint256) {
        uint256 RDNTPrice = this.getRDNTPrice();
        uint256 rdntPerSecToRadpie = _rdntEmission(pool);

        return (rdntPerSecToRadpie, _anualize(rdntPerSecToRadpie, RDNTPrice, 18, pool.tvl));
    }

    function getRDNTRate(RadpiePool memory pool) external view returns(uint256, uint256) {
        uint256 RDNTPrice = this.getRDNTPrice();
        (uint256 rdntDRate, uint256 liquidity) = _RDNTLiquidRate(pool);
        (uint256 rdntBRate, uint256 debt) = _RDNTBorrowRate(pool);

        return (
            _anualize(rdntDRate, RDNTPrice, 18, liquidity),
            _anualize(rdntBRate, RDNTPrice, 18, debt)
        );
    }

    function getRDNTPrice() external view returns (uint256) {
        return uint256(RDNTOracle.latestAnswer());
    }

    function getDlpPrice() external view returns (uint256) {
        address priceProvider = IMultiFeeDistribution(radiantMFD).getPriceProvider();
        return IPriceProvider(priceProvider).getLpTokenPriceUsd();
    }

    /* ============ Admin functions ============ */

    function init(
        address _mDLP,
        address _RDNT,
        address _WETH,
        address _RDNT_LP,
        address _masterRadpie,
        address _radpieStaking
    ) external onlyOwner {
        mDLP = _mDLP;
        RDNT = _RDNT;
        WETH = _WETH;
        RDNT_LP = _RDNT_LP;
        masterRadpie = IMasterRadpieReader(_masterRadpie);
        radpieStaking = IRadpieStakingReader(_radpieStaking);
    }

    function config(
        address _rdntRewardManager,
        address _rewardDistributor,
        address _radiantMFD,
        address _lendingPool,
        address _RDNTOracle,
        address _chefIncentives
    ) external onlyOwner {
        rdntRewardManager = IRDNTRewardManagerReader(_rdntRewardManager);
        rewardDistributor  =IRewardDistributor(_rewardDistributor);
        radiantMFD = IMultiFeeDistribution(_radiantMFD);
        lendingPool = ILendingPool(_lendingPool);
        rdntVestManager = IRDNTVestManagerReader(radpieStaking.rdntVestManager());
        RDNTOracle = AggregatorV3Interface(_RDNTOracle);
        chefIncentives = IChefIncentivesController(_chefIncentives);
    }

    function addRDNTrevShare(uint256 value) external onlyOwner {
        RDNTrevShare.push(value);
    }

    function RDNTrevShareLength() external view returns (uint256) {
        return RDNTrevShare.length;
    }

    function updateRDNTrevShare(uint256 _index, uint256 _value) external onlyOwner {
        RDNTrevShare[_index] = _value;
    }

    /* ============ Internal functions ============ */

    function _updateBasedOnRevShare(RadpieInfo memory info) internal view {
        uint256 rdntPerSec = info.systemRDNTInfo.totalRDNTpersec;
        uint256 rdntPerSecToMDlp = (rdntPerSec * RDNTrevShare[1]) / DENOMINATOR;
        uint256 RDNTPrice = this.getRDNTPrice();

        // mDLP
        info.pools[0].radpieLendingInfo.RDNTAPR = _anualize(
            rdntPerSecToMDlp,
            RDNTPrice,
            18,
            info.pools[0].tvl
        );
    }

    function _rdntEmission(RadpiePool memory pool) internal view returns (uint256) {
        uint256 rdntRate = chefIncentives.rewardsPerSecond();
        uint256 totalAllocPoint = chefIncentives.totalAllocPoint();

        uint256 rTokenBal = IERC20(pool.rToken).balanceOf(address(radpieStaking));
        uint256 vdTokenBal = IERC20(pool.vdToken).balanceOf(address(radpieStaking));

        (uint256 rTotalSup, uint256 rAllocpoint, , , ) = chefIncentives.poolInfo(pool.rToken);
        (uint256 vdTotalSup, uint256 vdAllocpoint, , , ) = chefIncentives.poolInfo(pool.vdToken);

        uint256 emitForRToken = (rAllocpoint * rdntRate * rTokenBal) /
            (totalAllocPoint * rTotalSup);
        uint256 emitForVdToken = (vdAllocpoint * rdntRate * vdTokenBal) /
            (totalAllocPoint * vdTotalSup);

        return emitForRToken + emitForVdToken;
    }

    function _RDNTLiquidRate(RadpiePool memory pool) internal view returns(uint256, uint256) {
        uint256 rdntRate = chefIncentives.rewardsPerSecond();
        uint256 totalAllocPoint = chefIncentives.totalAllocPoint();    

        (uint256 rTotalSup, uint256 rAllocpoint, , , ) = chefIncentives.poolInfo(pool.rToken);

        uint256 RDNTDepositRate = (rAllocpoint * rdntRate / totalAllocPoint);
        uint256 offset = 10 ** pool.stakedTokenInfo.decimals;

        return (RDNTDepositRate, (rTotalSup * pool.assetPrice) / offset);
    }

    function _RDNTBorrowRate(RadpiePool memory pool) internal view returns(uint256, uint256) {
        uint256 rdntRate = chefIncentives.rewardsPerSecond();
        uint256 totalAllocPoint = chefIncentives.totalAllocPoint();    

        (uint256 vdTotalSup, uint256 vdAllocpoint, , , ) = chefIncentives.poolInfo(pool.vdToken);

        uint256 RDNTDebtRate = (vdAllocpoint * rdntRate / totalAllocPoint);
        uint256 offset = 10 ** pool.stakedTokenInfo.decimals;

        return (RDNTDebtRate, (vdTotalSup * pool.assetPrice) / offset);
    }

    function _anualize(
        uint256 _rewardPerSec,
        uint256 _rewardPrice,
        uint256 rewardDecimal,
        uint256 _assetTVL
    ) internal pure returns (uint256) {
        return
            (DENOMINATOR * _rewardPerSec * 86400 * 365 * _rewardPrice) /
            (_assetTVL * 10 ** rewardDecimal);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/radiant/LockedBalance.sol";
import "./interfaces/radpieReader/IRDNTVestManagerReader.sol";


interface ReaderDatatype {

    struct RadpieInfo {
        address masterRadpie;
        address radpieStaking;
        address rdntRewardManager;
        address rdntVestManager;
        address vlRDP;
        address radpieOFT;
        address RDNT;
        address WETH;
        address RDNT_LP;  
        address mDLP;
        uint256 minHealthFactor;
        uint256 systemHealthFactor;
        RadpieRDNTInfo systemRDNTInfo;
        RadpieEsRDNTInfo esRDNTInfo;
        RadpiePool[] pools;
    }    

    struct RadpieRDNTInfo {
        uint256 lockedDLPUSD;
        uint256 requiredDLPUSD;
        uint256 totalCollateralUSD;
        uint256 nextStartVestTime;
        uint256 lastHarvestTime;
        uint256 totalEarnedRDNT;
        uint256 systemVestable;
        uint256 systemVested;
        uint256 systemVesting;
        uint256 totalRDNTpersec;
        EarnedBalance[] vestingInfos;

        uint256 userVestedRDNT;
        uint256 userVestingRDNT;
        VestingSchedule[] userVestingSchedules;
    }

    struct RadpieEsRDNTInfo {
        address tokenAddress;
        uint256 balance;
        uint256 vestAllowance;
    }
    
    // by pools
    struct RadpiePool {
        uint256 poolId;
        uint256 sizeOfPool;
        uint256 tvl;
        uint256 debt;
        uint256 leveragedTVL;
        address stakingToken; // Address of staking token contract to be staked.
        address receiptToken; // Address of receipt token contract represent a staking position
        address asset;
        address rToken;
        address vdToken;
        address rewarder;
        address helper;
        bool    isActive;
        bool    isNative;
        string  poolType;
        uint256 assetPrice;
        uint256 maxCap;
        uint256 quotaLeft;
        RadpieLendingInfo radpieLendingInfo;
        ERC20TokenInfo stakedTokenInfo;
        RadpieAccountInfo  accountInfo;
        RadpieRewardInfo rewardInfo;
        RadpieLegacyRewardInfo legacyRewardInfo;
    }

    struct RadpieAccountInfo {
        uint256 balance;
        uint256 stakedAmount;  // receipttoken
        uint256 stakingAllowance; // asset allowance
        uint256 availableAmount; // current stake amount
        uint256 mDLPAllowance;
        uint256 lockRDPAllowance;
        uint256 rdntBalance;
        uint256 rdntDlpBalance;
        uint256 tvl;
    }

    struct RadpieRewardInfo {
        uint256 pendingRDP;
        address[]  bonusTokenAddresses;
        string[]  bonusTokenSymbols;
        uint256[]  pendingBonusRewards;
        uint256 entitledRDNT;
    }

    struct RadpieLendingInfo {
        uint256 healthFactor;
        uint256 depositRate;
        uint256 borrowRate;
        uint256 RDNTDepositRate;
        uint256 RDNTDBorrowRate;
        uint256 depositAPR;
        uint256 borrowAPR;
        uint256 RDNTAPR;
        uint256 RDNTpersec;
    }        

    struct RadpieLegacyRewardInfo {
        uint256[]  pendingBonusRewards;
        address[]  bonusTokenAddresses;
        string[] bonusTokenSymbols;
    }

    struct ERC20TokenInfo {
        address tokenAddress;
        string symbol;
        uint256 decimals;
    }
}