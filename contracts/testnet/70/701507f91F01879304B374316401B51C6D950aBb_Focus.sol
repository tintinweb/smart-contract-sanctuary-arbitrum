// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
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
        return _paused;
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
        _paused = true;
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
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../lib/FloatingPointConstants.sol";
import "../Utils/Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "../Utils/EpochConfigurable.sol";
import "./IFocus.sol";

struct FocusStorage {
  uint64 lastActivityTimestamp;
  int64 currentFocusValue;
  int64 focusCounter;
}

uint constant FOCUS_LINEAR = 0;
uint constant FOCUS_SIGMOID = 1;

struct FocusConfig {
  // Max total focus (100%)
  int64 maxFocus;
  // 0 - linear, 1 - gas-effective sigmoid
  uint32 focusCalcType;
  // Number of days - min/max. lower/upper bounds for linear or soft caps point for sigmoid
  // mid is the middle point for sigmoid, range length for linear
  int32 counterCurveRangeMax;
  int32 counterCurveRangeMin;
  int32 counterMidRange;
  // Daily focus gain range, base focus is the point in the middle
  int32 minFocusGain;
  int32 baseFocusGain;
  int32 maxFocusGain;
  // Sigmoid params
  int32 focusOffset;
  int32 upperCurveMultiplier;
  int32 upperCurveAdjuster;
  int32 lowerCurveMultiplier;
  int32 lowerCurveAdjuster;
}

