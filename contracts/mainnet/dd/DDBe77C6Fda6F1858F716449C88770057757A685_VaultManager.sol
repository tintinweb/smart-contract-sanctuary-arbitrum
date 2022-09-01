// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IVaultAdapter } from "./interfaces/IVaultAdapter.sol";
import { IERC20TokenReceiver } from "./interfaces/IERC20TokenReceiver.sol";

import { PausableAccessControl } from "./utils/PausableAccessControl.sol";
import { TokenUtils } from "./utils/TokenUtils.sol";
import "./utils/Errors.sol";

contract VaultManager is PausableAccessControl, ReentrancyGuard {
	/// @notice A structure to store the informations related to a vault.
	struct Vault {
		/// @notice The address of the vault adapter.
		address adapter;
		/// @notice The total amount deposited into the vault.
		uint256 totalDeposited;
	}

	/// @notice The identifier of the role that sends funds and execute the onERC20Received callback
	bytes32 public constant SOURCE_ROLE = keccak256("SOURCE");

	/// @notice Gets the address of the underlying token managed by the vault manager.
	address public immutable vaultToken;

	/// @notice Gets the address of the reward token managed by the vault manager.
	address public immutable rewardToken;

	/// @notice Gets the address of the contract that receives the harvested rewards.
	address public harvester;

	/// @notice Gets the required amount of tokens deposited before they are automatically flushed into the active vault.
	uint256 public flushThreshold;

	/// @notice Gets the number of vaults in the vault list.
	uint256 public vaultCount;

	/// @notice Associates a unique number with a vault.
	mapping(uint256 => Vault) private _vaults;

	constructor(
		address _vaultToken,
		address _rewardToken,
		address _harvester
	) {
		vaultToken = _vaultToken;
		rewardToken = _rewardToken;
		harvester = _harvester;
	}

	/// @notice Sets the address of the active vault adapter.
	///
	/// @notice Reverts with an {OnlyAdminAllowed} error if the caller is missing the admin role.
	/// @notice Reverts with an {UnsupportedVaultToken} error if the adapter underlying token differs from vault manager underlying token.
	///
	/// @notice Emits a {ActiveVaultUpdated} event.
	///
	/// @param _vaultAdapter the adapter for the vault the system will migrate to.
	function setActiveVault(address _vaultAdapter) external {
		_onlyAdmin();

		// Checks if vault supports the underlying token
		if (IVaultAdapter(_vaultAdapter).token() != vaultToken) {
			revert UnsupportedVaultToken();
		}

		uint256 _vaultCount = vaultCount;
		_vaults[_vaultCount] = Vault({ adapter: _vaultAdapter, totalDeposited: 0 });
		vaultCount = _vaultCount + 1;

		emit ActiveVaultUpdated(_vaultAdapter);
	}

	/// @notice Sets the harvester.
	///
	/// @notice Reverts with an {OnlyAdminAllowed} error if the caller is missing the admin role.
	/// @notice Reverts with an {ZeroAddress} error if the harvester is the 0 address.
	///
	/// @notice Emits a {HarvesterUpdated} event.
	///
	/// @param _harvester the address of the harvester that receives the rewards.
	function setHarvester(address _harvester) external {
		_onlyAdmin();
		if (_harvester == address(0)) {
			revert ZeroAddress();
		}

		harvester = _harvester;

		emit HarvesterUpdated(_harvester);
	}

	/// @notice Sets the flush threshold.
	///
	/// @notice Reverts with an {OnlyAdminAllowed} error if the caller is missing the admin role.
	///
	/// @notice Emits a {FlushThresholdUpdated} event.
	///
	/// @param _flushThreshold the new flushThreshold.
	function setFlushThreshold(uint256 _flushThreshold) external {
		_onlyAdmin();

		flushThreshold = _flushThreshold;

		emit FlushThresholdUpdated(_flushThreshold);
	}

	/// @notice Deposits underlying tokens into the vault.
	///
	/// @notice Reverts with an {ContractPaused} error if the contract is in pause state.
	///
	/// @notice Emits a {TokensDeposited} event.
	///
	/// @param _amount The amount of underlying tokens to deposit.
	function deposit(uint256 _amount) external nonReentrant {
		_onlySource();
		_checkNotPaused();

		if (_amount == 0) {
			revert ZeroValue();
		}

		uint256 _underlyingReserve = TokenUtils.safeBalanceOf(vaultToken, address(this));
		if (_underlyingReserve > flushThreshold) {
			_depositToVault(vaultCount - 1, _underlyingReserve);
		}

		emit TokensDeposited(msg.sender, _amount);
	}

	/// @notice Withdraws `_amount` of underlying tokens and send them to `_recipient`.
	///
	/// @notice Emits a {TokensWithdrawn} event.
	///
	/// @param _recipient The address of the recipient of the funds.
	/// @param _amount The amount of tokens to withdraw.
	function withdraw(address _recipient, uint256 _amount) external nonReentrant {
		_onlySource();
		if (_recipient == address(0)) {
			revert ZeroAddress();
		}
		if (_amount == 0) {
			revert ZeroValue();
		}

		uint256 _underlyingReserve = TokenUtils.safeBalanceOf(vaultToken, address(this));

		uint256 _amountLeftToWithdraw = _amount;
		if (_amount > _underlyingReserve) {
			uint256 _missingReserveAmount = _amount - _underlyingReserve;
			_amountLeftToWithdraw = _underlyingReserve;
			_withdrawFromVault(vaultCount - 1, _recipient, _missingReserveAmount);
		}
		if (_amountLeftToWithdraw > 0) {
			TokenUtils.safeTransfer(vaultToken, _recipient, _amountLeftToWithdraw);
		}
		emit TokensWithdrawn(_recipient, _amount);
	}

	/// @notice Harvests yield from a vault and transfer the harvested amount to the harvester.
	///
	/// @notice Reverts with an {OutOfBoundsArgument} error if the vault id argument is out of bounds.
	/// @notice Reverts with an {NothingHarvested} error if the harvested amount is 0.
	///
	/// @notice Emits a {FundsHarvested} event.
	///
	/// @param _vaultId The identifier of the vault to harvest from.
	///
	/// @return The amount of tokens harvested.
	function harvest(uint256 _vaultId) external nonReentrant returns (uint256) {
		if (_vaultId >= vaultCount) {
			revert OutOfBoundsArgument();
		}

		address _adapter = _vaults[_vaultId].adapter;
		IVaultAdapter(_adapter).harvest(address(this));

		uint256 _harvestedAmount = TokenUtils.safeBalanceOf(rewardToken, address(this));
		if (_harvestedAmount == 0) {
			revert NothingHarvested();
		}

		_distributeToHarvester(_harvestedAmount);

		emit FundsHarvested(_harvestedAmount);

		return _harvestedAmount;
	}

	/// @notice Flushes all funds from the contract into the active vault.
	///
	/// @notice Reverts with an {ContractPaused} error if the contract is in pause state.
	///
	/// @notice Emits a {FundsFlushed} event.
	///
	/// @notice Reverts if the contract is in pause state.
	function flush() external nonReentrant {
		_checkNotPaused();

		uint256 _underlyingReserve = TokenUtils.safeBalanceOf(vaultToken, address(this));
		if (_underlyingReserve == 0) {
			revert NothingFlushed();
		}
		_depositToVault(vaultCount - 1, _underlyingReserve);
	}

	/// @notice Recalls an amount of deposited funds from a vault to this contract.
	///
	/// @notice Reverts with an {Unauthorized} error if all the following conditions are true:
	/// @notice - Contract is not in pause state.
	/// @notice - Caller is missing the admin role.
	/// @notice - `_vaultId` is the id of the active vault.
	/// @notice Reverts with an {OutOfBoundsArgument} error if the vault id argument is out of bounds.
	///
	/// @notice Emits a {FundsRecalled} event.
	///
	/// @param _vaultId The identifier of the vault funds are recalled from.
	/// @param _amount The amount of tokens recalled from the vault.
	function recall(uint256 _vaultId, uint256 _amount) external nonReentrant {
		_recall(_vaultId, _amount);
	}

	/// @notice Recalls all the deposited funds from a vault to this contract.
	function recallAll(uint256 _vaultId) external nonReentrant returns (uint256) {
		uint256 _totalDeposited = _vaults[_vaultId].totalDeposited;
		_recall(_vaultId, _totalDeposited);
		return _totalDeposited;
	}

	/// @notice Gets the address of the adapter and the total amount deposited for the vault number  `_vaultId`.
	///
	/// @param _vaultId the identifier of the vault to query.
	///
	/// @return The address of the vault adapter.
	/// @return The total amount of deposited tokens.
	function vault(uint256 _vaultId) external view returns (address, uint256) {
		Vault storage _vault = _vaults[_vaultId];
		return (_vault.adapter, _vault.totalDeposited);
	}

	/// @notice Recalls an amount of funds from a vault.
	///
	/// @param _vaultId The identifier of the vault to recall funds from.
	/// @param _amount  The amount of funds to recall from the vault.
	function _recall(uint256 _vaultId, uint256 _amount) internal {
		if (!paused && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && _vaultId == vaultCount - 1) {
			revert Unauthorized();
		}
		if (_vaultId >= vaultCount) {
			revert OutOfBoundsArgument();
		}
		if (_amount == 0) {
			revert NothingRecalled();
		}

		_withdrawFromVault(_vaultId, address(this), _amount);

		emit FundsRecalled(_vaultId, _amount);
	}

	function _distributeToHarvester(uint256 _amount) internal {
		address _harvester = harvester;
		TokenUtils.safeTransfer(rewardToken, _harvester, _amount);
		IERC20TokenReceiver(_harvester).onERC20Received(rewardToken, _amount);
	}

	/// @notice Pulls `_amount ` of tokens from vault `_vaultId`.
	///
	/// @param _vaultId The id of the vault to withdraw funds from.
	/// @param _recipient The beneficiary of the withdrawn funds.
	/// @param _amount The amount of funds to withdraw.
	function _withdrawFromVault(
		uint256 _vaultId,
		address _recipient,
		uint256 _amount
	) internal {
		// Decreases vault deposit
		Vault storage _vault = _vaults[_vaultId];
		_vault.totalDeposited -= _amount;
		// Withdraws from vault to reserve
		IVaultAdapter(_vault.adapter).withdraw(_recipient, _amount);
	}

	/// @notice Flushes `_amount ` of tokens to vault `_vaultId`.
	///
	/// @param _vaultId The id of the vault to deposit funds to.
	/// @param _amount The amount of funds to deposit.
	function _depositToVault(uint256 _vaultId, uint256 _amount) internal {
		// Increases vault deposit
		Vault storage _vault = _vaults[_vaultId];
		_vault.totalDeposited += _amount;
		// Deposits from reserve to vault
		address _adapter = _vault.adapter;
		TokenUtils.safeTransfer(vaultToken, _adapter, _amount);
		IVaultAdapter(_adapter).deposit(_amount);

		emit FundsFlushed(_amount);
	}

	/// @notice Check that the caller has the source role.
	function _onlySource() internal view {
		if (!hasRole(SOURCE_ROLE, msg.sender)) {
			revert OnlySourceAllowed();
		}
	}

	/// @notice Emitted when `amount` of underlying tokens are deposited into the vault and an equivalent amount of vault token is minted.
	///
	/// @param recipient The address of the account that receives the newly minted tokens.
	/// @param amount The amount of tokens deposited.
	event TokensDeposited(address recipient, uint256 amount);

	/// @notice Emitted when `amount` of tokens are burned and an equivalent amount of underlying tokens are transferred to `recipient`.
	///
	/// @param recipient The address of the beneficiary that receives the funds withdrawn.
	/// @param amount The amount of token burnt.
	event TokensWithdrawn(address recipient, uint256 amount);

	/// @notice Emitted when the active vault is updated.
	///
	/// @param adapter The address of the adapter.
	event ActiveVaultUpdated(address adapter);

	/// @notice Emitted when the harvester is updated.
	///
	/// @param harvester The address of the harvester.
	event HarvesterUpdated(address harvester);

	/// @notice Emitted when funds are harvested from the vault.
	///
	/// @param harvestedAmount The amount of funds harvested from the vault.
	event FundsHarvested(uint256 harvestedAmount);

	/// @notice Emitted when funds are recalled from an underlying vault.
	///
	/// @param vaultId The id of the vault.
	/// @param amount The amount of funds withdrawn from the vault.
	event FundsRecalled(uint256 indexed vaultId, uint256 amount);

	/// @notice Emitted when funds are flushed into the active vault.
	///
	/// @param flushedAmount The amount of funds flushed into the active vault.
	event FundsFlushed(uint256 flushedAmount);

	/// @notice Emitted when flush activator is updated.
	///
	/// @param flushThreshold The amount of tokens received before funds are automatically flush into the last vault.
	event FlushThresholdUpdated(uint256 flushThreshold);

	/// @notice Indicates that the vault token is not supported.
	error UnsupportedVaultToken();

	/// @notice Indicates that a flush operation fails because there is nothing to flush.
	error NothingFlushed();

	/// @notice Indicates that a recall operation fails because there is nothing to recall.
	error NothingRecalled();

	/// @notice Indicates that an harvest operation fails because there is nothing to harvest.
	error NothingHarvested();

	/// @notice Indicates that the caller is missing the source role.
	error OnlySourceAllowed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title IVaultAdapter
/// @author Koala Money
interface IVaultAdapter {
	/// @notice Gets the token that the adapter accepts.
	function token() external view returns (address);

	/// @notice Deposits funds into the vault
	///
	/// @param _amount The amount of funds to deposit
	function deposit(uint256 _amount) external;

	/// @notice Withdraw `_amount` of tokens from the vaults and send the withdrawn tokens to `_recipient`.
	///
	/// @param _recipient The address of the recipient of the funds.
	/// @param _amount    The amount of funds to requested.
	function withdraw(address _recipient, uint256 _amount) external;

	/// @notice Harvests rewards and transfers them to `_recipient`.
	///
	/// @param _recipient The addres of the recipient of the harvested rewards.
	function harvest(address _recipient) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title IERC20TokenReceiver
/// @author Alchemix Finance
interface IERC20TokenReceiver {
	/// @notice Informs implementors of this interface that an ERC20 token has been transferred.
	///
	/// @param token The token that was transferred.
	/// @param value The amount of the token that was transferred.
	function onERC20Received(address token, uint256 value) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { AdminAccessControl } from "./AdminAccessControl.sol";

/// @title  PausableAccessControl
/// @author Koala Money
///
/// @notice An admin access control with sentinel role and pausable state.
contract PausableAccessControl is AdminAccessControl {
	/// @notice The identifier of the role which can pause/unpause contract
	bytes32 public constant SENTINEL_ROLE = keccak256("SENTINEL");

	/// @notice Check if the token is paused.
	bool public paused;

	/// @notice Emitted when the contract enters the pause state.
	event Pause();

	/// @notice Emitted when the contract enters the unpause state.
	event Unpause();

	/// @notice Indicates that the caller is missing the sentinel role.
	error OnlySentinelAllowed();

	/// @notice Indicates that the contract is in pause state.
	error ContractPaused();

	/// @notice indicates that the contract is not in pause state.
	error ContractNotPaused();

	/// @notice Sets the contract in the pause state.
	///
	/// @notice Reverts if the caller does not have sentinel role.
	function pause() external {
		_onlySentinel();
		paused = true;
		emit Pause();
	}

	/// @notice Sets the contract in the unpause state.
	///
	/// @notice Reverts if the caller does not have sentinel role.
	function unpause() external {
		_onlySentinel();
		paused = false;
		emit Unpause();
	}

	/// @notice Checks that the contract is in the unpause state.
	function _checkNotPaused() internal view {
		if (paused) {
			revert ContractPaused();
		}
	}

	/// @notice Checks that the contract is in the pause state.
	function _checkPaused() internal view {
		if (!paused) {
			revert ContractNotPaused();
		}
	}

	/// @notice Checks that the caller has the sentinel role.
	function _onlySentinel() internal view {
		if (!hasRole(SENTINEL_ROLE, msg.sender)) {
			revert OnlySentinelAllowed();
		}
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "../interfaces/token/IERC20Burnable.sol";
import "../interfaces/token/IERC20Metadata.sol";
import "../interfaces/token/IERC20Minimal.sol";
import "../interfaces/token/IERC20Mintable.sol";

/// @title  TokenUtils
/// @author Alchemix Finance
library TokenUtils {
	/// @notice An error used to indicate that a call to an ERC20 contract failed.
	///
	/// @param target  The target address.
	/// @param success If the call to the token was a success.
	/// @param data    The resulting data from the call. This is error data when the call was not a success. Otherwise,
	///                this is malformed data when the call was a success.
	error ERC20CallFailed(address target, bool success, bytes data);

	/// @dev A safe function to get the decimals of an ERC20 token.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
	///
	/// @param token The target token.
	///
	/// @return The amount of decimals of the token.
	function expectDecimals(address token) internal view returns (uint8) {
		(bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20Metadata.decimals.selector));

		if (!success || data.length < 32) {
			revert ERC20CallFailed(token, success, data);
		}

		return abi.decode(data, (uint8));
	}

	/// @dev Gets the balance of tokens held by an account.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
	///
	/// @param token   The token to check the balance of.
	/// @param account The address of the token holder.
	///
	/// @return The balance of the tokens held by an account.
	function safeBalanceOf(address token, address account) internal view returns (uint256) {
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, account)
		);

		if (!success || data.length < 32) {
			revert ERC20CallFailed(token, success, data);
		}

		return abi.decode(data, (uint256));
	}

	/// @dev Gets the total supply of tokens.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
	///
	/// @param token   The token to check the total supply of.
	///
	/// @return The balance of the tokens held by an account.
	function safeTotalSupply(address token) internal view returns (uint256) {
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(IERC20Minimal.totalSupply.selector)
		);

		if (!success || data.length < 32) {
			revert ERC20CallFailed(token, success, data);
		}

		return abi.decode(data, (uint256));
	}

	/// @dev Transfers tokens to another address.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.
	///
	/// @param token     The token to transfer.
	/// @param recipient The address of the recipient.
	/// @param amount    The amount of tokens to transfer.
	function safeTransfer(
		address token,
		address recipient,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Minimal.transfer.selector, recipient, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Approves tokens for the smart contract.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.
	///
	/// @param token   The token to approve.
	/// @param spender The contract to spend the tokens.
	/// @param value   The amount of tokens to approve.
	function safeApprove(
		address token,
		address spender,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Minimal.approve.selector, spender, value)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Transfer tokens from one address to another address.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.
	///
	/// @param token     The token to transfer.
	/// @param owner     The address of the owner.
	/// @param recipient The address of the recipient.
	/// @param amount    The amount of tokens to transfer.
	function safeTransferFrom(
		address token,
		address owner,
		address recipient,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, owner, recipient, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Mints tokens to an address.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the mint fails or returns an unexpected value.
	///
	/// @param token     The token to mint.
	/// @param recipient The address of the recipient.
	/// @param amount    The amount of tokens to mint.
	function safeMint(
		address token,
		address recipient,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Mintable.mint.selector, recipient, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Burns tokens.
	///
	/// Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.
	///
	/// @param token  The token to burn.
	/// @param amount The amount of tokens to burn.
	function safeBurn(address token, uint256 amount) internal {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Burnable.burn.selector, amount));

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Burns tokens from its total supply.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.
	///
	/// @param token  The token to burn.
	/// @param owner  The owner of the tokens.
	/// @param amount The amount of tokens to burn.
	function safeBurnFrom(
		address token,
		address owner,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Burnable.burnFrom.selector, owner, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

/// @notice An error used to indicate that an action could not be completed because a zero address argument was passed to the function.
error ZeroAddress();

/// @notice An error used to indicate that an action could not be completed because a zero amount argument was passed to the function.
error ZeroValue();

/// @notice An error used to indicate that an action could not be completed because a function was called with an out of bounds argument.
error OutOfBoundsArgument();

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title  AdminAccessControl
/// @author Koala Money
///
/// @notice An access control with admin role granted to the contract deployer.
contract AdminAccessControl is AccessControl {
	/// @notice Indicates that the caller is missing the admin role.
	error OnlyAdminAllowed();

	constructor() {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function _onlyAdmin() internal view {
		if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
			revert OnlyAdminAllowed();
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IERC20Burnable {
	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title  IERC20Metadata
/// @author Alchemix Finance
interface IERC20Metadata {
	/// @notice Gets the name of the token.
	///
	/// @return The name.
	function name() external view returns (string memory);

	/// @notice Gets the symbol of the token.
	///
	/// @return The symbol.
	function symbol() external view returns (string memory);

	/// @notice Gets the number of decimals that the token has.
	///
	/// @return The number of decimals.
	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title  IERC20Minimal
/// @author Alchemix Finance
interface IERC20Minimal {
	/// @notice An event which is emitted when tokens are transferred between two parties.
	///
	/// @param owner     The owner of the tokens from which the tokens were transferred.
	/// @param recipient The recipient of the tokens to which the tokens were transferred.
	/// @param amount    The amount of tokens which were transferred.
	event Transfer(address indexed owner, address indexed recipient, uint256 amount);

	/// @notice An event which is emitted when an approval is made.
	///
	/// @param owner   The address which made the approval.
	/// @param spender The address which is allowed to transfer tokens on behalf of `owner`.
	/// @param amount  The amount of tokens that `spender` is allowed to transfer.
	event Approval(address indexed owner, address indexed spender, uint256 amount);

	/// @notice Gets the current total supply of tokens.
	///
	/// @return The total supply.
	function totalSupply() external view returns (uint256);

	/// @notice Gets the balance of tokens that an account holds.
	///
	/// @param account The account address.
	///
	/// @return The balance of the account.
	function balanceOf(address account) external view returns (uint256);

	/// @notice Gets the allowance that an owner has allotted for a spender.
	///
	/// @param owner   The owner address.
	/// @param spender The spender address.
	///
	/// @return The number of tokens that `spender` is allowed to transfer on behalf of `owner`.
	function allowance(address owner, address spender) external view returns (uint256);

	/// @notice Transfers `amount` tokens from `msg.sender` to `recipient`.
	///
	/// @notice Emits a {Transfer} event.
	///
	/// @param recipient The address which will receive the tokens.
	/// @param amount    The amount of tokens to transfer.
	///
	/// @return If the transfer was successful.
	function transfer(address recipient, uint256 amount) external returns (bool);

	/// @notice Approves `spender` to transfer `amount` tokens on behalf of `msg.sender`.
	///
	/// @notice Emits a {Approval} event.
	///
	/// @param spender The address which is allowed to transfer tokens on behalf of `msg.sender`.
	/// @param amount  The amount of tokens that `spender` is allowed to transfer.
	///
	/// @return If the approval was successful.
	function approve(address spender, uint256 amount) external returns (bool);

	/// @notice Transfers `amount` tokens from `owner` to `recipient` using an approval that `owner` gave to `msg.sender`.
	///
	/// @notice Emits a {Approval} event.
	/// @notice Emits a {Transfer} event.
	///
	/// @param owner     The address to transfer tokens from.
	/// @param recipient The address that will receive the tokens.
	/// @param amount    The amount of tokens to transfer.
	///
	/// @return If the transfer was successful.
	function transferFrom(
		address owner,
		address recipient,
		uint256 amount
	) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IERC20Mintable {
	function mint(address _recipient, uint256 _amount) external;

	function burnFrom(address account, uint256 amount) external;
}