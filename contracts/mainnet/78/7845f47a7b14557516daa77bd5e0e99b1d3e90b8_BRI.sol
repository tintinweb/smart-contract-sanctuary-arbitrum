// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "./LedgerOwner.sol";
import "./Errors.sol";
import "./BrightPoolWarden.sol";

contract BRI is ERC20, LedgerOwner {
    uint256 constant BRI_HARD_CAP = 5_000_000_000 gwei;

    uint256 constant MINIMUM_KILL_COOLDOWN = 24 hours;

    /**
     * @dev The event emitted on new oracle is set.
     *
     * @param oracle New oracle address set
     */
    event NewOracle(address indexed oracle);

    /**
     * @dev The event emitted on new tokens being minted.
     *
     * @param recipient The recipient of newly minted tokens
     * @param amount The amount of tokens being minted
     */
    event BridgedIn(address indexed recipient, uint256 amount);

    /**
     * @dev The event emitted on tokens being burnt.
     *
     * @param source The source account of tokens burnt
     * @param amount The amount of tokens being burnt
     */
    event BridgedOut(address indexed source, uint256 amount);

    /**
     * @dev The event emitted on new tokens being minted as rewards.
     *
     * @param recipient The recipient of newly minted tokens
     * @param amount The amount of tokens being minted
     */
    event Rewarded(address indexed recipient, uint256 amount);

    /**
     * @dev The event emitted on tokens being burnt on reward cancellation.
     *
     * @param source The source account of tokens burnt
     * @param amount The amount of tokens being burnt
     */
    event RewardCancelled(address indexed source, uint256 amount);

    /**
     * @dev The event emitted upon kill switch set
     *
     * @param deadline The deadline of killswitch set
     */
    event TransfersKilled(uint256 deadline);

    /**
     * @dev The oracle address that is allowed to mint and burn tokens as bridging between blockchains
     */
    address public oracle;

    /**
     * @dev The date the kill switch has been moved
     */
    uint256 killSwitch;

    /**
     * @dev The modifier restricting method to be run by oracle address only
     */
    modifier onlyOracle() {
        if (_msgSender() != oracle) revert Restricted();
        _;
    }

    /**
     * @dev Token constructor.
     *
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param owner_ The owner of the contract
     * @param admin_ The administrator of the contact (allowed to kill transfers)
     * @param oracle_ The oracle that is allowed to mint and burn tokens
     * @param initialMint_ The initial mint created by the owner - deployer
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        address admin_,
        address oracle_,
        uint256 initialMint_,
        BrightPoolWarden warden_
    ) ERC20(name_, symbol_) LedgerOwner(owner_, admin_, warden_) {
        if (oracle_ == address(0)) revert ZeroAddress();
        _mint(owner_, initialMint_);
        oracle = oracle_;
    }

    /**
     * @dev Complying to BEP-20 standard - delivering the address of token owner
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Sets decimal places for token to just 9 places instead of default 18
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     * @dev Method changing an oracle. Only contract owner can do that.
     *
     * The change of the oracle is possible only during BRI lock
     *
     * @param oracle_ New contract oracle. Might be address(0) to stop mint/burning mechanism.
     */
    function setOracle(address oracle_) external onlyAdminOrOwner {
        if (oracle_ == oracle) revert AlreadySet();

        // slither-disable-start reentrancy-events
        // slither-disable-next-line reentrancy-no-eth
        if (_getWarden().changeValue(oracle_, "oracle", msg.sender)) {
            oracle = oracle_;
            emit NewOracle(oracle_);
        }
        // slither-disable-end reentrancy-events
    }

    /**
     * @dev Method allowing the oracle to mint new tokens.
     *
     * @param recipient_ The recipient of the newly minted tokens.
     * @param amount_ The amount of tokens being minted.
     */
    function bridgeIn(address recipient_, uint256 amount_) external onlyOracle {
        if (totalSupply() + amount_ > BRI_HARD_CAP) revert CapExceeded();
        _mint(recipient_, amount_);
        emit BridgedIn(recipient_, amount_);
    }

    /**
     * @dev Method allowing the oracle to burn tokens.
     *
     * @param source_ The source of the tokens being burnt.
     * @param amount_ The amount of tokens being burnt.
     */
    function bridgeOut(address source_, uint256 amount_) external onlyOracle {
        _burn(source_, amount_);
        emit BridgedOut(source_, amount_);
    }

    /**
     * @dev Method allowing the ledger to mint new tokens.
     *
     * @param recipient_ The recipient of the newly minted tokens.
     * @param amount_ The amount of tokens being minted.
     */
    function reward(address recipient_, uint256 amount_) external onlyLedger {
        if (totalSupply() + amount_ > BRI_HARD_CAP) revert CapExceeded();
        _mint(recipient_, amount_);
        emit Rewarded(recipient_, amount_);
    }

    /**
     * @dev Method allowing the ledger to burn tokens.
     *
     * @param source_ The source of the tokens being burnt.
     * @param amount_ The amount of tokens being burnt.
     */
    function cancelReward(address source_, uint256 amount_) external onlyLedger {
        _burn(source_, amount_);
        emit RewardCancelled(source_, amount_);
    }

    /**
     * @dev Owners method to kill any transfers for token until given time (not more than 24h)
     *
     * @param deadlineInHours_ Amount of hours to kill the transfers for
     */
    function killTransfers(uint256 deadlineInHours_) external onlyAdmin {
        // slither-disable-next-line timestamp
        if (killSwitch >= block.timestamp) revert KillSwitch();
        // slither-disable-next-line timestamp
        if (killSwitch + MINIMUM_KILL_COOLDOWN >= block.timestamp) revert Restricted();
        // slither-disable-next-line timestamp
        if (deadlineInHours_ == 0 || deadlineInHours_ > 24) revert WrongDeadline();

        killSwitch = block.timestamp + deadlineInHours_ * (1 hours);

        emit TransfersKilled(killSwitch);
    }

    /**
     * @dev Transfer checker
     */
    function _beforeTokenTransfer(address, address, uint256) internal virtual override {
        // slither-disable-next-line timestamp
        if (killSwitch > block.timestamp) revert KillSwitch();
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./Ownable.sol";
import "./Errors.sol";
import "./IBrightPoolLedger.sol";
import "./BrightPoolWarden.sol";

/**
 * @dev An abstract class defining what ledger owner contracts has to have in common
 */
abstract contract LedgerOwner is Ownable {
    IBrightPoolLedger private _ledger;

    BrightPoolWarden private _warden;

    /**
     * @dev The admin address that is allowed to change cron and backend addresses
     */
    address private _admin;

    /**
     * @dev Event emitted upon ledger change commit
     */
    event NewLedger(address indexed ledger);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyLedger() {
        if (msg.sender != address(_ledger)) revert Restricted();
        _;
    }

    /**
     * @dev The modifier restricting method to be run by admin address only
     */
    modifier onlyAdmin() {
        if (_msgSender() != _admin) revert Restricted();
        _;
    }

    /**
     * @dev The modifier restricting method to be run by admin address only
     */
    modifier onlyAdminOrOwner() {
        if (_msgSender() != _admin && _msgSender() != owner()) revert Restricted();
        _;
    }

    constructor(address owner_, address admin_, BrightPoolWarden warden_) Ownable(owner_) {
        if (owner_ == address(0)) revert ZeroAddress();
        if (admin_ == address(0)) revert ZeroAddress();
        if (address(warden_) == address(0)) revert ZeroAddress();
        _warden = warden_;
        _admin = admin_;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function ledger() public view virtual returns (IBrightPoolLedger) {
        return _ledger;
    }

    /**
     * @dev Method changing an oracle. Only contract owner can do that.
     *
     * @param ledger_ New contract ledger. Might be address(0) to stop mint/burning mechanism.
     */
    function setLedger(IBrightPoolLedger ledger_) external virtual onlyAdminOrOwner {
        if (address(ledger_) == address(0)) revert ZeroAddress();
        // slither-disable-start reentrancy-no-eth
        // slither-disable-start reentrancy-events
        if (
            (address(_ledger) == address(0) && _warden.awaitingValue("ledger") == address(0))
                || _warden.changeValue(address(ledger_), "ledger", msg.sender)
        ) {
            _ledger = ledger_;
            emit NewLedger(address(ledger_));
        }
        // slither-disable-end reentrancy-events
        // slither-disable-end reentrancy-no-eth
    }

    function _setLedger(IBrightPoolLedger ledger_) internal {
        _ledger = ledger_;
    }

    function _getWarden() internal view returns (BrightPoolWarden) {
        return _warden;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/**
 * @dev Action restricted. Given account is not allowed to run it
 */
error Restricted();

/**
 * @dev Trying to set Zero Address to an attribute that cannot be 0
 */
error ZeroAddress();

/**
 * @dev Attribute already set and does not allow resetting
 */
error AlreadySet();

/**
 * @dev A cap has been exceeded - temporarily locked
 */
error CapExceeded();

/**
 * @dev A deadline has been wrongly set
 */
error WrongDeadline();

/**
 * @dev A kill switch is in play. Action restricted and temporarily frozen
 */
error KillSwitch();

/**
 * @dev A value cannot be zero
 */
error ZeroValue();

/**
 * @dev Value exceeded maximum allowed
 */
error TooBig();

/**
 * @dev Appointed item does not exist
 */
error NotExists();

/**
 * @dev Appointed item already exist
 */
error AlreadyExists();

/**
 * @dev Timed action has timed out
 */
error Timeout();

/**
 * @dev Insufficient funds to perform action
 */
error InsufficientFunds();

/**
 * @dev Wrong currency used
 */
error WrongCurrency();

/**
 * @dev Blocked action. For timing or other reasons
 */
error Blocked();

/**
 * @dev Suspended access
 */
error Suspended();

/**
 * @dev Nothing to claim
 */
error NothingToClaim();

/**
 * @dev Missing vesting tokens
 */
error MissingVestingTokens();

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./Errors.sol";

/**
 * @dev Warden contract to register and check values that should have been time locked.
 * All timelocks are set to 24 hours
 */
contract BrightPoolWarden {
    uint256 constant TIME_LOCK = 24 hours;

    /**
     * @dev Event emitted on change being scheduled
     */
    event ChangeScheduled(address indexed scheduler, string name, address value);
    /**
     * @dev Event emmitted on change being reverted
     */
    event ChangeReverted(address indexed scheduler, string name, address value);

    struct LockedValue {
        address value;
        address registrant;
        uint256 time;
    }

    mapping(address => mapping(string => LockedValue)) private _lockedValues;

    /**
     * @dev Method to set the change sequence for a registered value.
     *
     * @param to_ Address to change value to
     * @param name_ The name of the value that is a subject to change
     * @param registrant_ The address that is initialiting the call (or 0 address if this is irrelevant)
     *
     * @return True if value can be set immediately. False otherwise
     */
    function changeValue(address to_, string calldata name_, address registrant_) external returns (bool) {
        LockedValue storage lockedValue = _lockedValues[msg.sender][name_];
        if (to_ == lockedValue.value) {
            // slither-disable-next-line timestamp
            if (lockedValue.time < block.timestamp) {
                if (lockedValue.registrant != address(0) && lockedValue.registrant == registrant_) {
                    revert Restricted();
                }
                lockedValue.value = address(0);
                lockedValue.registrant = address(0);
                lockedValue.time = 0;
                return true;
            } else {
                revert Blocked();
            }
        } else {
            if (to_ == address(0)) {
                emit ChangeReverted(msg.sender, name_, lockedValue.value);
                lockedValue.value = address(0);
                lockedValue.registrant = address(0);
                lockedValue.time = 0;
            } else if (lockedValue.value != address(0)) {
                revert Blocked();
            } else {
                lockedValue.value = to_;
                lockedValue.registrant = registrant_;
                // slither-disable-next-line timestamp
                lockedValue.time = block.timestamp + TIME_LOCK;
                emit ChangeScheduled(msg.sender, name_, to_);
            }
        }
        return false;
    }

    /**
     * @dev The method to check currently awaiting value in the plan
     *
     * @param name_ The name of the value to be checked
     *
     * @return Value currently awaiting change
     */
    function awaitingValue(string calldata name_) external view returns (address) {
        return _lockedValues[msg.sender][name_].value;
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "openzeppelin-contracts/utils/Context.sol";
import "./Errors.sol";

abstract contract Ownable is Context {
    address private _owner;

    constructor(address owner_) {
        if (owner_ == address(0)) revert ZeroAddress();
        _owner = owner_;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != _owner) revert Restricted();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./Ownable.sol";
import "./IBrightPoolTreasury.sol";
import "./BrightPoolWarden.sol";

/**
 * @dev An abstract class defining what a BrightPoolLedger contract has to offer
 */
abstract contract IBrightPoolLedger is Ownable {
    /**
     * @dev Manager instance able to use ledgers functions
     */
    address public manager;

    /**
     * @dev The struct describing a single token amount and address for exchange purpose
     * One should use address(0) to point native blockchain asset.
     */
    struct Asset {
        IERC20 token;
        uint256 amount;
    }

    /**
     * @dev The struct describing a single order information
     */
    struct Order {
        uint256 id;
        Asset ask;
        Asset bid;
        address owner;
        uint256 reward;
        uint256 affId;
        address affRcpt;
    }

    /**
     * @dev The event emitted upon new order added to the ledger
     */
    event NewOrder(
        uint256 indexed id,
        IERC20 indexed askToken,
        IERC20 indexed bidToken,
        address owner,
        uint256 askAmount,
        uint256 bidAmount,
        uint256 reward
    );

    /**
     * @dev The event emitted upon order being cancelled from the ledger
     */
    event ExecutedOrder(uint256 indexed id);

    /**
     * @dev The event emitted upon order being cancelled from the ledger
     */
    event CancelledOrder(uint256 indexed id, uint256 reward);

    /**
     * @dev The event emitted upon new manager address being set for the ledger
     */
    event NewManager(address indexed manager);

    /**
     * @dev The event emitted when native currency is sent to the contract independently
     */
    event EthReceived(address indexed from, uint256 value);

    /**
     * @dev The event emitted when new exchange is added to exchange list
     */
    event NewExchange(address indexed exchange);

    /**
     * @dev The event emitted when the exchange is removed from the exchange list
     */
    event RemovedExchange(uint256 indexed exchangeIndex);

    /**
     * @dev Warden contract for manager changes
     */
    BrightPoolWarden private _warden;

    /**
     * @dev Modifier locking method from being run by third parties not being the manager of the contract
     */
    modifier onlyManager() {
        if (_msgSender() != manager) revert Restricted();
        _;
    }

    constructor(address owner_, BrightPoolWarden warden_) Ownable(owner_) {
        if (address(warden_) == address(0)) revert ZeroAddress();
        _warden = warden_;
    }

    /**
     * @dev Automatic retrieval of ETH funds
     */
    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    /**
     * @dev The method for setting new manager of the contract.
     * The method restricted to contract owner.
     *
     * @param manager_ The address of the manager of the contract.
     */
    function setManager(address manager_) external onlyOwner {
        if (address(0) == manager_) revert ZeroAddress();
        if (manager == manager_) revert AlreadySet();

        // slither-disable-start reentrancy-events
        // slither-disable-next-line reentrancy-no-eth
        if (_warden.changeValue(manager_, "manager", address(0))) {
            manager = manager_;
            emit NewManager(manager_);
        }
        // slither-disable-end reentrancy-events
    }

    function _getWarden() internal view returns (BrightPoolWarden) {
        return _warden;
    }

    /**
     * @dev The method to check the owner of created order
     *
     * @param id_ The order id to be checked for the owner
     *
     * @return The owner address
     */
    function ownerOf(uint256 id_) external view virtual returns (address);

    /**
     * @dev The method for making new order signed in the ledger.
     * The method restricted to contract manager only.
     *
     * @param order_ The order struct. It's id has to be unique and cannot be 0
     * @param timeout_ The deadline after which this order can be executed (timestamp)
     */
    function makeOrder(Order calldata order_, uint256 timeout_) external payable virtual;

    /**
     * @dev The method for order execution with success or failure (cancellation).
     * The method restricted to contracts manager only.
     *
     * @param id_ The id of the order to be cancelled.
     * @param revoked_ Is the order revoked or executed should be processed
     * @param rewardConsumed_ The amount of the reward consumed upon order cancellation from the sender
     * @param treasury_ The treasury address to use as potential exchange
     * @param treasuryCap_ The amount cap for treasury usage in this order
     *
     * @return True if executed or reverted successfully, false if order does not exist
     */
    function executeOrder(
        uint256 id_,
        bool revoked_,
        uint256 rewardConsumed_,
        IBrightPoolTreasury treasury_,
        uint256 treasuryCap_
    ) external virtual returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./IBrightPoolConsumer.sol";
import "./IBrightPoolExchangeable.sol";

/**
 * @dev An abstract class defining treasury methods
 */
interface IBrightPoolTreasury is IBrightPoolExchangeable, IBrightPoolConsumer {
    /**
     * @dev Method returns balance of given token or coin.
     *
     * @param token_ The token address to check balance of or 0 to check native coin balance
     *
     * @return The balance of requested token or coin
     */
    function balanceOf(IERC20 token_) external view returns (uint256);

    /**
     * @dev The method checking if given affiliate ID pays in BRI
     *
     * @param id_ The id of the affiliate program
     *
     * @return True if affiliate program pays in BRI, false otherwise
     */
    function isBRIAffiliate(uint256 id_) external view returns (bool);

    /**
     * @dev The method returning the amount of the reward for affiliate
     *
     * @param id_ The id of the affiliate
     * @param amount_ The amount of the original transaction
     *
     * @return The amount to be paid as a reward
     */
    function rewardForAffiliate(uint256 id_, uint256 amount_) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./IBrightPoolLedger.sol";

interface IBrightPoolConsumer {
    function consume(IBrightPoolLedger.Asset memory asset_, uint256 affId_, address affRcpt_) external payable;
}

pragma solidity 0.8.16;

import "./IBrightPoolConsumer.sol";
import "./IBrightPoolLedger.sol";

interface IBrightPoolExchangeable {
    function exchange(IBrightPoolConsumer consumer_, IBrightPoolLedger.Order memory order_, uint256 bestExchange_)
        external
        payable;
}