contract Focus is IFocus, Pausable, EpochConfigurable {
  // adventurer address => adventurer id => remaining focus
  mapping(address => mapping(uint => FocusStorage)) public STORAGE;

  FocusConfig public CONFIG;

  constructor(address _manager) EpochConfigurable(_manager, 24 hours, 0) {
    CONFIG.maxFocus = 100_000;

    CONFIG.minFocusGain = 1_000;
    CONFIG.maxFocusGain = 10_000;
    CONFIG.baseFocusGain = CONFIG.maxFocusGain - CONFIG.minFocusGain;
    CONFIG.counterCurveRangeMax = 20;
    CONFIG.counterMidRange = 20;
    CONFIG.counterCurveRangeMin = 40;
    CONFIG.focusCalcType = 0;
  }

  event FocusNotChanged(address _adventurerAddress, uint _adventurerId, int focus);
  event FocusChanged(address _adventurerAddress, uint _adventurerId, int newFocus);

  function currentFocus(
    address _adventurerAddress,
    uint _adventurerId
  ) external view returns (int) {
    return _currentFocus(_adventurerAddress, _adventurerId);
  }

  function currentCounter(
    address _adventurerAddress,
    uint _adventurerId
  ) external view returns (int) {
    return _currentCounter(_adventurerAddress, _adventurerId);
  }

  function currentFocusBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external view returns (int[] memory result) {
    result = new int[](_adventurerAddresses.length);
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      result[i] = _currentFocus(_adventurerAddresses[i], _adventurerIds[i]);
    }
  }

  function currentCounterBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external view returns (int[] memory result) {
    result = new int[](_adventurerAddresses.length);
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      result[i] = _currentCounter(_adventurerAddresses[i], _adventurerIds[i]);
    }
  }

  function calculateNextFocusGain(
    address _adventurerAddress,
    uint _adventurerId
  ) public view returns (int) {
    int64 counter = STORAGE[_adventurerAddress][_adventurerId].focusCounter;
    return int(_calculateFocusGain(counter, CONFIG));
  }

  function calculateNextFocusGainBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) public view returns (int[] memory result) {
    result = new int[](_adventurerAddresses.length);
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      int64 counter = STORAGE[_adventurerAddresses[i]][_adventurerIds[i]].focusCounter;
      result[i] = int(_calculateFocusGain(counter, CONFIG));
    }
  }

  function isFocusedThisEpoch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external view returns (bool[] memory result) {
    uint currentEpoch = currentEpoch();
    result = new bool[](_adventurerAddresses.length);
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      result[i] = (epochAtTimestamp(
        uint(STORAGE[_adventurerAddresses[i]][_adventurerIds[i]].lastActivityTimestamp)
      ) >= currentEpoch);
    }
  }

  function setCounterBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _newValues
  ) external onlyManager {
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      STORAGE[_adventurerAddresses[i]][_adventurerIds[i]].focusCounter = int64(_newValues[i]);
    }
  }

  function setCounterBatchSingleValue(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int64 _newValue
  ) external onlyManager {
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      STORAGE[_adventurerAddresses[i]][_adventurerIds[i]].focusCounter = _newValue;
    }
  }

  function addToCounterBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _addValues
  ) external onlyManager {
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      STORAGE[_adventurerAddresses[i]][_adventurerIds[i]].focusCounter += int64(_addValues[i]);
    }
  }

  function addToCounterBatchSingleValue(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int64 _addValue
  ) external onlyManager {
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      STORAGE[_adventurerAddresses[i]][_adventurerIds[i]].focusCounter += _addValue;
    }
  }

  function markFocusedBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external onlyManager {
    FocusConfig memory cfg = CONFIG;
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      _markFocused(_adventurerAddresses[i], _adventurerIds[i], cfg);
    }
  }

  function markFocused(address _adventurerAddress, uint _adventurerId) external onlyManager {
    _markFocused(_adventurerAddress, _adventurerId, CONFIG);
  }

  function spendFocus(
    address _adventurerAddress,
    uint _adventurerId,
    int _spentFocus
  ) external onlyManager {
    _spendFocus(_adventurerAddress, _adventurerId, int64(_spentFocus));
  }

  function spendFocusBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _spendings
  ) external onlyManager {
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      _spendFocus(_adventurerAddresses[i], _adventurerIds[i], int64(_spendings[i]));
    }
  }

  function _spendFocus(address _adventurerAddress, uint _adventurerId, int64 _spentFocus) internal {
    if (_spentFocus == 0) {
      return;
    }
    FocusStorage storage focusStorage = STORAGE[_adventurerAddress][_adventurerId];
    FocusStorage memory focusMem = focusStorage;
    if (focusMem.currentFocusValue < _spentFocus) {
      revert InsufficientFocus(
        _adventurerAddress,
        _adventurerId,
        _spentFocus,
        focusMem.currentFocusValue
      );
    }

    focusMem.currentFocusValue = focusMem.currentFocusValue - _spentFocus;
    focusStorage.currentFocusValue = focusMem.currentFocusValue;
    emit FocusChanged(_adventurerAddress, _adventurerId, focusMem.currentFocusValue);
  }

  function _currentFocus(
    address _adventurerAddress,
    uint _adventurerId
  ) internal view returns (int) {
    return int(STORAGE[_adventurerAddress][_adventurerId].currentFocusValue);
  }

  function _currentCounter(
    address _adventurerAddress,
    uint _adventurerId
  ) internal view returns (int) {
    return int(STORAGE[_adventurerAddress][_adventurerId].focusCounter);
  }

  function _markFocused(
    address _adventurerAddress,
    uint _adventurerId,
    FocusConfig memory config
  ) internal {
    FocusStorage storage focusStorage = STORAGE[_adventurerAddress][_adventurerId];
    FocusStorage memory focusMem = focusStorage;
    uint lastActivityEpoch = epochAtTimestamp(uint(focusMem.lastActivityTimestamp));
    if (lastActivityEpoch >= currentEpoch()) {
      return;
    }

    focusStorage.lastActivityTimestamp = uint64(block.timestamp);
    if (focusMem.currentFocusValue >= config.maxFocus) {
      emit FocusNotChanged(_adventurerAddress, _adventurerId, focusMem.currentFocusValue);
      return;
    }

    focusMem.focusCounter++;
    focusStorage.focusCounter = focusMem.focusCounter;
    focusMem.currentFocusValue += _calculateFocusGain(focusMem.focusCounter, config);
    if (focusMem.currentFocusValue > config.maxFocus) {
      focusMem.currentFocusValue = config.maxFocus;
    }
    focusStorage.currentFocusValue = focusMem.currentFocusValue;
    emit FocusChanged(_adventurerAddress, _adventurerId, focusMem.currentFocusValue);
  }

  function _calculateFocusGain(
    int64 counter,
    FocusConfig memory config
  ) internal pure returns (int64) {
    if (config.focusCalcType == FOCUS_SIGMOID) {
      return int64(_calculateSigmoidGain(int(counter), config));
    } else {
      return int64(_calculateLinearGain(int(counter), config));
    }
  }

  /**
   * @dev Calculates the linear gain based on the given counter and configuration.
   *
   * The function behaves as follows:
   * 1. If the counter is less than the minimum curve range specified in the configuration, it returns the maximum focus gain.
   * 2. If the counter is more than the maximum curve range specified in the configuration, it returns the minimum focus gain.
   * 3. If the counter is between the min and max curve range, it calculates the percentage difference from the mid-range. This percentage is then used to calculate and return a proportional gain between the minimum and base focus gain.
   *
   * @param counter the counter value which could represent the progression or level of some process.
   * @param config the FocusConfig memory structure that contains various parameters used for the calculation.
   * @return the calculated linear gain as a uint
   */
  function _calculateLinearGain(
    int counter,
    FocusConfig memory config
  ) internal pure returns (int) {
    if (counter <= config.counterCurveRangeMax) {
      return int(config.maxFocusGain);
    } else if (counter >= config.counterCurveRangeMin) {
      return int(config.minFocusGain);
    } else {
      int percentage = SIGNED_ONE_HUNDRED -
        (((counter - int(config.counterCurveRangeMax)) * SIGNED_ONE_HUNDRED) /
          int(config.counterMidRange));
      return
        ((int(config.baseFocusGain) * percentage) / SIGNED_ONE_HUNDRED) + int(config.minFocusGain);
    }
  }

  error A(int a, int c, int x);

  /**
   * function _calculateSigmoidGain(uint counter, FocusConfig memory config) internal returns (uint)
   * @dev Calculates the linear gain based on the given counter and configuration.
   * As counter increases the focus gain decreases according to a sigmoid-like function
   * We're not using a true sigmoid due to gas efficiency
   * counterMidRange - point of the curve where you get exactly "baseAnimaGain"
   * counterCurveRangeMin - the minimum counter range where you start getting diminishing returns from "maxAnimaGain" up to the mid range point
   * counterCurveRangeMax - the maximum counter range where diminishing returns eventually reach "minAnimaGain" at this point (from mid point)
   * It's a piecewise function that is using (counter - counterMidRange) as x:
   * First we calculate the focusMultiplier:
   * focusMultiplier for x below or equal mid point we're using 1-(config.counterCurveRangeMin/(config.counterCurveRangeMin-x*config.upperCurveAdjuster)-1)*config.upperCurveMultiplier
   * focusMultiplier for x above mid point we're using 1+config.counterCurveRangeMax/(config.counterCurveRangeMax+x*config.lowerCurveAdjuster)-1)*config.lowerCurveMultiplier
   * based on the focusMultiplier we calculate the focus gain:
   * result = focusMultiplier*config.baseFocusGain+config.focusOffset
   * then we cap the result between config.minFocusGain and config.maxFocusGain
   */

  function _calculateSigmoidGain(
    int counter,
    FocusConfig memory config
  ) internal pure returns (int) {
    int x = counter - int(config.counterMidRange);
    int focusMultiplier;

    if (x <= 0) {
      focusMultiplier =
        SIGNED_ONE_HUNDRED -
        (((config.counterCurveRangeMax * SIGNED_ONE_HUNDRED_SQUARE) /
          (SIGNED_ONE_HUNDRED * config.counterCurveRangeMax - (x * config.upperCurveAdjuster)) -
          SIGNED_ONE_HUNDRED) * config.upperCurveMultiplier) /
        SIGNED_ONE_HUNDRED;
    } else {
      focusMultiplier =
        SIGNED_ONE_HUNDRED +
        (((int(config.counterCurveRangeMin) * SIGNED_ONE_HUNDRED_SQUARE) /
          (int(config.counterCurveRangeMin) *
            SIGNED_ONE_HUNDRED +
            (x * config.lowerCurveAdjuster)) -
          SIGNED_ONE_HUNDRED) * config.lowerCurveMultiplier) /
        SIGNED_ONE_HUNDRED;
    }

    // Calculate focus gain based on focusMultiplier
    int result = ((focusMultiplier * int(config.baseFocusGain)) / SIGNED_ONE_HUNDRED) +
      int(config.focusOffset);
    // Cap the result between config.minFocusGain and config.maxFocusGain
    if (result < int(config.minFocusGain)) {
      return int(config.minFocusGain);
    } else if (result > int(config.maxFocusGain)) {
      return int(config.maxFocusGain);
    } else {
      return result;
    }
  }

  function updateFocusConfig(FocusConfig calldata _config) external onlyAdmin {
    CONFIG = _config;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

interface IFocus is IEpochConfigurable {
  error InsufficientFocus(
    address adventurerAddress,
    uint adventurerId,
    int64 spentFocus,
    int64 currentFocus
  );

  function currentFocus(address _adventurerAddress, uint _adventurerId) external view returns (int);

  function currentFocusBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external view returns (int[] memory result);

  function isFocusedThisEpoch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external view returns (bool[] memory result);

  function setCounterBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _newValues
  ) external;

  function setCounterBatchSingleValue(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int64 _newValue
  ) external;

  function addToCounterBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _addValues
  ) external;

  function addToCounterBatchSingleValue(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int64 _addValue
  ) external;

  function markFocusedBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external;

  function spendFocusBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _spendings
  ) external;
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "../lib/FloatingPointConstants.sol";

