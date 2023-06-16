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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
pragma solidity 0.8.19;

struct User {
    uint256 totalPegPerMember;
    uint256 pegClaimed;
    bool exist;
}

struct Stake {
    uint256 amount; ///@dev amount of peg staked.
    int256 rewardDebt; ///@dev outstanding rewards that will not be included in the next rewards calculation.
}

struct StakeClass {
    uint256 id;
    uint256 minDuration;
    uint256 maxDuration;
    bool isActive;
}

struct Lock {
    uint256 pegLocked;
    uint256 wethLocked;
    uint256 totalLpShare;
    int256 rewardDebt;
    uint48 lockedAt; // locked
    uint48 lastLockedAt; // last time user increased their lock allocation
    uint48 unlockTimestamp; // unlockable
}

struct EsPegLock {
    uint256 esPegLocked;
    uint256 wethLocked;
    uint256 totalLpShare;
    int256 rewardDebt;
    uint48 lockedAt; // locked
    uint48 unlockTimestamp; // unlockable
}

struct FeeDistributorInfo {
    uint256 accumulatedUsdcPerContract; ///@dev usdc allocated to the three contracts in the fee distributor.
    uint256 lastBalance; ///@dev last balance of usdc in the fee distributor.
    uint256 currentBalance; ///@dev current balance of usdc in the fee distributor.
    int256 stakingContractDebt; ///@dev outstanding rewards of this contract (staking) that will not be included in the next rewards calculation.
    int256 lockContractDebt; ///@dev outstanding rewards of this contract (lock) that will not be included in the next rewards calculation.
    int256 plsAccumationContractDebt; ///@dev outstanding rewards of this contract (pls accumulator) that will not be included in the next rewards calculation.
    uint48 lastUpdateTimestamp; ///@dev last time the fee distributor rewards were updated.
}

struct StakeDetails {
    int256 rewardDebt;
    uint112 plsStaked;
    uint32 epoch;
    address user;
}

struct StakedDetails {
    uint112 amount;
    uint32 lastCheckpoint;
}

struct EsPegStake {
    address user; //user who staked
    uint256 amount; //amount of esPeg staked
    uint256 amountClaimable; //amount of peg claimable
    uint256 amountClaimed; //amount of peg claimed
    uint256 pegPerSecond; //reward rate
    uint48 startTime; //time when the stake started
    uint48 fullVestingTime; //time when the stake is fully vested
    uint48 lastClaimTime; //time when the user last claimed
}

struct EsPegVest {
    address user; //user who staked
    uint256 amount; //amount of esPeg staked
    uint256 amountClaimable; //amount of peg claimable
    uint256 amountClaimed; //amount of peg claimed
    uint256 pegPerSecond; //reward rate
    uint48 startTime; //time when the stake started
    uint48 fullVestingTime; //time when the stake is fully vested
    uint48 lastClaimTime; //time when the user last claimed
}

struct Referrers {
    uint256 epochId;
    address[] referrers;
    uint256[] allocations;
}

struct Group {
    uint256 totalUsdcDistributed;
    uint256 accumulatedUsdcPerContract;
    uint256 pendingGroupUsdc;
    uint256 lastGroupBalance;
    int256 shareDebt;
    string name;
    uint16 feeShare;
    uint8 groupId; //1: staking , 2:locking , 3:plsAccumulator
}

struct Contract {
    uint256 totalUsdcReceived;
    int256 contractShareDebt;
    address contractAddress;
    uint16 feeShare;
    uint8 groupId; ///@dev group contract belongs to
}

struct GroupUpdate {
    uint8 groupId;
    uint16 newShare;
}

struct ContractUpdate {
    address contractAddress;
    uint16 newShare;
}

///@notice PepeBet structs
struct BetDetails {
    uint256 amount;
    uint256 wagerAmount;
    uint256 openingPrice;
    uint256 closingPrice;
    uint256 startTime;
    uint256 endTime;
    uint256 betId;
    address initiator;
    address betToken;
    address asset;
    bool isLong;
    bool active;
}

struct WagerTokenDetails {
    address token;
    uint256 minBetAmount;
    uint256 maxBetAmount;
}

///@notice PepeLockExtention structs
struct LockExtension {
    address user;
    uint256 amount;
    uint48 lockDuration;
}

