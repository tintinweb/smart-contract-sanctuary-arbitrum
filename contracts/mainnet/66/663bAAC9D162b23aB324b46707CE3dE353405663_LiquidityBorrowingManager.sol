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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: SAL-1.0
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TransferHelper } from "../libraries/TransferHelper.sol";
import { IUniswapV3Pool } from "../interfaces/IUniswapV3Pool.sol";
import { SafeCast } from "../vendor0.8/uniswap/SafeCast.sol";
import "../libraries/ExternalCall.sol";
import "../libraries/ErrLib.sol";

abstract contract ApproveSwapAndPay {
    using SafeCast for uint256;
    using TransferHelper for address;
    using { ExternalCall._patchAmountAndCall } for address;
    using { ExternalCall._readFirstBytes4 } for bytes;
    using { ErrLib.revertError } for bool;

    /// @notice Struct representing the parameters for a Uniswap V3 exact input swap.
    struct v3SwapExactInputParams {
        /// @dev The fee tier to be used for the swap.
        uint24 fee;
        /// @dev The address of the token to be swapped from.
        address tokenIn;
        /// @dev The address of the token to be swapped to.
        address tokenOut;
        /// @dev The amount of `tokenIn` to be swapped.
        uint256 amountIn;
    }

    /// @notice Struct to hold parameters for swapping tokens
    struct SwapParams {
        /// @notice Address of the aggregator's router
        address swapTarget;
        /// @notice The index in the `swapData` array where the swap amount in is stored
        uint256 swapAmountInDataIndex;
        /// @notice The maximum gas limit for the swap call
        uint256 maxGasForCall;
        /// @notice The aggregator's data that stores paths and amounts for swapping through
        bytes swapData;
    }

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    address public immutable UNDERLYING_V3_FACTORY_ADDRESS;
    bytes32 public immutable UNDERLYING_V3_POOL_INIT_CODE_HASH;

    ///     swapTarget   => (func.selector => is allowed)
    mapping(address => mapping(bytes4 => bool)) public whitelistedCall;

    error SwapSlippageCheckError(uint256 expectedOut, uint256 receivedOut);

    constructor(
        address _UNDERLYING_V3_FACTORY_ADDRESS,
        bytes32 _UNDERLYING_V3_POOL_INIT_CODE_HASH
    ) {
        UNDERLYING_V3_FACTORY_ADDRESS = _UNDERLYING_V3_FACTORY_ADDRESS;
        UNDERLYING_V3_POOL_INIT_CODE_HASH = _UNDERLYING_V3_POOL_INIT_CODE_HASH;
    }

    /**
     * @dev This internal function attempts to approve a specific amount of tokens for a spender.
     * It performs a call to the `approve` function on the token contract using the provided parameters,
     * and returns a boolean indicating whether the approval was successful or not.
     * @param token The address of the token contract.
     * @param spender The address of the spender.
     * @param amount The amount of tokens to be approved.
     * @return A boolean indicating whether the approval was successful or not.
     */
    function _tryApprove(address token, address spender, uint256 amount) private returns (bool) {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, amount)
        );
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }

    /**
     * @dev This internal function ensures that the allowance for a spender is at least the specified amount.
     * If the current allowance is less than the specified amount, it attempts to approve the maximum possible value,
     * and if that fails, it retries with the maximum possible value minus one. If both attempts fail,
     * it reverts with an error indicating that the approval did not succeed.
     * @param token The address of the token contract.
     * @param spender The address of the spender.
     * @param amount The minimum required allowance.
     */
    function _maxApproveIfNecessary(address token, address spender, uint256 amount) internal {
        if (IERC20(token).allowance(address(this), spender) < amount) {
            if (!_tryApprove(token, spender, type(uint256).max)) {
                if (!_tryApprove(token, spender, type(uint256).max - 1)) {
                    require(_tryApprove(token, spender, 0));
                    if (!_tryApprove(token, spender, type(uint256).max)) {
                        if (!_tryApprove(token, spender, type(uint256).max - 1)) {
                            true.revertError(ErrLib.ErrorCode.ERC20_APPROVE_DID_NOT_SUCCEED);
                        }
                    }
                }
            }
        }
    }

    /**
     * @dev This internal view function retrieves the balance of the contract for a specific token.
     * It performs a staticcall to the `balanceOf` function on the token contract using the provided parameter,
     * and returns the balance as a uint256 value.
     * @param token The address of the token contract.
     * @return balance The balance of the contract for the specified token.
     */
    function _getBalance(address token) internal view returns (uint256 balance) {
        balance = token.getBalance();
    }

    /**
     * @dev Retrieves the balance of two tokens in the contract.
     * @param tokenA The address of the first token.
     * @param tokenB The address of the second token.
     * @return balanceA The balance of the first token in the contract.
     * @return balanceB The balance of the second token in the contract.
     */
    function _getPairBalance(
        address tokenA,
        address tokenB
    ) internal view returns (uint256 balanceA, uint256 balanceB) {
        balanceA = tokenA.getBalance();
        balanceB = tokenB.getBalance();
    }

    /**
     * @dev Executes a swap between two tokens using an external contract.
     * @param tokenIn The address of the token to be swapped.
     * @param tokenOut The address of the token to receive in the swap.
     * @param externalSwap The swap parameters from the external contract.
     * @param amountIn The amount of `tokenIn` to be swapped.
     * @param amountOutMin The minimum amount of `tokenOut` expected to receive from the swap.
     * @return amountOut The actual amount of `tokenOut` received from the swap.
     * @notice This function will revert if the swap target is not approved or the resulting amountOut
     * is zero or below the specified minimum amountOut.
     */
    function _patchAmountsAndCallSwap(
        address tokenIn,
        address tokenOut,
        SwapParams calldata externalSwap,
        uint256 amountIn,
        uint256 amountOutMin
    ) internal returns (uint256 amountOut) {
        bytes4 funcSelector = externalSwap.swapData._readFirstBytes4();
        // Verifying if the swap target is whitelisted for the specified function selector
        (!whitelistedCall[externalSwap.swapTarget][funcSelector]).revertError(
            ErrLib.ErrorCode.SWAP_TARGET_NOT_APPROVED
        );
        // Maximizing approval if necessary
        _maxApproveIfNecessary(tokenIn, externalSwap.swapTarget, amountIn);
        uint256 balanceOutBefore = _getBalance(tokenOut);
        (externalSwap.swapAmountInDataIndex > externalSwap.swapData.length / 0x20).revertError(
            ErrLib.ErrorCode.INVALID_SWAP_DATA_INDEX
        );
        // Patching the amount and calling the external swap
        bool success = externalSwap.swapTarget._patchAmountAndCall(
            externalSwap.swapData,
            externalSwap.maxGasForCall,
            externalSwap.swapAmountInDataIndex,
            amountIn
        );
        (!success).revertError(ErrLib.ErrorCode.INVALID_SWAP);
        // Calculating the actual amount of output tokens received
        amountOut = _getBalance(tokenOut) - balanceOutBefore;
        // Checking if the received amount satisfies the minimum requirement
        if (amountOut < amountOutMin) {
            revert SwapSlippageCheckError(amountOutMin, amountOut);
        }
    }

    /**
     * @dev Transfers a specified amount of tokens from the `payer` to the `recipient`.
     * @param token The address of the token to be transferred.
     * @param payer The address from which the tokens will be transferred.
     * @param recipient The address that will receive the tokens.
     * @param value The amount of tokens to be transferred.
     * @notice If the specified `value` is greater than zero, this function will transfer the tokens either by calling `safeTransfer`
     * if the `payer` is equal to `address(this)`, or by calling `safeTransferFrom` otherwise.
     */
    function _pay(address token, address payer, address recipient, uint256 value) internal {
        if (value > 0) {
            if (payer == address(this)) {
                token.safeTransfer(recipient, value);
            } else {
                token.safeTransferFrom(payer, recipient, value);
            }
        }
    }

    /**
     * @dev Performs a token swap using Uniswap V3 with exact input.
     * @param params The struct containing all swap parameters.
     * @return amountOut The amount of tokens received as output from the swap.
     * @notice This internal function swaps the exact amount of `params.amountIn` tokens from `params.tokenIn` to `params.tokenOut`.
     * The swapped amount is calculated based on the current pool ratio between `params.tokenIn` and `params.tokenOut`.
     */
    function _v3SwapExactInput(
        v3SwapExactInputParams memory params
    ) internal returns (uint256 amountOut) {
        // Determine if tokenIn has a 0th token
        bool zeroForTokenIn = params.tokenIn < params.tokenOut;
        // Compute the address of the Uniswap V3 pool based on tokenIn, tokenOut, and fee
        // Call the swap function on the Uniswap V3 pool contract
        (int256 amount0Delta, int256 amount1Delta) = IUniswapV3Pool(
            computePoolAddress(params.tokenIn, params.tokenOut, params.fee)
        ).swap(
                address(this), //recipient
                zeroForTokenIn,
                params.amountIn.toInt256(),
                zeroForTokenIn ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
                abi.encode(params.fee, params.tokenIn, params.tokenOut)
            );
        // Calculate the actual amount of output tokens received
        amountOut = uint256(-(zeroForTokenIn ? amount1Delta : amount0Delta));
    }

    /**
     * @dev Callback function invoked by Uniswap V3 swap.
     *
     * This function is called when a swap is executed on a Uniswap V3 pool. It performs the necessary validations
     * and payment processing.
     *
     * Requirements:
     * - The swap must not entirely fall within 0-liquidity regions, as it is not supported.
     * - The caller must be the expected Uniswap V3 pool contract.
     *
     * @param amount0Delta The change in token0 balance resulting from the swap.
     * @param amount1Delta The change in token1 balance resulting from the swap.
     * @param data Additional data required for processing the swap, encoded as `(uint24, address, address)`.
     */
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        (amount0Delta <= 0 && amount1Delta <= 0).revertError(ErrLib.ErrorCode.INVALID_SWAP); // swaps entirely within 0-liquidity regions are not supported

        (uint24 fee, address tokenIn, address tokenOut) = abi.decode(
            data,
            (uint24, address, address)
        );
        (computePoolAddress(tokenIn, tokenOut, fee) != msg.sender).revertError(
            ErrLib.ErrorCode.INVALID_CALLER
        );
        uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
        _pay(tokenIn, address(this), msg.sender, amountToPay);
    }

    /**
     * @dev Computes the address of a Uniswap V3 pool based on the provided parameters.
     *
     * This function calculates the address of a Uniswap V3 pool contract using the token addresses and fee.
     * It follows the same logic as Uniswap's pool initialization process.
     *
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param fee The fee level of the pool.
     * @return pool The computed address of the Uniswap V3 pool.
     */
    function computePoolAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (address pool) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            UNDERLYING_V3_FACTORY_ADDRESS,
                            keccak256(abi.encode(tokenA, tokenB, fee)),
                            UNDERLYING_V3_POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: SAL-1.0
pragma solidity 0.8.21;
import "../vendor0.8/uniswap/FullMath.sol";
import "../libraries/Keys.sol";
import { Constants } from "../libraries/Constants.sol";

abstract contract DailyRateAndCollateral {
    /**
     * @dev Struct representing information about a token.
     * @param latestUpTimestamp The timestamp of the latest update for the token information.
     * @param accLoanRatePerSeconds The accumulated loan rate per second for the token.
     * @param currentDailyRate The current daily loan rate for the token.
     * @param totalBorrowed The total amount borrowed for the token.
     * @param entranceFeeBP The entrance fee in basis points for the token.
     */
    struct TokenInfo {
        uint32 latestUpTimestamp;
        uint256 accLoanRatePerSeconds;
        uint256 currentDailyRate;
        uint256 totalBorrowed;
        uint256 entranceFeeBP;
    }

    /// pairKey => TokenInfo
    mapping(bytes32 => TokenInfo) public holdTokenInfo;

    function _checkEntranceFee(uint256 entranceFeeBP) internal pure returns (uint256) {
        if (entranceFeeBP == 0) {
            entranceFeeBP = Constants.DEFAULT_ENTRANCE_FEE_BPS;
        } else if (entranceFeeBP == 1) {
            // To disable entry fees, set it to one
            entranceFeeBP = 0;
        }
        return entranceFeeBP;
    }

    /**
     * @notice This internal view function retrieves the current daily rate for the hold token specified by `holdToken`
     * in relation to the sale token specified by `saleToken`. It also returns detailed information about the hold token rate stored
     * in the `holdTokenInfo` mapping. If the rate is not set, it defaults to `Constants.DEFAULT_DAILY_RATE`. If there are any existing
     * borrowings for the hold token, the accumulated loan rate per second is updated based on the time difference since the last update and the
     * current daily rate. The latest update timestamp is also recorded for future calculations.
     * @param saleToken The address of the sale token in the pair.
     * @param holdToken The address of the hold token in the pair.
     * @return holdTokenRateInfo The struct containing information about the hold token rate.
     */
    function _getHoldTokenInfo(
        address saleToken,
        address holdToken
    ) internal view returns (TokenInfo memory) {
        (, TokenInfo memory holdTokenRateInfo) = _getHTInfo(saleToken, holdToken);
        holdTokenRateInfo.entranceFeeBP = _checkEntranceFee(holdTokenRateInfo.entranceFeeBP);
        return holdTokenRateInfo;
    }

    /**
     * @notice This internal function updates the hold token rate information for the pair of sale token specified by `saleToken`
     * and hold token specified by `holdToken`. It retrieves the existing hold token rate information from the `holdTokenInfo` mapping,
     * including the current daily rate. If the current daily rate is not set, it defaults to `Constants.DEFAULT_DAILY_RATE`.
     * If there are any existing borrowings for the hold token, the accumulated loan rate per second is updated based on the time
     * difference since the last update and the current daily rate. Finally, the latest update timestamp is recorded for future calculations.
     * @param saleToken The address of the sale token in the pair.
     * @param holdToken The address of the hold token in the pair.
     * @return currentDailyRate The updated current daily rate for the hold token.
     * @return holdTokenRateInfo The struct containing the updated hold token rate information.
     */
    function _updateHoldTokenRateInfo(
        address saleToken,
        address holdToken
    ) internal returns (uint256, TokenInfo storage) {
        (bytes32 key, TokenInfo memory info) = _getHTInfo(saleToken, holdToken);
        TokenInfo storage holdTokenRateInfo = holdTokenInfo[key];
        holdTokenRateInfo.accLoanRatePerSeconds = info.accLoanRatePerSeconds;
        holdTokenRateInfo.latestUpTimestamp = info.latestUpTimestamp;
        return (info.currentDailyRate, holdTokenRateInfo);
    }

    /**
     * @notice This internal function calculates the collateral balance and current fees.
     * If the `borrowedAmount` is greater than 0, it calculates the fees based on the difference between the current accumulated
     * loan rate per second (`accLoanRatePerSeconds`) and the accumulated loan rate per share at the time of borrowing (`borrowingAccLoanRatePerShare`).
     * The fees are calculated using the FullMath library's `mulDivRoundingUp()` function, rounding up the result to the nearest integer.
     * The collateral balance is then calculated by subtracting the fees from the daily rate collateral at the time of borrowing (`borrowingDailyRateCollateral`).
     * Both the collateral balance and fees are returned as the function's output.
     * @param borrowedAmount The amount borrowed.
     * @param borrowingAccLoanRatePerShare The accumulated loan rate per share at the time of borrowing.
     * @param borrowingDailyRateCollateral The daily rate collateral at the time of borrowing.
     * @param accLoanRatePerSeconds The current accumulated loan rate per second.
     * @return collateralBalance The calculated collateral balance after deducting fees.
     * @return currentFees The calculated fees for the borrowing operation.
     */
    function _calculateCollateralBalance(
        uint256 borrowedAmount,
        uint256 borrowingAccLoanRatePerShare,
        uint256 borrowingDailyRateCollateral,
        uint256 accLoanRatePerSeconds
    ) internal pure returns (int256 collateralBalance, uint256 currentFees) {
        if (borrowedAmount > 0) {
            currentFees = FullMath.mulDivRoundingUp(
                borrowedAmount,
                accLoanRatePerSeconds - borrowingAccLoanRatePerShare,
                Constants.BP
            );
            collateralBalance = int256(borrowingDailyRateCollateral) - int256(currentFees);
        }
    }

    function _getHTInfo(
        address saleToken,
        address holdToken
    ) private view returns (bytes32 key, TokenInfo memory holdTokenRateInfo) {
        key = Keys.computePairKey(saleToken, holdToken);
        holdTokenRateInfo = holdTokenInfo[key];

        if (holdTokenRateInfo.currentDailyRate == 0) {
            holdTokenRateInfo.currentDailyRate = Constants.DEFAULT_DAILY_RATE;
        }
        if (holdTokenRateInfo.totalBorrowed > 0) {
            uint256 timeWeightedRate = (uint32(block.timestamp) -
                holdTokenRateInfo.latestUpTimestamp) * holdTokenRateInfo.currentDailyRate;
            holdTokenRateInfo.accLoanRatePerSeconds +=
                (timeWeightedRate * Constants.COLLATERAL_BALANCE_PRECISION) /
                1 days;
        }

        holdTokenRateInfo.latestUpTimestamp = uint32(block.timestamp);
    }
}

// SPDX-License-Identifier: SAL-1.0
pragma solidity 0.8.21;
import "../vendor0.8/uniswap/LiquidityAmounts.sol";
import "../vendor0.8/uniswap/TickMath.sol";
import "../interfaces/INonfungiblePositionManager.sol";
import { CalculateExactZapInParams, ILightQuoterV3 } from "../interfaces/ILightQuoterV3.sol";
import "./ApproveSwapAndPay.sol";
import "../Vault.sol";
import { Constants } from "../libraries/Constants.sol";
import { ErrLib } from "../libraries/ErrLib.sol";
import { AmountsLiquidity } from "../libraries/AmountsLiquidity.sol";

// import "hardhat/console.sol";

