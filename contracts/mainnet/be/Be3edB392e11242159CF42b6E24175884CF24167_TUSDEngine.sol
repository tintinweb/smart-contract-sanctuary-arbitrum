// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

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
pragma solidity ^0.8.15;

//  _________  ________  ________  ________  ___  ___  _______
// |\___   ___\\   __  \|\   __  \|\   __  \|\  \|\  \|\  ___ \
// \|___ \  \_\ \  \|\  \ \  \|\  \ \  \|\  \ \  \\\  \ \   __/|
//     \ \  \ \ \  \\\  \ \   _  _\ \  \\\  \ \  \\\  \ \  \_|/__
//      \ \  \ \ \  \\\  \ \  \\  \\ \  \\\  \ \  \\\  \ \  \_|\ \
//       \ \__\ \ \_______\ \__\\ _\\ \_____  \ \_______\ \_______\
//        \|__|  \|_______|\|__|\|__|\|___| \__\|_______|\|_______|

interface ITUSDEngine {
    ///////////////////
    // Errors
    ///////////////////
    error TUSDEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error TUSDEngine__NeedsMoreThanZero();
    error TUSDEngine__TokenNotAllowed(address token);
    error TUSDEngine__TransferFailed();
    error TUSDEngine__BreaksHealthFactor(uint256 healthFactorValue);
    error TUSDEngine__MintFailed();
    error TUSDEngine__HealthFactorOk();
    error TUSDEngine__HealthFactorNotImproved();
    error TUSDEngine__NotLatestPrice();
    error OracleLib__StalePrice();

    ///////////////////
    // Events
    ///////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(
        address indexed redeemedFrom,
        uint256 indexed amountCollateral,
        address from,
        address to
    ); // if from != to, then it was liquidated
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//  _________  ________  ________  ________  ___  ___  _______
// |\___   ___\\   __  \|\   __  \|\   __  \|\  \|\  \|\  ___ \
// \|___ \  \_\ \  \|\  \ \  \|\  \ \  \|\  \ \  \\\  \ \   __/|
//     \ \  \ \ \  \\\  \ \   _  _\ \  \\\  \ \  \\\  \ \  \_|/__
//      \ \  \ \ \  \\\  \ \  \\  \\ \  \\\  \ \  \\\  \ \  \_|\ \
//       \ \__\ \ \_______\ \__\\ _\\ \_____  \ \_______\ \_______\
//        \|__|  \|_______|\|__|\|__|\|___| \__\|_______|\|_______|

