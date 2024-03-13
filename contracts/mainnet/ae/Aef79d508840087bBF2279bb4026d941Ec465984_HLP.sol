// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './LendingRewards.sol';

contract HLP is ERC20 {
  address public lendingPool;
  LendingRewards public lendingRewards;

  modifier onlyLendingPool() {
    require(_msgSender() == lendingPool, 'UNAUTHORIZED');
    _;
  }

  constructor() ERC20('HYPE LP', 'HLP') {
    lendingPool = _msgSender();
    lendingRewards = new LendingRewards(address(this));
  }

  function mint(address _wallet, uint256 _amount) external onlyLendingPool {
    _mint(_wallet, _amount);
  }

  function burn(address _wallet, uint256 _amount) external onlyLendingPool {
    _burn(_wallet, _amount);
  }

  function _canReceiveRewards(address _wallet) internal pure returns (bool) {
    return _wallet != address(0);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual override {
    if (_canReceiveRewards(_from)) {
      lendingRewards.setShare(_from, _amount, true);
    }
    if (_canReceiveRewards(_to)) {
      lendingRewards.setShare(_to, _amount, false);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRewardsTracker {
  function claimReward() external;

  function depositRewards() external payable;

  function getShares(address wallet) external view returns (uint256);

  function setShare(
    address shareholder,
    uint256 balanceUpdate,
    bool isRemoving
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './RewardsTracker.sol';

contract LendingRewards is RewardsTracker {
  constructor(address _token) RewardsTracker(_token) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
  uint constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint constant SECONDS_PER_HOUR = 60 * 60;
  uint constant SECONDS_PER_MINUTE = 60;
  int constant OFFSET19700101 = 2440588;

  uint constant DOW_MON = 1;
  uint constant DOW_TUE = 2;
  uint constant DOW_WED = 3;
  uint constant DOW_THU = 4;
  uint constant DOW_FRI = 5;
  uint constant DOW_SAT = 6;
  uint constant DOW_SUN = 7;

  // ------------------------------------------------------------------------
  // Calculate the number of days from 1970/01/01 to year/month/day using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and subtracting the offset 2440588 so that 1970/01/01 is day 0
  //
  // days = day
  //      - 32075
  //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
  //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
  //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
  //      - offset
  // ------------------------------------------------------------------------
  function _daysFromDate(
    uint year,
    uint month,
    uint day
  ) internal pure returns (uint _days) {
    require(year >= 1970);
    int _year = int(year);
    int _month = int(month);
    int _day = int(day);

    int __days = _day -
      32075 +
      (1461 * (_year + 4800 + (_month - 14) / 12)) /
      4 +
      (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
      12 -
      (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
      4 -
      OFFSET19700101;

    _days = uint(__days);
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(
    uint _days
  ) internal pure returns (uint year, uint month, uint day) {
    int __days = int(_days);

    int L = __days + 68569 + OFFSET19700101;
    int N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int _month = (80 * L) / 2447;
    int _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint(_year);
    month = uint(_month);
    day = uint(_day);
  }

  function timestampFromDate(
    uint year,
    uint month,
    uint day
  ) internal pure returns (uint timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }

  function timestampFromDateTime(
    uint year,
    uint month,
    uint day,
    uint hour,
    uint minute,
    uint second
  ) internal pure returns (uint timestamp) {
    timestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      hour *
      SECONDS_PER_HOUR +
      minute *
      SECONDS_PER_MINUTE +
      second;
  }

  function timestampToDate(
    uint timestamp
  ) internal pure returns (uint year, uint month, uint day) {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function timestampToDateTime(
    uint timestamp
  )
    internal
    pure
    returns (
      uint year,
      uint month,
      uint day,
      uint hour,
      uint minute,
      uint second
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
    secs = secs % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
    second = secs % SECONDS_PER_MINUTE;
  }

  function isValidDate(
    uint year,
    uint month,
    uint day
  ) internal pure returns (bool valid) {
    if (year >= 1970 && month > 0 && month <= 12) {
      uint daysInMonth = _getDaysInMonth(year, month);
      if (day > 0 && day <= daysInMonth) {
        valid = true;
      }
    }
  }

  function isValidDateTime(
    uint year,
    uint month,
    uint day,
    uint hour,
    uint minute,
    uint second
  ) internal pure returns (bool valid) {
    if (isValidDate(year, month, day)) {
      if (hour < 24 && minute < 60 && second < 60) {
        valid = true;
      }
    }
  }

  function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
    uint year;
    uint month;
    uint day;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    leapYear = _isLeapYear(year);
  }

  function _isLeapYear(uint year) internal pure returns (bool leapYear) {
    leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
  }

  function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
    weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
  }

  function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
    weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
  }

  function getDaysInMonth(
    uint timestamp
  ) internal pure returns (uint daysInMonth) {
    uint year;
    uint month;
    uint day;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    daysInMonth = _getDaysInMonth(year, month);
  }

  function _getDaysInMonth(
    uint year,
    uint month
  ) internal pure returns (uint daysInMonth) {
    if (
      month == 1 ||
      month == 3 ||
      month == 5 ||
      month == 7 ||
      month == 8 ||
      month == 10 ||
      month == 12
    ) {
      daysInMonth = 31;
    } else if (month != 2) {
      daysInMonth = 30;
    } else {
      daysInMonth = _isLeapYear(year) ? 29 : 28;
    }
  }

  // 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
    uint _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + 3) % 7) + 1;
  }

  function getYear(uint timestamp) internal pure returns (uint year) {
    uint month;
    uint day;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getMonth(uint timestamp) internal pure returns (uint month) {
    uint year;
    uint day;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getDay(uint timestamp) internal pure returns (uint day) {
    uint year;
    uint month;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getHour(uint timestamp) internal pure returns (uint hour) {
    uint secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
  }

  function getMinute(uint timestamp) internal pure returns (uint minute) {
    uint secs = timestamp % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
  }

  function getSecond(uint timestamp) internal pure returns (uint second) {
    second = timestamp % SECONDS_PER_MINUTE;
  }

  function addYears(
    uint timestamp,
    uint _years
  ) internal pure returns (uint newTimestamp) {
    uint year;
    uint month;
    uint day;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year += _years;
    uint daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addMonths(
    uint timestamp,
    uint _months
  ) internal pure returns (uint newTimestamp) {
    uint year;
    uint month;
    uint day;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    month += _months;
    year += (month - 1) / 12;
    month = ((month - 1) % 12) + 1;
    uint daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addDays(
    uint timestamp,
    uint _days
  ) internal pure returns (uint newTimestamp) {
    newTimestamp = timestamp + _days * SECONDS_PER_DAY;
    require(newTimestamp >= timestamp);
  }

  function addHours(
    uint timestamp,
    uint _hours
  ) internal pure returns (uint newTimestamp) {
    newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
    require(newTimestamp >= timestamp);
  }

  function addMinutes(
    uint timestamp,
    uint _minutes
  ) internal pure returns (uint newTimestamp) {
    newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp >= timestamp);
  }

  function addSeconds(
    uint timestamp,
    uint _seconds
  ) internal pure returns (uint newTimestamp) {
    newTimestamp = timestamp + _seconds;
    require(newTimestamp >= timestamp);
  }

  function subYears(
    uint timestamp,
    uint _years
  ) internal pure returns (uint newTimestamp) {
    uint year;
    uint month;
    uint day;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year -= _years;
    uint daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subMonths(
    uint timestamp,
    uint _months
  ) internal pure returns (uint newTimestamp) {
    uint year;
    uint month;
    uint day;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint yearMonth = year * 12 + (month - 1) - _months;
    year = yearMonth / 12;
    month = (yearMonth % 12) + 1;
    uint daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subDays(
    uint timestamp,
    uint _days
  ) internal pure returns (uint newTimestamp) {
    newTimestamp = timestamp - _days * SECONDS_PER_DAY;
    require(newTimestamp <= timestamp);
  }

  function subHours(
    uint timestamp,
    uint _hours
  ) internal pure returns (uint newTimestamp) {
    newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
    require(newTimestamp <= timestamp);
  }

  function subMinutes(
    uint timestamp,
    uint _minutes
  ) internal pure returns (uint newTimestamp) {
    newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp <= timestamp);
  }

  function subSeconds(
    uint timestamp,
    uint _seconds
  ) internal pure returns (uint newTimestamp) {
    newTimestamp = timestamp - _seconds;
    require(newTimestamp <= timestamp);
  }

  function diffYears(
    uint fromTimestamp,
    uint toTimestamp
  ) internal pure returns (uint _years) {
    require(fromTimestamp <= toTimestamp);
    uint fromYear;
    uint fromMonth;
    uint fromDay;
    uint toYear;
    uint toMonth;
    uint toDay;
    (fromYear, fromMonth, fromDay) = _daysToDate(
      fromTimestamp / SECONDS_PER_DAY
    );
    (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _years = toYear - fromYear;
  }

  function diffMonths(
    uint fromTimestamp,
    uint toTimestamp
  ) internal pure returns (uint _months) {
    require(fromTimestamp <= toTimestamp);
    uint fromYear;
    uint fromMonth;
    uint fromDay;
    uint toYear;
    uint toMonth;
    uint toDay;
    (fromYear, fromMonth, fromDay) = _daysToDate(
      fromTimestamp / SECONDS_PER_DAY
    );
    (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
  }

  function diffDays(
    uint fromTimestamp,
    uint toTimestamp
  ) internal pure returns (uint _days) {
    require(fromTimestamp <= toTimestamp);
    _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
  }

  function diffHours(
    uint fromTimestamp,
    uint toTimestamp
  ) internal pure returns (uint _hours) {
    require(fromTimestamp <= toTimestamp);
    _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
  }

  function diffMinutes(
    uint fromTimestamp,
    uint toTimestamp
  ) internal pure returns (uint _minutes) {
    require(fromTimestamp <= toTimestamp);
    _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
  }

  function diffSeconds(
    uint fromTimestamp,
    uint toTimestamp
  ) internal pure returns (uint _seconds) {
    require(fromTimestamp <= toTimestamp);
    _seconds = toTimestamp - fromTimestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './interfaces/IRewardsTracker.sol';
import './libraries/BokkyPooBahsDateTimeLibrary.sol';

contract RewardsTracker is IRewardsTracker {
  uint256 constant MULTIPLIER = 10 ** 36;
  address public token;
  uint256 public totalStakedUsers;
  uint256 public totalSharesDeposited;

  struct Share {
    uint256 amount;
    uint256 stakedTime;
  }
  struct Reward {
    uint256 totalExcluded;
    uint256 totalRealized;
  }
  mapping(address => Share) private shares;
  mapping(address => Reward) public rewards;

  uint256 public rewardsPerShare;
  uint256 public totalDistributed;
  uint256 public totalRewards;
  mapping(uint256 => uint256) public monthlyRewards;

  event AddShares(address indexed user, uint256 amount);
  event RemoveShares(address indexed user, uint256 amount);
  event ClaimReward(address user);
  event DistributeReward(address indexed user, uint256 amount);
  event DepositRewards(address indexed user, uint256 amountTokens);

  modifier onlyToken() {
    require(msg.sender == token, 'ONLYTOKEN');
    _;
  }

  constructor(address _token) {
    token = _token;
  }

  function setShare(
    address shareholder,
    uint256 balanceUpdate,
    bool isRemoving
  ) public override onlyToken {
    _setShare(shareholder, balanceUpdate, isRemoving);
  }

  function _setShare(
    address shareholder,
    uint256 balanceUpdate,
    bool isRemoving
  ) internal {
    if (isRemoving) {
      _removeShares(shareholder, balanceUpdate);
      emit RemoveShares(shareholder, balanceUpdate);
    } else {
      _addShares(shareholder, balanceUpdate);
      emit AddShares(shareholder, balanceUpdate);
    }
  }

  function _addShares(address shareholder, uint256 amount) private {
    if (shares[shareholder].amount > 0) {
      _distributeReward(shareholder);
    }

    uint256 sharesBefore = shares[shareholder].amount;

    totalSharesDeposited += amount;
    shares[shareholder].amount += amount;
    shares[shareholder].stakedTime = block.timestamp;
    if (sharesBefore == 0 && shares[shareholder].amount > 0) {
      totalStakedUsers++;
    }
    rewards[shareholder].totalExcluded = _cumulativeRewards(
      shares[shareholder].amount
    );
  }

  function _removeShares(address shareholder, uint256 amount) private {
    require(
      shares[shareholder].amount > 0 && amount <= shares[shareholder].amount,
      'REMOVE: no shares'
    );
    _distributeReward(shareholder);

    totalSharesDeposited -= amount;
    shares[shareholder].amount -= amount;
    if (shares[shareholder].amount == 0) {
      totalStakedUsers--;
    }
    rewards[shareholder].totalExcluded = _cumulativeRewards(
      shares[shareholder].amount
    );
  }

  function depositRewards() external payable override {
    _depositRewards(msg.value);
  }

  function _depositRewards(uint256 _amount) internal {
    require(_amount > 0, 'DEPOSIT: no ETH');
    require(totalSharesDeposited > 0, 'DEPOSIT: no shares');

    totalRewards += _amount;
    uint256 _month = beginningOfMonth(block.timestamp);
    monthlyRewards[_month] += _amount;
    rewardsPerShare += (MULTIPLIER * _amount) / totalSharesDeposited;
    emit DepositRewards(msg.sender, _amount);
  }

  function _distributeReward(address shareholder) internal {
    if (shares[shareholder].amount == 0) {
      return;
    }

    uint256 amount = getUnpaid(shareholder);
    rewards[shareholder].totalRealized += amount;
    rewards[shareholder].totalExcluded = _cumulativeRewards(
      shares[shareholder].amount
    );

    if (amount > 0) {
      totalDistributed += amount;
      uint256 _balBefore = address(this).balance;
      (bool success, ) = payable(shareholder).call{ value: amount }('');
      require(success, 'DIST: could not distribute');
      require(address(this).balance >= _balBefore - amount, 'DIST: too much');
      emit DistributeReward(shareholder, amount);
    }
  }

  function claimReward() external override {
    _distributeReward(msg.sender);
    emit ClaimReward(msg.sender);
  }

  function getUnpaid(address shareholder) public view returns (uint256) {
    if (shares[shareholder].amount == 0) {
      return 0;
    }
    uint256 earnedRewards = _cumulativeRewards(shares[shareholder].amount);
    uint256 rewardsExcluded = rewards[shareholder].totalExcluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }
    return earnedRewards - rewardsExcluded;
  }

  function beginningOfMonth(uint256 _timestamp) public pure returns (uint256) {
    (, , uint256 _dayOfMonth) = BokkyPooBahsDateTimeLibrary.timestampToDate(
      _timestamp
    );
    return
      _timestamp - ((_dayOfMonth - 1) * 24 * 60 * 60) - (_timestamp % 1 days);
  }

  function _cumulativeRewards(uint256 share) internal view returns (uint256) {
    return (share * rewardsPerShare) / MULTIPLIER;
  }

  function getShares(address user) external view override returns (uint256) {
    return shares[user].amount;
  }
}