abstract contract LiquidityManager is ApproveSwapAndPay {
    using { ErrLib.revertError } for bool;
    /**
     * @notice Represents information about a loan.
     * @dev This struct is used to store liquidity and tokenId for a loan.
     * @param liquidity The amount of liquidity for the loan represented by a uint128 value.
     * @param tokenId The token ID associated with the loan represented by a uint256 value.
     */
    struct LoanInfo {
        uint128 liquidity;
        uint256 tokenId;
    }

    struct Amounts {
        uint256 amount0;
        uint256 amount1;
    }
    /**
     * @notice Contains parameters for restoring liquidity.
     * @dev This struct is used to store various parameters required for restoring liquidity.
     * @param zeroForSaleToken A boolean value indicating whether the token for sale is the 0th token or not.
     * @param fee The fee associated with the internal swap pool is represented by a uint24 value.
     * @param slippageBP1000 The slippage in basis points (BP) represented by a uint256 value.
     * @param totalfeesOwed The total fees owed represented by a uint256 value.
     * @param totalBorrowedAmount The total borrowed amount represented by a uint256 value.
     */
    struct RestoreLiquidityParams {
        bool zeroForSaleToken;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        uint256 totalfeesOwed;
        uint256 totalBorrowedAmount;
    }
    /**
     * @title NFT Position Cache Data Structure
     * @notice This struct holds the cache data necessary for restoring liquidity to an NFT position.
     * @dev Stores essential parameters for an NFT representing a position in a Uniswap-like pool.
     * @param tickLower The lower bound of the liquidity position's price range, represented as an int24.
     * @param tickUpper The upper bound of the liquidity position's price range, represented as an int24.
     * @param fee The fee tier of the Uniswap pool in which this liquidity will be restored, represented as a uint24.
     * @param liquidity The amount of NFT Position liquidity.
     * @param saleToken The ERC-20 sale token.
     * @param holdToken The ERC-20 hold token.
     * @param operator The address of the operator who is permitted to restore liquidity and manage this position.
     * @param holdTokenDebt The outstanding debt of the hold token that needs to be repaid when liquidity is restored, represented as a uint256.
     */
    struct NftPositionCache {
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
        uint128 liquidity;
        address saleToken;
        address holdToken;
        address operator;
        uint256 holdTokenDebt;
    }
    /**
     * @notice The address of the vault contract.
     */
    address public immutable VAULT_ADDRESS;
    /**
     * @notice The Nonfungible Position Manager contract.
     */
    INonfungiblePositionManager public immutable underlyingPositionManager;
    /**
     * @notice The Quoter contract.
     */
    ILightQuoterV3 public immutable lightQuoterV3;

    ///  msg.sender => token => FeesAmt
    mapping(address => mapping(address => uint256)) internal loansFeesInfo;

    /**
     * @dev Contract constructor.
     * @param _underlyingPositionManagerAddress Address of the underlying position manager contract.
     * @param _lightQuoterV3 Address of the LightQuoterV3 contract.
     * @param _underlyingV3Factory Address of the underlying V3 factory contract.
     * @param _underlyingV3PoolInitCodeHash The init code hash of the underlying V3 pool.
     */
    constructor(
        address _underlyingPositionManagerAddress,
        address _lightQuoterV3,
        address _underlyingV3Factory,
        bytes32 _underlyingV3PoolInitCodeHash
    ) ApproveSwapAndPay(_underlyingV3Factory, _underlyingV3PoolInitCodeHash) {
        // Assign the underlying position manager contract address
        underlyingPositionManager = INonfungiblePositionManager(_underlyingPositionManagerAddress);
        // Assign the quoter contract address
        lightQuoterV3 = ILightQuoterV3(_lightQuoterV3);
        // Generate a unique salt for the new Vault contract
        bytes32 salt = keccak256(abi.encode(block.timestamp, address(this)));
        // Deploy a new Vault contract using the generated salt and assign its address to VAULT_ADDRESS
        VAULT_ADDRESS = address(new Vault{ salt: salt }());
    }

    error InvalidBorrowedLiquidityAmount(
        uint256 tokenId,
        uint128 posLiquidity,
        uint128 minLiquidityAmt,
        uint128 liquidity
    );
    error InvalidTokens(uint256 tokenId);
    error NotApproved(uint256 tokenId);
    error InvalidRestoredLiquidity(
        uint256 tokenId,
        uint128 borrowedLiquidity,
        uint128 restoredLiquidity,
        uint256 amount0,
        uint256 amount1,
        uint256 holdTokentBalance,
        uint256 saleTokenBalance
    );

    /**
     * @dev Calculates the borrowed amount from a pool's single side position, rounding up if necessary.
     * @param zeroForSaleToken A boolean value indicating whether the token for sale is the 0th token or not.
     * @param tickLower The lower tick value of the position range.
     * @param tickUpper The upper tick value of the position range.
     * @param liquidity The liquidity of the position.
     * @return borrowedAmount The calculated borrowed amount.
     */
    function _getSingleSideRoundUpBorrowedAmount(
        bool zeroForSaleToken,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) private pure returns (uint256 borrowedAmount) {
        borrowedAmount = (
            zeroForSaleToken
                ? AmountsLiquidity.getAmount1RoundingUpForLiquidity(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidity
                )
                : AmountsLiquidity.getAmount0RoundingUpForLiquidity(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidity
                )
        );
    }

    /**
     * @dev Calculates the minimum liquidity amount for a given tick range.
     * @param tickLower The lower tick of the range.
     * @param tickUpper The upper tick of the range.
     * @return minLiquidity The minimum liquidity amount.
     */
    function _getMinLiquidityAmt(
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (uint128 minLiquidity) {
        uint128 liquidity0 = LiquidityAmounts.getLiquidityForAmount0(
            TickMath.getSqrtRatioAtTick(tickUpper - 1),
            TickMath.getSqrtRatioAtTick(tickUpper),
            Constants.MINIMUM_EXTRACTED_AMOUNT
        );
        uint128 liquidity1 = LiquidityAmounts.getLiquidityForAmount1(
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickLower + 1),
            Constants.MINIMUM_EXTRACTED_AMOUNT
        );
        minLiquidity = liquidity0 > liquidity1 ? liquidity0 : liquidity1;
    }

    /**
     * @notice This function extracts liquidity from provided loans and calculates the total borrowed amount.
     * @dev Iterates through an array of LoanInfo structs, validates loan parameters, and accumulates borrowed amounts.
     * @param zeroForSaleToken A boolean indicating whether the token for sale is the 0th token in the pair.
     * @param saleToken The address of the token being sold in the trading pair.
     * @param holdToken The address of the token being held in the trading pair.
     * @param loans An array of LoanInfo struct instances, each representing a loan from which to extract liquidity.
     * @return borrowedAmount The total amount of the holdToken that has been borrowed across all provided loans.
     */
    function _extractLiquidity(
        bool zeroForSaleToken,
        address saleToken,
        address holdToken,
        LoanInfo[] memory loans
    ) internal returns (uint256 borrowedAmount) {
        NftPositionCache memory cache;

        for (uint256 i; i < loans.length; ) {
            LoanInfo memory loan = loans[i];
            // Extract position-related details
            _upNftPositionCache(zeroForSaleToken, loan, cache);

            // Check operator approval
            if (cache.operator != address(this)) {
                revert NotApproved(loan.tokenId);
            }
            // Check token validity
            if (cache.saleToken != saleToken || cache.holdToken != holdToken) {
                revert InvalidTokens(loan.tokenId);
            }

            // Check borrowed liquidity validity
            uint128 minLiquidityAmt = _getMinLiquidityAmt(cache.tickLower, cache.tickUpper);
            if (loan.liquidity > cache.liquidity || loan.liquidity < minLiquidityAmt) {
                revert InvalidBorrowedLiquidityAmount(
                    loan.tokenId,
                    cache.liquidity,
                    minLiquidityAmt,
                    loan.liquidity
                );
            }

            // Calculate borrowed amount
            borrowedAmount += cache.holdTokenDebt;
            // Decrease liquidity and move to the next loan
            _decreaseLiquidity(loan.tokenId, loan.liquidity);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev This function is used to simulate a swap operation.
     *
     * It quotes the exact input single for the swap using the `lightQuoterV3` contract.
     *
     * @param fee The pool's fee in hundredths of a bip, i.e. 1e-6
     * @param tokenIn The address of the token being used as input for the swap.
     * @param tokenOut The address of the token being received as output from the swap.
     * @param amountIn The amount of tokenIn to be used as input for the swap.
     *
     * @return sqrtPriceX96After The square root price after the swap.
     * @return amountOut The amount of tokenOut received as output from the swap.
     */
    function _simulateSwap(
        bool zeroForIn,
        uint24 fee,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (uint160 sqrtPriceX96After, uint256 amountOut) {
        // Quote exact input single for swap
        address pool = computePoolAddress(tokenIn, tokenOut, fee);
        (sqrtPriceX96After, amountOut) = lightQuoterV3.quoteExactInputSingle(
            zeroForIn,
            pool,
            0, //sqrtPriceLimitX96
            amountIn
        );
    }

    function _calculateAmountsToSwap(
        bool zeroForIn,
        uint160 currentSqrtPriceX96,
        uint128 liquidity,
        NftPositionCache memory cache,
        uint256 tokenOutBalance
    ) private view returns (uint160 sqrtPriceX96After, uint256 amountIn, Amounts memory amounts) {
        address pool = computePoolAddress(cache.holdToken, cache.saleToken, cache.fee);

        (, sqrtPriceX96After, amountIn, , amounts.amount0, amounts.amount1) = lightQuoterV3
            .calculateExactZapIn(
                CalculateExactZapInParams({
                    swapPool: pool,
                    zeroForIn: zeroForIn,
                    sqrtPriceX96: currentSqrtPriceX96,
                    tickLower: cache.tickLower,
                    tickUpper: cache.tickUpper,
                    liquidityExactAmount: liquidity,
                    tokenInBalance: cache.holdTokenDebt,
                    tokenOutBalance: tokenOutBalance
                })
            );
    }

    /**
     * @dev This function is used to prevent front-running during a swap.
     *
     * We do not check slippage during a swap as we need to restore liquidity anyway despite the losses,
     * so we only check the initial price state in the pool to prevent price manipulation.
     *
     * When liquidity is restored, a hold token is sold therefore,
     * - If `zeroForSaleToken` is `false`, the current `sqrtPrice` cannot be less than `sqrtPriceLimitX96`.
     * - If `zeroForSaleToken` is `true`, the current `sqrtPrice` cannot be greater than `sqrtPriceLimitX96`.
     *
     * @param zeroForSaleToken A boolean indicating whether the sale token is zero or not.
     * @param fee The fee for the swap.
     * @param sqrtPriceLimitX96 The square root price limit for the swap.
     * @param saleToken The address of the token being sold.
     * @param holdToken The address of the token being held.
     */
    function _frontRunningAttackPrevent(
        bool zeroForSaleToken,
        uint24 fee,
        uint160 sqrtPriceLimitX96,
        address saleToken,
        address holdToken
    ) internal view {
        uint160 sqrtPriceX96 = _getCurrentSqrtPriceX96(zeroForSaleToken, saleToken, holdToken, fee);
        (zeroForSaleToken ? sqrtPriceX96 > sqrtPriceLimitX96 : sqrtPriceX96 < sqrtPriceLimitX96)
            .revertError(ErrLib.ErrorCode.UNACCEPTABLE_SQRT_PRICE);
    }

    /**
     * @dev Restores liquidity from loans.
     * @param params The RestoreLiquidityParams struct containing restoration parameters.
     * @param externalSwap The SwapParams struct containing external swap details.
     * @param loans An array of LoanInfo struct instances containing loan information.
     */
    function _restoreLiquidity(
        // Create a cache struct to store temporary data
        RestoreLiquidityParams memory params,
        SwapParams calldata externalSwap,
        LoanInfo[] memory loans
    ) internal {
        NftPositionCache memory cache;

        for (uint256 i; i < loans.length; ) {
            // Update the cache for the current loan
            LoanInfo memory loan = loans[i];
            // Get the owner of the Nonfungible Position Manager token by its tokenId
            address creditor = _getOwnerOf(loan.tokenId);
            // Check that the token is not burned
            if (creditor != address(0)) {
                _upNftPositionCache(params.zeroForSaleToken, loan, cache);

                // Calculate the square root price using `_getCurrentSqrtPriceX96` function
                uint160 sqrtPriceX96 = _getCurrentSqrtPriceX96(
                    params.zeroForSaleToken,
                    cache.saleToken,
                    cache.holdToken,
                    cache.fee
                );
                uint256 saleTokenBalance = _getBalance(cache.saleToken);
                // Calculate the hold token amount to be used for swapping
                (uint256 holdTokenAmountIn, Amounts memory amounts) = _getHoldTokenAmountIn(
                    params.zeroForSaleToken,
                    cache.tickLower,
                    cache.tickUpper,
                    sqrtPriceX96,
                    loan.liquidity,
                    cache.holdTokenDebt,
                    saleTokenBalance
                );

                if (holdTokenAmountIn > 0) {
                    if (params.sqrtPriceLimitX96 != 0) {
                        _frontRunningAttackPrevent(
                            params.zeroForSaleToken,
                            params.fee,
                            params.sqrtPriceLimitX96,
                            cache.saleToken,
                            cache.holdToken
                        );
                    }
                    // Perform external swap if external swap target is provided
                    if (externalSwap.swapTarget != address(0)) {
                        uint256 saleTokenAmountOut;
                        if (params.sqrtPriceLimitX96 != 0) {
                            (, saleTokenAmountOut) = _simulateSwap(
                                !params.zeroForSaleToken, // holdToken is tokenIn
                                params.fee,
                                cache.holdToken,
                                cache.saleToken,
                                holdTokenAmountIn
                            );
                        }
                        _patchAmountsAndCallSwap(
                            cache.holdToken,
                            cache.saleToken,
                            externalSwap,
                            holdTokenAmountIn,
                            // The minimum amount out should not be less than with an internal pool swap.
                            // checking only once during the first swap when params.sqrtPriceLimitX96 != 0
                            saleTokenAmountOut
                        );
                    } else {
                        //  The internal swap in the same pool in which liquidity is restored.
                        if (params.fee == cache.fee) {
                            (sqrtPriceX96, holdTokenAmountIn, amounts) = _calculateAmountsToSwap(
                                !params.zeroForSaleToken,
                                sqrtPriceX96,
                                loan.liquidity,
                                cache,
                                saleTokenBalance
                            );
                        }

                        // Perform v3 swap exact input and update sqrtPriceX96
                        _v3SwapExactInput(
                            v3SwapExactInputParams({
                                fee: params.fee,
                                tokenIn: cache.holdToken,
                                tokenOut: cache.saleToken,
                                amountIn: holdTokenAmountIn
                            })
                        );
                    }
                    // the price manipulation check is carried out only once
                    params.sqrtPriceLimitX96 = 0;
                }

                // Increase liquidity and transfer liquidity owner reward
                _increaseLiquidity(
                    cache.saleToken,
                    cache.holdToken,
                    loan,
                    amounts.amount0,
                    amounts.amount1
                );
                uint256 liquidityOwnerReward = FullMath.mulDiv(
                    params.totalfeesOwed,
                    cache.holdTokenDebt,
                    params.totalBorrowedAmount
                );

                loansFeesInfo[creditor][cache.holdToken] += liquidityOwnerReward;
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Retrieves the owner of a token without causing a revert if token not exist.
     * @param tokenId The identifier of the token.
     * @return tokenOwner The address of the token owner.
     */
    function _getOwnerOf(uint256 tokenId) internal view returns (address tokenOwner) {
        bytes memory callData = abi.encodeWithSelector(
            underlyingPositionManager.ownerOf.selector,
            tokenId
        );
        (bool success, bytes memory data) = address(underlyingPositionManager).staticcall(callData);
        if (success && data.length >= 32) {
            tokenOwner = abi.decode(data, (address));
        }
    }

    /**
     * @dev Retrieves the current square root price in X96 representation.
     * @param zeroForA Flag indicating whether to treat the tokenA as the 0th token or not.
     * @param tokenA The address of token A.
     * @param tokenB The address of token B.
     * @param fee The fee associated with the Uniswap V3 pool.
     * @return sqrtPriceX96 The current square root price in X96 representation.
     */
    function _getCurrentSqrtPriceX96(
        bool zeroForA,
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (uint160 sqrtPriceX96) {
        if (!zeroForA) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        address poolAddress = computePoolAddress(tokenA, tokenB, fee);
        (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(poolAddress).slot0();
    }

    /**
     * @dev Decreases the liquidity of a position by removing tokens.
     * @param tokenId The ID of the position token.
     * @param liquidity The amount of liquidity to be removed.
     */
    function _decreaseLiquidity(uint256 tokenId, uint128 liquidity) private {
        // Call the decreaseLiquidity function of underlyingPositionManager contract
        // with DecreaseLiquidityParams struct as argument
        (uint256 amount0, uint256 amount1) = underlyingPositionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
        // Call the collect function of underlyingPositionManager contract
        // with CollectParams struct as argument
        (amount0, amount1) = underlyingPositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: uint128(amount0),
                amount1Max: uint128(amount1)
            })
        );
    }

    /**
     * @dev Increases the liquidity of a position by providing additional tokens.
     * @param saleToken The address of the sale token.
     * @param holdToken The address of the hold token.
     * @param loan An instance of LoanInfo memory struct containing loan details.
     * @param amount0 The amount of token0 to be added to the liquidity.
     * @param amount1 The amount of token1 to be added to the liquidity.
     */
    function _increaseLiquidity(
        address saleToken,
        address holdToken,
        LoanInfo memory loan,
        uint256 amount0,
        uint256 amount1
    ) private {
        // Call the increaseLiquidity function of underlyingPositionManager contract
        // with IncreaseLiquidityParams struct as argument
        (uint128 restoredLiquidity, , ) = underlyingPositionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: loan.tokenId,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
        // Check if the restored liquidity is less than the loan liquidity amount
        // If true, revert with InvalidRestoredLiquidity exception
        if (restoredLiquidity < loan.liquidity) {
            // Get the balance of holdToken and saleToken
            (uint256 holdTokentBalance, uint256 saleTokenBalance) = _getPairBalance(
                holdToken,
                saleToken
            );

            revert InvalidRestoredLiquidity(
                loan.tokenId,
                loan.liquidity,
                restoredLiquidity,
                amount0,
                amount1,
                holdTokentBalance,
                saleTokenBalance
            );
        }
    }

    /**
     * @notice Calculates the required hold token amount and expected amounts of token0 and token1 for providing liquidity.
     * @dev This function uses the `AmountsLiquidity` library to determine the token amounts based on provided liquidity parameters.
     * @param zeroForSaleToken Indicates if the sale token is token0 (`true`) or token1 (`false`)
     * @param tickLower The lower tick of the liquidity price range
     * @param tickUpper The upper tick of the liquidity price range
     * @param sqrtPriceX96 The square root of the current price ratio between tokens, scaled by 2^96
     * @param liquidity The desired amount of liquidity to provide
     * @param holdTokenDebt The debt amount in terms of the hold token
     * @param saleTokenBalance The balance amount of the sale token
     * @return holdTokenAmountIn The calculated required amount of hold token necessary to achieve the desired liquidity
     * @return amounts A struct containing the calculated amounts of token0 (`amounts.amount0`) and token1 (`amounts.amount1`) for the specified liquidity range
     */
    function _getHoldTokenAmountIn(
        bool zeroForSaleToken,
        int24 tickLower,
        int24 tickUpper,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 holdTokenDebt,
        uint256 saleTokenBalance
    ) private pure returns (uint256 holdTokenAmountIn, Amounts memory amounts) {
        // Call getAmountsForLiquidity function from AmountsLiquidity library
        // to get the amounts of token0 and token1 for a given liquidity position
        (amounts.amount0, amounts.amount1) = AmountsLiquidity.getAmountsRoundingUpForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            liquidity
        );

        if (saleTokenBalance < (zeroForSaleToken ? amounts.amount0 : amounts.amount1)) {
            // Calculate the holdTokenAmountIn based on the zeroForSaleToken flag
            holdTokenAmountIn = zeroForSaleToken
                ? holdTokenDebt - amounts.amount1
                : holdTokenDebt - amounts.amount0;
        }
    }

    /**
     * @dev Updates the NftPositionCache struct with data from the underlyingPositionManager contract.
     * @param zeroForSaleToken A boolean value indicating whether the token for sale is the 0th token or not.
     * @param loan The LoanInfo struct containing loan details.
     * @param cache The NftPositionCache struct to be updated.
     */
    function _upNftPositionCache(
        bool zeroForSaleToken,
        LoanInfo memory loan,
        NftPositionCache memory cache
    ) internal view {
        // Get the positions data from `PositionManager` and store it in the cache variables
        (
            ,
            cache.operator,
            cache.saleToken,
            cache.holdToken,
            cache.fee,
            cache.tickLower,
            cache.tickUpper,
            cache.liquidity,
            ,
            ,
            ,

        ) = underlyingPositionManager.positions(loan.tokenId);
        // Swap saleToken and holdToken if zeroForSaleToken is false
        if (!zeroForSaleToken) {
            (cache.saleToken, cache.holdToken) = (cache.holdToken, cache.saleToken);
        }
        // Calculate the holdTokenDebt using
        cache.holdTokenDebt = _getSingleSideRoundUpBorrowedAmount(
            zeroForSaleToken,
            cache.tickLower,
            cache.tickUpper,
            loan.liquidity
        );
    }
}

// SPDX-License-Identifier: SAL-1.0
pragma solidity 0.8.21;
import "@openzeppelin/contracts/access/Ownable.sol";
import { Constants } from "../libraries/Constants.sol";

abstract contract OwnerSettings is Ownable {
    /**
     * @dev Enum representing various items.
     *
     * @param PLATFORM_FEES_BP The percentage of platform fees in basis points.
     * @param DEFAULT_LIQUIDATION_BONUS The default liquidation bonus.
     * @param OPERATOR The operator for operating the daily rate and entrance fee.
     * @param LIQUIDATION_BONUS_FOR_TOKEN The liquidation bonus for a specific token.
     */
    enum ITEM {
        PLATFORM_FEES_BP,
        DEFAULT_LIQUIDATION_BONUS,
        OPERATOR,
        LIQUIDATION_BONUS_FOR_TOKEN
    }
    /**
     * @dev Struct representing liquidation parameters.
     *
     * @param bonusBP The bonus in basis points that will be applied during a liquidation.
     * @param minBonusAmount The minimum amount of bonus that can be applied during a liquidation.
     */
    struct Liquidation {
        uint256 bonusBP;
        uint256 minBonusAmount;
    }
    /**
     * @dev Address of the daily rate operator.
     */
    address public operator;
    /**
     * @dev Platform fees in basis points.
     * 2000 BP represents a 20% fee on the daily rate.
     */
    uint256 public platformFeesBP = 2000;
    /**
     * @dev Default liquidation bonus in basis points.
     * 69 BP represents a 0.69% bonus per extracted liquidity.
     */
    uint256 public dafaultLiquidationBonusBP = 69;
    /**
     * @dev Mapping to store liquidation bonuses for each token address.
     * The keys are token addresses and values are instances of the `Liquidation` struct.
     */
    mapping(address => Liquidation) public liquidationBonusForToken;

    event UpdateSettingsByOwner(ITEM _item, uint256[] values);

    error InvalidSettingsValue(uint256 value);

    constructor() {
        operator = msg.sender;
    }

    /**
     * @notice This external function is used to update the settings for a particular item. The function requires two parameters: `_item`,
     * which is the item to be updated, and `values`, which is an array of values containing the new settings.
     * Only the owner of the contract has the permission to call this function.
     * @dev Can only be called by the owner of the contract.
     * @param _item The item to update the settings for.
     * @param values An array of values containing the new settings.
     */
    function updateSettings(ITEM _item, uint256[] calldata values) external onlyOwner {
        if (_item == ITEM.LIQUIDATION_BONUS_FOR_TOKEN) {
            require(values.length == 3);
            if (values[1] > Constants.MAX_LIQUIDATION_BONUS) {
                revert InvalidSettingsValue(values[1]);
            }
            if (values[2] == 0) {
                revert InvalidSettingsValue(0);
            }
            liquidationBonusForToken[address(uint160(values[0]))] = Liquidation(
                values[1],
                values[2]
            );
        } else {
            require(values.length == 1);
            if (_item == ITEM.PLATFORM_FEES_BP) {
                if (values[0] > Constants.MAX_PLATFORM_FEE) {
                    revert InvalidSettingsValue(values[0]);
                }
                platformFeesBP = values[0];
            } else if (_item == ITEM.DEFAULT_LIQUIDATION_BONUS) {
                if (values[0] > Constants.MAX_LIQUIDATION_BONUS) {
                    revert InvalidSettingsValue(values[0]);
                }
                dafaultLiquidationBonusBP = values[0];
            } else if (_item == ITEM.OPERATOR) {
                operator = address(uint160(values[0]));
            }
        }
        emit UpdateSettingsByOwner(_item, values);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

/// @title Struct for "Zap In" Calculation Parameters
/// @notice This struct encapsulates the various parameters required for calculating the exact amount of tokens to zap in.
struct CalculateExactZapInParams {
    /// @notice The address of the swap pool where liquidity will be added.
    address swapPool;
    /// @notice A boolean determining which token will be used to add liquidity (true for token0 or false for token1).
    bool zeroForIn;
    /// @notice The square root of the current price in the pool, encoded as a fixed-point number with 96 bits of precision.
    uint160 sqrtPriceX96;
    /// @notice The lower bound of the tick range for the position within the pool.
    int24 tickLower;
    /// @notice The upper bound of the tick range for the position within the pool.
    int24 tickUpper;
    /// @notice The exact amount of liquidity to add to the pool.
    uint128 liquidityExactAmount;
    /// @notice The balance of the token that will be used to add liquidity.
    uint256 tokenInBalance;
    /// @notice The balance of the other token in the pool, not typically used for adding liquidity directly but necessary for calculations.
    uint256 tokenOutBalance;
}

/// @title Light Quoter Interface
interface ILightQuoterV3 {
    /// @notice Calculates parameters related to "zapping in" to a position with an exact amount of liquidity.
    /// @dev Interacts with an on-chain liquidity pool to precisely estimate the amounts in/out to add liquidity.
    ///      This calculation is performed using iterative methods to ensure the exactness of the resulting values.
    ///      It uses the `getSqrtRatioAtTick` method within the loop to determine price bounds.
    ///      This process is designed to avoid failure due to constraints such as limited input or other conditions.
    ///      The number of iterations to reach an accurate result is bounded by a maximum value.
    /// @param params A `CalculateExactZapInParams` struct containing all necessary parameters to perform the calculations.
    ///               This may include details about the liquidity pool, desired position, slippage tolerance, etc.
    /// @return iterations The total number of iterations executed to converge on the precise calculation.
    /// @return sqrtPriceX96After The square root of the price after adding liquidity, adjusted by scaling factor 2^96.
    /// @return swapAmountIn The exact total amount of input tokens required to complete the zap in operation.
    /// @return swapAmountOut The output token amount after swap.
    ///                       This can be used to measure slippage or compare against expected values.
    /// @return amount0 The exact amount of the token0 will be used for "zapping in" to a position.
    /// @return amount1 The exact amount of the token1 will be used for "zapping in" to a position.
    function calculateExactZapIn(
        CalculateExactZapInParams memory params
    )
        external
        view
        returns (
            uint256 iterations,
            uint160 sqrtPriceX96After,
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @notice Quotes the output amount for a given input amount in a single token swap operation.
     * @dev This function prepares a cache object through `_prepareSwapCashe`
     *      and performs the calculation of the swap via `_calcsSwap`.
     * @param zeroForIn A boolean indicating whether the input token is the 0th token (true) or not (false).
     * @param swapPool Address of the swap pool contract used for the trade.
     * @param sqrtPriceLimitX96 The square root price limit for the swap, scaled by 2^96.
     * @param amountIn Amount of input tokens to be swapped.
     * @return sqrtPriceX96After The square root price after the swap, scaled by 2^96.
     * @return amountOut The amount of output tokens that will be received from the swap.
     */
    function quoteExactInputSingle(
        bool zeroForIn,
        address swapPool,
        uint160 sqrtPriceLimitX96,
        uint256 amountIn
    ) external view returns (uint160 sqrtPriceX96After, uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

interface INonfungiblePositionManager {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    /**
     * @notice from IERC721
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoterV2 {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    )
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountIn The desired input amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInputSingle(
        QuoteExactInputSingleParams memory params
    )
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutput(
        bytes memory path,
        uint256 amountOut
    )
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountOut The desired output amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutputSingle(
        QuoteExactOutputSingleParams memory params
    )
        external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: SAL-1.0
pragma solidity 0.8.21;

// Interface for the Vault contract
interface IVault {
    // Function to transfer tokens from the vault to a specified address
    function transferToken(address _token, address _to, uint256 _amount) external;

    // Function to get the balances of multiple tokens
    function getBalances(
        address[] calldata tokens
    ) external view returns (uint256[] memory balances);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import { FullMath } from "../vendor0.8/uniswap/FullMath.sol";
import { FixedPoint96 } from "../vendor0.8/uniswap/FixedPoint96.sol";

library AmountsLiquidity {
    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0RoundingUpForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96)
                (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);

            return
                FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, intermediate);
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1RoundingUpForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return
                FullMath.mulDivRoundingUp(
                    liquidity,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    FixedPoint96.Q96
                );
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsRoundingUpForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0RoundingUpForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0RoundingUpForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1RoundingUpForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1RoundingUpForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: SAL-1.0
pragma solidity 0.8.21;

/// @title Constant state
library Constants {
    uint256 internal constant BP = 10000;
    uint256 internal constant BPS = 1000;
    uint256 internal constant DEFAULT_DAILY_RATE = 10; // 0.1%
    uint256 internal constant MAX_PLATFORM_FEE = 2000; // 20%
    uint256 internal constant MAX_LIQUIDATION_BONUS = 100; // 1%
    uint256 internal constant MAX_DAILY_RATE = 10000; // 100%
    uint256 internal constant MIN_DAILY_RATE = 5; // 0.05 %
    uint256 internal constant MAX_ENTRANCE_FEE_BPS = 1000; // 10%
    uint256 internal constant DEFAULT_ENTRANCE_FEE_BPS = 10; // 0.1%
    uint256 internal constant MAX_NUM_LOANS_PER_POSITION = 7;
    uint256 internal constant COLLATERAL_BALANCE_PRECISION = 1e18;
    uint256 internal constant MINIMUM_AMOUNT = 1000;
    uint256 internal constant MINIMUM_EXTRACTED_AMOUNT = 10;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

library ErrLib {
    enum ErrorCode {
        INVALID_BORROWING_KEY, // 0
        LIQUIDITY_IS_ZERO, // 1
        TOO_BIG_MARGIN_DEPOSIT, // 2
        TOO_OLD_TRANSACTION, // 3
        FORBIDDEN, // 4
        COLLATERAL_AMOUNT_IS_NOT_ENOUGH, // 5
        TOO_MANY_LOANS_PER_POSITION, // 6
        LOANS_IS_EMPTY, // 7
        PRICE_SLIPPAGE_CHECK, // 8
        ERC20_APPROVE_DID_NOT_SUCCEED, // 9
        SWAP_TARGET_NOT_APPROVED, // 10
        INVALID_SWAP, //11
        INVALID_CALLER, //12
        UNEXPECTED_CHANGES, //13
        TOO_BIG_DAILY_RATE, //14
        UNACCEPTABLE_SQRT_PRICE, //15
        INVALID_SWAP_DATA_INDEX, //16
        INTERNAL_SWAP_POOL_FEE_REQUIRED //17
    }

    error RevertErrorCode(ErrorCode code);

    /**
     * @dev Reverts with a custom error message based on the provided condition and error code.
     * @param condition The condition to check for reverting.
     * @param code The ErrorCode representing the specific error.
     */
    function revertError(bool condition, ErrorCode code) internal pure {
        if (condition) {
            revert RevertErrorCode(code);
        }
    }
}

// SPDX-License-Identifier: SAL-1.0
pragma solidity 0.8.21;

library ExternalCall {
    /**
     * @dev Executes a call to the `target` address with the given `data`, gas limit `maxGas`, and optional patching of a swapAmount value.
     * @param target The address of the contract or external function to call.
     * @param data The calldata to include in the call.
     * @param maxGas The maximum amount of gas to be used for the call. If set to 0, it uses the remaining gas.
     * @param swapAmountInDataIndex The index at which to patch the `swapAmountInDataValue` in the calldata.
     * @param swapAmountInDataValue The value to be patched at the specified index in the calldata. Can be 0 to skip patching.
     * @return success A boolean indicating whether the call was successful.
     */
    function _patchAmountAndCall(
        address target,
        bytes calldata data,
        uint256 maxGas,
        uint256 swapAmountInDataIndex,
        uint256 swapAmountInDataValue
    ) internal returns (bool success) {
        if (maxGas == 0) {
            maxGas = gasleft();
        }
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            calldatacopy(ptr, data.offset, data.length)
            if gt(swapAmountInDataValue, 0) {
                mstore(add(add(ptr, 0x24), mul(swapAmountInDataIndex, 0x20)), swapAmountInDataValue)
            }
            success := call(
                maxGas,
                target,
                0, //value
                ptr, //Inputs are stored at location ptr
                data.length,
                0,
                0
            )

            if and(not(success), and(gt(returndatasize(), 0), lt(returndatasize(), 256))) {
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }

            mstore(0x40, add(ptr, data.length)) // Set storage pointer to empty space
        }
    }

    /**
     * @dev Reads the first 4 bytes from the given `swapData` parameter and returns them as a bytes4 value.
     * @param swapData The calldata containing the data to read the first 4 bytes from.
     * @return result The first 4 bytes of the `swapData` as a bytes4 value.
     */
    function _readFirstBytes4(bytes calldata swapData) internal pure returns (bytes4 result) {
        // Read the bytes4 from array memory
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            calldatacopy(ptr, swapData.offset, 32)
            result := mload(ptr)
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(
                result,
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }
        return result;
    }
}

// SPDX-License-Identifier: SAL-1.0
pragma solidity 0.8.21;

library Keys {
    /**
     * @dev Computes the borrowing key based on the borrower's address, sale token address, and hold token address.
     * @param borrower The address of the borrower.
     * @param saleToken The address of the sale token.
     * @param holdToken The address of the hold token.
     * @return The computed borrowing key as a bytes32 value.
     */
    function computeBorrowingKey(
        address borrower,
        address saleToken,
        address holdToken
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(borrower, saleToken, holdToken));
    }

    /**
     * @dev Computes the pair key based on the sale token address and hold token address.
     * @param saleToken The address of the sale token.
     * @param holdToken The address of the hold token.
     * @return The computed pair key as a bytes32 value.
     */
    function computePairKey(address saleToken, address holdToken) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(saleToken, holdToken));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "WL-STF");
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "WL-ST");
    }

    function getBalance(address token) internal view returns (uint256 balance) {
        bytes memory callData = abi.encodeWithSelector(IERC20.balanceOf.selector, address(this));
        (bool success, bytes memory data) = token.staticcall(callData);
        require(success && data.length >= 32);
        balance = abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./interfaces/ILightQuoterV3.sol";
import { IUniswapV3Pool } from "./interfaces/IUniswapV3Pool.sol";
import { SafeCast } from "./vendor0.8/uniswap/SafeCast.sol";
import { Tick } from "./vendor0.8/uniswap/Tick.sol";
import { TickBitmap } from "./vendor0.8/uniswap/TickBitmap.sol";
import { TickMath } from "./vendor0.8/uniswap/TickMath.sol";
import { SwapMath } from "./vendor0.8/uniswap/SwapMath.sol";
import { BitMath } from "./vendor0.8/uniswap/BitMath.sol";
import { AmountsLiquidity } from "./libraries/AmountsLiquidity.sol";

// import "hardhat/console.sol";

contract LightQuoterV3 is ILightQuoterV3 {
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 public constant MAX_ITER = 10;

    struct SwapCache {
        bool zeroForOne;
        uint8 feeProtocol;
        uint128 liquidityStart;
        uint24 fee;
        int24 tickSpacing;
        int24 tick;
        uint160 sqrtPriceX96;
        uint160 sqrtPriceX96Limit;
        address swapPool;
    }

    // the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the current liquidity in range
        uint128 liquidity;
    }

    struct StepComputations {
        // the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }

    function quoteExactInputSingle(
        bool zeroForIn,
        address swapPool,
        uint160 sqrtPriceLimitX96,
        uint256 amountIn
    ) external view returns (uint160 sqrtPriceX96After, uint256 amountOut) {
        SwapCache memory cache = _prepareSwapCashe(zeroForIn, swapPool, sqrtPriceLimitX96);
        return _calcsSwap(amountIn.toInt256(), cache);
    }

    function calculateExactZapIn(
        CalculateExactZapInParams memory params
    )
        external
        view
        returns (
            uint256 i,
            uint160 sqrtPriceX96After,
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            uint256 maxnAmountIn,
            uint256 minAmountOut
        )
    {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);
        SwapCache memory cache;

        uint256 amountOut;

        uint256 amountInNext;
        (amountInNext, maxnAmountIn, minAmountOut) = _getHoldTokenAmountIn(
            sqrtRatioAX96,
            sqrtRatioBX96,
            params
        );

        if (amountInNext != 0 && params.tokenOutBalance < minAmountOut) {
            (cache) = _prepareSwapCashe(params.zeroForIn, params.swapPool, 0);

            for (i; i < MAX_ITER; ) {
                uint256 amountIn = amountInNext;
                (params.sqrtPriceX96, amountOut) = _calcsSwap(amountIn.toInt256(), cache);

                (amountInNext, maxnAmountIn, minAmountOut) = _getHoldTokenAmountIn(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    params
                );

                if (
                    i > 0 &&
                    amountOut + params.tokenOutBalance >= minAmountOut &&
                    maxnAmountIn <= params.tokenInBalance - amountIn
                ) {
                    sqrtPriceX96After = params.sqrtPriceX96;
                    swapAmountIn = amountIn;
                    swapAmountOut = amountOut;
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        }
        require(swapAmountIn > 0 || i == 0, "CALCULATE_ZAP_OUT_FAILED");
        if (!params.zeroForIn) {
            (maxnAmountIn, minAmountOut) = (minAmountOut, maxnAmountIn);
        }
    }

    function _getHoldTokenAmountIn(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        CalculateExactZapInParams memory params
    ) private pure returns (uint256 holdTokenAmountIn, uint256 maxnAmountIn, uint256 minAmountOut) {
        // Call getAmountsForLiquidity function from LiquidityAmounts library
        // to get the amounts of token0 and token1 for a given liquidity position

        (uint256 amount0, uint256 amount1) = AmountsLiquidity.getAmountsRoundingUpForLiquidity(
            params.sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            params.liquidityExactAmount
        );

        // Calculate the holdTokenAmountIn based on the zeroForSaleToken flag
        (holdTokenAmountIn, maxnAmountIn, minAmountOut) = params.zeroForIn
            ? (params.tokenInBalance - amount0, amount0, amount1)
            : (params.tokenInBalance - amount1, amount1, amount0);
    }

    function _prepareSwapCashe(
        bool zeroForOne,
        address swapPool,
        uint160 sqrtPriceLimitX96
    ) private view returns (SwapCache memory cache) {
        (uint160 sqrtPriceX96, int24 tick, , , , uint8 feeProtocol, ) = IUniswapV3Pool(swapPool)
            .slot0();

        if (sqrtPriceLimitX96 != 0) {
            require(
                zeroForOne
                    ? sqrtPriceLimitX96 < sqrtPriceX96 &&
                        sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                    : sqrtPriceLimitX96 > sqrtPriceX96 &&
                        sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
                "SQRT_PRICE_LIMIT_EXCEEDS_BOUNDS"
            );
        } else {
            sqrtPriceLimitX96 = zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1;
        }

        cache = SwapCache({
            zeroForOne: zeroForOne,
            liquidityStart: IUniswapV3Pool(swapPool).liquidity(),
            feeProtocol: zeroForOne ? (feeProtocol % 16) : (feeProtocol >> 4),
            fee: IUniswapV3Pool(swapPool).fee(),
            tickSpacing: IUniswapV3Pool(swapPool).tickSpacing(),
            tick: tick,
            sqrtPriceX96: sqrtPriceX96,
            sqrtPriceX96Limit: sqrtPriceLimitX96,
            swapPool: swapPool
        });
    }

    function _calcsSwap(
        int256 amountIn,
        SwapCache memory cache
    ) private view returns (uint160, uint256) {
        require(amountIn != 0, "CALCULATE_SWAP_AMOUNT_IN_ZERO");
        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountIn,
            amountCalculated: 0,
            sqrtPriceX96: cache.sqrtPriceX96,
            tick: cache.tick,
            liquidity: cache.liquidityStart
        });
        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
        while (
            state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != cache.sqrtPriceX96Limit
        ) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = _nextInitializedTickWithinOneWord(
                cache.swapPool,
                state.tick,
                cache.tickSpacing,
                cache.zeroForOne
            );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath
                .computeSwapStep(
                    state.sqrtPriceX96,
                    (
                        cache.zeroForOne
                            ? step.sqrtPriceNextX96 < cache.sqrtPriceX96Limit
                            : step.sqrtPriceNextX96 > cache.sqrtPriceX96Limit
                    )
                        ? cache.sqrtPriceX96Limit
                        : step.sqrtPriceNextX96,
                    state.liquidity,
                    state.amountSpecifiedRemaining,
                    cache.fee
                );

            // safe because we test that amountSpecified > amountIn + feeAmount in SwapMath
            unchecked {
                state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
            }
            state.amountCalculated -= step.amountOut.toInt256();

            // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
            if (cache.feeProtocol > 0) {
                unchecked {
                    uint256 delta = step.feeAmount / cache.feeProtocol;
                    step.feeAmount -= delta;
                }
            }

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    // check for the placeholder value, which we replace with the actual value the first time the swap
                    // crosses an initialized tick

                    (, int128 liquidityNet, , , , , , ) = IUniswapV3Pool(cache.swapPool).ticks(
                        step.tickNext
                    );
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    unchecked {
                        if (cache.zeroForOne) liquidityNet = -liquidityNet;
                    }

                    state.liquidity = liquidityNet < 0
                        ? state.liquidity - uint128(-liquidityNet)
                        : state.liquidity + uint128(liquidityNet);
                }

                unchecked {
                    state.tick = cache.zeroForOne ? step.tickNext - 1 : step.tickNext;
                }
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }
        return (state.sqrtPriceX96, uint256(-state.amountCalculated));
    }

    function _position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        unchecked {
            wordPos = int16(tick >> 8);
            bitPos = uint8(int8(tick % 256));
        }
    }

    function _nextInitializedTickWithinOneWord(
        address swapPool,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) private view returns (int24 next, bool initialized) {
        unchecked {
            int24 compressed = tick / tickSpacing;
            if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

            if (lte) {
                (int16 wordPos, uint8 bitPos) = _position(compressed);
                // all the 1s at or to the right of the current bitPos
                uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
                uint256 masked = IUniswapV3Pool(swapPool).tickBitmap(wordPos) & mask;

                // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) *
                        tickSpacing
                    : (compressed - int24(uint24(bitPos))) * tickSpacing;
            } else {
                // start from the word of the next tick, since the current tick state doesn't matter
                (int16 wordPos, uint8 bitPos) = _position(compressed + 1);
                // all the 1s at or to the left of the bitPos
                uint256 mask = ~((1 << bitPos) - 1);
                uint256 masked = IUniswapV3Pool(swapPool).tickBitmap(wordPos) & mask;

                // if there are no initialized ticks to the left of the current tick, return leftmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed +
                        1 +
                        int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                    : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
            }
        }
    }
}

// SPDX-License-Identifier: SAL-1.0

/**
 * WAGMI Leverage Protocol v1.0
 * wagmi.com
 */

pragma solidity 0.8.21;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./abstract/LiquidityManager.sol";
import "./abstract/OwnerSettings.sol";
import "./abstract/DailyRateAndCollateral.sol";
import "./libraries/ErrLib.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title LiquidityBorrowingManager
 * @dev This contract manages the borrowing liquidity functionality for WAGMI Leverage protocol.
 * It inherits from LiquidityManager, OwnerSettings, DailyRateAndCollateral, and ReentrancyGuard contracts.
 */
contract LiquidityBorrowingManager is
    LiquidityManager,
    OwnerSettings,
    DailyRateAndCollateral,
    ReentrancyGuard
{
    using { ErrLib.revertError } for bool;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @title BorrowParams
    /// @notice This struct represents the parameters required for borrowing.
    struct BorrowParams {
        /// @notice The pool fee level for the internal swap
        uint24 internalSwapPoolfee;
        /// @notice The address of the token that will be sold to obtain the loan currency
        address saleToken;
        /// @notice The address of the token that will be held
        address holdToken;
        /// @notice The minimum amount of holdToken that must be obtained
        uint256 minHoldTokenOut;
        /// @notice The maximum amount of margin deposit that can be provided
        uint256 maxMarginDeposit;
        /// @notice The maximum allowable daily rate
        uint256 maxDailyRate;
        /// @notice The SwapParams struct representing the external swap parameters
        SwapParams externalSwap;
        /// @notice An array of LoanInfo structs representing multiple loans
        LoanInfo[] loans;
    }
    /// @title BorrowingInfo
    /// @notice This struct represents the borrowing information for a borrower.
    struct BorrowingInfo {
        address borrower;
        address saleToken;
        address holdToken;
        /// @notice The amount of fees owed by the creditor
        uint256 feesOwed;
        /// @notice The amount borrowed by the borrower
        uint256 borrowedAmount;
        /// @notice The amount of liquidation bonus
        uint256 liquidationBonus;
        /// @notice The accumulated loan rate per share
        uint256 accLoanRatePerSeconds;
        /// @notice The daily rate collateral balance multiplied by COLLATERAL_BALANCE_PRECISION
        uint256 dailyRateCollateralBalance;
    }
    /// @notice This struct used for caching variables inside a function 'borrow'
    struct BorrowCache {
        uint256 dailyRateCollateral;
        uint256 accLoanRatePerSeconds;
        uint256 borrowedAmount;
        uint256 holdTokenBalance;
        uint256 holdTokenEntraceFee;
    }
    /// @notice Struct representing the extended borrowing information.
    struct BorrowingInfoExt {
        /// @notice The main borrowing information.
        BorrowingInfo info;
        /// @notice An array of LoanInfo structs representing multiple loans
        LoanInfo[] loans;
        /// @notice The balance of the collateral.
        int256 collateralBalance;
        /// @notice The estimated lifetime of the loan.
        uint256 estimatedLifeTime;
        /// borrowing Key
        bytes32 key;
    }

    /// @title RepayParams
    /// @notice This struct represents the parameters required for repaying a loan.
    struct RepayParams {
        /// @return returnOnlyHoldToken A boolean representing whether the contract returns only the HoldToken
        bool returnOnlyHoldToken;
        /// @notice The activation of the emergency liquidity restoration mode (available only to the lender)
        bool isEmergency;
        /// @notice The pool fee level for the internal swap
        uint24 internalSwapPoolfee;
        /// @notice The external swap parameters for the repayment transaction
        SwapParams externalSwap;
        /// @notice The unique borrowing key associated with the loan
        bytes32 borrowingKey;
        /// @dev sqrtPriceLimitX96 The Q64.96 sqrt price limit. when liquidity is restored, a hold token is sold therefore,
        /// If zeroForSaleToken==false, the price cannot be less than this value after the swap.
        /// If zeroForSaleToken==true, the price cannot be greater than this value after the swap
        uint160 sqrtPriceLimitX96;
    }
    /// borrowingKey=>LoanInfo
    mapping(bytes32 => LoanInfo[]) public loansInfo;
    /// borrowingKey=>BorrowingInfo
    mapping(bytes32 => BorrowingInfo) public borrowingsInfo;
    /// NonfungiblePositionManager tokenId => EnumerableSet.Bytes32Set
    mapping(uint256 => EnumerableSet.Bytes32Set) private tokenIdToBorrowingKeys;
    /// borrower => EnumerableSet.Bytes32Set
    mapping(address => EnumerableSet.Bytes32Set) private userBorrowingKeys;

    ///  token => FeesAmt
    mapping(address => uint256) private platformsFeesInfo;

    /// Indicates that a borrower has made a new loan
    event Borrow(
        address borrower,
        bytes32 borrowingKey,
        uint256 borrowedAmount,
        uint256 borrowingCollateral,
        uint256 liquidationBonus,
        uint256 dailyRatePrepayment,
        uint256 feesDebt,
        uint256 holdTokenEntraceFee
    );
    /// Indicates that a borrower has repaid their loan, optionally with the help of a liquidator
    event Repay(address borrower, address liquidator, bytes32 borrowingKey);
    /// Indicates that a loan has been closed due to an emergency situation
    event EmergencyLoanClosure(address borrower, address lender, bytes32 borrowingKey);
    /// Indicates that the protocol has collected fee tokens
    event CollectProtocol(address recipient, address[] tokens, uint256[] amounts);
    /// Indicates that the lender has collected fee tokens
    event CollectLoansFees(address recipient, address[] tokens, uint256[] amounts);
    /// Indicates that the daily interest rate for holding token(for specific pair) has been updated
    event UpdateHoldTokenDailyRate(address saleToken, address holdToken, uint256 value);
    /// Indicates that the entrance fee for holding token(for specific pair) has been updated
    event UpdateHoldTokeEntranceFee(address saleToken, address holdToken, uint256 value);
    /// Indicates that a borrower has increased their collateral balance for a loan
    event IncreaseCollateralBalance(address borrower, bytes32 borrowingKey, uint256 collateralAmt);

    event Harvest(bytes32 borrowingKey, uint256 harvestedAmt);

    error TooLittleReceivedError(uint256 minOut, uint256 out);

    /// @dev Modifier to check if the current block timestamp is before or equal to the deadline.
    modifier checkDeadline(uint256 deadline) {
        (_blockTimestamp() > deadline).revertError(ErrLib.ErrorCode.TOO_OLD_TRANSACTION);
        _;
    }

    modifier onlyOperator() {
        (msg.sender != operator).revertError(ErrLib.ErrorCode.INVALID_CALLER);
        _;
    }

    function _blockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    constructor(
        address _underlyingPositionManagerAddress,
        address _lightQuoterV3,
        address _underlyingV3Factory,
        bytes32 _underlyingV3PoolInitCodeHash
    )
        LiquidityManager(
            _underlyingPositionManagerAddress,
            _lightQuoterV3,
            _underlyingV3Factory,
            _underlyingV3PoolInitCodeHash
        )
    {}

    /**
     * @dev Adds or removes a swap call params to the whitelist.
     * @param swapTarget The address of the target contract for the swap call.
     * @param funcSelector The function selector of the swap call.
     * @param isAllowed A boolean indicating whether the swap call is allowed or not.
     */
    function setSwapCallToWhitelist(
        address swapTarget,
        bytes4 funcSelector,
        bool isAllowed
    ) external onlyOwner {
        (swapTarget == VAULT_ADDRESS ||
            swapTarget == address(this) ||
            swapTarget == address(underlyingPositionManager) ||
            funcSelector == IERC20.transferFrom.selector).revertError(ErrLib.ErrorCode.FORBIDDEN);
        whitelistedCall[swapTarget][funcSelector] = isAllowed;
    }

    /**
     * @notice This function allows the owner to collect protocol fees for multiple tokens
     * and transfer them to a specified recipient.
     * @dev Only the contract owner can call this function.
     * @param recipient The address of the recipient who will receive the collected fees.
     * @param tokens An array of addresses representing the tokens for which fees will be collected.
     */
    function collectProtocol(address recipient, address[] calldata tokens) external onlyOwner {
        uint256[] memory amounts = _collect(platformsFeesInfo, recipient, tokens);

        emit CollectProtocol(recipient, tokens, amounts);
    }

    /**
     * @notice This function allows the caller to collect their own loan fees for multiple tokens
     * and transfer them to themselves.
     * @param tokens An array of addresses representing the tokens for which fees will be collected.
     */
    function collectLoansFees(address[] calldata tokens) external {
        mapping(address => uint256) storage collection = loansFeesInfo[msg.sender];
        uint256[] memory amounts = _collect(collection, msg.sender, tokens);

        emit CollectLoansFees(msg.sender, tokens, amounts);
    }

    /**
     * @notice This function is used to update the daily rate for holding token for specific pair.
     * @dev Only the daily rate operator can call this function.
     * @param saleToken The address of the sale token.
     * @param holdToken The address of the hold token.
     * @param value The new value of the daily rate for the hold token will be calculated based
     * on the volatility of the pair and the popularity of loans in it
     * @dev The value must be within the range of MIN_DAILY_RATE and MAX_DAILY_RATE.
     */
    function updateHoldTokenDailyRate(
        address saleToken,
        address holdToken,
        uint256 value
    ) external onlyOperator {
        if (value > Constants.MAX_DAILY_RATE || value < Constants.MIN_DAILY_RATE) {
            revert InvalidSettingsValue(value);
        }
        // If the value is within the acceptable range, the function updates the currentDailyRate property
        // of the holdTokenRateInfo structure associated with the token pair.
        (, TokenInfo storage holdTokenRateInfo) = _updateHoldTokenRateInfo(saleToken, holdToken);
        holdTokenRateInfo.currentDailyRate = value;
        emit UpdateHoldTokenDailyRate(saleToken, holdToken, value);
    }

    function updateHoldTokenEntranceFee(
        address saleToken,
        address holdToken,
        uint256 value
    ) external onlyOperator {
        if (value > Constants.MAX_ENTRANCE_FEE_BPS) {
            revert InvalidSettingsValue(value);
        }
        // If the value is within the acceptable range, the function updates the currentDailyRate property
        // of the holdTokenRateInfo structure associated with the token pair.
        (, TokenInfo storage holdTokenEntranceFeeInfo) = _updateHoldTokenRateInfo(
            saleToken,
            holdToken
        );
        holdTokenEntranceFeeInfo.entranceFeeBP = value;
        emit UpdateHoldTokeEntranceFee(saleToken, holdToken, value);
    }

    /**
     * @notice This function is used to check the daily rate collateral for a specific borrowing.
     * @param borrowingKey The key of the borrowing.
     * @return balance The balance of the daily rate collateral.
     * @return estimatedLifeTime The estimated lifetime of the collateral in seconds.
     */
    function checkDailyRateCollateral(
        bytes32 borrowingKey
    ) external view returns (int256 balance, uint256 estimatedLifeTime) {
        (, balance, estimatedLifeTime) = _getDebtInfo(borrowingKey);
        balance /= int256(Constants.COLLATERAL_BALANCE_PRECISION);
    }

    /**
     * @notice Get information about loans associated with a borrowing key
     * @dev This function retrieves an array of loan information for a given borrowing key.
     * The loans are stored in the loansInfo mapping, which is a mapping of borrowing keys to LoanInfo arrays.
     * @param borrowingKey The unique key associated with the borrowing
     * @return loans An array containing LoanInfo structs representing the loans associated with the borrowing key
     */
    function getLoansInfo(bytes32 borrowingKey) external view returns (LoanInfo[] memory loans) {
        loans = loansInfo[borrowingKey];
    }

    /**
     * @notice Retrieves the borrowing information for a specific NonfungiblePositionManager tokenId.
     * @param tokenId The unique identifier of the PositionManager token.
     * @return extinfo An array of BorrowingInfoExt structs representing the borrowing information.
     */
    function getLenderCreditsInfo(
        uint256 tokenId
    ) external view returns (BorrowingInfoExt[] memory extinfo) {
        bytes32[] memory borrowingKeys = getBorrowingKeysForTokenId(tokenId);
        extinfo = _getDebtsInfo(borrowingKeys);
    }

    /**
     * @dev Retrieves the borrowing keys associated with a token ID.
     * @param tokenId The identifier of the token.
     * @return borrowingKeys An array of borrowing keys.
     */
    function getBorrowingKeysForTokenId(
        uint256 tokenId
    ) public view returns (bytes32[] memory borrowingKeys) {
        borrowingKeys = tokenIdToBorrowingKeys[tokenId].values();
    }

    /**
     * @dev Retrieves the borrowing keys for a specific borrower.
     * @param borrower The address of the borrower.
     * @return borrowingKeys An array of borrowing keys.
     */
    function getBorrowingKeysForBorrower(
        address borrower
    ) public view returns (bytes32[] memory borrowingKeys) {
        borrowingKeys = userBorrowingKeys[borrower].values();
    }

    /**
     * @notice Retrieves the debts information for a specific borrower.
     * @param borrower The address of the borrower.
     * @return extinfo An array of BorrowingInfoExt structs representing the borrowing information.
     */
    function getBorrowerDebtsInfo(
        address borrower
    ) external view returns (BorrowingInfoExt[] memory extinfo) {
        bytes32[] memory borrowingKeys = userBorrowingKeys[borrower].values();
        extinfo = _getDebtsInfo(borrowingKeys);
    }

    /**
     * @dev Returns the number of loans associated with a given NonfungiblePositionManager tokenId.
     * @param tokenId The ID of the token.
     * @return count The total number of loans associated with the tokenId.
     */
    function getLenderCreditsCount(uint256 tokenId) external view returns (uint256 count) {
        count = tokenIdToBorrowingKeys[tokenId].length();
    }

    /**
     * @dev Returns the number of borrowings for a given borrower.
     * @param borrower The address of the borrower.
     * @return count The total number of borrowings for the borrower.
     */
    function getBorrowerDebtsCount(address borrower) external view returns (uint256 count) {
        count = userBorrowingKeys[borrower].length();
    }

    /**
     * @dev Returns the current daily rate for holding token.
     * @param saleToken The address of the token being sold.
     * @param holdToken The address of the token being held.
     * @return  holdTokenRateInfo The structured data containing detailed information for the hold token.
     */
    function getHoldTokenInfo(
        address saleToken,
        address holdToken
    ) external view returns (TokenInfo memory holdTokenRateInfo) {
        holdTokenRateInfo = _getHoldTokenInfo(saleToken, holdToken);
    }

    /**
     * @dev Returns the fees information for multiple tokens in an array.
     * @param feesOwner The address of the owner of the fees.
     * @param tokens An array of token addresses for which the fees are to be retrieved.
     * @return fees An array containing the fees for each token.
     */
    function getFeesInfo(
        address feesOwner,
        address[] calldata tokens
    ) external view returns (uint256[] memory fees) {
        mapping(address => uint256) storage collection = loansFeesInfo[feesOwner];
        fees = _getFees(collection, tokens);
    }

    /**
     * @dev Get the platform fees information for a list of tokens.
     *
     * This function returns an array of fees corresponding to the list of input tokens provided.
     * Each fee is retrieved from the `platformsFeesInfo` mapping which stores the fee for each token address.
     *
     * @param tokens An array of token addresses for which to retrieve the fees information.
     * @return fees Returns an array of fees, one per each token given as input in the same order.
     */
    function getPlatformFeesInfo(
        address[] calldata tokens
    ) external view returns (uint256[] memory fees) {
        mapping(address => uint256) storage collection = platformsFeesInfo;
        fees = _getFees(collection, tokens);
    }

    /**
     * @dev Calculates the collateral amount required for a lifetime in seconds.
     *
     * @param borrowingKey The unique identifier of the borrowing.
     * @param lifetimeInSeconds The duration of the borrowing in seconds.
     * @return collateralAmt The calculated collateral amount that is needed.
     */
    function calculateCollateralAmtForLifetime(
        bytes32 borrowingKey,
        uint256 lifetimeInSeconds
    ) external view returns (uint256 collateralAmt) {
        // Retrieve the BorrowingInfo struct associated with the borrowing key
        BorrowingInfo memory borrowing = borrowingsInfo[borrowingKey];
        // Check if the borrowed position is existing
        if (borrowing.borrowedAmount > 0) {
            // Get the current daily rate for the hold token
            uint256 currentDailyRate = _getHoldTokenInfo(borrowing.saleToken, borrowing.holdToken)
                .currentDailyRate;
            // Calculate the collateral amount per second
            uint256 everySecond = (
                FullMath.mulDivRoundingUp(
                    borrowing.borrowedAmount,
                    currentDailyRate * Constants.COLLATERAL_BALANCE_PRECISION,
                    1 days * Constants.BP
                )
            );
            // Calculate the total collateral amount for the borrowing lifetime
            collateralAmt = FullMath.mulDivRoundingUp(
                everySecond,
                lifetimeInSeconds,
                Constants.COLLATERAL_BALANCE_PRECISION
            );
            // Ensure that the collateral amount is at least 1
            if (collateralAmt == 0) collateralAmt = 1;
        }
    }

    /**
     * @notice This function is used to increase the daily rate collateral for a specific borrowing.
     * @param borrowingKey The unique identifier of the borrowing.
     * @param collateralAmt The amount of collateral to be added.
     * @param deadline The deadline timestamp after which the transaction is considered invalid.
     */
    function increaseCollateralBalance(
        bytes32 borrowingKey,
        uint256 collateralAmt,
        uint256 deadline
    ) external checkDeadline(deadline) {
        BorrowingInfo storage borrowing = borrowingsInfo[borrowingKey];
        // Ensure that the borrowed position exists and the borrower is the message sender
        (borrowing.borrowedAmount == 0 || borrowing.borrower != address(msg.sender)).revertError(
            ErrLib.ErrorCode.INVALID_BORROWING_KEY
        );
        // Increase the daily rate collateral balance by the specified collateral amount
        borrowing.dailyRateCollateralBalance +=
            collateralAmt *
            Constants.COLLATERAL_BALANCE_PRECISION;
        _pay(borrowing.holdToken, msg.sender, VAULT_ADDRESS, collateralAmt);
        emit IncreaseCollateralBalance(msg.sender, borrowingKey, collateralAmt);
    }

    /**
     * @notice Borrow function allows a user to borrow tokens by providing collateral and taking out loans.
     * The trader opens a long position by borrowing the liquidity of Uniswap V3 and extracting it into a pair of tokens,
     * one of which will be swapped into a desired(holdToken).The tokens will be kept in storage until the position is closed.
     * The margin is calculated on the basis that liquidity must be restored with any price movement.
     * The time the position is held is paid by the trader.
     * @dev Emits a Borrow event upon successful borrowing.
     * @param params The BorrowParams struct containing the necessary parameters for borrowing.
     * @param deadline The deadline timestamp after which the transaction is considered invalid.
     *
     * @return borrowedAmount The total amount of `params.holdToken` borrowed.
     * @return marginDeposit The required collateral deposit amount for initiating the loan.
     * @return liquidationBonus An additional amount added to the debt as a bonus in case of liquidation.
     * @return dailyRateCollateral The collateral deposit to hold the transaction for a day.
     */
    function borrow(
        BorrowParams calldata params,
        uint256 deadline
    )
        external
        nonReentrant
        checkDeadline(deadline)
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        // Precalculating borrowing details and storing them in cache
        BorrowCache memory cache = _precalculateBorrowing(params);
        // Initializing borrowing variables and obtaining borrowing key
        (
            uint256 feesDebt,
            bytes32 borrowingKey,
            BorrowingInfo storage borrowing
        ) = _initOrUpdateBorrowing(
                params.saleToken,
                params.holdToken,
                cache.accLoanRatePerSeconds,
                cache.holdTokenEntraceFee
            );
        uint256 liquidationBonus;
        {
            // Adding borrowing key and loans information to storage
            uint256 pushCounter = _addKeysAndLoansInfo(borrowingKey, params.loans);
            // Calculating liquidation bonus based on hold token, borrowed amount, and number of used loans
            liquidationBonus = getLiquidationBonus(
                params.holdToken,
                cache.borrowedAmount,
                pushCounter
            );
        }
        // Updating borrowing details
        borrowing.borrowedAmount += cache.borrowedAmount;
        borrowing.liquidationBonus += liquidationBonus;
        borrowing.dailyRateCollateralBalance +=
            cache.dailyRateCollateral *
            Constants.COLLATERAL_BALANCE_PRECISION;
        // Checking if borrowing marginDeposit exceeds the maximum allowed
        uint256 marginDeposit = cache.borrowedAmount > cache.holdTokenBalance
            ? cache.borrowedAmount - cache.holdTokenBalance
            : 0;
        (marginDeposit > params.maxMarginDeposit).revertError(
            ErrLib.ErrorCode.TOO_BIG_MARGIN_DEPOSIT
        );
        //
        cache.holdTokenEntraceFee =
            cache.holdTokenEntraceFee /
            Constants.COLLATERAL_BALANCE_PRECISION +
            1;

        // Transfer the required tokens to the VAULT_ADDRESS for collateral and holdTokenBalance
        _pay(
            params.holdToken,
            msg.sender,
            VAULT_ADDRESS,
            marginDeposit +
                liquidationBonus +
                cache.dailyRateCollateral +
                feesDebt +
                cache.holdTokenEntraceFee
        );
        // Transferring holdTokenBalance to VAULT_ADDRESS
        _pay(params.holdToken, address(this), VAULT_ADDRESS, cache.holdTokenBalance);
        // Emit the Borrow event with the borrower, borrowing key, and borrowed amount
        emit Borrow(
            msg.sender,
            borrowingKey,
            cache.borrowedAmount,
            marginDeposit,
            liquidationBonus,
            cache.dailyRateCollateral,
            feesDebt,
            cache.holdTokenEntraceFee
        );
        return (
            cache.borrowedAmount,
            marginDeposit,
            liquidationBonus,
            cache.dailyRateCollateral,
            cache.holdTokenEntraceFee
        );
    }

    /**
     * @notice Allows lenders to harvest the fees accumulated from their loans.
     * @dev Retrieves and updates fee amounts for all loans associated with a borrowing position.
     * The function iterates through each loan, calculating and updating the amount of fees due.
     *
     * Requirements:
     * - The borrowingKey must correspond to an active and valid borrowing position.
     * - The collateral balance must be above zero or the current fees must be above the minimum required amount.
     *
     * @param borrowingKey The unique identifier for the specific borrowing position.
     *
     * @return harvestedAmt The total amount of fees harvested by the borrower.
     */
    function harvest(bytes32 borrowingKey) external nonReentrant returns (uint256 harvestedAmt) {
        BorrowingInfo storage borrowing = borrowingsInfo[borrowingKey];
        // Check if the borrowing key is valid
        _existenceCheck(borrowing.borrowedAmount);

        // Update token rate information and get holdTokenRateInfo storage reference
        (, TokenInfo storage holdTokenRateInfo) = _updateHoldTokenRateInfo(
            borrowing.saleToken,
            borrowing.holdToken
        );

        // Calculate collateral balance and validate caller
        (int256 collateralBalance, uint256 currentFees) = _calculateCollateralBalance(
            borrowing.borrowedAmount,
            borrowing.accLoanRatePerSeconds,
            borrowing.dailyRateCollateralBalance,
            holdTokenRateInfo.accLoanRatePerSeconds
        );

        (collateralBalance < 0 ||
            currentFees < Constants.MINIMUM_AMOUNT * Constants.COLLATERAL_BALANCE_PRECISION)
            .revertError(ErrLib.ErrorCode.FORBIDDEN);

        // Calculate platform fees and adjust fees owed
        borrowing.dailyRateCollateralBalance -= currentFees;
        borrowing.feesOwed += _pickUpPlatformFees(borrowing.holdToken, currentFees);
        // Set the accumulated loan rate per second for the borrowing position
        borrowing.accLoanRatePerSeconds = holdTokenRateInfo.accLoanRatePerSeconds;

        uint256 feesOwed = borrowing.feesOwed;
        uint256 borrowedAmount = borrowing.borrowedAmount;

        bool zeroForSaleToken = borrowing.saleToken < borrowing.holdToken;

        // Create a memory struct to store liquidity cache information.
        NftPositionCache memory cache;
        // Get the array of LoanInfo structs associated with the given borrowing key.
        LoanInfo[] memory loans = loansInfo[borrowingKey];
        // Iterate through each loan in the loans array.
        for (uint256 i; i < loans.length; ) {
            LoanInfo memory loan = loans[i];
            // Get the owner address of the loan's token ID using the underlyingPositionManager contract.
            address creditor = _getOwnerOf(loan.tokenId);
            // Check if the owner of the loan's token ID is equal to the `msg.sender`.
            if (creditor != address(0)) {
                // Update the liquidity cache based on the loan information.
                _upNftPositionCache(zeroForSaleToken, loan, cache);
                uint256 feesAmt = FullMath.mulDiv(feesOwed, cache.holdTokenDebt, borrowedAmount);
                // Calculate the fees amount based on the total fees owed and holdTokenDebt.
                loansFeesInfo[creditor][cache.holdToken] += feesAmt;
                harvestedAmt += feesAmt;
            }
            unchecked {
                ++i;
            }
        }

        borrowing.feesOwed -= harvestedAmt;

        emit Harvest(borrowingKey, harvestedAmt);
    }

    /**
     * @notice Used for repaying loans, optionally with liquidation or emergency liquidity withdrawal.
     * The position is closed either by the trader or by the liquidator if the trader has not paid for holding the position
     * and the moment of liquidation has arrived.The positions borrowed from liquidation providers are restored from the held
     * token and the remainder is sent to the caller.In the event of liquidation, the liquidity provider
     * whose liquidity is present in the trader’s position can use the emergency mode and withdraw their liquidity.In this case,
     * he will receive hold tokens and liquidity will not be restored in the uniswap pool.
     * @param params The repayment parameters including
     *  activation of the emergency liquidity restoration mode (available only to the lender)
     *  internal swap pool fee,
     *  external swap parameters,
     *  borrowing key,
     *  swap slippage allowance.
     * @param deadline The deadline by which the repayment must be made.
     *
     * @return saleTokenBack The amount of saleToken returned back to the user after repayment.
     * @return holdTokenBack The amount of holdToken returned back to the user after repayment or emergency withdrawal.
     */
    function repay(
        RepayParams calldata params,
        uint256 deadline
    )
        external
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 saleTokenBack, uint256 holdTokenBack)
    {
        BorrowingInfo memory borrowing = borrowingsInfo[params.borrowingKey];
        // Check if the borrowing key is valid
        _existenceCheck(borrowing.borrowedAmount);

        bool zeroForSaleToken = borrowing.saleToken < borrowing.holdToken;
        uint256 liquidationBonus = borrowing.liquidationBonus;
        int256 collateralBalance;
        // Update token rate information and get holdTokenRateInfo storage reference
        (, TokenInfo storage holdTokenRateInfo) = _updateHoldTokenRateInfo(
            borrowing.saleToken,
            borrowing.holdToken
        );
        {
            // Calculate collateral balance and validate caller
            uint256 accLoanRatePerSeconds = holdTokenRateInfo.accLoanRatePerSeconds;
            uint256 currentFees;
            (collateralBalance, currentFees) = _calculateCollateralBalance(
                borrowing.borrowedAmount,
                borrowing.accLoanRatePerSeconds,
                borrowing.dailyRateCollateralBalance,
                accLoanRatePerSeconds
            );

            (msg.sender != borrowing.borrower && collateralBalance >= 0).revertError(
                ErrLib.ErrorCode.INVALID_CALLER
            );

            // Calculate liquidation bonus and adjust fees owed

            if (collateralBalance > 0) {
                uint256 compensation = _calcFeeCompensationUpToMin(
                    collateralBalance,
                    currentFees,
                    borrowing.feesOwed
                );
                currentFees += compensation;
                collateralBalance -= int256(compensation);
                liquidationBonus +=
                    uint256(collateralBalance) /
                    Constants.COLLATERAL_BALANCE_PRECISION;
            } else {
                currentFees = borrowing.dailyRateCollateralBalance;
            }

            // Calculate platform fees and adjust fees owed
            borrowing.feesOwed += _pickUpPlatformFees(borrowing.holdToken, currentFees);
        }
        // Check if it's an emergency repayment
        if (params.isEmergency) {
            (collateralBalance >= 0).revertError(ErrLib.ErrorCode.FORBIDDEN);
            (
                uint256 removedAmt,
                uint256 feesAmt,
                bool completeRepayment
            ) = _calculateEmergencyLoanClosure(
                    zeroForSaleToken,
                    params.borrowingKey,
                    borrowing.feesOwed,
                    borrowing.borrowedAmount
                );
            (removedAmt == 0).revertError(ErrLib.ErrorCode.LIQUIDITY_IS_ZERO);
            // Subtract the removed amount and fees from borrowedAmount and feesOwed
            borrowing.borrowedAmount -= removedAmt;
            borrowing.feesOwed -= feesAmt;
            feesAmt /= Constants.COLLATERAL_BALANCE_PRECISION;
            // Deduct the removed amount from totalBorrowed
            holdTokenRateInfo.totalBorrowed -= removedAmt;
            // If loansInfoLength is 0, remove the borrowing key from storage and get the liquidation bonus
            if (completeRepayment) {
                LoanInfo[] memory empty;
                _removeKeysAndClearStorage(borrowing.borrower, params.borrowingKey, empty);
                feesAmt += liquidationBonus;
            } else {
                // make changes to the storage
                BorrowingInfo storage borrowingStorage = borrowingsInfo[params.borrowingKey];
                borrowingStorage.dailyRateCollateralBalance = 0;
                borrowingStorage.feesOwed = borrowing.feesOwed;
                borrowingStorage.borrowedAmount = borrowing.borrowedAmount;
            }
            holdTokenBack = removedAmt + feesAmt;
            // Transfer removedAmt + feesAmt to msg.sender and emit EmergencyLoanClosure event
            Vault(VAULT_ADDRESS).transferToken(borrowing.holdToken, msg.sender, holdTokenBack);
            emit EmergencyLoanClosure(borrowing.borrower, msg.sender, params.borrowingKey);
        } else {
            // Deduct borrowedAmount from totalBorrowed
            holdTokenRateInfo.totalBorrowed -= borrowing.borrowedAmount;

            // Transfer the borrowed amount and liquidation bonus from the VAULT to this contract
            Vault(VAULT_ADDRESS).transferToken(
                borrowing.holdToken,
                address(this),
                borrowing.borrowedAmount + liquidationBonus
            );
            // Restore liquidity using the borrowed amount and pay a daily rate fee
            LoanInfo[] memory loans = loansInfo[params.borrowingKey];
            _maxApproveIfNecessary(
                borrowing.holdToken,
                address(underlyingPositionManager),
                type(uint128).max
            );
            _maxApproveIfNecessary(
                borrowing.saleToken,
                address(underlyingPositionManager),
                type(uint128).max
            );
            // when params.sqrtPriceLimitX96 is set (It is highly recommended for both internal and external swaps)
            // or returnOnlyHoldToken option is set (in this case the swap is only in the internal pool)
            //  params.internalSwapPoolfee is required for _frontRunningAttackPrevent and _simulateSwap functions
            (params.internalSwapPoolfee == 0 &&
                (params.sqrtPriceLimitX96 != 0 || params.returnOnlyHoldToken)).revertError(
                    ErrLib.ErrorCode.INTERNAL_SWAP_POOL_FEE_REQUIRED
                );

            _restoreLiquidity(
                RestoreLiquidityParams({
                    zeroForSaleToken: zeroForSaleToken,
                    fee: params.internalSwapPoolfee,
                    sqrtPriceLimitX96: params.sqrtPriceLimitX96,
                    totalfeesOwed: borrowing.feesOwed,
                    totalBorrowedAmount: borrowing.borrowedAmount
                }),
                params.externalSwap,
                loans
            );
            // Get the remaining balance of saleToken and holdToken
            (saleTokenBack, holdTokenBack) = _getPairBalance(
                borrowing.saleToken,
                borrowing.holdToken
            );
            // Remove borrowing key from related data structures
            _removeKeysAndClearStorage(borrowing.borrower, params.borrowingKey, loans);

            if (saleTokenBack > 0 && params.returnOnlyHoldToken) {
                (, uint256 holdTokenAmountOut) = _simulateSwap(
                    zeroForSaleToken,
                    params.internalSwapPoolfee,
                    borrowing.saleToken, // saleToken is tokenIn
                    borrowing.holdToken,
                    saleTokenBack
                );
                if (holdTokenAmountOut > 0) {
                    // Call the internal v3SwapExactInput function
                    holdTokenBack += _v3SwapExactInput(
                        v3SwapExactInputParams({
                            fee: params.internalSwapPoolfee,
                            tokenIn: borrowing.saleToken,
                            tokenOut: borrowing.holdToken,
                            amountIn: saleTokenBack
                        })
                    );
                    saleTokenBack = 0;
                }
            }
            // Pay a profit to a msg.sender
            _pay(borrowing.holdToken, address(this), msg.sender, holdTokenBack);
            _pay(borrowing.saleToken, address(this), msg.sender, saleTokenBack);

            emit Repay(borrowing.borrower, msg.sender, params.borrowingKey);
        }
    }

    /**
     * @dev Calculates the liquidation bonus for a given token, borrowed amount, and times factor.
     * @param token The address of the token.
     * @param borrowedAmount The amount of tokens borrowed.
     * @param times The times factor to apply to the liquidation bonus calculation.
     * @return liquidationBonus The calculated liquidation bonus.
     */
    function getLiquidationBonus(
        address token,
        uint256 borrowedAmount,
        uint256 times
    ) public view returns (uint256 liquidationBonus) {
        // Retrieve liquidation bonus for the given token
        Liquidation memory liq = liquidationBonusForToken[token];

        if (liq.bonusBP == 0) {
            // If there is no specific bonus for the token
            // Use default bonus
            liq.minBonusAmount = Constants.MINIMUM_AMOUNT;
            liq.bonusBP = dafaultLiquidationBonusBP;
        }
        liquidationBonus = (borrowedAmount * liq.bonusBP) / Constants.BP;

        if (liquidationBonus < liq.minBonusAmount) {
            liquidationBonus = liq.minBonusAmount;
        }
        liquidationBonus *= (times > 0 ? times : 1);
    }

    /**
     * @dev Calculates the fee compensation up to the minimum amount.
     * @param collateralBalance The current balance of collateral.
     * @param currentFees The current fees.
     * @param feesOwed The fees owed.
     * @return compensation The fee compensation up to the minimum amount.
     */
    function _calcFeeCompensationUpToMin(
        int256 collateralBalance,
        uint256 currentFees,
        uint256 feesOwed
    ) private pure returns (uint256 compensation) {
        uint256 minimum = Constants.MINIMUM_AMOUNT * Constants.COLLATERAL_BALANCE_PRECISION;
        uint256 total = currentFees + feesOwed;
        if (total < minimum) {
            compensation = minimum - total;
            if (uint256(collateralBalance) < compensation) {
                compensation = uint256(collateralBalance);
            }
        }
    }

    /**
     * @notice Calculates the amount to be repaid in an emergency situation.
     * @dev This function removes loans associated with a borrowing key owned by the `msg.sender`.
     * @param zeroForSaleToken A boolean value indicating whether the token for sale is the 0th token or not.
     * @param borrowingKey The identifier for the borrowing key.
     * @param totalfeesOwed The total fees owed without pending fees.
     * @param totalBorrowedAmount The total borrowed amount.
     * @return removedAmt The amount of debt removed from the loan.
     * @return feesAmt The calculated fees amount.
     * @return completeRepayment indicates the complete closure of the debtor's position
     */
    function _calculateEmergencyLoanClosure(
        bool zeroForSaleToken,
        bytes32 borrowingKey,
        uint256 totalfeesOwed,
        uint256 totalBorrowedAmount
    ) private returns (uint256 removedAmt, uint256 feesAmt, bool completeRepayment) {
        // Create a memory struct to store liquidity cache information.
        NftPositionCache memory cache;
        // Get the array of LoanInfo structs associated with the given borrowing key.
        LoanInfo[] storage loans = loansInfo[borrowingKey];
        // Iterate through each loan in the loans array.
        for (uint256 i; i < loans.length; ) {
            LoanInfo memory loan = loans[i];
            // Get the owner address of the loan's token ID using the underlyingPositionManager contract.
            address creditor = _getOwnerOf(loan.tokenId);
            // Check if the owner of the loan's token ID is equal to the `msg.sender`.
            if (creditor == msg.sender) {
                // If the owner matches the `msg.sender`, replace the current loan with the last loan in the loans array
                // and remove the last element.
                loans[i] = loans[loans.length - 1];
                loans.pop();
                // Remove the borrowing key from the tokenIdToBorrowingKeys mapping.
                tokenIdToBorrowingKeys[loan.tokenId].remove(borrowingKey);
                // Update the liquidity cache based on the loan information.
                _upNftPositionCache(zeroForSaleToken, loan, cache);
                // Add the holdTokenDebt value to the removedAmt.
                removedAmt += cache.holdTokenDebt;
                // Calculate the fees amount based on the total fees owed and holdTokenDebt.
                feesAmt += FullMath.mulDiv(totalfeesOwed, cache.holdTokenDebt, totalBorrowedAmount);
            } else {
                // If the owner of the loan's token ID is not equal to the `msg.sender`,
                // the function increments the loop counter and moves on to the next loan.
                unchecked {
                    ++i;
                }
            }
        }
        // Check if all loans have been removed, indicating complete repayment.
        completeRepayment = loans.length == 0;
    }

    /**
     * @dev This internal function is used to remove borrowing keys and clear related storage for a specific
     * borrower and borrowing key.
     * @param borrower The address of the borrower.
     * @param borrowingKey The borrowing key to be removed.
     * @param loans An array of LoanInfo structs representing the loans associated with the borrowing key.
     */
    function _removeKeysAndClearStorage(
        address borrower,
        bytes32 borrowingKey,
        LoanInfo[] memory loans
    ) private {
        // Remove the borrowing key from the tokenIdToBorrowingKeys mapping for each loan in the loans array.
        for (uint256 i; i < loans.length; ) {
            tokenIdToBorrowingKeys[loans[i].tokenId].remove(borrowingKey);
            unchecked {
                ++i;
            }
        }
        // Remove the borrowing key from the userBorrowingKeys mapping for the borrower.
        userBorrowingKeys[borrower].remove(borrowingKey);
        // Delete the borrowing information and loans associated with the borrowing key from the borrowingsInfo
        // and loansInfo mappings.
        delete borrowingsInfo[borrowingKey];
        delete loansInfo[borrowingKey];
    }

    /**
     * @dev This internal function is used to add borrowing keys and loan information for a specific borrowing key.
     * @param borrowingKey The borrowing key to be added or updated.
     * @param sourceLoans An array of LoanInfo structs representing the loans to be associated with the borrowing key.
     */
    function _addKeysAndLoansInfo(
        bytes32 borrowingKey,
        LoanInfo[] memory sourceLoans
    ) private returns (uint256 pushCounter) {
        // Get the storage reference to the loans array for the borrowing key
        LoanInfo[] storage loans = loansInfo[borrowingKey];
        // Iterate through the sourceLoans array
        for (uint256 i; i < sourceLoans.length; ) {
            // Get the current loan from the sourceLoans array
            LoanInfo memory loan = sourceLoans[i];
            // Get the storage reference to the tokenIdLoansKeys array for the loan's token ID
            if (tokenIdToBorrowingKeys[loan.tokenId].add(borrowingKey)) {
                // Push the current loan to the loans array
                loans.push(loan);
                pushCounter++;
            } else {
                // If already exists, find the loan and update its liquidity
                for (uint256 j; j < loans.length; ) {
                    if (loans[j].tokenId == loan.tokenId) {
                        loans[j].liquidity += loan.liquidity;
                        break;
                    }
                    unchecked {
                        ++j;
                    }
                }
            }
            unchecked {
                ++i;
            }
        }
        // Ensure that the number of loans does not exceed the maximum limit
        (loans.length > Constants.MAX_NUM_LOANS_PER_POSITION).revertError(
            ErrLib.ErrorCode.TOO_MANY_LOANS_PER_POSITION
        );
        // Add the borrowing key to the userBorrowingKeys mapping for the borrower if it does not exist
        userBorrowingKeys[msg.sender].add(borrowingKey);
    }

    /**
     * @dev This internal function is used to precalculate borrowing parameters and update the cache.
     * @param params The BorrowParams struct containing the borrowing parameters.
     * @return cache A BorrowCache struct containing the calculated values.
     */
    function _precalculateBorrowing(
        BorrowParams calldata params
    ) private returns (BorrowCache memory cache) {
        {
            bool zeroForSaleToken = params.saleToken < params.holdToken;
            // Create a storage reference for the hold token rate information
            TokenInfo storage holdTokenRateInfo;
            // Update the token rate information and retrieve the dailyRate and TokenInfo for the holdTokenRateInfo
            (cache.dailyRateCollateral, holdTokenRateInfo) = _updateHoldTokenRateInfo(
                params.saleToken,
                params.holdToken
            );

            (cache.dailyRateCollateral > params.maxDailyRate).revertError(
                ErrLib.ErrorCode.TOO_BIG_DAILY_RATE
            );

            cache.holdTokenEntraceFee = holdTokenRateInfo.entranceFeeBP;

            cache.holdTokenEntraceFee = _checkEntranceFee(cache.holdTokenEntraceFee);

            // Set the accumulated loan rate per second from the updated holdTokenRateInfo
            cache.accLoanRatePerSeconds = holdTokenRateInfo.accLoanRatePerSeconds;
            // Extract liquidity and store the borrowed amount in the cache
            cache.borrowedAmount = _extractLiquidity(
                zeroForSaleToken,
                params.saleToken,
                params.holdToken,
                params.loans
            );
            // the empty loans[] disallowed
            (cache.borrowedAmount == 0).revertError(ErrLib.ErrorCode.LOANS_IS_EMPTY);
            // Increment the total borrowed amount for the hold token information
            holdTokenRateInfo.totalBorrowed += cache.borrowedAmount;
        }
        // Calculate the prepayment per day fees based on the borrowed amount and daily rate collateral
        cache.dailyRateCollateral = FullMath.mulDivRoundingUp(
            cache.borrowedAmount,
            cache.dailyRateCollateral,
            Constants.BP
        );
        // Check if the dailyRateCollateral is less than the minimum amount defined in the Constants contract
        if (cache.dailyRateCollateral < Constants.MINIMUM_AMOUNT) {
            cache.dailyRateCollateral = Constants.MINIMUM_AMOUNT;
        }
        uint256 saleTokenBalance;
        // Get the balance of the sale token and hold token in the pair
        (saleTokenBalance, cache.holdTokenBalance) = _getPairBalance(
            params.saleToken,
            params.holdToken
        );
        // Check if the sale token balance is greater than 0
        if (saleTokenBalance > 0) {
            if (params.externalSwap.swapTarget != address(0)) {
                // Call the external swap function and update the hold token balance in the cache
                cache.holdTokenBalance += _patchAmountsAndCallSwap(
                    params.saleToken,
                    params.holdToken,
                    params.externalSwap,
                    saleTokenBalance,
                    0
                );
            } else {
                // Call the internal v3SwapExactInput function and update the hold token balance in the cache
                cache.holdTokenBalance += _v3SwapExactInput(
                    v3SwapExactInputParams({
                        fee: params.internalSwapPoolfee,
                        tokenIn: params.saleToken,
                        tokenOut: params.holdToken,
                        amountIn: saleTokenBalance
                    })
                );
            }
        }
        // Calculate the hold token entrance fee based on the hold token balance and entrance fee basis points
        cache.holdTokenEntraceFee =
            (cache.holdTokenBalance *
                cache.holdTokenEntraceFee *
                Constants.COLLATERAL_BALANCE_PRECISION) /
            Constants.BP;

        // Ensure that the received holdToken balance meets the minimum required
        if (cache.holdTokenBalance < params.minHoldTokenOut) {
            revert TooLittleReceivedError(params.minHoldTokenOut, cache.holdTokenBalance);
        }
    }

    /**
     * @dev This internal function is used to initialize or update the borrowing process for a given saleToken and holdToken combination.
     * It computes the borrowingKey, retrieves the BorrowingInfo from borrowingsInfo mapping,
     * and updates the BorrowingInfo based on the current state of the borrowing.
     * @param saleToken The address of the sale token.
     * @param holdToken The address of the hold token.
     * @param accLoanRatePerSeconds The accumulated loan rate per second for the borrower.
     * @return feesDebt The calculated fees debt.
     * @return borrowingKey The borrowing key for the borrowing position.
     * @return borrowing The storage reference to the BorrowingInfo struct.
     */
    function _initOrUpdateBorrowing(
        address saleToken,
        address holdToken,
        uint256 accLoanRatePerSeconds,
        uint256 entranceFee
    ) private returns (uint256 feesDebt, bytes32 borrowingKey, BorrowingInfo storage borrowing) {
        // Compute the borrowingKey using the msg.sender, saleToken, and holdToken
        borrowingKey = Keys.computeBorrowingKey(msg.sender, saleToken, holdToken);
        // Retrieve the BorrowingInfo from borrowingsInfo mapping using the borrowingKey
        borrowing = borrowingsInfo[borrowingKey];
        // update
        if (borrowing.borrowedAmount > 0) {
            // Ensure that the borrower of the existing borrowing position matches the msg.sender
            (borrowing.borrower != address(msg.sender)).revertError(
                ErrLib.ErrorCode.INVALID_BORROWING_KEY
            );
            // Calculate the collateral balance and current fees based on the existing borrowing information
            (int256 collateralBalance, uint256 currentFees) = _calculateCollateralBalance(
                borrowing.borrowedAmount,
                borrowing.accLoanRatePerSeconds,
                borrowing.dailyRateCollateralBalance,
                accLoanRatePerSeconds
            );
            // Calculate the fees debt
            if (collateralBalance < 0) {
                feesDebt = uint256(-collateralBalance) / Constants.COLLATERAL_BALANCE_PRECISION + 1;
                borrowing.dailyRateCollateralBalance = 0;
            } else {
                borrowing.dailyRateCollateralBalance -= currentFees;
            }
            // Pick up platform fees from the hold token's current fees
            currentFees = _pickUpPlatformFees(holdToken, currentFees);
            // Increment the fees owed in the borrowing position
            borrowing.feesOwed += currentFees;
        } else {
            // Initialize the BorrowingInfo for the new position
            borrowing.borrower = msg.sender;
            borrowing.saleToken = saleToken;
            borrowing.holdToken = holdToken;
        }
        // Pick up platform fees from the entrance fee
        entranceFee = _pickUpPlatformFees(holdToken, entranceFee);
        // Increment the fees owed in the borrowing position
        borrowing.feesOwed += entranceFee;
        // Set the accumulated loan rate per second for the borrowing position
        borrowing.accLoanRatePerSeconds = accLoanRatePerSeconds;
    }

    /**
     * @dev This internal function is used to pick up platform fees from the given fees amount.
     * It calculates the platform fees based on the fees and platformFeesBP (basis points) variables,
     * updates the platformsFeesInfo mapping with the platform fees for the holdToken,
     * and returns the remaining fees after deducting the platform fees.
     * @param holdToken The address of the hold token.
     * @param fees The total fees amount.
     * @return currentFees The remaining fees after deducting the platform fees.
     */
    function _pickUpPlatformFees(
        address holdToken,
        uint256 fees
    ) private returns (uint256 currentFees) {
        uint256 platformFees = (fees * platformFeesBP) / Constants.BP;
        platformsFeesInfo[holdToken] += platformFees;
        currentFees = fees - platformFees;
    }

    /**
     * @dev This internal function is used to get information about a specific debt.
     * It retrieves the borrowing information from the borrowingsInfo mapping based on the borrowingKey,
     * calculates the current daily rate and hold token rate info using the _getHoldTokenInfo function,
     * calculates the collateral balance using the _calculateCollateralBalance function,
     * and calculates the estimated lifetime of the debt if the collateral balance is greater than zero.
     * @param borrowingKey The unique key associated with the debt.
     * @return borrowing The struct containing information about the debt.
     * @return collateralBalance The calculated collateral balance for the debt.
     * @return estimatedLifeTime The estimated number of seconds the debt will last based on the collateral balance.
     */
    function _getDebtInfo(
        bytes32 borrowingKey
    )
        private
        view
        returns (
            BorrowingInfo memory borrowing,
            int256 collateralBalance,
            uint256 estimatedLifeTime
        )
    {
        // Retrieve the borrowing information from the borrowingsInfo mapping based on the borrowingKey
        borrowing = borrowingsInfo[borrowingKey];
        // Calculate the current daily rate and hold token rate info using the _getHoldTokenInfo function
        TokenInfo memory holdTokenRateInfo = _getHoldTokenInfo(
            borrowing.saleToken,
            borrowing.holdToken
        );

        (collateralBalance, ) = _calculateCollateralBalance(
            borrowing.borrowedAmount,
            borrowing.accLoanRatePerSeconds,
            borrowing.dailyRateCollateralBalance,
            holdTokenRateInfo.accLoanRatePerSeconds
        );
        // Calculate the estimated lifetime of the debt if the collateral balance is greater than zero
        if (collateralBalance > 0) {
            uint256 everySecond = (
                FullMath.mulDivRoundingUp(
                    borrowing.borrowedAmount,
                    holdTokenRateInfo.currentDailyRate * Constants.COLLATERAL_BALANCE_PRECISION,
                    1 days * Constants.BP
                )
            );

            estimatedLifeTime = uint256(collateralBalance) / everySecond;
            if (estimatedLifeTime == 0) estimatedLifeTime = 1;
        }
    }

    function _getFees(
        mapping(address => uint256) storage collection,
        address[] calldata tokens
    ) internal view returns (uint256[] memory fees) {
        fees = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; ) {
            address token = tokens[i];
            uint256 amount = collection[token] / Constants.COLLATERAL_BALANCE_PRECISION;
            fees[i] = amount;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Retrieves the debt information for the specified borrowing keys.
    /// @param borrowingKeys The array of borrowing keys to retrieve the debt information for.
    /// @return extinfo An array of BorrowingInfoExt structs representing the borrowing information.
    function _getDebtsInfo(
        bytes32[] memory borrowingKeys
    ) private view returns (BorrowingInfoExt[] memory extinfo) {
        extinfo = new BorrowingInfoExt[](borrowingKeys.length);
        for (uint256 i; i < borrowingKeys.length; ) {
            bytes32 key = borrowingKeys[i];
            extinfo[i].key = key;
            extinfo[i].loans = loansInfo[key];
            (
                extinfo[i].info,
                extinfo[i].collateralBalance,
                extinfo[i].estimatedLifeTime
            ) = _getDebtInfo(key);
            unchecked {
                ++i;
            }
        }
    }

    function _existenceCheck(uint256 borrowedAmount) private pure {
        (borrowedAmount == 0).revertError(ErrLib.ErrorCode.INVALID_BORROWING_KEY);
    }

    function _collect(
        mapping(address => uint256) storage collection,
        address recipient,
        address[] calldata tokens
    ) private returns (uint256[] memory amounts) {
        amounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; ) {
            address token = tokens[i];
            uint256 amount = collection[token] / Constants.COLLATERAL_BALANCE_PRECISION;
            if (amount > 0) {
                collection[token] = 0;
                amounts[i] = amount;
                Vault(VAULT_ADDRESS).transferToken(token, recipient, amount);
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IQuoterV2.sol";

contract AggregatorMock {
    IQuoterV2 public immutable underlyingQuoterV2;

    constructor(address _underlyingQuoterV2) {
        underlyingQuoterV2 = IQuoterV2(_underlyingQuoterV2);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, ) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success, "AggregatorMock: safeTransfer failed");
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success, "AggregatorMock: safeTransferFrom failed");
    }

    function nonWhitelistedSwap(bytes calldata wrappedCallData) external {
        _swap(wrappedCallData, false);
    }

    function swap(bytes calldata wrappedCallData) external {
        _swap(wrappedCallData, false);
    }

    function badswap(bytes calldata wrappedCallData) external {
        _swap(wrappedCallData, true);
    }

    function _swap(bytes calldata wrappedCallData, bool slip) internal {
        (address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin) = abi.decode(
            wrappedCallData,
            (address, address, uint256, uint256)
        );
        require(tokenIn != tokenOut, "TE");

        (uint256 amountOut, , , ) = underlyingQuoterV2.quoteExactInputSingle(
            IQuoterV2.QuoteExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                fee: 500,
                sqrtPriceLimitX96: 0
            })
        );

        require(amountOut >= amountOutMin, "AggregatorMock: price slippage check");
        _safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        _safeTransfer(tokenOut, msg.sender, slip ? (amountOut * 100) / 10000 : amountOut);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/abstract/ApproveSwapAndPay.sol";
