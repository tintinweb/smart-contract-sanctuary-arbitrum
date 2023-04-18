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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
interface IERC165 {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library CTHelpers {
    /// @dev Constructs a condition ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function getConditionId(address oracle, bytes32 questionId, uint outcomeSlotCount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount));
    }

    uint constant P = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint constant B = 3;

    function sqrt(uint x) private pure returns (uint y) {
        uint p = P;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // add chain generated via https://crypto.stackexchange.com/q/27179/71252
            // and transformed to the following program:

            // x=1; y=x+x; z=y+y; z=z+z; y=y+z; x=x+y; y=y+x; z=y+y; t=z+z; t=z+t; t=t+t;
            // t=t+t; z=z+t; x=x+z; z=x+x; z=z+z; y=y+z; z=y+y; z=z+z; z=z+z; z=y+z; x=x+z;
            // z=x+x; z=z+z; z=z+z; z=x+z; y=y+z; x=x+y; z=x+x; z=z+z; y=y+z; z=y+y; t=z+z;
            // t=t+t; t=t+t; z=z+t; x=x+z; y=y+x; z=y+y; z=z+z; z=z+z; x=x+z; z=x+x; z=z+z;
            // z=x+z; z=z+z; z=z+z; z=x+z; y=y+z; z=y+y; t=z+z; t=t+t; t=z+t; t=y+t; t=t+t;
            // t=t+t; t=t+t; t=t+t; z=z+t; x=x+z; z=x+x; z=x+z; y=y+z; z=y+y; z=y+z; z=z+z;
            // t=z+z; t=z+t; w=t+t; w=w+w; w=w+w; w=w+w; w=w+w; t=t+w; z=z+t; x=x+z; y=y+x;
            // z=y+y; x=x+z; y=y+x; x=x+y; y=y+x; x=x+y; z=x+x; z=x+z; z=z+z; y=y+z; z=y+y;
            // z=z+z; x=x+z; y=y+x; z=y+y; z=y+z; x=x+z; y=y+x; x=x+y; y=y+x; z=y+y; z=z+z;
            // z=y+z; x=x+z; z=x+x; z=x+z; y=y+z; x=x+y; y=y+x; x=x+y; y=y+x; z=y+y; z=y+z;
            // z=z+z; x=x+z; y=y+x; z=y+y; z=y+z; z=z+z; x=x+z; z=x+x; t=z+z; t=t+t; t=z+t;
            // t=x+t; t=t+t; t=t+t; t=t+t; t=t+t; z=z+t; y=y+z; x=x+y; y=y+x; x=x+y; z=x+x;
            // z=x+z; z=z+z; z=z+z; z=z+z; z=x+z; y=y+z; z=y+y; z=y+z; z=z+z; x=x+z; z=x+x;
            // z=x+z; y=y+z; x=x+y; z=x+x; z=z+z; y=y+z; x=x+y; z=x+x; y=y+z; x=x+y; y=y+x;
            // z=y+y; z=y+z; x=x+z; y=y+x; z=y+y; z=y+z; z=z+z; z=z+z; x=x+z; z=x+x; z=z+z;
            // z=z+z; z=x+z; y=y+z; x=x+y; z=x+x; t=x+z; t=t+t; t=t+t; z=z+t; y=y+z; z=y+y;
            // x=x+z; y=y+x; x=x+y; y=y+x; x=x+y; y=y+x; z=y+y; t=y+z; z=y+t; z=z+z; z=z+z;
            // z=t+z; x=x+z; y=y+x; x=x+y; y=y+x; x=x+y; z=x+x; z=x+z; y=y+z; x=x+y; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; res=y+x
            // res == (P + 1) // 4

            y := mulmod(x, x, p)
            {
                let z := mulmod(y, y, p)
                z := mulmod(z, z, p)
                y := mulmod(y, z, p)
                x := mulmod(x, y, p)
                y := mulmod(y, x, p)
                z := mulmod(y, y, p)
                {
                    let t := mulmod(z, z, p)
                    t := mulmod(z, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    z := mulmod(z, t, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(y, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    t := mulmod(z, z, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    z := mulmod(z, t, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    z := mulmod(x, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    t := mulmod(z, z, p)
                    t := mulmod(t, t, p)
                    t := mulmod(z, t, p)
                    t := mulmod(y, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    z := mulmod(z, t, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    z := mulmod(z, z, p)
                    t := mulmod(z, z, p)
                    t := mulmod(z, t, p)
                    {
                        let w := mulmod(t, t, p)
                        w := mulmod(w, w, p)
                        w := mulmod(w, w, p)
                        w := mulmod(w, w, p)
                        w := mulmod(w, w, p)
                        t := mulmod(t, w, p)
                    }
                    z := mulmod(z, t, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    z := mulmod(x, z, p)
                    z := mulmod(z, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(z, z, p)
                    z := mulmod(y, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    t := mulmod(z, z, p)
                    t := mulmod(t, t, p)
                    t := mulmod(z, t, p)
                    t := mulmod(x, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    z := mulmod(z, t, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    z := mulmod(x, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    t := mulmod(x, z, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    z := mulmod(z, t, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    t := mulmod(y, z, p)
                    z := mulmod(y, t, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(t, z, p)
                }
                x := mulmod(x, z, p)
                y := mulmod(y, x, p)
                x := mulmod(x, y, p)
                y := mulmod(y, x, p)
                x := mulmod(x, y, p)
                z := mulmod(x, x, p)
                z := mulmod(x, z, p)
                y := mulmod(y, z, p)
            }
            x := mulmod(x, y, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            y := mulmod(y, x, p)
        }
    }

    /// @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
    /// @param parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
    /// @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
    function getCollectionId(bytes32 parentCollectionId, bytes32 conditionId, uint indexSet) internal view returns (bytes32) {
        uint x1 = uint(keccak256(abi.encodePacked(conditionId, indexSet)));
        bool odd = x1 >> 255 != 0;
        uint y1;
        uint yy;
        do {
            x1 = addmod(x1, 1, P);
            yy = addmod(mulmod(x1, mulmod(x1, x1, P), P), B, P);
            y1 = sqrt(yy);
        } while(mulmod(y1, y1, P) != yy);
        if(odd && y1 % 2 == 0 || !odd && y1 % 2 == 1)
            y1 = P - y1;

        uint x2 = uint(parentCollectionId);
        if(x2 != 0) {
            odd = x2 >> 254 != 0;
            x2 = (x2 << 2) >> 2;
            yy = addmod(mulmod(x2, mulmod(x2, x2, P), P), B, P);
            uint y2 = sqrt(yy);
            if(odd && y2 % 2 == 0 || !odd && y2 % 2 == 1)
                y2 = P - y2;
            require(mulmod(y2, y2, P) == yy, "invalid parent collection ID");

            (bool success, bytes memory ret) = address(6).staticcall(abi.encode(x1, y1, x2, y2));
            require(success, "ecadd failed");
            (x1, y1) = abi.decode(ret, (uint, uint));
        }

        if(y1 % 2 == 1)
            x1 ^= 1 << 254;

        return bytes32(x1);
    }

    /// @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(IERC20 collateralToken, bytes32 collectionId) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(collateralToken, collectionId)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IConditionalTokens {
    function splitPosition(
        address collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint[] calldata partition,
        uint amount
    ) external;
    function mergePositions(
        address collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint[] calldata partition,
        uint amount
    ) external;
    function reportPayouts(bytes32 questionId, uint[] calldata payouts) external;
    function prepareCondition(address oracle, bytes32 questionId, uint outcomeSlotCount) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;
    function balanceOf(address owner, uint256 id) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IConditionalTokens.sol";

/**
 * @dev This contract is an on chain orderbook for 2 outcome markets. It is created and managed by the MarketFactory contract.
 * The market uses gnosis' ConditionalToken framework as the settlement layer.
 */
contract Market is Ownable, ReentrancyGuard, ERC1155Holder {

    struct BidData {
        uint256 price;
        uint256 amountShares;
        address creator;
        bytes32 nextBestOrderId;
        bool isConditionalTokenShares;
    }

    bytes32 public constant EMPTY_BYTES = bytes32(0);

    uint[] public BINARY_PARTITION = [1, 2];
    bool public isMarketActive = true;

    // The token all trades are settled in (USDC)
    address public collateralToken;
    // The conditional token for the market
    address public conditionalToken;
    // The conditionId of the market
    bytes32 public conditionId;
    // Collateral token decimals
    uint public collateralTokenDecimals;
    // Min amount of collateral per limit order
    uint public minAmount;
    // Fee on volume (in 1e6)
    uint public fee;
    // Fee recipient
    address feeRecipient;

    // outcome (0,1) => positionId (in conditional tokens)
    mapping (uint => uint) public outcomePositionIds;
    // outcome (0,1) => bidCount
    mapping (uint => uint) public outcomeBidCount;
    // outcome (0,1) => bestBid (id)
    mapping (uint => bytes32) public bestBid;
    // outcome (0,1) => orderId => BidData
    mapping(uint => mapping(bytes32 => BidData)) public outcomeBids;

    event NewBid(uint indexed outcome, uint price, uint amount, address indexed creator, bool isConditionalTokenShares);
    event NewBestBid(uint indexed outcome, uint price, uint amount, address indexed creator, bool isConditionalTokenShares, uint256 timestamp);

    modifier validPrice(uint price) {
        require(0 < price && price < 1e6, "E2");
        _;
    }

    constructor(
        address _collateralToken,
        address _conditionalToken,
        bytes32 _conditionId,
        uint _positionIdOutcome0,
        uint _positionIdOutcome1,
        uint _minAmount,
        uint _fee,
        address _feeRecipient
    ) {
        require(_fee <= 1e5, "Fee cannot be greater than 10%");
        collateralToken = _collateralToken;
        conditionalToken = _conditionalToken;
        conditionId = _conditionId;
        outcomePositionIds[0] = _positionIdOutcome0;
        outcomePositionIds[1] = _positionIdOutcome1;
        minAmount = _minAmount;
        fee = _fee;
        feeRecipient = _feeRecipient;
        collateralTokenDecimals = ERC20(_collateralToken).decimals();
        IERC20(_collateralToken).approve(_conditionalToken, type(uint256).max);
    }

    /**
     * @dev Places a limit order for a given outcome, fills any existing orders first if possible.
     * Amount in denominated in collateral token.
     * 
     * @param outcome The desired outcome to buy
     * @param price The desired price to buy outcome shares at
     * @param amountCollateral The desired amount of collateral to use
     */
    function limitOrderCollateral(uint outcome, uint price, uint amountCollateral) public nonReentrant validPrice(price) returns (bytes32) {
        require(amountCollateral >= minAmount, "E3");
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amountCollateral);
        uint amountShares = (amountCollateral * 1e6) / price;

        return _limitOrder(outcome, price, amountShares);
    }

    /**
     * @dev Places a limit order for a given outcome, fills any existing orders first if possible.
     * Amount in denominated in conditional token shares. 
     * 
     * @param outcome The desired outcome to buy
     * @param price The desired price to buy outcome shares at
     * @param amountShares The desired amount of shares to buy
     */
    function limitOrder(uint outcome, uint price, uint amountShares) public nonReentrant validPrice(price) returns (bytes32) {
        uint amountCollateral = (amountShares * price) / 1e6;
        require(amountCollateral >= minAmount, "E3");
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amountCollateral);

        return _limitOrder(outcome, price, amountShares);
    }

    /**
     * @dev Places a limit order for a given outcome, fills any existing orders first if possible.
     * 
     * @param outcome The desired outcome to buy
     * @param price The desired price to buy outcome shares at
     * @param amountShares The desired amount of shares to sell
     */
    function limitOrderSell(uint outcome, uint price, uint amountShares) public nonReentrant returns (bytes32) {
        require(isMarketActive, "E1");
        require(0 < price && price < 1e6, "E2");

        IConditionalTokens(conditionalToken).safeTransferFrom(
            msg.sender, 
            address(this),
            outcomePositionIds[outcome], 
            amountShares,
            new bytes(0)
        );

        uint collateralAmount = amountShares * price / 1e6;
        require(collateralAmount >= minAmount, "E3");

        amountShares = _fillOrdersShares(outcome, price, amountShares);
        if (amountShares == 0) return EMPTY_BYTES;
        uint oppositeOutcome = 1 - outcome;
        uint bidPrice = 1e6 - price;
        return _postOrder(oppositeOutcome, bidPrice, amountShares, true);
    }

    /**
     * @dev Sells a given amount of shares for the best price possible, for at.
     * 
     * @param outcome The desired outcome shares to sell
     * @param amountShares The desired amount of shares to sell
     * @param maxPrice The max price to sell shares at.
     */
    function marketSell(uint outcome, uint amountShares, uint maxPrice) public nonReentrant {
        require(isMarketActive, "E1");
        IConditionalTokens(conditionalToken).safeTransferFrom(
            msg.sender, 
            address(this),
            outcomePositionIds[outcome], 
            amountShares,
            new bytes(0)
        );
        require(bestBid[outcome] != bytes32(0), "E3");

        amountShares = _fillOrdersShares(outcome, 1e6 - maxPrice, amountShares);
        if (amountShares > 0) {
            IConditionalTokens(conditionalToken).safeTransferFrom(
                address(this),
                msg.sender, 
                outcomePositionIds[outcome], 
                amountShares,
                new bytes(0)
            );
        }
    }


    /**
     * @dev Buy a given amount of shares for the best price possible, for at most maxPrice.
     * 
     * @param outcome The desired outcome shares to buy
     * @param amount The desired amount of collateral tokens to buy with
     * @param maxPrice The max price to buy shares at.
     */
    function marketBuy(uint outcome, uint amount, uint maxPrice) public nonReentrant {
        require(isMarketActive, "E1");
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        uint oppositeOutcome = 1 - outcome;
        require(bestBid[oppositeOutcome] != bytes32(0), "E3");
        amount = _fillOrdersCollateralToken(outcome, maxPrice, amount);
        if (amount > 0) IERC20(collateralToken).transfer(msg.sender, amount);
    }

    /**
     * @dev Cancels an order.
     * 
     * @param outcome The outcome to cancel orders for
     * @param orderId The orderId of the order to cancel
     * @param prevBestOrderId The max price to buy shares at.
     */
    function cancelOrder(uint outcome, bytes32 orderId, bytes32 prevBestOrderId) external {
        require(outcomeBids[outcome][orderId].creator == msg.sender, "E5");
        if (prevBestOrderId == bytes32(0)) {
            require(bestBid[outcome] == orderId, "E6");
            bestBid[outcome] = outcomeBids[outcome][orderId].nextBestOrderId;
        } else {
            require(outcomeBids[outcome][prevBestOrderId].nextBestOrderId == orderId, "E7");
            outcomeBids[outcome][prevBestOrderId].nextBestOrderId = outcomeBids[outcome][orderId].nextBestOrderId;
        }

        uint amountShares = outcomeBids[outcome][orderId].amountShares;
        outcomeBids[outcome][orderId].amountShares = 0;
        if (outcomeBids[outcome][orderId].isConditionalTokenShares) {
            uint oppositeOutcome = 1 - outcome;
            IConditionalTokens(conditionalToken).safeTransferFrom(
                address(this),
                msg.sender, 
                outcomePositionIds[oppositeOutcome], 
                amountShares,
                new bytes(0)
            );
        } else {
            uint collateralAmount = amountShares * outcomeBids[outcome][orderId].price / 1e6;
            IERC20(collateralToken).transfer(msg.sender, collateralAmount);
        }
        outcomeBidCount[outcome]--;
    }

    /**
     * @dev Bulk cancels orders, owner only when market is paused.
     * 
     * @param limit The max number of orders to cancel
     */
    function bulkCancelOrders(uint limit) external onlyOwner {
        require(!isMarketActive, "E1");
        uint i = 0;
        uint outcome = 0;
        while (i < limit) {
            bytes32 orderId = bestBid[outcome];
            if (orderId == bytes32(0)) {
                outcome++;
                if (outcome == 2) break;
                continue; 
            }
            BidData memory bid = outcomeBids[outcome][orderId];
            outcomeBids[outcome][orderId].amountShares = 0;
            if (bid.isConditionalTokenShares) {
                uint oppositeOutcome = 1 - outcome;
                IConditionalTokens(conditionalToken).safeTransferFrom(
                    address(this),
                    bid.creator,
                    outcomePositionIds[oppositeOutcome], 
                    bid.amountShares,
                    new bytes(0)
                );
            } else {
                uint collateralAmount = bid.amountShares * bid.price / 1e6;
                IERC20(collateralToken).transfer(bid.creator, collateralAmount);
            }
            bestBid[outcome] = bid.nextBestOrderId;
            outcomeBidCount[outcome]--;
            i++;
        }
    }

    function _limitOrder(uint outcome, uint price, uint amountShares) internal returns (bytes32) {
        require(isMarketActive, "E1");
        require(0 < price && price < 1e6, "E2");

        amountShares = _fillOrders(outcome, 1e6 - price, amountShares);
        if (amountShares == 0) return EMPTY_BYTES;
        return _postOrder(outcome, price, amountShares, false);
    }

    function _postOrder(uint outcome, uint price, uint amount, bool isConditionalShares) internal returns (bytes32) {
        bytes32 orderId = keccak256(abi.encodePacked(outcome, msg.sender, price, amount));
        require(outcomeBids[outcome][orderId].creator == address(0), "Order with these details already exists");

        bytes32 bestBidOrderId = bestBid[outcome];
        // If first bid
        if (bestBidOrderId == bytes32(0)) {
            bestBid[outcome] = orderId;
            outcomeBids[outcome][orderId] = BidData(price, amount, msg.sender, bytes32(0), isConditionalShares);
            emit NewBestBid(outcome, price, amount, msg.sender, isConditionalShares, block.timestamp);
        } else {
            // If best bid
            if (outcomeBids[outcome][bestBidOrderId].price < price) {
                outcomeBids[outcome][orderId] = BidData(price, amount, msg.sender, bestBidOrderId, isConditionalShares);
                bestBid[outcome] = orderId;
                emit NewBestBid(outcome, price, amount, msg.sender, isConditionalShares, block.timestamp );
            } else {
                // If not best bid
                bytes32 currentBestOrderId = bestBidOrderId;
                bytes32 nextBestOrderId = outcomeBids[outcome][currentBestOrderId].nextBestOrderId;
                while (nextBestOrderId != bytes32(0)) {
                    if (outcomeBids[outcome][nextBestOrderId].price < price) {
                        outcomeBids[outcome][currentBestOrderId].nextBestOrderId = orderId;
                        outcomeBids[outcome][orderId].nextBestOrderId = nextBestOrderId;
                        outcomeBids[outcome][orderId] = BidData(price, amount, msg.sender, nextBestOrderId, isConditionalShares);
                        break;
                    }
                    currentBestOrderId = nextBestOrderId;
                    nextBestOrderId = outcomeBids[outcome][currentBestOrderId].nextBestOrderId;
                }
                // If worst bid
                if (nextBestOrderId == bytes32(0)) {
                    outcomeBids[outcome][currentBestOrderId].nextBestOrderId = orderId;
                    outcomeBids[outcome][orderId] = BidData(price, amount, msg.sender, bytes32(0), isConditionalShares);
                }
            }
        }
        outcomeBidCount[outcome]++;
        emit NewBid(outcome, price, amount, msg.sender, isConditionalShares);
        return orderId;
    }

    /**
     * @dev Fills orders up until `maxPrice` and `amount` is reached. Returns the remaining amount.
     */
    function _fillOrdersShares(uint outcome, uint maxPrice, uint amountShares) internal returns (uint) {
        bytes32 bestBidOrderId = bestBid[outcome];

        while (amountShares > 0) {
            uint bestBidAmount = outcomeBids[outcome][bestBidOrderId].amountShares;
            uint bestBidPrice = outcomeBids[outcome][bestBidOrderId].price;
            if (bestBidAmount == 0 || bestBidPrice < maxPrice) break;

            uint finalAmountShares = bestBidAmount > amountShares ? amountShares : bestBidAmount;
            outcomeBids[outcome][bestBidOrderId].amountShares -= finalAmountShares;
            amountShares -= finalAmountShares;
            if (outcomeBids[outcome][bestBidOrderId].isConditionalTokenShares) {
                IConditionalTokens(conditionalToken).mergePositions(
                    collateralToken,
                    EMPTY_BYTES, 
                    conditionId,
                    BINARY_PARTITION,
                    finalAmountShares
                );
                _transferTokensWithFee(
                    outcomeBids[outcome][bestBidOrderId].creator,
                    outcomeBids[outcome][bestBidOrderId].price * 1e6 / finalAmountShares
                );
                _transferTokensWithFee(
                    msg.sender,
                    (1e6 - outcomeBids[outcome][bestBidOrderId].price) * 1e6 / finalAmountShares
                );
            } else {
                uint collateralAmount = finalAmountShares * outcomeBids[outcome][bestBidOrderId].price / 1e6;
                _transferConditionalTokensWithFee(
                    outcomeBids[outcome][bestBidOrderId].creator,
                    outcomePositionIds[outcome],
                    finalAmountShares
                );
                _transferTokensWithFee(msg.sender, collateralAmount);
            }
            if (bestBidAmount <= finalAmountShares) {
                bestBidOrderId = outcomeBids[outcome][bestBidOrderId].nextBestOrderId;
                outcomeBidCount[outcome]--;
            }
        }
        
        bestBid[outcome] = bestBidOrderId;
        return amountShares;
    }

    /**
     * @dev Fills orders up until `maxPrice` and `amount` is reached. Returns the remaining amount.
     */
    function _fillOrders(uint outcome, uint maxPrice, uint amountShares) internal returns (uint) {
        uint oppositeOutcome = 1 - outcome;
        bytes32 bestBidOrderId = bestBid[oppositeOutcome];
        if (bestBidOrderId == bytes32(0)) return amountShares;

        while (amountShares > 0) {
            uint bestBidAmount = outcomeBids[oppositeOutcome][bestBidOrderId].amountShares;
            uint bestBidPrice = outcomeBids[oppositeOutcome][bestBidOrderId].price;
            if (bestBidAmount == 0 || bestBidPrice < maxPrice) break;

            uint finalAmountShares = bestBidAmount > amountShares ? amountShares : bestBidAmount;
            uint collateralAmount = finalAmountShares * outcomeBids[oppositeOutcome][bestBidOrderId].price / 1e6;
            outcomeBids[oppositeOutcome][bestBidOrderId].amountShares -= finalAmountShares;
            amountShares -= amountShares * maxPrice / bestBidPrice;
            if (outcomeBids[oppositeOutcome][bestBidOrderId].isConditionalTokenShares) {
                // transfer shares to msg.sender
                _transferConditionalTokensWithFee(
                    msg.sender,
                    outcomePositionIds[outcome],
                    finalAmountShares
                );
                _transferTokensWithFee(
                    outcomeBids[oppositeOutcome][bestBidOrderId].creator,
                    collateralAmount
                );
            } else {
                _splitConditionalTokens(
                    outcomeBids[oppositeOutcome][bestBidOrderId].creator,
                    oppositeOutcome,
                    msg.sender,
                    outcome,
                    finalAmountShares
                );
            }
            if (bestBidAmount <= finalAmountShares) {
                bestBidOrderId = outcomeBids[oppositeOutcome][bestBidOrderId].nextBestOrderId;
                outcomeBidCount[oppositeOutcome]--;
            }
        }

        bestBid[oppositeOutcome] = bestBidOrderId;
        return amountShares;
    }

    /**
     * @dev Fills orders up until `maxPrice` and `amount` is reached. Returns the remaining amount.
     */
    function _fillOrdersCollateralToken(uint outcome, uint maxPrice, uint amountCollateral) internal returns (uint) {
        uint oppositeOutcome = 1 - outcome;
        bytes32 bestBidOrderId = bestBid[oppositeOutcome];
        if (bestBidOrderId == bytes32(0)) return amountCollateral;

        // Rounding
        while (amountCollateral > 1) {
            uint bestBidAmount = outcomeBids[oppositeOutcome][bestBidOrderId].amountShares;
            uint bestBidPrice = outcomeBids[oppositeOutcome][bestBidOrderId].price;
            if (bestBidAmount == 0 || bestBidPrice > maxPrice) break;

            uint amountSharesFromCollateral = amountCollateral * 1e6 / (1e6 - bestBidPrice);
            uint finalAmountShares = bestBidAmount > amountSharesFromCollateral ? amountSharesFromCollateral : bestBidAmount;
            amountCollateral -= finalAmountShares * (1e6 - bestBidPrice) / 1e6;
            outcomeBids[oppositeOutcome][bestBidOrderId].amountShares -= finalAmountShares;

            if (outcomeBids[oppositeOutcome][bestBidOrderId].isConditionalTokenShares) {
                // transfer shares to msg.sender
                _transferConditionalTokensWithFee(
                    msg.sender,
                    outcomePositionIds[outcome],
                    finalAmountShares
                );
                _transferTokensWithFee(
                    outcomeBids[oppositeOutcome][bestBidOrderId].creator,
                    finalAmountShares * (1e6 - bestBidPrice) / 1e6
                );
            } else {
                _splitConditionalTokens(
                    outcomeBids[oppositeOutcome][bestBidOrderId].creator,
                    oppositeOutcome,
                    msg.sender,
                    outcome,
                    finalAmountShares
                );
            }
            if (bestBidAmount <= finalAmountShares) {
                bestBidOrderId = outcomeBids[oppositeOutcome][bestBidOrderId].nextBestOrderId;
                outcomeBidCount[oppositeOutcome]--;
            }
        }

        bestBid[oppositeOutcome] = bestBidOrderId;
        return amountCollateral;
    }

    function _splitConditionalTokens(
        address recipient1,
        uint outcomeRecipient1,
        address recipient2,
        uint outcomeRecipient2,
        uint amount
    ) internal {
            IConditionalTokens(conditionalToken).splitPosition(
                collateralToken,
                EMPTY_BYTES,
                conditionId,
                BINARY_PARTITION,
                amount
            );
            uint positionIdRecipient1 = outcomePositionIds[outcomeRecipient1];
            uint positionIdRecipient2 = outcomePositionIds[outcomeRecipient2];
            _transferConditionalTokensWithFee(
                recipient1,
                positionIdRecipient1,
                amount
            );
            _transferConditionalTokensWithFee(
                recipient2,
                positionIdRecipient2,
                amount
            );
    }

    function _transferTokensWithFee(address _to, uint _amount) internal {
        uint feeAmount = _amount * fee / 1e6;
        if (feeAmount > 0) IERC20(collateralToken).transfer(
            feeRecipient,
            feeAmount
        );
        IERC20(collateralToken).transfer(
            _to,
            _amount - feeAmount
        );
    }

    function _transferConditionalTokensWithFee(address _to, uint positionId, uint _amount) internal {
        uint feeAmount = _amount * fee / 1e6;
        if (feeAmount > 0) IConditionalTokens(conditionalToken).safeTransferFrom(
            address(this),
            feeRecipient, 
            positionId, 
            feeAmount,
            new bytes(0)
        );
        IConditionalTokens(conditionalToken).safeTransferFrom(
            address(this),
            _to, 
            positionId, 
            _amount - feeAmount,
            new bytes(0)
        );
    }

    function toggleMarketStatus() external onlyOwner {
        isMarketActive = !isMarketActive;
    }

    function setFee(uint _fee) external onlyOwner {
        require(_fee <= 1e5, "Fee cannot be greater than 10%");
        fee = _fee;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function getAllOutcomeBids(uint outcome) external view returns (BidData[] memory) {
        uint bidCount = outcomeBidCount[outcome];
        BidData[] memory bids = new BidData[](bidCount);
        bytes32 currentBestOrderId = bestBid[outcome];
        uint i = 0;
        while (currentBestOrderId != bytes32(0)) {
            bids[i] = outcomeBids[outcome][currentBestOrderId];
            currentBestOrderId = outcomeBids[outcome][currentBestOrderId].nextBestOrderId;
            i++;
        }
        return bids;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Market.sol";

contract MarketCreator {
    function createMarket(
        address _collateralToken,
        address _conditionalToken,
        bytes32 _conditionId,
        uint _positionIdOutcome0,
        uint _positionIdOutcome1,
        uint _minAmount,
        uint _fee,
        address _feeRecipient
    ) external returns (address) {
        Market market = new Market(
            _collateralToken,
            _conditionalToken,
            _conditionId,
            _positionIdOutcome0,
            _positionIdOutcome1,
            _minAmount,
            _fee,
            _feeRecipient
        );
        market.transferOwnership(msg.sender);
        return (address(market));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Market.sol";
import "./MarketCreator.sol";
import { CTHelpers } from "./CTHelpers.sol";

/**
 * @dev This contract is the factory for creating on chain orderbooks.
 * This market uses gnosis' ConditionalToken framework as the settlement layer.
 */
contract MarketFactory is Ownable {

    MarketCreator public marketCreator;
    IConditionalTokens public conditionalTokens;

    mapping (address => string) public marketQuestions;
    mapping (address => bytes32) public marketQuestionIds;
    mapping (address => bool) public marketIsResolved;

    address[] public activeMarkets;
    address[] public inactiveMarkets;

    event NewMarket(address market);

    constructor(address _marketCreator, address _conditionalTokens) {
        marketCreator = MarketCreator(_marketCreator);
        conditionalTokens = IConditionalTokens(_conditionalTokens);
    }

    /**
     * @dev Creates a new market, as well as the necessary condition and oracle in the ConditionalToken 
     * 
     * @param _collateralToken Address of the collateral token for the market
     * @param _question The two outcome question to create a market on top of
     * @param _minAmount The minimum amount of collateral that can be used to create a new order
     * @param _fee The volume based trading fee
     * @param _feeRecipient Address which will receive the fees
     */
    function createMarket(
        address _collateralToken,
        string memory _question,
        uint _minAmount,
        uint _fee,
        address _feeRecipient
    ) public onlyOwner {
        bytes32 _questionId = keccak256(abi.encodePacked(_question));
        bytes32 conditionId = CTHelpers.getConditionId(address(this), _questionId, 2);
        uint positionIdOutcome0 = CTHelpers.getPositionId(IERC20(_collateralToken), CTHelpers.getCollectionId(bytes32(0), conditionId, 1));
        uint positionIdOutcome1 = CTHelpers.getPositionId(IERC20(_collateralToken), CTHelpers.getCollectionId(bytes32(0), conditionId, 2));
        // Hardcoded binary outcome for MVP
        conditionalTokens.prepareCondition(address(this), _questionId, 2);
        address market = marketCreator.createMarket(
            _collateralToken,
            address(conditionalTokens),
            conditionId,
            positionIdOutcome0,
            positionIdOutcome1,
            _minAmount,
            _fee,
            _feeRecipient
        );
        activeMarkets.push(address(market));
        marketQuestions[market] = _question;
        marketQuestionIds[market] = _questionId;
    }

    function resolveAndCloseMarket(address market, uint[] calldata indexSets, uint limit) external onlyOwner {
        _resolveMarket(market, indexSets);
        uint index = type(uint).max;
        for (uint i = 0; i < activeMarkets.length; i++) {
            if (activeMarkets[i] == market) {
                index = i;
                break;
            }
        }
        require(index != type(uint).max, "Market not found");
        activeMarkets[index] = activeMarkets[activeMarkets.length - 1];
        activeMarkets.pop();
        inactiveMarkets.push(market);
        Market(market).toggleMarketStatus();
        Market(market).bulkCancelOrders(limit);
    }

    function resolveMarket(address market, uint[] calldata indexSets) external onlyOwner {
        _resolveMarket(market, indexSets);
    }

    function setMarketFee(address market, uint fee) external onlyOwner {
        Market(market).setFee(fee);
    }

    function setMarketFeeRecipient(address market, address recipient) external onlyOwner {
        Market(market).setFeeRecipient(recipient);
    }

    function bulkCancelOrders(address market, uint limit) external onlyOwner {
        Market(market).bulkCancelOrders(limit);
    }

    function toggleMarketStatus(address market) external onlyOwner {
        uint index = type(uint).max;
        if (Market(market).isMarketActive()) {
            for (uint i = 0; i < activeMarkets.length; i++) {
                if (activeMarkets[i] == market) {
                    index = i;
                    break;
                }
            }
            require(index != type(uint).max, "Market not found");
            activeMarkets[index] = activeMarkets[activeMarkets.length - 1];
            activeMarkets.pop();
            inactiveMarkets.push(market);
        } else {
            for (uint i = 0; i < inactiveMarkets.length; i++) {
                if (inactiveMarkets[i] == market) {
                    index = i;
                    break;
                }
            }
            require(index != type(uint).max, "Market not found");
            inactiveMarkets[index] = inactiveMarkets[inactiveMarkets.length - 1];
            inactiveMarkets.pop();
            activeMarkets.push(market);
        }
        Market(market).toggleMarketStatus();
    }

    function getAllActiveMarkets() external view returns (address[] memory, string[] memory, bool[] memory) {
        uint256 length = activeMarkets.length; 
        uint i = 0; 
        bool[] memory isResolved = new bool[](length); 
        string[] memory questions = new string[](length); 
        for ( i; i < length; i++) {
            address market = activeMarkets[i]; 
            questions[i] = marketQuestions[market]; 
            isResolved[i] = marketIsResolved[market];
        }
        return (activeMarkets, questions, isResolved);
    }

    function getAllInactiveMarkets() external view returns (address[] memory, string[] memory, bool[] memory) {
        uint256 length = inactiveMarkets.length; 
        uint i = 0; 
        bool[] memory isResolved = new bool[](length); 
        string[] memory questions = new string[](length); 
        for ( i; i < length; i++) {
            address market = inactiveMarkets[i]; 
            questions[i] = marketQuestions[market]; 
            isResolved[i] = marketIsResolved[market];
        }
        return (inactiveMarkets, questions, isResolved);
    }

    function _resolveMarket(address market, uint[] calldata indexSets) internal {
        bytes32 questionId = marketQuestionIds[market];
        conditionalTokens.reportPayouts(questionId, indexSets);
        marketIsResolved[market] = true;
    }
}