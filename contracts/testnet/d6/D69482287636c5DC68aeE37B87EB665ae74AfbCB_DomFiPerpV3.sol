// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../utils/SafeERC20.sol";
import "../../../interfaces/IERC4626.sol";
import "../../../utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * CAUTION: Deposits and withdrawals may incur unexpected slippage. Users should verify that the amount received of
 * shares or assets is as expected. EOAs should operate through a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * _Available since v4.7._
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _decimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _decimals = success ? assetDecimals : super.decimals();
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).call(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are read from the underlying asset in the constructor and cached. If this fails (e.g., the asset
     * has not been created yet), the cached value is set to a default obtained by `super.decimals()` (which depends on
     * inheritance but is most likely 18). Override this function in order to set a guaranteed hardcoded value.
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}. */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToAssets} when overriding it.
     */
    function _initialConvertToShares(
        uint256 assets,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 shares) {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToShares} when overriding it.
     */
    function _initialConvertToAssets(
        uint256 shares,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 assets) {
        return shares;
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';

interface IPriceFeed {
    function getPrice(bytes32 productId) external view returns (FixedPoint.Unsigned);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC4626.sol';

interface IPerpetual {
    struct Position {
        address owner;
        bytes32 productId;
        uint256 margin; // collateral provided for this position
        FixedPoint.Unsigned leverage;
        FixedPoint.Unsigned price; // price when position was increased. weighted average by size
        FixedPoint.Unsigned oraclePrice;
        FixedPoint.Signed funding;
        bytes16 ownerPositionId;
        uint64 timestamp; // last position increase
        bool isLong;
        bool isNextPrice;
    }

    struct ProductParams {
        bytes32 productId;
        FixedPoint.Unsigned maxLeverage;
        FixedPoint.Unsigned fee;
        bool isActive;
        FixedPoint.Unsigned minPriceChange; // min oracle increase % for trader to close with profit
        FixedPoint.Unsigned weight; // share of the max exposure
        uint256 reserve; // Virtual reserve used to calculate slippage
    }

    struct Product {
        bytes32 productId;
        FixedPoint.Unsigned maxLeverage;
        FixedPoint.Unsigned fee;
        bool isActive;
        FixedPoint.Unsigned openInterestLong;
        FixedPoint.Unsigned openInterestShort;
        FixedPoint.Unsigned minPriceChange; // min oracle increase % for trader to close with profit
        FixedPoint.Unsigned weight; // share of the max exposure
        uint256 reserve; // Virtual reserve used to calculate slippage
    }

    struct OpenPositionParams {
        address user;
        bytes16 userPositionId;
        bytes32 productId;
        uint256 margin;
        bool isLong;
        FixedPoint.Unsigned leverage;
    }

    struct ClosePositionParams {
        address user;
        bytes16 userPositionId;
        uint256 margin;
    }

    function distributeVaultReward() external returns (uint256);

    function getPendingVaultReward() external view returns (uint256);

    function openPositions(
        OpenPositionParams[] calldata params
    ) external;

    function closePositions(
        ClosePositionParams[] calldata params
    ) external;

    function getProduct(bytes32 productId) external view returns (Product memory);

    function getPosition(address account, bytes16 accountPositionId) external view returns (Position memory);

    function getMaxExposure(FixedPoint.Unsigned productWeight)
        external
        view
        returns (FixedPoint.Unsigned);
}

interface IDomFiPerp is IPerpetual, IERC20, IERC4626 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';

interface IFeeCalculator {
    function getFee(
        FixedPoint.Unsigned productFee,
        address user,
        address sender
    ) external view returns (FixedPoint.Unsigned);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';

interface IFundingManager {
    function updateFunding(bytes32) external;

    function getFunding(bytes32) external view returns (FixedPoint.Signed);

    function getFundingRate(bytes32) external view returns (FixedPoint.Signed);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVaultReward {
    function updateReward(address account) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.8;

/**
 * @title Library for fixed point arithmetic on (u)ints
 */
library FixedPoint {
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_DECIMALS = 18;
    uint256 private constant FP_SCALING_FACTOR = 10**FP_DECIMALS;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    type Unsigned is uint256;

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned) {
        return Unsigned.wrap(a * FP_SCALING_FACTOR);
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) == Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) == Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) > Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) >= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) >= Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) >= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) < Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) <= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) <= Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) <= Unsigned.unwrap(b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) + Unsigned.unwrap(b));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) - Unsigned.unwrap(b));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned b) internal pure returns (Unsigned) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned.wrap(Unsigned.unwrap(a) * Unsigned.unwrap(b) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) * b);
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        uint256 mulRaw = Unsigned.unwrap(a) * Unsigned.unwrap(b);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw % FP_SCALING_FACTOR;
        if (mod != 0) {
            return Unsigned.wrap(mulFloor + 1);
        } else {
            return Unsigned.wrap(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        // Since b is an uint, there is no risk of truncation and we can just mul it normally
        return Unsigned.wrap(Unsigned.unwrap(a) * b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned.wrap(Unsigned.unwrap(a) * FP_SCALING_FACTOR / Unsigned.unwrap(b));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) / b);
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned b) internal pure returns (Unsigned) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        uint256 aScaled = Unsigned.unwrap(a) * FP_SCALING_FACTOR;
        uint256 divFloor = aScaled / Unsigned.unwrap(b);
        uint256 mod = aScaled % Unsigned.unwrap(b);
        if (mod != 0) {
            return Unsigned.wrap(divFloor + 1);
        } else {
            return Unsigned.wrap(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(Unsigned.unwrap(a).div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned a, uint256 b) internal pure returns (Unsigned output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i++) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    type Signed is int256;

    function fromSigned(Signed a) internal pure returns (Unsigned) {
        require(Signed.unwrap(a) >= 0, 'Negative value provided');
        return Unsigned.wrap(uint256(Signed.unwrap(a)));
    }

    function fromUnsigned(Unsigned a) internal pure returns (Signed) {
        require(Unsigned.unwrap(a) <= uint256(type(int256).max), 'Unsigned too large');
        return Signed.wrap(int256(Unsigned.unwrap(a)));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed) {
        return Signed.wrap(a * SFP_SCALING_FACTOR);
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) == Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) == Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) > Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) > Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) > Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) >= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) >= Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) >= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) < Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) < Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) < Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) <= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) <= Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) <= Signed.unwrap(b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.unwrap(a) < Signed.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.unwrap(a) > Signed.unwrap(b) ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) + Signed.unwrap(b));
    }

    /**
     * @notice Adds a `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, int256 b) internal pure returns (Signed) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Adds a `Signed` to an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an Unsigned.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, Unsigned b) internal pure returns (Signed) {
        return add(a, fromUnsigned(b));
    }

    /**
     * @notice Adds a `Signed` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, uint256 b) internal pure returns (Signed) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) - Signed.unwrap(b));
    }

    /**
     * @notice Subtracts an unscaled int256 from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, int256 b) internal pure returns (Signed) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Unsigned.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, Unsigned b) internal pure returns (Signed) {
        return sub(a, fromUnsigned(b));
    }

    /**
     * @notice Subtracts an unscaled uint256 from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, uint256 b) internal pure returns (Signed) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts a `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed b) internal pure returns (Signed) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, Signed b) internal pure returns (Signed) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed.wrap(Signed.unwrap(a) * Signed.unwrap(b) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, int256 b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) * b);
    }

    /**
     * @notice Multiplies a `Signed` and `Unsigned`, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Unsigned.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, Unsigned b) internal pure returns (Signed) {
        return mul(a, fromUnsigned(b));
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, uint256 b) internal pure returns (Signed) {
        return mul(a, fromUnscaledUint(b));
    }

    function neg(Signed a) internal pure returns (Signed) {
        return mul(a, -1);
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed a, Signed b) internal pure returns (Signed) {
        int256 mulRaw = Signed.unwrap(a) * Signed.unwrap(b);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed.wrap(mulTowardsZero + valueToAdd);
        } else {
            return Signed.wrap(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed a, int256 b) internal pure returns (Signed) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed.wrap(Signed.unwrap(a) * b);
    }

    /**
     * @notice Divides one `Signed` by a `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, Signed b) internal pure returns (Signed) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed.wrap(Signed.unwrap(a) * SFP_SCALING_FACTOR / Signed.unwrap(b));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, int256 b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) / b);
    }

    /**
     * @notice Divides one `Signed` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint.Signed numerator.
     * @param b a FixedPoint.Unsigned denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, Unsigned b) internal pure returns (Signed) {
        return div(a, fromUnsigned(b));
    }

    /**
     * @notice Divides one `Signed` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, uint256 b) internal pure returns (Signed) {
        return div(a, fromUnscaledUint(b));
    }

    /**
     * @notice Divides one unscaled int256 by a `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed b) internal pure returns (Signed) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by a `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed a, Signed b) internal pure returns (Signed) {
        int256 aScaled = Signed.unwrap(a) * SFP_SCALING_FACTOR;
        int256 divTowardsZero = aScaled / Signed.unwrap(b);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % Signed.unwrap(b);
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed.wrap(divTowardsZero + valueToAdd);
        } else {
            return Signed.wrap(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed a, int256 b) internal pure returns (Signed) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(Signed.unwrap(a).div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises a `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed a, uint256 b) internal pure returns (Signed output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i++) {
            output = mul(output, a);
        }
    }

    /**
     * @notice Absolute value of a FixedPoint.Signed
     */
    function abs(Signed value) internal pure returns (Unsigned) {
        int256 x = Signed.unwrap(value);
        uint256 raw = (x < 0) ? uint256(-x) : uint256(x);
        return Unsigned.wrap(raw);
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, "truncating" any decimal portion.
     */
    function trunc(FixedPoint.Unsigned value) internal pure returns (uint256) {
        return Unsigned.unwrap(value) / FP_SCALING_FACTOR;
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, "truncating" any decimal portion.
     */
    function trunc(FixedPoint.Signed value) internal pure returns (int256) {
        return Signed.unwrap(value) / SFP_SCALING_FACTOR;
    }

    /**
     * @notice Rounding a FixedPoint.Unsigned down to the nearest integer.
     */
    function floor(FixedPoint.Unsigned value) internal pure returns (FixedPoint.Unsigned) {
        return FixedPoint.fromUnscaledUint(trunc(value));
    }

    /**
     * @notice Round a FixedPoint.Unsigned up to the nearest integer.
     */
    function ceil(FixedPoint.Unsigned value) internal pure returns (FixedPoint.Unsigned) {
        FixedPoint.Unsigned iPart = floor(value);
        FixedPoint.Unsigned fPart = sub(value, iPart);
        if (Unsigned.unwrap(fPart) > 0) {
            return add(iPart, fromUnscaledUint(1));
        } else {
            return iPart;
        }
    }

    /**
     * @notice Given a uint with a certain number of decimal places, normalize it to a FixedPoint
     * @param value uint256, e.g. 10000000 wei USDC
     * @param decimals uint8 number of decimals to interpret `value` as, e.g. 6
     * @return output FixedPoint.Unsigned, e.g. (10.000000)
     */
    function fromScalar(uint256 value, uint8 decimals) internal pure returns (FixedPoint.Unsigned) {
        require(decimals <= FP_DECIMALS, 'FixedPoint: max decimals');
        return div(fromUnscaledUint(value), 10**decimals);
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, rounding up any decimal portion.
     */
    function roundUp(FixedPoint.Unsigned value) internal pure returns (uint256) {
        return trunc(ceil(value));
    }

    /**
     * @notice Round a trader's PnL in favor of liquidity providers
     */
    function roundTraderPnl(FixedPoint.Signed value) internal pure returns (FixedPoint.Signed) {
        if (Signed.unwrap(value) >= 0) {
            // If the P/L is a trader gain/value loss, then fractional dust gained for the trader should be reduced
            FixedPoint.Unsigned pnl = fromSigned(value);
            return fromUnsigned(floor(pnl));
        } else {
            // If the P/L is a trader loss/vault gain, then fractional dust lost should be magnified towards the trader
            return neg(fromUnsigned(ceil(abs(value))));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './FixedPoint.sol';

import '../interfaces/perp/IFeeCalculator.sol';
import '../interfaces/perp/IFundingManager.sol';

library PerpLib {
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for FixedPoint.Signed;

    function _canTakeProfit(
        bool isLong,
        uint256 positionTimestamp,
        FixedPoint.Unsigned positionOraclePrice,
        FixedPoint.Unsigned oraclePrice,
        FixedPoint.Unsigned minPriceChange,
        uint256 minProfitTime
    ) internal view returns (bool) {
        if (block.timestamp > positionTimestamp + minProfitTime) {
            return true;
        } else if (isLong && oraclePrice.isGreaterThan(positionOraclePrice.mul(minPriceChange.add(1)))) {
            return true;
        } else if (
            !isLong &&
            oraclePrice.isLessThan(positionOraclePrice.mul(FixedPoint.fromUnscaledUint(1).sub(minPriceChange)))
        ) {
            return true;
        }
        return false;
    }

    function _getPnl(
        bool isLong,
        FixedPoint.Unsigned positionPrice,
        FixedPoint.Unsigned positionLeverage,
        uint256 margin,
        FixedPoint.Unsigned price
    ) internal pure returns (FixedPoint.Signed pnl) {
        pnl = (isLong
            ? FixedPoint.fromUnsigned(price).sub(positionPrice)
            : FixedPoint.fromUnsigned(positionPrice).sub(price)
            ).mul(margin).mul(positionLeverage).div(positionPrice);
    }

    function _getFundingPayment(
        bool isLong,
        FixedPoint.Unsigned positionLeverage,
        uint256 margin,
        FixedPoint.Signed funding,
        FixedPoint.Signed cumulativeFunding
    ) internal pure returns (FixedPoint.Signed) {
        FixedPoint.Signed actualMargin = FixedPoint.fromUnscaledUint(margin).fromUnsigned();
        return
            actualMargin.mul(positionLeverage).mul(
                isLong ? (cumulativeFunding.sub(funding)) : (funding.sub(cumulativeFunding))
            );
    }

    function _getTradeFee(
        uint256 margin,
        FixedPoint.Unsigned leverage,
        FixedPoint.Unsigned productFee,
        address user,
        address sender,
        IFeeCalculator feeCalculator
    ) internal view returns (uint256) {
        FixedPoint.Unsigned fee = feeCalculator.getFee(productFee, user, sender);
        return FixedPoint.fromUnscaledUint(margin).mul(leverage).mul(fee).roundUp();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../interfaces/oracle/IPriceFeed.sol';
import '../interfaces/perp/IDomFiPerp.sol';
import '../interfaces/perp/IFundingManager.sol';
import '../interfaces/perp/IFeeCalculator.sol';
import '../interfaces/staking/IVaultReward.sol';
import '../lib/PerpLib.sol';
import '../lib/FixedPoint.sol';


/**
 * @title Perpetual long/short levered instruments for Domination Finance
 */
contract DomFiPerpV3 is ReentrancyGuard, IPerpetual, ERC4626 {
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for FixedPoint.Signed;
    using SafeERC20 for IERC20;
    using Math for uint256;

    address public owner; /// @notice manages vault parameters, products, managers
    address public guardian; /// @notice can pause trading
    address public gov; /// @notice can set owner, guardian, gov
    IPriceFeed public oracle;
    IFeeCalculator public feeCalculator;
    IFundingManager public fundingManager;

    // deposits:
    uint256 public balance; /// @notice staked collateral plus trader losses
    uint256 public maxCollateral; /// @notice deposits are rejected if they'd raise balance above max
    bool private canUserDeposit = true; /// @notice whether accounts other than the owner can deposit

    // trading:
    mapping(bytes32 => Position) private positions;
    mapping(address => bool) public nextPriceManagers;
    mapping(address => bool) public managers; /// @notice managers may make trades on behalf of other addresses
    mapping(address => mapping(address => bool)) public approvedManagers; /// @notice managers must be approved by users
    bool private isTradeEnabled = true;
    bool private isManagerOnlyForOpen = false;
    bool private isManagerOnlyForClose = false;
    uint256 public minProfitTime = 6 hours; /// @notice wait before trades can be cashed out with < minProfit
    uint256 public minMargin; ///@notice minimum margin increment; gas could make very small liquidations unprofitable

    /// @dev scaling factor for price shift that balances long and short exposure
    FixedPoint.Unsigned public maxShift = FixedPoint.fromUnscaledUint(3).div(1000);
    /// @dev scale price shift to 1/3 (giving more favorable prices) for orders that reduce net exposure
    FixedPoint.Unsigned public helpfulShiftScaler = FixedPoint.fromUnscaledUint(1).div(3);

    // liquidations:
    bool private allowPublicLiquidator = false;
    mapping(address => bool) public liquidators;
    /// @notice positions are liquidated if losses >= 80% of margin
    FixedPoint.Unsigned public liquidationThreshold = FixedPoint.fromUnscaledUint(80).div(100);
    /// @notice upon liquidation, 50% of remaining margin is given to liquidators
    FixedPoint.Unsigned private liquidationBounty = FixedPoint.fromUnscaledUint(50).div(100);

    // rewards:
    /// @notice 20% of rewards are allocated to protocol
    FixedPoint.Unsigned public protocolRewardRatio = FixedPoint.fromUnscaledUint(20).div(100);
    /// @notice 30% of rewards are allocated to pika (TODO rename)
    FixedPoint.Unsigned public domFiRewardRatio = FixedPoint.fromUnscaledUint(30).div(100);
    FixedPoint.Unsigned private pendingProtocolReward;
    FixedPoint.Unsigned private pendingDomFiReward;
    FixedPoint.Unsigned private pendingVaultReward; /// @notice remaining rewards (50%) are given to vault LPs
    address public protocolRewardDistributor;
    address public domFiRewardDistributor;
    IVaultReward public vaultRewardDistributor; /// @notice distributes trade/liquidity fees to vault LPs
    IVaultReward public vaultTokenReward; /// @notice distributes external token reward to vault LPs

    // product controls:
    mapping(bytes32 => Product) private products;
    FixedPoint.Unsigned public totalWeight; /// @notice total exposure weights of all products
    FixedPoint.Unsigned public totalOpenInterest; /// @notice total size of all outstanding positions in token wei
    /// @notice maxExposure limited to 10x vault balance
    FixedPoint.Unsigned public exposureMultiplier = FixedPoint.fromUnscaledUint(10);
    /// @notice total open interest (long + short) limited to 10x vault balance
    FixedPoint.Unsigned public utilizationMultiplier = FixedPoint.fromUnscaledUint(10);
    /// @notice open interest of a product limited at 3x its proportional share of maxExposure
    FixedPoint.Unsigned public maxExposureMultiplier = FixedPoint.fromUnscaledUint(3);

    // Events

    event NewPosition(
        bytes32 indexed positionId,
        address indexed user,
        bytes32 indexed productId,
        uint256 fee,
        Position position
    );

    event ClosePosition(
        bytes32 indexed positionId,
        address indexed user,
        bytes32 indexed productId,
        bool didLiquidate,
        uint256 fee,
        int256 netPnl,
        FixedPoint.Unsigned exitPrice,
        Position position
    );

    event AddMargin(
        bytes32 indexed positionId,
        address indexed sender,
        address indexed user,
        uint256 oldMargin,
        uint256 newMargin,
        FixedPoint.Unsigned oldLeverage,
        FixedPoint.Unsigned newLeverage,
        Position position
    );

    event PositionLiquidated(
        bytes32 indexed positionId,
        address indexed liquidator,
        uint256 liquidatorReward,
        uint256 remainingReward,
        Position position
    );

    event ProtocolRewardDistributed(address to, uint256 amount);
    event DomFiRewardDistributed(address to, uint256 amount);
    event VaultRewardDistributed(IVaultReward to, uint256 amount);
    event VaultUpdated(uint256 maxCollateral, uint256 balance);
    event ProductAdded(bytes32 productId, Product product);
    event ProductUpdated(bytes32 productId, Product product);
    event AddressesSet(IPriceFeed oracle, IFeeCalculator feeCalculator, IFundingManager fundingManager);
    event OwnerUpdated(address newOwner);
    event GuardianUpdated(address newGuardian);
    event GovUpdated(address newGov);

    constructor(
        IERC20Metadata _token,
        IPriceFeed _oracle,
        IFeeCalculator _feeCalculator,
        IFundingManager _fundingManager
    ) ERC4626(_token) ERC20("Domination Finance Perp Deposit", "DOMD") {
        owner = msg.sender;
        guardian = msg.sender;
        gov = msg.sender;
        oracle = _oracle;
        feeCalculator = _feeCalculator;
        fundingManager = _fundingManager;
    }

    /** @notice deposit `amount` collateral to `user`
     *  @return shares DOMD amount representing this deposit
     */
    function deposit(uint256 amount, address user) public override nonReentrant returns (uint256 shares) {
        require((canUserDeposit || msg.sender == owner) && (msg.sender == user || _validateManager(user)), '!stake');
        require(amount <= maxDeposit(user), "!maxCollateral");

        shares = previewDeposit(amount);
        _deposit(msg.sender, user, amount, shares);

        balance += amount;
        return shares;
    }

    /** @notice redeem `shares` from `account`. send collateral to `receiver`
     *  @return amount collateral sent to receiver
     */
    function redeem(uint256 shares, address receiver, address account) public virtual override returns (uint256 amount) {
        require(account == msg.sender || _validateManager(account), '!redeem');

        amount = super.redeem(shares, receiver, account);

        balance -= amount;
    }

    /** @notice Open multiple positions simultaneously. Fails unless all succeed.
     */
    function openPositions(
        OpenPositionParams[] calldata params
    ) external override {
        require(isTradeEnabled, '!enabled');
        for (uint256 i = 0; i < params.length; i++) {
            _openPosition(params[i]);
        }
    }

    function _openPosition(
        OpenPositionParams calldata params
    ) internal nonReentrant {
        require(_validateManager(params.user) || (!isManagerOnlyForOpen && params.user == msg.sender), '!allowed');

        // Check params
        require(params.margin >= minMargin, '!margin');
        require(params.leverage.isGreaterThanOrEqual(1), '!lev');

        // Check product
        Product storage product = products[params.productId];
        require(product.isActive, '!active');
        require(params.leverage.isLessThanOrEqual(product.maxLeverage), '!max-lev');

        // Transfer margin plus fee
        uint256 tradeFee = PerpLib._getTradeFee(params.margin, params.leverage, product.fee, params.user, msg.sender, feeCalculator);
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), params.margin + tradeFee);
        _updatePendingRewards(tradeFee);

        FixedPoint.Unsigned increaseMargin = FixedPoint.fromUnscaledUint(params.margin);
        FixedPoint.Unsigned increaseSize = increaseMargin.mul(params.leverage);

        FixedPoint.Unsigned price = _calculatePrice(
            product.productId,
            params.isLong,
            product.openInterestLong,
            product.openInterestShort,
            FixedPoint.fromUnscaledUint(balance).mul(product.weight).mul(exposureMultiplier).div(totalWeight),
            product.reserve,
            increaseSize.trunc()
        );

        _updateFundingAndOpenInterest(params.productId, increaseSize, params.isLong, true);

        FixedPoint.Signed funding = fundingManager.getFunding(params.productId);

        bytes32 positionId = getPositionId(params.user, params.userPositionId);
        Position storage prev = positions[positionId];
        FixedPoint.Unsigned leverage = params.leverage;
        uint256 margin = params.margin;
        if (prev.margin > 0) {
            require(prev.productId == params.productId, 'WRONG_PRODUCT');

            FixedPoint.Unsigned prevMargin = FixedPoint.fromUnscaledUint(prev.margin);
            FixedPoint.Unsigned prevSize = prevMargin.mul(prev.leverage);
            price = (prevSize.mul(prev.price).add(increaseSize.mul(price))).div(prevSize.add(increaseSize));

            funding = FixedPoint.fromUnsigned(prevSize).mul(prev.funding)
                .add(funding.mul(increaseSize))
                .div(prevSize.add(increaseSize));
            leverage = (prevSize.add(increaseSize)).div(prevMargin.add(increaseMargin));
            margin = prev.margin + params.margin;
        }

        // If this is a new position, `isNextPrice` depends only on the
        // sender being a `nextPriceManager`.
        //
        // Otherwise, for an existing position, it is `false` if the existing
        // position's `isNextPrice` is `false` or the sender is not a
        // `nextPriceManager`.

        positions[positionId] = Position({
            owner: params.user,
            ownerPositionId: params.userPositionId,
            productId: params.productId,
            margin: margin,
            leverage: leverage,
            price: price,
            oraclePrice: oracle.getPrice(product.productId),
            timestamp: uint64(block.timestamp),
            isLong: params.isLong,
            isNextPrice: nextPriceManagers[msg.sender] && (prev.margin == 0 || (prev.isNextPrice)),
            funding: funding
        });

        emit NewPosition(
            positionId,
            params.user,
            params.productId,
            tradeFee,
            positions[positionId]
        );
    }

    // Add margin to Position with positionId
    function addMargin(bytes32 positionId, uint256 margin) external nonReentrant {
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), margin);

        // Check params
        require(margin >= minMargin, '!margin');

        // Check position
        Position storage position = positions[positionId];

        require(msg.sender == position.owner || _validateManager(position.owner), '!allowed');

        // New position params
        uint256 newMargin = position.margin + margin;
        FixedPoint.Unsigned oldLeverage = position.leverage;
        FixedPoint.Unsigned newLeverage = oldLeverage.mul(position.margin).div(newMargin);
        require(newLeverage.isGreaterThanOrEqual(1), '!low-lev');

        position.margin = newMargin;
        position.leverage = newLeverage;

        emit AddMargin(
            positionId,
            msg.sender,
            position.owner,
            margin,
            newMargin,
            oldLeverage,
            newLeverage,
            position
        );
    }

    /** @notice Close multiple positions simultaneously. Fails unless all succeed.
     */
    function closePositions(
        ClosePositionParams[] calldata params
    ) external {
        for (uint256 i = 0; i < params.length; i++) {
            closePositionWithId(
                getPositionId(params[i].user, params[i].userPositionId),
                params[i].margin
            );
        }
    }

    // Closes position from Position with id = positionId
    function closePositionWithId(bytes32 positionId, uint256 margin) public nonReentrant {
        // Check position
        Position storage position = positions[positionId];
        require(_validateManager(position.owner) || (!isManagerOnlyForClose && msg.sender == position.owner), '!close');

        // Check product
        Product storage product = products[position.productId];

        bool isFullClose;
        if (margin >= position.margin) {
            margin = position.margin;
            isFullClose = true;
        }

        FixedPoint.Unsigned decreaseMargin = FixedPoint.fromUnscaledUint(margin);
        FixedPoint.Unsigned price = _calculatePrice(
            product.productId,
            !position.isLong,
            product.openInterestLong,
            product.openInterestShort,
            getMaxExposure(product.weight),
            product.reserve,
            decreaseMargin.mul(position.leverage).trunc()
        );

        (FixedPoint.Signed pnl, , bool isLiquidatable) = _canLiquidate(
            position,
            price
        );
        if (isLiquidatable) {
            _updateFundingAndOpenInterest(
                position.productId,
                decreaseMargin.mul(position.leverage),
                position.isLong,
                false
            );

            margin = position.margin;
            pnl = decreaseMargin.fromUnsigned().neg();
        } else {
            // front running protection: if oracle price up change is smaller than threshold and minProfitTime has not passed
            // and either open or close order is not using next oracle price, the pnl is be set to 0
            if (
                pnl.isGreaterThan(0) &&
                !PerpLib._canTakeProfit(
                    position.isLong,
                    uint64(position.timestamp),
                    position.oraclePrice,
                    oracle.getPrice(product.productId),
                    product.minPriceChange,
                    minProfitTime
                ) &&
                (!position.isNextPrice || !nextPriceManagers[msg.sender])
            ) {
                pnl = FixedPoint.fromUnscaledInt(0);
            }
        }

        (uint256 totalFee, int256 netPnl) =
            _updateVaultAndGetFee(pnl, position, margin, product.fee);

        position.margin -= margin;

        {
            // Avoid stack too deep
            Position storage pos = position;
            emit ClosePosition(
                positionId,
                pos.owner,
                pos.productId,
                isLiquidatable,
                totalFee,
                netPnl,
                price,
                pos
            );
        }

        if (isFullClose) {
            delete positions[positionId];
        }
    }

    function _updateVaultAndGetFee(
        FixedPoint.Signed pnl,
        Position memory position,
        uint256 margin,
        FixedPoint.Unsigned fee
    ) private returns (
        uint256 totalFee,
        int256 netPnl
    ) {
        totalFee = PerpLib._getTradeFee(
            margin,
            position.leverage,
            fee,
            position.owner,
            msg.sender,
            feeCalculator
        );

        FixedPoint.Signed pnlAfterFee = pnl
            .sub(totalFee)
            .roundTraderPnl();

        netPnl = pnlAfterFee.trunc();

        // Update vault
        uint256 _pnlAfterFee = pnlAfterFee.abs().trunc();
        if (pnlAfterFee.isLessThan(0)) {
            if (_pnlAfterFee < margin) {
                IERC20(asset()).safeTransfer(position.owner, margin - _pnlAfterFee);
                balance += _pnlAfterFee;
            } else {
                balance += margin;
                return (totalFee, netPnl);
            }
        } else {
            // Check vault
            require(balance >= _pnlAfterFee, '!bal');
            balance -= _pnlAfterFee;
            IERC20(asset()).safeTransfer(position.owner, margin + _pnlAfterFee);
        }

        _updatePendingRewards(totalFee);
        balance -= totalFee;

        return (totalFee, netPnl);
    }

    // Liquidate positionIds
    function liquidatePositions(bytes32[] calldata positionIds, address feeReceiver) external {
        require(liquidators[msg.sender] || allowPublicLiquidator, '!liquidator');

        uint256 totalLiquidatorReward;
        for (uint256 i = 0; i < positionIds.length; i++) {
            bytes32 positionId = positionIds[i];
            uint256 liquidatorReward = liquidatePosition(positionId);
            totalLiquidatorReward += liquidatorReward;
        }

        if (totalLiquidatorReward > 0) {
            IERC20(asset()).safeTransfer(feeReceiver, totalLiquidatorReward);
        }
    }

    function canLiquidate(bytes32[] calldata positionIds)
        external
        view
        returns (
            FixedPoint.Signed[] memory pnl,
            FixedPoint.Signed[] memory funding,
            bool[] memory isLiquidatable
        )
    {
        pnl = new FixedPoint.Signed[](positionIds.length);
        funding = new FixedPoint.Signed[](positionIds.length);
        isLiquidatable = new bool[](positionIds.length);

        for (uint256 i = 0; i < positionIds.length; i++) {
            Position storage position = positions[positionIds[i]];
            FixedPoint.Unsigned price = oracle.getPrice(position.productId);
            (
                FixedPoint.Signed positionPnl,
                FixedPoint.Signed positionFunding,
                bool positionLiquidatable
            ) = _canLiquidate(position, price);
            pnl[i] = positionPnl;
            funding[i] = positionFunding;
            isLiquidatable[i] = positionLiquidatable;
        }
    }

    function _canLiquidate(Position storage position, FixedPoint.Unsigned price)
        internal
        view
        returns (
            FixedPoint.Signed pnl,
            FixedPoint.Signed funding,
            bool isLiquidatable
        )
    {
        require(position.productId != 0, 'DomFiPerpV3: invalid position');
        FixedPoint.Signed cumulativeFunding = fundingManager.getFunding(position.productId);

        funding = PerpLib._getFundingPayment(
            position.isLong,
            position.leverage,
            position.margin,
            position.funding,
            cumulativeFunding
        );

        pnl = PerpLib._getPnl(position.isLong, position.price, position.leverage, position.margin, price).sub(funding);

        FixedPoint.Unsigned positionMargin = FixedPoint.fromUnscaledUint(position.margin);

        if (pnl.isLessThanOrEqual(FixedPoint.fromUnsigned(positionMargin).mul(liquidationThreshold).neg())) {
            isLiquidatable = true;
        }
    }

    function liquidatePosition(bytes32 positionId) private returns (uint256 liquidatorReward) {
        Position storage position = positions[positionId];
        Product storage product = products[position.productId];

        FixedPoint.Unsigned oraclePrice = oracle.getPrice(product.productId);
        (FixedPoint.Signed pnl, , bool isLiquidatable) = _canLiquidate(
            position,
            oraclePrice
        );

        if (!isLiquidatable) {
            return 0;
        }

        _updateFundingAndOpenInterest(
            position.productId,
            FixedPoint.fromUnscaledUint(position.margin).mul(position.leverage),
            position.isLong,
            false
        );

        require(pnl.isLessThan(0), 'DomFiPerpV3: liquidatable');
        uint256 loss = pnl.abs().roundUp();

        int256 netPnl;
        uint256 remainingReward;
        if (position.margin > loss) {
            liquidatorReward = FixedPoint.fromUnscaledUint(position.margin - loss).mul(liquidationBounty).trunc();
            remainingReward = position.margin - loss - liquidatorReward;
            _updatePendingRewards(remainingReward);
            netPnl = -int256(loss);
            balance += loss;
        } else {
            netPnl = -int256(position.margin);
            balance += position.margin;
        }

        emit ClosePosition(
            positionId,
            position.owner,
            position.productId,
            true,
            0,
            netPnl,
            oraclePrice,
            position
        );

        emit PositionLiquidated(
            positionId,
            msg.sender,
            liquidatorReward,
            remainingReward,
            position
        );

        delete positions[positionId];

        return liquidatorReward;
    }

    function _updatePendingRewards(uint256 reward) private {
        FixedPoint.Unsigned actualReward = FixedPoint.fromUnscaledUint(reward);

        pendingProtocolReward = pendingProtocolReward.add(actualReward.mul(protocolRewardRatio));
        pendingDomFiReward = pendingDomFiReward.add(actualReward.mul(domFiRewardRatio));
        pendingVaultReward = pendingVaultReward.add(
            actualReward.mul(FixedPoint.fromUnscaledUint(1).sub(protocolRewardRatio).sub(domFiRewardRatio))
        );
    }

    function _checkOpenInterest(
        bytes32 productId,
        FixedPoint.Unsigned totalOI,
        FixedPoint.Unsigned maxExpo,
        FixedPoint.Unsigned amount
    ) internal view {
        Product memory product = products[productId];
        FixedPoint.Unsigned vaultBalance = FixedPoint.fromUnscaledUint(balance);
        FixedPoint.Unsigned newTotalExposure = product.openInterestLong.add(product.openInterestShort).add(amount);

        require(
            totalOI.isLessThanOrEqual(vaultBalance.mul(utilizationMultiplier)) &&
                newTotalExposure.isLessThan(maxExpo.mul(maxExposureMultiplier)),
            '!maxOI'
        );
    }

    function _updateFundingAndOpenInterest(
        bytes32 productId,
        FixedPoint.Unsigned amount,
        bool isLong,
        bool isIncrease
    ) private {
        fundingManager.updateFunding(productId);
        Product storage product = products[productId];
        if (isIncrease) {
            totalOpenInterest = totalOpenInterest.add(amount);
            FixedPoint.Unsigned maxExposure = getMaxExposure(product.weight);

            _checkOpenInterest(productId, totalOpenInterest, maxExposure, amount);

            if (isLong) {
                product.openInterestLong = product.openInterestLong.add(amount);
                require(
                    product.openInterestLong.isLessThanOrEqual(maxExposure.add(product.openInterestShort)),
                    '!exposure-long'
                );
            } else {
                product.openInterestShort = product.openInterestShort.add(amount);
                require(
                    product.openInterestShort.isLessThanOrEqual(maxExposure.add(product.openInterestLong)),
                    '!exposure-short'
                );
            }
        } else {
            totalOpenInterest = totalOpenInterest.sub(amount);
            if (isLong) {
                if (product.openInterestLong.isGreaterThanOrEqual(amount)) {
                    product.openInterestLong = product.openInterestLong.sub(amount);
                } else {
                    product.openInterestLong = FixedPoint.fromUnscaledUint(0);
                }
            } else {
                if (product.openInterestShort.isGreaterThanOrEqual(amount)) {
                    product.openInterestShort = product.openInterestShort.sub(amount);
                } else {
                    product.openInterestShort = FixedPoint.fromUnscaledUint(0);
                }
            }
        }
    }

    function _validateManager(address account) private view returns (bool) {
        return managers[msg.sender] && approvedManagers[account][msg.sender];
    }

    function distributeProtocolReward() external returns (uint256 _reward) {
        require(msg.sender == protocolRewardDistributor, '!dist');
        _reward = pendingProtocolReward.trunc();
        if (_reward > 0) {
            pendingProtocolReward = pendingProtocolReward.sub(_reward);
            IERC20(asset()).safeTransfer(protocolRewardDistributor, _reward);
            emit ProtocolRewardDistributed(protocolRewardDistributor, _reward);
        }
    }

    function distributeDomFiReward() external returns (uint256 _reward) {
        require(msg.sender == domFiRewardDistributor, '!dist');
        _reward = pendingDomFiReward.trunc();
        if (_reward > 0) {
            pendingDomFiReward = pendingDomFiReward.sub(_reward);
            IERC20(asset()).safeTransfer(domFiRewardDistributor, _reward);

            emit DomFiRewardDistributed(domFiRewardDistributor, _reward);
        }
    }

    function distributeVaultReward() external override returns (uint256 _reward) {
        require(msg.sender == address(vaultRewardDistributor), '!dist');
        _reward = pendingVaultReward.trunc();
        if (_reward > 0) {
            pendingVaultReward = pendingVaultReward.sub(_reward);
            IERC20(asset()).safeTransfer(address(vaultRewardDistributor), _reward);
            emit VaultRewardDistributed(vaultRewardDistributor, _reward);
        }
    }

    // Getters
    function getPendingDomFiReward() external view returns (uint256) {
        return pendingDomFiReward.trunc();
    }

    function getPendingProtocolReward() external view returns (uint256) {
        return pendingProtocolReward.trunc();
    }

    function getPendingVaultReward() external view override returns (uint256) {
        return pendingVaultReward.trunc();
    }

    function getProduct(bytes32 productId) external view override returns (Product memory product) {
        product = products[productId];
    }

    function getPositionId(address account, bytes16 accountPositionId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, accountPositionId));
    }

    function getPosition(address account, bytes16 accountPositionId)
        external
        view
        override
        returns (Position memory position)
    {
        position = positions[getPositionId(account, accountPositionId)];
    }

    function getPositions(bytes32[] calldata positionIds) external view returns (Position[] memory _positions) {
        uint256 length = positionIds.length;
        _positions = new Position[](length);
        for (uint256 i = 0; i < length; i++) {
            _positions[i] = positions[bytes32(positionIds[i])];
        }
    }

    function getMaxExposure(FixedPoint.Unsigned productWeight)
        public
        view
        override
        returns (FixedPoint.Unsigned)
    {
        return FixedPoint.fromUnscaledUint(balance).mul(productWeight).mul(exposureMultiplier).div(totalWeight);
    }

    /** @notice Total uncommitted assets / available for withdraw. Excludes open positions, whose funding
                stakers are not entitled to
     */
    function totalAssets() public view override returns (uint256 totalManagedAssets) {
        return balance;
    }

    function maxDeposit(address receiver) public view override returns (uint256 maxAssets) {
        if (!canUserDeposit && receiver != owner) {
            return 0;
        }
        maxAssets = maxCollateral - balance;
    }


    // Private methods

    // Apply two kinds of slippage to oracle price:
    //     % penalty [0,∞) as amount approaches reserve. like typical constant-product dex slippage
    //     % offset [0,maxShift] proportional to current / max exposure. improves price for orders reducing exposure
    function _calculatePrice(
        bytes32 productId,
        bool isLong,
        FixedPoint.Unsigned openInterestLong,
        FixedPoint.Unsigned openInterestShort,
        FixedPoint.Unsigned maxExposure,
        uint256 reserve,
        uint256 amount
    ) private view returns (FixedPoint.Unsigned) {
        _checkOpenInterest(
            productId,
            totalOpenInterest,
            maxExposure,
            FixedPoint.fromUnscaledUint(amount)
        );

        FixedPoint.Unsigned oraclePrice = oracle.getPrice(productId);

        FixedPoint.Unsigned slippage = isLong
                ? FixedPoint.fromUnscaledUint(reserve).mul(reserve).div(reserve - amount).sub(reserve).div(amount)
                : FixedPoint.fromUnscaledUint(reserve).sub(FixedPoint.fromUnscaledUint(reserve).mul(reserve).div(reserve + amount)).div(amount)
        ;

        FixedPoint.Signed shift = openInterestLong.fromUnsigned().sub(openInterestShort).mul(maxShift).div(maxExposure);
        bool decreasesExposure = isLong
            ? openInterestLong.isLessThan(openInterestShort)
            : openInterestLong.isGreaterThan(openInterestShort);
        slippage = slippage.fromUnsigned().add(
            decreasesExposure ? shift.mul(helpfulShiftScaler) : shift
        ).fromSigned();

        return oraclePrice.mul(slippage);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *      Scale by 1e18 to mitigate inflation attacks: github.com/OpenZeppelin/openzeppelin-contracts/issues/3706
     */
    function _initialConvertToShares(
        uint256 assets,
        Math.Rounding /*rounding*/
    ) internal pure override returns (uint256 shares) {
        return assets * 10**18;
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     */
    function _initialConvertToAssets(
        uint256 shares,
        Math.Rounding /*rounding*/
    ) internal pure override returns (uint256) {
        return shares / 10**18;
    }


    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/) internal override {
        if (from != address(0x0) && balanceOf(from) > 0) {
            vaultRewardDistributor.updateReward(from);
            vaultTokenReward.updateReward(from);
        }
        if (to != address(0x0)) {
            vaultRewardDistributor.updateReward(to);
            vaultTokenReward.updateReward(to);
        }
    }

    function _afterTokenTransfer(address /*from*/, address /*to*/, uint256 /*amount*/) internal view override {
        require(
            totalOpenInterest.isLessThanOrEqual(FixedPoint.fromUnscaledUint(balance).mul(utilizationMultiplier)),
            '!utilized'
        );
    }

    // Owner methods

    function setMaxCollateral(uint256 _maxCollateral) external {
        onlyOwner();

        require(_maxCollateral > 0, '!allowed');

        maxCollateral = _maxCollateral;

        emit VaultUpdated(maxCollateral, balance);
    }

    function addProduct(ProductParams memory _product) external {
        onlyOwner();

        bytes32 productId = _product.productId;
        require(productId != 0, "DomFiPerpV3: product id");

        Product memory oldProduct = products[productId];

        require(oldProduct.maxLeverage.isEqual(0), "DomFiPerpV3: duplicate product");
        require(_product.maxLeverage.isGreaterThanOrEqual(1), "DomFiPerpV3: product leverage");

        products[productId] = Product({
            productId: productId,
            maxLeverage: _product.maxLeverage,
            fee: _product.fee,
            isActive: _product.isActive,
            openInterestLong: FixedPoint.fromUnscaledUint(0),
            openInterestShort: FixedPoint.fromUnscaledUint(0),
            minPriceChange: _product.minPriceChange,
            weight: _product.weight,
            reserve: _product.reserve
        });

        totalWeight = totalWeight.add(_product.weight);

        emit ProductAdded(productId, products[productId]);
    }

    function updateProduct(ProductParams memory _product) external {
        onlyOwner();

        bytes32 productId = _product.productId;
        require(productId != 0, "DomFiPerpV3: product id");
        Product storage product = products[productId];

        require(
            product.maxLeverage.isGreaterThan(0) &&
                _product.maxLeverage.isGreaterThanOrEqual(1),
            "DomFiPerpV3: product leverage"
        );

        product.maxLeverage = _product.maxLeverage;
        product.fee = _product.fee;
        product.isActive = _product.isActive;
        product.minPriceChange = _product.minPriceChange;

        totalWeight = (totalWeight.sub(product.weight)).add(_product.weight);
        product.weight = _product.weight;
        product.reserve = _product.reserve;

        emit ProductUpdated(productId, product);
    }

    function setDistributors(
        address _protocolRewardDistributor,
        address _domFiRewardDistributor,
        IVaultReward _vaultRewardDistributor,
        IVaultReward _vaultTokenReward
    ) external {
        onlyOwner();
        protocolRewardDistributor = _protocolRewardDistributor;
        domFiRewardDistributor = _domFiRewardDistributor;
        vaultRewardDistributor = _vaultRewardDistributor;
        vaultTokenReward = _vaultTokenReward;
    }

    function setManager(address _manager, bool _isActive) external {
        onlyOwner();
        managers[_manager] = _isActive;
    }

    function setAccountManager(address _manager, bool _isActive) external {
        approvedManagers[msg.sender][_manager] = _isActive;
    }

    function setRewardRatio(
        FixedPoint.Unsigned _protocolRewardRatio,
        FixedPoint.Unsigned _domFiRewardRatio
    ) external {
        onlyOwner();
        require(_protocolRewardRatio.add(_domFiRewardRatio).isLessThanOrEqual(FixedPoint.fromUnscaledUint(1)));
        protocolRewardRatio = _protocolRewardRatio;
        domFiRewardRatio = _domFiRewardRatio;
    }

    function setMinMargin(uint256 _minMargin) external {
        onlyOwner();
        minMargin = _minMargin;
    }

    function setTradeEnabled(bool _isTradeEnabled) external {
        require(msg.sender == owner || managers[msg.sender]);
        isTradeEnabled = _isTradeEnabled;
    }

    function setParameters(
        FixedPoint.Unsigned _maxShift,
        uint256 _minProfitTime,
        bool _canUserDeposit,
        bool _allowPublicLiquidator,
        bool _isManagerOnlyForOpen,
        bool _isManagerOnlyForClose,
        FixedPoint.Unsigned _exposureMultiplier,
        FixedPoint.Unsigned _utilizationMultiplier,
        FixedPoint.Unsigned _maxExposureMultiplier,
        FixedPoint.Unsigned _liquidationBounty,
        FixedPoint.Unsigned _liquidationThreshold,
        FixedPoint.Unsigned _helpfulShiftScaler
    ) external {
        onlyOwner();

        require(
            _maxShift.isLessThanOrEqual(FixedPoint.fromUnscaledUint(1).div(100)) &&
                _minProfitTime <= 24 hours &&
                _helpfulShiftScaler.isGreaterThan(0) &&
                _liquidationThreshold.isGreaterThan(FixedPoint.fromUnscaledUint(50).div(100)) &&
                _maxExposureMultiplier.isGreaterThan(0)
        );

        maxShift = _maxShift;
        minProfitTime = _minProfitTime;
        canUserDeposit = _canUserDeposit;
        allowPublicLiquidator = _allowPublicLiquidator;
        isManagerOnlyForOpen = _isManagerOnlyForOpen;
        isManagerOnlyForClose = _isManagerOnlyForClose;
        exposureMultiplier = _exposureMultiplier;
        utilizationMultiplier = _utilizationMultiplier;
        maxExposureMultiplier = _maxExposureMultiplier;
        liquidationBounty = _liquidationBounty;
        liquidationThreshold = _liquidationThreshold;
        helpfulShiftScaler = _helpfulShiftScaler;
    }

    function setAddresses(
        IPriceFeed _oracle,
        IFeeCalculator _feeCalculator,
        IFundingManager _fundingManager
    ) external {
        onlyOwner();
        oracle = _oracle;
        feeCalculator = _feeCalculator;
        fundingManager = _fundingManager;
        emit AddressesSet(_oracle, _feeCalculator, _fundingManager);
    }

    function setLiquidator(address _liquidator, bool _isActive) external {
        onlyOwner();
        liquidators[_liquidator] = _isActive;
    }

    function setNextPriceManager(address _nextPriceManager, bool _isActive) external {
        onlyOwner();
        nextPriceManagers[_nextPriceManager] = _isActive;
    }

    function setOwner(address _owner) external {
        onlyGov();
        owner = _owner;
        emit OwnerUpdated(_owner);
    }

    function setGuardian(address _guardian) external {
        onlyGov();
        guardian = _guardian;
        emit GuardianUpdated(_guardian);
    }

    function setGov(address _gov) external {
        onlyGov();
        gov = _gov;
        emit GovUpdated(_gov);
    }

    function pauseTrading() external {
        require(msg.sender == guardian, '!guard');
        isTradeEnabled = false;
        canUserDeposit = false;
    }

    function onlyOwner() private view {
        require(msg.sender == owner, '!owner');
    }

    function onlyGov() private view {
        require(msg.sender == gov, '!gov');
    }
}