import "../../../../contracts/libraries/Keys.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract $ApproveSwapAndPay is ApproveSwapAndPay {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant __hh_exposed_bytecode_marker = "hardhat-exposed";
    EnumerableSet.Bytes32Set self;

    event return$_patchAmountsAndCallSwap(uint256 amountOut);

    event return$_v3SwapExactInput(uint256 amountOut);

    constructor(
        address _UNDERLYING_V3_FACTORY_ADDRESS,
        bytes32 _UNDERLYING_V3_POOL_INIT_CODE_HASH
    )
        payable
        ApproveSwapAndPay(_UNDERLYING_V3_FACTORY_ADDRESS, _UNDERLYING_V3_POOL_INIT_CODE_HASH)
    {}

    function $MIN_SQRT_RATIO() external pure returns (uint160) {
        return MIN_SQRT_RATIO;
    }

    function $MAX_SQRT_RATIO() external pure returns (uint160) {
        return MAX_SQRT_RATIO;
    }

    function $_removeKey(bytes32 key) external {
        self.remove(key);
    }

    function $_addKeyIfNotExists(bytes32 key) external {
        self.add(key);
    }

    function $getSelf() external view returns (bytes32[] memory) {
        return self.values();
    }

    function $_computePairKey(
        address saleToken,
        address holdToken
    ) external pure returns (bytes32) {
        return Keys.computePairKey(saleToken, holdToken);
    }

    function $_maxApproveIfNecessary(address token, address spender, uint256 amount) external {
        super._maxApproveIfNecessary(token, spender, amount);
    }

    function $_getBalance(address token) external view returns (uint256 balance) {
        (balance) = super._getBalance(token);
    }

    function $_getPairBalance(
        address tokenA,
        address tokenB
    ) external view returns (uint256 balanceA, uint256 balanceB) {
        (balanceA, balanceB) = super._getPairBalance(tokenA, tokenB);
    }

    function $_patchAmountsAndCallSwap(
        address tokenIn,
        address tokenOut,
        SwapParams calldata externalSwap,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256 amountOut) {
        (amountOut) = super._patchAmountsAndCallSwap(
            tokenIn,
            tokenOut,
            externalSwap,
            amountIn,
            amountOutMin
        );
        emit return$_patchAmountsAndCallSwap(amountOut);
    }

    function $_pay(address token, address payer, address recipient, uint256 value) external {
        super._pay(token, payer, recipient, value);
    }

    function $_v3SwapExactInput(
        v3SwapExactInputParams calldata params
    ) external returns (uint256 amountOut) {
        (amountOut) = super._v3SwapExactInput(params);
        emit return$_v3SwapExactInput(amountOut);
    }

    function $setSwapCallToWhitelist(
        address swapTarget,
        bytes4 funcSelector,
        bool isAllowed
    ) external {
        whitelistedCall[swapTarget][funcSelector] = isAllowed;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/abstract/DailyRateAndCollateral.sol";

contract $DailyRateAndCollateral is DailyRateAndCollateral {
    bytes32 public constant __hh_exposed_bytecode_marker = "hardhat-exposed";

    event return$_updateHoldTokenInfo(uint256 currentDailyRate, TokenInfo holdTokenRateInfo);

    constructor() payable {}

    function $_getHoldTokenInfo(
        address saleToken,
        address holdToken
    ) external view returns (TokenInfo memory holdTokenRateInfo) {
        holdTokenRateInfo = super._getHoldTokenInfo(saleToken, holdToken);
    }

    function $_updateHoldTokenInfo(
        address saleToken,
        address holdToken
    ) external returns (uint256 currentDailyRate, TokenInfo memory holdTokenRateInfo) {
        (currentDailyRate, holdTokenRateInfo) = super._updateHoldTokenRateInfo(
            saleToken,
            holdToken
        );
        emit return$_updateHoldTokenInfo(currentDailyRate, holdTokenRateInfo);
    }

    function $_calculateCollateralBalance(
        uint256 borrowedAmount,
        uint256 borrowingAccLoanRatePerShare,
        uint256 borrowingDailyRateCollateral,
        uint256 accLoanRatePerSeconds
    ) external pure returns (int256 collateralBalance, uint256 currentFees) {
        (collateralBalance, currentFees) = super._calculateCollateralBalance(
            borrowedAmount,
            borrowingAccLoanRatePerShare,
            borrowingDailyRateCollateral,
            accLoanRatePerSeconds
        );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/abstract/LiquidityManager.sol";

contract $LiquidityManager is LiquidityManager {
    bytes32 public constant __hh_exposed_bytecode_marker = "hardhat-exposed";

    event return$_extractLiquidity(uint256 borrowedAmount);

    event return$_patchAmountsAndCallSwap(uint256 amountOut);

    event return$_v3SwapExactInput(uint256 amountOut);

    constructor(
        address _underlyingPositionManagerAddress,
        address _lightQuoterV3,
        address _underlyingV3Factory,
        bytes32 _underlyingV3PoolInitCodeHash
    )
        payable
        LiquidityManager(
            _underlyingPositionManagerAddress,
            _lightQuoterV3,
            _underlyingV3Factory,
            _underlyingV3PoolInitCodeHash
        )
    {}

    function $MIN_SQRT_RATIO() external pure returns (uint160) {
        return MIN_SQRT_RATIO;
    }

    function $MAX_SQRT_RATIO() external pure returns (uint160) {
        return MAX_SQRT_RATIO;
    }

    function $_extractLiquidity(
        bool zeroForSaleToken,
        address token0,
        address token1,
        LoanInfo[] calldata loans
    ) external returns (uint256 borrowedAmount) {
        (borrowedAmount) = super._extractLiquidity(zeroForSaleToken, token0, token1, loans);
        emit return$_extractLiquidity(borrowedAmount);
    }

    function $_restoreLiquidity(
        RestoreLiquidityParams calldata params,
        SwapParams calldata externalSwap,
        LoanInfo[] calldata loans
    ) external {
        super._restoreLiquidity(params, externalSwap, loans);
    }

    function $_maxApproveIfNecessary(address token, address spender, uint256 amount) external {
        super._maxApproveIfNecessary(token, spender, amount);
    }

    function $_getBalance(address token) external view returns (uint256 balance) {
        (balance) = super._getBalance(token);
    }

    function $_getPairBalance(
        address tokenA,
        address tokenB
    ) external view returns (uint256 balanceA, uint256 balanceB) {
        (balanceA, balanceB) = super._getPairBalance(tokenA, tokenB);
    }

    function $_patchAmountsAndCallSwap(
        address tokenIn,
        address tokenOut,
        SwapParams calldata externalSwap,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256 amountOut) {
        (amountOut) = super._patchAmountsAndCallSwap(
            tokenIn,
            tokenOut,
            externalSwap,
            amountIn,
            amountOutMin
        );
        emit return$_patchAmountsAndCallSwap(amountOut);
    }

    function $_pay(address token, address payer, address recipient, uint256 value) external {
        super._pay(token, payer, recipient, value);
    }

    function $_v3SwapExactInput(
        v3SwapExactInputParams calldata params
    ) external returns (uint256 amountOut) {
        (amountOut) = super._v3SwapExactInput(params);
        emit return$_v3SwapExactInput(amountOut);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory _name, string memory _shortName) ERC20(_name, _shortName) {
        _mint(msg.sender, 1e24);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20FailApprove is ERC20 {
    constructor(string memory _name, string memory _shortName) ERC20(_name, _shortName) {}

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        if (
            (spender == address(1) && amount == type(uint256).max) ||
            (spender == address(2) && amount == type(uint256).max - 1) ||
            (amount == 0 && spender != address(3))
        ) {
            _approve(owner, spender, amount);
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import { IUniswapV3Pool } from "./interfaces/IUniswapV3Pool.sol";
import { TickMath } from "./vendor0.8/uniswap/TickMath.sol";
import { AmountsLiquidity } from "./libraries/AmountsLiquidity.sol";
import { FullMath, LiquidityAmounts } from "./vendor0.8/uniswap/LiquidityAmounts.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract PositionEffectivityChart {
    struct LoanInfo {
        uint128 liquidity;
        uint256 tokenId;
    }
    struct Chart {
        uint256 x; //price
        int256 y; //profit
    }

    /// @notice Describes a loan's position data for charting purposes
    struct LoansData {
        uint256 amount; // The amount of the holdToken debt
        uint256 minPrice; // The minimum price based on lowerSqrtPriceX96
        uint256 maxPrice; // The maximum price based on upperSqrtPriceX96
    }

    struct CalcCashe {
        uint160 maxSqrtPriceX96;
        uint160 minSqrtPriceX96;
        uint256 holdTokenDebtSum;
        uint256 marginDepoSum;
    }

    struct NftPositionCache {
        uint24 fee;
        uint160 lowerSqrtPriceX96;
        uint160 upperSqrtPriceX96;
        int24 entryTick;
        uint160 entrySqrtPriceX96;
        address saleToken;
        address holdToken;
        uint256 holdTokenDebt;
        uint256 marginDepo;
    }
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    address public immutable UNDERLYING_V3_FACTORY_ADDRESS;
    address public immutable UNDERLYING_POSITION_MANAGER_ADDRESS;
    bytes32 public immutable UNDERLYING_V3_POOL_INIT_CODE_HASH;

    constructor(
        address _positionManagerAddress,
        address _v3FactoryAddress,
        bytes32 _v3PoolInitCodeHash
    ) {
        UNDERLYING_V3_FACTORY_ADDRESS = _v3FactoryAddress;
        UNDERLYING_V3_POOL_INIT_CODE_HASH = _v3PoolInitCodeHash;
        UNDERLYING_POSITION_MANAGER_ADDRESS = _positionManagerAddress;
    }

    /// @notice Creates charts representing loan positions over a price range, including an aggressive mode profit line.
    /// @param zeroForSaleToken Flag indicating whether the sale token is zero for price calculations
    /// @param loans Array of loan positions that will be visualized
    /// @param pointsNumber Number of points to plot on the chart for the price range
    /// @param marginPointsNumber Number of additional margin points for the price range on the chart
    /// @return loansChartData An array with detailed information for each loan position
    /// @return aggressiveModeProfitLine A two-point line showing potential profit in an aggressive margin setup
    /// @return chart An array of Chart structs representing the loan positions over the plotted price range
    function createChart(
        bool zeroForSaleToken,
        LoanInfo[] calldata loans,
        uint256 pointsNumber,
        uint160 marginPointsNumber
    )
        external
        view
        returns (
            LoansData[] memory loansChartData,
            Chart[2] memory aggressiveModeProfitLine,
            Chart[] memory chart
        )
    {
        if (pointsNumber < 6) {
            pointsNumber = 6;
        }
        NftPositionCache[] memory caches = new NftPositionCache[](loans.length);
        loansChartData = new LoansData[](loans.length);
        CalcCashe memory calcCashe;
        uint128 oneHoldToken;
        uint160 weightedAverageEntraceSqrtPriceX96;
        {
            calcCashe.minSqrtPriceX96 = MAX_SQRT_RATIO;
            calcCashe.maxSqrtPriceX96 = MIN_SQRT_RATIO;

            for (uint256 i = 0; i < loans.length; ) {
                _upNftPositionCache(zeroForSaleToken, loans[i], caches[i]);

                if (i == 0) {
                    oneHoldToken = uint128(10 ** IERC20Metadata(caches[0].holdToken).decimals());
                }
                if (caches[i].lowerSqrtPriceX96 < calcCashe.minSqrtPriceX96) {
                    calcCashe.minSqrtPriceX96 = caches[i].lowerSqrtPriceX96;
                }
                if (caches[i].upperSqrtPriceX96 > calcCashe.maxSqrtPriceX96) {
                    calcCashe.maxSqrtPriceX96 = caches[i].upperSqrtPriceX96;
                }

                if (caches[i].entrySqrtPriceX96 < calcCashe.minSqrtPriceX96) {
                    calcCashe.minSqrtPriceX96 = caches[i].entrySqrtPriceX96;
                }
                if (caches[i].entrySqrtPriceX96 > calcCashe.maxSqrtPriceX96) {
                    calcCashe.maxSqrtPriceX96 = caches[i].entrySqrtPriceX96;
                }

                calcCashe.holdTokenDebtSum += caches[i].holdTokenDebt;
                calcCashe.marginDepoSum += caches[i].marginDepo;
                weightedAverageEntraceSqrtPriceX96 +=
                    caches[i].entrySqrtPriceX96 *
                    uint160(caches[i].holdTokenDebt);

                loansChartData[i].amount = caches[i].holdTokenDebt;
                loansChartData[i].minPrice = _getAmountOut(
                    !zeroForSaleToken,
                    caches[i].lowerSqrtPriceX96,
                    oneHoldToken
                );
                loansChartData[i].maxPrice = _getAmountOut(
                    !zeroForSaleToken,
                    caches[i].upperSqrtPriceX96,
                    oneHoldToken
                );
                unchecked {
                    i++;
                }
            }
            weightedAverageEntraceSqrtPriceX96 /= uint160(calcCashe.holdTokenDebtSum);
        }

        uint160 step = uint160(
            (calcCashe.maxSqrtPriceX96 - calcCashe.minSqrtPriceX96) / pointsNumber
        );
        // margin from edges
        uint160 margin = step * marginPointsNumber;
        if (MIN_SQRT_RATIO <= calcCashe.minSqrtPriceX96 - margin) {
            calcCashe.minSqrtPriceX96 -= margin;
            pointsNumber += marginPointsNumber;
        }
        if (MAX_SQRT_RATIO >= calcCashe.maxSqrtPriceX96 + margin) {
            calcCashe.maxSqrtPriceX96 += margin;
            pointsNumber += marginPointsNumber;
        }

        chart = new Chart[](pointsNumber);
        uint160 sqrtPriceX96;
        for (uint256 i = 0; i < pointsNumber; ) {
            sqrtPriceX96 = uint160(
                zeroForSaleToken
                    ? (calcCashe.maxSqrtPriceX96 - step * i)
                    : (calcCashe.minSqrtPriceX96 + step * i)
            );

            chart[i].x = _getAmountOut(!zeroForSaleToken, sqrtPriceX96, oneHoldToken);

            for (uint256 j = 0; j < loans.length; ) {
                uint256 holdTokenAmount = _optimisticHoldTokenAmountForLiquidity(
                    zeroForSaleToken,
                    sqrtPriceX96,
                    caches[j].lowerSqrtPriceX96,
                    caches[j].upperSqrtPriceX96,
                    loans[j].liquidity,
                    caches[j].holdTokenDebt
                );

                chart[i].y += int256(holdTokenAmount) - int256(caches[j].marginDepo);

                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }

        aggressiveModeProfitLine[0].x = _getAmountOut(
            !zeroForSaleToken,
            weightedAverageEntraceSqrtPriceX96,
            oneHoldToken
        );
        aggressiveModeProfitLine[1].x = chart[pointsNumber - 1].x;
        uint256 profitInSallToken = ((calcCashe.holdTokenDebtSum * aggressiveModeProfitLine[1].x) -
            ((calcCashe.holdTokenDebtSum - calcCashe.marginDepoSum) *
                aggressiveModeProfitLine[0].x)) / oneHoldToken;

        aggressiveModeProfitLine[1].y =
            int256(_getAmountOut(zeroForSaleToken, sqrtPriceX96, uint128(profitInSallToken))) -
            int256(calcCashe.marginDepoSum);
    }

    function _optimisticHoldTokenAmountForLiquidity(
        bool zeroForSaleToken,
        uint160 sqrtPriceX96,
        uint160 lowerSqrtPriceX96,
        uint160 upperSqrtPriceX96,
        uint128 liquidity,
        uint256 holdTokenDebt
    ) private pure returns (uint256 holdTokenAmount) {
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            lowerSqrtPriceX96,
            upperSqrtPriceX96,
            liquidity
        );
        if (!zeroForSaleToken) {
            (amount0, amount1) = (amount1, amount0);
        }
        holdTokenAmount = amount1 + _getAmountOut(zeroForSaleToken, sqrtPriceX96, uint128(amount0));
        holdTokenAmount = holdTokenDebt > holdTokenAmount ? holdTokenDebt - holdTokenAmount : 0;
    }

    function _getAmountOut(
        bool zeroForIn,
        uint160 sqrtPriceX96,
        uint128 amountIn
    ) private pure returns (uint256 amountOut) {
        if (sqrtPriceX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtPriceX96) * sqrtPriceX96;
            amountOut = zeroForIn
                ? FullMath.mulDiv(ratioX192, amountIn, 1 << 192)
                : FullMath.mulDiv(1 << 192, amountIn, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 64);
            amountOut = zeroForIn
                ? FullMath.mulDiv(ratioX128, amountIn, 1 << 128)
                : FullMath.mulDiv(1 << 128, amountIn, ratioX128);
        }
    }

    function _upNftPositionCache(
        bool zeroForSaleToken,
        LoanInfo memory loan,
        NftPositionCache memory cache
    ) internal view {
        int24 tickLower;
        int24 tickUpper;
        // Get the positions data from `PositionManager` and store it in the cache variables
        (
            ,
            ,
            cache.saleToken,
            cache.holdToken,
            cache.fee,
            tickLower,
            tickUpper,
            ,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(UNDERLYING_POSITION_MANAGER_ADDRESS).positions(
            loan.tokenId
        );
        {
            address poolAddress = computePoolAddress(cache.saleToken, cache.holdToken, cache.fee);
            (cache.entrySqrtPriceX96, cache.entryTick, , , , , ) = IUniswapV3Pool(poolAddress)
                .slot0();

            cache.lowerSqrtPriceX96 = TickMath.getSqrtRatioAtTick(tickLower);
            cache.upperSqrtPriceX96 = TickMath.getSqrtRatioAtTick(tickUpper);

            cache.holdTokenDebt = _getSingleSideRoundUpAmount(
                zeroForSaleToken,
                cache.lowerSqrtPriceX96,
                cache.upperSqrtPriceX96,
                loan.liquidity
            );
        }
        if (!zeroForSaleToken) {
            // Swap saleToken and holdToken if zeroForSaleToken is false
            (cache.saleToken, cache.holdToken) = (cache.holdToken, cache.saleToken);
        }

        cache.marginDepo = _optimisticHoldTokenAmountForLiquidity(
            zeroForSaleToken,
            cache.entrySqrtPriceX96,
            cache.lowerSqrtPriceX96,
            cache.upperSqrtPriceX96,
            loan.liquidity,
            cache.holdTokenDebt
        );
    }

    function _getSingleSideRoundUpAmount(
        bool zeroForSaleToken,
        uint160 lowerSqrtPriceX96,
        uint160 upperSqrtPriceX96,
        uint128 liquidity
    ) private pure returns (uint256 amount) {
        amount = (
            zeroForSaleToken
                ? AmountsLiquidity.getAmount1RoundingUpForLiquidity(
                    lowerSqrtPriceX96,
                    upperSqrtPriceX96,
                    liquidity
                )
                : AmountsLiquidity.getAmount0RoundingUpForLiquidity(
                    lowerSqrtPriceX96,
                    upperSqrtPriceX96,
                    liquidity
                )
        );
    }

    function computePoolAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (address pool) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            UNDERLYING_V3_FACTORY_ADDRESS,
                            keccak256(abi.encode(tokenA, tokenB, fee)),
                            UNDERLYING_V3_POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: SAL-1.0
pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVault.sol";
import { TransferHelper } from "./libraries/TransferHelper.sol";

contract Vault is Ownable, IVault {
    using TransferHelper for address;

    /**
     * @notice Transfers tokens to a specified address
     * @param _token The address of the token to be transferred
     * @param _to The address to which the tokens will be transferred
     * @param _amount The amount of tokens to be transferred
     */
    function transferToken(address _token, address _to, uint256 _amount) external onlyOwner {
        if (_amount > 0) {
            _token.safeTransfer(_to, _amount);
        }
    }

    /**
     * @dev Retrieves the balances of multiple tokens for this contract.
     * @param tokens The array of token addresses for which to retrieve the balances.
     * @return balances An array of uint256 values representing the balances of the corresponding tokens in the `tokens` array.
     */
    function getBalances(
        address[] calldata tokens
    ) external view returns (uint256[] memory balances) {
        uint256 length = tokens.length;
        balances = new uint256[](length);
        for (uint256 i; i < length; ) {
            balances[i] = tokens[i].getBalance();
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/*
 * @author Uniswap
 * @notice Library from Uniswap
 */
library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

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
        r = (r + x / r) >> 1;

        uint256 r1 = x / r;

        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                r += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                r += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                r += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                r += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                r += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                r += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                r += 2;
            }
            if (x >= 0x2) r += 1;
        }
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            r = 255;
            if (x & type(uint128).max > 0) {
                r -= 128;
            } else {
                x >>= 128;
            }
            if (x & type(uint64).max > 0) {
                r -= 64;
            } else {
                x >>= 64;
            }
            if (x & type(uint32).max > 0) {
                r -= 32;
            } else {
                x >>= 32;
            }
            if (x & type(uint16).max > 0) {
                r -= 16;
            } else {
                x >>= 16;
            }
            if (x & type(uint8).max > 0) {
                r -= 8;
            } else {
                x >>= 8;
            }
            if (x & 0xf > 0) {
                r -= 4;
            } else {
                x >>= 4;
            }
            if (x & 0x3 > 0) {
                r -= 2;
            } else {
                x >>= 2;
            }
            if (x & 0x1 > 0) r -= 1;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0 = a * b; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the preconditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import { FullMath } from "./FullMath.sol";
import { FixedPoint96 } from "./FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return
                toUint128(
                    FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96)
                );
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96)
                (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                FullMath.mulDiv(
                    uint256(liquidity) << FixedPoint96.RESOLUTION,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                ) / sqrtRatioAX96;
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafeCast} from './SafeCast.sol';

import {FullMath} from './FullMath.sol';
import {UnsafeMath} from './UnsafeMath.sol';
import {FixedPoint96} from './FixedPoint96.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            unchecked {
                uint256 product;
                if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                    uint256 denominator = numerator1 + product;
                    if (denominator >= numerator1)
                        // always fits in 160 bits
                        return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
                }
            }
            // denominator is checked for overflow
            return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96) + amount));
        } else {
            unchecked {
                uint256 product;
                // if the product overflows, we know the denominator underflows
                // in addition, we must check that the denominator does not underflow
                require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
                uint256 denominator = numerator1 - product;
                return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
            }
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? (amount << FixedPoint96.RESOLUTION) / liquidity
                    : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
            );

            return (uint256(sqrtPX96) + quotient).toUint160();
        } else {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
                    : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
            );

            require(sqrtPX96 > quotient);
            // always fits 160 bits
            unchecked {
                return uint160(sqrtPX96 - quotient);
            }
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
                : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
                : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
            uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

            require(sqrtRatioAX96 > 0);

            return
                roundUp
                    ? UnsafeMath.divRoundingUp(
                        FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                        sqrtRatioAX96
                    )
                    : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
        }
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                roundUp
                    ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                    : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        unchecked {
            return
                liquidity < 0
                    ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                    : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
        }
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        unchecked {
            return
                liquidity < 0
                    ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                    : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {FullMath} from './FullMath.sol';
import {SqrtPriceMath} from './SqrtPriceMath.sol';

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        unchecked {
            bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
            bool exactIn = amountRemaining >= 0;

            if (exactIn) {
                uint256 amountRemainingLessFee = FullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);
                amountIn = zeroForOne
                    ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
                if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
                else
                    sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                        sqrtRatioCurrentX96,
                        liquidity,
                        amountRemainingLessFee,
                        zeroForOne
                    );
            } else {
                amountOut = zeroForOne
                    ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
                if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
                else
                    sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                        sqrtRatioCurrentX96,
                        liquidity,
                        uint256(-amountRemaining),
                        zeroForOne
                    );
            }

            bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

            // get the input/output amounts
            if (zeroForOne) {
                amountIn = max && exactIn
                    ? amountIn
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true);
                amountOut = max && !exactIn
                    ? amountOut
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false);
            } else {
                amountIn = max && exactIn
                    ? amountIn
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
                amountOut = max && !exactIn
                    ? amountOut
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
            }

            // cap the output amount to not exceed the remaining output amount
            if (!exactIn && amountOut > uint256(-amountRemaining)) {
                amountOut = uint256(-amountRemaining);
            }

            if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
                // we didn't reach the target, so take the remainder of the maximum input as fee
                feeAmount = uint256(amountRemaining) - amountIn;
            } else {
                feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafeCast} from './SafeCast.sol';