uint256 constant MASK_128 = ((1 << 128) - 1);
uint128 constant MASK_64 = ((1 << 64) - 1);

library Epoch {
  // Converts a given timestamp to an epoch using the specified duration and offset.
  // Example for battle timers resetting at noon UTC is: _duration = 1 days; _offset = 12 hours;
  function toEpochNumber(
    uint256 _timestamp,
    uint256 _duration,
    uint256 _offset
  ) internal pure returns (uint256) {
    return (_timestamp + _offset) / _duration;
  }

  // Here we assume that _config is a packed _duration (left 64 bits) and _offset (right 64 bits)
  function toEpochNumber(uint256 _timestamp, uint128 _config) internal pure returns (uint256) {
    return (_timestamp + (_config & MASK_64)) / ((_config >> 64) & MASK_64);
  }

  // Returns a value between 0 and ONE_HUNDRED which is the percentage of "completeness" of the epoch
  // result variable is reused for memory efficiency
  function toEpochCompleteness(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = (_config >> 64) & MASK_64;
    result = (ONE_HUNDRED * ((_timestamp + (_config & MASK_64)) % result)) / result;
  }

  // Create a config for the function above
  function toConfig(uint64 _duration, uint64 _offset) internal pure returns (uint128) {
    return (uint128(_duration) << 64) | uint128(_offset);
  }

  // Pack the epoch number with the config into a single uint256 for mappings
  function packEpoch(uint256 _epochNumber, uint128 _config) internal pure returns (uint256) {
    return (uint256(_config) << 128) | uint128(_epochNumber);
  }

  // Convert timestamp to Epoch and pack it with the config into a single uint256 for mappings
  function packTimestampToEpoch(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256) {
    return packEpoch(toEpochNumber(_timestamp, _config), _config);
  }

  // Unpack packedEpoch to epochNumber and config
  function unpack(
    uint256 _packedEpoch
  ) internal pure returns (uint256 epochNumber, uint128 config) {
    config = uint128(_packedEpoch >> 128);
    epochNumber = _packedEpoch & MASK_128;
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "./IEpochConfigurable.sol";

contract EpochConfigurable is ManagerModifier, IEpochConfigurable {
  uint128 public EPOCH_CONFIG;

  constructor(
    address _manager,
    uint64 _epochDuration,
    uint64 _epochOffset
  ) ManagerModifier(_manager) {
    EPOCH_CONFIG = Epoch.toConfig(_epochDuration, _epochOffset);
  }

  function currentEpoch() public view returns (uint) {
    return epochAtTimestamp(block.timestamp);
  }

  function epochAtTimestamp(uint _timestamp) public view returns (uint) {
    return Epoch.toEpochNumber(_timestamp, EPOCH_CONFIG);
  }

  function updateEpochConfig(uint64 duration, uint64 offset) external onlyAdmin {
    EPOCH_CONFIG = Epoch.toConfig(duration, offset);
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}