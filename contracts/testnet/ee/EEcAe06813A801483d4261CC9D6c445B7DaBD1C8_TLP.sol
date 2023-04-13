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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../interfaces/ITLP.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IERC20BackwardsCompatible.sol";
import "../interfaces/IFeeTracker.sol";

contract TLP is ITLP, ERC20, Ownable, ReentrancyGuard {
    error PoolNotPublic();
    error PoolAlreadyPublic();
    error PoolAlreadyPrivate();
    error InsufficientUSDBalance(uint256 _amountUSDT, uint256 _balance);
    error InsufficientUSDAllowance(uint256 _amountUSDT, uint256 _allowance);
    error InsufficientTLPBalance(uint256 _amountTLP, uint256 _balance);
    error InsufficientTLPAllowance(uint256 _amountTLP, uint256 _allowance);
    error ZeroDepositAmount();
    error ZeroWithdrawalAmount();
    error OnlyHouse(address _caller);
    error AlreadyInitialized();
    error NotInitialized();
    error DepositFeeTooHigh();
    error WithdrawFeeTooHigh();
    error FeesRemoved();
    error FeesAlreadyAdded();

    IERC20BackwardsCompatible public immutable usdt;

    uint256 public depositFee = 100;
    uint256 public withdrawFee = 100;
    bool public feesRemoved;
    IFeeTracker public stkuFees;
    IFeeTracker public xtkuFees;

    mapping(address => uint256) public depositsByAccount;
    mapping(address => uint256) public withdrawalsByAccount;
    uint256 public deposits;
    uint256 public withdrawals;
    uint256 public inflow;
    uint256 public outflow;
    uint256 public depositFeesCollected;
    uint256 public withdrawalFeesCollected;

    address public house;

    event Deposit(
        address indexed _account,
        uint256 indexed _amountUSDT,
        uint256 indexed _timestamp,
        uint256 _amountTLP,
        uint256 _fee
    );
    event Withdrawal(
        address indexed _account,
        uint256 indexed _amountUSDT,
        uint256 indexed _timestamp,
        uint256 _amountTLP,
        uint256 _fee
    );
    event Win(
        address indexed _account,
        uint256 indexed _game,
        uint256 indexed _timestamp,
        bytes32 _requestId,
        uint256 _amount
    );
    event Loss(
        address indexed _account,
        uint256 indexed _game,
        uint256 indexed _timestamp,
        bytes32 _requestId,
        uint256 _amount
    );

    mapping(address => bool) public depositorWhitelist;
    bool public open;

    bool private initialized;

    modifier onlyHouse() {
        if (msg.sender != house) {
            revert OnlyHouse(msg.sender);
        }
        _;
    }

    constructor(address _USDT) ERC20("Taku LP", "TLP") {
        usdt = IERC20BackwardsCompatible(_USDT);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function initialize(
        address _house,
        address _stkuFees,
        address _xtkuFees
    ) external nonReentrant onlyOwner {
        if (initialized) {
            revert AlreadyInitialized();
        }
        house = _house;
        stkuFees = IFeeTracker(_stkuFees);
        xtkuFees = IFeeTracker(_xtkuFees);
        usdt.approve(_stkuFees, type(uint256).max);
        usdt.approve(_xtkuFees, type(uint256).max);
        initialized = true;
    }

    function deposit(uint256 _amountUSDT) external nonReentrant {
        if (!open && !depositorWhitelist[msg.sender]) {
            revert PoolNotPublic();
        }
        if (_amountUSDT == 0) {
            revert ZeroDepositAmount();
        }
        if (_amountUSDT > usdt.balanceOf(msg.sender)) {
            revert InsufficientUSDBalance(
                _amountUSDT,
                usdt.balanceOf(msg.sender)
            );
        }
        if (_amountUSDT > usdt.allowance(msg.sender, address(this))) {
            revert InsufficientUSDAllowance(
                _amountUSDT,
                usdt.balanceOf(msg.sender)
            );
        }

        uint256 _fee;
        if (depositFee > 0) {
            _fee = (_amountUSDT * depositFee) / 10000;
            usdt.transferFrom(msg.sender, address(this), _fee);
            _depositYield(0, _fee);
            _amountUSDT -= _fee;
            depositFeesCollected += _fee;
        }

        uint256 _supplyTLP = this.totalSupply();
        uint256 _amountTLP = _supplyTLP == 0
            ? _amountUSDT
            : (_amountUSDT * _supplyTLP) / usdt.balanceOf(address(this));

        _mint(msg.sender, _amountTLP);
        usdt.transferFrom(msg.sender, address(this), _amountUSDT);
        deposits += _amountUSDT;
        depositsByAccount[msg.sender] += _amountUSDT;
        emit Deposit(
            msg.sender,
            _amountUSDT,
            block.timestamp,
            _amountTLP,
            _fee
        );
    }

    function withdraw(uint256 _amountTLP) external nonReentrant {
        if (_amountTLP == 0) {
            revert ZeroWithdrawalAmount();
        }
        if (_amountTLP > this.balanceOf(msg.sender)) {
            revert InsufficientTLPBalance(
                _amountTLP,
                this.balanceOf(msg.sender)
            );
        }
        if (_amountTLP > this.allowance(msg.sender, address(this))) {
            revert InsufficientTLPAllowance(
                _amountTLP,
                this.balanceOf(msg.sender)
            );
        }

        uint256 _amountUSDT = (_amountTLP * usdt.balanceOf(address(this))) /
            this.totalSupply();

        uint256 _fee;
        if (withdrawFee > 0) {
            _fee = (_amountUSDT * withdrawFee) / 10000;
            _depositYield(1, _fee);
            _amountUSDT -= _fee;
            withdrawalFeesCollected += _fee;
        }

        _burn(msg.sender, _amountTLP);
        usdt.transfer(msg.sender, _amountUSDT);
        withdrawals += _amountUSDT;
        withdrawalsByAccount[msg.sender] += _amountUSDT;
        emit Withdrawal(
            msg.sender,
            _amountUSDT,
            block.timestamp,
            _amountTLP,
            _fee
        );
    }

    function _depositYield(uint256 _source, uint256 _fee) private {
        uint256 _fee80Pct = (_fee * 8000) / 10000;
        xtkuFees.depositYield(_source, _fee80Pct);
        stkuFees.depositYield(_source, _fee - _fee80Pct);
    }

    function payWin(
        address _account,
        uint256 _game,
        bytes32 _requestId,
        uint256 _amount
    ) external override nonReentrant onlyHouse {
        usdt.transfer(_account, _amount);
        outflow += _amount;
        emit Win(_account, _game, block.timestamp, _requestId, _amount);
    }

    function receiveLoss(
        address _account,
        uint256 _game,
        bytes32 _requestId,
        uint256 _amount
    ) external override nonReentrant onlyHouse {
        usdt.transferFrom(msg.sender, address(this), _amount);
        inflow += _amount;
        emit Loss(_account, _game, block.timestamp, _requestId, _amount);
    }

    function setDepositFee(
        uint256 _depositFee
    ) external nonReentrant onlyOwner {
        if (feesRemoved) {
            revert FeesRemoved();
        }
        if (_depositFee > 200) {
            revert DepositFeeTooHigh();
        }
        depositFee = _depositFee;
    }

    function setWithdrawFee(
        uint256 _withdrawFee
    ) external nonReentrant onlyOwner {
        if (feesRemoved) {
            revert FeesRemoved();
        }
        if (_withdrawFee > 200) {
            revert WithdrawFeeTooHigh();
        }
        withdrawFee = _withdrawFee;
    }

    function addFees(
        uint256 _depositFee,
        uint256 _withdrawFee
    ) external nonReentrant onlyOwner {
        if (!feesRemoved) {
            revert FeesAlreadyAdded();
        }
        depositFee = _depositFee;
        withdrawFee = _withdrawFee;
        feesRemoved = false;
    }

    function removeFees() external nonReentrant onlyOwner {
        if (feesRemoved) {
            revert FeesRemoved();
        }
        depositFee = 0;
        withdrawFee = 0;
        feesRemoved = true;
    }

    function setDepositorWhitelist(
        address _depositor,
        bool _isWhitelisted
    ) external nonReentrant onlyOwner {
        depositorWhitelist[_depositor] = _isWhitelisted;
    }

    function goPublic() external nonReentrant onlyOwner {
        if (open) {
            revert PoolAlreadyPublic();
        }
        open = true;
    }

    function goPrivate() external nonReentrant onlyOwner {
        if (!open) {
            revert PoolAlreadyPrivate();
        }
        open = false;
    }

    function getTLPFromUSDT(
        uint256 _amountUSDT
    ) external view returns (uint256) {
        uint256 _supplyTLP = this.totalSupply();
        return
            _supplyTLP == 0
                ? _amountUSDT
                : (_amountUSDT * _supplyTLP) / usdt.balanceOf(address(this));
    }

    function getUSDTFromTLP(
        uint256 _amountTLP
    ) external view returns (uint256) {
        return
            (_amountTLP * usdt.balanceOf(address(this))) / this.totalSupply();
    }

    function getDepositsByAccount(
        address _account
    ) external view returns (uint256) {
        return depositsByAccount[_account];
    }

    function getWithdrawalsByAccount(
        address _account
    ) external view returns (uint256) {
        return withdrawalsByAccount[_account];
    }

    function getDeposits() external view returns (uint256) {
        return deposits;
    }

    function getWithdrawals() external view returns (uint256) {
        return withdrawals;
    }

    function getInflow() external view returns (uint256) {
        return inflow;
    }

    function getOutflow() external view returns (uint256) {
        return outflow;
    }

    function getFees() external view returns (uint256, uint256) {
        return (depositFee, withdrawFee);
    }

    function getFeesCollected()
        external
        view
        returns (uint256, uint256, uint256)
    {
        return (
            depositFeesCollected + withdrawalFeesCollected,
            depositFeesCollected,
            withdrawalFeesCollected
        );
    }

    function getOpen() external view returns (bool) {
        return open;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BackwardsCompatible {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function transfer(address to, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function approve(address spender, uint256 amount) external;

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
    ) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IFeeTracker {
    function setShare(address shareholder, uint256 amount) external;

    function depositYield(uint256 _source, uint256 _fees) external;

    function addYieldSource(address _yieldSource) external;

    function withdrawYield() external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface ITLP {
    function payWin(
        address _account,
        uint256 _game,
        bytes32 _requestId,
        uint256 _amount
    ) external;

    function receiveLoss(
        address _account,
        uint256 _game,
        bytes32 _requestId,
        uint256 _amount
    ) external;
}