// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title BaseVault
 *
 * @author Fujidao Labs
 *
 * @notice Abstract contract that defines the basic common functions and interface
 * for all vault types. User state is kept in vaults via tokenized shares compliant to ERC4626.
 * BaseVault defines but does not implement the debt handling functions. Slippage protected
 * functions are available through ERC5143 extension. The `_providers` of this vault are the
 * liquidity source for lending, borrowing and/or yielding operations.
 * Setter functions are controlled by timelock, and roles defined in {SystemAccessControl}.
 * Pausability in core functions is implemented for emergency cases.
 * Allowance and approvals for value extracting operations  is possible via
 * signed messages defined in {VaultPermissions}.
 * A rebalancing function is implemented to move vault's funds across providers.
 * A `depositCap` is defined to control risk and maximum TVL of this vault.
 */
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from
  "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {IVault} from "../interfaces/IVault.sol";
import {ILendingProvider} from "../interfaces/ILendingProvider.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {VaultPermissions} from "../vaults/VaultPermissions.sol";
import {SystemAccessControl} from "../access/SystemAccessControl.sol";
import {PausableVault} from "./PausableVault.sol";

abstract contract BaseVault is ERC20, SystemAccessControl, PausableVault, VaultPermissions, IVault {
  using Math for uint256;
  using Address for address;

  /// @dev Custom Errors
  error BaseVault__constructor_invalidInput();
  error BaseVault__deposit_moreThanMax();
  error BaseVault__deposit_lessThanMin();
  error BaseVault__mint_moreThanMax();
  error BaseVault__mint_lessThanMin();
  error BaseVault__withdraw_invalidInput();
  error BaseVault__withdraw_moreThanMax();
  error BaseVault__redeem_moreThanMax();
  error BaseVault__redeem_invalidInput();
  error BaseVault__setter_invalidInput();
  error BaseVault__checkRebalanceFee_excessFee();
  error BaseVault__deposit_slippageTooHigh();
  error BaseVault__mint_slippageTooHigh();
  error BaseVault__withdraw_slippageTooHigh();
  error BaseVault__redeem_slippageTooHigh();

  /**
   *  @dev `VERSION` of this vault.
   * Software versioning rules are followed: v-0.0.0 (v-MAJOR.MINOR.PATCH)
   * Major version when you make incompatible ABI changes
   * Minor version when you add functionality in a backwards compatible manner.
   * Patch version when you make backwards compatible fixes.
   */
  string public constant VERSION = string("0.0.1");

  IERC20Metadata internal _asset;

  uint8 private immutable _decimals;

  ILendingProvider[] internal _providers;
  ILendingProvider public activeProvider;

  uint256 public minAmount;
  uint256 public depositCap;

  /**
   * @notice Constructor of a new {BaseVault}.
   *
   * @param asset_ this vault will handle as main asset (collateral)
   * @param chief_ that deploys and controls this vault
   * @param name_ of the token-shares handled in this vault
   * @param symbol_ of the token-shares handled in this vault
   *
   * @dev Requirements:
   * - Must assign `asset_` {ERC20-decimals} and `_decimals` equal.
   * - Must check initial `minAmount` is not < 1e6. Refer to https://rokinot.github.io/hatsfinance.
   * - Must initialize `depositCap` as type(uint256).max.
   */
  constructor(
    address asset_,
    address chief_,
    string memory name_,
    string memory symbol_
  )
    ERC20(name_, symbol_)
    SystemAccessControl(chief_)
    VaultPermissions(name_)
  {
    if (asset_ == address(0) || chief_ == address(0)) {
      revert BaseVault__constructor_invalidInput();
    }
    _asset = IERC20Metadata(asset_);
    _decimals = IERC20Metadata(asset_).decimals();
    depositCap = type(uint128).max;
    minAmount = 1e6;
  }

  /*////////////////////////////////////////////////////
      Asset management: allowance {IERC20} overrides 
      Overrides to handle as `withdrawAllowance`
  ///////////////////////////////////////////////////*/

  /**
   * @notice Returns the shares amount allowed to transfer from
   *  `owner` to `receiver`.
   *
   * @param owner of the shares
   * @param receiver that can receive the shares
   *
   * @dev Requirements:
   * - Must be overriden to call {VaultPermissions-withdrawAllowance}.
   */
  function allowance(
    address owner,
    address receiver
  )
    public
    view
    override(ERC20, IERC20)
    returns (uint256)
  {
    address operator = receiver;
    return convertToShares(withdrawAllowance(owner, operator, receiver));
  }

  /**
   * @notice Approve allowance of `shares` to `receiver`.
   *
   * @param receiver to whom share allowance is being set
   * @param shares amount of allowance
   *
   * @dev Recommend to use increase/decrease methods see OZ notes for {IERC20-approve}.
   * Requirements:
   * - Must be overriden to call {VaultPermissions-_setWithdrawAllowance}.
   * - Must convert `shares` into `assets` amount before calling internal functions.
   */
  function approve(address receiver, uint256 shares) public override(ERC20, IERC20) returns (bool) {
    address owner = _msgSender();
    address operator = receiver;
    _setWithdrawAllowance(owner, operator, receiver, convertToAssets(shares));
    return true;
  }

  /**
   * @notice Increase allowance of token-shares to `receiver` by `shares`.
   *
   * @param receiver to whom shares allowance is being increased
   * @param shares amount to increase allowance
   *
   * @dev Requirements:
   * - Must be overriden to call {VaultPermissions-increaseWithdrawAllowance}
   * - Must convert `shares` to `assets` amount before calling internal functions.
   *   VaultPermissions-increaseWithdrawAllowance.
   */
  function increaseAllowance(address receiver, uint256 shares) public override returns (bool) {
    address operator = receiver;
    increaseWithdrawAllowance(operator, receiver, convertToAssets(shares));
    return true;
  }

  /**
   * @notice Decrease allowance of token-shares to `receiver` by `shares`.
   *
   * @param receiver to whom shares allowance is decreased
   * @param shares amount to decrease allowance
   *
   * @dev Requirements:
   * - Must be overriden to call {VaultPermissions-decreaseWithdrawAllowance}.
   * - Must convert `shares` to `assets` before calling internal functions.
   */
  function decreaseAllowance(address receiver, uint256 shares) public override returns (bool) {
    address operator = receiver;
    decreaseWithdrawAllowance(operator, receiver, convertToAssets(shares));
    return true;
  }

  /**
   * @dev Called during {ERC20-transferFrom} to decrease allowance.
   * Requirements:
   * - Must be overriden to call {VaultPermissions-_spendWithdrawAllowance}.
   * - Msut convert `shares` to `assets` before calling internal functions.
   *
   * @param owner of `shares`
   * @param operator allowed to act on `owners` behalf
   * @param receiver to whom `shares` will be spent
   * @param shares amount to spend
   */
  function _spendAllowance(
    address owner,
    address operator,
    address receiver,
    uint256 shares
  )
    internal
  {
    _spendWithdrawAllowance(owner, operator, receiver, convertToAssets(shares));
  }

  /*//////////////////////////////////////////
      Asset management: overrides IERC4626
  //////////////////////////////////////////*/

  /**
   * @notice Returns the number of decimals used to get number representation.
   */
  function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
    return _decimals;
  }

  /// @inheritdoc IERC4626
  function asset() public view virtual override returns (address) {
    return address(_asset);
  }

  /// @inheritdoc IVault
  function balanceOfAsset(address owner) external view virtual override returns (uint256 assets) {
    return convertToAssets(balanceOf(owner));
  }

  /// @inheritdoc IERC4626
  function totalAssets() public view virtual override returns (uint256 assets) {
    return _checkProvidersBalance("getDepositBalance");
  }

  /// @inheritdoc IERC4626
  function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
    return _convertToShares(assets, Math.Rounding.Down);
  }

  /// @inheritdoc IERC4626
  function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
    return _convertToAssets(shares, Math.Rounding.Down);
  }

  /// @inheritdoc IERC4626
  function maxDeposit(address) public view virtual override returns (uint256) {
    return depositCap - totalAssets();
  }

  /// @inheritdoc IERC4626
  function maxMint(address) public view virtual override returns (uint256) {
    return _convertToShares(maxDeposit(address(0)), Math.Rounding.Down);
  }

  /// @inheritdoc IERC4626
  function maxWithdraw(address owner) public view override returns (uint256) {
    return _computeFreeAssets(owner);
  }

  /// @inheritdoc IERC4626
  function maxRedeem(address owner) public view override returns (uint256) {
    return _convertToShares(_computeFreeAssets(owner), Math.Rounding.Down);
  }

  /// @inheritdoc IERC4626
  function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
    return _convertToShares(assets, Math.Rounding.Down);
  }

  /// @inheritdoc IERC4626
  function previewMint(uint256 shares) public view virtual override returns (uint256) {
    return _convertToAssets(shares, Math.Rounding.Down);
  }

  /// @inheritdoc IERC4626
  function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
    return _convertToShares(assets, Math.Rounding.Down);
  }

  /// @inheritdoc IERC4626
  function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
    return _convertToAssets(shares, Math.Rounding.Down);
  }

  /**
   * @notice Slippage protected `deposit()` per EIP5143.
   *
   * @param assets amount to be deposited
   * @param receiver to whom `assets` amount will be credited
   * @param minShares amount expected from this deposit action
   *
   * @dev Refer to https://eips.ethereum.org/EIPS/eip-5143.
   * Requirements:
   * - Must mint at least `minShares` when calling `deposit()`.
   */
  function deposit(
    uint256 assets,
    address receiver,
    uint256 minShares
  )
    public
    virtual
    returns (uint256)
  {
    uint256 receivedShares = deposit(assets, receiver);
    if (receivedShares < minShares) {
      revert BaseVault__deposit_slippageTooHigh();
    }
    return receivedShares;
  }

  /// @inheritdoc IERC4626
  function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
    uint256 shares = previewDeposit(assets);

    // Use shares because it's cheaper to get `totalSupply()` compared to `totalAssets()`.
    if (shares + totalSupply() > maxMint(receiver)) {
      revert BaseVault__deposit_moreThanMax();
    }
    if (assets < minAmount) {
      revert BaseVault__deposit_lessThanMin();
    }

    _deposit(_msgSender(), receiver, assets, shares);

    return shares;
  }

  /**
   * @notice Slippage protected `mint()` per EIP5143.
   *
   * @param shares amount to mint
   * @param receiver to whom `shares` amount will be credited
   * @param maxAssets amount that Must be credited when calling mint
   *
   * @dev Refer to https://eips.ethereum.org/EIPS/eip-5143.
   * Requirements:
   * - Must not pull more than `maxAssets` when calling `mint()`.
   */
  function mint(
    uint256 shares,
    address receiver,
    uint256 maxAssets
  )
    public
    virtual
    returns (uint256)
  {
    uint256 pulledAssets = mint(shares, receiver);
    if (pulledAssets > maxAssets) {
      revert BaseVault__mint_slippageTooHigh();
    }
    return pulledAssets;
  }

  /// @inheritdoc IERC4626
  function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
    uint256 assets = previewMint(shares);

    if (shares + totalSupply() > maxMint(receiver)) {
      revert BaseVault__mint_moreThanMax();
    }
    if (assets < minAmount) {
      revert BaseVault__mint_lessThanMin();
    }

    _deposit(_msgSender(), receiver, assets, shares);

    return assets;
  }

  /**
   * @notice Slippage protected `withdraw()` per EIP5143.
   *
   * @param assets amount that is being withdrawn
   * @param receiver to whom `assets` amount will be transferred
   * @param owner to whom `assets` amount will be debited
   * @param maxShares amount that shall be burned when calling withdraw
   *
   * @dev Refer to https://eips.ethereum.org/EIPS/eip-5143.
   * Requirements:
   * - Must not burn more than `maxShares` when calling `withdraw()`.
   */
  function withdraw(
    uint256 assets,
    address receiver,
    address owner,
    uint256 maxShares
  )
    public
    virtual
    returns (uint256)
  {
    uint256 burnedShares = withdraw(assets, receiver, owner);
    if (burnedShares > maxShares) {
      revert BaseVault__withdraw_slippageTooHigh();
    }
    return burnedShares;
  }

  /// @inheritdoc IERC4626
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  )
    public
    override
    returns (uint256)
  {
    if (assets == 0 || receiver == address(0) || owner == address(0)) {
      revert BaseVault__withdraw_invalidInput();
    }

    if (assets > maxWithdraw(owner)) {
      revert BaseVault__withdraw_moreThanMax();
    }

    address caller = _msgSender();
    if (caller != owner) {
      _spendAllowance(owner, caller, receiver, convertToShares(assets));
    }

    uint256 shares = previewWithdraw(assets);
    _withdraw(caller, receiver, owner, assets, shares);

    return shares;
  }

  /**
   * @notice Slippage protected `redeem()` per EIP5143.
   *
   * @param shares amount that will be redeemed
   * @param receiver to whom asset equivalent of `shares` amount will be transferred
   * @param owner of the shares
   * @param minAssets amount that `receiver` must expect
   *
   * @dev Refer to https://eips.ethereum.org/EIPS/eip-5143.
   * Requirements:
   * - Must  receive at least `minAssets` when calling `redeem()`.
   */
  function redeem(
    uint256 shares,
    address receiver,
    address owner,
    uint256 minAssets
  )
    public
    virtual
    returns (uint256)
  {
    uint256 receivedAssets = redeem(shares, receiver, owner);
    if (receivedAssets < minAssets) {
      revert BaseVault__redeem_slippageTooHigh();
    }
    return receivedAssets;
  }

  /// @inheritdoc IERC4626
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  )
    public
    override
    returns (uint256)
  {
    if (shares == 0 || receiver == address(0) || owner == address(0)) {
      revert BaseVault__redeem_invalidInput();
    }

    if (shares > maxRedeem(owner)) {
      revert BaseVault__redeem_moreThanMax();
    }

    address caller = _msgSender();
    if (caller != owner) {
      _spendAllowance(owner, caller, receiver, shares);
    }

    uint256 assets = previewRedeem(shares);
    _withdraw(caller, receiver, owner, assets, shares);

    return assets;
  }

  /**
   * @dev Conversion function from `assets` to shares equivalent with support for rounding direction.
   * Requirements:
   * - Must return zero if `assets` or `totalSupply()` == 0.
   * - Must revert if `totalAssets()` is not > 0.
   *   (Corresponds to a case where you divide by zero.)
   *
   * @param assets amount to convert to shares
   * @param rounding direction of division remainder
   */
  function _convertToShares(
    uint256 assets,
    Math.Rounding rounding
  )
    internal
    view
    virtual
    returns (uint256 shares)
  {
    uint256 supply = totalSupply();
    return (assets == 0 || supply == 0) ? assets : assets.mulDiv(supply, totalAssets(), rounding);
  }

  /**
   * @dev Conversion function from `shares` to asset type with support for rounding direction.
   * Requirements:
   * - Must return zero if `totalSupply()` == 0.
   *
   * @param shares amount to convert to assets
   * @param rounding direction of division remainder
   */
  function _convertToAssets(
    uint256 shares,
    Math.Rounding rounding
  )
    internal
    view
    virtual
    returns (uint256 assets)
  {
    uint256 supply = totalSupply();
    return (supply == 0) ? shares : shares.mulDiv(totalAssets(), supply, rounding);
  }

  /**
   * @dev Perform `_deposit()` at provider {IERC4626-deposit}.
   * Requirements:
   * - Must call `activeProvider` in `_executeProviderAction()`.
   * - Must emit a Deposit event.
   *
   * @param caller or {msg.sender}
   * @param receiver to whom `assets` are credited by `shares` amount
   * @param assets amount transferred during this deposit
   * @param shares amount credited to `receiver` during this deposit
   */
  function _deposit(
    address caller,
    address receiver,
    uint256 assets,
    uint256 shares
  )
    internal
    whenNotPaused(VaultActions.Deposit)
  {
    SafeERC20.safeTransferFrom(IERC20(asset()), caller, address(this), assets);
    _executeProviderAction(assets, "deposit", activeProvider);
    _mint(receiver, shares);

    emit Deposit(caller, receiver, assets, shares);
  }

  /**
   * @dev Perform `_withdraw()` at provider {IERC4626-withdraw}.
   * Requirements:
   * - Must call `activeProvider` in `_executeProviderAction()`.
   * - Must emit a Withdraw event.
   *
   * @param caller or {msg.sender}
   * @param receiver to whom `assets` amount will be transferred to
   * @param owner to whom `shares` will be burned
   * @param assets amount transferred during this withraw
   * @param shares amount burned to `owner` during this withdraw
   */
  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  )
    internal
    whenNotPaused(VaultActions.Withdraw)
  {
    _burn(owner, shares);
    _executeProviderAction(assets, "withdraw", activeProvider);
    SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);

    emit Withdraw(caller, receiver, owner, assets, shares);
  }

  /**
   * @dev Hook before all token-share transfers.
   * Requirements:
   * - Must check `from` can move `amount` of shares.
   *
   * @param from address
   * @param to address
   * @param amount of shares
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
    to;
    if (from != address(0)) {
      require(amount <= maxRedeem(from), "Transfer more than max");
    }
  }

  /*//////////////////////////////////////////////////
      Debt management: based on IERC4626 semantics
  //////////////////////////////////////////////////*/

  /// @inheritdoc IVault
  function debtDecimals() public view virtual override returns (uint8);

  /// @inheritdoc IVault
  function debtAsset() public view virtual returns (address);

  /// @inheritdoc IVault
  function balanceOfDebt(address account) public view virtual override returns (uint256 debt);

  /// @inheritdoc IVault
  function balanceOfDebtShares(address owner)
    external
    view
    virtual
    override
    returns (uint256 debtShares);

  /// @inheritdoc IVault
  function totalDebt() public view virtual returns (uint256);

  /// @inheritdoc IVault
  function convertDebtToShares(uint256 debt) public view virtual returns (uint256 shares);

  /// @inheritdoc IVault
  function convertToDebt(uint256 shares) public view virtual returns (uint256 debt);

  /// @inheritdoc IVault
  function maxBorrow(address borrower) public view virtual returns (uint256);

  /// @inheritdoc IVault
  function borrow(uint256 debt, address receiver, address owner) public virtual returns (uint256);

  /// @inheritdoc IVault
  function payback(uint256 debt, address owner) public virtual returns (uint256);

  /**
   * @notice Returns borrow allowance. See {IVaultPermissions-borrowAllowance}.
   *
   * @param owner that provides borrow allowance
   * @param operator who can process borrow allowance on owner's behalf
   * @param receiver who can spend borrow allowance
   *
   * @dev Requirements:
   * - Must be implemented in a {BorrowingVault}, and revert in a {YieldVault}.
   */
  function borrowAllowance(
    address owner,
    address operator,
    address receiver
  )
    public
    view
    virtual
    override
    returns (uint256)
  {}

  /**
   * @notice Increase borrow allowance. See {IVaultPermissions-decreaseborrowAllowance}.
   *
   * @param operator who can process borrow allowance on owner's behalf
   * @param receiver whom spending borrow allowance is increasing
   *
   * @dev Requirements:
   * - Must be immplemented in a {BorrowingVault}, and revert in a {YieldVault}.
   */
  function increaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {}

  /**
   * @notice Decrease borrow allowance. See {IVaultPermissions-decreaseborrowAllowance}.
   *
   * @param operator address who can process borrow allowance on owner's behalf
   * @param receiver address whom spending borrow allowance is decreasing
   *
   * @dev Requirements:
   * - Must be implemented in a {BorrowingVault}, revert in a {YieldVault}.
   */
  function decreaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {}

  /**
   * @notice Process signed permit for borrow allowance. See {IVaultPermissions-permitBorrow}.
   *
   * @param owner address who signed this permit
   * @param receiver address whom spending borrow allowance will be set
   * @param value amount of borrow allowance
   * @param deadline timestamp at when this permit expires
   * @param v signature value
   * @param r signature value
   * @param s signature value
   *
   * @dev Requirements:
   * - Must be implemented in a {BorrowingVault}, revert in a {YieldVault}.
   */
  function permitBorrow(
    address owner,
    address receiver,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
    virtual
    override
  {}

  /**
   * @dev Compute how much free 'assets' a user can withdraw or transfer
   * given their `balanceOfDebt()`.
   * Requirements:
   * - Must be implemented in {BorrowingVault} contract.
   * - Must not be implemented in a {YieldVault} contract.
   * - Must read price from {FujiOracle}.
   *
   * @param owner address to whom free assets is being checked
   */
  function _computeFreeAssets(address owner) internal view virtual returns (uint256);

  /*//////////////////////////
      Fuji Vault functions
  //////////////////////////*/

  /**
   * @dev Execute an action at provider.
   *
   * @param assets amount handled in this action
   * @param name string of the method to call
   * @param provider to whom action is being called
   */
  function _executeProviderAction(
    uint256 assets,
    string memory name,
    ILendingProvider provider
  )
    internal
  {
    bytes memory data = abi.encodeWithSignature(
      string(abi.encodePacked(name, "(uint256,address)")), assets, address(this)
    );
    address(provider).functionDelegateCall(
      data, string(abi.encodePacked(name, ": delegate call failed"))
    );
  }

  /**
   * @dev Returns balance of `asset` or `debtAsset` of this vault at all
   * listed providers in `_providers` array.
   *
   * @param method string method to call: "getDepositBalance" or "getBorrowBalance".
   */
  function _checkProvidersBalance(string memory method) internal view returns (uint256 assets) {
    uint256 len = _providers.length;
    bytes memory callData = abi.encodeWithSignature(
      string(abi.encodePacked(method, "(address,address)")), address(this), address(this)
    );
    bytes memory returnedBytes;
    for (uint256 i = 0; i < len;) {
      returnedBytes = address(_providers[i]).functionStaticCall(callData, ": balance call failed");
      assets += uint256(bytes32(returnedBytes));
      unchecked {
        ++i;
      }
    }
  }

  /*////////////////////
      Public getters
  /////////////////////*/

  /**
   * @notice Returns the array of providers of this vault.
   */
  function getProviders() external view returns (ILendingProvider[] memory list) {
    list = _providers;
  }

  /*/////////////////////////
       Admin set functions
  /////////////////////////*/

  /// @inheritdoc IVault
  function setProviders(ILendingProvider[] memory providers) external onlyTimelock {
    _setProviders(providers);
  }

  /// @inheritdoc IVault
  function setActiveProvider(ILendingProvider activeProvider_) external override onlyTimelock {
    _setActiveProvider(activeProvider_);
  }

  /// @inheritdoc IVault
  function setMinAmount(uint256 amount) external override onlyTimelock {
    minAmount = amount;
    emit MinAmountChanged(amount);
  }

  /// @inheritdoc IVault
  function setDepositCap(uint256 newCap) external override onlyTimelock {
    if (newCap == 0 || newCap <= minAmount) {
      revert BaseVault__setter_invalidInput();
    }
    depositCap = newCap;
    emit DepositCapChanged(newCap);
  }

  /// @inheritdoc PausableVault
  function pauseForceAll() external override hasRole(msg.sender, PAUSER_ROLE) {
    _pauseForceAllActions();
  }

  /// @inheritdoc PausableVault
  function unpauseForceAll() external override hasRole(msg.sender, UNPAUSER_ROLE) {
    _unpauseForceAllActions();
  }

  /// @inheritdoc PausableVault
  function pause(VaultActions action) external virtual override hasRole(msg.sender, PAUSER_ROLE) {
    _pause(action);
  }

  /// @inheritdoc PausableVault
  function unpause(VaultActions action)
    external
    virtual
    override
    hasRole(msg.sender, UNPAUSER_ROLE)
  {
    _unpause(action);
  }

  /**
   * @dev Sets the providers of this vault.
   * Requirements:
   * - Must be implemented at {BorrowingVault} or {YieldVault} level.
   * - Must infinite approve erc20 transfers of `asset` or `debtAsset` accordingly.
   * - Must emit a ProvidersChanged event.
   *
   * @param providers array of addresses
   */
  function _setProviders(ILendingProvider[] memory providers) internal virtual;

  /**
   * @dev Sets the `activeProvider` of this vault.
   * Requirements:
   * - Must emit an ActiveProviderChanged event.
   *
   * @param activeProvider_ address to be set
   */
  function _setActiveProvider(ILendingProvider activeProvider_) internal {
    if (!_isValidProvider(address(activeProvider_))) {
      revert BaseVault__setter_invalidInput();
    }
    activeProvider = activeProvider_;
    emit ActiveProviderChanged(activeProvider_);
  }

  /**
   * @dev Returns true if `provider` is in `_providers` array.
   *
   * @param provider address
   */
  function _isValidProvider(address provider) internal view returns (bool check) {
    uint256 len = _providers.length;
    for (uint256 i = 0; i < len;) {
      if (provider == address(_providers[i])) {
        check = true;
      }
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Check rebalance fee is within 10 basis points.
   * Requirements:
   * - Must be equal to or less than %0.10 (max 10 basis points) of `amount`.
   *
   * @param fee amount to be checked
   * @param amount being rebalanced to check against
   */
  function _checkRebalanceFee(uint256 fee, uint256 amount) internal pure {
    uint256 reasonableFee = (amount * 10) / 10000;
    if (fee > reasonableFee) {
      revert BaseVault__checkRebalanceFee_excessFee();
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title EIP712
 *
 * @author Fujidao Labs
 *
 * @notice EIP712 abstract contract for VaultPermissions.
 *
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and
 * signing of typed structured data.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that
 * is used as part of the encoding scheme, and the final step of the encoding to obtain
 * the message digest that is then signed via ECDSA ({_hashTypedDataV4}).
 *
 * A big part of this implementation is inspired from:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol
 *
 * The main difference with OZ is that the "chainid" is not included in the domain separator
 * but in the structHash. The rationale behind is to adapt EIP712 to our cross-chain message
 * signing: allowing a user on chain A to sign a message that will be verified on chain B.
 * If we were to include the "chainid" in the domain separator, that would require the user
 * to switch networks back and forth, because of the limitation: "The user-agent should
 * refuse signing if it does not match the currently active chain.". That would serously
 * deteriorate the UX.
 *
 * Indeed, EIP712 doesn't forbid it as it states that "Protocol designers only need to
 * include the fields that make sense for their signing domain." into the the struct
 * "EIP712Domain". However, we decided to add a ref to "chainid" in the param salt. Together
 * with "chainid" in the typeHash, we assume those provide sufficient security guarantees.
 */

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

abstract contract EIP712 {
  /* solhint-disable var-name-mixedcase */
  /**
   * @dev Cache the domain separator as an immutable value, but also store
   * the chain id that it corresponds to, in order to invalidate the cached
   * domain separator if the chain id changes.
   */
  bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
  uint256 private immutable _CACHED_CHAIN_ID;
  address private immutable _CACHED_THIS;

  bytes32 private immutable _HASHED_NAME;
  bytes32 private immutable _HASHED_VERSION;
  bytes32 private immutable _TYPE_HASH;

  /**
   * @notice Constructor to initializes the domain separator and parameter caches.
   *
   * @param name_ of the signing domain, i.e. the name of the DApp or the protocol
   * @param version_ of the current major version of the signing domain
   *
   * @dev The meaning of `name` and `version` is specified in
   * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
   * NOTE: These parameters cannot be changed except through a
   * xref:learn::upgrading-smart-contracts.adoc[smartcontract upgrade].
   */
  constructor(string memory name_, string memory version_) {
    bytes32 hashedName = keccak256(bytes(name_));
    bytes32 hashedVersion = keccak256(bytes(version_));
    bytes32 typeHash =
      keccak256("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)");
    _HASHED_NAME = hashedName;
    _HASHED_VERSION = hashedVersion;
    _CACHED_CHAIN_ID = block.chainid;
    _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
    _CACHED_THIS = address(this);
    _TYPE_HASH = typeHash;
  }

  /**
   * @dev Returns the domain separator of this contract.
   */
  function _domainSeparatorV4() internal view returns (bytes32) {
    if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
      return _CACHED_DOMAIN_SEPARATOR;
    } else {
      return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
    }
  }

  /**
   * @dev Builds and returns domain seperator according to inputs.
   *
   * @param typeHash cached in this contract
   * @param nameHash cahed in this contract
   * @param versionHash cached in this contract
   */
  function _buildDomainSeparator(
    bytes32 typeHash,
    bytes32 nameHash,
    bytes32 versionHash
  )
    private
    view
    returns (bytes32)
  {
    return keccak256(
      abi.encode(
        typeHash, nameHash, versionHash, address(this), keccak256(abi.encode(block.chainid))
      )
    );
  }

  /**
   * @dev Given an already:
   * https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct],
   * this function returns the hash of the fully encoded EIP712 message for this domain.
   *
   * This hash can be used together with {ECDSA-recover} to obtain the signer of
   * a message. For example:
   *
   * ```solidity
   * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
   *     keccak256("Mail(address to,string contents)"),
   *     mailTo,
   *     keccak256(bytes(mailContents))
   * )));
   * address signer = ECDSA.recover(digest, signature);
   * ```
   * @param structHash of signed data
   */
  function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
    return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title PausableVault
 *
 * @author Fujidao Labs
 *
 * @notice Abstract pausable contract developed for granular control over vault actions.
 * This contract should be inherited by a vault implementation. The code is inspired on
 * OpenZeppelin-Pausable contract.
 */

import {IPausableVault} from "../interfaces/IPausableVault.sol";

abstract contract PausableVault is IPausableVault {
  /// @dev Custom Errors
  error PausableVault__requiredNotPaused_actionPaused();
  error PausableVault__requiredPaused_actionNotPaused();

  mapping(VaultActions => bool) private _actionsPaused;

  /**
   * @dev Modifier to make a function callable only when `VaultAction` in the contract
   * is not paused.
   */
  modifier whenNotPaused(VaultActions action) {
    _requireNotPaused(action);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when `VaultAction` in the contract
   * is paused.
   */
  modifier whenPaused(VaultActions action) {
    _requirePaused(action);
    _;
  }

  /// @inheritdoc IPausableVault
  function paused(VaultActions action) public view virtual returns (bool) {
    return _actionsPaused[action];
  }

  /// @inheritdoc IPausableVault
  function pauseForceAll() external virtual override;

  /// @inheritdoc IPausableVault
  function unpauseForceAll() external virtual override;

  /// @inheritdoc IPausableVault
  function pause(VaultActions action) external virtual override;

  /// @inheritdoc IPausableVault
  function unpause(VaultActions action) external virtual override;

  /**
   * @dev Throws if the `action` in contract is paused.
   *
   * @param action Enum: 0-deposit, 1-withdraw, 2-borrow, 3-payback
   */
  function _requireNotPaused(VaultActions action) private view {
    if (_actionsPaused[action]) {
      revert PausableVault__requiredNotPaused_actionPaused();
    }
  }

  /**
   * @dev Throws if the `action` in contract is not paused.
   *
   * @param action Enum: 0-deposit, 1-withdraw, 2-borrow, 3-payback
   */
  function _requirePaused(VaultActions action) private view {
    if (!_actionsPaused[action]) {
      revert PausableVault__requiredPaused_actionNotPaused();
    }
  }

  /**
   * @dev Sets pause state for `action` of this vault.
   *
   * @param action Enum: 0-deposit, 1-withdraw, 2-borrow, 3-payback
   */
  function _pause(VaultActions action) internal whenNotPaused(action) {
    _actionsPaused[action] = true;
    emit Paused(msg.sender, action);
  }

  /**
   * @dev Sets unpause state for `action` of this vault.
   *
   * @param action Enum: 0-deposit, 1-withdraw, 2-borrow, 3-payback
   */
  function _unpause(VaultActions action) internal whenPaused(action) {
    _actionsPaused[action] = false;
    emit Unpaused(msg.sender, action);
  }

  /**
   * @dev Forces set paused state for all `VaultActions`.
   */
  function _pauseForceAllActions() internal {
    _actionsPaused[VaultActions.Deposit] = true;
    _actionsPaused[VaultActions.Withdraw] = true;
    _actionsPaused[VaultActions.Borrow] = true;
    _actionsPaused[VaultActions.Payback] = true;
    emit PausedForceAll(msg.sender);
  }

  /**
   * @dev Forces set unpause state for all `VaultActions`.
   */
  function _unpauseForceAllActions() internal {
    _actionsPaused[VaultActions.Deposit] = false;
    _actionsPaused[VaultActions.Withdraw] = false;
    _actionsPaused[VaultActions.Borrow] = false;
    _actionsPaused[VaultActions.Payback] = false;
    emit UnpausedForceAll(msg.sender);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title CoreRoles
 *
 * @author Fujidao Labs
 *
 * @notice System definition of roles used across FujiV2 contracts.
 */

contract CoreRoles {
  bytes32 public constant HOUSE_KEEPER_ROLE = keccak256("HOUSE_KEEPER_ROLE");

  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  bytes32 public constant HARVESTER_ROLE = keccak256("HARVESTER_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title SystemAccessControl
 *
 * @author Fujidao Labs
 *
 * @notice Abstract contract that should be inherited by contract implementations that
 * call the {Chief} contract for access control checks.
 */

import {IChief} from "../interfaces/IChief.sol";
import {CoreRoles} from "./CoreRoles.sol";

contract SystemAccessControl is CoreRoles {
  /// @dev Custom Errors
  error SystemAccessControl__hasRole_missingRole(address caller, bytes32 role);
  error SystemAccessControl__onlyTimelock_callerIsNotTimelock();
  error SystemAccessControl__onlyHouseKeeper_notHouseKeeper();

  IChief public immutable chief;

  /**
   * @dev Modifier that checks `caller` has `role`.
   */
  modifier hasRole(address caller, bytes32 role) {
    if (!chief.hasRole(role, caller)) {
      revert SystemAccessControl__hasRole_missingRole(caller, role);
    }
    _;
  }

  /**
   * @dev Modifier that checks `msg.sender` has HOUSE_KEEPER_ROLE.
   */
  modifier onlyHouseKeeper() {
    if (!chief.hasRole(HOUSE_KEEPER_ROLE, msg.sender)) {
      revert SystemAccessControl__onlyHouseKeeper_notHouseKeeper();
    }
    _;
  }

  /**
   * @dev Modifier that checks `msg.sender` is the defined `timelock` in {Chief}
   * contract.
   */
  modifier onlyTimelock() {
    if (msg.sender != chief.timelock()) {
      revert SystemAccessControl__onlyTimelock_callerIsNotTimelock();
    }
    _;
  }

  /**
   * @notice Abstract constructor of a new {SystemAccessControl}.
   *
   * @param chief_ address
   *
   * @dev Requirements:
   * - Must pass non-zero {Chief} address, that could be checked at child contract.
   */
  constructor(address chief_) {
    chief = IChief(chief_);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IChief
 *
 * @author Fujidao Labs
 *
 * @notice Defines interface for {Chief} access control operations.
 */

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IChief is IAccessControl {
  /// @notice Returns the timelock address of the FujiV2 system.
  function timelock() external view returns (address);

  /// @notice Returns the address mapper contract address of the FujiV2 system.
  function addrMapper() external view returns (address);

  /**
   * @notice Returns true if `flasher` is an allowed {IFlasher}.
   *
   * @param flasher address to check
   */
  function allowedFlasher(address flasher) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IFlasher
 * @author Fujidao Labs
 * @notice Defines the interface for all flashloan providers.
 */

interface IFlasher {
  /**
   * @notice Initiates a flashloan a this provider.
   * @param asset address to be flashloaned.
   * @param amount of `asset` to be flashloaned.
   * @param requestor address to which flashloan will be facilitated.
   * @param requestorCalldata encoded args with selector that will be OPCODE-CALL'ed to `requestor`.
   * @dev To encode `params` see examples:
   * • solidity:
   *   > abi.encodeWithSelector(contract.transferFrom.selector, from, to, amount);
   * • ethersJS:
   *   > contract.interface.encodeFunctionData("transferFrom", [from, to, amount]);
   * • foundry cast:
   *   > cast calldata "transferFrom(address,address,uint256)" from, to, amount
   *
   * Requirements:
   * - MUST implement `_checkAndSetEntryPoint()`
   */
  function initiateFlashloan(
    address asset,
    uint256 amount,
    address requestor,
    bytes memory requestorCalldata
  )
    external;

  /**
   * @notice Returns the address from which flashloan for `asset` is sourced.
   * @param asset intended to be flashloaned.
   * @dev Override at flashloan provider implementation as required.
   * Some protocol implementations source flashloans from different contracts
   * depending on `asset`.
   */
  function getFlashloanSourceAddr(address asset) external view returns (address callAddr);

  /**
   * @notice Returns the expected flashloan fee for `amount`
   * of this flashloan provider.
   * @param asset to be flashloaned
   * @param amount of flashloan
   */
  function computeFlashloanFee(address asset, uint256 amount) external view returns (uint256 fee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IFujiOracle
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface of the {FujiOracle}.
 */

interface IFujiOracle {
  /**
   * @dev Emit when a change in price feed address is done for an `asset`.
   *
   * @param asset address
   * @param newPriceFeedAddress that returns USD price from Chainlink
   */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  /**
   * @notice Returns the exchange rate between two assets, with price oracle given in
   * specified `decimals`.
   *
   * @param currencyAsset to be used, zero-address for USD
   * @param commodityAsset to be used, zero-address for USD
   * @param decimals  of the desired price output
   *
   * @dev Price format is defined as: (currencyAsset per unit of commodityAsset Exchange Rate).
   * Requirements:
   * - Must check that both `currencyAsset` and `commodityAsset` are set in
   *   usdPriceFeeds, otherwise return zero.
   */
  function getPriceOf(
    address currencyAsset,
    address commodityAsset,
    uint8 decimals
  )
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IVault} from "./IVault.sol";

/**
 * @title ILendingProvider
 *
 * @author Fujidao Labs
 *
 * @notice  Defines the interface for core engine to perform operations at lending providers.
 *
 * @dev Functions are intended to be called in the context of a Vault via delegateCall,
 * except indicated.
 */

interface ILendingProvider {
  function providerName() external view returns (string memory);
  /**
   * @notice Returns the operator address that requires ERC20-approval for vault operations.
   *
   * @param keyAsset address to inquiry operator
   * @param asset address of the calling vault
   * @param debtAsset address of the calling vault. Note: if {YieldVault} this will be address(0).
   *
   * @dev Provider implementations may or not require all 3 inputs.
   */
  function approvedOperator(
    address keyAsset,
    address asset,
    address debtAsset
  )
    external
    view
    returns (address operator);

  /**
   * @notice Performs deposit operation at lending provider on behalf vault.
   *
   * @param amount amount to deposit
   * @param vault IVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function deposit(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs borrow operation at lending provider on behalf vault.
   *
   * @param amount amount to borrow
   * @param vault IVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function borrow(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs withdraw operation at lending provider on behalf vault.
   * @param amount amount to withdraw
   * @param vault IVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function withdraw(uint256 amount, IVault vault) external returns (bool success);

  /**
   *
   * @notice Performs payback operation at lending provider on behalf vault.
   *
   * @param amount amount to payback
   * @param vault IVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   * - Check there is erc20-approval to `approvedOperator` by the `vault` prior to call.
   */
  function payback(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Returns DEPOSIT balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getDepositBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns BORROW balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getBorrowBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns the latest SUPPLY annual percent rate (APR) at lending provider.
   *
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getDepositRateFor(IVault vault) external view returns (uint256 rate);

  /**
   * @notice Returns the latest BORROW annual percent rate (APR) at lending provider.
   *
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getBorrowRateFor(IVault vault) external view returns (uint256 rate);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IPausableVault
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface {PausableVault} contract.
 */

interface IPausableVault {
  enum VaultActions {
    Deposit,
    Withdraw,
    Borrow,
    Payback
  }

  /**
   * @dev Emit when pause of `action` is triggered by `account`.
   *
   * @param account who called the pause
   * @param action being paused
   */
  event Paused(address account, VaultActions action);
  /**
   * @dev Emit when the pause of `action` is lifted by `account`.
   *
   * @param account who called the unpause
   * @param action being paused
   */
  event Unpaused(address account, VaultActions action);
  /**
   * emit
   * @dev Emitted when forced pause all `VaultActions` triggered by `account`.
   *
   * @param account who called all pause
   */
  event PausedForceAll(address account);
  /**
   * @dev Emit when forced pause is lifted to all `VaultActions` by `account`.
   *
   * @param account who called the all unpause
   */
  event UnpausedForceAll(address account);

  /**
   * @notice Returns true if the `action` in contract is paused, otherwise false.
   *
   * @param action to check pause status
   */
  function paused(VaultActions action) external view returns (bool);

  /**
   * @notice Force pause state for all `VaultActions`.
   *
   * @dev Requirements:
   * - Must be implemented in child contract with access restriction.
   */
  function pauseForceAll() external;

  /**
   * @notice Force unpause state for all `VaultActions`.
   *
   * @dev Requirements:
   * - Must be implemented in child contract with access restriction.
   */
  function unpauseForceAll() external;

  /**
   * @notice Set paused state for `action` of this vault.
   *
   * @param action Enum: 0-deposit, 1-withdraw, 2-borrow, 3-payback
   *
   * Requirements:
   * - The `action` in contract must not be unpaused.
   * - Must be implemented in child contract with access restriction.
   */
  function pause(VaultActions action) external;

  /**
   * @notice Set unpause state for `action` of this vault.
   *
   * @param action Enum: 0-deposit, 1-withdraw, 2-borrow, 3-payback
   *
   * @dev Requirements:
   * - The `action` in contract must be paused.
   * - Must be implemented in child contract with access restriction.
   */
  function unpause(VaultActions action) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IVault
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface for vaults extending from IERC4326.
 */

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {ILendingProvider} from "./ILendingProvider.sol";
import {IFujiOracle} from "./IFujiOracle.sol";

interface IVault is IERC4626 {
  /**
   * @dev Emit when borrow action occurs.
   *
   * @param sender who calls {IVault-borrow}
   * @param receiver of the borrowed 'debt' amount
   * @param owner who will incur the debt
   * @param debt amount
   * @param shares amount of 'debtShares' received
   */
  event Borrow(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 debt,
    uint256 shares
  );

  /**
   * @dev Emit when payback action occurs.
   *
   * @param sender address who calls {IVault-payback}
   * @param owner address whose debt will be reduced
   * @param debt amount
   * @param shares amound of 'debtShares' burned
   */
  event Payback(address indexed sender, address indexed owner, uint256 debt, uint256 shares);

  /**
   * @dev Emit when the oracle address is changed.
   *
   * @param newOracle the new oracle address
   */
  event OracleChanged(IFujiOracle newOracle);

  /**
   * @dev Emit when the available providers for the vault change.
   *
   * @param newProviders the new providers available
   */
  event ProvidersChanged(ILendingProvider[] newProviders);

  /**
   * @dev Emit when the active provider is changed.
   *
   * @param newActiveProvider the new active provider
   */
  event ActiveProviderChanged(ILendingProvider newActiveProvider);

  /**
   * @dev Emit when the vault is rebalanced.
   *
   * @param assets amount to be rebalanced
   * @param debt amount to be rebalanced
   * @param from provider
   * @param to provider
   */
  event VaultRebalance(uint256 assets, uint256 debt, address indexed from, address indexed to);

  /**
   * @dev Emit when the max LTV is changed.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   *
   * @param newMaxLtv the new max LTV
   */
  event MaxLtvChanged(uint256 newMaxLtv);

  /**
   * @dev Emit when the liquidation ratio is changed.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   *
   * @param newLiqRatio the new liquidation ratio
   */
  event LiqRatioChanged(uint256 newLiqRatio);

  /**
   * @dev Emit when the minumum amount is changed.
   *
   * @param newMinAmount the new minimum amount
   */
  event MinAmountChanged(uint256 newMinAmount);

  /**
   * @dev Emit when the deposit cap is changed.
   *
   * @param newDepositCap the new deposit cap of this vault
   */
  event DepositCapChanged(uint256 newDepositCap);

  /*///////////////////////////
    Asset management functions
  //////////////////////////*/

  /**
   * @notice Returns the amount of assets owned by `owner`.
   *
   * @param owner to check balance
   *
   * @dev This method avoids having to do external conversions from shares to
   * assets, since {IERC4626-balanceOf} returns shares.
   */
  function balanceOfAsset(address owner) external view returns (uint256 assets);

  /*///////////////////////////
    Debt management functions
  //////////////////////////*/

  /**
   * @notice Returns the decimals for 'debtAsset' of this vault.
   *
   * @dev Requirements:
   * - Must match the 'debtAsset' decimals in ERC20 token.
   * - Must return zero in a {YieldVault}.
   */
  function debtDecimals() external view returns (uint8);

  /**
   * @notice Returns the address of the underlying token used as debt in functions
   * `borrow()`, and `payback()`. Based on {IERC4626-asset}.
   *
   * @dev Requirements:
   * - Must be an ERC-20 token contract.
   * - Must not revert.
   * - Must return zero in a {YieldVault}.
   */
  function debtAsset() external view returns (address);

  /**
   * @notice Returns the amount of debt owned by `owner`.
   *
   * @param owner to check balance
   */
  function balanceOfDebt(address owner) external view returns (uint256 debt);

  /**
   * @notice Returns the amount of `debtShares` owned by `owner`.
   *
   * @param owner to check balance
   */
  function balanceOfDebtShares(address owner) external view returns (uint256 debtShares);

  /**
   * @notice Returns the total amount of the underlying debt asset
   * that is “managed” by this vault. Based on {IERC4626-totalAssets}.
   *
   * @dev Requirements:
   * - Must account for any compounding occuring from yield or interest accrual.
   * - Must be inclusive of any fees that are charged against assets in the Vault.
   * - Must not revert.
   * - Must return zero in a {YieldVault}.
   */
  function totalDebt() external view returns (uint256);

  /**
   * @notice Returns the amount of shares this vault would exchange for the amount
   * of debt assets provided. Based on {IERC4626-convertToShares}.
   *
   * @param debt to convert into `debtShares`
   *
   * @dev Requirements:
   * - Must not be inclusive of any fees that are charged against assets in the Vault.
   * - Must not show any variations depending on the caller.
   * - Must not reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - Must not revert.
   *
   * NOTE: This calculation MAY not reflect the “per-user” price-per-share, and instead Must reflect the
   * “average-user’s” price-per-share, meaning what the average user Must expect to see when exchanging to and
   * from.
   */
  function convertDebtToShares(uint256 debt) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of debt assets that this vault would exchange for the amount
   * of shares provided. Based on {IERC4626-convertToAssets}.
   *
   * @param shares amount to convert into `debt`
   *
   * @dev Requirements:
   * - Must not be inclusive of any fees that are charged against assets in the Vault.
   * - Must not show any variations depending on the caller.
   * - Must not reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - Must not revert.
   *
   * NOTE: This calculation MAY not reflect the “per-user” price-per-share, and instead must reflect the
   * “average-user’s” price-per-share, meaning what the average user Must expect to see when exchanging to and
   * from.
   */
  function convertToDebt(uint256 shares) external view returns (uint256 debt);

  /**
   * @notice Returns the maximum amount of the debt asset that can be borrowed for the `owner`,
   * through a borrow call. Based on {IERC4626-maxDeposit}.
   *
   * @param owner to check
   *
   * @dev Requirements:
   * - Must return a limited value if receiver is subject to some borrow limit.
   * - Must return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be borrowed.
   * - Must not revert.
   */
  function maxBorrow(address owner) external view returns (uint256);

  /**
   * @notice Perform a borrow action. Function inspired on {IERC4626-deposit}.
   *
   * @param debt amount
   * @param receiver of the `debt` amount
   * @param owner who will incur the `debt` amount
   *
   * * @dev Mints debtShares to owner by taking a loan of exact amount of underlying tokens.
   * Requirements:
   * - Must emit the Borrow event.
   * - Must revert if owner does not own sufficient collateral to back debt.
   * - Must revert if caller is not owner or permissioned operator to act on owner behalf.
   */
  function borrow(uint256 debt, address receiver, address owner) external returns (uint256);

  /**
   * @notice Burns `debtShares` to `receiver` by paying back loan with exact amount of underlying tokens.
   *
   * @param debt amount to payback
   * @param receiver to whom debt amount is being paid back
   *
   * @dev Implementations will require pre-erc20-approval of the underlying asset token.
   * Requirements:
   * - Must emit a Payback event.
   */
  function payback(uint256 debt, address receiver) external returns (uint256);

  /*///////////////////
    General functions
  ///////////////////*/

  /**
   * @notice Returns the active provider of this vault.
   */
  function getProviders() external view returns (ILendingProvider[] memory);
  /**
   * @notice Returns the active provider of this vault.
   */
  function activeProvider() external view returns (ILendingProvider);

  /*/////////////////////////
     Rebalancing Function
  ////////////////////////*/

  /**
   * @notice Performs rebalancing of vault by moving funds across providers.
   *
   * @param assets amount of this vault to be rebalanced
   * @param debt amount of this vault to be rebalanced (Note: pass zero if this is a {YieldVault})
   * @param from provider
   * @param to provider
   * @param fee expected from rebalancing operation
   * @param setToAsActiveProvider boolean
   *
   * @dev Requirements:
   * - Must check providers `from` and `to` are valid.
   * - Must be called from a {RebalancerManager} contract that makes all proper checks.
   * - Must revert if caller is not an approved rebalancer.
   * - Must emit the VaultRebalance event.
   * - Must check `fee` is a reasonable amount.
   */
  function rebalance(
    uint256 assets,
    uint256 debt,
    ILendingProvider from,
    ILendingProvider to,
    uint256 fee,
    bool setToAsActiveProvider
  )
    external
    returns (bool);

  /*/////////////////////////
     Liquidation Functions
  /////////////////////////*/

  /**
   * @notice Returns the current health factor of 'owner'.
   *
   * @param owner to get health factor
   *
   * @dev Requirements:
   * - Must return type(uint254).max when 'owner' has no debt.
   * - Must revert in {YieldVault}.
   *
   * 'healthFactor' is scaled up by 1e18. A value below 1e18 means 'owner' is eligable for liquidation.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   */
  function getHealthFactor(address owner) external returns (uint256 healthFactor);

  /**
   * @notice Returns the liquidation close factor based on 'owner's' health factor.
   *
   * @param owner of debt position
   *
   * @dev Requirements:
   * - Must return zero if `owner` is not liquidatable.
   * - Must revert in {YieldVault}.
   */
  function getLiquidationFactor(address owner) external returns (uint256 liquidationFactor);

  /**
   * @notice Performs liquidation of an unhealthy position, meaning a 'healthFactor' below 100.
   *
   * @param owner to be liquidated
   * @param receiver of the collateral shares of liquidation
   *
   * @dev Requirements:
   * - Must revert if caller is not an approved liquidator.
   * - Must revert if 'owner' is not liquidatable.
   * - Must emit the Liquidation event.
   * - Must liquidate 50% of 'owner' debt when: 100 >= 'healthFactor' > 95.
   * - Must liquidate 100% of 'owner' debt when: 95 > 'healthFactor'.
   * - Must revert in {YieldVault}.
   *
   * WARNING! It is liquidator's responsability to check if liquidation is profitable.
   */
  function liquidate(address owner, address receiver) external returns (uint256 gainedShares);

  /*/////////////////////
     Setter functions 
  ////////////////////*/

  /**
   * @notice Sets the lists of providers of this vault.
   *
   * @param providers address array
   *
   * @dev Requirements:
   * - Must not contain zero addresses.
   */
  function setProviders(ILendingProvider[] memory providers) external;

  /**
   * @notice Sets the active provider for this vault.
   *
   * @param activeProvider address
   *
   * @dev Requirements:
   * - Must be a provider previously set by `setProviders()`.
   * - Must be called from a timelock contract.
   *
   * WARNING! Changing active provider without a `rebalance()` call
   * can result in denial of service for vault users.
   */
  function setActiveProvider(ILendingProvider activeProvider) external;

  /**
   * @notice Sets the minimum amount for: `deposit()`, `mint()` and borrow()`.
   *
   * @param amount to be as minimum.
   */
  function setMinAmount(uint256 amount) external;

  /**
   * @notice Sets the deposit cap amount of this vault.
   *
   * @param newCap amount to be set
   *
   * @dev Requirements:
   * - Must be greater than zero.
   */
  function setDepositCap(uint256 newCap) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IVaultPermissions
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface for a vault extended with
 * signed permit operations for `withdraw()` and `borrow()` allowance.
 */

interface IVaultPermissions {
  /**
   * @dev Emitted when `asset` withdraw allowance is set.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param amount of allowance given
   */
  event WithdrawApproval(address indexed owner, address operator, address receiver, uint256 amount);

  /**
   * @dev Emitted when `debtAsset` borrow allowance is set.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param amount of allowance given
   */
  event BorrowApproval(address indexed owner, address operator, address receiver, uint256 amount);

  /// @dev Based on {IERC20Permit-DOMAIN_SEPARATOR}.
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external returns (bytes32);

  /**
   * @notice Returns the current amount of withdraw allowance from `owner` to `receiver` that
   * can be executed by `operator`. This is similar to {IERC20-allowance} for BaseVault assets,
   * instead of token-shares.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   *
   * @dev Requirements:
   * - Must replace {IERC4626-allowance} in a vault implementation.
   */
  function withdrawAllowance(
    address owner,
    address operator,
    address receiver
  )
    external
    view
    returns (uint256);

  /**
   * @notice Returns the current amount of borrow allowance from `owner` to `receiver` that
   * can be executed by `operator`. This is similar to {IERC20-allowance} for
   * BaseVault-debtAsset.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   */
  function borrowAllowance(
    address owner,
    address operator,
    address receiver
  )
    external
    view
    returns (uint256);

  /**
   * @dev Atomically increases the `withdrawAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-increaseAllowance} for assets.
   *
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param byAmount to increase withdraw allowance
   *
   * @dev Requirements:
   * - Must emit a {WithdrawApproval} event indicating the updated withdraw allowance.
   * - Must check `operator` and `receiver are not zero address.
   */
  function increaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically decreases the `withdrawAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-decreaseAllowance} for assets.
   *
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param byAmount to decrease withdraw allowance
   *
   * @dev Requirements:
   * - Must emit a {WithdrawApproval} event indicating the updated withdraw allowance.
   * - Must check `operator` and `receiver` are not zero address.
   * - Must check `operator` and `receiver` have `borrowAllowance` of at least `byAmount`.
   *
   */
  function decreaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically increases the `borrowAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-increaseAllowance}
   * for `debtAsset`.
   *
   * @param operator address who can execute the use of the allowance
   * @param receiver address who can spend the allowance
   * @param byAmount to increase borrow allowance
   *
   * @dev Requirements:
   * - Must emit a {BorrowApproval} event indicating the updated borrow allowance.
   * - Must check `operator` and `receiver` are not zero address.
   */
  function increaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically decrease the `borrowAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-decreaseAllowance}
   * for `debtAsset`.
   *
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param byAmount to decrease borrow allowance
   *
   * Requirements:
   * - Must emit a {BorrowApproval} event indicating the updated borrow allowance.
   * - Must check `operator` and `receiver` are not the zero address.
   * - Must check `operator` and `receiver` have `borrowAllowance` of at least `byAmount`.
   */
  function decreaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @notice Returns the curent used nonces for permits of `owner`.
   * Based on OZ {IERC20Permit-nonces}.
   *
   * @param owner address to check nonces
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @notice Sets `amount` as the `withdrawAllowance` of `receiver` executable by
   * caller over `owner`'s tokens, given the `owner`'s signed approval.
   * Inspired by {IERC20Permit-permit} for assets.
   *
   * @param owner providing allowance
   * @param receiver who can spend the allowance
   * @param amount of allowance
   * @param deadline timestamp limit for the execution of signed permit
   * @param v signature value
   * @param r signature value
   * @param s signature value
   *
   * @dev Requirements:
   * - Must check `deadline` is a timestamp in the future.
   * - Must check `receiver` is a non-zero address.
   * - Must check that `v`, `r` and `s` are valid `secp256k1` signature for `owner`
   *   over EIP712-formatted function arguments.
   * - Must check the signature used `owner`'s current nonce (see {nonces}).
   * - Must emits an {AssetsApproval} event.
   */
  function permitWithdraw(
    address owner,
    address receiver,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;

  /**
   * @notice Sets `amount` as the `borrowAllowance` of `receiver` executable by caller over
   * `owner`'s borrowing powwer, given the `owner`'s signed approval.
   * Inspired by {IERC20Permit-permit} for debt.
   *
   * @param owner address providing allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   * @param deadline timestamp limit for the execution of signed permit
   * @param v signature value
   * @param r signature value
   * @param s signature value
   *
   * @dev Requirements:
   * - Must emit a {BorrowApproval} event.
   * - Must be implemented in a {BorrowingVault}.
   * - Must check `deadline` is a timestamp in the future.
   * - Must check `receiver` is a non-zero address.
   * - Must check that `v`, `r` and `s` are valid `secp256k1` signature for `owner`.
   *   over EIP712-formatted function arguments.
   * - Must check the signature used `owner`'s current nonce (see {nonces}).
   */
  function permitBorrow(
    address owner,
    address receiver,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title VaultPermissions
 *
 * @author Fujidao Labs
 *
 * @notice An abstract contract intended to be inherited by tokenized vaults, that
 * allow users to modify allowance of a withdraw and/or borrow amount by signing a
 * structured data {EIP712} message.
 * This implementation is inspired by EIP2612 used for `ERC20-permit()`.
 * The use of `permitBorrow()` and `permitWithdraw()` allows for third party contracts
 * or "operators" to perform actions on behalf users across chains.
 */

import {IVaultPermissions} from "../interfaces/IVaultPermissions.sol";
import {EIP712} from "../abstracts/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";

contract VaultPermissions is IVaultPermissions, EIP712 {
  using Counters for Counters.Counter;

  /// @dev Custom Errors
  error VaultPermissions__zeroAddress();
  error VaultPermissions__expiredDeadline();
  error VaultPermissions__invalidSignature();
  error VaultPermissions__insufficientWithdrawAllowance();
  error VaultPermissions__insufficientBorrowAllowance();
  error VaultPermissions__allowanceBelowZero();

  /// @dev Allowance mapping structure: owner => operator => receiver => amount.
  mapping(address => mapping(address => mapping(address => uint256))) internal _withdrawAllowance;
  mapping(address => mapping(address => mapping(address => uint256))) internal _borrowAllowance;

  mapping(address => Counters.Counter) private _nonces;

  // solhint-disable-next-line var-name-mixedcase
  bytes32 private constant PERMIT_WITHDRAW_TYPEHASH = keccak256(
    "PermitWithdraw(uint256 destChainId,address owner,address operator,address receiver,uint256 amount,uint256 nonce,uint256 deadline)"
  );
  // solhint-disable-next-line var-name-mixedcase
  bytes32 private constant PERMIT_BORROW_TYPEHASH = keccak256(
    "PermitBorrow(uint256 destChainId,address owner,address operator,address receiver,uint256 amount,uint256 nonce,uint256 deadline)"
  );

  /// @dev Reserve a slot as recommended in OZ {draft-ERC20Permit}.
  // solhint-disable-next-line var-name-mixedcase
  bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

  /**
   * @notice Constructor of a new {VaultPermissions}.
   *
   * @param name_ string used in {BaseVault}
   *
   * @dev Requirements:
   * - Must initialize using the same `name` parameter
   * - Must initialize the {EIP712} domain separator using the `name` parameter as used
   *   in {BaseVault}. and setting `version` to "1".
   */
  constructor(string memory name_) EIP712(name_, "1") {}

  /// @inheritdoc IVaultPermissions
  function withdrawAllowance(
    address owner,
    address operator,
    address receiver
  )
    public
    view
    override
    returns (uint256)
  {
    return _withdrawAllowance[owner][operator][receiver];
  }

  /// @inheritdoc IVaultPermissions
  function borrowAllowance(
    address owner,
    address operator,
    address receiver
  )
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _borrowAllowance[owner][operator][receiver];
  }

  /// @inheritdoc IVaultPermissions
  function increaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    override
    returns (bool)
  {
    address owner = msg.sender;
    _setWithdrawAllowance(
      owner, operator, receiver, _withdrawAllowance[owner][operator][receiver] + byAmount
    );
    return true;
  }

  /// @inheritdoc IVaultPermissions
  function decreaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    override
    returns (bool)
  {
    address owner = msg.sender;
    uint256 currentAllowance = _withdrawAllowance[owner][operator][receiver];
    if (byAmount > currentAllowance) {
      revert VaultPermissions__allowanceBelowZero();
    }
    unchecked {
      _setWithdrawAllowance(owner, operator, receiver, currentAllowance - byAmount);
    }
    return true;
  }

  /// @inheritdoc IVaultPermissions
  function increaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {
    address owner = msg.sender;
    _setBorrowAllowance(
      owner, operator, receiver, _borrowAllowance[owner][operator][receiver] + byAmount
    );
    return true;
  }

  /// @inheritdoc IVaultPermissions
  function decreaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {
    address owner = msg.sender;
    uint256 currentAllowance = _borrowAllowance[owner][operator][receiver];
    if (byAmount > currentAllowance) {
      revert VaultPermissions__allowanceBelowZero();
    }
    unchecked {
      _setBorrowAllowance(owner, operator, receiver, currentAllowance - byAmount);
    }
    return true;
  }

  /// @inheritdoc IVaultPermissions
  function nonces(address owner) public view override returns (uint256) {
    return _nonces[owner].current();
  }

  /// @inheritdoc IVaultPermissions
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    return _domainSeparatorV4();
  }

  /// @inheritdoc IVaultPermissions
  function permitWithdraw(
    address owner,
    address receiver,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
    override
  {
    _checkDeadline(deadline);
    address operator = msg.sender;
    bytes32 structHash = keccak256(
      abi.encode(
        PERMIT_WITHDRAW_TYPEHASH,
        block.chainid,
        owner,
        operator,
        receiver,
        amount,
        _useNonce(owner),
        deadline
      )
    );
    _checkSigner(structHash, owner, v, r, s);

    _setWithdrawAllowance(owner, operator, receiver, amount);
  }

  /// @inheritdoc IVaultPermissions
  function permitBorrow(
    address owner,
    address receiver,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
    virtual
    override
  {
    _checkDeadline(deadline);
    address operator = msg.sender;
    bytes32 structHash = keccak256(
      abi.encode(
        PERMIT_BORROW_TYPEHASH,
        block.chainid,
        owner,
        operator,
        receiver,
        amount,
        _useNonce(owner),
        deadline
      )
    );
    _checkSigner(structHash, owner, v, r, s);

    _setBorrowAllowance(owner, operator, receiver, amount);
  }

  /// Internal Functions

  /**
   * @dev Sets assets `amount` as the allowance of `operator` over the `owner`'s assets.
   * This internal function is equivalent to `approve`.
   * Requirements:
   * - Must only be used in `asset` withdrawal logic.
   * - Must check `owner` cannot be the zero address.
   * - Much check `operator` cannot be the zero address.
   * - Must emits an {WithdrawApproval} event.
   *
   * @param owner address who is providing `withdrawAllowance`
   * @param operator address who is allowed to operate the allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   *
   */
  function _setWithdrawAllowance(
    address owner,
    address operator,
    address receiver,
    uint256 amount
  )
    internal
  {
    if (owner == address(0) || operator == address(0) || receiver == address(0)) {
      revert VaultPermissions__zeroAddress();
    }
    _withdrawAllowance[owner][operator][receiver] = amount;
    emit WithdrawApproval(owner, operator, receiver, amount);
  }

  /**
   * @dev Sets `amount` as the borrow allowance of `operator` over the `owner`'s debt.
   * This internal function is equivalent to `approve` for debt.
   * Requirements:
   * - Must  only be used in `debtAsset` borrowing logic.
   * - Must check `owner` cannot be the zero address.
   * - Much check `operator` cannot be the zero address.
   * - Must emit an {BorrowApproval} event.
   *
   * @param owner address who is providing `borrowAllowance`
   * @param operator address who is allowed to operate the allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   *
   */
  function _setBorrowAllowance(
    address owner,
    address operator,
    address receiver,
    uint256 amount
  )
    internal
  {
    if (owner == address(0) || operator == address(0) || receiver == address(0)) {
      revert VaultPermissions__zeroAddress();
    }
    _borrowAllowance[owner][operator][receiver] = amount;
    emit BorrowApproval(owner, operator, receiver, amount);
  }

  /**
   * @dev Spends `withdrawAllowance`.
   * Based on OZ {ERC20-spendAllowance} for {BaseVault-assets}.
   *
   * @param owner address who is spending `withdrawAllowance`
   * @param operator address who is allowed to operate the allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   */
  function _spendWithdrawAllowance(
    address owner,
    address operator,
    address receiver,
    uint256 amount
  )
    internal
  {
    uint256 currentAllowance = withdrawAllowance(owner, operator, receiver);
    if (currentAllowance != type(uint256).max) {
      if (amount > currentAllowance) {
        revert VaultPermissions__insufficientWithdrawAllowance();
      }
      unchecked {
        _setWithdrawAllowance(owner, operator, receiver, currentAllowance - amount);
      }
    }
  }

  /**
   * @dev Spends 'borrowAllowance`.
   * Based on OZ {ERC20-spendAllowance} for assets.
   *
   * @param owner address who is spending `borrowAllowance`
   * @param operator address who is allowed to operate the allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   */
  function _spendBorrowAllowance(
    address owner,
    address operator,
    address receiver,
    uint256 amount
  )
    internal
    virtual
  {
    uint256 currentAllowance = _borrowAllowance[owner][operator][receiver];
    if (currentAllowance != type(uint256).max) {
      if (amount > currentAllowance) {
        revert VaultPermissions__insufficientBorrowAllowance();
      }
      unchecked {
        _setBorrowAllowance(owner, operator, receiver, currentAllowance - amount);
      }
    }
  }

  /**
   * @dev "Consume a nonce": return the current amount and increment.
   * _Available since v4.1._
   *
   * @param owner address who uses a permit
   */
  function _useNonce(address owner) internal returns (uint256 current) {
    Counters.Counter storage nonce = _nonces[owner];
    current = nonce.current();
    nonce.increment();
  }

  /**
   * @dev Reverts if block.timestamp is expired according to `deadline`.
   *
   * @param deadline timestamp to check
   */
  function _checkDeadline(uint256 deadline) private view {
    if (block.timestamp > deadline) {
      revert VaultPermissions__expiredDeadline();
    }
  }

  /**
   * @dev Reverts if `presumedOwner` is not signer of `structHash`.
   *
   * @param structHash of data
   * @param presumedOwner address to check
   * @param v signature value
   * @param r signautre value
   * @param s signature value
   */
  function _checkSigner(
    bytes32 structHash,
    address presumedOwner,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    internal
    view
  {
    bytes32 digest = _hashTypedDataV4(structHash);
    address signer = ECDSA.recover(digest, v, r, s);
    if (signer != presumedOwner) {
      revert VaultPermissions__invalidSignature();
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title BorrowingVault
 *
 * @author Fujidao Labs
 *
 * @notice Implementation vault that handles pooled collateralized debt positions.
 * User state is kept at vaults via token-shares compliant to ERC4626, including
 * extension for debt asset and their equivalent debtshares.
 * Debt shares are not transferable.
 * Slippage protected functions include `borrow()` and `payback()`,
 * thru an implementation similar to ERC5143.
 * Setter functions for maximum loan-to-value and liquidation ratio factors
 * are defined and controlled by timelock.
 * A primitive liquidation function is implemented along additional view
 * functions to determine user's health factor.
 */

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from
  "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {ILendingProvider} from "../../interfaces/ILendingProvider.sol";
import {IFujiOracle} from "../../interfaces/IFujiOracle.sol";
import {IFlasher} from "../../interfaces/IFlasher.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {BaseVault} from "../../abstracts/BaseVault.sol";
import {VaultPermissions} from "../VaultPermissions.sol";

contract BorrowingVault is BaseVault {
  using Math for uint256;

  /**
   * @dev Emitted when a user is liquidated.
   *
   * @param caller of liquidation
   * @param receiver of liquidation bonus
   * @param owner whose assets are being liquidated
   * @param collateralSold `owner`'s amount of collateral sold during liquidation
   * @param debtPaid `owner`'s amount of debt paid back during liquidation
   * @param price price of collateral at which liquidation was done
   * @param liquidationFactor what % of debt was liquidated
   */
  event Liquidate(
    address indexed caller,
    address indexed receiver,
    address indexed owner,
    uint256 collateralSold,
    uint256 debtPaid,
    uint256 price,
    uint256 liquidationFactor
  );

  /// @dev Custom errors
  error BorrowingVault__borrow_invalidInput();
  error BorrowingVault__borrow_moreThanAllowed();
  error BorrowingVault__payback_invalidInput();
  error BorrowingVault__payback_moreThanMax();
  error BorrowingVault__liquidate_invalidInput();
  error BorrowingVault__liquidate_positionHealthy();
  error BorrowingVault__rebalance_invalidProvider();
  error BorrowingVault__rebalance_invalidFlasher();
  error BorrowingVault__checkFee_excessFee();
  error BorrowingVault__borrow_slippageTooHigh();
  error BorrowingVault__payback_slippageTooHigh();
  error BorrowingVault__burnDebtShares_amountExceedsBalance();

  /*///////////////////
   Liquidation controls
  ////////////////////*/

  /// @notice Returns default liquidation close factor: 50% of debt.
  uint256 public constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 0.5e18;

  /// @notice Returns max liquidation close factor: 100% of debt.
  uint256 public constant MAX_LIQUIDATION_CLOSE_FACTOR = 1e18;

  /// @notice Returns health factor threshold at which max liquidation can occur.
  uint256 public constant FULL_LIQUIDATION_THRESHOLD = 95e16;

  /// @notice Returns the penalty factor at which collateral is sold during liquidation: 90% below oracle price.
  uint256 public constant LIQUIDATION_PENALTY = 0.9e18;

  IERC20Metadata internal _debtAsset;
  uint8 internal immutable _debtDecimals;

  uint256 public debtSharesSupply;

  mapping(address => uint256) internal _debtShares;
  mapping(address => mapping(address => uint256)) private _borrowAllowances;

  IFujiOracle public oracle;

  /**
   * @dev Factor See: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme
   */

  /// @notice Returns the factor defining the maximum loan-to-value a user can take in this vault.
  uint256 public maxLtv;

  /// @notice Returns the factor defining the loan-to-value at which a user can be liquidated.
  uint256 public liqRatio;

  /**
   * @notice Constructor of a new {BorrowingVault}.
   *
   * @param asset_ this vault will handle as main asset (collateral)
   * @param debtAsset_ this vault will handle as debt asset
   * @param oracle_ of {FujiOracle} implementation
   * @param chief_ that deploys and controls this vault
   * @param name_ string of the token-shares handled in this vault
   * @param symbol_ string of the token-shares handled in this vault
   * @param providers_ array that will initialize this vault
   *
   * @dev Requirements:
   * - Must be initialized with a set of providers.
   * - Must set first provider in `providers_` array as `activeProvider`.
   * - Must initialize `maxLTV` and `liqRatio` with a non-zero value.
   * - Must check `maxLTV` Must < `liqRatio`.
   * - Must check `debtAsset_` erc20-decimals and `_debtDecimals` of this vault are equal.
   */
  constructor(
    address asset_,
    address debtAsset_,
    address oracle_,
    address chief_,
    string memory name_,
    string memory symbol_,
    ILendingProvider[] memory providers_
  )
    BaseVault(asset_, chief_, name_, symbol_)
  {
    _debtAsset = IERC20Metadata(debtAsset_);
    _debtDecimals = IERC20Metadata(debtAsset_).decimals();

    oracle = IFujiOracle(oracle_);
    maxLtv = 75 * 1e16;
    liqRatio = 80 * 1e16;

    _setProviders(providers_);
    _setActiveProvider(providers_[0]);
  }

  receive() external payable {}

  /*///////////////////////////////
  /// Debt management overrides ///
  ///////////////////////////////*/

  /// @inheritdoc IVault
  function debtDecimals() public view override returns (uint8) {
    return _debtDecimals;
  }

  /// @inheritdoc IVault
  function debtAsset() public view override returns (address) {
    return address(_debtAsset);
  }

  /// @inheritdoc IVault
  function balanceOfDebt(address owner) public view override returns (uint256 debt) {
    return convertToDebt(_debtShares[owner]);
  }

  /// @inheritdoc IVault
  function balanceOfDebtShares(address owner) external view override returns (uint256 debtShares) {
    return _debtShares[owner];
  }

  /// @inheritdoc IVault
  function totalDebt() public view override returns (uint256) {
    return _checkProvidersBalance("getBorrowBalance");
  }

  /// @inheritdoc IVault
  function convertDebtToShares(uint256 debt) public view override returns (uint256 shares) {
    return _convertDebtToShares(debt, Math.Rounding.Down);
  }

  /// @inheritdoc IVault
  function convertToDebt(uint256 shares) public view override returns (uint256 debt) {
    return _convertToDebt(shares, Math.Rounding.Down);
  }

  /// @inheritdoc IVault
  function maxBorrow(address borrower) public view override returns (uint256) {
    return _computeMaxBorrow(borrower);
  }

  /**
   * @notice Slippage protected `borrow()` inspired by EIP5143.
   *
   * @param debt amount to borrow
   * @param receiver address to whom borrowed amount will be transferred
   * @param owner address who will incur the debt
   * @param maxDebtShares amount that Must be minted in this borrow call
   *
   * @dev Requirements:
   * - Must mint maximum `maxDebtShares` when calling `borrow()`.
   */
  function borrow(
    uint256 debt,
    address receiver,
    address owner,
    uint256 maxDebtShares
  )
    public
    returns (uint256)
  {
    uint256 receivedDebtShares = borrow(debt, receiver, owner);
    if (receivedDebtShares > maxDebtShares) {
      revert BorrowingVault__borrow_slippageTooHigh();
    }
    return receivedDebtShares;
  }

  /// @inheritdoc BaseVault
  function borrow(uint256 debt, address receiver, address owner) public override returns (uint256) {
    address caller = _msgSender();

    if (debt == 0 || receiver == address(0) || owner == address(0) || debt < minAmount) {
      revert BorrowingVault__borrow_invalidInput();
    }
    if (debt > maxBorrow(owner)) {
      revert BorrowingVault__borrow_moreThanAllowed();
    }

    if (caller != owner) {
      _spendBorrowAllowance(owner, caller, receiver, debt);
    }

    uint256 shares = convertDebtToShares(debt);
    _borrow(caller, receiver, owner, debt, shares);

    return shares;
  }

  /**
   * @notice Slippage protected `payback()` inspired by EIP5143.
   *
   * @param debt amount to payback
   * @param owner address whose debt will be reduced
   * @param minDebtShares amount that Must be burned in this payback call
   *
   * @dev Requirements:
   * - Must burn at least `minDebtShares` when calling `payback()`.
   */
  function payback(uint256 debt, address owner, uint256 minDebtShares) public returns (uint256) {
    uint256 burnedDebtShares = payback(debt, owner);
    if (burnedDebtShares < minDebtShares) {
      revert BorrowingVault__payback_slippageTooHigh();
    }
    return burnedDebtShares;
  }

  /// @inheritdoc BaseVault
  function payback(uint256 debt, address owner) public override returns (uint256) {
    if (debt == 0 || owner == address(0)) {
      revert BorrowingVault__payback_invalidInput();
    }

    if (debt > convertToDebt(_debtShares[owner])) {
      revert BorrowingVault__payback_moreThanMax();
    }

    uint256 shares = convertDebtToShares(debt);
    _payback(_msgSender(), owner, debt, shares);

    return shares;
  }

  /*///////////////////////
      Borrow allowances 
  ///////////////////////*/

  /// @inheritdoc BaseVault
  function borrowAllowance(
    address owner,
    address operator,
    address receiver
  )
    public
    view
    virtual
    override
    returns (uint256)
  {
    return VaultPermissions.borrowAllowance(owner, operator, receiver);
  }

  /// @inheritdoc BaseVault
  function increaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {
    return VaultPermissions.increaseBorrowAllowance(operator, receiver, byAmount);
  }

  /// @inheritdoc BaseVault
  function decreaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {
    return VaultPermissions.decreaseBorrowAllowance(operator, receiver, byAmount);
  }

  /// @inheritdoc BaseVault
  function permitBorrow(
    address owner,
    address receiver,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
    override
  {
    VaultPermissions.permitBorrow(owner, receiver, value, deadline, v, r, s);
  }

  /**
   * @dev Computes max borrow amount a user can take given their 'asset'
   * (collateral) balance and price.
   * Requirements:
   * - Must read price from {FujiOracle}.
   *
   * @param borrower to whom to check max borrow amount
   */
  function _computeMaxBorrow(address borrower) internal view returns (uint256 max) {
    uint256 price = oracle.getPriceOf(debtAsset(), asset(), _debtDecimals);
    uint256 assetShares = balanceOf(borrower);
    uint256 assets = convertToAssets(assetShares);
    uint256 debtShares = _debtShares[borrower];
    uint256 debt = convertToDebt(debtShares);

    uint256 baseUserMaxBorrow = ((assets * maxLtv * price) / (1e18 * 10 ** decimals()));
    max = baseUserMaxBorrow > debt ? baseUserMaxBorrow - debt : 0;
  }

  /// @inheritdoc BaseVault
  function _computeFreeAssets(address owner) internal view override returns (uint256 freeAssets) {
    uint256 debtShares = _debtShares[owner];

    // Handle no debt case.
    if (debtShares == 0) {
      freeAssets = convertToAssets(balanceOf(owner));
    } else {
      uint256 debt = convertToDebt(debtShares);
      uint256 price = oracle.getPriceOf(asset(), debtAsset(), decimals());
      uint256 lockedAssets = (debt * 1e18 * price) / (maxLtv * 10 ** _debtDecimals);

      if (lockedAssets == 0) {
        // Handle wei level amounts in where 'lockedAssets' < 1 wei.
        lockedAssets = 1;
      }

      uint256 assets = convertToAssets(balanceOf(owner));

      freeAssets = assets > lockedAssets ? assets - lockedAssets : 0;
    }
  }

  /**
   * @dev Conversion function from debt to `debtShares` with support for rounding direction.
   * Requirements:
   * - Must revert if debt > 0, debtSharesSupply > 0 and totalDebt = 0.
   *   (Corresponds to a case where you divide by zero.)
   * - Must return `debt` if `debtSharesSupply` == 0.
   *
   * @param debt amount to convert to `debtShares`
   * @param rounding direction of division remainder
   */
  function _convertDebtToShares(
    uint256 debt,
    Math.Rounding rounding
  )
    internal
    view
    returns (uint256 shares)
  {
    uint256 supply = debtSharesSupply;
    return (debt == 0 || supply == 0) ? debt : debt.mulDiv(supply, totalDebt(), rounding);
  }

  /**
   * @dev Conversion function from `debtShares` to debt with support for rounding direction.
   * Requirements:
   * - Must return zero if `debtSharesSupply` == 0.
   *
   * @param shares amount to convert to `debt`
   * @param rounding direction of division remainder
   */
  function _convertToDebt(
    uint256 shares,
    Math.Rounding rounding
  )
    internal
    view
    returns (uint256 assets)
  {
    uint256 supply = debtSharesSupply;
    return (supply == 0) ? shares : shares.mulDiv(totalDebt(), supply, rounding);
  }

  /**
   * @dev Perform borrow action at provdier. Borrow/mintDebtShares common workflow.
   * Requirements:
   * - Must call `activeProvider` in `_executeProviderAction()`.
   * - Must emit a Borrow event.
   *
   * @param caller or operator
   * @param receiver to whom borrowed amount is transferred
   * @param owner to whom `debtShares` get minted
   * @param assets amount of debt
   * @param shares amount of `debtShares`
   */
  function _borrow(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  )
    internal
    whenNotPaused(VaultActions.Borrow)
  {
    _mintDebtShares(owner, shares);

    address asset = debtAsset();
    _executeProviderAction(assets, "borrow", activeProvider);

    SafeERC20.safeTransfer(IERC20(asset), receiver, assets);

    emit Borrow(caller, receiver, owner, assets, shares);
  }

  /**
   * @dev Perform payback action at provider. Payback/burnDebtShares common workflow.
   * Requirements:
   * - Must call `activeProvider` in `_executeProviderAction()`.
   * - Must emit a Payback event.
   *
   * @param caller msg.sender
   * @param owner to whom `debtShares` will bet burned
   * @param assets amount of debt
   * @param shares amount of `debtShares`
   */
  function _payback(
    address caller,
    address owner,
    uint256 assets,
    uint256 shares
  )
    internal
    whenNotPaused(VaultActions.Payback)
  {
    address asset = debtAsset();
    SafeERC20.safeTransferFrom(IERC20(asset), caller, address(this), assets);

    _executeProviderAction(assets, "payback", activeProvider);

    _burnDebtShares(owner, shares);

    emit Payback(caller, owner, assets, shares);
  }

  /**
   * @dev Common workflow to update state and mint `debtShares`.
   *
   * @param owner to whom shares get minted
   * @param amount of shares
   */
  function _mintDebtShares(address owner, uint256 amount) internal {
    debtSharesSupply += amount;
    _debtShares[owner] += amount;
  }

  /**
   * @dev Common workflow to update state and burn `debtShares`.
   *
   * @param owner to whom shares get burned
   * @param amount of shares
   */
  function _burnDebtShares(address owner, uint256 amount) internal {
    uint256 balance = _debtShares[owner];
    if (balance < amount) {
      revert BorrowingVault__burnDebtShares_amountExceedsBalance();
    }
    unchecked {
      _debtShares[owner] = balance - amount;
    }
    debtSharesSupply -= amount;
  }

  /*/////////////////
      Rebalancing 
  /////////////////*/

  /// @inheritdoc IVault
  function rebalance(
    uint256 assets,
    uint256 debt,
    ILendingProvider from,
    ILendingProvider to,
    uint256 fee,
    bool setToAsActiveProvider
  )
    external
    hasRole(msg.sender, REBALANCER_ROLE)
    returns (bool)
  {
    if (!_isValidProvider(address(from)) || !_isValidProvider(address(to))) {
      revert BorrowingVault__rebalance_invalidProvider();
    }
    SafeERC20.safeTransferFrom(IERC20(debtAsset()), msg.sender, address(this), debt);
    _executeProviderAction(debt, "payback", from);
    _executeProviderAction(assets, "withdraw", from);

    _checkRebalanceFee(fee, debt);

    _executeProviderAction(assets, "deposit", to);
    _executeProviderAction(debt + fee, "borrow", to);
    SafeERC20.safeTransfer(IERC20(debtAsset()), msg.sender, debt + fee);

    if (setToAsActiveProvider) {
      _setActiveProvider(to);
    }

    emit VaultRebalance(assets, debt, address(from), address(to));
    return true;
  }

  /*////////////////////
       Liquidation  
  ////////////////////*/

  /// @inheritdoc IVault
  function getHealthFactor(address owner) public view returns (uint256 healthFactor) {
    uint256 debtShares = _debtShares[owner];
    uint256 debt = convertToDebt(debtShares);

    if (debt == 0) {
      healthFactor = type(uint256).max;
    } else {
      uint256 assetShares = balanceOf(owner);
      uint256 assets = convertToAssets(assetShares);
      uint256 price = oracle.getPriceOf(debtAsset(), asset(), _debtDecimals);

      healthFactor = (assets * liqRatio * price) / (debt * 10 ** decimals());
    }
  }

  /// @inheritdoc IVault
  function getLiquidationFactor(address owner) public view returns (uint256 liquidationFactor) {
    uint256 healthFactor = getHealthFactor(owner);

    if (healthFactor >= 1e18) {
      liquidationFactor = 0;
    } else if (FULL_LIQUIDATION_THRESHOLD < healthFactor) {
      liquidationFactor = DEFAULT_LIQUIDATION_CLOSE_FACTOR; // 50% of owner's debt
    } else {
      liquidationFactor = MAX_LIQUIDATION_CLOSE_FACTOR; // 100% of owner's debt
    }
  }

  /// @inheritdoc IVault
  function liquidate(
    address owner,
    address receiver
  )
    external
    hasRole(msg.sender, LIQUIDATOR_ROLE)
    returns (uint256 gainedShares)
  {
    if (receiver == address(0)) {
      revert BorrowingVault__liquidate_invalidInput();
    }

    address caller = _msgSender();

    uint256 liquidationFactor = getLiquidationFactor(owner);
    if (liquidationFactor == 0) {
      revert BorrowingVault__liquidate_positionHealthy();
    }

    // Compute debt amount that must be paid by liquidator.
    uint256 debt = convertToDebt(_debtShares[owner]);
    uint256 debtSharesToCover = Math.mulDiv(_debtShares[owner], liquidationFactor, 1e18);
    uint256 debtToCover = Math.mulDiv(debt, liquidationFactor, 1e18);

    // Compute `gainedShares` amount that the liquidator will receive.
    uint256 price = oracle.getPriceOf(debtAsset(), asset(), _debtDecimals);
    uint256 discountedPrice = Math.mulDiv(price, LIQUIDATION_PENALTY, 1e18);
    gainedShares = convertToShares(Math.mulDiv(debt, liquidationFactor, discountedPrice));

    _payback(caller, owner, debtToCover, debtSharesToCover);

    // Ensure liquidator receives no more shares than 'owner' owns.
    uint256 existingShares = balanceOf(owner);
    if (gainedShares > existingShares) {
      gainedShares = existingShares;
    }

    // Internal share adjusment between 'owner' and 'liquidator'.
    _burn(owner, gainedShares);
    _mint(receiver, gainedShares);

    emit Liquidate(caller, receiver, owner, gainedShares, debtToCover, price, liquidationFactor);
  }

  /*/////////////////////////
      Admin set functions 
  /////////////////////////*/

  /**
   * @notice Sets `newOracle` address as the {FujiOracle} for this vault.
   *
   * @param newOracle address
   *
   * @dev Requirements:
   * - Must not be address zero.
   * - Must emit a OracleChanged event.
   * - Must be called from a timelock.
   */
  function setOracle(IFujiOracle newOracle) external onlyTimelock {
    if (address(newOracle) == address(0)) {
      revert BaseVault__setter_invalidInput();
    }
    oracle = newOracle;
    emit OracleChanged(newOracle);
  }

  /**
   * @notice Sets the maximum loan-to-value factor of this vault.
   *
   * @param maxLtv_ factor to be set
   *
   *  @dev See factor
   * https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   * Restrictions:
   * - Must be called from a timelock.
   * - Must be at least 1% (1e16).
   */
  function setMaxLtv(uint256 maxLtv_) external onlyTimelock {
    if (maxLtv_ < 1e16) {
      revert BaseVault__setter_invalidInput();
    }
    maxLtv = maxLtv_;
    emit MaxLtvChanged(maxLtv);
  }

  /**
   * @notice Sets the Loan-To-Value liquidation threshold factor of this vault.
   *
   * @param liqRatio_ factor to be set
   *
   * @dev See factor
   * https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   * Restrictions:
   * - Must be greater than 'maxLTV', and non zero.
   * - Must be called from a timelock.
   */
  function setLiqRatio(uint256 liqRatio_) external onlyTimelock {
    if (liqRatio_ < maxLtv || liqRatio_ == 0) {
      revert BaseVault__setter_invalidInput();
    }
    liqRatio = liqRatio_;
    emit LiqRatioChanged(liqRatio);
  }

  /// @inheritdoc BaseVault
  function _setProviders(ILendingProvider[] memory providers) internal override {
    uint256 len = providers.length;
    for (uint256 i = 0; i < len;) {
      if (address(providers[i]) == address(0)) {
        revert BaseVault__setter_invalidInput();
      }
      IERC20(asset()).approve(
        providers[i].approvedOperator(asset(), asset(), debtAsset()), type(uint256).max
      );
      IERC20(debtAsset()).approve(
        providers[i].approvedOperator(debtAsset(), asset(), debtAsset()), type(uint256).max
      );
      unchecked {
        ++i;
      }
    }
    _providers = providers;

    emit ProvidersChanged(providers);
  }
}