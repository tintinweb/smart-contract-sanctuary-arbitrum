// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.18;

import "./ILiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AbstractLiquidityPool.sol";

/**
 * @title A Liquidity Pool in the form of Physicall-Settled
 * @notice This pool implementation is purely token-based - no raw ETH
 * @notice It has a token of liquidity
 * @notice It has a settlement token which is a used by an option holder to pay for the liquidity token (physical settlement)
 * @notice Uses internal PoolToken (ERC20) to represents portions of the pool belonging to providers - this token has no trade value
 * @dev Pools are deployed and belongs to [Options] smart contracts
 */
contract ERCERCPhySettlPool is AbstractLiquidityPool {
    using SafeERC20 for ERC20;

    constructor(address _liquidityToken, address _settlementToken, address _poolToken)
         AbstractLiquidityPool(_liquidityToken, _settlementToken, _poolToken) {}

    //slither-disable-start reentrancy-benign
    function _provideLiquidity(uint256 quantity) override internal {
        // Despite payable, in this case contract can't receiver ether, use `ETH_ERC_PhySettlPool`instead
        // require(msg.value == 0, "this contract doesn't accept ether");
        liquidityToken.safeTransferFrom(msg.sender, address(this), quantity);
        lastProvideTimestamp[msg.sender] = block.timestamp;
        _raiseLiquiditySharesOf(msg.sender, quantity);
    }
    //slither-disable-end reentrancy-benign

    //slither-disable-start reentrancy-events
    function _withdrawLiquidity(
        address provider,
        uint256 quantity,
        uint256 balance,
        uint256 lockedBalance
    ) override internal {
        
        require(!_inLockupPeriod(provider), "Pool Error: Withdrawal is locked up");
        require(quantity <= _totalLiquidityBalance(), "Pool Error: Not enough free liquidity. Lower the amount.");
        require(lockedBalance + quantity <= balance, "Not enough unlocked tokens");
        
        _reduceLiquiditySharesOf(provider, quantity);
        liquidityToken.safeTransfer(provider, quantity);

        emit Withdraw(msg.sender, quantity, block.timestamp);
    }
    //slither-disable-end reentrancy-events
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title a common interface for Liquidity Pools
 */
interface ILiquidityPool{
    event Withdraw(address indexed account, uint256 quantity, uint256 timestamp);
    event Provide(address indexed account, uint256 quantity, uint256 timestamp);
    event SetLockupPeriod(uint value);
    event LiquidateFor(uint256 snapshotId, address indexed provider, uint256 reduceShares);
    event DisbursePremiumFor(uint256 snapshotId, address indexed provider, uint256 premiumShares);
    event RemoveActiveSnapshot(uint256 snapshotId);

    struct LiquidityProvidersRepartition {
        mapping(address => uint256) liquidityProviderAmount;
        address[] liquidityProvidersKeys; // address of liquidity providers for iteration
    }

    /**
     * @notice Liquidity Provider (LP) provides liquidity token to the pool
     * @notice LP gets in return a portion of shares of the pool, in tokenPool units
     * @notice liquidity token requires allowance from provider
     * @param quantity Provided tokens
     */
    function provideLiquidity(uint256 quantity) payable external;

    /**
     * @notice LP burns tokenPool and receive liquidity tokens
     * @param quantity quantity of liquidity tokens LP wants to withdraw
     * @dev for instance a LP may wants to withdraw N liquidity tokens, but doesn't want to lower more than X% of his participation (shares) in the pool
     * @dev Usually amount = maxBurn for convenience.
     */
    function withdrawLiquidity(uint256 quantity) external;

    /// @notice Withdraw all available liquidity (balance of account excludes locked liquidity in options)
    function withdrawAll() external;

    /**
     * @notice set lockup period
     * @notice lockup period defines how long the liquidity token can or can't be withdrawn
     */
    function setLockupPeriod(uint value) external;

    /**
     * @notice Returns the amount of liquidity tokens not locked, and thus available for withdrawals
     */
    function availableLiquidity() external view returns (uint256 balance);

    /**
     * @notice get the allowance of the liquidity token given by owner for the caller
     * @param owner the token holder
     * @param spender the token spender
     */
    // function liquidityTokenAllowance(address owner, address spender) external view returns (uint256 allowance);

    /**
     * @notice get the allowance of the settlement token given by owner for the caller
     * @param owner the token holder
     * @param spender the token spender
     */
    // function settlementTokenAllowance(address owner, address spender) external view returns (uint256 allowance);

    /**
     * @notice set allowance of settlement token, used for limit order to be able to transfer liquidity tokens
     */
    // function setSettlementTokenAllowance(uint quantity, address spender) external;
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ILiquidityPool.sol";
import "./PoolToken.sol";
import "../limitOrders/ILimitOrderProxy.sol";
import "../options/AbstractOptions.sol";
import {BinarySearch} from "../libraries/Search.sol";
import {CommonUtils} from "../libraries/Utils.sol";
import "../options/IOptions.sol";

/**
 * @title a common and partial (abstract) implementation for Liquidity Pools
 */
abstract contract AbstractLiquidityPool is ILiquidityPool, Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;

    PoolToken immutable public poolToken;

    ERC20 immutable public liquidityToken;
    ERC20 immutable public settlementToken;

    uint256 public lockupPeriod = 0 weeks; // TODO: set back to a real value
    uint256 public totalLockedQuantity;
    mapping(address => uint256) public lastProvideTimestamp;
    
    /// @dev Snapshots (for a specified option) are not fully (all LPs) collateralized
    uint256[] public activeSnapshotIds;

    /// @dev Mark a provider reduced liquidity for an option. Key: See function `CommonUtils.keyOf()`
    mapping(uint256 => mapping(address => bool)) private _reducedProviders;
    /// @dev Liquidity amount that is locked at a snapshotId. This will be reduced when admin/owner make post-exercise actions
    mapping(uint256 => uint256) public lockedAt;
    /// @dev Total Liquidity amount that is locked when an option is created
    mapping(uint256 => uint256) public totalLockedAt;
    /**
     * @dev Each time admin scan a provider to reduce liquidity (that is locked to an option).
     * We increase _liquidityTotalScanned by balanceOf provider at the snapshotId
     * Record total scanned balance (of providers). Maximum equals to totalSupplyAt of a snapshotId
     */ 
    mapping(uint256 => uint256) private _liquidityTotalScanned;

    /// @dev Mark a provider claimed Premium of an option. Key: See function `CommonUtils.keyOf()`
    mapping(uint256 => mapping(address => bool)) private _claimedPremiumProviders;
    /// @dev Remain availabe Premium that isn't claimed at a snapshotId. This will be reduced when admin/owner make disburse premium actions, or provider call claimPremium method
    mapping(uint256 => uint256) public remainPremiumAt;
    /// @dev Total Premium that is provided when an option is created
    mapping(uint256 => uint256) public totalPremiumAt;
    /**
     * @notice Each time admin scan a provider to disburse premium shares(that is provide when created an option).
     * We increase premiumTotalScanned by balanceOf provider at the snapshotId
     * Record total scanned balance (of providers). Maximum equals to totalSupplyAt of a snapshotId
     */
    mapping(uint256 => uint256) public premiumTotalScanned;

    constructor(address _liquidityToken, address _settlementToken, address _poolToken) {
        liquidityToken = ERC20(_liquidityToken);
        settlementToken = ERC20(_settlementToken);
        poolToken = PoolToken(_poolToken);
    }

    /// @notice Liquidity Pool can't receive raw Ether
    receive() external virtual payable { revert('Not payable'); }

    fallback() external virtual { revert('Fallback not allowed'); }

    /// @notice Set/init Option contract to this pool. Grant owner, snapshot role & allow max amount for tokens
    function setOptionContract(address optionContract) external onlyOwner {
        transferOwnership(optionContract);
        // set unlimited allowance to the option contract (the owner)
        liquidityToken.safeApprove(optionContract, type(uint256).max);
        settlementToken.safeApprove(optionContract, type(uint256).max);
    }

    /// @notice Returns the total liquidity token available in the pool (locked or not)
    function _totalLiquidityBalance() internal view returns (uint256) {
        return liquidityToken.balanceOf(address(this));
    }

    /**
     * @notice Liquidity Provider (LP) provides liquidity token to the pool
     * @notice LP gets in return a portion of shares of the pool, in tokenPool units
     * @notice liquidity token requires allowance from provider
     * @param quantity Provided tokens
     */
    function provideLiquidity(uint256 quantity) payable override external {
        _provideLiquidity(quantity);

        emit Provide(msg.sender, quantity, block.timestamp);
    }

    function _provideLiquidity(uint256 quantity) virtual internal;

    /// @notice Re-inject liquidity from DEX, caller is Option contract
    function reinjectLiquidity(uint256 quantity) payable external onlyOwner {
        liquidityToken.safeTransferFrom(msg.sender, address(this), quantity);
    }

    //slither-disable-start calls-loop
    /// @notice Raise the liquidity shares of given receiver
    function _raiseLiquiditySharesOf(address receiver, uint256 quantity) internal {
        poolToken.mint(receiver, quantity);
    }
    //slither-disable-end calls-loop

     /// @notice inject ARP liquidity shares from DEX for a provider, caller is Option contract
    function injectARP(address receiver, uint256 quantity) external onlyOwner {
        _raiseLiquiditySharesOf(receiver, quantity);
    }

    /**
     * @notice LP burns tokenPool and receive liquidity tokens
     * @param quantity quantity of liquidity tokens LP wants to withdraw
     * @dev for instance a LP may wants to withdraw N liquidity tokens, but doesn't want to lower more than X% of his participation (shares) in the pool
     * @dev Usually amount = maxBurn for convenience.
     */
    function withdrawLiquidity(uint256 quantity) override public {
        require(quantity > 0, "!quantity");
        _withdrawLiquidity(msg.sender, quantity, poolToken.balanceOf(msg.sender), _lockedBalanceOf(msg.sender));
        
    }

    /// @dev See {ILiquidityPool}
    function withdrawAll() override public {
        address provider = msg.sender;
        uint256 locked = _lockedBalanceOf(provider);
        uint256 balance = poolToken.balanceOf(provider);
        require(locked < balance, "Not enough unlocked tokens");

        _withdrawLiquidity(provider, balance - locked, balance, locked);
    }

    /// @notice Withdraw a {quantity} liquidity for provider
    function _withdrawLiquidity(address provider, uint256 quantity, uint256 balance, uint256 lockedBalance) virtual internal;

    //slither-disable-start calls-loop
    /// @notice Reduce the liquidity shares of given receiver
    function _reduceLiquiditySharesOf(address receiver, uint256 quantity) internal {
        poolToken.burn(receiver, quantity);
    }
    //slither-disable-end calls-loop

    /// @notice Unlock a {quantity} liquidity for entire pool
    function _unlockLiquidity(uint256 quantity) internal {
        require(quantity > 0, "!quantity");
        require(totalLockedQuantity >= quantity, "Not enough locked balance");
        //slither-disable-next-line costly-loop
        totalLockedQuantity -= quantity;
    }

    /// @notice Set lockup period. Lockup period defines how long the liquidity token can or can't be withdrawn
    function setLockupPeriod(uint value) override external onlyOwner {
        require(value <= 60 days, "Lockup period is too large");
        lockupPeriod = value;
    }

    /// @notice Returns the amount of liquidity tokens not locked, and thus available for withdrawals
    function availableLiquidity() override public view returns (uint256 balance){
        return _totalLiquidityBalance() - totalLockedQuantity;
    }

    //slither-disable-start reentrancy-benign
    /// @notice Take a snapshot for a given option
    function snapshot(IOptions.Option calldata option) public onlyOwner returns (uint256 snapshotId) {
        snapshotId = poolToken.snapshot();
        activeSnapshotIds.push(snapshotId);

        uint256 totalAmount = option.liquidityAmount;
        uint256 premium = option.premiumWad;

        // Lock liquidity for option
        require(totalAmount > 0, "!quantity");
        require(_totalLiquidityBalance() > 0, "Insufficient Liquidity token");
        require(poolToken.totalSupply() >= totalAmount + totalLockedQuantity, "Not enough unlocked balance");
        totalLockedQuantity += totalAmount;

        lockedAt[snapshotId] = totalAmount;
        totalLockedAt[snapshotId] = totalAmount;
        totalPremiumAt[snapshotId] = premium;
        remainPremiumAt[snapshotId] = premium;
    }
    //slither-disable-end reentrancy-benign

    /// @notice deactivate a snapshot, when the option is expired
    function deactivate(uint256 snapshotId, bool needUnlock) public onlyOwner {
        _deactivate(snapshotId, needUnlock);
    }

    //slither-disable-start costly-loop
    function _deactivate(uint256 snapshotId, bool needUnlock) internal {
        _removeActiveSnapshot(snapshotId);
        if (needUnlock) _unlockLiquidity(lockedAt[snapshotId]);
        delete lockedAt[snapshotId];
        delete totalLockedAt[snapshotId];
        delete _liquidityTotalScanned[snapshotId];
    }
    //slither-disable-end costly-loop

    /// @notice Calculate the current locked balance for a provider
    function _lockedBalanceOf(address provider) internal view returns(uint256) {
        uint256 totalLocked = 0;
        uint256 len = activeSnapshotIds.length;
        if (len == 0) return 0;
        
        uint256 snapshotId = 0;
        uint256 foundIdx = type(uint256).max; // Init with Max index
        uint256 lockedAmount = 0;
        uint256 balanceAt = 0;
        uint256 totalAt = 0;

        for (uint256 i = len - 1; ; ) {
            snapshotId = activeSnapshotIds[i];
            // If found an extractly snapshot id (which store balanceOf value) is less than given snapshotId
            // We can re-user that foundIdx to next for loop. 
            // If the next snapshotId still greater than foundIdx, re-user balanceOf value at previous for loop.
            if (foundIdx > snapshotId) {
                (foundIdx, balanceAt) = poolToken.balanceOfAt(provider, snapshotId);
            }
            (,totalAt) = poolToken.totalSupplyAt(snapshotId);
            lockedAmount = _isReducedLiquidity(snapshotId, provider) ? 0 : totalLockedAt[snapshotId] * balanceAt / totalAt;
            totalLocked += Math.min(balanceAt, lockedAmount);
            if (i == 0) break;
            unchecked { i--; }
        }
        return totalLocked;
    }

    /**
     * @notice Estimated locked balance of a provider in Active/Pending options. 
     * This is not actual Collateral liquidity when execute post exercised Option 
     * See: {_liquidateFor()} function
     */
    function lockedBalances(address provider) external view returns(uint256) {
        return _lockedBalanceOf(provider);
    }

    //slither-disable-start similar-names
    /// @notice Get shares of a given amount (liquidity, ARP, premium) a provider at a snapshot
    function getSharesOfAt(uint256 amount, address provider, uint256 snapshotId) external view returns(uint256 _shares, uint256 _balanceAt, uint256 _totalSupplyAt, uint256 foundIdx) {
    //    return _getSharesOfAt(amount, provider, snapshotId);
       (foundIdx,_balanceAt) = poolToken.balanceOfAt(provider, snapshotId);
        (, _totalSupplyAt) = poolToken.totalSupplyAt(snapshotId);
        _shares = (amount * _balanceAt)/_totalSupplyAt;
    }
    //slither-disable-end similar-names

    function _isReducedLiquidity(uint256 snapshotId, address provider) internal view returns(bool) {
        return _reducedProviders[snapshotId][provider];
    }

    function _setReducedLiquidity(uint256 snapshotId, address provider) internal {
        _reducedProviders[snapshotId][provider] = true;
    }

    //slither-disable-start reentrancy-benign
    //slither-disable-start reentrancy-no-eth 
    //slither-disable-start reentrancy-events 
    /// @notice liquidate provier's shares amount of an option by given snapshotId
    function liquidate(uint256 snapshotId, address[] calldata providers) public onlyOwner {
        require(_isSnapshotIdActive(snapshotId), "Snapshot is not active");
        // totalSupplyAt is same to all providers at snapshotId
        (,uint256 totalSupplyAt_) = poolToken.totalSupplyAt(snapshotId);
        uint256 totalLockedAt_ = totalLockedAt[snapshotId];
        uint256 lockedAt_ = lockedAt[snapshotId];
        uint256 scanned = _liquidityTotalScanned[snapshotId];
        bool allLiquidated = false;
        uint256 totalReduced = 0;

        uint256 length = providers.length;
        for (uint i = 0; i < length; ) {
            (uint256 reduceShares, uint256 balanceAt, bool allLiquidated_) 
                = _liquidateFor(
                    providers[i],
                    snapshotId,
                    totalSupplyAt_,
                    totalLockedAt_,
                    scanned
                );
            scanned += balanceAt;
            if (allLiquidated_) { 
                allLiquidated = true;
                // If all provider is liquidated, but there are any amount left. 
                // Due to the surplus of division
                // The last provider will take it.
                // E.g. lockedAt_ = 100, but totalReduced = 99, then totalReduced = 100.
                if (lockedAt_ > totalReduced) {
                    totalReduced = lockedAt_;
                } 
            } else {
                totalReduced += reduceShares;
            }
            unchecked { i++; }
        }
        require(totalReduced <= lockedAt_, string.concat("Insufficient locked liquidity at snapshot ", Strings.toString(snapshotId)));
        if (allLiquidated) {
            _deactivate(snapshotId, false);
        } else {
            lockedAt[snapshotId] = lockedAt_ - totalReduced;
            _liquidityTotalScanned[snapshotId] = scanned;
        }
        _unlockLiquidity(totalReduced);
    }
    //slither-disable-end reentrancy-no-eth
    //slither-disable-end reentrancy-benign
    //slither-disable-end reentrancy-events

    //slither-disable-start reentrancy-events
    //slither-disable-start calls-loop
    /// @notice Check to reduce liquidity shares of a provider to an option
    function _liquidateFor(
        address provider,
        uint256 snapshotId,
        uint256 totalSupplyAt_,
        uint256 totalLockedAt_,
        uint256 scanned_
    ) internal returns(uint256 reduceShares, uint256 balanceAt, bool allLiquidated) {
        require(!_isReducedLiquidity(snapshotId, provider), "Liquidity provider has been reduced");

        (,balanceAt) = poolToken.balanceOfAt(provider, snapshotId);
        reduceShares = (balanceAt * totalLockedAt_) / totalSupplyAt_;

        if (reduceShares > 0) {
            // If, Scanned all providers for liquidate this option
            if (scanned_ + balanceAt == totalSupplyAt_) {
                allLiquidated = true;
            }
            _setReducedLiquidity(snapshotId, provider);
            _reduceLiquiditySharesOf(provider, reduceShares);
            emit LiquidateFor(snapshotId, provider, reduceShares);
        }
    }
    //slither-disable-end calls-loop
    //slither-disable-end reentrancy-events

    //slither-disable-start reentrancy-no-eth
    /// @notice Disburse Premium shares of an option (at snapshotId) to providers
    function disbursePremiums(uint256 snapshotId, address[] calldata providers) public onlyOwner {
        require(_isSnapshotIdActive(snapshotId), "Snapshot is not active");
        bool allPremiumClaimed = false;
        // totalSupplyAt is same to all providers at snapshotId
        (,uint256 totalSupplyAt_) = poolToken.totalSupplyAt(snapshotId);
        uint256 totalPremiumAt_ = totalPremiumAt[snapshotId];
        uint256 remainPremiumAt_ = remainPremiumAt[snapshotId];
        uint256 scanned = premiumTotalScanned[snapshotId];
        uint256 totalDisbursed = 0;

        uint256 length = providers.length;
        for (uint i = 0; i < length;) {
            (uint256 premiumShares, uint256 balanceAt, bool allPremiumClaimed_) 
                = _disbursePremiumFor(
                    snapshotId,
                    providers[i],
                    totalSupplyAt_,
                    totalPremiumAt_,
                    scanned
                );
            scanned += balanceAt;
            if (allPremiumClaimed_) {
                allPremiumClaimed = true;
                // If all provider is claimed/disbursed premium, but there are any amount left. 
                // Due to the surplus of division
                // The last provider will take it.
                // E.g. remainPremiumAt_ = 100, but totalDisbursed = 99, then totalDisbursed = 100.
                if (remainPremiumAt_ > totalDisbursed) {
                    totalDisbursed = remainPremiumAt_;
                }
            } else {
                totalDisbursed += premiumShares;
            }
            unchecked { i++; }
        }
        require(totalDisbursed <= remainPremiumAt_, "Insufficient Premium at snapshot");
        if (allPremiumClaimed) {
            // Delete all premium states when all provider claimed/disbursed
            delete remainPremiumAt[snapshotId];
            delete totalPremiumAt[snapshotId];
            delete premiumTotalScanned[snapshotId];
        } else {
            remainPremiumAt[snapshotId] = remainPremiumAt_ - totalDisbursed;
            premiumTotalScanned[snapshotId] = scanned;   
        }
    }
    //slither-disable-end reentrancy-no-eth

    //slither-disable-start reentrancy-benign
    //slither-disable-start reentrancy-no-eth
    /// @notice Claim Premium shares of an option (at snapshotId) for a provider
    function claimPremiumFor(uint256 snapshotId, address provider) public onlyOwner returns(uint256) {
        (,uint256 totalSupplyAt_) = poolToken.totalSupplyAt(snapshotId);

        (uint256 premiumShares,, bool allClaimed)
            = _disbursePremiumFor(
                    snapshotId,
                    provider,
                    totalSupplyAt_,
                    totalPremiumAt[snapshotId],
                    premiumTotalScanned[snapshotId]
                );
        if (allClaimed) {
            delete remainPremiumAt[snapshotId];
            delete totalPremiumAt[snapshotId];
            delete premiumTotalScanned[snapshotId];
        }
        return premiumShares;
    }
    //slither-disable-end reentrancy-no-eth
    //slither-disable-end reentrancy-benign


    //slither-disable-start calls-loop
    //slither-disable-start reentrancy-events
    /// @notice Disburse Premium shares of an option (at snapshotId) to provider
    function _disbursePremiumFor(
        uint256 snapshotId,
        address provider,
        uint256 totalSupplyAt_,
        uint256 totalPremiumAt_,
        uint256 scanned_
    ) internal returns (uint256 premiumShares, uint256 balanceAt, bool allPremiumClaimed) {
        require(!_claimedPremiumProviders[snapshotId][provider], "Already claimed");

        (,balanceAt) = poolToken.balanceOfAt(provider, snapshotId);
        premiumShares = (balanceAt * totalPremiumAt_) / totalSupplyAt_;

        if (premiumShares > 0) {
            if (scanned_ + balanceAt == totalSupplyAt_) {
                allPremiumClaimed = true;
            }

            // Mark provider is claimed premium for option with snapshotId
            _claimedPremiumProviders[snapshotId][provider] = true;
            _raiseLiquiditySharesOf(provider, premiumShares);
            emit DisbursePremiumFor(snapshotId, provider, premiumShares);
        }
    }
    //slither-disable-end calls-loop
    //slither-disable-end reentrancy-events

    function _isSnapshotIdActive(uint256 snapshotId) internal view returns(bool) {
        uint256 activeIndex = BinarySearch.bsearch(activeSnapshotIds, snapshotId);
        return activeIndex < activeSnapshotIds.length;
    }

    //slither-disable-start costly-loop
    /// @notice Find & remove an active a snapshot. In other words, deactivate that snapshotId
    function _removeActiveSnapshot(uint256 snapshotId) internal {
        if (activeSnapshotIds.length == 0) return;
        uint256 idx = BinarySearch.bsearch(activeSnapshotIds, snapshotId);
        
        if (idx < activeSnapshotIds.length) {
            // Shift all items before found index to left & Remove last item
            uint256 activeSnapshotLength = activeSnapshotIds.length - 1;
            for (uint i = idx; i < activeSnapshotLength;){
                activeSnapshotIds[i] = activeSnapshotIds[i+1];
                unchecked { i++; }
            }
            activeSnapshotIds.pop();
            emit RemoveActiveSnapshot(snapshotId);
        }
    }
    //slither-disable-end costly-loop

    /// @notice Check if provider is in lockup period. Then, he/she can not withdraw
    function _inLockupPeriod(address provider) internal view returns(bool) {
        //slither-disable-next-line timestamp
        return lastProvideTimestamp[provider] + lockupPeriod > block.timestamp;
    }

    /// @notice Transfer Settlement token (received after exercised an option) to Limit order proxy in order to place a Limit order
    function transferLimitOrder(address limitOrderProxy, uint256 amount) external onlyOwner {
        settlementToken.safeTransfer(limitOrderProxy, amount);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../tokens/ERC20SS.sol";

/**
 * @title Pool token as liquidity shares token
 * @dev See custom SnapshotERC20 contract at {ERC20SS}
 */
contract PoolToken is ERC20, ERC20SS, AccessControl {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

    constructor() ERC20SS("MGH_Pool_Token", "mPool") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
    }

    /// @notice Take a snapshot for token
    function snapshot() public onlyRole(SNAPSHOT_ROLE) returns (uint256) {
        return _snapshot();
    }

    function mint(address account, uint256 amount) public onlyRole(SNAPSHOT_ROLE) {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyRole(SNAPSHOT_ROLE) {
        _burn(account, amount);
    }

    /// @dev The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20SS)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.18;

import "../options/AbstractOptions.sol";
import "../options/IOptions.sol";

/// @dev States of Limit Orders
enum LimitOrderState {Active, Exercised, Expired}

/**
* if type is Call : maker waits for the price to be lower than threshold
* it type is Put : maker waits for the price to be upper than threshold
*/
enum LimitOrderType {Call, Put}

/**
* @title Limit Order Proxy
* @author MGH Protocol
* @dev Common interface for Limit Order on-chain processes
*/
interface ILimitOrderProxy {
    /**
    * @title Represents a Limit Order
    * @dev Exemple for a Limit order after a Call Option Exercised:
    * 1. price of underlier has raised, so option have been exercised.
    * 2. maker wants to buy back N amount of Asset_A, giving M amount of asset_B
    * 3. price of asset_A (rate with asset_B) falls and cut threshold price, before end of period P
    * 4. maker pays N Asset_A to taker
    * 5. takers transfers M amount of asset_B to maker
    *
    * Note: in the particular case of Limit Order USDC/ETH, the Asset_B is not a token but raw ethers
    *
    * @param optionContractAddress address of the option contract that fill the order
    * @param optionID Option ID of the exercised option
    * @param makerAmount amount of token given by the maker to the taker
    * @param takerAmount amount of token given by the taker to the maker
    * @param maturityDate maturity / expiration of the order
    * @param timestamp creation timestamp
    * @param state status
    * @param orderType type of order
    */
    struct OrderStruct {
        address payable optionContractAddress;
        uint256 optionID;
        uint256 makerAmount;
        uint256 takerAmount;
        uint256 maturityDate;
        uint256 timestamp;
        LimitOrderState state;
        LimitOrderType orderType;
    }

    event LimitOrderCreated(address optionContractAddress, uint256 optionId, uint makerAmount, uint takerAmount);
    event LimitOrderExercised(address indexed maker, uint makerAmount, string makerTokenName, uint takerAmount);

    /**
     * @notice Operator or owner makes execution in order to re-inject amount of liquidity token to Liquidity pool
     * @param optionContractAddress Address of Put/Call Option contract
     * @param optionID ID of option to be re-injected
     * @param amount Amount to be re-injected
     */
    function reinjectLiquidity(address payable optionContractAddress, uint256 optionID, uint256 amount) external;

    //slither-disable-start similar-names
    /**
     * Create & place a limit order to specific DEX
     * @param optionID Executed option ID
     * @param makerAmount_ Amount of 
     */
    function createOrder(uint256 optionID, uint256 makerAmount_, uint256 takerAmount_, LimitOrderType orderType_) external;
    //slither-disable-end similar-names
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "./IOptions.sol";
import "../limitOrders/ILimitOrderProxy.sol";
import "../pools/ILiquidityPool.sol";
import "../pools/AbstractLiquidityPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SettlerProxy.sol";
import "../priceProviders/PriceProviderInterfaces.sol";
import "./PricerProxy.sol";
import "../libraries/VerifySignature.sol";
import {BinarySearch} from "../libraries/Search.sol";
import {CommonUtils} from "../libraries/Utils.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error NotCallOrPut();
error InvalidOptionState();
error InvalidOptionType();
error InvalidId();
error InvalidState();

/**
 * @title On-chain Options Trading Protocol on Ethereum
 * @notice Protocol Options Contract
 */
abstract contract AbstractOptions is IOptions, Ownable {
    using SafeERC20 for ERC20;

    // keccak256("PriceInfo(uint8 optionType,uint256 price,uint256 strike,uint256 maturity,uint256 nonce,uint256 expiration,address buyer)");
    bytes32 public constant PRICE_INFO_HASH = 0xb9d42e02520442cbfe92f14271973b41e7e2bd6da3006deb0594d4c1d1bf9582;

    /// Min, Max option period for exercise
    uint256 public constant MIN_PERIOD = 1 hours;
    uint256 public constant MAX_PERIOD = 4 * 4 weeks;

    /// @dev Protocol fee percentage
    uint256 public constant PROTOCOL_REWARD_PERCENT = 10; // 10% protocol reward as a percentage of premiums

    SettlerProxy immutable public settlerProxy;
    PricerProxy immutable public pricerProxy;

    MGHPriceProvider immutable public underlyingAssetPriceIndex;

    mapping(uint256 => Option) public options;
    uint256 private _optionsSize = 0;
    
    /// @dev Amount ARP claimed by provider in an option. Key: See function `CommonUtils.keyOf()`
    mapping(uint256 => mapping(address => uint256)) private _claimedARPAmount;

    OptionType public optionType;

    address payable public settlementFeeRecipient;
    uint256 immutable internal contractCreationTimestamp;
    ILimitOrderProxy immutable internal limitOrderProxy;
    AbstractLiquidityPool immutable public pool;

    mapping(address => uint256) priceInfoNonce;
    string constant NAME = "MGH protocol";
    string constant VERSION = "1.0.0";

    /**
     * @param pp The address of price feed contract
     * @param _type Put or Call type of an option contract
     */
    constructor(
        MGHPriceProvider pp,
        OptionType _type,
        ILimitOrderProxy _limitOrderProxy,
        AbstractLiquidityPool _pool,
        SettlerProxy _settlerProxy,
        PricerProxy _pricerProxy,
        address payable _settlementFeeRecipient
    ) {
        underlyingAssetPriceIndex = pp;
        optionType = _type;
        settlementFeeRecipient = payable(_settlementFeeRecipient);
        contractCreationTimestamp = block.timestamp;
        limitOrderProxy = _limitOrderProxy;
        pool = _pool;
        settlerProxy = _settlerProxy;
        pricerProxy = _pricerProxy;
    }

    receive() external payable { revert(); }
    fallback() external { revert(); }

    function transferPoolOwnership() external onlyOwner {
        //slither-disable-next-line timestamp
        require(block.timestamp < contractCreationTimestamp + 90 days);
        pool.transferOwnership(owner());
    }

    function getOption(uint256 optionID) public view returns (Option memory option){
        option = options[optionID];
    }

    function setSettlementFeeRecipient(
        address payable recipient
    ) external override onlyOwner {
        require(recipient != address(0));
        settlementFeeRecipient = recipient;
        emit SettlementFeeRecipientChanged(recipient);
    }

    function nonce(
        address buyer
    ) public view returns (uint256) {
        return priceInfoNonce[buyer];
    }

    function _verifySignature(
        PriceInfo calldata priceInfo,
        bytes calldata signature,
        uint256 strike,
        uint256 maturity
    ) internal view {
        require(priceInfo.nonce == priceInfoNonce[msg.sender], "Invalid nonce");
        //slither-disable-next-line timestamp
        require(priceInfo.expiration >= block.timestamp, "Price info expired");

        if (optionType == OptionType.Put) {
            if(priceInfo.optionType != 1) revert InvalidOptionType();
        } else if (optionType == OptionType.Call) {
            if(priceInfo.optionType != 2) revert InvalidOptionType();
        } else {
            revert NotCallOrPut();
        }

        bytes32 hash = keccak256(
            abi.encode(
                PRICE_INFO_HASH,
                priceInfo.optionType,
                priceInfo.price,
                strike,
                maturity,
                priceInfo.nonce,
                priceInfo.expiration,
                priceInfo.buyer
            )
        );

        require(
            VerifySignature.verify(
                pricerProxy.pricer(),
                hash,
                signature,
                NAME,
                VERSION,
                block.chainid,
                address(this)
            ),
            "Must be signed by pricer"
        );
    }

    // slither-disable-start reentrancy-events
    // slither-disable-start reentrancy-no-eth
    /// @dev See {IOptions}
    function create(
        uint256 maturity,
        uint256 quantityWad,
        uint256 strikeWad,
        PriceInfo calldata priceInfo,
        bytes calldata signature
    ) external payable virtual {
        _verifySignature(priceInfo, signature, strikeWad, maturity);

        priceInfoNonce[msg.sender]++;

        require(strikeWad > 0, "strike can't be less than 1");
        require(quantityWad > 0, "quantity can't be less than 1");
        require(maturity >= MIN_PERIOD, "Period is too short");
        require(maturity <= MAX_PERIOD, "Period is too long");

        uint256 premium = (priceInfo.price * quantityWad) / 1e18;
        uint256 protocolFee = _getProtocolFee(premium);
        uint256 poolPremium = premium - protocolFee;

        uint optionID = _optionsSize;
        _createOption(optionID, strikeWad, quantityWad, poolPremium, maturity);
        Option memory option = options[optionID];
        uint256 snapshotId = pool.poolToken().currentSnapshotId() + 1;
        options[optionID].snapshotId = snapshotId;

        // Transfer Premium to this contract
        ERC20 premiumToken = optionType == OptionType.Put ? pool.liquidityToken() : pool.settlementToken();
        require(msg.value == 0, "option can't receive eth");
        require(premiumToken.allowance(msg.sender, address(this)) >= premium, 'allowance for the pool of liquidity token is not enough');
        premiumToken.safeTransferFrom(msg.sender, address(this), premium);
        
        // Transfer Protocol Fees to Fee recipient
        premiumToken.safeTransfer(settlementFeeRecipient, protocolFee);

        // Incrase option counter
        _optionsSize++;

        // Transfer pool premium from this contract to Pool
        premiumToken.safeTransfer(address(pool), poolPremium);
        // Take snapshot for new option
        require(pool.snapshot(option) == snapshotId, "Invalid snapshot id creatation");
        emit Create(optionID, msg.sender, maturity, quantityWad, strikeWad, priceInfo.price, premium, protocolFee, poolPremium, block.timestamp);
    }
    // slither-disable-end reentrancy-no-eth
    // slither-disable-end reentrancy-events

    function _createOption(
        uint256 optionID,
        uint256 strikeWad,
        uint256 quantityWad,
        uint256 poolPremium,
        uint256 maturity
    ) internal virtual;

    function _isExerciseSwap(Option storage option) internal virtual returns (bool);

    //slither-disable-start reentrancy-events
    /// @dev See {IOptions}
    function exercise(uint256 optionID) external payable override {
        Option storage option = options[optionID];
        //slither-disable-next-line timestamp
        require(option.maturity <= block.timestamp, "Option maturity not reached");
        require(option.holder == msg.sender || settlerProxy.settler() == msg.sender, "Wrong msg.sender");
        require(option.state == State.Active, "Wrong state");

        if (_isStrikeOk(option)) {
            // I. Strike check is OK, Make swap
            bool holderTransfered = _isExerciseSwap(option);

            if (holderTransfered) {
                // I.1. Both transfers are success, place Limit Order & option is exercised
                _exercisedOption(optionID);
            } else {
                // I.2. Holder transfer failed
                option.state = State.Pending;
                emit Pending(optionID, msg.sender);
            }
        } else {
            // II. Strike check is NG, Expire Option
            option.state = State.Expired;
            pool.deactivate(option.snapshotId, true);
            emit Expire(optionID, option.premiumWad, msg.sender);
        }
    }
    //slither-disable-end reentrancy-events

    //slither-disable-start reentrancy-events
    function _exercisedOption(uint256 optionID) internal {
        require(optionID < _optionsSize, '!optionID');
        Option storage option = options[optionID];
        require(option.state == State.Active || option.state == State.Pending, '!Exercised');
        option.state = State.Exercised;

        // Compute Limit order args before place an order on DEX
        // slither-disable-next-line similar-names
        (uint256 makerAmount, uint256 takerAmount, LimitOrderType orderType) = _computeLimitOrderArgs(option);

        // Move settlement tokens to limit order proxy
        pool.transferLimitOrder(address(limitOrderProxy), makerAmount);
        // Place a limit order on DEX
        limitOrderProxy.createOrder(optionID, makerAmount, takerAmount, orderType);
        emit Exercise(optionID, option.holder, option.liquidityAmount, msg.sender);
    }
    //slither-disable-end reentrancy-events

    /**
     * @notice Admin/Owner liquidate liquidity shares (of options) to providers
     */
    function batchPostExercised(uint256[] calldata optionIDs, address[] calldata providers) external onlyOwner {
        // slither-disable-start calls-loop
        uint256 length = optionIDs.length;
        for (uint i = 0; i < length;) {
            uint256 optionID = optionIDs[i];
            if (optionID >= _optionsSize) revert InvalidId();
            Option storage option = options[optionID];

            if (
                option.state == State.Active ||
                option.state == State.Pending
            ) revert InvalidOptionState();
                
            pool.liquidate(option.snapshotId, providers);
            unchecked { i++; }
        }
        // slither-disable-end calls-loop
    }

    /**
     * @notice Admin/Owner disburse premium shares (of an option) to providers
     */
    function batchDisbursePremium(uint256 optionID, address[] calldata providers) external onlyOwner {
        pool.disbursePremiums(options[optionID].snapshotId, providers);
    }

    /// @dev See {IOptions}
    function setLockupPeriod(uint256 value) external override onlyOwner {
        require(value <= 60 days, "Lockup period too large");
        pool.setLockupPeriod(value);
    }

    /**
     * @notice Calculates settlementFee
     * @param premium Option premium
     * @return Protocol fee amount
     */
    function _getProtocolFee(uint256 premium) internal pure returns (uint256) {
        return premium * PROTOCOL_REWARD_PERCENT / 100;
    }

    /**
     * @notice Return if strike if option can be exercised based on strike and current price
     */
    function _isStrikeOk(Option storage option) internal view virtual returns (bool);

    /**
     * @notice Make the settlement after exercise
     * @notice in case of physical settlement : transfer pool's liquidity token to option holder and holder pays the pool with settlement token
     * @notice in case of cash settlement : pool pays the holder with the strike * quantity
     * @param option a specific option contract
     */
    function _computeLimitOrderArgs(Option storage option) internal view virtual returns (uint256, uint256, LimitOrderType);

    //slither-disable-start reentrancy-events
    /**
     * @dev See {IOptions}
     */
    function reinjectLiquidity(uint256 optionID, uint256 amount) external {
        require(msg.sender == address(limitOrderProxy), "Only limit order proxy should call this function");

        Option storage option = options[optionID];
        if (option.filled + amount > option.liquidityAmount) {
            amount = option.liquidityAmount - option.filled;
        }

        option.filled = option.filled + amount;
        // Transfer Reinject amount from sender to this contract
        pool.liquidityToken().safeTransferFrom(msg.sender, address(this), amount);
        // Approve reinject amount of this contract to withdraw from pool
        require(pool.liquidityToken().approve(address(pool), amount), "Approve Settlement Asset for pool failed");
        pool.reinjectLiquidity(amount);

        emit ReinjectLiquidity(msg.sender, optionID, amount);
    }
    //slither-disable-end reentrancy-events

    /**
     * @notice Provider claims premium shares of multiple options
     */
    function claimPremiums(uint256[] calldata optionIDs) external returns (uint256 claimed) {
        // slither-disable-start calls-loop
        uint256 length = optionIDs.length;
        for (uint i = 0; i < length;) {
            claimed += pool.claimPremiumFor(options[optionIDs[i]].snapshotId, msg.sender);
            unchecked { i++; }
        }
        // slither-disable-end calls-loop
    }

    /**
     * @notice Admin/Owner Claim ARP profit of multiple options for multiple providers
     */
    function batchClaimARP(uint256[] calldata optionIDs, address[] calldata providers) external onlyOwner {
        uint256 optionLength = optionIDs.length;
        uint256 providerLength = providers.length;

        for (uint i = 0; i < optionLength;) {
            uint256 optionID = optionIDs[i];
            if (optionID >= _optionsSize) continue;
            Option storage option = options[optionID];

            if (
                option.state != State.Exercised ||
                option.liquidityAmount == option.totalClaimedARPAmount
            ) continue;
                
            for (uint j = 0; j < providerLength;) {
                _claimARP(optionID, providers[j]);
                unchecked { j++; }
            }
            unchecked { i++; }
        }
    }

    /**
     * @notice Claim ARP profit of multiple options
     */
    function claimARPs(uint256[] calldata optionIDs) external returns (uint256 claimed) {
        uint256 length = optionIDs.length;
        for (uint i = 0; i < length;) {
            claimed += _claimARP(optionIDs[i], msg.sender);
            unchecked { i++; }
        }
    }

    // slither-disable-start calls-loop
    // slither-disable-start reentrancy-events
    /**
     * @notice Claim ARP profit share for a provider
     */
    function _claimARP(uint256 optionID, address provider) internal returns (uint256) {
        Option storage option = options[optionID];
        require(option.state == State.Exercised, "Option is not exercised");

        // Get current amount that claimed ARP
        uint256 amountClaimed = _claimedARPAmount[optionID][provider];
        (uint256 filledShares,,,) = pool.getSharesOfAt(option.filled, provider, option.snapshotId);
        uint256 claimMore = filledShares - amountClaimed;
        require(claimMore > 0, "Cannot claim more");

        // Set provider is Claimed ARP for option with optionID
        _claimedARPAmount[optionID][provider] = filledShares;
        // Increase liquidity share for provider
        pool.injectARP(provider, claimMore);
        emit ClaimARP(optionID, provider, claimMore);
        return claimMore;
    }
    // slither-disable-end calls-loop
    // slither-disable-end reentrancy-events
    /**
     * @notice Option holder resolves Pending option
     */
    function resolvePending(uint256 optionID) external {
        require(optionID < _optionsSize, "!optionID");
        Option storage option = options[optionID];
        require(msg.sender == option.holder, "!holder");
        require(option.state == State.Pending, "Not pending option");

        bool holderTransfered = _isExerciseSwap(option);

        require(holderTransfered, "Transfer is not success, please approve enough amount and try again");
        _exercisedOption(optionID);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

/**
 * @title Binary search for arrays
 */
library BinarySearch {
  function findInternal(uint256[] calldata data, uint256 begin, uint256 end, uint256 value) internal pure returns (uint256 ret) {
    uint256 len = end - begin;
    if (len == 0 || (len == 1 && data[begin] != value)) {
      return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }
    uint256 mid = begin + len / 2;
    uint256 v = data[mid];
    if (value < v)
      return findInternal(data, begin, mid, value);
    else if (value > v)
      return findInternal(data, mid + 1, end, value);
    else
      return mid;
  }
  
  /**
   * @notice Binary search for given sorted array by given integer value
   */
  function bsearch(uint256[] calldata sortedArray, uint256 value) public pure returns (uint256 ret) {
    return findInternal(sortedArray, 0, sortedArray.length, value);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Commonly Utilities for protocol
 */
library CommonUtils {
    /**
     * @notice Combine key from given id (of option or snapshot) and address (option's owner or liquidity provider)
     */
    function keyOf(uint256 id_, address address_) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(id_, address_));
    }

    /**
     * @notice return success or not for transferFrom function when using low-level call
     */
    function transferFromWithReturn(IERC20 token, address from, address to, uint256 amount) public returns(bool) {
        require(from != address(0), "!from");
        require(to != address(0), "!to");
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        //slither-disable-next-line low-level-calls
        (bool success, bytes memory data) 
            = address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.18;

import "../pools/ILiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title a common interface for Options
 * @notice Deployed Options contracts are defined by their tuple of (type: Call | Put, liquidity token, settlement token)
 * @dev Options contracts are owners of their liquidity pools
 * @dev Options manage the transfer of settlement tokens to / from the pool, thus manage the allowance / approval requests
 * @dev Options manage the transfer of liquidity tokens to / from the pool, thus manage the allowance / approval requests
 */
interface IOptions{
    event Create(
        uint256 indexed id,
        address indexed account,
        uint256 maturity,
        uint256 quantityWad,
        uint256 strikeWad,
        uint256 price,
        uint256 premium,
        uint256 protocolFee,
        uint256 poolPremium,
        uint256 timestamp
    );
    event Exercise(uint256 indexed id, address indexed holder, uint256 liquidityAmount, address indexed caller);
    event Expire(uint256 indexed id, uint256 poolPremium, address indexed caller);
    event Pending(uint256 indexed id, address indexed caller);
    event SettlementFeeRecipientChanged(address indexed recipient);
    event ReinjectLiquidity(address sender, uint256 optionID, uint256 amount);
    event ClaimARP(uint256 optionID, address provider, uint256 amount);
    
    /// @dev Option states
    enum State {Active, Exercised, Pending, Expired}
    /// @dev Option types
    enum OptionType {Put, Call}

    /// @dev Option info
    struct Option {
        State state;
        address payable holder;
        uint256 strikeWad;
        uint256 quantityWad;
        uint256 premiumWad;
        uint256 maturity;
        uint256 filled;
        uint256 snapshotId;
        uint256 liquidityAmount;
        // Total ARP amount that has been claimed by LPs
        uint256 totalClaimedARPAmount;
    }

    /// @dev Price info
    struct PriceInfo {
        uint256 price;
        uint256 nonce;
        uint256 expiration;
        address buyer;
        uint8 optionType; // 1: put, 2: call
    }

    /// @dev Underlying asset
    // function underlyingAsset() external view returns(ERC20);
    /// @dev Settlement asset
    // function settlementAsset() external view returns(ERC20);
    /// @dev Underlying symbol
    // function underlyingAssetSymbol() external view returns(string memory);
    /// @dev Settlement symbol
    // function settlementAssetSymbol() external view returns(string memory);
    /// @dev Strike currency symbol
    // function strikeCurrencySymbol() external view returns(string memory);

    /**
     * @notice gets the number of Options listed, independent of their statuses
     */
    // function getOptionsSize() external view returns (uint);

    /**
     * @notice Can be used to update the contract in critical situations, in the first 90 days after deployment
     * @notice will transfer the pool owner which is the option contract, to the option contract's owner (i.e. deployer)
     */
    function transferPoolOwnership() external;

    
    /**
     * @notice Used for changing settlementFeeRecipient, aka the protocol recipient address
     * @param recipient settlementFee recipient address
     */
    function setSettlementFeeRecipient(address payable recipient) external;

    /**
     * @notice Creates a new option
     * @param maturity Option period in seconds (1 days <= period <= 4 weeks)
     * @param quantityWad Option quantity of underlier, must be transfered to pay option's premium //TODO wip was payable - to convert
     * @param strikeWad Strike price of the option
     * @param priceInfo Pricing information from external pricer
     * @param signature Pricing information signature
     */
    function create(uint256 maturity, uint256 quantityWad, uint256 strikeWad, PriceInfo calldata priceInfo, bytes calldata signature) external payable ;


    /**
     * @notice Exercises an active option
     * @param optionID ID of your option
     */
    function exercise(uint256 optionID) external payable;
    
    /**
     * @notice Used for changing the lockup period of the attached liquidity pool
     * @param value New period value
     */
    function setLockupPeriod(uint256 value) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

/**
 * @notice Customization of ERC20Snapshot. Return actual `index` when query balanceOfAt, totalSupplyOfAt.
 * `index` is the actual snapshot index that snapshoted value of balance or total supply, not the given query index: snapshotId 
 */
abstract contract ERC20SS is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    // mapping(uint256 => uint256) private _totalSupplySnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        // _totalSupplySnapshots[currentId] = totalSupply();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function currentSnapshotId() public view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    /**
     * @dev Get the last snapshotId
     */
    function lastSnapshotId() public view returns (uint256) {
        return _getCurrentSnapshotId() - 1;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256, uint256) {
        (bool snapshotted, uint256 index, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return (index, snapshotted ? value : balanceOf(account));
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");
        (bool snapshotted, uint256 index, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return (index, snapshotted ? value : totalSupply());
        // return _totalSupplySnapshots[snapshotId];
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0, 0);
        } else {
            return (true, index, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
        // _totalSupplySnapshots[_getCurrentSnapshotId()] = totalSupply();
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title a proxy contract to store the settler address
 */
contract SettlerProxy is Ownable {

    address public settler;

    constructor(address _settler) {
        require(_settler != address(0), "!settler");
        settler = _settler;
    }

    function setSettler(address settler_) external onlyOwner {
        require(settler_ != address(0), "!settler");
        settler = settler_;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

pragma solidity ^0.8.18;

/**
 * @title MGH protocol Price provider interface
 */
interface MGHPriceProvider is AggregatorV3Interface {
    
    /**
     * @notice important notice, here the price is uint, so can't handle negative prices, not following ChainLink's AggregatorV3 interface
     * @param latestAnswerWad current value, expressed as a 'wei' value
     */
    function latestAnswer() external view returns (uint256 latestAnswerWad);
}

interface IPriceProviderObservable {
    function setSubscriber(address subscriber) external;

    function removeSubscriber(uint subscriberID) external;
}

interface IPriceProviderForceable {
    function setPrice(uint256 _price) external;

    event PriceChange(
        uint256 price
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title a proxy contract to store the pricer address
 */
contract PricerProxy is Ownable {

    address public pricer;

    constructor(address _pricer) {
        require(_pricer != address(0), "!pricer");
        pricer = _pricer;
    }

    function setPricer(address pricer_) external onlyOwner {
        require(pricer_ != address(0), "!pricer");
        pricer = pricer_;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Signature verifications
 */
library VerifySignature {
    /// @dev Hash given data
    function hashTypedDataV4(
        bytes32 messageHash_,
        string calldata name,
        string calldata version,
        uint256 chainId,
        address verifyingContract
    ) public pure returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, messageHash_));
    }

    /// @dev Verify given signature with hashed given data
    function verify(
        address pricer,
        bytes32 hash,
        bytes calldata signature,
        string calldata name, 
        string calldata version, 
        uint256 chainId,
        address verifyingContract
    ) public pure returns (bool) {
        bytes32 digest = hashTypedDataV4(hash, name, version, chainId, verifyingContract);
        address signer = ECDSA.recover(digest, signature);
        return pricer == signer ;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./StorageSlot.sol";
import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}