import {TickMath} from './TickMath.sol';

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations
library Tick {
    error LO();

    using SafeCast for int256;

    // info stored for each initialized individual tick
    struct Info {
        // the total position liquidity that references this tick
        uint128 liquidityGross;
        // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        int128 liquidityNet;
        // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        // the cumulative tick value on the other side of the tick
        int56 tickCumulativeOutside;
        // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint160 secondsPerLiquidityOutsideX128;
        // the seconds spent on the other side of the tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint32 secondsOutside;
        // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
        // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
        bool initialized;
    }

    /// @notice Derives max liquidity per tick from given tick spacing
    /// @dev Executed within the pool constructor
    /// @param tickSpacing The amount of required tick separation, realized in multiples of `tickSpacing`
    ///     e.g., a tickSpacing of 3 requires ticks to be initialized every 3rd tick i.e., ..., -6, -3, 0, 3, 6, ...
    /// @return The max liquidity per tick
    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) internal pure returns (uint128) {
        unchecked {
            int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
            int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
            uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
            return type(uint128).max / numTicks;
        }
    }

    /// @notice Retrieves fee growth data
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @param tickCurrent The current tick
    /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @return feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @return feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function getFeeGrowthInside(
        mapping(int24 => Tick.Info) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        unchecked {
            Info storage lower = self[tickLower];
            Info storage upper = self[tickUpper];

            // calculate fee growth below
            uint256 feeGrowthBelow0X128;
            uint256 feeGrowthBelow1X128;
            if (tickCurrent >= tickLower) {
                feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
                feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
            } else {
                feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
                feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
            }

            // calculate fee growth above
            uint256 feeGrowthAbove0X128;
            uint256 feeGrowthAbove1X128;
            if (tickCurrent < tickUpper) {
                feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
                feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
            } else {
                feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
                feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
            }

            feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
            feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
        }
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be updated
    /// @param tickCurrent The current tick
    /// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
    /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulativeX128 The all-time seconds per max(1, liquidity) of the pool
    /// @param tickCumulative The tick * time elapsed since the pool was first initialized
    /// @param time The current block timestamp cast to a uint32
    /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
    /// @param maxLiquidity The maximum liquidity allocation for a single tick
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time,
        bool upper,
        uint128 maxLiquidity
    ) internal returns (bool flipped) {
        Tick.Info storage info = self[tick];

        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = liquidityDelta < 0
            ? liquidityGrossBefore - uint128(-liquidityDelta)
            : liquidityGrossBefore + uint128(liquidityDelta);

        if (liquidityGrossAfter > maxLiquidity) revert LO();

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (liquidityGrossBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (tick <= tickCurrent) {
                info.feeGrowthOutside0X128 = feeGrowthGlobal0X128;
                info.feeGrowthOutside1X128 = feeGrowthGlobal1X128;
                info.secondsPerLiquidityOutsideX128 = secondsPerLiquidityCumulativeX128;
                info.tickCumulativeOutside = tickCumulative;
                info.secondsOutside = time;
            }
            info.initialized = true;
        }

        info.liquidityGross = liquidityGrossAfter;

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        info.liquidityNet = upper ? info.liquidityNet - liquidityDelta : info.liquidityNet + liquidityDelta;
    }

    /// @notice Clears tick data
    /// @param self The mapping containing all initialized tick information for initialized ticks
    /// @param tick The tick that will be cleared
    function clear(mapping(int24 => Tick.Info) storage self, int24 tick) internal {
        delete self[tick];
    }

    /// @notice Transitions to next tick as needed by price movement
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The destination tick of the transition
    /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulativeX128 The current seconds per liquidity
    /// @param tickCumulative The tick * time elapsed since the pool was first initialized
    /// @param time The current block.timestamp
    /// @return liquidityNet The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    function cross(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time
    ) internal returns (int128 liquidityNet) {
        unchecked {
            Tick.Info storage info = self[tick];
            info.feeGrowthOutside0X128 = feeGrowthGlobal0X128 - info.feeGrowthOutside0X128;
            info.feeGrowthOutside1X128 = feeGrowthGlobal1X128 - info.feeGrowthOutside1X128;
            info.secondsPerLiquidityOutsideX128 =
                secondsPerLiquidityCumulativeX128 -
                info.secondsPerLiquidityOutsideX128;
            info.tickCumulativeOutside = tickCumulative - info.tickCumulativeOutside;
            info.secondsOutside = time - info.secondsOutside;
            liquidityNet = info.liquidityNet;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BitMath} from './BitMath.sol';

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        unchecked {
            wordPos = int16(tick >> 8);
            bitPos = uint8(int8(tick % 256));
        }
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    /// @param tickSpacing The spacing between usable ticks
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        unchecked {
            require(tick % tickSpacing == 0); // ensure that the tick is spaced
            (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
            uint256 mask = 1 << bitPos;
            self[wordPos] ^= mask;
        }
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        unchecked {
            int24 compressed = tick / tickSpacing;
            if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

            if (lte) {
                (int16 wordPos, uint8 bitPos) = position(compressed);
                // all the 1s at or to the right of the current bitPos
                uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
                uint256 masked = self[wordPos] & mask;

                // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                    : (compressed - int24(uint24(bitPos))) * tickSpacing;
            } else {
                // start from the word of the next tick, since the current tick state doesn't matter
                (int16 wordPos, uint8 bitPos) = position(compressed + 1);
                // all the 1s at or to the left of the bitPos
                uint256 mask = ~((1 << bitPos) - 1);
                uint256 masked = self[wordPos] & mask;

                // if there are no initialized ticks to the left of the current tick, return leftmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                    : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @notice Thrown when the tick passed to #getSqrtRatioAtTick is not between MIN_TICK and MAX_TICK
    error InvalidTick();
    /// @notice Thrown when the ratio passed to #getTickAtSqrtRatio does not correspond to a price between MIN_TICK and MAX_TICK
    error InvalidSqrtRatio();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Given a tickSpacing, compute the maximum usable tick
    function maxUsableTick(int24 tickSpacing) internal pure returns (int24) {
        unchecked {
            return (MAX_TICK / tickSpacing) * tickSpacing;
        }
    }

    /// @notice Given a tickSpacing, compute the minimum usable tick
    function minUsableTick(int24 tickSpacing) internal pure returns (int24) {
        unchecked {
            return (MIN_TICK / tickSpacing) * tickSpacing;
        }
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (currency1/currency0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert InvalidTick();

            uint256 ratio =
                absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO) revert InvalidSqrtRatio();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}