import { ERC20Burnable, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract TUSD is ERC20Burnable, Ownable {
    error TUSD__AmountMustBeMoreThanZero();
    error TUSD__BurnAmountExceedsBalance();
    error TUSD__NotZeroAddress();

    constructor() ERC20("Torque USD", "TUSD") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert TUSD__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert TUSD__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert TUSD__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert TUSD__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./TUSDEngineAbstract.sol";

/*
 * Title: USDEngine
 * Author: Torque Inc.
 * Collateral: Exogenous
 * Minting: Algorithmic
 * Stability: TUSD Peg
 * Collateral: Crypto
 *
 * This contract is the core of TUSD.money. It handles the TUSD 'mint
 * and redeem' logic and is based on the MakerDAO DSS system.
 */
contract TUSDEngine is TUSDEngineAbstract {
    ///////////////////
    // Functions
    ///////////////////

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        uint256[] memory liquidationThresholds,
        uint256[] memory collateralDecimals,
        address tusdAddress
    )
        TUSDEngineAbstract(
            tokenAddresses,
            priceFeedAddresses,
            liquidationThresholds,
            collateralDecimals,
            tusdAddress
        )
    {}

    ///////////////////
    // External Functions
    ///////////////////
    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     * @param amountUSD;ToMint: The amount of TUSD you want to mint
     * @notice This function will deposit your collateral and mint TUSD in one transaction
     */
    function depositCollateralAndMintTusd(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amounUSDToMint,
        address onBehalfUser
    ) external payable override(TUSDEngineAbstract) {
        depositCollateral(tokenCollateralAddress, amountCollateral, onBehalfUser);
        mintTusd(amounUSDToMint, tokenCollateralAddress, onBehalfUser);
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     * @param amountUSD;ToBurn: The amount of TUSD you want to burn
     * @notice This function will withdraw your collateral and burn TUSD in one transaction
     */
    function redeemCollateralForTusd(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountUsdToBurn,
        address onBehalfUser
    ) external payable override(TUSDEngineAbstract) moreThanZero(amountCollateral) {
        _burnUsd(amountUsdToBurn, onBehalfUser, msg.sender, tokenCollateralAddress);
        _redeemCollateral(tokenCollateralAddress, amountCollateral, onBehalfUser, msg.sender);
        revertIfHealthFactorIsBroken(onBehalfUser, tokenCollateralAddress);
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're redeeming
     * @param amountCollateral: The amount of collateral you're redeeming
     * @notice This function will redeem your collateral.
     * @notice If you have TUSD minted, you'll not be able to redeem until you burn your TUSD
     */
    function redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address onBehalfUser
    ) external payable override(TUSDEngineAbstract) moreThanZero(amountCollateral) nonReentrant {
        _redeemCollateral(tokenCollateralAddress, amountCollateral, onBehalfUser, onBehalfUser);
        revertIfHealthFactorIsBroken(onBehalfUser, tokenCollateralAddress);
    }

    /*
     * @notice You'll burn your TUSD here! Make sure you want to do this..
     * @dev You might want to use this to just to move away from liquidation.
     */
    function burnTusd(
        uint256 amount,
        address collateral,
        address onBehalfUser
    ) external override(TUSDEngineAbstract) moreThanZero(amount) {
        _burnUsd(amount, onBehalfUser, msg.sender, collateral);
        revertIfHealthFactorIsBroken(onBehalfUser, collateral);
    }

    /*
     * @param collateral: The ERC20 token address of the collateral you're using to make the protocol solvent again.
     * This is collateral that you're going to take from the user who is insolvent.
     * In return, you have to burn your TUSD to pay off their debt, but you don't pay off your own.
     * @param user: The user who is insolvent. They have to have a _healthFactor below MIN_HEALTH_FACTOR
     * @param debtToCover: The amount of TUSD you want to burn to cover the user's debt.
     *
     * @notice: You can partially liquidate a user.
     * @notice: You will get a 10% LIQUIDATION_BONUS for taking the users funds.
     * @notice: This function working assumes that the protocol will be roughly 150% overcollateralized in order for this to work.
     * @notice: A known bug would be if the protocol was only 100% collateralized, we wouldn't be able to liquidate anyone.
     * For example, if the price of the collateral plummeted before anyone could be liquidated.
     */
    function liquidate(
        address collateral,
        address user,
        uint256 debtToCover
    ) external payable override(TUSDEngineAbstract) moreThanZero(debtToCover) nonReentrant {
        uint256 startingUserHealthFactor = _healthFactor(user, collateral);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert TUSDEngine__HealthFactorOk();
        }
        // If covering 100 TUSD, we need to $100 of collateral
        (uint256 tokenAmountFromDebtCovered, bool isLatestPrice) = getTokenAmountFromTusd(
            collateral,
            debtToCover
        );
        if (!isLatestPrice) {
            revert TUSDEngine__NotLatestPrice();
        }
        // And give them a 10% bonus
        // So we are giving the liquidator $110 of WETH for 100 TUSD
        // We should implement a feature to liquidate in the event the protocol is insolvent
        // And sweep extra amounts into a treasury
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / 100;
        // Burn TUSD equal to debtToCover
        // Figure out how much collateral to recover based on how much burnt
        _redeemCollateral(
            collateral,
            tokenAmountFromDebtCovered + bonusCollateral,
            user,
            msg.sender
        );
        _burnUsd(debtToCover, user, msg.sender, collateral);

        uint256 endingUserHealthFactor = _healthFactor(user, collateral);
        // This conditional should never hit, but just in case
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert TUSDEngine__HealthFactorNotImproved();
        }
        revertIfHealthFactorIsBroken(msg.sender, collateral);
    }

    ///////////////////
    // Public Functions
    ///////////////////
    /*
     * @param amountUSD;ToMint: The amount of TUSD you want to mint
     * You can only mint TUSD if you have enough collateral
     */
    function mintTusd(
        uint256 amounUSDToMint,
        address collateral,
        address onBehalfUser
    ) public override(TUSDEngineAbstract) moreThanZero(amounUSDToMint) nonReentrant {
        s_USDMinted[onBehalfUser][collateral] += amounUSDToMint;
        revertIfHealthFactorIsBroken(onBehalfUser, collateral);
        bool minted = i_usd.mint(msg.sender, amounUSDToMint);

        if (minted != true) {
            revert TUSDEngine__MintFailed();
        }
    }

    function getMintableTUSD(
        address tokenCollateralAddress,
        address user,
        uint256 amountCollateral
    ) public view override(TUSDEngineAbstract) returns (uint256, bool) {
        uint256 amount = s_collateralDeposited[user][tokenCollateralAddress];
        uint256 normalizedAmount = normalizeTokenAmount(amountCollateral, tokenCollateralAddress);
        (uint256 tusdValue, bool isLatestPrice) = _getTusdValue(
            tokenCollateralAddress,
            amount + normalizedAmount
        );
        uint256 totalTusdMintableAmount = (tusdValue *
            liquidationThreshold[tokenCollateralAddress]) / 100;

        (uint256 totalUsdMinted, , ) = _getAccountInformation(user, tokenCollateralAddress);

        if (totalTusdMintableAmount <= totalUsdMinted) {
            uint256 debtTusdAmount = totalUsdMinted - totalTusdMintableAmount;
            return (debtTusdAmount, false); // cannot mint tusd anymore
        } else {
            uint256 mintableTusdAmount = totalTusdMintableAmount - totalUsdMinted;
            return (convertToSafetyValue(mintableTusdAmount), isLatestPrice);
        }
    }

    function getBurnableTUSD(
        address tokenCollateralAddress,
        address user,
        uint256 amountUSD
    ) public view override(TUSDEngineAbstract) returns (uint256, bool) {
        (uint256 totalUsdMinted, uint256 totalCollateralInUSD, ) = _getAccountInformation(
            user,
            tokenCollateralAddress
        );
        uint256 totalTusdAfterBurn = 0;
        uint256 tokenAmountInTUSD = 0;
        if (amountUSD < totalUsdMinted) {
            totalTusdAfterBurn = totalUsdMinted - amountUSD;
        }

        uint256 backupTokenInTUSD = (totalTusdAfterBurn * 100) /
            liquidationThreshold[tokenCollateralAddress];
        tokenAmountInTUSD = totalCollateralInUSD >= backupTokenInTUSD
            ? totalCollateralInUSD - backupTokenInTUSD
            : 0;

        return getTokenAmountFromTusd(tokenCollateralAddress, tokenAmountInTUSD);
    }

    //////////////////////////////
    // Private & Internal View & Pure Functions
    //////////////////////////////
    function _getAccountInformation(
        address user,
        address collateral
    )
        internal
        view
        override(TUSDEngineAbstract)
        returns (uint256 totalUsdMinted, uint256 collateralValueInUsd, bool isLatestPrice)
    {
        totalUsdMinted = s_USDMinted[user][collateral];
        (uint256 _collateralValueInUsd, bool _isLatestPrice) = getAccountCollateralValue(
            user,
            collateral
        );
        collateralValueInUsd = _collateralValueInUsd;
        _isLatestPrice = isLatestPrice;
    }

    function _healthFactor(
        address user,
        address collateral
    ) internal view override(TUSDEngineAbstract) returns (uint256) {
        (
            uint256 totalUsdMinted,
            uint256 collateralValueInUsd,
            bool isLatestPrice
        ) = _getAccountInformation(user, collateral);
        return _calculateHealthFactor(totalUsdMinted, collateralValueInUsd, collateral);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function getAccountCollateralValue(
        address user,
        address collateral
    ) public view override(TUSDEngineAbstract) returns (uint256, bool) {
        uint256 amount = s_collateralDeposited[user][collateral];
        return _getTusdValue(collateral, amount);
    }

    function getTokenAmountFromTusd(
        address token,
        uint256 usdAmountInWei
    ) public view override(TUSDEngineAbstract) returns (uint256, bool) {
        uint256 tokenAmount;
        bool isLatestPrice;
        if (s_priceFeeds[token] == WSTETHPriceFeed) {
            (uint256 wstETHToEthPrice, bool isLatestPrice1) = validatePriceFeedAndReturnValue(
                WSTETHPriceFeed
            );
            (uint256 ethToTUSDPrice, bool isLatestPrice2) = validatePriceFeedAndReturnValue(
                ETHPriceFeed
            );
            isLatestPrice = isLatestPrice1 && isLatestPrice2;
            tokenAmount =
                (usdAmountInWei * PRECISION ** 2) /
                (ADDITIONAL_FEED_PRECISION ** 2 * wstETHToEthPrice * ethToTUSDPrice);
        } else {
            (uint256 price, bool _isLatestPrice) = validatePriceFeedAndReturnValue(
                s_priceFeeds[token]
            );
            isLatestPrice = _isLatestPrice;
            tokenAmount = ((usdAmountInWei * PRECISION) / (price * ADDITIONAL_FEED_PRECISION));
        }
        uint256 finalAmount = (tokenAmount * 10 ** s_collateralDecimal[token]) / 10 ** 18;
        return (finalAmount, isLatestPrice);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//  _________  ________  ________  ________  ___  ___  _______
// |\___   ___\\   __  \|\   __  \|\   __  \|\  \|\  \|\  ___ \
// \|___ \  \_\ \  \|\  \ \  \|\  \ \  \|\  \ \  \\\  \ \   __/|
//     \ \  \ \ \  \\\  \ \   _  _\ \  \\\  \ \  \\\  \ \  \_|/__
//      \ \  \ \ \  \\\  \ \  \\  \\ \  \\\  \ \  \\\  \ \  \_|\ \
//       \ \__\ \ \_______\ \__\\ _\\ \_____  \ \_______\ \_______\
//        \|__|  \|_______|\|__|\|__|\|___| \__\|_______|\|_______|
//

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TUSD } from "./TUSD.sol";
import "./interfaces/ITUsdEngine.sol";

abstract contract TUSDEngineAbstract is ReentrancyGuard, Ownable, ITUSDEngine {
    ///////////////////
    // State Variables
    ///////////////////
    TUSD internal immutable i_usd;

    // uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    mapping(address => uint256) internal liquidationThreshold;
    uint256 internal constant DENOMINATOR_PRECISION = 1e6;
    uint256 internal safetyNumerator = 950000; // 95 %
    uint256 internal constant LIQUIDATION_BONUS = 10; // This means you get assets at a 10% discount when liquidating
    uint256 internal constant MIN_HEALTH_FACTOR = 1e18;
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 internal constant FEED_PRECISION = 1e8;
    uint256 internal constant TIMEOUT = 24 hours;
    address internal WETH = 0xEe01c0CD76354C383B8c7B4e65EA88D00B06f36f;
    address internal WSTETHPriceFeed = 0xb523AE262D20A936BC152e6023996e46FDC2A95D; // For WSTETH priceFeed
    address internal ETHPriceFeed = 0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08;

    /// @dev Mapping of token address to price feed address
    mapping(address collateralToken => address priceFeed) internal s_priceFeeds;
    /// @dev Amount of collateral deposited by user
    mapping(address user => mapping(address collateralToken => uint256 amount))
        internal s_collateralDeposited;
    /// @dev Amount of TUSD minted by user
    mapping(address user => mapping(address token => uint256 amount)) internal s_USDMinted;
    /// @dev If we know exactly how many tokens we have, we could make this immutable!
    mapping(address => uint256) s_collateralDecimal;
    address[] public s_collateralTokens;

    ///////////////////
    // Modifiers
    ///////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert TUSDEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert TUSDEngine__TokenNotAllowed(token);
        }
        _;
    }

    ///////////////////
    // Functions
    ///////////////////
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        uint256[] memory liquidationThresholds,
        uint256[] memory collateralDecimals,
        address tusdAddress
    ) {
        if (
            tokenAddresses.length != priceFeedAddresses.length &&
            tokenAddresses.length != collateralDecimals.length
        ) {
            revert TUSDEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
            liquidationThreshold[tokenAddresses[i]] = liquidationThresholds[i];
            s_collateralDecimal[tokenAddresses[i]] = collateralDecimals[i];
        }
        i_usd = TUSD(tusdAddress);
    }

    function updateWSTETHPriceFeed(
        address _wstethPriceFeed,
        address _ethPriceFeed
    ) public onlyOwner {
        WSTETHPriceFeed = _wstethPriceFeed;
        ETHPriceFeed = _ethPriceFeed;
    }

    function updateAllPriceFeed(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        uint256[] memory liquidationThresholds,
        uint256[] memory collateralDecimals
    ) public onlyOwner {
        delete s_collateralTokens;
        if (
            tokenAddresses.length != priceFeedAddresses.length &&
            tokenAddresses.length != collateralDecimals.length
        ) {
            revert TUSDEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
            liquidationThreshold[tokenAddresses[i]] = liquidationThresholds[i];
            s_collateralDecimal[tokenAddresses[i]] = collateralDecimals[i];
        }
    }

    function normalizeTokenAmount(
        uint256 amount,
        address collateral
    ) internal view returns (uint256) {
        return (amount * 10 ** 18) / (10 ** s_collateralDecimal[collateral]);
    }

    function updatepriceFeed(address tokenAddress, address priceFeedAddress) public onlyOwner {
        s_priceFeeds[tokenAddress] = priceFeedAddress;
    }

    function updateWETH(address _WETH) public onlyOwner {
        WETH = _WETH;
    }

    function depositCollateralAndMintTusd(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amounUSDToMint,
        address onBehalfUser
    ) external payable virtual {}

    function redeemCollateralForTusd(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountUSDToBurn,
        address onBehalfUser
    ) external payable virtual moreThanZero(amountCollateral) {}

    function redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address onBehalfUser
    ) external payable virtual moreThanZero(amountCollateral) nonReentrant {}

    function burnTusd(
        uint256 amount,
        address collateral,
        address onBehalfUser
    ) external virtual moreThanZero(amount) {}

    function liquidate(
        address collateral,
        address user,
        uint256 debtToCover
    ) external payable virtual moreThanZero(debtToCover) nonReentrant {}

    function mintTusd(
        uint256 amounUSDToMint,
        address collateral,
        address onBehalfUser
    ) public virtual moreThanZero(amounUSDToMint) nonReentrant {}

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address onBehalfUser
    )
        public
        payable
        moreThanZero(amountCollateral)
        nonReentrant
        isAllowedToken(tokenCollateralAddress)
    {
        if (tokenCollateralAddress == WETH) {
            require(msg.value == amountCollateral, "TUSD: Not enough balance");
        } else {
            bool success = IERC20(tokenCollateralAddress).transferFrom(
                msg.sender,
                address(this),
                amountCollateral
            );
            if (!success) {
                revert TUSDEngine__TransferFailed();
            }
        }
        uint256 normalizedAmount = normalizeTokenAmount(amountCollateral, tokenCollateralAddress);
        s_collateralDeposited[onBehalfUser][tokenCollateralAddress] += normalizedAmount;
        emit CollateralDeposited(onBehalfUser, tokenCollateralAddress, amountCollateral);
    }

    function getMintableTUSD(
        address tokenCollateralAddress,
        address user,
        uint256 amountCollateral
    ) public view virtual returns (uint256, bool) {}

    function getBurnableTUSD(
        address tokenCollateralAddress,
        address user,
        uint256 amountUSD
    ) public view virtual returns (uint256, bool) {}

    ///////////////////
    // Private Functions
    ///////////////////
    function _redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address from,
        address to
    ) internal {
        uint256 normalizedAmount = normalizeTokenAmount(amountCollateral, tokenCollateralAddress);
        s_collateralDeposited[from][tokenCollateralAddress] -= normalizedAmount;
        if (tokenCollateralAddress == WETH) {
            (bool success, ) = to.call{ value: amountCollateral }("");
            require(success, "TUSD: Transfer ETH failed");
        } else {
            bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
            if (!success) {
                revert TUSDEngine__TransferFailed();
            }
        }
        emit CollateralRedeemed(from, amountCollateral, from, to);
    }

    function _burnUsd(
        uint256 amountUSDToBurn,
        address onBehalfOf,
        address tusdFrom,
        address collateral
    ) internal {
        if (s_USDMinted[onBehalfOf][collateral] >= amountUSDToBurn) {
            s_USDMinted[onBehalfOf][collateral] -= amountUSDToBurn;
        } else {
            s_USDMinted[onBehalfOf][collateral] = 0;
        }

        bool success = i_usd.transferFrom(tusdFrom, address(this), amountUSDToBurn);
        // This conditional is hypothetically unreachable
        if (!success) {
            revert TUSDEngine__TransferFailed();
        }
        i_usd.burn(amountUSDToBurn);
    }

    //////////////////////////////
    // Private & Internal View & Pure Functions
    //////////////////////////////

    function _getAccountInformation(
        address user,
        address collateral
    )
        internal
        view
        virtual
        returns (uint256 totalUsdMinted, uint256 collateralValueInUsd, bool isLatestPrice)
    {}

    function _healthFactor(
        address user,
        address collateral
    ) internal view virtual returns (uint256) {}

    // function _getTusdValue(address token, uint256 amount) internal view virtual returns (uint256) {}
    function _getTusdValue(address token, uint256 amount) internal view returns (uint256, bool) {
        uint256 tusdValue;
        bool isLatestPrice;
        if (s_priceFeeds[token] == WSTETHPriceFeed) {
            (uint256 wstToETHPrice, bool isLatestPrice1) = validatePriceFeedAndReturnValue(
                WSTETHPriceFeed
            );
            (uint256 ethToTUSDPrice, bool isLatestPrice2) = validatePriceFeedAndReturnValue(
                ETHPriceFeed
            );
            isLatestPrice = isLatestPrice1 && isLatestPrice2;
            tusdValue =
                (amount *
                    uint256(wstToETHPrice) *
                    uint256(ethToTUSDPrice) *
                    ADDITIONAL_FEED_PRECISION ** 2) /
                PRECISION ** 2;
        } else {
            (uint256 price, bool _isLatestPrice) = validatePriceFeedAndReturnValue(
                s_priceFeeds[token]
            );
            isLatestPrice = _isLatestPrice;
            tusdValue = ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
        }
        return (tusdValue, isLatestPrice);
    }

    function _calculateHealthFactor(
        uint256 totalUsdMinted,
        uint256 collateralValueInUsd,
        address collateral
    ) internal view returns (uint256) {
        if (totalUsdMinted == 0) return type(uint256).max;
        return
            (collateralValueInUsd * liquidationThreshold[collateral] * 1e18) /
            (totalUsdMinted * 100);
    }

    function revertIfHealthFactorIsBroken(address user, address collateral) internal view {
        uint256 userHealthFactor = _healthFactor(user, collateral);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert TUSDEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    function validatePriceFeedAndReturnValue(
        address _priceFeed
    ) internal view returns (uint256, bool) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        if (updatedAt == 0) {
            revert OracleLib__StalePrice();
        }
        uint256 secondsSince = block.timestamp - updatedAt;
        if (secondsSince > TIMEOUT) revert OracleLib__StalePrice();
        bool isLatestValue = answeredInRound >= roundId;
        return (uint256(price), isLatestValue);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    function calculateHealthFactor(
        uint256 totalUsdMinted,
        uint256 collateralValueInUsd,
        address collateral
    ) external view returns (uint256) {
        return _calculateHealthFactor(totalUsdMinted, collateralValueInUsd, collateral);
    }

    function getAccountInformation(
        address user,
        address collateral
    )
        external
        view
        returns (uint256 totalUsdMinted, uint256 collateralValueInUsd, bool isLatestPrice)
    {
        return _getAccountInformation(user, collateral);
    }

    function getTusdValue(
        address token,
        uint256 amount // in WEI
    ) external view returns (uint256, bool) {
        return _getTusdValue(token, amount);
    }

    function getCollateralBalanceOfUser(
        address user,
        address token
    ) external view returns (uint256) {
        return s_collateralDeposited[user][token];
    }

    function getAccountCollateralValue(
        address user,
        address collateral
    ) public view virtual returns (uint256, bool) {}

    function getTokenAmountFromTusd(
        address token,
        uint256 usdAmountInWei
    ) public view virtual returns (uint256, bool) {}

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getLiquidationThreshold(address _token) external view returns (uint256) {
        return liquidationThreshold[_token];
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getTusd() external view returns (address) {
        return address(i_usd);
    }

    function getCollateralTokenPriceFeed(address token) external view returns (address) {
        return s_priceFeeds[token];
    }

    function getHealthFactor(address user, address collateral) external view returns (uint256) {
        return _healthFactor(user, collateral);
    }

    function changeSafetyNumerator(uint256 _safetyNumerator) external onlyOwner {
        safetyNumerator = _safetyNumerator;
    }

    function convertToSafetyValue(uint256 initialValue) internal view returns (uint256) {
        return (initialValue * safetyNumerator) / DENOMINATOR_PRECISION;
    }
}