///@notice PepeDegen struct
struct DegenEpoch {
    uint32 epochId;
    address[] users;
    uint256[] amounts;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IEsPepeToken is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function retrieve(address _token) external;

    function owner() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { EsPegLock } from "../Structs.sol";

interface IPepeEsPegLockUp {
    function lock(uint256 wethAmount, uint256 esPegAmount, uint256 minBlpOut) external;

    function unlock(uint256 lockId) external;

    ///@notice update rewards accumulated to this contract.
    function updateRewards() external;

    function claimUsdcRewards(uint256 lockId) external;

    function claimAllUsdcRewards() external;

    function getTotalPendingUsdcRewards(address user) external view returns (uint256);

    function pendingUsdcRewards(address user, uint256 lockId) external view returns (uint256);

    function setRewardPool(address _rewardPool) external;

    function updateLockGroupId(uint8 _lockGroupId) external;

    function setLockDuration(uint48 _lockDuration) external;

    function getLockDetails(address _user, uint256 lockId) external view returns (EsPegLock memory);

    function getAllUsers() external view returns (address[] memory);

    function setFeeDistributor(address _feeDistributor) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPepeEsPegRewardPoolV2 {
    function approveContract(address contract_) external;

    function revokeContract(address contract_) external;

    function updateStakingContract(address _staking) external;

    ///@notice backward compatibility with esPeg staking/vesting contract V1
    function allocatePegStaking(uint256 _amount) external;

    function fundContractOperation(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function retrieve(address _token) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import { Group, GroupUpdate, Contract, ContractUpdate } from "../Structs.sol";

interface IPepeFeeDistributorV2 {
    function updateGroupAllocations() external;

    function updateContractAllocations() external;

    function allocateUsdcToGroup(uint8 groupId) external;

    function transferUsdcToContract(uint8 groupId, address contractAddress) external returns (uint256);

    function allocateUsdcToAllGroups() external;

    function transferUsdcToAllContracts() external;

    function transferUsdcToContractsByGroupId(uint8 groupId) external;

    function addGroup(
        GroupUpdate[] calldata update,
        string calldata name,
        uint16 groupShare,
        address contractAddress,
        uint16 contractShare
    ) external;

    function addContract(
        ContractUpdate[] memory existingContractsUpdate,
        uint8 groupId,
        address contractAddress,
        uint16 share
    ) external;

    function removeGroup(uint8 groupId, GroupUpdate[] memory existingGroups) external;

    function removeContract(uint8 groupId, address contractAddress, ContractUpdate[] memory existingContracts) external;

    function updateGroupShares(GroupUpdate[] memory existingGroups) external;

    function updateContractShares(uint8 groupId, ContractUpdate[] memory existingContracts) external;

    function contractPendingUsdcRewards(address contractAddress, uint8 groupId) external view returns (uint256);

    function retrieveTokens(address[] calldata _tokens, address to) external;

    function retrieve(address _token, address to) external;

    function getLastBalance() external view returns (uint256);

    function getAccumulatedUsdcPerGroup() external view returns (uint256);

    function getLastUpdatedContractsTimestamp() external view returns (uint48);

    function getLastUpdatedGroupsTimestamp() external view returns (uint48);

    function getContractIndex(uint8 groupdId, address _contract) external view returns (uint256);

    function getGroup(uint8 groupId) external view returns (Group memory);

    function getContracts(uint8 groupId) external view returns (Contract[] memory);

    function getGroupShareDebt(uint8 groupId) external view returns (int256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Lock } from "../Structs.sol";

interface IPepeLockUp {
    function initializePool(uint256 wethAmount, uint256 pegAmount, address poolAdmin) external;

    function updateRewards() external;

    function lock(uint256 wethAmount, uint256 pegAmount, uint256 minBlpOut) external;

    function unLock() external;

    function claimUsdcRewards() external;

    function pendingUsdcRewards(address _user) external view returns (uint256);

    function getLockDetails(address _user) external view returns (Lock memory);

    function lockDuration() external view returns (uint48);

    function setLockDuration(uint48 _lockDuration) external;

    function setFeeDistributor(address _feeDistributor) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IBasePool is IERC20 {
    function getSwapFeePercentage() external view returns (uint256);

    function setSwapFeePercentage(uint256 swapFeePercentage) external;

    function setAssetManagerPoolConfig(IERC20 token, IAssetManager.PoolConfig memory poolConfig) external;

    function setPaused(bool paused) external;

    function getVault() external view returns (IVault);

    function getPoolId() external view returns (bytes32);

    function getOwner() external view returns (address);
}

interface IWeightedPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory normalizedWeights,
        address[] memory rateProviders,
        uint256 swapFeePercentage,
        address owner,
        bytes32 salt
    ) external returns (address);
}

interface IWeightedPool is IBasePool {
    function getSwapEnabled() external view returns (bool);

    function getNormalizedWeights() external view returns (uint256[] memory);

    function getGradualWeightUpdateParams()
        external
        view
        returns (uint256 startTime, uint256 endTime, uint256[] memory endWeights);

    function setSwapEnabled(bool swapEnabled) external;

    function updateWeightsGradually(uint256 startTime, uint256 endTime, uint256[] memory endWeights) external;

    function withdrawCollectedManagementFees(address recipient) external;

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }
}

interface IAssetManager {
    struct PoolConfig {
        uint64 targetPercentage;
        uint64 criticalPercentage;
        uint64 feePercentage;
    }

    function setPoolConfig(bytes32 poolId, PoolConfig calldata config) external;
}

interface IAsset {}

interface IVault {
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    function setRelayerApproval(address sender, address relayer, bool approved) external;

    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function registerTokens(bytes32 poolId, IERC20[] memory tokens, address[] memory assetManagers) external;

    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    function getPoolTokenInfo(
        bytes32 poolId,
        IERC20 token
    ) external view returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);

    function getPoolTokens(
        bytes32 poolId
    ) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind {
        JOIN,
        EXIT
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    enum PoolBalanceOpKind {
        WITHDRAW,
        DEPOSIT,
        UPDATE
    }
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    function setPaused(bool paused) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IWeightedPool, IAsset, IVault } from "../interfaces/IWeightedPoolFactory.sol";
import { IPepeLockUp } from "../interfaces/IPepeLockUp.sol";

abstract contract PepeEsPegLPHelper {
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant PEG = 0x4fc2A3Fb655847b7B72E19EAA2F10fDB5C2aDdbe;
    address public constant VAULT_ADDRESS = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public constant LP_TOKEN = 0x3eFd3E18504dC213188Ed2b694F886A305a6e5ed;
    bytes32 public constant POOL_ID = 0x3efd3e18504dc213188ed2b694f886a305a6e5ed00020000000000000000041d;

    event AddedLP(uint256 wethAmount, uint256 pegAmount, uint256 minBlpOut);

    function _joinPool(uint256 wethAmount, uint256 pegAmount, uint256 minBlpOut) internal {
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(PEG);
        assets[1] = IAsset(WETH);

        uint256[] memory maxAmountsIn = new uint256[](2);

        maxAmountsIn[0] = pegAmount;
        maxAmountsIn[1] = wethAmount;

        IERC20(PEG).approve(VAULT_ADDRESS, pegAmount);
        IERC20(WETH).approve(VAULT_ADDRESS, wethAmount);

        bytes memory userDataEncoded = abi.encode(
            IWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            maxAmountsIn,
            minBlpOut
        );
        IVault.JoinPoolRequest memory inRequest = IVault.JoinPoolRequest(assets, maxAmountsIn, userDataEncoded, false);
        IVault(VAULT_ADDRESS).joinPool(POOL_ID, address(this), address(this), inRequest);

        emit AddedLP(wethAmount, pegAmount, minBlpOut);
    }

    function _exitPool(uint256 lpAmount) internal {
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(PEG);
        assets[1] = IAsset(WETH);

        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[0] = 1;
        minAmountsOut[1] = 1;

        IERC20(LP_TOKEN).approve(VAULT_ADDRESS, lpAmount);

        bytes memory userData = abi.encode(IWeightedPool.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, lpAmount);

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(assets, minAmountsOut, userData, false);
        IVault(VAULT_ADDRESS).exitPool(POOL_ID, address(this), payable(msg.sender), request); //send both peg and weth to the locker (user).
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable2Step } from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { Group, Contract, FeeDistributorInfo } from "../Structs.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IPepeEsPegLockUp } from "../interfaces/IPepeEsPegLockUp.sol";
import { IPepeEsPegRewardPoolV2 } from "../interfaces/IPepeEsPegRewardPoolV2.sol";
import { IEsPepeToken } from "../interfaces/IEsPepeToken.sol";
import { IPepeFeeDistributorV2 } from "../interfaces/IPepeFeeDistributorV2.sol";
import { EsPegLock } from "../Structs.sol";
import { PepeEsPegLPHelper } from "./PepeEsPegLPHelper.sol";

contract PepeEsPegLockUp is ERC20, IPepeEsPegLockUp, Ownable2Step, PepeEsPegLPHelper {
    ///@dev users can lockup their $esPEG tokens for a 1.5 months.

    using Math for uint256;
    using Math for int256;

    /********** IMMUTABLES ************/
    IERC20 public immutable pegToken;
    IERC20 public immutable wethToken;
    IERC20 public immutable usdcToken;
    IEsPepeToken public immutable esPegToken;

    /*****VARIABLES******/
    IPepeEsPegRewardPoolV2 public rewardPoolV2; // rewardPoolV2 contract.
    IPepeFeeDistributorV2 public feeDistributorV2; ///@dev distributes usdc rewards to this contract.

    address[] public allUsers; ///@dev all users who have locked up.
    uint256 public totalEsPegLocked; ///@dev total EsPeg locked.
    uint256 public totalWethLocked; ///@dev total weth locked.
    uint256 public totalLpShares; ///@dev total lp shares.
    uint256 public accumulatedUsdcPerLpShare; ///@dev accumulated usdc per lp share.
    uint48 public lockUpDuration; ///@dev lock duration in seconds.
    uint48 public lastUpdateRewardsTimestamp; ///@dev last timestamp when rewards were updated.
    uint8 public lockGroupId; ///@dev the id of the lock group in feeDistributorV2.

    mapping(address user => mapping(uint256 lockId => EsPegLock lock)) public lockUpDetails; ///@dev lock up details.
    mapping(address user => uint256 lockId) public userLockCount; ///@dev user lock count.
    mapping(address user => uint256 index) public userIndex; ///@dev user index in allUsers array.
    mapping(address => bool) public isUser; ///@dev is user who has locked up.

    /*********EVENTS ***********/
    event RewardPoolChanged(address indexed poolAddress);
    event LockDurationChanged(uint48 indexed previousLockDuration, uint48 indexed lockDuration);
    event Locked(
        address indexed user,
        uint256 wethAmount,
        uint256 esPegAmount,
        uint256 lpAmount,
        uint48 indexed duration
    );
    event Unlocked(address indexed user, uint256 wethAmount, uint256 pegAmount, uint256 lpAmount);
    event ClaimedUsdcRewards(address user, uint256 amountClaimed);
    event LockGroupIdChanged(uint8 indexed previousLockGroupId, uint8 indexed lockGroupId);
    event FeeDistributorUpdated(address indexed previousFeeDistributor, address indexed newFeeDistributor);

    constructor(
        address pegToken_,
        address esPegToken_,
        address wethToken_,
        address usdcToken_,
        address rewardPool_,
        address feeDistributorV2_
    ) ERC20("Locked PepeEsPeg Token", "lEsPeg") {
        pegToken = IERC20(pegToken_);
        esPegToken = IEsPepeToken(esPegToken_);
        wethToken = IERC20(wethToken_);
        usdcToken = IERC20(usdcToken_);
        rewardPoolV2 = IPepeEsPegRewardPoolV2(rewardPool_);
        feeDistributorV2 = IPepeFeeDistributorV2(feeDistributorV2_);
        lockUpDuration = 45 days;
        lockGroupId = 2;
    }

    ///@notice lock weth with esPeg tokens to receive usdc rewards.
    ///@param wethAmount amount of weth to lock.
    ///@param esPegAmount amount of esPeg to lock.
    ///@param minBlpOut minimum amount of blp tokens to receive.
    function lock(uint256 wethAmount, uint256 esPegAmount, uint256 minBlpOut) external override {
        require(wethAmount != 0 && esPegAmount != 0, "zero amount");
        require(esPegToken.transferFrom(msg.sender, address(this), esPegAmount), "esPeg transferFrom failed");
        require(wethToken.transferFrom(msg.sender, address(this), wethAmount), "weth transferFrom failed");

        updateRewards();
        uint256 userLockCount_ = ++userLockCount[msg.sender];

        rewardPoolV2.fundContractOperation(esPegAmount);

        uint256 currentBlpBalance = IERC20(LP_TOKEN).balanceOf(address(this));
        _joinPool(wethAmount, esPegAmount, minBlpOut);

        ///check blp balance and calculate blp received, update user blp balance
        uint256 newBlpBalance = IERC20(LP_TOKEN).balanceOf(address(this));

        uint256 lpShare = newBlpBalance - currentBlpBalance;

        lockUpDetails[msg.sender][userLockCount_] = EsPegLock({
            esPegLocked: esPegAmount,
            wethLocked: wethAmount,
            totalLpShare: lpShare,
            rewardDebt: int256(lpShare.mulDiv(accumulatedUsdcPerLpShare, 1e18)),
            lockedAt: uint48(block.timestamp),
            unlockTimestamp: uint48(block.timestamp + lockUpDuration)
        });

        if (!isUser[msg.sender]) {
            userIndex[msg.sender] = allUsers.length;
            allUsers.push(msg.sender);
            isUser[msg.sender] = true;
        }

        totalLpShares += lpShare;
        totalEsPegLocked += esPegAmount;
        totalWethLocked += wethAmount;

        _mint(msg.sender, lpShare); ///mint lPeg to the user.

        ///@dev user provides $esPeg + $WETH and we provide liquidity on their behalf $PEG + $WETH.
        emit Locked(msg.sender, wethAmount, esPegAmount, lpShare, lockUpDuration);
    }

    ///@notice unlock lp tokens and claim all rewards.
    ///@param lockId the id of the lock.
    function unlock(uint256 lockId) external override {
        EsPegLock memory _userLockDetails = lockUpDetails[msg.sender][lockId];
        require(_userLockDetails.totalLpShare != 0, "no lock found");
        require(_userLockDetails.unlockTimestamp <= uint48(block.timestamp), "lock period not expired");

        claimUsdcRewards(lockId);

        totalLpShares -= _userLockDetails.totalLpShare;
        totalEsPegLocked -= _userLockDetails.esPegLocked;
        totalWethLocked -= _userLockDetails.wethLocked;

        _burn(msg.sender, _userLockDetails.totalLpShare);
        esPegToken.burn(address(this), _userLockDetails.esPegLocked);

        delete lockUpDetails[msg.sender][lockId];
        isUser[msg.sender] = false;

        uint256 i = 1;
        uint256 userLockCount_ = userLockCount[msg.sender];
        for (; i <= userLockCount_; ) {
            if (lockUpDetails[msg.sender][i].totalLpShare != 0) {
                isUser[msg.sender] = true;
                break;
            }
            unchecked {
                ++i;
            }
        }

        if (!isUser[msg.sender]) {
            uint256 userIndex_ = userIndex[msg.sender];
            allUsers[userIndex_] = allUsers[allUsers.length - 1];

            if (userIndex_ != allUsers.length - 1) {
                userIndex[allUsers[userIndex_]] = userIndex_;
            } else {
                delete userIndex[msg.sender];
            }

            allUsers.pop();
        }

        // call exit pool
        _exitPool(_userLockDetails.totalLpShare);

        emit Unlocked(
            msg.sender,
            _userLockDetails.wethLocked,
            _userLockDetails.esPegLocked,
            _userLockDetails.totalLpShare
        );
    }

    ///@notice update rewards accumulated to this contract.
    function updateRewards() public override {
        if (totalLpShares == 0) {
            lastUpdateRewardsTimestamp = uint48(block.timestamp);
            return;
        }
        if (uint48(block.timestamp) > lastUpdateRewardsTimestamp) {
            uint256 sharableUsdc = feeDistributorV2.transferUsdcToContract(lockGroupId, address(this));
            if (sharableUsdc != 0) {
                uint256 usdcPerLp = sharableUsdc.mulDiv(1e18, totalLpShares);
                accumulatedUsdcPerLpShare += usdcPerLp;
            }
            lastUpdateRewardsTimestamp = uint48(block.timestamp);
        }
    }

    ///@notice claim usdc rewards for a specific lock.
    ///@param lockId the id of the lock.
    function claimUsdcRewards(uint256 lockId) public override {
        EsPegLock memory _userLockDetails = lockUpDetails[msg.sender][lockId];
        if (_userLockDetails.totalLpShare == 0) return;
        updateRewards();

        int256 accumulatedUsdc = int256(_userLockDetails.totalLpShare.mulDiv(accumulatedUsdcPerLpShare, 1e18));
        uint256 pendingUsdc = uint256(accumulatedUsdc - _userLockDetails.rewardDebt);
        lockUpDetails[msg.sender][lockId].rewardDebt = accumulatedUsdc;

        if (pendingUsdc != 0) {
            require(usdcToken.transfer(msg.sender, pendingUsdc), "transfer failed");
            emit ClaimedUsdcRewards(msg.sender, pendingUsdc);
        }
    }

    ///@notice claim usdc rewards for all locks.
    function claimAllUsdcRewards() external override {
        uint256 userLockCount_ = userLockCount[msg.sender];
        for (uint256 i = 1; i <= userLockCount_; ) {
            claimUsdcRewards(i);

            unchecked {
                ++i;
            }
        }
    }

    ///@notice get pending usdc rewards for a specific lock.
    ///@param user the user address.
    ///@param lockId the id of the lock.
    function pendingUsdcRewards(address user, uint256 lockId) public view override returns (uint256) {
        EsPegLock memory _userLockDetails = lockUpDetails[user][lockId];
        if (_userLockDetails.totalLpShare == 0) return 0;

        uint256 pendingUsdcFromFeeDistributor = feeDistributorV2.contractPendingUsdcRewards(address(this), lockGroupId);

        uint256 accumulatedUsdcPerLpShare_ = accumulatedUsdcPerLpShare;

        if (pendingUsdcFromFeeDistributor != 0) {
            accumulatedUsdcPerLpShare_ += pendingUsdcFromFeeDistributor.mulDiv(1e18, totalLpShares);
        }

        int256 accumulatedUsdcForUser = int256(_userLockDetails.totalLpShare.mulDiv(accumulatedUsdcPerLpShare_, 1e18));
        return uint256(accumulatedUsdcForUser - _userLockDetails.rewardDebt);
    }

    ///@notice get total pending usdc rewards for a user.
    ///@param user the user address.
    function getTotalPendingUsdcRewards(address user) external view override returns (uint256) {
        uint256 userLockCount_ = userLockCount[user];
        uint256 totalPendingUsdc;
        for (uint256 i = 1; i <= userLockCount_; ) {
            totalPendingUsdc += pendingUsdcRewards(user, i);

            unchecked {
                ++i;
            }
        }

        return totalPendingUsdc;
    }

    ///@notice update the Peg reward pool address.
    function setRewardPool(address _rewardPool) external override onlyOwner {
        require(_rewardPool != address(0), "!rewardPoolV2");
        rewardPoolV2 = IPepeEsPegRewardPoolV2(_rewardPool);
        emit RewardPoolChanged(_rewardPool);
    }

    ///@notice update the lock group id if changed is in the fee distributor.
    ///@param _lockGroupId the new lock group id in Fee distributor.
    function updateLockGroupId(uint8 _lockGroupId) external onlyOwner {
        require(_lockGroupId != 0, "!lockGroupId");
        emit LockGroupIdChanged(lockGroupId, _lockGroupId);
        lockGroupId = _lockGroupId;
    }

    ///@notice update the lock duration.
    ///@param _lockDuration the new lock duration.
    function setLockDuration(uint48 _lockDuration) external onlyOwner {
        require(_lockDuration != 0, "!lockDuration");

        uint48 prevlockDuration = lockUpDuration;
        lockUpDuration = _lockDuration;

        emit LockDurationChanged(prevlockDuration, _lockDuration);
    }

    ///@notice update the fee distributor address.
    ///@param _feeDistributor the new fee distributor address.
    function setFeeDistributor(address _feeDistributor) external override onlyOwner {
        require(_feeDistributor != address(0), "!address");
        emit FeeDistributorUpdated(address(feeDistributorV2), _feeDistributor);
        feeDistributorV2 = IPepeFeeDistributorV2(_feeDistributor);
    }

    ///@notice transfer is not allowed.
    function _transfer(address, address, uint256) internal pure override {
        require(false, "transfer not allowed");
    }

    ///@notice get the details of the lock of a user.
    function getLockDetails(address _user, uint256 lockId) external view override returns (EsPegLock memory) {
        return lockUpDetails[_user][lockId];
    }

    ///@notice an array of all lockers.
    function getAllUsers() external view override returns (address[] memory) {
        return allUsers;
    }
}