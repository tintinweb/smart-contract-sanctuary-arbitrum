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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/interfaces/IERC721Receiver.sol";
import "./interfaces/IBeefyVault.sol";
import "./interfaces/ICrossChainStablecoin.sol";
import "./interfaces/IPerfToken.sol";

contract ThreeStepQiZappah is Ownable, Pausable, IERC721Receiver{
    struct AssetChain {
        IERC20 asset;
        IPerfToken perfToken;
        ICrossChainStablecoin mooTokenVault;
        /*
        WSTETH -> @ 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb
        Call enter on PerfToken @ 0x77965B3282DFdeB258B7ad77e833ad7Ee508B878
        Call depositCollateral @ 0xdB5D7086C5198e8A4da5BD2972c8584309c3759e
        */
       
    }
    mapping (bytes32 => AssetChain) private _chainWhiteList;
    
    event AssetZapped(address indexed asset, uint256 indexed amount, uint256 vaultId);
    event AssetUnZapped(address indexed asset, uint256 indexed amount, uint256 vaultId);

    function _beefyZapToVault(uint256 amount, uint256 vaultId, AssetChain memory chain) internal whenNotPaused returns (uint256) {
        require(amount > 0, "You need to deposit at least some tokens");

        uint256 allowance = chain.asset.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        require(chain.mooTokenVault.exists(vaultId), "VaultId provided doesn't exist");

        chain.asset.transferFrom(msg.sender, address(this), amount);
        chain.asset.approve(address(chain.perfToken), amount);
        chain.perfToken.enter(amount);
        uint256 perfTokenBalToZap = chain.perfToken.balanceOf(address(this));

        chain.perfToken.approve(address(chain.mooTokenVault), perfTokenBalToZap);
        chain.mooTokenVault.depositCollateral(vaultId, perfTokenBalToZap);
        emit AssetZapped(address(chain.asset), amount, vaultId);
        return chain.perfToken.balanceOf(msg.sender);
    }

    function _beefyZapFromVault(uint256 amount, uint256 vaultId, AssetChain memory chain) internal whenNotPaused returns (uint256) {
        require(amount > 0, "You need to withdraw at least some tokens");
        require(chain.mooTokenVault.getApproved(vaultId) == address(this), "Need to have approval");
        require(chain.mooTokenVault.ownerOf(vaultId) == msg.sender, "You can only zap out of vaults you own");

        //Transfer vault to this contract
        chain.perfToken.approve(address(chain.mooTokenVault), amount);
        chain.mooTokenVault.safeTransferFrom(msg.sender, address(this), vaultId);

        //Withdraw funds from vault
        uint256 perfTokenBalanceBeforeWithdraw = chain.perfToken.balanceOf(address(this));
        chain.mooTokenVault.withdrawCollateral(vaultId, amount);
        uint256 perfTokenBalanceToUnzap = chain.perfToken.balanceOf(address(this)) - perfTokenBalanceBeforeWithdraw;
        
        //Return vault to user
        chain.mooTokenVault.approve(msg.sender, vaultId);
        chain.mooTokenVault.safeTransferFrom(address(this), msg.sender, vaultId);

        //Exit from the perfToken to mooToken
        uint256 tokenBalanceBeforeWithdraw = chain.asset.balanceOf(address(this));
        chain.perfToken.leave(perfTokenBalanceToUnzap);
        uint256 tokenBalanceToTransfer = chain.asset.balanceOf(address(this)) - tokenBalanceBeforeWithdraw;

        //Transfer tokens to user
        chain.asset.approve(address(this), tokenBalanceToTransfer);
        chain.asset.transfer(msg.sender, tokenBalanceToTransfer);

        emit AssetUnZapped(address(chain.asset), amount, vaultId);
        return tokenBalanceToTransfer;
    }

    function _buildAssetChain(address _asset, address perfToken, address _mooAssetVault) pure internal returns (AssetChain memory) {
        AssetChain memory chain;
        chain.asset = IERC20(_asset);
        chain.perfToken = IPerfToken(perfToken);
        chain.mooTokenVault = ICrossChainStablecoin(_mooAssetVault);
        return chain;
    }

    function _hashAssetChain(AssetChain memory chain) pure internal returns (bytes32){
        return keccak256(
            abi.encodePacked(address(chain.asset), address(chain.perfToken), address(chain.mooTokenVault)));
    }

    function isWhiteListed(AssetChain memory chain) view public returns (bool){
        return address(_chainWhiteList[_hashAssetChain(chain)].asset) != address(0x0);
    }

    function addChainToWhiteList(address _asset, address _perfToken, address _mooAssetVault) public onlyOwner {
        AssetChain memory chain = _buildAssetChain(_asset, _perfToken, _mooAssetVault);
        if(!isWhiteListed(chain)){
            _chainWhiteList[_hashAssetChain(chain)] = chain;
        } else {
            revert("Chain already in White List");
        }
    }

    function removeChainFromWhiteList(address _asset, address _perfToken, address _mooAssetVault) public onlyOwner {
        AssetChain memory chain = _buildAssetChain(_asset, _perfToken, _mooAssetVault);
        if(isWhiteListed(chain)){
            delete _chainWhiteList[_hashAssetChain(chain)];
        } else {
            revert("Chain not in white List");
        }
    }

    function pauseZapping() public onlyOwner {
        _pause();
    }

    function resumeZapping() public onlyOwner {
        _unpause();
    }

    function beefyZapToVault(uint256 amount, uint256 vaultId, address _asset, address _perfToken, address _mooAssetVault) public whenNotPaused returns (uint256) {
        AssetChain memory chain = _buildAssetChain(_asset, _perfToken, _mooAssetVault);
        require(isWhiteListed(chain), "mooToken chain not in on allowable list");
        return _beefyZapToVault(amount, vaultId, chain);
    }

    function beefyZapFromVault(uint256 amount, uint256 vaultId, address _asset, address _perfToken, address _mooAssetVault) public whenNotPaused returns (uint256) {
        AssetChain memory chain = _buildAssetChain(_asset, _perfToken, _mooAssetVault);
        require(isWhiteListed(chain), "mooToken chain not in on allowable list");
        return _beefyZapFromVault(amount, vaultId, chain);
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBeefyVault {
    function name() external view returns (string memory);
    function deposit(uint256) external;
    function depositAll() external;
    function withdraw(uint256) external;
    function withdrawAll() external;
    function getPricePerFullShare() external view returns (uint256);
    function upgradeStrat() external;
    function balance() external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6.
pragma solidity >=0.7.0 <0.9.0;
import "openzeppelin-contracts/token/ERC721/IERC721.sol";

interface ICrossChainStablecoin is IERC721 {
    event AddedFrontEnd(uint256 promoter);
    event BorrowToken(uint256 vaultID, uint256 amount);
    event BoughtRiskyDebtVault(
        uint256 riskyVault,
        uint256 newVault,
        address riskyVaultBuyer,
        uint256 amountPaidtoBuy
    );
    event BurnedToken(uint256 amount);
    event CreateVault(uint256 vaultID, address creator);
    event DepositCollateral(uint256 vaultID, uint256 amount);
    event DestroyVault(uint256 vaultID);
    event LiquidateVault(
        uint256 vaultID,
        address owner,
        address buyer,
        uint256 debtRepaid,
        uint256 collateralLiquidated,
        uint256 closingFee
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event PayBackToken(uint256 vaultID, uint256 amount, uint256 closingFee);
    event RemovedFrontEnd(uint256 promoter);
    event UpdatedAdmin(address newAdmin);
    event UpdatedClosingFee(uint256 newFee);
    event UpdatedDebtRatio(uint256 _debtRatio);
    event UpdatedEthPriceSource(address _ethPriceSourceAddress);
    event UpdatedFees(uint256 _adminFee, uint256 _refFee);
    event UpdatedFrontEnd(uint256 promoter, uint256 newFee);
    event UpdatedGainRatio(uint256 _gainRatio);
    event UpdatedInterestRate(uint256 interestRate);
    event UpdatedMaxDebt(uint256 newMaxDebt);
    event UpdatedMinCollateralRatio(uint256 newMinCollateralRatio);
    event UpdatedMinDebt(uint256 newMinDebt);
    event UpdatedOpeningFee(uint256 newFee);
    event UpdatedOracleName(string oracle);
    event UpdatedRef(address newRef);
    event UpdatedStabilityPool(address pool);
    event UpdatedTokenURI(string uri);
    event WithdrawCollateral(uint256 vaultID, uint256 amount);
    event WithdrawInterest(uint256 earned);

    function _minimumCollateralPercentage() external view returns (uint256);

    function accumulatedVaultDebt(uint256) external view returns (uint256);

    function addFrontEnd(uint256 _promoter) external;

    function adm() external view returns (address);

    function adminFee() external view returns (uint256);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function borrowToken(
        uint256 vaultID,
        uint256 amount,
        uint256 _front
    ) external;

    function burn(uint256 amountToken) external;

    function buyRiskDebtVault(uint256 vaultID) external returns (uint256);

    function calculateFee(
        uint256 fee,
        uint256 amount,
        uint256 promoFee
    ) external view returns (uint256);

    function changeEthPriceSource(address ethPriceSourceAddress) external;

    function checkCollateralPercentage(uint256 vaultID)
        external
        view
        returns (uint256);

    function checkCost(uint256 vaultID) external view returns (uint256);

    function checkExtract(uint256 vaultID) external view returns (uint256);

    function checkLiquidation(uint256 vaultID) external view returns (bool);

    function checkRiskyVault(uint256 vaultID) external view returns (bool);

    function closingFee() external view returns (uint256);

    function collateral() external view returns (address);

    function createVault() external returns (uint256);

    function debtRatio() external view returns (uint256);

    function decimalDifferenceRaisedToTen() external view returns (uint256);

    function depositCollateral(uint256 vaultID, uint256 amount) external;

    function destroyVault(uint256 vaultID) external;

    function ethPriceSource() external view returns (address);

    function exists(uint256 vaultID) external view returns (bool);

    function gainRatio() external view returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address);

    function getClosingFee() external view returns (uint256);

    function getDebtCeiling() external view returns (uint256);

    function getEthPriceSource() external view returns (uint256);

    function getPaid(address pay) external;

    function getPaid() external;

    function getTokenPriceSource() external view returns (uint256);

    function getTotalValueLocked() external view returns (uint256);

    function iR() external view returns (uint256);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function isValidCollateral(uint256 _collateral, uint256 debt)
        external
        view
        returns (bool);

    function lastInterest(uint256) external view returns (uint256);

    function liquidateVault(uint256 vaultID, uint256 _front) external;

    function mai() external view returns (address);

    function maiDebt() external view returns (uint256);

    function maticDebt(address) external view returns (uint256);

    function maxDebt() external view returns (uint256);

    function minDebt() external view returns (uint256);

    function name() external view returns (string memory);

    function openingFee() external view returns (uint256);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function payBackToken(
        uint256 vaultID,
        uint256 amount,
        uint256 _front
    ) external;

    function paybackTokenAll(
        uint256 vaultID,
        uint256 deadline,
        uint256 _front
    ) external;

    function priceSourceDecimals() external view returns (uint256);

    function promoter(uint256) external view returns (uint256);

    function ref() external view returns (address);

    function refFee() external view returns (uint256);

    function removeFrontEnd(uint256 _promoter) external;

    function renounceOwnership() external;

    function router() external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function setAdmin(address _adm) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setClosingFee(uint256 _closingFee) external;

    function setDebtRatio(uint256 _debtRatio) external;

    function setFees(uint256 _admin, uint256 _ref) external;

    function setGainRatio(uint256 _gainRatio) external;

    function setInterestRate(uint256 _iR) external;

    function setMaxDebt(uint256 _maxDebt) external;

    function setMinCollateralRatio(uint256 minimumCollateralPercentage)
        external;

    function setMinDebt(uint256 _minDebt) external;

    function setOpeningFee(uint256 _openingFee) external;

    function setRef(address _ref) external;

    function setRouter(address _router) external;

    function setStabilityPool(address _pool) external;

    function setTokenURI(string memory _uri) external;

    function stabilityPool() external view returns (address);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenPeg() external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalBorrowed() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;

    function updateFrontEnd(uint256 _promoter, uint256 cashback) external;

    function updateOracleName(string memory _oracle) external;

    function updateVaultDebt(uint256 vaultID) external returns (uint256);

    function uri() external view returns (string memory);

    function vaultCollateral(uint256) external view returns (uint256);

    function vaultCount() external view returns (uint256);

    function vaultDebt(uint256 vaultID) external view returns (uint256);

    function version() external view returns (uint8);

    function withdrawCollateral(uint256 vaultID, uint256 amount) external;

    function withdrawInterest() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IPerfToken is IERC20 {
    function enter(uint256 _amount) external;
    function leave(uint256 _share) external;
}